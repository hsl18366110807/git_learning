unit Tcpgameserver;

interface

uses
  Tcpserver, System.Classes, GameProtocol, System.SysUtils, LogServer,
  GameSqlServer, System.Math;

type
  TGameClient = class
  private
    FClient: TTCPClient;
    FUsername: AnsiString;
    GamerPosX: Integer;
    GamerPosY: Integer;
  public
    constructor Create(UserName: AnsiString; AClient: TTCPClient);
  end;

  TTcpgameserver = class(TTcpServer)
  private
    FGamers: TStrings;
    FUsers: TStrings;
  public
    FMap: TMap;
    procedure ProcessRequests(RequestPtr: PLoginMsg; AClient: TTCPClient);
    constructor Create;
    destructor Destroy; override;
  protected
    procedure ProcessClientIO(AClient: TTCPClient); override;
  private
    procedure InitMap;
    procedure SetGamerPos(AGamer: TGameClient);
    function RegisterNewUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
    function LoginUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
    function SendAllUser: Integer;
  end;

var
  FTcpgameserver: TTcpgameserver;

implementation


{ TTcpgameserver }

constructor TTcpgameserver.Create;
begin
  inherited Create;
  FGamers := TStringList.Create;
  InitMap;
end;

destructor TTcpgameserver.Destroy;
var
  i: Integer;
begin
  inherited;
  for i := 0 to FGamers.Count - 1 do
  begin
    FGamers.Free;
  end;
  FGamers.Free;
end;

procedure TTcpgameserver.InitMap;
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to MapLength do
  begin
    for J := 0 to MapWide do
    begin
      FMap.Map[I][J] := 0;
      if (I = 5) or (J = 5) then
      begin
        FMap.Map[I][J] := 3;
      end;
      if (I mod 2 = 0) and (J mod 2 = 0) then
      begin
        FMap.Map[I][J] := 2;
      end;
    end;
  end;

end;

function TTcpgameserver.LoginUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
var
  AGameer: TGameClient;
  UserName, password, Error: AnsiString;
  sql: AnsiString;
  request: TServerMessage;
begin
  if FGamers.IndexOfName(RequestPtr.UserName) = -1 then
  begin
    UserName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
    password := StrPas(PAnsichar(@(RequestPtr.Password)[0]));
    sql := 'SELECT * from test where username=' + '"' + UserName + '"' + 'and password=' + '"' + password + '";';
    if SQLserver.SetSqlList(sql) = True then
    begin
      Log.Info('用户' + RequestPtr.UserName + '登录');
      AGameer := TGameClient.Create(RequestPtr.UserName, AClient);
      AGameer.FUsername := RequestPtr.UserName;
      SetGamerPos(AGameer);
      FGamers.AddObject(UserName, AGameer);
      SendAllUser;
      Result := 0;
    end
    else
    begin
      Log.Error('用户名或密码错误！');
      Result := 1;
    end;
  end
  else
  begin
    Log.Error('用户已经在线！');
    Result := 2;
  end;
  FillChar(request, SizeOf(request), 0);
  request.head.Flag := PACK_FLAG;
  request.head.Size := SizeOf(request);
  request.head.Command := S_LOGIN;
  request.ErrorCode := Result;
  if Result = 1 then
  begin
    Error := '用户名或密码错误';
    StrLCopy(@request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end
  else if Result = 2 then
  begin
    Error := '用户已经在线';
    StrLCopy(@request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end;
  AClient.SendData(@request, SizeOf(request));
end;

procedure TTcpgameserver.ProcessClientIO(AClient: TTCPClient);
var
  BufPtr: PByte;
  BufSize, FetchSize: Integer;
begin
  AClient.LockReadBuffer(BufPtr, BufSize);
  FetchSize := 0;
  try
    if BufSize = 0 then
    begin
      Exit;
    end;
    while BufSize > 4 do
    begin
      if PCardinal(BufPtr)^ <> PACK_FLAG then
      begin
        BufSize := BufSize - 1;
        BufPtr := Pointer(Integer(BufPtr) + 1);
        FetchSize := FetchSize + 1;
        Continue;
      end;

      if (BufSize >= SizeOf(TLoginMsgHead)) and (PLoginMsgHead(BufPtr)^.Size <= BufSize) then
      begin
        FetchSize := FetchSize + PLoginMsgHead(BufPtr)^.Size;
        ProcessRequests(PLoginMsg(BufPtr), AClient);
        BufSize := BufSize - FetchSize;
      end;

    end;
  finally
    AClient.UnLockReadBuffer(FetchSize);
  end;
end;

procedure TTcpgameserver.ProcessRequests(RequestPtr: PLoginMsg; AClient: TTCPClient);
begin

  case RequestPtr.Head.Command of
    C_REGISTER:
      begin
        RegisterNewUser(PLoginMsg(RequestPtr), AClient);
      end;
    C_LOGIN:
      begin
        LoginUser(PLoginMsg(RequestPtr), AClient);
      end;
  end;
end;

function TTcpgameserver.RegisterNewUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
var
  sql: AnsiString;
  username, password, Error: AnsiString;
  Request: TServerMessage;
begin
  username := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  password := StrPas(PAnsichar(@(RequestPtr.Password)[0]));
  sql := 'SELECT * from test where username=' + '"' + username + '"';
  if SQLserver.SetSqlList(sql) = False then
  begin
    sql := 'INSERT into test (username, password) values(' + '"' + username + '"' + ',' + '"' + password + '"' + ');';
    if SQLserver.SetSqlList(sql) then
    begin
      Log.Info('注册成功');
      Result := 0;
    end;
  end
  else
  begin
    Log.Warn('用户已存在，注册失败');
    Result := 1;
  end;

  FillChar(Request, SizeOf(Request), 0);
  Request.head.Flag := PACK_FLAG;
  Request.head.Size := SizeOf(Request);
  Request.head.Command := S_REGISTER;
  Request.ErrorCode := Result;
  if Result = 1 then
  begin
    Error := '用户已经存在';
    StrLCopy(@Request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end;
  AClient.SendData(@Request, sizeof(Request));
end;

function TTcpgameserver.SendAllUser: Integer;
var
  UserName: AnsiString;
  i: integer;
begin
  for i := 0 to FGamers.Count - 1 do
  begin
    UserName := FGamers.Strings[i];
    FMap.head.Flag := PACK_FLAG;
    FMap.head.Size := SizeOf(FMap);
    FMap.head.Command := S_MAP;

    TGameClient(FGamers.Objects[i]).FClient.SendData(@Fmap, SizeOf(FMap));
  end;
  Result := 0;
end;

procedure TTcpgameserver.SetGamerPos(AGamer: TGameClient);
var
  X, Y: Integer;
begin
  repeat
    X := randomrange(0, 9);
    Y := RandomRange(0, 9);
  until FMap.Map[X][Y] = 0;
  AGamer.GamerPosX := X;
  AGamer.GamerPosY := Y;
  FMap.Map[X][Y] := 3;
end;
{ TGameClient }

constructor TGameClient.Create(UserName: AnsiString; AClient: TTCPClient);
begin
  FUsername := UserName;
  FClient := AClient;
end;

initialization
  FTcpgameserver := TTcpgameserver.Create;

finalization
  FTcpgameserver.free;

end.


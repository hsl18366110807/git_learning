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
    procedure ChangeGamerPos(ChangeType: MoveDirect);
    constructor Create(UserName: AnsiString; AClient: TTCPClient);
  end;

  TTcpgameserver = class(TTcpServer)
  private
    FGamers: TStrings;
    FBombList: TStrings;
  public
    FMap: TMap;
    procedure ProcessRequests(RequestPtr: PLoginMsg; AClient: TTCPClient);
    constructor Create;
    destructor Destroy; override;
  protected
    procedure Execute; override;
    procedure ProcessClientIO(AClient: TTCPClient); override;
    procedure ClientRemoved(AClient: TTCPClient); override;
  private
    function FindGamer(AClient: TTCPClient): TGameClient;
    procedure InitGameMap;
    procedure SetGamerPos(AGamer: TGameClient);
    function RegisterNewUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
    function LoginUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
    function PlayerMove(RequestPtr: PPlayerMove; AClient: TTCPClient): Integer;
    function PlayerSetBomb(RequestPtr: PPlayerSetBoom; AClient: TTCPClient): Integer;
    function BombEvent(BomePos: Integer): Integer;
    function SendAllUser: Integer;
    function SendBombEvent(BombX: Integer; BombY: Integer; BoomW: Integer; BoomA: Integer; BoomS: Integer; BoomD: Integer): Integer;
    function PlayerDead(UserName: AnsiString; PlayerPosX: Integer; PlayerPosY: Integer): Integer;
  end;

var
  FTcpgameserver: TTcpgameserver;

implementation


{ TTcpgameserver }

function TTcpgameserver.BombEvent(BomePos: Integer): Integer;
var
  BombX, BombY, PlayerX, PlayerY, I, J: Integer;
  BoomW, BoomA, BoomD, BoomS: Integer;
begin

  BombX := TBomb(FBombList.Objects[BomePos]).FBombPosX;
  BombY := TBomb(FBombList.Objects[BomePos]).FBombPosY;

  for I := 0 to BoomScope - 1 do   //判定是否爆破到人
  begin
    Inc(BoomD);
    if (FMap.Map[BombX + I][BombY] <> 0) and (FMap.Map[BombX + I][BombY] = 3) then
    begin

      PlayerX := BombX + I;
      PlayerY := BombY;
      for J := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FGamers.Delete(J);
          FMap.Map[PlayerX][PlayerY] := 0;
          SendAllUser;
        end;
      end;
    end
    else if FMap.Map[BombX + I][BombY] = 1 then
    begin
      Break;
    end
    else if FMap.Map[BombX + I][BombY] = 2 then
    begin
      FMap.Map[BombX + I][BombY] := 0;
      SendAllUser;
      Break;
    end;
  end;
  for I := 0 to BoomScope - 1 do
  begin
    Inc(BoomA);
    if (FMap.Map[BombX - I][BombY] <> 0) and (FMap.Map[BombX - I][BombY] = 3) then
    begin
      PlayerX := BombX - I;
      PlayerY := BombY;
      for J := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FGamers.Delete(J);
          FMap.Map[PlayerX][PlayerY] := 0;
          SendAllUser;
        end;
      end;
    end
    else if FMap.Map[BombX - I][BombY] = 1 then
    begin
      Break;
    end
    else if FMap.Map[BombX - I][BombY] = 2 then
    begin
      FMap.Map[BombX - I][BombY] := 0;
      SendAllUser;
      Break;
    end;
  end;
  for I := 0 to BoomScope - 1 do
  begin
    Inc(BoomS);
    if (FMap.Map[BombX][BombY + I] <> 0) and (FMap.Map[BombX][BombY + I] = 3) then
    begin
      for J := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FGamers.Delete(J);
          FMap.Map[PlayerX][PlayerY] := 0;
          SendAllUser;
        end;
      end;
    end
    else if FMap.Map[BombX][BombY + I] = 1 then
    begin
      Break;
    end
    else if FMap.Map[BombX][BombY + I] = 2 then
    begin
      FMap.Map[BombX][BombY + I] := 0;
      SendAllUser;
      Break;
    end;
  end;

  for I := 0 to BoomScope - 1 do
  begin
    Inc(BoomW);
    if (FMap.Map[BombX][BombY - I] <> 0) and (FMap.Map[BombX][BombY - I] = 3) then
    begin
      for J := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FGamers.Delete(J);
          FMap.Map[PlayerX][PlayerY] := 0;
          SendAllUser;
        end;
      end;
    end
    else if FMap.Map[BombX][BombY - I] = 1 then
    begin
      Break;
    end
    else if FMap.Map[BombX][BombY - I] = 2 then
    begin
      FMap.Map[BombX][BombY - I] := 0;
      SendAllUser;
      Break;
    end;
  end;

  SendBombEvent(BombX, BombY, BoomW, BoomA, BoomS, BoomD);
end;

procedure TTcpgameserver.ClientRemoved(AClient: TTCPClient);
var
  Idx: Integer;
  DeletedChatter: TGameClient;
begin
  DeletedChatter := FindGamer(AClient);
  if DeletedChatter <> nil then
  begin
    FMap.Map[DeletedChatter.GamerPosX][DeletedChatter.GamerPosY] := 0;
    Idx := FGamers.IndexOfObject(DeletedChatter);
    if Idx >= 0 then
      FGamers.Delete(Idx)
    else
      Exit;
    DeletedChatter.Free;
  end;
  SendAllUser;
end;

constructor TTcpgameserver.Create;
begin
  inherited Create;
  FGamers := TStringList.Create;
  FBombList := TStringList.Create;
  InitGameMap;
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

procedure TTcpgameserver.Execute;
var
  i: Integer;
  nowtimer: TDateTime;
begin
  inherited;
  if FBombList.Count > 0 then
  begin
    for i := 0 to FBombList.Count - 1 do
    begin
      if (nowtimer - (TBOMB(FBombList.Objects[i]).Timer)) = BoomTime then
      begin
        BombEvent(i); //爆炸事件;
      end;
    end;

  end;
end;

function TTcpgameserver.FindGamer(AClient: TTCPClient): TGameClient;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FGamers.Count - 1 do
  begin
    if TGameClient(FGamers.Objects[i]).FClient = AClient then
    begin
      Result := TGameClient(FGamers.Objects[i]);
      break;
    end;
  end;
end;

procedure TTcpgameserver.InitGameMap;
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to MapLength do
  begin
    for J := 0 to MapWide do
    begin
      if (I = 0) or (J = 0) or (I = MapLength) or (J = MapWide) then
      begin
        FMap.Map[I][J] := 1;
      end;
      if (I mod 2 = 0) and (J mod 2 = 0) then
      begin
        FMap.Map[I][J] := 1;
      end;
      if (I = 9) or (J = 9) then
      begin
        FMap.Map[I][J] := 2;
      end
    end;
  end

end;

function TTcpgameserver.LoginUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
var
  AGameer: TGameClient;
  UserName, password, Error: AnsiString;
  sql: AnsiString;
  request: TServerMessage;
begin
  UserName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  password := StrPas(PAnsichar(@(RequestPtr.Password)[0]));
  if FGamers.IndexOf(UserName) = -1 then
  begin
    sql := 'SELECT * from test where username=' + '"' + UserName + '"' + 'and password=' + '"' + password + '";';
    if SQLserver.SetSqlList(sql) = True then
    begin
      Log.Info('用户' + RequestPtr.UserName + '登录');
      AGameer := TGameClient.Create(RequestPtr.UserName, AClient);
      AGameer.FUsername := RequestPtr.UserName;
      SetGamerPos(AGameer);
      FGamers.AddObject(UserName, AGameer);
//      SendAllUser;
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
//  if Result = 0 then
//  begin
//    SendAllUser;
//  end;

end;

function TTcpgameserver.PlayerDead(UserName: AnsiString; PlayerPosX: Integer; PlayerPosY: Integer): Integer;
var
  I: Integer;
  PlayerDeadEvent: TPlayerDeadEvent;
begin
  PlayerDeadEvent.head.Flag := PACK_FLAG;
  PlayerDeadEvent.head.Size := SizeOf(PlayerDeadEvent);
  PlayerDeadEvent.head.Command := S_PlayerDead;
  Move(Pointer(UserName)^, PlayerDeadEvent.UserName, Length(UserName));
  PlayerDeadEvent.PlayerPosX := PlayerPosX;
  PlayerDeadEvent.PlayerPosY := PlayerPosY;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@PlayerDeadEvent, SizeOf(PlayerDeadEvent));
  end;

end;

function TTcpgameserver.PlayerMove(RequestPtr: PPlayerMove; AClient: TTCPClient): Integer;
var
  X, Y: Integer;
  PlayerName: AnsiString;
begin

  PlayerName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  if RequestPtr.MoveType = MOVEUP then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if FMap.Map[X][Y - 1] = 0 then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVEUP);
      FMap.Map[X][Y] := 0;
      FMap.Map[X][Y - 1] := 3;
    end;
  end
  else if RequestPtr.MoveType = MOVEDOWN then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if FMap.Map[X][Y + 1] = 0 then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVEDOWN);
      FMap.Map[X][Y] := 0;
      FMap.Map[X][Y + 1] := 3;
    end;
  end
  else if RequestPtr.MoveType = MOVELEFT then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if FMap.Map[X - 1][Y] = 0 then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVELEFT);
      FMap.Map[X][Y] := 0;
      FMap.Map[X - 1][Y] := 3;
    end;
  end
  else if RequestPtr.MoveType = MOVERIGHT then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if FMap.Map[X + 1][Y] = 0 then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVERIGHT);
      FMap.Map[X][Y] := 0;
      FMap.Map[X + 1][Y] := 3;
    end;
  end;
  SendAllUser;
end;

function TTcpgameserver.PlayerSetBomb(RequestPtr: PPlayerSetBoom; AClient: TTCPClient): Integer;
var
  x: Integer;
  y: Integer;
  ABomb: TBOMB;
begin
  x := TGameClient(FGamers.Objects[FGamers.IndexOf(RequestPtr.PlayerName)]).GamerPosX;
  y := TGameClient(FGamers.Objects[FGamers.IndexOf(RequestPtr.PlayerName)]).GamerPosY;
  ABomb := TBOMB.Create(x, y);
  ABomb.BombID := FBombList.Count;
  FBombList.AddObject(IntToStr(ABomb.BombID), ABomb);
  FMap.Map[x][y] := 4;
  SendAllUser;
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

      if (BufSize >= SizeOf(TGameMsgHead)) and (PGameMsgHead(BufPtr)^.Size <= BufSize) then
      begin
        FetchSize := FetchSize + PGameMsgHead(BufPtr)^.Size;
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
    C_MAP:
      begin
        SendAllUser;
      end;
    C_MOVE:
      begin
        PlayerMove(PPlayerMove(RequestPtr), AClient);
      end;
    C_BOOM:
      begin
        PlayerSetBomb(PPlayerSetBoom(RequestPtr), AClient);
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

function TTcpgameserver.SendBombEvent(BombX: Integer; BombY: Integer; BoomW: Integer; BoomA: Integer; BoomS: Integer; BoomD: Integer): Integer;
var
  I: integer;
  BombEvent: TBombBoom;
begin
  for I := 0 to FGamers.Count - 1 do
  begin
    BombEvent.head.Flag := PACK_FLAG;
    BombEvent.head.Size := SizeOf(BombEvent);
    BombEvent.head.Command := S_BOMBBOOM;
    BombEvent.Bombx := BombX;
    BombEvent.BombY := BombY;
    TGameClient(FGamers.Objects[I]).FClient.SendData(@BombEvent, SizeOf(BombEvent));
  end;

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

procedure TGameClient.ChangeGamerPos(ChangeType: MoveDirect);
begin
  if ChangeType = MOVEUP then
  begin
    GamerPosY := GamerPosY - 1;
  end
  else if ChangeType = MOVEDOWN then
  begin
    GamerPosY := GamerPosY + 1;
  end
  else if ChangeType = MOVELEFT then
  begin
    GamerPosX := GamerPosX - 1;
  end
  else if ChangeType = MOVERIGHT then
  begin
    GamerPosX := GamerPosX + 1;
  end;
end;

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


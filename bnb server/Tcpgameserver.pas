unit Tcpgameserver;

interface

uses
  Tcpserver, System.Classes, GameProtocol, System.SysUtils, LogServer,
  GameSqlServer, System.Math, DateUtils;

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
    ShoseTime: TDateTime;
    ShoseNum: Integer;
  public
    FMap: TMap;
    FUserList: TPlayerInfoList;
    procedure ProcessRequests(RequestPtr: PLoginMsg; AClient: TTCPClient);
    constructor Create;
    destructor Destroy; override;
  protected
    procedure Execute; override;
    procedure ProcessClientIO(AClient: TTCPClient); override;
    procedure ClientRemoved(AClient: TTCPClient); override;
    procedure CheckBombTime; override;
    procedure SetShoesProp; override;
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

    if FMap.Map[BombX + I][BombY] = 3 then
    begin
      PlayerX := BombX + I;
      PlayerY := BombY;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FClients.Delete(J);
          ClientRemoved(TGameClient(FGamers.Objects[J]).FClient);
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
    Inc(BoomD);
  end;
  for I := 0 to BoomScope - 1 do
  begin
    if FMap.Map[BombX - I][BombY] = 3 then
    begin
      PlayerX := BombX - I;
      PlayerY := BombY;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FClients.Delete(J);
          ClientRemoved(TGameClient(FGamers.Objects[J]).FClient);
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
    Inc(BoomA);
  end;
  for I := 0 to BoomScope - 1 do
  begin

    if FMap.Map[BombX][BombY + I] = 3 then
    begin
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FClients.Delete(J);
          ClientRemoved(TGameClient(FGamers.Objects[J]).FClient);
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
    Inc(BoomS);
  end;

  for I := 0 to BoomScope - 1 do
  begin

    if FMap.Map[BombX][BombY - I] = 3 then
    begin
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FClients.Delete(J);
          ClientRemoved(TGameClient(FGamers.Objects[J]).FClient);
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
    Inc(BoomW);
  end;
  SendBombEvent(BombX, BombY, BoomW, BoomA, BoomS, BoomD);
  FMap.Map[BombX][BombY] := 0;
  SendAllUser;
end;

procedure TTcpgameserver.CheckBombTime;
var
  i: Integer;
  nowtimer: TDateTime;
begin
  inherited;
  if FBombList.Count > 0 then
  begin
    for i := FBombList.Count - 1 downto 0 do
    begin
      nowtimer := Now;
      if SecondsBetween(nowtimer, (TBOMB(FBombList.Objects[i]).Timer)) = BoomTime then
      begin
        Log.Info(Format('炸弹 %d 爆炸', [i]));
        BombEvent(i); //爆炸事件;
        FBombList.Delete(i);
      end;
    end;
  end;

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
begin
  inherited;

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
  if (FGamers.IndexOf(UserName) = -1) and (FGamers.Count < 5) then
  begin
    sql := 'SELECT * from test where username=' + '"' + UserName + '"' + 'and password=' + '"' + password + '";';
    if SQLserver.SetSqlList(sql) = True then
    begin
      Log.Info('用户' + RequestPtr.UserName + '登录');
      AGameer := TGameClient.Create(RequestPtr.UserName, AClient);
      AGameer.FUsername := RequestPtr.UserName;
      SetGamerPos(AGameer);
      FGamers.AddObject(UserName, AGameer);
      Result := 0;
      FUserList.UserList[FGamers.Count - 1].UserID := FGamers.Count - 1;
      StrPCopy(FUserList.UserList[FGamers.Count - 1].UserName, UserName);
      FUserList.UserList[FGamers.Count - 1].UserPosX := AGameer.GamerPosX;
      FUserList.UserList[FGamers.Count - 1].UserPosY := AGameer.GamerPosY;
    end
    else
    begin
      Log.Error('用户名或密码错误！');
      Result := 1;
    end;
  end
  else if (FGamers.Count > 5) then
  begin
    Log.Error('用户已达上限！');
    Result := 2;
  end
  else
  begin
    Log.Error('用户已经在线！');
    Result := 3;
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
    Error := '用户已达上限';
    StrLCopy(@request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end
  else if Result = 3 then
  begin
    Error := '用户已经在线';
    StrLCopy(@request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end;

  AClient.SendData(@request, SizeOf(request));
//  if Result = 0 then
//  begin
//    SendAllUser;
//  end;
  ShoseTime := Now;
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
  X, Y, I: Integer;
  PlayerName, ListPlayerName: AnsiString;
begin
  PlayerName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  if RequestPtr.MoveType = MOVEUP then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if (FMap.Map[X][Y - 1] = 0) or (FMap.Map[X][Y - 1] = 5) then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVEUP);
      if FMap.Map[X][Y] <> 4 then
      begin
        FMap.Map[X][Y] := 0;
      end;
      for I := 0 to FGamers.Count - 1 do
      begin
        ListPlayerName := StrPas(PAnsichar(@(FUserList.UserList[I].UserName)[0]));
        if (ListPlayerName = PlayerName) then
        begin
          if FUserList.UserList[I].FaceTo <> NORTH then
          begin
            FUserList.UserList[I].FaceTo := NORTH;
          end;
          FUserList.UserList[I].UserPosX := X;
          FuserList.UserList[I].UserPosY := Y - 1;
          if FMap.Map[X][Y - 1] = 5 then
          begin
            FUserList.UserList[I].Speed := FUserList.UserList[I].Speed + 1;
            Dec(ShoseNum); 
          end;
        end;
      end;
      FMap.Map[X][Y - 1] := 3;
      Log.Info(Format('玩家 %s 向北移动', [PlayerName]));
    end;
  end
  else if RequestPtr.MoveType = MOVEDOWN then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if (FMap.Map[X][Y + 1] = 0) or (FMap.Map[X][Y + 1] = 5) then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVEDOWN);
      if FMap.Map[X][Y] <> 4 then
      begin
        FMap.Map[X][Y] := 0;
      end;

      for I := 0 to FGamers.Count - 1 do
      begin
        ListPlayerName := StrPas(PAnsichar(@(FUserList.UserList[I].UserName)[0]));
        if (ListPlayerName = PlayerName) then
        begin
          if FUserList.UserList[I].FaceTo <> SOUTH then
          begin
            FUserList.UserList[I].FaceTo := SOUTH;
          end;
          FUserList.UserList[I].UserPosX := X;
          FuserList.UserList[I].UserPosY := Y + 1;
          if FMap.Map[X][Y + 1] = 5 then
          begin
            FUserList.UserList[I].Speed := FUserList.UserList[I].Speed + 1;
            Dec(ShoseNum);
          end;
        end;
      end;
      FMap.Map[X][Y + 1] := 3;
      Log.Info(Format('玩家 %s 向南移动', [PlayerName]));
    end;
  end
  else if RequestPtr.MoveType = MOVELEFT then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if (FMap.Map[X - 1][Y] = 0) or (FMap.Map[X - 1][Y] = 5) then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVELEFT);
      if FMap.Map[X][Y] <> 4 then
      begin
        FMap.Map[X][Y] := 0;
      end;
      for I := 0 to FGamers.Count - 1 do
      begin
        ListPlayerName := StrPas(PAnsichar(@(FUserList.UserList[I].UserName)[0]));
        if (ListPlayerName = PlayerName) then
        begin
          if FUserList.UserList[I].FaceTo <> WEST then
          begin
            FUserList.UserList[I].FaceTo := WEST;
          end;
          FUserList.UserList[I].UserPosX := X - 1;
          FuserList.UserList[I].UserPosY := Y;
          if FMap.Map[X - 1][Y] = 5 then
          begin
            FUserList.UserList[I].Speed := FUserList.UserList[I].Speed + 1;
            Dec(ShoseNum);
          end;
        end;
      end;
      FMap.Map[X - 1][Y] := 3;
      Log.Info(Format('玩家 %s 向西移动', [PlayerName]));
    end;
  end
  else if RequestPtr.MoveType = MOVERIGHT then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if (FMap.Map[X + 1][Y] = 0) or (FMap.Map[X + 1][Y] = 5) then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVERIGHT);
      if FMap.Map[X][Y] <> 4 then
      begin
        FMap.Map[X][Y] := 0;
      end;
      for I := 0 to FGamers.Count - 1 do
      begin
        ListPlayerName := StrPas(PAnsichar(@(FUserList.UserList[I].UserName)[0]));
        if (ListPlayerName = PlayerName) then
        begin
          if FUserList.UserList[I].FaceTo <> EAST then
          begin
            FUserList.UserList[I].FaceTo := EAST;
          end;
          FUserList.UserList[I].UserPosX := X + 1;
          FuserList.UserList[I].UserPosY := Y;
          if FMap.Map[X + 1][Y] = 5 then
          begin
            FUserList.UserList[I].Speed := FUserList.UserList[I].Speed + 1;
            Dec(ShoseNum);
          end;

        end;
      end;
      FMap.Map[X + 1][Y] := 3;
      Log.Info(Format('玩家 %s 向东移动', [PlayerName]));
    end;
  end;
  SendAllUser;
end;

function TTcpgameserver.PlayerSetBomb(RequestPtr: PPlayerSetBoom; AClient: TTCPClient): Integer;
var
  x: Integer;
  y: Integer;
  ABomb: TBOMB;
  PlayerName: AnsiString;
begin
  PlayerName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  x := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
  y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
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

    FUserList.head.Flag := PACK_FLAG;
    FUserList.head.Size := SizeOf(FUserList);
    FUserList.head.Command := S_USERLIST;

    TGameClient(FGamers.Objects[i]).FClient.SendData(@Fmap, SizeOf(FMap));
    TGameClient(FGamers.Objects[i]).FClient.SendData(@FUserList, SizeOf(FUserList));
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

procedure TTcpgameserver.SetShoesProp;
var
  X, Y: Integer;
  Prevtime: TDateTime;
  NowTime: TDateTime;
  PosTime: TDateTime;
begin
  inherited;
  NowTime := Now;
  if SecondsBetween(NowTime, ShoseTime) = 15 then
  begin
    repeat
      X := randomrange(0, 9);
      Y := RandomRange(0, 9);
    until FMap.Map[X][Y] = 0;
    if ShoseNum < 7 then
    begin
      FMap.Map[X][Y] := 5;
      SendAllUser;
      Inc(ShoseNum);
    end;
    ShoseTime := NowTime;
  end;
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


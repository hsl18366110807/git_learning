unit Tcpgameserver;

interface

uses
  Tcpserver, System.Classes, GameProtocol, System.SysUtils, LogServer,
  GameSqlServer, System.Math, DateUtils, Winapi.Windows, Vcl.ExtCtrls;

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
    FDeadGamers: TStrings;
    FGamers: TStrings;
    FBots: TStrings;
    FBombList: TStrings;
    FMoveUserList: TStrings;
    ShoseTime: TDateTime;
    ShoseNum: Integer;
  public
    FMap: TMap;
    FUserList: TPlayerInfoList;
    FBotList: TRoBotInfoList;
    procedure ProcessRequests(RequestPtr: PLoginMsg; AClient: TTCPClient);
    constructor Create;
    destructor Destroy; override;
  protected
    procedure Execute; override;
    procedure ProcessClientIO(AClient: TTCPClient); override;
    procedure ClientRemoved(AClient: TTCPClient); override;
    procedure CheckBombTime; override;
    procedure SetShoesProp; override;
    procedure SendMoveMessage; override;
  private
    timer: TTimer;
    procedure ControlBots(Sender: TObject);
    procedure BotMove(BotId: Integer);
    procedure DeleteUserList(Pos: Integer);
    function FindGamer(AClient: TTCPClient): TGameClient;
    function FindDeadGamer(AClient: TTCPClient): TGameClient;
    procedure InitGameMap;
    procedure InitBot;
    procedure SetGamerPos(AGamer: TGameClient);
    function RegisterNewUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
    function LoginUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
    function AddMoveUser(RequestPtr: PPlayerMove; AClient: TTCPClient): Integer;
    function PlayerMove(FMovePlayer: TMovePlayer): Integer;
    function RemoveUser(RequestPtr: PPlayerStopMove; AClient: TTCPClient): Integer;
    function PlayerSetBomb(RequestPtr: PPlayerSetBoom; AClient: TTCPClient): Integer;
    function PlayerUseProp(RequestPtr: PUseProp; AClient: TTCPClient): Integer;
    function BombEvent(BomePos: Integer): Integer;
    function SendMap: Integer;
    function SendPlayerInfo(PlayerName: AnsiString): Integer;
    function SendPlayerMoveInfo(PlayerName: AnsiString): Integer;
    function SendSetBombInfo(BombX, BombY: Integer): Integer;
    function SendBombEvent(BombX: Integer; BombY: Integer; BoomW: Integer; BoomA: Integer; BoomS: Integer; BoomD: Integer; PosArray: Pointer): Integer;
    function PlayerDead(UserName: AnsiString; PlayerPosX: Integer; PlayerPosY: Integer): Integer;
    function SendShoesPos(x, y: Integer): Integer;
    function SendPlaverLeave(PlayerName: AnsiString): Integer;
    function FindKillerPlayerMelee(RequestPtr: PUseProp): Integer;
    function FindKillerPlayerRanged(RequestPtr: PUseProp): Integer;
    function SendRangedPropInfo(PropPosX: Integer; PropPosY: Integer; DestoryPos: DestoryTypes): Integer;
    function SendBotInfo(BotID: Integer; PosX: Integer; PosY: Integer; FaceTo: Integer): Integer;
    function SendBotMove(BotID, PosX, PosY, faceto: Integer): Integer;
    function CheckAndRemoveList(PlayerName: AnsiString): Integer;
  end;

var
  FTcpgameserver: TTcpgameserver;

implementation


{ TTcpgameserver }

function TTcpgameserver.AddMoveUser(RequestPtr: PPlayerMove; AClient: TTCPClient): Integer;
var
  playername: AnsiString;
  FMovePlayer: TMovePlayer;
  MovePlayerSpeed: Integer;
begin
  FMovePlayer := TMovePlayer.Create;
  playername := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  MovePlayerSpeed := FUserList.UserList[FGamers.IndexOf(playername)].Speed;
  FMovePlayer.MoveSpeed := MovePlayerSpeed;
  FMovePlayer.UserName := playername;
  FMovePlayer.Timer := GetTickCount;
  FMovePlayer.MoveType := RequestPtr.MoveType;
//  PlayerMove(FMovePlayer);
  FMoveUserList.AddObject(playername, FMovePlayer);
end;

function TTcpgameserver.BombEvent(BomePos: Integer): Integer;
var
  BombX, BombY, PlayerX, PlayerY, I, J, Z: Integer;
  BoomW, BoomA, BoomD, BoomS: Integer;
  DestoryPos: array[0..3, 0..1] of Integer;
begin
  fillchar(DestoryPos, sizeof(DestoryPos), -1);
  BombX := TBomb(FBombList.Objects[BomePos]).FBombPosX;
  BombY := TBomb(FBombList.Objects[BomePos]).FBombPosY;

  for Z := 0 to FGamers.Count - 1 do
  begin
    if (BombX = TGameClient(FGamers.Objects[Z]).GamerPosX) and (BombY = TGameClient(FGamers.Objects[Z]).GamerPosY) then
    begin
      PlayerX := BombX + I;
      PlayerY := BombY;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          DeleteUserList(J);
        end;
      end;
    end;
  end;

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
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          DeleteUserList(J);
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
      DestoryPos[0][0] := BombX + I;
      DestoryPos[0][1] := BombY;
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
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          DeleteUserList(J);
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
      DestoryPos[1][0] := BombX - I;
      DestoryPos[1][1] := BombY;
      Break;
    end;
    Inc(BoomA);
  end;
  for I := 0 to BoomScope - 1 do
  begin

    if FMap.Map[BombX][BombY + I] = 3 then
    begin
      PlayerX := BombX;
      PlayerY := BombY + I;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          DeleteUserList(J);
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
      DestoryPos[2][0] := BombX;
      DestoryPos[2][1] := BombY + I;
      Break;
    end;
    Inc(BoomS);
  end;

  for I := 0 to BoomScope - 1 do
  begin

    if FMap.Map[BombX][BombY - I] = 3 then
    begin
      PlayerX := BombX;
      PlayerY := BombY - I;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          DeleteUserList(J);
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
      DestoryPos[3][0] := BombX;
      DestoryPos[3][1] := BombY - I;
      Break;
    end;
    Inc(BoomW);
  end;
  Log.Info(Format('爆炸范围-> W:%d, A:%d, S:%d, D:%d', [BoomW, BoomA, BoomS, BoomD]));
  SendBombEvent(BombX, BombY, BoomW, BoomA, BoomS, BoomD, @DestoryPos);
  FMap.Map[BombX][BombY] := 0;
end;

procedure TTcpgameserver.ControlBots(Sender: TObject);
var
  I: Integer;
  PosX, PosY, FaceTo, BotID: Integer;
begin
  if FBotList.BotNums <> 0 then
  begin
    for I := 0 to FBotList.BotNums do
    begin
      BotMove(FBotList.BotNums);
    end;
  end;
  if FBotList.BotNums <> 0 then
  begin
    for I := 0 to FBotList.BotNums do
    begin
      SendBotMove(FBotList.BotList[FBotList.BotNums - 1].RoBotID, FBotList.BotList[FBotList.BotNums - 1].BotPosX, FBotList.BotList[FBotList.BotNums - 1].BotPosY, FBotList.BotList[FBotList.BotNums - 1].BotFaceTo);
    end;
  end;

end;

procedure TTcpgameserver.BotMove(BotId: Integer);
var
  PosX, PosY, I: Integer;
begin
  PosX := FBotList.BotList[BotId - 1].BotPosX;
  PosY := FBotList.BotList[BotId - 1].BotPosY;
  if FBotList.BotList[BotId - 1].BotFaceTo = 0 then
  begin
    if FMap.Map[PosX][PosY - 1] = 0 then
    begin
      FBotList.BotList[BotId - 1].BotPosY := PosY - 1;
    end
    else if FMap.Map[PosX][PosY - 1] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosy = PosY - 1) then
        begin
          Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY - 1);
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          DeleteUserList(I);
        end;

      end;
    end
    else
    begin
      FBotList.BotList[BotId - 1].BotFaceTo := RandomRange(0, 3);
    end;
    Exit;
  end
  else if FBotList.BotList[BotId - 1].BotFaceTo = 1 then
  begin
    if FMap.Map[PosX][PosY + 1] = 0 then
    begin
      FBotList.BotList[BotId - 1].BotPosY := PosY + 1;
    end
    else if FMap.Map[PosX][PosY + 1] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosy = PosY + 1) then
        begin
          Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY + 1);
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          DeleteUserList(I);
        end;
      end;
    end
    else
    begin
      FBotList.BotList[BotId - 1].BotFaceTo := RandomRange(0, 3);
    end;
    Exit;
  end
  else if FBotList.BotList[BotId - 1].BotFaceTo = 2 then
  begin
    if FMap.Map[PosX - 1][PosY] = 0 then
    begin
      FBotList.BotList[BotId - 1].BotPosX := PosX - 1;
    end
    else if FMap.Map[PosX - 1][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX - 1) and (TGameClient(FGamers.Objects[I]).GamerPosy = PosY) then
        begin
          Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX - 1, PosY);
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          DeleteUserList(I);
        end;
      end;
    end
    else
    begin
      FBotList.BotList[BotId - 1].BotFaceTo := RandomRange(0, 3);
    end;
    Exit;
  end
  else if FBotList.BotList[BotId - 1].BotFaceTo = 3 then
  begin
    if FMap.Map[PosX + 1][PosY] = 0 then
    begin
      FBotList.BotList[BotId - 1].BotPosX := PosX + 1;
    end
    else if FMap.Map[PosX + 1][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX + 1) and (TGameClient(FGamers.Objects[I]).GamerPosy = PosY) then
        begin
          Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX + 1, PosY);
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          DeleteUserList(I);
        end;
      end;
    end
    else
    begin
      FBotList.BotList[BotId - 1].BotFaceTo := RandomRange(0, 3);
    end;
    Exit;
  end;
end;

function TTcpgameserver.CheckAndRemoveList(PlayerName: AnsiString): Integer;
begin
  if FMoveUserList.IndexOf(PlayerName) <> -1 then
  begin
    FMoveUserList.Delete(FMoveUserList.IndexOf(PlayerName));
  end;
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
  DeletedDeadChatter: TGameClient;
  I: Integer;
begin
  DeletedChatter := FindGamer(AClient);
  DeletedDeadChatter := FindDeadGamer(AClient);

  if DeletedChatter <> nil then
  begin
    FMap.Map[DeletedChatter.GamerPosX][DeletedChatter.GamerPosY] := 0;
    Idx := FGamers.IndexOfObject(DeletedChatter);
    if Idx >= 0 then
    begin
      FGamers.Delete(Idx);
      DeleteUserList(Idx);
    end
    else
    begin
      if DeletedDeadChatter <> nil then
      begin
        FMap.Map[DeletedDeadChatter.GamerPosX][DeletedDeadChatter.GamerPosY] := 0;
        Idx := FGamers.IndexOfObject(DeletedDeadChatter);
        if Idx >= 0 then
        begin
          if FMoveUserList.Count <> 0 then
          begin
            CheckAndRemoveList(TGameClient(FGamers.Objects[Idx]).FUsername);
          end;
          FDeadGamers.Delete(Idx);
          DeleteUserList(Idx);
        end
        else
        begin
          Exit;
        end;
        DeletedChatter.Free;
      end;
      Exit;
    end;
    DeletedChatter.Free;
  end;
end;

constructor TTcpgameserver.Create;
begin
  inherited Create;
  FGamers := TStringList.Create;
  FBombList := TStringList.Create;
  FDeadGamers := TStringList.Create;
  FMoveUserList := TStringList.Create;
  InitGameMap;
  timer := TTimer.Create(timer);
  timer.OnTimer := ControlBots;
<<<<<<< Updated upstream
  timer.Enabled := False;
  timer.Interval := 800;
  timer.Enabled := False;
=======
<<<<<<< Updated upstream
  timer.Interval := 100;
//  timer.Enabled := False;
=======
  timer.Interval := 8000;
  timer.Enabled := False;
>>>>>>> Stashed changes
>>>>>>> Stashed changes
end;

procedure TTcpgameserver.DeleteUserList(Pos: Integer);
var
  i: Integer;
begin
  for i := Pos to Length(FUserList.UserList) - 1 do
  begin
    FUserList.UserList[Pos] := FUserList.UserList[Pos + 1];
    FillMemory(@(FUserList.UserList[Pos + 1]), SizeOf(FUserList.UserList[Pos + 1]), 0);
  end;
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

function TTcpgameserver.FindDeadGamer(AClient: TTCPClient): TGameClient;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FDeadGamers.Count - 1 do
  begin
    if TGameClient(FDeadGamers.Objects[i]).FClient = AClient then
    begin
      Result := TGameClient(FDeadGamers.Objects[i]);
      break;
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

function TTcpgameserver.FindKillerPlayerMelee(RequestPtr: PUseProp): Integer;
var
  UserName: AnsiString;
  UserNumber: Integer;
  PosX, PosY, I: Integer;
begin
  UserName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  UserNumber := FGamers.IndexOf(UserName);
  if FUserList.UserList[UserNumber].FaceTo = NORTH then
  begin
    PosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY + 1;
    PosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX;
    if FMap.Map[PosX][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosY = PosY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY);
          Log.Info(Format('玩家 %s 被砍死', [TGameClient(FGamers.Objects[I]).FUsername]));
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          FGamers.Delete(I);
          DeleteUserList(I);
        end;
      end;
    end;
  end
  else if FUserList.UserList[UserNumber].FaceTo = SOUTH then
  begin
    PosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY - 1;
    PosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX;
    if FMap.Map[PosX][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosY = PosY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY);
          Log.Info(Format('玩家 %s 被砍死', [TGameClient(FGamers.Objects[I]).FUsername]));
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          FGamers.Delete(I);
          DeleteUserList(I);
        end;
      end;
    end;
  end
  else if FUserList.UserList[UserNumber].FaceTo = WEST then
  begin
    PosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY;
    PosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX - 1;
    if FMap.Map[PosX][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosY = PosY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY);
          Log.Info(Format('玩家 %s 被砍死', [TGameClient(FGamers.Objects[I]).FUsername]));
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          FGamers.Delete(I);
          DeleteUserList(I);
        end;
      end;
    end;
  end
  else if FUserList.UserList[UserNumber].FaceTo = EAST then
  begin
    PosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY;
    PosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX + 1;
    if FMap.Map[PosX][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosY = PosY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY);
          Log.Info(Format('玩家 %s 被砍死', [TGameClient(FGamers.Objects[I]).FUsername]));
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          FGamers.Delete(I);
          DeleteUserList(I);
        end;
      end;
    end;
  end;
end;

function TTcpgameserver.FindKillerPlayerRanged(RequestPtr: PUseProp): Integer;
var
  UserName: AnsiString;
  UserNumber: Integer;
  PosX, PosY, PropPosX, PropPosY, I: Integer;
begin
  UserName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  UserNumber := FGamers.IndexOf(UserName);
  PropPosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX;
  PropPosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY;
  if FUserList.UserList[UserNumber].FaceTo = NORTH then
  begin
    for I := PropPosY - 1 downto 0 do
    begin
      if FMap.Map[PropPosX][I] = 0 then
      begin
        Dec(PropPosY);
      end
      else if FMap.Map[PropPosX][I] = 1 then   //碰撞墙壁
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Block);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 2 then   //碰撞木箱
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Box);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 3 then   //碰撞人物
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Player);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 4 then    //碰撞炸弹
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Bomb);
        Exit;
      end;
    end;
    SendRangedPropInfo(PropPosX, PropPosY, NoDestory);
  end
  else if FUserList.UserList[UserNumber].FaceTo = SOUTH then
  begin
    for I := PropPosY + 1 to 19 do
    begin
      if FMap.Map[PropPosX][I] = 0 then
      begin
        Inc(PropPosY);
      end
      else if FMap.Map[PropPosX][I] = 1 then   //碰撞墙壁
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Block);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 2 then   //碰撞木箱
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Box);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 3 then   //碰撞人物
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Player);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 4 then    //碰撞炸弹
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Bomb);
        Exit;
      end;
    end;
    SendRangedPropInfo(PropPosX, PropPosY, NoDestory);
  end
  else if FUserList.UserList[UserNumber].FaceTo = WEST then
  begin
    for I := PropPosX - 1 downto 0 do
    begin
      if FMap.Map[I][PropPosY] = 0 then
      begin
        Dec(PropPosX);
      end
      else if FMap.Map[I][PropPosY] = 1 then   //碰撞墙壁
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Block);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 2 then   //碰撞木箱
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Box);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 3 then   //碰撞人物
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Player);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 4 then    //碰撞炸弹
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Bomb);
        Exit;
      end;
    end;
    SendRangedPropInfo(PropPosX, PropPosY, NoDestory);
  end
  else if FUserList.UserList[UserNumber].FaceTo = EAST then
  begin
    for I := PropPosX + 1 to 19 do
    begin
      if FMap.Map[I][PropPosY] = 0 then
      begin
        Inc(PropPosX);
      end
      else if FMap.Map[I][PropPosY] = 1 then   //碰撞墙壁
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Block);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 2 then   //碰撞木箱
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Box);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 3 then   //碰撞人物
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Player);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 4 then    //碰撞炸弹
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Bomb);
        Exit;
      end;
    end;
    SendRangedPropInfo(PropPosX, PropPosY, NoDestory);
  end;
end;

procedure TTcpgameserver.InitBot;
var
  X, Y: Integer;
  Faceto: Integer;
begin
  repeat
    X := randomrange(0, 19);
    Y := RandomRange(0, 19);
  until FMap.Map[X][Y] = 0;
  Faceto := randomrange(0, 3);
  FBotList.BotList[FBotList.BotNums].RoBotID := FBotList.BotNums + 1;
  FBotList.BotList[FBotList.BotNums].BotPosX := X;
  FBotList.BotList[FBotList.BotNums].BotPosY := Y;
  FBotList.BotList[FBotList.BotNums].BotFaceTo := Faceto;
  Inc(FBotList.BotNums);

  FMap.Map[X][Y] := 6;
  SendBotInfo(FBotList.BotList[FBotList.BotNums].RoBotID, X, Y, Faceto);
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
  UserInfo: TPlayerInfo;
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
      FUserList.UserList[FGamers.Count - 1].UserID := FGamers.Count;
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
  if Result = 0 then
  begin
    SendPlayerInfo(UserName);
  end;
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
  FillMemory(@PlayerDeadEvent.UserName, Length(PlayerDeadEvent.UserName), 0);
  Move(Pointer(UserName)^, PlayerDeadEvent.UserName, Length(UserName));
  PlayerDeadEvent.PlayerPosX := PlayerPosX;
  PlayerDeadEvent.PlayerPosY := PlayerPosY;
  FMap.Map[PlayerPosX][PlayerPosY] := 0;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@PlayerDeadEvent, SizeOf(PlayerDeadEvent));
  end;

end;

function TTcpgameserver.PlayerMove(FMovePlayer: TMovePlayer): Integer;
var
  X, Y, I: Integer;
  PlayerName, ListPlayerName: AnsiString;
  SpeedToMove: Integer;
begin
  PlayerName := FMovePlayer.UserName;
  if FDeadGamers.IndexOf(PlayerName) <> -1 then
  begin
    Exit;
  end;
  SpeedToMove := FUserList.UserList[FGamers.IndexOf(PlayerName)].Speed + 1;
  if FMovePlayer.MoveType = MOVEUP then
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
            Log.Info(Format('玩家%s获得道具鞋子，速度变为%d', [PlayerName, FUserList.UserList[I].Speed]));
            Dec(ShoseNum);
          end;
        end;
      end;
      FMap.Map[X][Y - 1] := 3;
      Log.Info(Format('玩家 %s 向北移动,当前坐标(%d, %d)', [PlayerName, X, Y - 1]));
    end
    else if FMap.Map[X][Y - 1] = 6 then
    begin
      Log.Info(Format('玩家: %s 被怪物杀死', [PlayerName]));
      PlayerDead(PlayerName, X, Y - 1);
      FDeadGamers.AddObject(PlayerName, TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]));
      DeleteUserList(FGamers.IndexOf(PlayerName));
      Exit;
    end;
  end
  else if FMovePlayer.MoveType = MOVEDOWN then
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
            Log.Info(Format('玩家%s获得道具鞋子，速度变为%d', [PlayerName, FUserList.UserList[I].Speed]));
            Dec(ShoseNum);
          end;
        end;
      end;
      FMap.Map[X][Y + 1] := 3;
      Log.Info(Format('玩家 %s 向南移动,当前坐标(%d, %d)', [PlayerName, X, Y + 1]));
    end
    else if FMap.Map[X][Y + 1] = 6 then
    begin
      Log.Info(Format('玩家: %s 被怪物杀死', [PlayerName]));
      PlayerDead(PlayerName, X, Y + 1);
      FDeadGamers.AddObject(PlayerName, TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]));
      DeleteUserList(FGamers.IndexOf(PlayerName));
      Exit;
    end;
  end
  else if FMovePlayer.MoveType = MOVELEFT then
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
            Log.Info(Format('玩家%s获得道具鞋子，速度变为%d', [PlayerName, FUserList.UserList[I].Speed]));
            Dec(ShoseNum);
          end;
        end;
      end;
      FMap.Map[X - 1][Y] := 3;
      Log.Info(Format('玩家 %s 向西移动,当前坐标(%d, %d)', [PlayerName, X - 1, Y]));
    end
    else if FMap.Map[X - 1][Y] = 6 then
    begin
      Log.Info(Format('玩家: %s 被怪物杀死', [PlayerName]));
      PlayerDead(PlayerName, X - 1, Y);
      FDeadGamers.AddObject(PlayerName, TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]));
      DeleteUserList(FGamers.IndexOf(PlayerName));
      Exit;
    end;
  end
  else if FMovePlayer.MoveType = MOVERIGHT then
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
            Log.Info(Format('玩家%s获得道具鞋子，速度变为%d', [PlayerName, FUserList.UserList[I].Speed]));
            Dec(ShoseNum);
          end;

        end;
      end;
      FMap.Map[X + 1][Y] := 3;
      Log.Info(Format('玩家 %s 向东移动,当前坐标(%d, %d)', [PlayerName, X + 1, Y]));
    end
    else if FMap.Map[X + 1][Y] = 6 then
    begin
      Log.Info(Format('玩家: %s 被怪物杀死', [PlayerName]));
      PlayerDead(PlayerName, X + 1, Y);
      FDeadGamers.AddObject(PlayerName, TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]));
      DeleteUserList(FGamers.IndexOf(PlayerName));
      Exit;
    end;
  end;
  SendPlayerMoveInfo(PlayerName);
end;

function TTcpgameserver.PlayerSetBomb(RequestPtr: PPlayerSetBoom; AClient: TTCPClient): Integer;
var
  x: Integer;
  y: Integer;
  ABomb: TBOMB;
  PlayerName: AnsiString;
begin
  PlayerName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  if FDeadGamers.IndexOf(PlayerName) <> -1 then
  begin
    Exit;
  end;
  x := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
  y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
  if FMap.Map[x][y] <> 4 then
  begin
    ABomb := TBOMB.Create(x, y);
    ABomb.BombID := FBombList.Count;
    FBombList.AddObject(IntToStr(ABomb.BombID), ABomb);
    FMap.Map[x][y] := 4;
    SendSetBombInfo(x, y);
  end;
end;

function TTcpgameserver.PlayerUseProp(RequestPtr: PUseProp; AClient: TTCPClient): Integer;
begin
  case RequestPtr.PropType of
    NoProp:
      begin
        Exit;
      end;
    MeleeWeapon:
      begin
        FindKillerPlayerMelee(RequestPtr);
      end;
    RangedWeapon:
      begin
        FindKillerPlayerRanged(RequestPtr);
      end
  end;
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
var
  nowtime: TDateTime;
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
        SendMap;
      end;
    C_MOVE:
      begin

        AddMoveUser(PPlayerMove(RequestPtr), AClient);
      end;
    C_STOPMOVE:
      begin
        RemoveUser(PPlayerStopMove(RequestPtr), AClient);
      end;
    C_BOOM:
      begin
        PlayerSetBomb(PPlayerSetBoom(RequestPtr), AClient);
      end;
    C_USEPROP:
      begin
        PlayerUseProp(PUseProp(RequestPtr), AClient);
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

function TTcpgameserver.RemoveUser(RequestPtr: PPlayerStopMove; AClient: TTCPClient): Integer;
var
  PlayerName: AnsiString;
begin
  PlayerName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  if FMoveUserList.Count > 0 then
    FMoveUserList.Delete(FMoveUserList.IndexOf(PlayerName));
end;

function TTcpgameserver.SendMap: Integer;
var
  UserName: AnsiString;
  i: integer;
begin
  FMap.head.Flag := PACK_FLAG;
  FMap.head.Size := SizeOf(FMap);
  FMap.head.Command := S_MAP;
  FUserList.head.Flag := PACK_FLAG;
  FUserList.head.Size := SizeOf(FUserList);
  FUserList.head.Command := S_USERLIST;
  TGameClient(FGamers.Objects[FGamers.Count - 1]).FClient.SendData(@Fmap, SizeOf(FMap));
  TGameClient(FGamers.Objects[FGamers.Count - 1]).FClient.SendData(@FUserList, SizeOf(FUserList));
//  InitBot;
//  timer.Enabled := True;
  Result := 0;
end;

procedure TTcpgameserver.SendMoveMessage;
var
  I: Integer;
  nowtime: Int64;
  lasttime: TDate;
begin
  if FMoveUserList.Count > 0 then
  begin
    nowtime := GetTickCount;
    for I := 0 to FMoveUserList.Count - 1 do
    begin
      if (nowtime - TMovePlayer(FMoveUserList.Objects[I]).Timer) > (2000 div (4 + TMovePlayer(FMoveUserList.Objects[I]).MoveSpeed)) then
      begin
        PlayerMove(TMovePlayer(FMoveUserList.Objects[I]));
        Log.Info('move');
        TMovePlayer(FMoveUserList.Objects[I]).Timer := nowtime;
      end;
    end;
  end;
end;

function TTcpgameserver.SendPlaverLeave(PlayerName: AnsiString): Integer;
var
  FPlayerLeave: TPlayerLeave;
  I: Integer;
begin
  for I := 0 to FGamers.Count - 1 do
  begin
    FPlayerLeave.head.Flag := PACK_FLAG;
    FPlayerLeave.head.Size := SizeOf(FPlayerLeave);
    FPlayerLeave.head.Command := S_PLAYERLEAVE;
    strpcopy(FPlayerLeave.UserName, PlayerName);
    TGameClient(FGamers.Objects[I]).FClient.SendData(@Fmap, SizeOf(FMap));
  end;
  Result := 0;
end;

function TTcpgameserver.SendPlayerInfo(PlayerName: AnsiString): Integer;
var
  I: Integer;
  FPlayerInfo: TPlayerInfo;
begin
  for I := 0 to 4 do
  begin
    if FUserList.UserList[I].UserName = PlayerName then
    begin
      FPlayerInfo.UserID := FUserList.UserList[I].UserID;
      FPlayerInfo.UserName := FUserList.UserList[I].UserName;
      FPlayerInfo.UserPosX := FUserList.UserList[I].UserPosX;
      FPlayerInfo.UserPosY := FUserList.UserList[I].UserPosY;
      FPlayerInfo.FaceTo := FUserList.UserList[I].FaceTo;
      FPlayerInfo.Speed := FUserList.UserList[I].Speed;
    end;
  end;
  for I := 0 to FGamers.Count - 1 do
  begin
    FPlayerInfo.head.Flag := PACK_FLAG;
    FPlayerInfo.head.Size := SizeOf(FPlayerInfo);
    FPlayerInfo.head.Command := S_PlayerInfo;
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FPlayerInfo, SizeOf(FPlayerInfo));
  end;

end;

function TTcpgameserver.SendPlayerMoveInfo(PlayerName: AnsiString): Integer;
var
  I: Integer;
  FPlayerInfo: TPlayerInfo;
begin
  for I := 0 to 4 do
  begin
    if FUserList.UserList[I].UserName = PlayerName then
    begin
      FPlayerInfo.UserID := FUserList.UserList[I].UserID;
      FPlayerInfo.UserName := FUserList.UserList[I].UserName;
      FPlayerInfo.UserPosX := FUserList.UserList[I].UserPosX;
      FPlayerInfo.UserPosY := FUserList.UserList[I].UserPosY;
      FPlayerInfo.FaceTo := FUserList.UserList[I].FaceTo;
      FPlayerInfo.Speed := FUserList.UserList[I].Speed;
    end;
  end;
  for I := 0 to FGamers.Count - 1 do
  begin
    FPlayerInfo.head.Flag := PACK_FLAG;
    FPlayerInfo.head.Size := SizeOf(FPlayerInfo);
    FPlayerInfo.head.Command := S_PLAYERMOVE;
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FPlayerInfo, SizeOf(FPlayerInfo));
  end;
end;

function TTcpgameserver.SendRangedPropInfo(PropPosX, PropPosY: Integer; DestoryPos: DestoryTypes): Integer;
var
  FRangedPropInfo: TRangedPropInfo;
  I: Integer;
begin
  FRangedPropInfo.head.Flag := PACK_FLAG;
  FRangedPropInfo.head.Size := SizeOf(FRangedPropInfo);
  FRangedPropInfo.head.Command := S_RANGEDPROP;
  FRangedPropInfo.DestoryType := DestoryPos;
  FRangedPropInfo.DestoryPosX := PropPosX;
  FRangedPropInfo.DestoryPosY := PropPosY;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FRangedPropInfo, SizeOf(FRangedPropInfo));
  end;
end;

function TTcpgameserver.SendSetBombInfo(BombX, BombY: Integer): Integer;
var
  I: Integer;
  FBombInfo: TBombSeted;
begin
  FBombInfo.head.Flag := PACK_FLAG;
  FBombInfo.head.Size := SizeOf(FBombInfo);
  FBombInfo.head.Command := S_SETBOME;
  FBombInfo.BombPosX := BombX;
  FBombInfo.BombPosY := BombY;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FBombInfo, SizeOf(FBombInfo));
  end;

end;

function TTcpgameserver.SendShoesPos(x, y: Integer): Integer;
var
  FShoesInfo: TShoesInfo;
  I: Integer;
begin
  FShoesInfo.head.Flag := PACK_FLAG;
  FShoesInfo.head.Size := SizeOf(FShoesInfo);
  FShoesInfo.head.Command := S_SETSHOES;
  FShoesInfo.ShoesPosX := x;
  FShoesInfo.ShoesPosY := y;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FShoesInfo, SizeOf(FShoesInfo));
  end;
end;

function TTcpgameserver.SendBombEvent(BombX: Integer; BombY: Integer; BoomW: Integer; BoomA: Integer; BoomS: Integer; BoomD: Integer; PosArray: Pointer): Integer;
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
    BombEvent.BoomW := BoomW;
    BombEvent.BoomA := BoomA;
    BombEvent.BoomS := BoomS;
    BombEvent.BoomD := BoomD;
    CopyMemory(@(BombEvent.DestoryPos), PosArray, SizeOf(BombEvent.DestoryPos));
    TGameClient(FGamers.Objects[I]).FClient.SendData(@BombEvent, SizeOf(BombEvent));
  end;

end;

function TTcpgameserver.SendBotInfo(BotID: Integer; PosX: Integer; PosY: Integer; FaceTo: Integer): Integer;
var
  I: Integer;
  FBotInfo: TBotInfo;
begin
  for I := 0 to FGamers.Count - 1 do
  begin
    FBotInfo.head.Flag := PACK_FLAG;
    FBotInfo.head.Size := SizeOf(FBotList);
    FBotInfo.head.Command := S_BOTINFO;
    FBotInfo.BotID := BotID;
    FBotInfo.BotPosX := PosX;
    FBotInfo.BotPosY := PosY;
    FBotInfo.BotFaceTo := FaceTo;
    TGameClient(FGamers.Objects[FGamers.Count - 1]).FClient.SendData(@FBotInfo, SizeOf(FBotInfo));
  end;

end;

function TTcpgameserver.SendBotMove(BotID, PosX, PosY, faceto: Integer): Integer;
var
  I: Integer;
  FBotInfo: TBotInfo;
begin
  for I := 0 to FGamers.Count - 1 do
  begin
    FBotInfo.head.Flag := PACK_FLAG;
    FBotInfo.head.Size := SizeOf(FBotList);
    FBotInfo.head.Command := S_BOTMOVE;
    FBotInfo.BotID := BotID;
    FBotInfo.BotPosX := PosX;
    FBotInfo.BotPosY := PosY;
    FBotInfo.BotFaceTo := faceto;
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FBotInfo, SizeOf(FBotInfo));
  end;
end;

procedure TTcpgameserver.SetGamerPos(AGamer: TGameClient);
var
  X, Y: Integer;
begin
  repeat
    X := randomrange(0, 19);
    Y := RandomRange(0, 19);
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
      X := randomrange(0, 19);
      Y := RandomRange(0, 19);
    until FMap.Map[X][Y] = 0;
    if ShoseNum < 7 then
    begin
      FMap.Map[X][Y] := 5;
      SendShoesPos(X, Y);
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


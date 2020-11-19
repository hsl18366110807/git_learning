unit NewForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Role,
  GR32_Image, Vcl.ExtCtrls, ChatProtocol, ChatManager, GR32, GR32_PNG,
  System.SyncObjs;

type
  TRecv = class(TThread)
  protected
    procedure Execute; override;
  public
    procedure doRecvWork;
    constructor Create;
  end;

  TForm1 = class(TForm)
    tmr1: TTimer;
    pntbx: TPaintBox32;
    procedure tmr1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    Map: array of Integer;
    Msgs: TChatMsgs;
    UserList: TUserList; //用来接收服务器的定长的角色数组列表
    RoleList: array[0..4] of TRole;
    BmpFloor, BmpCookie1, BmpBox1, BmpShoe: TBitmap32;
    Lock: TCriticalSection;
    RecvThread: TRecv;
    Role: TRole;
    Pressed: Boolean;
  public
    procedure InitRoleList;
    procedure DrawMap(Sender: TObject);
    procedure DestroyRoleList;
    procedure DrawPlayer(PosX, PosY: Integer);
    procedure PlayerMove(DesPlayer: PTPlayerInfo);
    procedure UpdateUserList(Role: TRole);
    procedure SetShoes(Ptr: PTShoesInfo);
    function AddRole(User: TPlayerInfo): Integer;
    function DeleteRole(User: TPlayerInfo): Integer;
    function AddUserToList(User: TPlayerInfo): Integer; // 0 失败 1 成功
    function FindRole(x, y: Integer): TRole; overload;
    function FindRole(id: Integer): TRole; overload;
  end;

var
  GameForm: TForm1;
  num: Integer;

implementation

{$R *.dfm}

function TForm1.AddRole(User: TPlayerInfo): Integer;
var
  I: Integer;
  Role: TRole;
begin
  Result := 0;
  for I := 0 to Length(RoleList) do
  begin
    if RoleList[I] = nil then
    begin
      Role := TRole.Create(User.UserPosX, User.UserPosY, User.UserID, DEFAULT_SPEED + User.Speed * SPEED_INTERVAL, StrPas(PAnsiChar(@User.UserName[0])));
      RoleList[I] := Role;
      Result := 1;
      Exit;
    end;
  end;
end;

function TForm1.AddUserToList(User: TPlayerInfo): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Length(UserList) - 1 do
  begin
    if UserList[I].UserID = 0 then
    begin
      UserList[I] := User;
      Map[User.UserPosX * 20 + User.UserPosY] := 3;
      AddRole(User);
      Result := 1;
      Exit
    end;
  end;
  if I = Length(UserList) - 1 then
    Result := 0;
end;

function TForm1.DeleteRole(User: TPlayerInfo): Integer;
begin
//删除Role, 析构Role
end;

procedure TForm1.DestroyRoleList;
var
  I: Integer;
begin
  for I := 0 to Length(RoleList) do
  begin
    if RoleList[I] <> nil then
//        RoleList[I].Free;
       //free
  end;
end;

procedure TForm1.DrawMap(Sender: TObject);
var
  x, y, i, j, drawY, bmpBombH, PosX, PosY, RoleId: Integer;
begin
  x := 0;
  y := 0;
  while x < 800 do
  begin
    while y < 800 do
    begin
      BmpFloor.DrawTo(pntbx.Buffer, x, y);
      y := y + 40;
    end;
    x := x + 40;
    y := 0;
  end;
  x := 0;
  y := 0;
  while y < 800 do
  begin
    while x < 800 do
    begin
      i := x div 40;
      j := y div 40;
      if Map[i * 20 + j] = 1 then //cookie//
      begin
        drawY := y - (BmpCookie1.Height - 40);
        BmpCookie1.DrawTo(pntbx.Buffer, x, drawY);
      end
      else if Map[i * 20 + j] = 2 then  //箱子
      begin
        drawY := y - (BmpBox1.Height - 40);
        BmpBox1.DrawTo(pntbx.Buffer, x, drawY);
      end
      else if Map[i * 20 + j] = 3 then
      begin
        DrawPlayer(i, j);
      end
      else if Map[i * 20 + j] = 5 then //鞋子
      begin
        drawY := y - (BmpShoe.Height - 40);
        BmpShoe.DrawTo(pntbx.Buffer, x, drawY);
      end;
      x := x + 40;
    end;
    y := y + 40;
    x := 0;
  end;
end;

procedure TForm1.DrawPlayer(PosX, PosY: Integer);
var
  Role: TRole;
  x, y: Integer;
  PieceOfBmp, High: Integer;
begin
  Role := FindRole(PosX, PosY);
//  if (Role = nil) or (Role.FBmp = nil)then
//    Exit;
  PieceOfBmp := Role.FBmp.Width div 6;
  High := Role.FBmp.Height;
  if not Role.IsMoveListEmpty then
  begin
    if (Role.FBeginMove.DesX = PosX) and (Role.FBeginMove.DesY = PosY) then
    begin
      Role.State := ROLESTILL;
      Role.DelFirstMoveList;
    end
    else
      Role.State := ROLEMOVE;
  end;
  if Role.State = ROLESTILL then
  begin
    x := Role.X * CELL_WIDTH;
    y := Role.Y * CELL_WIDTH - (High - CELL_WIDTH);
    Role.FBmp.DrawTo(pntbx.Buffer, Rect(x, y, CELL_WIDTH + x, y + High), Rect(0, 0, PieceOfBmp, High));
  end
  else
  begin
    //更新人物状态
    Role.Speed := Role.FBeginMove.Speed;
    Role.TurnTo := Role.FBeginMove.TurnTo;
    Role.Move(pntbx, Role.FBeginMove.DesX, Role.FBeginMove.DesY);
    if Role.State = ROLEMOVE then
      Role.Fmovetime := Role.Fmovetime + tmr1.Interval
    else
    begin
      Map[PosX * 20 + PosY] := 0;
      Map[Role.X * 20 + Role.Y] := 3;
        //更新userlist ----------------------------------------------------------------------------没有更新
    end;
  end;

end;

function TForm1.FindRole(x, y: Integer): TRole;
var
  I: Integer;
begin
  for I := 0 to Length(RoleList) do
  begin
    if (RoleList[I] <> nil) and (RoleList[I].x = x) and (RoleList[I].y = y) then
      Result := RoleList[I];
  end;
end;

function TForm1.FindRole(id: Integer): TRole;
var
  I: Integer;
begin
  for I := 0 to Length(RoleList) do
  begin
    if (RoleList[I] <> nil) and (RoleList[I].id = id) then
      Result := RoleList[I];
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  ptr: PTPlayerInfo;
begin
  //初始化自己的成员
  SetLength(Map, 400);
  FillMemory(Map, 400, 0);
  Msgs := TChatMsgs.Create;
  Lock := TCriticalSection.Create;

  ptr := ChatMgr.ReadPlayerInfo;
  Role := TRole.Create(ptr.UserPosX, ptr.UserPosY, ptr.UserID, DEFAULT_SPEED + ptr.Speed * SPEED_INTERVAL, StrPas(PAnsiChar(@ptr.UserName[0])));
  //初始化资源
  BmpFloor := TBitmap32.Create;
  LoadBitmap32FromPNG(BmpFloor, 'img/floor1.png');
  BmpCookie1 := TBitmap32.Create;
  BmpCookie1.DrawMode := dmBlend;
  LoadBitmap32FromPNG(BmpCookie1, 'img/cookie1.png');
  BmpBox1 := TBitmap32.Create;
  BmpBox1.DrawMode := dmBlend;
  LoadBitmap32FromPNG(BmpBox1, 'img/box1.png');
  BmpShoe := TBitmap32.Create;
  BmpShoe.DrawMode := dmBlend;
  LoadBitmap32FromPNG(BmpShoe, 'img/shoe.png');
  //线程接收服务器信息
  RecvThread := TRecv.Create;
  //UI主线程渲染工作
  tmr1.Enabled := True;
  //请求Map
  ChatMgr.RequestMap;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  RecvThread.Terminate;
  //析构Rolelist
  DestroyRoleList;  {-----------------------------------------------------------------------------------------free有问题}
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 32 then
  begin
    ChatMgr.RequestBoom;
    exit;
  end;
  if True then
    if (Role.State = ROLESTILL) and (Pressed = False) then
    begin
      Pressed := True;
      ChatMgr.RequestMove(Key);
    end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Pressed := False;
  ChatMgr.RequestStopMove(Key);
end;

procedure TForm1.InitRoleList;
var
  I: Integer;
begin
  GameForm.Lock.Enter;
  try
    for I := 0 to Length(UserList) do
    begin
      if UserList[I].UserID = 0 then
        Exit;
      if AddRole(UserList[I]) = 0 then
      begin
        OutputDebugString('添加Role失败！');
        Exit;
      end;
    end;
  finally
    GameForm.Lock.Leave;
  end;
  Role := FindRole(ChatMgr.ReadPlayerInfo.UserID);
end;

procedure TForm1.PlayerMove(DesPlayer: PTPlayerInfo);
var
  id: Integer;
  Role: TRole;
  Move: PTRoleMove;
begin
  id := DesPlayer^.UserID;
  Role := FindRole(id);
  if (Role.X = DesPlayer.UserPosX) and (Role.Y = DesPlayer.UserPosY) then
    Exit;
  Move := AllocMem(SizeOf(TRoleMove));
  Move.Next := nil;
  Move.DesX := DesPlayer.UserPosX;
  Move.DesY := DesPlayer.UserPosY;
  Move.TurnTo := DesPlayer.FaceTo;
  Move.Speed := DesPlayer.Speed;
  Role.AddMoveList(Move);
  Role.State := ROLEMOVE;
end;

procedure TForm1.SetShoes(Ptr: PTShoesInfo);
var
  PosX, PosY: Integer;
begin
  PosX := Ptr^.ShoesPosX;
  PosY := Ptr^.ShoesPosY;
  Map[PosX * 20 + PosY] := 5;
end;

procedure TForm1.tmr1Timer(Sender: TObject);
begin
   //渲染界面
  DrawMap(self);
  pntbx.Invalidate;
end;

procedure TForm1.UpdateUserList(Role: TRole);
var
  I: Integer;
begin
  for I := 0 to Length(UserList) do
  begin
    if UserList[I].UserID = Role.Id then
    begin
      if (UserList[I].UserPosX <> Role.X) or (UserList[I].UserPosY <> Role.Y) then
      begin
        UserList[I].UserPosX := Role.X;
        UserList[I].UserPosY := Role.Y;
      end;
    end;
  end;
end;

{ TRecv }

constructor TRecv.Create;
begin
  inherited Create(False);
end;

procedure TRecv.doRecvWork;
var
  MsgPtr: PChatMsg;
  ServerMsgPtr: PServerMessage;
  MapPtr: PTSMap;
  UserPtr: PTPlayerInfo;
  UserListPtr: PTPlayerInfoList;
  BoomFlor: PTBombBoom;
  ShoesPtr: PTShoesInfo;
  BombPtr: PTBombSeted;
  BombBoomPtr: PTBombBoom;
  PlayerDeadPtr: PTPlayerDeadEvent;
begin
  ChatMgr.ReadResponse(GameForm.Msgs);
  while not GameForm.Msgs.IsEmpty do
  begin
    GameForm.Msgs.FetchNext(MsgPtr);
    if MsgPtr <> nil then
    begin
      ServerMsgPtr := PServerMessage(MsgPtr);
      try
        case ServerMsgPtr^.Head.Command of
          S_MAP: {接收服务器传来的Map只接收一次所以不用临界保护}
            begin
              MapPtr := PTSMap(MsgPtr);
              CopyMemory(GameForm.Map, @MapPtr^.Map[0], 1600);
            end;
         {传来的是定长的角色数组, 自己本地new角色实例}
          S_USERLIST:
            begin
              UserListPtr := PTPlayerInfoList(MsgPtr);
              GameForm.Lock.Enter;
              try
                GameForm.UserList := UserListPtr^.UserList;
              finally
                GameForm.Lock.Leave;
              end;
              GameForm.InitRoleList;
            end;
          {收到新加入的玩家的信息}
          S_PlayerInfo:
            begin
              UserPtr := PTPlayerInfo(MsgPtr);
              GameForm.AddUserToList(UserPtr^);
            end;
            {收到玩家move一步的信息}
          S_PLAYERMOVE:
            begin
              UserPtr := PTPlayerInfo(MsgPtr);
              GameForm.PlayerMove(UserPtr);
              Inc(num);
              OutputDebugString(PWideChar(IntToStr(num)));
            end;
            {收到鞋子信息}
          S_SETSHOES:
            begin
              ShoesPtr := PTShoesInfo(MsgPtr);
              GameForm.SetShoes(ShoesPtr);   //鞋子的动画还要加上
            end;
            {收到炸弹信息}
          S_SETBOME:
            begin
              BombPtr := PTBombSeted(MsgPtr);
//              GameForm.SetBomb(BombPtr);
            end;
            {收到爆炸火花信息}
          S_BOMBBOOM:
            begin
              BombBoomPtr := PTBombBoom(MsgPtr);
//              GameForm.SetBombBoom(BombBoomPtr);
            end;
            {收到玩家死亡信息}
          S_PLAYERDEAD:
            begin
              PlayerDeadPtr := PTPlayerDeadEvent(MsgPtr);
//              GameForm.SetPlayerDead(PlayerDeadPtr);
            end;
            {收到Bot信息}
          S_BOTINFO:
            begin
              OutputDebugString('111111111111111111');
            end;
            {收到Bot移动的信息}
          S_BOTMOVE:
            begin
              OutputDebugString('2222222222222222');
            end;
        end;
//        Inc(FMsgNum);
      finally
        FreeMem(MsgPtr);
      end;
    end;
  end;
end;

procedure TRecv.Execute;
begin
  while not Terminated do
  begin
    doRecvWork;
  end;
end;

end.


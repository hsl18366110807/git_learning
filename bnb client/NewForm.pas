unit NewForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Role,
  GR32_Image, Vcl.ExtCtrls, ChatProtocol, ChatManager, GR32, GR32_PNG,
  System.SyncObjs, Item;

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
    KeyPressed: Boolean;
    ItemList: array[0..49] of TItem;
//    TickShoes: Integer;
  public
    procedure InitRoleList;
    procedure DrawMap(Sender: TObject);
    procedure DestroyRoleList;
    procedure DestroyItemList;
    procedure DrawPlayer(PosX, PosY: Integer);
    procedure DrawBomb;
    procedure PlayerMove(DesPlayer: PTPlayerInfo);
    procedure UpdateUserList(Role: TRole);
    procedure SetShoes(Ptr: PTShoesInfo);
    procedure SetBomb(Ptr: PTBombSeted);
    procedure ShowItem(PosX, PosY: Integer);
    function AddItem(TypeId: MapSign; PosX, PosY: Integer): Integer;
    function AddRole(User: TPlayerInfo): Integer;
    function DeleteRole(User: TPlayerInfo): Integer;
    function DeleteItem(PosX, PosY: Integer): Integer;
    function AddUserToList(User: TPlayerInfo): Integer; // 0 失败 1 成功
    function FindRole(x, y: Integer): TRole; overload;
    function FindRole(id: Integer): TRole; overload;
    function FindItem(x, y: Integer): TItem;
  end;

var
  GameForm: TForm1;
  num: Integer;
  oldtime: TDateTime;
  newtime: TDateTime;
  serverspeed: Integer;
  lixiangspeed: Integer;
  clientspeed: Integer;

implementation

{$R *.dfm}
uses
  System.DateUtils; // just for test speed;

function TForm1.AddItem(TypeId: MapSign; PosX, PosY: Integer): Integer;
var
  I: Integer;
  Item: TItem;
  ItemTypeId: Integer;
begin
  Result := 0;
  for I := 0 to Length(ItemList) do
  begin
    if ItemList[I] = nil then
    begin
      case TypeId of
        PBOMB:
          begin
            ItemTypeId := 4;
            Item := TItem.Create(PosX, PosY, ItemTypeId);
            Item.ShowBmpType := 0;
          end;
        PSHOES:
          begin
            ItemTypeId := 5;
            Item := TItem.Create(PosX, PosY, ItemTypeId);
            Item.ShowBmpType := 1;
          end;
        PBOT:
          ;
      end;
      ItemList[I] := Item;
      Result := 1;
      Exit;
    end;
  end;
end;

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

function TForm1.DeleteItem(PosX, PosY: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Length(ItemList) do
  begin
    if (ItemList[I].X = PosX) and (ItemList[I].Y = PosY) then
    begin
      ItemList[I].Free;
      ItemList[I] := nil;
      Result := 1;
    end;
  end;
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
    begin
      RoleList[I].Free;
      RoleList[I] := nil;
    end;
  end;
end;

procedure TForm1.DestroyItemList;
var
  I: Integer;
begin
  for I := 0 to Length(ItemList) do
  begin
    if ItemList[I] <> nil then
    begin
      ItemList[I].Free;
      ItemList[I] := nil;
    end;
  end;
end;

procedure TForm1.DrawBomb;
var
  I: Integer;
begin
  for I := 0 to Length(ItemList) do
  begin
    if (ItemList[I] <> nil) and (ItemList[I].ItemType = 4) then
      ShowItem(ItemList[I].X, ItemList[I].Y);
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
      else if (Map[i * 20 + j] = 5) then //鞋子
      begin
        ShowItem(i, j);
      end;
      x := x + 40;
    end;
    y := y + 40;
    x := 0;
  end;
  DrawBomb;
  pntbx.Buffer.TextOut(10, 10, '理想速度  ' + IntToStr(lixiangspeed));
  pntbx.Buffer.TextOut(10, 40, '客户端速度  ' + IntToStr(clientspeed));
  pntbx.Buffer.TextOut(10, 70, '服务器速度  ' + IntToStr(serverspeed));
end;

procedure TForm1.DrawPlayer(PosX, PosY: Integer);
var
  Role: TRole;
  x, y: Integer;
  PieceOfBmp, High: Integer;
begin
  Role := FindRole(PosX, PosY);
  PieceOfBmp := Role.Bmp.Width div 6;
  High := Role.Bmp.Height;
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
    Role.Bmp.DrawTo(pntbx.Buffer, Rect(x, y, CELL_WIDTH + x, y + High), Rect(Role.NowFrame * PieceOfBmp, 0, (Role.NowFrame + 1) * PieceOfBmp, High));
  end
  else
  begin
    //更新人物状态
    Role.Speed := Role.FBeginMove.Speed;
    if Role.TurnTo <> Role.FBeginMove.TurnTo then
    begin
      Role.TurnTo := Role.FBeginMove.TurnTo;
      Role.NowFrame := 0;
    end;
    Role.Move(pntbx, Role.FBeginMove.DesX, Role.FBeginMove.DesY);
    if Role.State = ROLEMOVE then
      Role.Fmovetime := Role.Fmovetime + tmr1.Interval
    else
    begin
      Map[PosX * 20 + PosY] := 0;
      Map[Role.X * 20 + Role.Y] := 3;
      clientspeed := Role.actrolspeed;
//      OutputDebugString(PWideChar('actrolclientspeed' + IntToStr(Role.actrolspeed)));
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

function TForm1.FindItem(x, y: Integer): TItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Length(ItemList) do
  begin
    if (ItemList[I] <> nil) and (ItemList[I].x = x) and (ItemList[I].y = y) then
      Result := ItemList[I];
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
//  BmpShoe := TBitmap32.Create;
//  BmpShoe.DrawMode := dmBlend;
//  LoadBitmap32FromPNG(BmpShoe, 'img/shoe.png');
//  //线程接收服务器信息
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
  DestroyRoleList;

end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 32 then
  begin
    ChatMgr.RequestBoom;
    exit;
  end;
  if True then
    if (Role.State = ROLESTILL) and (KeyPressed = False) then
    begin
      KeyPressed := True;
      ChatMgr.RequestMove(Key);
    end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  KeyPressed := False;
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
  lixiangspeed := 80 + DesPlayer.Speed * 20;
end;

procedure TForm1.SetBomb(Ptr: PTBombSeted);
var
  PosX, PosY: Integer;
  BoomPtr: PTBoomPic;
begin
  PosX := Ptr^.BombPosX;
  PosY := Ptr^.BombPosY;
//  Map[PosX * 20 + PosY] := 4;
  if AddItem(PBOMB, PosX, PosY) = 0 then
    OutputDebugString('AddBmob failed!');
end;

procedure TForm1.SetShoes(Ptr: PTShoesInfo);
var
  PosX, PosY: Integer;
begin
  PosX := Ptr^.ShoesPosX;
  PosY := Ptr^.ShoesPosY;
  Map[PosX * 20 + PosY] := 5;
  if AddItem(PSHOES, PosX, PosY) = 0 then
    OutputDebugString('AddShoes failed!');
end;

procedure TForm1.ShowItem(PosX, PosY: Integer);
var
  Item: TItem;
  x, y, piceBoomW: Integer;
  bmp: TBitmap32;
begin
  Item := FindItem(PosX, PosY);
  if Item = nil then
    Exit;
  case Item.ShowBmpType of
    0:  //auto
      begin                                                                  
        bmp := Item.AutoBmp;
        piceBoomW := bmp.Width div Item.AutoBmpMaxFrame;
        x := Item.X * CELL_WIDTH;
        y := Item.Y * CELL_WIDTH - (bmp.Height - CELL_WIDTH);
        bmp.DrawTo(pntbx.Buffer, rect(x, y, piceBoomW + x, y + bmp.Height), Rect(piceBoomW * Item.AutoBmpFrame, 0, piceBoomW * (Item.AutoBmpFrame + 1), bmp.Height));
        Item.AutoBmpFrame := (Item.AutoBmpFrame + 1) mod Item.AutoBmpMaxFrame;
      end;
    1: //float
      begin
        x := Item.X * CELL_WIDTH;
        y := Item.Y * CELL_WIDTH + Item.FloatDistance;
        bmp := Item.FloatBmp;
        bmp.DrawTo(pntbx.Buffer, x, y);
        if Item.FloatDistanceOrder then
          Item.FloatDistance := Item.FloatDistance + 1
        else
          Item.FloatDistance := Item.FloatDistance - 1;
        if Item.FloatDistance = MaxFloatDistance then
          Item.FloatDistanceOrder := False;
        if Item.FloatDistance = 0 then
          Item.FloatDistanceOrder := True;
      end;
  end;
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
  numMovepkg: Integer;
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
              GameForm.Lock.Enter;
              try
                GameForm.AddUserToList(UserPtr^);
              finally
                GameForm.Lock.Leave;
              end;
            end;
            {收到玩家move一步的信息}
          S_PLAYERMOVE:
            begin
              if num = 0 then
              begin
                oldtime := Now;
                newtime := Now;
              end;
              Inc(num);
              newtime := Now;
              if num > 2 then
              begin
                serverspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
                oldtime := newtime;
              end;
              OutputDebugString(PWideChar(IntToStr(num)));
              UserPtr := PTPlayerInfo(MsgPtr);
              GameForm.PlayerMove(UserPtr);
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
              GameForm.SetBomb(BombPtr);
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


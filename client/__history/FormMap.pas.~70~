unit FormMap;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  ChatProtocol, Vcl.StdCtrls, ChatManager, GR32, GR32_Image, GR32_PNG,
  Vcl.ExtCtrls, System.DateUtils;

type
  TFrmMap = class(TForm)
    pntbx: TPaintBox32;
    tmr1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure doWork(Sender: TObject);
    procedure processAni(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function FindInList(const UserList: TUserList; role: TPlayerInfo): Integer;
    procedure RoleMoveOneStepY;
    procedure RoleMoveOneStepX;
    procedure DrawFloorCooke;
    procedure tmr1Timer(Sender: TObject);
//    procedure tmr1Timer(Sender: TObject);
  private
    FBmpRole: TBitmap32;
    FBmpBoom: TBitmap32;
    FBmpShoe: TBitmap32;
    Fmsgs: TChatMsgs;
    FSrcX, FSrcY, FDesX, FDesY: Integer;
    FMovingRoleIndex: Integer;
    FNewTime, FOldTime: TDateTime;
    bmpRoleW, bmpRoleH, piceRoleW: Integer;
    bmpBoomW, bmpBoomH, piceBoomW: Integer;
    timer: TTimer;
    TickForRole: Integer;
    TickForBomb: Integer;
    color: TColor;
    posX, posY: Integer;
    FOldMap: array of Integer;
    FMap: array of Integer;
    FUsersChanged: Boolean;
    FUserListNew: TUserList; // array[0..4] of TPlayerInfo;
    FUserListOld: TUserList;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMap: TFrmMap;

implementation

{$R *.dfm}

const
  W = 40;

var
  bmp2, bmp3, bmp4: TBitmap32;
  bmpE, bmpWW, bmpS, bmpN: TBitmap32;
  tick: Integer;

procedure TFrmMap.doWork(Sender: TObject);
var
  MsgPtr: PChatMsg;
  ServerMsgPtr: PServerMessage;
  MapPtr: PTSMap;
  UserPtr: PTPlayerInfoList;
  BoomFlor: PTBombBoom;
begin
  ChatMgr.ReadResponse(FMsgs);
  while not FMsgs.IsEmpty do
  begin
    FMsgs.FetchNext(MsgPtr);

    if MsgPtr <> nil then
    begin
      ServerMsgPtr := PServerMessage(MsgPtr);
      try
        case ServerMsgPtr^.Head.Command of
          S_Map:
            begin
              MapPtr := PTSMap(MsgPtr);
              CopyMemory(FMap, @MapPtr^.Map[0], 1600);
            end;
          S_USERLIST:
            begin
              UserPtr := PTPlayerInfoList(MsgPtr);
              FUserListNew := UserPtr^.UserList;
              FUsersChanged := True;
            end;
        end;
      finally
        FreeMem(MsgPtr);
      end;
    end;
  end;
  processAni(self);
end;

procedure TFrmMap.DrawFloorCooke;
var
  x, y, i, j, drawY, bmpBombH, PosX, PosY: Integer;
begin
  x := 0;
  y := 0;
  while x < 800 do
  begin
    while y < 800 do
    begin
      bmp2.DrawTo(pntbx.Buffer, x, y);
      y := y + 40;
    end;
    x := x + 40;
    y := 0;
  end;

  //画地板
  x := 0;
  y := 0;
  while x < 800 do
  begin
    while y < 800 do
    begin
      i := x div 40;
      j := y div 40;
      if FMap[i * 20 + j] = 1 then //地板//
      begin
        drawY := y - (bmp3.Height - 40);
        bmp3.DrawTo(pntbx.Buffer, x, drawY);
      end
      else if FMap[i * 20 + j] = 2 then  //箱子
      begin
        drawY := y - (bmp4.Height - 40);
        bmp4.DrawTo(pntbx.Buffer, x, drawY);
      end
      else if FMap[i * 20 + j] = 4 then
      begin
        drawY := y - (bmp4.Height - 40);
        FBmpBoom.DrawTo(pntbx.Buffer, rect(x, drawY, piceBoomW + x, drawY + bmpBombH), Rect(piceBoomW * TickForBomb, 0, piceBoomW * (TickForBomb + 1), bmpBombH));
        Inc(TickForBomb);
        if TickForBomb = 4 then
          TickForBomb := 0;
      end
      else if FMap[i * 20 + j] = 5 then //鞋子
      begin
        drawY := y - (FBmpShoe.Height - 40);
        FBmpShoe.DrawTo(pntbx.Buffer, x, drawY);
      end;
      y := y + 40;
    end;
    x := x + 40;
    y := 0;
  end;
end;

function TFrmMap.FindInList(const UserList: TUserList; role: TPlayerInfo): Integer;
var
  i, j: Integer;
  tmpRole: TPlayerInfo;
begin
  Result := -1;
  for i := 0 to Length(UserList) do
  begin
    tmpRole := UserList[i];
    j := 0;
    while (tmpRole.UserName[j] = role.UserName[j]) and (j <= Length(role.UserName) - 1) do
      Inc(j);
    if j = Length(role.UserName) then
      Result := i;
  end;
end;

procedure TFrmMap.FormCreate(Sender: TObject);
begin
//
  FMsgs := TChatMsgs.Create;
  ChatMgr.RequestMap;
  FBmpRole := TBitmap32.Create;
  bmpE := TBitmap32.Create;
  bmpWW := TBitmap32.Create;
  bmpN := TBitmap32.Create;
  bmpS := TBitmap32.Create;
  FBmpShoe := TBitmap32.Create;
  FBmpBoom := TBitmap32.Create;
  FBmpRole.DrawMode := dmTransparent;
  bmpE.DrawMode := dmBlend;
  bmpN.DrawMode := dmBlend;
  bmpS.DrawMode := dmBlend;
  bmpWW.DrawMode := dmBlend;
  FBmpShoe.DrawMode := dmBlend;
  FBmpBoom.DrawMode := dmTransparent;
  LoadBitmap32FromPNG(FBmpRole, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpE, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpN, 'img/redp_m_north.png');
  LoadBitmap32FromPNG(bmpS, 'img/redp_m_south.png');
  LoadBitmap32FromPNG(bmpWW, 'img/redp_m_west.png');
  LoadBitmap32FromPNG(FBmpBoom, 'img/bomb.png');
  LoadBitmap32FromPNG(FBmpShoe, 'img/shoe.png');

  bmpRoleW := FBmpRole.Width;
  bmpRoleH := FBmpRole.Height;
  piceRoleW := bmpRoleW div 6;
  bmpBoomW := FBmpBoom.Width;
  bmpBoomH := FBmpBoom.Height;
  piceBoomW := bmpBoomW div 4;

  bmp2 := TBitmap32.Create;
  LoadBitmap32FromPNG(bmp2, 'img/floor1.png');

  bmp3 := TBitmap32.Create;
  bmp3.DrawMode := dmBlend;
  LoadBitmap32FromPNG(bmp3, 'img/cookie1.png');

  bmp4 := TBitmap32.Create;
  bmp4.DrawMode := dmBlend;
  LoadBitmap32FromPNG(bmp4, 'img/box1.png');

  PosX := 0;
  PosY := 0;

  SetLength(FMap, 400);
  FillMemory(FMap, 400, 0);

  timer := TTimer.Create(Self);
  timer.OnTimer := doWork;
  timer.Interval := 100;
  timer.Enabled := True;
  FMovingRoleIndex := -1;
  FOldTime := Now;
  FNewTime := Now;
end;

procedure TFrmMap.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 32 then
  begin
    ChatMgr.RequestBoom;
    exit;
  end;
  FNewTime := Now;
  if (TickForRole = 0) and (FMovingRoleIndex = -1) and (SecondsBetween(FNewTime, FOldTime) > 0.1) then
  begin
    ChatMgr.RequestMove(Key);
    FOldTime := Now;
  end;

end;

procedure TFrmMap.RoleMoveOneStepX;
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY: Integer;
begin
  piceRoleW := FBmpRole.Width div 6;
  if FSrcX < FDesX then
  begin
    bmpRoleH := FBmpRole.Height;
    PosX := FSrcX * 40 + (TickForRole + 1) * 40 div 6;
    PosY := FSrcY * 40 - (bmpRoleH - 40);
    FBmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * TickForRole, 0, piceRoleW * (TickForRole + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmpRole.Height;
    PosX := FSrcX * 40 - (TickForRole + 1) * 40 div 6;
    PosY := FSrcY * 40 - (bmpRoleH - 40);
    FBmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * TickForRole, 0, piceRoleW * (TickForRole + 1), bmpRoleH));
  end;
end;

procedure TFrmMap.RoleMoveOneStepY;
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY: Integer;
begin
  piceRoleW := FBmpRole.Width div 6;
  if FSrcY < FDesY then
  begin
    bmpRoleH := FBmpRole.Height;
    PosX := FSrcX * 40;
    PosY := FSrcY * 40 - (bmpRoleH - 40) + (TickForRole + 1) * 40 div 6;
    FBmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * TickForRole, 0, piceRoleW * (TickForRole + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmpRole.Height;
    PosX := FSrcX * 40;
    PosY := FSrcY * 40 - (bmpRoleH - 40) - (TickForRole + 1) * 40 div 6;
    FBmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * TickForRole, 0, piceRoleW * (TickForRole + 1), bmpRoleH));
  end;
end;

procedure TFrmMap.tmr1Timer(Sender: TObject);
begin
  OutputDebugString('1111111111111111111');
end;

//procedure TFrmMap.tmr1Timer(Sender: TObject);
//begin
//  if (tick mod 6 = 0) and (tick <> 0) then
//    tmr1.Enabled := False;
//  if FSrcX = FDesX then
//    RoleMoveOneStepY(FSrcX, FSrcY, FDesY)
//  else
//    RoleMoveOneStepX(FSrcY, FSrcX, FDesX);
//
//end;

procedure TFrmMap.processAni(Sender: TObject);
var
  x, y, i, j: Integer;
  drawX, drawY: Integer;
  RoleNew: TPlayerInfo;
  RoleOld: TPlayerInfo;
  indexRoleOld: Integer;
  indexRoleNew: Integer;
  steps: Integer;
begin
//  if FUsersChanged then
//  begin
  DrawFloorCooke;
  for i := 0 to Length(FUserListNew) do
  begin
    RoleNew := FUserListNew[i];
    if RoleNew.UserName[0] = #0 then
      Continue;
    indexRoleOld := FindInList(FUserListOld, RoleNew);
    if indexRoleOld = -1 then
    begin   //角色新建立
      FBmpRole := bmpS;
      PosX := RoleNew.UserPosX * 40;
      PosY := RoleNew.UserPosY * 40 - (FBmpRole.Height - 40);
      FBmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(0, 0, piceRoleW, bmpRoleH));
      FUserListOld := FUserListNew;
    end
    else if (FUserListOld[indexRoleOld].UserPosX = RoleNew.UserPosX) and (FUserListOld[indexRoleOld].UserPosY = RoleNew.UserPosY) and ((FMovingRoleIndex = -1) or (indexRoleOld <> FMovingRoleIndex)) then
    begin //角色存在没有动作
      case RoleNew.FaceTo of
        NORTH:
          FBmpRole := bmpN;
        SOUTH:
          FBmpRole := bmpS;
        WEST:
          FBmpRole := bmpWW;
        EAST:
          FBmpRole := bmpE;
      end;
      PosX := RoleNew.UserPosX * 40;
      PosY := RoleNew.UserPosY * 40 - (FBmpRole.Height - 40);
      FBmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(0, 0, piceRoleW, bmpRoleH));
    end
    else if (FUserListOld[indexRoleOld].UserPosX <> RoleNew.UserPosX) or (FUserListOld[indexRoleOld].UserPosY <> RoleNew.UserPosY) then
    begin
       //角色移动
      case RoleNew.FaceTo of
        NORTH:
          FBmpRole := bmpN;
        SOUTH:
          FBmpRole := bmpS;
        WEST:
          FBmpRole := bmpWW;
        EAST:
          FBmpRole := bmpE;
      end;
      if FMovingRoleIndex <> indexRoleOld then
        FMovingRoleIndex := indexRoleOld;

      if FUserListOld[indexRoleOld].UserPosX = RoleNew.UserPosX then
      begin
        FSrcX := FUserListOld[indexRoleOld].UserPosX;
        FSrcY := FUserListOld[indexRoleOld].UserPosY;
        FDesX := RoleNew.UserPosX;
        FDesY := RoleNew.UserPosY;
        RoleMoveOneStepY;
        TickForRole := TickForRole + 1;
        if TickForRole = 6 then
        begin
          FUserListOld[indexRoleOld] := RoleNew;
          TickForRole := 0;
          FMovingRoleIndex := -1;
        end;
      end
      else if FUserListOld[indexRoleOld].UserPosY = RoleNew.UserPosY then
      begin
        FSrcX := FUserListOld[indexRoleOld].UserPosX;
        FSrcY := FUserListOld[indexRoleOld].UserPosY;
        FDesX := RoleNew.UserPosX;
        FDesY := RoleNew.UserPosY;
        RoleMoveOneStepX;
        TickForRole := TickForRole + 1;
        if TickForRole = 6 then
        begin
          FUserListOld[indexRoleOld] := RoleNew;
          TickForRole := 0;
          FMovingRoleIndex := -1;
        end;
      end;

    end;
  end;
  for i := 0 to Length(FUserListOld) do
  begin
    RoleOld := FUserListOld[i];
    if RoleOld.UserName[0] = #0 then
      Continue;
    indexRoleNew := FindInList(FUserListNew, RoleOld);
    if indexRoleNew = -1 then
    begin
           //角色死亡
      FMap[RoleOld.UserPosX * 20 + RoleOld.UserPosY] := 0;
    end;
  end;
  pntbx.Invalidate;
end;

end.


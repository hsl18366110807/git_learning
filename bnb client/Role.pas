unit Role;

interface

uses
  System.Classes, GR32, GR32_Image, GR32_PNG, ChatProtocol, System.SysUtils,
  System.DateUtils;

const
  CELL_WIDTH = 40; //每个格子40像素
  DEFAULT_SPEED = 16 * CELL_WIDTH;     // Speed 默认speed 每秒2个单位格
  SPEED_INTERVAL = 20;
  FPS = 18;
type
  Tprocess = procedure(Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer) of object;

  TMyTimer = class
  private
//      OldTime: TTime;
//      NewTime: TTime;
  public
    constructor Create;
    procedure dowork(proce: Tprocess; Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer; interval: Integer; timeTurnoff: Integer);
  end;

  TRole = class(TBitmap32)
  private
    FId: Integer;
    FName: AnsiString;
    FPos: TPoint;
    Ftick: Integer;
    FTurnTo: FaceOrientate;
    FState: RoleState;
  public
    function IsMoveListEmpty: Boolean;
    function GetSpeed: Integer;
    procedure AddMoveList(Move: PTRoleMove);
    procedure DelFirstMoveList;
    procedure SetState(const Value: RoleState);
    procedure Move(Map: TPaintBox32; DesX, DesY: Integer);
    procedure MoveOneStepX(Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer); //W 为正方形格子的宽度
    procedure MoveOneStepY(Map: TPaintBox32; SrcX, SrcY, DesY: Integer; W: Integer);
    procedure SetTurnTo(const Dir: FaceOrientate);
    procedure SetSpeed(const Value: Integer);
    procedure SetBomb;
  public
    FBmp: TBitmap32;
    Fmovetime: Integer;
    FSpeed: Integer;
    FMoveList: PTRoleMove;
    FBeginMove: PTRoleMove;
    FEndMove: PTRoleMove;
    constructor Create(PosX, PosY, Id, Speed: Integer; Name: AnsiString);
    property Id: Integer read FId;
    property Name: AnsiString read FName; //先暂时没有添加改名接口
    property X: Integer read FPos.x;
    property Y: Integer read FPos.y;
    property State: RoleState read FState write SetState;
    property TurnTo: FaceOrientate read FTurnTo write SetTurnTo;
    property Speed: Integer read GetSpeed write SetSpeed;
  end;

implementation

var
  bmpE, bmpW, bmpS, bmpN: TBitmap32; //相当于这个类的图片资源，所以没有写在类的里面，而是根据不同的情况来选则不同的图片资源

{ RolePlayer }

procedure TRole.AddMoveList(Move: PTRoleMove);
begin
  if FBeginMove = nil then
  begin
    FBeginMove := Move;
    FEndMove := Move;
  end
  else
  begin
    FEndMove.Next := Move;
    FEndMove := FEndMove.Next;
  end;
end;

constructor TRole.Create(PosX, PosY, Id, Speed: Integer; Name: AnsiString);
begin
  bmpE := TBitmap32.Create;
  bmpW := TBitmap32.Create;
  bmpN := TBitmap32.Create;
  bmpS := TBitmap32.Create;
  bmpE.DrawMode := dmTransparent;
  bmpN.DrawMode := dmTransparent;
  bmpS.DrawMode := dmTransparent;
  bmpW.DrawMode := dmTransparent;
  LoadBitmap32FromPNG(bmpE, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpN, 'img/redp_m_north.png');
  LoadBitmap32FromPNG(bmpS, 'img/redp_m_south.png');
  LoadBitmap32FromPNG(bmpW, 'img/redp_m_west.png');
  FPos.X := PosX;
  FPos.Y := PosY;
  FBmp := bmpS;
  FId := Id;
  FSpeed := Speed;
  FTurnTo := SOUTH;
  FName := Name;
  Ftick := 0;
  FState := ROLESTILL;
end;

procedure TRole.SetTurnTo(const Dir: FaceOrientate);
begin
  FTurnTo := Dir;
  case Dir of
    EAST:
      FBmp := bmpE;
    SOUTH:
      FBmp := bmpS;
    WEST:
      FBmp := bmpW;
    NORTH:
      FBmp := bmpN;
  end;
end;

procedure TRole.DelFirstMoveList;
var
  Ptr: PTRoleMove;
begin
  if FBeginMove = nil then
    Exit;
  Ptr := FBeginMove;
  FBeginMove := FBeginMove.Next;
  FreeMem(Ptr);
end;

function TRole.GetSpeed: Integer;
begin
  Result := (FSpeed - DEFAULT_SPEED) div SPEED_INTERVAL;
end;

function TRole.IsMoveListEmpty: Boolean;
begin
  Result := (FBeginMove = nil);
end;

procedure TRole.Move(Map: TPaintBox32; DesX, DesY: Integer);
begin
//
  if (FPos.X = DesX) and (FPos.Y = DesY) then
    Exit;
  if FPos.X = DesX then
  begin
    if FPos.Y < DesY then
    begin
//      if FTurnTo <> SOUTH then
//        SetTurnTo(SOUTH);
      MoveOneStepY(Map, FPos.X, FPos.Y, FPos.Y + 1, 40);
      if FSpeed * Fmovetime div 1000 > 40 then
      begin
        Inc(FPos.Y);
        Fmovetime := 0;
        DelFirstMoveList;
//        if IsMoveListEmpty then
          State := ROLESTILL;
      end;
    end;
    if FPos.Y > DesY then
    begin
//      if FTurnTo <> NORTH then
//        SetTurnTo(NORTH);
      MoveOneStepY(Map, FPos.X, FPos.Y, FPos.Y - 1, 40);
      if FSpeed * Fmovetime div 1000 > 40 then
      begin
        Dec(FPos.Y);
        Fmovetime := 0;
        DelFirstMoveList;
//        if IsMoveListEmpty then
          State := ROLESTILL;
      end;
    end;
  end;
  if FPos.Y = DesY then
  begin
    if FPos.X < DesX then
    begin
//      if FTurnTo <> EAST then
//        SetTurnTo(EAST);
      MoveOneStepX(Map, FPos.Y, FPos.X, FPos.X + 1, 40);
      if FSpeed * Fmovetime div 1000 > 40 then
      begin
        Inc(FPos.X);
        Fmovetime := 0;
        DelFirstMoveList;
//        if IsMoveListEmpty then
          State := ROLESTILL;
      end;
    end;
    if FPos.X > DesX then
    begin
//      if FTurnTo <> WEST then
//        SetTurnTo(WEST);
      MoveOneStepX(Map, FPos.Y, FPos.X, FPos.X - 1, 40);
      if FSpeed * Fmovetime div 1000 > 40 then
      begin
        Dec(FPos.X);
        Fmovetime := 0;
        DelFirstMoveList;
//        if IsMoveListEmpty then
          State := ROLESTILL;
      end;
    end;
  end;
end;

procedure TRole.MoveOneStepX(Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer);
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY, Distance, Frame: Integer;
begin
  piceRoleW := FBmp.Width div 6;
  Distance := FSpeed * Fmovetime div 1000;
  Frame := Fmovetime * FPS div 1000 mod 6;
  if SrcX < DesX then
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * 40 + Distance;
    PosY := SrcY * 40 - (bmpRoleH - 40);
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * 40 - Distance;
    PosY := SrcY * 40 - (bmpRoleH - 40);
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end;
  Map.Invalidate;
end;

procedure TRole.MoveOneStepY(Map: TPaintBox32; SrcX, SrcY, DesY: Integer; W: Integer);
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY, Distance, Frame: Integer;
begin
  piceRoleW := FBmp.Width div 6;
  Distance := FSpeed * Fmovetime div 1000;
  Frame := Fmovetime * FPS div 1000 mod 6;
  if SrcY < DesY then
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * 40;
    PosY := SrcY * 40 - (bmpRoleH - 40) + Distance;
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * 40;
    PosY := SrcY * 40 - (bmpRoleH - 40) - Distance;
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end;
  Map.Invalidate;
end;

procedure TRole.SetBomb;
begin
// 目前想的是bomb的创建不在role中创建，只是发消息在Map层实现创建和销毁。
end;

procedure TRole.SetSpeed(const Value: Integer);
begin
  FSpeed := DEFAULT_SPEED + Value * SPEED_INTERVAL;
end;

procedure TRole.SetState(const Value: RoleState);
begin
  FState := Value;
end;

{ TMyTimer }

constructor TMyTimer.Create;
begin
//  OldTime := Now;
//  NewTime := Now;
end;

procedure TMyTimer.dowork(proce: Tprocess; Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer; interval, timeTurnoff: Integer);
var
  tick: Integer;
  oldtime: TDateTime;
  newtime: TDateTime;
begin
  tick := 0;
  oldtime := Now;
  while tick <> timeTurnoff do
  begin
    newtime := Now;
    if MilliSecondsBetween(newtime, oldtime) >= interval * tick then
    begin
      proce(Map, SrcY, SrcX, DesX, 40);
      Inc(tick);
      oldtime := newtime;
    end;

  end;
end;

end.


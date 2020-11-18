unit Role;

interface

uses
  System.Classes, GR32, GR32_Image, GR32_PNG, ChatProtocol, System.SysUtils,
  System.DateUtils;

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
    FSpeed: Integer;
    Ftick: Integer;
    Ftime: TMyTimer;
  public
    FBmp: TBitmap32;
    constructor Create(PosX, PosY, Id, Speed: Integer; Name: AnsiString);
    property Id: Integer read FId;
    property Name: AnsiString read FName; //先暂时没有添加改名接口
    property x: Integer read FPos.x;
    property y: Integer read FPos.y;
  public
    procedure Move(Map: TPaintBox32; DesX, DesY: Integer);
    procedure MoveOneStepX(Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer); //W 为正方形格子的宽度
    procedure MoveOneStepY(Map: TPaintBox32; SrcX, SrcY, DesY: Integer; W: Integer);
    procedure FaceTo(Dir: FaceOrientate);
    procedure SetBomb;
  end;

implementation

var
  bmpE, bmpW, bmpS, bmpN: TBitmap32; //相当于这个类的图片资源，所以没有写在类的里面，而是根据不同的情况来选则不同的图片资源

{ RolePlayer }

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
//  FName := StrPas(Name);
  FName := Name;
  Ftick := 0;
  Ftime := TMyTimer.Create;
end;

procedure TRole.FaceTo(Dir: FaceOrientate);
begin
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

procedure TRole.Move(Map: TPaintBox32; DesX, DesY: Integer);
begin
//
  if (FPos.X = DesX) and (FPos.Y = DesY) then
    Exit;
  if FPos.X = DesX then
  begin
    if FPos.Y < DesY then
    begin
      FaceTo(SOUTH);
      MoveOneStepY(Map, FPos.X, FPos.Y, FPos.Y + 1, 40);
//      Ftime.dowork(MoveOneStepY,Map, SrcX, SrcY, SrcY + 1, 40, 100, 6);
      if Ftick = 0 then
        Inc(FPos.Y);
    end;
    if FPos.Y > DesY then
    begin
      FaceTo(NORTH);
      MoveOneStepY(Map, FPos.X, FPos.Y, FPos.Y + 1, 40);
//      Ftime.dowork(MoveOneStepY,Map, FPos.X, FPos.Y, FPos.Y - 1, 40, 100, 6);
      if Ftick = 0 then
        Dec(FPos.Y);
    end;
  end;
  if FPos.Y = DesY then
  begin
    if FPos.X < DesX then
    begin
      FaceTo(EAST);
      MoveOneStepX(Map, FPos.Y, FPos.X, FPos.X + 1, 40);
//      Ftime.dowork(MoveOneStepX,Map, SrcY, SrcX, DesX + 1, 40, 100, 6);
//      SrcX := SrcX + 1;
      if Ftick = 0 then
        Inc(FPos.X);
    end;
    if FPos.X > DesX then
    begin
      FaceTo(WEST);
      MoveOneStepX(Map, FPos.Y, FPos.X, FPos.X - 1, 40);
//      Ftime.dowork(MoveOneStepX,Map, SrcY, SrcX, DesX - 1, 40, 100, 6);
//      SrcX := SrcX - 1;
      if Ftick = 0 then
        Dec(FPos.X);
    end;
  end;
end;

procedure TRole.MoveOneStepX(Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer);
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY: Integer;
begin
  piceRoleW := FBmp.Width div 6;
//  while Ftick <> 6 do
//  begin
  if SrcX < DesX then
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * 40 + (Ftick + 1) * 40 div 6;
    PosY := SrcY * 40 - (bmpRoleH - 40);
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Ftick, 0, piceRoleW * (Ftick + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * 40 - (Ftick + 1) * 40 div 6;
    PosY := SrcY * 40 - (bmpRoleH - 40);
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Ftick, 0, piceRoleW * (Ftick + 1), bmpRoleH));
  end;
  Map.Invalidate;
  Inc(Ftick);
//  end;
  if Ftick = 6 then
    Ftick := 0;
end;

procedure TRole.MoveOneStepY(Map: TPaintBox32; SrcX, SrcY, DesY: Integer; W: Integer);
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY: Integer;
begin
  piceRoleW := FBmp.Width div 6;
//  while Ftick <> 6 do
//  begin
  if SrcY < DesY then
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * 40;
    PosY := SrcY * 40 - (bmpRoleH - 40) + (Ftick + 1) * 40 div 6;
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Ftick, 0, piceRoleW * (Ftick + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * 40;
    PosY := SrcY * 40 - (bmpRoleH - 40) - (Ftick + 1) * 40 div 6;
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Ftick, 0, piceRoleW * (Ftick + 1), bmpRoleH));
  end;
  Map.Invalidate;
  Inc(Ftick);
//  end;
  if Ftick = 6 then
    Ftick := 0;
end;

procedure TRole.SetBomb;
begin
// 目前想的是bomb的创建不在role中创建，只是发消息在Map层实现创建和销毁。
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


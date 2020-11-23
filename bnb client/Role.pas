unit Role;

interface

uses
  System.Classes, GR32, GR32_Image, GR32_PNG, ChatProtocol, System.SysUtils,
  System.DateUtils;

type
  TRole = class
  private
    FId: Integer;
    FName: AnsiString;
    FPos: TPoint;
    FTurnTo: FaceOrientate;
    FState: RoleState;
    FBmp: TBitmap32;
  public
    function IsMoveListEmpty: Boolean;
    function GetSpeed: Integer;
    function GetBmp: TBitmap32;
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
    Fmovetime: Integer;
    FSpeed: Integer;
    FMoveList: PTRoleMove;
    FBeginMove: PTRoleMove;
    FEndMove: PTRoleMove;
    NowFrame: Integer;

     //test
    oldtime: TDateTime;
    newtime: TDateTime;
    actrolspeed: Integer;
    first: Boolean;
    constructor Create(PosX, PosY, Id, Speed: Integer; Name: AnsiString);
    property Id: Integer read FId;
    property Name: AnsiString read FName; //先暂时没有添加改名接口
    property X: Integer read FPos.x;
    property Y: Integer read FPos.y;
    property State: RoleState read FState write SetState;
    property TurnTo: FaceOrientate read FTurnTo write SetTurnTo;
    property Speed: Integer read GetSpeed write SetSpeed;
    property Bmp: TBitmap32 read GetBmp;
  end;

implementation

var
  bmpE, bmpW, bmpS, bmpN: TBitmap32; //相当于这个类的图片资源，所以没有写在类的里面，而是根据不同的情况来选则不同的图片资源
  bmpE_Stop, bmpW_Stop, bmpS_Stop, bmpN_Stop: TBitmap32;
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
  bmpE_Stop := TBitmap32.Create;
  bmpW_Stop := TBitmap32.Create;
  bmpN_Stop := TBitmap32.Create;
  bmpS_Stop := TBitmap32.Create;
  bmpE.DrawMode := dmTransparent;
  bmpN.DrawMode := dmTransparent;
  bmpS.DrawMode := dmTransparent;
  bmpW.DrawMode := dmTransparent;
  bmpE_Stop.DrawMode := dmTransparent;
  bmpN_Stop.DrawMode := dmTransparent;
  bmpS_Stop.DrawMode := dmTransparent;
  bmpW_Stop.DrawMode := dmTransparent;
  LoadBitmap32FromPNG(bmpE, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpN, 'img/redp_m_north.png');
  LoadBitmap32FromPNG(bmpS, 'img/redp_m_south.png');
  LoadBitmap32FromPNG(bmpW, 'img/redp_m_west.png');
  LoadBitmap32FromPNG(bmpE_Stop, 'img/redp_s_east.png');
  LoadBitmap32FromPNG(bmpN_Stop, 'img/redp_s_north.png');
  LoadBitmap32FromPNG(bmpS_Stop, 'img/redp_s_south.png');
  LoadBitmap32FromPNG(bmpW_Stop, 'img/redp_s_west.png');
  FPos.X := PosX;
  FPos.Y := PosY;
  FBmp := bmpS;
  FId := Id;
  FSpeed := Speed;
  FTurnTo := SOUTH;
  FName := Name;
  NowFrame := 0;
  FState := ROLESTILL;
  //test
  first := True;
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

function TRole.GetBmp: TBitmap32;
var
  bmp: TBitmap32;
begin
//  if FState = ROLEMOVE then
//  begin
  case FTurnTo of
    EAST:
      bmp := bmpE;
    SOUTH:
      bmp := bmpS;
    WEST:
      bmp := bmpW;
    NORTH:
      bmp := bmpN;
  end;
//  end
//  else
//  begin
//    case FTurnTo of
//      EAST:
//        bmp := bmpE_Stop;
//      SOUTH:
//        bmp := bmpS_Stop;
//      WEST:
//        bmp := bmpW_Stop;
//      NORTH:
//        bmp := bmpN_Stop;
//    end;
//  end;
  Result := bmp;
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
      MoveOneStepY(Map, FPos.X, FPos.Y, FPos.Y + 1, CELL_WIDTH);
      if (FSpeed * 2 - 20) * Fmovetime div 1000 > CELL_WIDTH then
      begin

      //test
        if first then
        begin
          first := False;
          newtime := Now;
          oldtime := Now;
        end
        else
        begin
          newtime := Now;
          actrolspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
          oldtime := newtime;
        end;
        ////////test
        NowFrame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
        Inc(FPos.Y);
        Fmovetime := 0;
        DelFirstMoveList;
        State := ROLESTILL;
      end;
    end;
    if FPos.Y > DesY then
    begin
      MoveOneStepY(Map, FPos.X, FPos.Y, FPos.Y - 1, CELL_WIDTH);
      if (FSpeed * 2 - 20) * Fmovetime div 1000 > CELL_WIDTH then
      begin
        //test
        if first then
        begin
          first := False;
          newtime := Now;
          oldtime := Now;
        end
        else
        begin
          newtime := Now;
          actrolspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
          oldtime := newtime;
        end;
        //test
        NowFrame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
        Dec(FPos.Y);
        Fmovetime := 0;
        DelFirstMoveList;
        State := ROLESTILL;
      end;
    end;
  end;
  if FPos.Y = DesY then
  begin
    if FPos.X < DesX then
    begin
      MoveOneStepX(Map, FPos.Y, FPos.X, FPos.X + 1, CELL_WIDTH);
      if (FSpeed * 2 - 20) * Fmovetime div 1000 > CELL_WIDTH then
      begin
        //test
        if first then
        begin
          first := False;
          newtime := Now;
          oldtime := Now;
        end
        else
        begin
          newtime := Now;
          actrolspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
          oldtime := newtime;
        end;
        //test
        NowFrame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
        Inc(FPos.X);
        Fmovetime := 0;
        DelFirstMoveList;
        State := ROLESTILL;
      end;
    end;
    if FPos.X > DesX then
    begin
      MoveOneStepX(Map, FPos.Y, FPos.X, FPos.X - 1, CELL_WIDTH);
      if (FSpeed * 2 - 20) * Fmovetime div 1000 > CELL_WIDTH then
      begin
        //test
        if first then
        begin
          first := False;
          newtime := Now;
          oldtime := Now;
        end
        else
        begin
          newtime := Now;
          actrolspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
          oldtime := newtime;
        end;
        //test
        NowFrame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
        Dec(FPos.X);
        Fmovetime := 0;
        DelFirstMoveList;
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
  Distance := (FSpeed * 2 - 20) * Fmovetime div 1000;
  Frame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
  if SrcX < DesX then
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * CELL_WIDTH + Distance;
    PosY := SrcY * CELL_WIDTH - (bmpRoleH - CELL_WIDTH);
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * CELL_WIDTH - Distance;
    PosY := SrcY * CELL_WIDTH - (bmpRoleH - CELL_WIDTH);
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
  Distance := (FSpeed * 2 - 20) * Fmovetime div 1000;
  Frame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
  if SrcY < DesY then
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * CELL_WIDTH;
    PosY := SrcY * CELL_WIDTH - (bmpRoleH - CELL_WIDTH) + Distance;
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * CELL_WIDTH;
    PosY := SrcY * CELL_WIDTH - (bmpRoleH - CELL_WIDTH) - Distance;
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

end.


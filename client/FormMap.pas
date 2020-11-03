unit FormMap;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  ChatProtocol, Vcl.StdCtrls, ChatManager, GR32, GR32_Image, GR32_PNG,
  Vcl.ExtCtrls;

type
  TFrmMap = class(TForm)
    pntbx: TPaintBox32;
    procedure FormCreate(Sender: TObject);
    procedure doWork(Sender: TObject);
    procedure processAni(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FBmpRole: TBitmap32;
    FBmpBoom: TBitmap32;
    Fmsgs: TChatMsgs;
    bmpRoleW, bmpRoleH, piceRoleW: Integer;
    bmpBoomW, bmpBoomH, piceBoomW: Integer;
    timer: TTimer;
    ticksix: Integer;
    tickfour: Integer;
    color: TColor;
    posX, posY: Integer;
    FOldMap: array of Integer;
    FMap: array of Integer;
//    FMapChanged: Boolean;
//    FMap:
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

procedure TFrmMap.doWork(Sender: TObject);
var
  MsgPtr: PChatMsg;
  ServerMsgPtr: PServerMessage;
  MapPtr: PTSMap;
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
          S_BOMBBOOM:
            begin
              BoomFlor := PTBombBoom(MsgPtr);
//              doBoomFlor(BoomFlor);
            end;

        end;
      finally
        FreeMem(MsgPtr);
      end;
    end;
  end;
  processAni(self);
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
  FBmpBoom := TBitmap32.Create;
  FBmpRole.DrawMode := dmTransparent;
  bmpE.DrawMode := dmTransparent;
  bmpN.DrawMode := dmTransparent;
  bmpS.DrawMode := dmTransparent;
  bmpWW.DrawMode := dmTransparent;
  FBmpBoom.DrawMode := dmTransparent;
  LoadBitmap32FromPNG(FBmpRole, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpE, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpN, 'img/redp_m_north.png');
  LoadBitmap32FromPNG(bmpS, 'img/redp_m_south.png');
  LoadBitmap32FromPNG(bmpWW, 'img/redp_m_west.png');
  LoadBitmap32FromPNG(FBmpBoom, 'img/bomb.png');

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

  posX := 0;
  posY := 0;

  SetLength(FMap, 400);
  SetLength(FOldMap, 400);
  FillMemory(FMap, 400, 0);
  FillMemory(FOldMap, 400, 0);

  timer := TTimer.Create(Self);
  timer.OnTimer := doWork;
  timer.Interval := 500;
  timer.Enabled := True;
end;

procedure TFrmMap.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 32 then
  begin
    ChatMgr.RequestBoom;
    exit;
  end;

  if Key = Word('A') then
  begin
//    posX := posX - 40;
    FBmpRole := bmpWW;
  end;
  if Key = Word('S') then
  begin
//    posY := posY + 40;
    FBmpRole := bmpS;
  end;
  if Key = Word('D') then
  begin
//    posX := posX + 40;
    FBmpRole := bmpE;
  end;
  if Key = Word('W') then
  begin
//    posY := posY - 40;
    FBmpRole := bmpN;
  end;
  ChatMgr.RequestMove(Key);
end;

procedure TFrmMap.processAni(Sender: TObject);
var
  x, y, i, j: Integer;
  drawX, drawY: Integer;
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

  //���ذ�
  x := 0;
  y := 0;
  while x < 800 do
  begin
    while y < 800 do
    begin
      i := x div 40;
      j := y div 40;
      if FMap[i * 20 + j] = 1 then
      begin
        drawY := y - (bmp3.Height - 40);
        bmp3.DrawTo(pntbx.Buffer, x, drawY);
      end
      else if FMap[i * 20 + j] = 2 then
      begin
        drawY := y - (bmp4.Height - 40);
        bmp4.DrawTo(pntbx.Buffer, x, drawY);
      end//      else if (FMap[i * 20 + j] = 3) and (FOldMap[i * 20 + j] <> 3) then
      else if FMap[i * 20 + j] = 3 then
      begin
        posX := x;
        posY := y;
        drawY := posY - (FBmpRole.Height - 40);
        FBmpRole.DrawTo(pntbx.Buffer, rect(posX, drawY, W + posX, drawY + bmpRoleH), Rect(piceRoleW * ticksix, 0, piceRoleW * (ticksix + 1), bmpRoleH));
      end
      else if FMap[i * 20 + j] = 4 then
      begin
        posX := x;
        posY := y;
        drawY := posY - (FBmpBoom.Height - 40) - 10;
        FBmpBoom.DrawTo(pntbx.Buffer, rect(posX, drawY, W + posX, drawY + bmpRoleH), Rect(piceBoomW * tickfour, 0, piceBoomW * (tickfour + 1), bmpBoomH));
      end;
      y := y + 40;
    end;
    x := x + 40;
    y := 0;
  end;

//  CopyMemory(@FOldMap[0], @FMap[0], 1600);
  //���ˣ����ֻ�ͼ
//  drawY  := posY - (bmp.Height - 40);
//  bmp.DrawTo(pntbx.Buffer, rect(posX, drawY, W + posX, drawY + bmpH), Rect(piceW * tick, 0, piceW * (tick + 1), bmpH));
  //��͸���ɰ�
//  pntbx.Buffer.Draw(0, 0, bmp3);

  pntbx.Invalidate;

  ticksix := (ticksix + 1) mod 6;
  tickfour := (tickfour + 1) mod 4;
//  timer.Enabled := False;

end;

end.


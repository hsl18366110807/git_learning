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
//    procedure Button1Click(Sender: TObject);
//    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure doWork(Sender: TObject);
    procedure processAni(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure btn1Click(Sender: TObject);
  private
    Fmsgs: TChatMsgs;
    FMap: array of Integer;
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
  bmp, bmp2, bmp3, bmp4: TBitmap32;
  bmpE, bmpWW, bmpS, bmpN: TBitmap32;
  timer: TTimer;
  bmpW, bmpH, piceW: Integer;
  tick: Integer;
  color: TColor;
  posX, posY: Integer;


//procedure TFrmMap.FormKeyDown(Sender: TObject; var Key: Word;
//  Shift: TShiftState);
//begin
//  if Key = Word('A') then
//  begin
//    posX := posX - 40;
//    bmp := bmpWW;
//  end;
//  if Key = Word('S') then
//  begin
//    posY := posY + 40;
//    bmp := bmpS;
//  end;
//  if Key = Word('D') then
//  begin
//    posX := posX + 40;
//    bmp := bmpE;
//  end;
//  if Key = Word('W') then
//  begin
//    posY := posY - 40;
//    bmp := bmpN;
//  end;
//  bmpW := bmp.Width;
//  bmpH := bmp.Height;
//  piceW := bmpW div 6;
//end;

procedure TFrmMap.doWork(Sender: TObject);
var
  MsgPtr: PChatMsg;
  ServerMsgPtr: PServerMessage;
  MapPtr: PTSMap;
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
  bmp := TBitmap32.Create;
  bmpE := TBitmap32.Create;
  bmpWW := TBitmap32.Create;
  bmpN := TBitmap32.Create;
  bmpS := TBitmap32.Create;
  bmp.DrawMode := dmTransparent;
  bmpE.DrawMode := dmTransparent;
  bmpN.DrawMode := dmTransparent;
  bmpS.DrawMode := dmTransparent;
  bmpWW.DrawMode := dmTransparent;
  LoadBitmap32FromPNG(bmp, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpE, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpN, 'img/redp_m_north.png');
  LoadBitmap32FromPNG(bmpS, 'img/redp_m_south.png');
  LoadBitmap32FromPNG(bmpWW, 'img/redp_m_west.png');
  bmpW := bmp.Width;
  bmpH := bmp.Height;
  piceW := bmpW div 6;

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
  FillMemory(FMap, 400, 0);

  timer := TTimer.Create(Self);
  timer.OnTimer := doWork;
  timer.Interval := 500;
  timer.Enabled := True;
end;

procedure TFrmMap.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
//  if Key = Word('A') then
//  begin
//    posX := posX - 40;
////    bmp := bmpWW;
//  end;
//  if Key = Word('S') then
//  begin
//    posY := posY + 40;
////    bmp := bmpS;
//  end;
//  if Key = Word('D') then
//  begin
//    posX := posX + 40;
////    bmp := bmpE;
//  end;
//  if Key = Word('W') then
//  begin
//    posY := posY - 40;
////    bmp := bmpN;
//  end;

  ChatMgr.RequestMove(Key);
//  bmpW := bmp.Width;
//  bmpH := bmp.Height;
//  piceW := bmpW div 6;
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
      end
      else if FMap[i * 20 + j] = 3 then
      begin
         posX := x;
         posY := y;
        drawY := posY - (bmp.Height - 40);
        bmp.DrawTo(pntbx.Buffer, rect(posX, drawY, W + posX, drawY + bmpH), Rect(piceW * tick, 0, piceW * (tick + 1), bmpH));
      end;

      y := y + 40;
    end;
    x := x + 40;
    y := 0;
  end;
  //���ˣ����ֻ�ͼ
//  drawY  := posY - (bmp.Height - 40);
//  bmp.DrawTo(pntbx.Buffer, rect(posX, drawY, W + posX, drawY + bmpH), Rect(piceW * tick, 0, piceW * (tick + 1), bmpH));
  //��͸���ɰ�
//  pntbx.Buffer.Draw(0, 0, bmp3);

  pntbx.Invalidate;

  tick := (tick + 1) mod 6;
end;

end.


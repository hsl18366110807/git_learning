unit Role;

interface

uses
  System.Classes, GR32, GR32_Image, GR32_PNG, ChatProtocol, System.SysUtils;

type
  TRole = class(TBitmap32)
  private
    FId: Integer;
    FName: AnsiString;
    FBmp: TBitmap32;
    FPos: TPoint;
    FSpeed: Integer;
  public
    constructor Create(PosX, PosY, Id, Speed: Integer; Name: array of AnsiChar);
    property Id: Integer read FId;
    property Name: AnsiString read FName; //����ʱû����Ӹ����ӿ�
  public
    procedure Move(Map: TPaintBox32; SrcX, SrcY, DesX, DesY: Integer);
    procedure FaceTo(Dir: FaceOrientate);
    procedure SetBomb;
  end;

implementation

var
  bmpE, bmpW, bmpS, bmpN: TBitmap32; //�൱��������ͼƬ��Դ������û��д��������棬���Ǹ��ݲ�ͬ�������ѡ��ͬ��ͼƬ��Դ

{ RolePlayer }

constructor TRole.Create(PosX, PosY, Id, Speed: Integer; Name: array of AnsiChar);
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
  FName := StrPas(Name);
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

procedure TRole.Move(Map: TPaintBox32; SrcX, SrcY, DesX, DesY: Integer);
begin
//
end;

procedure TRole.SetBomb;
begin
// Ŀǰ�����bomb�Ĵ�������role�д�����ֻ�Ƿ���Ϣ��Map��ʵ�ִ��������١�
end;

end.


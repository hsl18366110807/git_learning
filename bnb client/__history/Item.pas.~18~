unit Item;

interface

uses
  System.Classes, GR32, GR32_Png;

type
  TItem = class
  public
    constructor Create(x, y, typeid: Integer);
  private
    FPos: TPoint;
    FType: Integer;
    FAutoFrame: Integer;
    FFloatDistance: Integer;
    FShowBmpType: Integer; //0 autoframe 1 floatframe
    FFloatDistanceOrder: Boolean;
  public
    function GetFloatBmp: TBitmap32;
    function GetAutoBmp: TBitmap32;
    procedure SetShowBmpType(ShowBmpTypeId: Integer);
    procedure SetFloatDistance(value: Integer);
    procedure SetFFloatDistanceOrder(value: Boolean);
    property FloatBmp: TBitmap32 read GetFloatBmp;
    property AutoBmp: TBitmap32 read GetAutoBmp;
    property X: Integer read FPos.X;
    property Y: Integer read FPos.Y;
    property ShowBmpType: Integer read FShowBmpType write SetShowBmpType;
    property FloatDistance: Integer read FFloatDistance write SetFloatDistance;
    property FloatDistanceOrder: Boolean read FFloatDistanceOrder write SetFFloatDistanceOrder;
  end;

var
  BmpShoes: TBitmap32;

implementation

{ TItem }

constructor TItem.Create(x, y, typeid: Integer);
begin
  BmpShoes := TBitmap32.Create;
  BmpShoes.DrawMode := dmBlend;
  LoadBitmap32FromPNG(BmpShoes, 'img/shoe.png');
  FPos.X := x;
  FPos.Y := y;
  FType := typeid;
  FAutoFrame := 0;
  FFloatDistance := 0;
  FFloatDistanceOrder := True;
end;

function TItem.GetAutoBmp: TBitmap32;
begin
//
end;

function TItem.GetFloatBmp: TBitmap32;
var
  bmp: TBitmap32;
begin
  case FType of
    5:
      bmp := BmpShoes;
  end;
  Result := bmp;
end;

procedure TItem.SetFFloatDistanceOrder(value: Boolean);
begin
  FFloatDistanceOrder := value;
end;

procedure TItem.SetFloatDistance(value: Integer);
begin
  FFloatDistance := value;
end;

procedure TItem.SetShowBmpType(ShowBmpTypeId: Integer);
begin
  FShowBmpType := ShowBmpTypeId;
end;

end.


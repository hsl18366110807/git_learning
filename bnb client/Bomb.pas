unit Bomb;

interface
uses
  System.Classes, GR32;

type
  TBomb = class(TBitmap32)
  public
    constructor Create; override;
  end;
implementation

{ TBomb }

constructor TBomb.Create;
begin
  inherited;
  //
end;

end.

unit Item;

interface
 uses
   System.Classes, GR32;
   type
   TItem = class(TBitmap32)
     public
     constructor Create; override;
   end;
implementation

{ TItem }

constructor TItem.Create;
begin
  inherited;

end;

end.

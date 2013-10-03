unit uText;

interface

uses
  uRenderable,
  glr, glrMath;

type
  TglrText = class(Tglr2DRenderable, IglrText)
  protected
    FFont: IglrFont;
    FText: WideString;

    //Очищаем от непечатаемых символов
    function Clean(const aText: WideString): WideString;
    function GetFont(): IglrFont;
    procedure SetFont(aFont: IglrFont);
    function GetText(): WideString;
    procedure SetText(aText: WideString);
  public
    constructor Create(); override;
    destructor Destroy; override;

    property Font: IglrFont read GetFont write SetFont;
    property Text: WideString read GetText write SetText;

    procedure DoRender(); override;
  end;

implementation

uses
  ogl, uRenderer;

{ TdfText }

function TglrText.Clean(const aText: WideString): WideString;
var
  i, j: Integer;
begin
  if not Assigned(FFont) then
    Exit();

  j := 0;
  SetLength(Result, Length(aText));
  for i := 1 to Length(aText) do
    if FFont.IsSymbolExist(aText[i]) then
    begin
      Inc(j);
      Result[j] := aText[i];
    end;
  SetLength(Result, j);
end;

constructor TglrText.Create;
begin
  inherited;
  Material.Texture := nil;
  FScale := dfVec2f(1, 1);
end;

destructor TglrText.Destroy;
begin
  FFont := nil;
  inherited;
end;

procedure TglrText.DoRender;
begin
  gl.Disable(GL_LIGHTING);
  FFont.PrintText(Self);
  gl.Enable(GL_LIGHTING);
end;

function TglrText.GetFont: IglrFont;
begin
  Result := FFont;
end;

function TglrText.GetText: WideString;
begin
  Result := FText;
end;

procedure TglrText.SetFont(aFont: IglrFont);
begin
  FFont := aFont;
end;

procedure TglrText.SetText(aText: WideString);
begin
  FText := Clean(aText);
  with FFont.GetTextSize(Self) do
  begin
    Width  := x;
    Height := y;
  end;
//  RecalcCoords();
end;


end.

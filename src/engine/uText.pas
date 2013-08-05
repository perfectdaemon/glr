unit uText;

interface

uses
  uRenderable,
  dfHRenderer, dfMath;

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
//    procedure SetWidth(const aWidth: Single); override;
//    procedure SetHeight(const aHeight: Single); override;
  public
    constructor Create(); override;
    destructor Destroy; override;

    property Font: IglrFont read GetFont write SetFont;
    property Text: WideString read GetText write SetText;

    procedure DoRender(); override;
  end;

implementation

uses
  dfHGL, uRenderer;

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
  inherited;
  if not Assigned(FFont) then
    Exit();
//Пока вывод идет через 2DScene - это не нужно
//  gl.MatrixMode(GL_PROJECTION);
//  gl.PushMatrix();
//  gl.LoadIdentity();
//  vp := TheRenderer.Camera.GetViewport();
//  gl.Ortho(vp.X, vp.W, vp.H, vp.Y, -1, 1);
  gl.MatrixMode(GL_MODELVIEW);
  if FAbsolutePosition then
    gl.LoadIdentity();
  gl.Translatef(FPos.x, FPos.y, 0);
  gl.Rotatef(FRot, 0, 0, 1);
  //gl.Disable(GL_DEPTH_TEST);
  gl.Disable(GL_LIGHTING);

  FFont.PrintText(Self);

  gl.Enable(GL_LIGHTING);
  //gl.Enable(GL_DEPTH_TEST);
//Пока вывод идет через 2DScene - это не нужно
//  gl.MatrixMode(GL_PROJECTION);
//  gl.PopMatrix();
  gl.MatrixMode(GL_MODELVIEW);
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

//procedure TdfText.SetHeight(const aHeight: Single);
//begin
//  inherited;
//end;

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

//procedure TdfText.SetWidth(const aWidth: Single);
//begin
//  inherited;
//end;

end.

unit uGUI;

interface

uses
  dfHRenderer;

const
  DISAPPEAR_TIME = 1.0;

type
  TglrInGameGUI = class
  protected
    FFont: IglrFont;
    FCenterText: IglrText;
    Ft: Single;
  public
    constructor Create(aScene: Iglr2DScene); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);

    procedure ShowText(aText: WideString);
  end;

implementation

uses
  uGlobal,
  dfHUtility, dfTweener, dfMath;

{ TglrInGameGUI }

constructor TglrInGameGUI.Create(aScene: Iglr2DScene);
begin
  inherited Create();
  FFont := Factory.NewFont();
  FFont.AddSymbols(FONT_USUAL_CHARS);
  FFont.FontSize := 18;
  FFont.GenerateFromTTF('data\fonts\CyrillicCooper.ttf');

  FCenterText := Factory.NewText();
  FCenterText.Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);
  FCenterText.PivotPoint := ppCenter;
  FCenterText.Font := FFont;
  FCenterText.Material.MaterialOptions.Diffuse := dfVec4f(0.1, 0.1, 0.1, 1.0);
//  FCenterText.Text := 'CHECK it pleaSe ПриВет :)';

  aScene.RegisterElement(FCenterText);
end;

destructor TglrInGameGUI.Destroy;
begin

  inherited;
end;

procedure TglrInGameGUI.ShowText(aText: WideString);
begin
  FCenterText.Text := aText;
  Tweener.AddTweenPSingle(@FCenterText.Material.MaterialOptions.PDiffuse.x,
    tsElasticEaseIn, 0.1, 0.6, 2.5, 0.0);
  Ft := DISAPPEAR_TIME;
end;

procedure TglrInGameGUI.Update(const dt: Double);
begin

  if Ft > 0 then
  begin
    Ft := Ft - dt;
    FCenterText.Material.MaterialOptions.PDiffuse.w := Ft / DISAPPEAR_TIME;
  end
end;

end.

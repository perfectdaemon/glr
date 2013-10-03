unit uGUI;

interface

uses
  glr, glrMath;

const
  DISAPPEAR_TIME = 3.0;

type
  TglrInGameGUI = class
  protected
    FPoints: Integer;
    Ft: Single;
  public
    FCenterText, FShowText, FPointsText: IglrText;
    constructor Create(aScene: Iglr2DScene); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);

    procedure ShowText(aText: WideString);
    procedure AddScore(const aScore: Integer; aPoint: TdfVec2f); overload;
    procedure AddScore(const aScore: Integer); overload;

    property Score: Integer read FPoints;
  end;

implementation

uses
  SysUtils,
  uGlobal, uPopup,
  glrUtils, dfTweener;

{ TglrInGameGUI }

procedure TglrInGameGUI.AddScore(const aScore: Integer; aPoint: TdfVec2f);
begin
  Inc(FPoints, aScore);
  FPointsText.Text := 'ќчки: ' + IntToStr(FPoints);
  aPoint.x := Clamp(aPoint.x, 5, R.WindowWidth - 70);
  aPoint.y := Clamp(aPoint.y, 5, R.WindowHeight - 25);
  if aScore > 0 then
    AddNewPopup(aPoint.x, aPoint.y, '+' + IntToStr(aScore))
  else
    AddNewPopupEx(aPoint.x, aPoint.y, IntToStr(aScore), colorRed);
end;

procedure TglrInGameGUI.AddScore(const aScore: Integer);
begin
  Self.AddScore(aScore, dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2 + 30));
end;

constructor TglrInGameGUI.Create(aScene: Iglr2DScene);
begin
  inherited Create();
  FPoints := 0;

  FPointsText := Factory.NewText();
  FPointsText.Position := dfVec3f(12, 60, Z_HUD);
  FPointsText.PivotPoint := ppTopLeft;
  FPointsText.Font := fontCooper;
  FPointsText.Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);
  FPointsText.Text := 'ќчки: ';

  FCenterText := Factory.NewText();
  FCenterText.Position := dfVec3f(R.WindowWidth div 2, 40, Z_HUD);
  FCenterText.PivotPoint := ppTopCenter;
  FCenterText.Font := fontCooper;
  FCenterText.Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);
  FCenterText.Text := 'ќтбей как можно больше м€чей влево или вправо'#13#10'за отведенное врем€. „ем сильнее Ч тем лучше!'
    + #13#10'»спользуй ноги или голову, за руки Ч штраф!'
    + #13#10'—трелки Ч двигатьс€'
    + #13#10'Space Ч пауза вкл/выкл';

  FShowText := Factory.NewText();
  FShowText.Position := dfVec3f(R.WindowWidth div 2, R.WindowHeight div 2, Z_HUD);
  FShowText.PivotPoint := ppCenter;
  FShowText.Font := fontCooper;
  FShowText.Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);

  aScene.RootNode.AddChild(FCenterText);
  aScene.RootNode.AddChild(FShowText);
  aScene.RootNode.AddChild(FPointsText);
end;

destructor TglrInGameGUI.Destroy;
begin
  inherited;
end;

procedure TglrInGameGUI.ShowText(aText: WideString);
begin
  FShowText.Text := aText;
//  Tweener.AddTweenPSingle(@FShowText.Material.MaterialOptions.PDiffuse.x,
//    tsElasticEaseIn, 0.1, 0.6, 2.5, 0.0);
  Ft := DISAPPEAR_TIME;
end;

procedure TglrInGameGUI.Update(const dt: Double);
begin
  if Ft > 0 then
  begin
    Ft := Ft - dt;
    FShowText.Material.PDiffuse.w := Ft / DISAPPEAR_TIME;
  end
end;

end.

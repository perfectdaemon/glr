unit uGUI;

interface

uses
  glr, glrMath;

const
  DISAPPEAR_TIME = 3.0;

  HEALTHBAR_X = 30;
  HEALTHBAR_Y = 40;
  FORCEBAR_X  = 30;
  FORCEBAR_Y  = 60;

  TEXT_CANUSE  = '[Enter] — использовать спец. способность';
  TEXT_CANTUSE = 'Недостаточно энергии';

type
  TglrInGameGUI = class
  protected
    Ft: Single;
  public
    FShowText, FPlayerText, FPlayer2Text, FCanUseAbility: IglrText;
    FPlayerHealthBar, FPlayer2HealthBar,
    FPlayerForceBar, FPlayer2ForceBar: IglrGUISlider;
    constructor Create(aScene: Iglr2DScene); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);
    procedure UpdateSliders();

    procedure ShowText(aText: WideString);
    procedure ShowAbilityText(aText: WideString; aTime: Single);
  end;

implementation

uses
  SysUtils,
  uGlobal, uPopup, uGameScreen.Game,
  glrUtils, dfTweener;

procedure UpdateSliderValue(aSlider: IdfTweenObject; aValue: Single);
begin
  with IglrGUISlider(aSlider) do
    Value := Floor(aValue);
end;

{ TglrInGameGUI }

constructor TglrInGameGUI.Create(aScene: Iglr2DScene);
begin
  inherited Create();

  FPlayerText := Factory.NewText();
  with FPlayerText do
  begin
    Position := dfVec2f(HEALTHBAR_X, 10);
    PivotPoint := ppTopLeft;
    Font := fontCooper;
    Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);
    Z := Z_HUD;
    case game.GameMode of
      gmSingle:         Text := 'Игрок';
      gmTwoPlayersVs:   Text := 'Игрок 1';
    end;
  end;

  FPlayer2Text := Factory.NewText();
  with FPlayer2Text do
  begin
    Position := dfVec2f(R.WindowWidth - HEALTHBAR_X, 10);
    PivotPoint := ppTopRight;
    Font := fontCooper;
    Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);
    Z := Z_HUD;
    case game.GameMode of
      gmSingle:       Text := 'Противник';
      gmTwoPlayersVs: Text := 'Игрок 2';
    end;
  end;

  FShowText := Factory.NewText();
  with FShowText do
  begin
    Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);
    PivotPoint := ppCenter;
    Font := fontCooper;
    Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);
    Z := Z_HUD;
  end;

  FCanUseAbility := Factory.NewText();
  with FCanUseAbility do
  begin
    Position := dfVec2f(R.WindowWidth div 2, 70);
    PivotPoint := ppCenter;
    Font := fontCooper;
    Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);
    Z := Z_HUD;
  end;

  FPlayerHealthBar := Factory.NewGuiSlider();
  with FPlayerHealthBar do
  begin
    Material.Texture := atlasMain.LoadTexture(HEALTHSLIDER_BACK);
    UpdateTexCoords();
    SetSizeToTextureSize();
    with SliderOver do
    begin
      Material.Texture := atlasMain.LoadTexture(HEALTHSLIDER_OVER);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;
    SliderButton.Visible := False;
    Z := Z_HUD;
    Position := dfVec2f(HEALTHBAR_X , HEALTHBAR_Y);
  end;

  FPlayer2HealthBar := Factory.NewGuiSlider();
  with FPlayer2HealthBar do
  begin
    Material.Texture := atlasMain.LoadTexture(HEALTHSLIDER_BACK);
    UpdateTexCoords();
    SetSizeToTextureSize();
    with SliderOver do
    begin
      Material.Texture := atlasMain.LoadTexture(HEALTHSLIDER_OVER);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;
    SliderButton.Visible := False;
    Z := Z_HUD;
    Position := dfVec2f(R.WindowWidth - HEALTHBAR_X - Width, HEALTHBAR_Y);
  end;

  FPlayerForceBar := Factory.NewGuiSlider();
  with FPlayerForceBar do
  begin
    Material.Texture := atlasMain.LoadTexture(SLIDER_BACK);
    Material.Diffuse := dfVec4f(0.0, 0.0, 0.0, 1.0);
    UpdateTexCoords();
    SetSizeToTextureSize();
    with SliderOver do
    begin
      Material.Texture := atlasMain.LoadTexture(SLIDER_OVER);
      Material.Diffuse := dfVec4f(0.2, 0.2, 0.6, 1.0);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;
    SliderButton.Visible := False;
    Z := Z_HUD;
    Position := dfVec2f(FORCEBAR_X , FORCEBAR_Y);
  end;

  FPlayer2ForceBar := Factory.NewGuiSlider();
  with FPlayer2ForceBar do
  begin
    Material.Texture := atlasMain.LoadTexture(SLIDER_BACK);
    Material.Diffuse := dfVec4f(0.0, 0.0, 0.0, 1.0);
    UpdateTexCoords();
    SetSizeToTextureSize();
    with SliderOver do
    begin
      Material.Texture := atlasMain.LoadTexture(SLIDER_OVER);
      Material.Diffuse := dfVec4f(0.2, 0.2, 0.6, 1.0);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;
    SliderButton.Visible := False;
    Z := Z_HUD;
    Position := dfVec2f(R.WindowWidth - FORCEBAR_X - Width, FORCEBAR_Y);
  end;

  aScene.RegisterElement(FShowText);
  aScene.RegisterElement(FPlayerText);
  aScene.RegisterElement(FPlayerHealthBar);
  aScene.RegisterElement(FPlayerForceBar);
  aScene.RegisterElement(FPlayer2Text);
  aScene.RegisterElement(FPlayer2HealthBar);
  aScene.RegisterElement(FPlayer2ForceBar);
  aScene.RegisterElement(FCanUseAbility)
end;

destructor TglrInGameGUI.Destroy;
begin
  inherited;
end;

procedure TglrInGameGUI.ShowAbilityText(aText: WideString; aTime: Single);
begin

end;

procedure TglrInGameGUI.ShowText(aText: WideString);
begin
  FShowText.Text := aText;
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

procedure TglrInGameGUI.UpdateSliders;
begin
  Tweener.AddTweenInterface(FPlayerHealthBar, @UpdateSliderValue, tsExpoEaseIn, FPlayerHealthBar.Value, player.Health, 1.5, 0.0);
  Tweener.AddTweenInterface(FPlayer2HealthBar, @UpdateSliderValue, tsExpoEaseIn, FPlayer2HealthBar.Value, player2.Health, 1.5, 0.0);

  Tweener.AddTweenInterface(FPlayerForceBar, @UpdateSliderValue, tsExpoEaseIn, FPlayerForceBar.Value, player.Force, 1.5, 0.0);
  Tweener.AddTweenInterface(FPlayer2ForceBar, @UpdateSliderValue, tsExpoEaseIn, FPlayer2ForceBar.Value, player2.Force, 1.5, 0.0);
end;

end.

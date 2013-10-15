unit uGameScreen.MainMenu;

interface

uses
  glr,
  uGameScreen;

const
  //Общее время показа/скрытия
  TIME_FADEIN  = 0.65;
  TIME_FADEOUT = 0.7;

  //Время и пауза для отдельных элементов при твине
  TIME_NG = 2.3; TIME_NG_PAUSE = 0.6;
  TIME_SN = 2.3; TIME_SN_PAUSE = 0.7;
  TIME_EX = 2.3; TIME_EX_PAUSE = 0.8;

  TIME_ABOUTTEXT = 1.7; TIME_ABOUTTEXT_PAUSE = 1.2;

  ABOUT_OFFSET_Y = -75;
  IGDC_OFFSET_Y  = 30;
type
  TpdMainMenu = class (TpdGameScreen)
  private
    FGUIManager: IglrGUIManager;
    FScene: Iglr2DScene;
    FScrGame: TpdGameScreen;

    //Кнопки
    FBtnNewGame, FBtnSettings, FBtnExit: IglrGUITextButton;
    FFakeBackground: IglrSprite;

    FAboutText, FIGDCText: IglrText;

    FSettingsShowed: Boolean;
    Ft: Single; //Время для анимации

    //--settings menu
    FMusicText, FSoundText: IglrText;
    FSoundVol, FMusicVol: IglrGUISlider;

    FBtnBack: IglrGUITextButton;

    procedure LoadBackground();
    procedure LoadButtons();
    procedure LoadText();

    procedure LoadSettingsMenu();

    procedure ShowSettings();
    procedure HideSettings();
  protected
    procedure FadeIn(deltaTime: Double); override;
    procedure FadeOut(deltaTime: Double); override;

    procedure SetStatus(const aStatus: TpdGameScreenStatus); override;
    procedure FadeInComplete();
    procedure FadeOutComplete();
  public
    constructor Create(); override;
    destructor Destroy; override;

    procedure Load(); override;
    procedure Unload(); override;

    procedure Update(deltaTime: Double); override;

    procedure SetGameScreenLinks(aGame: TpdGameScreen);
  end;

var
  mainMenu: TpdMainMenu;

implementation

uses
  Windows,
  glrMath, ogl, dfTweener, uGameScreen.Game,
  uGlobal;

const
  //New game
  PLAY_X      = 500;
  PLAY_Y      = 250;

  //Settings
  SETTINGS_X  = PLAY_X;
  SETTINGS_Y  = PLAY_Y + 60;

  //Exit
  EXIT_X      = PLAY_X;
  EXIT_Y      = SETTINGS_Y + 60;

  //Settings offset
  TEXT_MUSIC_X = 350;
  TEXT_MUSIC_Y = 200;

  TEXT_SOUND_X = TEXT_MUSIC_X;
  TEXT_SOUND_Y = TEXT_MUSIC_Y + 50;

  SLIDER_SOUND_X = TEXT_MUSIC_X + 100;
  SLIDER_SOUND_Y = TEXT_SOUND_Y + 10;

  SLIDER_MUSIC_X = SLIDER_SOUND_X;
  SLIDER_MUSIC_Y = TEXT_MUSIC_Y + 10;

  BTN_BACK_X = PLAY_X;
  BTN_BACK_Y = 350;

  BTN_TEXT_OFFSET_X = -100;
  BTN_TEXT_OFFSET_Y = -15;

procedure MouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  sound.PlaySample(sClick);
  with mainMenu do
    if Sender = (FBtnNewGame as IglrGUIElement) then
    begin
      OnNotify(FScrGame, naSwitchTo);
    end

    else if Sender = (FBtnSettings as IglrGUIElement) then
    begin
      ShowSettings();
    end

    else if Sender = (FBtnBack as IglrGUIElement) then
    begin
      HideSettings();
    end

    else if Sender = (FBtnExit as IglrGUIElement) then
    begin
      OnNotify(nil, naQuitGame);
    end;
end;

procedure OnMouseOver(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin

end;

procedure OnMouseOut(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin

end;

procedure OnSliderValueChanged(Sender: IglrGUIElement; aNewValue: Integer);
begin
  with mainMenu do
    if Sender = FSoundVol as IglrGUIElement then
      sound.SoundVolume := aNewValue / 100
    else if Sender = FMusicVol as IglrGUIElement then
      sound.MusicVolume := aNewValue / 100;
end;

procedure TweenSceneOrigin(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdMainMenu do
    FScene.RootNode.PPosition.x := aValue;
end;

{ TpdMainMenu }

constructor TpdMainMenu.Create;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();

  LoadBackground();
  LoadButtons();
  LoadText();
  LoadSettingsMenu();

  //Бэкграунд для fade in/out
  FFakeBackground := Factory.NewHudSprite();
  FFakeBackground.Position := dfVec3f(0, 0, 100);
  FFakeBackground.Material.Diffuse := dfVec4f(1, 1, 1, 1);
  FFakeBackground.Material.Texture.BlendingMode := tbmTransparency;
  FFakeBackground.Width := R.WindowWidth;
  FFakeBackground.Height := R.WindowHeight;
  FScene.RootNode.AddChild(FFakeBackground);
end;

destructor TpdMainMenu.Destroy;
begin
  inherited;
end;

procedure TpdMainMenu.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := Ft / TIME_FADEIN;
  end;
end;

procedure TpdMainMenu.FadeInComplete;
begin
  Status := gssReady;

  FGUIManager.RegisterElement(FBtnNewGame);
  FGUIManager.RegisterElement(FBtnSettings);
  FGUIManager.RegisterElement(FBtnExit);
end;

procedure TpdMainMenu.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := 1 - Ft / TIME_FADEOUT;
  end;
end;

procedure TpdMainMenu.FadeOutComplete;
begin
  Status := gssNone;
end;

procedure TpdMainMenu.HideSettings;
begin
  if not FSettingsShowed then
    Exit();

  FGUIManager.UnregisterElement(FSoundVol);
  FGUIManager.UnregisterElement(FMusicVol);
  FGUIManager.UnregisterElement(FBtnBack);
  Tweener.AddTweenSingle(Self, @TweenSceneOrigin, tsExpoEaseIn, FScene.RootNode.Position.x, 0, 2.0, 0.0);
  FSettingsShowed := False;
end;

procedure TpdMainMenu.LoadButtons();
begin
  FBtnNewGame  := Factory.NewGUITextButton();
  FBtnSettings := Factory.NewGUITextButton();
  FBtnExit     := Factory.NewGUITextButton();

  with FBtnNewGame do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(PLAY_X, PLAY_Y, Z_MAINMENU);

    with TextObject do
    begin
      Font := fontSouvenir;
      Text := 'Игра';
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
      Material.Diffuse := colorWhite;
    end;
    TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnSettings do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(SETTINGS_X, SETTINGS_Y, Z_MAINMENU);

    with TextObject do
    begin
      Font := fontSouvenir;
      Text := 'Настройки';
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
      Material.Diffuse := colorWhite;
    end;

    TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnExit do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(EXIT_X, EXIT_Y, Z_MAINMENU);

    with TextObject do
    begin
      Font := fontSouvenir;
      Text := 'Выход';
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
      Material.Diffuse := colorWhite;
    end;

    TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  FBtnNewGame.OnMouseClick := MouseClick;
  FBtnSettings.OnMouseClick := MouseClick;
  FBtnExit.OnMouseClick := MouseClick;

  FScene.RootNode.AddChild(FBtnNewGame);
  FScene.RootNode.AddChild(FBtnSettings);
  FScene.RootNode.AddChild(FBtnExit);
end;

procedure TpdMainMenu.LoadSettingsMenu;
begin
  FMusicText := Factory.NewText();
  FSoundText := Factory.NewText();

  FSoundVol  := Factory.NewGUISlider();
  FMusicVol  := Factory.NewGUISlider();

  FBtnBack := Factory.NewGUITextButton();

  with FMusicText do
  begin
    Font := fontSouvenir;
    Text := 'Музыка';
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_MUSIC_X - R.WindowWidth, TEXT_MUSIC_Y, Z_MAINMENU);
    Material.Diffuse := colorWhite;
  end;

  with FSoundText do
  begin
    Font := fontSouvenir;
    Text := 'Звук';
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_SOUND_X - R.WindowWidth, TEXT_SOUND_Y, Z_MAINMENU);
    Material.Diffuse := colorWhite;
  end;

  //Sliders
  with FSoundVol do
  begin
    Material.Texture := atlasMain.LoadTexture(SLIDER_BACK);
    UpdateTexCoords();
    SetSizeToTextureSize();
    with SliderButton do
    begin
      Material.Texture := atlasMain.LoadTexture(SLIDER_BTN);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;

    with SliderOver do
    begin
      Material.Texture := atlasMain.LoadTexture(SLIDER_OVER);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;
    Position := dfVec3f(SLIDER_SOUND_X - R.WindowWidth, SLIDER_SOUND_Y, Z_MAINMENU);
    OnValueChanged := OnSliderValueChanged;
    OnMouseDown := MouseClick;
  end;

  with FMusicVol do
  begin
    Material.Texture := atlasMain.LoadTexture(SLIDER_BACK);
    UpdateTexCoords();
    SetSizeToTextureSize();
    with SliderButton do
    begin
      Material.Texture := atlasMain.LoadTexture(SLIDER_BTN);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;

    with SliderOver do
    begin
      Material.Texture := atlasMain.LoadTexture(SLIDER_OVER);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;
    Position := dfVec3f(SLIDER_MUSIC_X - R.WindowWidth, SLIDER_MUSIC_Y, Z_MAINMENU);
    OnValueChanged := OnSliderValueChanged;
    OnMouseDown := MouseClick;
  end;

  with FBtnBack do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(BTN_BACK_X - R.WindowWidth, BTN_BACK_Y, Z_MAINMENU);

    with TextObject do
    begin
      Font := fontSouvenir;
      Text := 'Применить';
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
      Material.Diffuse := colorWhite;
    end;

    TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;
  FBtnBack.OnMouseClick := MouseClick;

  FScene.RootNode.AddChild(FMusicText);
  FScene.RootNode.AddChild(FSoundText);

  FScene.RootNode.AddChild(FSoundVol);
  FScene.RootNode.AddChild(FMusicVol);
  FScene.RootNode.AddChild(FBtnBack);
end;

procedure TpdMainMenu.Load;
begin
  inherited;
  //Устанавливаем цвет фона при переключении окон
  gl.ClearColor(0, 30 / 255, 60 / 250, 1.0);

  FMusicVol.Value := 51;
  FSoundVol.Value := 51;
  sound.PlayMusic(musicMenu);

  R.RegisterScene(FScene);
end;

procedure TpdMainMenu.LoadBackground();
begin

end;

procedure TpdMainMenu.LoadText;
begin
  FAboutText := Factory.NewText();
  FIGDCText := Factory.NewText();

  with FAboutText do
  begin
    Font := fontSouvenir;
    Text := '— perfect.daemon —'#13#10'   октябрь 2013';
    PivotPoint := ppBottomCenter;
    Position := dfVec3f(R.WindowWidth div 2, R.WindowHeight + ABOUT_OFFSET_Y, Z_MAINMENU);
  end;

  with FIGDCText do
  begin
    Font := fontSouvenir;
    Text := 'MultiTetris — почти обычный тетрис,'
        +#13#10'в котором фигуры появляются со'
        +#13#10'всех 4-х сторон.'
        +#13#10#13#10'Только для igdc#100';
    PivotPoint := ppTopCenter;
    Position := dfVec3f(R.WindowWidth div 2, IGDC_OFFSET_Y, Z_MAINMENU);
  end;

  FScene.RootNode.AddChild(FAboutText);
  FScene.RootNode.AddChild(FIGDCText);
end;

procedure TpdMainMenu.SetGameScreenLinks(aGame: TpdGameScreen);
begin
  FScrGame := aGame;
end;

procedure TpdMainMenu.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
  case aStatus of
    gssNone: Exit;

    gssReady: Exit;

    gssFadeIn:
    begin
      sound.PlayMusic(musicMenu);
      FFakeBackground.Visible := True;
      Ft := TIME_FADEIN;

      Tweener.AddTweenPSingle(@FBtnNewGame.PPosition.y, tsExpoEaseIn, -70, PLAY_Y, TIME_NG, TIME_NG_PAUSE);
      Tweener.AddTweenPSingle(@FBtnSettings.PPosition.x, tsExpoEaseIn, R.WindowWidth + 250, SETTINGS_X, TIME_SN, TIME_SN_PAUSE);
      Tweener.AddTweenPSingle(@FBtnExit.PPosition.y, tsExpoEaseIn, R.WindowHeight + 70, EXIT_Y, TIME_EX, TIME_EX_PAUSE);

      Tweener.AddTweenPSingle(@FAboutText.PPosition.y, tsExpoEaseIn,
        R.WindowHeight + 70, R.WindowHeight + ABOUT_OFFSET_Y, TIME_ABOUTTEXT, TIME_ABOUTTEXT_PAUSE);

      Tweener.AddTweenPSingle(@FIGDCText.PPosition.Y, tsExpoEaseIn,
        -150, IGDC_OFFSET_Y, TIME_ABOUTTEXT + 1, TIME_ABOUTTEXT_PAUSE + 1.0);
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      FFakeBackground.Visible := True;
      Ft := TIME_FADEOUT;
      FGUIManager.UnregisterElement(FBtnNewGame);
      FGUIManager.UnregisterElement(FBtnSettings);
      FGUIManager.UnregisterElement(FBtnExit);
      sound.SetMusicFade(musicMenu, 3000);
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdMainMenu.ShowSettings;
begin
  if FSettingsShowed then
    Exit();

  FGUIManager.RegisterElement(FSoundVol);
  FGUIManager.RegisterElement(FMusicVol);
  FGUIManager.RegisterElement(FBtnBack);
  Tweener.AddTweenSingle(Self, @TweenSceneOrigin, tsExpoEaseIn, FScene.RootNode.Position.x, R.WindowWidth, 2.0, 0.0);

  FSettingsShowed := True;
end;

procedure TpdMainMenu.Unload;
begin
  inherited;

  R.UnregisterScene(FScene);
end;

procedure TpdMainMenu.Update(deltaTime: Double);
begin
  inherited;
  case FStatus of
    gssNone           : Exit;
    gssFadeIn         : FadeIn(deltaTime);
    gssFadeInComplete : Exit;
    gssFadeOut        : FadeOut(deltaTime);
    gssFadeOutComplete: Exit;

    gssReady:
    begin
      if (R.Input.IsKeyDown(VK_ESCAPE)) then
        if FSettingsShowed then
          HideSettings();
    end;
  end;
end;

end.

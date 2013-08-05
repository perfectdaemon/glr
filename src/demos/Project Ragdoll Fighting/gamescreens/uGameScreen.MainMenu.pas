unit uGameScreen.MainMenu;

interface

uses
  dfHRenderer, uSettings_SaveLoad,
  uGameScreen;

const
  SETTINGS_FILE = 'rdf.txt';

  //Общее время показа/скрытия
  TIME_FADEIN  = 0.65;
  TIME_FADEOUT = 0.7;

  //Время и пауза для отдельных элементов при твине
  TIME_NG = 2.3; TIME_NG_PAUSE = 0.6;
  TIME_CO = 2.3; TIME_CO_PAUSE = 0.7;
  TIME_SN = 2.3; TIME_SN_PAUSE = 0.8;
  TIME_EX = 2.3; TIME_EX_PAUSE = 0.9;

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
    FBtnNewGame, FBtnCoopGame, FBtnSettings, FBtnExit: IglrGUITextButton;
    FFakeBackground: IglrSprite;

    FAboutText, FIGDCText: IglrText;

    FSettingsShowed: Boolean;
    Ft: Single; //Время для анимации

    //--settings menu
    FMusicText, FSoundText, FDifficultyText, FDificultyDescriptionText: IglrText;
    FSoundVol, FMusicVol, FDifficulty: IglrGUISlider;

    FBtnBack: IglrGUITextButton;

    //--settings file
    FSettingsFile: TpdSettingsFile;

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

    procedure UpdateSettings();
  end;

var
  mainMenu: TpdMainMenu;

implementation

uses
  Windows,
  dfMath, dfHGL, dfTweener, uGameScreen.Game,
  uGlobal;

const
  //New game
  PLAY_X      = 512;
  PLAY_Y      = 250;

  //Co-op
  COOP_X = PLAY_X;
  COOP_Y = PLAY_Y + 80;

  //About
  SETTINGS_X  = PLAY_X;
  SETTINGS_Y  = COOP_Y + 80;

  //Exit
  EXIT_X      = PLAY_X;
  EXIT_Y      = SETTINGS_Y + 80;

  //Settings offset
  TEXT_MUSIC_X = 200;
  TEXT_MUSIC_Y = 200;

  TEXT_SOUND_X = TEXT_MUSIC_X;
  TEXT_SOUND_Y = TEXT_MUSIC_Y + 50;

  TEXT_DIFF_X  = TEXT_MUSIC_X;
  TEXT_DIFF_Y  = TEXT_SOUND_Y + 50;

  SLIDER_SOUND_X = 450;
  SLIDER_SOUND_Y = TEXT_SOUND_Y + 10;

  SLIDER_MUSIC_X = SLIDER_SOUND_X;
  SLIDER_MUSIC_Y = TEXT_MUSIC_Y + 10;

  SLIDER_DIFF_X = SLIDER_SOUND_X;
  SLIDER_DIFF_Y = TEXT_DIFF_Y + 10;

  TEXT_DIFFDESC_X = SLIDER_DIFF_X + 120;
  TEXT_DIFFDESC_Y = SLIDER_DIFF_Y + 30;

  BTN_BACK_X = 550;
  BTN_BACK_Y = 550;

  DESC: array[0..4] of WideString = ('Прогулка', 'Тренировка', 'Самое оно!', 'Без шансов', 'Только для Чака Норриса!');

procedure MouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  sound.PlaySample(sClick);
  with mainMenu do
    if Sender = (FBtnNewGame as IglrGUIElement) then
    begin
      (FScrGame as TpdGame).GameMode := gmSingle;
      OnNotify(FScrGame, naSwitchTo);
    end

    else if Sender = (FBtnCoopGame as IglrGUIElement) then
    begin
      (FScrGame as TpdGame).GameMode := gmTwoPlayersVs;
      OnNotify(FScrGame, naSwitchTo);
    end

    else if Sender = (FBtnSettings as IglrGUIElement) then
    begin
      ShowSettings();
    end

    else if Sender = (FBtnBack as IglrGUIElement) then
    begin
      HideSettings();
      UpdateSettings();
      FSettingsFile.SaveToFile(SETTINGS_FILE);
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
      sound.MusicVolume := aNewValue / 100
    else if Sender = FDifficulty as IglrGUIElement then
    begin
      uGlobal.difficulty := FDifficulty.Value;
      FDificultyDescriptionText.Text := DESC[difficulty];
    end;
         
end;

procedure TweenSceneOrigin(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdMainMenu do
    FScene.Origin := dfVec2f(aValue, 0);
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
  FFakeBackground.Position := dfVec2f(0, 0);
  FFakeBackground.Z := 100;
  FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
  FFakeBackground.Material.Texture.BlendingMode := tbmTransparency;
  FFakeBackground.Width := R.WindowWidth;
  FFakeBackground.Height := R.WindowHeight;
  FScene.RegisterElement(FFakeBackground);

  FSettingsFile := TpdSettingsFile.Initialize(SETTINGS_FILE);
end;

destructor TpdMainMenu.Destroy;
begin
  FScene.UnregisterElements();
  UpdateSettings();
  FSettingsFile.SaveToFile(SETTINGS_FILE);
  FSettingsFile.Free();
  inherited;
end;

procedure TpdMainMenu.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.MaterialOptions.PDiffuse.w := Ft / TIME_FADEIN;
  end;
end;

procedure TpdMainMenu.FadeInComplete;
begin
  Status := gssReady;

  FGUIManager.RegisterElement(FBtnNewGame);
  FGUIManager.RegisterElement(FBtnCoopGame);
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
    FFakeBackground.Material.MaterialOptions.PDiffuse.w := 1 - Ft / TIME_FADEOUT;
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
  FGUIManager.UnregisterElement(FDifficulty);
  FGUIManager.UnregisterElement(FBtnBack);
  Tweener.AddTweenSingle(Self, @TweenSceneOrigin, tsExpoEaseIn, FScene.Origin.x, 0, 2.0, 0.0);
  FSettingsShowed := False;
end;

procedure TpdMainMenu.LoadButtons();
begin
  FBtnNewGame  := Factory.NewGUITextButton();
  FBtnCoopGame  := Factory.NewGUITextButton();
  FBtnSettings := Factory.NewGUITextButton();
  FBtnExit     := Factory.NewGUITextButton();

  with FBtnNewGame do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(PLAY_X, PLAY_Y);
    Z := Z_MAINMENU_BUTTONS;

    with TextObject do
    begin
      Font := fontCooper;
      Text := 'Одиночная игра';
      PivotPoint := ppTopLeft;
      Position := dfVec2f(-150, -15);
      Material.MaterialOptions.Diffuse := colorWhite;
    end;
    TextureNormal := atlasMain.LoadTexture(PLAY_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(PLAY_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(PLAY_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnCoopGame do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(COOP_X, COOP_Y);
    Z := Z_MAINMENU_BUTTONS;

    with TextObject do
    begin
      Font := fontCooper;
      Text := 'Играть вдвоем';
      PivotPoint := ppTopLeft;
      Position := dfVec2f(-150, -15);
      Material.MaterialOptions.Diffuse := colorWhite;
    end;

    TextureNormal := atlasMain.LoadTexture(COOP_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(COOP_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(COOP_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnSettings do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(SETTINGS_X, SETTINGS_Y);
    Z := Z_MAINMENU_BUTTONS;

    with TextObject do
    begin
      Font := fontCooper;
      Text := 'Настройки';
      PivotPoint := ppTopLeft;
      Position := dfVec2f(-150, -15);
      Material.MaterialOptions.Diffuse := colorWhite;
    end;

    TextureNormal := atlasMain.LoadTexture(SETTINGS_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(SETTINGS_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(SETTINGS_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnExit do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(EXIT_X, EXIT_Y);
    Z := Z_MAINMENU_BUTTONS;

    with TextObject do
    begin
      Font := fontCooper;
      Text := 'Выйти';
      PivotPoint := ppTopLeft;
      Position := dfVec2f(-150, -15);
      Material.MaterialOptions.Diffuse := colorWhite;
    end;

    TextureNormal := atlasMain.LoadTexture(EXIT_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(EXIT_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(EXIT_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  FBtnNewGame.OnMouseClick := MouseClick;
  FBtnCoopGame.OnMouseClick := MouseClick;
  FBtnSettings.OnMouseClick := MouseClick;
  FBtnExit.OnMouseClick := MouseClick;

  FScene.RegisterElement(FBtnNewGame);
  FScene.RegisterElement(FBtnCoopGame);
  FScene.RegisterElement(FBtnSettings);
  FScene.RegisterElement(FBtnExit);
end;

procedure TpdMainMenu.LoadSettingsMenu;
begin
  FMusicText := Factory.NewText();
  FSoundText := Factory.NewText();
  FDifficultyText := Factory.NewText();
  FDificultyDescriptionText := Factory.NewText();

  FSoundVol  := Factory.NewGUISlider();
  FMusicVol  := Factory.NewGUISlider();
  FDifficulty := Factory.NewGUISlider();

  FBtnBack := Factory.NewGUITextButton();

  with FMusicText do
  begin
    Font := fontCooper;
    Text := 'Музыка';
    Z := Z_MAINMENU_BUTTONS;
    PivotPoint := ppTopLeft;
    Position := dfVec2f(TEXT_MUSIC_X - R.WindowWidth, TEXT_MUSIC_Y);
    Material.MaterialOptions.Diffuse := colorWhite;
  end;

  with FSoundText do
  begin
    Font := fontCooper;
    Text := 'Звук';
    Z := Z_MAINMENU_BUTTONS;
    PivotPoint := ppTopLeft;
    Position := dfVec2f(TEXT_SOUND_X - R.WindowWidth, TEXT_SOUND_Y);
    Material.MaterialOptions.Diffuse := colorWhite;
  end;

  with FDifficultyText do
  begin
    Font := fontCooper;
    Text := 'Сложность';
    Z := Z_MAINMENU_BUTTONS;
    PivotPoint := ppTopLeft;
    Position := dfVec2f(TEXT_DIFF_X - R.WindowWidth, TEXT_DIFF_Y);
    Material.MaterialOptions.Diffuse := colorWhite;
  end;

  with FDificultyDescriptionText do
  begin
    Font := fontCooper;
    Text := '';
    Z := Z_MAINMENU_BUTTONS;
    PivotPoint := ppCenter;
    Position := dfVec2f(TEXT_DIFFDESC_X - R.WindowWidth, TEXT_DIFFDESC_Y);
    Material.MaterialOptions.Diffuse := colorWhite;
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
    Z := Z_MAINMENU_BUTTONS;
    Position := dfVec2f(SLIDER_SOUND_X - R.WindowWidth, SLIDER_SOUND_Y);
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
    Z := Z_MAINMENU_BUTTONS;
    Position := dfVec2f(SLIDER_MUSIC_X - R.WindowWidth, SLIDER_MUSIC_Y);
    OnValueChanged := OnSliderValueChanged;
    OnMouseDown := MouseClick;
  end;

  with FDifficulty do
  begin
    Material.Texture := atlasMain.LoadTexture(SLIDER_BACK);
    UpdateTexCoords();
    SetSizeToTextureSize();
    MinValue := 0;
    MaxValue := 4;
    Value := 2;
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
    Z := Z_MAINMENU_BUTTONS;
    Position := dfVec2f(SLIDER_DIFF_X - R.WindowWidth, SLIDER_DIFF_Y);
    OnValueChanged := OnSliderValueChanged;
    OnMouseDown := MouseClick;
  end;

  with FBtnBack do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(BTN_BACK_X - R.WindowWidth, BTN_BACK_Y);
    Z := Z_MAINMENU_BUTTONS;

    with TextObject do
    begin
      Font := fontCooper;
      Text := 'Применить';
      PivotPoint := ppTopLeft;
      Position := dfVec2f(-150, -15);
      Material.MaterialOptions.Diffuse := colorWhite;
    end;

    TextureNormal := atlasMain.LoadTexture(BACK_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BACK_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BACK_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;
  FBtnBack.OnMouseClick := MouseClick;

  FScene.RegisterElement(FMusicText);
  FScene.RegisterElement(FSoundText);
  FScene.RegisterElement(FDifficultyText);
  FScene.RegisterElement(FDificultyDescriptionText);

  FScene.RegisterElement(FSoundVol);
  FScene.RegisterElement(FMusicVol);
  FScene.RegisterElement(FDifficulty);
  FScene.RegisterElement(FBtnBack);
end;

procedure TpdMainMenu.Load;
var
  int, ecode: Integer;
begin
  inherited;
  //Устанавливаем цвет фона при переключении окон
  gl.ClearColor(54 / 255, 172 / 255, 179 / 255, 1.0);
  with FSettingsFile do
  begin
    Val(Settings[stMusicVolume], int, ecode);  FMusicVol.Value := int;
    Val(Settings[stSoundVolume], int, ecode);  FSoundVol.Value := int;
    Val(Settings[stDifficulty], int, ecode);
      FDifficulty.Value := int;
      OnSliderValueChanged(FDifficulty as IglrGUIElement, int);
    Val(Settings[stFirstLaunch], int, ecode);  firstLaunch := (int > 0);
  end;

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
    Font := fontCooper;
    Text := 'автор — perfect.daemon'#13#10'Музыка — BoxCat Games, CC-BY';
    PivotPoint := ppBottomCenter;
    Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight + ABOUT_OFFSET_Y);
    Z := Z_MAINMENU_BUTTONS;
  end;

  with FIGDCText do
  begin
    Font := fontCooper;
    Text := 'Совершенно секретно'#13#10'Только для IGDC#97';
    PivotPoint := ppTopCenter;
    Position := dfVec2f(R.WindowWidth div 2, IGDC_OFFSET_Y);
    Material.MaterialOptions.Diffuse := colorGray2;
    Z := Z_MAINMENU_BUTTONS;
  end;

  FScene.RegisterElement(FAboutText);
  FScene.RegisterElement(FIGDCText);
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
      Tweener.AddTweenPSingle(@FBtnCoopGame.PPosition.x, tsExpoEaseIn, -170, COOP_X, TIME_CO, TIME_CO_PAUSE);
      Tweener.AddTweenPSingle(@FBtnSettings.PPosition.x, tsExpoEaseIn, R.WindowWidth + 250, SETTINGS_X, TIME_SN, TIME_SN_PAUSE);
      Tweener.AddTweenPSingle(@FBtnExit.PPosition.y, tsExpoEaseIn, R.WindowHeight + 70, EXIT_Y, TIME_EX, TIME_EX_PAUSE);

      Tweener.AddTweenPSingle(@FAboutText.PPosition.y, tsExpoEaseIn,
        R.WindowHeight + 70, R.WindowHeight + ABOUT_OFFSET_Y, TIME_ABOUTTEXT, TIME_ABOUTTEXT_PAUSE);

      Tweener.AddTweenPSingle(@FIGDCText.PPosition.y, tsBounce,
        -70, IGDC_OFFSET_Y, TIME_ABOUTTEXT, TIME_ABOUTTEXT_PAUSE + 1.0);
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      FFakeBackground.Visible := True;
      Ft := TIME_FADEOUT;
      FGUIManager.UnregisterElement(FBtnNewGame);
      FGUIManager.UnregisterElement(FBtnCoopGame);
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
  FGUIManager.RegisterElement(FDifficulty);
  FGUIManager.RegisterElement(FBtnBack);
  Tweener.AddTweenSingle(Self, @TweenSceneOrigin, tsExpoEaseIn, FScene.Origin.x, R.WindowWidth, 2.0, 0.0);

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

procedure TpdMainMenu.UpdateSettings;
var
  tmpStr: String;
begin
  with FSettingsFile do
  begin
    Str(FSoundVol.Value, tmpStr);   Settings[stSoundVolume] := tmpStr;
    Str(FMusicVol.Value, tmpStr);   Settings[stMusicVolume] := tmpStr;
    Str(FDifficulty.Value, tmpStr); Settings[stDifficulty]  := tmpStr;
    Settings[stFirstLaunch] := '0';
  end;
end;

end.

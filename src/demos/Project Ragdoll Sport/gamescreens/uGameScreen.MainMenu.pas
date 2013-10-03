unit uGameScreen.MainMenu;

interface

uses
  glr, uSettings_SaveLoad,
  uGameScreen;

const
  SETTINGS_FILE = 'rds.txt';

  //Общее время показа/скрытия
  TIME_FADEIN  = 0.65;
  TIME_FADEOUT = 0.7;

  //Время и пауза для отдельных элементов при твине
  TIME_NG = 2.3; TIME_NG_PAUSE = 0.6;
  TIME_SN = 2.3; TIME_SN_PAUSE = 0.8;
  TIME_EX = 2.3; TIME_EX_PAUSE = 0.9;

  TIME_ABOUTTEXT = 1.7; TIME_ABOUTTEXT_PAUSE = 1.2;

  ABOUT_OFFSET_Y = -75;
type
  TpdMainMenu = class (TpdGameScreen)
  private
    FGUIManager: IglrGUIManager;
    FScene: Iglr2DScene;
    FScrGame: TpdGameScreen;

    //Кнопки
    FBtnNewGame, FBtnSettings, FBtnExit: IglrGUIButton;
    FFakeBackground: IglrSprite;

    FAboutText: IglrText;

    FSettingsShowed: Boolean;
    Ft: Single; //Время для анимации

    //--settings menu
    FMusicText, FSoundText,
    FOnlineText,
    FControlMouseText: IglrText;
    FSoundVol, FMusicVol: IglrGUISlider;
    FCbOnline, FCbControl: IglrGUICheckBox;

    FHintOnline, FHintControl: IglrText;

    FBtnBack: IglrGUIButton;

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
  glrMath, dfTweener, ogl,
  uGlobal;

const
  //New game
  PLAY_X      = 512;
  PLAY_Y      = 250;

  //About
  SETTINGS_X  = PLAY_X - 150;
  SETTINGS_Y  = PLAY_Y + 140;

  //Exit
  EXIT_X      = PLAY_X + 150;
  EXIT_Y      = SETTINGS_Y;

  //Settings offset
  TEXT_MUSIC_X = 200;
  TEXT_MUSIC_Y = 200;

  TEXT_SOUND_X = TEXT_MUSIC_X;
  TEXT_SOUND_Y = TEXT_MUSIC_Y + 50;

  TEXT_ONLINE_X = TEXT_MUSIC_X;
  TEXT_ONLINE_Y = TEXT_SOUND_Y + 50;

  TEXT_CONTROL_X = TEXT_MUSIC_X;
  TEXT_CONTROL_Y = TEXT_ONLINE_Y + 50;

  SLIDER_SOUND_X = 450;
  SLIDER_SOUND_Y = TEXT_SOUND_Y + 10;

  SLIDER_MUSIC_X = SLIDER_SOUND_X;
  SLIDER_MUSIC_Y = TEXT_MUSIC_Y + 10;

  CB_ONLINE_X    = SLIDER_SOUND_X + 100;
  CB_ONLINE_Y    = TEXT_ONLINE_Y - 5;

  CB_CONTROL_X    = CB_ONLINE_X;
  CB_CONTROL_Y    = TEXT_CONTROL_Y - 5;

  HINT_ONLINE_X         = TEXT_MUSIC_X;
  HINT_ONLINE_OFFSET_Y  = -60; //Offset, так как отсчитывается снизу
  HINT_CONTROL_X        = TEXT_MUSIC_X;
  HINT_CONTROL_OFFSET_Y = -60; //Offset, так как отсчитывается снизу

  BTN_BACK_X = 900;
  BTN_BACK_Y = 350;

procedure InterfacePositionXTween(aInt: IInterface; aValue: Single);
begin
  (aInt as IglrNode).PPosition.x := aValue;
end;

procedure InterfacePositionYTween(aInt: IInterface; aValue: Single);
begin
  (aInt as IglrNode).PPosition.y := aValue;
end;

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
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
  with mainMenu do
    if Sender = (FCbOnline as IglrGUIElement) then
      Tweener.AddTweenInterface(FHintOnline, InterfacePositionYTween, tsExpoEaseIn,
        R.WindowHeight + 60, R.WindowHeight + HINT_ONLINE_OFFSET_Y, 1.0, 0.0)
//      Tweener.AddTweenPSingle(@FHintOnline.PPosition.y, tsExpoEaseIn,
//        R.WindowHeight + 60, R.WindowHeight + HINT_ONLINE_OFFSET_Y, 1.0, 0.0)
    else if Sender = (FCbControl as IglrGUIElement) then
      Tweener.AddTweenInterface(FHintControl, InterfacePositionYTween, tsExpoEaseIn,
        R.WindowHeight + 60, R.WindowHeight + HINT_CONTROL_OFFSET_Y, 1.0, 0.0)
//      Tweener.AddTweenPSingle(@FHintControl.PPosition.y, tsExpoEaseIn,
//        R.WindowHeight + 60, R.WindowHeight + HINT_CONTROL_OFFSET_Y, 1.0, 0.0)
end;

procedure OnMouseOut(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with mainMenu do
    if Sender = (FCbOnline as IglrGUIElement) then
      Tweener.AddTweenInterface(FHintOnline, InterfacePositionYTween, tsExpoEaseIn,
        R.WindowHeight + HINT_ONLINE_OFFSET_Y, R.WindowHeight + 60,  1.0, 0.0)
//      Tweener.AddTweenPSingle(@FHintOnline.PPosition.y, tsExpoEaseIn,
//        R.WindowHeight + HINT_ONLINE_OFFSET_Y, R.WindowHeight + 60,  1.0, 0.0)
    else if Sender = (FCbControl as IglrGUIElement) then
      Tweener.AddTweenInterface(FHintControl, InterfacePositionYTween, tsExpoEaseIn,
        R.WindowHeight + HINT_CONTROL_OFFSET_Y, R.WindowHeight + 60,  1.0, 0.0)
//      Tweener.AddTweenPSingle(@FHintControl.PPosition.y, tsExpoEaseIn,
//        R.WindowHeight + HINT_CONTROL_OFFSET_Y, R.WindowHeight + 60,  1.0, 0.0)
end;

procedure OnVolumeChanged(Sender: IglrGUIElement; aNewValue: Integer);
begin
  with mainMenu do
    if Sender = FSoundVol as IglrGUIElement then
      sound.SoundVolume := aNewValue / 100
    else if Sender = FMusicVol as IglrGUIElement then
      sound.MusicVolume := aNewValue / 100;
end;

procedure OnCheck(Sender: IglrGUICheckBox; Checked: Boolean);
begin
  with mainMenu do
    if Sender = FCbOnline then
      uGlobal.onlineServices := Checked
    else if Sender = FCbControl then
      uGlobal.mouseControl := Checked;
end;

procedure TweenSceneOrigin(aObject: TdfTweenObject; aValue: Single);
begin
  with (aObject as TpdMainMenu).FScene.RootNode do
    PPosition.x := aValue;
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

  FSettingsFile := TpdSettingsFile.Initialize(SETTINGS_FILE);
end;

destructor TpdMainMenu.Destroy;
begin
  FScene.RootNode.RemoveAllChilds();
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
  FGUIManager.UnregisterElement(FCbOnline);
  FGUIManager.UnregisterElement(FCbControl);
  FGUIManager.UnregisterElement(FBtnBack);
  Tweener.AddTweenSingle(Self, @TweenSceneOrigin, tsExpoEaseIn, FScene.RootNode.Position.x, 0, 2.0, 0.0);
  FSettingsShowed := False;
end;

procedure TpdMainMenu.LoadButtons();
begin
  FBtnNewGame  := Factory.NewGUIButton();
  FBtnSettings := Factory.NewGUIButton();
  FBtnExit     := Factory.NewGUIButton();

  with FBtnNewGame do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(PLAY_X, PLAY_Y, Z_MAINMENU_BUTTONS);
    TextureNormal := atlasMain.LoadTexture(PLAY_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(PLAY_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(PLAY_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnSettings do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(SETTINGS_X, SETTINGS_Y, Z_MAINMENU_BUTTONS);
    TextureNormal := atlasMain.LoadTexture(SETTINGS_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(SETTINGS_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(SETTINGS_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnExit do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(EXIT_X, EXIT_Y, Z_MAINMENU_BUTTONS);
    TextureNormal := atlasMain.LoadTexture(EXIT_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(EXIT_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(EXIT_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  FBtnNewGame.OnMouseClick := OnMouseClick;
  FBtnSettings.OnMouseClick := OnMouseClick;
  FBtnExit.OnMouseClick := OnMouseClick;

  FScene.RootNode.AddChild(FBtnNewGame);
  FScene.RootNode.AddChild(FBtnSettings);
  FScene.RootNode.AddChild(FBtnExit);
end;

procedure TpdMainMenu.LoadSettingsMenu;
begin
  FMusicText := Factory.NewText();
  FSoundText := Factory.NewText();
  FOnlineText := Factory.NewText();
  FControlMouseText := Factory.NewText();

  FSoundVol  := Factory.NewGUISlider();
  FMusicVol  := Factory.NewGUISlider();
  FCbOnline  := Factory.NewGUICheckBox();
  FCbControl := Factory.NewGUICheckBox();

  FHintOnline := Factory.NewText();
  FHintControl := Factory.NewText();

  FBtnBack := Factory.NewGUIButton();

  with FMusicText do
  begin
    Font := fontCooper;
    Text := 'Музыка';
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_MUSIC_X - R.WindowWidth, TEXT_MUSIC_Y, Z_MAINMENU_BUTTONS);
    Material.Diffuse := dfVec4f(131 / 255, 217 / 255, 16 / 255, 1.0);
  end;

  with FSoundText do
  begin
    Font := fontCooper;
    Text := 'Звук';
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_SOUND_X - R.WindowWidth, TEXT_SOUND_Y, Z_MAINMENU_BUTTONS);
    Material.Diffuse := dfVec4f(131 / 255, 217 / 255, 16 / 255, 1.0);
  end;

  with FOnlineText do
  begin
    Font := fontCooper;
    Text := 'Online-рекорды';
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_ONLINE_X - R.WindowWidth, TEXT_ONLINE_Y, Z_MAINMENU_BUTTONS);
    Material.Diffuse := dfVec4f(131 / 255, 217 / 255, 16 / 255, 1.0);
  end;

  with FControlMouseText do
  begin
    Font := fontCooper;
    Text := 'Управление мышью';
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_CONTROL_X - R.WindowWidth, TEXT_CONTROL_Y, Z_MAINMENU_BUTTONS);
    Material.Diffuse := dfVec4f(131 / 255, 217 / 255, 16 / 255, 1.0);
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
    Position := dfVec3f(SLIDER_SOUND_X - R.WindowWidth, SLIDER_SOUND_Y, Z_MAINMENU_BUTTONS);
    OnValueChanged := OnVolumeChanged;
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
    Position := dfVec3f(SLIDER_MUSIC_X - R.WindowWidth, SLIDER_MUSIC_Y, Z_MAINMENU_BUTTONS);
    OnValueChanged := OnVolumeChanged;
  end;

  with FCbOnline do
  begin
    PivotPoint := ppTopLeft;
    Position := dfVec3f(CB_ONLINE_X - R.WindowWidth, CB_ONLINE_Y, Z_MAINMENU_BUTTONS);
    TextureOn := atlasMain.LoadTexture(CB_ON_TEXTURE);
    TextureOnOver := atlasMain.LoadTexture(CB_ON_OVER_TEXTURE);
    TextureOff := atlasMain.LoadTexture(CB_OFF_TEXTURE);
    TextureOffOver := atlasMain.LoadTexture(CB_OFF_OVER_TEXTURE);
    SetSizeToTextureSize();
    Width := Width / 1.5;
    Height := Height / 1.5;
  end;

  FCbOnline.OnMouseOver := OnMouseOver;
  FCbOnline.OnMouseOut := OnMouseOut;
  FCbOnline.OnCheck := OnCheck;

  with FCbControl do
  begin
    PivotPoint := ppTopLeft;
    Position := dfVec3f(CB_CONTROL_X - R.WindowWidth, CB_CONTROL_Y, Z_MAINMENU_BUTTONS);
    TextureOn := atlasMain.LoadTexture(CB_ON_TEXTURE);
    TextureOnOver := atlasMain.LoadTexture(CB_ON_OVER_TEXTURE);
    TextureOff := atlasMain.LoadTexture(CB_OFF_TEXTURE);
    TextureOffOver := atlasMain.LoadTexture(CB_OFF_OVER_TEXTURE);
    SetSizeToTextureSize();
    Width := Width / 1.5;
    Height := Height / 1.5;
  end;

  FCbControl.OnMouseOver := OnMouseOver;
  FCbControl.OnMouseOut := OnMouseOut;
  FCbControl.OnCheck := OnCheck;

  with FHintOnline do
  begin
    Font := fontCooper;
    Text := 'Позволяет получать рекорды с сервера и'#13#10'публиковать свои результаты';
    PivotPoint := ppBottomLeft;
    Position := dfVec3f(HINT_ONLINE_X - R.WindowWidth, R.WindowHeight + 60, Z_MAINMENU_BUTTONS);
    Material.Diffuse := dfVec4f(1, 1, 1, 1);
  end;

  with FHintControl do
  begin
    Font := fontCooper;
    Text := 'Переключает режимы управления:'#13#10'мышь или курсорные стрелки';
    PivotPoint := ppBottomLeft;
    Position := dfVec3f(HINT_CONTROL_X - R.WindowWidth, R.WindowHeight + 60, Z_MAINMENU_BUTTONS);
    Material.Diffuse := dfVec4f(1, 1, 1, 1);
  end;


  with FBtnBack do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(BTN_BACK_X - R.WindowWidth, BTN_BACK_Y, Z_MAINMENU_BUTTONS);
    TextureNormal := atlasMain.LoadTexture(BACK_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BACK_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BACK_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;
  FBtnBack.OnMouseClick := OnMouseClick;

  FScene.RootNode.AddChild(FMusicText);
  FScene.RootNode.AddChild(FSoundText);
  FScene.RootNode.AddChild(FOnlineText);
  FScene.RootNode.AddChild(FControlMouseText);

  FScene.RootNode.AddChild(FSoundVol);
  FScene.RootNode.AddChild(FMusicVol);
  FScene.RootNode.AddChild(FCbOnline);
  FScene.RootNode.AddChild(FCbControl);
  FScene.RootNode.AddChild(FHintOnline);
  FScene.RootNode.AddChild(FHintControl);
  FScene.RootNode.AddChild(FBtnBack);
end;

procedure TpdMainMenu.Load;
var
  int, ecode: Integer;
begin
  inherited;
  //Устанавливаем цвет фона при переключении окон
  gl.ClearColor(99 / 255, 99 / 255, 99 / 255, 1.0);
  sound.PlayMusic(musicMenu);

  with FSettingsFile do
  begin
    Val(Settings[stMusicVolume], int, ecode);  FMusicVol.Value := int;
    Val(Settings[stSoundVolume], int, ecode);  FSoundVol.Value := int;
    Val(Settings[stOnline], int, ecode);       FCbOnline.Checked := (int > 0);
    Val(Settings[stMouseControl], int, ecode); FCbControl.Checked := (int > 0);
    uGlobal.playerName := Settings[stPlayername];
  end;

  R.RegisterScene(FScene);
end;

procedure TpdMainMenu.LoadBackground();
begin

end;

procedure TpdMainMenu.LoadText;
begin
  FAboutText := Factory.NewText();
  with FAboutText do
  begin
    Font := fontCooper;
    Text := 'Ragdoll Sports [Prototype]'#13#10'       by perfect.daemon';
    PivotPoint := ppBottomCenter;
    Position := dfVec3f(R.WindowWidth div 2, R.WindowHeight + ABOUT_OFFSET_Y, Z_MAINMENU_BUTTONS);
  end;

  FScene.RootNode.AddChild(FAboutText);
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

      Tweener.AddTweenInterface(FBtnNewGame, InterfacePositionYTween, tsExpoEaseIn, -70, PLAY_Y, TIME_NG, TIME_NG_PAUSE);
//      Tweener.AddTweenPSingle(@FBtnNewGame.PPosition.y, tsExpoEaseIn, -70, PLAY_Y, TIME_NG, TIME_NG_PAUSE);
      Tweener.AddTweenInterface(FBtnSettings, InterfacePositionXTween, tsExpoEaseIn, R.WindowWidth + 250, SETTINGS_X, TIME_SN, TIME_SN_PAUSE);
//      Tweener.AddTweenPSingle(@FBtnSettings.PPosition.x, tsExpoEaseIn, R.WindowWidth + 250, SETTINGS_X, TIME_SN, TIME_SN_PAUSE);
      Tweener.AddTweenInterface(FBtnExit, InterfacePositionYTween, tsExpoEaseIn, R.WindowHeight + 70, EXIT_Y, TIME_EX, TIME_EX_PAUSE);
//      Tweener.AddTweenPSingle(@FBtnExit.PPosition.y, tsExpoEaseIn, R.WindowHeight + 70, EXIT_Y, TIME_EX, TIME_EX_PAUSE);
      Tweener.AddTweenInterface(FAboutText, InterfacePositionYTween, tsExpoEaseIn, R.WindowHeight + 70, R.WindowHeight + ABOUT_OFFSET_Y, TIME_ABOUTTEXT, TIME_ABOUTTEXT_PAUSE);
//      Tweener.AddTweenPSingle(@FAboutText.PPosition.y, tsExpoEaseIn,
//        R.WindowHeight + 70, R.WindowHeight + ABOUT_OFFSET_Y, TIME_ABOUTTEXT, TIME_ABOUTTEXT_PAUSE);
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      FFakeBackground.Visible := True;
      Ft := TIME_FADEOUT;
      FGUIManager.UnRegisterElement(FBtnNewGame);
      FGUIManager.UnregisterElement(FBtnSettings);
      FGUIManager.UnRegisterElement(FBtnExit);
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
  FGUIManager.RegisterElement(FCbOnline);
  FGUIManager.RegisterElement(FCbControl);
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

procedure TpdMainMenu.UpdateSettings;
var
  tmpStr: String;
begin
  with FSettingsFile do
  begin
    Str(FSoundVol.Value, tmpStr);   Settings[stSoundVolume] := tmpStr;
    Str(FMusicVol.Value, tmpStr);   Settings[stMusicVolume] := tmpStr;
    Settings[stPlayername] := uGlobal.playerName;
    if FCbOnline.Checked then
      Settings[stOnline] := '1'
    else
      Settings[stOnline] := '0';
    if FCbControl.Checked then
      Settings[stMouseControl] := '1'
    else
      Settings[stMouseControl] := '0';
  end;
end;

end.

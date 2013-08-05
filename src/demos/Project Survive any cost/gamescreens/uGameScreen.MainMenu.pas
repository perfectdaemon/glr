unit uGameScreen.MainMenu;

interface

uses
  dfHRenderer,
  uGameScreen;

const
  //Общее время показа/скрытия
  TIME_FADEIN  = 0.65;
  TIME_FADEOUT = 0.7;

  //Время и пауза для отдельных элементов при твине
  TIME_NG = 1.7; TIME_NG_PAUSE = 0.6;
  TIME_AB = 1.5; TIME_AB_PAUSE = 0.7;
  TIME_SN = 1.5; TIME_SN_PAUSE = 0.8;
  TIME_EX = 1.7; TIME_EX_PAUSE = 0.9;

  TIME_ABOUTTEXT1 = 1.7; TIME_ABOUT_TEXT1_PAUSE = 0.0;

  ABOUT3_OFFSET_Y = -135;

type
  TpdMainMenu = class (TpdGameScreen)
  private
    FGUIManager: IglrGUIManager;
    FScene: Iglr2DScene;
    FScrGame, FScrAdvices: TpdGameScreen;

    //Кнопки
    FBtnNewGame, FBtnAbout, FBtnExit: IglrGUIButton;
    FCBSound: IglrGUICheckBox;

    //Оформление бэка
    FGameName, FGrass, FFlower, FMushroom, FFish,
    FBackTop, FBackBottom, FFakeBackground: IglrSprite;

    FForIGDCText, FAboutText1, FAboutText2, FAboutText3: IglrText;

    Ft: Single; //Время для анимации

    FTime, FSin: Single; //время для анимации элементов, переменная для хранения синуса

    FAboutShowed: Boolean;

    FFirstPlay: Boolean; //Показываем сначала советы

    procedure LoadBackground();
    procedure InitButtons();
    procedure ShowOrHideAbout();
    procedure ShowAbout();
    procedure HideAbout();
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

    procedure SetGameScreenLinks(aGame, aAdvices: TpdGameScreen);
  end;

var
  mainMenu: TpdMainMenu;

implementation

uses
  Windows,
  dfMath, dfHGL, dfTweener,
  uGlobal;

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with mainMenu do
    if Sender = (FBtnNewGame as IglrGUIElement) then
    begin
      if FFirstPlay then
      begin
        OnNotify(FScrAdvices, naSwitchTo);
        FFirstPlay := False;
      end
      else
        OnNotify(FScrGame, naSwitchTo);
    end

    else if Sender = (mainMenu.FBtnAbout as IglrGUIElement) then
    begin
      ShowOrHideAbout();
    end

    else if Sender = (FBtnExit as IglrGUIElement) then
    begin
      OnNotify(nil, naQuitGame);
    end;
end;

procedure OnMouseOver(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if Sender = (mainMenu.FBtnAbout as IglrGUIElement) then
  begin
    mainMenu.ShowAbout();
  end;
end;

procedure OnMouseOut(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if Sender = (mainMenu.FBtnAbout as IglrGUIElement) then
  begin
    mainMenu.HideAbout();
  end;
end;

procedure OnCheck(Sender: IglrGUICheckBox; Checked: Boolean);
begin
  if Sender = mainMenu.FCBSound then
  begin
    sound.Enabled := not sound.Enabled;
  end;
end;

{ TpdMainMenu }

const
  //New game
  PLAY_X      = 512;
  PLAY_Y      = 300;

  //About
  ABOUT_X      = PLAY_X;
  ABOUT_Y      = PLAY_Y + 90;

  //Sound
  SOUND_X      = PLAY_X;
  SOUND_Y      = ABOUT_Y + 90;

  //Exit
  EXIT_X      = PLAY_X;
  EXIT_Y      = SOUND_Y + 90;

constructor TpdMainMenu.Create;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();
  FFirstPlay := True;

  LoadBackground();

  InitButtons();
  //--Инициализируем текст IGDC
  FForIGDCText := Factory.NewText();
  with FForIGDCText do
  begin
    Font := fontCooper;
    Text := 'only for' + #10 + 'igdc #93';
    Position := dfVec2f(R.WindowWidth - 130, R.WindowHeight - 60);
    Z := Z_MAINMENU_BUTTONS;
    Material.MaterialOptions.Diffuse := dfVec4f(0, 107.0 / 255, 203 / 255, 1);
    Rotation := -30;
  end;
  FScene.RegisterElement(FForIGDCText);

  //--Инициализируем текст About
  FAboutText1 := Factory.NewText();
  with FAboutText1 do
  begin
    Font := fontCooper;
    Text := '[создал]' + #10 + 'perfect.daemon';
    Position := dfVec2f(50, 320);
    Z := Z_MAINMENU_BUTTONS;
    Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);//dfVec4f(0, 107.0 / 255, 203 / 255, 1);
    Rotation := 0;
    Visible := False;
  end;
  FScene.RegisterElement(FAboutText1);

  FAboutText2 := Factory.NewText();
  with FAboutText2 do
  begin
    Font := fontCooper;
    Text := '[озвучил]' + #10 + 'Alexandr Zhelanov';
    Position := dfVec2f(R.WindowWidth - 250, 320);
    Z := Z_MAINMENU_BUTTONS;
    Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1); //dfVec4f(0, 107.0 / 255, 203 / 255, 1);
    Rotation := 0;
    Visible := False;
  end;
  FScene.RegisterElement(FAboutText2);

  FAboutText3 := Factory.NewText();
  with FAboutText3 do
  begin
    Font := fontCooper;
    Text := '[улучшили]' + #13#10 + 'Алексей «Ulop», Максим «Монах»,'#13#10'«Lampogolovii», Евгений «ist.flash»,'#13#10'Настя «Kisslika»';
    Position := dfVec2f(R.WindowWidth div 2 - 150, R.WindowHeight + ABOUT3_OFFSET_Y);
    Z := Z_MAINMENU_BUTTONS;
    Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1); //dfVec4f(0, 107.0 / 255, 203 / 255, 1);
    Rotation := 0;
    Visible := False;
  end;
  FScene.RegisterElement(FAboutText3);

  //Бэкграунд для fade in/out
  FFakeBackground := Factory.NewHudSprite();
  FFakeBackground.Position := dfVec2f(0, 0);
  FFakeBackground.Z := 100;
  FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
  FFakeBackground.Material.Texture.BlendingMode := tbmTransparency;
  FFakeBackground.Width := R.WindowWidth;
  FFakeBackground.Height := R.WindowHeight;
  FScene.RegisterElement(FFakeBackground);
end;

destructor TpdMainMenu.Destroy;
begin
  FScene.UnregisterElements();
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
  FGUIManager.RegisterElement(FBtnAbout);
  FGUIManager.RegisterElement(FCBSound);
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

procedure TpdMainMenu.HideAbout;
begin
  Tweener.AddTweenPSingle(@FAboutText1.PPosition.x, tsElasticEaseIn, 50, -40, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);
  Tweener.AddTweenPSingle(FAboutText1.PRotation, tsElasticEaseIn, 0, 90, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);

  Tweener.AddTweenPSingle(@FAboutText2.PPosition.x, tsElasticEaseIn, R.WindowWidth - 250, R.WindowWidth + 80, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);
  Tweener.AddTweenPSingle(FAboutText2.PRotation, tsElasticEaseIn, 0, 90, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);

  Tweener.AddTweenPSingle(@FAboutText3.PPosition.y, tsElasticEaseIn,
    R.WindowHeight + ABOUT3_OFFSET_Y, R.WindowHeight + 10, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);

  FAboutShowed := not FAboutShowed;
end;

procedure TpdMainMenu.InitButtons();

begin
  FBtnNewGame := Factory.NewGUIButton();
  FBtnAbout   := Factory.NewGUIButton();
  FCBSound    := Factory.NewGUICheckBox();
  FBtnExit    := Factory.NewGUIButton();

  with FBtnNewGame do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(PLAY_X, PLAY_Y);
    Z := Z_MAINMENU_BUTTONS;
    TextureNormal := atlasMenu.LoadTexture(PLAY_NORMAL_TEXTURE);
    TextureOver := atlasMenu.LoadTexture(PLAY_OVER_TEXTURE);
    TextureClick := atlasMenu.LoadTexture(PLAY_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnAbout do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(ABOUT_X, ABOUT_Y);
    Z := Z_MAINMENU_BUTTONS;
    TextureNormal := atlasMenu.LoadTexture(ABOUT_NORMAL_TEXTURE);
    TextureOver := atlasMenu.LoadTexture(ABOUT_OVER_TEXTURE);
    TextureClick := atlasMenu.LoadTexture(ABOUT_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FCBSound do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(SOUND_X, SOUND_Y);
    Z := Z_MAINMENU_BUTTONS;
    TextureOn := atlasMenu.LoadTexture(SOUND_ON_TEXTURE);
    TextureOnOver := atlasMenu.LoadTexture(SOUND_ON_OVER_TEXTURE);
    TextureOff := atlasMenu.LoadTexture(SOUND_OFF_TEXTURE);
    TextureOffOver := atlasMenu.LoadTexture(SOUND_OFF_OVER_TEXTURE);

    //UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnExit do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(EXIT_X, EXIT_Y);
    Z := Z_MAINMENU_BUTTONS;
    TextureNormal := atlasMenu.LoadTexture(EXIT_NORMAL_TEXTURE);
    TextureOver := atlasMenu.LoadTexture(EXIT_OVER_TEXTURE);
    TextureClick := atlasMenu.LoadTexture(EXIT_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  FBtnNewGame.OnMouseClick := OnMouseClick;
  FBtnAbout.OnMouseClick := OnMouseClick;
//Позволяет делать возникновение и скрытие about надписей на mouse over/out
//  FBtnAbout.OnMouseOver := OnMouseOver;
//  FBtnAbout.OnMouseOut := OnMouseOut;
  FCBSound.Checked := True;
  FCBSound.OnCheck := OnCheck;
  FBtnExit.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnNewGame);
  FScene.RegisterElement(FBtnAbout);
  FScene.RegisterElement(FCBSound);
  FScene.RegisterElement(FBtnExit);
end;

procedure TpdMainMenu.Load;
begin
  inherited;
  //Устанавливаем цвет фона при переключении окон
  gl.ClearColor(73 / 255, 169 / 255, 1.0, 1.0);

  R.RegisterScene(FScene);
end;

procedure TpdMainMenu.LoadBackground();

const
  BACKTOP_TEXTURE = 'back_topright.png';
  BACKBOTTOM_TEXTURE = 'back_bottomright.png';
  FISH_TEXTURE = 'fish.png';
  MUSHROOM_TEXTURE = 'mushroom.png';
  FLOWER_TEXTURE = 'flower.png';
  GRASS_TEXTURE = 'grass.png';
  GAMENAME_TEXTURE = 'gamename.png';

begin
  FFish := Factory.NewHudSprite();
  FBackTop := Factory.NewHudSprite();
  FBackBottom := Factory.NewHudSprite();
  FGameName := Factory.NewHudSprite();
  FFlower := Factory.NewHudSprite();
  FMushroom := Factory.NewHudSprite();
  FGrass := Factory.NewHudSprite();

  with FFish do
  begin
    Material.Texture := atlasMenu.LoadTexture(FISH_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec2f(R.WindowWidth - 150, 180);
    PivotPoint := ppTopCenter;
    Z := Z_BACKGROUND;
  end;

  with FBackTop do
  begin
    Material.Texture := atlasMenu.LoadTexture(BACKTOP_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec2f(R.WindowWidth + 65, -20);
    PivotPoint := ppTopRight;
    Z := Z_BACKGROUND + 1;
  end;

  with FBackBottom do
  begin
    Material.Texture := atlasMenu.LoadTexture(BACKBOTTOM_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec2f(R.WindowWidth, R.WindowHeight);
    PivotPoint := ppBottomRight;
    Z := Z_BACKGROUND + 1;
  end;

  with FGameName do
  begin
    Material.Texture := atlasMenu.LoadTexture(GAMENAME_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec2f(R.WindowWidth div 2 + 40, 50);
    PivotPoint := ppTopCenter;
    Z := Z_BACKGROUND + 2;
  end;

  with FFlower do
  begin
    Material.Texture := atlasMenu.LoadTexture(FLOWER_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec2f(45, R.WindowHeight - 20);
    PivotPoint := ppBottomCenter;
    Z := Z_BACKGROUND;
  end;

  with FMushroom do
  begin
    Material.Texture := atlasMenu.LoadTexture(MUSHROOM_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec2f(60, R.WindowHeight - 20);
    PivotPoint := ppBottomLeft;
    Z := Z_BACKGROUND + 1;
  end;

  with FGrass do
  begin
    Material.Texture := atlasMenu.LoadTexture(GRASS_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec2f(10, R.WindowHeight);
    PivotPoint := ppBottomLeft;
    Z := Z_BACKGROUND + 2;
  end;

  FScene.RegisterElement(FFish);
  FScene.RegisterElement(FBackTop);
  FScene.RegisterElement(FBackBottom);
  FScene.RegisterElement(FGameName);
  FScene.RegisterElement(FFlower);
  FScene.RegisterElement(FMushroom);
  FScene.RegisterElement(FGrass);
end;

procedure TpdMainMenu.SetGameScreenLinks(aGame, aAdvices: TpdGameScreen);
begin
  FScrGame := aGame;
  FScrAdvices := aAdvices;
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
      //FFakeBackground.Visible := True;
      Ft := TIME_FADEIN;

      Tweener.AddTweenPSingle(@FBtnNewGame.PPosition.y, tsExpoEaseIn, -50, PLAY_Y, TIME_NG, TIME_NG_PAUSE);
      Tweener.AddTweenPSingle(@FBtnAbout.PPosition.x, tsExpoEaseIn, -250, ABOUT_X, TIME_AB, TIME_AB_PAUSE);
      Tweener.AddTweenPSingle(@FCBSound.PPosition.x, tsExpoEaseIn, R.WindowWidth + 250, SOUND_X, TIME_SN, TIME_SN_PAUSE);
      Tweener.AddTweenPSingle(@FBtnExit.PPosition.y, tsExpoEaseIn, R.WindowHeight + 50, EXIT_Y, TIME_EX, TIME_EX_PAUSE);
      Tweener.AddTweenPSingle(@FFish.PPosition.y, tsElasticEaseOut, 70, 175, 2.0, 1.0);
      Tweener.AddTweenPSingle(@FGameName.Material.MaterialOptions.PDiffuse.w,
        tsExpoEaseIn, 0.0, 1.0, 5.0, TIME_AB_PAUSE);

      Tweener.AddTweenPSingle(@FForIGDCText.PPosition.y, tsExpoEaseIn,
        FForIGDCText.PPosition.y + 150, FForIGDCText.PPosition.y, 1.0, TIME_EX_PAUSE);
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      //FFakeBackground.Visible := True;
      Ft := TIME_FADEOUT;
      FGUIManager.UnRegisterElement(FBtnNewGame);
      FGUIManager.UnRegisterElement(FBtnAbout);
      FGUIManager.UnregisterElement(FCBSound);
      FGUIManager.UnRegisterElement(FBtnExit);
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdMainMenu.ShowAbout;
begin
  FAboutText1.Visible := True;
  FAboutText2.Visible := True;
  FAboutText3.Visible := True;
  Tweener.AddTweenPSingle(@FAboutText1.PPosition.x, tsElasticEaseIn, -40, 50, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);
  Tweener.AddTweenPSingle(FAboutText1.PRotation, tsElasticEaseIn, 90, 0, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);

  Tweener.AddTweenPSingle(@FAboutText2.PPosition.x, tsElasticEaseIn, R.WindowWidth + 80, R.WindowWidth - 250, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);
  Tweener.AddTweenPSingle(FAboutText2.PRotation, tsElasticEaseIn, 90, 0, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);

  Tweener.AddTweenPSingle(@FAboutText3.PPosition.y, tsElasticEaseIn,
    R.WindowHeight + 10, R.WindowHeight + ABOUT3_OFFSET_Y, TIME_ABOUTTEXT1, TIME_ABOUT_TEXT1_PAUSE);

  FAboutShowed := not FAboutShowed;
end;

procedure TpdMainMenu.ShowOrHideAbout;
begin
  if not FAboutShowed then
    ShowAbout()
  else
    HideAbout();
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
        if FAboutShowed then
          HideAbout();

      //Анимация цветочка и рыбы
      FTime := FTime + deltaTime;
      if FTime > 6.28 then
        FTime := 0;
      FSin := Sin(FTime);
      FFish.Rotation := 7 * FSin;
      FFlower.Rotation := 3 * FSin;
      FFlower.PPosition.y := R.WindowHeight - 20 - 3*FSin;
    end;
  end;
end;

end.

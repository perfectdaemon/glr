unit uGameScreen.PauseMenu;

interface

uses
  uGameScreen,
  glr;

const
  TIME_FADEIN = 0.5;
  TIME_FADEOUT = 0.5;

type
  TpdPauseMenu = class (TpdGameScreen)
  private
    FScene: Iglr2DScene;
    FGUIManager: IglrGUIManager;
    FScrMainMenu, FScrGame, FScrAdvices: TpdGameScreen;

    //Кнопки
    FBtnToMenu, FBtnToGame, FBtnToAdvices: IglrGUIButton;
    FFlower, FBackground, FFakeBackground: IglrSprite;

    Ft: Single; //Время для анимации fadein / fadeout

    procedure InitButtons();
    procedure InitBackground();
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

    procedure SetGameScreenLinks(aToMainMenu, aToGame, aToAdvices: TpdGameScreen);
  end;

var
  pauseMenu: TpdPauseMenu;

implementation

uses
  glrMath, dfTweener,
  uGlobal;

const
  BACKGRND_TEXTURE   = 'back_pausemenu.png';

  BACK_NORMAL_TEXTURE  = 'back_normal.png';
  BACK_OVER_TEXTURE  = 'back_over.png';
  BACK_CLICK_TEXTURE = 'back_click.png';

  ADVICES_NORMAL_TEXTURE = 'tutorial_normal.png';
  ADVICES_OVER_TEXTURE   = 'tutorial_over.png';
  ADVICES_CLICK_TEXTURE  = 'tutorial_click.png';

  MENU_NORMAL_TEXTURE = 'menu_normal.png';
  MENU_OVER_TEXTURE   = 'menu_over.png';
  MENU_CLICK_TEXTURE  = 'menu_click.png';

  FLOWER_TEXTURE      = 'flower2.png';

  BACK_OFFSET_Y = -70;
  ADVICES_OFFSET_Y = 30;
  MENU_OFFSET_Y =  130;
  FLOWER_OFFSET_X = -25;
  FLOWER_OFFSET_Y = -5;

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with pauseMenu do
  begin
    if Sender = (FBtnToMenu as IglrGUIElement) then
    begin
      //FScrGame.Unload();
      FScrGame.Status := gssFadeOut;
      OnNotify(FScrMainMenu, naSwitchTo);
    end

    else if Sender = (FBtnToGame as IglrGUIElement) then
    begin
      OnNotify(FScrGame, naSwitchTo);
    end

    else if Sender = (FBtnToAdvices as IglrGUIElement) then
    begin
      OnNotify(FScrAdvices, naSwitchTo);
    end;
  end;
end;

procedure SetSingle(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdPauseMenu do
  begin
    FBackground.PPosition.y := aValue;
    FBtnToMenu.PPosition.y := aValue + MENU_OFFSET_Y;
    FBtnToAdvices.PPosition.y := aValue + ADVICES_OFFSET_Y;
    FBtnToGame.PPosition.y := aValue + BACK_OFFSET_Y;
    FFlower.PPosition.y := aValue + FBackground.Height / 2 + FLOWER_OFFSET_Y;
  end;
end;

{ TpdPauseMenu }

constructor TpdPauseMenu.Create;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();

  InitBackground();

  InitButtons();
end;

destructor TpdPauseMenu.Destroy;
begin
  FScene.UnregisterElements();
  inherited;
end;

procedure TpdPauseMenu.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := 0.5 - 0.5 * Ft / TIME_FADEIN;
  end;
end;

procedure TpdPauseMenu.FadeInComplete;
begin
  Status := gssReady;
  FGUIManager.RegisterElement(FBtnToMenu);
  FGUIManager.RegisterElement(FBtnToGame);
  FGUIManager.RegisterElement(FBtnToAdvices);
end;

procedure TpdPauseMenu.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := 0.5 * Ft / TIME_FADEOUT;
  end;
end;

procedure TpdPauseMenu.FadeOutComplete;
begin
  Status := gssNone;
  FFakeBackground.Visible := False;
end;

procedure TpdPauseMenu.InitBackground;
begin
  FFakeBackground := Factory.NewHudSprite();
  with FFakeBackground do
  begin
    Material.Diffuse := dfVec4f(0, 0, 0, 0.0);
    Material.Texture.BlendingMode := tbmTransparency;
    Z := Z_INGAMEMENU - 1;
    PivotPoint := ppTopLeft;
    Width := R.WindowWidth;
    Height := R.WindowHeight;
    Position := dfVec2f(0, 0);
  end;

  FBackground := Factory.NewHudSprite();
  with FBackground do
  begin
    Material.Texture := atlasInGameMenu.LoadTexture(BACKGRND_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize;
    Z := Z_INGAMEMENU;
    PivotPoint := ppCenter;
    Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);
  end;

  FFlower := Factory.NewHudSprite();
  with FFlower do
  begin
    Material.Texture := atlasInGameMenu.LoadTexture(FLOWER_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Z := Z_INGAMEMENU + 1;
    PivotPoint := ppBottomLeft;
    Position := FBackground.Position +
      dfVec2f(FLOWER_OFFSET_X - FBackground.Width / 2, FLOWER_OFFSET_Y + FBackground.Height / 2);
  end;

  FScene.RegisterElement(FFakeBackground);
  FScene.RegisterElement(FBackground);
  FScene.RegisterElement(FFlower);
end;

procedure TpdPauseMenu.InitButtons();
begin
  FBtnToGame    := Factory.NewGUIButton();
  FBtnToMenu    := Factory.NewGUIButton();
  FBtnToAdvices := Factory.NewGUIButton();

  with FBtnToGame do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2 + BACK_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
    TextureNormal := atlasInGameMenu.LoadTexture(BACK_NORMAL_TEXTURE);
    TextureOver := atlasInGameMenu.LoadTexture(BACK_OVER_TEXTURE);
    TextureClick := atlasInGameMenu.LoadTexture(BACK_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnToAdvices do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2 + ADVICES_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
    TextureNormal := atlasInGameMenu.LoadTexture(ADVICES_NORMAL_TEXTURE);
    TextureOver := atlasInGameMenu.LoadTexture(ADVICES_OVER_TEXTURE);
    TextureClick := atlasInGameMenu.LoadTexture(ADVICES_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnToMenu do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2 + MENU_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
    TextureNormal := atlasInGameMenu.LoadTexture(MENU_NORMAL_TEXTURE);
    TextureOver := atlasInGameMenu.LoadTexture(MENU_OVER_TEXTURE);
    TextureClick := atlasInGameMenu.LoadTexture(MENU_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  FBtnToMenu.OnMouseClick := OnMouseClick;
  FBtnToAdvices.OnMouseClick := OnMouseClick;
  FBtnToGame.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnToMenu);
  FScene.RegisterElement(FBtnToAdvices);
  FScene.RegisterElement(FBtnToGame);
end;

procedure TpdPauseMenu.Load;
begin
  inherited;
  R.RegisterScene(FScene);
end;

procedure TpdPauseMenu.SetGameScreenLinks(aToMainMenu, aToGame, aToAdvices: TpdGameScreen);
begin
  FScrMainMenu := aToMainMenu;
  FScrGame := aToGame;
  FScrAdvices := aToAdvices;
end;

procedure TpdPauseMenu.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
  case aStatus of
    gssNone: Exit;

    gssReady: Exit;

    gssFadeIn:
    begin
      FFakeBackground.Visible := True;
      Ft := TIME_FADEIN;
      Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, - 300, R.WindowHeight / 2, 2, 0.5);
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, R.WindowHeight / 2, - 300, 1, 0.0);
      FGUIManager.UnregisterElement(FBtnToMenu);
      FGUIManager.UnregisterElement(FBtnToGame);
      FGUIManager.UnregisterElement(FBtnToAdvices);
      Ft := TIME_FADEOUT;
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdPauseMenu.Unload;
begin
  inherited;
  R.UnregisterScene(FScene);
end;

procedure TpdPauseMenu.Update(deltaTime: Double);
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
      if R.Input.IsKeyPressed(27) then
        OnMouseClick(FBtnToGame as IglrGUIElement, 0, 0, mbLeft, []);
    end;
  end;
end;

end.

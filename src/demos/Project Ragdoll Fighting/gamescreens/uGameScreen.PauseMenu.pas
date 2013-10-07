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
    FScrMainMenu, FScrGame: TpdGameScreen;

    //Кнопки
    FBtnToMenu, FBtnToGame: IglrGUITextButton;
    FFakeBackground: IglrSprite;
    FHelpText: IglrText;

    Ft: Single; //Время для анимации fadein / fadeout

    FEscapeDown: Boolean;

    procedure InitButtons();
    procedure InitBackground();
    procedure InitText();
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

    procedure SetGameScreenLinks(aToMainMenu, aToGame: TpdGameScreen);
  end;

var
  pauseMenu: TpdPauseMenu;

implementation

uses
  glrMath, dfTweener,
  uGlobal;

const
  BACK_OFFSET_Y = -30;
  MENU_OFFSET_Y =  30;

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
    end;
  end;
end;

procedure SetSingle(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdPauseMenu do
  begin
    FBtnToMenu.PPosition.y := aValue + MENU_OFFSET_Y;
    FBtnToGame.PPosition.y := aValue + BACK_OFFSET_Y;
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
  InitText();
end;

destructor TpdPauseMenu.Destroy;
begin
  Unload();

  FScene.RootNode.RemoveAllChilds();
  FScene := nil;
  inherited;
end;

procedure TpdPauseMenu.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := 0.7 - 0.7 * Ft / TIME_FADEIN;
  end;
end;

procedure TpdPauseMenu.FadeInComplete;
begin
  Status := gssReady;
end;

procedure TpdPauseMenu.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := 0.7 * Ft / TIME_FADEOUT;
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
    PivotPoint := ppTopLeft;
    Width := R.WindowWidth;
    Height := R.WindowHeight;
    Position := dfVec3f(0, 0, Z_INGAMEMENU - 1);
  end;

  FScene.RootNode.AddChild(FFakeBackground);
end;

procedure TpdPauseMenu.InitButtons();
begin
  FBtnToGame := Factory.NewGUITextButton();
  FBtnToMenu := Factory.NewGUITextButton();

  with FBtnToGame do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(R.WindowWidth div 2, R.WindowHeight div 2 + BACK_OFFSET_Y, Z_INGAMEMENU + 2);
    TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

    with TextObject do
    begin
      Font := fontCooper;
      Text := 'Продолжить';
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(-150, -15);
      Material.Diffuse := colorWhite;
    end;

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnToMenu do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(R.WindowWidth div 2, R.WindowHeight div 2 + MENU_OFFSET_Y, Z_INGAMEMENU + 2);
    TextureNormal := atlasMain.LoadTexture(MENU_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(MENU_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(MENU_CLICK_TEXTURE);

    with TextObject do
    begin
      Font := fontCooper;
      Text := 'В меню';
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(-150, -15);
      Material.Diffuse := colorWhite;
    end;

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  FBtnToMenu.OnMouseClick := OnMouseClick;
  FBtnToGame.OnMouseClick := OnMouseClick;

  FScene.RootNode.AddChild(FBtnToMenu);
  FScene.RootNode.AddChild(FBtnToGame);
end;

procedure TpdPauseMenu.Load;
begin
  inherited;
  R.RegisterScene(FScene);
end;

procedure TpdPauseMenu.InitText;
begin
  FHelpText := Factory.NewText();
  with FHelpText do
  begin
    Font := fontCooper;
    Text := 'Стрелки — управление персонажем'#13#10
      + 'WASD — управление вторым персонажем в игре друг против друга'#13#10
      + 'Enter — применение спец. способности в одиночной игре'#13#10'              Тратит 50% энергии';
    PivotPoint := ppTopCenter;
    Position := dfVec3f(R.WindowWidth div 2, 20, Z_INGAMEMENU + 1);
  end;

  FScene.RootNode.AddChild(FHelpText);
end;

procedure TpdPauseMenu.SetGameScreenLinks(aToMainMenu, aToGame: TpdGameScreen);
begin
  FScrMainMenu := aToMainMenu;
  FScrGame := aToGame;
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
      Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, - 300, R.WindowHeight / 2, 2, 0.5);
      FGUIManager.RegisterElement(FBtnToMenu);
      FGUIManager.RegisterElement(FBtnToGame);
      Ft := TIME_FADEIN;
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, R.WindowHeight / 2, - 300, 1, 0.0);
      FGUIManager.UnregisterElement(FBtnToMenu);
      FGUIManager.UnregisterElement(FBtnToGame);
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

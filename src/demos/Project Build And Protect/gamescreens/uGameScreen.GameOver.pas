unit uGameScreen.GameOver;

interface

uses
  uGameScreen, dfHRenderer;

const
  TIME_FADEIN = 1.8;
  TIME_FADEOUT = 0.5;

type
  TpdRow = record
    tPlayerName, tScore, tMaxPower: IglrText;
  end;

  TpdRows = array of TpdRow;

  TpdGameOver = class (TpdGameScreen)
  private
    FScene: Iglr2DScene;
    FGUIManager: IglrGUIManager;
    FScrMainMenu, FScrGame: TpdGameScreen;

    //Тексты
    FScores, FMaxPower, FFoulsCount: IglrText;
    //Кнопки
    FBtnReplay, FBtnMenu: IglrGUIButton;


    {FFakeBackground, }FBackground: IglrSprite;
    Ft: Single; //Время для анимации fadein / fadeout

    FEscapeDown: Boolean;

    procedure LoadButtons();
    procedure LoadBackground();
    procedure LoadTexts();

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

    procedure SetGameScreenLinks(aMainMenu, aGame: TpdGameScreen);
  end;

var
  gameOver: TpdGameOver;

implementation

uses
  SysUtils,
  dfMath, dfTweener,
  uGameScreen.Game, uGlobal;

const
  //Верхний левый блок. Отсчет 0, 0. Корневой - Scores. Дальнейший отсчет от него
  SCORES_OFFSET_X   = 50;
  SCORES_OFFSET_Y   = 20;
  MAXPOWER_OFFSET_X = 0;
  MAXPOWER_OFFSET_Y = 30;
  FOULS_OFFSET_X    = 0;
  FOULS_OFFSET_Y    = 60;

  //Нижний блок, отсчет Width / 2, Height
  BTN_RETRY_OFFSET_X = -80;
  BTN_RETRY_OFFSET_Y = -90;
  BTN_MENU_OFFSET_X  = -BTN_RETRY_OFFSET_X;
  BTN_MENU_OFFSET_Y  =  BTN_RETRY_OFFSET_Y;



procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  sound.PlaySample(sClick);
  with gameOver do
  begin
    if Sender = FBtnReplay as IglrGUIElement then
    begin
      FScrGame.Status := gssNone;
      FScrGame.Unload();
      OnNotify(FScrGame, naSwitchTo);
    end
    else if Sender = FBtnMenu as IglrGUIElement then
    begin
      FScrGame.Status := gssFadeOut;
      OnNotify(FScrMainMenu, naSwitchTo);
    end;
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

procedure TopBlockTween(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdGameOver do
  begin
    FScores.PPosition.y := aValue;
    FMaxPower.PPosition.y := aValue + MAXPOWER_OFFSET_Y;
    FFoulsCount.PPosition.y := aValue + FOULS_OFFSET_Y;
  end;
end;

{ TpdPauseMenu }

constructor TpdGameOver.Create;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();

  LoadBackground();
  LoadTexts();
  LoadButtons();
end;

destructor TpdGameOver.Destroy;
begin
  FScene.UnregisterElements();
  inherited;
end;

procedure TpdGameOver.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FBackground.Material.MaterialOptions.PDiffuse.w := 0.75 * (1 - Ft / TIME_FADEIN);
  end;
end;

procedure TpdGameOver.FadeInComplete;
begin
  Status := gssReady;
end;

procedure TpdGameOver.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FBackground.Material.MaterialOptions.PDiffuse.w := 0.75 * Ft / TIME_FADEOUT;
  end;
end;

procedure TpdGameOver.FadeOutComplete;
begin
  Status := gssNone;
//  FFakeBackground.Visible := False;
end;

procedure TpdGameOver.LoadBackground;
begin
//  FFakeBackground := dfCreateHUDSprite;
  FBackground := Factory.NewHudSprite();

//  with FFakeBackground do
//  begin
//    Material.MaterialOptions.Diffuse := dfVec4f(0.0, 0, 0, 0.0);
//    Material.Texture.BlendingMode := tbmTransparency;
//    Z := Z_INGAMEMENU - 1;
//    PivotPoint := ppTopLeft;
//    Width := R.WindowWidth;
//    Height := R.WindowHeight;
//    Position := dfVec2f(0, 0);
//  end;

  with FBackground do
  begin
    Material.MaterialOptions.Diffuse := dfVec4f(0.0, 0, 0, 0.0);
    Material.Texture.BlendingMode := tbmTransparency;
    Z := Z_INGAMEMENU;
    PivotPoint := ppTopLeft;
    Width := R.WindowWidth;
    Height := R.WindowHeight;
    Position := dfVec2f(0, 0);
  end;

//  FScene.RegisterElement(FFakeBackground);
  FScene.RegisterElement(FBackground);
end;

procedure TpdGameOver.LoadButtons();
begin
  FBtnReplay := Factory.NewGUIButton();
  FBtnMenu := Factory.NewGUIButton();

  with FBtnReplay do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(R.WindowWidth div 2 + BTN_RETRY_OFFSET_X, R.WindowHeight +  BTN_RETRY_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
//    TextureNormal := atlasMain.LoadTexture(REPLAY_NORMAL_TEXTURE);
//    TextureOver := atlasMain.LoadTexture(REPLAY_OVER_TEXTURE);
//    TextureClick := atlasMain.LoadTexture(REPLAY_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnMenu do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(R.WindowWidth div 2 + BTN_MENU_OFFSET_X, R.WindowHeight + BTN_MENU_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
//    TextureNormal := atlasMain.LoadTexture(MENU_NORMAL_TEXTURE);
//    TextureOver := atlasMain.LoadTexture(MENU_OVER_TEXTURE);
//    TextureClick := atlasMain.LoadTexture(MENU_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  FBtnReplay.OnMouseClick := OnMouseClick;
  FBtnMenu.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnReplay);
  FScene.RegisterElement(FBtnMenu);
end;

procedure TpdGameOver.LoadTexts;
begin
  FScores := Factory.NewText();
  FMaxPower := Factory.NewText();
  FFoulsCount := Factory.NewText();

  with FScores do
  begin
    Font := fontCooper;
    Material.MaterialOptions.Diffuse := colorWhite;
    Z := Z_INGAMEMENU + 2;
    PivotPoint := ppTopLeft;
    Position := dfVec2f(SCORES_OFFSET_X, SCORES_OFFSET_Y);
  end;

  with FMaxPower do
  begin
    Font := fontCooper;
    Material.MaterialOptions.Diffuse := colorWhite;
    Z := Z_INGAMEMENU + 2;
    PivotPoint := ppTopLeft;
    Position := FScores.Position + dfVec2f(MAXPOWER_OFFSET_X, MAXPOWER_OFFSET_Y);
  end;

  with FFoulsCount do
  begin
    Font := fontCooper;
    Material.MaterialOptions.Diffuse := colorWhite;
    Z := Z_INGAMEMENU + 2;
    PivotPoint := ppTopLeft;
    Position := FScores.Position +  dfVec2f(FOULS_OFFSET_X, FOULS_OFFSET_Y);
  end;


  FScene.RegisterElement(FScores);
  FScene.RegisterElement(FMaxPower);
  FScene.RegisterElement(FFoulsCount);
end;

procedure TpdGameOver.Load;
begin
  inherited;
  R.RegisterScene(FScene);
end;

procedure TpdGameOver.SetGameScreenLinks(aMainMenu, aGame: TpdGameScreen);
begin
  FScrMainMenu := aMainMenu;
  FScrGame := aGame;
end;

procedure TpdGameOver.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
  case aStatus of
    gssNone: Exit;

    gssReady: Exit;

    gssFadeIn:
    begin
//      FFakeBackground.Visible := True;
      Ft := TIME_FADEIN;

      FGUIManager.RegisterElement(FBtnReplay);
      FGUIManager.RegisterElement(FBtnMenu);

      Tweener.AddTweenPSingle(@FBtnReplay.PPosition.x, tsExpoEaseIn,
        -100, R.WindowWidth div 2 + BTN_RETRY_OFFSET_X, 1.5, 1.0);
      Tweener.AddTweenPSingle(@FBtnMenu.PPosition.x, tsExpoEaseIn,
        R.WindowWidth + 100, R.WindowWidth div 2 + BTN_MENU_OFFSET_X, 1.5, 1.0);

      Tweener.AddTweenSingle(Self, @TopBlockTween, tsExpoEaseIn, -95, SCORES_OFFSET_Y, 1.5, 1.0);
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      Ft := TIME_FADEOUT;
      FGUIManager.UnregisterElement(FBtnReplay);
      FGUIManager.UnregisterElement(FBtnMenu);

      Tweener.AddTweenPSingle(@FBtnReplay.PPosition.x, tsExpoEaseIn,
        R.WindowWidth div 2 + BTN_RETRY_OFFSET_X, -100, 1.5, 0.0);
      Tweener.AddTweenPSingle(@FBtnMenu.PPosition.x, tsExpoEaseIn,
        R.WindowWidth div 2 + BTN_MENU_OFFSET_X, R.WindowWidth + 100, 1.5, 0.0);

      Tweener.AddTweenSingle(Self, TopBlockTween, tsExpoEaseIn, SCORES_OFFSET_Y, -95, 1.5, 0.0);
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdGameOver.Unload;
begin
  inherited;
  R.UnregisterScene(FScene);
end;

procedure TpdGameOver.Update(deltaTime: Double);
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
        OnMouseClick(FBtnMenu as IglrGUIElement, 0, 0, mbLeft, []);
    end;
  end;
end;

end.

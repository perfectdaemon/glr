unit uGameScreen.GameOver;

interface

uses
  uGameScreen,
  glr;

const
  TIME_FADEIN = 1.0;
  TIME_FADEOUT = 0.2;

type
  TpdGameOver = class (TpdGameScreen)
  private
    FScene: Iglr2DScene;
    FGUIManager: IglrGUIManager;
    FScrMainMenu, FScrGame: TpdGameScreen;

    //Кнопки
    FBtnUpload, FBtnNoUpload, FBtnRetry, FBtnMenu: IglrGUIButton;
    FBackground, FFakeBackground: IglrSprite;
    FTimeText, FReasonText: IglrText;

    Ft: Single; //Время для анимации fadein / fadeout
    FSurviveTime: Double;

    procedure InitButtons();
    procedure InitBackground();
    procedure InitTexts();
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
    procedure ShowRetryAndMenuButtons();
  end;

var
  gameOver: TpdGameOver;

implementation

uses
  glrMath, dfTweener,
  uGameScreen.Game, uGlobal;

const
  BACKGRND_TEXTURE   = 'back_gameover.png';
  UPLOAD_NORMAL_TEXTURE  = 'upload_normal.png';
  UPLOAD_OVER_TEXTURE  = 'upload_over.png';
  UPLOAD_CLICK_TEXTURE = 'upload_click.png';
  NOUPLOAD_NORMAL_TEXTURE = 'noupload_normal.png';
  NOUPLOAD_OVER_TEXTURE   = 'noupload_over.png';
  NOUPLOAD_CLICK_TEXTURE  = 'noupload_click.png';

  MENU_NORMAL_TEXTURE = 'menu_normal.png';
  MENU_OVER_TEXTURE   = 'menu_over.png';
  MENU_CLICK_TEXTURE  = 'menu_click.png';
  RETRY_NORMAL_TEXTURE = 'retry_normal.png';
  RETRY_OVER_TEXTURE   = 'retry_over.png';
  RETRY_CLICK_TEXTURE  = 'retry_click.png';

  UPLOAD_OFFSET_X = -177;
  UPLOAD_OFFSET_Y = 115;
  NOUPLOAD_OFFSET_X = 177;
  NOUPLOAD_OFFSET_Y = 115;

  RETRY_OFFSET_X = UPLOAD_OFFSET_X;
  RETRY_OFFSET_Y = UPLOAD_OFFSET_Y;
  MENU_OFFSET_X = NOUPLOAD_OFFSET_X;
  MENU_OFFSET_Y = NOUPLOAD_OFFSET_Y;

  TIMETEXT_OFFSET_X = -100;
  TIMETEXT_OFFSET_Y = -95;
  REASONTEXT_OFFSET_X = TIMETEXT_OFFSET_X;
  REASONTEXT_OFFSET_Y = -25;

  REASONTEXTS: array[TpdParam] of WideString =
  ('Человек более не властен над дикой'#13#10'природой. Инфекция и болезни'#13#10'сделали свое дело...',
   'Умереть от истощения — не самое'#13#10'приятное, но вы выбрали именно'#13#10'такую смерть...',
   '«Воды!» — было вашим последним, '#13#10'слабо различимым словом...',
   'Нелепая смерть, утонуть в одном'#13#10'из двух озер в этом проклятом'#13#10'месте...',
   'Преодолевая трудности и тяготы,'#13#10'вы не смогли сохранить то, что'#13#10'делает вас человеком — разум...');

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with gameOver do
  begin
    if Sender = (FBtnUpload as IglrGUIElement) then
    begin
      ShowRetryAndMenuButtons();
    end
    else if Sender = (FBtnNoUpload as IglrGUIElement) then
    begin
      ShowRetryAndMenuButtons();
    end

    else if Sender = (FBtnRetry as IglrGUIElement) then
    begin
      FScrGame.Status := gssNone;
      FScrGame.Unload();
      OnNotify(FScrGame, naSwitchTo);
    end
    else if Sender = (FBtnMenu as IglrGUIElement) then
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

//Для твина появления меню
procedure SetSingle(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdGameOver do
  begin
    FBackground.PPosition.y := aValue;
    FBtnUpload.PPosition.y := aValue + UPLOAD_OFFSET_Y;
    FBtnNoUpload.PPosition.y := aValue + NOUPLOAD_OFFSET_Y;
    FBtnRetry.PPosition.y := aValue + RETRY_OFFSET_Y;
    FBtnMenu.PPosition.y := aValue + MENU_OFFSET_Y;
    FTimeText.PPosition.y := aValue + TIMETEXT_OFFSET_Y;
    FReasonText.PPosition.y := aValue + REASONTEXT_OFFSET_Y;
  end;
end;

//для твина исчезновения кнопок upload/no upload
procedure SetButtonHide(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdGameOver do
  begin
    FBtnUpload.PPosition.y := aValue;
    FBtnNoUpload.PPosition.y := aValue;
  end;
end;

procedure SetButtonHideAlpha(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdGameOver do
  begin
    FBtnUpload.Material.PDiffuse.w := aValue;
    FBtnNoUpload.Material.PDiffuse.w := aValue;
  end;
end;

//Для твина появления кнопок retry/menu
procedure SetButtonShow(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdGameOver do
  begin
    FBtnRetry.PPosition.y := aValue;
    FBtnMenu.PPosition.y := aValue;
  end;
end;

procedure SetButtonShowAlpha(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdGameOver do
  begin
    FBtnRetry.Material.PDiffuse.w := aValue;
    FBtnMenu.Material.PDiffuse.w := aValue;
  end;
end;

{ TpdPauseMenu }

constructor TpdGameOver.Create;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();

  InitBackground();
  InitTexts();
  InitButtons();
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
    FFakeBackground.Material.PDiffuse.w := 0.55 * (1 - Ft / TIME_FADEIN);
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
    FFakeBackground.Material.PDiffuse.w := 0.55 * Ft / TIME_FADEOUT;
  end;
end;

procedure TpdGameOver.FadeOutComplete;
begin
  Status := gssNone;
  FFakeBackground.Visible := False;
end;

procedure TpdGameOver.InitBackground;
begin
  FFakeBackground := Factory.NewHudSprite();
  with FFakeBackground do
  begin
    Material.Diffuse := dfVec4f(0.7, 0, 0, 0.0);
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

  FScene.RegisterElement(FFakeBackground);
  FScene.RegisterElement(FBackground);
end;

procedure TpdGameOver.InitButtons();
begin
  FBtnUpload := Factory.NewGUIButton();
  FBtnNoUpload := Factory.NewGUIButton();

  FBtnRetry := Factory.NewGUIButton();
  FBtnMenu := Factory.NewGUIButton();

  with FBtnUpload do
  begin
    PivotPoint := ppCenter;
    Position := FBackground.Position + dfVec2f(UPLOAD_OFFSET_X, UPLOAD_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
    TextureNormal := atlasInGameMenu.LoadTexture(UPLOAD_NORMAL_TEXTURE);
    TextureOver := atlasInGameMenu.LoadTexture(UPLOAD_OVER_TEXTURE);
    TextureClick := atlasInGameMenu.LoadTexture(UPLOAD_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnNoUpload do
  begin
    PivotPoint := ppCenter;
    Position := FBackground.Position + dfVec2f(NOUPLOAD_OFFSET_X, NOUPLOAD_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
    TextureNormal := atlasInGameMenu.LoadTexture(NOUPLOAD_NORMAL_TEXTURE);
    TextureOver := atlasInGameMenu.LoadTexture(NOUPLOAD_OVER_TEXTURE);
    TextureClick := atlasInGameMenu.LoadTexture(NOUPLOAD_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnRetry do
  begin
    PivotPoint := ppCenter;
    Position := FBackground.Position + dfVec2f(RETRY_OFFSET_X, RETRY_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
    TextureNormal := atlasInGameMenu.LoadTexture(RETRY_NORMAL_TEXTURE);
    TextureOver := atlasInGameMenu.LoadTexture(RETRY_OVER_TEXTURE);
    TextureClick := atlasInGameMenu.LoadTexture(RETRY_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
    Visible := False;
  end;

  with FBtnMenu do
  begin
    PivotPoint := ppCenter;
    Position := FBackground.Position + dfVec2f(MENU_OFFSET_X, MENU_OFFSET_Y);
    Z := Z_INGAMEMENU + 2;
    TextureNormal := atlasInGameMenu.LoadTexture(MENU_NORMAL_TEXTURE);
    TextureOver := atlasInGameMenu.LoadTexture(MENU_OVER_TEXTURE);
    TextureClick := atlasInGameMenu.LoadTexture(MENU_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
    Visible := False;
  end;

  FBtnUpload.OnMouseClick := OnMouseClick;
  FBtnNoUpload.OnMouseClick := OnMouseClick;
  FBtnRetry.OnMouseClick := OnMouseClick;
  FBtnMenu.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnUpload);
  FScene.RegisterElement(FBtnNoUpload);
  FScene.RegisterElement(FBtnRetry);
  FScene.RegisterElement(FBtnMenu);
end;

procedure TpdGameOver.InitTexts;
begin
  FTimeText := Factory.NewText();
  FReasonText := Factory.NewText();

  with FTimeText do
  begin
    Font := fontCooper;
    Position := FBackground.Position + dfVec2f(TIMETEXT_OFFSET_X, TIMETEXT_OFFSET_Y);
    Z := Z_INGAMEMENU + 1;
  end;

  with FReasonText do
  begin
    Font := fontCooper;
    Position := FBackground.Position + dfVec2f(REASONTEXT_OFFSET_X, REASONTEXT_OFFSET_Y);
    Z := Z_INGAMEMENU + 1;
  end;

  FScene.RegisterElement(FTimeText);
  FScene.RegisterElement(FReasonText);
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
      FGUIManager.RegisterElement(FBtnUpload);
      FGUIManager.RegisterElement(FBtnNoUpload);
//      SetButtonHide(Self, FBackground.Position.y + UPLOAD_OFFSET_Y);
      SetButtonHideAlpha(Self, 1.0);
      FGUIManager.UnregisterElement(FBtnRetry);
      FGUIManager.UnregisterElement(FBtnMenu);
      FBtnRetry.Visible := False;
      FBtnMenu.Visible := False;
      FFakeBackground.Visible := True;

      Ft := TIME_FADEIN;
      Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, R.WindowHeight + 300, R.WindowHeight / 2, 4, 0.5);
      sound.PlayMusic(musicMenu);
      with (FScrGame as TpdGame) do
      begin
        FTimeText.Text := SurviveTimeText;
        FSurviveTime := SurviveTime;
        FReasonText.Text := REASONTEXTS[DeathReason];
      end;
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, R.WindowHeight / 2, - 300, 3, 0.0);
      FGUIManager.UnregisterElement(FBtnUpload);
      FGUIManager.UnregisterElement(FBtnNoUpload);
      Ft := TIME_FADEOUT;
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdGameOver.ShowRetryAndMenuButtons;
begin
  FGUIManager.UnregisterElement(FBtnUpload);
  FGUIManager.UnregisterElement(FBtnNoUpload);

  Tweener.AddTweenSingle(Self, @SetButtonHide, tsExpoEaseIn,
    FBtnUpload.Position.y, FBtnUpload.Position.y - 100, 1.0);
  Tweener.AddTweenSingle(Self, @SetButtonHideAlpha, tsExpoEaseIn,
    1.0, 0.0, 1.5);

  FBtnRetry.Visible := True;
  FBtnMenu.Visible := True;

  Tweener.AddTweenSingle(Self, @SetButtonShow, tsExpoEaseIn,
    FBtnRetry.Position.y + 100, FBtnRetry.Position.y, 1.0, 0.2);
  Tweener.AddTweenSingle(Self, @SetButtonShowAlpha, tsExpoEaseIn,
    0.0, 1.0, 1.5, 0.2);

  FGUIManager.RegisterElement(FBtnRetry);
  FGUIManager.RegisterElement(FBtnMenu);
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
        OnMouseClick(FBtnNoUpload as IglrGUIElement, 0, 0, mbLeft, []);
    end;
  end;
end;

end.

unit uGameScreen.Game;

interface

uses
  Contnrs,
  glr, glrUtils, glrMath,
  uGameScreen, uField,
  uGlobal;

const
  TIME_FADEIN  = 1.5;
  TIME_FADEOUT = 0.2;

  TIME_COUNT_GAMEOVER = 2.0;

  //top left
  TEXT_SCORES_X = 32;
  TEXT_SCORES_Y = 10;

  TEXT_SPEED_X = TEXT_SCORES_X;
  TEXT_SPEED_Y = TEXT_SCORES_Y + 35;

  TEXT_CLEAN_X = TEXT_SCORES_X + 220;
  TEXT_CLEAN_Y = TEXT_SCORES_Y + 15;

  //top right
  TEXT_HELP_X = -155;
  TEXT_HELP_Y = TEXT_CLEAN_Y + 40;

  TEXT_PAUSE_X = -120;
  TEXT_PAUSE_Y = -160;

  BTN_CONTINUE_X = -140;
  BTN_CONTINUE_Y = TEXT_PAUSE_Y + 60;
  BTN_MENU_X = BTN_CONTINUE_X;
  BTN_MENU_Y = BTN_CONTINUE_Y + 60;

type
  TpdGame = class (TpdGameScreen)
  private
    FMainScene, FHUDScene: Iglr2DScene;
    FScrGameOver, FScrMenu: TpdGameScreen;

    FPause: Boolean;

    {$IFDEF DEBUG}
    FFPSCounter: TglrFPSCounter;
    FDebug: TglrDebugInfo;
    {$ENDIF}

    FHelpText, FPauseText,
    FCleanCounterText, FScoresText, FSpeedText: IglrText;
    FBtnMenu, FBtnContinue: IglrGUITextButton;
    FLastCleanCount: Integer;

    Ft: Single; //Время для расчета анимации fadein/fadeout
    FFakeBackground: IglrSprite;
    FGoodLine: IglrSprite;

    FField: TpdField;

    procedure LoadHUD();
    procedure FreeHUD();

    procedure LoadField();
    procedure FreeField();

    procedure DoUpdate(const dt: Double);
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

    procedure SetGameScreenLinks(aGameOver: TpdGameScreen; aMenu: TpdGameScreen);

    procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure OnGameOver();
    procedure PauseOrContinue();
  end;

var
  game: TpdGame;

implementation

uses
  uGameScreen.GameOver,
  Windows, SysUtils,
  dfTweener, ogl;


procedure MouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  sound.PlaySample(sClick);
  with game do
    if Sender = (FBtnMenu as IglrGUIElement) then
      OnNotify(FScrMenu, naSwitchTo)
    else if Sender = (FBtnContinue as IglrGUIElement) then
      PauseOrContinue();
end;

{ TpdGame }

constructor TpdGame.Create;
begin
  inherited;

  FMainScene := Factory.New2DScene();
  FHUDScene := Factory.New2DScene();

  uGlobal.mainScene := FMainScene;
  uGlobal.hudScene := FHUDScene;
end;

destructor TpdGame.Destroy;
begin
  Unload();

  FMainScene := nil;
  FHUDscene := nil;
  uGlobal.mainScene := nil;
  uGlobal.hudScene := nil;
  inherited;
end;

procedure TpdGame.DoUpdate(const dt: Double);
begin
  {$IFDEF DEBUG}
  if R.Input.IsKeyPressed(VK_I) then
  begin
    FDebug.FText.Visible := not FDebug.FText.Visible;
    FFPSCounter.TextObject.Visible := not FFPSCounter.TextObject.Visible;
  end;
  FFpsCounter.Update(dt);
  {$ENDIF}

  if R.Input.IsKeyPressed(VK_ESCAPE) then
    PauseOrContinue();

  if FPause then
    Exit();

  FField.Update(dt);
  if (FField.BeforeCleanCounter <> FLastCleanCount) then
  begin
    FLastCleanCount := FField.BeforeCleanCounter;
    FCleanCounterText.Text := 'Очистка через ' + IntToStr(FLastCleanCount) + ' фигур';
    Tweener.AddTweenPSingle(@FCleanCounterText.Material.PDiffuse.x, tsSimple, 0.0, 1.0, 1.0, 0.2);
    Tweener.AddTweenPSingle(@FCleanCounterText.Material.PDiffuse.z, tsSimple, 0.0, 1.0, 1.0, 0.2);
  end;
  FScoresText.Text := 'Очки: ' + IntToStr(FField.Scores);
  FSpeedText.Text := 'Скорость: ' + FloatToStrF(FField.CurrentSpeed, ffGeneral, 1, 2);
end;

procedure TpdGame.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := Ft / TIME_FADEIN;
  end;
end;

procedure TpdGame.FadeInComplete;
begin
  FFakeBackground.Visible := False;
  Status := gssReady;
end;

procedure TpdGame.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := 1 - Ft / TIME_FADEOUT;
  end;
end;

procedure TpdGame.FadeOutComplete;
begin
  Status := gssNone;
  Unload();
end;

procedure TpdGame.FreeField;
begin
  if Assigned(FField) then
    FreeAndNil(FField);
end;

procedure TpdGame.FreeHUD;
begin
  {$IFDEF DEBUG}
  if Assigned(FDebug) then
    FreeAndNil(FDebug);
  if Assigned(FFPSCounter) then
    FreeAndNil(FFPSCounter);
  {$ENDIF}
  //*
end;


procedure TpdGame.Load;
begin
  inherited;
  if FLoaded then
    Exit();

  sound.PlayMusic(musicIngame);

  FPause := False;

  gl.ClearColor(0, 30 / 255, 60 / 250, 1.0);
  FMainScene.RootNode.RemoveAllChilds();
  FMainScene.RootNode.Position := dfVec3f(0, 0, 0);
  FHudScene.RootNode.RemoveAllChilds();

  LoadHUD();
  LoadField();

  FFakeBackground := Factory.NewHudSprite();
  with FFakeBackground do
  begin
    Position := dfVec3f(0, 0, 100);
    Material.Diffuse := dfVec4f(1, 1, 1, 1);
    Material.Texture.BlendingMode := tbmTransparency;
    Width := R.WindowWidth;
    Height := R.WindowHeight;
  end;
  FHUDScene.RootNode.AddChild(FFakeBackground);

  R.RegisterScene(FMainScene);
  R.RegisterScene(FHUDScene);

  FLoaded := True;
end;

procedure TpdGame.LoadField;
begin
  if Assigned(FField) then
    FreeAndNil(FField);
  FField := TpdField.Create();
  FField.onGameOver := OnGameOver;
end;

procedure TpdGame.LoadHUD;
begin
  {$IFDEF DEBUG}
  FFPSCounter := TglrFPSCounter.Create(FHUDScene, 'FPS:', 1, nil);
  FFPSCounter.TextObject.Material.Diffuse := dfVec4f(0, 0, 0, 1);
  FFPSCounter.TextObject.Visible := False;

  FDebug := TglrDebugInfo.Create(FHUDScene.RootNode);
  FDebug.FText.Material.Diffuse := dfVec4f(0, 0, 0, 1);
  FDebug.FText.Visible := False;
  FDebug.FText.PPosition.y := 20;
  {$ENDIF}

  FHelpText := Factory.NewText();
  with FHelpText do
  begin
    Font := fontSouvenir;
    PivotPoint := ppTopRight;
    ScaleMult(0.7);
    Position := dfVec3f(R.WindowWidth + TEXT_HELP_X, TEXT_HELP_Y, Z_HUD);
    Text := 'Помощь'#13#10 +
      'Стрелки/wsad — движение фигуры'#13#10 +
      'Пробел — поворот фигуры'#13#10 +
      'Escape — пауза'#13#10#13#10 +
      'Текущее "дно" подсвечивается'#13#10 +
      'красной линией'#13#10#13#10 +
      'Через N фигур выполняется'#13#10 +
      'очистка одинаковых по цвету'#13#10 +
      'фигур, связанных по вертикали'#13#10 +
      'или горизонтали, если их число '#13#10 +
      'больше или равно ' + IntToStr(CLEAN_BLOCK_THRESHOLD);
  end;
  FHUDScene.RootNode.AddChild(FHelpText);

  FPauseText := Factory.NewText();
  with FPauseText do
  begin
    Font := fontSouvenir;
    PivotPoint := ppBottomRight;
    Position := dfVec3f(R.WindowWidth + TEXT_PAUSE_X, R.WindowHeight + TEXT_PAUSE_Y, Z_HUD);
    Material.Diffuse := colorWhite;
    Text := 'Пауза';
    Visible := False;
  end;
  FHUDScene.RootNode.AddChild(FPauseText);

  FBtnMenu := Factory.NewGUITextButton();
  with FBtnMenu do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(R.WindowWidth + BTN_MENU_X, R.WindowHeight + BTN_MENU_Y, Z_HUD);

    with TextObject do
    begin
      Font := fontSouvenir;
      Text := 'Меню';
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
      Material.Diffuse := colorWhite;
    end;
    TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();

    Visible := False;
    OnMouseClick := MouseClick;
  end;
  FHUDScene.RootNode.AddChild(FBtnMenu);

  FBtnContinue := Factory.NewGUITextButton();
  with FBtnContinue do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(R.WindowWidth + BTN_CONTINUE_X, R.WindowHeight + BTN_CONTINUE_Y, Z_HUD);

    with TextObject do
    begin
      Font := fontSouvenir;
      Text := 'Продолжить';
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
      Material.Diffuse := colorWhite;
    end;
    TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();

    Visible := False;
    OnMouseClick := MouseClick;
  end;
  FHUDScene.RootNode.AddChild(FBtnContinue);

  FScoresText := Factory.NewText();
  with FScoresText do
  begin
    Font := fontSouvenir;
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_SCORES_X, TEXT_SCORES_Y, Z_HUD);
    Text := 'Очки: 0';
  end;
  FHUDScene.RootNode.AddChild(FScoresText);

  FSpeedText := Factory.NewText();
  with FSpeedText do
  begin
    Font := fontSouvenir;
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_SPEED_X, TEXT_SPEED_Y, Z_HUD);
    Text := 'Скорость: 1';
  end;
  FHUDScene.RootNode.AddChild(FSpeedText);

  FCleanCounterText := Factory.NewText();
  with FCleanCounterText do
  begin
    Font := fontSouvenir;
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_CLEAN_X, TEXT_CLEAN_Y, Z_HUD);
    Text := 'Очистка через _ фигур';
  end;
  FHUDScene.RootNode.AddChild(FCleanCounterText);

  FGoodLine := Factory.NewHudSprite();
  with FGoodLine do
  begin
    Material.Texture := atlasMain.LoadTexture(GOODLINE_TEXTURE);
    Material.Diffuse := dfVec4f(1, 1, 1, 0.3);
    SetSizeToTextureSize();
    Width := 1.5 * Width;
    Height := 1.5 * Height;
    PivotPoint := ppCenter;
    UpdateTexCoords();
    Position := dfVec3f(R.WindowWidth div 2 + uField.FIELD_OFFSET_X,
      R.WindowHeight div 2 + uField.FIELD_OFFSET_Y, Z_BACKGROUND);
  end;
  FMainScene.RootNode.AddChild(FGoodLine);
end;

procedure TpdGame.SetGameScreenLinks(aGameOver: TpdGameScreen; aMenu: TpdGameScreen);
begin
  FScrGameOver := aGameOver;
  FScrMenu := aMenu;
end;

procedure TpdGame.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
  case aStatus of
    gssNone: Exit;

    gssReady: Exit;

    gssFadeIn:
    begin
      FFakeBackground.Visible := True;
      Ft := TIME_FADEIN;
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      FFakeBackground.Visible := True;
      Ft := TIME_FADEOUT;
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdGame.Unload;
begin
  inherited;
  if not FLoaded then
    Exit();

  FreeHUD();
  FreeField();

  R.GUIManager.UnregisterElement(FBtnMenu);

  R.UnregisterScene(FMainScene);
  R.UnregisterScene(FHUDScene);

  FLoaded := False;
end;

procedure TpdGame.Update(deltaTime: Double);
begin
  inherited;
  case FStatus of
    gssFadeIn  : FadeIn(deltaTime);
    gssFadeOut : FadeOut(deltaTime);
    gssReady   : DoUpdate(deltaTime);
  end;
end;

procedure TpdGame.OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();
end;

procedure TpdGame.OnGameOver;
begin
  //todo - что-то посчитать
  (FScrGameOver as TpdGameOver).Scores := FField.Scores;
  OnNotify(FScrGameOver, naShowModal);
end;

procedure TpdGame.OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();
end;

procedure TpdGame.OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();
end;

procedure TpdGame.PauseOrContinue;
begin
  FPause := not FPause;
  FPauseText.Visible := FPause;
  FBtnMenu.Visible := FPause;
  FBtnContinue.Visible := FPause;
  if FPause then
  begin
    R.GUIManager.RegisterElement(FBtnMenu);
    R.GUIManager.RegisterElement(FBtnContinue);
  end
  else
  begin
    R.GUIManager.UnregisterElement(FBtnMenu);
    R.GUIManager.UnregisterElement(FBtnContinue);
  end;
end;

end.

unit uGameScreen.GameOver;

interface

uses
  uGameScreen, uGameSync,
  glr;

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
    FScores, FMaxPower, FFoulsCount, FSubmitScore,
    FOnlineTableText: IglrText;
    //Кнопки
    FBtnReplay, FBtnMenu: IglrGUIButton;

    FPlayerName: IglrGUITextBox;
    FBtnSubmit: IglrGUIButton;

    {FFakeBackground, }FBackground: IglrSprite;
    Ft: Single; //Время для анимации fadein / fadeout

    FSync: TpdRagdollSportsGameSync;

    FTable: TpdRows;

    procedure LoadButtons();
    procedure LoadBackground();
    procedure LoadTexts();
    procedure LoadRecords();

    procedure SubmitScore();
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
  glrMath, dfTweener,
  uGameScreen.Game, uGlobal;

const
  //Верхний левый блок. Отсчет 0, 0. Корневой - Scores. Дальнейший отсчет от него
  SCORES_OFFSET_X   = 50;
  SCORES_OFFSET_Y   = 20;
  MAXPOWER_OFFSET_X = 0;
  MAXPOWER_OFFSET_Y = 30;
  FOULS_OFFSET_X    = 0;
  FOULS_OFFSET_Y    = 60;

  //Правый верхний блок. Отсчет Width / 2, 0. Основной Sumbit, дальнейший отсчет от него
  SUBMIT_OFFSET_X    = -70;
  SUBMIT_OFFSET_Y    = SCORES_OFFSET_Y;
  TEXTBOX_PLAYERNAME_OFFSET_X = 0;
  TEXTBOX_PLAYERNAME_OFFSET_Y = 30;
  BTN_SUBMIT_OFFSET_X = 75;
  BTN_SUBMIT_OFFSET_Y = 25;

  //Блок таблицы. Отсчет 0, 0, основной FOnlineTable
  TEXT_TABLE_OFFSET_X = 50;
  TEXT_TABLE_OFFSET_Y = 150;
  TABLE_COL_PLAYER_OFFSET_X = 0;
  TABLE_COL_PLAYER_OFFSET_Y = 40;
  TABLE_COL_SCORE_OFFSET_X = 350;
  TABLE_COL_SCORE_OFFSET_Y = 40;
  TABLE_COL_MAXPOWER_OFFSET_X = 450;
  TABLE_COL_MAXPOWER_OFFSET_Y = 40;
  TABLE_ROW_HEIGHT = 30;

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
    else if Sender = FBtnSubmit as IglrGUIElement then
    begin
      if uGlobal.onlineServices then
      begin
        SubmitScore();
        uGlobal.playerName := FPlayerName.TextObject.Text;
      end
      else
      begin
        FSubmitScore.Text := 'Онлайн-сервисы отключены в настройках';
        FSubmitScore.Material.Diffuse := colorRed;
      end;
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
    with FScores.Position do y := aValue;
    with FMaxPower.Position do y := aValue + MAXPOWER_OFFSET_Y;
    with FFoulsCount.Position do y := aValue + FOULS_OFFSET_Y;

    with FSubmitScore.Position do y := aValue;
    with FPlayerName.Position do y := aValue + TEXTBOX_PLAYERNAME_OFFSET_Y;
    with FBtnSubmit.Position do y := FPlayerName.Position.y + BTN_SUBMIT_OFFSET_Y;
  end;
end;

procedure SubmitBlockTween(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdGameOver do
  begin
    with FSubmitScore.Position do y := aValue;
    with FPlayerName.Position do y := aValue + TEXTBOX_PLAYERNAME_OFFSET_Y;
    with FBtnSubmit.Position do y := FPlayerName.Position.y + BTN_SUBMIT_OFFSET_Y;
  end;
end;

procedure TableRecordsTween(aObject: TdfTweenObject; aValue: Single);
var
  i: Integer;
begin
  with (aObject as TpdGameOver) do
    for i := 0 to High(FTable) do
    begin
      with FTable[i].tPlayerName.Position do x := aValue;
      with FTable[i].tScore.Position do x := aValue + TABLE_COL_SCORE_OFFSET_X;
      with FTable[i].tMaxPower.Position do x := aValue + TABLE_COL_MAXPOWER_OFFSET_X;
    end;
end;

procedure InterfacePositionXTween(aInt: IInterface; aValue: Single);
begin
  with (aInt as IglrRenderable).Position do
    x := aValue;
end;

{ TpdPauseMenu }

constructor TpdGameOver.Create;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();
  FSync := TpdRagdollSportsGameSync.Create();

  LoadBackground();
  LoadTexts();
  LoadButtons();
//  LoadRecords();
end;

destructor TpdGameOver.Destroy;
var
  i: Integer;
begin
  FSync.Free();
//  FScene.UnregisterElements();
  for i := 0 to High(FTable) do
    with FTable[i] do
    begin
      tPlayerName := nil;
      tScore := nil;
      tMaxPower := nil;
    end;
  inherited;
end;

procedure TpdGameOver.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FBackground.Material.PDiffuse.w := 0.75 * (1 - Ft / TIME_FADEIN);
  end;
end;

procedure TpdGameOver.FadeInComplete;
begin
  Status := gssReady;
  if uGlobal.onlineServices then
  begin
    LoadRecords();
    Tweener.AddTweenSingle(Self, @TableRecordsTween, tsExpoEaseIn,
      - R.WindowWidth / 2, TEXT_TABLE_OFFSET_X, 1.5, 0.0);
  end;
end;

procedure TpdGameOver.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FBackground.Material.PDiffuse.w := 0.75 * Ft / TIME_FADEOUT;
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
    Material.Diffuse := dfVec4f(0.0, 0, 0, 0.0);
    Material.Texture.BlendingMode := tbmTransparency;
    PivotPoint := ppTopLeft;
    Width := R.WindowWidth;
    Height := R.WindowHeight;
    Position := dfVec3f(0, 0, Z_INGAMEMENU);
  end;

//  FScene.RegisterElement(FFakeBackground);
  FScene.RootNode.AddChild(FBackground);
end;

procedure TpdGameOver.LoadButtons();
begin
  FBtnReplay := Factory.NewGUIButton();
  FBtnMenu := Factory.NewGUIButton();
  FBtnSubmit := Factory.NewGUIButton();

  FPlayerName := Factory.NewGUITextBox();

  with FBtnReplay do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(R.WindowWidth div 2 + BTN_RETRY_OFFSET_X,
      R.WindowHeight +  BTN_RETRY_OFFSET_Y,
      Z_INGAMEMENU + 2);
    TextureNormal := atlasMain.LoadTexture(REPLAY_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(REPLAY_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(REPLAY_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FBtnMenu do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(R.WindowWidth div 2 + BTN_MENU_OFFSET_X,
      R.WindowHeight + BTN_MENU_OFFSET_Y,
      Z_INGAMEMENU + 2);
    TextureNormal := atlasMain.LoadTexture(MENU_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(MENU_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(MENU_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  with FPlayerName do
  begin
    TextObject.Font := fontCooper;
    TextObject.Text := uGlobal.playerName;
    MaxTextLength := 24;
    CursorObject.Width := 10;
    CursorObject.Material.Diffuse := dfVec4f(1,1,1,1);
    TextOffset := dfVec2f(9, 9);
    CursorOffset := dfVec2f(3, 12);
    Material.Texture := atlasMain.LoadTexture(TEXTBOX_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position2D := FSubmitScore.Position2D + dfVec2f(TEXTBOX_PLAYERNAME_OFFSET_X, TEXTBOX_PLAYERNAME_OFFSET_Y);
    with Position do z := Z_INGAMEMENU + 2;
  end;

  with FBtnSubmit do
  begin
    PivotPoint := ppCenter;
    Position2D := FPlayerName.Position2D + dfVec2f(FPlayerName.Width + BTN_SUBMIT_OFFSET_X, BTN_SUBMIT_OFFSET_Y);
    with Position do z := Z_INGAMEMENU + 2;
    TextureNormal := atlasMain.LoadTexture(SUBMIT_NORMAL_TEXTURE);
    TextureOver := atlasMain.LoadTexture(SUBMIT_OVER_TEXTURE);
    TextureClick := atlasMain.LoadTexture(SUBMIT_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();

    Width := Width / 2;
    Height := Height / 2;
  end;

  FBtnReplay.OnMouseClick := OnMouseClick;
  FBtnMenu.OnMouseClick := OnMouseClick;
  FBtnSubmit.OnMouseClick := OnMouseClick;

  FScene.RootNode.AddChild(FBtnReplay);
  FScene.RootNode.AddChild(FBtnMenu);
  FScene.RootNode.AddChild(FBtnSubmit);
  FScene.RootNode.AddChild(FPlayerName);
end;

procedure TpdGameOver.LoadRecords;

  function InitText(aText: WideString; aPos: TdfVec2f; aColor: TdfVec4f): IglrText;
  begin
    Result := Factory.NewText();
    Result.Font := fontCooper;
    Result.Text := aText;
    Result.Position := dfVec3f(aPos, Z_INGAMEMENU + 2);
    Result.Material.Diffuse := aColor;
    FScene.RootNode.AddChild(Result);
  end;

var
  rawData: TpdScoreTable;
  i: Integer;
begin
  for i := 0 to High(FTable) do
  with FTable[i] do
  begin
    FScene.RootNode.RemoveChild(tPlayerName);
    tPlayerName := nil;
    FScene.RootNode.RemoveChild(tScore);
    tScore := nil;
    FScene.RootNode.RemoveChild(tMaxPower);
    tMaxPower := nil;
  end;

  if not FSync.IsServerAvailable() then
  begin
    FOnlineTableText.Text := 'Таблица рекордов — сервер недоступен';
    FOnlineTableText.Material.Diffuse := colorRed;
    Exit();
  end
  else
  begin
    FOnlineTableText.Text := 'Таблица рекордов';
    FOnlineTableText.Material.Diffuse := colorWhite;
    rawData := FSync.GetScoreTable();
    SetLength(FTable, Length(rawData) + 1);

    //Шапка
    FTable[0].tPlayerName := InitText('Игрок',
      FOnlineTableText.Position2D
      + dfVec2f(TABLE_COL_PLAYER_OFFSET_X, TABLE_COL_PLAYER_OFFSET_Y),
      dfVec4f(1, 0, 0, 1));
    FTable[0].tScore := InitText('Очки',
      FOnlineTableText.Position2D
      + dfVec2f(TABLE_COL_SCORE_OFFSET_X, TABLE_COL_SCORE_OFFSET_Y),
      dfVec4f(1, 0, 0, 1));
    FTable[0].tMaxPower := InitText('Лучший удар',
      FOnlineTableText.Position2D
      + dfVec2f(TABLE_COL_MAXPOWER_OFFSET_X, TABLE_COL_MAXPOWER_OFFSET_Y),
      dfVec4f(1, 0, 0, 1));

    for i := 1 to High(FTable) do
    begin
      FTable[i].tPlayerName := InitText(rawData[i - 1].playerName,
        FOnlineTableText.Position2D
        + dfVec2f(TABLE_COL_PLAYER_OFFSET_X, TABLE_COL_PLAYER_OFFSET_Y)
        + dfVec2f(0, TABLE_ROW_HEIGHT * i),
        dfVec4f(1, 1, 1, 1));
      FTable[i].tScore := InitText(IntToStr(rawData[i - 1].score),
        FOnlineTableText.Position2D
        + dfVec2f(TABLE_COL_SCORE_OFFSET_X, TABLE_COL_SCORE_OFFSET_Y)
        + dfVec2f(0, TABLE_ROW_HEIGHT * i),
        dfVec4f(1, 1, 1, 1));
      FTable[i].tMaxPower := InitText(IntToStr(rawData[i - 1].maxPower),
        FOnlineTableText.Position2D
        + dfVec2f(TABLE_COL_MAXPOWER_OFFSET_X, TABLE_COL_MAXPOWER_OFFSET_Y)
        + dfVec2f(0, TABLE_ROW_HEIGHT * i),
        dfVec4f(1, 1, 1, 1));
    end;
    SetLength(rawData, 0);
  end;
end;

procedure TpdGameOver.LoadTexts;
begin
  FScores := Factory.NewText();
  FMaxPower := Factory.NewText();
  FFoulsCount := Factory.NewText();
  FSubmitScore := Factory.NewText();
  FOnlineTableText := Factory.NewText();

  with FScores do
  begin
    Font := fontCooper;
    Material.Diffuse := colorWhite;
    PivotPoint := ppTopLeft;
    Position := dfVec3f(SCORES_OFFSET_X, SCORES_OFFSET_Y, Z_INGAMEMENU + 2);
  end;

  with FMaxPower do
  begin
    Font := fontCooper;
    Material.Diffuse := colorWhite;
    PivotPoint := ppTopLeft;
    Position := FScores.Position + dfVec3f(MAXPOWER_OFFSET_X, MAXPOWER_OFFSET_Y, 0);
  end;

  with FFoulsCount do
  begin
    Font := fontCooper;
    Material.Diffuse := colorWhite;
    PivotPoint := ppTopLeft;
    Position := FScores.Position +  dfVec3f(FOULS_OFFSET_X, FOULS_OFFSET_Y, 0);
  end;

  with FSubmitScore do
  begin
    Font := fontCooper;
    Material.Diffuse := colorWhite;
    PivotPoint := ppTopLeft;
    Position := dfVec3f(R.WindowWidth div 2 + SUBMIT_OFFSET_X, SUBMIT_OFFSET_Y, Z_INGAMEMENU + 2);
    Text := 'Загрузить результат на сервер';
  end;

  with FOnlineTableText do
  begin
    Font := fontCooper;
    Material.Diffuse := colorWhite;
    PivotPoint := ppTopLeft;
    Position := dfVec3f(TEXT_TABLE_OFFSET_X, TEXT_TABLE_OFFSET_Y, Z_INGAMEMENU + 2);
  end;

  FScene.RootNode.AddChild(FScores);
  FScene.RootNode.AddChild(FMaxPower);
  FScene.RootNode.AddChild(FFoulsCount);
  FScene.RootNode.AddChild(FSubmitScore);
  FScene.RootNode.AddChild(FOnlineTableText);
end;

procedure TpdGameOver.Load;
begin
  inherited;
  R.RegisterScene(FScene);

  with (FScrGame as TpdGame).GetStatsData() do
  begin
    FScores.Text := 'Очки: ' + IntToStr(scores);
    FMaxPower.Text := 'Лучший удар: ' + IntToStr(maxPower);
    FFoulsCount.Text := 'Игра рукой: ' + IntToStr(foulsCount);
  end;
  FOnlineTableText.Text := '';
  FOnlineTableText.Material.Diffuse := colorWhite;

  FSubmitScore.Text := 'Загрузить результат на сервер';
  FSubmitScore.Material.Diffuse := colorWhite;

  FPlayerName.TextObject.Text := uGlobal.playerName;
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
      FGUIManager.RegisterElement(FBtnSubmit);
      FGuiManager.RegisterElement(FPlayerName);
      FGUIManager.Focused := FPlayerName;
      FBtnSubmit.Enabled := True;

      Tweener.AddTweenInterface(FBtnReplay, InterfacePositionXTween,
        tsExpoEaseIn, -100, R.WindowWidth div 2 + BTN_RETRY_OFFSET_X, 1.5, 1.0);
//      Tweener.AddTweenPSingle(@FBtnReplay.PPosition.x, tsExpoEaseIn,
//        -100, R.WindowWidth div 2 + BTN_RETRY_OFFSET_X, 1.5, 1.0);
      Tweener.AddTweenInterface(FBtnMenu, InterfacePositionXTween,
        tsExpoEaseIn, R.WindowWidth + 100, R.WindowWidth div 2 + BTN_MENU_OFFSET_X, 1.5, 1.0);
//      Tweener.AddTweenPSingle(@FBtnMenu.PPosition.x, tsExpoEaseIn,
//        R.WindowWidth + 100, R.WindowWidth div 2 + BTN_MENU_OFFSET_X, 1.5, 1.0);

      Tweener.AddTweenSingle(Self, @TopBlockTween, tsExpoEaseIn, -95, SCORES_OFFSET_Y, 1.5, 1.0);
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      Ft := TIME_FADEOUT;
      FGUIManager.UnregisterElement(FBtnReplay);
      FGUIManager.UnregisterElement(FBtnMenu);
      FGUIManager.UnregisterElement(FBtnSubmit);
      FGuiManager.UnregisterElement(FPlayerName);

      Tweener.AddTweenInterface(FBtnReplay, InterfacePositionXTween,
        tsExpoEaseIn, R.WindowWidth div 2 + BTN_RETRY_OFFSET_X, -100, 1.5, 0.0);

//      Tweener.AddTweenPSingle(@FBtnReplay.PPosition.x, tsExpoEaseIn,
//        R.WindowWidth div 2 + BTN_RETRY_OFFSET_X, -100, 1.5, 0.0);
      Tweener.AddTweenInterface(FBtnReplay, InterfacePositionXTween,
        tsExpoEaseIn, R.WindowWidth div 2 + BTN_MENU_OFFSET_X, R.WindowWidth + 100, 1.5, 0.0);
//      Tweener.AddTweenPSingle(@FBtnMenu.PPosition.x, tsExpoEaseIn,
//        R.WindowWidth div 2 + BTN_MENU_OFFSET_X, R.WindowWidth + 100, 1.5, 0.0);

      Tweener.AddTweenSingle(Self, TopBlockTween, tsExpoEaseIn, SCORES_OFFSET_Y, -95, 1.5, 0.0);
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdGameOver.SubmitScore;
begin
  if FSync.IsServerAvailable then
    with (FScrGame as TpdGame).GetStatsData() do
      if FSync.AddScore(FPlayerName.TextObject.Text, scores, maxPower) then
      begin
        FSubmitScore.Text := 'Успешно загружено!';
        FSubmitScore.Material.Diffuse := colorGreen;
        FBtnSubmit.Enabled := False;
        LoadRecords();
        Tweener.AddTweenSingle(Self, SubmitBlockTween, tsExpoEaseIn, SUBMIT_OFFSET_Y, -95, 1.5, 2.5);
      end
      else
      begin
        FSubmitScore.Text := 'Ошибка загрузки';
        FSubmitScore.Material.Diffuse := colorRed;
      end
  else
  begin
    FSubmitScore.Text := 'Сервер недоступен';
    FSubmitScore.Material.Diffuse := colorRed;
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

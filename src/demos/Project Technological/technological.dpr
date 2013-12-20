program technological;
uses
  ShareMem,
  Windows,
  uGlobal in 'uGlobal.pas',
  bass in '..\..\headers\bass.pas',
  dfTweener in '..\..\headers\dfTweener.pas',
  glr in '..\..\headers\glr.pas',
  glrMath in '..\..\headers\glrMath.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  ogl in '..\..\headers\ogl.pas',
  uBox2DImport in '..\..\headers\box2d\uBox2DImport.pas',
  UPhysics2D in '..\..\headers\box2d\UPhysics2D.pas',
  UPhysics2DTypes in '..\..\headers\box2d\UPhysics2DTypes.pas',
  glrSound in '..\..\headers\glrSound.pas',
  uGame in 'uGame.pas';

const
  {$REGION 'Menu positions'}
  ORIGIN_X = 500;

  CONTINUE_X = ORIGIN_X - 270;
  CONTINUE_Y = 60;
  RESTART_X = ORIGIN_X;
  RESTART_Y = CONTINUE_Y;
  EXIT_X = ORIGIN_X + 270;
  EXIT_Y = CONTINUE_Y;

  PAUSE_TEXT_X = ORIGIN_X;
  PAUSE_TEXT_Y = 5;

  {$ENDREGION}

var
  bigPause, pause: Boolean;
  game: TpdGame;

  //Menu
  menuContainer: IglrNode;
  btnContinue, btnRestart, btnExit: IglrGUITextButton;
  textPause: IglrText;

  {$REGION 'Initial game logic'}

  procedure GameStart();
  begin
    if Assigned(game) then
      game.Free();

    game := TpdGame.Create();
  end;

  {$ENDREGION}

  {$REGION 'Menu logic'}

  procedure MenuShowOrHide(IsShow: Boolean);
  begin
    menuContainer.Visible := IsShow;
    if IsShow then
    begin
      R.GUIManager.RegisterElement(btnContinue);
      R.GUIManager.RegisterElement(btnRestart);
      R.GUIManager.RegisterElement(btnExit);
    end
    else
    begin
      R.GUIManager.UnregisterElement(btnContinue);
      R.GUIManager.UnregisterElement(btnRestart);
      R.GUIManager.UnregisterElement(btnExit);
    end;
  end;

  procedure MouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin
    sound.PlaySample(sClick);
    if Sender = (btnContinue as IglrGUIElement) then
    begin
      pause := False;
      MenuShowOrHide(False);
    end

    else if Sender = (btnRestart as IglrGUIElement) then
      GameStart()

    else if Sender = (btnExit as IglrGUIElement) then
      R.Stop();
  end;

  procedure MenuInit();
  begin
    menuContainer := Factory.NewNode();
    hudScene.RootNode.AddChild(menuContainer);

    btnContinue := Factory.NewGUITextButton();
    btnRestart := Factory.NewGUITextButton();
    btnExit := Factory.NewGUITextButton();
    textPause := Factory.NewText();

    with btnContinue do
    begin
      PivotPoint := ppCenter;
      Position := dfVec3f(CONTINUE_X, CONTINUE_Y, Z_INGAMEMENU);

      with TextObject do
      begin
        Font := fontBaltica;
        Text := 'Продолжить';
        PivotPoint := ppTopLeft;
        Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
        Material.Diffuse := colorOrange;
      end;
      TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
      TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
      TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

      UpdateTexCoords();
      SetSizeToTextureSize();
    end;

    with btnRestart do
    begin
      PivotPoint := ppCenter;
      Position := dfVec3f(RESTART_X, RESTART_Y, Z_INGAMEMENU);

      with TextObject do
      begin
        Font := fontBaltica;
        Text := 'Еще раз';
        PivotPoint := ppTopLeft;
        Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
        Material.Diffuse := colorOrange;
      end;
      TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
      TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
      TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

      UpdateTexCoords();
      SetSizeToTextureSize();
    end;

    with btnExit do
    begin
      PivotPoint := ppCenter;
      Position := dfVec3f(EXIT_X, EXIT_Y, Z_INGAMEMENU);

      with TextObject do
      begin
        Font := fontBaltica;
        Text := 'Выход';
        PivotPoint := ppTopLeft;
        Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
        Material.Diffuse := colorOrange;
      end;
      TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
      TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
      TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);

      UpdateTexCoords();
      SetSizeToTextureSize();
    end;

    textPause := Factory.NewText();
    with textPause do
    begin
      Font := fontBaltica;
      Text := 'Пауза';
      PivotPoint := ppTopCenter;
      Position := dfVec3f(PAUSE_TEXT_X, PAUSE_TEXT_Y, Z_INGAMEMENU);
    end;

    btnContinue.OnMouseClick := MouseClick;
    btnRestart.OnMouseClick := MouseClick;
    btnExit.OnMouseClick := MouseClick;
    menuContainer.AddChild(btnContinue);
    menuContainer.AddChild(btnRestart);
    menuContainer.AddChild(btnExit);
    menuContainer.AddChild(textPause);

    menuContainer.Visible := False;
  end;

  {$ENDREGION}

  procedure OnUpdate(const dt: Double);
  begin
    cursor.Rotation := cursor.Rotation + 200 * dt;
    if cursor.Rotation > 360 then
      cursor.Rotation := 0;
    if R.Input.IsKeyPressed(VK_PAUSE) then
      bigPause := not bigPause;

    if bigPause then
      Exit();

    Tweener.Update(dt);

    if R.Input.IsKeyPressed(VK_ESCAPE) then
    begin
      pause := not pause;
      MenuShowOrHide(pause);
    end;

    if not pause then
    begin
      game.Update(dt);
    end;
  end;

  {$REGION 'Callbacks'}

  procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
  begin
    cursor.Position2D := dfVec2f(X, Y);
    if (not pause) then
      game.OnMouseMove(X, Y, Shift);
  end;

  procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin
    if (not pause) then
      game.OnMouseDown(X, Y, MouseButton, Shift);
  end;

  procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin
    if (not pause) then
      game.OnMouseUp(X, Y, MouseButton, Shift);
  end;

  {$ENDREGION}

begin
  Randomize();
  LoadRendererLib();
  gl.Init();

  Factory := glrGetObjectFactory();
  R := glrGetRenderer();
  R.Init('settings_tech.txt');
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('igdc #103 - Techological. Версия '
    + GAMEVERSION + ' [glRenderer ' + R.VersionText + ']');

  InitializeGlobal();
  MenuInit();
  GameStart();
  R.Start();
  FinalizeGlobal();

  R.DeInit();
  UnLoadRendererLib();
end.

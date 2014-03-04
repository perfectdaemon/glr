program space106;
uses
  Windows,
  SysUtils,
  bass in '..\..\headers\bass.pas',
  dfTweener in '..\..\headers\dfTweener.pas',
  glr in '..\..\headers\glr.pas',
  glrMath in '..\..\headers\glrMath.pas',
  glrSound in '..\..\headers\glrSound.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  ogl in '..\..\headers\ogl.pas',
  uGlobal in 'uGlobal.pas',
  uShip in 'uShip.pas',
  uPause in 'uPause.pas',
  uSpace in 'uSpace.pas';

var
  bigPause, pause: Boolean;
  debug: IglrText;

  procedure CameraUpdate(const dt: Double);
  begin
    //mainScene.RootNode.Position := player.Body.Position - dfVec3f(R.WindowWidth div 2, R.WindowHeight div 2, 0);
  end;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyPressed(VK_ESCAPE) then
    begin
      pauseMenu.ShowOrHide();
      pause := True;
    end;

    if R.Input.IsKeyPressed(VK_PAUSE) then
      bigPause := not bigPause;

    if not bigPause then
    begin
      Tweener.Update(dt);

      if not pause then
      begin
        //Main code here
        player.Update(dt);
        pauseMenu.Update(dt);
        debug.Text := FloatToStr(R.Camera.Position.x) + ':' + FloatToStr(R.Camera.Position.y);
        space.Update(dt);

        CameraUpdate(dt);

        if R.Input.IsKeyDown(VK_LEFT) then
          R.Camera.Translate(0, 200 * dt)
          //mainScene.RootNode.PPosition.x := mainScene.RootNode.PPosition.x + 200 * dt
        else if R.Input.IsKeyDown(VK_RIGHT) then
          R.Camera.Translate(0, -200 * dt);
          //mainScene.RootNode.PPosition.x := mainScene.RootNode.PPosition.x - 200 * dt;
        if R.Input.IsKeyDown(VK_UP) then
          R.Camera.Translate(200 * dt, 0)
          //mainScene.RootNode.PPosition.y := mainScene.RootNode.PPosition.y + 200 * dt
        else if R.Input.IsKeyDown(VK_DOWN) then
          R.Camera.Translate(-200 * dt, 0);
          //mainScene.RootNode.PPosition.y := mainScene.RootNode.PPosition.y - 200 * dt;
      end;
    end;
  end;

  procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
  begin
    mousePos := dfVec2f(X, Y);
    mousePosAtScene := mousePos - dfVec2f(mainScene.RootNode.Position);
  end;

  procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin

  end;

  procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin

  end;

begin
  Randomize();
  LoadRendererLib();
  gl.Init();

  R := glrGetRenderer();
  R.Init('settings_space.txt');
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('Космосим для конкурса igdc#106 '
    + GAMEVERSION + ' [glRenderer ' + R.VersionText + ']');
  Factory := glrGetObjectFactory();

  InitializeGlobal();

  debug := Factory.NewText();
  debug.Font := fontSouvenir;
  debug.Position := dfVec3f(500, 500, 50);
  hudScene.RootNode.AddChild(debug);

  GameStart();
  R.Start();
  GameEnd();

  FinalizeGlobal();

  R.DeInit();
  UnLoadRendererLib();
end.

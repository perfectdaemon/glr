program wind107;
uses
  Windows,
  bass in '..\..\headers\bass.pas',
  dfTweener in '..\..\headers\dfTweener.pas',
  glr in '..\..\headers\glr.pas',
  glrMath in '..\..\headers\glrMath.pas',
  glrSound in '..\..\headers\glrSound.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  ogl in '..\..\headers\ogl.pas',
  uAccum in 'uAccum.pas',
  uGlobal in 'uGlobal.pas',
  uHud in 'uHud.pas',
  uParticles in 'uParticles.pas',
  uPause in 'uPause.pas',
  uArrow in 'uArrow.pas',
  uLevel in 'uLevel.pas';

var
  bigPause{, pause}: Boolean;
  debug: IglrText;

  procedure CameraUpdate(const dt: Double);
  var
    camPos: TdfVec3f;
  begin
    camPos := currentLevel.Arrow.Sprite.Position - cameraOffset;
    camPos := camPos.Clamp(dfVec3f(0, currentLevel.Target.Position.y - 300, -100),
      dfVec3f(R.WindowWidth, currentLevel.Arrow.StartPos.y + 100, 100));
    R.Camera.Position := R.Camera.Position.Lerp(camPos, 2 * dt);
  end;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyPressed(VK_ESCAPE) then
      pauseMenu.ShowOrHide();

    if R.Input.IsKeyPressed(VK_PAUSE) then
      bigPause := not bigPause;


    if not bigPause then
    begin
      mousePosAtScene := mousePos + dfVec2f(R.Camera.Position);
      Tweener.Update(dt);

      if not pauseMenu.IsActive then
      begin
        if R.Input.IsKeyPressed(VK_E) then
          currentLevel.EditorMode := not currentLevel.EditorMode;

        if not currentLevel.EditorMode then
        begin
          //Main code here
          pauseMenu.Update(dt);


          CameraUpdate(dt);
          particles.Update(dt);
          hud.Update(dt);
        end
        else
        begin

        end;

        currentLevel.Update(dt);
      end;
    end;
  end;

  procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
  begin
    mousePos := dfVec2f(X, Y);
  end;

  procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin
    if not pauseMenu.IsActive then
    begin

    end;
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
  R.Init('settings_wind.txt');
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('Unlucky shooter [igdc#107]. Версия '
    + GAMEVERSION + ' [glRenderer ' + R.VersionText + ']');
  Factory := glrGetObjectFactory();

  InitializeGlobal();

  debug := Factory.NewText();
  debug.Font := fontSouvenir;
  debug.Position := dfVec3f(500, 500, 50);
  hudScene.RootNode.AddChild(debug);

  GameStart(-1);

  //debgu
  currentLevel.Arrow.Sprite.Position2D := dfVec2f(R.WindowWidth div 2, R.WindowHeight - 2 * currentLevel.Arrow.Sprite.Height);
  currentLevel.Target.Position2D := dfVec2f(R.WindowWidth div 2, -900);
  currentLevel.Arrow.MoveDir := dfVec2f(5, -360);

  currentLevel.AddWall(dfVec2f(300, -100));
  currentLevel.AddWall(dfVec2f(380, -400));

  currentLevel.GenerateClouds();

  R.Start();
  GameEnd();

  FinalizeGlobal();

  R.DeInit();
  UnLoadRendererLib();
end.

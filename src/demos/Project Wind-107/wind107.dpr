program wind107;
uses
  Windows,
  (*SysUtils,*)
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
  uPause in 'uPause.pas';

var
  bigPause{, pause}: Boolean;
  debug: IglrText;

  procedure CameraUpdate(const dt: Double);
  begin
//    R.Camera.Position := player.Body.Position - playerOffset;
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
        //Main code here
        pauseMenu.Update(dt);


        CameraUpdate(dt);
        particles.Update(dt);
        hud.Update(dt);
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
  R.WindowCaption := PWideChar('Unlucky shooter  [igdc#107]. Версия '
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

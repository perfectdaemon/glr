program space106;
uses
  Windows,
  bass in '..\..\headers\bass.pas',
  dfTweener in '..\..\headers\dfTweener.pas',
  glr in '..\..\headers\glr.pas',
  glrMath in '..\..\headers\glrMath.pas',
  glrSound in '..\..\headers\glrSound.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  ogl in '..\..\headers\ogl.pas',
  uGlobal in 'uGlobal.pas';

  var
    bigPause: Boolean;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyPressed(VK_ESCAPE) then
      R.Stop();

    if R.Input.IsKeyPressed(VK_PAUSE) then
      bigPause := not bigPause;

    if not bigPause then
    begin
      //Main code here
      Tweener.Update(dt);
    end;
  end;

  procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
  begin

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

  R.Start();


  FinalizeGlobal();

  R.DeInit();
  UnLoadRendererLib();
end.

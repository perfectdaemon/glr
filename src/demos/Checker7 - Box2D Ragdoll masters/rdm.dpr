program rdm;
uses
  Windows,
  dfHEngine in '..\..\common\dfHEngine.pas',
  dfHGL in '..\..\common\dfHGL.pas',
  dfMath in '..\..\common\dfMath.pas',
  dfHRenderer in '..\..\headers\dfHRenderer.pas',
  dfHUtility in '..\..\headers\dfHUtility.pas',
  uBox2DImport in '..\..\headers\box2d\uBox2DImport.pas',
  UPhysics2D in '..\..\headers\box2d\UPhysics2D.pas',
  UPhysics2DTypes in '..\..\headers\box2d\UPhysics2DTypes.pas',
  uCharacterController in 'uCharacterController.pas',
  uGUI in 'uGUI.pas',
  uCharacterBoxes in 'uCharacterBoxes.pas',
  uGlobal in 'uGlobal.pas',
  dfTweener in '..\..\common\dfTweener.pas';

var
  bPause, bPausePressed: Boolean;

  cl: TglrContactListener;
  g: TVector2;

  character, c2: TglrBoxCharacter;
  player_controller, p2: TglrPlayerCharacterController;

  charParams: TglrCharacterParams =
    (initialPosition: (X: 200; Y: 200;);
     charForm: cfCircle;
     charGroup: 1;);

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyDown(VK_ESCAPE) then
      R.Stop();
    if R.Input.IsKeyPressed(VK_SPACE, @bPausePressed) then
      bPause := not bPause;
    if not bPause then
    begin
      fpsCounter.Update(dt);
      b2w.Update(dt);
      Tweener.Update(dt);
      gui.Update(dt);
    end;
  end;

  procedure OnSimulation(const FixedDeltaTime: Double);
  begin
    character.Update(FixedDeltaTime);
    c2.Update(FixedDeltaTime);
  end;

begin
  LoadRendererLib();
  R := glrCreateRenderer();
  Factory := glrGetObjectFactory();
  R.Init('settings.txt');
  R.OnUpdate := OnUpdate;
  gl.Init();
  gl.ClearColor(0.8, 0.9, 0.87, 1);

  mainScene := Factory.New2DScene();
  hudScene := Factory.New2DScene();
  R.RegisterScene(mainScene);
  R.RegisterScene(hudScene);

  InitializeGlobal();

  //Box2D
  g.SetValue(0, 0.9);
  b2w := Tglrb2World.Create(g, True, 1 / 60, 6);
  b2w.OnBeforeSimulation := OnSimulation;
  cl := TglrContactListener.Create();
  b2w.SetContactListener(cl);
  dfb2InitBoxStatic(b2w, dfVec2f(0, 300), dfVec2f(5, 600), 0, 1, 1, 0, $FFFF, $FFFF, 2);
  dfb2InitBoxStatic(b2w, dfVec2f(800, 300), dfVec2f(5, 600), 0, 1, 1, 0, $FFFF, $FFFF, 2);
  dfb2InitBoxStatic(b2w, dfVec2f(400, 600), dfVec2f(800, 2), 0, 1, 1, 0, $FFFF, $FFFF, 2);
  dfb2InitBoxStatic(b2w, dfVec2f(400, 0), dfVec2f(800, 2), 0, 1, 1, 0, $FFFF, $FFFF, 2);


  //Character 1
  character := TglrBoxCharacter.Init(b2w, mainScene, charParams);
  player_controller := TglrPlayerCharacterController.Init(R.Input, character,
    TglrControllerKeys.Init(VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN));

  //Character 2
  charParams.charGroup := 2;
  charParams.initialPosition := dfVec2f(400, 400);
  c2 := TglrBoxCharacter.Init(b2w, mainScene, charParams);
  p2 := TglrPlayerCharacterController.Init(R.Input, c2,
    TglrControllerKeys.Init($41, $44, $57, $53));



  R.Start();

  player_controller.Free;
  character.Free;
  p2.Free();
  c2.Free();

  cl.Free;
  b2w.Free;

  FinalizeGlobal();

  R.DeInit();
  UnLoadRendererLib();
end.

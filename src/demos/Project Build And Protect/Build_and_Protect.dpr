program Build_and_Protect;


uses
  uAccum in 'uAccum.pas',
  uGlobal in 'uGlobal.pas',
  uGUI in 'uGUI.pas',
  uBlocks in 'uBlocks.pas',
  uPopup in 'uPopup.pas',
  uSettings_SaveLoad in 'uSettings_SaveLoad.pas',
  uSound in 'uSound.pas',
  uGameScreen.Game in 'gamescreens\uGameScreen.Game.pas',
  uGameScreen.GameOver in 'gamescreens\uGameScreen.GameOver.pas',
  uGameScreen.MainMenu in 'gamescreens\uGameScreen.MainMenu.pas',
  uGameScreen in 'gamescreens\uGameScreen.pas',
  uGameScreenManager in 'gamescreens\uGameScreenManager.pas',
  bass in '..\..\headers\bass.pas',
  dfHRenderer in '..\..\headers\dfHRenderer.pas',
  dfHUtility in '..\..\headers\dfHUtility.pas',
  dfHEngine in '..\..\common\dfHEngine.pas',
  dfHGL in '..\..\common\dfHGL.pas',
  dfMath in '..\..\common\dfMath.pas',
  dfTweener in '..\..\common\dfTweener.pas',
  uPlayer in 'uPlayer.pas',
  uEnemies in 'uEnemies.pas',
  uBullets in 'uBullets.pas';

var
  gsManager: TpdGSManager;

  procedure OnUpdate(const dt: Double);
  begin
    if GSManager.IsQuitMessageReceived then
      R.Stop();
    gsManager.Update(dt);
    Tweener.Update(dt);
  end;

  procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
  begin
    if Assigned(gsManager.Current) then
      gsManager.Current.OnMouseMove(X, Y, Shift);
    mousePos.X := X;
    mousePos.Y := Y;
  end;

  procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin
    if Assigned(gsManager.Current) then
      gsManager.Current.OnMouseDown(X, Y, MouseButton, Shift);
    mousePos.X := X;
    mousePos.Y := Y;
  end;

  procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin
    if Assigned(gsManager.Current) then
      gsManager.Current.OnMouseUp(X, Y, MouseButton, Shift);
    mousePos.X := X;
    mousePos.Y := Y;
  end;

begin
  Randomize();
  LoadRendererLib();
  gl.Init();

  R := glrCreateRenderer();
  R.Init('settings_rds.txt');
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('Build & Protect! Версия '
    + GAMEVERSION + ' [glRenderer ' + R.VersionText + ']');
  Factory := glrGetObjectFactory();

  gl.ClearColor(1, 1, 1, 1);
  InitializeGlobal();
  gsManager := TpdGSManager.Create();
//  mainMenu := TpdMainMenu.Create();
  game := TpdGame.Create();
//  gameOver := TpdGameOver.Create();

//  mainMenu.SetGameScreenLinks(game);
  game.SetGameScreenLinks(gameOver);
//  gameOver.SetGameScreenLinks(mainMenu, game);

//  gsManager.Add(mainMenu);
  gsManager.Add(game);
//  gsManager.Add(gameOver);
//  {$IFDEF DEBUG}
  gsManager.Notify(game, naSwitchTo);
//  {$ELSE}
//  gsManager.Notify(mainMenu, naSwitchTo);
//  {$ENDIF}

  R.Start();

  gsManager.Free();
  FinalizeGlobal();

  R.DeInit();
  R._Release();
  R := nil;
  UnLoadRendererLib();
end.

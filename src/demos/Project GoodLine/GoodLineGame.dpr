{
  TODO:
    Переключение передач
  + Перемещение камеры
    Редактирование ландшафта

    Груз ?
    Таймер доставки
    Звуки

}

program GoodLineGame;
uses
  ShareMem,
  Windows,
  uGlobal in 'uGlobal.pas',
  uSound in 'uSound.pas',
  uGameScreen.Game in 'gamescreens\uGameScreen.Game.pas',
  uGameScreen.GameOver in 'gamescreens\uGameScreen.GameOver.pas',
  uGameScreen.MainMenu in 'gamescreens\uGameScreen.MainMenu.pas',
  uGameScreen in 'gamescreens\uGameScreen.pas',
  uGameScreenManager in 'gamescreens\uGameScreenManager.pas',
  bass in '..\..\headers\bass.pas',
  dfTweener in '..\..\headers\dfTweener.pas',
  glr in '..\..\headers\glr.pas',
  glrMath in '..\..\headers\glrMath.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  ogl in '..\..\headers\ogl.pas',
  uBox2DImport in '..\..\headers\box2d\uBox2DImport.pas',
  UPhysics2D in '..\..\headers\box2d\UPhysics2D.pas',
  UPhysics2DTypes in '..\..\headers\box2d\UPhysics2DTypes.pas',
  uCar in 'uCar.pas',
  uSettingsSaveLoad in 'uSettingsSaveLoad.pas',
  uCarSaveLoad in 'uCarSaveLoad.pas',
  uLevel in 'uLevel.pas',
  uHud in 'uHud.pas';

var
  gsManager: TpdGSManager;
  bigPause: Boolean;

  procedure OnUpdate(const dt: Double);
  begin
    if GSManager.IsQuitMessageReceived then
      R.Stop();

    if R.Input.IsKeyPressed(VK_PAUSE) then
      bigPause := not bigPause;

    if not bigPause then
    begin
      gsManager.Update(dt);
      Tweener.Update(dt);
    end;
  end;

  procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
  begin
    if Assigned(gsManager.Current) then
      gsManager.Current.OnMouseMove(X, Y, Shift);
  end;

  procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin
    if Assigned(gsManager.Current) then
      gsManager.Current.OnMouseDown(X, Y, MouseButton, Shift);
  end;

  procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState);
  begin
    if Assigned(gsManager.Current) then
      gsManager.Current.OnMouseUp(X, Y, MouseButton, Shift);
  end;

begin
  Randomize();
  LoadRendererLib();
  gl.Init();

  R := glrGetRenderer();
  R.Init('settings_glg.txt');
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('GoodLine Game Версия '
    + GAMEVERSION + ' [glRenderer ' + R.VersionText + ']');
  Factory := glrGetObjectFactory();

  InitializeGlobal();
  gsManager := TpdGSManager.Create();
  mainMenu := TpdMainMenu.Create();
  game := TpdGame.Create();
  gameOver := TpdGameOver.Create();

  mainMenu.SetGameScreenLinks(game);
  game.SetGameScreenLinks(gameOver, mainMenu);
  gameOver.SetGameScreenLinks(mainMenu, game);

  gsManager.Add(mainMenu);
  gsManager.Add(game);
  gsManager.Add(gameOver);
  {$IFDEF DEBUG}
  gsManager.Notify(game, naSwitchTo);
  {$ELSE}
  gsManager.Notify(mainMenu, naSwitchTo);
  {$ENDIF}

  R.Start();

  gsManager.Free();
  FinalizeGlobal();

  R.DeInit();
  R._Release();
  R := nil;
  UnLoadRendererLib();
end.

{
  TODO:

    AI
      Учитывать положение себя и игрока для поворота
    + Крутиться в разные стороны


  - Убрать паузу при старте, добавить отсчет
  + Увеличить время паузы твина частей при ударе

  + Главное меню
    + Добавить опцию - сложность противника
    - Добавить текст - зайдите в опции, чтобы поменять сложность
    + Добавить текст igdc

  + Отталкивание при ударе
  + Звук при ударе

  + Punch2 - понизить громкость

  + Учитывать сложность - урон игрока, урон противника, время плохой штуки

  + Здоровье у игроков
      + Параметр в классе
      + Полоска в гуе
      + Уменьшение при дамаже

    Суперудар
      + Шкала "Сила"
      + Накопление при ударах
      + Плавное накопление по твину
      - Затухание при получении ударов (?)
      + На 30% есть возможность применить суперудар, варианты:
          Волна во все стороны
          Бросок сюрикена в ближайшего противника
        + "Привязка" веса к ногам противника на n секунд = 30%
        Оповещение, что можно сделать удар
        Оповещение, что невозможно сделать удар (при попытке применения)


  + Смерть
    + Статус IsDead
    + Разлет на части

  + Меню "геймовер"
    + Надпись You win / You lose
    + Кнопки replay, menu
    + Счетчик до перехода в геймовер


  + Меню паузы
    + Кнопки continue, menu

  + Спецэффекты
    + Звездочки при ударе/блоке
    + Улучшить спецэффекты
    + Сменить текстуру партикла
    + Кровавый партикл при ударе

  + BUG #1: Можно применить способность после смерти противника
  + BUG #2: Жор памяти когда вышел, а плохая штука не закончилась
    BUG #3: Не сбрасываются глобальные переменные
}


program RagdollFighting;
uses
  ShareMem,
  Windows,
  glr in '..\..\headers\glr.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  uBox2DImport in '..\..\headers\box2d\uBox2DImport.pas',
  UPhysics2D in '..\..\headers\box2d\UPhysics2D.pas',
  UPhysics2DTypes in '..\..\headers\box2d\UPhysics2DTypes.pas',
  uCharacterController in 'uCharacterController.pas',
  uGUI in 'uGUI.pas',
  uCharacter in 'uCharacter.pas',
  uGlobal in 'uGlobal.pas',
  uGameScreen.Game in 'gamescreens\uGameScreen.Game.pas',
  uGameScreen.GameOver in 'gamescreens\uGameScreen.GameOver.pas',
  uGameScreen.MainMenu in 'gamescreens\uGameScreen.MainMenu.pas',
  uGameScreen in 'gamescreens\uGameScreen.pas',
  uGameScreen.PauseMenu in 'gamescreens\uGameScreen.PauseMenu.pas',
  uGameScreenManager in 'gamescreens\uGameScreenManager.pas',
  uSound in 'uSound.pas',
  bass in '..\..\headers\bass.pas',
  uAccum in 'uAccum.pas',
  uPopup in 'uPopup.pas',
  uSettings_SaveLoad in 'uSettings_SaveLoad.pas',
  uParticles in 'uParticles.pas',
  dfTweener in '..\..\headers\dfTweener.pas',
  glrMath in '..\..\headers\glrMath.pas',
  ogl in '..\..\headers\ogl.pas';

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

  R := glrGetRenderer();
  R.Init('settings_rds.txt');
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('Ragdoll Fighting. Прототип. Версия '
    + GAMEVERSION + ' [glRenderer ' + R.VersionText + ']');
  Factory := glrGetObjectFactory();

  InitializeGlobal();
  gsManager := TpdGSManager.Create();
  mainMenu := TpdMainMenu.Create();
  game := TpdGame.Create();
  pauseMenu := TpdPauseMenu.Create();
  gameOver := TpdGameOver.Create();

  mainMenu.SetGameScreenLinks(game);
  game.SetGameScreenLinks(pauseMenu, gameOver);
  pauseMenu.SetGameScreenLinks(mainMenu, game);
  gameOver.SetGameScreenLinks(mainMenu, game);

  gsManager.Add(mainMenu);
  gsManager.Add(game);
  gsManager.Add(pauseMenu);
  gsManager.Add(gameOver);
  {$IFDEF DEBUG}
  game.GameMode := gmSingle;
  gsManager.Notify(game, naSwitchTo);
  {$ELSE}
  gsManager.Notify(mainMenu, naSwitchTo);
  {$ENDIF}

  R.Start();

  gsManager.Free();
  FinalizeGlobal();

  R.DeInit();
  R := nil;
  UnLoadRendererLib();
end.

{
  BUGS:
  + BUG #1:  Ошибка при закрытии игры. Возникает только если был переход в игру.
             Вероятно связано с подсчетом ссылок
  + BUG #2:  Не сохраняются настройки уровня громкости
  + BUG #3:  Подальше вверх двигать панели в GameOver
  + BUG #4:  Tween-появления таблицы рекордов
    BUG #5:  Fadeout таблицы рекордов



  МЕНЮ:
    Меню паузы
      Продолжить, меню
      Подсказка по управлению
      Подсказка, что делать

  + Меню геймовера
  +   Всего мячей выбито
  +   Максимальная сила удара
  +   Ударов руками
  +   Кнопки - реплей, меню
  + Меню главное
  +   Fade out
  -   Circles
  + Меню настроек
  +   громкость звуков,
  +   музыки,
      цвет фона
      имя игрока
  + Онлайн-таблица рекордов
  +   Получение таблицы
  +   Отображение таблицы
  +   Запись игрока

  ИГРА:
    Обычный режим:
  +   Добавить время
  +   Спрайты сверху и снизу

    Управление с помощью мыши

  + Сохранение/загрузка настроек

    Мячи, которые нельзя трогать (бомбы)
    Сумасшедшие мячи (перемещающиеся по замысловатой траектории)
    Игровые ивенты (единоразовый спаун 10-15 мячей)
    Достижения
    Музыка
    Доп звук
  +   Клик на кнопки
    Спецэффекты на частицах
  + Уменьшить штраф за руки
  + Сделать таймаут для штрафа на руки
  +-Влияние настроек online и mousecontrol


    БОНУСЫ?!
}

program RagdollSport;
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
  uObjects in 'uObjects.pas',
  uAccum in 'uAccum.pas',
  uPopup in 'uPopup.pas',
  uGameSync in 'uGameSync.pas',
  uSettings_SaveLoad in 'uSettings_SaveLoad.pas',
  dfTweener in '..\..\headers\dfTweener.pas',
  glrMath in '..\..\headers\glrMath.pas',
  ogl in '..\..\headers\ogl.pas';

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

  R := glrGetRenderer();
  R.Init('settings_rds.txt');
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('Ragdoll Sports. Прототип. Версия '
    + GAMEVERSION + ' [glRenderer ' + R.VersionText + ']');
  Factory := glrGetObjectFactory();

  gl.ClearColor(99 / 255, 99 / 255, 99 / 255, 1.0);
  InitializeGlobal();
  gsManager := TpdGSManager.Create();
  mainMenu := TpdMainMenu.Create();
  game := TpdGame.Create();
//  pauseMenu := TpdPauseMenu.Create();
  gameOver := TpdGameOver.Create();

  mainMenu.SetGameScreenLinks(game);
  game.SetGameScreenLinks(pauseMenu, gameOver);
//  pauseMenu.SetGameScreenLinks(mainMenu, game);
  gameOver.SetGameScreenLinks(mainMenu, game);

  gsManager.Add(mainMenu);
  gsManager.Add(game);
//  gsManager.Add(pauseMenu);
  gsManager.Add(gameOver);
//  {$IFDEF DEBUG}
//  gsManager.Notify(game, naSwitchTo);
//  {$ELSE}
  gsManager.Notify(mainMenu, naSwitchTo);
//  {$ENDIF}

  R.Start();

  gsManager.Free();
  FinalizeGlobal();

  R.DeInit();
  R._Release();
  R := nil;
  UnLoadRendererLib();
end.

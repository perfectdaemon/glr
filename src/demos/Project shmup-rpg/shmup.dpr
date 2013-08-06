{
  Прототип Shoot 'em up.

  Старт разработки: 17 февраля 2013.
  Окончание разработки: ---

+ BUG #1: патроны рисуются с visible false
+ BUG #2: неправильный порядок отрисовки у интерфейса
+ BUG #3: AV при выходе пули за пределы экрана при TpdAccum
+ BUG #4: Не рисуется прицел
+ BUG #5: Неверный расчет исчезновения пуль при уроне из дробовика
+ BUG #6: Баг стрельбы, когда курсор близко к ковбою
+ BUG #7: Патроны не восстанавливаются после рестарта
+ BUG #8: "Клин" автомата при переключении
+ BUG #9: Игрок не попорачивается, если при перемещении WASD не двигать мышь
  BUG #10: Игрок продолжает стрелять, если поставить паузу и снять ее, даже если мышь была отжата
+ BUG #11: Белая окантовка у наслаивающихся койотов
  BUG #12: Мертвый койот поверх живого
+ BUG #13: Из меню паузы при нажатии "Продолжить" - начинается новая игра
+ BUG #14: Из меню паузы в основное меню - остается загруженной и отрисовываемой сама игра
  BUG #15: Странные артефакты у спрайта игрока
 !BUG #16: EInvalidOp редко. Думаю, что дело в просчете LinerVelocity.Length
           Не факт, что в нем
  BUG #17: Прицел рисуется в меню паузы
+ BUG #18: Физика не переинициализируется

  TODO по прототипам:
+   Прототип 1: ГГ перемещается по WASD, поворачивается за мышью, "стреляет"
+   Прототип 2: Появляющиеся по краям враги идущие к ГГ, которые могут быть убиты
+   Прототип 3: Очки, Здоровье у врагов
+   Прототип 4: Два(три) оружия, Критические попадания,
+   Прототип 5: Здоровье и смерть ГГ, Рестарт, Прицел под курсором
+   Прототип 6: Бонусы и патроны из врагов, Отображение всплывающих надписей
    Прототип 7: Полноценное меню, Причесывание дизайна, Твининг анимаций,
    Прототип Х: Начинаем мутить геймплей

  TODO:
+   Проверить критические попадания - есть они или нет :)
+   player.Hit, когда монстры приближаются к ГГ
+   Сделать рестарт
+   Написать абстрактный аккумулятор
+   Реализовать Z-index для спрайтов в glRenderer
+   Выпадающие аптечки
+   Бэкграунд
+   Статистика при gameover?
+   Привязать меню
+   Спрайт огня при выстреле
+   Спрайты врагов (+ разные спрайты на смерть, атаку)
+   Изменить размер хитбокса для врагов в соответствии со спрайтами
+   Повороты врагов
+   Отображение урона для игрока при атаке всплывающим сообщением
    Подтормаживание врагов?
    HUD - оружие, патроны и очки
+-  Плавные переходы между меню
+-  Привязка физики
    Шаги на песке от героя
    Меню авторов
    Меню настроек
    Меню рекордов
    Несколько жизней
    Разброс оружия
    Обоймы и перезарядка
    Загрузка атласов в формате .atlas. Сделать сторонним модулем

    Сделать аналог чайлдов, чтобы сделать возможным вложенные трансформации
      (привязать спрайт огня при выстреле, точку выстрела) Как?


  Отчет

  2013-02-17 - Готов Прототип №1. ОБнуражен баг #1
  2013-02-18 - Баг #1 исправлен в glRenderer (проверка visible в scene2d)
               Готов прототип №2.
  2013-02-19 - Готов прототип №3, исправлен баг с уроном.
  2013-02-20 - Начал разделять юниты на модули.
  2013-02-21 - Почти готов прототип №4. Осталось замутить разные пули для
               разного оружия
               Разделение на модули
  2013-02-23 - Нарисована часть арта: ГГ, три вида оружия, кнопки для меню
  2013-02-24 - Сделаны отдельные процедуры для разного типа оружия. Дробовик
               работает :)
  2013-02-28 - В соседнем проекте почти доделано меню
  2013-03-01 - Спрайт игрока,
               Добавлены выпадающие патроны
               Добавлен прицел
               Добавил паузу по пробелу
  2013-03-03 - Здоровье и смерть ГГ, рестарт
               Прототип №5 готов
  2013-03-04 - Абстрактный аккумулятор готов.
               Аккумуляторы dropItems, bullets, enemies переведены на TpdAccum
               Исправлен баг #3
               Исправлен баг #4
               Добавлены всплывающие надписи: очки за убийство, патроны
               Теперь патроны медленно исчезают
  2013-03-05 - Добавлен бэкграунд
               Добавлена статистика - точность стрельбы
               Добавлены повороты врагов
               Простестировано выделение памяти - пока все окей, ничего не бежит
               Добавлены выпадающие аптечки
               ----
               Готов прототип №6
               Частично привязано меню
  2013-03-07 - Добавлены разные спрайты ГГ для разного оружия
               Изменена траектория выстрела, добавлены разные точки спавна
               пули в зависимости от оружия
               Исправлены баги 6,7,8.
               Баг #6 исправлен подбором минимальной Length между postion и mousePos
               Исправлен баг #9
  2013-03-15 - Спустя неделю вновь сел за прототип. Сделал плавный переход для
               главного меню
               Z_--- константы для Z-индексов разных спрайтов (игрок, враги, попапы)
               Добавил разные спрайты для врагов. Надо поиграть с размером
               Также, придется прикручивать физику, однозначно. Спрайты врагов
               "продолговатые", так что самопальные окружности не пойдут
  2013-03-16 - Решил баг #11
  2013-03-18 - Начал внедрять физику. Надо решить проблему с перемещением героя
               Вероятно, задавать постоянную скорость
  2013-03-21 - Игрок двигается, пули двигаются и рикошетят. Все в виде костылей
  2013-03-25 - #15 исправлен - wrap выставлен в clamp


}

program shmup;

uses
  Windows,
  SysUtils,
  dfHEngine in '..\..\common\dfHEngine.pas',
  ogl in '..\..\common\ogl.pas',
  glrMath in '..\..\common\glrMath.pas',
  glr in '..\..\headers\glr.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  uWeapons in 'uWeapons.pas',
  uGlobal in 'uGlobal.pas',
  uPlayer in 'uPlayer.pas',
  uEnemies in 'uEnemies.pas',
  uDrop in 'uDrop.pas',
  uAccum in 'uAccum.pas',
  uPopup in 'uPopup.pas',
  uButtonsInfo in 'gamescreens\uButtonsInfo.pas',
  uGameScreen.Authors in 'gamescreens\uGameScreen.Authors.pas',
  uGameScreen.MainMenu in 'gamescreens\uGameScreen.MainMenu.pas',
  uGameScreen.ArenaGame in 'gamescreens\uGameScreen.ArenaGame.pas',
  uGameScreen in 'gamescreens\uGameScreen.pas',
  uGameScreenManager in 'gamescreens\uGameScreenManager.pas',
  uBox2DImport in '..\..\headers\box2d\uBox2DImport.pas',
  UPhysics2D in '..\..\headers\box2d\UPhysics2D.pas',
  UPhysics2DTypes in '..\..\headers\box2d\UPhysics2DTypes.pas',
  uStaticObjects in 'uStaticObjects.pas',
  uGameScreen.PauseMenu in 'gamescreens\uGameScreen.PauseMenu.pas',
  uGameScreen.Settings in 'gamescreens\uGameScreen.Settings.pas';

const
  VERSION = '0.10';
  BACK_TEXTURE = RES_FOLDER + 'map.tga';

var
  gsManager: TpdGSManager;

  procedure OnUpdate(const dt: Double);
  begin
    if GSManager.IsQuitMessageReceived then
      R.Stop();
    gsManager.Update(dt);
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
  LoadRendererLib();
  R := glrCreateRenderer();
  R.Init('settings_shmup.txt');
  Factory := glrGetObjectFactory();

  gl.Init();
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('Shoot ''em up. Прототип. Версия '
    + VERSION + ' [glRenderer ' + R.VersionText + ']');

  mainMenu := TpdMainMenu.Create();
  arenaGame := TpdArenaGame.Create();
//  authors := TpdAuthors.Create();
  pauseMenu := TpdPauseMenu.Create();

  mainMenu.SetGameScreenLinks({authors} nil, arenaGame);
//  authors.SetGameScreenLinks(mainMenu, 'http://perfect-daemon.blogspot.ru/');
  arenaGame.SetGameScreenLinks(pauseMenu);
  pauseMenu.SetGameScreenLinks(mainMenu, arenaGame);

  gsManager := TpdGSManager.Create();
  gsManager.Add(mainMenu);
//  gsManager.Add(authors);
  gsManager.Add(arenaGame);
  gsManager.Add(pauseMenu);

//  gsManager.Notify(mainMenu, naSwitchTo);
  gsManager.Notify(arenaGame, naSwitchTo);

  R.Start();

  gsManager.Free();
  R.DeInit();
  UnLoadRendererLib();
end.

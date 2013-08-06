{
  Направление работ на следующий день:


BUGS:
 + BUG #1 - Постоянное перемещение игрока
 +-BUG #2 - Дерганье на vsync = true
 + BUG #3 - Возможно, двойное исполненеи Unload
 + BUG #4 - не обуляется текст cursorText при вызове меню паузы
 + BUG #5 - Нельзя сразу переключить на game, так как тогда вызывается SetStatus до Load() -> AV
            Надо разобраться с этим менеджером, уже затрахала эта тупая архитектура
 + BUG #6 - Многократный подъем ножа и прочего вызывает многократные фразы и подъем духа
 + BUG #7 - AV при дабл-клике на поднимаемом world-объекте
 + BUG #8 - Сырой шашлык из рыбы, что-то не так при применении
 + BUG #9 - При съедании рыбы ничего не происходит
 + BUG #10  AV при перетягивании пустого слота инвентаря
 + BUG #11  Если что-то бросить за костер, куст или траву - поднять уже не получится
 + BUG #12  Отключить музыку, зайти в игру, потом в меню - вкл музыку, музыки нет
 + BUG #13  Последний глоток во фляжке не такой :)

TODO:
  РЕФАКТОРИНГ:
    Унифицировать фразы, которые говорит игрок при крафте и подъеме одних и тех же предметов
    Использовать TpdWorldObject.GetObjectSprite для Initialize и иконок крафта
    Отдельный метод OnDrop у WorldObject для удобства
    Рерайт методов _AddNew[Object] у TpdGame.
    Рерайт RecalBB, чтобы не пересчитывать его при изменении позиции

  ОБЩЕЕ:
  + Твин убирания кнопки play у game
  + Затемнение экрана
    Регулятор громкости музыки
    Ввод имени игрока, отправка результатов на сервер
  + Комментарии, ибо явно заброшу на пару недель
  + Движение с зажатой левой кнопкой мыши
  + Поиск чего-нибудь в кустах
  + Индикация уменьшения запаса сил в воде
  +-Добавить советы:
      При первом подъеме фляжки - "Чтобы наполнить фляжку, перетяните ее в воду"
      При сооружении удочки - "С помощью удочки можно ловить рыбу. Для этого перетяните ее в воду, либо используйте (Правая кнопка мыши), находясь в воде"
      При создании костра - "На костер можно перетянуть сырые продукты", "У костра отдых идет быстрее"
      При входе в воду "Осторожно, если запас сил дойдет до нуля, то вы утонете"
      При переполнении инвентаря - легкое указание на рюкзак

  + Открывать панель крафта, когда появляется первая (или новая) для него возможность
  + Увеличить скорость набора запаса сил
  + Разобраться с ромашкой и заготовкой из чая. Заготовка из чая должна немного снижать действие сырой воды
  + Приподнять цветочек в меню паузы
  + Посмотреть что не так с кепкой ГГ с рюкзаком и без
  + Добавить при крафте увеличение силы духа
  + Не забыть включить музыку!
  +-BUGTEST - mainmenu - game - mainmenu - game
  + Добавить параметр: запас сил.
  + Когда персонаж не двигается - запас сил восстанавливается. Когда двигается - тратится
  + WorldObject.IsInside
  - Отсечение обработки (и рисования?) невидимых WorldObjects
  - Ограничить мир рамками - океаном
  + При + к параметру подсвечивать его рамку. Рамку сделать белой и через tcmModulate менять цвет
    Сгладить резкий переход в музыке
    Увеличить радиус клика на объектах (ветки)
  + Рисовать ягоды на кусту
  + Не двигать персонажа, если запас сил упал до 0
    (пасхалка)Сделать мышь, выбегающую из куста
  + Нарисовать кнопку retry для gameover?

  - GoAndDrop вместо простого drop

  + Подумать над тем, чтобы применять удочку и наполнять фляжку с помощью правой кнопки

  ВОДА:
  + Детектить воду
  + Загрузка воды из файла
  + Пить воду
  + В воде запас сил постоянно уменьшается.
  + Если он дойдет до 0 в воде - персонаж утонет
  + Перетягивание фляжки в воду
  + Перетягивание удочки в воду
  + Наличие рыбы в воде

  КРАФТ:
  + Панель крафта
  + Скрытие/показ панели крафта
  + Элементы на панели
  + При наведении - показывать ингридиенты и инструменты
  + Делать скрытие показ ингридиентов красиво
  + Гасить цвет крафт-итема, если сделать нельзя
  + Результат крафта - создание нового объекта, или изменение старого
  + Крафт на костре

  + Костер
  + Острая ветка
  + Удочка
  + Сырой шашлык из грибов
  + Фляга с ромашкой и водой
  + Сырой шашлык из рыбы


  ФОРМУЛЫ КРАФТА
    + означает смешение в крафтмастере
    -> означает перенос объекта в другой объект (вода, костер)
  + Леска + ветка + нож = удочка + нож
  + 2ветка + 2листва = костер
  + ветка -> костер = костер дольше горит
  + листва -> костер = костер дольше горит
  + Нож + ветка = острая ветка
  + 2Гриба + острая ветка = шашлык из грибов
  + Шашлык из грибов -> огонь = готовый шашлык из грибов
  + Фляга -> вода = фляга с водой
  + Фляга с водой -> костер = фляга с кипяченной водой
  + Фляга с водой + ромашка = фляга с ромашкой и водой
  + Фляга с ромашкой и водой -> костер = ромашковый чай
  + Рыба + острая ветка + нож = сырой шашлык из рыбы + нож
  + Сырой шашлык из рыбы -> костер = готовый шашлык из рыбы

  Объекты на крафт-панели:
  + Костер
  + Острая ветка
  + Удочка
  + Сырой шашлык из грибов
  + Фляга с ромашкой и водой
  + Сырой шашлык из рыбы

  МЕНЮ:

  + MainMenu - Fade in
  + MainMenu - Fade out
  + Game - Fade in
  + Game - Fade out
  + Меню паузы
  + Меню gameover
  + Escape из меню паузы - возврат в игру

  ИНВЕНТАРЬ:
  + Инвентарь - скрытие, показ
  + Инвентарь - сбор объектов
  + Инвентарь - выкидывание предмета
  + Инвентарь - применение предмета
  + Инвентарь - подсказка при наведении на объект
  + Инвентарь - появление дополнительных ячеек в случае подъема рюкзака
  + Инвентарь - если некуда класть, то показать инвентарь (если он не показан)

  ТЕЧЕНИЕ ВРЕМЕНИ:
  + Добавить время и его отображение
  + Перенести таймер в верх экрана и отцентрировать


  ГЛАВЫЙ ГЕРОЙ:
  + Изначально параметры не на максимуме
  ? Подсказка при наведении на параметры
  + Переделать инициализацию слотов (руки, нож...)
  + Рисование точки, куда идет игрок
  + При клике на объект - подойти, затем взять.
  - Расчет скорости игрока в зависимости от параметров - добавил запас сил
  + Смерть ГГ
  - В случае падения силы духа - неконтролируемое поведение
  + tween исчезновения и появления текста
  + Возможность показа нескольких текстов подряд
  + При падении различных характеристик выдавать различные фразы: "Черт, как же хочется пить" и прочее
  - popup при подъеме всякой всячины


  ОСТАЛЬНОЕ:
  + Режим редактора - перемещение объектов. Сохранение местоположения в файл
  + Останавливать обработку событий мыши, если наведено на игровой HUD
  - Синглтоны для некоторых предметов (рюкзак, нож, проволока, фляга)
  + fade in/out for about
  + Смена музыки при входе в игру
  + Правильное убывание полоски
  + Управление с мыши
  + Отображение надписи над объектом
  + Нож + к силе духа, добавить в инвентарь
  + Рюкзак - доп слоты и + к силе духа, поменять спрайт игрока, добавтиь надпись о доп слотах
  + Леска + к силе духа
  + Фляга + к силе духа
  + УБРАТЬ СЛОТЫ(?)



ПЛАНЫ НА БУДУЩЕЕ:
  Животные (опасные и трусливые). Бегать от первых и за вторыми, не наоборот
  Крафт оружия, ловушек
  Через N времени вырастают ягоды
  Через M времени появляется рыба в водоемах
  Вырастают зеленые кусты
  Зеленые становятся пожухлыми
  Ловля рыбы усложняется - необходимо копать червей, они используются на
    каждую ловлю. Ловля не всегда 100% успешная.
  Генерируемый на ходу мир
  Картинки-таблички в качестве туториала
  Синхронизация с сервером
  Деревья
  Миникарта
  Ограниченный чем-либо мир
  Физика
}

program survive;

{$R 'icon.res' 'icon.rc'}

uses
  glr in '..\..\headers\glr.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  dfHEngine in '..\..\common\dfHEngine.pas',
  ogl in '..\..\common\ogl.pas',
  glrMath in '..\..\common\glrMath.pas',
  dfTweener in '..\..\common\dfTweener.pas',
  uGlobal in 'uGlobal.pas',
  uGameScreen.Game in 'gamescreens\uGameScreen.Game.pas',
  uGameScreen.MainMenu in 'gamescreens\uGameScreen.MainMenu.pas',
  uGameScreen in 'gamescreens\uGameScreen.pas',
  uGameScreen.PauseMenu in 'gamescreens\uGameScreen.PauseMenu.pas',
  uGameScreenManager in 'gamescreens\uGameScreenManager.pas',
  Bass in '..\..\headers\Bass.pas',
  uSound in 'uSound.pas',
  uPlayer in 'uPlayer.pas',
  uWorldObjects in 'uWorldObjects.pas',
  uLevel_SaveLoad in 'uLevel_SaveLoad.pas',
  uInventory in 'uInventory.pas',
  uWater in 'uWater.pas',
  uGameScreen.GameOver in 'gamescreens\uGameScreen.GameOver.pas',
  uCraft in 'uCraft.pas',
  uAdvices in 'uAdvices.pas',
  uGameScreen.Advices in 'gamescreens\uGameScreen.Advices.pas';

const
  VERSION = '0.10a';

var
  gsManager: TpdGSManager;

  procedure OnUpdate(const dt: Double);
  begin
    if GSManager.IsQuitMessageReceived then
      R.Stop();
    gsManager.Update(dt);
    Tweener.Update(dt);
    UpdateCursor(dt);
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
  R := glrCreateRenderer();
  R.Init('settings_survive.txt');
  Factory := glrGetObjectFactory();

  gl.Init();
  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.OnMouseUp := OnMouseUp;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('Survive. Прототип. Версия '
    + VERSION + ' [glRenderer ' + R.VersionText + ']');

  gsManager := TpdGSManager.Create();
  LoadGlobalResources();

  mainMenu := TpdMainMenu.Create();
  game := TpdGame.Create();
  pauseMenu := TpdPauseMenu.Create();
  advices := TpdAdvicesMenu.Create();
  gameOver := TpdGameOver.Create();

  mainMenu.SetGameScreenLinks(game, advices);
  game.SetGameScreenLinks(pauseMenu, gameOver);
  pauseMenu.SetGameScreenLinks(mainMenu, game, advices);
  advices.SetGameScreenLinks(game);
  gameOver.SetGameScreenLinks(mainMenu, game);

  gsManager.Add(mainMenu);
  gsManager.Add(game);
  gsManager.Add(pauseMenu);
  gsManager.Add(advices);
  gsManager.Add(gameOver);
  {$IFDEF DEBUG}
  gsManager.Notify(game, naSwitchTo);
  sound.Enabled := False;
  {$ELSE}
  gsManager.Notify(mainMenu, naSwitchTo);
  {$ENDIF}

  R.Start();

  gsManager.Free();
  FreeGlobalResources();
  R.DeInit();
  UnLoadRendererLib();
end.

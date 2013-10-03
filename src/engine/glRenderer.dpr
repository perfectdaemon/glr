{
  TODO:
    Переписать GUI с учетом того, что Renderable - наследник Node
    Доступ к логгеру для приложений
    Поддержка align у текста
 +  Поддержка pivot point у текста
    Поддержка width у текста - перенос по буквам/словам
 +  Z-index и его влияение для 2d-объектов
 +  Замутить дополнительные свйоства для TdfVec-параметров:
      DiffuseP - pointer. Чтобы можно было Diffuse.X менять

 -  Проверить SetParent у Node и 2DRenderable
 -  RenderChilds у 2DRenderable пока не используется
 +  Рерайт CheckHit в HudSprite
    Рерайт системы Scene - Renderable в целом. Уход от Scene в пользу пустых Renderable
    RootNode перенести из Iglr3DScene -> IglrBaseScene. Iglr2DScene также будет
      использовать RootNode

 ПОСЛЕ РЕРАЙТА Renderable-Node ПРОВЕРИТЬ КЛАССЫ:
  GUI
  Camera
  Font
  HudSprite
  Light
  Node
  Renderable
  Text
  UserRenderable


  LD - Last Developed - Над чем работал в последний раз в этот день


  2013-09-18 - LD - Renderable - наследник Node. Рерайт жуткий
  2013-08-05 - -- - Ответвление 0.3.0. Рефакторинг всего и вся, причесывание
  2013-07-31 - LD - Начат рефакторинг имен (df -> glr)
  2013-07-30 - LD - Добавлен glrObjectFactory
  2013-07-14 - LD - GUITextButton добавлен
  2013-05-14 - LD - GUITextBox.KeyDown - добавлено игнорирование Return
  2013-05-08 - LD - Кривые костыли: 2DRenderable.ParentScene. Кривой пересчет X, Y у GUIManager
  2013-05-04 - LD - GUISlider, 1st version
  2013-05-03 - LD - _Focus, _Unfocus, OnFocused у GUIElement, _Focus у GUITextBox
  2013-05-03 - LD - CursorOffset у GUITextBox
  2013-05-03 - LD - Парсинг ttf/otf неудачный. Теперь имя шрифта указывается при
                    генерации, либо при пустом значении вычисляется из имени файла
  2013-05-01 - LD - Исправлена ошибка добавления шрифта.
                    Раньше имя шрифта вычислялось по имени файла, теперь оно
                    читается из ttf/otf файла
  2013-04-30 - LD - Поддержка pivot point у текста
  2013-04-28 - LD - Начал делать IdfGUITextBox. См GUIManager.KeyDown.
  2013-04-27 - LD - Добавил в лог GL_VENDOR, GL_RENDERER, GL_VERSION, GL_GLSL
  2013-04-23 - LD - Добавил IdfGUIElement.Reset - сбрасывает внутреннее состояние
                    override у потомков для установки normal-текстуры
  2013-04-19 - LD - Изменил стиль создаваемого окна - нет min/max. non sizing border
  2013-04-16 - LD - Приступил к изменнеию рендера 2D
                    Переношу функционал Node внутрь 2DRenderable.
  2013-04-14 - LD - Добавлен параметр cursor true/false
  2013-04-13 - LD - PRotation, PDiffuse - build 36
  2013-04-12 - LD - Сделал атрибут PPosition - отдает PdfVec2f - build 35
  2013-04-06 - LD - Сделал чекбокс (пока без подписи к нему)
  2013-03-25 - LD - Поправил фильтрацию для текстур, загруженных через Load2D(File)
  2013-03-24 - LD - Доделал FSAA через временный контекст и мультисэмплинг
  2013-03-24 - LD - Начал делать поддержку multisamle для сглаживания
                    через wglChoosePixelFormat. Для этого надо делать временный
                    контекст. См TdfRenderer.OpenGLInitTemporaryContext
                    Не доделано!
  2013-03-03 - LD - Поддержка переносов у текста с помощью #10
                    Scene.UnregisterElements - удаляет все элементы
                    Поддержка Scale у текста
  2013-02-23 - LD - Load2DRegion - проверил на Checker5_GUI - работает.
                    Пофиксил баг с двойным переключением текстуры у текста.
                    Пофиксил текстурные координаты для спрайтов, которые юзают
                    region. Пока надо принудительно вызывать UpdateTexCoords()
                    после загрузки Load2DRegion.
                    Добавил TextureSwitches у Renderer - количество переключений
                    текстур за кадр
  2013-02-17 - LD - Texture.Load2DRegion - загрузка части уже существующей
                    текстуры. Проообраз атласа.
  2012-09-08 - LD - Checker 7 - ragdoll masters, uCharacter - need joints
  2012-08-25 - LD - Idf2DScene. Надо что0то думать
  2012-08-23 - LD - GUIManager.MouseDown, Up, Over, Out
                    GUIElement - CheckHit
  2012-08-23 - LD - GUIElement, GUIManager. Начал думать над Idf2DSceneManager
                    TdfGUIButton._MouseDown
  2012-07-02 - LD - Спрайт выводится нормально, использует свои параметры.
                    Работает pivot point
  2012-07-01 - LD - Вывод спрайта с использованием матрицы Node. Херня какая-то
  2012-04-15 - LD - Баг с вьюпортом и выводом спрайта поборот:
                    AdjustWindowRect должен затрагивать только создание окна
                    В остальном - использовать первоначальные данные
  2012-02-27 - LD - Баг с вьюпортом и вывод спрайта
  2012-02-?? - LD - TdfTexture, TdfMaterial, TdfSprite. Начал делать рендер спрайта

  BUGS:
+  1. TdfNode пустой - не обрабатывает left, up и dir
+  2. TdfNode - Добавить CreateAsChild и сопутствующий функционал
+     Вероятно, проще заглянуть в соответсствующий юнит DiF Engine
+  3. TdfNode - поправить функционал в целом. Слишком много багов
+  4. TInterfaceList странно зануляет ссылки в конце. Переделал под TList, но
      надо разобраться
   5. TdfLight - наследник TdfNode, неверно. Лучше сделать его как TdfRenderable
      Но как тогда быть с перехватом SetPos?
+  6. Баг с размером вьюпорта. Смотреть Camera.Init и Renderer.Init()



  2011-10-11: TODO:
    1. Миграция на интерфейсы уже существующих базовых классов:
+     1. Camera - Базово сделано
+     2. Light - Базово сделано, но заточено под один источник света
      3. Shaders
+     4. Textures
    2. Создание новых классов и интерфейсов графического движка:
+     1. Node - Базово сделано
      2. Scene
      3. VBOBuffer
      4. Mesh
+     5. Sprite
+     6. Material
      7. Actor
    3. Создание вспомогательных классов и интерфейсов:
      1. Resource
      2. ResourceManager

    4. Сборка воедино, проверка работоспособности

    5. Привязка звуков, физики и прочих свистелок


  2011-04-09//
              Новое ответвление - передел под COM-стандарт: интерфейсы и классы
}
library glRenderer;

{$R *.res}

uses
  ShareMem,
  uRenderer in 'uRenderer.pas',
  uCamera in 'uCamera.pas',
  uLight in 'uLight.pas',
  uHudSprite in 'uHudSprite.pas',
  uTexture in 'uTexture.pas',
  uShader in 'uShader.pas',
  uLogger in 'uLogger.pas',
  glr in '..\headers\glr.pas',
  uNode in 'uNode.pas',
  ExportFunc in 'ExportFunc.pas',
  TexLoad in 'TexLoad.pas',
  uRenderable in 'uRenderable.pas',
  uMaterial in 'uMaterial.pas',
  uFont in 'uFont.pas',
  uText in 'uText.pas',
  uWindow in 'uWindow.pas',
  uPrimitives in 'uPrimitives.pas',
  uUserRenderable in 'uUserRenderable.pas',
  uGUIElement in 'GUI\uGUIElement.pas',
  uGUIButton in 'GUI\uGUIButton.pas',
  uInput in 'uInput.pas',
  uGUIManager in 'GUI\uGUIManager.pas',
  uScene in 'uScene.pas',
  uGUICheckbox in 'GUI\uGUICheckbox.pas',
  uGUITextBox in 'GUI\uGUITextBox.pas',
  uGUISlider in 'GUI\uGUISlider.pas',
  uGUITextButton in 'GUI\uGUITextButton.pas',
  uFactory in 'uFactory.pas',
  dfLogger in 'dfLogger.pas',
  glrMath in '..\headers\glrMath.pas',
  ogl in '..\headers\ogl.pas',
  uBaseInterfaceObject in 'uBaseInterfaceObject.pas';

exports
  GetRenderer, GetObjectFactory;
begin
end.

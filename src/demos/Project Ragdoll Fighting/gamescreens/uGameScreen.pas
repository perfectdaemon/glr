{Концепция GameScreen - некоторый интерактивный экран, являющийся активным у юзверя.
 Говоря проще, это базовый класс для главного меню, самой игры и различных ее режимов
 Данные сущности (меню, сама игра) реализуются в потомках класса}
unit uGameScreen;

interface

uses
  glr;

type
  TpdGameScreen = class;

  //Действия, которые экран может отсылать классу TdfGame
  //Нет действия, переключиться, переключиться без показа FadeIn и FadeOut,
  //Показать поверх, предзагрузка, выйти из игры
  TpdNotifyAction = (naNone, naSwitchTo, naSwitchToQ, naShowModal, naPreload, naQuitGame);

  //Процедура уведомления. Уведомляем о том, что хотим сделать
  // с экраном Subject действие Action.
  TpdNotifyProc = procedure(ToScreen: TpdGameScreen; Action: TpdNotifyAction) of object;

  //Статус текущего экрана
  //gssNone - нет статуса. не update-ится и не показывается
  //gssReady - активный на данный момент, Update выполняется, реакция на действия
  //gssFadeIn - идет процесс показа (появления)
  //gssFadeInComplete - процесс появления завершен, автоматически переключается в gssReady
  //gssFadeOut - идет процесс скрывания с экрана
  //gssFadeOutComplete - процесс скрытия завершен, автоматически переключается в gssNone
  //gssPaused - пауза, экран продолжает отрисовываться, но не Update-ится
  TpdGameScreenStatus = (gssNone, gssReady, gssFadeIn, gssFadeInComplete,
                         gssFadeOut, gssFadeOutComplete, gssPaused);

  {О правилах загрузки:
   Create - содержит данные, которые загрязсят один раз и будут висеть в памяти
            на протяжении всей игры

   Load   - Непосредственная подгрузка при активации данного экрана


   Рекомендуется: Создавать все объекты в Create, но не помещать их в
   рендер-узел сразу, а делать это при Load. Также при Load
   следует подгружать игровые данные}

  {
    Следует перегрузить все абстрактные методы.
    А также:
      SetStatus - для реагирования на смену статуса.
      FadeIn, FadeOut, причем inheritd вызывать в конце, когда они закончатся

      Подробнее см. код
  }
  TpdGameScreen = class
  private
  protected
    FLoaded: Boolean;
    FName: String;
    FStatus: TpdGameScreenStatus;
    FNotifyProc: TpdNotifyProc;

    procedure FadeIn(deltaTime: Double); virtual;
    procedure FadeOut(deltaTime: Double); virtual;
    procedure SetName(const Value: String); virtual;

    function GetStatus: TpdGameScreenStatus; virtual;
    procedure SetStatus(const aStatus: TpdGameScreenStatus); virtual;
    function GetLoaded: Boolean; virtual;
  public
    constructor Create(); virtual; abstract;
    destructor Destroy; override; abstract;

    procedure Load(); virtual; abstract;
    procedure Unload(); virtual; abstract;

    procedure Update(deltaTime: Double); virtual; abstract;

    property OnNotify: TpdNotifyProc read FNotifyProc write FNotifyProc;
    property Status: TpdGameScreenStatus read GetStatus write SetStatus;
    property IsLoaded: Boolean read GetLoaded;
    property Name: String read FName write SetName;

    procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState); virtual;
    procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
      Shift: TglrMouseShiftState); virtual;
    procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
      Shift: TglrMouseShiftState); virtual;
  end;

  {
    Абстрактный GameScreen (GS) менеджер.
    Для конкретной игры следует определить метод Notify и переопределить Update()
  }

  TpdAbstractGSManager = class
  protected
    FGameScreens: array of TpdGameScreen;
    FFreeObjects: Boolean;
    FNextIndex: Integer;
    FQuit: Boolean;
  public
    constructor Create(aFreeScreensAtDestroy: Boolean = True); virtual;
    destructor Destroy(); override;

    procedure Add(aScreen: TpdGameScreen); virtual;
    //Удаляет из списка, но не удаляет из памяти
    procedure Remove(aScreen: TpdGameScreen); overload; virtual;
    procedure Remove(aScreenIndex: Integer); overload; virtual;
    //Удаляет из списка И ИЗ ПАМЯТИ
    procedure Delete(aScreen: TpdGameScreen); virtual;

    procedure Update(const dt: Double); virtual;

    //Сюда приходят действия по переключению
    procedure Notify(ToScreen: TpdGameScreen; Action: TpdNotifyAction); virtual; abstract;

    property IsQuitMessageReceived: Boolean read FQuit;
  end;

  //TpdGameSceneClass = class of TpdGameScreen;

implementation

{ TpdGameScreen }

procedure TpdGameScreen.FadeIn(deltaTime: Double);
begin
  Status := gssFadeInComplete;
end;

procedure TpdGameScreen.FadeOut(deltaTime: Double);
begin
  Status := gssFadeOutComplete;
end;

function TpdGameScreen.GetLoaded: Boolean;
begin
  Result := FLoaded;
end;

function TpdGameScreen.GetStatus: TpdGameScreenStatus;
begin
  Result := FStatus;
end;

procedure TpdGameScreen.OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin

end;

procedure TpdGameScreen.OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin

end;

procedure TpdGameScreen.OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin

end;

procedure TpdGameScreen.SetName(const Value: String);
begin
  FName := Value;
end;

procedure TpdGameScreen.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  FStatus := aStatus;
end;

{ TpdAbstractGSManager }

procedure TpdAbstractGSManager.Add(aScreen: TpdGameScreen);
begin
  if FNextIndex = Length(FGameScreens) then
    SetLength(FGameScreens, FNextIndex + FNextIndex div 4);
  FGameScreens[FNextIndex] := aScreen;
  Inc(FNextIndex);
end;

constructor TpdAbstractGSManager.Create(aFreeScreensAtDestroy: Boolean);
begin
  inherited Create;
  FFreeObjects := aFreeScreensAtDestroy;
  SetLength(FGameScreens, 16);
  FNextIndex := 0;
  FQuit := False;
end;

procedure TpdAbstractGSManager.Delete(aScreen: TpdGameScreen);
var
  i: Integer;
begin
  for i := 0 to High(FGameScreens) do
    if aScreen = FGameScreens[i] then
      try
        FGameScreens[i].Free;
        FGameScreens[i] := nil;
        aScreen := nil;
      finally
      end;
end;

destructor TpdAbstractGSManager.Destroy;
var
  i: Integer;
begin
  if FFreeObjects then
    for i := 0 to High(FGameScreens) do
      try
        FGameScreens[i].Free;
      finally
      end;
  SetLength(FGameScreens, 0);
  inherited;
end;

procedure TpdAbstractGSManager.Remove(aScreenIndex: Integer);
begin
  if aScreenIndex < Length(FGameScreens) then
    FGameScreens[aScreenIndex] := nil;
end;

procedure TpdAbstractGSManager.Remove(aScreen: TpdGameScreen);
var
  i: Integer;
begin
  for i := 0 to High(FGameScreens) do
    if aScreen = FGameScreens[i] then
      FGameScreens[i] := nil;
end;

procedure TpdAbstractGSManager.Update(const dt: Double);
var
  i: Integer;
begin
  for i := 0 to High(FGameScreens) do
    if Assigned(FGameScreens[i]) then
      FGameScreens[i].Update(dt);
end;

end.

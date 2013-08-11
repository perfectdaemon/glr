unit uGUIManager;

interface

uses
  Classes,
  glr, uBaseInterfaceObject;

type
  TglrGUIManager = class(TglrInterfacedObject, IglrGUIManager)
  private
    FElements: TInterfaceList;
    FFocused: IglrGUIElement;

    function GetFocused(): IglrGUIElement;
    procedure SetFocused(aElement: IglrGUIElement);

    function GetElementIndexAtPos(X, Y: Integer): Integer;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    //Зарегистрировать/разрегистрировать элемент
    procedure RegisterElement(aElement: IglrGUIElement);
    procedure UnregisterElement(aElement: IglrGUIElement);

    //Элемент, находящийся в фокусе
    property Focused: IglrGUIElement read GetFocused write SetFocused;

    //для внутреннего использования IdfRenderer-ом.
    procedure MouseMove (X, Y: Integer; Shift: TglrMouseShiftState);
    procedure MouseDown (X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState);
    procedure MouseUp   (X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState);
    procedure MouseWheel(X, Y: Integer; Shift: TglrMouseShiftState; WheelDelta: Integer);
    procedure KeyDown   (KeyCode: Word; KeyData: Integer);
  end;

implementation

{ TdfGUIManager }

constructor TglrGUIManager.Create;
begin
  inherited;
  FElements := TInterfaceList.Create();
  FFocused := nil;
end;

destructor TglrGUIManager.Destroy;
begin
  FFocused := nil;
  FElements.Free;
  inherited;
end;

function TglrGUIManager.GetElementIndexAtPos(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FElements.Count - 1 do //для каждого элемента
    with IglrGUIElement(FElements[i]) do
      if CheckHit(X - Trunc(ParentScene.Origin.x), Y - Trunc(ParentScene.Origin.y)) then //если есть попадание
        if Result <> -1 then // если до этого уже есть кандидат
        begin
          if Z < IglrGUIElement(FElements[Result]).Z then
            Result := i
        end
        else
          Result := i;
end;

function TglrGUIManager.GetFocused: IglrGUIElement;
begin
  Result := FFocused;
end;

procedure TglrGUIManager.KeyDown(KeyCode: Word; KeyData: Integer);
begin
  if Assigned(FFocused) then
    FFocused._KeyDown(KeyCode, KeyData);
end;

procedure TglrGUIManager.MouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
var
  ind: Integer;
begin
  ind := GetElementIndexAtPos(X, Y);
  if ind <> -1 then
  begin
    Focused := IglrGUIElement(FElements[ind]);
    FFocused._MouseDown(X - Trunc(FFocused.ParentScene.Origin.x),
      Y - Trunc(FFocused.ParentScene.Origin.y), MouseButton, Shift);
  end
  else
    Focused := nil;
end;

procedure TglrGUIManager.MouseMove(X, Y: Integer; Shift: TglrMouseShiftState);

  //Находим все элементы, у которых стоит флаг о том, что мышь над ними
  //Все кроме ExceptIndex потеряли мышь, exceptIndex - тшт элемент, который
  //ее получил
  procedure SetMouseOut(exceptIndex: Integer);
  var
    i: Integer;
  begin
    for i := 0 to FElements.Count - 1 do
      with IglrGUIElement(FElements[i]) do
        if (MousePos = mpOver) and (i <> exceptIndex) then
          _MouseOut(X - Trunc(ParentScene.Origin.x), Y - Trunc(ParentScene.Origin.y), Shift);
  end;

var
  ind: Integer;
begin
  ind := GetElementIndexAtPos(X, Y);
  SetMouseOut(ind);

  //Если мышь не отжата, то передем фокусному элементу сообщение
  if ((ssLeft in Shift) or (ssRight in Shift) or (ssMiddle in Shift) )
    and Assigned(FFocused) then
    FFocused._MouseMove(X - Trunc(FFocused.ParentScene.Origin.x), Y - Trunc(FFocused.ParentScene.Origin.y), Shift);

  if ind <> -1 then
    with IglrGUIElement(FElements[ind]) do
      //Если мыши ранее не было на элементе, то инициируем omMouseOver
      if MousePos = mpOut then
        _MouseOver(X - Trunc(ParentScene.Origin.x), Y - Trunc(ParentScene.Origin.y), Shift)
      //Иначе - просто движение мыши по элементу
      else
        _MouseMove(X - Trunc(ParentScene.Origin.x), Y - Trunc(ParentScene.Origin.y), Shift);
end;

procedure TglrGUIManager.MouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
var
  ind: Integer;
begin
  ind := GetElementIndexAtPos(X, Y);

  if Assigned(FFocused) and ( (ind = -1) or (FElements[ind] <> FFocused) ) then
    with FFocused do
      _MouseUp(X - Trunc(ParentScene.Origin.x), Y - Trunc(ParentScene.Origin.y), MouseButton, Shift);

  if ind <> -1 then
  begin
    with IglrGUIElement(FElements[ind]) do
      if MousePos  = mpOver then
      begin
        _MouseClick(X - Trunc(ParentScene.Origin.x), Y - Trunc(ParentScene.Origin.y), MouseButton, Shift);
        _MouseUp(X - Trunc(ParentScene.Origin.x), Y - Trunc(ParentScene.Origin.y), MouseButton, Shift);
      end
      else
        _MouseUp(X - Trunc(ParentScene.Origin.x), Y - Trunc(ParentScene.Origin.y), MouseButton, Shift);
  end;
end;

procedure TglrGUIManager.MouseWheel(X, Y: Integer; Shift: TglrMouseShiftState;
  WheelDelta: Integer);
//var
//  ind: Integer;
begin
//  ind := GetElementIndexAtPos(X, Y);
//  if (ind <> -1) then
//    IdfGUIElement(FElements[ind])._MouseWheel(X, Y, Shift, WheelDelta);
end;

procedure TglrGUIManager.RegisterElement(aElement: IglrGUIElement);
begin
  FElements.Add(aElement);
  aElement.Reset();
//  aElement._MouseOut(0, 0, []); //Убираем возможное состояние наведенности мыши
end;

procedure TglrGUIManager.SetFocused(aElement: IglrGUIElement);
begin
  if Assigned(FFocused) then
    FFocused._Unfocused();
  if Assigned(aElement) then
    aElement._Focused();

  FFocused := aElement;
end;

procedure TglrGUIManager.UnregisterElement(aElement: IglrGUIElement);
begin
  if aElement = FFocused then
    FFocused := nil;
  FElements.Remove(aElement);
end;

end.

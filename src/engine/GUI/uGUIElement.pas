{
  TODO: CheckHit для повернутого изображения
  TODO: CheckHit для альфа-изображений
}

unit uGUIElement;

interface

uses
  uRenderable,
  //debug
  uHudSprite,
  glr;

type
  TglrGUIElement = class(TglrHUDSprite, IglrGUIElement)
  private
  protected
    //Относительная позиция мыши по отношению к элементу
    FMousePos: TglrMousePos;
    FHitMode: TglrGUIHitMode;
    FOnClick, FOnOver, FOnOut, FOnDown, FOnUp: TglrMouseEvent;
    FOnWheel: TglrWheelEvent;
    FOnFocus: TglrFocusEvent;
    FEnabled: Boolean;

    procedure CalcHitZone(); virtual;

    function GetEnabled(): Boolean; virtual;
    procedure SetEnabled(const aEnabled: Boolean); virtual;

    function GetHitMode(): TglrGUIHitMode; virtual;
    procedure SetHitMode(aMode: TglrGUIHitMode); virtual;

    function GetOnClick(): TglrMouseEvent; virtual;
    function GetOnOver(): TglrMouseEvent; virtual;
    function GetOnOut(): TglrMouseEvent; virtual;
    function GetOnDown(): TglrMouseEvent; virtual;
    function GetOnUp(): TglrMouseEvent; virtual;
    function GetOnWheel(): TglrWheelEvent; virtual;
    function GetOnFocus(): TglrFocusEvent; virtual;

    procedure SetOnClick(aProc: TglrMouseEvent); virtual;
    procedure SetOnOver(aProc: TglrMouseEvent); virtual;
    procedure SetOnOut(aProc: TglrMouseEvent); virtual;
    procedure SetOnDown(aProc: TglrMouseEvent); virtual;
    procedure SetOnUp(aProc: TglrMouseEvent); virtual;
    procedure SetOnWheel(aProc: TglrWheelEvent); virtual;
    procedure SetOnFocus(aProc: TglrFocusEvent); virtual;

    function GetMousePos(): TglrMousePos;

    //Для внутреннего использования. Либо для принудительного вызова события
    procedure _MouseMove (X, Y: Integer; Shift: TglrMouseShiftState); virtual;
    procedure _MouseOver (X, Y: Integer; Shift: TglrMouseShiftState); virtual;
    procedure _MouseOut (X, Y: Integer; Shift: TglrMouseShiftState); virtual;
    procedure _MouseDown (X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); virtual;
    procedure _MouseUp   (X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); virtual;
    procedure _MouseWheel(X, Y: Integer; Shift: TglrMouseShiftState; WheelDelta: Integer); virtual;
    procedure _MouseClick(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); virtual;
    procedure _Focused(); virtual;
    procedure _Unfocused(); virtual;
    procedure _KeyDown(KeyCode: Word; KeyData: Integer); virtual;
  public

    property Enabled: Boolean read GetEnabled write SetEnabled;

    //Режим проверки попадания по элементу.
    property HitMode: TglrGUIHitMode read GetHitMode write SetHitMode;
    //Проверка на попадание по элементу
    function CheckHit(X, Y: Integer): Boolean; virtual;
    //Коллбэки для пользователя
    property OnMouseClick: TglrMouseEvent read GetOnClick write SetOnClick;
    property OnMouseOver: TglrMouseEvent read GetOnOver write SetOnOver;
    property OnMouseOut: TglrMouseEvent read GetOnOut write SetOnOut;
    property OnMouseDown: TglrMouseEvent read GetOnDown write SetOnDown;
    property OnMouseUp: TglrMouseEvent read GetOnUp write SetOnUp;
    property OnMouseWheel: TglrWheelEvent read GetOnWheel write SetOnWheel;

    property MousePos: TglrMousePos read GetMousePos;

    procedure Reset(); virtual;

    constructor Create(); override;
  end;


implementation

uses
  glrMath;

procedure TglrGUIElement.CalcHitZone();
begin
//  if Assigned(FTexNormal) then
//  begin
//
//  end;
end;

function TglrGUIElement.CheckHit(X, Y: Integer): Boolean;

  //Предпроверка для всех типов по баундинг боксу
  //для hmBox при нулевом уле поворота соответствует полной
  //проверке
  function CheckBB(X, Y: Single): Boolean;
  begin
    with GetBB do
      Result := ( (X > Left) and (X < Right)  )
             and( (Y > Top)  and (Y < Bottom) );
  end;

  function CheckWithAlpha(): Boolean;
  begin
    Result := True;
  end;

var
  absPos: TdfVec2f;

begin
  // + debug
//  absPos := dfVec2f(X, Y) - FParentScene.Origin;
//  Exit(CheckBB(absPos.x, absPos.y));
  Exit(CheckBB(X, Y));
  // - debug
//  case HitMode of
//    hmBox:
//      if Abs(FRot) < cEPS then
//        Result := CheckBB(X, Y);
//    hmAlpha0: ;
//    hmAlpha50: ;
//  end;
end;

constructor TglrGUIElement.Create;
begin
  inherited Create;
  FEnabled := True;
  FHitMode := hmBox;
end;

function TglrGUIElement.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TglrGUIElement.GetHitMode: TglrGUIHitMode;
begin
  Result := FHitMode;
end;

function TglrGUIElement.GetMousePos: TglrMousePos;
begin
  Result := FMousePos;
end;

function TglrGUIElement.GetOnClick: TglrMouseEvent;
begin
  Result := FOnClick;
end;

function TglrGUIElement.GetOnDown: TglrMouseEvent;
begin
  Result := FOnDown;
end;

function TglrGUIElement.GetOnFocus: TglrFocusEvent;
begin
  Result := FOnFocus;
end;

function TglrGUIElement.GetOnOut: TglrMouseEvent;
begin
  Result := FOnOut;
end;

function TglrGUIElement.GetOnOver: TglrMouseEvent;
begin
  Result := FOnOver;
end;

function TglrGUIElement.GetOnUp: TglrMouseEvent;
begin
  Result := FOnUp;
end;

function TglrGUIElement.GetOnWheel: TglrWheelEvent;
begin
  Result := FOnWheel;
end;

procedure TglrGUIElement.Reset;
begin
  FMousePos := mpOut;
end;

procedure TglrGUIElement.SetEnabled(const aEnabled: Boolean);
begin
  FEnabled := aEnabled;
end;

procedure TglrGUIElement.SetHitMode(aMode: TglrGUIHitMode);
begin
  FHitMode := aMode;
  if FHitMode in [hmAlpha0, hmAlpha50] then
    CalcHitZone();
end;

procedure TglrGUIElement.SetOnClick(aProc: TglrMouseEvent);
begin
  FOnClick := aProc;
end;

procedure TglrGUIElement.SetOnDown(aProc: TglrMouseEvent);
begin
  FOnDown := aProc;
end;

procedure TglrGUIElement.SetOnFocus(aProc: TglrFocusEvent);
begin
  FOnFocus := aProc;
end;

procedure TglrGUIElement.SetOnOut(aProc: TglrMouseEvent);
begin
  FOnOut := aProc;
end;

procedure TglrGUIElement.SetOnOver(aProc: TglrMouseEvent);
begin
  FOnOver := aProc;
end;

procedure TglrGUIElement.SetOnUp(aProc: TglrMouseEvent);
begin
  FOnUp := aProc;
end;

procedure TglrGUIElement.SetOnWheel(aProc: TglrWheelEvent);
begin
  FOnWheel := aProc;
end;

procedure TglrGUIElement._Focused;
begin
  if Assigned(FOnFocus) then
    FOnFocus(Self, True);
end;

procedure TglrGUIElement._KeyDown(KeyCode: Word; KeyData: Integer);
begin

end;

procedure TglrGUIElement._MouseClick(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if Assigned(FOnClick) and FEnabled then
    FOnClick(Self, X, Y, MouseButton, Shift);
end;

procedure TglrGUIElement._MouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if Assigned(FOnDown) and FEnabled then
    FOnDown(Self, X, Y, MouseButton, Shift);
end;

procedure TglrGUIElement._MouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  if (FMousePos = mpOver) and (not CheckHit(X, Y)) and FEnabled then
    FMousePos := mpOut;
end;

procedure TglrGUIElement._MouseOut(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  FMousePos := mpOut;
  if Assigned(FOnOut) and FEnabled then
    FOnOut(Self, X, Y, mbNone, Shift);
end;

procedure TglrGUIElement._MouseOver(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  FMousePos := mpOver;
  if Assigned(FOnOver) and FEnabled then
    FOnOver(Self, X, Y, mbNone, Shift);
end;

procedure TglrGUIElement._MouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if Assigned(FOnUp) and FEnabled then
    FOnUp(Self, X, Y, MouseButton, Shift);
end;

procedure TglrGUIElement._MouseWheel(X, Y: Integer; Shift: TglrMouseShiftState;
  WheelDelta: Integer);
begin
  if Assigned(FOnWheel) and FEnabled then
    FOnWheel(Self, X, Y, Shift, WheelDelta);
end;

procedure TglrGUIElement._Unfocused;
begin
  if Assigned(FOnFocus) then
    FOnFocus(Self, False);
end;

end.

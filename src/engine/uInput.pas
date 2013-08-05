unit uInput;

interface

uses
  Windows,
  dfHRenderer;

type
  TglrInput = class(TInterfacedObject, IglrInput)
  protected
    FAllow: Boolean;
    vLastWheelDelta : Integer;
    FKeysPressed: array[$01..$FE] of Boolean;
    function GetAllow(): Boolean;
    procedure SetAllow(aAllow: Boolean);
  public
    constructor Create(); virtual;

    function IsKeyDown(const vk: Integer): Boolean; overload;
    function IsKeyDown(const c: WideChar): Boolean; overload;

    function IsKeyPressed(aCode: Integer; aPressed: PBoolean): Boolean; overload;  deprecated;
    function IsKeyPressed(aChar: WideChar; aPressed: PBoolean): Boolean; overload; deprecated;
    function IsKeyPressed(aCode: Integer): Boolean; overload;
    function IsKeyPressed(aChar: WideChar): Boolean; overload;

    procedure KeyboardNotifyWheelMoved(wheelDelta : Integer);
    //–азрешить захват клавиш.
    //јвтоматически мен€етс€ в зависимости от того, активно окно или нет
    property AllowKeyCapture: Boolean read GetAllow write SetAllow;
  end;

implementation

function TglrInput.IsKeyDown(const vk: Integer): Boolean;
begin
  if not FAllow then
    Exit(False);

   case vk of
      VK_MOUSEWHEELUP :
      begin
        Result := (vLastWheelDelta > 0);
        if Result then
          vLastWheelDelta := 0;
      end;
      VK_MOUSEWHEELDOWN :
      begin
        Result := (vLastWheelDelta < 0);
        if Result then
          vLastWheelDelta := 0;
      end;
   else
      Result := (GetAsyncKeyState(vk) < 0);
   end;
end;

constructor TglrInput.Create;
var
  i: Integer;
begin
  inherited;
  FAllow := True;
  for i := Low(FKeysPressed) to High(FKeysPressed) do
    FKeysPressed[i] := False;
end;

function TglrInput.GetAllow: Boolean;
begin
  Result := FAllow;
end;

function TglrInput.IsKeyDown(const c: WideChar): Boolean;
var
   vk: Integer;
begin
  if not FAllow then
    Exit(False);

   vk := VkKeyScan(c) and $FF;
   if vk <> $FF then
     Result := (GetAsyncKeyState(vk) < 0)
   else
     Result := False;
end;

procedure TglrInput.KeyboardNotifyWheelMoved(wheelDelta : Integer);
begin
   vLastWheelDelta := wheelDelta;
end;

procedure TglrInput.SetAllow(aAllow: Boolean);
begin
  FAllow := aAllow;
end;

function TglrInput.IsKeyPressed(aCode: Integer; aPressed: PBoolean): Boolean;
begin
  if not FAllow then
    Exit(False);

  Result := False;

  if (not aPressed^) and (GetAsyncKeyState(aCode) < 0) then
  begin
    Result := True;
    aPressed^ := True;
  end;

  if (GetAsyncKeyState(aCode) >= 0) then
    aPressed^ := False;
end;


function TglrInput.IsKeyPressed(aChar: WideChar; aPressed: PBoolean): Boolean;
var
  aCode: Integer;
begin
  if not FAllow then
    Exit(False);

  Result := False;

  aCode := VkKeyScan(aChar) and $FF;
  if aCode <> $FF then
  begin
    if (not aPressed^) and (GetAsyncKeyState(aCode) < 0) then
    begin
      Result := True;
      aPressed^ := True;
    end;

    if (GetAsyncKeyState(aCode) >= 0) then
      aPressed^ := False;
  end
  else
    Result := False;
end;

function TglrInput.IsKeyPressed(aCode: Integer): Boolean;
begin
  if not FAllow then
    Exit(False);

  Result := False;

  if (not FKeysPressed[aCode]) and (GetAsyncKeyState(aCode) < 0) then
  begin
    Result := True;
    FKeysPressed[aCode] := True;
  end;

  if (GetAsyncKeyState(aCode) >= 0) then
    FKeysPressed[aCode] := False;
end;

function TglrInput.IsKeyPressed(aChar: WideChar): Boolean;
begin
  Result := IsKeyPressed(Ord(aChar));
end;

end.

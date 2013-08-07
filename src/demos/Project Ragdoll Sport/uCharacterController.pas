unit uCharacterController;

interface

uses
  glr, glrMath,
  uCharacter;

const
  PLAYER_CONTROL_FORCE = 20;
  PLAYER_CONTROL_MOUSE_THRESHOLD = 30;

type
  TglrControllerKeys = record
    kLeft, kRight, kUp, kDown: Integer;
    class function Init(aLeft, aRight, aUp, aDown: Integer): TglrControllerKeys; static;
  end;

  TpdPlayerCharacterController = class
  protected
    FCharacter: TpdCharacter;
    FInput: IglrInput;
    FDir: TdfVec2f;
    FDirLength, FForce: Single;
  public
    Keys: TglrControllerKeys;
    class function Init(aInput: IglrInput; aCharacter: TpdCharacter;
      aKeys: TglrControllerKeys): TpdPlayerCharacterController;

    procedure Control(const dt: Double);
    procedure ControlMouse(const dt: Double);

    destructor Destroy(); override;
  end;

implementation

uses
  uGlobal,
  UPhysics2DTypes;

{ TglrControllerKeys }

class function TglrControllerKeys.Init(aLeft, aRight, aUp,
  aDown: Integer): TglrControllerKeys;
begin
  with Result do
  begin
    kLeft := aLeft;
    kRight := aRight;
    kUp := aUp;
    kDown := aDown;
  end;
end;

{ TglPlayerCharacterController }

procedure TpdPlayerCharacterController.Control(const dt: Double);
begin
  inherited;
  if FInput.IsKeyDown(Keys.kLeft) then
    FCharacter.ApplyControlImpulse(TVector2.From(-PLAYER_CONTROL_FORCE, 0));
  if FInput.IsKeyDown(Keys.kRight) then
    FCharacter.ApplyControlImpulse(TVector2.From( PLAYER_CONTROL_FORCE, 0));
  if FInput.IsKeyDown(Keys.kUp) then
    FCharacter.ApplyControlImpulse(TVector2.From(0, -PLAYER_CONTROL_FORCE));
  if FInput.IsKeyDown(Keys.kDown) then
    FCharacter.ApplyControlImpulse(TVector2.From(0,  PLAYER_CONTROL_FORCE));
end;

procedure TpdPlayerCharacterController.ControlMouse(const dt: Double);
begin
  FDir := mousePos - FCharacter.GetHeadPosition;
  FDirLength := FDir.Length;
  if FDirLength > PLAYER_CONTROL_MOUSE_THRESHOLD then
  begin
    FDir.Normalize;
    FForce := Clamp(FDirLength / 5, 0, PLAYER_CONTROL_FORCE);
    FDir := FDir * FForce;
    FCharacter.ApplyControlImpulse(TVector2.From(FDir.x, FDir.y));
  end;
end;

destructor TpdPlayerCharacterController.Destroy;
begin
  FCharacter.OnControl := nil;
  FInput := nil;
  inherited;
end;

class function TpdPlayerCharacterController.Init(aInput: IglrInput;
  aCharacter: TpdCharacter;
  aKeys: TglrControllerKeys): TpdPlayerCharacterController;
begin
  Result := TpdPlayerCharacterController.Create();
  with Result do
  begin
    Keys := aKeys;
    FCharacter := aCharacter;
    FInput := aInput;
    if uGlobal.mouseControl then
      FCharacter.OnControl := ControlMouse
    else
      FCharacter.OnControl := Control;
  end;
end;

end.

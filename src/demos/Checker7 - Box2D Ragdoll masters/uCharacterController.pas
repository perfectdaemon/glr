unit uCharacterController;

interface

uses
  dfHRenderer,
  uCharacterBoxes;

type
  TglrCharacterController = class
  protected
    FCharacter: TglrBoxCharacter;
  public
    procedure Control(const dt: Double); virtual; abstract;
  end;

  TglrControllerKeys = record
    kLeft, kRight, kUp, kDown: Integer;
    class function Init(aLeft, aRight, aUp, aDown: Integer): TglrControllerKeys; static;
  end;

  TglrPlayerCharacterController = class(TglrCharacterController)
  protected
    FInput: IglrInput;
  public
    Keys: TglrControllerKeys;
    class function Init(aInput: IglrInput; aCharacter: TglrBoxCharacter;
      aKeys: TglrControllerKeys): TglrPlayerCharacterController;

    procedure Control(const dt: Double); override;

    destructor Destroy(); override;
  end;

const
  AI_MIN_LEVEL = 0;
  AI_MAX_LEVEL = 5;

type
  TglrAICharacterController = class(TglrCharacterController)
  protected
    FAILevel: Integer;
  public
    class function Init(aCharacter: TglrBoxCharacter; AILevel: Integer): TglrAICharacterController;
    procedure Control(const dt: Double); override;

    destructor Destroy(); override;
  end;

implementation

uses
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

procedure TglrPlayerCharacterController.Control(const dt: Double);
const
  cForce = 20;
begin
  inherited;
  if FInput.IsKeyDown(Keys.kLeft) then
    FCharacter.ApplyControlImpulse(TVector2.From(-cForce, 0));
  if FInput.IsKeyDown(Keys.kRight) then
    FCharacter.ApplyControlImpulse(TVector2.From( cForce, 0));
  if FInput.IsKeyDown(Keys.kUp) then
    FCharacter.ApplyControlImpulse(TVector2.From(0, -cForce));
  if FInput.IsKeyDown(Keys.kDown) then
    FCharacter.ApplyControlImpulse(TVector2.From(0,  cForce));
end;

destructor TglrPlayerCharacterController.Destroy;
begin
  FCharacter.OnControl := nil;
  inherited;
end;

class function TglrPlayerCharacterController.Init(aInput: IglrInput;
  aCharacter: TglrBoxCharacter;
  aKeys: TglrControllerKeys): TglrPlayerCharacterController;
begin
  Result := TglrPlayerCharacterController.Create();
  with Result do
  begin
    Keys := aKeys;
    FCharacter := aCharacter;
    FInput := aInput;
    FCharacter.OnControl := Control;
  end;
end;

{ TglrAICharacterController }

procedure TglrAICharacterController.Control(const dt: Double);
begin

end;

destructor TglrAICharacterController.Destroy;
begin
  FCharacter.OnControl := nil;
  inherited;
end;

class function TglrAICharacterController.Init(aCharacter: TglrBoxCharacter;
  AILevel: Integer): TglrAICharacterController;
begin
  Result := TglrAICharacterController.Create();
  with Result do
  begin
    FCharacter := aCharacter;
    FCharacter.OnControl := Control;
    if AILevel < AI_MIN_LEVEL then
      FAILevel := AI_MIN_LEVEL
    else if AILevel > AI_MAX_LEVEL then
      FAILevel := AI_MAX_LEVEL
    else
      FAILevel := AILevel;

  end;

end;

end.

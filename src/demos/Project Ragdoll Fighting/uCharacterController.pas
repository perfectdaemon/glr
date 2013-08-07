unit uCharacterController;

interface

uses
  glr, glrMath,
  uCharacter;

const
  PLAYER_CONTROL_FORCE = 20;

  AI_CONTROL_STEP_TIME_BASE = 0.3;
  AI_CONTROL_DISTANCE_TO_ROTATE = 210;

type
  TglrControllerKeys = record
    kLeft, kRight, kUp, kDown: Integer;
    class function Init(aLeft, aRight, aUp, aDown: Integer): TglrControllerKeys; static;
  end;

  TpdCharacterController = class
  protected
    FCharacter: TpdCharacter;
  public
    procedure Control(const dt: Double); virtual; abstract;
  end;

  TpdPlayerCharacterController = class (TpdCharacterController)
  protected
    FInput: IglrInput;
    FDir: TdfVec2f;
    FDirLength, FForce: Single;
  public
    Keys: TglrControllerKeys;
    class function Init(aInput: IglrInput; aCharacter: TpdCharacter;
      aKeys: TglrControllerKeys): TpdPlayerCharacterController;

    procedure Control(const dt: Double); override;

    destructor Destroy(); override;
  end;

  TpdAICharacterContoller = class (TpdCharacterController)
  protected
    FDifficulty: Integer;

    rotate: Boolean; //Нужно ли вращаться
    rotationAngle, tmpAngle: Single;

    dir: TdfVec2f; //Вектор направления к игроку
    dist: Single; //Дистанция до игрока

    timeToThink: Single;

    procedure MakeRotation180(const dt: Single);
    procedure OnRotateDone();
  public
    class function Init(aCharacter: TpdCharacter;
      aDifficulty: Integer): TpdAICharacterContoller;
    procedure Control(const dt: Double); override;
  end;

implementation

uses
  dfTweener,
  uGlobal,
  uBox2DImport,
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
    FCharacter.OnControl := Control;
  end;
end;

{ TpdAICharacterContoller }

procedure TpdAICharacterContoller.Control(const dt: Double);
begin
  if not player.IsDead then
  begin
    if timeToThink > 0 then //если еще не настало время подумать
      timeToThink := timeToThink - dt
    else
    begin
      dir := player.GetBodyCenterPosition - Self.FCharacter.GetHeadPosition;
      dist := dir.Length;
      dir := dir * (1 / dist); //normalize dir vector

      if (dist < AI_CONTROL_DISTANCE_TO_ROTATE) and not rotate then
      begin
        rotate := true;
        rotationAngle := dir.GetRotationAngle();
        if Random() > 0.5 then
          tmpAngle := 180
        else
          tmpAngle := -180;
        with Tweener.AddTweenPSingle(@rotationAngle, tsSimple, rotationAngle, rotationAngle + tmpAngle, 0.8) do
          OnDone := Self.OnRotateDone;
      end;
      //Подумать в следующий раз через timeToThink секунд
      timeToThink := AI_CONTROL_STEP_TIME_BASE / (FDifficulty + 1);
    end;
  end;
  if rotate then
    dir := dfVec2f(cos(-rotationAngle * deg2rad), sin(rotationAngle * deg2rad));
  FCharacter.ApplyControlImpulse(ConvertGLToB2(dir * PLAYER_CONTROL_FORCE));
end;

class function TpdAICharacterContoller.Init(aCharacter: TpdCharacter;
  aDifficulty: Integer): TpdAICharacterContoller;
begin
  Result := TpdAICharacterContoller.Create();
  with Result do
  begin
    FCharacter := aCharacter;
    FCharacter.OnControl := Control;
    FDifficulty := aDifficulty;
  end;
end;

procedure TpdAICharacterContoller.MakeRotation180(const dt: Single);
begin

end;

procedure TpdAICharacterContoller.OnRotateDone;
begin
  rotate := false;
end;

end.

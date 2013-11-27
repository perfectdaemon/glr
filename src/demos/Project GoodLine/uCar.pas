unit uCar;

interface

uses
  glr, glrMath,
  uCarSaveLoad,
  uPhysics2D;

const
  INITIAL_X = 100;
  INITIAL_Y = 300;

  MIN_MOTOR_SPEED = 2;

  //Значение при котором можно переключиться с первой на заднюю и наоборот
  CHANGE_GEAR_MOTORFORCE_THRESHOLD = 1;

type
  TpdMoveDirection = (mNoMove, mLeft, mRight);

  TpdCar = class
  private
    procedure InitSprites(const aCarInfo: TpdCarInfo);
    procedure InitBodies(const aCarInfo: TpdCarInfo);
    procedure InitJoints(const aCarInfo: TpdCarInfo);

    procedure AutomaticTransmissionUpdate(const dt: Double);
    procedure DefineCarDynamicParams(const dt: Double);
    procedure AddAccel(const dt: Double); //Добовление ускорения на колеса
    procedure ReduceAccel(const dt: Double); //Снижение скорости колес
    procedure Brake(UseBrake: Boolean); //Торможение
    procedure CalcMotorSpeed(const dt: Double); //использует обратную связь от колес
  public
    RearLight, BrakeLight: IglrSprite;

    WheelRear, WheelFront, Body, SuspRear, SuspFront: IglrSprite;
    b2WheelRear, b2WheelFront, b2Body, b2SuspRear, b2SuspFront: Tb2Body;
    b2WheelJointRear, b2WheelJointFront: Tb2RevoluteJoint;
    b2SuspJointRear, b2SuspJointFront: Tb2PrismaticJoint;

    CurrentMotorSpeed, MaxMotorSpeed, Acceleration: Single;
    Gear: Integer;
    Gears: array of Single;

    MoveDirection: TpdMoveDirection;
    BodySpeed, WheelSpeed: Single;

    constructor Create(const aCarInfo: TpdCarInfo);
    destructor Destroy(); override;

    procedure Update(const dt: Double);
  end;

implementation

uses
  Windows,
  uGlobal, uBox2DImport, uPhysics2DTypes;

{ TpdCar }

procedure TpdCar.AddAccel(const dt: Double);
begin
  CurrentMotorSpeed := Clamp(CurrentMotorSpeed + dt * Acceleration, 0, MaxMotorSpeed);
end;

procedure TpdCar.AutomaticTransmissionUpdate(const dt: Double);
begin
  if Abs(CurrentMotorSpeed - MaxMotorSpeed) <= cEPS then
  begin
    if (Gear <> 0) and (Gear < High(Gears)) then
    begin
      Inc(Gear); //Повышаем передачу
      CurrentMotorSpeed := CurrentMotorSpeed * (Gears[Gear - 1] / Gears[Gear]) * 0.7;
    end;
  end
  else if CurrentMotorSpeed < MIN_MOTOR_SPEED then
  begin
    if Gear > 1 then
    begin
      Dec(Gear);
      CurrentMotorSpeed := CurrentMotorSpeed * (Gears[Gear + 1] / Gears[Gear]);
    end;
  end;
end;

procedure TpdCar.Brake(UseBrake: Boolean);
begin
  b2WheelJointFront.SetMotorSpeed(0);
  b2WheelJointFront.EnableMotor(UseBrake);
  BrakeLight.Visible := UseBrake;
end;

procedure TpdCar.CalcMotorSpeed(const dt: Double);
begin
  if CurrentMotorSpeed > Abs(WheelSpeed / Gears[Gear]) then
    CurrentMotorSpeed := Lerp(CurrentMotorSpeed, Abs(WheelSpeed / Gears[Gear]), 0.3 * 1 / Abs(Gears[Gear]));
end;

constructor TpdCar.Create(const aCarInfo: TpdCarInfo);
var
  i: Integer;
begin
  inherited Create();
  InitSprites(aCarInfo);
  InitBodies(aCarInfo);
  InitJoints(aCarInfo);

  MaxMotorSpeed := aCarInfo.MaxMotorSpeed;
  Acceleration := aCarInfo.Acceleration;
  Gear := 1;
  SetLength(Gears, aCarInfo.GearCount);
  for i := 0 to aCarInfo.GearCount - 1 do
    Gears[i] := aCarInfo.Gears[i];
end;

procedure TpdCar.DefineCarDynamicParams(const dt: Double);

const
  SPEED_THRESHOLD = 2.0;// / C_COEF;

begin
  WheelSpeed := b2WheelRear.GetAngularVelocity;// / C_COEF;

  BodySpeed := b2Body.GetLinearVelocity.x;// / C_COEF;
  if BodySpeed > SPEED_THRESHOLD then
    MoveDirection := mRight
  else if BodySpeed < -SPEED_THRESHOLD then
    MoveDirection := mLeft
  else
    MoveDirection := mNoMove;
end;

destructor TpdCar.Destroy;
begin
  mainScene.RootNode.RemoveChild(Body);
  mainScene.RootNode.RemoveChild(WheelRear);
  mainScene.RootNode.RemoveChild(WheelFront);
  mainScene.RootNode.RemoveChild(SuspRear);
  mainScene.RootNode.RemoveChild(SuspFront);
  inherited;
end;

procedure TpdCar.InitBodies(const aCarInfo: TpdCarInfo);
var
  mask: Word;

  procedure SetUserData(forBody: Tb2Body);
  var
    ud: PpdUserData;
  begin
    New(ud);
    ud^.aType := oPlayer;
    ud^.aObject := Self;
    forBody.UserData := ud;
  end;

begin
  mask := CAT_STATIC or CAT_BONUS or CAT_ENEMY or CAT_SENSOR;
  with aCarInfo do
  begin
    b2Body := dfb2InitBox(b2world, Body, BodyD, BodyF, BodyR, mask, CAT_PLAYER, -2);
    b2WheelRear := dfb2InitCircle(b2world, WheelRear, WheelRearD, WheelRearF, WheelRearR, mask, CAT_PLAYER, -2);
    b2WheelFront := dfb2InitCircle(b2world, WheelFront, WheelFrontD, WheelFrontF, WheelFrontR, mask, CAT_PLAYER, -2);
    b2SuspRear := dfb2InitBox(b2world, SuspRear, 2.0, 0, 0, mask, CAT_PLAYER, -2);
    b2SuspFront := dfb2InitBox(b2world, SuspFront, 2.0, 0, 0, mask, CAT_PLAYER, -2);

    SetUserData(b2Body);
    SetUserData(b2WheelRear);
    SetUserData(b2WheelFront);
    SetUserData(b2SuspRear);
    SetUserData(b2SuspFront);

    b2WheelRear.AngularDamping := 0.2;
    b2WheelFront.AngularDamping := 0.2;
  end;
end;

procedure TpdCar.InitJoints(const aCarInfo: TpdCarInfo);
var
  suspAxis: TVector2;
  PriDef: Tb2PrismaticJointDef;
  RevDef: Tb2RevoluteJointDef;
begin
  suspAxis := ConvertGLToB2((aCarInfo.WheelRearOffset - aCarInfo.SuspRearOffset).Normal);
  PriDef := Tb2PrismaticJointDef.Create;
  PriDef.Initialize(b2Body, b2SuspRear, b2SuspRear.GetPosition, suspAxis);
  PriDef.enableLimit := True;
  PriDef.enableMotor := True;
  b2SuspJointRear := Tb2PrismaticJoint(b2World.CreateJoint(PriDef));
  with b2SuspJointRear, aCarInfo do
  begin
    SetLimits(SuspRearLimit.x * C_COEF, SuspRearLimit.y * C_COEF);
    SetMotorSpeed(SuspRearMotorSpeed);
    SetMaxMotorForce(SuspRearMaxMotorForce);
  end;

  suspAxis := ConvertGLToB2((aCarInfo.WheelFrontOfsset - aCarInfo.SuspFrontOffset).Normal);
  PriDef := Tb2PrismaticJointDef.Create;
  PriDef.Initialize(b2Body, b2SuspFront, b2SuspFront.GetPosition, suspAxis);
  PriDef.enableLimit := True;
  PriDef.enableMotor := True;
  b2SuspJointFront := Tb2PrismaticJoint(b2World.CreateJoint(PriDef));
  with b2SuspJointFront, aCarInfo do
  begin
    SetLimits(SuspFrontLimit.x * C_COEF, SuspFrontLimit.y * C_COEF);
    SetMotorSpeed(SuspFrontMotorSpeed);
    SetMaxMotorForce(SuspFrontMaxMotorForce);
  end;

  RevDef := Tb2RevoluteJointDef.Create;
  RevDef.enableMotor := True;
  RevDef.Initialize(b2WheelRear, b2SuspRear, b2WheelRear.GetPosition);
  b2WheelJointRear := Tb2RevoluteJoint(b2World.CreateJoint(RevDef));
  b2WheelJointRear.SetMaxMotorTorque(100);

  RevDef := Tb2RevoluteJointDef.Create;
  RevDef.enableMotor := False;
  RevDef.Initialize(b2WheelFront, b2SuspFront, b2WheelFront.GetPosition);
  b2WheelJointFront := Tb2RevoluteJoint(b2World.CreateJoint(RevDef));
  b2WheelJointFront.SetMaxMotorTorque(100);
end;

procedure TpdCar.InitSprites(const aCarInfo: TpdCarInfo);
begin
  Body := Factory.NewSprite();
  with Body do
  begin
    Material.Texture := atlasMain.LoadTexture(BLOCK_TEXTURE);
    SetSizeToTextureSize();
    Material.Diffuse := colorOrange;

    UpdateTexCoords();
    PivotPoint := ppCenter;
    Position := dfVec3f(INITIAL_X, INITIAL_Y, Z_PLAYER);
  end;
  mainScene.RootNode.AddChild(Body);

  SuspRear := Factory.NewSprite();
  with SuspRear do
  begin
    Width := 5;
    Height := 20;
    Material.Diffuse := colorRed;
    PivotPoint := ppCenter;
    Position := Body.Position + dfVec3f(aCarInfo.SuspRearOffset, 1);
    Rotation := (aCarInfo.WheelRearOffset - aCarInfo.SuspRearOffset).Normal.GetRotationAngle();
  end;
  mainScene.RootNode.AddChild(SuspRear);

  SuspFront := Factory.NewSprite();
  with SuspFront do
  begin
    Width := 5;
    Height := 20;
    Material.Diffuse := colorRed;
    PivotPoint := ppCenter;
    Position := Body.Position + dfVec3f(aCarInfo.SuspFrontOffset, 1);
    Rotation := (aCarInfo.WheelFrontOfsset - aCarInfo.SuspFrontOffset).Normal.GetRotationAngle();
  end;
  mainScene.RootNode.AddChild(SuspFront);

  WheelRear := Factory.NewSprite();
  with WheelRear do
  begin
    Material.Texture := atlasMain.LoadTexture(CIRCLE_TEXTURE);
    Material.Diffuse := colorOrange;
    //SetSizeToTextureSize();
    Width := aCarInfo.WheelRearSize;
    Height := aCarInfo.WheelRearSize;
    UpdateTexCoords();
    PivotPoint := ppCenter;
    Position := Body.Position + dfVec3f(aCarInfo.WheelRearOffset, 2);
  end;
  mainScene.RootNode.AddChild(WheelRear);

  WheelFront := Factory.NewSprite();
  with WheelFront do
  begin
    Material.Texture := atlasMain.LoadTexture(CIRCLE_TEXTURE);
    Material.Diffuse := colorOrange;
    //SetSizeToTextureSize();
    Width := aCarInfo.WheelFrontSize;
    Height := aCarInfo.WheelFrontSize;
    UpdateTexCoords();
    PivotPoint := ppCenter;
    Position := Body.Position + dfVec3f(aCarInfo.WheelFrontOfsset, 2);
  end;
  mainScene.RootNode.AddChild(WheelFront);

  RearLight := Factory.NewSprite();
  with RearLight do
  begin
    PivotPoint := ppCenter;
    Material.Diffuse := colorWhite;
    Width := 15;
    Height := Width;
    Position := dfVec3f(-Body.Width / 2, +10, Body.Position.z + 3);
    Visible := False;
  end;
  Body.AddChild(RearLight);

  BrakeLight := Factory.NewSprite();
  with BrakeLight do
  begin
    PivotPoint := ppCenter;
    Material.Diffuse := colorRed;
    Width := 15;
    Height := Width;
    Position := dfVec3f(-Body.Width / 2, -10, Body.Position.z + 3);
    Visible := False;
  end;
  Body.AddChild(BrakeLight);
end;


procedure TpdCar.ReduceAccel(const dt: Double);
begin
  CurrentMotorSpeed := Clamp(CurrentMotorSpeed - dt * Acceleration, 0, MaxMotorSpeed);
end;

procedure TpdCar.Update(const dt: Double);
begin
  Brake(False);

  if R.Input.IsKeyDown(VK_UP) then
  begin
    b2WheelJointRear.EnableMotor(True);
    //Если включена задняя передача
    if Gear = 0 then
    begin
      if Abs(BodySpeed) < CHANGE_GEAR_MOTORFORCE_THRESHOLD then
      begin
        //Можно переключаться на первую
        RearLight.Visible := False;
        Gear := 1;
        CurrentMotorSpeed := 0;
      end
      else
      begin
        //Просот снижаем скорость
        ReduceAccel(2 * dt);
        Brake(True);
      end;
    end
    else
    begin
      AddAccel(dt);
    end;
  end

  else if R.Input.IsKeyDown(VK_DOWN) then
  begin
    b2WheelJointRear.EnableMotor(True);
    if Gear > 0 then
    begin
      if BodySpeed < CHANGE_GEAR_MOTORFORCE_THRESHOLD then
      begin
        //Можно переключаться на заднюю
        Gear := 0;
        CurrentMotorSpeed := 0;
        RearLight.Visible := True;
      end
      else
      begin
        //Прост снижаем скорость
        ReduceAccel(2 * dt);
        Brake(True);
      end;

    end
    else
    begin
      AddAccel(dt);
    end;
  end

  //не нажато ни вперед, ни назад
  else
  begin
    b2WheelJointRear.EnableMotor(False);
    ReduceAccel(0.5 * dt);
    CalcMotorSpeed(dt);
    //b2WheelJointRear.EnableMotor(True);
    //b2WheelJointRear.SetMaxMotorTorque(100);
  end;

  if b2WheelJointRear.IsMotorEnabled then
    b2WheelJointRear.SetMotorSpeed(-CurrentMotorSpeed * Gears[Gear]);

  if R.Input.IsKeyDown(VK_SPACE) then
  begin
    b2WheelJointRear.EnableMotor(True);
    b2WheelJointRear.SetMotorSpeed(0);
  end;

  AutomaticTransmissionUpdate(dt);
  DefineCarDynamicParams(dt);

  SyncObjects(b2Body, Body);
  SyncObjects(b2SuspRear, SuspRear);
  SyncObjects(b2SuspFront, SuspFront);
  SyncObjects(b2WheelRear, WheelRear);
  SyncObjects(b2WheelFront, WheelFront);
end;

end.

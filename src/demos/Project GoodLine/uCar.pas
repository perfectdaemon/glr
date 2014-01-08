unit uCar;

interface

uses
  glr, glrMath,
  uCarSaveLoad, uTrigger,
  uPhysics2D, uPhysics2DTypes;

const
  INITIAL_X = 100;
  INITIAL_Y = 300;

  MIN_MOTOR_SPEED = 10;

  //Значение при котором можно переключиться с первой на заднюю и наоборот
  CHANGE_GEAR_MOTORFORCE_THRESHOLD = 1;

type
  TpdMoveDirection = (mNoMove, mLeft, mRight);

  TpdCar = class
  private
    WheelTriggerOffset: TdfVec2f;
    WheelTrigger: TpdTrigger;
    procedure InitSprites(const aCarInfo: TpdCarInfo);
    procedure InitBodies(const aCarInfo: TpdCarInfo);
    procedure InitJoints(const aCarInfo: TpdCarInfo);

    procedure InitShovel();

    procedure GearUp();
    procedure GearDown();
    procedure AutomaticTransmissionUpdate(const dt: Double);
    procedure DefineCarDynamicParams(const dt: Double);
    procedure AddAccel(const dt: Double); //Добовление ускорения на колеса
    procedure ReduceAccel(const dt: Double); //Снижение скорости колес
    procedure Brake(UseBrake: Boolean); //Торможение
    procedure CalcMotorSpeed(const dt: Double); //использует обратную связь от колес
    procedure AddDownForce(const dt: Double);
    procedure OnWheelTriggerEnter(Trigger: TpdTrigger; Catched: Tb2Fixture);
    procedure OnWheelTriggerLeave(Trigger: TpdTrigger; Catched: Tb2Fixture);
  public
    WheelPoints: Integer;

    RearLight, BrakeLight: IglrSprite;

    WheelRear, WheelFront, Body, SuspRear, SuspFront: IglrSprite;
    b2WheelRear, b2WheelFront, b2Body, b2SuspRear, b2SuspFront: Tb2Body;
    b2WheelJointRear, b2WheelJointFront: Tb2RevoluteJoint;
    b2SuspJointRear, b2SuspJointFront: Tb2PrismaticJoint;

    b2Shovel: Tb2Body;
    b2ShovelJoint: Tb2PrismaticJoint;
    Shovel: IglrSprite;

    CurrentMotorSpeed, MaxMotorSpeed, Acceleration: Single;
    Gear: Integer;
    Gears: array of Single;

    MoveDirection: TpdMoveDirection;
    BodySpeed, WheelSpeed: Single;

    AutomaticTransmission: Boolean;

    constructor Create(const aCarInfo: TpdCarInfo);
    destructor Destroy(); override;

    procedure Update(const dt: Double);
  end;

implementation

uses
  Windows,
  uGlobal, uBox2DImport;

{ TpdCar }

procedure TpdCar.AddAccel(const dt: Double);
begin
  CurrentMotorSpeed := Clamp(CurrentMotorSpeed + dt * Acceleration, 0, MaxMotorSpeed);
end;

procedure TpdCar.AddDownForce(const dt: Double);
begin
  b2Body.ApplyLinearImpulse(TVector2.From(0, 2.0 * Abs(BodySpeed) * dt), b2Body.GetWorldCenter);
end;

procedure TpdCar.AutomaticTransmissionUpdate(const dt: Double);
begin
  if Abs(CurrentMotorSpeed - MaxMotorSpeed) <= cEPS then
    GearUp()
  else if CurrentMotorSpeed < MIN_MOTOR_SPEED then
    GearDown();
end;

procedure TpdCar.Brake(UseBrake: Boolean);
begin
  b2WheelJointFront.SetMotorSpeed(0);
  b2WheelJointFront.EnableMotor(UseBrake);
  b2WheelJointFront.SetMaxMotorTorque(8);
  BrakeLight.Visible := UseBrake;
end;

procedure TpdCar.CalcMotorSpeed(const dt: Double);
begin
//  if CurrentMotorSpeed > Abs(WheelSpeed / Gears[Gear]) then
  CurrentMotorSpeed := Lerp(CurrentMotorSpeed, Abs(WheelSpeed / Gears[Gear]), 1 / Abs(Gears[Gear]));
end;

constructor TpdCar.Create(const aCarInfo: TpdCarInfo);
var
  i: Integer;
begin
  inherited Create();
  InitSprites(aCarInfo);
  InitBodies(aCarInfo);
  InitJoints(aCarInfo);
  InitShovel();

  MaxMotorSpeed := aCarInfo.MaxMotorSpeed;
  Acceleration := aCarInfo.Acceleration;
  Gear := 1;
  SetLength(Gears, aCarInfo.GearCount);
  for i := 0 to aCarInfo.GearCount - 1 do
    Gears[i] := aCarInfo.Gears[i];

  AutomaticTransmission := True;

  with aCarInfo do
    WheelTriggerOffset := (WheelFrontOfsset + WheelRearOffset) * 0.5 + dfVec2f(0, 20);
  WheelTrigger := triggers.AddBoxTrigger(dfVec2f(INITIAL_X, INITIAL_Y) + WheelTriggerOffset, 50, 40, CAT_STATIC, False);
  WheelTrigger.Visible := False;
  WheelTrigger.OnEnter := OnWheelTriggerEnter;
  WheelTrigger.OnLeave := OnWheelTriggerLeave;
  WheelTriggerOffset := WheelTriggerOffset * C_COEF;
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
  mainScene.RootNode.RemoveChild(Shovel);
  WheelTrigger.Free();

  b2world.DestroyJoint(b2WheelJointRear);
  b2world.DestroyJoint(b2WheelJointFront);
  b2world.DestroyJoint(b2SuspJointRear);
  b2world.DestroyJoint(b2SuspJointFront);
  b2world.DestroyJoint(b2ShovelJoint);

  b2world.DestroyBody(b2WheelRear);
  b2world.DestroyBody(b2WheelFront);
  b2world.DestroyBody(b2Body);
  b2world.DestroyBody(b2SuspRear);
  b2world.DestroyBody(b2SuspFront);
  b2world.DestroyBody(b2Shovel);
  inherited;
end;

procedure TpdCar.GearDown;
begin
  if Gear > 1 then
  begin
    Dec(Gear);
    CurrentMotorSpeed := CurrentMotorSpeed * (Gears[Gear + 1] / Gears[Gear]);
  end;
end;

procedure TpdCar.GearUp;
begin
  if (Gear <> 0) and (Gear < High(Gears)) then
  begin
    Inc(Gear); //Повышаем передачу
    CurrentMotorSpeed := CurrentMotorSpeed * (Gears[Gear - 1] / Gears[Gear]) * 0.7;
  end;
end;

procedure TpdCar.InitBodies(const aCarInfo: TpdCarInfo);

  procedure SetUserData(forBody: Tb2Body);
  var
    ud: PpdUserData;
  begin
    New(ud);
    ud^.aType := oPlayer;
    ud^.aObject := Self;
    forBody.UserData := ud;
  end;

var
  mass: Tb2MassData;

begin
  with aCarInfo do
  begin
    b2Body := dfb2InitBox(b2world, Body, BodyD, BodyF, BodyR, MASK_PLAYER, CAT_PLAYER, -2);
    b2WheelRear := dfb2InitCircle(b2world, WheelRear, WheelRearD, WheelRearF, WheelRearR, MASK_PLAYER_WHEELS, CAT_WHEELS, -2);
    b2WheelFront := dfb2InitCircle(b2world, WheelFront, WheelFrontD, WheelFrontF, WheelFrontR, MASK_PLAYER_WHEELS, CAT_WHEELS, -2);
    b2SuspRear := dfb2InitBox(b2world, SuspRear, 2.0, 0, 0, MASK_PLAYER_WHEELS, CAT_WHEELS, -2);
    b2SuspFront := dfb2InitBox(b2world, SuspFront, 2.0, 0, 0, MASK_PLAYER_WHEELS, CAT_WHEELS, -2);

    b2Body.GetMassData(mass);
    mass.center := ConvertGLToB2(BodyMassCenterOffset * C_COEF);
    b2Body.SetMassData(mass);

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
  b2WheelJointRear.SetMaxMotorTorque(10);

  RevDef := Tb2RevoluteJointDef.Create;
  RevDef.enableMotor := False;
  RevDef.Initialize(b2WheelFront, b2SuspFront, b2WheelFront.GetPosition);
  b2WheelJointFront := Tb2RevoluteJoint(b2World.CreateJoint(RevDef));
  b2WheelJointFront.SetMaxMotorTorque(10);
end;

function b2ShovelCreate(aSprite: IglrSprite; d, f, r: Double; mask, category: UInt16): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2PolygonShape;
  FixtureDef: Tb2FixtureDef;
  vertices: TVectorArray;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2PolygonShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_dynamicBody;
    position := ConvertGLToB2(aSprite.Position2D * C_COEF);
  end;

  SetLength(vertices, 8);
  with aSprite do
  begin
    vertices[0] := TVector2.From(-0.5 * Width, -0.5  * Height) * C_COEF;
    vertices[1] := TVector2.From(-0.5 * Width,  0.5  * Height) * C_COEF;
    vertices[2] := TVector2.From( 0.5 * Width,  0.5  * Height) * C_COEF;
    vertices[3] := TVector2.From( 0.5 * Width,  0.45 * Height) * C_COEF;
    vertices[4] := TVector2.From(-0.2 * Width,  0.1  * Height) * C_COEF;
    vertices[5] := TVector2.From(-0.4 * Width, -  1  * Height) * C_COEF;
    vertices[6] := TVector2.From(-0.2 * Width, -1.5  * Height) * C_COEF;
    vertices[7] := vertices[0];
  end;
  with ShapeDef do
  begin
    SetVertices(@vertices[0], 8);
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
//    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(False);
end;

procedure TpdCar.InitShovel;
var
  def: Tb2PrismaticJointDef;
begin
  Shovel := Factory.NewSprite();
  with Shovel do
  begin
    Material.Texture := atlasMain.LoadTexture(SHOVEL_TEXTURE);
    Material.Diffuse := Body.Material.Diffuse;
    SetSizeToTextureSize;
    UpdateTexCoords();
    PivotPoint := ppCenter;
    Position := Body.Position + dfVec3f(77, 15, 0);
  end;
  mainScene.RootNode.AddChild(Shovel);

  b2Shovel := b2ShovelCreate(Shovel, 0.1, 0.0, 0.2, MASK_PLAYER, CAT_PLAYER);

  def := Tb2PrismaticJointDef.Create;
  def.Initialize(b2Body, b2Shovel, b2Shovel.GetPosition + TVector2.From(0, -5 * C_COEF), TVector2.From(0, -1));
  def.enableLimit := True;
  //def.enableMotor := True;
  b2ShovelJoint := Tb2PrismaticJoint(b2World.CreateJoint(Def));
  with b2ShovelJoint do
  begin
    SetLimits(-15 * C_COEF, 5 * C_COEF);
    SetMotorSpeed(-2);
    SetMaxMotorForce(2);
  end;
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
var
  IsAccelerating: Boolean;
begin
  Brake(False);

  if R.Input.IsKeyDown(VK_RIGHT) then
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
        ReduceAccel(3 * dt);
        Brake(True);
        IsAccelerating := False;
        b2WheelJointRear.EnableMotor(False);
      end;
    end
    else
    begin
      AddAccel(dt);
      IsAccelerating := True;
    end;
  end

  else if R.Input.IsKeyDown(VK_LEFT) then
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
        IsAccelerating := False;
        b2WheelJointRear.EnableMotor(False);
      end;

    end
    else
    begin
      AddAccel(dt);
      IsAccelerating := True;
    end;
  end

  //не нажато ни вперед, ни назад
  else
  begin
    b2WheelJointRear.EnableMotor(False);
    IsAccelerating := False;
    ReduceAccel(0.5 * dt);
    CalcMotorSpeed(dt);
  end;


  if IsAccelerating then
  begin
    b2WheelJointRear.SetMotorSpeed(-CurrentMotorSpeed * Gears[Gear]);
    b2WheelJointRear.SetMaxMotorTorque(5 / Abs(Gears[Gear]));
    if (WheelPoints > 0){ and (Gear > 0)} then
      AddDownForce(dt);
  end;

  if R.Input.IsKeyDown(VK_SPACE) then
  begin
    b2WheelJointRear.EnableMotor(True);
    b2WheelJointRear.SetMotorSpeed(0);
    b2WheelJointRear.SetMaxMotorTorque(10);
  end;

  if AutomaticTransmission then
    AutomaticTransmissionUpdate(dt)
  else
    if R.Input.IsKeyPressed(VK_A) then
      GearUp()
    else if R.Input.IsKeyPressed(VK_Z) then
      GearDown();

  if R.Input.IsKeyPressed(VK_M) then
    AutomaticTransmission := not AutomaticTransmission;

  DefineCarDynamicParams(dt);
  //CalcMotorSpeed(dt);

  SyncObjects(b2Body, Body);
  SyncObjects(b2SuspRear, SuspRear);
  SyncObjects(b2SuspFront, SuspFront);
  SyncObjects(b2WheelRear, WheelRear);
  SyncObjects(b2WheelFront, WheelFront);
  SyncObjects(b2Shovel, Shovel);
  WheelTrigger.Body.SetTransform(b2Body.GetPosition + ConvertGLToB2(WheelTriggerOffset), 0);
  SyncObjects(WheelTrigger.Body, WheelTrigger.Sprite);
end;

procedure TpdCar.OnWheelTriggerEnter(Trigger: TpdTrigger; Catched: Tb2Fixture);
begin
  Inc(WheelPoints);
end;

procedure TpdCar.OnWheelTriggerLeave(Trigger: TpdTrigger; Catched: Tb2Fixture);
begin
  Dec(WheelPoints);
end;

end.

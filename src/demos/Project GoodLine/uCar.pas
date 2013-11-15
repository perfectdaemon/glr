unit uCar;

interface

uses
  glr, glrMath,
  uCarSaveLoad,
  uPhysics2D;

const
  INITIAL_X = 100;
  INITIAL_Y = 30;

type
  TpdCar = class
  private
    procedure InitSprites(const aCarInfo: TpdCarInfo);
    procedure InitBodies(const aCarInfo: TpdCarInfo);
    procedure InitJoints(const aCarInfo: TpdCarInfo);
  public
    WheelRear, WheelFront, Body: IglrSprite;
    b2WheelRear, b2WheelFront, b2Body, b2SuspRear, b2SuspFront: Tb2Body;
    b2WheelJointRear, b2WheelJointFront: Tb2RevoluteJoint;
    b2SuspJointRear, b2SuspJointFront: Tb2PrismaticJoint;

    constructor Create(const aCarInfo: TpdCarInfo);
    destructor Destroy(); override;

    procedure Update(const dt: Double);
  end;

implementation

uses
  Windows,
  uGlobal, uBox2DImport, uPhysics2DTypes;

{ TpdCar }

constructor TpdCar.Create(const aCarInfo: TpdCarInfo);
begin
  inherited Create();
  InitSprites(aCarInfo);
  InitBodies(aCarInfo);
  InitJoints(aCarInfo);
end;

destructor TpdCar.Destroy;
begin
  mainScene.RootNode.RemoveChild(Body);
  mainScene.RootNode.RemoveChild(WheelRear);
  mainScene.RootNode.RemoveChild(WheelFront);
  inherited;
end;

procedure TpdCar.InitBodies(const aCarInfo: TpdCarInfo);
begin
  with aCarInfo do
  begin
    b2Body := dfb2InitBox(b2world, Body, BodyD, BodyF, BodyR, $FFFF, $000F, -2);
    b2WheelRear := dfb2InitCircle(b2world, WheelRear, WheelRearD, WheelRearF, WheelRearR, $FFFF, $000F, -2);
    b2WheelFront := dfb2InitCircle(b2world, WheelFront, WheelFrontD, WheelFrontF, WheelFrontR, $FFFF, $000F, -2);
    b2SuspRear := dfb2InitBox(b2world, Body.Position2D + SuspRearOffset, dfVec2f(20, 5), 0, 1.0, 0, 0, $FFFF, $0000, -2);
    b2SuspFront := dfb2InitBox(b2world, Body.Position2D + SuspFrontOffset, dfVec2f(20, 5), 0, 1.0, 0, 0, $FFFF, $0000, -2);
  end;
end;

procedure TpdCar.InitJoints(const aCarInfo: TpdCarInfo);
var
  suspAxis: TVector2;
  PriDef: Tb2PrismaticJointDef;
  RevDef: Tb2RevoluteJointDef;
begin
  suspAxis.SetValue(0, 1);

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
  RevDef.Initialize(b2WheelRear, b2SuspRear, b2WheelRear.GetPosition);
  b2WheelJointRear := Tb2RevoluteJoint(b2World.CreateJoint(RevDef));

  RevDef := Tb2RevoluteJointDef.Create;
  RevDef.Initialize(b2WheelFront, b2SuspFront, b2WheelFront.GetPosition);
  b2WheelJointFront := Tb2RevoluteJoint(b2World.CreateJoint(RevDef));
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

  WheelRear := Factory.NewSprite();
  with WheelRear do
  begin
    Material.Texture := atlasMain.LoadTexture(CIRCLE_TEXTURE);
    Material.Diffuse := colorWhite;
    SetSizeToTextureSize();
    UpdateTexCoords();
    PivotPoint := ppCenter;
    Position := Body.Position + dfVec3f(aCarInfo.WheelRearOffset, 1);
  end;
  mainScene.RootNode.AddChild(WheelRear);

  WheelFront := Factory.NewSprite();
  with WheelFront do
  begin
    Material.Texture := atlasMain.LoadTexture(CIRCLE_TEXTURE);
    Material.Diffuse := colorWhite;
    SetSizeToTextureSize();
    UpdateTexCoords();
    PivotPoint := ppCenter;
    Position := Body.Position + dfVec3f(aCarInfo.WheelFrontOfsset, 1);
  end;
  mainScene.RootNode.AddChild(WheelFront);
end;

procedure TpdCar.Update(const dt: Double);
begin
  if R.Input.IsKeyDown(VK_UP) then
  begin
    b2WheelJointRear.EnableMotor(True);
    b2WheelJointRear.SetMotorSpeed(-15);
    b2WheelJointRear.SetMaxMotorTorque(100);
  end
  else if R.Input.IsKeyDown(VK_DOWN) then
  begin
    b2WheelJointRear.EnableMotor(True);
    b2WheelJointRear.SetMotorSpeed(15);
    b2WheelJointRear.SetMaxMotorTorque(100);
  end
  else
  begin
    b2WheelJointRear.EnableMotor(False);
    b2WheelJointRear.SetMotorSpeed(0);
    b2WheelJointRear.SetMaxMotorTorque(100);
  end;

  SyncObjects(b2Body, Body);
  SyncObjects(b2WheelRear, WheelRear);
  SyncObjects(b2WheelFront, WheelFront);
end;

end.

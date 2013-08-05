unit uCar;

interface

uses
  dfHRenderer,
  dfMath,
  uBox2DImport, UPhysics2D, UPhysics2DTypes;

type
  TglrCarParams = record
    position: TdfVec2f;
    rotation: Single;
    spriteFileName: String;
    bodySizeOffset: TdfVec2f;
    massCenterOffset: TdfVec2f;
    forcePointOffset: TdfVec2f;
    density, friction, restitution: Single;
    rightWheelOffset, leftWheelOffset,
    wheelSize: TdfVec2f;
  end;

  TglrCar = class
  private
    FSprite: IglrSprite;
    FBody: Tb2Body;
    FRightWheel, FLeftWheel: Tb2Body;
    FRightWheelJoint, FLeftWheelJoint: Tb2RevoluteJoint;
    FForcePointOffset: TdfVec2f;

    FWheelsAngle: Single;

    FMoveForward: Boolean;

    procedure Handling(const dt: Double);
  public
    class function Init(aScene: Iglr2DScene; aWorld: Tglrb2World; aParams: TglrCarParams): TglrCar;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);
  end;

var
  CarR: IglrRenderer;

implementation

uses
  Windows,
  uUtils;

{ TglrCar }

constructor TglrCar.Create;
begin
  inherited;
end;

destructor TglrCar.Destroy;
begin
  FSprite := nil;
  inherited;
end;

procedure TglrCar.Handling(const dt: Double);
var
  f, pt: TdfVec2f;
begin
  f := dfVec2f(cos(FBody.GetAngle), sin(FBody.GetAngle));
  pt := (FSprite.Position + f * FForcePointOffset) * C_COEF;
  f := f * C_COEF * 14;
  if CarR.Input.IsKeyDown(VK_UP) then
  begin
    FBody.ApplyLinearImpulse(ConvertGLToB2(f), ConvertGLToB2(pt));
    FMoveForward := True;
  end
  else if CarR.Input.IsKeyDown(VK_DOWN) then
  begin
    FBody.ApplyLinearImpulse(ConvertGLToB2(f.NegateVector), ConvertGLToB2(pt));
    FMoveForward := False;
  end;

  if CarR.Input.IsKeyDown(VK_LEFT) then
    FWheelsAngle := -4
  else if CarR.Input.IsKeyDown(VK_RIGHT) then
    FWheelsAngle := 4
  else
    FWheelsAngle := 0.0;

  if not FMoveForward then
    FWheelsAngle := -FWheelsAngle;

//  if FBody.GetLinearVelocity.SqrLength > 15 * C_COEF then
    FBody.ApplyAngularImpulse(FWheelsAngle * FBody.GetLinearVelocity.SqrLength * 0.2 * C_COEF);
end;

class function TglrCar.Init(aScene: Iglr2DScene; aWorld: Tglrb2World; aParams: TglrCarParams): TglrCar;
var
  finalSize: TdfVec2f;
  rev_def: Tb2RevoluteJointDef;
  mass: Tb2MassData;
begin
  Result := TglrCar.Create();
  with aParams, Result do
  begin
    FSprite := glrGetObjectFactory().NewSprite();
    glrLoadSprite(FSprite, spriteFileName, position, rotation);
    aScene.RegisterElement(FSprite);
    finalSize := dfVec2f(FSprite.Width, FSprite.Height) + bodySizeOffset;

    //Тело машины
    FBody := dfb2InitBox(aWorld, position, finalSize, rotation, density, friction, restitution, $0002, $0004, -1);
    FBody.AngularDamping := 3;
    FBody.LinearDamping := 2;
    FBody.GetMassData(mass); mass.center := ConvertGLToB2(massCenterOffset);
//    FRightWheel := dfb2InitBox(aWorld, position + rightWheelOffset, wheelSize, 0, density, friction, restitution, $0002, $0004);
//    FLeftWheel := dfb2InitBox(aWorld, position + leftWheelOffset, wheelSize, 0, density, friction, restitution, $0002, $0004);
//
//    FForcePointOffset := forcePointOffset;
//
//    rev_def := Tb2RevoluteJointDef.Create;
//    rev_def.Initialize(FBody, FRightWheel, FRightWheel.GetPosition);
//    rev_def.enableLimit := True;
////    rev_def.lowerAngle := -45 * deg2rad;
////    rev_def.upperAngle := 45 * deg2rad;
//    FRightWheelJoint := Tb2RevoluteJoint(aWorld.CreateJoint(rev_def));
//
//    rev_def := Tb2RevoluteJointDef.Create;
//    rev_def.Initialize(FBody, FLeftWheel, FLeftWheel.GetPosition);
//    rev_def.enableLimit := True;
////    rev_def.lowerAngle := -45 * deg2rad;
////    rev_def.upperAngle := 45 * deg2rad;
//    FLeftWheelJoint := Tb2RevoluteJoint(aWorld.CreateJoint(rev_def));
  end;
end;

procedure TglrCar.Update(const dt: Double);
begin
//  FLeftWheelJoint.SetMotorSpeed(1 * (FWheelsAngle - FLeftWheelJoint.GetJointAngle));
//  FRightWheelJoint.SetMotorSpeed(1 * (FWheelsAngle - FRightWheelJoint.GetJointAngle));

  Handling(dt);
  SyncObjects(FBody, FSprite);
end;

end.

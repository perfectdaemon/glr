{
  TODO:
  +  Joints
  +- Joint correction

}

unit uCharacter;

interface

uses
  dfHRenderer,
  dfMath,
  UPhysics2D, uBox2DImport;

const
  CHAR_ARM_BLOCK_COUNT = 6;
  CHAR_BODY_BLOCK_COUNT = 8;
  CHAR_LEG_BLOCK_COUNT = 7;

  CHAR_HEAD_RADIUS = 30.0;
  CHAR_OTHER_RADIUS = 15.0;

  CHAR_DENSITY = 0.3;
  CHAR_HEAD_DENSITY = 2;
  CHAR_FRICTION = 0.1;
  CHAR_RESTITUTION = 0.7;

  CHAR_LIMIT_L = -5;
  CHAR_LIMIT_H = 5;

  CHAR_CORRECTION_STOP_ON_ANGLE: Single = 1 * 3.1415 / 180;


type
  TglrCharacterForm = (cfCircle = 0, cfBox = 1);
  TglrCharacterParams = record
    initialPosition: TdfVec2f;
    charForm: TglrCharacterForm;
  end;

  TglrCharacter = class
  private
  protected
    FInput: IdfInput;
    //Bodies
    FHead: Tb2Body;
    FBody: array[0..CHAR_BODY_BLOCK_COUNT - 1] of Tb2Body;
    FLeftArm, FRightArm: array[0..CHAR_ARM_BLOCK_COUNT - 1] of Tb2Body;
    FRightLeg, FLeftLeg: array[0..CHAR_LEG_BLOCK_COUNT - 1] of Tb2Body;

    //Joints
    FRightLegJoints, FLeftLegJoints: array[0..CHAR_LEG_BLOCK_COUNT - 2] of Tb2RevoluteJoint;
    FBodyJoints: array[0..CHAR_BODY_BLOCK_COUNT - 2] of Tb2RevoluteJoint;
    FRightArmJoints, FLeftArmJoints: array[0..CHAR_ARM_BLOCK_COUNT - 2] of Tb2RevoluteJoint;

    FHeadBodyJoint,
    FLeftArmBodyJoint, FRightArmBodyJoint,
    FLeftLegBodyJoint, FRightLegBodyJoint: Tb2RevoluteJoint;

    FScene2D: Idf2DScene;

    //Sprites
    FGLHead: IdfSprite;
    FGLBody: array[0..CHAR_BODY_BLOCK_COUNT - 1] of IdfSprite;
    FGLLeftArm, FGLRightArm: array[0..CHAR_ARM_BLOCK_COUNT - 1] of IdfSprite;
    FGLRightLeg, FGLLeftLeg: array[0..CHAR_LEG_BLOCK_COUNT - 1] of IdfSprite;

    FTex: IdfTexture;

    procedure Control(const dt: Double); virtual;
    procedure ApplyCorrection(); virtual;

    constructor Create(); virtual;
  public
    class function Init(b2w: Tdfb2World; scene2d: Idf2DScene; input: IdfInput;
      params: TglrCharacterParams): TglrCharacter; virtual;

    destructor Destroy(); override;

    procedure Update(const dt: Double); virtual;
  end;

implementation

uses
  Windows,
  UPhysics2DTypes;

{ TglrCharacter }

constructor TglrCharacter.Create;
begin
  inherited;
end;

destructor TglrCharacter.Destroy;
begin
  inherited;
end;

procedure TglrCharacter.ApplyCorrection;

  procedure ApplyCorrectionToJoint(aJoint: Tb2RevoluteJoint);
  begin
    if Abs(aJoint.GetJointAngle) < CHAR_CORRECTION_STOP_ON_ANGLE then
    begin
      aJoint.EnableMotor(False);
      aJoint.SetMotorSpeed(0);
      aJoint.SetMaxMotorTorque(1000);
    end
    else
    begin
      aJoint.SetMotorSpeed(-20*aJoint.GetJointAngle());
      aJoint.SetMaxMotorTorque(1000);
    end;
  end;

var
  i: Integer;

begin
  ApplyCorrectionToJoint(FHeadBodyJoint);
  ApplyCorrectionToJoint(FLeftArmBodyJoint);
  ApplyCorrectionToJoint(FRightArmBodyJoint);
  ApplyCorrectionToJoint(FLeftLegBodyJoint);
  ApplyCorrectionToJoint(FRightLegBodyJoint);
  for i := 0 to CHAR_BODY_BLOCK_COUNT - 2 do
    ApplyCorrectionToJoint(FBodyJoints[i]);
  for i := 0 to CHAR_ARM_BLOCK_COUNT - 2 do
  begin
    ApplyCorrectionToJoint(FLeftArmJoints[i]);
    ApplyCorrectionToJoint(FRightArmJoints[i]);
  end;
  for i := 0 to CHAR_LEG_BLOCK_COUNT - 2 do
  begin
    ApplyCorrectionToJoint(FLeftLegJoints[i]);
    ApplyCorrectionToJoint(FRightLegJoints[i]);
  end;

end;

procedure TglrCharacter.Control(const dt: Double);
  const
    cForce = 40;
begin
  if FInput.IsKeyDown(VK_LEFT) then
    FHead.ApplyForce(TVector2.From(-cForce, 0), FHead.GetWorldCenter);
  if FInput.IsKeyDown(VK_RIGHT) then
    FHead.ApplyForce(TVector2.From(cForce, 0), FHead.GetWorldCenter);
  if FInput.IsKeyDown(VK_UP) then
    FHead.ApplyForce(TVector2.From(0, -cForce), FHead.GetWorldCenter);
  if FInput.IsKeyDown(VK_DOWN) then
    FHead.ApplyForce(TVector2.From(0, cForce), FHead.GetWorldCenter);
end;

class function TglrCharacter.Init(b2w: Tdfb2World; scene2d: Idf2DScene; input: IdfInput;
  params: TglrCharacterParams): TglrCharacter;

  procedure QuickInit(var aSprite: IdfSprite; var aBody: Tb2Body; aPos: TdfVec2f; aRad: Single;
    color: TdfVec4f; density: Single = -1);
  begin
    aSprite := dfCreateHUDSprite();
    aSprite.PivotPoint := ppCenter;
    aSprite.Position := aPos;
    aSprite.Width := aRad;
    aSprite.Height := aRad;
    aSprite.Material.Texture := Result.FTex;
    aSprite.Material.MaterialOptions.Diffuse := color;
    Result.FScene2D.RegisterElement(aSprite);

    if density = -1 then
      density := CHAR_DENSITY;

    aBody := dfb2InitCircle(b2w, aRad, aPos,
      density, CHAR_FRICTION, CHAR_RESTITUTION,
      $0002, $0004, -1);
    aBody.LinearDamping := 0.5;
    aBody.AngularDamping := 0.1;
  end;

  procedure QuickJointInit(var joint: Tb2RevoluteJoint; b1, b2: Tb2Body; limits: TdfVec2f);
  var
    def: Tb2RevoluteJointDef;
    aPos, b1p, b2p: TdfVec2f;
  begin
    b1p := ConvertB2ToGL(b1.GetWorldCenter);
    b2p := ConvertB2ToGL(b2.GetWorldCenter);
    aPos := b1p + (b2p - b1p) * 0.5;
    def := Tb2RevoluteJointDef.Create;
    def.Initialize(b1, b2, ConvertGLToB2(aPos));
    def.lowerAngle := limits.x;
    def.upperAngle := limits.y;
    def.enableLimit := True;
//    def.enableMotor := True;
//    def.motorSpeed := 0.1;
    def.maxMotorTorque := 1000;
    joint := Tb2RevoluteJoint(b2w.CreateJoint(def));
  end;
var
  i: Integer;
begin
  Result := TglrCharacter.Create();
  with Result do
  begin
    //Texture
    FTex := dfCreateTexture();
    FTex.Load2D('data/circle.tga');
    FTex.BlendingMode := tbmTransparency;
    FTex.CombineMode := tcmModulate;

    FScene2D := scene2d;
    FInput := input;

    //head
    QuickInit(FGLHead, FHead, params.initialPosition, CHAR_HEAD_RADIUS, dfVec4f(1, 1, 1, 1), CHAR_HEAD_DENSITY);

    //body
    for i := 0 to CHAR_BODY_BLOCK_COUNT - 1 do
      QuickInit(FGLBody[i], FBody[i], params.initialPosition + dfVec2f(0, (i + 1) * CHAR_OTHER_RADIUS / 2),
        CHAR_OTHER_RADIUS, dfVec4f(0.5, 0.5, 0.5, 0.5));

    //arms
    for i := 0 to CHAR_ARM_BLOCK_COUNT - 1 do
    begin
      QuickInit(FGLLeftArm[i], FLeftArm[i], FGLBody[2].Position + dfVec2f( - (i + 1) * CHAR_OTHER_RADIUS / 2, 0),
        CHAR_OTHER_RADIUS, dfVec4f(1, 0.5, 0.5, 1));
      QuickInit(FGLRightArm[i], FRightArm[i], FGLBody[2].Position + dfVec2f((i + 1) * CHAR_OTHER_RADIUS / 2, 0),
        CHAR_OTHER_RADIUS,  dfVec4f(0.5, 0.5, 1, 1));
    end;

    //legs
    for i := 0 to CHAR_LEG_BLOCK_COUNT - 1 do
    begin
      QuickInit(FGLLeftLeg[i], FLeftLeg[i],
        FGLBody[CHAR_BODY_BLOCK_COUNT - 1].Position + dfVec2f( - (i + 1) * CHAR_OTHER_RADIUS / 2.5, (i + 1) * CHAR_OTHER_RADIUS / 2),
        CHAR_OTHER_RADIUS, dfVec4f(1, 0.5, 0.5, 1));
      QuickInit(FGLRightLeg[i], FRightLeg[i],
        FGLBody[CHAR_BODY_BLOCK_COUNT - 1].Position + dfVec2f((i + 1) * CHAR_OTHER_RADIUS / 2.5, (i + 1) * CHAR_OTHER_RADIUS / 2),
        CHAR_OTHER_RADIUS,  dfVec4f(0.5, 0.5, 1, 1));
    end;

    //JOINTS
    //body
    for i := 0 to CHAR_BODY_BLOCK_COUNT - 2 do
      QuickJointInit(FBodyJoints[i], FBody[i], FBody[i + 1], dfVec2f(CHAR_LIMIT_L * deg2rad, CHAR_LIMIT_H * deg2rad));

    //legs
    for i := 0 to CHAR_LEG_BLOCK_COUNT - 2 do
    begin
      QuickJointInit(FLeftLegJoints[i], FLeftLeg[i], FLeftLeg[i + 1], dfVec2f(CHAR_LIMIT_L * deg2rad, CHAR_LIMIT_H * deg2rad));
      QuickJointInit(FRightLegJoints[i], FRightLeg[i], FRightLeg[i + 1], dfVec2f(CHAR_LIMIT_L * deg2rad, CHAR_LIMIT_H * deg2rad));
    end;

    for i := 0 to CHAR_ARM_BLOCK_COUNT - 2 do
    begin
      QuickJointInit(FLeftArmJoints[i], FLeftArm[i], FLeftArm[i + 1], dfVec2f(CHAR_LIMIT_L * deg2rad, CHAR_LIMIT_H * deg2rad));
      QuickJointInit(FRightArmJoints[i], FRightArm[i], FRightArm[i + 1], dfVec2f(CHAR_LIMIT_L * deg2rad, CHAR_LIMIT_H * deg2rad));
    end;

    //Head-body
    QuickJointInit(FHeadBodyJoint, FHead, FBody[0], dfVec2f(-20 * deg2rad, 20 * deg2rad));
    //leg-body
    QuickJointInit(FLeftLegBodyJoint, FLeftLeg[0], FBody[CHAR_BODY_BLOCK_COUNT - 1], dfVec2f(-30 * deg2rad, 30 * deg2rad));
    QuickJointInit(FRightLegBodyJoint, FRightLeg[0], FBody[CHAR_BODY_BLOCK_COUNT - 1], dfVec2f(-30 * deg2rad, 30 * deg2rad));
    //arm-body
    QuickJointInit(FLeftArmBodyJoint, FLeftArm[0], FBody[3], dfVec2f(-30 * deg2rad, 30 * deg2rad));
    QuickJointInit(FRightArmBodyJoint, FRightArm[0], FBody[3], dfVec2f(-30 * deg2rad, 30 * deg2rad));
  end;
end;

procedure TglrCharacter.Update(const dt: Double);
var
  i: Integer;
begin
  SyncObjects(FHead, FGLHead);
  for i := 0 to CHAR_BODY_BLOCK_COUNT - 1 do
    SyncObjects(FBody[i], FGLBody[i]);
  for i := 0 to CHAR_ARM_BLOCK_COUNT - 1 do
  begin
    SyncObjects(FLeftArm[i], FGLLeftArm[i]);
    SyncObjects(FRightArm[i], FGLRightArm[i]);
  end;

  for i := 0 to CHAR_LEG_BLOCK_COUNT - 1 do
  begin
    SyncObjects(FLeftLeg[i], FGLLeftLeg[i]);
    SyncObjects(FRightLeg[i], FGLRightLeg[i]);
  end;

  Control(dt);
  ApplyCorrection();
end;

end.

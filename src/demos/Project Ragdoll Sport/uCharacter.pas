unit uCharacter;

interface

uses
  glr,
  glrMath,
//  uCharacter,
  UPhysics2D, UPhysics2DTypes, uBox2DImport;

const
//  CHAR_ARM_BLOCK_COUNT = 2;
//  CHAR_BODY_BLOCK_COUNT = 2;
//  CHAR_LEG_BLOCK_COUNT = 2;

  CHAR_HEAD_SIZE = 30.0;
  CHAR_BODY_SIZE_X = 15;
  CHAR_BODY_SIZE_Y = 30;
  CHAR_ARM_SIZE_X  = 15;
  CHAR_ARM_SIZE_Y  = 30;
  CHAR_LEG_SIZE_X  = 15;
  CHAR_LEG_SIZE_Y  = 45;

  CHAR_ARM_ANGLE = 90;
  CHAR_LEG_ANGLE = 45;

  CHAR_BLOCK_OFFSET = 5;
  //CHAR_OTHER_RADIUS = 35;
//  CHAR_OTHER_X = 15;
//  CHAR_OTHER_Y = 35;

  CHAR_DENSITY = 0.5;
  CHAR_HEAD_DENSITY = 0.4;
  CHAR_FRICTION = 0.1;
  CHAR_RESTITUTION = 0.7;

  CHAR_LIMIT_L = -45;
  CHAR_LIMIT_H = 45;

  CHAR_CORRECTION_STOP_ON_ANGLE: Single = 2 * 3.1415 / 180;

  ARMHIT_TIMEOUT = 0.6;

  HIT_THRESHOLD_SPEED = 4.5;


type
  TglrOnControl = procedure(const dt: Double) of object;

  TglrCharacterForm = (cfCircle = 0, cfBox = 1);
  TglrCharacterParams = record
    initialPosition: TdfVec2f;
    charForm: TglrCharacterForm;
    charGroup: Integer;
  end;

  TpdCharacter = class
  protected
    //Bodies
    FHead: Tb2Body;
    FBody: array[0..1] of Tb2Body;
    FLeftArm, FRightArm: array[0..1] of Tb2Body;
    FRightLeg, FLeftLeg: array[0..1] of Tb2Body;

    FRightLegJoint, FLeftLegJoint, FBodyJoint, FRightArmJoint, FLeftArmJoint,
    FHeadBodyJoint,
    FLeftArmBodyJoint, FRightArmBodyJoint,
    FLeftLegBodyJoint, FRightLegBodyJoint: Tb2RevoluteJoint;

    FScene2D: Iglr2DScene;

    //Sprites
    FGLHead: IglrSprite;
    FGLBody: array[0..1] of IglrSprite;
    FGLLeftArm, FGLRightArm: array[0..1] of IglrSprite;
    FGLRightLeg, FGLLeftLeg: array[0..1] of IglrSprite;

    FOnControl: TglrOnControl;

    FArmHitTimeout: Single;

    procedure ApplyCorrection(); virtual;

    constructor Create(); virtual;
  public
    class function Init(b2w: Tglrb2World; scene2d: Iglr2DScene;
      params: TglrCharacterParams): TpdCharacter; virtual;

    destructor Destroy(); override;

    procedure Update(const dt: Double); virtual;
    procedure ApplyControlImpulse(impulse: TVector2);
    property OnControl: TglrOnControl read FOnControl write FOnControl;
    function GetHeadPosition(): TdfVec2f;
  end;

  TglrBodyPart = (bpNone, bpHead, bpBody, bpLegStart, bpLegEnd, bpArmStart, bpArmEnd);

  TglrContactListener = class(Tb2ContactListener)
  public
    procedure BeginContact(var contact: Tb2Contact); override;
  end;

implementation

uses
  uGlobal, dfTweener, uObjects,
  Windows;


var
  colorHead:     TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorBody:     TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorLeftArm:  TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorRightArm: TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorLeftLeg:  TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorRightLeg: TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);

  internalZ: Integer = 0;

{ TglrCharacter }

constructor TpdCharacter.Create;
begin
  inherited;
end;

destructor TpdCharacter.Destroy;
begin
  Dispose(FHead.UserData);

  Dispose(FBody[0].UserData);
  Dispose(FBody[1].UserData);

  Dispose(FLeftArm[0].UserData);
  Dispose(FLeftArm[1].UserData);
  Dispose(FRightArm[0].UserData);
  Dispose(FRightArm[1].UserData);

  Dispose(FLeftLeg[0].UserData);
  Dispose(FLeftLeg[1].UserData);
  Dispose(FRightLeg[0].UserData);
  Dispose(FRightLeg[1].UserData);
  inherited;
end;

function TpdCharacter.GetHeadPosition: TdfVec2f;
begin
  Result := FGLHead.Position2D;
end;

procedure TpdCharacter.ApplyCorrection;

  procedure ApplyCorrectionToJoint(aJoint: Tb2RevoluteJoint);
  begin
    if Abs(aJoint.GetJointAngle) < CHAR_CORRECTION_STOP_ON_ANGLE then
    begin
      aJoint.EnableMotor(False);
      aJoint.SetMotorSpeed(0);
      aJoint.SetMaxMotorTorque(1);
    end
    else
    begin
      aJoint.EnableMotor(True);
      aJoint.SetMotorSpeed(-1 * aJoint.GetJointAngle());
      aJoint.SetMaxMotorTorque(1);
    end;
  end;

begin
  ApplyCorrectionToJoint(FHeadBodyJoint);
  ApplyCorrectionToJoint(FLeftArmBodyJoint);
  ApplyCorrectionToJoint(FRightArmBodyJoint);
  ApplyCorrectionToJoint(FLeftLegBodyJoint);
  ApplyCorrectionToJoint(FRightLegBodyJoint);
  ApplyCorrectionToJoint(FBodyJoint);
  ApplyCorrectionToJoint(FLeftArmJoint);
  ApplyCorrectionToJoint(FRightArmJoint);
  ApplyCorrectionToJoint(FLeftLegJoint);
  ApplyCorrectionToJoint(FRightLegJoint);
end;

procedure TpdCharacter.ApplyControlImpulse(impulse: TVector2);
begin
  FHead.ApplyForce(impulse, FHead.GetWorldCenter);
end;

class function TpdCharacter.Init(b2w: Tglrb2World; scene2d: Iglr2DScene; {input: IdfInput;}
  params: TglrCharacterParams): TpdCharacter;

  procedure QuickInit(var aSprite: IglrSprite; var aBody: Tb2Body; aPos: TdfVec2f; aSize: TdfVec2f; aRot: Single;
    color: TdfVec4f; bodyPart: TglrBodyPart; density: Single = -1);
  var
    userdata: ^TpdUserData;
  begin
    aSprite := Factory.NewSprite();
    aSprite.PivotPoint := ppCenter;
    aSprite.Position := dfVec3f(aPos, Z_PLAYER + internalZ);
    aSprite.Width := aSize.x;
    aSprite.Height := aSize.y;
    aSprite.Rotation := aRot;
    Inc(internalZ);

    aSprite.Material.Diffuse := color;
    Result.FScene2D.RootNode.AddChild(aSprite);

    if density = -1 then
      density := CHAR_DENSITY;
    if bodyPart = bpHead then
    begin
      aBody := dfb2InitCircle(b2w, aSize.x / 2, aPos,
        CHAR_DENSITY, CHAR_FRICTION, CHAR_RESTITUTION,
        $FFFF, $0000 + params.charGroup, -params.charGroup);
      aSprite.Material.Texture := texHead;
      aSprite.UpdateTexCoords();
    end
    else
    begin
      aBody := dfb2InitBox(b2w, aPos, aSize, aRot, density, CHAR_FRICTION, CHAR_RESTITUTION,
        $FFFF, $0000 + params.charGroup, -params.charGroup);
      aSprite.Material.Texture := texBodyPart;
      aSprite.UpdateTexCoords();
    end;

    aBody.LinearDamping := 0.2;
    aBody.AngularDamping := 0.1;
    New(userdata);
    userdata^.aType := tCharacter;
    userdata^.aObject := Result;
    userdata^.aBodyPart := bodyPart;
    userdata^.aObjectSprite := aSprite;
    aSprite._Release();
    aBody.UserData := userdata;
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
  Result := TpdCharacter.Create();
  with Result do
  begin
    FScene2D := scene2d;

    //head
    QuickInit(FGLHead, FHead, params.initialPosition, dfVec2f(CHAR_HEAD_SIZE, CHAR_HEAD_SIZE), 0,
      colorHead, bpHead, CHAR_HEAD_DENSITY);

    //body
    for i := 0 to 1 do
      QuickInit(FGLBody[i], FBody[i], params.initialPosition + dfVec2f(0, CHAR_BLOCK_OFFSET * i + (i + 1) * CHAR_BODY_SIZE_Y),
        dfVec2f(CHAR_BODY_SIZE_X, CHAR_BODY_SIZE_Y), 0, colorBody, bpBody);

    //arms
      QuickInit(FGLLeftArm[0], FLeftArm[0], FGLBody[0].Position2D + dfVec2f(- CHAR_BLOCK_OFFSET * 0 - (1) * CHAR_ARM_SIZE_Y, 0),
        dfVec2f(CHAR_ARM_SIZE_X, CHAR_ARM_SIZE_Y), 90, colorLeftArm, bpArmStart);
      QuickInit(FGLRightArm[0], FRightArm[0], FGLBody[0].Position2D + dfVec2f(CHAR_BLOCK_OFFSET * 0 + (1) * CHAR_ARM_SIZE_Y, 0),
        dfVec2f(CHAR_ARM_SIZE_X, CHAR_ARM_SIZE_Y), 90, colorRightArm, bpArmStart);

      QuickInit(FGLLeftArm[1], FLeftArm[1], FGLBody[0].Position2D + dfVec2f(- CHAR_BLOCK_OFFSET * 1 - (2) * CHAR_ARM_SIZE_Y, 0),
        dfVec2f(CHAR_ARM_SIZE_X, CHAR_ARM_SIZE_Y), 90, colorLeftArm, bpArmEnd);
      QuickInit(FGLRightArm[1], FRightArm[1], FGLBody[0].Position2D + dfVec2f(CHAR_BLOCK_OFFSET * 1 + (2) * CHAR_ARM_SIZE_Y, 0),
        dfVec2f(CHAR_ARM_SIZE_X, CHAR_ARM_SIZE_Y), 90, colorRightArm, bpArmEnd);

    //legs
      QuickInit(FGLLeftLeg[0], FLeftLeg[0],
        FGLBody[1].Position2D + dfVec2f(-1.5*CHAR_BODY_SIZE_X, 1.5*CHAR_BODY_SIZE_X) + dfVec2f( - (0) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * cos(CHAR_LEG_ANGLE * deg2rad),
                                                                 (0) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * sin(CHAR_LEG_ANGLE * deg2rad)),
        dfVec2f(CHAR_LEG_SIZE_X, CHAR_LEG_SIZE_Y), CHAR_LEG_ANGLE, colorLeftLeg, bpLegStart);
      QuickInit(FGLRightLeg[0], FRightLeg[0],
        FGLBody[1].Position2D + dfVec2f(1.5*CHAR_BODY_SIZE_X, 1.5*CHAR_BODY_SIZE_X) + dfVec2f((0) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * cos(CHAR_LEG_ANGLE * deg2rad),
                                                              (0) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * sin(CHAR_LEG_ANGLE * deg2rad)),
        dfVec2f(CHAR_LEG_SIZE_X, CHAR_LEG_SIZE_Y), -CHAR_LEG_ANGLE, colorRightLeg, bpLegStart);

      QuickInit(FGLLeftLeg[1], FLeftLeg[1],
        FGLBody[1].Position2D + dfVec2f(-1.5*CHAR_BODY_SIZE_X, 1.5*CHAR_BODY_SIZE_X) + dfVec2f( - (1) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * cos(CHAR_LEG_ANGLE * deg2rad),
                                                                 (1) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * sin(CHAR_LEG_ANGLE * deg2rad)),
        dfVec2f(CHAR_LEG_SIZE_X, CHAR_LEG_SIZE_Y), CHAR_LEG_ANGLE, colorLeftLeg, bpLegEnd);
      QuickInit(FGLRightLeg[1], FRightLeg[1],
        FGLBody[1].Position2D + dfVec2f(1.5*CHAR_BODY_SIZE_X, 1.5*CHAR_BODY_SIZE_X) + dfVec2f((1) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * cos(CHAR_LEG_ANGLE * deg2rad),
                                                              (1) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * sin(CHAR_LEG_ANGLE * deg2rad)),
        dfVec2f(CHAR_LEG_SIZE_X, CHAR_LEG_SIZE_Y), -CHAR_LEG_ANGLE, colorRightLeg, bpLegEnd);

    //JOINTS
    //body
    QuickJointInit(FBodyJoint, FBody[0], FBody[1], dfVec2f(5 * deg2rad, 5 * deg2rad));

    //legs
    QuickJointInit(FLeftLegJoint, FLeftLeg[0], FLeftLeg[1], dfVec2f(-CHAR_LIMIT_H * deg2rad, -CHAR_LIMIT_L * deg2rad));
    QuickJointInit(FRightLegJoint, FRightLeg[0], FRightLeg[1], dfVec2f(CHAR_LIMIT_L * deg2rad, CHAR_LIMIT_H * deg2rad));

    //arms
    QuickJointInit(FLeftArmJoint, FLeftArm[0], FLeftArm[1], dfVec2f(CHAR_LIMIT_L * deg2rad, CHAR_LIMIT_H * deg2rad));
    QuickJointInit(FRightArmJoint, FRightArm[0], FRightArm[1], dfVec2f(CHAR_LIMIT_L * deg2rad, CHAR_LIMIT_H * deg2rad));

    //Head-body
    QuickJointInit(FHeadBodyJoint, FHead, FBody[0], dfVec2f(-20 * deg2rad, 20 * deg2rad));
    //leg-body
    QuickJointInit(FLeftLegBodyJoint, FLeftLeg[0], FBody[1], dfVec2f(-30 * deg2rad, 30 * deg2rad));
    QuickJointInit(FRightLegBodyJoint, FRightLeg[0], FBody[1], dfVec2f(-30 * deg2rad, 30 * deg2rad));
    //arm-body
    QuickJointInit(FLeftArmBodyJoint, FLeftArm[0], FBody[0], dfVec2f(-45 * deg2rad, 45 * deg2rad));
    QuickJointInit(FRightArmBodyJoint, FRightArm[0], FBody[0], dfVec2f(-45 * deg2rad, 45 * deg2rad));
  end;
end;

procedure TpdCharacter.Update(const dt: Double);
var
  i: Integer;
begin
  SyncObjects(FHead, FGLHead);
  for i := 0 to 1 do
    SyncObjects(FBody[i], FGLBody[i]);
  for i := 0 to 1 do
  begin
    SyncObjects(FLeftArm[i], FGLLeftArm[i]);
    SyncObjects(FRightArm[i], FGLRightArm[i]);
  end;

  for i := 0 to 1 do
  begin
    SyncObjects(FLeftLeg[i], FGLLeftLeg[i]);
    SyncObjects(FRightLeg[i], FGLRightLeg[i]);
  end;

  if Assigned(FOnControl) then
    FOnControl(dt);
  ApplyCorrection();

  if FArmHitTimeout > 0 then
    FArmHitTimeout := FArmHitTimeout - dt;
end;

{ TglrContactListener }

procedure TglrContactListener.BeginContact(var contact: Tb2Contact);

var
  obj1, obj2: TpdUserData;
  wm: Tb2WorldManifold;
  point, vA, vB: TVector2;
  velocity: Single;
  hit: Byte;

  //0 - голова - плюс к очкам
  //1 - Руки - штраф
  //2 - тело, ноги - пойдет
  function GetBodyPartHitType(bp: TglrBodyPart): Byte;
  begin
    Result := $FF;
    if bp in [bpHead] then
      Result := 0
    else if bp in [bpArmStart, bpArmEnd] then
      Result := 1
    else if bp in [bpBody, bpLegStart, bpLegEnd] then
      Result := 2;
  end;

  procedure MakeHit(Character, Sphere: TpdUserData);
  begin
    if Abs(Velocity) < HIT_THRESHOLD_SPEED then
      Exit;
//    gui.ShowText('Отличный удар!');
    Tweener.AddTweenPSingle(@Character.aObjectSprite.Material.PDiffuse.y,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    Tweener.AddTweenPSingle(@Sphere.aObjectSprite.Material.PDiffuse.y,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    gui.AddScore(5, player.GetHeadPosition() + dfVec2f(0, -10) + dfVec2f(20 - Random(40), 20 - Random(40)));
    sound.PlaySample(sKick);
    (Sphere.aObject as TpdDropObject).aLastBodyPartTouched := Character.aBodyPart;
  end;

  procedure MakeHeadHit(Character, Sphere: TpdUserData);
  begin
    if Abs(Velocity) < HIT_THRESHOLD_SPEED then
      Exit;

//    gui.ShowText('Да, ты туда не только ешь!!');
    Tweener.AddTweenPSingle(@Character.aObjectSprite.Material.PDiffuse.y,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    Tweener.AddTweenPSingle(@Sphere.aObjectSprite.Material.PDiffuse.y,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    gui.AddScore(50, player.GetHeadPosition() + dfVec2f(0, -10) + dfVec2f(20 - Random(40), 20 - Random(40)));
    sound.PlaySample(sKick);
    (Sphere.aObject as TpdDropObject).aLastBodyPartTouched := Character.aBodyPart;
  end;

  procedure MakeArmHit(Character, Sphere: TpdUserData);
  begin
    if (Abs(Velocity) < HIT_THRESHOLD_SPEED) or ((Character.aObject as TpdCharacter).FArmHitTimeout > 0) then
      Exit;

//    gui.ShowText('Так нельзя!');
    Tweener.AddTweenPSingle(@Character.aObjectSprite.Material.PDiffuse.x,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    Tweener.AddTweenPSingle(@Sphere.aObjectSprite.Material.PDiffuse.x,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    gui.AddScore(-50, player.GetHeadPosition() + dfVec2f(0, -10) + dfVec2f(20 - Random(40), 20 - Random(40)));
    Inc(playerFoulsCount);
    sound.PlaySample(sKick);
    (Sphere.aObject as TpdDropObject).aLastBodyPartTouched := Character.aBodyPart;
    (Character.aObject as TpdCharacter).FArmHitTimeout := ARMHIT_TIMEOUT;
  end;

begin
  inherited;
  if contact.m_fixtureA.GetBody.UserData <> nil then
    obj1 := TpdUserData(contact.m_fixtureA.GetBody.UserData^)
  else
    Exit;
  if contact.m_fixtureB.GetBody.UserData <> nil then
    obj2 := TpdUserData(contact.m_fixtureB.GetBody.UserData^)
  else
    Exit;

  contact.GetWorldManifold(wm);
  point := wm.points[0];
  vA := contact.m_fixtureA.GetBody.GetLinearVelocityFromWorldPoint(point);
  vB := contact.m_fixtureB.GetBody.GetLinearVelocityFromWorldPoint(point);
  vB.SubtractBy(vA);
  velocity := b2Dot(vB, wm.normal);

  if obj1.aType = tCharacter then
  begin
    if obj2.aType = tSphere then
    begin
      //character - sphere
      hit := GetBodyPartHitType(obj1.aBodyPart);
      case hit of
        0: MakeHeadHit(obj1, obj2);
        1: MakeArmHit(obj1, obj2);
        2: MakeHit(obj1, obj2);
      end;
    end;
  end
  else if obj2.aType = tCharacter then
  begin
    if obj1.aType = tSphere then
    begin
      //sphere - character
      hit := GetBodyPartHitType(obj2.aBodyPart);
      case hit of
        0: MakeHeadHit(obj2, obj1);
        1: MakeArmHit(obj2, obj1);
        2: MakeHit(obj2, obj1);
      end;
    end;
  end;
end;

end.

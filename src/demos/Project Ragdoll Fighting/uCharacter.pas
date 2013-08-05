unit uCharacter;

interface

uses
  dfHRenderer,
  dfMath,
  UPhysics2D, UPhysics2DTypes, uBox2DImport;

const
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

  CHAR_DENSITY = 0.5;
  CHAR_HEAD_DENSITY = 0.4;
  CHAR_FRICTION = 0.1;
  CHAR_RESTITUTION = 0.7;

  CHAR_LIMIT_L = -45;
  CHAR_LIMIT_H = 45;

  CHAR_CORRECTION_STOP_ON_ANGLE: Single = 2 * 3.1415 / 180;


  CHAR_CONTACT_IMPULSE = 28.0;

  TIME_BETWEEN_BLOCKS = 0.5;


type

  TpdBodyPart = (bpNone, bpHead, bpBody, bpLegStart, bpLegEnd, bpArmStart, bpArmEnd);
  TpdObjectType = (tCharacter, tThrowObject, tEnv, tDeadMeat);

  TpdUserData = record
    aType: TpdObjectType;
    aObject: TObject;
    aObjectSprite: IglrSprite;
    aBodyPart: TpdBodyPart;
  end;

  PpdUserData = ^TpdUserData;

  TglrOnControl = procedure(const dt: Double) of object;
  TpdSimpleCallback = procedure of object;

  TglrCharacterParams = record
    initialPosition: TdfVec2f;
    normalColor: TdfVec4f;
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

    FHealth, FForce: Integer;

    FOnDie: TpdSimpleCallback;

    FIsDead: Boolean;

    FBadThingCountDown: Single;
    FBadBlocks: array[0..1] of Tb2Body;
    FBadJoints: array[0..1] of Tb2RevoluteJoint;
    FGLBadBlocks: array[0..1] of IglrSprite;

    procedure ApplyCorrection(); virtual;


    constructor Create(); virtual;
    procedure SetHealth(const aNewHealth: Integer);
    procedure SetForce(const aNewForce: Integer);
  public
    NormalColor: TdfVec4f;
    ShouldDestroyJoints, ShouldRemoveBad, HasBadThing: Boolean;
    Damage: Integer;

    procedure DestroyAllJoints();
    class function Init(b2w: Tglrb2World; scene2d: Iglr2DScene;
      params: TglrCharacterParams): TpdCharacter; virtual;

    destructor Destroy(); override;

    procedure Update(const dt: Double); virtual;
    procedure ApplyControlImpulse(impulse: TVector2);
    property OnControl: TglrOnControl read FOnControl write FOnControl;
    function GetHeadPosition(): TdfVec2f;
    function GetBodyCenterPosition(): TdfVec2f;

    property Health: Integer read FHealth write SetHealth;
    property Force: Integer read FForce write SetForce;
    property OnDie: TpdSimpleCallback read FOnDie write FOnDie;
    property IsDead: Boolean read FIsDead;

    //Привязываем вес к ногам
    procedure MakeABadThing(aDuration: Single);
    procedure RemoveBadThing();
  end;

  TglrContactListener = class(Tb2ContactListener)
  private
    hit1, hit2: Byte;
    shouldUseImpulse: Boolean;
    lastBlockCountdown, lastHitCountdown: Single;
  protected
    function GetContactVelocity(contact: Tb2Contact): Single;
    function GetContactPoint(contact: Tb2Contact): TdfVec2f;
    procedure ProcessCharToCharCollision(data1, data2: TpdUserData; contact: Tb2Contact);
  public
    procedure BeginContact(var contact: Tb2Contact); override;
    procedure PostSolve(var contact: Tb2Contact; const impulse: Tb2ContactImpulse); override;

    procedure Update(const dt: Single);
  end;

var
  charInternalZ: Integer = 0;

implementation

uses
  dfTweener, uGlobal,
  Windows;


var
  colorHead:     TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorBody:     TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorLeftArm:  TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorRightArm: TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorLeftLeg:  TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorRightLeg: TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);

{ TglrCharacter }

constructor TpdCharacter.Create;
begin
  inherited;
  Health := {$IFDEF DEBUG}10{$ELSE}100{$ENDIF};
  Force := 0;
  FIsDead := False;
  ShouldDestroyJoints := False;
  ShouldRemoveBad := False;
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

  if HasBadThing then
    RemoveBadThing();
  inherited;
end;

procedure TpdCharacter.DestroyAllJoints;
  procedure UpdateUserData(aPointer: Pointer);
  begin
    with PpdUserData(aPointer)^ do
      aType := tDeadMeat;
  end;
begin
  UpdateUserData(FHead.UserData);
  UpdateUserData(FBody[0].UserData);
  UpdateUserData(FBody[1].UserData);
  UpdateUserData(FLeftArm[0].UserData);
  UpdateUserData(FLeftArm[1].UserData);
  UpdateUserData(FRightArm[0].UserData);
  UpdateUserData(FRightArm[1].UserData);
  UpdateUserData(FLeftLeg[0].UserData);
  UpdateUserData(FLeftLeg[1].UserData);
  UpdateUserData(FRightLeg[0].UserData);
  UpdateUserData(FRightLeg[1].UserData);
  b2world.DestroyJoint(FHeadBodyJoint);
  b2world.DestroyJoint(FLeftArmBodyJoint);
  b2world.DestroyJoint(FRightArmBodyJoint);
  b2world.DestroyJoint(FLeftLegBodyJoint);
  b2world.DestroyJoint(FRightLegBodyJoint);
  b2world.DestroyJoint(FBodyJoint);
  b2world.DestroyJoint(FLeftArmJoint);
  b2world.DestroyJoint(FRightArmJoint);
  b2world.DestroyJoint(FLeftLegJoint);
  b2world.DestroyJoint(FRightLegJoint);
end;

function TpdCharacter.GetBodyCenterPosition: TdfVec2f;
begin
  Result := FGLBody[1].Position;
end;

function TpdCharacter.GetHeadPosition: TdfVec2f;
begin
  Result := FGLHead.Position;
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

class function TpdCharacter.Init(b2w: Tglrb2World; scene2d: Iglr2DScene;
  params: TglrCharacterParams): TpdCharacter;

  procedure QuickInit(var aSprite: IglrSprite; var aBody: Tb2Body; aPos: TdfVec2f; aSize: TdfVec2f; aRot: Single;
    color: TdfVec4f; bodyPart: TpdBodyPart; density: Single = -1);
  var
    userdata: ^TpdUserData;
  begin
    aSprite := Factory.NewSprite();
    aSprite.PivotPoint := ppCenter;
    aSprite.Position := aPos;
    aSprite.Width := aSize.x;
    aSprite.Height := aSize.y;
    aSprite.Rotation := aRot;
    aSprite.Z := Z_PLAYER + charInternalZ;
    Inc(charInternalZ);

    aSprite.Material.MaterialOptions.Diffuse := color;
    Result.FScene2D.RegisterElement(aSprite);

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

    NormalColor := params.normalColor;
    colorHead := NormalColor;
    colorBody := NormalColor;
    colorLeftArm := NormalColor;
    colorRightArm := NormalColor;
    colorLeftLeg := NormalColor;
    colorRightLeg := NormalColor;

    //head
    QuickInit(FGLHead, FHead, params.initialPosition, dfVec2f(CHAR_HEAD_SIZE, CHAR_HEAD_SIZE), 0,
      colorHead, bpHead, CHAR_HEAD_DENSITY);

    //body
    for i := 0 to 1 do
      QuickInit(FGLBody[i], FBody[i], params.initialPosition + dfVec2f(0, CHAR_BLOCK_OFFSET * i + (i + 1) * CHAR_BODY_SIZE_Y),
        dfVec2f(CHAR_BODY_SIZE_X, CHAR_BODY_SIZE_Y), 0, colorBody, bpBody);

    //arms
      QuickInit(FGLLeftArm[0], FLeftArm[0], FGLBody[0].Position + dfVec2f(- CHAR_BLOCK_OFFSET * 0 - (1) * CHAR_ARM_SIZE_Y, 0),
        dfVec2f(CHAR_ARM_SIZE_X, CHAR_ARM_SIZE_Y), 90, colorLeftArm, bpArmStart);
      QuickInit(FGLRightArm[0], FRightArm[0], FGLBody[0].Position + dfVec2f(CHAR_BLOCK_OFFSET * 0 + (1) * CHAR_ARM_SIZE_Y, 0),
        dfVec2f(CHAR_ARM_SIZE_X, CHAR_ARM_SIZE_Y), 90, colorRightArm, bpArmStart);

      QuickInit(FGLLeftArm[1], FLeftArm[1], FGLBody[0].Position + dfVec2f(- CHAR_BLOCK_OFFSET * 1 - (2) * CHAR_ARM_SIZE_Y, 0),
        dfVec2f(CHAR_ARM_SIZE_X, CHAR_ARM_SIZE_Y), 90, colorLeftArm, bpArmEnd);
      QuickInit(FGLRightArm[1], FRightArm[1], FGLBody[0].Position + dfVec2f(CHAR_BLOCK_OFFSET * 1 + (2) * CHAR_ARM_SIZE_Y, 0),
        dfVec2f(CHAR_ARM_SIZE_X, CHAR_ARM_SIZE_Y), 90, colorRightArm, bpArmEnd);

    //legs
      QuickInit(FGLLeftLeg[0], FLeftLeg[0],
        FGLBody[1].Position + dfVec2f(-1.5*CHAR_BODY_SIZE_X, 1.5*CHAR_BODY_SIZE_X) + dfVec2f( - (0) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * cos(CHAR_LEG_ANGLE * deg2rad),
                                                                 (0) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * sin(CHAR_LEG_ANGLE * deg2rad)),
        dfVec2f(CHAR_LEG_SIZE_X, CHAR_LEG_SIZE_Y), CHAR_LEG_ANGLE, colorLeftLeg, bpLegStart);
      QuickInit(FGLRightLeg[0], FRightLeg[0],
        FGLBody[1].Position + dfVec2f(1.5*CHAR_BODY_SIZE_X, 1.5*CHAR_BODY_SIZE_X) + dfVec2f((0) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * cos(CHAR_LEG_ANGLE * deg2rad),
                                                              (0) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * sin(CHAR_LEG_ANGLE * deg2rad)),
        dfVec2f(CHAR_LEG_SIZE_X, CHAR_LEG_SIZE_Y), -CHAR_LEG_ANGLE, colorRightLeg, bpLegStart);

      QuickInit(FGLLeftLeg[1], FLeftLeg[1],
        FGLBody[1].Position + dfVec2f(-1.5*CHAR_BODY_SIZE_X, 1.5*CHAR_BODY_SIZE_X) + dfVec2f( - (1) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * cos(CHAR_LEG_ANGLE * deg2rad),
                                                                 (1) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * sin(CHAR_LEG_ANGLE * deg2rad)),
        dfVec2f(CHAR_LEG_SIZE_X, CHAR_LEG_SIZE_Y), CHAR_LEG_ANGLE, colorLeftLeg, bpLegEnd);
      QuickInit(FGLRightLeg[1], FRightLeg[1],
        FGLBody[1].Position + dfVec2f(1.5*CHAR_BODY_SIZE_X, 1.5*CHAR_BODY_SIZE_X) + dfVec2f((1) * (CHAR_LEG_SIZE_Y + CHAR_BLOCK_OFFSET) * cos(CHAR_LEG_ANGLE * deg2rad),
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

procedure TpdCharacter.MakeABadThing(aDuration: Single);

procedure QuickInit(var aSprite: IglrSprite; var aBody: Tb2Body; aPos: TdfVec2f; density: Single);
  var
    userdata: ^TpdUserData;
  begin
    aSprite := Factory.NewSprite();
    aSprite.PivotPoint := ppCenter;
    aSprite.Position := aPos;
    aSprite.Material.Texture := atlasMain.LoadTexture(WEIGHT_TEXTURE);
    aSprite.UpdateTexCoords();
    aSprite.SetSizeToTextureSize();
    aSprite.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1.0);

    aSprite.Z := Z_PLAYER + charInternalZ + 1;
    FScene2D.RegisterElement(aSprite);

    aBody := dfb2InitBox(b2world, aSprite, density, 2.0, 0.1,
      $FFFF, $0008, 8);

    aBody.LinearDamping := 0.2;
    aBody.AngularDamping := 0.1;
    New(userdata);
    userdata^.aType := tEnv;
    userdata^.aObject := Self;
    userdata^.aBodyPart := bpNone;
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
    joint := Tb2RevoluteJoint(b2world.CreateJoint(def));
  end;

var
  vPos: TdfVec2f;

begin
  if (FBadThingCountDown <= 0) and (not HasBadThing) then
  begin
    FBadThingCountDown := aDuration;
    HasBadThing := True;

    vPos := FGLLeftLeg[1].Position + dfVec2f(0, 15);
    vPos.y := Clamp(vPos.y, 0, R.WindowHeight - 30);
    QuickInit(FGLBadBlocks[0], FBadBlocks[0], vPos, 15.0);

    vPos := FGLRightLeg[1].Position + dfVec2f(0, 15);
    vPos.y := Clamp(vPos.y, 0, R.WindowHeight - 30);
    QuickInit(FGLBadBlocks[1], FBadBlocks[1], vPos, 15.0);

    QuickJointInit(FBadJoints[0], FBadBlocks[0], FLeftLeg[1], dfVec2f(-45 * deg2rad, 45 * deg2rad));
    QuickJointInit(FBadJoints[1], FBadBlocks[1], FRightLeg[1], dfVec2f(-45 * deg2rad, 45 * deg2rad));
  end;
end;

procedure TpdCharacter.RemoveBadThing;
begin
  b2world.DestroyJoint(FBadJoints[0]);
  b2world.DestroyJoint(FBadJoints[1]);
  Dispose(FBadBlocks[0].UserData);
  Dispose(FBadBlocks[1].UserData);
  b2world.DestroyBody(FBadBlocks[0]);
  b2world.DestroyBody(FBadBlocks[1]);
  FScene2D.UnregisterElement(FGLBadBlocks[0]);
  FScene2D.UnregisterElement(FGLBadBlocks[1]);
  HasBadThing := False;
end;

procedure TpdCharacter.SetForce(const aNewForce: Integer);
begin
  FForce := Clamp(aNewForce, 0, 100);
end;

procedure TpdCharacter.SetHealth(const aNewHealth: Integer);
begin
  FHealth := Clamp(aNewHealth, 0, 100);
  if (FHealth = 0) and not FIsDead then
  begin
    FIsDead := True;
    ShouldDestroyJoints := True;
    if Assigned(FOnDie) then
      FOnDie();
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

  if not FIsDead then
  begin
    if Assigned(FOnControl) then
      FOnControl(dt);
    ApplyCorrection();
  end;

  if HasBadThing then
  begin
    SyncObjects(FBadBlocks[0], FGLBadBlocks[0]);
    SyncObjects(FBadBlocks[1], FGLBadBlocks[1]);
    if FBadThingCountDown > 0 then
      FBadThingCountDown := FBadThingCountDown - dt
    else
      RemoveBadThing();
  end;
end;

{ TglrContactListener }

procedure TglrContactListener.BeginContact(var contact: Tb2Contact);
var
  obj1, obj2: TpdUserData;
begin
  inherited;
  shouldUseImpulse := False;

  //Get objects
  if contact.m_fixtureA.GetBody.UserData <> nil then
    obj1 := TpdUserData(contact.m_fixtureA.GetBody.UserData^)
  else
    Exit;
  if contact.m_fixtureB.GetBody.UserData <> nil then
    obj2 := TpdUserData(contact.m_fixtureB.GetBody.UserData^)
  else
    Exit;

  if (obj1.aType = tCharacter) and (obj2.aType = tCharacter) then
    ProcessCharToCharCollision(obj1, obj2, contact);

  //*
end;

procedure TglrContactListener.PostSolve(var contact: Tb2Contact; const impulse: Tb2ContactImpulse);
var
  wm: Tb2WorldManifold;
begin
  inherited;
  if shouldUseImpulse then
  begin
    contact.GetWorldManifold(wm);
    with contact.m_fixtureA.GetBody do
      ApplyLinearImpulse(CHAR_CONTACT_IMPULSE * (GetWorldCenter - wm.points[0]), GetWorldCenter);
    with contact.m_fixtureB.GetBody do
      ApplyLinearImpulse(CHAR_CONTACT_IMPULSE * (GetWorldCenter - wm.points[0]), GetWorldCenter);
    shouldUseImpulse := False;
  end;
end;

function TglrContactListener.GetContactPoint(contact: Tb2Contact): TdfVec2f;
var
  wm: Tb2WorldManifold;
begin
  contact.GetWorldManifold(wm);
  Result := ConvertB2ToGL(wm.points[0]) *  (1/C_COEF);
end;

function TglrContactListener.GetContactVelocity(contact: Tb2Contact): Single;
var
  wm: Tb2WorldManifold;
  point, vA, vB: TVector2;
begin
  contact.GetWorldManifold(wm);
  point := wm.points[0];
  vA := contact.m_fixtureA.GetBody.GetLinearVelocityFromWorldPoint(point);
  vB := contact.m_fixtureB.GetBody.GetLinearVelocityFromWorldPoint(point);
  vB.SubtractBy(vA);
  Result := b2Dot(vB, wm.normal);
end;

procedure TglrContactListener.ProcessCharToCharCollision(data1,
  data2: TpdUserData; contact: Tb2Contact);

  //0 - голова
  //1 - кулаки и ступни (чем можно нанести урон)
  //2 - тело, плечи и бедра (можно только получить урон)
  function GetBodyPartHitType(bp: TpdBodyPart): Byte;
  begin
    if bp in [bpHead] then
      Result := 0
    else if bp in [bpLegEnd, bpArmEnd] then
      Result := 1
    else if bp in [bpBody, bpLegStart, bpArmStart] then
      Result := 2;
  end;

  procedure MakeDoubleHit(Character1, Character2: TpdUserData);
  begin
    if lastHitCountdown <= 0 then
    begin
      particles.AddPunch(GetContactPoint(contact));
      lastHitCountdown := TIME_BETWEEN_BLOCKS;
      gui.ShowText('Double Hit!');
      Tweener.AddTweenPSingle(@Character1.aObjectSprite.Material.MaterialOptions.PDiffuse.x,
        tsExpoEaseIn, 0.9, (Character1.aObject as TpdCharacter).NormalColor.x, 2.0, 1.5);
      Tweener.AddTweenPSingle(@Character2.aObjectSprite.Material.MaterialOptions.PDiffuse.x,
        tsExpoEaseIn, 0.9, (Character2.aObject as TpdCharacter).NormalColor.x, 2.0, 1.5);
      with (Character1.aObject as TpdCharacter) do
        Health := Health - (Character2.aObject as TpdCharacter).Damage;
      with (Character2.aObject as TpdCharacter) do
        Health := Health - (Character1.aObject as TpdCharacter).Damage;

      gui.UpdateSliders();
      sound.PlaySample(sPunch2);
    end;
  end;

  procedure MakeHit(Damager, Reciever: TpdUserData);
  begin
    if lastHitCountdown <= 0 then
    begin
      particles.AddPunch(GetContactPoint(contact));
      lastHitCountdown := TIME_BETWEEN_BLOCKS;
      gui.ShowText('Damage!');
      with (Reciever.aObject as TpdCharacter) do
        Health := Health - (Damager.aObject as TpdCharacter).Damage;
      with (Damager.aObject as TpdCharacter) do
        Force := Force + 10;
      Tweener.AddTweenPSingle(@Reciever.aObjectSprite.Material.MaterialOptions.PDiffuse.x,
        tsExpoEaseIn, 0.9, (Reciever.aObject as TpdCharacter).NormalColor.x, 2.0, 1.5);
      gui.UpdateSliders();
      sound.PlaySample(sPunch);
    end;
  end;

  procedure MakeBlock(Character1, Character2: TpdUserData);
  begin
    gui.ShowText('Block!');
    if lastBlockCountdown <= 0 then
    begin
      particles.AddBlock(GetContactPoint(contact));
      lastBlockCountdown := TIME_BETWEEN_BLOCKS;
      sound.PlaySample(sBlock);
    end;
  end;

begin
  shouldUseImpulse := True;
  hit1 := GetBodyPartHitType(data1.aBodyPart);
  hit2 := GetBodyPartHitType(data2.aBodyPart);

  case hit1 of
    0:
      case hit2 of
        0: MakeDoubleHit(data1, data2);
        1: MakeHit(data2, data1);
        2: MakeHit(data1, data2);
      end;
    1:
      if hit2 = 1 then
        MakeBlock(data1, data2)
      else
        MakeHit(data1, data2);
    2:
      if hit2 = 2 then
        MakeBlock(data1, data2)
      else
        MakeHit(data2, data1);
  end;
end;

procedure TglrContactListener.Update(const dt: Single);
begin
  if lastBlockCountdown > 0 then
    lastBlockCountdown := lastBlockCountdown - dt;
  if lastHitCountdown > 0 then
    lastHitCountdown := lastHitCountdown - dt;
end;

end.

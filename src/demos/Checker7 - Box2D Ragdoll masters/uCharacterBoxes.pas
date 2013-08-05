unit uCharacterBoxes;

interface

uses
  dfHRenderer,
  dfMath,
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


type
  TglrOnControl = procedure(const dt: Double) of object;

  TglrCharacterForm = (cfCircle = 0, cfBox = 1);
  TglrCharacterParams = record
    initialPosition: TdfVec2f;
    charForm: TglrCharacterForm;
    charGroup: Integer;
  end;

  TglrBoxCharacter = class
  private
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

    FTex, FTex2: IglrTexture;

    FOnControl: TglrOnControl;

    procedure ApplyCorrection(); virtual;

    constructor Create(); virtual;
  public
    class function Init(b2w: Tglrb2World; scene2d: Iglr2DScene;
      params: TglrCharacterParams): TglrBoxCharacter; virtual;

    destructor Destroy(); override;

    procedure Update(const dt: Double); virtual;
    procedure ApplyControlImpulse(impulse: TVector2);
    property OnControl: TglrOnControl read FOnControl write FOnControl;
  end;

  TglrBodyPart = (bpHead, bpBody, bpLegStart, bpLegEnd, bpArmStart, bpArmEnd);

//const
//  //Число, находящееся на пересечении определяет урон
//  // +1 Урон наносится первому герою
//  // -1 Урон наносится второму герою
//  // 0 блок
//  // 2 - обоюдный урон
//  TglHitTable: array[Low(TglrBodyPart)..High(TglrBodyPart),
//    Low(TglrBodyPart)..High(TglrBodyPart)] of Integer =
//    ((2, -1, 0, 0, 0, 0),
//     (0,  0, 0, 0, 0, 0),
//     (0,  0, 0, 0, 0, 0),
//     (0,  0, 0, 0, 0, 0),
//     (0,  0, 0, 0, 0, 0),
//     (0,  0, 0, 0, 0, 0));

type

  TglrUserData = record
    character: TglrBoxCharacter;
    BodyPart: TglrBodyPart;
    BodyPartSprite: IglrSprite;
  end;

  TglrContactListener = class(Tb2ContactListener)
  public
    procedure BeginContact(var contact: Tb2Contact); override;
  end;

implementation

uses
  uGlobal, dfTweener,
  Windows;


const
  colorHead:     TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorBody:     TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorLeftArm:  TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorRightArm: TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorLeftLeg:  TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);
  colorRightLeg: TdfVec4f = (x: 0.2; y: 0.2; z: 0.2; w: 1);

{ TglrCharacter }

constructor TglrBoxCharacter.Create;
begin
  inherited;
end;

destructor TglrBoxCharacter.Destroy;
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

procedure TglrBoxCharacter.ApplyCorrection;

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
      aJoint.SetMotorSpeed(-1000*aJoint.GetJointAngle());
      aJoint.SetMaxMotorTorque(1000);
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

procedure TglrBoxCharacter.ApplyControlImpulse(impulse: TVector2);
begin
  FHead.ApplyForce(impulse, FHead.GetWorldCenter);
end;

class function TglrBoxCharacter.Init(b2w: Tglrb2World; scene2d: Iglr2DScene; {input: IdfInput;}
  params: TglrCharacterParams): TglrBoxCharacter;

  procedure QuickInit(var aSprite: IglrSprite; var aBody: Tb2Body; aPos: TdfVec2f; aSize: TdfVec2f; aRot: Single;
    color: TdfVec4f; bodyPart: TglrBodyPart; density: Single = -1);
  var
    userdata: ^TglrUserData;
  begin
    aSprite := glrGetObjectFactory().NewSprite();
    aSprite.PivotPoint := ppCenter;
    aSprite.Position := aPos;
    aSprite.Width := aSize.x;
    aSprite.Height := aSize.y;
    aSprite.Rotation := aRot;

    aSprite.Material.MaterialOptions.Diffuse := color;
    Result.FScene2D.RegisterElement(aSprite);

    if density = -1 then
      density := CHAR_DENSITY;
    if bodyPart = bpHead then
    begin
      aBody := dfb2InitCircle(b2w, aSize.x / 2, aPos,
        CHAR_DENSITY, CHAR_FRICTION, CHAR_RESTITUTION,
        $FFFF, $0000 + params.charGroup, -params.charGroup);
      aSprite.Material.Texture := Result.FTex2;
    end
    else
    begin
      aBody := dfb2InitBox(b2w, aPos, aSize, aRot, density, CHAR_FRICTION, CHAR_RESTITUTION,
        $FFFF, $0000 + params.charGroup, -params.charGroup);
      aSprite.Material.Texture := Result.FTex;
    end;

    aBody.LinearDamping := 0.2;
    aBody.AngularDamping := 0.1;
    New(userdata);
    userdata^.character := Result;
    userdata^.BodyPart := bodyPart;
    userdata^.BodyPartSprite := aSprite;
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
  Result := TglrBoxCharacter.Create();
  with Result do
  begin
    //Texture
    FTex := glrGetObjectFactory().NewTexture();
    FTex.Load2D('data/bodypart.tga');
    FTex.BlendingMode := tbmTransparency;
    FTex.CombineMode := tcmModulate;

    FTex2 := glrGetObjectFactory().NewTexture();
    FTex2.Load2D('data/head.tga');
    FTex2.BlendingMode := tbmTransparency;
    FTex2.CombineMode := tcmModulate;

    FScene2D := scene2d;
//    FInput := input;

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

procedure TglrBoxCharacter.Update(const dt: Double);
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
end;

{ TglrContactListener }

procedure TglrContactListener.BeginContact(var contact: Tb2Contact);

var
  char1, char2: TglrUserData;
  hit1, hit2: Byte;

  //0 - голова
  //1 - кулаки и ступни (чем можно нанести урон)
  //2 - тело, плечи и бедра (можно только получить урон)
  function GetBodyPartHitType(bp: TglrBodyPart): Byte;
  begin
    if bp in [bpHead] then
      Result := 0
    else if bp in [bpLegEnd, bpArmEnd] then
      Result := 1
    else if bp in [bpBody, bpLegStart, bpArmStart] then
      Result := 2;
  end;

  procedure MakeDoubleHit(Character1, Character2: TglrUserData);
  begin
    gui.ShowText('Double Hit!');
    Tweener.AddTweenPSingle(@Character1.BodyPartSprite.Material.MaterialOptions.PDiffuse.x,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    Tweener.AddTweenPSingle(@Character2.BodyPartSprite.Material.MaterialOptions.PDiffuse.x,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
  end;

  procedure MakeHit(Damager, Reciever: TglrUserData);
  begin
    gui.ShowText('Damage!');
    Tweener.AddTweenPSingle(@Damager.BodyPartSprite.Material.MaterialOptions.PDiffuse.y,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    Tweener.AddTweenPSingle(@Reciever.BodyPartSprite.Material.MaterialOptions.PDiffuse.x,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
  end;

  procedure MakeBlock(Character1, Character2: TglrUserData);
  begin
    gui.ShowText('Block!');
    Tweener.AddTweenPSingle(@Character1.BodyPartSprite.Material.MaterialOptions.PDiffuse.y,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
    Tweener.AddTweenPSingle(@Character2.BodyPartSprite.Material.MaterialOptions.PDiffuse.y,
      tsExpoEaseIn, 0.9, 0.2, 2.0, 0.5);
  end;

begin
  inherited;
  if contact.m_fixtureA.GetBody.UserData <> nil then
    char1 := TglrUserData(contact.m_fixtureA.GetBody.UserData^)
  else
    Exit;
  if contact.m_fixtureB.GetBody.UserData <> nil then
    char2 := TglrUserData(contact.m_fixtureB.GetBody.UserData^)
  else
    Exit;

  hit1 := GetBodyPartHitType(char1.BodyPart);
  hit2 := GetBodyPartHitType(char2.BodyPart);

  case hit1 of
    0:
      case hit2 of
        0: MakeDoubleHit(char1, char2);
        1: MakeHit(char2, char1);
        2: MakeHit(char1, char2);
      end;
    1:
      if hit2 = 1 then
        MakeBlock(char1, char2)
      else
        MakeHit(char1, char2);
    2:
      if hit2 = 2 then
        MakeBlock(char1, char2)
      else
        MakeHit(char2, char1);
  end;
end;

end.

unit uTrigger;

interface

uses
  glr, glrMath,
  uPhysics2D, uBox2DImport;

type
  TpdTrigger = class;

  TpdOnTrigger = procedure(Trigger: TpdTrigger; Catched: Tb2Fixture) of object;

  TpdTrigger = class
  private
    FActive: Boolean;
    FOnEnter, FOnLeave: TpdOnTrigger;
    function GetPos: TdfVec2f;
    function GetSize: TdfVec2f;
    function GetVisible: Boolean;
    procedure SetPos(const Value: TdfVec2f);
    procedure SetSize(const Value: TdfVec2f);
    procedure SetVisible(const Value: Boolean);
    class function CreateBoxTrigger(aPos: TdfVec2f;  W, H: Single; mask: Word): TpdTrigger;
    class function CreateCircleTrigger(aPos: TdfVec2f; Rad: Single; mask: Word): TpdTrigger;
  public
    Sprite: IglrSprite;
    Body: Tb2Body;

    property Position: TdfVec2f read GetPos write SetPos;
    property Size: TdfVec2f read GetSize write SetSize;
    property Visible: Boolean read GetVisible write SetVisible;
    property OnEnter: TpdOnTrigger read FOnEnter write FOnEnter;
    property OnLeave: TpdOnTrigger read FOnLeave write FOnLeave;

    property IsActive: Boolean read FActive;

    constructor Create();
    destructor Destroy(); override;

    procedure SetTrigger(Active: Boolean; Catched: Tb2Fixture);
  end;

  TpdTriggerFactory = class
  private
    procedure OnBeginContact(var contact: Tb2Contact);
    procedure OnEndContact(var contact: Tb2Contact);
  public
    constructor Create();
    destructor Destroy(); override;

    function AddBoxTrigger(aPos: TdfVec2f;  W, H: Single; mask: Word): TpdTrigger;
    function AddCircleTrigger(aPos: TdfVec2f; Rad: Single; mask: Word): TpdTrigger;
  end;


implementation

uses
  uGlobal;

{ TpdTrigger }

const
  COLOR_INACTIVE: TdfVec4f = (x: 0.3; y: 0.9; z: 0.3; w: 0.3);
  COLOR_ACTIVE:   TdfVec4f = (x: 0.9; y: 0.3; z: 0.3; w: 0.3);

constructor TpdTrigger.Create;
begin
  inherited;
  Sprite := Factory.NewSprite();
  with Sprite do
  begin
    PivotPoint := ppCenter;
    Visible := False;
    Material.Diffuse := COLOR_INACTIVE;
    Material.Texture.BlendingMode := tbmTransparency;
    PPosition.z := 5;
  end;
  mainScene.RootNode.AddChild(Sprite);
end;

class function TpdTrigger.CreateBoxTrigger(aPos: TdfVec2f; W,
  H: Single; mask: Word): TpdTrigger;
var
  f: Tb2Filter;
  userData: PpdUserData;
begin
  Result := TpdTrigger.Create();
  with Result do
  begin
    Sprite.Width := W;
    Sprite.Height := H;
    Sprite.Position2D := aPos;
    Body := glrb2InitBoxSensor(b2world, aPos, dfVec2f(W, H), 0, mask, CAT_SENSOR);
    New(userData);
    userData^.aType := oSensor;
    userData^.aObject := Result;
    Body.UserData := userData;
//    f.categoryBits := CAT_SENSOR;
//    f.maskBits := mask;
//    Body.GetFixtureList.SetFilterData(f);
  end;
end;

class function TpdTrigger.CreateCircleTrigger(aPos: TdfVec2f;
  Rad: Single; mask: Word): TpdTrigger;
var
  f: Tb2Filter;
begin
  Result := TpdTrigger.Create();
  with Result do
  begin
    Sprite.Width := Rad;
    Sprite.Height := Rad;
    Sprite.Position2D := aPos;
    Body := glrb2InitCircleSensor(b2world, aPos, Rad);
    Body.UserData := @Result;
    f.categoryBits := CAT_SENSOR;
    f.maskBits := mask;
    Body.GetFixtureList.SetFilterData(f);
  end;
end;

destructor TpdTrigger.Destroy;
begin
  mainScene.RootNode.RemoveChild(Sprite);
  inherited;
end;

function TpdTrigger.GetPos: TdfVec2f;
begin
  Result := Sprite.Position2D;
end;

function TpdTrigger.GetSize: TdfVec2f;
begin
  Result := dfVec2f(Sprite.Width, Sprite.Height);
end;

function TpdTrigger.GetVisible: Boolean;
begin
  Result := Sprite.Visible;
end;

procedure TpdTrigger.SetPos(const Value: TdfVec2f);
begin
  Sprite.Position2D := Value;
end;

procedure TpdTrigger.SetSize(const Value: TdfVec2f);
begin
  Sprite.Width := Value.x;
  Sprite.Height := Value.y;
end;

procedure TpdTrigger.SetTrigger(Active: Boolean; Catched: Tb2Fixture);
begin
  if Active then
  begin
    Sprite.Material.Diffuse := COLOR_ACTIVE;
    if Assigned(FOnEnter) then
      FOnEnter(Self, Catched);
  end
  else
  begin
    Sprite.Material.Diffuse := COLOR_INACTIVE;
    if Assigned(FOnLeave) then
      FOnLeave(Self, Catched);
  end;

//  if Active and not FActive then
//  begin
//    Sprite.Material.Diffuse := COLOR_ACTIVE;
//    if Assigned(FOnEnter) then
//      FOnEnter(Self, Catched);
//  end
//  else if not Active and FActive then
//  begin
//    Sprite.Material.Diffuse := COLOR_INACTIVE;
//    if Assigned(FOnLeave) then
//      FOnLeave(Self, Catched);
//  end;
  FActive := Active;
end;

procedure TpdTrigger.SetVisible(const Value: Boolean);
begin
  Sprite.Visible := Value;
end;

{ TpdTriggerFactory }

function TpdTriggerFactory.AddBoxTrigger(aPos: TdfVec2f; W, H: Single;
  mask: Word): TpdTrigger;
begin
  Result := TpdTrigger.CreateBoxTrigger(aPos, W, H, mask);
end;

function TpdTriggerFactory.AddCircleTrigger(aPos: TdfVec2f; Rad: Single;
  mask: Word): TpdTrigger;
begin
  Result := TpdTrigger.CreateCircleTrigger(aPos, Rad, mask);
end;

constructor TpdTriggerFactory.Create;
begin
  inherited;
  b2world.AddOnBeginContact(OnBeginContact);
  b2world.AddOnEndContact(OnEndContact);
end;

destructor TpdTriggerFactory.Destroy;
begin
  b2world.RemoveOnBeginContact(OnBeginContact);
  b2world.RemoveOnEndContact(OnEndContact);
  inherited;
end;

procedure TpdTriggerFactory.OnBeginContact(var contact: Tb2Contact);
var
  f1, f2: Tb2Fixture;
  p: TpdUserData;
begin
  f1 := contact.m_fixtureA;
  f2 := contact.m_fixtureB;
  if f1.IsSensor and (not f2.IsSensor) then
  begin
    p := TpdUserData(f1.GetBody.UserData^);
    TpdTrigger(p.aObject).SetTrigger(True, f2);
  end;
  if (not f1.IsSensor) and f2.IsSensor then
  begin
    p := TpdUserData(f2.GetBody.UserData^);
    TpdTrigger(p.aObject).SetTrigger(True, f1);  !!!! //move it to afterupdate
  end;
end;

procedure TpdTriggerFactory.OnEndContact(var contact: Tb2Contact);
var
  f1, f2: Tb2Fixture;
  p: TpdUserData;
begin
  f1 := contact.m_fixtureA;
  f2 := contact.m_fixtureB;
  if f1.IsSensor and (not f2.IsSensor) then
  begin
    p := TpdUserData(f1.GetBody.UserData^);
    TpdTrigger(p.aObject).SetTrigger(False, f2);
  end;
  if (not f1.IsSensor) and f2.IsSensor then
  begin
    p := TpdUserData(f2.GetBody.UserData^);
    TpdTrigger(p.aObject).SetTrigger(False, f1);
  end;
end;

end.

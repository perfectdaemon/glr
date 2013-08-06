unit uBox2DImport;

interface

uses
  glrMath, glr,
  UPhysics2D, UPhysics2DTypes;

const
  //Коэффициент соотношения размеров физических объектов и объектов на экране
  //(для внутренних расчетов)
  //Категорически не рекомендуется изменять без понимания, ЗАЧЕМ
  C_COEF = 1 / 40;

type

  {Класс box2d-мира}

  Tglrb2SimulationEvent = procedure (const FixedDeltaTime: Double);

  Tglrb2World = class(Tb2World)
  private
    FBefore, FAfter: Tglrb2SimulationEvent;
    FStep, FPhysicTime, FSimulationTime: Single;
    FIter: Integer;
  public
    constructor Create(const gravity: TVector2; doSleep: Boolean;
      aStep: Single; aIterations: Integer); reintroduce;

    procedure Update(const DeltaTime: Double);

    property OnAfterSimulation: Tglrb2SimulationEvent read FAfter write FAfter;
    property OnBeforeSimulation: Tglrb2SimulationEvent read FBefore write FBefore;
  end;

  { box2d }

  procedure SyncObjects(b2Body: Tb2Body; renderObject: IglrSprite);
  function ConvertB2ToGL(aVec: TVector2): TdfVec2f;
  function ConvertGLToB2(aVec: TdfVec2f): TVector2;


  function dfb2InitBox(b2World: Tb2World; const aSprite: IglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
  function dfb2InitBox(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
  function dfb2InitCircle(b2World: Tb2World; aRad: Double; aPos: TdfVec2f; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
  function dfb2InitCircle(b2World: Tb2World; const aSprite: IglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;

  function dfb2InitBoxStatic(b2World: Tb2World; const aSprite: IglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
  function dfb2InitBoxStatic(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;

implementation

{ Tdfb2World }

constructor Tglrb2World.Create(const gravity: TVector2; doSleep: Boolean;
  aStep: Single; aIterations: Integer);
begin
  inherited Create(gravity{, doSleep});
  FStep := aStep;
  FIter := aIterations;
end;

procedure Tglrb2World.Update(const DeltaTime: Double);
begin
  FPhysicTime := FPhysicTime + DeltaTime;
  while FSimulationTime <= FPhysicTime do
  begin
    FSimulationTime := FSimulationTime + FStep;

    if Assigned(FBefore) then
      FBefore(FStep);

    Step(FStep, FIter, FIter, False);

    if Assigned(FAfter) then
      FAfter(FStep);
  end;
end;



procedure SyncObjects(b2Body: Tb2Body; renderObject: IglrSprite);
begin
  renderObject.Position := dfVec2f(b2Body.GetPosition.x, b2Body.GetPosition.y) * (1 / C_COEF);
  renderObject.Rotation := b2Body.GetAngle * rad2deg;
end;

function ConvertB2ToGL(aVec: TVector2): TdfVec2f;
begin
  Result := dfVec2f(aVec.x, aVec.y);
end;

function ConvertGLToB2(aVec: TdfVec2f): TVector2;
begin
  Result.SetValue(aVec.x, aVec.y);
end;


function dfb2InitBox(b2World: Tb2World; const aSprite: IglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2PolygonShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2PolygonShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_dynamicBody;
    position := ConvertGLToB2(aSprite.Position * C_COEF);
    angle := aSprite.Rotation * deg2rad;
  end;

  with ShapeDef do
  begin
    SetAsBox(aSprite.Width / 2 * C_COEF, aSprite.Height / 2 * C_COEF);
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(False);
end;
{var
  aCenter: TdfVec2f;
begin
  case aSprite.PivotPoint of
    ppTopLeft: ;
    ppTopRight: ;
    ppBottomLeft: ;
    ppBottomRight: ;
    ppCenter: aCenter := dfVec2f(0, 0);
    ppTopCenter: ;
    ppBottomCenter: ;
    ppCustom: ;
  end;
  Result := dfb2InitBox(b2World, aSprite.Position, dfVec2f(aSprite.Width * 0.5, aSprite.Height * 0.5), aSprite.Rotation, d, f, r, mask, category, group);
end;          }


function dfb2InitBox(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2PolygonShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2PolygonShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_dynamicBody;
    position := ConvertGLToB2(aPos * C_COEF);
    angle := aRot * deg2rad;
  end;

  with ShapeDef do
  begin
    SetAsBox(aSize.x * 0.5 * C_COEF, aSize.y * 0.5 * C_COEF);
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(False);
end;

function dfb2InitCircle(b2World: Tb2World; aRad: Double; aPos: TdfVec2f; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2CircleShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2CircleShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_dynamicBody;
    position := ConvertGLToB2(aPos * C_COEF);
  end;

  with ShapeDef do
  begin
    m_radius := aRad * C_COEF;
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(False);
end;

function dfb2InitCircle(b2World: Tb2World; const aSprite: IglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body;
begin
  Result := dfb2InitCircle(b2World, aSprite.Width / 2, aSprite.Position, d, f, r, mask, Category, group);
end;

function dfb2InitBoxStatic(b2World: Tb2World; const aSprite: IglrSprite; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
begin
  Result := dfb2InitBoxStatic(b2World, aSprite.Position, dfVec2f(aSprite.Width, aSprite.Height), aSprite.Rotation, d, f, r, mask, category, group);
end;

function dfb2InitBoxStatic(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16; group: SmallInt): Tb2Body; overload;
var
  BodyDef: Tb2BodyDef;
  ShapeDef: Tb2PolygonShape;
  FixtureDef: Tb2FixtureDef;
begin
  FixtureDef := Tb2FixtureDef.Create;
  ShapeDef := Tb2PolygonShape.Create;
  BodyDef := Tb2BodyDef.Create;

  with BodyDef do
  begin
    bodyType := b2_staticBody;
    position := ConvertGLToB2(aPos * C_COEF);
    angle := aRot * deg2rad;
  end;

  with ShapeDef do
  begin
    SetAsBox(aSize.x * 0.5 * C_COEF, aSize.y * 0.5 * C_COEF);
  end;

  with FixtureDef do
  begin
    shape := ShapeDef;
    density := d;
    friction := f;
    restitution := r;
    filter.maskBits := mask;
    filter.categoryBits := category;
    filter.groupIndex := group;
  end;

  Result := b2World.CreateBody(BodyDef);
  Result.CreateFixture(FixtureDef);
  Result.SetSleepingAllowed(True);
end;

end.

{
  Юнит для упрощения работы с glRenderer и box2d
}
unit uUtils;

interface

uses
  UPhysics2D, UPhysics2DTypes, uBox2DImport,

  dfHRenderer, dfMath;

{ glRenderer }
function dfNewSpriteWithNode(const aParent: IglrNode): IglrSprite; overload;
function dfNewSpriteWithNode(const aParent: IglrNode; var ResultNode: IglrNode): IglrSprite; overload;
function dfNewSpriteAtScene(const aScene: Iglr2DScene): IglrSprite;
procedure dfLoadSprite(var aSprite: IglrSprite; aFileName: String; aPos: TdfVec2f; aRot: Single);

{ box2d }

//procedure SyncObjects(b2Body: Tb2Body; renderObject: IdfSprite);
//function ConvertB2ToGL(aVec: TVector2): TdfVec2f;
//function ConvertGLToB2(aVec: TdfVec2f): TVector2;

{ box2d + glrenderer}
//function dfb2InitBox(b2World: Tb2World; const aSprite: IdfSprite; d, f, r: Double; mask, category: UInt16): Tb2Body;
//function dfb2InitCircle(b2World: Tb2World; aRad: Double; aPos: TdfVec2f; d, f, r: Double; mask, category: UInt16): Tb2Body; overload;
//function dfb2InitCircle(b2World: Tb2World; const aSprite: IdfSprite; d, f, r: Double; mask, category: UInt16): Tb2Body; overload;
//
//function dfb2InitBoxStatic(b2World: Tb2World; const aSprite: IdfSprite; d, f, r: Double; mask, category: UInt16): Tb2Body; overload;
//function dfb2InitBoxStatic(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16): Tb2Body; overload;

implementation

{$REGION ' [glRenderer ] '}

function dfNewSpriteWithNode(const aParent: IglrNode): IglrSprite;
var
  rNode: IglrNode;
begin
  Result := dfNewSpriteWithNode(aParent, rNode);
  rNode := nil;
end;

function dfNewSpriteWithNode(const aParent: IglrNode; var ResultNode: IglrNode): IglrSprite;
begin
  ResultNode := glrCreateNode(aParent);
  Result := glrGetObjectFactory().NewSprite();
  ResultNode.Renderable := Result;
end;

function dfNewSpriteAtScene(const aScene: Iglr2DScene): IglrSprite;
begin
  Result := glrGetObjectFactory().NewSprite();
  aScene.RegisterElement(Result);
end;

procedure dfLoadSprite(var aSprite: IglrSprite; aFileName: String; aPos: TdfVec2f; aRot: Single);
begin
  with aSprite do
  begin
    Position := aPos;
    PivotPoint := ppCenter;
    Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
    Material.Texture := glrGetObjectFactory().NewTexture();
    Material.Texture.Load2D(aFileName);
    Material.Texture.BlendingMode := tbmTransparency;
    Material.Texture.CombineMode := tcmModulate;
    Width := Material.Texture.Width;
    Height := Material.Texture.Height;
    Rotation := aRot;
  end;
end;

{$ENDREGION}

{$REGION ' [ box2d ] '}

//procedure SyncObjects(b2Body: Tb2Body; renderObject: IdfSprite);
//begin
//  renderObject.Position := dfVec2f(b2Body.GetPosition.x, b2Body.GetPosition.y) * (1 / C_COEF);
//  renderObject.Rotation := b2Body.GetAngle * rad2deg;
//end;
//
//function ConvertB2ToGL(aVec: TVector2): TdfVec2f;
//begin
//  Result := dfVec2f(aVec.x, aVec.y);
//end;
//
//function ConvertGLToB2(aVec: TdfVec2f): TVector2;
//begin
//  Result.SetValue(aVec.x, aVec.y);
//end;

{$ENDREGION}

{$REGION ' [ box2d + glRenderer ] '}

//function dfb2InitBox(b2World: Tb2World; const aSprite: IdfSprite; d, f, r: Double; mask, category: UInt16): Tb2Body;
//var
//  BodyDef: Tb2BodyDef;
//  ShapeDef: Tb2PolygonShape;
//  FixtureDef: Tb2FixtureDef;
//begin
//  FixtureDef := Tb2FixtureDef.Create;
//  ShapeDef := Tb2PolygonShape.Create;
//  BodyDef := Tb2BodyDef.Create;
//
//  with BodyDef do
//  begin
//    bodyType := b2_dynamicBody;
//    position := ConvertGLToB2(aSprite.Position * C_COEF);
//    angle := aSprite.Rotation * deg2rad;
//  end;
//
//  with ShapeDef do
//  begin
//    SetAsBox(aSprite.Width / 2 * C_COEF, aSprite.Height / 2 * C_COEF);
//  end;
//
//  with FixtureDef do
//  begin
//    shape := ShapeDef;
//    density := d;
//    friction := f;
//    restitution := r;
//    filter.maskBits := mask;
//    filter.categoryBits := category;
//  end;
//
//  Result := b2World.CreateBody(BodyDef);
//  Result.CreateFixture(FixtureDef);
//  Result.SetSleepingAllowed(False);
//end;
//
//function dfb2InitCircle(b2World: Tb2World; aRad: Double; aPos: TdfVec2f; d, f, r: Double; mask, category: UInt16): Tb2Body;
//var
//  BodyDef: Tb2BodyDef;
//  ShapeDef: Tb2CircleShape;
//  FixtureDef: Tb2FixtureDef;
//begin
//  FixtureDef := Tb2FixtureDef.Create;
//  ShapeDef := Tb2CircleShape.Create;
//  BodyDef := Tb2BodyDef.Create;
//
//  with BodyDef do
//  begin
//    bodyType := b2_dynamicBody;
//    position := ConvertGLToB2(aPos * C_COEF);
//  end;
//
//  with ShapeDef do
//  begin
//    m_radius := aRad * C_COEF;
//  end;
//
//  with FixtureDef do
//  begin
//    shape := ShapeDef;
//    density := d;
//    friction := f;
//    restitution := r;
//    filter.maskBits := mask;
//    filter.categoryBits := category;
//  end;
//
//  Result := b2World.CreateBody(BodyDef);
//  Result.CreateFixture(FixtureDef);
//  Result.SetSleepingAllowed(False);
//end;
//
//function dfb2InitCircle(b2World: Tb2World; const aSprite: IdfSprite; d, f, r: Double; mask, category: UInt16): Tb2Body;
//begin
//  Result := dfb2InitCircle(b2World, aSprite.Width / 2, aSprite.Position, d, f, r, mask, Category);
//end;
//
//function dfb2InitBoxStatic(b2World: Tb2World; const aSprite: IdfSprite; d, f, r: Double; mask, category: UInt16): Tb2Body; overload;
//begin
//  Result := dfb2InitBoxStatic(b2World, aSprite.Position, dfVec2f(aSprite.Width, aSprite.Height), aSprite.Rotation, d, f, r, mask, category);
//end;
//
//function dfb2InitBoxStatic(b2World: Tb2World; aPos, aSize: TdfVec2f; aRot: Single; d, f, r: Double; mask, category: UInt16): Tb2Body; overload;
//var
//  BodyDef: Tb2BodyDef;
//  ShapeDef: Tb2PolygonShape;
//  FixtureDef: Tb2FixtureDef;
//begin
//  FixtureDef := Tb2FixtureDef.Create;
//  ShapeDef := Tb2PolygonShape.Create;
//  BodyDef := Tb2BodyDef.Create;
//
//  with BodyDef do
//  begin
//    bodyType := b2_staticBody;
//    position := ConvertGLToB2(aPos * C_COEF);
//    angle := aRot * deg2rad;
//  end;
//
//  with ShapeDef do
//  begin
//    SetAsBox(aSize.x * 0.5 * C_COEF, aSize.y * 0.5 * C_COEF);
//  end;
//
//  with FixtureDef do
//  begin
//    shape := ShapeDef;
//    density := d;
//    friction := f;
//    restitution := r;
//    filter.maskBits := mask;
//    filter.categoryBits := category;
//  end;
//
//  Result := b2World.CreateBody(BodyDef);
//  Result.CreateFixture(FixtureDef);
//  Result.SetSleepingAllowed(True);
//end;

{$ENDREGION}

end.

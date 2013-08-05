unit uStaticObjects;

interface

uses
  dfHRenderer, UPhysics2D;

type
  TpdStaticObject = class
    sprite: IglrSprite;
    body: Tb2Body;

    constructor Create();
    destructor Destroy(); override;
  end;

procedure LoadStaticObjects();
procedure InitStaticObjects(aScene: Iglr2DScene);
procedure UpdateStaticObjects(const dt: Double);
procedure FreeStaticObjects();

var
  staticObjects: array of TpdStaticObject;
  dynamicObjects: array of TpdStaticObject;

implementation

uses
  uGlobal,
  uBox2DImport,
  dfMath;

var
  scene: Iglr2DScene;

function InitSprite(): IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.MaterialOptions.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);
  Result.Width := 48;
  Result.Height := 48;
  Result.Z := Z_STATICOBJECTS;
  scene.RegisterElement(Result);
end;

procedure LoadStaticObjects();
begin

end;

procedure InitStaticObjects(aScene: Iglr2DScene);
var
  i: Integer;
begin
  scene := aScene;
  if Length(staticObjects) > 0 then
    for i := 0 to High(staticObjects) do
      staticObjects[i].Free();
  SetLength(staticObjects, 4);
  staticObjects[0] := TpdStaticObject.Create();
  staticObjects[0].sprite.Position := dfVec2f(100, 200);
  staticObjects[0].body := dfb2InitBoxStatic(Phys, staticObjects[0].sprite,
    1.0, 0.5, 0.0, $FFFF, $0002, -1);

  staticObjects[1] := TpdStaticObject.Create();
  staticObjects[1].sprite.Position := dfVec2f(600, 600);
  staticObjects[1].body := dfb2InitBoxStatic(Phys, staticObjects[1].sprite,
    1.0, 0.5, 0.0, $FFFF, $0002, -1);

  staticObjects[2] := TpdStaticObject.Create();
  staticObjects[2].sprite.Position := dfVec2f(500, 300);
  staticObjects[2].body := dfb2InitBoxStatic(Phys, staticObjects[2].sprite,
    1.0, 0.5, 0.0, $FFFF, $0002, -1);

  staticObjects[3] := TpdStaticObject.Create();
  staticObjects[3].sprite.Position := dfVec2f(400, 700);
  staticObjects[3].body := dfb2InitBoxStatic(Phys, staticObjects[3].sprite,
    1.0, 0.5, 0.0, $FFFF, $0002, -1);

  if Length(dynamicObjects) > 0 then
    for i := 0 to High(dynamicObjects) do
      dynamicObjects[i].Free();
  SetLength(dynamicObjects, 4);
  dynamicObjects[0] := TpdStaticObject.Create();
  dynamicObjects[0].sprite.Position := dfVec2f(300, 100);
  dynamicObjects[0].sprite.Material.MaterialOptions.Diffuse := dfVec4f(0.3, 0.5, 0.3, 1.0);
  dynamicObjects[0].body := dfb2InitBox(Phys, dynamicObjects[0].sprite,
    2.0, 0.5, 0.0, $FFFF, $0004, 1);
  dynamicObjects[0].body.AngularDamping := 1.0;
  dynamicObjects[0].body.LinearDamping := 2.0;

  dynamicObjects[1] := TpdStaticObject.Create();
  dynamicObjects[1].sprite.Position := dfVec2f(600, 400);
  dynamicObjects[1].sprite.Material.MaterialOptions.Diffuse := dfVec4f(0.3, 0.5, 0.3, 1.0);
  dynamicObjects[1].body := dfb2InitBox(Phys, dynamicObjects[1].sprite,
    2.0, 0.5, 0.0, $FFFF, $0004, 1);
  dynamicObjects[1].body.AngularDamping := 1.0;
  dynamicObjects[1].body.LinearDamping := 2.0;

  dynamicObjects[2] := TpdStaticObject.Create();
  dynamicObjects[2].sprite.Position := dfVec2f(540, 320);
  dynamicObjects[2].sprite.Material.MaterialOptions.Diffuse := dfVec4f(0.3, 0.5, 0.3, 1.0);
  dynamicObjects[2].body := dfb2InitBox(Phys, dynamicObjects[2].sprite,
    2.0, 0.5, 0.0, $FFFF, $0004, 1);
  dynamicObjects[2].body.AngularDamping := 1.0;
  dynamicObjects[2].body.LinearDamping := 2.0;

  dynamicObjects[3] := TpdStaticObject.Create();
  dynamicObjects[3].sprite.Position := dfVec2f(430, 650);
  dynamicObjects[3].sprite.Material.MaterialOptions.Diffuse := dfVec4f(0.3, 0.5, 0.3, 1.0);
  dynamicObjects[3].body := dfb2InitBox(Phys, dynamicObjects[3].sprite,
    2.0, 0.5, 0.0, $FFFF, $0004, 1);
  dynamicObjects[3].body.AngularDamping := 1.0;
  dynamicObjects[3].body.LinearDamping := 2.0;
end;

procedure UpdateStaticObjects(const dt: Double);
var
  i: Integer;
begin
  for i := 0 to High(dynamicObjects) do
  begin
    SyncObjects(dynamicObjects[i].body, dynamicObjects[i].sprite);
  end;
end;

procedure FreeStaticObjects();
var
  i: Integer;
begin
  if Length(staticObjects) > 0 then
    for i := 0 to High(staticObjects) do
      staticObjects[i].Free();

  if Length(dynamicObjects) > 0 then
    for i := 0 to High(dynamicObjects) do
      dynamicObjects[i].Free();
end;


{ TpdStaticObject }

constructor TpdStaticObject.Create;
begin
  inherited;
  sprite := InitSprite();
  sprite.PivotPoint := ppCenter;
end;

destructor TpdStaticObject.Destroy;
begin
  Phys.DestroyBody(body);
  inherited;
end;

end.

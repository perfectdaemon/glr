unit uLevel;

interface

uses
  glr, glrMath, uPhysics2D;

type
  TpdLevel = class
    Earth: IglrSprite;
    b2Earth: Tb2Body;

    constructor Create();
    destructor Destroy(); override;
  end;

implementation

uses
  uGlobal, uBox2DImport;

{ TpdLevel }

constructor TpdLevel.Create;
begin
  inherited;
  Earth := Factory.NewSprite();
  with Earth do
  begin
    Position := dfVec3f(500, 400, Z_LEVEL);
    Width := 1000;
    Height := 20;
    Material.Diffuse := colorGreen;
    PivotPoint := ppCenter;
  end;
  mainScene.RootNode.AddChild(Earth);

  dfb2InitBoxStatic(b2world, Earth, 1.0, 0.5, 0.2, $FFFF, $0001, 1);
end;

destructor TpdLevel.Destroy;
begin
  mainScene.RootNode.RemoveChild(Earth);
  inherited;
end;

end.

unit uArrow;

interface

uses
  glr, glrMath;

type
  TpdArrow = class
  private
  public
    Sprite: IglrSprite;
    MoveDir: TdfVec2f;
    StartPos: TdfVec2f;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);
  end;

implementation

uses
  uGlobal;

{ TpdArrow }

constructor TpdArrow.Create;
begin
  inherited;
  Sprite := Factory.NewSprite();
  with Sprite do
  begin
    Position := dfVec3f(0, 0, Z_PLAYER);
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(ARROW_TEXTURE);
    Material.Diffuse := colorWhite;
    UpdateTexCoords();
    SetSizeToTextureSize();
    Rotation := -90;
  end;

  moveDir := dfVec2f(0, -10);

  mainScene.RootNode.AddChild(Sprite);
end;

destructor TpdArrow.Destroy;
begin

  mainScene.RootNode.RemoveChild(Sprite);
  inherited;
end;

procedure TpdArrow.Update(const dt: Double);
begin
  Sprite.Position2D := Sprite.Position2D + (MoveDir * dt);
  Sprite.Rotation := MoveDir.GetRotationAngle();
end;

end.

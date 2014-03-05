unit uShip;

interface

uses
  glr, glrMath;

const
  VELOCITY_MAX = 1000;
  ACCEL = 400;

type
  TpdShip = class
  protected
    procedure Control(const dt: Double); virtual; abstract;
  public
    Enabled: Boolean;
    Body, Flame: IglrSprite;

    Velocity: TdfVec2f;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double); virtual;
  end;


  TpdPlayer = class (TpdShip)
  protected
    procedure Control(const dt: Double); override;
  public
    constructor Create(); override;
  end;

implementation

uses
  uGlobal;

{ TpdShip }

constructor TpdShip.Create;
begin
  inherited;
  Enabled := True;
  Body := Factory.NewSprite();
  Flame := Factory.NewSprite();

  with Body do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(SHIP_TEXTURE);
    Material.Diffuse := scolorWhite;
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec3f(0, 0, Z_PLAYER);
    AddChild(Flame);
  end;

  with Flame do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(FLAME_TEXTURE);
    Material.Diffuse := scolorWhite;
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec3f(0, 45, Z_PLAYER - 1);

    Visible := False;
  end;

  mainScene.RootNode.AddChild(Body);
end;

destructor TpdShip.Destroy;
begin
  mainScene.RootNode.RemoveChild(Body);
  inherited;
end;

procedure TpdShip.Update(const dt: Double);
begin
  if Enabled then
    Control(dt);
end;

{ TpdPlayer }

procedure TpdPlayer.Control(const dt: Double);
begin
  Body.Rotation := LerpAngles(Body.Rotation, (uGlobal.mousePosAtScene - Body.Position2D).GetRotationAngle(), 0.1);

  if R.Input.IsKeyDown(VK_W) then
    Velocity := Velocity + dfVec2f(Body.Rotation - 90) * dt * ACCEL;

  with R.Input do
    Flame.Visible := IsKeyDown(VK_W) or IsKeyDown(VK_S) or IsKeyDown(VK_D) or IsKeyDown(VK_A);

  Velocity := Velocity.Clamp(0, VELOCITY_MAX);

  Body.Position2D := Body.Position2D + Velocity * dt;
end;

constructor TpdPlayer.Create;
begin
  inherited;
  Body.Material.Diffuse := scolorBlue;
end;

end.

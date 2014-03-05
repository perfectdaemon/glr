unit uShip;

interface

uses
  glr, glrMath;

const
  VELOCITY_MAX = 400;
  ACCEL = 300;

  NOT_NEWTON_SPEED_FADE = 0.5;
  HANDBRAKE_SPEED_FADE = 1.0;

type
  TpdShip = class
  protected
    procedure Control(const dt: Double); virtual; abstract;
  public
    Enabled: Boolean;
    FixedPosition: Boolean;
    Body, Flame: IglrSprite;
    Direction, Left: TdfVec2f;

    Velocity: TdfVec2f;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double); virtual;

    procedure FireBlaster();
    procedure FireLaserBeam();
  end;


  TpdPlayer = class (TpdShip)
  protected
    procedure Control(const dt: Double); override;
  public
    constructor Create(); override;
  end;

  TpdEnemyTurret = class (TpdShip)
  protected
    procedure Control(const dt: Double); override;
  public
    constructor Create(); override;
  end;

implementation

uses
  Windows,
  uProjectiles,
  uGlobal;

{ TpdShip }

constructor TpdShip.Create;
begin
  inherited;
  Enabled := True;
  FixedPosition := False;
  Body := Factory.NewSprite();
  Flame := Factory.NewSprite();

  with Body do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(SHIP_TEXTURE);
    Material.Diffuse := scolorWhite;
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec3f(0, 0, 0);
    AddChild(Flame);
  end;

  with Flame do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(FLAME_TEXTURE);
    Material.Diffuse := scolorWhite;
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec3f(0, 45, -1);

    Visible := False;
  end;

  mainScene.RootNode.AddChild(Body);
end;

destructor TpdShip.Destroy;
begin
  mainScene.RootNode.RemoveChild(Body);
  inherited;
end;

procedure TpdShip.FireBlaster;
begin
  with projectiles.GetItem() do
  begin
    SetType(ptLaserBullet);
    InitialPosition := Body.Position2D;
    Sprite.Position2D := InitialPosition;
    Velocity := Direction * LASER_BULLET_VELOCITY_MAGNITUDE;
    Sprite.Rotation := Direction.GetRotationAngle();
  end;
end;

procedure TpdShip.FireLaserBeam;
begin
  with projectiles.GetItem() do
  begin
    SetType(ptLaserBeam);
    InitialPosition := Body.Position2D;
    Sprite.Position2D := InitialPosition;
//    Velocity := Direction * LASER_BULLET_VELOCITY_MAGNITUDE;
    Sprite.Rotation := Direction.GetRotationAngle();
  end;
end;

procedure TpdShip.Update(const dt: Double);
begin
  if not Enabled then
    Exit();

  Control(dt);

  Direction := dfVec2f(Body.Rotation - 90);
  Left := dfVec2f(Direction.y, -Direction.x);

  if not FixedPosition then
  begin
    Velocity := Velocity.Clamp(0, VELOCITY_MAX);
    Body.Position2D := Body.Position2D + Velocity * dt;
  end;
end;

{ TpdPlayer }

procedure TpdPlayer.Control(const dt: Double);
begin
  Body.Rotation := LerpAngles(Body.Rotation, (uGlobal.mousePosAtScene - Body.Position2D).GetRotationAngle(), dt * 10);

  if R.Input.IsKeyDown(VK_W) then
    Velocity := Velocity + Direction * dt * ACCEL
  else if R.Input.IsKeyDown(VK_S) then
    Velocity := Velocity - Direction * dt * ACCEL;
  if R.Input.IsKeyDown(VK_D) then
    Velocity := Velocity - Left * dt * ACCEL
  else if R.Input.IsKeyDown(VK_A) then
    Velocity := Velocity + Left * dt * ACCEL;

  if R.Input.IsKeyDown(VK_SPACE) then
    Velocity := Velocity * (1 - HANDBRAKE_SPEED_FADE * dt);

  with R.Input do
    Flame.Visible := IsKeyDown(VK_W) or IsKeyDown(VK_S) or IsKeyDown(VK_D) or IsKeyDown(VK_A);

  if not UseNewtonDynamics and not Flame.Visible then
    Velocity := Velocity * (1 - NOT_NEWTON_SPEED_FADE * dt);
end;

constructor TpdPlayer.Create;
begin
  inherited;
  Body.Material.Diffuse := scolorBlue;
end;

{ TpdEnemyTurret }

procedure TpdEnemyTurret.Control(const dt: Double);
begin
  Body.Rotation := LerpAngles(Body.Rotation, (uGlobal.player.Body.Position2D - Body.Position2D).GetRotationAngle(), dt * 1);
end;

constructor TpdEnemyTurret.Create;
begin
  inherited;
  FixedPosition := True;
  Body.Material.Diffuse := scolorRed;
  Body.PPosition.z := Z_ENEMY;
end;

end.

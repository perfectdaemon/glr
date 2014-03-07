unit uShip;

interface

uses
  glr, glrMath;

const
  VELOCITY_MAX = 400;
  ACCEL = 300;

  NOT_NEWTON_SPEED_FADE = 0.5;
  HANDBRAKE_SPEED_FADE = 1.0;
  EXHAUST_PARTICLES_TIMEOUT = 0.1;

type
  TpdShip = class
  protected
    tExhaustParticles1, tExhaustParticles2: Single;
    ForwardMovement, SideMovement: ShortInt;
    procedure Control(const dt: Double); virtual; abstract;
  public
    Enabled: Boolean;
    FixedPosition: Boolean;
    Body, FlameForward, FlameSide: IglrSprite;
    Direction, Left: TdfVec2f;

    Velocity: TdfVec2f;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double); virtual;

    procedure FireBlaster();
    procedure FireLaserBeam();
    procedure FireRocket(aTarget: TpdShip);
  end;


  TpdPlayer = class (TpdShip)
  protected
    procedure Control(const dt: Double); override;
  public
    constructor Create(); override;
  end;

  TpdEnemyTurret = class (TpdShip)
  protected
    cooldown: Single;
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
  FlameForward := Factory.NewSprite();
  FlameSide := Factory.NewSprite();

  with Body do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(SHIP_TEXTURE);
    Material.Diffuse := scolorWhite;
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec3f(0, 0, 0);
    AddChild(FlameForward);
    AddChild(FlameSide);
  end;

  with FlameForward do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(FLAME_TEXTURE);
    Material.Diffuse := scolorWhite;
//    Material.PDiffuse.w := 0.7;
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec3f(-45, 0, -1);

    Visible := False;
  end;

  with FlameSide do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(FLAME_TEXTURE);
    Material.Diffuse := scolorWhite;
//    Material.PDiffuse.w := 0.7;
    UpdateTexCoords();
    SetSizeToTextureSize();
    Position := dfVec3f(-15, 55, -1);
    Rotation := 90;

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
    ProjectileType := ptLaserBullet;
    InitialPosition := Body.Position2D;
    Velocity := Direction * LASER_BULLET_VELOCITY_MAGNITUDE;
    FromShip := Self;
  end;
end;

procedure TpdShip.FireLaserBeam;
begin
  with projectiles.GetItem() do
  begin
    ProjectileType := ptLaserBeam;
    InitialPosition := Body.Position2D;
    Velocity := Direction * LASER_BULLET_VELOCITY_MAGNITUDE;
    FromShip := Self;
  end;
end;

procedure TpdShip.FireRocket(aTarget: TpdShip);
begin
  if Assigned(aTarget) then
    with projectiles.GetItem() do
    begin
      ProjectileType := ptRocket;
      Target := aTarget;
      InitialPosition := Body.Position2D;
      Velocity := (aTarget.Body.Position2D - Body.Position2D).Normal * ROCKET_VELOCITY_MAGNITUDE;
      FromShip := Self;
    end;
end;

procedure TpdShip.Update(const dt: Double);
begin
  if not Enabled then
    Exit();

  ForwardMovement := 0;
  SideMovement := 0;

  Control(dt);

  Direction := dfVec2f(Body.Rotation);
  Left := dfVec2f(Direction.y, -Direction.x);

  if not FixedPosition then
  begin
    FlameForward.Visible := ForwardMovement <> 0;
    FlameSide.Visible := SideMovement <> 0;

    FlameForward.PPosition.x := -45 * ForwardMovement;
    if ForwardMovement > 0 then
      FlameForward.Rotation := 0
    else
      FlameForward.Rotation := 180;
    FlameSide.PPosition.y := 55 * SideMovement;
    if SideMovement < 0 then
      FlameSide.Rotation := 90
    else
      FlameSide.Rotation := 270;

    tExhaustParticles1 := tExhaustParticles1 - dt;
    tExhaustParticles2 := tExhaustParticles2 - dt;
    if (ForwardMovement <> 0) and (tExhaustParticles1 <= 0) then
    begin
      tExhaustParticles1 := EXHAUST_PARTICLES_TIMEOUT;
      particles.AddEngineExhaust(dfVec2f(Body.ModelMatrix * FlameForward.Position), Direction * ForwardMovement);
    end;

    if (SideMovement <> 0) and (tExhaustParticles2 <= 0) then
    begin
      tExhaustParticles2 := EXHAUST_PARTICLES_TIMEOUT;
      particles.AddEngineExhaust(dfVec2f(Body.ModelMatrix * FlameSide.Position), Left * SideMovement);
    end;

    if not UseNewtonDynamics and (ForwardMovement = 0) and (SideMovement = 0) then
      Velocity := Velocity * (1 - NOT_NEWTON_SPEED_FADE * dt);


    Velocity := Velocity
      + Direction * ForwardMovement * dt * ACCEL
      + Left * SideMovement * dt * ACCEL;

    Velocity := Velocity.Clamp(0, VELOCITY_MAX);
    if Velocity.LengthQ > sqr(1) then
      Body.Position2D := Body.Position2D + Velocity * dt;
  end;
end;

{ TpdPlayer }

procedure TpdPlayer.Control(const dt: Double);
begin
  Body.Rotation := LerpAngles(Body.Rotation, (uGlobal.mousePosAtScene - Body.Position2D).GetRotationAngle(), dt * 10);

  if R.Input.IsKeyDown(VK_W) then
    ForwardMovement := 1
  else if R.Input.IsKeyDown(VK_S) then
    ForwardMovement := -1;
  if R.Input.IsKeyDown(VK_D) then
    SideMovement := -1
  else if R.Input.IsKeyDown(VK_A) then
    SideMovement := 1;

  if R.Input.IsKeyDown(VK_SPACE) then
    Velocity := Velocity * (1 - HANDBRAKE_SPEED_FADE * dt);
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
  cooldown := cooldown - dt;
  if cooldown <= 0 then
  begin
    FireRocket(player);
    cooldown := 5 + Random(2);
  end;
end;

constructor TpdEnemyTurret.Create;
begin
  inherited;
  FixedPosition := True;
  Body.Material.Diffuse := scolorRed;
  Body.PPosition.z := Z_ENEMY;
  cooldown := 4;
end;

end.

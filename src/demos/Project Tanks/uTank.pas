unit uTank;

interface

uses
  dfHRenderer, dfMath;

const
  BODY_SIZE_X   = 32;
  BODY_SIZE_Y   = 12;
  TOWER_SIZE_X   = 16;
  TOWER_SIZE_Y   = 8;
  BARREL_SIZE_X = 20;
  BARREL_SIZE_Y = 6;

  BARREL_MIN_ANGLE = -180;
  BARREL_MAX_ANGLE = 0;
  BARREL_CHANGE_SPEED = 25;
  SHOT_MIN_POWER   = 30;
  SHOT_MAX_POWER   = 200;
  SHOT_CHANGE_SPEED = 30;

  ENEMY_TIME_WAIT = 2.0;


type
  TpdTank = class
  protected
    bulletMoveVec: TdfVec2f;
    constructor Create(); virtual;
    destructor Destroy(); override;
  public
    health: Single; //0..1;
    bullet: IglrSprite;
    tileX, tileY: Integer;
    tileID: Byte;
    power: Single;
    body, tower, barrel: IglrSprite;
    readyForShot: Boolean;

    onDie: procedure;
    class function Initialize(aScene: Iglr2DScene): TpdTank; virtual; abstract;
    procedure SetPosition(aTileX, aTileY: Integer; aSpritePos: Boolean = True); virtual;
    procedure ChangePower(aDelta: Single);
    procedure ChangeBarrelAngle(aDelta: Single);
    procedure Shot();

    procedure Update(const dt: Double); virtual;
    procedure CheckForFall();
    procedure DecreaseHealth(aDelta: Single); virtual;
  end;

  TpdPlayerTank = class (TpdTank)
  public
    class function Initialize(aScene: Iglr2DScene): TpdTank; override;

    procedure DecreaseHealth(aDelta: Single); override;
  end;

  TpdEnemyTank = class (TpdTank)
  private
    Ft: Single;
    FIsParamsSet: Boolean;
    FNeedAngle: Single;
  public
    class function Initialize(aScene: Iglr2DScene): TpdTank; override;
    procedure DecreaseHealth(aDelta: Single); override;

    procedure Update(const dt: Double); override;

    procedure AISetParams();
  end;

implementation

uses
  SysUtils,
  dfTweener,
  uEarth, uGlobal;

{ TpdTank }

procedure MoveTankDown(aTank: TdfTweenObject; Value: Single);
begin
  with aTank as TpdTank do
  begin
    body.PPosition.y := Value + TILE_SIZE;
    tower.PPosition.y := body.Position.y - BODY_SIZE_Y;
    barrel.PPosition.y := body.Position.y - BODY_SIZE_Y div 2 - TOWER_SIZE_Y;
  end;
end;

{
function DanBallistics(const PosOrigin, PosTarget: TdfVec2f;
  const TotalVelocity, Gravity: Single;
  var Trajectory0, Trajectory1: TdfVec2f;
  var Time0, Time1: Single): Boolean;

var
  x, y, x2, vt2, vt4,
  gr, gr2, dc, n0, n1, t2, t, vx, vy: Double;
begin
  x := PosTarget.x - PosOrigin.x;
  x2 := x * x;
  y := PosTarget.y - PosOrigin.y;
  vt2 := TotalVelocity * TotalVelocity;
  vt4 := vt2 * vt2;
  gr := Gravity;
  gr2 := gr * gr;
  dc := 16 * (2 * vt2 * y * gr + vt4 - x2 * gr2);
  if dc > 0 then
  begin
    dc := Sqrt(dc);
    n0 := 4 * vt2 + 4 * y * gr;
    n1 := 1 / (2 * gr2);
    t2 := (n0 - dc) * n1;
    if t2 >= 0 then
    begin
      t := Sqrt(t2);
      vx := x / t;
      vy := (2 * y - gr * t2) / (2 * t);
      vx := Sqrt(vt2 - vy * vy);
      if (x < 0) <> (vx < 0) then
        vx := -vx;
      Trajectory0.x := vx;
      Trajectory0.y := vy;
      if Trajectory0.Length > TotalVelocity then
        Trajectory0 := Trajectory0.Normal * TotalVelocity;
      Time0 := t;
    end
    else
    begin
      Trajectory0 := dfVec2f(0, 0);
      Time0 := 0;
      Result := False;
      Exit;
    end;
    t2 := (n0 + dc) * n1;
    if t2 >= 0 then
    begin
      t := Sqrt(t2);
      vx := x / t;
      vy := (2 * y - gr * t2) / (2 * t);
      Trajectory1.x := vx;
      Trajectory1.y := vy;
      if Trajectory1.Length > TotalVelocity then
        Trajectory1 := Trajectory1.Normal * TotalVelocity;
      Time1 := t;
    end
    else
    begin
      Trajectory1 := dfVec2f(0, 0);
      Time1 := 0;
      Result := False;
      Exit;
    end;
    Result := True;
  end
  else
  begin
    Trajectory0 := dfVec2f(0, 0);
    Trajectory1 := dfVec2f(0, 0);
    Time0 := 0;
    Time1 := 0;
    Result := False;
  end;
end;

}

procedure TpdTank.ChangeBarrelAngle(aDelta: Single);
begin
  barrel.Rotation := Clamp(barrel.Rotation + aDelta, BARREL_MIN_ANGLE, BARREL_MAX_ANGLE);
end;

procedure TpdTank.ChangePower(aDelta: Single);
begin
  power := Clamp(power + aDelta, SHOT_MIN_POWER, SHOT_MAX_POWER);
end;

procedure TpdTank.CheckForFall;
var
  i: Integer;
begin
  for i := tileY + 1 to TILES_Y - 1 do
    if (earth.tiles[tileX, i] = TILE_EARTH) or (earth.tiles[tileX + 1, i] = TILE_EARTH) then
      Break;
  if i = tileY + 1 then
    Exit()
  else
  begin
    Tweener.AddTweenSingle(Self, @MoveTankDown, tsSimple, tileY * TILE_SIZE, (i-1) * TILE_SIZE, 0.5, 0.0);
    SetPosition(tileX, i-1, False);
  end;
end;

constructor TpdTank.Create;
begin
  inherited;
  body := Factory.NewSprite();
  body.Width := BODY_SIZE_X;
  body.Height := BODY_SIZE_Y;
  body.PivotPoint := ppBottomLeft;
  body.Z := Z_TANK;

  tower := Factory.NewSprite();
  tower.Width := TOWER_SIZE_X;
  tower.Height := TOWER_SIZE_Y;
  tower.PivotPoint := ppBottomCenter;
  tower.Z := Z_TANK + 1;

  barrel := Factory.NewSprite();
  barrel.Width := BARREL_SIZE_X;
  barrel.Height := BARREL_SIZE_Y;
  barrel.SetCustomPivotPoint(0, 0.5);
  barrel.PivotPoint := ppCustom;
  barrel.Rotation := -35;
  barrel.Z := Z_TANK;

  bullet := Factory.NewSprite();
  bullet.Width := 5;
  bullet.Height := 5;
  bullet.PivotPoint := ppCenter;
  bullet.Visible := False;
  bullet.Z := Z_TANK - 1;

  health := 1;

  power := (SHOT_MAX_POWER - SHOT_MIN_POWER) / 2;
  readyForShot := True;
  bulletMoveVec.Reset();
end;

procedure TpdTank.DecreaseHealth(aDelta: Single);
begin
  if (health - aDelta) < 0 then
    OnDie();
  health := Clamp(health - aDelta, 0, 1.0);
end;

destructor TpdTank.Destroy;
begin

  inherited;
end;

procedure TpdTank.SetPosition(aTileX, aTileY: Integer; aSpritePos: Boolean = True);
begin
  earth.tiles[tileX, tileY] := TILE_EMPTY;
  earth.tiles[tileX + 1, tileY] := TILE_EMPTY;
  tileX := Clamp(aTileX, 0, TILES_X - 2);
  tileY := Clamp(aTileY, 0, TILES_Y - 1);
  if aSpritePos then
  begin
    body.Position := TilePosToRealPos(tileX, tileY) + dfVec2f(0, TILE_SIZE);
    tower.Position := body.Position + dfVec2f(BODY_SIZE_X div 2, -BODY_SIZE_Y);
    barrel.Position := body.Position + dfVec2f(BODY_SIZE_X div 2, - BODY_SIZE_Y div 2 - TOWER_SIZE_Y);
  end;
  earth.tiles[tileX, tileY] := tileID;
  earth.tiles[tileX + 1, tileY] := tileID;
end;

procedure TpdTank.Shot;
begin
  readyForShot := False;
  bullet.Position := tower.Position;
  bullet.Visible := True;
  bulletMoveVec := dfVec2f(cos(-barrel.Rotation * deg2rad), sin(barrel.Rotation * deg2rad)) * power;
  sound.PlaySample(soundShot);
  SwitchTurn(TURN_WAIT);
end;

procedure TpdTank.Update(const dt: Double);
var
  tX, tY: Integer;
begin
  if not readyForShot then
  begin
    bullet.Position := bullet.Position + bulletMoveVec * dt * 5;
    bulletMoveVec := bulletMoveVec + dfVec2f(0, GRAVITY);

    with bullet.Position do
      if (x < 0) or (x > R.WindowWidth) or (y > R.WindowHeight) then
      begin
        readyForShot := True;
        bulletMoveVec.Reset();
        bullet.Visible := False;
        if Self is TpdPlayerTank then
          SwitchTurn(TURN_ENEMY)
        else if Self is TpdEnemyTank then
          SwitchTurn(TURN_PLAYER);
      end
      else
      begin
        RealPosToTilePos(bullet.Position, tX, tY);
        if ((tX = tileX) or (tX = tileX + 1)) and (tY = tileY) then
          Exit();
        if ty < 0 then
          Exit();
        if (earth.tiles[tX, tY] <> TILE_EMPTY) or (ty = TILES_Y - 1) then
        begin
          earth.BombAt(tX, tY, 2);
          readyForShot := True;
          bulletMoveVec.Reset();
          bullet.Visible := False;
          if Self is TpdPlayerTank then
            SwitchTurn(TURN_ENEMY)
          else if Self is TpdEnemyTank then
            SwitchTurn(TURN_PLAYER);
        end;
      end;
  end;
end;

{ TpdPlayerTank }

procedure TpdPlayerTank.DecreaseHealth(aDelta: Single);
begin
  inherited;
  body.Material.MaterialOptions.Diffuse := health * colorPlayer;
  barrel.Material.MaterialOptions.Diffuse := health * colorPlayer;
  tower.Material.MaterialOptions.Diffuse := health * colorPlayer;
end;

class function TpdPlayerTank.Initialize(aScene: Iglr2DScene): TpdTank;
begin
  Result := TpdPlayerTank.Create();
  with Result do
  begin
    body.Material.MaterialOptions.Diffuse := colorPlayer;
    tower.Material.MaterialOptions.Diffuse := colorPlayer;
    barrel.Material.MaterialOptions.Diffuse := colorPlayer;
    bullet.Material.MaterialOptions.Diffuse := colorBullet;

    tileID := TILE_PLAYER;

    aScene.RegisterElement(body);
    aScene.RegisterElement(tower);
    aScene.RegisterElement(barrel);
    aScene.RegisterElement(bullet);
  end;
end;

{ TpdEnemyTank }

procedure Rotate(aTank: TdfTweenObject; aValue: Single);
begin
  with aTank as TpdTank do
    barrel.Rotation := aValue;
end;

procedure TpdEnemyTank.AISetParams;

  procedure GetHighestTileBetween(var tX, tY: Integer);
  var
    i, j: Integer;
  begin
    tY := TILES_Y - 1;
    for i := tileX downto tileX - 15 do
      for j := 0 to TILES_Y - 1 do
        if earth.tiles[i, j] = TILE_EARTH then
        begin
          if j < tY then
          begin
            tY := j;
            tX := i;
          end;
          break;
        end;
  end;

var
  hX, hY: Integer;
  hPos: TdfVec2f;
  hDist: Single;
begin
  if FIsParamsSet then
    Exit();
  GetHighestTileBetween(hX, hY);
  if ((tileY - hY) > 4) then
  begin
    hPos := TilePosToRealPos(hX, hY - 5);
    hDist := hPos.Dist(Self.body.Position);
    power := Clamp(hDist * 0.45 + (tileY - hy) * 0.2 + Random(10), SHOT_MIN_POWER, SHOT_MAX_POWER);
  end
  else
  begin
    hPos := TilePosToRealPos(player.tileX, player.tileY);
    hDist := hPos.Dist(Self.body.Position);
    power := Clamp(hDist * 0.7 + Random(15), SHOT_MIN_POWER, SHOT_MAX_POWER);
  end;
  FNeedAngle := -90 + (hPos - Self.body.Position).Normal().GetRotationAngle() - Random(15);
  FNeedAngle := Clamp(FNeedAngle, BARREL_MIN_ANGLE, BARREL_MAX_ANGLE);
  Tweener.AddTweenSingle(Self, @Rotate, tsSimple, barrel.Rotation, FNeedAngle, 1.0);
  Ft := ENEMY_TIME_WAIT;
  FIsParamsSet := True;
end;

procedure TpdEnemyTank.DecreaseHealth(aDelta: Single);
begin
  inherited;
  body.Material.MaterialOptions.Diffuse := health * colorEnemy;
  barrel.Material.MaterialOptions.Diffuse := health * colorEnemy;
  tower.Material.MaterialOptions.Diffuse := health * colorEnemy;
end;

class function TpdEnemyTank.Initialize(aScene: Iglr2DScene): TpdTank;
begin
  Result := TpdEnemyTank.Create();
  with Result do
  begin
    body.Material.MaterialOptions.Diffuse := colorEnemy;
    tower.Material.MaterialOptions.Diffuse := colorEnemy;
    barrel.Material.MaterialOptions.Diffuse := colorEnemy;
    bullet.Material.MaterialOptions.Diffuse := colorEnemy;

    barrel.Rotation := -180 + 35;

    tileID := TILE_ENEMY;

    aScene.RegisterElement(body);
    aScene.RegisterElement(tower);
    aScene.RegisterElement(barrel);
    aScene.RegisterElement(bullet);
  end;
end;

procedure TpdEnemyTank.Update(const dt: Double);
begin
  inherited;
  if (turn = TURN_ENEMY) and FIsParamsSet then
  begin
    Ft := Ft - dt;
    if Ft < 0 then
    begin
      Shot();
      FIsParamsSet := False;
    end;
  end;
end;

end.

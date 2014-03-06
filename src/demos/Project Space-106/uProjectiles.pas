unit uProjectiles;

interface

uses
  glr, glrMath, uShip,
  uAccum;

const
  LASER_BULLET_RANGE = 800;
  LASER_BULLET_VELOCITY_MAGNITUDE = 600;
  LASER_BEAM_TIME = 0.7;
  LASER_BEAM_RANGE = 550;

type
  TpdProjectileType = (ptLaserBullet, ptRocket, ptLaserBeam);

  TpdProjectile = class (TpdAccumItem)
  private
    lbCounter: Single; //Счетчик времени до исчезания луча (laser beam)
  protected
    FTarget: TpdShip;
    FPrType: TpdProjectileType;
    FInitialPosition: TdfVec2f;
    FVelocity: TdfVec2f;
    FMaxRange: Single;
    procedure SetInitialPosition(const aValue: TdfVec2f);
    procedure SetVelocity(const aValue: TdfVec2f);
    procedure SetType(const aType: TpdProjectileType);
    procedure SetMaxRange(const aValue: Single);
    procedure SetTarget(const aValue: TpdShip);
  public
    Sprite: IglrSprite;

    FromShip: TpdShip;

    {Процедура вызывается после создания нового объекта, т. е. один раз за все время}
    procedure OnCreate(); override;
    {Процедура вызывается каждый раз, когда объект достают из аккумулятора}
    procedure OnGet(); override;
    {Процедура вызывается, когда обект помещают в аккумулятор}
    procedure OnFree(); override;

    property ProjectileType: TpdProjectileType read FPrType write SetType;
    property InitialPosition: TdfVec2f read FInitialPosition write SetInitialPosition;
    property Velocity: TdfVec2f read FVelocity write SetVelocity;
    property MaxRange: Single read FMaxRange write SetMaxRange;

    property Target: TpdShip read FTarget write SetTarget;
  end;

  TpdProjectilesAccum = class (TpdAccum)
  protected
  public
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdProjectile; reintroduce;

    procedure Update(const dt: Single);
  end;

implementation

uses
  dfTweener,
  uGlobal;

{ TpdProjectile }

procedure TpdProjectile.OnCreate;
begin
  inherited;
  Sprite := Factory.NewSprite();
  Sprite.SetCustomPivotPoint(0.0, 0.5);
  projectilesDummy.AddChild(Sprite);
  OnFree();
end;

procedure TpdProjectile.OnFree;
begin
  inherited;
  Sprite.Visible := False;
end;

procedure TpdProjectile.OnGet;
begin
  inherited;
  ProjectileType := ptLaserBullet;
  Sprite.Visible := True;
end;

procedure TpdProjectile.SetInitialPosition(const aValue: TdfVec2f);
begin
  FInitialPosition := aValue;
  Sprite.Position2D := InitialPosition;
end;

procedure TpdProjectile.SetMaxRange(const aValue: Single);
begin
  FMaxRange := aValue;
end;

procedure TpdProjectile.SetTarget(const aValue: TpdShip);
begin
  FTarget := aValue;
end;

procedure TpdProjectile.SetType(const aType: TpdProjectileType);
begin
  FPrType := aType;
  case aType of
    ptLaserBullet:
    begin
      with Sprite do
      begin
        Width := 21;
        Height := 3;
        Material.Diffuse := scolorRed;
      end;
      MaxRange := LASER_BULLET_RANGE;
    end;

    ptRocket:
    begin

    end;

    ptLaserBeam:
    begin
      lbCounter := LASER_BEAM_TIME;
      with Sprite do
      begin
        Width := LASER_BEAM_RANGE;
        Height := 3;
        Material.Diffuse := scolorBlue;
        Material.Texture.BlendingMode := tbmTransparency;
      end;
    end;
  end;
end;

procedure TpdProjectile.SetVelocity(const aValue: TdfVec2f);
begin
  FVelocity := aValue;
  Sprite.Rotation := Velocity.GetRotationAngle();
end;

{ TpdProjectilesAccum }

function TpdProjectilesAccum.GetItem: TpdProjectile;
begin
  Result := inherited GetItem() as TpdProjectile;
end;

function TpdProjectilesAccum.NewAccumItem: TpdAccumItem;
begin
  Result := TpdProjectile.Create();
end;

procedure TpdProjectilesAccum.Update(const dt: Single);
var
  i, j: Integer;
begin
  for i := 0 to Length(Items) - 1 do
    if Items[i].Used then
      with TpdProjectile(Items[i]) do
      begin
        if ProjectileType = ptLaserBeam then
        begin
          lbCounter := lbCounter - dt;
          Sprite.Material.PDiffuse.w := lbCounter / LASER_BEAM_TIME;
          if lbCounter <= 0 then
            FreeItem(Items[i]);

          for j := 0 to ships.Count - 1 do
            if FromShip = TpdShip(ships[j]) then
              continue
            else
              if LineCircleIntersect(InitialPosition, Velocity, TpdShip(ships[j]).Body.Position2D, TpdShip(ships[j]).Body.Width / 2 + 5) then
                Tweener.AddTweenPSingle(@TpdShip(ships[j]).Body.Material.PDiffuse.w, tsElasticEaseIn, 0.2, 1.0, 2.0, 0.2);

        end
        else
        begin
          Sprite.Position2D := Sprite.Position2D + Velocity * dt;
          if (Sprite.Position2D - InitialPosition).LengthQ > Sqr(MaxRange) then
            FreeItem(Items[i]);
        end

      end;
end;

end.

unit uProjectiles;

interface

uses
  glr, glrMath,
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
  public
    PrType: TpdProjectileType;
    Sprite: IglrSprite;
    InitialPosition: TdfVec2f;
    Velocity: TdfVec2f;
    MaxRange: Single;

    {Процедура вызывается после создания нового объекта, т. е. один раз за все время}
    procedure OnCreate(); override;
    {Процедура вызывается каждый раз, когда объект достают из аккумулятора}
    procedure OnGet(); override;
    {Процедура вызывается, когда обект помещают в аккумулятор}
    procedure OnFree(); override;

    procedure SetType(aType: TpdProjectileType);
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
  uGlobal;

{ TpdProjectile }

procedure TpdProjectile.OnCreate;
begin
  inherited;
  Sprite := Factory.NewSprite();
  Sprite.SetCustomPivotPoint(0.5, 1.0);
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
  PrType := ptLaserBullet;

  Sprite.Visible := True;
end;

procedure TpdProjectile.SetType(aType: TpdProjectileType);
begin
  PrType := aType;
  case aType of
    ptLaserBullet:
    begin
      with Sprite do
      begin
        Width := 3;
        Height := 21;
        Material.Diffuse := scolorRed;
      end;
      MaxRange := LASER_BULLET_RANGE;
    end;
    ptRocket: ;
    ptLaserBeam:
    begin
      lbCounter := LASER_BEAM_TIME;
      with Sprite do
      begin
        Width := 3;
        Height := LASER_BEAM_RANGE;
        Material.Diffuse := scolorBlue;
        Material.Texture.BlendingMode := tbmTransparency;
      end;
    end;
  end;
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
  i: Integer;
begin
  for i := 0 to Length(Items) - 1 do
    if Items[i].Used then
      with TpdProjectile(Items[i]) do
      begin
        if PrType = ptLaserBeam then
        begin
          lbCounter := lbCounter - dt;
          Sprite.Material.PDiffuse.w := lbCounter / LASER_BEAM_TIME;
          if lbCounter <= 0 then
            FreeItem(Items[i]);
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

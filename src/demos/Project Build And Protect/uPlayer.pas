unit uPlayer;

interface

uses
  dfHRenderer, dfMath;

type
  TpdPlayer = class
  protected
    dirVec: TdfVec2f;
    constructor Create(); virtual;
    destructor Destroy(); override;

  public
    planet, weapon, barrel: IglrSprite;
    barrelShotOffset: Single;
    class function Initialize(aScene: Iglr2DScene): TpdPlayer;

    procedure Update(const dt: Double);
    procedure UpdateRotation();

    procedure Shoot();
  end;

implementation

uses
  uGlobal, dfTweener;

{ TpdPlayer }

constructor TpdPlayer.Create;
begin
  planet := Factory.NewSprite();
  weapon := Factory.NewSprite();
  barrel := Factory.NewSprite();
  barrelShotOffset := 0;
end;

destructor TpdPlayer.Destroy;
begin
  planet := nil;
  barrel := nil;
  weapon := nil;
  inherited;
end;

class function TpdPlayer.Initialize(aScene: Iglr2DScene): TpdPlayer;
begin
  Result := TpdPlayer.Create();
  with Result do
  begin
    with planet do
    begin
      PivotPoint := ppCenter;
      Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);
      Z := Z_PLAYER;
      Material.Texture := atlasMain.LoadTexture(TEXTURE_PLANET);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;
    with weapon do
    begin
      PivotPoint := ppCenter;
      Z := Z_PLAYER - 1;
      Material.Texture := atlasMain.LoadTexture(TEXTURE_WEAPON);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;
    with barrel do
    begin
      PivotPoint := ppCenter;
      Z := Z_PLAYER - 2;
      Material.Texture := atlasMain.LoadTexture(TEXTURE_BARREL);
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;

    aScene.RegisterElement(barrel);
    aScene.RegisterElement(weapon);
    aScene.RegisterElement(planet);
  end;
end;

procedure TpdPlayer.Shoot;
begin
  sound.PlaySample(sShot);
  Tweener.AddTweenPSingle(@barrelShotOffset, tsExpoEaseIn, -25, 0, 1.5, 0.0);
  bullets.GetItem();
end;

procedure TpdPlayer.Update(const dt: Double);
begin
  barrel.Position := weapon.Position + dirVec * (weapon.Width / 2 + 20 + barrelShotOffset);
end;

procedure TpdPlayer.UpdateRotation;
begin
  dirVec := (mousePos - planet.Position).Normal;
  planet.Rotation := dirVec.GetRotationAngle;
  barrel.Rotation := planet.Rotation;
  weapon.Rotation := planet.Rotation;

  weapon.Position := planet.Position + dirVec * (planet.Width / 2 + 10);
end;

end.

{
  Оружие и патроны

+ TODO: Процедура Shoot()
  TODO: Переделать позиционирование fireSprite и патронов при выстреле
}

unit uWeapons;

interface

uses
  uAccum, uGlobal, UPhysics2D,
  dfHRenderer, dfMath;

const
  PISTOL_INDEX     = 0;
  SHOTGUN_INDEX    = 1;
  MACHINEGUN_INDEX = 2;

  PISTOL_NAME     = 'Револьвер';
  SHOTGUN_NAME    = 'Дробовик';
  MACHINEGUN_NAME = 'Автомат';

  WEAPON_FIRE_SHOW_TIME = 0.12;

type
  PpdWeapon = ^TpdWeapon;

  TpdShootProcedure = procedure(aWeapon: PpdWeapon);
  TpdGetBulletOrigin = function(): TdfVec2f;

  TpdWeapon = record
    name: UnicodeString;
    //-sprite: IdfSprite; - для HUD
    minDamage, maxDamage: Integer;
    ammoLeft, ammoMax: Integer;
    sps: Single; //SPS - Shoot per second, выстрелов в секунду
    rof: Single; // ROF - Rate Of Fire - скорострельность, минимальное время между двумя выстрелами
    isAutomatic, isShoot: Boolean;
    recoilTime: Single;
    bulletSpeed: Single;
    criticalHitChance: Single;
    shootProc: TpdShootProcedure;
    getBulletOrigin: TpdGetBulletOrigin;
    procedure StartShoot();
    procedure EndShoot();
    procedure Update(const dt: Double);
    function GetDamage(): Integer;

  private
    procedure Shoot();
  end;

  TpdBullet = class (TpdAccumItem)
  public
    sprite: IglrSprite;
    body: Tb2Body;

    moveVec: TdfVec2f;
    weapon: PpdWeapon;
    lastPos: TdfVec2f; //Позиция на предыдущем шаге. Нужна для правильного вращения спрайта по скорости
    procedure OnCreate(); override;
    procedure OnGet(); override;
    procedure OnFree(); override;
  end;

  TpdBullets = class (TpdAccum)
  public
    function NewAccumItem(): TpdAccumItem; override;

    function GetItem(): TpdBullet; reintroduce;
  end;

  procedure LoadWeapons();
  procedure InitWeapons();
  procedure UpdateWeapons(const dt: Double);
  procedure FreeWeapons();

  function NextWeapon(): PpdWeapon;
  function PrevWeapon(): PpdWeapon;


  function InitPistolBulletSprite(): IglrSprite;

  procedure InitBullets(aScene: Iglr2DScene);
  procedure UpdateBullets(const dt: Double);
  procedure FreeBullets();

  procedure ShootPistol(aWeapon: PpdWeapon);
  procedure ShootShotgun(aWeapon: PpdWeapon);
  procedure ShootMachineGun(aWeapon: PpdWeapon);
  function getBulletOriginRV(): TdfVec2f;
  function getBulletOriginSG(): TdfVec2f;
  function getBulletOriginMG(): TdfVec2f;

const
  BULLET_SPEED = 450.0;
  BULLET_HIT_RADIUS = 4.0;

var
  bullets: TpdBullets;
  weapons: array of TpdWeapon;
  currentWeaponIndex: Integer = 0;


implementation

uses
  uBox2DImport, UPhysics2DTypes,
  uPlayer;

var
  scene: Iglr2DScene;
  fireSprite: IglrSprite;
  fireTimeRemain: Single;

{$REGION ' < Weapons > '}

procedure LoadWeapons();
begin
  fireSprite := Factory.NewSprite();
  fireSprite.Visible := False;
  with fireSprite.Material.Texture do
  begin
    Load2D(FILE_WEAPON_FIRE_SPRITE);
    BlendingMode := tbmTransparency;
    CombineMode := tcmModulate;
  end;
  fireSprite.SetSizeToTextureSize();
  fireSprite.PivotPoint := ppCenter;

  SetLength(weapons, 3);
  with weapons[PISTOL_INDEX] do
  begin
    name := PISTOL_NAME;
    minDamage := 3;
    maxDamage := 6;
    ammoMax := -1;
    ammoLeft := -1;
    sps := 5.0;
    rof := 1 / sps;
    isAutomatic := False;
    isShoot := False;
    bulletSpeed := 450.0 * uBox2DImport.C_COEF;
    criticalHitChance := 0.1;

    shootProc := @ShootPistol;
    getBulletOrigin := @getBulletOriginRV;
  end;

  with weapons[SHOTGUN_INDEX] do
  begin
    name := SHOTGUN_NAME;
    minDamage := 5;
    maxDamage := 10;
    ammoMax := 50;
    ammoLeft := 50;
    sps := 2.0;
    rof := 1 / sps;
    isAutomatic := False;
    isShoot := False;
    bulletSpeed := 350.0 * uBox2DImport.C_COEF;
    criticalHitChance := 0.2;

    shootProc := @ShootShotgun;
    getBulletOrigin := @getBulletOriginSG;
  end;

  with weapons[MACHINEGUN_INDEX] do
  begin
    name := MACHINEGUN_NAME;
    minDamage := 2;
    maxDamage := 4;
    ammoMax := 300;
    ammoLeft := 300;
    sps := 10.0;
    rof := 1 / sps;
    isAutomatic := True;
    isShoot := False;
    bulletSpeed := 500.0 * uBox2DImport.C_COEF;
    criticalHitChance := 0.07;

    shootProc := @ShootMachineGun;
    getBulletOrigin := @getBulletOriginMG;
  end;
end;

procedure InitWeapons();
var
  i: Integer;
begin
  scene.RegisterElement(fireSprite);
  for i := 0 to High(weapons) do
  begin
    weapons[i].ammoLeft := weapons[i].ammoMax;
    weapons[i].recoilTime := 0;
  end;
end;

function NextWeapon(): PpdWeapon;
begin
  weapons[currentWeaponIndex].EndShoot;
  if currentWeaponIndex = High(weapons) then
    currentWeaponIndex := 0
  else
    Inc(currentWeaponIndex, 1);
  Result := @weapons[currentWeaponIndex];
  ChangeSpriteDueToWeapon();
end;

function PrevWeapon(): PpdWeapon;
begin
  weapons[currentWeaponIndex].EndShoot;
  if currentWeaponIndex = 0 then
    currentWeaponIndex := High(weapons)
  else
    Dec(currentWeaponIndex, 1);
  Result := @weapons[currentWeaponIndex];
  ChangeSpriteDueToWeapon();
end;

procedure UpdateWeapons(const dt: Double);
begin
  if fireTimeRemain > 0 then
    fireTimeRemain := fireTimeRemain - dt
  else
    fireSprite.Visible := False;

  fireSprite.Position := player.sprite.Position + (player.dir * 96) + dfVec2f(-player.dir.y, player.dir.x) * 12;
  fireSprite.Rotation := player.sprite.Rotation;
end;

procedure FreeWeapons();
begin
  SetLength(weapons, 0);
end;

{ TpdWeapon }

procedure TpdWeapon.StartShoot();
begin
  isShoot := True;
  Shoot();
  if not isAutomatic then
    EndShoot();
end;

procedure TpdWeapon.EndShoot;
begin
  isShoot := False;
end;

function TpdWeapon.GetDamage: Integer;
begin
  Result := minDamage + Random(maxDamage + 1 - minDamage); //random дает 0..(range-1)
  if Random() <= criticalHitChance then
    Result := Result * 3;
end;

procedure TpdWeapon.Shoot();
begin
  if (ammoLeft <> 0) and (recoilTime <= 0.0) then
  begin
    if ammoLeft <> -1 then //для оружия с бесконечным запасом патронов
      Dec(ammoLeft, 1);
    recoilTime := rof;
    shootProc(@Self);
  end;
end;

procedure TpdWeapon.Update(const dt: Double);
begin
  if recoilTime > 0.0 then
    recoilTime := recoilTime - dt
  else if isShoot then
    Shoot();
end;

{$ENDREGION}

{$REGION ' < Bullets > '}

function InitPistolBulletSprite(): IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.PivotPoint := ppCenter;
  Result.Width := 4;
  Result.Height := 12;
  Result.Material.MaterialOptions.Diffuse := dfVec4f(0.7, 0.2, 0.2, 1.0);
  scene.RegisterElement(Result);
end;



procedure InitBullets(aScene: Iglr2DScene);
begin
  scene := aScene;
  if Assigned(bullets) then
    bullets.Free();
  bullets := TpdBullets.Create(32);
end;

procedure UpdateBullets(const dt: Double);

  function IsOutOfScreen(aPos: TdfVec2f): Boolean;
  begin
    with aPos, R do
      Result := (x < 0) or (y < 0) or (x > WindowWidth) or (y > WindowHeight);
  end;

  function IsSpeedLow(bullet: TpdBullet): Boolean;
  begin
    Result := bullet.body.GetLinearVelocity.Length() < bullet.weapon.bulletSpeed * 0.3;
  end;

var
  i: Integer;
begin
  for i := 0 to High(bullets.Items) do
    if bullets.Items[i].Used then
      with bullets.Items[i] as TpdBullet do
      begin
        SyncObjects(body, sprite);
        sprite.Rotation := ConvertB2ToGL(body.GetLinearVelocity).Normal.GetRotationAngle;
        //Free, если за пределами экрана
        if IsOutOfScreen(sprite.Position) or IsSpeedLow(bullets.Items[i] as TpdBullet) then
          bullets.FreeItem(bullets.Items[i]);
      end;
end;

procedure FreeBullets();
begin
  bullets.Free();
  bullets := nil;
  scene := nil;
end;

{$ENDREGION}

{$REGION ' < Shoot procedures for various types of weapon > '}

procedure ShootPistol(aWeapon: PpdWeapon);
begin
  with bullets.GetItem() do
  begin
    weapon := aWeapon;
    sprite.Position := aWeapon^.getBulletOrigin();
    if (mousePos - sprite.Position).Length < 60 then
      moveVec := player.dir
    else
      moveVec := (mousePos - sprite.Position).Normal;
    sprite.Rotation := moveVec.GetRotationAngle();
    body.SetTransform(ConvertGLToB2(sprite.Position * C_COEF), sprite.Rotation * deg2rad);
    body.SetLinearVelocity(ConvertGLToB2(moveVec * aWeapon.bulletSpeed));
    body.SetFixedRotation(False);

    lastPos := sprite.Position;
  end;
  fireTimeRemain := WEAPON_FIRE_SHOW_TIME;
  fireSprite.Visible := True;
end;

const
  DISP_COEF = 0.07;

procedure ShootShotgun(aWeapon: PpdWeapon);
var
  i, start: Integer;
begin
  start := -2;
  for i := 0 to 4 do
    with bullets.GetItem() do
    begin
      weapon := aWeapon;
      sprite.Position := aWeapon^.getBulletOrigin();
      if (mousePos - sprite.Position).Length < 70 then
        moveVec := player.dir
      else
        moveVec := (mousePos - sprite.Position).Normal;
      moveVec := moveVec + {перпендикулярный вектор} dfVec2f(-player.dir.y, player.dir.x) * (start + i) * DISP_COEF;
      sprite.Rotation := moveVec.GetRotationAngle();
      body.SetTransform(ConvertGLToB2(sprite.Position * C_COEF), sprite.Rotation * deg2rad);
      body.SetLinearVelocity(ConvertGLToB2(moveVec * aWeapon.bulletSpeed));
      body.SetFixedRotation(False);

      lastPos := sprite.Position;
    end;
  fireTimeRemain := WEAPON_FIRE_SHOW_TIME;
  fireSprite.Visible := True;
end;

procedure ShootMachineGun(aWeapon: PpdWeapon);
begin
  with bullets.GetItem() do
  begin
    weapon := aWeapon;
    sprite.Position := aWeapon^.getBulletOrigin();
    if (mousePos - sprite.Position).Length < 80 then
      moveVec := player.dir
    else
      moveVec := (mousePos - sprite.Position).Normal;
    sprite.Rotation := moveVec.GetRotationAngle();
    body.SetTransform(ConvertGLToB2(sprite.Position * C_COEF), sprite.Rotation * deg2rad);
    body.SetLinearVelocity(ConvertGLToB2(moveVec * aWeapon.bulletSpeed));
    body.SetFixedRotation(False);

    lastPos := sprite.Position;
  end;
  fireTimeRemain := WEAPON_FIRE_SHOW_TIME;
  fireSprite.Visible := True;
end;

function getBulletOriginRV(): TdfVec2f;
begin
  Result := player.sprite.Position + player.dir * 60 + dfVec2f(-player.dir.y, player.dir.x) * 6;
end;

function getBulletOriginSG(): TdfVec2f;
begin
  Result := player.sprite.Position + player.dir * 65 + dfVec2f(-player.dir.y, player.dir.x) * 12;
end;

function getBulletOriginMG(): TdfVec2f;
begin
  Result := player.sprite.Position + player.dir * 80 + dfVec2f(-player.dir.y, player.dir.x) * 12;
end;
{$ENDREGION}

{ TpdBullets }

function TpdBullets.GetItem(): TpdBullet;
begin
  Result := inherited GetItem() as TpdBullet;
end;

function TpdBullets.NewAccumItem: TpdAccumItem;
begin
  Result := TpdBullet.Create();
end;

{ TpdBullet }

procedure TpdBullet.OnCreate;
begin
  inherited;
  sprite := InitPistolBulletSprite();
  body := dfb2InitCircle(Phys, sprite, 2.5, 0.1, 0.1, $FFFF, $0001, -2);
  body.AngularDamping := 1.0;
  sprite.Visible := False;
  moveVec.Reset();
  weapon := nil;
end;

procedure TpdBullet.OnFree;
begin
  inherited;
  sprite.Visible := False;
  body.SetLinearVelocity(TVector2.From(0, 0));
  body.SetAngularVelocity(0);
  body.SetActive(False);
  //body.SetFixedRotation(True);
  weapon := nil;
end;

procedure TpdBullet.OnGet;
begin
  inherited;
  sprite.Visible := True;
  body.SetActive(True);
  moveVec.Reset();
  Inc(player.shotsFired);
end;

end.

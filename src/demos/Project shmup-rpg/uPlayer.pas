{
  TODO:
  + Инициализация здоровья ГГ
  + Отображение здоровья ГГ
  + Смерть
}

unit uPlayer;

interface

uses
  Windows,
  uWeapons, uGlobal, UPhysics2D, UPhysics2DTypes,
  dfHRenderer, dfMath;

const
  //FILE_PLAYER_SPRITE = RES_FOLDER + 'cowboy.tga';
  PLAYER_PICKUP_RADIUS = 48; //Радиус игрока для пикапа вещей
  PLAYER_HIT_RADIUS    = 90; //Радиус игрока для расчета урона

type
  TpdPlayer = record
    health, healthMax: Integer;

    sprite: IglrSprite;
    body: Tb2Body;
    dir: TdfVec2f; //вектор направления, нормализован
    move: TdfVec2f; //вектор движения = dir + скалируется по speed каждый шаг
    score: Integer; //Очки
    currentWeapon: PpdWeapon;

    shotsFired, shotsOnTarget: LongWord;

    speed: Single; //скорость передвижения

    procedure AddScore(const aAdd: Integer);
    procedure Hit(const aDamage: Integer);
    procedure Die();
    function GetAccuracyPercent(): Single;
  end;

  PpdPlayer = ^TpdPlayer;

var
  player: TpdPlayer;

procedure LoadPlayer();
procedure InitPlayer(aScene: Iglr2DScene);
procedure UpdatePlayer(const dt: Double);
procedure ChangeSpriteDueToWeapon();
procedure FreePlayer();

implementation

uses
  uBox2DImport,
  SysUtils,
  uPopup;

var
  texPlayerRV, texPlayerSG, texPlayerMG: IglrTexture;

{$REGION ' < Player > '}

procedure LoadPlayer();
begin
  texPlayerRV := Factory.NewTexture();
  texPlayerRV.Load2D(FILE_PLAYER_SPRITE_REVOLVER);
  texPlayerRV.BlendingMode := tbmTransparency;
  texPlayerRV.CombineMode := tcmModulate;
  texPlayerRV.WrapS := twClamp;
  texPlayerRV.WrapT := twClamp;
  texPlayerRV.WrapR := twClamp;

  texPlayerSG := Factory.NewTexture();
  texPlayerSG.Load2D(FILE_PLAYER_SPRITE_SHOTGUN);
  texPlayerSG.BlendingMode := tbmTransparency;
  texPlayerSG.CombineMode := tcmModulate;
  texPlayerSG.WrapS := twClamp;
  texPlayerSG.WrapT := twClamp;
  texPlayerSG.WrapR := twClamp;

  texPlayerMG := Factory.NewTexture();
  texPlayerMG.Load2D(FILE_PLAYER_SPRITE_MACHINEGUN);
  texPlayerMG.BlendingMode := tbmTransparency;
  texPlayerMG.CombineMode := tcmModulate;
  texPlayerMG.WrapS := twClamp;
  texPlayerMG.WrapT := twClamp;
  texPlayerMG.WrapR := twClamp;

  with player do
  begin
    sprite := Factory.NewSprite();
    sprite.SetCustomPivotPoint(0.5, 0.85);
//    with sprite.Material.Texture do
//    begin
//      Load2D(FILE_PLAYER_SPRITE);
//      BlendingMode := tbmTransparency;
//      CombineMode := tcmModulate;
//    end;
    sprite.SetSizeToTextureSize();
  end;
end;

procedure InitPlayer(aScene: Iglr2DScene);
begin
  with player do
  begin
    sprite.Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);
    sprite.Z := Z_PLAYER;
    aScene.RegisterElement(sprite);
    speed := 400;
    healthMax := 100;
    health := healthMax;
    score := 0;
    currentWeapon := @weapons[0];
    shotsFired := 0;
    shotsOnTarget := 0;
  end;
  ChangeSpriteDueToWeapon();

  player.body :=  dfb2InitCircle(Phys, player.sprite, 1.0, 0.5, 0.0, $FFFF, $0001, -2);
  player.body.SetFixedRotation(True);
end;

procedure UpdatePlayer(const dt: Double);
begin
  player.move.Reset();
  if R.Input.IsKeyDown('w') or R.Input.IsKeyDown('ц') then
    player.move := player.move + dfVec2f(0, -1)
  else
    if R.Input.IsKeyDown('s') or R.Input.IsKeyDown('ы') then
      player.move := player.move + dfVec2f(0, 1);
  if R.Input.IsKeyDown('a') or R.Input.IsKeyDown('ф') then
    player.move := player.move + dfVec2f(-1, 0)
  else
    if R.Input.IsKeyDown('d') or R.Input.IsKeyDown('в') then
      player.move := player.move + dfVec2f(1, 0);
  if (player.move.LengthQ > 0.8) and (player.body.GetLinearVelocity.Length < 1) then
  begin
    player.move := player.move.Normal * dt * player.speed;
    player.body.SetLinearVelocity(ConvertGLToB2(player.move));
//    player.body.ApplyLinearImpulse(ConvertGLToB2(player.move), player.body.GetWorldCenter);
//    player.move := player.move.Normal * dt * player.speed;
//    player.sprite.Position := player.sprite.Position + player.move;
  end
  else
    player.body.SetLinearVelocity(TVector2.From(0, 0));

  SyncObjects(player.body, player.sprite);

  if R.Input.IsKeyDown(VK_MOUSEWHEELUP) then
    player.currentWeapon := PrevWeapon()
  else if R.Input.IsKeyDown(VK_MOUSEWHEELDOWN) then
    player.currentWeapon := NextWeapon();

  //Поворот героя по направлению к указателю мыши
  player.dir := mousePos - player.sprite.Position;
  player.dir.Normalize();
  player.sprite.Rotation := player.dir.GetRotationAngle();

  player.currentWeapon.Update(dt);
end;

procedure ChangeSpriteDueToWeapon();
  procedure SetTexture(aTex: IglrTexture);
  begin
    player.sprite.Material.Texture := aTex;
    player.sprite.SetSizeToTextureSize;
  end;

begin
  case currentWeaponIndex of
    PISTOL_INDEX: SetTexture(texPlayerRV);
    SHOTGUN_INDEX: SetTexture(texPlayerSG);
    MACHINEGUN_INDEX: SetTexture(texPlayerMG);
  end;
end;

procedure FreePlayer();
begin
//  sceneMain.UnregisterElement(player.sprite);
end;

{$ENDREGION}

{ TpdPlayer }

procedure TpdPlayer.AddScore(const aAdd: Integer);
begin
  score := score + aAdd;
end;

procedure TpdPlayer.Die;
begin
  //*
end;

function TpdPlayer.GetAccuracyPercent: Single;
begin
  if shotsFired > 0 then
    Result := 100 * shotsOnTarget / shotsFired
  else
    Result := 0;
end;

procedure TpdPlayer.Hit(const aDamage: Integer);
begin
  health := health - aDamage;
  uPopup.AddNewPopupEx(player.sprite.Position.x, player.sprite.Position.y - 15, '-' + IntToStr(aDamage) + ' здоровья', dfVec3f(0.9, 0.1, 0.1));
  if health <= 0 then
  begin
    Die();
  end;
end;

end.

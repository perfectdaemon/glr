unit uEnemies;

interface

uses
  uAccum,
  dfHRenderer, dfMath;

const
  ENEMY_SPEED = 50.0;
  ENEMY_HIT_RADIUS = 24;
  ENEMY_TIME_BTWN_SPAWN = 1.0; //Время между появлением врагов
  ENEMY_HEALH = 5;
  ENEMY_SCORE_POINTS = 50;
  ENEMY_COOLDAWN_TO_NEXT_HUMHUM = 2.0; //Время до следующего хрум-хрум игрока, если в пределах хрум-хрум
  ENEMY_HUMHUM_DAMAGE = 10;

  ENEMY_DEAD_TIME = 3.0; //Сколько времени валяется труп
  ENEMY_ATTACK_TIME = 1.0; //Сколько времени отображается текстура укуса

type
  TpdEnemyStatus = (esNormal, esAttack, esDead);

  TpdEnemy = class (TpdAccumItem)
  public
    sprite: IglrSprite;
    health, maxHealth: Integer;
    moveVec: TdfVec2f;
    cooldawnTime: Single;
    status: TpdEnemyStatus;
    timeToNextStatus: Single;

    procedure OnCreate(); override;
    procedure OnGet(); override;
    procedure OnFree(); override;
  end;

  TpdEnemies = class (TpdAccum)
  public
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdEnemy; reintroduce;
  end;


  function InitEnemySprite(): IglrSprite;

  procedure LoadEnemies();
  procedure InitEnemies(aScene: Iglr2DScene);
  procedure UpdateEnemies(const dt: Double);
  procedure FreeEnemies();

var
  enemies: TpdEnemies;

implementation

uses
  SysUtils,
  uGlobal, uPlayer, uWeapons, uDrop, uPopup;

var
  scene: Iglr2DScene;
  enemyTimeToNextSpawn: Single;
  enemyNormalColor: TdfVec4f = (x: 0.7; y: 0.7; z: 0.7; w: 1.0);
  texEnemyCoyotAtlas, texEnemyCoyotNormal, texEnemyCoyotAttack, texEnemyCoyotDead: IglrTexture;
  //debug
  increm: Integer = 0;

const
  COYOT_NORMAL_X = 168;
  COYOT_NORMAL_Y = 0;
  COYOT_NORMAL_W = 48;
  COYOT_NORMAL_H = 195;

  COYOT_ATTACK_X = 107;
  COYOT_ATTACK_Y = 0;
  COYOT_ATTACK_W = 60;
  COYOT_ATTACK_H = 195;

  COYOT_DEAD_X = 0;
  COYOT_DEAD_Y = 0;
  COYOT_DEAD_W = 106;
  COYOT_DEAD_H = 195;


procedure LoadEnemies();
begin
  texEnemyCoyotAtlas := Factory.NewTexture();
  texEnemyCoyotAtlas.Load2D(FILE_ENEMIES_COYOT_ATLAS);
  texEnemyCoyotAtlas.CombineMode := tcmModulate;
  texEnemyCoyotAtlas.BlendingMode := tbmTransparency;

  texEnemyCoyotNormal := Factory.NewTexture();
  texEnemyCoyotNormal.Load2DRegion(texEnemyCoyotAtlas, COYOT_NORMAL_X, COYOT_NORMAL_Y, COYOT_NORMAL_W, COYOT_NORMAL_H);

  texEnemyCoyotAttack := Factory.NewTexture();
  texEnemyCoyotAttack.Load2DRegion(texEnemyCoyotAtlas, COYOT_ATTACK_X, COYOT_ATTACK_Y, COYOT_ATTACK_W, COYOT_ATTACK_H);

  texEnemyCoyotDead := Factory.NewTexture();
  texEnemyCoyotDead.Load2DRegion(texEnemyCoyotAtlas, COYOT_DEAD_X, COYOT_DEAD_Y, COYOT_DEAD_W, COYOT_DEAD_H);
end;

function InitEnemySprite(): IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.PivotPoint := ppCenter;
  Result.Material.MaterialOptions.Diffuse := enemyNormalColor;
  Result.Z := Z_ENEMIES + increm;
  Inc(increm);
  scene.RegisterElement(Result);
end;

procedure InitEnemies(aScene: Iglr2DScene);
begin
  scene := aScene;
  if Assigned(enemies) then
    enemies.Free();
  enemies := TpdEnemies.Create(16);
  Randomize();
end;

procedure ChangeTexture(enemy: TpdEnemy; aTex: IglrTexture);
begin
  enemy.sprite.Material.Texture := aTex;
  enemy.sprite.SetSizeToTextureSize;
  //debug
  enemy.sprite.Scale := dfVec2f(0.7, 0.7);
  enemy.sprite.UpdateTexCoords();
end;

procedure UpdateEnemies(const dt: Double);

  procedure SpawnEnemy();
  begin
    enemyTimeToNextSpawn := ENEMY_TIME_BTWN_SPAWN;
    with enemies.GetItem() do
    begin
      //Некрасивый способ
      sprite.Position := dfVec2f(Random(R.WindowWidth), Random(R.WindowHeight));
      case Random(4) of
        0: sprite.Position := dfVec2f(-12, sprite.Position.y);
        1: sprite.Position := dfVec2f(sprite.Position.x, -12);
        2: sprite.Position := dfVec2f(R.WindowWidth + 12, sprite.Position.y);
        3: sprite.Position := dfVec2f(sprite.Position.x, R.WindowHeight + 12);
      end;
      moveVec := (player.sprite.Position - sprite.Position).Normal;
    end;
  end;

  procedure ShootEnemy(enemy: TpdEnemy);
  begin
    with enemy do
    begin
      health := health - player.currentWeapon.GetDamage();
      if health < 0 then
      begin
        TrySpawnDropItem(enemy.sprite.Position.x, enemy.sprite.Position.y + 20, 1.0);
        AddNewPopup(enemy.sprite.Position.x, enemy.sprite.Position.y - 20, '+'+IntToStr(ENEMY_SCORE_POINTS));
        player.AddScore(ENEMY_SCORE_POINTS);
        status := esDead;
        timeToNextStatus := ENEMY_DEAD_TIME;
        ChangeTexture(enemy, texEnemyCoyotDead);
        sprite.Material.MaterialOptions.Diffuse := enemyNormalColor;
      end
      else
        with sprite.Material.MaterialOptions do
          Diffuse := dfVec4f(enemyNormalColor.x + (1.0 - enemyNormalColor.x)*(1 - (health/maxhealth)), enemyNormalColor.y, enemyNormalColor.z, 1.0);
    end;

  end;

  function IsBulletHit(enemy: TpdEnemy; bullet: TpdBullet): Boolean;
  begin
    Result := enemy.sprite.Position.Dist(bullet.sprite.Position) < BULLET_HIT_RADIUS + ENEMY_HIT_RADIUS;
  end;

  function IsPlayerHit(enemy: TpdEnemy): Boolean;
  begin
    Result := enemy.sprite.Position.Dist(player.sprite.Position) < PLAYER_HIT_RADIUS + ENEMY_HIT_RADIUS;
  end;

  procedure CheckHits(enemy: TpdEnemy);
  var
    i: Integer;
  begin
    for i := 0 to High(bullets.Items) do
      //Проверка необходима, так как враг мог уже умереть от предыдущей пули
      if not enemy.Used then
        Exit()
      else if bullets.Items[i].Used then
        if IsBulletHit(enemy, bullets.Items[i] as TpdBullet) then
        begin
          Inc(player.shotsOnTarget);
          ShootEnemy(enemy);
          bullets.FreeItem(bullets.Items[i]);
        end;
  end;
var
  j: Integer;
begin
  for j := 0 to High(enemies.Items) do
    if enemies.Items[j].Used then
    begin
      with enemies.Items[j] as TpdEnemy do
      begin
        //Считаем кулдаун до смены статуса
        if timeToNextStatus > 0 then
          timeToNextStatus := timeToNextStatus - dt
        else
          case status of
            esNormal: ;
            esAttack:
              begin
                status := esNormal;
                ChangeTexture(enemies.Items[j] as TpdEnemy, texEnemyCoyotNormal);
              end;
            esDead: enemies.FreeItem(enemies.Items[j] as TpdEnemy);
          end;

        if status = esDead then
          Continue;
        
        //Перемещение
        sprite.Position := sprite.Position + moveVec * dt * ENEMY_SPEED;
        moveVec := (player.sprite.Position - sprite.Position).Normal;
        sprite.Rotation := moveVec.GetRotationAngle();

        //Проверка на столкновение с пулями
        CheckHits(enemies.Items[j] as TpdEnemy);

        //Проверка на столновение с игроком
        if IsPlayerHit(enemies.Items[j] as TpdEnemy) and (cooldawnTime <= 0) then
        begin
          player.Hit(ENEMY_HUMHUM_DAMAGE);
          cooldawnTime := ENEMY_COOLDAWN_TO_NEXT_HUMHUM;
          timeToNextStatus := ENEMY_ATTACK_TIME;
          status := esAttack;
          ChangeTexture(enemies.Items[j] as TpdEnemy, texEnemyCoyotAttack);
        end;

        //Считаем кулдаун до ам-ням, если он есть
        if cooldawnTime > 0 then
          cooldawnTime := cooldawnTime - dt;
      end;

    end;

  if enemyTimeToNextSpawn < 0 then
    //SpawnEnemy()
  else
    enemyTimeToNextSpawn := enemyTimeToNextSpawn - dt;
end;

procedure FreeEnemies();
begin
  enemies.Free();
  enemies := nil;
end;

{ TpdEnemies }

function TpdEnemies.GetItem: TpdEnemy;
begin
  Result := inherited GetItem() as TpdEnemy;
end;

function TpdEnemies.NewAccumItem: TpdAccumItem;
begin
  Result := TpdEnemy.Create();
end;

{ TpdEnemy }

procedure TpdEnemy.OnCreate;
begin
  inherited;
  sprite := InitEnemySprite();
  sprite.Visible := False;
  maxHealth := ENEMY_HEALH;
  health := maxHealth;
  moveVec.Reset();
  cooldawnTime := 0;
end;

procedure TpdEnemy.OnFree;
begin
  inherited;
  sprite.Visible := False;
end;

procedure TpdEnemy.OnGet;
begin
  inherited;
  sprite.Visible := True;
  maxHealth := ENEMY_HEALH;
  health := maxHealth;
  moveVec.Reset();
  cooldawnTime := 0;
  sprite.Material.MaterialOptions.Diffuse := enemyNormalColor;
  ChangeTexture(self, texEnemyCoyotNormal);
  status := esNormal;
  timeToNextStatus := 0;
end;

end.

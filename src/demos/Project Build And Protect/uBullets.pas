unit uBullets;

interface

uses
  dfHRenderer, dfMath, uAccum, uEnemies;

const
  BULLET_SPEED = 350;

type
  TpdBullet = class (TpdAccumItem)
  private
    moveVec: TdfVec2f;
    function IsOutOfScreen(): Boolean;
    function IsEnemyHit(): TpdEnemy;
  public
    aSprite: IglrSprite;
    procedure Update(const dt: Double);

    {Процедура вызывается после создания нового объекта, т. е. один раз за все время}
    procedure OnCreate(); override;
    {Процедура вызывается каждый раз, когда объект достают из аккумулятора}
    procedure OnGet(); override;
    {Процедура вызывается, когда обект помещают в аккумулятор}
    procedure OnFree(); override;
  end;

  TpdBullets = class (TpdAccum)
  public
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdBullet; reintroduce;

    procedure Update(const dt: Double);
  end;


implementation

uses
  uGlobal;

{ TpdBullet }

function TpdBullet.IsEnemyHit: TpdEnemy;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(enemies.Items) do
    with (enemies.Items[i] as TpdEnemy) do
      if (Self.aSprite.Position - aSprite.Position).Length < (aSprite.Width / 2) then
        Exit(enemies.Items[i] as TpdEnemy);
end;

function TpdBullet.IsOutOfScreen: Boolean;
begin
  with aSprite.Position do
    Result := (x < 0) or (x > R.WindowWidth) or (y < 0) or (y > r.WindowHeight);
end;

procedure TpdBullet.OnCreate;
begin
  inherited;
  aSprite := Factory.NewSprite();

  aSprite.PivotPoint := ppCenter;
  aSprite.Width := 5;
  aSprite.Height := 15;
  aSprite.Material.MaterialOptions.Diffuse := colorRed;
  aSprite.Z := Z_PLAYER;

  mainScene.RegisterElement(aSprite);

  OnFree();
end;

procedure TpdBullet.OnFree;
begin
  inherited;
  aSprite.Visible := False;
end;

procedure TpdBullet.OnGet;
begin
  inherited;
  asprite.Position := player.barrel.Position;
  moveVec := (mousePos - player.planet.Position).Normal;
  aSprite.Rotation := moveVec.GetRotationAngle();
  aSprite.Visible := True;
end;

procedure TpdBullet.Update(const dt: Double);
var
  deadEnemy: TpdEnemy;
begin
  if not FUsed then
    Exit();
  aSprite.Position := aSprite.Position + moveVec * dt * BULLET_SPEED;
  deadEnemy := IsEnemyHit();
  if Assigned(deadEnemy) then
  begin
    //Make Boom
    Self.OnFree();
    deadEnemy.OnFree();
    sound.PlaySample(sExpl);
  end
  else if IsOutOfScreen() then
    Self.OnFree()
end;

{ TpdBullets }

function TpdBullets.GetItem: TpdBullet;
begin
  Result := inherited GetItem() as TpdBullet;
end;

function TpdBullets.NewAccumItem: TpdAccumItem;
begin
  Result := TpdBullet.Create();
end;

procedure TpdBullets.Update(const dt: Double);
var
  i: Integer;
begin
  for i := 0 to High(Items) do
    (Items[i] as TpdBullet).Update(dt);
end;

end.

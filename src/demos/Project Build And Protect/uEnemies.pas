unit uEnemies;

interface

uses
  dfHRenderer, dfMath, uAccum;

const
  ENEMY_SPEED_MIN = 40;
  ENEMY_SPEED_MAX = 60;

type
  TpdEnemy = class (TpdAccumItem)
  private
    moveVec: TdfVec2f;
    enemySpeed: Single;
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

  TpdEnemies = class (TpdAccum)
  public
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdEnemy; reintroduce;

    procedure Update(const dt: Double);
  end;

implementation

uses
  uGlobal;

{ TpdEnemy }

procedure TpdEnemy.OnCreate;
begin
  inherited;
  aSprite := Factory.NewSprite();

  aSprite.Material.Texture := texEnemy;
  aSprite.PivotPoint := ppCenter;
  aSprite.UpdateTexCoords();
  aSprite.SetSizeToTextureSize();
  aSprite.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
  aSprite.Position := dfVec2f(140, 140);
  aSprite.Z := Z_ENEMY;

  mainScene.RegisterElement(aSprite);

  OnFree();
end;

procedure TpdEnemy.OnFree;
begin
  inherited;
  aSprite.Visible := False;
end;

procedure TpdEnemy.OnGet;
begin
  inherited;
  asprite.Position := dfVec2f(Random(R.WindowWidth), Random(R.WindowHeight));
  case Random(4) of
    0: aSprite.Position := dfVec2f(-30, aSprite.Position.y);
    1: aSprite.Position := dfVec2f(aSprite.Position.x, -30);
    2: aSprite.Position := dfVec2f(R.WindowWidth + 30, aSprite.Position.y);
    3: aSprite.Position := dfVec2f(aSprite.Position.x, R.WindowHeight + 30);
  end;
  enemySpeed := ENEMY_SPEED_MIN + Random(ENEMY_SPEED_MAX - ENEMY_SPEED_MIN + 1);
  moveVec := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2) - aSprite.Position;
  moveVec.Normalize;
  aSprite.Rotation := moveVec.GetRotationAngle();
  aSprite.Visible := True;
end;

procedure TpdEnemy.Update(const dt: Double);
begin
  if not FUsed then
    Exit();
  aSprite.Position := aSprite.Position + moveVec * dt * enemySpeed;
  if (player.planet.Position - aSprite.Position).Length < (player.planet.Width / 2) then
    Self.OnFree();
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

procedure TpdEnemies.Update(const dt: Double);
var
  i: Integer;
begin
  for i := 0 to High(Items) do
    (Items[i] as TpdEnemy).Update(dt);
end;

end.

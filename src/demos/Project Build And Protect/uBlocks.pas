unit uBlocks;

interface

uses
  dfHRenderer, dfMath, uAccum;

const
  BLOCK_SPEED_MIN = 30;
  BLOCK_SPEED_MAX = 50;

type
  TpdDropBlockType = (dbRed, dbGreen, dbBlue);

  TpdDropBlock = class (TpdAccumItem)
  public
    aSprite: IglrSprite;
    blockSpeed: Single;
    moveVec: TdfVec2f;
    aType: TpdDropBlockType;
    procedure Update(const dt: Double);

    {Процедура вызывается после создания нового объекта, т. е. один раз за все время}
    procedure OnCreate(); override;
    {Процедура вызывается каждый раз, когда объект достают из аккумулятора}
    procedure OnGet(); override;
    {Процедура вызывается, когда обект помещают в аккумулятор}
    procedure OnFree(); override;
  end;

  TpdBlocks = class (TpdAccum)
  public
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdDropBlock; reintroduce;

    procedure Update(const dt: Double);
  end;

implementation

uses
  SysUtils, uGlobal;

{ TglrDropObject }

const
  TIME_TO_LIVE = 15.0;
  TEXT_OFFSET_X = 0.0;
  TEXT_OFFSET_Y = -16.0;

procedure TpdDropBlock.OnCreate;
begin
  inherited;
  aSprite := Factory.NewSprite();

  aSprite.Material.Texture := texBlock;
  aSprite.PivotPoint := ppCenter;
  aSprite.UpdateTexCoords();
  aSprite.SetSizeToTextureSize();
  aSprite.Material.MaterialOptions.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1);
  aSprite.Z := Z_DROPOBJECTS;

  mainScene.RegisterElement(aSprite);

  OnFree();
end;

procedure TpdDropBlock.OnFree;
begin
  inherited;
  aSprite.Visible := False;
end;

procedure TpdDropBlock.OnGet;
begin
  inherited;
  asprite.Position := dfVec2f(Random(R.WindowWidth), Random(R.WindowHeight));
  case Random(4) of
    0: aSprite.Position := dfVec2f(-30, aSprite.Position.y);
    1: aSprite.Position := dfVec2f(aSprite.Position.x, -30);
    2: aSprite.Position := dfVec2f(R.WindowWidth + 30, aSprite.Position.y);
    3: aSprite.Position := dfVec2f(aSprite.Position.x, R.WindowHeight + 30);
  end;
  blockSpeed := BLOCK_SPEED_MIN + Random(BLOCK_SPEED_MAX - BLOCK_SPEED_MIN + 1);
  moveVec := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2) - aSprite.Position;
  moveVec.Normalize;
  aSprite.Rotation := moveVec.GetRotationAngle();
  aSprite.Material.MaterialOptions.Diffuse := colorGreen;
  aSprite.Visible := True;
end;

procedure TpdDropBlock.Update(const dt: Double);
begin
  if not FUsed then
    Exit();

  aSprite.Position := aSprite.Position + moveVec * dt * blockSpeed;
  if (player.planet.Position - aSprite.Position).Length < (player.planet.Width / 2) then
    Self.OnFree();
end;

{ TpdDrops }

function TpdBlocks.GetItem: TpdDropBlock;
begin
  Result := inherited GetItem() as TpdDropBlock;
end;

function TpdBlocks.NewAccumItem: TpdAccumItem;
begin
  Result := TpdDropBlock.Create();
end;

procedure TpdBlocks.Update(const dt: Double);
var
  i: Integer;
begin
  for i := 0 to High(Items) do
    (Items[i] as TpdDropBlock).Update(dt);
end;

end.

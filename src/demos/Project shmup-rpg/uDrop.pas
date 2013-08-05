unit uDrop;

interface

uses
  uGlobal, uAccum,
  dfHRenderer, dfMath;

const
  //FILE_AMMO_PISTOL     = RES_FOLDER + 'ammo_revolver.tga';

  DROPITEM_TIME_TO_DISAPPEAR = 10.0;
  DROPITEM_FADEOUT_TIME = 1.0;
  DROPITEM_COLLECT_RADIUS = 32 + 16; //необходимо учитывать также размер игрока

  SHOTGUN_AMMO_COUNT    = 10;
  MACHINEGUN_AMMO_COUNT = 30;
  WHISKEY_BOTTLE_HEALTH_AMOUNT = 20;

  //Шансы дропа патронов и бонусов с монстров в процентах
  SHOTGUN_AMMO_CHANCE = 9;
  MACHINEGUN_AMMO_CHANCE = 9;
  WHISKEY_BOTTLE_CHANCE = 5;

type

  TpdDropItemType = (dAmmoShotgun, dAmmoMG, dWhiskeyBottle);

  TpdDropItemAction = procedure;

  TpdDropItem = class (TpdAccumItem)
  public
    itemType: TpdDropItemType;
    sprite: IglrSprite;
    action: TpdDropItemAction;
    //Начальные размеры - для анимации исчезновения
    inWidth, inHeight: Single;
    //Стандартное время до исчезновения, осталось времени до исчезновения
    timeRemain: Single;
    procedure OnCreate(); override;
    procedure OnGet(); override;
    procedure OnFree(); override;
  end;

  TpdDropItems = class (TpdAccum)
  public
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdDropItem; reintroduce;
  end;

  procedure LoadDropItems();
  procedure InitDropItems(aScene: Iglr2DScene);
  procedure UpdateDropItems(const dt: Double);
  procedure FreeDropItems();

  //chanceMult - мультипликатор шанса спавна
  //Впоследствии, необходимо заменить другим способом
  //Так как из разных врагов по-разному выпадают разные патроны/бонусы
  procedure TrySpawnDropItem(const X, Y: Single; const chanceMult: Single);


var
  dropItems: TpdDropItems;
  scene: Iglr2DScene;

  //Для дебага - проверки сколько выпадает всяких бонусов
  dcWhiskey, dcShotgun, dcMG: Integer;

implementation

uses
  SysUtils,
  uWeapons, uPlayer, uPopup;

var
  texAmmoShotgun, texAmmoMG, texWhiskeyBottle: IglrTexture;

procedure actionAmmoShotgun();
var
  ammoAdd: Integer;
begin
  with weapons[SHOTGUN_INDEX], player.sprite.Position do
  begin
    ammoAdd := dfMath.Clamp(ammoMax - ammoLeft, 0, SHOTGUN_AMMO_COUNT);
    Inc(ammoLeft, ammoAdd);
    AddNewPopupEx(x, y, '+' + IntToStr(ammoAdd) + ' патронов дроби', dfVec3f(0.1, 0.6, 0.1));
  end;
end;

procedure actionAmmoMachineGun();
var
  ammoAdd: Integer;
begin
  with weapons[MACHINEGUN_INDEX], player.sprite.Position do
  begin
    ammoAdd := dfMath.Clamp(ammoMax - ammoLeft, 0, MACHINEGUN_AMMO_COUNT);
    Inc(ammoLeft, ammoAdd);
    AddNewPopupEx(x, y, '+' + IntToStr(ammoAdd) + ' патронов авт.', dfVec3f(0.1, 0.6, 0.1));
  end;
end;

procedure actionWhiskeyBottle();
var
  healthAdd: Integer;
begin
  healthAdd := dfMath.Clamp(player.healthMax - player.health, 0, WHISKEY_BOTTLE_HEALTH_AMOUNT);
  with player.sprite.Position do
    AddNewPopupEx(x, y, 'Ммм, виски...' + #10 + '+' + IntToStr(healthAdd) + ' здоровья', dfVec3f(0.6, 0.1, 0.1));
  Inc(player.health, healthAdd);
end;

procedure LoadTextures();
begin
  texAmmoShotgun := Factory.NewTexture();
  texAmmoShotgun.Load2D(FILE_DROP_AMMO_SHOTGUN);
  texAmmoShotgun.BlendingMode := tbmTransparency;
  texAmmoShotgun.CombineMode := tcmModulate;

  texAmmoMG := Factory.NewTexture();
  texAmmoMG.Load2D(FILE_DROP_AMMO_MACHINEGUN);
  texAmmoMG.BlendingMode := tbmTransparency;
  texAmmoMG.CombineMode := tcmModulate;

  texWhiskeyBottle := Factory.NewTexture();
  texWhiskeyBottle.Load2D(FILE_DROP_WHISKEY_BOTTLE);
  texWhiskeyBottle.BlendingMode := tbmTransparency;
  texWhiskeyBottle.CombineMode := tcmModulate;
end;

function InitDropItemSprite(): IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.PivotPoint := ppCenter;
  scene.RegisterElement(Result);
end;

procedure TrySpawnDropItem(const X, Y: Single; const chanceMult: Single);
var
  chance: Integer;
begin
  chance := Random(100);
  if chance < SHOTGUN_AMMO_CHANCE * chanceMult then
    //spawn shotgun ammo
    with dropItems.GetItem() do
    begin
      itemType := dAmmoShotgun;
      action := actionAmmoShotgun;
      sprite.Material.Texture := texAmmoShotgun;
      sprite.SetSizeToTextureSize();
      sprite.Position := dfVec2f(X, Y);
      inWidth := sprite.Width;
      inHeight:= sprite.Height;

      //debug
      dcShotgun := dcShotgun + 1;
    end

  else if chance < (MACHINEGUN_AMMO_CHANCE + SHOTGUN_AMMO_CHANCE) * chanceMult then
    //spawn mg ammo
    with dropItems.GetItem() do
    begin
      itemType := dAmmoMG;
      action := actionAmmoMachineGun;
      sprite.Material.Texture := texAmmoMG;
      sprite.SetSizeToTextureSize();
      sprite.Position := dfVec2f(X, Y);
      inWidth := sprite.Width;
      inHeight:= sprite.Height;

      //debug
      dcMG := dcMG + 1;
    end
  else if chance < (MACHINEGUN_AMMO_CHANCE + SHOTGUN_AMMO_CHANCE + WHISKEY_BOTTLE_CHANCE) * chanceMult then
    with dropItems.GetItem() do
    begin
      itemType := dWhiskeyBottle;
      action := actionWhiskeyBottle;
      sprite.Material.Texture := texWhiskeyBottle;
      sprite.SetSizeToTextureSize();
      sprite.Position := dfVec2f(X, Y);
      inWidth := sprite.Width;
      inHeight:= sprite.Height;

      //debug
      dcWhiskey := dcWhiskey + 1;
    end;

end;

//General

procedure LoadDropItems();
begin
  LoadTextures();
end;

procedure InitDropItems(aScene: Iglr2DScene);
begin
  scene := aScene;
  if Assigned(dropItems) then
    dropItems.Free;
  dropItems := TpdDropItems.Create(8);
end;

procedure UpdateDropItems(const dt: Double);

  function IsCollect(di: TpdDropItem): Boolean;
  begin
    Result := player.sprite.Position.Dist(di.sprite.Position) < DROPITEM_COLLECT_RADIUS;
  end;

var
  i: Integer;
begin
  for i := 0 to High(dropItems.Items) do
  if dropItems.Items[i].Used then
    with dropItems.Items[i] as TpdDropItem do
    begin
      if IsCollect(TpdDropItem(dropItems.Items[i])) then
      begin
        action();
        dropItems.FreeItem(dropItems.Items[i]);
      end;
      if timeRemain > 0 then
      begin
        timeRemain := timeRemain - dt;
        //Анимация исчезновения
        if timeRemain < DROPITEM_FADEOUT_TIME then
        begin
          sprite.Width := inWidth * (timeRemain / DROPITEM_FADEOUT_TIME);
          sprite.Height := inHeight * (timeRemain / DROPITEM_FADEOUT_TIME);
        end;
//        sprite.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, timeRemain / DROPITEM_TIME_TO_DISAPPEAR)
      end
      else
        dropItems.FreeItem(dropItems.Items[i])
    end;
end;

procedure FreeDropItems();
begin
  dropItems.Free;
  texAmmoShotgun := nil;
  texAmmoMG := nil;
  texWhiskeyBottle := nil;
end;

{ TpdDropItems }

function TpdDropItems.GetItem(): TpdDropItem;
begin
  Result := inherited GetItem() as TpdDropItem;
end;

function TpdDropItems.NewAccumItem(): TpdAccumItem;
begin
  Result := TpdDropItem.Create();
end;

{ TpdDropItem }

procedure TpdDropItem.OnCreate;
begin
  inherited;
  sprite := InitDropItemSprite();
  sprite.Visible := False;
  sprite.Z := Z_DROPS;
  timeRemain := 0;
end;

procedure TpdDropItem.OnFree;
begin
  inherited;
  sprite.Visible := False;
end;

procedure TpdDropItem.OnGet;
begin
  inherited;
  sprite.Visible := True;
  timeRemain := DROPITEM_TIME_TO_DISAPPEAR;
  sprite.SetSizeToTextureSize();
//  sprite.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
end;

end.

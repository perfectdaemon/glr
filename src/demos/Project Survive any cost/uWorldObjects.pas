unit uWorldObjects;

interface

uses
  glr, glrMath,
  uLevel_SaveLoad;

const
  //Единовременные бонусы при подъеме
  WIRE_ADDMIND_ONPICKUP     =  3.0;
  KNIFE_ADDMIND_ONPICKUP    = 11.0;
  BACKPACK_ADDMIND_ONPICKUP =  4.0;
  BOTTLE_ADDMIND_ONPICKUP   =  6.0;

  BERRY_BAD_CHANCE = 0.2; //Шанс плохой ягодки
  BERRY_BAD_ADD_HEALTH = -2.0; //ПЛохая ягодка убавляет здоровье
  BERRY_ADDHUNGER = 1.0; //Хорошая прибавляет голод, жжаду и запас сил
  BERRY_ADDTHIRST = 1.0;
  BERRY_ADDFATIGUE = 5.0;

  FLOWER_ADDHEALTH = 2.0;

  //Обычная, не кипяченая вода
  BOTTLE_ADDTHIRST = 9.0;
  BOTTLE_ADDHEALTH = -1.0;

  //Кипяченая
  BOTTLE_HOT_ADDTHIRST = 9.0;
  BOTTLE_HOT_ADDHEALTH = 0.5;

  //Заготовка для чая
  BOTTLE_RAWTEA_ADDTHIRST = 8.0;
  BOTTLE_RAWTEA_ADDHEALTH = BOTTLE_ADDHEALTH + FLOWER_ADDHEALTH;

  //Чай
  BOTTLE_TEA_ADDTHIRST = 8.0;
  BOTTLE_TEA_ADDHEALTH = 4.0;
  BOTTLE_TEA_ADDFATIGUE = 7.0;

  //Шанс, что попадется галюциногенный гриб
  MUSHROOM_CHANCE_OF_HALLUCINATION = 0.4;

  MUSHROOM_ADDHUNGER = 3.0; //если обычный гриб
  MUSHROOM_ADDMIND   = 12.0; //если галюциногенный. Может быть как плюс так и минус

  //Грибной шашлык (сырой и готовый)
  MUSHROOM_SHASHLIK_RAW_ADDHUNGER = 2 * MUSHROOM_ADDHUNGER;
  MUSHROOM_SHASHLIK_HOT_ADDHUNGER = 3.5 * MUSHROOM_ADDHUNGER;
  MUSHROOM_SHASHLIK_HOT_ADDFATIGUE = 10.0;

  //Рыба
  FISH_ADDHUNGER = 5.0;
  FISH_ADDHEALTH = -6.0;

  //Шашлык из рыбы (сырой и готовый)
  FISH_SHASHLIK_RAW_ADDHUNGER = FISH_ADDHUNGER;
  FISH_SHASHLIK_RAW_ADDHEALTH = 0.7 * FISH_ADDHEALTH; //считается чищенной

  FISH_SHASHLIK_HOT_ADDHUNGER = 2.5 * FISH_ADDHUNGER;
  FISH_SHASHLIK_HOT_ADDHEALTH = 4.0;
  FISH_SHASHLIK_HOT_ADDFATIGUE = 10.0;

  CAMPFIRE_TIME_TO_LIFE = 45.0; //Время жизни костра
  CAMPFIRE_TIME_ADD = 15.0;     //Сколько времени добавляется, когда в костер бросают ветку или сухую траву
  CAMPFIRE_REST_RADIUS = 100; //В данном радиусе (+ размер костра) у игрока быстрее восстанавливаются силы

  //В траве можно найти что-нибудь: змею, грибочек или ветку
  GRASS_SNAKE_CHANCE = 0.2;
  GRASS_SNAKE_ADDHEALTH = -10.0;
  GRASS_SNAKE_ADDMIND  = -10.0;

  GRASS_MUSHROOM_CHANCE = 0.2;
  GRASS_TWIG_CHANCE = 0.3;

  LITTLEBERRY_TEXTURE = 'object_bush_berry.png';

type
  //Статус объекта - в мире (лежит на земле и т.п) или в инвентаре
  //Это позволяет отдавать различные Hint
  TpdWorldObjectStatus = (sWorld, sInventory);

  TpdBB = record
    Left, Right, Top, Bottom: Single;
  end;

  //NOTE: При повороте объекта следует пересчитывать баундинг бокс
  //через RecalcBB
  TpdWorldObject = class
  protected
    bb: TpdBB;
    constructor Create(); virtual;
    destructor Destroy(); override;
    function GetHintText(): WideString; virtual; abstract;
  public
    sprite: IglrSprite;
    status: TpdWorldObjectStatus;
    removeOnUse: Boolean; //Исчезает ли при использовании
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; virtual; abstract;
    class function GetObjectSprite(): IglrSprite; virtual; abstract;

    procedure OnCollect(); virtual; //Действие при подъеме предмета
    procedure OnUse(); virtual; //Действие при использовании
    function IsInside(aPos: TdfVec2f): Boolean; virtual; //Проверка на попадание
    property HintText: WideString read GetHintText; //Подсказка при наведении
    procedure RecalcBB(); virtual; //Пересчитать ББ
  end;

  TpdWorldObjectClass = class of TpdWorldObject;

  //--Кустарник. Из него можно добыть ягоды
  TpdBush = class (TpdWorldObject)
  protected
    FScene: Iglr2DScene;
    FBerryCount: Integer;
    FBerries: array of IglrSprite;
    function GetHintText(): WideString; override;
    class function InitLittleBerry(): IglrSprite;
    procedure RemoveOnBerry();
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure RecalcBB(); override;
  end;

  //Ветка. Они используются для зажигания огня
  TpdTwig = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
  end;

  //Ромашка. Можно заварить во фляге над костром с водой - получится ромашковый чай
  TpdFlower = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

  //Грибочек. Утоляет голод, а также случайно может добавить или убавить силу духа
  //Депрессивный и веселый грибочки соответственно
  TpdMushroom = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

  //Старая (засохшая) трава
  //Нужная для разжигания костра
  TpdOldGrass = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
  end;

  //Нож. Просто полезная штука
  TpdKnife = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
  end;

  //Рюкзак. Дает возможность складывать вещи в инвентарь
  TpdBackpack = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    procedure OnCollect(); override;
  end;

  //Статус жидкости во фляге
  //Простая вода, кипяченая вода, заготовка для чая, чай
  TpdWaterStatus = (bsWater, bsHotWater, bsRawTea, bsTea);

  //Фляга. Позволяет набирать воду
  TpdBottle = class (TpdWorldObject)
  protected
    FNormTex, FTeaTex: IglrTexture;
    FWaterStatus: TpdWaterStatus;
    FWaterLevel: Integer;
    procedure SetWaterLevel(const Value: Integer);
    procedure SetWaterStatus(const Value: TpdWaterStatus);
    procedure SetTexture(aTex: IglrTexture);
    function GetHintText(): WideString; override;
  public
    //0-5 (выводится как 0 - 500 мл)
    property WaterLevel: Integer read FWaterLevel write SetWaterLevel;
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
    procedure FillWithWater();

    property WaterStatus: TpdWaterStatus read FWaterStatus write SetWaterStatus;
  end;

  //Моток лески. Пригодится для создания удочки
  TpdWire = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
  end;

  //Ягода. Сама по себе не валяется, встречается на кустах
  TpdBerry = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

  //Обычная трава, взять нельзя, но может можно найти что-нибудь интересное в ней?
  TpdNewGrass = class (TpdWorldObject)
  protected
    alreadySearch: Boolean;
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    procedure OnCollect(); override;
  end;

  //Рыба
  TpdFish = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;


  {
    СКРАФЧЕННЫЕ ИТЕМЫ
  }

  //Острая ветка
  TpdSharpTwig = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
  end;

  //Удочка
  TpdFishRod = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

  //Шашлык из грибов (сырой)
  TpdMushroomShashlikRaw = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

  //Шашлык из грибов (готовый)
  TpdMushroomShashlikHot = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

  //Шашлык из рыбы (сырой)
  TpdFishShashlikRaw = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

  //Шашлык из рыбы (готовый)
  TpdFishShashlikHot = class (TpdWorldObject)
  protected
    function GetHintText(): WideString; override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

  //Костер
  TpdCampFire = class (TpdWorldObject)
  protected
    lifeSpr: IglrSprite;
    function GetHintText(): WideString; override;
  public
    timeToLife: Single; //Оставшееся время горения костра
    restRadius: Single;
    class function Initialize(aScene: Iglr2DScene): TpdWorldObject; override;
    class function GetObjectSprite(): IglrSprite; override;
    procedure OnCollect(); override;
    procedure RecalcBB(); override;
  end;

  procedure InitializeWorldObjects(aSURFile: TSURFile);
  procedure DeinitializeWorldObjects();
  function GetWorldObjectAtPosition(aPos: TdfVec2f): TpdWorldObject;
  procedure UpdateWorldObjects(const dt: Double);
  function WorldObjectsOnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState): Boolean;
  function WorldObjectsOnMouseDown(X, Y: Integer;  MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState): Boolean;

  //for editor mode uses only
  procedure _SaveWorldObjects(var aSurFile: TSURFile);

  function AddNewWorldObject(aClass: TpdWorldObjectClass): TpdWorldObject;
  procedure DeleteWorldObject(aObject: TpdWorldObject);

  procedure NoPlaceToPut();

var
  worldObjects: array of TpdWorldObject;
  selectedWorldObject: TpdWorldObject;

implementation

uses
  SysUtils,
  uInventory, uPlayer, uWater,
  uGlobal;

var
  //Указывают на то, что в предметы уже поднимались (True) или нет (False)
  //Для предотвращения многократных бонусов к разуму - поднял, выкинул, поднял...
  knifeFirstPickup, wireFirstPickup, bottleFirstPickup: Boolean;


procedure NoPlaceToPut();
begin
  player.speech.Say('Некуда класть...', 3, colorRed, true);
  if not inventory.Visible then
    inventory.Visible := True;
end;

{ TpdWorldObject }

constructor TpdWorldObject.Create;
begin
  inherited Create();
  sprite := Factory.NewSprite();
  sprite.PivotPoint := ppCenter;
  sprite.PPosition.z := Z_STATICOBJECTS;
  status := sWorld;
  removeOnUse := True;
end;

destructor TpdWorldObject.Destroy;
begin
  sprite := nil;
  inherited;
end;

function TpdWorldObject.IsInside(aPos: TdfVec2f): Boolean;
begin
  Result := ( (aPos.x > bb.Left) and (aPos.x < bb.Right) )
       and( (aPos.y > bb.Top) and (aPos.y < bb.Bottom) );
end;

procedure TpdWorldObject.OnCollect;
begin
  DeleteWorldObject(Self);
end;

procedure TpdWorldObject.OnUse;
begin

end;

procedure TpdWorldObject.RecalcBB;
var
  i: Integer;
begin
  with sprite do
  begin
    bb.Left := 1/0;
    for i := 0 to 3 do
      if (Coords[i].x + Position.x) < bb.Left then
        bb.Left := Position.x + Coords[i].x;
    bb.Right := - 1/0;
    for i := 0 to 3 do
      if (Coords[i].x + Position.x) > bb.Right then
        bb.Right := Position.x + Coords[i].x;
    bb.Top :=  1/0;
    for i := 0 to 3 do
      if (Coords[i].y + Position.y) < bb.Top then
        bb.Top := Position.y + Coords[i].y;
    bb.Bottom := - 1/0;
    for i := 0 to 3 do
      if (Coords[i].y + Position.y) > bb.Bottom then
        bb.Bottom := Position.y + Coords[i].y;
  end;
end;

{ TpdBush }

const
  BERRIES_COORDS: array[0..4] of TdfVec2f =
  ((x: -25; y: -20), (x: 25; y: 20),
   (x: -25; y: 20), (x: 0; y: 0),
   (x: 25; y: -20)
  );

function TpdBush.GetHintText: WideString;
begin
  if FBerryCount > 0 then
    Result := 'Куст с ягодой (ягод: ' + IntToStr(FBerryCount) + ')'#13#10 + TEXT_LMB_COLLECT
  else
    Result := 'Куст без ягод';
end;

class function TpdBush.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(BUSH_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdBush.Initialize(aScene: Iglr2DScene): TpdWorldObject;
var
  i: Integer;
begin
  Result := TpdBush.Create();
  with Result as TpdBush do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(BUSH_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.PPosition.z := sprite.PPosition.z - 2;
    aScene.RootNode.AddChild(sprite);

    FBerryCount := 1 + Random(5);
    FScene := aScene;
    SetLength(FBerries, FBerryCount);
    for i := 0 to FBerryCount - 1 do
    begin
      FBerries[i] := InitLittleBerry();
      FScene.RootNode.AddChild(FBerries[i]);
    end;
  end;
end;

class function TpdBush.InitLittleBerry: IglrSprite;
begin
  Result := Factory.NewSprite();
  with Result do
  begin
    Material.Texture := atlasGame.LoadTexture(LITTLEBERRY_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    PivotPoint := ppCenter;
    PPosition.z := Z_STATICOBJECTS + 1;
  end;
end;

procedure TpdBush.OnCollect;
begin
  if FBerryCount > 0 then
    case inventory.AddObject(TpdBerry) of
      INV_OK:
      begin
        RemoveOnBerry();
      end;
      INV_NO_SLOTS: NoPlaceToPut();
      INV_MAX_CAPACITY: player.speech.Say('Больше не возьму, а то подавлю!', 3, colorYellow);
    end
  else
    player.speech.Say('Больше ягод не видно', 3);
end;

procedure TpdBush.RecalcBB;
var
  i: Integer;
begin
  inherited;
  //ыыы, хак
  for i := 0 to FBerryCount - 1 do
    FBerries[i].Position2D := sprite.Position2D
      + BERRIES_COORDS[i]
      + dfVec2f(6 - Random(13), 6 - Random(13));
end;

procedure TpdBush.RemoveOnBerry;
begin
   FBerryCount := FBerryCount - 1;
   FScene.RootNode.RemoveChild(FBerries[High(FBerries)]);
   SetLength(FBerries, High(FBerries));
end;

{ TpdTwig }

function TpdTwig.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Ветка.'#13#10 + TEXT_LMB_GET;
    sInventory: Result := 'Ветка.'#13#10'Точно пригодится для'#13#10'розжига костра.';
  end;
end;

class function TpdTwig.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(TWIG_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.Rotation := 35;
  Result.PivotPoint := ppCenter;
end;

class function TpdTwig.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdTwig.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(TWIG_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    //sprite.Rotation := 90 - Random(180);
    aScene.RootNode.AddChild(sprite);
    removeOnUse := False;
  end;
end;

procedure TpdTwig.OnCollect;
begin
  case inventory.AddObject(TpdTwig) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('У меня тут веток'#13#10'на шалаш хватит!', 3, colorYellow);
  end;
end;

{ TpdMushroom }

function TpdMushroom.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Гриб.'#13#10 + TEXT_LMB_COLLECT;
    sInventory: Result := 'Гриб.'#13#10'Кажется, подберезовик...'#13#10 + TEXT_RMB_EAT;
  end;
end;

class function TpdMushroom.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(MUSHROOM_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdMushroom.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdMushroom.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(MUSHROOM_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    aScene.RootNode.AddChild(sprite);
    removeOnUse := True;
  end;
end;

procedure TpdMushroom.OnCollect;
begin
  case inventory.AddObject(TpdMushroom) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Не-е, с грибами пора завязывать...', 3, colorYellow);
  end;
end;

procedure TpdMushroom.OnUse;
var
  isHal, isGood: Boolean;
begin
  inherited;
  isHal := Random() < MUSHROOM_CHANCE_OF_HALLUCINATION; //Галюциногенный или нет
  if isHal then
  begin
    isGood := Random() < 0.5; //Хороший галюциногенный или нет
    if isGood then
    begin
      player.speech.Say('У-у-ух. Какоооой'#13#10'хорооооший грибоооочек...', 4, colorGreen);
      player.AddParam(pMind, MUSHROOM_ADDMIND);
    end
    else
    begin
      player.speech.Say('Нет, не трогай меня! Неееет!'#13#10'НЕЕЕЕЕЕЕЕЕЕЕЕЕТ!', 4, colorRed);
      player.AddParam(pMind, -2 * MUSHROOM_ADDMIND);
    end;
  end
  else
    player.AddParam(pHunger, MUSHROOM_ADDHUNGER);
end;

{ TpdFlower }

function TpdFlower.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Ромашка.'#13#10 + TEXT_LMB_COLLECT;
    sInventory: Result := 'Ромашка.'#13#10'Любит, не любит?..'#13#10 + TEXT_RMB_EAT;
  end;
end;

class function TpdFlower.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(FLOWER_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdFlower.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdFlower.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(FLOWER_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    aScene.RootNode.AddChild(sprite);
    removeOnUse := True;
  end;
end;

procedure TpdFlower.OnCollect;
begin
  case inventory.AddObject(TpdFlower) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Хватит цветов, у меня уже аллергия!'#13#10'Да и дарить-то некому', 3, colorYellow);
  end;
end;

procedure TpdFlower.OnUse;
begin
  inherited;
  player.speech.Say('Мне кажется, что это можно'#13#10'употреблять по-другому...', 4);
  player.AddParam(pHealth, FLOWER_ADDHEALTH);
end;

{ TpdOldGrass }

function TpdOldGrass.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Старая пожухлая трава.'#13#10 + TEXT_LMB_COLLECT;
    sInventory: Result := 'Старая пожухлая трава.'#13#10'Отлично горит.';
  end;
end;

class function TpdOldGrass.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(OLDGRASS_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdOldGrass.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdOldGrass.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(OLDGRASS_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    aScene.RootNode.AddChild(sprite);
    removeOnUse := False;
  end;
end;


procedure TpdOldGrass.OnCollect;
begin
  case inventory.AddObject(TpdOldGrass) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Я не Боб Марли,'#13#10'куда мне столько травы?', 3, colorYellow);
  end;
end;

{ TpdKnife }

function TpdKnife.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Нож!'#13#10 + TEXT_LMB_GET;
    sInventory: Result := 'Здоровенный нож.'#13#10'Совсем как у Рэмбо.'#13#10'С таким не страшно.';
  end;
end;

class function TpdKnife.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(KNIFE_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.Rotation := 35;
  Result.PivotPoint := ppCenter;
end;

class function TpdKnife.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdKnife.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(KNIFE_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    aScene.RootNode.AddChild(sprite);
    removeOnUse := False;
  end;
end;

procedure TpdKnife.OnCollect;
begin
  case inventory.AddObject(TpdKnife) of
    INV_OK:
    begin
      if not knifeFirstPickup then
      begin
        player.speech.Say('Осталось припомнить, что обычно'#13#10'этим ножом делал Беар Гриллс', 5);
        player.AddParam(pMind, KNIFE_ADDMIND_ONPICKUP);
        knifeFirstPickup := True;
      end;
      inherited OnCollect();
    end;
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: ;
  end;
end;

{ TpdBackpack }

function TpdBackpack.GetHintText: WideString;
begin
  Result := 'Смахивает на какой-то рюкзак'#13#10 + TEXT_LMB_GET;
end;

class function TpdBackpack.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdBackpack.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(BACKPACK_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    aScene.RootNode.AddChild(sprite);
  end;
end;

procedure TpdBackpack.OnCollect;
begin
  player.speech.Say('Йо-хо-хо, теперь у меня есть рюкзак!', 5);
  player.AddParam(pMind, BACKPACK_ADDMIND_ONPICKUP);
  player.SetTextureWithBackpack();
  inventory.AddSlots(9);
  if inventory.Visible then
    inventory.Visible := False;
  inventory.Visible := True;
  inherited OnCollect();
end;

{ TpdBottle }

procedure TpdBottle.FillWithWater;
begin
  WaterLevel := 5;
  if WaterStatus in [bsHotWater, bsTea] then
    WaterStatus := bsWater;
  player.speech.Say('Залил до краев!', 3);
end;

function TpdBottle.GetHintText: WideString;
var
  rmbText: WideString;
begin
  case status of
    sWorld: Result := 'Фляга.'#13#10'Может, внутри что-нибудь осталось?'#13#10 + TEXT_LMB_GET;
    sInventory:
    begin
      if player.inWater then
        rmbText := TEXT_RMB_FULFILL
      else
        rmbText := TEXT_RMB_DRINK;
      case WaterStatus of
        bsWater: Result := 'Фляга, 500 мл.'#13#10'Воды: ' + IntToStr(FWaterLevel * 100) +' мл.'#13#10 + rmbText;
        bsHotWater: Result := 'Фляга, 500 мл.'#13#10'Кипяченой воды: ' + IntToStr(FWaterLevel * 100) +' мл.'#13#10 + rmbText;
        bsRawTea: Result := 'Фляга, 500 мл.'#13#10'Воды с ромашкой: ' + IntToStr(FWaterLevel * 100) +' мл.'#13#10 + rmbText;
        bsTea: Result := 'Фляга, 500 мл.'#13#10'Чая: ' + IntToStr(FWaterLevel * 100) +' мл.'#13#10 + rmbText;
      end;
    end;
  end;
end;

class function TpdBottle.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(BOTTLE_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdBottle.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdBottle.Create();
  with Result as TpdBottle do
  begin
    FNormTex := atlasGame.LoadTexture(BOTTLE_TEXTURE);
    FTeaTex := atlasGame.LoadTexture(BOTTLE_TEA_TEXTURE);
    SetTexture(FNormTex);
    aScene.RootNode.AddChild(sprite);
    removeOnUse := False;
    WaterLevel := 0;
    FWaterStatus := bsWater;
  end;
end;

procedure TpdBottle.OnCollect;
begin
  case inventory.AddObject(TpdBottle) of
    INV_OK:
    begin
      if not bottleFirstPickup then
      begin
        player.speech.Say('15 человек на сундук мертвеца!'#13#10'Йо-хо-хо! И бутылка... а нет, без рома', 7);
        player.AddParam(pMind, BOTTLE_ADDMIND_ONPICKUP);
        bottleFirstPickup := True;
      end;
      with (inventory.GetSlotWithItem(TpdBottle).item as TpdBottle) do
      begin
        WaterLevel := Self.WaterLevel;
        WaterStatus := Self.WaterStatus;
      end;
      inherited OnCollect();
    end;
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: ;
  end;
end;

procedure TpdBottle.OnUse;
begin
  inherited;
  //Если в воде, то наполняем фляжку
  if player.inWater then
  begin
    FillWithWater();
    Exit();
  end;

  if FWaterLevel > 0 then
  begin
    case WaterStatus of
      bsWater:
      begin
        player.AddParam(pThirst, BOTTLE_ADDTHIRST);
        player.AddParam(pHealth, BOTTLE_ADDHEALTH);
      end;
      bsHotWater:
      begin
        player.AddParam(pThirst, BOTTLE_HOT_ADDTHIRST);
        player.AddParam(pHealth, BOTTLE_HOT_ADDHEALTH);
      end;
      bsRawTea:
      begin
        player.AddParam(pThirst, BOTTLE_RAWTEA_ADDTHIRST);
        player.AddParam(pHealth, BOTTLE_RAWTEA_ADDHEALTH);
      end;
      bsTea:
      begin
        player.AddParam(pThirst, BOTTLE_TEA_ADDTHIRST);
        player.AddParam(pHealth, BOTTLE_TEA_ADDHEALTH);
        player.AddParam(pFatigue, BOTTLE_TEA_ADDFATIGUE);
      end;
    end;
    Dec(FWaterLevel);
    //Меняем фляжку на обычную
    if WaterLevel = 0 then
      WaterStatus := bsWater;
  end
  else
    player.speech.Say('Во фляжке пусто', 3);
end;

procedure TpdBottle.SetTexture(aTex: IglrTexture);
begin
  sprite.Material.Texture := aTex;
  sprite.UpdateTexCoords();
  sprite.SetSizeToTextureSize();
end;

procedure TpdBottle.SetWaterLevel(const Value: Integer);
begin
  FWaterLevel := Clamp(Value, 0, 5);
end;

procedure TpdBottle.SetWaterStatus(const Value: TpdWaterStatus);
begin
  if FWaterStatus <> Value then
  begin
    FWaterStatus := Value;
    if FWaterStatus in [bsRawTea, bsTea] then
      SetTexture(FTeaTex)
    else
      SetTexture(FNormTex);
  end;
end;

{ TpdWire }

function TpdWire.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Что-то блестит в траве'#13#10 + TEXT_LMB_GET;
    sInventory: Result := 'Прочная леска.'#13#10'Хоть удочку делай';
  end;
end;

class function TpdWire.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(WIRE_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdWire.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdWire.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(WIRE_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.ScaleMult(0.6);
    aScene.RootNode.AddChild(sprite);
    removeOnUse := True;
  end;
end;

procedure TpdWire.OnCollect;
begin
  case inventory.AddObject(TpdWire) of
    INV_OK:
    begin
      if not wireFirstPickup then
      begin
        player.speech.Say('Струна есть. Нужна пара деревяшек'#13#10'и штрихкод на затылок', 7);
        player.AddParam(pMind, WIRE_ADDMIND_ONPICKUP);
        wireFirstPickup := True;
      end;
      inherited OnCollect();
    end;
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: ;
  end;
end;


{ TpdBerry }

function TpdBerry.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Ягода'#13#10 + TEXT_LMB_COLLECT;
    sInventory: Result := 'Ягода.'#13#10'Весьма съедобна на вид.'#13#10 + TEXT_RMB_EAT;
  end;
end;

class function TpdBerry.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(BERRY_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdBerry.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdBerry.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(BERRY_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    aScene.RootNode.AddChild(sprite);
    removeOnUse := True;
  end;
end;

procedure TpdBerry.OnCollect;
begin
  case inventory.AddObject(TpdBerry) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Больше не возьму, а то подавлю!', 3, colorYellow);
  end;
end;


procedure TpdBerry.OnUse;
begin
  inherited;
  if Random() < BERRY_BAD_CHANCE then
  begin
    player.AddParam(pHealth, BERRY_BAD_ADD_HEALTH);
    player.AddParam(pHunger, -BERRY_ADDHUNGER);
    player.AddParam(pThirst, - 2 * BERRY_ADDTHIRST);
    player.speech.Say('Черт, кажется плохая попалась...', 3, colorRed);
  end
  else
  begin
    player.AddParam(pHunger, BERRY_ADDHUNGER);
    player.AddParam(pThirst, BERRY_ADDTHIRST);
    player.AddParam(pFatigue, BERRY_ADDFATIGUE);
  end;
end;

{ TpdNewGrass }

function TpdNewGrass.GetHintText: WideString;
begin
  Result := 'Обычная трава.'#13#10'ЛКМ — поискать что-нибудь';
end;

class function TpdNewGrass.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdNewGrass.Create();
  with Result as TpdNewGrass do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(NEWGRASS_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.PPosition.z := sprite.PPosition.z - 1;
    aScene.RootNode.AddChild(sprite);

    alreadySearch := False;
  end;
end;

procedure TpdNewGrass.OnCollect;
var
  chance: Single;
begin
  if alreadySearch then
    player.speech.Say('Тут я уже смотрел', 3)
  else
  begin
    chance := Random();
    if chance < GRASS_SNAKE_CHANCE then
    begin
      player.speech.Say('А-А-А! Меня что-то УКУСИЛО!', 3, colorRed);
      player.AddParam(pHealth, GRASS_SNAKE_ADDHEALTH);
      player.AddParam(pMind, GRASS_SNAKE_ADDMIND);
    end
    else if chance < GRASS_SNAKE_CHANCE + GRASS_MUSHROOM_CHANCE then
    begin
      player.speech.Say('Ух ты, грибочек!', 3);
      with AddNewWorldObject(TpdMushroom) do
      begin
        sprite.Position2D := Self.sprite.Position2D + dfVec2f(4 - Random(9), 4 - Random(9));
        sprite.Rotation := 10 - Random(20);
        RecalcBB();
      end;
    end
    else if chance < GRASS_SNAKE_CHANCE + GRASS_MUSHROOM_CHANCE + GRASS_TWIG_CHANCE then
    begin
      player.speech.Say('Отличная ветка!', 3);
      with AddNewWorldObject(TpdTwig) do
      begin
        sprite.Position2D := Self.sprite.Position2D + dfVec2f(15 - Random(31), 15 - Random(31));
        sprite.Rotation := 70 - Random(141);
        RecalcBB();
      end;
    end
    else
      player.speech.Say('Эх, тут совсем ничего нет', 3);
    alreadySearch := True;
  end;

//  player.speech.Say('Сюда можно было бы справить'#13#10'нужду, если бы создатель'#13#10'это предусмотрел', 6);
end;

{ TpdFish }

function TpdFish.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Рыба'#13#10 + TEXT_LMB_GET;
    sInventory: Result := 'Рыба.'#13#10'В сыром виде, несомненно,'#13#10'вредна для здоровья'#13#10 + TEXT_RMB_EAT;
  end;
end;

class function TpdFish.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(FISH_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
  Result.Rotation := 40;
end;

class function TpdFish.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdFish.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(FISH_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.Rotation := 40;
    aScene.RootNode.AddChild(sprite);
  end;
end;

procedure TpdFish.OnCollect;
begin
  case inventory.AddObject(TpdFish) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Довольно! У меня уже'#13#10'целый аквариум этих рыб!', 3, colorYellow);
  end;
end;

procedure TpdFish.OnUse;
begin
  inherited;
  player.AddParam(pHunger, FISH_ADDHUNGER);
  player.AddParam(pHealth, FISH_ADDHEALTH);
end;

{ TpdSharpTwig }

function TpdSharpTwig.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Острая ветка'#13#10 + TEXT_LMB_COLLECT;
    sInventory: Result := 'Острая ветка.'#13#10'Можно что-нибудь ей'#13#10'проткнуть. Например, палец...';
  end;
end;

class function TpdSharpTwig.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(SHARP_TWIG_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
  Result.Rotation := -40;
end;

class function TpdSharpTwig.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdSharpTwig.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(SHARP_TWIG_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.Rotation := -40;
    aScene.RootNode.AddChild(sprite);

    removeOnUse := False;
  end;
end;

procedure TpdSharpTwig.OnCollect;
begin
  case inventory.AddObject(TpdSharpTwig) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Хватит с меня острых палок!', 3, colorYellow);
  end;
end;


{ TpdFishRod }

function TpdFishRod.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Самодельная удочка'#13#10 + TEXT_LMB_COLLECT;
    sInventory:
      if player.inWater then
        Result := 'Самодельная удочка.'#13#10 + TEXT_RMB_GETFISH
      else
        Result := 'Самодельная удочка.'#13#10'Можно и на рыбалку.';
  end;
end;

class function TpdFishRod.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(FISHROD_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdFishRod.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdFishRod.Create();
  with Result do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(FISHROD_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    aScene.RootNode.AddChild(sprite);
    removeOnUse := False;
  end;
end;

procedure TpdFishRod.OnCollect;
begin
  case inventory.AddObject(TpdFishRod) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Ошибка, такого быть не должно', 3);
  end;
end;

procedure TpdFishRod.OnUse;
begin
  inherited;
  if Assigned(playerInWater) and (playerInWater.fishCount > 0) then
    case inventory.AddObject(TpdFish) of
      INV_OK:
      begin
        player.speech.Say('Ребята, здоровенный язь!', 3);
        playerInWater.GetOneFish();
      end;
      INV_NO_SLOTS: NoPlaceToPut();
      INV_MAX_CAPACITY: player.speech.Say('Довольно! У меня уже'#13#10'целый аквариум этих рыб!', 3, colorYellow);
    end
  else
    player.speech.Say('Кажется, здесь уже нет рыбы', 3);
end;

{ TpdMushroomShashlik }

function TpdMushroomShashlikRaw.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Сырой шашлык из грибов'#13#10 + TEXT_LMB_GET;
    sInventory: Result := 'Сырой шашлык из грибов'#13#10'Лучше пожарить'#13#10 + TEXT_RMB_EAT;
  end;
end;

class function TpdMushroomShashlikRaw.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(MUSHROOM_SHASHLIK_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
  Result.Rotation := 40;
end;

class function TpdMushroomShashlikRaw.Initialize(
  aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdMushroomShashlikRaw.Create();
  with Result as TpdMushroomShashlikRaw do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(MUSHROOM_SHASHLIK_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.Rotation := 40;
    aScene.RootNode.AddChild(sprite);
    removeOnUse := True;
  end;
end;

procedure TpdMushroomShashlikRaw.OnCollect;
begin
  case inventory.AddObject(TpdMushroomShashlikRaw) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('У меня тут уже перебор'#13#10'по шашлыкам', 3, colorYellow);
  end;
end;

procedure TpdMushroomShashlikRaw.OnUse;
begin
  inherited;
  player.AddParam(pHunger, MUSHROOM_SHASHLIK_RAW_ADDHUNGER);
  player.speech.Say('Неплохо, но лучше бы пожарить', 3);
end;

{ TpdMushroomShashlikHot }

function TpdMushroomShashlikHot.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Готовый шашлык из грибов'#13#10 + TEXT_LMB_GET;
    sInventory: Result := 'Готовый шашлык из грибов'#13#10'Выглядит страшновато'#13#10 + TEXT_RMB_EAT;
  end;
end;

class function TpdMushroomShashlikHot.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(MUSHROOM_SHASHLIK_READY_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
  Result.Rotation := 40;
end;

class function TpdMushroomShashlikHot.Initialize(
  aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdMushroomShashlikHot.Create();
  with Result as TpdMushroomShashlikHot do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(MUSHROOM_SHASHLIK_READY_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.Rotation := 40;
    aScene.RootNode.AddChild(sprite);
    removeOnUse := True;
  end;
end;

procedure TpdMushroomShashlikHot.OnCollect;
begin
  case inventory.AddObject(TpdMushroomShashlikHot) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('У меня тут уже перебор'#13#10'по шашлыкам', 3, colorYellow);
  end;
end;

procedure TpdMushroomShashlikHot.OnUse;
begin
  inherited;
  player.AddParam(pHunger, MUSHROOM_SHASHLIK_HOT_ADDHUNGER);
  player.AddParam(pFatigue, MUSHROOM_SHASHLIK_HOT_ADDFATIGUE);
  player.speech.Say('На вкус лучше, чем на вид', 3);
end;


{ TpdFishShashlik }

function TpdFishShashlikRaw.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Сырой шашлык из рыбы'#13#10 + TEXT_LMB_GET;
    sInventory: Result := 'Сырой шашлык из рыбы'#13#10'Обжарить бы...'#13#10 + TEXT_RMB_EAT;
  end;
end;

class function TpdFishShashlikRaw.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(FISH_SHASHLIK_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
  Result.Rotation := 40;
end;

class function TpdFishShashlikRaw.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdFishShashlikRaw.Create();
  with Result as TpdFishShashlikRaw do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(FISH_SHASHLIK_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.Rotation := 40;
    aScene.RootNode.AddChild(sprite);
    removeOnUse := True;
  end;
end;

procedure TpdFishShashlikRaw.OnCollect;
begin
  case inventory.AddObject(TpdFishShashlikRaw) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('У меня тут уже перебор'#13#10'по шашлыкам', 3, colorYellow);
  end;
end;

procedure TpdFishShashlikRaw.OnUse;
begin
  inherited;
  player.AddParam(pHunger, FISH_SHASHLIK_RAW_ADDHUNGER);
  player.AddParam(pHealth, FISH_SHASHLIK_RAW_ADDHEALTH);
  player.speech.Say('Сырая рыба на палке, фу...', 3);
end;

{ TpdFishShashlikHot }

function TpdFishShashlikHot.GetHintText: WideString;
begin
  case status of
    sWorld: Result := 'Готовый шашлык из рыбы'#13#10 + TEXT_LMB_GET;
    sInventory: Result := 'Готовый шашлык из рыбы'#13#10'Выглядит аппетитно!'#13#10 + TEXT_RMB_EAT;
  end;
end;

class function TpdFishShashlikHot.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(FISH_SHASHLIK_READY_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
  Result.Rotation := 40;
end;

class function TpdFishShashlikHot.Initialize(
  aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdFishShashlikHot.Create();
  with Result as TpdFishShashlikHot do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(FISH_SHASHLIK_READY_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.Rotation := 40;
    aScene.RootNode.AddChild(sprite);
    removeOnUse := True;
  end;
end;

procedure TpdFishShashlikHot.OnCollect;
begin
  case inventory.AddObject(TpdFishShashlikHot) of
    INV_OK: inherited OnCollect();
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('У меня тут уже перебор'#13#10'по шашлыкам', 3, colorYellow);
  end;
end;

procedure TpdFishShashlikHot.OnUse;
begin
  inherited;
  player.AddParam(pHunger, FISH_SHASHLIK_HOT_ADDHUNGER);
  player.AddParam(pHunger, FISH_SHASHLIK_HOT_ADDHEALTH);
  player.AddParam(pFatigue, FISH_SHASHLIK_HOT_ADDFATIGUE);
  player.speech.Say('Превосходный шашлык!', 3);
end;


{ TpdCampFire }

function TpdCampFire.GetHintText: WideString;
begin
  Result := 'Костер.'#13#10'Рядом лучше отдыхается.'#13#10'На нем можно что-нибудь пожарить';
end;

class function TpdCampFire.GetObjectSprite: IglrSprite;
begin
  Result := Factory.NewSprite();
  Result.Material.Texture := atlasGame.LoadTexture(CAMPFIRE_TEXTURE);
  Result.UpdateTexCoords();
  Result.SetSizeToTextureSize();
  Result.PivotPoint := ppCenter;
end;

class function TpdCampFire.Initialize(aScene: Iglr2DScene): TpdWorldObject;
begin
  Result := TpdCampFire.Create();
  with Result as TpdCampFire do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(CAMPFIRE_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize();
    sprite.PPosition.z := sprite.Position.z - 1;
    aScene.RootNode.AddChild(sprite);

    timeToLife := CAMPFIRE_TIME_TO_LIFE;
    restRadius := CAMPFIRE_REST_RADIUS + (sprite.Width + sprite.Height) / 4;

    lifeSpr := Factory.NewSprite();
    lifeSpr.PPosition.z := Z_STATICOBJECTS + 1;
    lifeSpr.Width := sprite.Width;
    lifespr.Height := 5;
    lifespr.Material.Diffuse := colorRed;
    aScene.RootNode.AddChild(lifeSpr);
  end;
end;

procedure TpdCampFire.OnCollect;
begin
  //Нельзя просто так взять и собрать огонь :)
end;


procedure TpdCampFire.RecalcBB;
begin
  inherited;
  lifeSpr.Position2D := sprite.Position2D + dfVec2f(-sprite.Width / 2, 30);
end;

//--Общие функции


procedure InitializeWorldObjects(aSURFile: TSURFile);
var
  i: Integer;
begin
  knifeFirstPickup := False;
  wireFirstPickup := False;
  bottleFirstPickup := False;
  if Length(worldObjects) > 0 then
    for i := 0 to High(worldObjects) do
      worldObjects[i].Free();
  selectedWorldObject := nil;

  SetLength(worldObjects, Length(aSURFile.Objects));
  for i := 0 to High(worldObjects) do
  begin
    case aSURFile.Objects[i].aType of
      SUR_OBJ_BUSH:     worldObjects[i] := TpdBush.Initialize(mainScene);
      SUR_OBJ_TWIG:     worldObjects[i] := TpdTwig.Initialize(mainScene);
      SUR_OBJ_FLOWER:   worldObjects[i] := TpdFlower.Initialize(mainScene);
      SUR_OBJ_MUSHROOM: worldObjects[i] := TpdMushroom.Initialize(mainScene);
      SUR_OBJ_OLDGRASS: worldObjects[i] := TpdOldGrass.Initialize(mainScene);
      SUR_OBJ_BACKPACK: worldObjects[i] := TpdBackpack.Initialize(mainScene);
      SUR_OBJ_BOTTLE:   worldObjects[i] := TpdBottle.Initialize(mainScene);
      SUR_OBJ_KNIFE:    worldObjects[i] := TpdKnife.Initialize(mainScene);
      SUR_OBJ_WIRE:     worldObjects[i] := TpdWire.Initialize(mainScene);
      SUR_OBJ_NEWGRASS: worldObjects[i] := TpdNewGrass.Initialize(mainScene);

      SUR_OBJ_IGNORE: Continue;
      else Continue;
    end;
    worldObjects[i].sprite.Position2D := aSurFile.Objects[i].aPos;
    worldObjects[i].sprite.Rotation := aSurFile.Objects[i].aRot;
  end;

  for i := 0 to High(worldObjects) do
    if not Assigned(worldObjects[i]) then
      DeleteWorldObject(worldObjects[i])
    else
      worldObjects[i].RecalcBB();
end;

procedure _SaveWorldObjects(var aSurFile: TSURFile);

  function ClassTypeToByte(aClassType: TClass): Byte;
  begin
    Result := SUR_OBJ_IGNORE;
    if aClassType = TpdBush then Exit(SUR_OBJ_BUSH);
    if aClassType = TpdTwig then Exit(SUR_OBJ_TWIG);
    if aClassType = TpdFlower then Exit(SUR_OBJ_FLOWER);
    if aClassType = TpdMushroom then Exit(SUR_OBJ_MUSHROOM);
    if aClassType = TpdOldGrass then Exit(SUR_OBJ_OLDGRASS);
    if aClassType = TpdKnife then Exit(SUR_OBJ_KNIFE);
    if aClassType = TpdBackpack then Exit(SUR_OBJ_BACKPACK);
    if aClassType = TpdBottle then Exit(SUR_OBJ_BOTTLE);
    if aClassType = TpdWire then Exit(SUR_OBJ_WIRE);
    if aClassType = TpdNewGrass then Exit(SUR_OBJ_NEWGRASS);
  end;

var
  i: Integer;
begin
  SetLength(aSurFile.Objects, Length(worldObjects));
  for i := 0 to High(worldObjects) do
    with aSurFile.Objects[i] do
    begin
      aType := ClassTypeToByte(worldObjects[i].ClassType);
      aPos := worldObjects[i].sprite.Position2D;
      aRot := worldObjects[i].sprite.Rotation;
    end;
end;

procedure DeinitializeWorldObjects();
var
  i: Integer;
begin
  if Length(worldObjects) > 0 then
    for i := 0 to High(worldObjects) do
      worldObjects[i].Free();
  selectedWorldObject := nil;
end;

function GetWorldObjectAtPosition(aPos: TdfVec2f): TpdWorldObject;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(worldObjects) do
    if worldObjects[i].IsInside(aPos) then
      Exit(worldObjects[i]);
end;

procedure UpdateWorldObjects(const dt: Double);
var
  i: Integer;
  nearFire: Boolean;
begin
  nearFire := False;
  for i := 0 to High(worldObjects) do
    if worldObjects[i] is TpdCampFire then
      with (worldObjects[i] as TpdCampFire) do
      begin
        if player.sprite.Position2D.Dist(sprite.Position2D) < restRadius then
          nearFire := True;
        
        timeToLife := timeToLife - dt;
        lifeSpr.Width := sprite.Width * (timeToLife / CAMPFIRE_TIME_TO_LIFE);
        if timeToLife < 0 then
        begin
          mainScene.RootNode.RemoveChild(lifeSpr);
          DeleteWorldObject(worldObjects[i]);
        end;
      end;
  player.NearCampFire := nearFire;
end;

function WorldObjectsOnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState): Boolean;
var
  i: Integer;
begin
  Result := False;
  selectedWorldObject := nil;
  cursorText.Text := '';
  for i := 0 to High(worldObjects) do
  begin
    //TODO: отсчечение по видимости
    if worldObjects[i].IsInside(dfVec2f(X, Y) - dfVec2f(mainScene.RootNode.Position)) then
    begin
      //Проверяем, не выбран ли какой-то объект до этого и сравниваем их Z-величину
      if Assigned(selectedWorldObject) then
      begin
        if selectedWorldObject.sprite.Position.z < worldObjects[i].sprite.Position.z then
        //Новый выше, значит выбираем его
        begin
          selectedWorldObject := worldObjects[i];
          cursorText.Text := selectedWorldObject.HintText;
          Result := True;
        end;
      end
      else
      begin
        selectedWorldObject := worldObjects[i];
        cursorText.Text := selectedWorldObject.HintText;
        Result := True;
      end;
//      break;
    end;
  end;
end;

function WorldObjectsOnMouseDown(X, Y: Integer;  MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;
begin
  Result := False;
  if Assigned(selectedWorldObject) then
  begin
    Result := True;
    if MouseButton = mbLeft then
    begin
      player.GoAndCollect(selectedWorldObject);
      selectedWorldObject := nil;
    end;
  end;
end;

function AddNewWorldObject(aClass: TpdWorldObjectClass): TpdWorldObject;
var
  l: Integer;
begin
  l := Length(worldObjects);
  SetLength(worldObjects, l + 1);
  worldObjects[l] := aClass.Initialize(mainScene);
  Result := worldObjects[l];
end;

procedure DeleteWorldObject(aObject: TpdWorldObject);

  function GetIndex(): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    for i := 0 to High(worldObjects) do
      if worldObjects[i] = aObject then
        Exit(i);
  end;

var
  index, len: Integer;

begin
  index := GetIndex();
  if index = -1 then
    Exit();

  if Assigned(worldObjects[index]) then
  begin
    mainScene.RootNode.RemoveChild(worldObjects[index].sprite);
    worldObjects[index].Free();
  end;
  len := Length(worldObjects);
  if index <> len - 1 then //не последний элемент
    //последний ставим на место удаленного, чтобы не перестраивать массив
    worldObjects[index] := worldObjects[len - 1];
  SetLength(worldObjects, len - 1);
end;

end.

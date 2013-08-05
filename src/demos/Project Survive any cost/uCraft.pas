unit uCraft;

interface

uses
  uWorldObjects, uInventory,
  dfHRenderer, dfMath;


const
  CRAFT_SHARPTWIG_ADDMIND = 2.0;
  CRAFT_CAMPFIRE_ADDMIND = 6.0;
  CRAFT_FISHROD_ADDMIND = 3.0;
  CRAFT_MUSHROOM_SHASHLIK_ADDMIND = 1.0;
  CRAFT_FISH_SHASHLIK_ADDMIND = 1.5;
  CRAFT_RAWTEA_ADDMIND = 1.0;

type
  //Ингридиент или инструмент
  TpdCraftResource = record
  private
    FCount: Integer;
    function GetPos: TdfVec2f;
    procedure SetPos(const Value: TdfVec2f);
    procedure SetCount(const Value: Integer);
  public
    aObject: TpdWorldObjectClass;
    aObjectSprite: IglrSprite;
    backSprite: IglrSprite;

    countText: IglrText;

    procedure Init(aClass: TpdWorldObjectClass; aScene: Iglr2DScene;
      isTool: Boolean = False);
    property Position: TdfVec2f read GetPos write SetPos;
    property Count: Integer read FCount write SetCount;
    procedure SetAlpha(aAlpha: Single);
  end;

  //Слот с крафтом - "содержит" результат, ингридиенты и инструменты
  TpdCraftSlot = class
  private
    FIngridientsShowed: Boolean;
    FEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
  public
    backSpr: IglrGUIButton; //бэкграунд
    resultSpr: IglrSprite; //спрайт того, что должно получиться
    resources: array of TpdCraftResource; //Ресурсы (тратятся)
    tools: array of TpdCraftResource; //Инструменты, не тратятся

    onCraft: function(): Boolean of object; //что произойдет после крафта

    hintText: WideString;

    constructor Create(); virtual;
    destructor Destroy(); override;
    procedure ShowIngridients();
    procedure HideIngridients();

    //Проверить,есть ли все необходимые элементы
    function CheckIngridientsAndTools(): Boolean;
    function RemoveIngridientsFromInventory(): Boolean;

    procedure SetPositionForIngridients();
    property Enabled: Boolean read FEnabled write SetEnabled;
  end;


  TpdCraftPanel = class
  private
    FGUIManager: IglrGUIManager;
    FVisible: Boolean;
    FBackground: IglrSprite;
    FSlots: array of TpdCraftSlot;

    procedure SetVisible(const aVisible: Boolean);
    procedure Show();
    procedure Hide();

    function CraftCampfire(): Boolean;
    function CraftSharpTwig(): Boolean;
    function CraftFishRod(): Boolean;
    function CraftMushroomShashlik(): Boolean;
    function CraftFishShashlik(): Boolean;
    function CraftBottleWithFlower(): Boolean;

    function IsInside(aPos: TdfVec2f): Boolean;

    constructor Create(); virtual;
    destructor Destroy(); override;
  public
    class function Initialize(aScene: Iglr2DScene): TpdCraftPanel;

    property Visible: Boolean read FVisible write SetVisible;

    procedure OnInventoryChanged();
  end;

var
  craftPanel: TpdCraftPanel;
  currentCraftSlot: TpdCraftSlot;


procedure InitializeCraft();
procedure UpdateCraft(const dt: Double);
function CraftOnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState): Boolean;
function CraftOnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;
function CraftOnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;
procedure DeinitializeCraft();

implementation

uses
  SysUtils,
  dfTweener,
  uPlayer, uGlobal;

const
  BACKGROUND_TEXTURE = 'craft_panel.png';
  SLOT_BACK_NORMAL_TEXTURE = 'craft_slot.png';
  SLOT_BACK_OVER_TEXTURE = 'craft_slot_over.png';
  SLOT_USE_TEXTURE = 'craft_slot_use.png';
  SLOT_RES_TEXTURE = 'inventory_slot.png';
  SLOTS_DISTANCE = 80;

  INGR_OFFSET_X = -20;
  INGR_OFFSET_Y = -90;
  INGR_DISTANCE = 70;

var
  slotsOrigin: TdfVec2f = (x: -300; y: 0);

//--для твина craft panel
procedure SetSingle(aObject: TdfTweenObject; aValue: Single);
var
  i: Integer;
begin
  with aObject as TpdCraftPanel do
  begin
    FBackground.PPosition.y := aValue;
    for i := 0 to High(FSlots) do
    begin
      FSlots[i].backSpr.PPosition.y := aValue;
      FSLots[i].resultSpr.Position := FSlots[i].backSpr.Position;
//      FSlots[i].HideIngridients();
    end;
  end;
end;

//--для твина ingridients
procedure SetSingleIngr(aObject: TdfTweenObject; aValue: Single);
var
  i: Integer;
begin
  with aObject as TpdCraftSlot do
  begin
    for i := 0 to High(resources) do
      resources[i].Position := dfVec2f(resources[i].Position.x, aValue);
    for i := 0 to High(tools) do
      tools[i].Position := dfVec2f(tools[i].Position.x, aValue);
  end;
end;

//--для твина ingridients
procedure SetSingleIngrA(aObject: TdfTweenObject; aValue: Single);
var
  i: Integer;
begin
  with aObject as TpdCraftSlot do
  begin
    for i := 0 to High(resources) do
      resources[i].SetAlpha(aValue);
    for i := 0 to High(tools) do
      tools[i].SetAlpha(aValue);
  end;
end;

procedure OnCraftSlotClick(aElement: IglrGUIElement; X, Y: Integer;
  MouseButton: TglrMouseButton; Shift: TglrMouseShiftState);
begin
  if MouseButton = mbLeft then
  begin
    if Assigned(currentCraftSlot) then
      with currentCraftSlot do
      begin
        if CheckIngridientsAndTools() then //Есть все необходимое, перестраховка
          if onCraft() then                //Если крафт удачен (есть место в рюкзаке)
           RemoveIngridientsFromInventory()//Забираем ингридиенты
      end;
  end;
end;


{ TpdCraftSlot }

function TpdCraftSlot.CheckIngridientsAndTools: Boolean;
var
  i: Integer;
  resSlot: TpdInvSlot;
begin
  for i := 0 to High(resources) do
  begin
    resSlot := inventory.GetSlotWithItem(resources[i].aObject);
    if not Assigned(resSlot) then
      Exit(False);
    if resSlot.count < resources[i].Count then
      Exit(False);
  end;

  for i := 0 to High(tools) do
  begin
    resSlot := inventory.GetSlotWithItem(tools[i].aObject);
    if not Assigned(resSlot) then
      Exit(False);
    if resSlot.count < tools[i].Count then
      Exit(False);
  end;

  Result := True;
end;

constructor TpdCraftSlot.Create;
begin
  inherited;
  backSpr := Factory.NewGUIButton();
  resultSpr := Factory.NewHudSprite();
  onCraft := nil;
  FIngridientsShowed := True;
end;

destructor TpdCraftSlot.Destroy;
begin
  inherited;
end;

procedure TpdCraftSlot.HideIngridients;
begin
  if not FIngridientsShowed then
    Exit();
  FIngridientsShowed := False;

  Tweener.AddTweenSingle(Self, @SetSingleIngr, tsExpoEaseIn, backSpr.Position.y + INGR_OFFSET_Y, backSpr.Position.y, 1.5, 0.0);
  Tweener.AddTweenSingle(Self, @SetSingleIngrA, tsExpoEaseIn, 1.0, 0.0, 1.0, 0.0);
end;

function TpdCraftSlot.RemoveIngridientsFromInventory(): Boolean;
var
  i, j: Integer;
  resSlot: TpdInvSlot;
begin
  for i := 0 to High(resources) do
  begin
    resSlot := inventory.GetSlotWithItem(resources[i].aObject);
    if not Assigned(resSlot) then
      Exit(False);
    if resSlot.count < resources[i].Count then
      Exit(False);
    for j := 0 to resources[i].Count - 1 do
      resSlot.RemoveOneItem();
  end;
  Result := True;
end;

procedure TpdCraftSlot.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
  if FEnabled then
  begin
    resultSpr.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
    backSpr.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
  end
  else
  begin
    resultSpr.Material.MaterialOptions.Diffuse := dfVec4f(0, 0, 0, 1);
    backSpr.Material.MaterialOptions.Diffuse := dfVec4f(0.5, 0.5, 0.5, 1);
  end;
end;

procedure TpdCraftSlot.SetPositionForIngridients;
var
  i: Integer;
begin
  //Очень сильное колдунство. Не трогать
  for i := 0 to High(resources) do
    resources[i].Position := backSpr.Position
     + dfVec2f(INGR_OFFSET_X * (Length(resources) + Length(tools)), INGR_OFFSET_Y)
     + dfVec2f(INGR_DISTANCE * i, 0);
  for i := 0 to High(tools) do
    tools[i].Position := backSpr.Position
     + dfVec2f(INGR_OFFSET_X * (Length(resources) + Length(tools)), INGR_OFFSET_Y)
     + dfVec2f(INGR_DISTANCE * (i + Length((resources))), 0);
end;

procedure TpdCraftSlot.ShowIngridients;
begin
  if FIngridientsShowed then
    Exit();
  FIngridientsShowed := True;

  Tweener.AddTweenSingle(Self, @SetSingleIngr, tsExpoEaseIn, backSpr.Position.y, backSpr.Position.y + INGR_OFFSET_Y, 1.5, 0.0);
  Tweener.AddTweenSingle(Self, @SetSingleIngrA, tsExpoEaseIn, 0.0, 1.0, 1.0, 0.0);
end;

{ TpdCraftPanel }

function TpdCraftPanel.CraftBottleWithFlower: Boolean;
begin
  Result := False;
  with (inventory.GetSlotWithItem(TpdBottle).item as TpdBottle) do
  begin
    case WaterStatus of
      bsWater, bsHotWater:
      begin
        Result := True;
        WaterStatus := bsRawTea;
        player.speech.Say('Отличная заготовка для чая!'#13#10'Надо ее прокипятить!', 3);
        player.AddParam(pMind, CRAFT_RAWTEA_ADDMIND);
      end;
      bsRawTea:
      begin
        player.speech.Say('Эй, у меня уже такое есть'#13#10'Не надо больше ромашки', 4);
      end;
      bsTea:
      begin
        player.speech.Say('У меня еще остался'#13#10'полноценный чай во фляжке', 4);
      end;
    end;
  end;
end;

function TpdCraftPanel.CraftCampfire: Boolean;
begin
  Result := False;
  if not player.inWater then
  begin
    Result := True;
    with AddNewWorldObject(TpdCampFire) do
    begin
      sprite.Position := player.sprite.Position + dfVec2f(0, 60);
      RecalcBB();
    end;
    player.speech.Say('Burn, baby, burn!', 3);
    player.AddParam(pMind, CRAFT_CAMPFIRE_ADDMIND);
  end
  else
    player.speech.Say('Я не могу зажечь костер в воде!', 3);
end;

function TpdCraftPanel.CraftFishRod: Boolean;
begin
  Result := False;
  case inventory.AddObject(TpdFishRod) of
    INV_OK:
    begin
      player.speech.Say('Теперь можно ловить рыбу!', 3);
      player.AddParam(pMind, CRAFT_FISHROD_ADDMIND);
      Result := True;
    end;
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Ошибка. Обратитесь к разработчику', 3);
  end;
end;

function TpdCraftPanel.CraftFishShashlik: Boolean;
begin
  Result := False;
  case inventory.AddObject(TpdFishShashlikRaw) of
    INV_OK:
    begin
      player.speech.Say('Теперь это надобно пожарить', 3);
      player.AddParam(pMind, CRAFT_FISH_SHASHLIK_ADDMIND);
      Result := True;
    end;
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('У меня тут уже перебор'#13#10'по шашлыкам', 3, colorYellow);
  end;
end;

function TpdCraftPanel.CraftMushroomShashlik: Boolean;
begin
  Result := False;
  case inventory.AddObject(TpdMushroomShashlikRaw) of
    INV_OK:
    begin
      player.speech.Say('Ну, это было нетрудно', 3);
      player.AddParam(pMind, CRAFT_MUSHROOM_SHASHLIK_ADDMIND);
      Result := True;
    end;
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('У меня тут уже перебор'#13#10'по шашлыкам', 3, colorYellow);
  end;
end;

function TpdCraftPanel.CraftSharpTwig: Boolean;
begin
  Result := False;
  case inventory.AddObject(TpdSharpTwig) of
    INV_OK:
    begin
      player.speech.Say('Ай, и правда острая!..', 3);
      player.AddParam(pMind, CRAFT_SHARPTWIG_ADDMIND);
      Result := True;
    end;
    INV_NO_SLOTS: NoPlaceToPut();
    INV_MAX_CAPACITY: player.speech.Say('Хватит с меня острых палок', 3, colorYellow);
  end;
end;

constructor TpdCraftPanel.Create;
begin
  inherited;
  FBackground := Factory.NewHudSprite();
  FVisible := True;
end;

destructor TpdCraftPanel.Destroy;
var
  i: Integer;
begin
  for i := 0 to High(FSlots) do
  begin
    FGUIManager.UnRegisterElement(FSlots[i].backSpr);
    FSlots[i].Free();
  end;
  inherited;
end;

procedure TpdCraftPanel.Hide;
begin
  FVisible := False;
  Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, FBackground.Position.y, R.WindowHeight + 100, 2.0, 0.0);
end;

class function TpdCraftPanel.Initialize(aScene: Iglr2DScene): TpdCraftPanel;


  procedure InitCampfireSlot(aSlot: TpdCraftSlot);
  begin
    //--result sprite
    with aSlot.resultSpr do
    begin
      PivotPoint := ppCenter;
      Position := aSlot.backSpr.Position;
      Z := Z_HUD + 1;
      Material.Texture := atlasGame.LoadTexture(CAMPFIRE_TEXTURE);
      UpdateTexCoords();
      SetSizeToTextureSize();
      aScene.RegisterElement(aSlot.resultSpr);
    end;
    aSlot.onCraft := Result.CraftCampfire;
    aSlot.hintText := 'Костер';

    SetLength(aSlot.resources, 2);
    aSlot.resources[0].Init(TpdOldGrass, aScene);
    aSlot.resources[0].Count := 2;
    aSlot.resources[1].Init(TpdTwig, aScene);
    aSlot.resources[1].Count := 2;

    aSlot.SetPositionForIngridients();
    aSlot.HideIngridients();
  end;

  procedure InitSharpTwigSlot(aSlot: TpdCraftSlot);
  begin
    //--result sprite
    with aSlot.resultSpr do
    begin
      PivotPoint := ppCenter;
      Position := aSlot.backSpr.Position;
      Z := Z_HUD + 1;
      Material.Texture := atlasGame.LoadTexture(SHARP_TWIG_TEXTURE);
      Rotation := -40;
      UpdateTexCoords();
      SetSizeToTextureSize();
      aScene.RegisterElement(aSlot.resultSpr);
    end;
    aSlot.onCraft := Result.CraftSharpTwig;
    aSlot.hintText := 'Острая ветка';

    SetLength(aSlot.resources, 1);
    aSlot.resources[0].Init(TpdTwig, aScene);
    aSlot.resources[0].Count := 1;

    SetLength(aSlot.tools, 1);
    aSlot.tools[0].Init(TpdKnife, aScene, True);

    aSlot.SetPositionForIngridients();
    aSlot.HideIngridients();
  end;

  procedure InitFishRodSlot(aSlot: TpdCraftSlot);
  begin
    //--result sprite
    with aSlot.resultSpr do
    begin
      PivotPoint := ppCenter;
      Position := aSlot.backSpr.Position;
      Z := Z_HUD + 1;
      Material.Texture := atlasGame.LoadTexture(FISHROD_TEXTURE);
      Material.Texture.CombineMode := tcmModulate;
      UpdateTexCoords();
      SetSizeToTextureSize();
      aScene.RegisterElement(aSlot.resultSpr);
    end;
    aSlot.onCraft := Result.CraftFishRod;
    aSlot.hintText := 'Удочка';

    SetLength(aSlot.resources, 2);
    aSlot.resources[0].Init(TpdWire, aScene);
    aSlot.resources[0].Count := 1;
    aSlot.resources[1].Init(TpdTwig, aScene);
    aSlot.resources[1].Count := 1;

    SetLength(aSlot.tools, 1);
    aSlot.tools[0].Init(TpdKnife, aScene, True);

    aSlot.SetPositionForIngridients();
    aSlot.HideIngridients();
  end;

  procedure InitMushroomShashlikSlot(aSlot: TpdCraftSlot);
  begin
    //--result sprite
    with aSlot.resultSpr do
    begin
      PivotPoint := ppCenter;
      Position := aSlot.backSpr.Position;
      Z := Z_HUD + 1;
      Material.Texture := atlasGame.LoadTexture(MUSHROOM_SHASHLIK_TEXTURE);
      Rotation := -45;
      UpdateTexCoords();
      SetSizeToTextureSize();
      aScene.RegisterElement(aSlot.resultSpr);
    end;
    aSlot.onCraft := Result.CraftMushroomShashlik;
    aSlot.hintText := 'Сырой шашлык из грибов';

    SetLength(aSlot.resources, 2);
    aSlot.resources[0].Init(TpdMushroom, aScene);
    aSlot.resources[0].Count := 2;
    aSlot.resources[1].Init(TpdSharpTwig, aScene);
    aSlot.resources[1].Count := 1;

    aSlot.SetPositionForIngridients();
    aSlot.HideIngridients();
  end;

  procedure InitFishShashlikSlot(aSlot: TpdCraftSlot);
  begin
    //--result sprite
    with aSlot.resultSpr do
    begin
      PivotPoint := ppCenter;
      Position := aSlot.backSpr.Position;
      Z := Z_HUD + 1;
      Material.Texture := atlasGame.LoadTexture(FISH_SHASHLIK_TEXTURE);
      Rotation := 45;
      UpdateTexCoords();
      SetSizeToTextureSize();
      aScene.RegisterElement(aSlot.resultSpr);
    end;
    aSlot.onCraft := Result.CraftFishShashlik;
    aSlot.hintText := 'Сырой шашлык из рыбы';

    SetLength(aSlot.resources, 2);
    aSlot.resources[0].Init(TpdFish, aScene);
    aSlot.resources[0].Count := 1;
    aSlot.resources[1].Init(TpdSharpTwig, aScene);
    aSlot.resources[1].Count := 1;

    SetLength(aSlot.tools, 1);
    aSlot.tools[0].Init(TpdKnife, aScene, True);

    aSlot.SetPositionForIngridients();
    aSlot.HideIngridients();
  end;

  procedure InitBottleWithFlowerSlot(aSlot: TpdCraftSlot);
  begin
    //--result sprite
    with aSlot.resultSpr do
    begin
      PivotPoint := ppCenter;
      Position := aSlot.backSpr.Position;
      Z := Z_HUD + 1;
      Material.Texture := atlasGame.LoadTexture(BOTTLE_TEA_TEXTURE);
      UpdateTexCoords();
      SetSizeToTextureSize();
      aScene.RegisterElement(aSlot.resultSpr);
    end;
    aSlot.onCraft := Result.CraftBottleWithFlower;
    aSlot.hintText := 'Фляга с заготовкой чая';

    SetLength(aSlot.resources, 1);
    aSlot.resources[0].Init(TpdFlower, aScene);
    aSlot.resources[0].Count := 2;

    SetLength(aSlot.tools, 1);
    aSlot.tools[0].Init(TpdBottle, aScene, True);
    aSlot.tools[0].Count := 1;

    aSlot.SetPositionForIngridients();
    aSlot.HideIngridients();
  end;

var
  i: Integer;
begin
  Result := TpdCraftPanel.Create();
  with Result do
  begin
    //--back
    FBackground.Material.Texture := atlasGame.LoadTexture(BACKGROUND_TEXTURE);
    FBackground.UpdateTexCoords();
    FBackground.SetSizeToTextureSize();
    FBackground.PivotPoint := ppCenter;
    FBackground.Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight - 55);
    FBackground.Z := Z_HUD - 1;

    FGUIManager := R.GUIManager;

    aScene.RegisterElement(FBackground);

    SetLength(FSlots, 6);

    for i := 0 to High(FSlots) do
    begin
      FSlots[i] := TpdCraftSlot.Create();
      with FSlots[i] do
      begin
        //--back sprite button
        with backSpr do
        begin
          PivotPoint := ppCenter;
          Position := FBackground.Position + slotsOrigin + dfVec2f(i * SLOTS_DISTANCE, 0);
          Z := Z_HUD;
          TextureNormal := atlasGame.LoadTexture(SLOT_BACK_NORMAL_TEXTURE);
          TextureOver := atlasGame.LoadTexture(SLOT_BACK_OVER_TEXTURE);
          UpdateTexCoords();
          SetSizeToTextureSize();
          OnMouseClick := OnCraftSlotClick;
          FGUIManager.RegisterElement(backSpr);
          aScene.RegisterElement(backSpr);
        end;
        Enabled := False;
      end;
    end;
    InitCampfireSlot(FSlots[0]);
    InitSharpTwigSlot(FSlots[1]);
    InitFishRodSlot(FSlots[2]);
    InitMushroomShashlikSlot(FSlots[3]);
    InitFishShashlikSlot(FSlots[4]);
    InitBottleWithFlowerSlot(FSlots[5]);

    Hide();
  end;
end;

function TpdCraftPanel.IsInside(aPos: TdfVec2f): Boolean;
begin
  with FBackground do
    Result := (aPos.x > Position.x - Width / 2) and (aPos.x < Position.x + Width / 2)
          and (aPos.y > Position.y - Height / 2) and (aPos.y < Position.y + Height / 2);
end;

procedure TpdCraftPanel.OnInventoryChanged();
var
  i: Integer;
begin
  for i := 0 to High(FSlots) do
    with FSlots[i] do
    begin
      if CheckIngridientsAndTools() and not FSlots[i].Enabled then
      //Что-то новое доступно для крафта!
        Show();
      FSlots[i].Enabled := CheckIngridientsAndTools();
    end;
end;

procedure TpdCraftPanel.SetVisible(const aVisible: Boolean);
begin
  if aVisible <> FVisible then
  begin
    FVisible := aVisible;
    if FVisible then
      Show()
    else
      Hide();
  end;
end;


procedure TpdCraftPanel.Show;
begin
  FVisible := True;
  Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, FBackground.Position.y, R.WindowHeight - 55, 2.0, 0.0);
end;

procedure InitializeCraft();
begin
  if Assigned(craftPanel) then
    craftPanel.Free();
  craftPanel := TpdCraftPanel.Initialize(hudScene);
end;

procedure UpdateCraft(const dt: Double);
begin
  //craftPanel.Update(dt);
end;

function CraftOnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState): Boolean;
var
  i: Integer;
begin
  Result := False;

  //Если мышь попадает на крафт-панель, то
  //обработка будет проходить тут, все остальные, кто ниже
  //в TpdGameOnMouseMove бреются
  if craftPanel.IsInside(dfVec2f(X, Y)) then
    Result := True;

  //Проверяем какова позиция мыши у текущего слота, если он вообще есть
  //Если мышь в ауте - все, слот больше не текущий
  if Assigned(currentCraftSlot) then
    if currentCraftSlot.backSpr.MousePos = mpOut then
    begin
      currentCraftSlot.HideIngridients();
      currentCraftSlot := nil;
    end;

  //Проходимся по остальным слотам, вдруг есть такой, над которым
  //висит мышь и при этом он не является текущим
  //Если так, то бреем текущий и делаем этот текущим.
  for i := 0 to High(craftPanel.FSlots) do
    if (craftPanel.FSlots[i].backSpr.MousePos = mpOver)
      and (currentCraftSlot <> craftPanel.FSlots[i]) then
    begin
      if Assigned(currentCraftSlot) then
        currentCraftSlot.HideIngridients();
      currentCraftSlot := craftPanel.FSlots[i];
      cursorText.Text := currentCraftSlot.hintText;
      currentCraftSlot.ShowIngridients();
      Exit();
    end;

  if not Assigned(currentCraftSlot) then
    cursorText.Text := '';
end;

function CraftOnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;
begin
  Result := False;
  if craftPanel.IsInside(dfVec2f(X, Y)) then
    Result := True;
end;

function CraftOnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState): Boolean;
begin
  Result := False;
  if craftPanel.IsInside(dfVec2f(X, Y)) then
    Result := True;
end;

procedure DeinitializeCraft();
begin
  craftPanel.Free();
  craftPanel := nil;
end;

{ TpdCraftResource }

function TpdCraftResource.GetPos: TdfVec2f;
begin
  Result := backSprite.Position;
end;

procedure TpdCraftResource.Init(aClass: TpdWorldObjectClass; aScene: Iglr2DScene;
  isTool: Boolean = False);
begin
  backSprite := Factory.NewHudSprite();
  if isTool then
    backSprite.Material.Texture := atlasGame.LoadTexture(SLOT_USE_TEXTURE)
  else
    backSprite.Material.Texture := atlasGame.LoadTexture(SLOT_RES_TEXTURE);
  backSprite.UpdateTexCoords();
  backSprite.SetSizeToTextureSize();
  backSprite.Z := Z_HUD - 3;
  backSprite.PivotPoint := ppCenter;

  aObject := aClass;
  aObjectSprite := aClass.GetObjectSprite();
  aObjectSprite.Z := Z_HUD - 2;
  aObjectSprite.PivotPoint := ppCenter;

  countText := Factory.NewText();
  countText.Font := fontCooper;
  countText.Material.MaterialOptions.Diffuse := dfVec4f(0, 0, 0, 1);
  countText.Z := Z_HUD - 1;

  Count := 1;

  aScene.RegisterElement(backSprite);
  aScene.RegisterElement(aObjectSprite);
  aScene.RegisterElement(countText);
end;

procedure TpdCraftResource.SetAlpha(aAlpha: Single);
begin
  backSprite.Material.MaterialOptions.PDiffuse.w := aAlpha;
  aObjectSprite.Material.MaterialOptions.PDiffuse.w := aAlpha;
  countText.Material.MaterialOptions.PDiffuse.w := aAlpha;
end;

procedure TpdCraftResource.SetCount(const Value: Integer);
begin
  FCount := Value;
  if FCount = 1 then
    countText.Text := ''
  else
    countText.Text := IntToStr(FCount);
end;

procedure TpdCraftResource.SetPos(const Value: TdfVec2f);
begin
  backSprite.Position := Value;
  aObjectSprite.Position := Value;
  countText.Position := Value + dfVec2f(12, 4);
end;

end.

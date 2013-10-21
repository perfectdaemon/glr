unit uWater;

interface

uses
  uLevel_SaveLoad, uWorldObjects,
  glr, glrMath;

const
  WATER_ADDTHIRST = BOTTLE_ADDTHIRST;
  WATER_ADDHEALTH = BOTTLE_ADDHEALTH;

type
  TpdWater = class (TpdWorldObject)
  protected
    procedure CalcRadius();
    function GetHintText(): WideString; override;

    constructor Create(); override;
    destructor Destroy(); override;
  public
    fishCount: Integer; //популяция рыбы
    radius: Single; //precalculated radius - среднее между width и height / 2
    class function Initialize(aScene: Iglr2DScene): TpdWater; reintroduce;
    class function GetObjectSprite(): IglrSprite; override;
    function IsInside(aPos: TdfVec2f): Boolean; override;

    procedure GetOneFish();

    procedure OnCollect(); override;
    procedure OnUse(); override;
  end;

var
  water: array of TpdWater;

  //Вода под курсором и вода под игроком. Могут быть разными
  currentWater, playerInWater: TpdWater;

//procedure InitializeWater(); overload;
procedure InitializeWater(aSurFile: TSURFile); //overload;
procedure UpdateWater(const dt: Double);
procedure DeinitializeWater();

function WaterObjectsOnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState): Boolean;
function WaterObjectsOnMouseDown(X, Y: Integer;  MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState): Boolean;

//Для редактора
procedure _SaveWater(aSURFile: TSURFile);

implementation

uses
  uPlayer, uInventory, uGlobal;

const
  WATER_TEXTURE = 'water.png';
  //Поравочный "коэффициент", уменшающий определяемую площадь воды
  WATER_COEF = 5;

{ TpdWater }

procedure TpdWater.CalcRadius;
begin
  radius := ((sprite.Width - WATER_COEF) * sprite.Scale.x + (sprite.Height - WATER_COEF) * sprite.Scale.y) / 4;
end;

constructor TpdWater.Create;
begin
  inherited;
  sprite := Factory.NewSprite();
end;

destructor TpdWater.Destroy;
begin
  inherited;
end;

function TpdWater.GetHintText: WideString;
begin
  if Assigned(dragObject) and (dragObject.item is TpdBottle) and (player.inWater) then
    Result := 'Вода. Довольно мокрая на вид.'#13#10+'Отпустите флягу, чтобы наполнить ее'
  else
    Result := 'Вода. Довольно мокрая на вид.'#13#10+TEXT_RMB_DRINK;
end;

class function TpdWater.GetObjectSprite: IglrSprite;
begin
  Result := nil;
end;

procedure TpdWater.GetOneFish();
begin
  if fishCount > 0 then
    Dec(fishCount);
end;

class function TpdWater.Initialize(aScene: Iglr2DScene): TpdWater;
begin
  Result := TpdWater.Create();
  with Result as TpdWater do
  begin
    sprite.Material.Texture := atlasGame.LoadTexture(WATER_TEXTURE);
    sprite.UpdateTexCoords();
    sprite.SetSizeToTextureSize;
    sprite.PivotPoint := ppCenter;
    sprite.PPosition.z := Z_STATICOBJECTS - 5;
    aScene.RootNode.AddChild(sprite);

    fishCount := 5 + Random(6);
  end;
end;

function TpdWater.IsInside(aPos: TdfVec2f): Boolean;
begin
  Result := aPos.Dist(sprite.Position2D) < radius;
end;

procedure TpdWater.OnCollect;
begin
  //Попить воды
  player.speech.Say('Ммм, вкууусно, но опасно'#13#10'для здоровья...', 3);
  player.AddParam(pHealth, WATER_ADDHEALTH);
  player.AddParam(pThirst, WATER_ADDTHIRST);
end;

procedure TpdWater.OnUse;
begin

end;

//procedure InitializeWater();
//var
//  i: Integer;
//begin
//  for i := 0 to High(water) do
//    if Assigned(water[i]) then
//      water[i].Free();
//
//  //TODO - загрузка воды из sur-файла
//  SetLength(water, 2);
//  water[0] := TpdWater.Initialize(mainScene);
//  water[0].sprite.Position := dfVec2f(-700, -450);
//  water[0].sprite.ScaleMult(4);
//  water[0].sprite.Rotation := 25;
//
//  water[1] := TpdWater.Initialize(mainScene);
//  water[1].sprite.Position := dfVec2f(1600, 900);
//  water[1].sprite.ScaleMult(2);
//  water[1].sprite.Rotation := -25;
//end;

procedure InitializeWater(aSurFile: TSURFile);
var
  i: Integer;
begin
  if Length(water) > 0 then
    for i := 0 to High(water) do
      water[i].Free();

  SetLength(water, Length(aSURFile.Water));
  for i := 0 to High(water) do
  begin
    water[i] := TpdWater.Initialize(mainScene);
    with water[i].sprite, aSurFile.Water[i] do
    begin
      Position2D := aPos;
      Rotation := aRot;
      Scale := aSurFile.Water[i].aScale;
    end;
    water[i].CalcRadius();
  end;
end;

procedure UpdateWater(const dt: Double);
var
  i: Integer;
begin
  player.inWater := False;
  for i := 0 to High(water) do
    if water[i].IsInside(player.sprite.Position2D) then
    begin
      player.inWater := True;
      playerInWater := water[i];
      break;
    end;
end;

procedure DeinitializeWater();
var
  i: Integer;
begin
  for i := 0 to High(water) do
    if Assigned(water[i]) then
      water[i].Free();
  SetLength(water, 0);
end;

procedure _SaveWater(aSURFile: TSURFile);
var
  i: Integer;
begin
  SetLength(aSURFile.Water, Length(water));
  for i := 0 to High(water) do
    with aSURFile.Water[i] do
    begin
      aPos := water[i].sprite.Position2D;
      aScale:= water[i].sprite.Scale;
      aRot := water[i].sprite.Rotation;
    end;
end;

function WaterObjectsOnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState): Boolean;
var
  i: Integer;
begin
  Result := False;
  currentWater := nil;
  for i := 0 to High(water) do
    if water[i].IsInside(dfVec2f(X, Y) - dfVec2f(mainScene.RootNode.Position)) then
    begin
      Result := True;
      currentWater := water[i];
      cursorText.Text := water[i].HintText;
    end;
    
end;

function WaterObjectsOnMouseDown(X, Y: Integer;  MouseButton: TglrMouseButton;
    Shift: TglrMouseShiftState): Boolean;
begin
  Result := False;
  if MouseButton = mbRight then
  begin
    if Assigned(currentWater) then
      player.GoAndCollect(currentWater);
  end;
end;

end.

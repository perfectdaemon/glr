unit uHud;

interface

uses
  uShip,
  glr, glrMath;

type
  TpdHud = class
  private
    hudDummy: IglrNode;
    function CreateHudSprite(aTextureName: WideString; aPos: TdfVec2f; aParent: IglrNode): IglrSprite;
    function CreateHudText(aText: WideString; aPos: TdfVec2f; aParent: IglrNode): IglrText;
  public
    Target: TpdShip;
    Selection: IglrNode;
    SelectionParts: array[0..3] of IglrSprite;
    HealthIcon, AmmoIcon: IglrSprite;
    HealthText, AmmoText, WeaponText: IglrText;
    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);
  end;

implementation

uses
  uGlobal;

var
  healthIconPos, healthTextPos, ammoIconPos, ammoTextPos, weaponTextPos: TdfVec2f;

const
  FRAME_SIZE = 35;

{ TpdHud }

constructor TpdHud.Create();
var
  i: Integer;
begin
  inherited;
  healthIconPos := dfVec2f(R.WindowWidth div 2 - 150, R.WindowHeight - 35);
  healthTextPos := healthIconPos + dfVec2f(55, 0);
  ammoIconPos := dfVec2f(R.WindowWidth div 2 + 150, R.WindowHeight - 35);
  ammoTextPos := ammoIconPos + dfVec2f(55, 0);
  weaponTextPos := ammoTextPos + dfVec2f(65, 0);

  hudDummy := Factory.NewNode();
  hudScene.RootNode.AddChild(hudDummy);

  HealthIcon := CreateHudSprite(HEALTH_TEXTURE, healthIconPos, hudDummy);
  HealthText := CreateHudText('100', healthTextPos, hudDummy);

  AmmoIcon := CreateHudSprite(AMMO_TEXTURE, ammoIconPos, hudDummy);
  AmmoText := CreateHudText('100', ammoTextPos, hudDummy);
  WeaponText := CreateHudText('Лазер', weaponTextPos, hudDummy);

  Selection := Factory.NewNode;
  mainScene.RootNode.AddChild(Selection);
  for i := 0 to 3 do
    SelectionParts[i] := CreateHudSprite(SELECTION_TEXTURE, dfVec2f(0, 0), Selection);

  SelectionParts[0].Position2D := dfVec2f(-FRAME_SIZE, -FRAME_SIZE);
  SelectionParts[0].Rotation := 0;
  SelectionParts[1].Position2D := dfVec2f(FRAME_SIZE, -FRAME_SIZE);
  SelectionParts[1].Rotation := 90;
  SelectionParts[2].Position2D := dfVec2f(FRAME_SIZE, FRAME_SIZE);
  SelectionParts[2].Rotation := 180;
  SelectionParts[3].Position2D := dfVec2f(-FRAME_SIZE, FRAME_SIZE);
  SelectionParts[3].Rotation := 270;

  Target := nil;
end;

function TpdHud.CreateHudSprite(aTextureName: WideString;
  aPos: TdfVec2f; aParent: IglrNode): IglrSprite;
begin
  Result := Factory.NewHudSprite();
  with Result do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(aPos, Z_HUD);
    Material.Texture := atlasMain.LoadTexture(aTextureName);
    Material.Diffuse := scolorWhite;
    SetSizeToTextureSize();
    UpdateTexCoords();
  end;
  aParent.AddChild(Result);
end;

function TpdHud.CreateHudText(aText: WideString; aPos: TdfVec2f; aParent: IglrNode): IglrText;
begin
  Result := Factory.NewText();
  with Result do
  begin
    PivotPoint := ppCenter;
    Font := fontSouvenir;
    Text := aText;
    Position := dfVec3f(aPos, Z_HUD);
    Material.Diffuse := scolorWhite;
  end;
  aParent.AddChild(Result);
end;

destructor TpdHud.Destroy;
begin

  inherited;
end;

procedure TpdHud.Update(const dt: Double);

  function IsOverSprite(aSpr: IglrSprite; aPoint: TdfVec2f): Boolean;
  begin
    Result := IsPointInBox(aPoint, aSpr.Position2D + aSpr.Coords[2], aSpr.Position2D + aSpr.Coords[0]);
  end;

var
  i: Integer;
begin
  Target := nil;
  for i := 0 to ships.Count - 1 do
    if ships[i] <> player then
      with TpdShip(ships[i]) do
        if not Enabled then
          continue
        else if IsOverSprite(Body, mousePosAtScene) then
        begin
          Target := TpdShip(ships[i]);
          Selection.Position := Body.Position;
          break;
        end;
  Selection.Visible := Target <> nil;
end;

end.

unit uHud;

interface

uses
  glr, glrMath;

type
  TpdHud = class
  private
    hudDummy: IglrNode;
    function CreateHudSprite(aTextureName: WideString; aPos: TdfVec2f): IglrSprite;
    function CreateHudText(aText: WideString; aPos: TdfVec2f): IglrText;
  public
    HealthIcon, HealthFrame, AmmoIcon, AmmoFrame: IglrSprite;
    HealthText, AmmoText, WeaponText: IglrText;
    constructor Create(); virtual;
    destructor Destroy(); override;
  end;

implementation

uses
  uGlobal;

var
  healthIconPos, healthTextPos, ammoIconPos, ammoTextPos, weaponTextPos: TdfVec2f;

{ TpdHud }

constructor TpdHud.Create();
begin
  inherited;
  healthIconPos := dfVec2f(R.WindowWidth div 2 - 150, R.WindowHeight - 35);
  healthTextPos := healthIconPos + dfVec2f(55, 0);
  ammoIconPos := dfVec2f(R.WindowWidth div 2 + 150, R.WindowHeight - 35);
  ammoTextPos := ammoIconPos + dfVec2f(55, 0);
  weaponTextPos := ammoTextPos + dfVec2f(65, 0);

  hudDummy := Factory.NewNode();
  hudScene.RootNode.AddChild(hudDummy);

  HealthIcon := CreateHudSprite(HEALTH_TEXTURE, healthIconPos);
  //HealthFrame := CreateHudSprite(FRAME_RECT_TEXTURE, healthIconPos);
  HealthText := CreateHudText('100', healthTextPos);

  AmmoIcon := CreateHudSprite(AMMO_TEXTURE, ammoIconPos);
  AmmoIcon.PivotPoint := ppCenter;
  //AmmoFrame := CreateHudSprite(FRAME_RECT_TEXTURE, ammoIconPos);
  AmmoText := CreateHudText('100', ammoTextPos);
  WeaponText := CreateHudText('Лазер', weaponTextPos);
end;

function TpdHud.CreateHudSprite(aTextureName: WideString;
  aPos: TdfVec2f): IglrSprite;
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
  hudDummy.AddChild(Result);
end;

function TpdHud.CreateHudText(aText: WideString; aPos: TdfVec2f): IglrText;
begin
  Result := Factory.NewText();
  with Result do
  begin
    PivotPoint := ppCenter;
    Font := fontSouvenir;
    Text := aText;
    Position := dfVec3f(aPos, Z_HUD);
    //Material.Diffuse := scolorWhite;
  end;
  hudScene.RootNode.AddChild(Result);
end;

destructor TpdHud.Destroy;
begin

  inherited;
end;

end.

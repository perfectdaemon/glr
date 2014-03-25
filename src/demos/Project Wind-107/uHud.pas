unit uHud;

interface

uses
  glr, glrMath;

type
  TpdHud = class
  private
    hudDummy: IglrNode;
    function CreateHudSprite(aTextureName: WideString; aPos: TdfVec2f; aParent: IglrNode): IglrSprite;
    function CreateHudText(aText: WideString; aPos: TdfVec2f; aParent: IglrNode): IglrText;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);
  end;

implementation

uses
  uGlobal;

{ TpdHud }

constructor TpdHud.Create();
begin
  inherited;

  hudDummy := Factory.NewNode();
  hudScene.RootNode.AddChild(hudDummy);
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
    Material.Diffuse := colorWhite;
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
    Material.Diffuse := colorWhite;
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

begin

end;

end.

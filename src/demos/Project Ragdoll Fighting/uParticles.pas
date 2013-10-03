unit uParticles;

interface

uses
  glr, glrMath,
  uAccum;

const
  FADE_TIME_BASE = 0.5;

type
  TpdParticle = class (TpdAccumItem)
  public
    spr: IglrSprite;
    timeRemain, timeAll: Single;
    moveDir: TdfVec2f;
    speed: Single;
    procedure OnCreate(); override;
    procedure OnGet(); override;
    procedure OnFree(); override;
  end;

  TpdParticles = class (TpdAccum)
  public
    class function Initialize(aScene: Iglr2DScene): TpdParticles;
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdParticle; reintroduce;

    procedure Update(const dt: Single);

    procedure AddBlock(aPos: TdfVec2f);
    procedure AddPunch(aPos: TdfVec2f);
  end;

var
  particlesInternalZ: Integer = 0;

implementation

uses
  uGlobal;

var
  scene: Iglr2DScene;

{ TpdParticle }

procedure TpdParticle.OnCreate;
begin
  inherited;
  spr := Factory.NewSprite();
  spr.Material.Texture := texParticle;
  spr.PivotPoint := ppCenter;
  spr.UpdateTexCoords();
  spr.SetSizeToTextureSize();
  spr.PPosition.z := Z_HUD + particlesInternalZ;
  Inc(particlesInternalZ);
  scene.RootNode.AddChild(spr);

  OnFree();
end;

procedure TpdParticle.OnFree;
begin
  inherited;
  spr.Visible := False;
  speed := 0;
end;

procedure TpdParticle.OnGet;
begin
  inherited;
  spr.Visible := True;
  timeAll := FADE_TIME_BASE + 1.5 * Random();
  timeRemain := timeAll;
  spr.Material.Diffuse := colorGreen;
  spr.SetSizeToTextureSize();
end;

{ TpdParticles }

procedure TpdParticles.AddBlock(aPos: TdfVec2f);
var
  i, count: Integer;
  color: TdfVec4f;
begin
  count := 5 + Random(5);
  color := dfVec4f(Random(), Random(), Random(), 1.0);
  for i := 0 to count - 1 do
    with GetItem() do
    begin
      spr.Position := aPos;
      spr.Rotation := Random(360);
      spr.Width := spr.Width * (0.3 + Random());
      spr.Height := spr.Width;
      moveDir := dfVec2f(0 + Random(360)).Normal;
      speed := 60 + Random(30);
      spr.Material.Diffuse := color;
    end;
end;

procedure TpdParticles.AddPunch(aPos: TdfVec2f);
var
  i, count: Integer;
  color: TdfVec4f;
begin
  count := 10 + Random(10);
  color := dfVec4f(1.0, 0.2, 0.1, 1.0);
  for i := 0 to count - 1 do
    with GetItem() do
    begin
      spr.Position := aPos;
      spr.Rotation := Random(360);
      spr.Width := spr.Width * (0.3 + Random());
      spr.Height := spr.Width;
      moveDir := dfVec2f(0 + Random(360)).Normal;
      speed := 60 + Random(30);
      spr.Material.Diffuse := color;
    end;
end;

function TpdParticles.GetItem: TpdParticle;
begin
  Result := inherited GetItem() as TpdParticle;
end;

class function TpdParticles.Initialize(aScene: Iglr2DScene): TpdParticles;
begin
  scene := aScene;
  Result := TpdParticles.Create(128);
end;

function TpdParticles.NewAccumItem: TpdAccumItem;
begin
  Result := TpdParticle.Create();
end;

procedure TpdParticles.Update(const dt: Single);
var
  i: Integer;
begin
  for i := 0 to High(Items) do
    if Items[i].Used then
      with Items[i] as TpdParticle do
      begin
        if timeRemain > 0 then
        begin
          timeRemain := timeRemain - dt;
          spr.Material.PDiffuse.w := timeRemain / timeAll;
          spr.Position := spr.Position + moveDir * speed * dt;
          moveDir := (moveDir + dfVec2f(0, 2.5 * dt));
        end
        else
          FreeItem(Items[i]);
      end;
end;

end.

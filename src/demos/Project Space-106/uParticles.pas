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
    startAlpha: Single;
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
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdParticle; reintroduce;

    procedure Update(const dt: Single);

    procedure AddEngineExhaust(aPos, aDir: TdfVec2f);
    procedure AddRocketSelfExplosion(aPos: TdfVec2f);
  end;

var
  particlesInternalZ: Integer = 0;

implementation

uses
  uGlobal;

{ TpdParticle }

procedure TpdParticle.OnCreate;
begin
  inherited;
  spr := Factory.NewSprite();
  spr.Material.Texture := texParticle;
  spr.Material.Texture.BlendingMode := tbmTransparency;
  spr.PivotPoint := ppCenter;
  spr.UpdateTexCoords();
  spr.SetSizeToTextureSize();
  spr.PPosition.z := Z_PARTICLES + particlesInternalZ;
  Inc(particlesInternalZ);
  particlesDummy.AddChild(spr);

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
  spr.Material.Diffuse := scolorBlue;
  spr.SetSizeToTextureSize();
end;

{ TpdParticles }

procedure TpdParticles.AddEngineExhaust(aPos, aDir: TdfVec2f);
var
  i, count: Integer;
  color: TdfVec4f;
begin
  count := 5 + Random(5);
//  if Random() < 0.5 then
    color := scolorBlue;
//  else
//    color := scolorRed;
  for i := 0 to count - 1 do
    with GetItem() do
    begin
      startAlpha := Random();
      spr.Position2D := aPos;
      spr.Rotation := Random(360);
      spr.Width := spr.Width * (0.3 + Random());
      spr.Height := spr.Width;
      moveDir := aDir + (1 - Random(2)) * dfVec2f(aDir.y, -aDir.x);
      speed := 30 + Random(30);
      spr.Material.Diffuse := color;
    end;
end;

procedure TpdParticles.AddRocketSelfExplosion(aPos: TdfVec2f);
var
  i, count: Integer;
  color: TdfVec4f;
begin
  count := 15 + Random(5);
  for i := 0 to count - 1 do
    with GetItem() do
    begin
      if Random() < 0.5 then
        color := scolorWhite
      else
        color := scolorRed;
      startAlpha := Random();
      spr.Position2D := aPos;
      spr.Rotation := Random(360);
      spr.Width := spr.Width * (0.3 + Random());
      spr.Height := spr.Width;
      moveDir := dfVec2f(Random(360));
      speed := 30 + Random(30);
      spr.Material.Diffuse := color;
    end;
end;

function TpdParticles.GetItem: TpdParticle;
begin
  Result := inherited GetItem() as TpdParticle;
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
          spr.Material.PDiffuse.w := startAlpha * timeRemain / timeAll;
          spr.Position2D := spr.Position2D + moveDir * speed * dt;
          //moveDir := (moveDir + dfVec2f(0, 2.5 * dt));
        end
        else
          FreeItem(Items[i]);
      end;
end;

end.

unit uHud;

interface

uses
  glr;

const
  ARROW_ROTATION_ZERO = -10;
  ARROW_ROTATION_MAX = -80;

  TAHO_X = 10;
  TAHO_Y = 560;
  GEAR_X = 20;
  GEAR_Y = 570;

type
  TpdTahometer = class
    Arrow: IglrSprite;
    //0..1
    TahoValue: Single;
    constructor Create();
    destructor Destroy(); override;

    procedure Update(dt: Double);
  end;

  TpdGearDisplay = class
  private
    FOldGearIndex: Integer;
  public
    GearText: IglrText;
    constructor Create();
    destructor Destroy(); override;

    procedure SetGear(GearIndex: Integer);
  end;

implementation

uses
  SysUtils,
  dfTweener,
  uGlobal, glrMath;

{ TpdTahometer }

constructor TpdTahometer.Create;
begin
  inherited;
  Arrow := Factory.NewHudSprite();
  with Arrow do
  begin
    Material.Diffuse := colorWhite;
    Width := 100;
    Height := 5;
    SetCustomPivotPoint(0, 0.5);
    Rotation := ARROW_ROTATION_ZERO;
    Position := dfVec3f(TAHO_X, TAHO_Y, Z_HUD);
  end;
  hudScene.RootNode.AddChild(Arrow);
  TahoValue := 0;
end;

destructor TpdTahometer.Destroy;
begin
  hudScene.RootNode.RemoveChild(Arrow);
  inherited;
end;

procedure TpdTahometer.Update(dt: Double);
var
  newRot: Single;
begin
  newRot := Clamp(ARROW_ROTATION_ZERO + (ARROW_ROTATION_MAX - ARROW_ROTATION_ZERO) * TahoValue, ARROW_ROTATION_MAX, ARROW_ROTATION_ZERO);
  Arrow.Rotation := Lerp(Arrow.Rotation, newRot, 3 * dt);
end;

{ TpdGearDisplay }

constructor TpdGearDisplay.Create;
begin
  inherited;
  FOldGearIndex := 100;
  GearText := Factory.NewText();
  with GearText do
  begin
    Font := fontSouvenir;
    Text := '';
    Position := dfVec3f(GEAR_X, GEAR_Y, Z_HUD + 1);
  end;
  hudScene.RootNode.AddChild(GearText);
end;

destructor TpdGearDisplay.Destroy;
begin
  hudScene.RootNode.RemoveChild(GearText);
  inherited;
end;

procedure TpdGearDisplay.SetGear(GearIndex: Integer);
begin
  if FOldGearIndex <> GearIndex then
  begin
    FOldGearIndex := GearIndex;
    if GearIndex = 0 then
      GearText.Text := 'R'
    else
      GearText.Text := 'D' + IntToStr(GearIndex);
  end;
end;

end.

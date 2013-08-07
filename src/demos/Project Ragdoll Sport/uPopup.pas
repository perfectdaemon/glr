unit uPopup;

interface

uses
  glr, glrMath,
  uAccum;

const
  POPUP_SHOW_TIME = 2.0;

type
  TpdPopupText = class (TpdAccumItem)
  public
    text: IglrText;
    timeRemain: Single;
    procedure OnCreate(); override;
    procedure OnGet(); override;
    procedure OnFree(); override;
  end;

  TpdPopups = class (TpdAccum)
  public
    class function Initialize(aScene: Iglr2DScene): TpdPopups;
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdPopupText; reintroduce;
  end;


procedure UpdatePopups(const dt: Double);
procedure AddNewPopup(X, Y: Single; aText: String);
procedure AddNewPopupEx(X, Y: Single; aText: String; aColor: TdfVec4f);

implementation

uses
  uGlobal,
  glrUtils;

var
  scene: Iglr2DScene;
  internalZ: Integer;

{ TpdPopupText }

procedure TpdPopupText.OnCreate;
begin
  inherited;
  text := Factory.NewText();
  text.Font := fontCooper;
  text.Z := Z_HUD + internalZ;
  Inc(internalZ);
  scene.RegisterElement(text);

  text.Visible := False;
  text.Text := '';
end;

procedure TpdPopupText.OnFree;
begin
  inherited;
  text.Visible := False;
  text.Text := '';
end;

procedure TpdPopupText.OnGet;
begin
  inherited;
  text.Visible := True;
  timeRemain := POPUP_SHOW_TIME;
  text.Material.Diffuse := colorGreen;
end;

{ TpdPopups }

function TpdPopups.GetItem: TpdPopupText;
begin
  Result := inherited GetItem() as TpdPopupText;
end;

class function TpdPopups.Initialize(aScene: Iglr2DScene): TpdPopups;
begin
  scene := aScene;
  Result := TpdPopups.Create(12);
end;

function TpdPopups.NewAccumItem: TpdAccumItem;
begin
  Result := TpdPopupText.Create();
end;

procedure UpdatePopups(const dt: Double);
var
  i: Integer;
begin
  for i := 0 to High(popups.Items) do
    if popups.Items[i].Used then
      with popups.Items[i] as TpdPopupText do
      begin
        if timeRemain > 0 then
        begin
          timeRemain := timeRemain - dt;
          text.Position := text.Position + dfVec2f(0, -20 * dt);
          text.Material.PDiffuse.w := timeRemain / POPUP_SHOW_TIME;
        end
        else
          popups.FreeItem(popups.Items[i]);
      end;
end;

procedure AddNewPopup(X, Y: Single; aText: String);
begin
  with popups.GetItem().text do
  begin
    Text := aText;
    Position := dfVec2f(X, Y);
  end;
end;

procedure AddNewPopupEx(X, Y: Single; aText: String; aColor: TdfVec4f);
begin
  with popups.GetItem() do
  begin
    text.Text := aText;
    text.Position := dfVec2f(X, Y);
    text.Material.Diffuse := aColor;
  end;
end;


end.

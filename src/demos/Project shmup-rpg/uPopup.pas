unit uPopup;

interface

uses
  dfHRenderer, dfMath,
  uAccum;

const
  POPUP_SHOW_TIME = 2.0;

type
  TpdPopupText = class (TpdAccumItem)
  public
    text: IglrText;
    timeRemain: Single;
    initialColor: TdfVec3f;
    procedure OnCreate(); override;
    procedure OnGet(); override;
    procedure OnFree(); override;
  end;

  TpdPopups = class (TpdAccum)
  public
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdPopupText; reintroduce;
  end;


procedure LoadPopups();
procedure InitPopups(aScene: Iglr2DScene);
procedure UpdatePopups(const dt: Double);
procedure AddNewPopup(X, Y: Single; aText: String);
procedure AddNewPopupEx(X, Y: Single; aText: String; aColor: TdfVec3f);
procedure FreePopups();

var
  popups: TpdPopups;
  popupFont: IglrFont;

implementation

uses
  uGlobal,
  dfHUtility;

var
  scene: Iglr2DScene;

{ TpdPopupText }

procedure TpdPopupText.OnCreate;
begin
  inherited;
  text := Factory.NewText();
  text.Font := popupFont;
  text.Z := Z_POPUPS;
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
  text.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
  initialColor := dfVec3f(text.Material.MaterialOptions.Diffuse);
end;

{ TpdPopups }

function TpdPopups.GetItem: TpdPopupText;
begin
  Result := inherited GetItem() as TpdPopupText;
end;

function TpdPopups.NewAccumItem: TpdAccumItem;
begin
  Result := TpdPopupText.Create();
end;

procedure LoadPopups();
begin
  popupFont := glrNewFilledFont('Impact', 14);
end;

procedure InitPopups(aScene: Iglr2DScene);
begin
  scene := aScene;
  if Assigned(popups) then
    popups.Free();
  popups := TpdPopups.Create(12);
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
          text.Position := text.Position + dfVec2f(0, -20*dt);
          text.Material.MaterialOptions.Diffuse := dfVec4f(initialColor, timeRemain / POPUP_SHOW_TIME);
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

procedure AddNewPopupEx(X, Y: Single; aText: String; aColor: TdfVec3f);
begin
  with popups.GetItem() do
  begin
    text.Text := aText;
    text.Position := dfVec2f(X, Y);
    initialColor := aColor;
  end;
end;

procedure FreePopups();
begin
  popups.Free();
  popups := nil;
  popupFont := nil;
end;


end.

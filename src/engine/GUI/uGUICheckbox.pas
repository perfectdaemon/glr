unit uGUICheckbox;

interface

uses
  dfHRenderer,
  uGUIElement;

type
  TglrGUICheckBox = class (TglrGUIElement, IglrGUICheckBox)
  protected
    FChecked: Boolean;
    //Текстуры: флажок есть, флажка нет, флажок есть и мышь наведена, флажка нет и мышь наведена
    FTexOn, FTexOff, FTexOnOver, FTexOffOver: IglrTexture;

    FTextureAutoChange: Boolean;
    FOnCheck: TglrCheckEvent;

    procedure TryChangeTexture(aTex: IglrTexture);

    function GetChecked: Boolean;
    procedure SetChecked(const aChecked: Boolean);

    function GetTextureOn(): IglrTexture;
    function GetTextureOnOver(): IglrTexture;
    function GetTextureOff(): IglrTexture;
    function GetTextureOffOver(): IglrTexture;

    procedure SetTextureOn(aTexture: IglrTexture);
    procedure SetTextureOnOver(aTexture: IglrTexture);
    procedure SetTextureOff(aTexture: IglrTexture);
    procedure SetTextureOffOver(aTexture: IglrTexture);

    function GetAutoChange: Boolean;
    procedure SetAutoChange(aChange: Boolean);

    function GetOnCheck: TglrCheckEvent;
    procedure SetOnCheck(const aOnCheck: TglrCheckEvent);
  public
    property Checked: Boolean read GetChecked write SetChecked;

    procedure _MouseOver (X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure _MouseOut  (X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure _MouseClick(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;

    property TextureOn:      IglrTexture read GetTextureOn      write SetTextureOn;
    property TextureOnOver:  IglrTexture read GetTextureOnOver  write SetTextureOnOver;
    property TextureOff:     IglrTexture read GetTextureOff     write SetTextureOff;
    property TextureOffOver: IglrTexture read GetTextureOffOver write SetTextureOffOver;

    //Текстуры будут меняться автоматически при наведении, клие и уходе мыши
    property TextureAutoChange: Boolean read GetAutoChange write SetAutoChange;
    //Событие при смене статуса checked
    property OnCheck: TglrCheckEvent read GetOnCheck write SetOnCheck;

    procedure Reset(); override;

    constructor Create(); override;
    destructor Destroy(); override;
  end;


implementation

{ TdfGUICheckBox }
constructor TglrGUICheckBox.Create;
begin
  inherited;
  FTextureAutoChange := True;
  FChecked := False;
  FOnCheck := nil;
end;

destructor TglrGUICheckBox.Destroy;
begin

  inherited;
end;

function TglrGUICheckBox.GetAutoChange: Boolean;
begin
  Result := FTextureAutoChange;
end;

function TglrGUICheckBox.GetChecked: Boolean;
begin
  Result := FChecked;
end;

function TglrGUICheckBox.GetOnCheck: TglrCheckEvent;
begin
  Result := FOnCheck;
end;

function TglrGUICheckBox.GetTextureOff: IglrTexture;
begin
  Result := FTexOff;
end;

function TglrGUICheckBox.GetTextureOffOver: IglrTexture;
begin
  Result := FTexOffOver;
end;

function TglrGUICheckBox.GetTextureOn: IglrTexture;
begin
  Result := FTexOn;
end;

function TglrGUICheckBox.GetTextureOnOver: IglrTexture;
begin
  Result := FTexOnOver;
end;

procedure TglrGUICheckBox.Reset;
begin
  inherited;
  if FChecked then
    TryChangeTexture(FTexOn)
  else
    TryChangeTexture(FTexOff);
end;

procedure TglrGUICheckBox.SetAutoChange(aChange: Boolean);
begin
  FTextureAutoChange := aChange;
end;

procedure TglrGUICheckBox.SetChecked(const aChecked: Boolean);
begin
  if FChecked <> aChecked then
  begin
    FChecked := aChecked;
    if MousePos = mpOut then
    begin
      if FChecked then
        TryChangeTexture(FTexOn)
      else
        TryChangeTexture(FTexOff);
    end
    else //Mouse over
    begin
      if FChecked then
        TryChangeTexture(FTexOnOver)
      else
        TryChangeTexture(FTexOffOver);
    end;
  end;
  if Assigned(FOnCheck) then
    FOnCheck(Self, FChecked);
end;

procedure TglrGUICheckBox.SetOnCheck(const aOnCheck: TglrCheckEvent);
begin
  FOnCheck := aOnCheck;
end;

procedure TglrGUICheckBox.SetTextureOff(aTexture: IglrTexture);
begin
  FTexOff := aTexture;
  if not FChecked then
    TryChangeTexture(FTexOff);
end;

procedure TglrGUICheckBox.SetTextureOffOver(aTexture: IglrTexture);
begin
  FTexOffOver := aTexture;
end;

procedure TglrGUICheckBox.SetTextureOn(aTexture: IglrTexture);
begin
  FTexOn := aTexture;
  if FChecked then
    TryChangeTexture(FTexOn);
end;

procedure TglrGUICheckBox.SetTextureOnOver(aTexture: IglrTexture);
begin
  FTexOnOver := aTexture;
end;

procedure TglrGUICheckBox.TryChangeTexture(aTex: IglrTexture);
begin
  if Assigned(aTex) and FTextureAutoChange then
  begin
    FMaterial.Texture := aTex;
    UpdateTexCoords();
  end;
end;

procedure TglrGUICheckBox._MouseClick(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  inherited;
  Checked := not Checked;
end;

procedure TglrGUICheckBox._MouseOut(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  inherited;
  if FChecked then
    TryChangeTexture(FTexOn)
  else
    TryChangeTexture(FTexOff);
end;

procedure TglrGUICheckBox._MouseOver(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  inherited;
  if FChecked then
    TryChangeTexture(FTexOnOver)
  else
    TryChangeTexture(FTexOffOver);
end;

end.

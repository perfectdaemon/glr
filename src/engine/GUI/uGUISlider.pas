unit uGUISlider;

interface

uses
  glr, glrMath, uGUIElement;

type
  TglrGUISlider = class (TglrGUIElement, IglrGUISlider)
  protected
    FOnValueChanged: TglrValueChangedEvent;
    FMaxValue, FMinValue, FValue: Integer;
    FSliderBtn, FSliderOver: IglrSprite;
    FMouseDownAtMe: Boolean;

    function GetMaxValue: Integer;
    function GetMinValue: Integer;
    function GetSliderBtn: IglrSprite;
    function GetSliderOver: IglrSprite;
    function GetValue: Integer;
    function GetOnValueChanged(): TglrValueChangedEvent;

    procedure SetMaxValue(const Value: Integer);
    procedure SetMinValue(const Value: Integer);
    procedure SetSliderBtn(const Value: IglrSprite);
    procedure SetSliderOver(const Value: IglrSprite);
    procedure SetValue(const Value: Integer);
    procedure SetOnValueChanged(const aOnValueChanged: TglrValueChangedEvent);
    procedure SetPos(const aPos: TdfVec3f); override;
    procedure SetVis(const aVis: Boolean); override;

    procedure _MouseMove (X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure _MouseDown (X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure _MouseUp   (X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure _MouseOver (X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure _MouseOut  (X, Y: Integer; Shift: TglrMouseShiftState); override;

    procedure UpdateSprites();
  public
    property Value:    Integer read GetValue    write SetValue;
    property MinValue: Integer read GetMinValue write SetMinValue;
    property MaxValue: Integer read GetMaxValue write SetMaxValue;
    property SliderButton: IglrSprite read GetSliderBtn  write SetSliderBtn;
    property SliderOver:   IglrSprite read GetSliderOver write SetSliderOver;

    constructor Create(); override;
    destructor Destroy(); override;

    //Проверка на попадание по элементу
    function CheckHit(X, Y: Integer): Boolean; override;
  end;

implementation

uses
  ExportFunc;

{ TdfGUISlider }

function TglrGUISlider.CheckHit(X, Y: Integer): Boolean;

  function SliderBtnCheckHit(X, Y: Integer): Boolean;
  begin
    with FSliderBtn.GetBB() do
      Result := ( (X > Left) and (X < Right) )
             and( (Y > Top)  and (Y < Bottom) );
  end;

begin
  Result := inherited CheckHit(X, Y) or SliderBtnCheckHit(X, Y);
end;

constructor TglrGUISlider.Create;
begin
  inherited;
  FSliderBtn := GetObjectFactory().NewHudSprite();
  FSliderBtn.PivotPoint := ppCenter;
  FSliderOver := GetObjectFactory().NewHudSprite();
  FSliderOver.PivotPoint := ppTopLeft;
  Self.AddChild(FSliderOver);
  Self.AddChild(FSliderBtn);
  FMinValue := 0;
  FMaxValue := 100;
  FValue := 50;
end;

destructor TglrGUISlider.Destroy;
begin
  inherited;
end;

function TglrGUISlider.GetMaxValue: Integer;
begin
  Result := FMaxValue;
end;

function TglrGUISlider.GetMinValue: Integer;
begin
  Result := FMinValue;
end;

function TglrGUISlider.GetOnValueChanged: TglrValueChangedEvent;
begin
  Result := FOnValueChanged;
end;

function TglrGUISlider.GetSliderBtn: IglrSprite;
begin
  Result := FSliderBtn;
end;

function TglrGUISlider.GetSliderOver: IglrSprite;
begin
  Result := FSliderOver;
end;

function TglrGUISlider.GetValue: Integer;
begin
  Result := FValue;
end;

procedure TglrGUISlider.SetMaxValue(const Value: Integer);
begin
  FMaxValue := Value;
  UpdateSprites();
end;

procedure TglrGUISlider.SetMinValue(const Value: Integer);
begin
  FMinValue := Value;
  UpdateSprites();
end;

procedure TglrGUISlider.SetOnValueChanged(
  const aOnValueChanged: TglrValueChangedEvent);
begin
  FOnValueChanged := aOnValueChanged;
end;

procedure TglrGUISlider.SetPos(const aPos: TdfVec3f);
begin
  inherited;
  UpdateSprites();

  FSliderOver.PPosition.z := aPos.z + 1;
  FSliderBtn.PPosition.z := aPos.z + 5;
end;

procedure TglrGUISlider.SetSliderBtn(const Value: IglrSprite);
begin
  FSliderBtn := Value;
end;

procedure TglrGUISlider.SetSliderOver(const Value: IglrSprite);
begin
  FSliderOver := Value;
end;

procedure TglrGUISlider.SetValue(const Value: Integer);
begin
  if FValue <> Value then
  begin
    FValue := Clamp(Value, FMinValue, FMaxValue);
    UpdateSprites();
    if Assigned(FOnValueChanged) then
      FOnValueChanged(Self, FValue);
  end;
end;

procedure TglrGUISlider.SetVis(const aVis: Boolean);
begin
  inherited;
  FSliderBtn.Visible := aVis;
  FSliderOver.Visible := aVis;
end;

procedure TglrGUISlider.UpdateSprites;
var
  percentage: Single;
begin
  //Получаем значение Value в пределах 0..1
  percentage := Value / (FMaxValue - FMinValue);
  FSliderBtn.Position2D := {Self.Position + }dfVec2f(Self.Width * percentage, Self.Height / 2);
  {FSliderOver.Position := Self.Position;}

  FSliderOver.Width := Self.Width * percentage;
  with FSliderOver.Material.Texture.GetTexDesc do
  begin
    FSliderOver.TexCoords[0] := dfVec2f((X + RegionWidth * percentage) / Width , (Y + RegionHeight) / Height);
    FSliderOver.TexCoords[1] := dfVec2f(FSliderOver.TexCoords[0].x, Y / Height);
  end;
end;

procedure TglrGUISlider._MouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  inherited;
  FMouseDownAtMe := True;
  Value := Round((MaxValue - MinValue) * (X - AbsoluteMatrix.Pos.x) / Width);
end;

procedure TglrGUISlider._MouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  inherited;
  if (ssLeft in Shift) and FMouseDownAtMe then
  begin
    Value := Round((MaxValue - MinValue) * (X - AbsoluteMatrix.Pos.x) / Width);
  end;
end;

procedure TglrGUISlider._MouseOut(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  inherited;
end;

procedure TglrGUISlider._MouseOver(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  inherited;
end;

procedure TglrGUISlider._MouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  inherited;
  FMouseDownAtMe := False;
end;

end.

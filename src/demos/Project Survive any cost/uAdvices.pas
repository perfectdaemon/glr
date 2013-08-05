unit uAdvices;

interface

uses
  dfHRenderer, dfMath;

const
  ADVICE_BACKGROUND_W = 500;
  ADVICE_TEXT_POSITION_X = 280;
  ADVICE_TEXT_POSITION_Y = 200;

  ADVICE_PREV_OFFSET_X = -30;
  ADVICE_PREV_OFFSET_Y = 40;

  ADVICE_NEXT_OFFSET_X = 520;
  ADVICE_NEXT_OFFSET_Y = ADVICE_PREV_OFFSET_Y;

type
  //Класс, отвечающий за отображение советов
  TpdAdviceController = class
  private
    FLastIndex, FCurrentIndex: Integer;
    FAdvices: array of WideString;
    FAdviceText: IglrText;
    FBackground: IglrSprite;
    FGUIManager: IglrGUIManager;
    FVisible: Boolean;
    procedure Expand();
    //Проверяем и изменяем визуальное состояние кнопок вперд, назад
    procedure ChangePrevNextState();
    constructor Create(); virtual;
    destructor Destroy(); override;
    procedure SetVisible(const Value: Boolean);
    procedure Show();
    procedure Hide();
  public
    FBtnNext, FBtnPrev: IglrGUIButton;
    class function Initialize(aScene: Iglr2DScene): TpdAdviceController;

    function AddAdvice(aAdviceText: WideString; aForceSwitch: Boolean = True): Integer; //Возвращает индекс
    procedure Previous();
    procedure Next();
    procedure ToIndex(const aIndex: Integer);
    procedure RemoveAdvice(const aIndex: Integer);

    procedure Update(const dt: Double);

    property Visible: Boolean read FVisible write SetVisible;
  end;

implementation

uses
  SysUtils,
  dfTweener,
  uGlobal;

const
  INITIAL_LENGTH = 8;
  PREV_BTN_NORMAL_TEXTURE = 'advicebtn_normal.png';
  PREV_BTN_OVER_TEXTURE   = 'advicebtn_over.png';
  PREV_BTN_CLICK_TEXTURE  = 'advicebtn_click.png';

{ TpdAdviceController }

//--Для твина
procedure SetSingle(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdAdviceController do
  begin
    FAdviceText.PPosition.y := aValue;
    FBackground.PPosition.y := aValue - 5;
    FBtnNext.PPosition.y := aValue + ADVICE_NEXT_OFFSET_Y;
    FBtnPrev.PPosition.y := aValue + ADVICE_PREV_OFFSET_Y;
  end;
end;

//-для твина при переключении
procedure SetHeight(aObject: TdfTweenObject; aValue: Single);
begin
  with aObject as TpdAdviceController do
    FBackground.Height := aValue;
end;


function TpdAdviceController.AddAdvice(aAdviceText: WideString;
  aForceSwitch: Boolean): Integer;
begin
  if FLastIndex = High(FAdvices) then
    Expand();
  Inc(FLastIndex);
  FAdvices[FLastIndex] := aAdviceText;
  Result := FLastIndex;
  if (aForceSwitch) or (FCurrentIndex = -1) then
    ToIndex(FLastIndex);
  ChangePrevNextState();
end;

procedure TpdAdviceController.ChangePrevNextState;
begin
  if FCurrentIndex = FLastIndex then
    FBtnNext.Material.MaterialOptions.Diffuse := dfVec4f(0.4, 0.4, 0.4, 1.0)
  else
    FBtnNext.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);

  if FCurrentIndex = 0 then
    FBtnPrev.Material.MaterialOptions.Diffuse := dfVec4f(0.4, 0.4, 0.4, 1.0)
  else
    FBtnPrev.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
end;

constructor TpdAdviceController.Create;
begin
  inherited;
  FLastIndex := -1;
  FCurrentIndex := -1;
  SetLength(FAdvices, INITIAL_LENGTH);
  FAdviceText := Factory.NewText();
  FBtnPrev := Factory.NewGUIButton();
  FBtnNext := Factory.NewGUIButton();
  FBackground := Factory.NewHudSprite();
  FVisible := False;
end;

destructor TpdAdviceController.Destroy;
begin
  FGUIManager.UnregisterElement(FBtnNext);
  FGUIManager.UnregisterElement(FBtnPrev);
  SetLength(FAdvices, 0);
  inherited;
end;

procedure TpdAdviceController.Expand;
begin
  SetLength(FAdvices, Length(FAdvices) + Length(FAdvices) div 2);
end;

procedure TpdAdviceController.Hide;
begin
  Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, ADVICE_TEXT_POSITION_Y, - 120, 1.2, 0);
end;

class function TpdAdviceController.Initialize(
  aScene: Iglr2DScene): TpdAdviceController;
begin
  Result := TpdAdviceController.Create();
  with Result do
  begin
    FGUIManager := R.GUIManager;

    FBackground.Z := Z_INGAMEMENU - 1;
    FBackground.Position := dfVec2f((R.WindowWidth - ADVICE_BACKGROUND_W) div 2, ADVICE_TEXT_POSITION_Y - 5);
    FBackground.Width := 500;
    FBackground.Height := 120;
    FBackground.Material.MaterialOptions.Diffuse := dfVec4f(0 / 255, 132 / 255, 251 / 255);
    aScene.RegisterElement(FBackground);

    FAdviceText.Font := fontCooper;
    FAdviceText.ScaleMult(0.7);
    FAdviceText.Position := dfVec2f(FBackground.Position.x + 5, ADVICE_TEXT_POSITION_Y);
    FAdviceText.Z := Z_INGAMEMENU;
    aScene.RegisterElement(FAdviceText);

    //--Buttons
    with FBtnPrev do
    begin
      Position := FAdviceText.Position + dfVec2f(ADVICE_PREV_OFFSET_X, ADVICE_PREV_OFFSET_Y);
      PivotPoint := ppCenter;
      TextureNormal := atlasGame.LoadTexture(PREV_BTN_NORMAL_TEXTURE);
      TextureOver := atlasGame.LoadTexture(PREV_BTN_OVER_TEXTURE);
      TextureClick := atlasGame.LoadTexture(PREV_BTN_CLICK_TEXTURE);
//      OnMouseClick := OnAdviceBtnClick;
      Z := Z_INGAMEMENU;

      UpdateTexCoords();
      SetSizeToTextureSize();
    end;

    with FBtnNext do
    begin
      Position := FAdviceText.Position + dfVec2f(ADVICE_NEXT_OFFSET_X, ADVICE_NEXT_OFFSET_Y);
      PivotPoint := ppCenter;
      TextureNormal := atlasGame.LoadTexture(PREV_BTN_NORMAL_TEXTURE);
      TextureOver := atlasGame.LoadTexture(PREV_BTN_OVER_TEXTURE);
      TextureClick := atlasGame.LoadTexture(PREV_BTN_CLICK_TEXTURE);
//      OnMouseClick := OnAdviceBtnClick;
      Z := Z_INGAMEMENU;
      Rotation := 180;
      UpdateTexCoords();
      SetSizeToTextureSize();
    end;

    aScene.RegisterElement(FBtnPrev);
    aScene.RegisterElement(FBtnNext);
    FGUIManager.RegisterElement(FBtnPrev);
    FGUIManager.RegisterElement(FBtnNext);
  end;
end;

procedure TpdAdviceController.RemoveAdvice(const aIndex: Integer);
begin
  //*
end;

procedure TpdAdviceController.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    if FVisible then
      Show()
    else
      Hide();
  end;
end;

procedure TpdAdviceController.Show;
begin
  Tweener.AddTweenSingle(Self, @SetSingle, tsExpoEaseIn, -130, ADVICE_TEXT_POSITION_Y, 1.2, 0);
end;

procedure TpdAdviceController.ToIndex(const aIndex: Integer);

  function CountPos(const subText: WideString; Text: WideString): Integer;
  begin
    if (Length(subText) = 0) or (Length(Text) = 0) or (Pos(subText, Text) = 0) then
      Result := 0
    else
      Result := (Length(Text) - Length(StringReplace(Text, subText, '', [rfReplaceAll]))) div Length(subText);
  end;

var
  height: Single;

begin
  Tweener.AddTweenPSingle(@FAdviceText.Material.MaterialOptions.PDiffuse.w, tsExpoEaseIn,
    0.0, 1.0, 3.0, 0.0);
  FCurrentIndex := aIndex;
  FAdviceText.Text := FAdvices[aIndex];
  height := 25 + 25 * CountPos(#13#10, FAdvices[aIndex]);
  Tweener.AddTweenSingle(Self, @SetHeight, tsExpoEaseIn, FBackground.Height, height, 0.5, 0);
//  Tweener.AddTweenSingle(Self,
//   @procedure(aObject: TdfTweenObject; aValue: Single)
//    begin
//      with aObject as TpdAdviceController do
//        FBackground.Height := aValue;
//    end,
//    tsExpoEaseIn, FBackground.Height, height, 1.0, 0.0);

  ChangePrevNextState();
end;

procedure TpdAdviceController.Next;
begin
  if (FCurrentIndex = -1) or (FCurrentIndex = FLastIndex) then
    Exit()
  else
    ToIndex(FCurrentIndex + 1);
end;

procedure TpdAdviceController.Previous;
begin
  if (FCurrentIndex = -1) or (FCurrentIndex = 0) then
    Exit()
  else
    ToIndex(FCurrentIndex - 1);
end;

procedure TpdAdviceController.Update(const dt: Double);
begin

end;


end.

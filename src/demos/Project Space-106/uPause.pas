unit uPause;

interface

uses
  glr, glrMath;

type
  TpdPauseMenu = class
  private
    FCont: IglrNode;
    FPauseText: IglrText;
    FBtnContinue, FBtnReplay, FBtnExit: IglrGUITextButton;
    procedure InitializeButton(var Button: IglrGUITextButton; aText: WideString; X, Y: Single);
    function GetActive(): Boolean;
  public
    property IsActive: Boolean read GetActive;
    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure ShowOrHide();

    procedure Update(const dt: Double);
  end;

implementation

uses
  uGlobal;

{ TpdPauseMenu }

procedure MouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with pauseMenu do
    if Sender = (FBtnContinue as IglrGUIElement) then
      ShowOrHide()
    else if Sender = (FBtnReplay as IglrGUIElement) then
    begin
      ShowOrHide();
      GameEnd();
      GameStart();
    end
    else if Sender = (FBtnExit as IglrGUIElement) then
      R.Stop();
end;

procedure MouseOver(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with (Sender as IglrGUITextButton) do
  begin
    Material.Diffuse := scolorRed;
    TextObject.Material.Diffuse := scolorRed;
  end;
end;

procedure MouseOut(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with (Sender as IglrGUITextButton) do
  begin
    Material.Diffuse := scolorBlue;
    TextObject.Material.Diffuse := scolorBlue;
  end;
end;

procedure TpdPauseMenu.InitializeButton(var Button: IglrGUITextButton;
  aText: WideString; X, Y: Single);
begin
  with Button do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(X, Y, Z_INGAMEMENU);

    with TextObject do
    begin
      Font := fontSouvenir;
      Text := aText;
      PivotPoint := ppTopLeft;
      Position2D := dfVec2f(BTN_TEXT_OFFSET_X, BTN_TEXT_OFFSET_Y);
      Material.Diffuse := scolorBlue;
    end;
    TextureNormal := atlasMain.LoadTexture(BTN_NORMAL_TEXTURE);
//    TextureOver := atlasMain.LoadTexture(BTN_OVER_TEXTURE);
//    TextureClick := atlasMain.LoadTexture(BTN_CLICK_TEXTURE);
    TextureAutoChange := False;
    Material.Diffuse := scolorBlue;

    UpdateTexCoords();
    SetSizeToTextureSize();

    OnMouseClick := MouseClick;
    OnMouseOver := MouseOver;
    OnMouseOut := MouseOut;
  end;
end;

procedure TpdPauseMenu.ShowOrHide;
begin
  if FCont.Visible then
  begin
    //hide
    FCont.Visible := False;
    R.GUIManager.UnregisterElement(FBtnContinue);
    R.GUIManager.UnregisterElement(FBtnReplay);
    R.GUIManager.UnregisterElement(FBtnExit);
  end
  else
  begin
    //show
    FCont.Visible := True;
    R.GUIManager.RegisterElement(FBtnContinue);
    R.GUIManager.RegisterElement(FBtnReplay);
    R.GUIManager.RegisterElement(FBtnExit);
  end;
end;

constructor TpdPauseMenu.Create;
begin
  inherited;
  FCont := Factory.NewNode();

  FPauseText := Factory.NewText();
  with FPauseText do
  begin
    Font := fontSouvenir;
    PivotPoint := ppCenter;
    Position := dfVec3f(R.WindowWidth div 2, R.WindowHeight div 2, Z_INGAMEMENU);
    Text := 'П А У З А';
    ScaleMult(1.0);
    Material.Diffuse := scolorWhite;
  end;

  FBtnContinue := Factory.NewGUITextButton();
  FBtnReplay := Factory.NewGUITextButton();
  FBtnExit := Factory.NewGUITextButton();

  InitializeButton(FBtnContinue, 'Продолжить', (R.WindowWidth div 2) - 250, R.WindowHeight - 100);
  InitializeButton(FBtnReplay, 'Еще раз', (R.WindowWidth div 2), R.WindowHeight - 100);
  InitializeButton(FBtnExit, 'Выйти', (R.WindowWidth div 2) + 250, R.WindowHeight - 100);

  FCont.AddChild(FPauseText);
  FCont.AddChild(FBtnContinue);
  FCont.AddChild(FBtnReplay);
  FCont.AddChild(FBtnExit);
  hudScene.RootNode.AddChild(FCont);

  FCont.Visible := False;
end;

destructor TpdPauseMenu.Destroy;
begin
  FCont.RemoveAllChilds();
  hudScene.RootNode.RemoveChild(FCont);
  inherited;
end;

function TpdPauseMenu.GetActive: Boolean;
begin
  Result := FCont.Visible;
end;

procedure TpdPauseMenu.Update(const dt: Double);
begin

end;

end.

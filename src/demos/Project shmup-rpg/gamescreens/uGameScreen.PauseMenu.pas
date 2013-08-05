unit uGameScreen.PauseMenu;

interface

uses
  uGameScreen,
  uButtonsInfo,
  dfHRenderer;

const
  BTN_WIDTH = 249;
  BTN_HEIGHT = 45;

  //Background

  BACK_X = 0;
  BACK_Y = 0;
  BACK_W = 380;
  BACK_H = 365;

  //To game button

//  BTN_TG_X = 50;
//  BTN_TG_Y = 300;
  BTN_TG_NORMAL_X = 250;
  BTN_TG_NORMAL_Y = 412;
  BTN_TG_OVER_X   = 0;
  BTN_TG_OVER_Y   = 412;
  BTN_TG_CLICK_X  = 0;
  BTN_TG_CLICK_Y  = 458;

  //To menu button
//  BTN_TM_X = BTN_NG_X;
//  BTN_TM_Y = BTN_NG_Y + BTN_HEIGHT + 5;
  BTN_TM_NORMAL_X = 0;
  BTN_TM_NORMAL_Y = 366;
  BTN_TM_OVER_X   = 250;
  BTN_TM_OVER_Y   = 458;
  BTN_TM_CLICK_X  = 250;
  BTN_TM_CLICK_Y  = 366;

type
  TpdPauseMenu = class (TpdGameScreen)
  private
    FScene: Iglr2DScene;
    FGUIManager: IglrGUIManager;
    FScrMainMenu, FScrGame: TpdGameScreen;

    //Кнопки
    FBtnToMenu, FBtnToGame: IglrGUIButton;
    FAtlasTexture: IglrTexture;
    FBackground: IglrSprite;

    procedure LoadAtlasTexture(const aFilename: String);
    procedure InitButtons(aToMenuInfo, aToGameInfo: TpdButtonInfo);
    procedure InitBackground();
  protected
    procedure FadeIn(deltaTime: Double); override;
    procedure FadeOut(deltaTime: Double); override;

    procedure SetStatus(const aStatus: TpdGameScreenStatus); override;
    procedure FadeInComplete();
    procedure FadeOutComplete();
  public
    constructor Create(); override;
    destructor Destroy; override;

    procedure Load(); override;
    procedure Unload(); override;

    procedure Update(deltaTime: Double); override;

    procedure SetGameScreenLinks(aToMainMenu, aToGame: TpdGameScreen);
  end;

var
  pauseMenu: TpdPauseMenu;

implementation

uses
  dfMath,
  uGlobal;

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with pauseMenu do
  begin
    if Sender = (FBtnToMenu as IglrGUIElement) then
    begin
      FScrGame.Status := gssFadeOut;
      OnNotify(FScrMainMenu, naSwitchTo);
    end

    else if Sender = (FBtnToGame as IglrGUIElement) then
    begin
      OnNotify(FScrGame, naSwitchTo);
    end;
  end;
end;

procedure OnMouseOver(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin

end;

procedure OnMouseOut(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin

end;

{ TpdPauseMenu }

constructor TpdPauseMenu.Create;
var
  aToMenuInfo, aToGameInfo: TpdButtonInfo;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();
  LoadAtlasTexture(FILE_PAUSEMENU_TEXTURE_ATLAS);
  InitBackground();

  {$REGION 'info records init'}
  with aToMenuInfo do
  begin
    texture := FAtlasTexture;
    width := BTN_WIDTH;
    height := BTN_HEIGHT;
    x := Round(FBackground.Position.x);
    y := Round(FBackground.Position.y + 50);
    texRegionInfo[ttNormal].x := BTN_TM_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_TM_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_TM_OVER_X;
    texRegionInfo[ttOver].y := BTN_TM_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_TM_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_TM_CLICK_Y;
  end;

  with aToGameInfo do
  begin
    texture := FAtlasTexture;
    width := BTN_WIDTH;
    height := BTN_HEIGHT;
    x := Round(FBackground.Position.x);
    y := Round(FBackground.Position.y - 50);
    texRegionInfo[ttNormal].x := BTN_TG_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_TG_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_TG_OVER_X;
    texRegionInfo[ttOver].y := BTN_TG_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_TG_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_TG_CLICK_Y;
  end;
  {$ENDREGION}

  InitButtons(aToMenuInfo, aToGameInfo);
end;

destructor TpdPauseMenu.Destroy;
begin

  inherited;
end;

procedure TpdPauseMenu.FadeIn(deltaTime: Double);
begin
  inherited;

end;

procedure TpdPauseMenu.FadeInComplete;
begin
  Status := gssReady;
  FGUIManager.RegisterElement(FBtnToMenu);
  FGUIManager.RegisterElement(FBtnToGame);
end;

procedure TpdPauseMenu.FadeOut(deltaTime: Double);
begin
  inherited;

end;

procedure TpdPauseMenu.FadeOutComplete;
begin
  Status := gssNone;
end;

procedure TpdPauseMenu.InitBackground;
begin
  FBackground := Factory.NewHudSprite();
  FBackground.Material.Texture.Load2DRegion(FAtlasTexture, BACK_X, BACK_Y, BACK_W, BACK_H);
  FBackground.UpdateTexCoords();
  FBackground.SetSizeToTextureSize;
  FBackground.Z := 45;
  FBackground.PivotPoint := ppCenter;
  FBackground.Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);

  FScene.RegisterElement(FBackground);
end;

procedure TpdPauseMenu.InitButtons(aToMenuInfo, aToGameInfo: TpdButtonInfo);

  function InitButton(aInfo: TpdButtonInfo): IglrGUIButton;
  begin
    Result := Factory.NewGUIButton();
    with Result do
    begin
      PivotPoint := ppCenter;
      Position := dfVec2f(aInfo.x, aInfo.y);
      Z := 50;
      Width := aInfo.width;
      Height := aInfo.height;
      //normal
      TextureNormal := Factory.NewTexture();
      TextureNormal.Load2DRegion(aInfo.texture, aInfo.texRegionInfo[ttNormal].x,
        aInfo.texRegionInfo[ttNormal].y, aInfo.width, aInfo.height);
      TextureNormal.BlendingMode := tbmTransparency;
      TextureNormal.CombineMode := tcmModulate;
      UpdateTexCoords();
      //over
      TextureOver := Factory.NewTexture();
      TextureOver.Load2DRegion(aInfo.texture, aInfo.texRegionInfo[ttOver].x,
        aInfo.texRegionInfo[ttOver].y, aInfo.width, aInfo.height);
      TextureOver.BlendingMode := tbmTransparency;
      TextureOver.CombineMode := tcmModulate;
      //click
      TextureClick := Factory.NewTexture();
      TextureClick.Load2DRegion(aInfo.texture, aInfo.texRegionInfo[ttClicked].x,
        aInfo.texRegionInfo[ttClicked].y, aInfo.width, aInfo.height);
      TextureClick.BlendingMode := tbmTransparency;
      TextureClick.CombineMode := tcmModulate;
      //TODO: disabled state for gui button
    end;
  end;
begin
  FBtnToMenu := InitButton(aToMenuInfo);
  FBtnToGame := InitButton(aToGameInfo);

  FBtnToMenu.OnMouseClick := OnMouseClick;
  FBtnToGame.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnToMenu);
  FScene.RegisterElement(FBtnToGame);
end;

procedure TpdPauseMenu.Load;
begin
  inherited;
  R.RegisterScene(FScene);
end;

procedure TpdPauseMenu.LoadAtlasTexture(const aFilename: String);
begin
  FAtlasTexture := Factory.NewTexture();
  FAtlasTexture.Load2D(aFilename);
  FAtlasTexture.BlendingMode := tbmTransparency;
  FAtlasTexture.CombineMode := tcmModulate;
end;

procedure TpdPauseMenu.SetGameScreenLinks(aToMainMenu, aToGame: TpdGameScreen);
begin
  FScrMainMenu := aToMainMenu;
  FScrGame := aToGame;
end;

procedure TpdPauseMenu.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
  case aStatus of
    gssNone: Exit;

    gssReady: Exit;

//    gssFadeIn:
//    begin
//      dfDebugInfo.Visible := False;
//      FBlankBack.Visible := True;
//      FRoot.Visible := True;
//      Ft := 0;
//    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      FGUIManager.UnregisterElement(FBtnToMenu);
      FGUIManager.UnregisterElement(FBtnToGame);
//      FBlankBack.Visible := True;
//      Ft := 0;
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdPauseMenu.Unload;
begin
  inherited;
  R.UnregisterScene(FScene);
end;

procedure TpdPauseMenu.Update(deltaTime: Double);
begin
  inherited;
  case FStatus of
    gssNone           : Exit;
    gssFadeIn         : FadeIn(deltaTime);
    gssFadeInComplete : Exit;
    gssFadeOut        : FadeOut(deltaTime);
    gssFadeOutComplete: Exit;

    gssReady:
    begin
      // ?
    end;
  end;
end;

end.

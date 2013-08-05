unit uGameScreen.MainMenu;

interface

uses
  dfHRenderer,
  uButtonsInfo,
  uGameScreen;

const
  FILE_MAINMENU_TEXTURE_ATLAS = 'shmup_res/main_menu.tga';
  FILE_MAINMENU_BACKGROUND = 'shmup_res/main_menu_back.tga';
  BTN_WIDTH = 249;
  BTN_HEIGHT = 45;

  //New game button

  BTN_NG_X = 50;
  BTN_NG_Y = 300;
  BTN_NG_NORMAL_X = 0;
  BTN_NG_NORMAL_Y = 92;
  BTN_NG_OVER_X   = 0;
  BTN_NG_OVER_Y   = 0;
  BTN_NG_CLICK_X  = 0;
  BTN_NG_CLICK_Y  = 138;

  //Authors button
  BTN_AU_X = BTN_NG_X;
  BTN_AU_Y = BTN_NG_Y + BTN_HEIGHT + 5;
  BTN_AU_NORMAL_X = 0;
  BTN_AU_NORMAL_Y = 368;
  BTN_AU_OVER_X   = 0;
  BTN_AU_OVER_Y   = 322;
  BTN_AU_CLICK_X  = 0;
  BTN_AU_CLICK_Y  = 276;

  //Exit button
  BTN_EX_X = BTN_NG_X;
  BTN_EX_Y = BTN_AU_Y + BTN_HEIGHT + 5;
  BTN_EX_NORMAL_X = 0;
  BTN_EX_NORMAL_Y = 184;
  BTN_EX_OVER_X   = 0;
  BTN_EX_OVER_Y   = 46;
  BTN_EX_CLICK_X  = 0;
  BTN_EX_CLICK_Y  = 230;

type
  TpdMainMenu = class (TpdGameScreen)
  private
    FGUIManager: IdfGUIManager;
    FScene: Idf2DScene;
    FScrAuthors, FScrNewGame: TpdGameScreen;

    // ÌÓÔÍË
    FBtnNewGame, FBtnAuthors, FBtnExit: IdfGUIButton;
    FAtlasTexture: IdfTexture;
    FBackground: IdfSprite;

    procedure LoadAtlasTexture(const aFilename: String);
    procedure LoadBackground(const aFilename: String);
    procedure InitButtons(aNewGameInfo, aAuthorsInfo, aExitInfo: TpdButtonInfo);
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

    procedure SetGameScreenLinks(aAuthors, aNewGame: TpdGameScreen);
  end;

var
  mainMenu: TpdMainMenu;

implementation

uses
  dfMath,
  uGlobal;

procedure OnMouseClick(Sender: IdfGUIElement; X, Y: Integer; mb: TdfMouseButton;
  Shift: TdfMouseShiftState);
begin
  if Sender = (mainMenu.FBtnNewGame as IdfGUIElement) then
  begin

  end

  else if Sender = (mainMenu.FbtnAuthors as IdfGUIElement) then
  begin

  end
  
  else if Sender = (mainMenu.FBtnExit as IdfGUIElement) then
  begin
    mainMenu.OnNotify(nil, naQuitGame);
  end;
end;

procedure OnMouseOver(Sender: IdfGUIElement; X, Y: Integer; Button: TdfMouseButton;
  Shift: TdfMouseShiftState);
begin

end;

procedure OnMouseOut(Sender: IdfGUIElement; X, Y: Integer; Button: TdfMouseButton;
  Shift: TdfMouseShiftState);
begin

end;

{ TpdMainMenu }

constructor TpdMainMenu.Create;
var
  aNewGameInfo, aAuthorsInfo, aExitInfo: TpdButtonInfo;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := dfCreate2DScene();

  LoadAtlasTexture(FILE_MAINMENU_TEXTURE_ATLAS);
  LoadBackground(FILE_MAINMENU_BACKGROUND);
  {$REGION 'info records init'}
  with aNewGameInfo do
  begin
    texture := FAtlasTexture;
    width := BTN_WIDTH;
    height := BTN_HEIGHT;
    x := BTN_NG_X;
    y := BTN_NG_Y;
    texRegionInfo[ttNormal].x := BTN_NG_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_NG_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_NG_OVER_X;
    texRegionInfo[ttOver].y := BTN_NG_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_NG_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_NG_CLICK_Y;
  end;

  with aAuthorsInfo do
  begin
    texture := FAtlasTexture;
    width := BTN_WIDTH;
    height := BTN_HEIGHT;
    x := BTN_AU_X;
    y := BTN_AU_Y;
    texRegionInfo[ttNormal].x := BTN_AU_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_AU_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_AU_OVER_X;
    texRegionInfo[ttOver].y := BTN_AU_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_AU_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_AU_CLICK_Y;
  end;

  with aExitInfo do
  begin
    texture := FAtlasTexture;
    width := BTN_WIDTH;
    height := BTN_HEIGHT;
    x := BTN_EX_X;
    y := BTN_EX_Y;
    texRegionInfo[ttNormal].x := BTN_EX_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_EX_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_EX_OVER_X;
    texRegionInfo[ttOver].y := BTN_EX_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_EX_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_EX_CLICK_Y;
  end;
  {$ENDREGION}
  InitButtons(aNewGameInfo, aAuthorsInfo, aExitInfo);
end;

destructor TpdMainMenu.Destroy;
begin
  inherited;
end;

procedure TpdMainMenu.FadeIn(deltaTime: Double);
begin
  inherited;

end;

procedure TpdMainMenu.FadeInComplete;
begin
  Status := gssReady;
end;

procedure TpdMainMenu.FadeOut(deltaTime: Double);
begin
  inherited;

end;

procedure TpdMainMenu.FadeOutComplete;
begin
  status := gssNone;
end;

procedure TpdMainMenu.InitButtons(aNewGameInfo, aAuthorsInfo, aExitInfo: TpdButtonInfo);

  function InitButton(aInfo: TpdButtonInfo): IdfGUIButton;
  begin
    Result := dfCreateGUIButton();
    with Result do
    begin
      Position := dfVec2f(aInfo.x, aInfo.y);
      Width := aInfo.width;
      Height := aInfo.height;
      //normal
      TextureNormal := dfCreateTexture();
      TextureNormal.Load2DRegion(aInfo.texture, aInfo.texRegionInfo[ttNormal].x,
        aInfo.texRegionInfo[ttNormal].y, aInfo.width, aInfo.height);
      TextureNormal.BlendingMode := tbmTransparency;
      TextureNormal.CombineMode := tcmModulate;
      UpdateTexCoords();
      //over
      TextureOver := dfCreateTexture();
      TextureOver.Load2DRegion(aInfo.texture, aInfo.texRegionInfo[ttOver].x,
        aInfo.texRegionInfo[ttOver].y, aInfo.width, aInfo.height);
      TextureOver.BlendingMode := tbmTransparency;
      TextureOver.CombineMode := tcmModulate;
      //click
      TextureClick := dfCreateTexture();
      TextureClick.Load2DRegion(aInfo.texture, aInfo.texRegionInfo[ttClicked].x,
        aInfo.texRegionInfo[ttClicked].y, aInfo.width, aInfo.height);
      TextureClick.BlendingMode := tbmTransparency;
      TextureClick.CombineMode := tcmModulate;
      //TODO: disabled state for gui button
    end;
  end;
begin
  FBtnNewGame := InitButton(aNewGameInfo);
  FBtnAuthors := InitButton(aAuthorsInfo);
  FBtnExit := InitButton(aExitInfo);

  FBtnNewGame.OnMouseClick := OnMouseClick;
  FBtnAuthors.OnMouseClick := OnMouseClick;
  FBtnExit.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnNewGame);
  FScene.RegisterElement(FBtnAuthors);
  FScene.RegisterElement(FBtnExit);
end;

procedure TpdMainMenu.Load;
begin
  inherited;
  R.RegisterScene(FScene);

  FGUIManager.RegisterElement(FBtnNewGame);
  FGUIManager.RegisterElement(FBtnAuthors);
  FGUIManager.RegisterElement(FBtnExit);
end;

procedure TpdMainMenu.LoadAtlasTexture(const aFilename: String);
begin
  FAtlasTexture := dfCreateTexture();
  FAtlasTexture.Load2D(aFileName);
  FAtlasTexture.BlendingMode := tbmTransparency;
  FAtlasTexture.CombineMode := tcmModulate;
end;

procedure TpdMainMenu.LoadBackground(const aFilename: String);
begin
  FBackground := dfCreateHUDSprite;
  FBackground.Position := dfVec2f(0, 0);
  FBackground.Material.Texture.Load2D(aFileName);
  FBackground.UpdateTexCoords();
  FBackground.Material.Texture.CombineMode := tcmModulate;
  FBackground.Width := R.WindowWidth;
  FBackground.Height := R.WindowHeight;

  FScene.RegisterElement(FBackground);
end;

procedure TpdMainMenu.SetGameScreenLinks(aAuthors, aNewGame: TpdGameScreen);
begin
  FScrAuthors := aAuthors;
  FScrNewGame := aNewGame;
end;

procedure TpdMainMenu.SetStatus(const aStatus: TpdGameScreenStatus);
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

//    gssFadeOut:
//    begin
//      FBlankBack.Visible := True;
//      Ft := 0;
//    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdMainMenu.Unload;
begin
  inherited;

  R.UnregisterScene(FScene);
//  sceneMainMenu.UnRegisterElement(FBtnNewGame);
//  sceneMainMenu.UnRegisterElement(FBtnAuthors);
//  sceneMainMenu.UnRegisterElement(FBtnExit);
//  sceneMainMenu.UnRegisterElement(FBackground);
//
  FGUIManager.UnRegisterElement(FBtnNewGame);
  FGUIManager.UnRegisterElement(FBtnAuthors);
  FGUIManager.UnRegisterElement(FBtnExit);
end;

procedure TpdMainMenu.Update(deltaTime: Double);
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

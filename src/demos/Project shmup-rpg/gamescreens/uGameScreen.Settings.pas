unit uGameScreen.Settings;

interface

uses
  dfHRenderer,
  uButtonsInfo,
  uGameScreen;

const
  TIME_FADEIN  = 1.5;
  TIME_FADEOUT = 1.5;

  BTN_WIDTH = 249;
  BTN_HEIGHT = 45;

  //Save & exit button

  BTN_SE_X = 50;
  BTN_SE_Y = 300;
  BTN_SE_NORMAL_X = 0;
  BTN_SE_NORMAL_Y = 92;
  BTN_SE_OVER_X   = 0;
  BTN_SE_OVER_Y   = 0;
  BTN_SE_CLICK_X  = 0;
  BTN_SE_CLICK_Y  = 138;

  //Cancel button
  BTN_CA_X = BTN_SE_X + BTN_WIDTH * 2;
  BTN_CA_Y = BTN_SE_Y;
  BTN_CA_NORMAL_X = 0;
  BTN_CA_NORMAL_Y = 368;
  BTN_CA_OVER_X   = 0;
  BTN_CA_OVER_Y   = 322;
  BTN_CA_CLICK_X  = 0;
  BTN_CA_CLICK_Y  = 276;

type
  TpdSettings = class (TpdGameScreen)
  private
    FGUIManager: IglrGUIManager;
    FScene: Iglr2DScene;
    FScrMainMenu: TpdGameScreen;

    //Кнопки
    FBtnSaveAndExit, FBtnCancel: IglrGUIButton;
    //Атлас
    FAtlasTexture: IglrTexture;
    //Бэкграунд и фейковый квад для осветления сцены
    {FBackground,} FFakeBackground: IglrSprite;

    Ft: Single; //Время для анимации

    procedure LoadAtlasTexture(const aFilename: String);
    procedure LoadBackground(const aFilename: String);
    procedure InitButtons(aSaveAndExitInfo, aCancelInfo: TpdButtonInfo);
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

    procedure SetGameScreenLinks(aMainMenu: TpdGameScreen);
  end;

var
  settings: TpdSettings;

implementation

uses
  dfMath,
  uGlobal;

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with settings do
  begin
    if Sender = (FBtnSaveAndExit as IglrGUIElement) then
    begin

    end
    else if Sender = (FBtnCancel as IglrGUIElement) then
    begin
      OnNotify(FScrMainMenu, naSwitchTo);
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

{ TpdSettings }

constructor TpdSettings.Create;
var
  aSaveAndExitInfo, aCancelInfo: TpdButtonInfo;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();

  LoadAtlasTexture(FILE_SETTINGSMENU_TEXTURE_ATLAS);
{  LoadBackground(FILE_MAINMENU_BACKGROUND); }
  {$REGION 'info records init'}
  with aSaveAndExitInfo do
  begin
    texture := FAtlasTexture;
    width := BTN_WIDTH;
    height := BTN_HEIGHT;
    x := BTN_SE_X;
    y := BTN_SE_Y;
    texRegionInfo[ttNormal].x := BTN_SE_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_SE_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_SE_OVER_X;
    texRegionInfo[ttOver].y := BTN_SE_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_SE_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_SE_CLICK_Y;
  end;

  with aCancelInfo do
  begin
    texture := FAtlasTexture;
    width := BTN_WIDTH;
    height := BTN_HEIGHT;
    x := BTN_CA_X;
    y := BTN_CA_Y;
    texRegionInfo[ttNormal].x := BTN_CA_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_CA_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_CA_OVER_X;
    texRegionInfo[ttOver].y := BTN_CA_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_CA_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_CA_CLICK_Y;
  end;

  {$ENDREGION}
  InitButtons(aSaveAndExitInfo, aCancelInfo);

  FFakeBackground := Factory.NewHudSprite();
  FFakeBackground.Position := dfVec2f(0, 0);
  FFakeBackground.Z := 100;
  FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
  FFakeBackground.Material.Texture.BlendingMode := tbmTransparency;
  FFakeBackground.Width := R.WindowWidth;
  FFakeBackground.Height := R.WindowHeight;
  FScene.RegisterElement(FFakeBackground);
end;

destructor TpdSettings.Destroy;
begin
  inherited;
end;

procedure TpdSettings.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 0.7 - 0.7 * Ft / TIME_FADEIN);
    FBtnSaveAndExit.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1 - Ft / TIME_FADEOUT);
    FBtnCancel.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1 - Ft / TIME_FADEOUT);
  end;
end;

procedure TpdSettings.FadeInComplete;
begin
  Status := gssReady;
//  FFakeBackground.Visible := False;

  FGUIManager.RegisterElement(FBtnSaveAndExit);
  FGUIManager.RegisterElement(FBtnCancel);
end;

procedure TpdSettings.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 0.7 * Ft / TIME_FADEOUT);
    FBtnSaveAndExit.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, Ft / TIME_FADEOUT);
    FBtnCancel.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, Ft / TIME_FADEOUT);
  end;
end;

procedure TpdSettings.FadeOutComplete;
begin
  Status := gssNone;
end;

procedure TpdSettings.InitButtons(aSaveAndExitInfo, aCancelInfo: TpdButtonInfo);

  function InitButton(aInfo: TpdButtonInfo): IglrGUIButton;
  begin
    Result := Factory.NewGUIButton();
    with Result do
    begin
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
  FBtnSaveAndExit := InitButton(aSaveAndExitInfo);
  FBtnCancel := InitButton(aCancelInfo);

  FBtnSaveAndExit.OnMouseClick := OnMouseClick;
  FBtnCancel.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnSaveAndExit);
  FScene.RegisterElement(FBtnCancel);
end;

procedure TpdSettings.Load;
begin
  inherited;
  R.RegisterScene(FScene);
end;

procedure TpdSettings.LoadAtlasTexture(const aFilename: String);
begin
  FAtlasTexture := Factory.NewTexture();
  FAtlasTexture.Load2D(aFileName);
  FAtlasTexture.BlendingMode := tbmTransparency;
  FAtlasTexture.CombineMode := tcmModulate;
end;

procedure TpdSettings.LoadBackground(const aFilename: String);
begin
{
  FBackground := dfCreateHUDSprite;
  FBackground.Position := dfVec2f(0, 0);
  FBackground.Material.Texture.Load2D(aFileName);
  FBackground.UpdateTexCoords();
  FBackground.Material.Texture.CombineMode := tcmModulate;
  FBackground.Width := R.WindowWidth;
  FBackground.Height := R.WindowHeight;

  FScene.RegisterElement(FBackground);
  }
end;

procedure TpdSettings.SetGameScreenLinks(aMainMenu: TpdGameScreen);
begin
  FScrMainMenu := aMainMenu;
end;

procedure TpdSettings.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
  case aStatus of
    gssNone: Exit;

    gssReady: Exit;

    gssFadeIn:
    begin
      FFakeBackground.Visible := True;
      Ft := TIME_FADEIN;
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      //FFakeBackground.Visible := True;
      Ft := TIME_FADEOUT;
      FGUIManager.UnRegisterElement(FBtnSaveAndExit);
      FGUIManager.UnRegisterElement(FBtnCancel);
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdSettings.Unload;
begin
  inherited;

  R.UnregisterScene(FScene);
end;

procedure TpdSettings.Update(deltaTime: Double);
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

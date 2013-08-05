{ALL IN DEBUG
  DO NOT USE BEFORE REFACTOR}

unit uGameScreen.Authors;

interface

uses
  dfHRenderer,
  uButtonsInfo,
  uGameScreen;

const
  //NO FILE!
  FILE_AUTHORS_TEXTURE_ATLAS = 'shmup_res/menu_authors.tga';

  //Main menu button

  BTN_MM_X        = 50;
  BTN_MM_Y        = 300;
  BTN_MM_W        = 249;
  BTN_MM_H        = 45;

  BTN_MM_NORMAL_X = 0;
  BTN_MM_NORMAL_Y = 92;
  BTN_MM_OVER_X   = 0;
  BTN_MM_OVER_Y   = 0;
  BTN_MM_CLICK_X  = 0;
  BTN_MM_CLICK_Y  = 138;

  //Blog button
  BTN_BG_X        = 100;
  BTN_BG_Y        = 200;
  BTN_BG_W        = 249;
  BTN_BG_H        = 45;

  BTN_BG_NORMAL_X = 0;
  BTN_BG_NORMAL_Y = 368;
  BTN_BG_OVER_X   = 0;
  BTN_BG_OVER_Y   = 322;
  BTN_BG_CLICK_X  = 0;
  BTN_BG_CLICK_Y  = 276;

type
  TpdAuthors = class (TpdGameScreen)
  private
    FScene: Iglr2DScene;
    FGUIManager: IglrGUIManager;
    FScrMainMenu: TpdGameScreen;
    FBlogLink: String;

    //Кнопки
    FBtnToMenu, FBtnToBlog: IglrGUIButton;
    FAtlasTexture: IglrTexture;
    FBackground: IglrSprite;

    procedure LoadAtlasTexture(const aFilename: String);
    procedure InitButtons(aToMenuInfo, aToBlogInfo: TpdButtonInfo);
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

    procedure SetGameScreenLinks(aToMenu: TpdGameScreen; aToBlog: String);
  end;

var
  authors: TpdAuthors;

implementation

uses
  dfMath,
  uGlobal;

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if Sender = (authors.FBtnToMenu as IglrGUIElement) then
  begin
    authors.OnNotify(authors.FScrMainMenu, naSwitchTo);
  end

  else if Sender = (authors.FBtnToBlog as IglrGUIElement) then
  begin

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

{ TpdAuthors }

constructor TpdAuthors.Create;
var
  aToMenu, aToBlog: TpdButtonInfo;
begin
  inherited;
  FGuiManager := R.GUIManager;
  FScene := Factory.New2DScene();
  LoadAtlasTexture(FILE_AUTHORS_TEXTURE_ATLAS);
  {$REGION 'info record init'}
  with aToMenu do
  begin
    x := BTN_MM_X;
    y := BTN_MM_Y;
    width := BTN_MM_W;
    height := BTN_MM_H;
    texture := FAtlasTexture;
    texRegionInfo[ttNormal].x := BTN_MM_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_MM_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_MM_OVER_X;
    texRegionInfo[ttOver].y := BTN_MM_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_MM_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_MM_CLICK_Y;
  end;

  with aToBlog do
  begin
    x := BTN_BG_X;
    y := BTN_BG_Y;
    width := BTN_BG_W;
    height := BTN_BG_H;
    texture := FAtlasTexture;
    texRegionInfo[ttNormal].x := BTN_BG_NORMAL_X;
    texRegionInfo[ttNormal].y := BTN_BG_NORMAL_Y;

    texRegionInfo[ttOver].x := BTN_BG_OVER_X;
    texRegionInfo[ttOver].y := BTN_BG_OVER_Y;

    texRegionInfo[ttClicked].x := BTN_BG_CLICK_X;
    texRegionInfo[ttClicked].y := BTN_BG_CLICK_Y;
  end;
  {$ENDREGION}
  InitButtons(aToMenu, aToBlog);
end;

destructor TpdAuthors.Destroy;
begin
  inherited;
end;

procedure TpdAuthors.FadeIn(deltaTime: Double);
begin
  inherited;

end;

procedure TpdAuthors.FadeInComplete;
begin
  Status := gssReady;
  FGUIManager.RegisterElement(FBtnToMenu);
  FGUIManager.RegisterElement(FBtnToBlog);
end;

procedure TpdAuthors.FadeOut(deltaTime: Double);
begin
  inherited;

end;

procedure TpdAuthors.FadeOutComplete;
begin
  Status := gssNone;
end;

procedure TpdAuthors.InitButtons(aToMenuInfo, aToBlogInfo: TpdButtonInfo);

  function InitButton(aInfo: TpdButtonInfo): IglrGUIButton;
  begin
    Result := Factory.NewGUIButton();
    with Result do
    begin
      Position := dfVec2f(aInfo.x, aInfo.y);
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
  FBtnToBlog := InitButton(aToBlogInfo);

  FBtnToMenu.OnMouseClick := OnMouseClick;
  FBtnToBlog.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnToMenu);
  FScene.RegisterElement(FBtnToBlog);
end;

procedure TpdAuthors.Load;
begin
  inherited;
  R.RegisterScene(FScene);
end;

procedure TpdAuthors.LoadAtlasTexture(const aFilename: String);
begin
  FAtlasTexture := Factory.NewTexture();
  FAtlasTexture.Load2D(aFilename);
  FAtlasTexture.BlendingMode := tbmTransparency;
  FAtlasTexture.CombineMode := tcmModulate;
end;

procedure TpdAuthors.SetGameScreenLinks(aToMenu: TpdGameScreen;
  aToBlog: String);
begin
  FScrMainMenu := aToMenu;
  FBlogLink := aToBlog;
end;

procedure TpdAuthors.SetStatus(const aStatus: TpdGameScreenStatus);
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
      FGUIManager.UnregisterElement(FBtnToBlog);
//      FBlankBack.Visible := True;
//      Ft := 0;
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdAuthors.Unload;
begin
  inherited;
  R.UnregisterScene(FScene);
end;

procedure TpdAuthors.Update(deltaTime: Double);
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

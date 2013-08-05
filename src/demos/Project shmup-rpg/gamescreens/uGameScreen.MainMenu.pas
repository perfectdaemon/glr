{$A8,B-,C+,D+,E-,F-,G+,H+,I+,J-,K-,L+,M-,N-,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$MINSTACKSIZE $00004000}
{$MAXSTACKSIZE $00100000}
{$IMAGEBASE $00400000}
{$APPTYPE GUI}
{$WARN SYMBOL_DEPRECATED ON}
{$WARN SYMBOL_LIBRARY ON}
{$WARN SYMBOL_PLATFORM ON}
{$WARN SYMBOL_EXPERIMENTAL ON}
{$WARN UNIT_LIBRARY ON}
{$WARN UNIT_PLATFORM ON}
{$WARN UNIT_DEPRECATED ON}
{$WARN UNIT_EXPERIMENTAL ON}
{$WARN HRESULT_COMPAT ON}
{$WARN HIDING_MEMBER ON}
{$WARN HIDDEN_VIRTUAL ON}
{$WARN GARBAGE ON}
{$WARN BOUNDS_ERROR ON}
{$WARN ZERO_NIL_COMPAT ON}
{$WARN STRING_CONST_TRUNCED ON}
{$WARN FOR_LOOP_VAR_VARPAR ON}
{$WARN TYPED_CONST_VARPAR ON}
{$WARN ASG_TO_TYPED_CONST ON}
{$WARN CASE_LABEL_RANGE ON}
{$WARN FOR_VARIABLE ON}
{$WARN CONSTRUCTING_ABSTRACT ON}
{$WARN COMPARISON_FALSE ON}
{$WARN COMPARISON_TRUE ON}
{$WARN COMPARING_SIGNED_UNSIGNED ON}
{$WARN COMBINING_SIGNED_UNSIGNED ON}
{$WARN UNSUPPORTED_CONSTRUCT ON}
{$WARN FILE_OPEN ON}
{$WARN FILE_OPEN_UNITSRC ON}
{$WARN BAD_GLOBAL_SYMBOL ON}
{$WARN DUPLICATE_CTOR_DTOR ON}
{$WARN INVALID_DIRECTIVE ON}
{$WARN PACKAGE_NO_LINK ON}
{$WARN PACKAGED_THREADVAR ON}
{$WARN IMPLICIT_IMPORT ON}
{$WARN HPPEMIT_IGNORED ON}
{$WARN NO_RETVAL ON}
{$WARN USE_BEFORE_DEF ON}
{$WARN FOR_LOOP_VAR_UNDEF ON}
{$WARN UNIT_NAME_MISMATCH ON}
{$WARN NO_CFG_FILE_FOUND ON}
{$WARN IMPLICIT_VARIANTS ON}
{$WARN UNICODE_TO_LOCALE ON}
{$WARN LOCALE_TO_UNICODE ON}
{$WARN IMAGEBASE_MULTIPLE ON}
{$WARN SUSPICIOUS_TYPECAST ON}
{$WARN PRIVATE_PROPACCESSOR ON}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN OPTION_TRUNCATED ON}
{$WARN WIDECHAR_REDUCED ON}
{$WARN DUPLICATES_IGNORED ON}
{$WARN UNIT_INIT_SEQ ON}
{$WARN LOCAL_PINVOKE ON}
{$WARN MESSAGE_DIRECTIVE ON}
{$WARN TYPEINFO_IMPLICITLY_ADDED ON}
{$WARN RLINK_WARNING ON}
{$WARN IMPLICIT_STRING_CAST ON}
{$WARN IMPLICIT_STRING_CAST_LOSS ON}
{$WARN EXPLICIT_STRING_CAST OFF}
{$WARN EXPLICIT_STRING_CAST_LOSS OFF}
{$WARN CVT_WCHAR_TO_ACHAR ON}
{$WARN CVT_NARROWING_STRING_LOST ON}
{$WARN CVT_ACHAR_TO_WCHAR OFF}
{$WARN CVT_WIDENING_STRING_LOST OFF}
{$WARN XML_WHITESPACE_NOT_ALLOWED ON}
{$WARN XML_UNKNOWN_ENTITY ON}
{$WARN XML_INVALID_NAME_START ON}
{$WARN XML_INVALID_NAME ON}
{$WARN XML_EXPECTED_CHARACTER ON}
{$WARN XML_CREF_NO_RESOLVE ON}
{$WARN XML_NO_PARM ON}
{$WARN XML_NO_MATCHING_PARM ON}
unit uGameScreen.MainMenu;

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
    FGUIManager: IglrGUIManager;
    FScene: Iglr2DScene;
    FScrAuthors, FScrArenaGame: TpdGameScreen;

    //Кнопки
    FBtnNewGame, FBtnAuthors, FBtnExit: IglrGUIButton;
    FAtlasTexture: IglrTexture;
    FBackground, FFakeBackground: IglrSprite;

    Ft: Single; //Время для анимации

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

    procedure SetGameScreenLinks(aAuthors, aArenaGame: TpdGameScreen);
  end;

var
  mainMenu: TpdMainMenu;

implementation

uses
  dfMath,
  uGlobal;

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if Sender = (mainMenu.FBtnNewGame as IglrGUIElement) then
  begin
    mainMenu.OnNotify(mainMenu.FScrArenaGame, naSwitchTo);
  end

  else if Sender = (mainMenu.FbtnAuthors as IglrGUIElement) then
  begin

  end
  
  else if Sender = (mainMenu.FBtnExit as IglrGUIElement) then
  begin
    mainMenu.OnNotify(nil, naQuitGame);
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

{ TpdMainMenu }

constructor TpdMainMenu.Create;
var
  aNewGameInfo, aAuthorsInfo, aExitInfo: TpdButtonInfo;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();

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

  FFakeBackground := Factory.NewHudSprite();
  FFakeBackground.Position := dfVec2f(0, 0);
  FFakeBackground.Z := 100;
  FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
  FFakeBackground.Material.Texture.BlendingMode := tbmTransparency;
  FFakeBackground.Width := R.WindowWidth;
  FFakeBackground.Height := R.WindowHeight;
  FScene.RegisterElement(FFakeBackground);
end;

destructor TpdMainMenu.Destroy;
begin
  inherited;
end;

procedure TpdMainMenu.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, Ft / TIME_FADEIN);
  end;
end;

procedure TpdMainMenu.FadeInComplete;
begin
  Status := gssReady;
  FFakeBackground.Visible := False;

  FGUIManager.RegisterElement(FBtnNewGame);
  FGUIManager.RegisterElement(FBtnAuthors);
  FGUIManager.RegisterElement(FBtnExit);
end;

procedure TpdMainMenu.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1 - Ft / TIME_FADEOUT);
  end;
end;

procedure TpdMainMenu.FadeOutComplete;
begin
  Status := gssNone;
end;

procedure TpdMainMenu.InitButtons(aNewGameInfo, aAuthorsInfo, aExitInfo: TpdButtonInfo);

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
end;

procedure TpdMainMenu.LoadAtlasTexture(const aFilename: String);
begin
  FAtlasTexture := Factory.NewTexture();
  FAtlasTexture.Load2D(aFileName);
  FAtlasTexture.BlendingMode := tbmTransparency;
  FAtlasTexture.CombineMode := tcmModulate;
end;

procedure TpdMainMenu.LoadBackground(const aFilename: String);
begin
  FBackground := Factory.NewHudSprite();
  FBackground.Position := dfVec2f(0, 0);
  FBackground.Material.Texture.Load2D(aFileName);
  FBackground.UpdateTexCoords();
  FBackground.Material.Texture.CombineMode := tcmModulate;
  FBackground.Width := R.WindowWidth;
  FBackground.Height := R.WindowHeight;

  FScene.RegisterElement(FBackground);
end;

procedure TpdMainMenu.SetGameScreenLinks(aAuthors, aArenaGame: TpdGameScreen);
begin
  FScrAuthors := aAuthors;
  FScrArenaGame := aArenaGame;
end;

procedure TpdMainMenu.SetStatus(const aStatus: TpdGameScreenStatus);
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
      FFakeBackground.Visible := True;
      Ft := TIME_FADEOUT;
      FGUIManager.UnRegisterElement(FBtnNewGame);
      FGUIManager.UnRegisterElement(FBtnAuthors);
      FGUIManager.UnRegisterElement(FBtnExit);
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdMainMenu.Unload;
begin
  inherited;

  R.UnregisterScene(FScene);
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

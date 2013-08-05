unit uGameScreen.Advices;

interface

uses
  uGameScreen, uAdvices,
  dfHRenderer;

const
  TIME_FADEIN = 0.7;
  TIME_FADEOUT = 0.7;

type
  TpdAdvicesMenu = class (TpdGameScreen)
  private
    FScene: Iglr2DScene;
    FScrGame: TpdGameScreen;
    FGUIManager: IglrGUIManager;

    FFakeBackground: IglrSprite;
    FAdvc: TpdAdviceController;
    FBtnToPauseMenu: IglrGUIButton;

    Ft: Single; //Время для анимации fadein / fadeout

    FEscapeDown: Boolean;

    procedure InitButtons();
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

    procedure SetGameScreenLinks(aToGame: TpdGameScreen);
  end;

var
  advices: TpdAdvicesMenu;

implementation

uses
  dfMath, dfTweener,
  uGlobal;

const
  OK_NORMAL_TEXTURE  = 'ok_normal.png';
  OK_OVER_TEXTURE  = 'ok_over.png';
  OK_CLICK_TEXTURE = 'ok_click.png';

  OK_OFFSET_Y = 90;
  ADVC_OFFSET_X = 0;
  ADVC_OFFSET_Y = 0;


procedure OnAdviceBtnClick(aElement: IglrGUIElement; X, Y: Integer;
  MouseButton: TglrMouseButton; Shift: TglrMouseShiftState);
begin
  with advices.FAdvc do
  if MouseButton = mbLeft then
  begin
    if aElement = (FBtnPrev as IglrGUIElement) then
      Previous()
    else if aElement = (FBtnNext as IglrGUIElement) then
      Next();
  end
end;

procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  with advices do
    if Sender = (FBtnToPauseMenu as IglrGUIElement) then
    begin
      OnNotify(FScrGame, naSwitchTo);
    end
end;

{ TpdAdvicesMenu }

constructor TpdAdvicesMenu.Create;
begin
  inherited;
  FGUIManager := R.GUIManager;
  FScene := Factory.New2DScene();

  InitBackground();

  InitButtons();

  FAdvc := TpdAdviceController.Initialize(FScene);
  FAdvc.FBtnNext.OnMouseClick := OnAdviceBtnClick;
  FAdvc.FBtnPrev.OnMouseClick := OnAdviceBtnClick;

  //--oops
  FAdvc.AddAdvice('Привет тебе, игрок! Я знаю, что это звучит стыдно, но'
       + #13#10 + 'вместо нормального обучения есть только набор'
       + #13#10 + 'советов по выживанию.'
       + #13#10 + 'Эти советы можно повторно вызвать из меню паузы.'
       + #13#10
       + #13#10 + 'Нажми OK, чтобы начать играть.');
  FAdvc.AddAdvice('Левая кнопка мыши — движение и взаимодействие c'
       + #13#10 + 'объектами. Зажмите, чтобы двигаться.'
       + #13#10 + 'Правая кнопка — использование объектов инвентаря'
       + #13#10 + 'Можно выбросить предмет, перетянув его из инвентаря'
       + #13#10 + 'Z или I — показать/скрыть инвентарь'
       + #13#10 + 'C — показать/скрыть панель крафта', False);
  FAdvc.AddAdvice('Советую пойти на север. Там можно найти интересное:'
       + #13#10 + 'рюкзак, нож, флягу и леску. Они сильно помогут.'
       , False);
  FAdvc.AddAdvice('Если один из параметров, кроме запаса сил,'
       + #13#10 + 'дойдет до нуля, то персонаж умрет. '
       + #13#10 + 'Нулевой запас сил критичен только в воде — можно'
       + #13#10 + 'утонуть.'
       , False);
  FAdvc.AddAdvice('Фляга, будучи брошенной в воду, наполнится водой.'
       + #13#10 + 'Если перетянуть удочку в воду — можно поймать рыбу'
       + #13#10 + 'Также, флягу и удочку можно применить из инвентаря,'
       + #13#10 + 'находясь в воде (правая кнопка мыши).'
       + #13#10 + 'Важно: необходимо зайти в воду чуть глубже.'
       , False);
  FAdvc.AddAdvice('Костер — очень важный предмет. Рядом с ним лучше'
       + #13#10 + 'отдыхается, можно что-нибудь пожарить или'
       + #13#10 + 'прокипятить. Можно подкинуть в костер веток или'
       + #13#10 + 'травы, чтобы он дольше горел.'
       + #13#10 + 'Просто перетяните предметы из инвентаря на костер.'
       , False);
  FAdvc.AddAdvice('Фляга может содержать воду (обычную или кипяченую)'
       + #13#10 + 'или чай (заготовку или завареный)'
       + #13#10 + 'Это достигается путем использования панели крафта и'
       + #13#10 + 'перетягивания фляги с содержимым на костер.'
       , False);
end;

destructor TpdAdvicesMenu.Destroy;
begin
  FScene.UnregisterElements();
  FAdvc.Free();
  inherited;
end;

procedure TpdAdvicesMenu.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.MaterialOptions.PDiffuse.w := 0.5 - 0.5 * Ft / TIME_FADEIN;
  end;
end;

procedure TpdAdvicesMenu.FadeInComplete;
begin
  Status := gssReady;
  FGUIManager.RegisterElement(FBtnToPauseMenu);
end;

procedure TpdAdvicesMenu.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.MaterialOptions.PDiffuse.w := 0.5 * Ft / TIME_FADEOUT;
  end;
end;

procedure TpdAdvicesMenu.FadeOutComplete;
begin
  Status := gssNone;
  FFakeBackground.Visible := False;
end;

procedure TpdAdvicesMenu.InitBackground;
begin
  FFakeBackground := Factory.NewHudSprite();
  with FFakeBackground do
  begin
    Material.MaterialOptions.Diffuse := dfVec4f(0, 0, 0, 0.0);
    Material.Texture.BlendingMode := tbmTransparency;
    Z := Z_INGAMEMENU - 2;
    PivotPoint := ppTopLeft;
    Width := R.WindowWidth;
    Height := R.WindowHeight;
    Position := dfVec2f(0, 0);
  end;

  FScene.RegisterElement(FFakeBackground);
end;

procedure TpdAdvicesMenu.InitButtons();
begin
  FBtnToPauseMenu:= Factory.NewGUIButton();

  with FBtnToPauseMenu do
  begin
    PivotPoint := ppCenter;
    Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2 + OK_OFFSET_Y);
    Z := Z_INGAMEMENU + 1;
    TextureNormal := atlasInGameMenu.LoadTexture(OK_NORMAL_TEXTURE);
    TextureOver := atlasInGameMenu.LoadTexture(OK_OVER_TEXTURE);
    TextureClick := atlasInGameMenu.LoadTexture(OK_CLICK_TEXTURE);

    UpdateTexCoords();
    SetSizeToTextureSize();
  end;

  FBtnToPauseMenu.OnMouseClick := OnMouseClick;

  FScene.RegisterElement(FBtnToPauseMenu);
end;

procedure TpdAdvicesMenu.Load;
begin
  inherited;
  R.RegisterScene(FScene);
end;

procedure TpdAdvicesMenu.SetGameScreenLinks(aToGame: TpdGameScreen);
begin
  FScrGame := aToGame;
end;

procedure TpdAdvicesMenu.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
  case aStatus of
    gssNone: Exit;

    gssReady: Exit;

    gssFadeIn:
    begin
      FFakeBackground.Visible := True;
      Ft := TIME_FADEIN;
      Tweener.AddTweenPSingle(@FBtnToPauseMenu.PPosition.y, tsExpoEaseIn,
        R.WindowHeight + 90, R.WindowHeight div 2 + OK_OFFSET_Y, 2, 0.1);
      FAdvc.Visible := True;
    end;

    gssFadeInComplete: FadeInComplete();

    gssFadeOut:
    begin
      Tweener.AddTweenPSingle(@FBtnToPauseMenu.PPosition.y, tsExpoEaseIn,
        R.WindowHeight div 2 + OK_OFFSET_Y, R.WindowHeight + 90, 2, 0.1);
      FGUIManager.UnregisterElement(FBtnToPauseMenu);
      Ft := TIME_FADEOUT;
      FAdvc.Visible := False;
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdAdvicesMenu.Unload;
begin
  inherited;
  R.UnregisterScene(FScene);
end;

procedure TpdAdvicesMenu.Update(deltaTime: Double);
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
      if R.Input.IsKeyPressed(27, @FEscapeDown) then
        OnMouseClick(FBtnToPauseMenu as IglrGUIElement, 0, 0, mbLeft, []);
      FAdvc.Update(deltaTime);
    end;
  end;
end;

end.

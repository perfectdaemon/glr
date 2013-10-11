unit uGameScreen.Game;

interface

uses
  Contnrs,
  glr, glrUtils, glrMath,
  uGameScreen, uField,
  uGlobal;

const
  TIME_FADEIN  = 1.5;
  TIME_FADEOUT = 0.2;

  TIME_COUNT_GAMEOVER = 2.0;
type
  TpdGameMode = (gmSingle, gmTwoPlayersVs);

  TpdGame = class (TpdGameScreen)
  private
    FMainScene, FHUDScene: Iglr2DScene;
    FScrGameOver: TpdGameScreen;

    FPause: Boolean;

    {$IFDEF DEBUG}
    FFPSCounter: TglrFPSCounter;
    FDebug: TglrDebugInfo;
    {$ENDIF}

    Ft: Single; //Время для расчета анимации fadein/fadeout
    FFakeBackground: IglrSprite;

    FField: TpdField;

    procedure LoadHUD();
    procedure FreeHUD();

    procedure LoadField();
    procedure FreeField();

    procedure DoUpdate(const dt: Double);
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

    procedure SetGameScreenLinks(aGameOver: TpdGameScreen);

    procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
  end;

var
  game: TpdGame;

implementation

uses
  Windows, SysUtils,
  dfTweener, ogl;

{ TpdGame }

constructor TpdGame.Create;
begin
  inherited;

  FMainScene := Factory.New2DScene();
  FHUDScene := Factory.New2DScene();

  uGlobal.mainScene := FMainScene;
  uGlobal.hudScene := FHUDScene;
end;

destructor TpdGame.Destroy;
begin
  Unload();

  FMainScene := nil;
  FHUDscene := nil;
  uGlobal.mainScene := nil;
  uGlobal.hudScene := nil;
  inherited;
end;

procedure TpdGame.DoUpdate(const dt: Double);
begin
  {$IFDEF DEBUG}
  if R.Input.IsKeyPressed(68) then
  begin
    FDebug.FText.Visible := not FDebug.FText.Visible;
    FFPSCounter.TextObject.Visible := not FFPSCounter.TextObject.Visible;
  end;
  FFpsCounter.Update(dt);
  {$ENDIF}

  if R.Input.IsKeyPressed(VK_ESCAPE) then
    FPause := not FPause;

  if FPause then
    Exit();

  FField.Update(dt);
end;

procedure TpdGame.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := Ft / TIME_FADEIN;
  end;
end;

procedure TpdGame.FadeInComplete;
begin
  FFakeBackground.Visible := False;
  Status := gssReady;
end;

procedure TpdGame.FadeOut(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.PDiffuse.w := 1 - Ft / TIME_FADEOUT;
  end;
end;

procedure TpdGame.FadeOutComplete;
begin
  Status := gssNone;
  Unload();
end;

procedure TpdGame.FreeField;
begin
  if Assigned(FField) then
    FreeAndNil(FField);
end;

procedure TpdGame.FreeHUD;
begin
  {$IFDEF DEBUG}
  if Assigned(FDebug) then
    FreeAndNil(FDebug);
  if Assigned(FFPSCounter) then
    FreeAndNil(FFPSCounter);
  {$ENDIF}
  //*
end;


procedure TpdGame.Load;
begin
  inherited;
  if FLoaded then
    Exit();

  sound.PlayMusic(musicIngame);

  //gl.ClearColor(119/255, 208/255, 214/255, 1);
  gl.ClearColor(0, 30 / 255, 60 / 250, 1.0);
  FMainScene.RootNode.RemoveAllChilds();
  FMainScene.RootNode.Position := dfVec3f(0, 0, 0);
  FHudScene.RootNode.RemoveAllChilds();

  LoadHUD();
  LoadField();

  FFakeBackground := Factory.NewHudSprite();
  with FFakeBackground do
  begin
    Position := dfVec3f(0, 0, 100);
    Material.Diffuse := dfVec4f(1, 1, 1, 1);
    Material.Texture.BlendingMode := tbmTransparency;
    Width := R.WindowWidth;
    Height := R.WindowHeight;
  end;
  FHUDScene.RootNode.AddChild(FFakeBackground);

  R.RegisterScene(FMainScene);
  R.RegisterScene(FHUDScene);

  FLoaded := True;
end;

procedure TpdGame.LoadField;
begin
  if Assigned(FField) then
    FreeAndNil(FField);
  FField := TpdField.Create();
end;

procedure TpdGame.LoadHUD;
begin
  {$IFDEF DEBUG}
  FFPSCounter := TglrFPSCounter.Create(FHUDScene, 'FPS:', 1, nil);
  FFPSCounter.TextObject.Material.Diffuse := dfVec4f(0, 0, 0, 1);
  FFPSCounter.TextObject.Visible := False;

  FDebug := TglrDebugInfo.Create(FHUDScene.RootNode);
  FDebug.FText.Material.Diffuse := dfVec4f(0, 0, 0, 1);
  FDebug.FText.Visible := False;
  FDebug.FText.PPosition.y := 20;
  {$ENDIF}

  //*
end;

procedure TpdGame.SetGameScreenLinks(aGameOver: TpdGameScreen);
begin
  FScrGameOver := aGameOver;
end;

procedure TpdGame.SetStatus(const aStatus: TpdGameScreenStatus);
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
    end;

    gssFadeOutComplete: FadeOutComplete();
  end;
end;

procedure TpdGame.Unload;
begin
  inherited;
  if not FLoaded then
    Exit();

  FreeHUD();
  FreeField();

  R.UnregisterScene(FMainScene);
  R.UnregisterScene(FHUDScene);

  FLoaded := False;
end;

procedure TpdGame.Update(deltaTime: Double);
begin
  inherited;
  case FStatus of
    gssFadeIn  : FadeIn(deltaTime);
    gssFadeOut : FadeOut(deltaTime);
    gssReady   : DoUpdate(deltaTime);
  end;
end;

procedure TpdGame.OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();
end;

procedure TpdGame.OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();
end;

procedure TpdGame.OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();
end;

end.

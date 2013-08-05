unit uGameScreen.Game;

interface

uses
  Contnrs,
  dfHRenderer, dfHUtility, dfMath,
  uGameScreen,
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
    FScrPauseMenu, FScrGameOver: TpdGameScreen;

    {$IFDEF DEBUG}
    FFPSCounter: TglrFPSCounter;
    FDebug: TglrDebugInfo;
    FDPressed: Boolean;
    {$ENDIF}

    FEscapeDown, FEnterDown: Boolean;
    Ft: Single; //¬рем€ дл€ расчета анимации fadein/fadeout
    FFakeBackground: IglrSprite;
    FCounter: Single;
    FCountToGameOver: Boolean;

    //¬ерхн€€ и нижн€€ стенки
    FTopWall, FBottomWall, FLeftWall, FRightWall: IglrSprite;
    FGameMode: TpdGameMode;
    procedure LoadHUD();
    procedure FreeHUD();

    procedure LoadPlayer();
    procedure FreePlayer();

    procedure LoadEnemy();
    procedure FreeEnemy();

    procedure LoadPhysics();
    procedure FreePhysics();

    procedure LoadAccums();
    procedure FreeAccums();

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

    property GameMode: TpdGameMode read FGameMode write FGameMode;

    procedure SetGameScreenLinks(aToPauseMenu, aGameOver: TpdGameScreen);

    procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
  end;

var
  game: TpdGame;

implementation

uses
  uCharacterController, uCharacter, uGUI, uPopup, uParticles,
  Windows, SysUtils,
  uPhysics2DTypes, uBox2DImport,
  dfTweener, dfHGL;

procedure OnPhysicsUpdate(const fixedDT: Double);
begin
  player.Update(fixedDT);
  player2.Update(fixedDT);
end;

procedure OnPhysicsAfterUpdate(const fixedDT: Double);
begin
  if player.ShouldDestroyJoints then
  begin
    player.DestroyAllJoints();
    player.ShouldDestroyJoints := False;
  end;

  if player2.ShouldDestroyJoints then
  begin
    player2.DestroyAllJoints();
    player2.ShouldDestroyJoints := False;
  end;

  if R.Input.IsKeyPressed(VK_RETURN)
    and not player.IsDead
    and not player2.IsDead
    and (game.GameMode = gmSingle)
    and (player.Force >= 50)
    and not player2.HasBadThing then
    begin
      player.Force := player.Force - 50;
      gui.UpdateSliders();
      player2.MakeABadThing(7 + (4 - difficulty));
    end;

  if not game.FCountToGameOver and (player.IsDead or player2.IsDead) then
    with game do
    begin
      FCountToGameOver := True;
      FCounter := TIME_COUNT_GAMEOVER;
    end;
end;

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

  FMainScene.UnregisterElements();
  FHudScene.UnregisterElements();
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


  b2world.Update(dt);
  gui.Update(dt);
  UpdatePopups(dt);
  particles.Update(dt);
  contactListener.Update(dt);


  if FCountToGameOver then
    if FCounter > 0 then
      FCounter := FCounter - dt
    else
    begin
      FCountToGameOver := False;
      OnNotify(FScrGameOver, naShowModal);
    end;

  if R.Input.IsKeyPressed(VK_ESCAPE) then
    OnNotify(FScrPauseMenu, naShowModal);
end;

procedure TpdGame.FadeIn(deltaTime: Double);
begin
  if Ft <= 0 then
    inherited
  else
  begin
    Ft := Ft - deltaTime;
    FFakeBackground.Material.MaterialOptions.PDiffuse.w := Ft / TIME_FADEIN;
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
    FFakeBackground.Material.MaterialOptions.PDiffuse.w := 1 - Ft / TIME_FADEOUT;
  end;
end;

procedure TpdGame.FadeOutComplete;
begin
  Status := gssNone;
  Unload();
end;

procedure TpdGame.FreeEnemy;
begin
  if Assigned(player2) then
    FreeAndNil(player2);
  if Assigned(playerController2) then
    FreeAndNil(playerController2);
end;

procedure TpdGame.FreeHUD;
begin
  {$IFDEF DEBUG}
  if Assigned(FDebug) then
    FreeAndNil(FDebug);
  if Assigned(FFPSCounter) then
    FreeAndNil(FFPSCounter);
  {$ENDIF}
  if Assigned(gui) then
    FreeAndNil(gui);
end;

procedure TpdGame.FreePhysics;
begin
  if Assigned(contactListener) then
    FreeAndNil(contactListener);
  if Assigned(b2world) then
    FreeAndNil(b2world);
end;

procedure TpdGame.FreePlayer;
begin
  if Assigned(playerController) then
    FreeAndNil(playerController);
  if Assigned(player) then
    FreeAndNil(player);
end;

procedure TpdGame.FreeAccums;
begin
  if Assigned(popups) then
    FreeAndNil(popups);
  if Assigned(particles) then
    FreeAndNil(particles);
end;

procedure TpdGame.Load;
begin
  inherited;
  if FLoaded then
    Exit();

  sound.PlayMusic(musicIngame);

  FCountToGameOver := False;

  gl.ClearColor(119/255, 208/255, 214/255, 1);
  FMainScene.UnregisterElements();
  FMainScene.Origin := dfVec2f(0, 0);
  FHudScene.UnregisterElements();

  charInternalZ := 0;
  particlesInternalZ := 0;
  popupsInternalZ := 0;

  LoadHUD();
  LoadPhysics();
  LoadPlayer();
  LoadEnemy();
  LoadAccums();
  gui.UpdateSliders();

  FFakeBackground := Factory.NewHudSprite();
  with FFakeBackground do
  begin
    Position := dfVec2f(0, 0);
    Z := 100;
    Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
    Material.Texture.BlendingMode := tbmTransparency;
    Width := R.WindowWidth;
    Height := R.WindowHeight;
  end;
  FHUDScene.RegisterElement(FFakeBackground);

  R.RegisterScene(FMainScene);
  R.RegisterScene(FHUDScene);

  FLoaded := True;
end;

procedure TpdGame.LoadEnemy;
var
  charParams: TglrCharacterParams;
begin
  charParams.initialPosition := dfVec2f(3 * R.WindowWidth div 4, R.WindowHeight div 2);
  charParams.charGroup := 4;
  charParams.normalColor := colorGray4;

  player2 := TpdCharacter.Init(b2world, mainScene, charParams);
  if FGameMode = gmTwoPlayersVs then
  begin
    playerController2 := TpdPlayerCharacterController.Init(R.Input, player2,
      TglrControllerKeys.Init($41, $44, $57, $53));
    player2.Damage := 4;
  end
  else
  begin
    playerController2 := TpdAICharacterContoller.Init(player2, difficulty);
    player2.Damage := 4 + uGlobal.difficulty;
  end;
end;

procedure TpdGame.LoadHUD;
begin
  {$IFDEF DEBUG}
  FFPSCounter := TglrFPSCounter.Create(FHUDScene, 'FPS:', 1, nil);
  FFPSCounter.TextObject.Material.MaterialOptions.Diffuse := dfVec4f(0, 0, 0, 1);
  FFPSCounter.TextObject.Visible := False;

  FDebug := TglrDebugInfo.Create(FHUDScene);
  FDebug.FText.Material.MaterialOptions.Diffuse := dfVec4f(0, 0, 0, 1);
  FDebug.FText.Visible := False;
  FDebug.FText.PPosition.y := 20;
  {$ENDIF}

  gui := TglrInGameGUI.Create(FHudScene);
end;

procedure TpdGame.LoadPhysics;
var
  g: TVector2;
begin
  //Box2D
  g.SetValue(0.0, 2.0);
  b2world := Tglrb2World.Create(g, True, 1 / 90, 8);
  b2world.OnBeforeSimulation := @OnPhysicsUpdate;
  b2world.OnAfterSimulation := @OnPhysicsAfterUpdate;
  contactListener := TglrContactListener.Create();
  b2world.SetContactListener(contactListener);

  //left, right, bottom, top
  dfb2InitBoxStatic(b2world, dfVec2f(0, R.WindowHeight div 2), dfVec2f(6, R.WindowHeight), 0, 1, 1, 0, $0FFF, $FFFF, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth, R.WindowHeight div 2), dfVec2f(6, R.WindowHeight), 0, 1, 1, 0, $0FFF, $FFFF, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth div 2, R.WindowHeight), dfVec2f(R.WindowWidth, 10), 0, 1, 1, 0, $0FFF, $FFFF, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth div 2, 0), dfVec2f(R.WindowWidth, 10), 0, 1, 1, 0, $0FFF, $FFFF, 0);

  //init graphical top/bottom

  FTopWall := Factory.NewSprite();
  FBottomWall := Factory.NewSprite();
  FLeftWall := Factory.NewSprite();
  FRightWall := Factory.NewSprite();

  with FTopWall do
  begin
    PivotPoint := ppTopLeft;
    Position := dfVec2f(0, 0);
    Material.MaterialOptions.Diffuse := colorGray2;
    Width := R.WindowWidth;
    Height := 5;
    Z := Z_DROPOBJECTS + 1;
  end;

  with FBottomWall do
  begin
    PivotPoint := ppBottomLeft;
    Position := dfVec2f(0, R.WindowHeight);
    Material.MaterialOptions.Diffuse := colorGray2;
    Width := R.WindowWidth;
    Height := 5;
    Z := Z_DROPOBJECTS + 1;
  end;

  with FLeftWall do
  begin
    PivotPoint := ppTopLeft;
    Position := dfVec2f(0, 0);
    Material.MaterialOptions.Diffuse := colorGray2;
    Width := 5;
    Height := R.WindowHeight;
    Z := Z_DROPOBJECTS + 1;
  end;

  with FRightWall do
  begin
    PivotPoint := ppTopRight;
    Position := dfVec2f(R.WindowWidth, 0);
    Material.MaterialOptions.Diffuse := colorGray2;
    Width := 5;
    Height := R.WindowHeight;
    Z := Z_DROPOBJECTS + 1;
  end;

  FMainScene.RegisterElement(FTopWall);
  FMainScene.RegisterElement(FBottomWall);
  FMainScene.RegisterElement(FLeftWall);
  FMainScene.RegisterElement(FRightWall);
end;

procedure TpdGame.LoadPlayer;
var
  charParams: TglrCharacterParams;
begin
  charParams.initialPosition := dfVec2f(R.WindowWidth div 4, R.WindowHeight div 2);
  charParams.charGroup := 2;
  charParams.normalColor := colorGray2;

  player := TpdCharacter.Init(b2world, mainScene, charParams);
  playerController := TpdPlayerCharacterController.Init(R.Input, player,
    TglrControllerKeys.Init(VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN));
  if GameMode = gmSingle then
    player.Damage := 4 + (4 - uGlobal.difficulty)
  else
    player.Damage := 4;
end;

procedure TpdGame.LoadAccums;
begin
  popups := TpdPopups.Initialize(FHUDScene);
  particles := TpdParticles.Initialize(FHUDScene);
end;

procedure TpdGame.SetGameScreenLinks(aToPauseMenu, aGameOver: TpdGameScreen);
begin
  FScrPauseMenu := aToPauseMenu;
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
  FreePlayer();
  FreeEnemy();
  FreePhysics();
  FreeAccums();

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

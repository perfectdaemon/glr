unit uGameScreen.Game;

interface

uses
  Contnrs,
  glr, glrUtils, glrMath,
  uGameScreen,
  uGlobal;

const
  TIME_FADEIN  = 1.5;
  TIME_FADEOUT = 0.2;

  TIME_NORMAL_MODE = {$IFDEF DEBUG}0.1{$ELSE} 3{$ENDIF} * 60; //Две минуты в обычном режиме

  TIME_SECONDS_IN_MINUTE = 1;
  TIME_MINUTES_IN_HOUR = 60;

  TIME_SPAWN_PERIOD = 2.0;

  POWER_FOR_GREAT_SHOT = 160.0;

type
  TpdGame = class (TpdGameScreen)
  private
    FMainScene, FHUDScene: Iglr2DScene;
    FScrPauseMenu, FScrGameOver: TpdGameScreen;

    //hud elements
    {$IFDEF DEBUG}
    //debug
    FFPSCounter: TglrFPSCounter;
    FDebug: TglrDebugInfo;
    {$ENDIF}

    FPause, FShouldWhistle: Boolean;
    FPauseText: IglrText;

    //Отображение времени
    FTime: Double;
    FTimeRounded: Integer;
    FTimeHours, FTimeMinutes: Integer;
    FTimeTmp1, FTimeTmp2: String;
    FTimerIcon: IglrSprite;
    FTimeText: IglrText;
    FIsTimeBecomeRed: Boolean;

    Ft: Single; //Время для расчета анимации fadein/fadeout
    FTimeToSpawn: Single;

    FFakeBackground: IglrSprite;

    FMaxPower: Integer; //Максимальная сила удара

    //Верхняя и нижняя стенки
    FTopWall, FBottomWall: IglrSprite;

    procedure LoadHUD();
    procedure FreeHUD();

    procedure LoadPlayer();
    procedure FreePlayer();

    procedure LoadPhysics();
    procedure FreePhysics();

    procedure LoadPopups();
    procedure FreePopups();

    procedure LoadDrops();
    procedure FreeDrops();

    procedure DoUpdate(const dt: Double);
    procedure UpdateTimeText();

    procedure SpawnSphere();
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

    procedure SetGameScreenLinks(aToPauseMenu, aGameOver: TpdGameScreen);

    procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;

    function GetStatsData(): TpdStatsData;
  end;

var
  game: TpdGame;

implementation

uses
  uCharacterController, uCharacter, uGUI, uPopup, uObjects,
  Windows, SysUtils,
  uPhysics2DTypes, uBox2DImport,
  dfTweener, ogl;


procedure OnPhysicsUpdate(const fixedDT: Double);
begin
  player.Update(fixedDT);
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
//  FreeHUD();
//  FreePlayer();
//  FreeDrops();
//  FreePhysics();
//  FreePopups();

//  FMainScene.UnregisterElements();
//  FHudScene.UnregisterElements();
  FMainScene := nil;
  FHUDscene := nil;
  uGlobal.mainScene := nil;
  uGlobal.hudScene := nil;
  inherited;
end;

procedure TpdGame.DoUpdate(const dt: Double);
var
  i, scoreAdd: Integer;
begin

  {$IFDEF DEBUG}
  if R.Input.IsKeyPressed(68) then
  begin
    FDebug.FText.Visible := not FDebug.FText.Visible;
    FFPSCounter.TextObject.Visible := not FFPSCounter.TextObject.Visible;
  end;

  FFpsCounter.Update(dt);
  {$ENDIF}
  //--update all
  if R.Input.IsKeyPressed(VK_SPACE) then
  begin
    FPause := not FPause;
    if FShouldWhistle then
    begin
      sound.PlaySample(sWhistle);
      FShouldWhistle := False;
    end;
    gui.FCenterText.Visible := FPause;
    FPauseText.Visible := FPause;
  end;

  if not FPause then
  begin
    if FTimeToSpawn > 0 then
      FTimeToSpawn := FTimeToSpawn - dt
    else
    begin
      SpawnSphere();
      FTimeToSpawn := TIME_SPAWN_PERIOD;
    end;

    for i := 0 to High(drops.Items) do
      if drops.Items[i].Used then
        with drops.Items[i] as TpdDropObject do
        begin
          Update(dt);
          if aTimeRemain < 0 then
            drops.FreeItem(drops.Items[i])
          else if IsOut() then
          begin
            scoreAdd := Round(aBody.GetLinearVelocity.Length() * 10);
            if scoreAdd > FMaxPower then
              FMaxPower := scoreAdd;
            if scoreAdd > POWER_FOR_GREAT_SHOT then
            begin
              sound.PlaySample(sGoal);
              gui.ShowText('Отличный удар!');
            end;
            gui.AddScore(scoreAdd, aSprite.Position2D);
            drops.FreeItem(drops.Items[i])
          end;
        end;
    b2world.Update(dt);
    gui.Update(dt);
    UpdatePopups(dt);

    FTime := FTime - dt;
    UpdateTimeText();
    if FTime < 0 then
    begin
      sound.PlaySample(sWhistle);
      OnNotify(FScrGameOver, naShowModal);
    end;
  end;
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
  FPause := True;
  FPauseText.Visible := True;
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

procedure TpdGame.FreeDrops;
begin
  if Assigned(drops) then
    FreeAndNil(drops);
end;

procedure TpdGame.FreeHUD;
begin
  {$IFDEF DEBUG}
  if Assigned(FDebug) then
    FreeAndNil(FDebug);
  if Assigned(FFPSCounter) then
    FreeAndNil(FFPSCounter);
  {$ENDIF}
  gui.Free();
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

procedure TpdGame.FreePopups;
begin
  if Assigned(popups) then
    FreeAndNil(popups);
end;

function TpdGame.GetStatsData: TpdStatsData;
begin
  with Result do
  begin
    scores := gui.Score;
    maxPower := FMaxPower;
    foulsCount := playerFoulsCount;
  end;
end;

procedure TpdGame.Load;
begin
  inherited;
  if FLoaded then
    Exit();

  gl.ClearColor(230/255, 255/255, 255/255, 1);

//  FMainScene.UnregisterElements();
  FMainScene.RootNode.Position := dfVec3f(0, 0, 0);
//  FHudScene.UnregisterElements();

  LoadHUD();
  LoadPhysics();
  LoadPlayer();
  LoadPopups();
  LoadDrops();
  FTime := TIME_NORMAL_MODE;
  UpdateTimeText();
  FMaxPower := 0;
  playerFoulsCount := 0;
  FTimeToSpawn := 0;
  FShouldWhistle := True;
  FIsTimeBecomeRed := False;


  FFakeBackground := Factory.NewSprite();
  FFakeBackground.Position := dfVec3f(0, 0, 100);
  FFakeBackground.Material.Diffuse := dfVec4f(1, 1, 1, 1);
  FFakeBackground.Material.Texture.BlendingMode := tbmTransparency;
  FFakeBackground.Width := R.WindowWidth;
  FFakeBackground.Height := R.WindowHeight;
  FHUDScene.RootNode.AddChild(FFakeBackground);

  R.RegisterScene(FMainScene);
  R.RegisterScene(FHUDScene);

  FLoaded := True;
end;

procedure TpdGame.LoadDrops;
begin
  if Assigned(drops) then
    drops.Free();

  drops := TpdDrops.Create(12);
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

  gui := TglrInGameGUI.Create(FHudScene);

  FTimerIcon := Factory.NewHudSprite();
  FTimerIcon.PivotPoint := ppTopLeft;
  FTimerIcon.Position := dfVec3f(10, 10, Z_HUD);
  FTimerIcon.Material.Texture := atlasMain.LoadTexture(TIMER_TEXTURE);
  FTimerIcon.UpdateTexCoords();
  FTimerIcon.SetSizeToTextureSize();
  FTimerIcon.Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1.0);

  FTimeText := Factory.NewText();
  FTimeText.Font := fontCooper;
  FTimeText.Position := FTimerIcon.Position + dfVec3f(40, 5, 0);
//  FTimeText.Text := '02:00';
  FTimeText.Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1);

  FPauseText := Factory.NewText();
  with FPauseText do
  begin
    Font := fontCooper;
    Position := dfVec3f(R.WindowWidth div 2, 10, Z_HUD);
    PivotPoint := ppCenter;
    Text := 'П А У З А';
    Material.Diffuse := colorRed;
  end;

  FHUDScene.RootNode.AddChild(FTimerIcon);
  FHUDScene.RootNode.AddChild(FTimeText);
  FHUDScene.RootNode.AddChild(FPauseText);
end;

procedure TpdGame.LoadPhysics;
var
  g: TVector2;
begin
  //Box2D
  g.SetValue(0.0, 2.0);
  b2world := Tglrb2World.Create(g, True, 1 / 90, 6);
  b2world.OnBeforeSimulation := @OnPhysicsUpdate;
  contactListener := TglrContactListener.Create();
  b2world.SetContactListener(contactListener);

  //left, right, bottom, top
  dfb2InitBoxStatic(b2world, dfVec2f(0, R.WindowHeight div 2), dfVec2f(6, R.WindowHeight), 0, 1, 1, 0, $0FFF, $FFFF, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth, R.WindowHeight div 2), dfVec2f(6, R.WindowHeight), 0, 1, 1, 0, $0FFF, $FFFF, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth div 2, R.WindowHeight), dfVec2f(R.WindowWidth, 10), 0, 1, 1, 0, $FFFF, $FFFF, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth div 2, 0), dfVec2f(R.WindowWidth, 10), 0, 1, 1, 0, $FFFF, $FFFF, 0);

  //init graphical top/bottom

  FTopWall := Factory.NewSprite();
  FBottomWall := Factory.NewSprite();

  with FTopWall do
  begin
    PivotPoint := ppTopLeft;
    Position := dfVec3f(0, 0, Z_DROPOBJECTS + 1);
    Material.Diffuse := colorGray2;
    Width := R.WindowWidth;
    Height := 5;
  end;

  with FBottomWall do
  begin
    PivotPoint := ppBottomLeft;
    Position := dfVec3f(0, R.WindowHeight, Z_DROPOBJECTS + 1);
    Material.Diffuse := colorGray2;
    Width := R.WindowWidth;
    Height := 5;
  end;

  FMainScene.RootNode.AddChild(FTopWall);
  FMainScene.RootNode.AddChild(FBottomWall);
end;

var
  charParams: TglrCharacterParams =
    (initialPosition: (X: 0; Y: 0;);
     charForm: cfCircle;
     charGroup: 2;);

procedure TpdGame.LoadPlayer;
begin
  charParams.initialPosition := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);

  player := TpdCharacter.Init(b2world, mainScene, charParams);
  playerController := TpdPlayerCharacterController.Init(R.Input, player,
    TglrControllerKeys.Init(VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN));
end;

procedure TpdGame.LoadPopups;
begin
  popups := TpdPopups.Initialize(FHUDScene);
end;

procedure TpdGame.SetGameScreenLinks(aToPauseMenu, aGameOver: TpdGameScreen);
begin
  FScrPauseMenu := aToPauseMenu;
  FScrGameOver := aGameOver;
end;

procedure TpdGame.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
    inherited;
  case aStatus of
    gssNone: Exit;

    gssReady: Exit;

    gssFadeIn:
    begin
      FFakeBackground.Visible := True;
      //sound.PlayMusic(musicIngame);
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

procedure TpdGame.SpawnSphere;
var
  sp: TpdDropObject;
  impulse: TVector2;
begin
  sp := drops.GetItem();
  sp.SetPosition(dfVec2f(100 + Random(R.WindowWidth - 200), 30));
  impulse.SetValue(0.15 - 0.3 * Random(), 0.5 * Random());
  sp.aBody.ApplyLinearImpulse(impulse, sp.aBody.GetWorldCenter);
end;

procedure TpdGame.Unload;
begin
  inherited;
  if not FLoaded then
    Exit();

  FreeHUD();
  FreePlayer();
  FreeDrops();
  FreePhysics();
  FreePopups();

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

procedure TpdGame.UpdateTimeText();
begin
  //Переводим время в строковый формат вида "12:34"

  FTimeRounded := Trunc(FTime);
  FTimeMinutes := FTimeRounded div TIME_SECONDS_IN_MINUTE;
  FTimeHours := FTimeMinutes div TIME_MINUTES_IN_HOUR;
  FTimeMinutes := FTimeMinutes mod TIME_MINUTES_IN_HOUR;
  if FTimeMinutes < 10 then
    FTimeTmp1 := '0' + IntToStr(FTimeMinutes)
  else
    FTimeTmp1 := IntToStr(FTimeMinutes);
  if FTimeHours < 10 then
    FTimeTmp2 := '0' + IntToStr(FTimeHours)
  else
    FTimeTmp2 := IntToStr(FTimeHours);
  FTimeText.Text := FTimeTmp2 + ':' + FTimeTmp1;

  if (FTime < 15) and not FIsTimeBecomeRed then
  begin
    Tweener.AddTweenPSingle(@FTimeText.Material.PDiffuse.x,
      tsExpoEaseIn, 0.0, 1.0, 3.0, 0.0);
    Tweener.AddTweenPSingle(@FTimerIcon.Material.PDiffuse.x,
      tsExpoEaseIn, 0.0, 1.0, 3.0, 0.0);
    FIsTimeBecomeRed := True;
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

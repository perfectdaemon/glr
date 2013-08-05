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

  TIME_NORMAL_MODE = {$IFDEF DEBUG}1{$ELSE} 3{$ENDIF} * 60; //Две минуты в обычном режиме

  TIME_SECONDS_IN_MINUTE = 1;
  TIME_MINUTES_IN_HOUR = 60;

  TIME_SPAWN_ENEMY_PERIOD = 2.0;
  TIME_SPAWN_BLOCK_PERIOD = 3.0;

type
  TpdGame = class (TpdGameScreen)
  private
    FMainScene, FHUDScene: Iglr2DScene;
    FScrGameOver: TpdGameScreen;

    //hud elements
    {$IFDEF DEBUG}
    //debug
    FFPSCounter: TglrFPSCounter;
    FDebug: TglrDebugInfo;
    {$ENDIF}

    {$IFDEF DEBUG}FDPressed,{$ENDIF} FSpacePressed: Boolean;

    FPause: Boolean;
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
    FTimeToSpawnBlock, FTimeToSpawnEnemy: Single;

    FFakeBackground: IglrSprite;

    procedure LoadHUD();
    procedure FreeHUD();

    procedure LoadPlayer();
    procedure FreePlayer();

    procedure LoadPopups();
    procedure FreePopups();

    procedure LoadBlocksAndEnemies();
    procedure FreeBlocksAndEnemies();

    procedure DoUpdate(const dt: Double);
    procedure UpdateTimeText();

    procedure SpawnBlock();
    procedure SpawnEnemy();
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
  uGUI, uPopup, uBlocks, uPlayer, uEnemies, uBullets,

  Windows, SysUtils,
  dfTweener, dfHGL;


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
  if R.Input.IsKeyPressed(68, @FDPressed) then
  begin
    FDebug.FText.Visible := not FDebug.FText.Visible;
    FFPSCounter.TextObject.Visible := not FFPSCounter.TextObject.Visible;
  end;

  FFpsCounter.Update(dt);
  {$ENDIF}
  //--update all
  if R.Input.IsKeyPressed(VK_SPACE, @FSpacePressed) then
  begin
    FPause := not FPause;
    gui.FCenterText.Visible := FPause;
    FPauseText.Visible := FPause;
  end;

  if not FPause then
  begin
    if FTimeToSpawnEnemy > 0 then
      FTimeToSpawnEnemy := FTimeToSpawnEnemy - dt
    else
    begin
      SpawnEnemy();
      FTimeToSpawnEnemy := TIME_SPAWN_ENEMY_PERIOD;
    end;

    if FTimeToSpawnBlock > 0 then
      FTimeToSpawnBlock := FTimeToSpawnBlock - dt
    else
    begin
      SpawnBlock();
      FTimeToSpawnBlock := TIME_SPAWN_BLOCK_PERIOD;
    end;
//    if FTimeToSpawn > 0 then
//      FTimeToSpawn := FTimeToSpawn - dt
//    else
//    begin
//      SpawnBlock();
//      FTimeToSpawn := TIME_SPAWN_PERIOD;
//    end;
//
//    for i := 0 to High(blocks.Items) do
//      if blocks.Items[i].Used then
//        with blocks.Items[i] as TpdDropBlock do
//        begin
//          Update(dt);
//        end;

    gui.Update(dt);
    player.Update(dt);
    enemies.Update(dt);
    bullets.Update(dt);
    blocks.Update(dt);
    UpdatePopups(dt);

    FTime := FTime - dt;
    UpdateTimeText();
    if FTime < 0 then
    begin
      //OnNotify(FScrGameOver, naShowModal);
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
    FFakeBackground.Material.MaterialOptions.PDiffuse.w := Ft / TIME_FADEIN;
  end;
end;

procedure TpdGame.FadeInComplete;
begin
  FFakeBackground.Visible := False;
  Status := gssReady;
  FPause := False;
  FPauseText.Visible := True;
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

procedure TpdGame.FreeBlocksAndEnemies;
begin
  if Assigned(blocks) then
    FreeAndNil(blocks);
  if Assigned(enemies) then
    FreeAndNil(enemies);
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

procedure TpdGame.FreePlayer;
begin
  if Assigned(player) then
    FreeAndNil(player);
  if Assigned(bullets) then
    FreeAndNil(bullets);
end;

procedure TpdGame.FreePopups;
begin
  if Assigned(popups) then
    FreeAndNil(popups);
end;

procedure TpdGame.Load;
begin
  inherited;
  if FLoaded then
    Exit();

//  gl.ClearColor(230/255, 255/255, 255/255, 1);

  FMainScene.UnregisterElements();
  FMainScene.Origin := dfVec2f(0, 0);
  FHudScene.UnregisterElements();

  LoadHUD();
  LoadPlayer();
  LoadPopups();
  LoadBlocksAndEnemies();
  FTime := TIME_NORMAL_MODE;
  UpdateTimeText();
  FTimeToSpawnBlock := 0;
  FTimeToSpawnEnemy := 0;

  FFakeBackground := Factory.NewHudSprite();
  FFakeBackground.Position := dfVec2f(0, 0);
  FFakeBackground.Z := 100;
  FFakeBackground.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
  FFakeBackground.Material.Texture.BlendingMode := tbmTransparency;
  FFakeBackground.Width := R.WindowWidth;
  FFakeBackground.Height := R.WindowHeight;
  FHUDScene.RegisterElement(FFakeBackground);

  R.RegisterScene(FMainScene);
  R.RegisterScene(FHUDScene);

  FLoaded := True;
end;

procedure TpdGame.LoadBlocksAndEnemies;
begin
  blocks := TpdBlocks.Create(16);
  enemies := TpdEnemies.Create(16);
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

  FTimerIcon := Factory.NewHudSprite();
  FTimerIcon.Z := Z_HUD;
  FTimerIcon.PivotPoint := ppTopLeft;
  FTimerIcon.Position := dfVec2f(10, 10);
  FTimerIcon.Material.Texture := atlasMain.LoadTexture(TIMER_TEXTURE);
  FTimerIcon.UpdateTexCoords();
  FTimerIcon.SetSizeToTextureSize();
  FTimerIcon.Material.MaterialOptions.Diffuse := colorMain;

  FTimeText := Factory.NewText();
  FTimeText.Font := fontCooper;
  FTimeText.Z := Z_HUD;
  FTimeText.Position := FTimerIcon.Position + dfVec2f(40, 5);
//  FTimeText.Text := '02:00';
  FTimeText.Material.MaterialOptions.Diffuse := colorMain;

  FPauseText := Factory.NewText();
  with FPauseText do
  begin
    Font := fontCooper;
    Z := Z_HUD;
    Position := dfVec2f(R.WindowWidth div 2, 10);
    PivotPoint := ppCenter;
    Text := 'П А У З А';
    Material.MaterialOptions.Diffuse := colorRed;
  end;

  FHUDScene.RegisterElement(FTimerIcon);
  FHUDScene.RegisterElement(FTimeText);
  FHUDScene.RegisterElement(FPauseText);
end;

procedure TpdGame.LoadPlayer;
begin
  player := TpdPlayer.Initialize(FMainScene);
  bullets := TpdBullets.Create(16);
end;

procedure TpdGame.LoadPopups;
begin
  popups := TpdPopups.Initialize(FHUDScene);
end;

procedure TpdGame.SetGameScreenLinks(aGameOver: TpdGameScreen);
begin
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

procedure TpdGame.SpawnBlock;
var
  sp: TpdDropBlock;
begin
  sp := blocks.GetItem();
end;

procedure TpdGame.SpawnEnemy;
begin
  with enemies.GetItem() do
  begin

  end;
end;

procedure TpdGame.Unload;
begin
  inherited;
  if not FLoaded then
    Exit();

  FreeHUD();
  FreePlayer();
  FreeBlocksAndEnemies();
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
    Tweener.AddTweenPSingle(@FTimeText.Material.MaterialOptions.PDiffuse.x,
      tsExpoEaseIn, 0.0, 1.0, 3.0, 0.0);
    Tweener.AddTweenPSingle(@FTimerIcon.Material.MaterialOptions.PDiffuse.x,
      tsExpoEaseIn, 0.0, 1.0, 3.0, 0.0);
    FIsTimeBecomeRed := True;
  end;
end;

procedure TpdGame.OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();

  if not FPause then
  begin
    player.UpdateRotation();
  end;
end;

procedure TpdGame.OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();

  if not FPause then
  begin
    player.Shoot();
  end;
end;

procedure TpdGame.OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if status <> gssReady then
    Exit();
end;

end.

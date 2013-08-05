unit uGameScreen.ArenaGame;

interface

uses
  dfHRenderer, dfHUtility,
  uGameScreen,
  uPlayer, uDrop, uEnemies, uPopup, uWeapons, uGlobal, uStaticObjects;

const
  FILE_BACKGROUND = RES_FOLDER + 'map.tga';
  FILE_CURSOR_SPRITE = RES_FOLDER + 'cursor.tga';

type
  TpdArenaGame = class (TpdGameScreen)
  private
    FMainScene, FHUDScene: Iglr2DScene;
    FScrPauseMenu: TpdGameScreen;

    FBackground: IglrSprite;

    //hud elements
    FHUDFont: IglrFont;
    FScoreText, FWeaponText, FHealthText, FGameOverText: IglrText;
    FFPSCounter: TglrFPSCounter;
    FCursor: IglrSprite;

    FPause, FSpacePressed, FGameOver: Boolean;

    procedure LoadBackground(const aFilename: String);
    procedure LoadHUD();
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

    procedure SetGameScreenLinks(aToPauseMenu: TpdGameScreen);

    procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
  end;

var
  arenaGame: TpdArenaGame;

implementation

uses
  uBox2DImport, UPhysics2D, UPhysics2DTypes,
  Windows, SysUtils,
  dfMath;

{ TpdArenaGame }

constructor TpdArenaGame.Create;
begin
  inherited;

  Phys := Tglrb2World.Create(TVector2.From(0, 0), True, 1/60, 8);

  FMainScene := Factory.New2DScene();
  FHUDScene := Factory.New2DScene();

  FFPSCounter := TglrFPSCounter.Create(FHUDScene, 'FPS:', 1, nil);

  LoadBackground(FILE_BACKGROUND);
  LoadEnemies();
  LoadHUD();
  LoadWeapons();
  LoadDropItems();
  LoadPlayer();
  LoadPopups();
  LoadStaticObjects();
end;

destructor TpdArenaGame.Destroy;
begin
  FFPSCounter.Free;
  FreeWeapons();
  FreeDropItems();
  FreePlayer();
  FreeBullets();
  FreeEnemies();
  FreePopups();
  FreeStaticObjects();

  FMainScene := nil;
  FHUDscene := nil;

  Phys.Free;
  inherited;
end;

procedure TpdArenaGame.DoUpdate(const dt: Double);
begin
  if FGameOver then
    begin
      if R.Input.IsKeyPressed(VK_SPACE, @FSpacePressed) then
      begin
        Unload();
        Load();
      end;
      Exit();
    end;

    if R.Input.IsKeyDown(VK_ESCAPE) then
      OnNotify(FScrPauseMenu, naShowModal);

    FFpsCounter.Update(dt);

    if R.Input.IsKeyPressed(VK_SPACE, @FSpacePressed) then
      FPause := not FPause;

    if not FPause then
    begin
      Phys.Update(dt);
      UpdatePlayer(dt);
      UpdateBullets(dt);
      UpdateEnemies(dt);
      UpdateWeapons(dt);
      UpdateDropItems(dt);
      UpdatePopups(dt);
      UpdateStaticObjects(dt);
    end;

    FScoreText.Text := IntToStr(player.score) + #10 +
      'Дробовик: ' + IntToStr(dcShotgun) + #10 +
      'Автомат: ' + IntToStr(dcMG) + #10 +
      'Виски: ' + IntToStr(dcWhiskey);
    FHealthText.Text := 'Здоровье ' + IntToStr(player.health) + '/' + IntToStr(player.healthMax) + #10 +
      'Точность — ' + Format('%.1f', [player.GetAccuracyPercent()]) + '%';
    with player.currentWeapon^ do
      FWeaponText.Text := name + ' ' + IntToStr(ammoLeft) + ' / ' + IntToStr(ammoMax);

    if player.health <= 0 then
    begin
      FGameOver := True;
      FGameOverText.Visible := True;
    end;
end;

procedure TpdArenaGame.FadeIn(deltaTime: Double);
begin
  inherited;

end;

procedure TpdArenaGame.FadeInComplete;
begin
  Status := gssReady;
end;

procedure TpdArenaGame.FadeOut(deltaTime: Double);
begin
  inherited;

end;

procedure TpdArenaGame.FadeOutComplete;
begin
  Status := gssNone;
  Unload();
end;

procedure TpdArenaGame.Load;
begin
  inherited;

  FMainScene.UnregisterElements();
  FMainScene.RegisterElement(FBackground);

  FGameOver := False;
  FPause := False;
  FGameOverText.Visible := False;

  InitDropItems(FMainScene);
  InitEnemies(FMainScene);
  InitBullets(FMainScene);
  InitWeapons();
  InitPlayer(FMainScene);
  InitPopups(FMainScene);
  InitStaticObjects(FMainScene);

  R.RegisterScene(FMainScene);
  R.RegisterScene(FHUDScene);
end;

procedure TpdArenaGame.LoadBackground(const aFilename: String);
begin
  FBackground := Factory.NewHudSprite();
  FBackground.Z := -99;
  FBackground.PivotPoint := ppCenter;
  FBackground.Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);
  with FBackground.Material.Texture do
  begin
   Load2D(aFilename);
   BlendingMode := tbmTransparency;
  end;
  FBackground.SetSizeToTextureSize();
end;

procedure TpdArenaGame.LoadHUD;
begin
  FHUDFont := glrNewFilledFont('Times New Roman', 14);

  FScoreText := Factory.NewText();
  FScoreText.Font := FHUDFont;
  FScoreText.Position := dfVec2f(R.WindowWidth - 120, 70);
  FScoreText.Z := Z_HUD;
  FHUDScene.RegisterElement(FScoreText);

  FWeaponText := Factory.NewText();
  FWeaponText.Font := FHUDFont;
  FWeaponText.Position := dfVec2f(R.WindowWidth - 200, 30);
  FWeaponText.Z := Z_HUD;
  FHUDScene.RegisterElement(FWeaponText);

  FHealthText := Factory.NewText();
  FHealthText.Font := FHUDFont;
  FHealthText.Position := dfVec2f(R.WindowWidth div 2, 10);
  FHealthText.Z := Z_HUD;
  FHUDScene.RegisterElement(FHealthText);

  FGameOverText := Factory.NewText();
  FGameOverText.Font := FHUDFont;
  FGameOverText.Position := dfVec2f(50, R.WindowHeight div 2);
  FGameOverText.ScaleMult(dfVec2f(3, 3));
  FGameOverText.Text := 'GAME OVER, MOTHERFUCKER' + #10 + 'PRESS «SPACE» TO RESTART';
  FGameOverText.Visible := False;
  FGameOverText.Z := Z_HUD + 5;
  FHUDScene.RegisterElement(FGameOverText);

  FCursor := Factory.NewHudSprite();
  FCursor.PivotPoint := ppCenter;
  with FCursor.Material.Texture do
  begin
    Load2D(FILE_CURSOR_SPRITE);
    BlendingMode := tbmTransparency;
    CombineMode := tcmModulate;
  end;
  FCursor.SetSizeToTextureSize;
  FCursor.Z := Z_HUD + 5;
  FHUDScene.RegisterElement(FCursor);
end;

procedure TpdArenaGame.SetGameScreenLinks(aToPauseMenu: TpdGameScreen);
begin
  FScrPauseMenu := aToPauseMenu;
end;

procedure TpdArenaGame.SetStatus(const aStatus: TpdGameScreenStatus);
begin
  inherited;
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

procedure TpdArenaGame.Unload;
begin
  inherited;
  R.UnregisterScene(FMainScene);
  R.UnregisterScene(FHUDScene);
end;

procedure TpdArenaGame.Update(deltaTime: Double);
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
      DoUpdate(deltaTime);
    end;
  end;
end;

procedure TpdArenaGame.OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  if FGameOver then
    Exit;

  if not FPause then
  begin
    FCursor.Position := dfVec2f(X, Y);
  end;
end;

procedure TpdArenaGame.OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if FGameOver then
    Exit;

  if not FPause then
    if MouseButton = mbLeft then
    begin
      player.currentWeapon.StartShoot();
    end;
end;

procedure TpdArenaGame.OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  if FGameOver then
    Exit;

  if not FPause then
    if MouseButton = mbLeft then
    begin
      player.currentWeapon.EndShoot();
    end;
end;

end.

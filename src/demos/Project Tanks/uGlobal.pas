unit uGlobal;

interface

uses
  dfHRenderer, dfMath, uEarth, uTank, uSound;


const
  GAMEVERSION = '0.03';
  RES_FOLDER = 'tanks-res\';

  TEXTURE_TILE = 'earthtile.tga';
  TEXTURE_CIRCLE = 'circle.tga';

  MAP_FILENAME = 'map.bmp';

  SOUND_SHOT      = 'shot.ogg';
  SOUND_EXPLOSION = 'explosion.ogg';

  TEXT_YOURTURN   = 'В А Ш   Х О Д';
  TEXT_ENEMYTURN  = 'Х О Д   П Р О Т И В Н И К А';
  TEXT_WAIT       = 'Ж Д Е М...';

  TURN_WAIT   = $00;
  TURN_PLAYER = $01;
  TURN_ENEMY  = $02;

  Z_TILES = 0;
  Z_TANK = 1;

  Z_HUD = 25;

  GRAVITY = 1.5;

var
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene: Iglr2DScene;
  sound: TpdSoundSystem;

  //game objects
  earth: TpdEarth;
  player: TpdPlayerTank;
  enemy: TpdEnemyTank;
  turn: Byte;

  //hud texts
  textAngle, textPower, textHint, textStep, textWinLose: IglrText;

  //textures
  texTile, texCircle: IglrTexture;

  soundShot, soundExp: LongWord;

  fontMain: IglrFont;

  //colors
  colorEarth: TdfVec4f = (x: 185 / 255; y: 143 / 255; z: 92 / 255);
  colorBullet: TdfVec4f = (x: 0.9; y: 0.9; z: 0.9; w: 1.0);
  colorPlayer: TdfVec4f = (x: 1.0; y: 0.0; z: 0.0; w: 1.0);
  colorEnemy: TdfVec4f = (x: 0.0; y: 1.0; z: 0.0; w: 1.0);
  colorExpl: TdfVec4f = (x: 215 / 255; y: 149 / 255; z: 21 / 255; w: 0.0);


procedure InitializeGlobal();
procedure FinalizeGlobal();

procedure RealPosToTilePos(const aRealPos: TdfVec2f; var aX, aY: Integer);
function TilePosToRealPos(const aX, aY: Integer): TdfVec2f;

procedure SwitchTurn(aNewTurn: Byte);

implementation

uses
  dfHUtility;

procedure InitializeGlobal();
begin
  //Scenes
  mainScene := Factory.New2DScene();
  hudScene := Factory.New2DScene();
  R.RegisterScene(mainScene);
  R.RegisterScene(hudScene);

  texTile := Factory.NewTexture();
  texTile.Load2D(RES_FOLDER + TEXTURE_TILE);
  texTile.BlendingMode := tbmOpaque;
  texTile.CombineMode := tcmModulate;

  texCircle := Factory.NewTexture();
  texCircle.Load2D(RES_FOLDER + TEXTURE_CIRCLE);
  texCircle.BlendingMode := tbmTransparency;
  texCircle.CombineMode := tcmModulate;

  fontMain := Factory.NewFont();
  fontMain.AddSymbols(FONT_USUAL_CHARS);
  fontMain.FontSize := 14;
  fontMain.GenerateFromFont('Verdana');

  textAngle := Factory.NewText();
  textAngle.Font := fontMain;
  textAngle.Position := dfVec2f(10, 5);
  textAngle.Z := Z_HUD;

  textPower := Factory.NewText();
  textPower.Font := fontMain;
  textPower.Position := dfVec2f(10, 25);
  textPower.Z := Z_HUD;

  textHint := Factory.NewText();
  textHint.Font := fontMain;
  textHint.Position := dfVec2f(R.WindowWidth - 10, 5);
  textHint.PivotPoint := ppTopRight;
  textHint.Text := 'Left, Right — угол наклона'#13#10'Up, Down — сила выстрела'#13#10'Enter — выстрел';
  textHint.Z := Z_HUD;

  textStep := Factory.NewText();
  textStep.Font := fontMain;
  textStep.Position := dfVec2f(R.WindowWidth div 2, 5);
  textStep.PivotPoint := ppTopCenter;
  textStep.Material.MaterialOptions.Diffuse := colorEnemy;
  textStep.Z := Z_HUD;

  textWinLose := Factory.NewText();
  textWinLose.Font := fontMain;
  textWinLose.Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);
  textWinLose.PivotPoint := ppCenter;
  textWinLose.Material.MaterialOptions.Diffuse := colorBullet;
  textWinLose.Z := Z_HUD;

  hudScene.RegisterElement(textAngle);
  hudScene.RegisterElement(textPower);
  hudScene.RegisterElement(textHint);
  hudScene.RegisterElement(textStep);
  hudScene.RegisterElement(textWinLose);

  sound := TpdSoundSystem.Create(R.WindowHandle);
  soundShot := sound.LoadSample(RES_FOLDER + SOUND_SHOT);
  soundExp := sound.LoadSample(RES_FOLDER + SOUND_EXPLOSION);
  sound.SoundVolume := 0.3;
end;

procedure FinalizeGlobal();
begin
  mainScene.UnregisterElements();
  hudScene.UnregisterElements();

  R.UnregisterScene(mainScene);
  R.UnregisterScene(hudScene);
  mainScene := nil;
  hudScene := nil;
  texTile := nil;
  texCircle := nil;
  fontMain := nil;
  textAngle := nil;
  textPower := nil;
  textHint := nil;
  textStep := nil;

  sound.Free();
end;

procedure RealPosToTilePos(const aRealPos: TdfVec2f; var aX, aY: Integer);
begin
  aX := Trunc(aRealPos.x) div TILE_SIZE;
  aY := Trunc(aRealPos.y) div TILE_SIZE;
end;

function TilePosToRealPos(const aX, aY: Integer): TdfVec2f;
begin
  Result := dfVec2f(aX * TILE_SIZE, aY * TILE_SIZE);
end;

procedure SwitchTurn(aNewTurn: Byte);
begin
  turn := aNewTurn;
  case turn of
    TURN_WAIT: textStep.Text := TEXT_WAIT;
    TURN_PLAYER: textStep.Text := TEXT_YOURTURN;
    TURN_ENEMY: textStep.Text := TEXT_ENEMYTURN;
  end;
end;

end.

unit uGlobal;

interface

uses
  dfHRenderer, dfMath, dfHUtility, uGUI, uSound, uPlayer,
  uPopup, uBlocks, uEnemies, uBullets;

const
  GAMEVERSION = '0.01';

  RES_FOLDER = 'cube-res\';

  Z_BACKGROUND    = -100;
  Z_STATICOBJECTS = -50;
  Z_DROPOBJECTS   = -40;
  Z_ENEMY         = -30;
  Z_PLAYER        =  0;
  Z_MAINMENU      =  25;
  Z_HUD           =  50;
  Z_INGAMEMENU    =  90;


  MUSIC_INGAME = RES_FOLDER + '';
  MUSIC_MENU = RES_FOLDER + '';

  SOUND_CLICK   = RES_FOLDER + 'click.ogg';
  SOUND_SHOT    = RES_FOLDER + 'shot.ogg';
  SOUND_EXPL    = RES_FOLDER + 'explosion.ogg';
  SOUND_BLOCK   = RES_FOLDER + 'fall.ogg';


  FILE_MAIN_TEXTURE_ATLAS = RES_FOLDER + 'atlas.atlas';

  //Текстуры
//  CURSOR_TEXTURE = 'cursor.png';

  TEXTURE_BLOCK   = 'block.png';
  TEXTURE_ENEMY   = 'enemy.png';
  TEXTURE_PLANET  = 'planet.png';
  TEXTURE_WEAPON  = 'weapon.png';
  TEXTURE_BARREL  = 'barrel.png';

//  PLAY_NORMAL_TEXTURE = 'play_normal.png';
//  PLAY_OVER_TEXTURE   = 'play_over.png';
//  PLAY_CLICK_TEXTURE  = 'play_click.png';
//
//  SETTINGS_NORMAL_TEXTURE = 'settings_normal.png';
//  SETTINGS_OVER_TEXTURE   = 'settings_over.png';
//  SETTINGS_CLICK_TEXTURE  = 'settings_click.png';
//
//  EXIT_NORMAL_TEXTURE = 'exit_normal.png';
//  EXIT_OVER_TEXTURE   = 'exit_over.png';
//  EXIT_CLICK_TEXTURE  = 'exit_click.png';
//
//  MENU_NORMAL_TEXTURE = 'menu_normal.png';
//  MENU_OVER_TEXTURE   = 'menu_over.png';
//  MENU_CLICK_TEXTURE  = 'menu_click.png';
//
//  REPLAY_NORMAL_TEXTURE = 'replay_normal.png';
//  REPLAY_OVER_TEXTURE   = 'replay_over.png';
//  REPLAY_CLICK_TEXTURE  = 'replay_click.png';
//
//  BACK_NORMAL_TEXTURE = 'back_normal.png';
//  BACK_OVER_TEXTURE   = 'back_over.png';
//  BACK_CLICK_TEXTURE  = 'back_click.png';
//
//  SUBMIT_NORMAL_TEXTURE = 'upload_normal.png';
//  SUBMIT_OVER_TEXTURE   = 'upload_over.png';
//  SUBMIT_CLICK_TEXTURE  = 'upload_click.png';

  SLIDER_BACK = 'slider_back.png';
  SLIDER_OVER = 'slider_over.png';
  SLIDER_BTN  = 'slider_btn.png';

  TIMER_TEXTURE = 'hud_timer.png';

var
  //Renderer and scenes
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene{, globalScene}: Iglr2DScene;

  //cursor
  mousePos: TdfVec2f;
  //cursor: IdfSprite;

  //Game systems
  sound: TpdSoundSystem;
  popups: TpdPopups;
  gui: TglrInGameGUI;
  blocks: TpdBlocks;
  enemies: TpdEnemies;
  bullets: TpdBullets;

  //Objects
  player: TpdPlayer;

  //Sound & music
  sClick, sShot, sExpl, sBlockFall: LongWord;
  musicIngame, musicMenu: LongWord;

  //Resources
  atlasMain: TglrAtlas;
  fontCooper: IglrFont;
  texBlock, texEnemy: IglrTexture;

  //Colors
  colorRed: TdfVec4f    = (x: 188/255; y: 71/255;  z: 0.0; w: 1.0);
  colorGreen: TdfVec4f  = (x: 55/255; y: 160/255; z: 0.0; w: 1.0);
  colorWhite: TdfVec4f  = (x: 1.0; y: 1.0;  z: 1.0; w: 1.0);
  colorYellow: TdfVec4f = (x: 0.9; y: 0.93; z: 0.1; w: 1.0);
  colorGray2: TdfVec4f  = (x: 0.2; y: 0.2;  z: 0.2; w: 1.0);
  colorMain: TdfVec4f   = (x: 0.0; y: 137.0/255.0; z: 135/255; w: 1.0);

procedure InitializeGlobal();
procedure FinalizeGlobal();

implementation

procedure InitializeGlobal();
begin
  atlasMain := TglrAtlas.InitCheetahAtlas(FILE_MAIN_TEXTURE_ATLAS);

  //--Font
  fontCooper := Factory.NewFont();
  with fontCooper do
  begin
    AddSymbols(FONT_USUAL_CHARS);
    FontSize := 18;
    GenerateFromTTF(RES_FOLDER + 'CyrillicCooper.ttf');
  end;

  texBlock := atlasMain.LoadTexture(TEXTURE_BLOCK);
  texEnemy := atlasMain.LoadTexture(TEXTURE_ENEMY);

  //--Sound
  sound := TpdSoundSystem.Create(R.WindowHandle);

  //musicIngame := sound.LoadMusic(MUSIC_INGAME);
  musicMenu := sound.LoadMusic(MUSIC_MENU, False);
  sClick := sound.LoadSample(SOUND_CLICK);
  sShot := sound.LoadSample(SOUND_SHOT);
  sBlockFall := sound.LoadSample(SOUND_BLOCK);
  sExpl := sound.LoadSample(SOUND_EXPL);

  //--global scene

//  globalScene := dfCreate2DScene();
//  R.RegisterScene(globalScene);

  //-- Cursor
//  cursor := dfCreateHUDSprite();
//  cursor.PivotPoint := ppTopLeft;
//  cursor.Material.Texture := atlasGame.LoadTexture(CURSOR_TEXTURE);
//  cursor.UpdateTexCoords;
//  cursor.SetSizeToTextureSize;
//  cursor.Z := 100;
//  globalScene.RegisterElement(cursor);
end;

procedure FinalizeGlobal();
begin
//  globalScene.UnregisterElements();
//  R.UnregisterScene(globalScene);
  fontCooper := nil;
  sound.Free();
  atlasMain.Free();
end;

end.

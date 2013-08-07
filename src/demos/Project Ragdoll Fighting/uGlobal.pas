unit uGlobal;

interface

uses
  glr, glrMath, glrUtils, uBox2DImport, uGUI, uSound,
  uCharacter, uCharacterController, uPopup, uParticles;

const
  GAMEVERSION = '0.02a';

  RES_FOLDER = 'rdf-res\';

  Z_PLAYER = 0;
  Z_BACKGROUND = -100;
  Z_STATICOBJECTS = -50;
  Z_DROPOBJECTS = -40;
  Z_MAINMENU_BUTTONS = 25;
  Z_HUD = 50;
  Z_INGAMEMENU = 90;


  MUSIC_INGAME = RES_FOLDER + 'BoxCat Games - Battle.ogg';
  MUSIC_MENU = RES_FOLDER   + 'BoxCat Games - Inspiration.ogg';

  SOUND_CLICK   = RES_FOLDER + 'click.ogg';
  SOUND_KICK    = RES_FOLDER + 'kick.ogg';
  SOUND_PUNCH   = RES_FOLDER + 'punch1.ogg';
  SOUND_PUNCH2  = RES_FOLDER + 'punch2.ogg';
  SOUND_BLOCK   = RES_FOLDER + 'block.ogg';


  FILE_MAIN_TEXTURE_ATLAS = RES_FOLDER + 'main.atlas';

  //Текстуры
//  CURSOR_TEXTURE = 'cursor.png';

//  PLAY_NORMAL_TEXTURE = 'play_normal.png';
//  PLAY_OVER_TEXTURE   = 'play_over.png';
//  PLAY_CLICK_TEXTURE  = 'play_click.png';
//
//  COOP_NORMAL_TEXTURE = 'coop_normal.png';
//  COOP_OVER_TEXTURE   = 'coop_over.png';
//  COOP_CLICK_TEXTURE  = 'coop_click.png';
//
//  SETTINGS_NORMAL_TEXTURE = 'options_normal.png';
//  SETTINGS_OVER_TEXTURE   = 'options_over.png';
//  SETTINGS_CLICK_TEXTURE  = 'options_click.png';
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

  BTN_NORMAL_TEXTURE  = 'btn_normal.png';
  BTN_OVER_TEXTURE    = 'btn_over.png';
  BTN_CLICK_TEXTURE   = 'btn_click.png';

  PLAY_NORMAL_TEXTURE = BTN_NORMAL_TEXTURE;
  PLAY_OVER_TEXTURE   = BTN_OVER_TEXTURE;
  PLAY_CLICK_TEXTURE  = BTN_CLICK_TEXTURE;

  COOP_NORMAL_TEXTURE = BTN_NORMAL_TEXTURE;
  COOP_OVER_TEXTURE   = BTN_OVER_TEXTURE;
  COOP_CLICK_TEXTURE  = BTN_CLICK_TEXTURE;

  SETTINGS_NORMAL_TEXTURE = BTN_NORMAL_TEXTURE;
  SETTINGS_OVER_TEXTURE   = BTN_OVER_TEXTURE;
  SETTINGS_CLICK_TEXTURE  = BTN_CLICK_TEXTURE;

  EXIT_NORMAL_TEXTURE = BTN_NORMAL_TEXTURE;
  EXIT_OVER_TEXTURE   = BTN_OVER_TEXTURE;
  EXIT_CLICK_TEXTURE  = BTN_CLICK_TEXTURE;

  MENU_NORMAL_TEXTURE = BTN_NORMAL_TEXTURE;
  MENU_OVER_TEXTURE   = BTN_OVER_TEXTURE;
  MENU_CLICK_TEXTURE  = BTN_CLICK_TEXTURE;

  REPLAY_NORMAL_TEXTURE = BTN_NORMAL_TEXTURE;
  REPLAY_OVER_TEXTURE   = BTN_OVER_TEXTURE;
  REPLAY_CLICK_TEXTURE  = BTN_CLICK_TEXTURE;

  BACK_NORMAL_TEXTURE = BTN_NORMAL_TEXTURE;
  BACK_OVER_TEXTURE   = BTN_OVER_TEXTURE;
  BACK_CLICK_TEXTURE  = BTN_CLICK_TEXTURE;


  SLIDER_BACK = 'slider_back.png';
  SLIDER_OVER = 'slider_over.png';
  SLIDER_BTN  = 'slider_btn.png';

  HEALTHSLIDER_BACK = 'slider_back2.png';
  HEALTHSLIDER_OVER = 'slider_over2.png';

  CB_ON_TEXTURE       = 'cb_on.png';
  CB_OFF_TEXTURE      = 'cb_off.png';
  CB_ON_OVER_TEXTURE  = 'cb_on_over.png';
  CB_OFF_OVER_TEXTURE = 'cb_off_over.png';

  BODYPART_TEXTURE = 'bodypart.png';
  HEAD_TEXTURE = 'head.png';
  BODYPART_TEXTURE2 = 'bodypart2.png';
  HEAD_TEXTURE2 = 'head2.png';
  BANDAGE_TEXTURE2 = 'bandage2.png';

  PARTICLE_TEXTURE  = 'particle.png';
  PARTICLE_TEXTURE2 = 'particle2.png';
  PARTICLE_TEXTURE3 = 'star.png';

  WEIGHT_TEXTURE = 'weight.png';

var
  //Renderer and scenes
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene, globalScene: Iglr2DScene;

  //Game objects
  player, player2: TpdCharacter;
  playerController: TpdPlayerCharacterController;
  playerController2: TpdCharacterController;

  //some settings
  difficulty: Integer;
  firstLaunch: Boolean;

  //cursor
  mousePos: TdfVec2f;
  //cursor: IdfSprite;

  //Box2D
  b2world: Tglrb2World;
  contactListener: TglrContactListener;

  //Game systems
  gui: TglrInGameGUI;
  sound: TpdSoundSystem;
  popups: TpdPopups;
  particles: TpdParticles;

  //Sound & music
  sClick{, sKick}, sPunch, sPunch2, sBlock: LongWord;
  musicIngame, musicMenu: LongWord;

  //Resources
  atlasMain: TglrAtlas;
  fontCooper: IglrFont;

  texBodyPart, texHead, texParticle: IglrTexture;

  //Colors
  colorRed: TdfVec4f    = (x: 188/255; y: 71/255;  z: 0.0; w: 1.0);
  colorGreen: TdfVec4f  = (x: 55/255; y: 160/255; z: 0.0; w: 1.0);
  colorWhite: TdfVec4f  = (x: 1.0; y: 1.0;  z: 1.0; w: 1.0);
  colorYellow: TdfVec4f = (x: 0.9; y: 0.93; z: 0.1; w: 1.0);
  colorGray2: TdfVec4f  = (x: 0.2; y: 0.2;  z: 0.2; w: 1.0);
  colorGray4: TdfVec4f  = (x: 0.4; y: 0.4;  z: 0.4; w: 1.0);
  colorOrange: TdfVec4f   = (x: 255/255; y: 125/255;  z: 8/255; w: 1.0);

procedure InitializeGlobal();
procedure FinalizeGlobal();

implementation

procedure InitializeGlobal();
begin
  atlasMain := TglrAtlas.InitCheetahAtlas(FILE_MAIN_TEXTURE_ATLAS);

  texBodyPart := atlasMain.LoadTexture(BODYPART_TEXTURE2);
  texHead := atlasMain.LoadTexture(HEAD_TEXTURE2);
  texParticle := atlasMain.LoadTexture(PARTICLE_TEXTURE2);

  //--Font
  fontCooper := Factory.NewFont();
  with fontCooper do
  begin
    AddSymbols(FONT_USUAL_CHARS);
    FontSize := 18;
    GenerateFromTTF(RES_FOLDER + 'CyrillicCooper.ttf');
  end;

  //--Sound
  sound := TpdSoundSystem.Create(R.WindowHandle);

  musicIngame := sound.LoadMusic(MUSIC_INGAME);
  musicMenu := sound.LoadMusic(MUSIC_MENU);
  sClick := sound.LoadSample(SOUND_CLICK);
  //sKick := sound.LoadSample(SOUND_KICK);
  sPunch := sound.LoadSample(SOUND_PUNCH);
  sPunch2 := sound.LoadSample(SOUND_PUNCH2);
  sBlock := sound.LoadSample(SOUND_BLOCK);

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
  texBodyPart := nil;
  texHead := nil;
  fontCooper := nil;
  sound.Free();
  atlasMain.Free();
end;

end.

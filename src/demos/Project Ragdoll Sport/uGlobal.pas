unit uGlobal;

interface

uses
  glr, glrMath, glrUtils, uBox2DImport, uGUI, uSound,
  uCharacter, uCharacterController, uPopup, uObjects;

type
  TpdObjectType = (tCharacter, tSphere);

  TpdUserData = record
    aType: TpdObjectType;
    aObject: TObject;
    aObjectSprite: IglrSprite;
    aBodyPart: TglrBodyPart;
  end;

  //Статистика для экрана геймовера
  TpdStatsData = record
    scores: Integer;
    maxPower: Integer;
    foulsCount: Integer;
  end;

const
  GAMEVERSION = '0.03a';

  RES_FOLDER = 'rds-res\';

  Z_PLAYER = 0;
  Z_BACKGROUND = -100;
  Z_STATICOBJECTS = -50;
  Z_DROPOBJECTS = -40;
  Z_MAINMENU_BUTTONS = 25;
  Z_HUD = 50;
  Z_INGAMEMENU = 90;


  MUSIC_INGAME = RES_FOLDER + '';
  MUSIC_MENU = RES_FOLDER + 'footbal marsh.ogg';

  SOUND_CLICK   = RES_FOLDER + 'click.ogg';
  SOUND_KICK    = RES_FOLDER + 'kick.ogg';
  SOUND_WHISTLE = RES_FOLDER + 'whistle.ogg';
  SOUND_GOAL    = RES_FOLDER + 'goal.ogg';


  FILE_MAIN_TEXTURE_ATLAS = RES_FOLDER + 'main-atlas.atlas';

  //Текстуры
//  CURSOR_TEXTURE = 'cursor.png';

  PLAY_NORMAL_TEXTURE = 'play_normal.png';
  PLAY_OVER_TEXTURE   = 'play_over.png';
  PLAY_CLICK_TEXTURE  = 'play_click.png';
//  PLAY_NORMAL_TEXTURE = 'play_over.png';
//  PLAY_OVER_TEXTURE   = 'play_click.png';
//  PLAY_CLICK_TEXTURE  = 'play_normal.png';

  SETTINGS_NORMAL_TEXTURE = 'settings_normal.png';
  SETTINGS_OVER_TEXTURE   = 'settings_over.png';
  SETTINGS_CLICK_TEXTURE  = 'settings_click.png';

  EXIT_NORMAL_TEXTURE = 'exit_normal.png';
  EXIT_OVER_TEXTURE   = 'exit_over.png';
  EXIT_CLICK_TEXTURE  = 'exit_click.png';

  MENU_NORMAL_TEXTURE = 'menu_normal.png';
  MENU_OVER_TEXTURE   = 'menu_over.png';
  MENU_CLICK_TEXTURE  = 'menu_click.png';

  REPLAY_NORMAL_TEXTURE = 'replay_normal.png';
  REPLAY_OVER_TEXTURE   = 'replay_over.png';
  REPLAY_CLICK_TEXTURE  = 'replay_click.png';

  BACK_NORMAL_TEXTURE = 'back_normal.png';
  BACK_OVER_TEXTURE   = 'back_over.png';
  BACK_CLICK_TEXTURE  = 'back_click.png';

  SUBMIT_NORMAL_TEXTURE = 'upload_normal.png';
  SUBMIT_OVER_TEXTURE   = 'upload_over.png';
  SUBMIT_CLICK_TEXTURE  = 'upload_click.png';

  TEXTBOX_TEXTURE         = 'textbox_back.png';
  TEXTBOX_FOCUSED_TEXTURE = 'textbox_back_focused.png';

  SLIDER_BACK = 'slider_back.png';
  SLIDER_OVER = 'slider_over.png';
  SLIDER_BTN  = 'slider_btn.png';

  CB_ON_TEXTURE       = 'cb_on.png';
  CB_OFF_TEXTURE      = 'cb_off.png';
  CB_ON_OVER_TEXTURE  = 'cb_on_over.png';
  CB_OFF_OVER_TEXTURE = 'cb_off_over.png';

  BODYPART_TEXTURE = 'bodypart.png';
  HEAD_TEXTURE = 'head.png';

  TIMER_TEXTURE = 'hud_timer.png';

var
  //Renderer and scenes
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene, globalScene: Iglr2DScene;

  //Game objects
  player: TpdCharacter;
  playerController: TpdPlayerCharacterController;
  playerFoulsCount: Integer;
  playerName: WideString;

  //cursor
  mousePos: TdfVec2f;
  cursor: IglrSprite;

  //Box2D
  b2world: Tglrb2World;
  contactListener: TglrContactListener;

  //Game systems
  gui: TglrInGameGUI;
  sound: TpdSoundSystem;
  popups: TpdPopups;
  drops: TpdDrops;

  onlineServices, mouseControl: Boolean;

  //Sound & music
  sClick, sKick, sGoal, sWhistle: LongWord;
  musicIngame, musicMenu: LongWord;

  //Resources
  atlasMain: TglrAtlas;
  fontCooper: IglrFont;

  texBodyPart, texHead: IglrTexture;

  //Colors
  colorRed: TdfVec4f    = (x: 188/255; y: 71/255;  z: 0.0; w: 1.0);
  colorGreen: TdfVec4f  = (x: 55/255; y: 160/255; z: 0.0; w: 1.0);
  colorWhite: TdfVec4f  = (x: 1.0; y: 1.0;  z: 1.0; w: 1.0);
  colorYellow: TdfVec4f = (x: 0.9; y: 0.93; z: 0.1; w: 1.0);
  colorGray2: TdfVec4f  = (x: 0.2; y: 0.2;  z: 0.2; w: 1.0);

procedure InitializeGlobal();
procedure FinalizeGlobal();

implementation

procedure InitializeGlobal();
begin
  atlasMain := TglrAtlas.InitCheetahAtlas(FILE_MAIN_TEXTURE_ATLAS);

  texBodyPart := atlasMain.LoadTexture(BODYPART_TEXTURE);
  texHead := atlasMain.LoadTexture(HEAD_TEXTURE);

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

  //musicIngame := sound.LoadMusic(MUSIC_INGAME);
  musicMenu := sound.LoadMusic(MUSIC_MENU, False);
  sClick := sound.LoadSample(SOUND_CLICK);
  sKick := sound.LoadSample(SOUND_KICK);
  sWhistle := sound.LoadSample(SOUND_WHISTLE);
  sGoal := sound.LoadSample(SOUND_GOAL);

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

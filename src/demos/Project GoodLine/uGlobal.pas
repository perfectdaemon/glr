unit uGlobal;

interface

uses
  glr, glrMath, glrUtils, uSound, uLevel, uBox2DImport, uTrigger;

const
  GAMEVERSION = '0.03';

  RES_FOLDER = 'glg-res\';

  Z_BACKGROUND = -100;
  Z_MAINMENU = 25;
  Z_LEVEL = 0;
  Z_BLOCKS = 10;
  Z_PLAYER = 25;
  Z_HUD = 50;
  Z_INGAMEMENU = 75;

  CAT_PLAYER  = $0001;
  CAT_WHEELS  = $0002;
  CAT_ENEMY   = $0004;
  CAT_STATIC  = $0008;
  CAT_BONUS   = $0010;
  CAT_SENSOR  = $0020;
  CAT_DYNAMIC = $0040;

  MASK_PLAYER = CAT_ENEMY or CAT_STATIC or CAT_BONUS or CAT_SENSOR or CAT_DYNAMIC;
  MASK_PLAYER_WHEELS = CAT_ENEMY or CAT_STATIC or CAT_BONUS or CAT_DYNAMIC;
  MASK_ENEMY  = CAT_PLAYER or CAT_WHEELS or CAT_STATIC or CAT_DYNAMIC;
  MASK_SENSOR = CAT_PLAYER;
  MASK_DYNAMIC = CAT_PLAYER or CAT_WHEELS or CAT_ENEMY or CAT_STATIC or CAT_DYNAMIC;
  MASK_EARTH = CAT_PLAYER or CAT_WHEELS or CAT_ENEMY or CAT_DYNAMIC;


  MUSIC_INGAME = RES_FOLDER + 'HE-LUX - Essentials.ogg';
  MUSIC_MENU   = RES_FOLDER + 'Misha Mishenko - Sol.ogg';

  SOUND_CLICK   = RES_FOLDER + 'click.ogg';

  FILE_MAIN_TEXTURE_ATLAS = RES_FOLDER + 'atlas.atlas';

  CAR_CONF_FILE = RES_FOLDER + 'car.conf';
  LEVEL_CONF_FILE = RES_FOLDER + 'level1.conf';

  BTN_NORMAL_TEXTURE  = 'btn_normal.png';
  BTN_OVER_TEXTURE    = 'btn_over.png';
  BTN_CLICK_TEXTURE   = 'btn_click.png';

  SLIDER_BACK = 'slider_back.png';
  SLIDER_OVER = 'slider_over.png';
  SLIDER_BTN  = 'slider_btn.png';

  BLOCK_TEXTURE = 'block.png';
  CUBE_TEXTURE = 'cube.png';
  CIRCLE_TEXTURE = 'circle.png';

  //CB_ON_TEXTURE       = 'cb_on.png';
  //CB_OFF_TEXTURE      = 'cb_off.png';
  //CB_ON_OVER_TEXTURE  = 'cb_on_over.png';
  //CB_OFF_OVER_TEXTURE = 'cb_off_over.png';

  //PARTICLE_TEXTURE  = 'particle.png';
  //PARTICLE_TEXTURE2 = 'particle2.png';

  BTN_TEXT_OFFSET_X = -100;
  BTN_TEXT_OFFSET_Y = -15;

type
  TpdObjectType = (oPlayer, oSensor, oEarth);
  TpdUserData = record
    aType: TpdObjectType;
    aObject: TObject;
  end;
  PpdUserData = ^TpdUserData;

var
  //Renderer and scenes
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene{, globalScene}: Iglr2DScene;

  //Game objects


  //Game systems
  sound: TpdSoundSystem;
  b2world: Tglrb2World;
  level: TpdLevel;
  triggers: TpdTriggerFactory;

  //Sound & music
  sClick: LongWord;
  musicIngame, musicMenu: LongWord;

  mousePos: TdfVec2f;

  //Resources
  atlasMain: TglrAtlas;
  fontSouvenir: IglrFont;

  //Colors
  colorRed: TdfVec4f    = (x: 255/255; y: 30/255;   z: 0.0;   w: 1.0);
  colorWhite: TdfVec4f  = (x: 1.0; y: 1.0;  z: 1.0; w: 1.0);
  colorGreen: TdfVec4f  = (x: 55/255;  y: 160/255;  z: 0.0;   w: 1.0);
  colorOrange: TdfVec4f = (x: 255/255; y: 125/255;  z: 8/255; w: 1.0);
  colorYellow: TdfVec4f = (x: 0.9;     y: 0.93;     z: 0.1;   w: 1.0);

procedure InitializeGlobal();
procedure FinalizeGlobal();

implementation

//uses
//  uCarSaveLoad;

procedure InitializeGlobal();
//var
//  car: TpdCarInfo;
begin
  atlasMain := TglrAtlas.InitCheetahAtlas(FILE_MAIN_TEXTURE_ATLAS);

  //--Font
  fontSouvenir := Factory.NewFont();
  with fontSouvenir do
  begin
    AddSymbols(FONT_USUAL_CHARS);
    FontSize := 18;
    GenerateFromTTF(RES_FOLDER + 'Souvenir Regular.ttf', 'Souvenir');
  end;

  //--Sound
  sound := TpdSoundSystem.Create(R.WindowHandle);

  musicIngame := sound.LoadMusic(MUSIC_INGAME);
  musicMenu := sound.LoadMusic(MUSIC_MENU);
  sClick := sound.LoadSample(SOUND_CLICK);

//  with car do
//  begin
//    BodyR := 0.5;
//    BodyD := 1.0;
//    BodyF := 0.9;
//    WheelRearR := 0.4;
//    WheelRearD := 0.2;
//    WheelRearF := 0.7;
//    WheelFrontR := 0.4;
//    WheelFrontD := 0.2;
//    WheelFrontF := 0.7;
//
//    WheelRearOffset := dfVec2f(-30, 20);
//    WheelFrontOfsset := dfVec2f(30, 20);
//    SuspRearOffset := dfVec2f(-30, 10);
//    SuspFrontOffset := dfVec2f(30, 10);
//    BodyMassCenterOffset := dfVec2f(0, 10);
//
//    SuspRearLimit := dfVec2f(-5, 5);
//    SuspFrontLimit := dfVec2f(-5, 5);
//
//    SuspRearMotorSpeed := 10;
//    SuspRearMaxMotorForce := 100;
//    SuspFrontMotorSpeed := 10;
//    SuspFrontMaxMotorForce := 100;
//  end;
//
//  TpdCarInfoSaveLoad.SaveToFile(CAR_CONF_FILE, car);
end;

procedure FinalizeGlobal();
begin
  sound.Free();
  atlasMain.Free();
end;

end.

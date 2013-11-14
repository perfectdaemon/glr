unit uGlobal;

interface

uses
  glr, glrMath, glrUtils, uSound;

const
  GAMEVERSION = '0.03';

  RES_FOLDER = 'glg-res\';

  Z_BACKGROUND = -100;
  Z_MAINMENU = 25;
  Z_HUD = 50;
  Z_INGAMEMENU = 75;


  MUSIC_INGAME = RES_FOLDER + 'HE-LUX - Essentials.ogg';
  MUSIC_MENU   = RES_FOLDER + 'Misha Mishenko - Sol.ogg';

  SOUND_CLICK   = RES_FOLDER + 'click.ogg';
  SOUND_ROTATE  = RES_FOLDER + 'rotate.ogg';
  SOUND_DOWN    = RES_FOLDER + 'down.ogg';

  FILE_MAIN_TEXTURE_ATLAS = RES_FOLDER + 'atlas.atlas';

  BTN_NORMAL_TEXTURE  = 'btn_normal.png';
  BTN_OVER_TEXTURE    = 'btn_over.png';
  BTN_CLICK_TEXTURE   = 'btn_click.png';

  SLIDER_BACK = 'slider_back.png';
  SLIDER_OVER = 'slider_over.png';
  SLIDER_BTN  = 'slider_btn.png';

  CB_ON_TEXTURE       = 'cb_on.png';
  CB_OFF_TEXTURE      = 'cb_off.png';
  CB_ON_OVER_TEXTURE  = 'cb_on_over.png';
  CB_OFF_OVER_TEXTURE = 'cb_off_over.png';

  PARTICLE_TEXTURE  = 'particle.png';
  PARTICLE_TEXTURE2 = 'particle2.png';

  BTN_TEXT_OFFSET_X = -100;
  BTN_TEXT_OFFSET_Y = -15;

var
  //Renderer and scenes
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene{, globalScene}: Iglr2DScene;

  //Game objects


  //Game systems
  sound: TpdSoundSystem;

  //Sound & music
  sClick: LongWord;
  musicIngame, musicMenu: LongWord;

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

procedure InitializeGlobal();
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
end;

procedure FinalizeGlobal();
begin
  sound.Free();
  atlasMain.Free();
end;

end.

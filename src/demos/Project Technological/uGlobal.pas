unit uGlobal;

interface

uses
  glr, glrMath, glrUtils, glrSound, uBox2DImport;

const
  GAMEVERSION = '0.01';

  RES_FOLDER = 'tech-res\';

  Z_BACKGROUND = -100;
  Z_LEVEL = 0;
  Z_PLAYER = 25;
  Z_BLOCKS = 35;
  Z_HUD = 50;
  Z_INGAMEMENU = 75;

  CAT_STATIC = $0001;
  CAT_BLOCK  = $0002;

  MUSIC_INGAME = RES_FOLDER + '';
  SOUND_CLICK   = RES_FOLDER + 'click.ogg';

  FILE_MAIN_TEXTURE_ATLAS = RES_FOLDER + 'atlas.atlas';

  BTN_NORMAL_TEXTURE  = 'btn_normal.png';
  BTN_OVER_TEXTURE    = 'btn_over.png';
  BTN_CLICK_TEXTURE   = 'btn_click.png';

  CIRCLE_TEXTURE = 'circle.png';

  BTN_TEXT_OFFSET_X = -100;
  BTN_TEXT_OFFSET_Y = -12;

var
  //Renderer and scenes
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene{, globalScene}: Iglr2DScene;

  //Game objects
  cursor: IglrSprite;

  //Game systems
  sound: TpdSoundSystem;
  b2world: Tglrb2World;

  //Sound & music
  sClick: LongWord;
  musicIngame, musicMenu: LongWord;

  //Resources
  atlasMain: TglrAtlas;
  fontBaltica: IglrFont;

  //Colors
  colors: array[0..3] of TdfVec4f =
  ((x: 255/255; y: 30/255;   z: 0.0;   w: 1.0), //red
   (x: 55/255;  y: 160/255;  z: 0.0;   w: 1.0), //green
   (x: 255/255; y: 125/255;  z: 8/255; w: 1.0), //orange
   (x: 0.9;     y: 0.93;     z: 0.1;   w: 1.0)); //yellow

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

  mainScene := Factory.New2DScene();
  hudScene := Factory.New2DScene();
  cursor := Factory.NewHudSprite();
  with cursor do
  begin
    Width := 40;
    Height := Width;
    Material.Texture := atlasMain.LoadTexture(CIRCLE_TEXTURE);
    Material.Diffuse := colorOrange;
    UpdateTexCoords();
    PivotPoint := ppCenter;
    Position := dfVec3f(0, 0 , 100);
  end;
  hudScene.RootNode.AddChild(cursor);

  R.RegisterScene(mainScene);
  R.RegisterScene(hudScene);

  //--Font
  fontBaltica := Factory.NewFont();
  with fontBaltica do
  begin
    AddSymbols(FONT_USUAL_CHARS);
    FontSize := 18;
    GenerateFromTTF(RES_FOLDER + 'BalticaCTT.ttf');
  end;

  //--Sound
  sound := TpdSoundSystem.Create(R.WindowHandle);
  sClick := sound.LoadSample(SOUND_CLICK);
  musicIngame := sound.LoadMusic(MUSIC_INGAME);
end;

procedure FinalizeGlobal();
begin
  //R.UnregisterScene(mainScene);
  sound.Free();
  atlasMain.Free();
end;

end.

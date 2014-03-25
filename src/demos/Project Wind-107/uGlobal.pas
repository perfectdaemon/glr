unit uGlobal;

interface

uses
  glr, glrMath, glrUtils, glrSound,
  uPause, uHud, uParticles;

const
  GAMEVERSION = '0.01';

  RES_FOLDER = 'wind-res\';

  Z_BACKGROUND = -100;
  Z_STARS = -50;
  Z_PLAYER = 0;
  Z_ENEMY = 10;
  Z_PARTICLES = 25;
  Z_HUD = 75;
  Z_INGAMEMENU = 90;

  MUSIC_INGAME = RES_FOLDER + 'BRD - Teleport Prokg.ogg';
  MUSIC_MENU   = RES_FOLDER + 'Misha Mishenko - Sol.ogg';

  FILE_MAIN_TEXTURE_ATLAS = RES_FOLDER + 'atlas.atlas';

  BTN_NORMAL_TEXTURE  = 'btn.png';
//  BTN_OVER_TEXTURE    = 'btn.png';
//  BTN_CLICK_TEXTURE   = 'btn.png';

//  SLIDER_BACK = 'slider_back.png';
//  SLIDER_OVER = 'slider_over.png';
//  SLIDER_BTN  = 'slider_btn.png';

  PARTICLE_BOOM_TEXTURE  = 'particle.png';

  ARROW_TEXTURE = 'arrow.png';
  TARGET_TEXTURE = 'target.png';
  WALL_TEXTURE = 'wall.png';


  BTN_TEXT_OFFSET_X = -50;
  BTN_TEXT_OFFSET_Y = -15;


var
  //Renderer and scenes
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene: Iglr2DScene;

  //Game objects

  //Game systems
  sound: TpdSoundSystem;
  pauseMenu: TpdPauseMenu;
  hud: TpdHud;
  particles: TpdParticles;
  particlesDummy: IglrNode;

  //Sound & music
  musicIngame, musicMenu: LongWord;

  mousePos, mousePosAtScene: TdfVec2f;

  //Resources
  atlasMain: TglrAtlas;
  fontSouvenir: IglrFont;

  //Colors

  colorWhite: TdfVec4f  = (x: 1.0; y: 1.0;  z: 1.0; w: 1.0);
  colorBlack: TdfVec4f  = (x: 0.0; y: 0.0; z: 0.0; w: 1.0);
  colorGray: TdfVec4f   = (x: 0.15; y: 0.15; z: 0.25; w: 1.0);

  colorRed: TdfVec4f    = (x: 255/255; y: 30/255;   z: 0.0;   w: 1.0);
  colorGreen: TdfVec4f  = (x: 55/255;  y: 160/255;  z: 0.0;   w: 1.0);
  colorOrange: TdfVec4f = (x: 255/255; y: 125/255;  z: 8/255; w: 1.0);
  colorYellow: TdfVec4f = (x: 0.9;     y: 0.93;     z: 0.1;   w: 1.0);


  texParticleBoom: IglrTexture;

procedure InitializeGlobal();
procedure FinalizeGlobal();

procedure GameStart();
procedure GameEnd();

implementation

uses
  ogl;


procedure InitializeGlobal();
begin
  gl.ClearColor(79 / 255, 134 / 255, 70 / 255, 1.0);
  atlasMain := TglrAtlas.InitCheetahAtlas(FILE_MAIN_TEXTURE_ATLAS);
  texParticleBoom := atlasMain.LoadTexture(PARTICLE_BOOM_TEXTURE);

  //--Font
  fontSouvenir := Factory.NewFont();
  with fontSouvenir do
  begin
    AddSymbols(FONT_USUAL_CHARS);
    FontSize := 16;
    GenerateFromTTF(RES_FOLDER + 'Souvenir Regular.ttf', 'Souvenir');
  end;

  //--Sound
  sound := TpdSoundSystem.Create(R.WindowHandle);

  musicIngame := sound.LoadMusic(MUSIC_INGAME);
  musicMenu := sound.LoadMusic(MUSIC_MENU);

  mainScene := Factory.New2DScene();
  hudScene := Factory.New2DScene();
  hudScene.IsCameraIndependent := True;
  R.RegisterScene(mainScene);
  R.RegisterScene(hudScene);

  pauseMenu := TpdPauseMenu.Create();
end;

procedure FinalizeGlobal();
begin
  sound.Free();
  atlasMain.Free();
  pauseMenu.Free();
  mainScene.RootNode.RemoveAllChilds();
  hudScene.RootNode.RemoveAllChilds();
  mainScene := nil;
  hudScene := nil;
end;

procedure GameStart();
begin
  particlesInternalZ := 0;
  particlesDummy := Factory.NewNode();
  particles := TpdParticles.Create(32);

  mainScene.RootNode.AddChild(particlesDummy);

  hud := TpdHud.Create();
end;

procedure GameEnd();
begin
  hud.Free();
  particles.Free();
  particlesDummy.RemoveAllChilds();

  particlesDummy := nil;
  mainScene.RootNode.RemoveAllChilds();
end;

end.

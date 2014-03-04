unit uGlobal;

interface

uses
  SysUtils,
  glr, glrMath, glrUtils, glrSound,
  uShip, uPause, uSpace;

const
  GAMEVERSION = '0.01';

  RES_FOLDER = 'space-res\';

  Z_BACKGROUND = -100;
  Z_STARS = -50;
  Z_PLAYER = 0;
  Z_ENEMY = 10;
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

  PARTICLE_TEXTURE  = 'particle.png';
  SHIP_TEXTURE = 'player.png';
  FLAME_TEXTURE = 'flame.png';

  BTN_TEXT_OFFSET_X = -50;
  BTN_TEXT_OFFSET_Y = -15;

  STARS_PER_LAYER = 50;

var
  //Renderer and scenes
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mainScene, hudScene: Iglr2DScene;

  //Game objects
  player: TpdPlayer;
  space: TpdSpace;

  //Game systems
  sound: TpdSoundSystem;
  pauseMenu: TpdPauseMenu;

  //Sound & music
  musicIngame, musicMenu: LongWord;

  mousePos, mousePosAtScene: TdfVec2f;

  //Resources
  atlasMain: TglrAtlas;
  fontSouvenir: IglrFont;

  //Colors
{
  colorWhite: TdfVec4f  = (x: 1.0; y: 1.0;  z: 1.0; w: 1.0);
  colorBlack: TdfVec4f  = (x: 0.0; y: 0.0; z: 0.0; w: 1.0);
  colorGray: TdfVec4f   = (x: 0.15; y: 0.15; z: 0.25; w: 1.0);

  colorRed: TdfVec4f    = (x: 255/255; y: 30/255;   z: 0.0;   w: 1.0);
  colorGreen: TdfVec4f  = (x: 55/255;  y: 160/255;  z: 0.0;   w: 1.0);
  colorOrange: TdfVec4f = (x: 255/255; y: 125/255;  z: 8/255; w: 1.0);
  colorYellow: TdfVec4f = (x: 0.9;     y: 0.93;     z: 0.1;   w: 1.0);
                                                }
  //special for space 106
  scolorWhite: TdfVec4f = (x: 1.0; y: 1.0;  z: 1.0; w: 1.0);
  scolorBlack: TdfVec4f = (x: 30/255; y: 30/255;  z: 30/255; w: 1.0);
  scolorBlue:  TdfVec4f = (x: 74/255; y: 151/255;  z: 215/255; w: 1.0);
  scolorRed:   TdfVec4f = (x: 215/255; y: 109/255;  z: 74/255; w: 1.0);

procedure InitializeGlobal();
procedure FinalizeGlobal();

procedure GameStart();
procedure GameEnd();

implementation


procedure InitializeGlobal();
begin
  atlasMain := TglrAtlas.InitCheetahAtlas(FILE_MAIN_TEXTURE_ATLAS);

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
  if Assigned(player) then
    FreeAndNil(player);
  if Assigned(space) then
    FreeAndNil(space);
  mainScene.RootNode.RemoveAllChilds();

  player := TpdPlayer.Create();
  player.Body.Position2D := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2);

  space := TpdSpace.Create(3);
end;

procedure GameEnd();
begin
  FreeAndNil(player);
  FreeAndNil(space);
end;

end.

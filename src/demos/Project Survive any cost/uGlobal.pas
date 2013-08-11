unit uGlobal;

interface

uses
  glr, glrUtils, glrMath, uSound;

type
  TpdParam = (pHealth, pHunger, pThirst, pFatigue, pMind);

  TpdDieCallback = procedure(aReason: TpdParam) of object;

const
  RES_FOLDER = 'survive-res\';

  Z_PLAYER = 0;
  Z_BACKGROUND = -100;
  Z_STATICOBJECTS = -50;
  Z_MAINMENU_BUTTONS = 50;
  Z_HUD = 75;
  Z_INGAMEMENU = 90;

  FILE_MENU_TEXTURE_ATLAS = RES_FOLDER + 'menu-atlas.atlas';
  FILE_GAME_TEXTURE_ATLAS = RES_FOLDER + 'game-atlas.atlas';
  FILE_INGAMEMENU_TEXTURE_ATLAS = RES_FOLDER + 'ingame-menus.atlas';

  TEXT_LMB_COLLECT = 'ËÊÌ — ñîáðàòü';
  TEXT_LMB_GET     = 'ËÊÌ — âçÿòü';
  TEXT_RMB_EAT     = 'ÏÊÌ — ñúåñòü';
  TEXT_RMB_DRINK   = 'ÏÊÌ — ïèòü';
  TEXT_RMB_FULFILL = 'ÏÊÌ — íàáðàòü âîäû';
  TEXT_RMB_GETFISH = 'ÏÊÌ — ïîðûáà÷èòü';

  //Òåêñòóðû
  PLAY_NORMAL_TEXTURE = 'play_normal.png';
  PLAY_OVER_TEXTURE   = 'play_over.png';
  PLAY_CLICK_TEXTURE  = 'play_click.png';

  ABOUT_NORMAL_TEXTURE = 'about_normal.png';
  ABOUT_OVER_TEXTURE   = 'about_over.png';
  ABOUT_CLICK_TEXTURE  = 'about_click.png';

  SOUND_ON_TEXTURE       = 'sound_on.png';
  SOUND_OFF_TEXTURE      = 'sound_off.png';
  SOUND_ON_OVER_TEXTURE  = 'sound_on_over.png';
  SOUND_OFF_OVER_TEXTURE = 'sound_off_over.png';

  EXIT_NORMAL_TEXTURE = 'exit_normal.png';
  EXIT_OVER_TEXTURE   = 'exit_over.png';
  EXIT_CLICK_TEXTURE  = 'exit_click.png';

  BUSH_TEXTURE = 'object_bush.png';
  BERRY_TEXTURE = 'item_berry.png';
  TWIG_TEXTURE = 'item_twig.png';
  MUSHROOM_TEXTURE = 'item_mushroom.png';
  FLOWER_TEXTURE = 'item_flower.png';
  OLDGRASS_TEXTURE = 'item_oldgrass.png';
  NEWGRASS_TEXTURE = 'item_grass.png';
  WIRE_TEXTURE     = 'item_wire.png';
  BOTTLE_TEXTURE   = 'item_bottle.png';
  KNIFE_TEXTURE    = 'item_knife.png';
  BACKPACK_TEXTURE = 'backpack.png';
  FISH_TEXTURE     = 'item_fish.png';

  CAMPFIRE_TEXTURE = 'campfire.png';
  SHARP_TWIG_TEXTURE = 'item_twig_sharp.png';
  FISHROD_TEXTURE    = 'item_fishrod.png';
  MUSHROOM_SHASHLIK_TEXTURE = 'item_mushroom_shashlik.png';
  MUSHROOM_SHASHLIK_READY_TEXTURE = 'item_mushroom_shashlik_ready.png';
  FISH_SHASHLIK_TEXTURE = 'item_fish_shashlik.png';
  FISH_SHASHLIK_READY_TEXTURE = 'item_fish_shashlik_ready.png';
  BOTTLE_TEA_TEXTURE = 'item_bottle_tea.png';


procedure LoadGlobalResources();
procedure FreeGlobalResources();

procedure UpdateCursor(const dt: Double);

var
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  sound: TpdSoundSystem;
  mousePos: TdfVec2f;
  cursor: IglrSprite;
  cursorText: IglrText;

  atlasMenu, atlasGame, atlasInGameMenu: TglrAtlas;

  fontCooper: IglrFont;

  mainScene, hudScene, globalScene: Iglr2DScene;

  musicIngame, musicMenu: LongWord;

  colorRed: TdfVec4f    = (x: 0.9; y: 0.1; z: 0.1; w: 1.0);
  colorGreen: TdfVec4f  = (x: 0.1; y: 0.93; z: 0.1; w: 1.0);
  colorWhite: TdfVec4f  = (x: 1.0; y: 1.0; z: 1.0; w: 1.0);
  colorYellow: TdfVec4f = (x: 0.9; y: 0.93; z: 0.1; w: 1.0);

const
  CURSOR_TEXTURE = 'cursor.png';
  MUSIC_INGAME = 'Water Night Etude.ogg';
  MUSIC_MENU = 'Without.ogg';

implementation

//uses
//  Graphics;

procedure LoadGlobalResources();
begin
  atlasMenu := TglrAtlas.InitCheetahAtlas(FILE_MENU_TEXTURE_ATLAS);
  atlasGame := TglrAtlas.InitCheetahAtlas(FILE_GAME_TEXTURE_ATLAS);
  atlasInGameMenu := TglrAtlas.InitCheetahAtlas(FILE_INGAMEMENU_TEXTURE_ATLAS);
  //--Font
  fontCooper := Factory.NewFont();
  with fontCooper do
  begin
    AddSymbols('ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ');
    AddSymbols('QWERTYUIIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm');
    AddSymbols('1234567890');
    AddSymbols('`~!@#$%^&*()"¹;%:?-+—«»[]{}'':<>.,\|/ ' + #13+#10);
    FontSize := 17;
    FontStyle := [];
    GenerateFromTTF(RES_FOLDER + 'CooperLightC BT.otf');
  end;

  //--Sound
  sound := TpdSoundSystem.Create(R.WindowHandle);
  musicIngame := sound.LoadMusic(RES_FOLDER + MUSIC_INGAME);
  musicMenu := sound.LoadMusic(RES_FOLDER + MUSIC_MENU);

  //--global scene

  globalScene := Factory.New2DScene();
  R.RegisterScene(globalScene);

  //-- Cursor
  cursor := Factory.NewHudSprite();
  cursor.PivotPoint := ppTopLeft;
  cursor.Material.Texture := atlasGame.LoadTexture(CURSOR_TEXTURE);
  cursor.UpdateTexCoords;
  cursor.SetSizeToTextureSize;
  cursor.Z := 100;

  cursorText := Factory.NewText();
  cursorText.Font := fontCooper;
  cursorText.Z := 100;
  cursorText.Text := '';
  cursorText.Material.Diffuse := dfVec4f(1, 1, 1, 1);//dfVec4f(0, 107.0 / 255, 203 / 255, 1);
  cursorText.ScaleMult(0.6);

  globalScene.RegisterElement(cursor);
  globalScene.RegisterElement(cursorText);
end;

procedure FreeGlobalResources();
begin
  atlasMenu.Free();
  atlasGame.Free();
  atlasInGameMenu.Free();
  fontCooper := nil;
  mainScene := nil;
  hudScene := nil;
  globalScene.UnregisterElements();
  R.UnregisterScene(globalScene);
  sound.Free();
end;

procedure UpdateCursor(const dt: Double);
begin
  cursor.Position := mousePos;
//  if mousePos.x < R.WindowWidth - 250 then
  cursorText.Position := mousePos + dfVec2f(32, 32);
//  else
//    cursorText.Position := mousePos + dfVec2f(-64, 32)
end;

end.

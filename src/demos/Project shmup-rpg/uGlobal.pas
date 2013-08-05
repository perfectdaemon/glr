{
  Глобальные переменные
}

unit uGlobal;

interface

uses
  dfMath, dfHRenderer, uBox2DImport;

const
  RES_FOLDER = 'shmup_res/';

  Z_PLAYER = 0;
  Z_ENEMIES = -30;
  Z_DROPS = -20;
  Z_BACKGROUND = -100;
  Z_STATICOBJECTS = -50;
  Z_POPUPS = 50;
  Z_HUD = 75;
  Z_INGAMEMENU = 90;

  //Menu: Main
  FILE_MAINMENU_TEXTURE_ATLAS = RES_FOLDER + 'main_menu.tga';
  FILE_MAINMENU_BACKGROUND = RES_FOLDER + 'main_menu_back.tga';

  //Menu: Pause
  FILE_PAUSEMENU_TEXTURE_ATLAS = RES_FOLDER + 'pause_menu.tga';

  //Menu: Authors
  FILE_AUTHORSMENU_TEXTURE_ATLAS = RES_FOLDER + 'authors_menu.tga';

  //Menu: settings
  FILE_SETTINGSMENU_TEXTURE_ATLAS = RES_FOLDER + 'settings_menu.tga';

  //Player
  FILE_PLAYER_SPRITE_REVOLVER   = RES_FOLDER + 'cowboy_rv.tga';
  FILE_PLAYER_SPRITE_SHOTGUN    = RES_FOLDER + 'cowboy_sg2.tga';
  FILE_PLAYER_SPRITE_MACHINEGUN = RES_FOLDER + 'cowboy_mg.tga';

  //Enemies
  FILE_ENEMIES_COYOT_ATLAS = RES_FOLDER + 'coyot.tga';

  //Weapon
  FILE_WEAPON_FIRE_SPRITE = RES_FOLDER + 'fire_sprite.tga';

  //Drop items
  FILE_DROP_AMMO_SHOTGUN    = RES_FOLDER + 'ammo_shotgun.tga';
  FILE_DROP_AMMO_MACHINEGUN = RES_FOLDER + 'ammo_mg.tga';
  FILE_DROP_WHISKEY_BOTTLE  = RES_FOLDER + 'whiskey.tga';

var
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  mousePos: TdfVec2f;
  Phys: Tglrb2World;

implementation

end.

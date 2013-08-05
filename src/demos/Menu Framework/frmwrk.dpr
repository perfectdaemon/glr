program frmwrk;

uses
  Windows,
  SysUtils,
  dfHEngine in '..\..\common\dfHEngine.pas',
  dfHGL in '..\..\common\dfHGL.pas',
  dfMath in '..\..\common\dfMath.pas',
  dfHRenderer in '..\..\headers\dfHRenderer.pas',
  dfHUtility in '..\..\headers\dfHUtility.pas',
  dfTweener in '..\..\common\dfTweener.pas',
  uGlobal in 'uGlobal.pas',
  uGameScreen in 'gamescreens\uGameScreen.pas',
  uGameScreenManager in 'gamescreens\uGameScreenManager.pas',
  uGameScreen.MainMenu in 'gamescreens\uGameScreen.MainMenu.pas',
  uGameScreen.Authors in 'gamescreens\uGameScreen.Authors.pas',
  uGameScreen.NewGame in 'gamescreens\uGameScreen.NewGame.pas',
  uButtonsInfo in 'uButtonsInfo.pas';

var
  GSManager: TpdGSManager;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyDown(VK_ESCAPE) or GSManager.IsQuitMessageReceived then
      R.Stop();
    GSManager.Update(dt);
  end;

begin
  LoadRendererLib();
  R := dfCreateRenderer();
  R.Init('settings_shmup.txt');
  R.OnUpdate := OnUpdate;

  //game screens and manager init
  GSManager := TpdGSManager.Create();
  mainMenu := TpdMainMenu.Create();
  GSManager.Add(mainMenu);
  GSManager.Notify(mainMenu, naSwitchTo);

  R.Start();

  GSManager.Free;
  R.DeInit();
  UnLoadRendererLib();
end.

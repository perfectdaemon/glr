{
  TODO:
  + Проверка при BombAt на нахождение игрока
  + Взрыв
  + Пошаговый режим
  + Враг
    Поправить АИ
    Музыка
    Еще звуки?
}

program taanks;

uses
  Windows,
  SysUtils,
  dfHEngine in '..\..\common\dfHEngine.pas',
  dfHGL in '..\..\common\dfHGL.pas',
  dfMath in '..\..\common\dfMath.pas',
  dfTweener in '..\..\common\dfTweener.pas',
  bass in '..\..\headers\bass.pas',
  dfHRenderer in '..\..\headers\dfHRenderer.pas',
  dfHUtility in '..\..\headers\dfHUtility.pas',
  uGlobal in 'uGlobal.pas',
  uEarth in 'uEarth.pas',
  uTank in 'uTank.pas',
  uSound in 'uSound.pas';

var
  bReturnPressed, bGameOver: Boolean;

  procedure OnEnemyDie();
  begin
    textWinLose.Text := 'Вы выиграли!'#13#10'Нажмите Enter, чтобы начать сначала';
    bGameOver := True;
  end;

  procedure OnPlayerDie();
  begin
    textWinLose.Text := 'Вы проиграли... :('#13#10'Нажмите Enter, чтобы начать сначала';
    bGameOver := True;
  end;

  procedure StartNewGame();
  begin
    if Assigned(player) then
      player.Free();
    if Assigned(enemy) then
      enemy.Free();
    if Assigned(earth) then
      earth.Free();

    mainScene.UnregisterElements();

    bGameOver := False;

    player := TpdPlayerTank.Initialize(mainScene) as TpdPlayerTank;
    player.onDie := OnPlayerDie;
    enemy := TpdEnemyTank.Initialize(mainScene) as TpdEnemyTank;
    enemy.onDie := OnEnemyDie;
    earth := TpdEarth.Initialize(RES_FOLDER + MAP_FILENAME, mainScene);

    player.SetPosition(4 + Random(7), 2);
    player.CheckForFall();
    enemy.SetPosition(45 + Random(9), 2);
    enemy.CheckForFall();
    SwitchTurn(TURN_PLAYER);
  end;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyDown(VK_ESCAPE) then
      R.Stop();

    if not bGameOver then
    begin
      //Player turn
      if turn = TURN_PLAYER then
      begin
        textAngle.Text := 'Угол: ' + IntToStr(Trunc(Abs(player.barrel.Rotation)));
        textPower.Text := 'Сила выстрела: ' + IntToStr(Trunc(player.power));

        if R.Input.IsKeyDown(VK_LEFT) then
          player.ChangeBarrelAngle(- BARREL_CHANGE_SPEED * dt)
        else if R.Input.IsKeyDown(VK_RIGHT) then
          player.ChangeBarrelAngle(  BARREL_CHANGE_SPEED * dt);

        if R.Input.IsKeyDown(VK_DOWN) then
          player.ChangePower(- SHOT_CHANGE_SPEED * dt)
        else if R.Input.IsKeyDown(VK_UP) then
          player.ChangePower(  SHOT_CHANGE_SPEED * dt);

        if R.Input.IsKeyPressed(VK_RETURN, @bReturnPressed) and player.readyForShot then
        begin
          player.Shot();
        end;
      end
      else if turn = TURN_ENEMY then
      begin
        enemy.AISetParams();
      end;
      //--//
      Tweener.Update(dt);
      player.Update(dt);
      enemy.Update(dt);
    end
    else
      if R.Input.IsKeyPressed(VK_RETURN, @bReturnPressed) then
      begin
        bGameOver := False;
        textWinLose.Text := '';
        StartNewGame();
      end;
  end;


begin
  Randomize();
  LoadRendererLib();
  R := glrCreateRenderer();
  Factory := glrGetObjectFactory();
  R.Init('settings_tanks.txt');
  R.OnUpdate := OnUpdate;
  R.Camera.ProjectionMode := pmOrtho;
  R.WindowCaption := PWideChar('Таанки! '
    + GAMEVERSION + ' [glRenderer ' + R.VersionText + ']');

  gl.Init();
  gl.ClearColor(0.3, 0.3, 0.55, 1);

  InitializeGlobal();
  StartNewGame();

  R.Start();

  FinalizeGlobal();

  earth.Free();
  player.Free;
  enemy.Free();

  R.DeInit();
  UnLoadRendererLib();
end.

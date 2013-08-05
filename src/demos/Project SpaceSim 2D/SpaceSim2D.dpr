{
  TODO: Camera movement
}

program SpaceSim2D;
uses
  Windows,
  SysUtils,
  dfHRenderer in '..\..\headers\dfHRenderer.pas',
  dfHUtility in '..\..\headers\dfHUtility.pas',
  dfHEngine in '..\..\common\dfHEngine.pas',
  dfHGL in '..\..\common\dfHGL.pas',
  dfMath in '..\..\common\dfMath.pas',
  uSpace in 'uSpace.pas';

const
  IMPULSE = 10;
  MAX_IMPULSE = 1000;
  SPEED = 10;

var
  R: IglrRenderer;
  fpsCounter: TglrFPSCounter;

  sceneMain: Iglr2DScene;
  sf: IglrSprite;
  sf_impulse: TdfVec2f;

  sun: IglrSprite;

  impulseText: IglrText;

//  dx, dy: Integer;

  timeElapsed: Double;

  procedure UpdateSpaceFighter(const dt: Double);

    procedure ReduceImpulse();
    begin
      if sf_impulse.LengthQ < 1 then
        sf_impulse := dfVec2f(0, 0)
      else
        sf_impulse := sf_impulse * 0.8;
    end;

  begin
    timeElapsed := timeElapsed + dt;
    if timeElapsed > 1 then
    begin
      timeElapsed := 0;
      ReduceImpulse();
    end;

    sf.Position := sf.Position + (sf_impulse * dt * SPEED);
  end;

  procedure AddImpulse(dir: TdfVec2f);
  begin
    sf_impulse := sf_impulse + (dir.Normal * IMPULSE);
    if sf_impulse.LengthQ > MAX_IMPULSE then
      sf_impulse := sf_impulse * (MAX_IMPULSE / sf_impulse.LengthQ);
  end;

  procedure UpdateCamera(const dt: Double);

    const
      BORDER = 70;

    function InBorders(): Boolean;
    begin
      Result := (Abs(sf.Position.x - sceneMain.Origin.x) < R.WindowWidth - BORDER)
             and(Abs(sf.Position.x - sceneMain.Origin.x) > BORDER)
             and(Abs(sf.Position.y - sceneMain.Origin.y) > BORDER)
             and(Abs(sf.Position.y - sceneMain.Origin.y) < R.WindowHeight - BORDER);
    end;

  begin
    if not InBorders() then
    begin
      sceneMain.Origin := sceneMain.Origin - (sf_impulse * dt * SPEED);
    end
  end;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyDown(VK_ESCAPE) then
      R.Stop();
    fpsCounter.Update(dt);
    UpdateSpaceFighter(dt);
    UpdateCamera(dt);
    UpdateStars(sceneMain.Origin);
  end;

  procedure AddSpaceFighter();
  begin
    sf := glrGetObjectFactory().NewSprite();
    sf.PivotPoint := ppCenter;
    sf.Position := dfVec2f(512, 384);
    sf.Material.Texture.Load2D('data\spacefighter1.tga');
    sf.Width := sf.Material.Texture.Width;
    sf.Height := sf.Material.Texture.Height;
    sf.ScaleMult(dfVec2f(0.15, 0.15));
    sf.Rotation := 0;

    sceneMain.RegisterElement(sf);
  end;

  procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState);
  var
    dir_vec: TdfVec2f;
  begin
    dir_vec := dfVec2f(X, Y) - sf.Position;
    AddImpulse(dir_vec.Normal * IMPULSE);
  end;

  procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
  var
    dir_vec: TdfVec2f;
  begin
      dir_vec := dfVec2f(X, Y) - sf.Position;
      dir_vec.Normalize();
      sf.Rotation := dir_vec.GetRotationAngle();
  end;

  procedure InitText();
  begin
    impulseText := glrGetObjectFactory().NewText();
    impulseText.Font := glrNewFilledFont('Verdana', 12);
    impulseText.Position := dfVec2f(0, 20);
    impulseText.Text := 'bla-bla';
    with R.RootNode.AddNewChild() do
      Renderable := impulseText;
    impulseText.AbsolutePosition := False;
  end;

  procedure AddSun();
  begin
    sun := glrGetObjectFactory().NewSprite();
    sun.Position := dfVec2f(512, 384);
    sun.Width := 50;
    sun.Height := 50;
    sun.Material.MaterialOptions.Diffuse := dfVec4f(0.3, 0.3, 0.4, 1);

    sceneMain.RegisterElement(sun);
  end;

begin
  LoadRendererLib();
  gl.Init();

  R := glrCreateRenderer();
  uSpace.R := R;

  R.Init('settings_ss2d.txt');

  fpsCounter := TglrFPSCounter.Create(R.RootNode, 'FPS:', 1, nil);
  sceneMain := glrGetObjectFactory().New2DScene();
  R.RegisterScene(sceneMain);

  AddSpaceFighter();
  AddSun();
  sf_impulse := dfVec2f(0, 0);

  R.OnUpdate := OnUpdate;
  R.OnMouseMove := OnMouseMove;
  R.OnMouseDown := OnMouseDown;
  R.Camera.ProjectionMode := pmOrtho;

//  InitText();
  InitStars(3, 40, 100);

  with glrGetObjectFactory().NewNode(R.RootNode) do
    Renderable := userRender;

  R.Start();
  sceneMain.UnregisterElements();
  R.DeInit();

  UnLoadRendererLib();

  fpsCounter.Free;
end.

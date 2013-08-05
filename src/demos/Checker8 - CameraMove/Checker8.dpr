program Checker8;
uses
  Windows,
  SysUtils,
  dfHEngine in '..\..\common\dfHEngine.pas',
  dfMath in '..\..\common\dfMath.pas',
  dfHRenderer in '..\..\headers\dfHRenderer.pas',
  dfHUtility in '..\..\headers\dfHUtility.pas',
  dfHGL in '..\..\common\dfHGL.pas';

var
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  fpsCounter: TglrFPSCounter;
  sc1: Iglr2DScene;

  text: IglrText;
  font: IglrFont;


const
  CAM_SPEED = 50;

  procedure MoveCamera(X, Y: Single);
  begin
    sc1.Origin := sc1.Origin + dfVec2f(X, Y);
  end;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyDown(VK_ESCAPE) then
      R.Stop();

    if R.Input.IsKeyDown(VK_LEFT) then
      MoveCamera(-CAM_SPEED * dt, 0)
    else if R.Input.IsKeyDown(VK_RIGHT) then
      MoveCamera(CAM_SPEED * dt, 0);
    if R.Input.IsKeyDown(VK_UP) then
      MoveCamera(0, -CAM_SPEED * dt)
    else if R.Input.IsKeyDown(VK_DOWN) then
      MoveCamera(0, CAM_SPEED * dt);

    fpsCounter.Update(dt);
    text.Text := Format('X %.2f  Y %.2f', [sc1.Origin.x, sc1.Origin.y]);
  end;

  procedure AddRandomObjects(aCount: Integer);
  var
    i: Integer;
    newSprite: IglrSprite;
  begin
    Randomize();
    for i := 0 to aCount - 1 do
    begin
      newSprite := Factory.NewSprite();
      newSprite.Position := dfVec2f(Random(800), Random(600));
      newSprite.Rotation := 90 - Random(180);
      newSprite.Width := 5;
      newSprite.Height := 5;
      newSprite.PivotPoint := ppCenter;
      newSprite.Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);

      sc1.RegisterElement(newSprite);
    end;
  end;

begin
  LoadRendererLib();

  R := glrCreateRenderer();
  R.Init('settings.txt');
  R.OnUpdate := OnUpdate;
  Factory  := glrGetObjectFactory();

  fpsCounter := TglrFPSCounter.Create(R.RootNode, 'FPS:', 1, nil);

  sc1 := Factory.New2DScene();
  R.RegisterScene(sc1);
  AddRandomObjects(30);

  font := Factory.NewFont();
  with font do
  begin
    AddRange('!', '~');
    AddRange('À', 'ÿ');
    AddRange(' ', ' ');
    FontSize := 14;
    FontStyle := [];
    GenerateFromFont('Times New Roman');
  end;

  text := Factory.NewText();
  text.Font := font;
  text.Position := dfVec2f(0, 20);
  text.Text := 'bla-bla';
  sc1.RegisterElement(text);

//  with R.RootNode.AddNewChild do
//  begin
//    Renderable := text;
//  end;



  R.Start();

  fpsCounter.Free;
  R.DeInit();


  UnLoadRendererLib();

end.

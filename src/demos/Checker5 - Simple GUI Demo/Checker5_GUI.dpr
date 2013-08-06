program Checker5_GUI;

uses
  Windows,
  SysUtils,
  glr in '..\..\headers\glr.pas',
  glrUtils in '..\..\headers\glrUtils.pas',
  glrMath in '..\..\headers\glrMath.pas',
  ogl in '..\..\headers\ogl.pas';

var
  R: IglrRenderer;
  Factory: IglrObjectFactory;

  Button1, Button2: IglrGUIButton;
  scene1: Iglr2DScene;
  tn, tn2, tn3: IglrTexture;
  //check texture regions
  tn_r: IglrTexture;

  checkbox1: IglrGUICheckbox;
  textbox1: IglrGUITextBox;

  font1: IglrFont;
  text1, text2: IglrText;
  text2PivotPoint: IglrSprite;


  fpsCounter: TglrFPSCounter;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyDown(VK_ESCAPE) then
      R.Stop();
    fpsCounter.Update(dt);
//    R.WindowCaption := PChar(IntToStr(R.TextureSwitches));
  end;

  procedure OnMouseClick(Sender: IglrGUIElement; X, Y: Integer; mb: TglrMouseButton; shift: TglrMouseShiftState);
  begin
    text1.Text := 'Mouse click ';
    if Sender = (Button1 as IglrGUIElement) then
      Button2.Enabled := not Button2.Enabled;
  end;

  procedure OnMouseOver(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton; Shift: TglrMouseShiftState);
  begin
    text1.Text := 'Mouse over';
  end;

  procedure OnMouseOut(Sender: IglrGUIElement; X, Y: Integer; Button: TglrMouseButton; Shift: TglrMouseShiftState);
  begin
    text1.Text := 'Mouse out';
  end;

  procedure InitCheckbox();
  var
    t_on, t_off, t_on_over, t_off_over: IglrTexture;
  begin
    checkbox1 := Factory.NewGuiCheckBox();
    with t_on do
    begin
      t_on := Factory.NewTexture();
      Load2D('data/cb_on.tga');
      BlendingMode := tbmTransparency;
      CombineMode := tcmModulate;
    end;

    with t_off do
    begin
      t_off := Factory.NewTexture();
      Load2D('data/cb_off.tga');
      BlendingMode := tbmTransparency;
      CombineMode := tcmModulate;
    end;

    with t_on_over do
    begin
      t_on_over := Factory.NewTexture();
      Load2D('data/cb_on_over.tga');
      BlendingMode := tbmTransparency;
      CombineMode := tcmModulate;
    end;

    with t_off_over do
    begin
      t_off_over := Factory.NewTexture();
      Load2D('data/cb_off_over.tga');
      BlendingMode := tbmTransparency;
      CombineMode := tcmModulate;
    end;

    with checkbox1 do
    begin
      TextureOn := t_on;
      TextureOnOver := t_on_over;
      TextureOff := t_off;
      TextureOffOver := t_off_over;
      Width := 40;
      Height := 40;
      Position := dfVec2f(220, 180);
      UpdateTexCoords();
    end;

    scene1.RegisterElement(checkbox1);
    R.GUIManager.RegisterElement(checkbox1);
  end;

  procedure InitTextBox();
  begin
    textbox1 := Factory.NewGuiTextBox();
    textbox1.Position := dfVec2f(220, 300);
    textbox1.TextObject.Font := font1;
    textbox1.TextOffset := dfVec2f(8, 4);
    textbox1.Z := 5;
    textbox1.Material.Diffuse := dfVec4f(0, 0, 0, 1);
    textbox1.TextObject.Material.Diffuse := dfVec4f(1, 1, 1, 1);
    textbox1.CursorObject.Material.Diffuse := dfVec4f(0.2, 0.2, 0.9, 1.0);
    textbox1.CursorObject.Width := 10;
    textbox1.Width := 300;
    textbox1.Height := 30;

    scene1.RegisterElement(textbox1);
    R.GUIManager.RegisterElement(textbox1);
    R.GUIManager.Focused := textbox1;
  end;

  procedure InitPivotPointText();
  begin
    text2 := Factory.NewText();
    text2.Font := font1;
    text2.Position := dfVec2f(R.WindowWidth div 2, R.WindowHeight div 2 + 100);
    text2.Text := 'Это многострочный'#13#10'текст, у которого есть длинные строки (и не только)'#13#10'А вообще-то он'#13#10'многострочный';
    text2.PivotPoint := ppTopCenter;
    scene1.RegisterElement(text2);

    text2PivotPoint := Factory.NewHudSprite();
    with text2PivotPoint do
    begin
      Width := 5;
      Height := 5;
      Z := 5;
      Position := text2.Position;
      PivotPoint := ppCenter;
      Material.Diffuse := dfVec4f(1, 0, 0, 0.5);
    end;

    scene1.RegisterElement(text2PivotPoint);
  end;

begin
  LoadRendererLib();

  R := glrCreateRenderer();
  Factory := glrGetObjectFactory();

  R.Init('settings.txt');

  fpsCounter := TglrFPSCounter.Create(R.RootNode, 'FPS:', 1, nil);

  R.OnUpdate := OnUpdate;

  //Text & font
  font1 := Factory.NewFont();
  font1.AddSymbols(FONT_USUAL_CHARS);
  font1.FontSize := 16;
  font1.GenerateFromTTF('data\fonts\Journal.ttf');
//  font1.GenerateFromTTF('data\fonts\BalticaCTT Regular.ttf', 'BalticaCTT');



  text1 := Factory.NewText();
  text1.Font := font1;
  text1.Position := dfVec2f(50, 20);
  text1.Text := 'bla-bla';

  //GUI

  tn_r := Factory.NewTexture();
  tn_r.Load2D('data/buttons.tga');
  tn_r.BlendingMode := tbmTransparency;
  tn_r.CombineMode := tcmModulate;

  Button1 := Factory.NewGUIButton();
  Button2 := Factory.NewGUIButton();
  // - normal texture
  tn := Factory.NewTexture();
  tn.Load2DRegion(tn_r, 0, 0, 256, 45);
  tn.BlendingMode := tbmTransparency;
  tn.CombineMode := tcmModulate;

  // - over texture
  tn2 := Factory.NewTexture();
  tn2.Load2DRegion(tn_r, 0, 47, 256, 45);

  // - click texture
  tn3 := Factory.NewTexture();
  tn3.Load2DRegion(tn_r, 0, 94, 256, 45);

  Button1.TextureNormal := tn;
  Button1.TextureOver := tn2;
  Button1.TextureClick := tn3;

  Button2.TextureNormal := tn;
  Button2.TextureOver := tn2;
  Button2.TextureClick := tn3;

  Button1.UpdateTexCoords();
  Button2.UpdateTexCoords();
  tn := nil;
  tn2 := nil;
  tn3 := nil;

  Button1.OnMouseOver := OnMouseOver;
  Button1.OnMouseOut := OnMouseOut;
  Button1.OnMouseClick := OnMouseClick;
  Button1.Width := 256;//130;
  Button1.Height := 45;//43;
  Button1.Position := dfVec2f(220, 20);

  Button2.OnMouseOver := OnMouseOver;
  Button2.OnMouseOut := OnMouseOut;
  Button2.OnMouseClick := OnMouseClick;
  Button2.Width := 256;//130;
  Button2.Height := 45;//43;
  Button2.Position := dfVec2f(220, 70);

  scene1 := Factory.New2DScene();
  scene1.RegisterElement(text1);
  scene1.RegisterElement(Button1);
  scene1.RegisterElement(Button2);
  R.RegisterScene(scene1);

  R.GUIManager.RegisterElement(Button1);
  R.GUIManager.RegisterElement(Button2);

  InitCheckbox();
  InitTextBox();
  InitPivotPointText();

  R.Start();
  R.DeInit();
  scene1.UnregisterElements();
  R := nil;

  fpsCounter.Free;

  UnLoadRendererLib();
end.

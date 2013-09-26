{
  Ќепосредственна€ проверка Node-системы и HUD-спрайтов
}

program Checker2;

{$APPTYPE CONSOLE}

uses
  ShareMem,
  Windows,
  SysUtils,
  glr in '..\..\headers\glr.pas',
  glrMath in '..\..\headers\glrMath.pas',
  ogl in '..\..\headers\ogl.pas';

var
  R: IglrRenderer;
  Factory: IglrObjectFactory;
  spr, pp, childSprite: IglrSprite;

  deltaRot: Single;

  procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState);
  begin
    case spr.PivotPoint of
      ppTopLeft:
      begin
        spr.PivotPoint := ppTopRight;
        R.WindowCaption := 'TopRight';
      end;
      ppTopRight:
      begin
        spr.PivotPoint := ppBottomLeft;
        R.WindowCaption := 'BottomLeft';
      end;
      ppBottomLeft:
      begin
        spr.PivotPoint := ppBottomRight;
        R.WindowCaption := 'BottomRight';
      end;
      ppBottomRight:
      begin
        spr.PivotPoint := ppCenter;
        R.WindowCaption := 'Center';
      end;
      ppCenter:
      begin
        spr.PivotPoint := ppTopCenter;
        R.WindowCaption := 'TopCenter';
      end;
      ppTopCenter:
      begin
        spr.PivotPoint := ppBottomCenter;
        R.WindowCaption := 'BottomCenter';
      end;
      ppBottomCenter:
      begin
        spr.SetCustomPivotPoint(0.2, 0.7);
        spr.PivotPoint := ppCustom;
        R.WindowCaption := 'Custom';
      end;
      ppCustom:
      begin
        spr.PivotPoint := ppTopLeft;
        R.WindowCaption := 'TopLeft';
      end;
    end;
  end;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyDown(VK_ESCAPE) then
      R.Stop();
    spr.Rotation := spr.Rotation + deltaRot * dt;
    if spr.Rotation > 30 then
      deltaRot := -10
    else if spr.Rotation < -30 then
      deltaRot := 10;
  end;

begin
  WriteLn(' ========= Demonstration 2 ======== ');
  WriteLn(' ====== Press ESCAPE to EXIT ====== ');

  LoadRendererLib();

  R := glrGetRenderer();
  Factory := glrGetObjectFactory();
  R.Init('settings.txt');
  R.OnMouseDown := OnMouseDown;
  R.OnUpdate := OnUpdate;

  spr := Factory.NewHudSprite();
  pp := Factory.NewHudSprite();
  childSprite := Factory.NewHudSprite();
  with spr do
  begin
    Width := 200;
    Height := 100;
    PivotPoint := ppTopLeft;
    Position := dfVec3f(300, 300, -5);
    Material.Texture := Factory.NewTexture();
    Material.Texture.Load2D('data\tile.bmp');
    Material.Diffuse := dfVec4f(1, 1, 1, 1);
    AbsolutePosition := False;
  end;
  R.RootNode.AddChild(spr);

  with pp do
  begin
    PivotPoint := ppCenter;
    Position := dfVec3f(0, 0, 5);
    Material.Diffuse := dfVec4f(1, 1, 1, 1);
    AbsolutePosition := False;
    Width := 5;
    Height := 5;
  end;
  spr.AddChild(pp);

  with childSprite do
  begin
    Width := 30;
    Height := 30;
    PivotPoint := ppCenter;
    Position := dfVec3f(100, 0, 10);
    Material.Diffuse := dfVec4f(1, 0, 0, 0);
    AbsolutePosition := False;
  end;

  spr.AddChild(childSprite);

  deltaRot := 10;

  R.Start();

  R.DeInit();
  R := nil;
//  pp.Material.Texture := nil;
//  pp.Material := nil;
  pp := nil;
  Factory := nil;
//  spr.Material.Texture := nil;
//  spr.Material := nil;
  spr := nil;

  UnLoadRendererLib();
end.

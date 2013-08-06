{

}
unit uHudSprite;

interface

uses
  glrMath, glr, uRenderable;

type

  TglrHUDSprite = class(Tglr2DRenderable, IglrSprite)
  private
    vp: TglrViewportParams;
  protected
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure DoRender(); override;
  end;

implementation

uses
  uRenderer, ogl;


{ TdfHUDSprite }

constructor TglrHUDSprite.Create;
begin
  inherited Create;
  FWidth := 1;
  FHeight := 1;
  FPos := dfVec2f(0, 0);
  FScale := dfVec2f(1, 1);
  FRot := 0.0;
  FPivot := ppTopLeft;
  RecalcCoords();

//  vp := TheRenderer.Camera.GetViewport();
//  FW := vp.W;
//  FH := vp.H;
//  FX := vp.X;
//  FY := vp.Y;
end;

destructor TglrHUDSprite.Destroy;
begin

  inherited;
end;

procedure TglrHUDSprite.DoRender;
begin
  inherited;
//ѕока вывод идет через 2DScene - это не нужно
//  gl.MatrixMode(GL_PROJECTION);
//  gl.PushMatrix();
//  gl.LoadIdentity();
//  vp := TheRenderer.Camera.GetViewport();
//  gl.Ortho(vp.X, vp.W, vp.H, vp.Y, -1, 1);
  gl.MatrixMode(GL_MODELVIEW);
  if FAbsolutePosition then
    gl.LoadIdentity();
  gl.Translatef(FPos.x, FPos.y, 0);
  gl.Rotatef(FRot, 0, 0, 1);
  //gl.Disable(GL_DEPTH_TEST);
  gl.Disable(GL_LIGHTING);
  gl.Beginp(GL_TRIANGLE_STRIP);
    gl.TexCoord2fv(FTexCoords[0]); gl.Vertex3f(FCoords[0].x, FCoords[0].y, FInternalZ);  //gl.Vertex2fv(FCoords[0]);
    gl.TexCoord2fv(FTexCoords[1]); gl.Vertex3f(FCoords[1].x, FCoords[1].y, FInternalZ);  //gl.Vertex2fv(FCoords[1]);
    gl.TexCoord2fv(FTexCoords[2]); gl.Vertex3f(FCoords[2].x, FCoords[2].y, FInternalZ);  //gl.Vertex2fv(FCoords[2]);
    gl.TexCoord2fv(FTexCoords[3]); gl.Vertex3f(FCoords[3].x, FCoords[3].y, FInternalZ);  //gl.Vertex2fv(FCoords[3]);
    gl.TexCoord2fv(FTexCoords[0]); gl.Vertex3f(FCoords[0].x, FCoords[0].y, FInternalZ);  //gl.Vertex2fv(FCoords[0]);
  gl.Endp();

  {Debug - выводим pivot point}
{
  gl.PointSize(5);
  gl.Color3f(1, 1, 1);
  gl.Translatef(-FPos.x, -FPos.y, 0);
  gl.Beginp(GL_POINTS);
    gl.Vertex2fv(FPos);
  gl.Endp();

}

  gl.Enable(GL_LIGHTING);
  //gl.Enable(GL_DEPTH_TEST);
//ѕока вывод идет через 2DScene - это не нужно
//  gl.MatrixMode(GL_PROJECTION);
//  gl.PopMatrix();
  gl.MatrixMode(GL_MODELVIEW);
end;

end.

{

}
unit uHudSprite;

interface

uses
  glrMath, glr, uRenderable;

type

  TglrHUDSprite = class(Tglr2DRenderable, IglrSprite)
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
  FScale := dfVec2f(1, 1);
  FRot := 0.0;
  FPivot := ppTopLeft;
  RecalcCoords();
end;

destructor TglrHUDSprite.Destroy;
begin
  inherited;
end;

procedure TglrHUDSprite.DoRender;
begin
  inherited;
  gl.MatrixMode(GL_MODELVIEW);
  if FAbsolutePosition then
    gl.LoadIdentity();
  //gl.Translatef(FPos.x, FPos.y, 0);
  //gl.Rotatef(FRot, 0, 0, 1);
  gl.Disable(GL_LIGHTING);
  gl.Beginp(GL_TRIANGLE_STRIP);
    gl.TexCoord2fv(FTexCoords[0]); gl.Vertex3f(FCoords[0].x, FCoords[0].y, FPos.z);
    gl.TexCoord2fv(FTexCoords[1]); gl.Vertex3f(FCoords[1].x, FCoords[1].y, FPos.z);
    gl.TexCoord2fv(FTexCoords[2]); gl.Vertex3f(FCoords[2].x, FCoords[2].y, FPos.z);
    gl.TexCoord2fv(FTexCoords[3]); gl.Vertex3f(FCoords[3].x, FCoords[3].y, FPos.z);
    gl.TexCoord2fv(FTexCoords[0]); gl.Vertex3f(FCoords[0].x, FCoords[0].y, FPos.z);
  gl.Endp();
  gl.Enable(GL_LIGHTING);
  gl.MatrixMode(GL_MODELVIEW);
end;

end.

unit uSpace;

interface

uses
  glr, glrMath, ogl;

type
  TpdStar = record
    initial, position: TdfVec3f;
    color: TdfVec4f;
  end;

  TpdSpace = class
  protected
    FRenderer: IglrUserRenderable;
  public
    FStars: array of TpdStar;
    constructor Create(const aLayerCount: Integer); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);
  end;

implementation

uses
  uGlobal;

{ TpdSpace }

procedure Render(); stdcall;
var
  i: Integer;
begin
  gl.Disable(GL_DEPTH_TEST);
  gl.Disable(GL_LIGHTING);
  gl.PointSize(1);

  gl.Beginp(GL_POINTS);
    with space do
      for i := 0 to High(FStars) do
      begin
        gl.Color4fv(FStars[i].color);
        gl.Vertex2fv(dfVec2f(FStars[i].initial - FStars[i].initial.z * (R.Camera.Position)));
      end;
  gl.Endp();

  gl.Enable(GL_LIGHTING);
  gl.Enable(GL_DEPTH_TEST);
end;

constructor TpdSpace.Create(const aLayerCount: Integer);
var
  L, i: Integer;
  z: Single;
begin
  FRenderer := Factory.NewUserRender();
  FRenderer.OnRender := Render;

  L := STARS_PER_LAYER * aLayerCount;
  SetLength(FStars, L);
  for i := 0 to L - 1 do
  begin
    z := ((i + 1) div STARS_PER_LAYER) / aLayerCount;
    FStars[i].initial := dfVec3f(Random(R.WindowWidth), Random(R.WindowHeight), z);
    FStars[i].color := scolorBlue;
  end;

  hudScene.RootNode.AddChild(FRenderer);
end;

destructor TpdSpace.Destroy;
begin
  mainScene.RootNode.RemoveChild(FRenderer);
  inherited;
end;

procedure TpdSpace.Update(const dt: Double);
begin

end;

end.

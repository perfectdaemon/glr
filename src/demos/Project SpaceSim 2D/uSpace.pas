unit uSpace;

interface

uses
  ogl,
  glr,
  glrMath;

type
  TssStar = packed record
    position: TdfVec2f;
    color: TdfVec3f;
    parallaxLevel: Byte;
  end;

procedure InitStars(aParallaxLevels, aCountOnLevelMin,
  aCountOnLevelMax: Integer);

procedure UpdateStars(aCameraPos: TdfVec2f);

procedure RenderStars(); stdcall;

var
  Stars: array of TssStar;
  psize: Single;
  userRender: IglrUserRenderable;
  R: IglrRenderer;

implementation


procedure RenderStars();
var
  i: Integer;
begin
//  gl.MatrixMode(GL_MODELVIEW);
//  gl.LoadIdentity();
//  gl.Disable(GL_DEPTH_TEST);
//  gl.Disable(GL_LIGHTING);
//  gl.PointSize(1);
//
//  gl.Beginp(GL_POINTS);
//    for i := 0 to High(Stars) do
//    begin
//      gl.Color3fv(Stars[i].color);
//      gl.Vertex2fv(Stars[i].position);
//    end;
//  gl.Endp();
//
//  gl.Enable(GL_LIGHTING);
//  gl.Enable(GL_DEPTH_TEST);
//  gl.MatrixMode(GL_PROJECTION);
//  gl.PopMatrix();
//  gl.MatrixMode(GL_MODELVIEW);
end;

procedure InitStars(aParallaxLevels, aCountOnLevelMin,
  aCountOnLevelMax: Integer);
var
  i, j, k: Integer;
  starCount: array of Integer;
  starCountAll: Integer;
begin
  Randomize();
  SetLength(starCount, aParallaxLevels);
  for i := 0 to aParallaxLevels - 1 do
  begin
    starCount[i] := aCountOnLevelMin + Random(aCountOnLevelMax * (i+1) - aCountOnLevelMin);
    starCountAll := starCountAll + starCount[i];
  end;
  SetLength(Stars, starCountAll);
  k := 0;
  for i := 0 to aParallaxLevels - 1 do
  begin
    for j := 0 to starCount[i] - 1 do
    begin
      with Stars[k] do
      begin
        position := dfVec2f(Random(1024), Random(768));
        color := dfVec3f(Random(255)/255, Random(255)/255, Random(255)/255);
        parallaxLevel := i;
      end;
      k := k + 1;
    end;
  end;

  userRender := glrGetObjectFactory().NewUserRender();
  userRender.OnRender := @RenderStars;
end;

procedure UpdateStars(aCameraPos: TdfVec2f);
begin

end;

end.

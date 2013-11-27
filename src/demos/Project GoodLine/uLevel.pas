unit uLevel;

interface

uses
  glr, glrMath, uPhysics2D,
  uTrigger;

type
  TpdLevel = class
  private
    procedure OnLevelEnd(Trigger: TpdTrigger; Catched: Tb2Fixture);
  public
    b2EarthBlocks: array of Tb2Body;
    EarthRenderer: IglrUserRenderable;
    Points: array of TdfVec2f;

    tLevelEnd: TpdTrigger;

    constructor Create();
    destructor Destroy(); override;

    class function LoadFromFile(const aFileName: String): TpdLevel;
    procedure SaveToFile(const aFileName: String);

    function GetLevelMax(): TdfVec2f;
    function GetLevelMin(): TdfVec2f;

    function GetPointIndexAt(aPos: TdfVec2f; aThreshold: TdfVec2f): Integer;
    procedure AddPoint(atPos: TdfVec2f; atIndex: Integer);

    procedure RebuildLevel();
  end;

implementation

uses
  ogl, uBox2DImport,
  uGlobal, uGameScreen.Game;

procedure OnEarthRender(); stdcall;
var
  i: Integer;
begin
  if not Assigned(level) then
    Exit();
  gl.Disable(TGLConst.GL_LIGHTING);
  gl.Enable(TGLConst.GL_BLEND);
  gl.Beginp(TGLConst.GL_LINE_STRIP);
    with colorGreen do
      gl.Color4f(x, y, z, 1);
    for i := 0 to High(level.Points) do
      gl.Vertex3fv(dfVec3f(level.Points[i], Z_LEVEL));

  gl.Endp();
  gl.Enable(TGLConst.GL_LIGHTING);
end;

{ TpdLevel }

procedure TpdLevel.AddPoint(atPos: TdfVec2f; atIndex: Integer);
var
  L: Integer;
begin
  L := Length(Points);
  SetLength(Points, L + 1);
  if atIndex = 0 then
  begin
    Move(Points[0], Points[1], SizeOf(TdfVec2f) * (L - 1));
    Points[0] := atPos;
  end    //*
  else if atIndex = L then
  begin
    Points[L] := atPos;
  end;

end;

constructor TpdLevel.Create;
var
  i: Integer;
begin
  inherited;
  EarthRenderer := Factory.NewUserRender();
  EarthRenderer.OnRender := OnEarthRender;
  mainScene.RootNode.AddChild(EarthRenderer);

//  Earth := Factory.NewSprite();
//  with Earth do
//  begin
//    Position := dfVec3f(500, 400, Z_LEVEL);
//    Width := 1000;
//    Height := 20;
//    Material.Diffuse := colorGreen;
//    PivotPoint := ppCenter;
//  end;
//  mainScene.RootNode.AddChild(Earth);
//
//  dfb2InitBoxStatic(b2world, Earth, 1.0, 0.5, 0.2, $FFFF, $0001, 1);
end;

destructor TpdLevel.Destroy;
begin
//  mainScene.RootNode.RemoveChild(Earth);
  mainScene.RootNode.RemoveChild(EarthRenderer);
  inherited;
end;

function TpdLevel.GetLevelMax: TdfVec2f;
begin
  Result.x := Points[High(Points)].x - 300;
  Result.y := 0;
end;

function TpdLevel.GetLevelMin: TdfVec2f;
begin
  Result.x := 0;
  Result.y := -100;
end;

function TpdLevel.GetPointIndexAt(aPos, aThreshold: TdfVec2f): Integer;
var
  i: Integer;
  aMin, aMax: TdfVec2f;
begin
  Result := -1;
  aMin := aPos - aThreshold;
  aMax := aPos + aThreshold;
  for i := 0 to High(Points) do
    if IsPointInBox(Points[i], aMin, aMax) then
      Exit(i);
end;

class function TpdLevel.LoadFromFile(const aFileName: String): TpdLevel;
var
  f: File;
  Count: Word;
  i: Integer;
begin
  Result := TpdLevel.Create();
  AssignFile(f, aFileName);
  Reset(f, 1);
  BlockRead(f, Count, SizeOf(Word));
  SetLength(Result.Points, Count);
  BlockRead(f, Result.Points[0], SizeOf(TdfVec2f) * Count);
  CloseFile(f);

  with Result do
  begin
    SetLength(b2EarthBlocks, 1);
    RebuildLevel();
    tLevelEnd := triggers.AddBoxTrigger(Points[Low(Points)+1], 150, 130, CAT_PLAYER);
    tLevelEnd.Visible := True;
    tLevelEnd.OnEnter := OnLevelEnd;
  end;
end;

procedure TpdLevel.OnLevelEnd(Trigger: TpdTrigger; Catched: Tb2Fixture);
begin
  game.OnGameOver();
end;

procedure TpdLevel.RebuildLevel;

  procedure SetUserData(forBody: Tb2Body);
  var
    ud: PpdUserData;
  begin
    New(ud);
    ud^.aType := oEarth;
    ud^.aObject := Self;
    forBody.UserData := ud;
  end;

begin
  if Assigned(b2EarthBlocks[0]) then
    b2world.DestroyBody(b2EarthBlocks[0]);

  b2EarthBlocks[0] := dfb2InitChainStatic(b2world, dfVec2f(0, 0), Points,
      1.0, 0.8, 0.1, CAT_PLAYER or CAT_ENEMY, CAT_STATIC, -5);
  SetUserData(b2EarthBlocks[0]);
end;

procedure TpdLevel.SaveToFile(const aFileName: String);
var
  f: File;
  Count: Word;
  i: Integer;
begin
  Count := Length(Points);
  AssignFile(f, aFileName);
  Rewrite(f, 1);
  BlockWrite(f, Count, SizeOf(Word));
  BlockWrite(f, Points[0], SizeOf(TdfVec2f) * Count);
  CloseFile(f);
end;

end.

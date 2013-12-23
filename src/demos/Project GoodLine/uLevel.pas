unit uLevel;

interface

uses
  glr, glrMath, uPhysics2D,
  uTrigger;

const
  TEXT_LEVEL = 'Up, Down Ч ехать'#13#10'Space Ч ручной тормоз'#13#10'ƒовези до финиша как можно больше €щиков';
  TEXT_LEVEL2 = 'M - режим трансмиссии'#13#10'A/Z Ч переключение передач в ручном режиме';

type
  TpdLevel = class
  private
    procedure OnBoxIn(Trigger: TpdTrigger; Catched: Tb2Fixture);
    procedure OnBoxOut(Trigger: TpdTrigger; Catched: Tb2Fixture);
  public
    BoxesIn: Integer;

    b2EarthBlocks: array of Tb2Body;
    b2DynBlocks: array of Tb2Body;
    DynBlocks: array of IglrSprite;
    EarthRenderer: IglrUserRenderable;
    Points: array of TdfVec2f;

    tBoxCounter: TpdTrigger;

    ExplainText, ExplainText2: IglrText;

    constructor Create();
    destructor Destroy(); override;

    class function LoadFromFile(const aFileName: String): TpdLevel;
    procedure SaveToFile(const aFileName: String);

    function GetLevelMax(): TdfVec2f;
    function GetLevelMin(): TdfVec2f;

    function GetPointIndexAt(aPos: TdfVec2f; aThreshold: TdfVec2f): Integer;
    procedure AddPoint(atPos: TdfVec2f; atIndex: Integer); overload;
    procedure AddPoint(atPos: TdfVec2f); overload;

    function GetDynBlocksIndexAt(aPos, aThreshold: TdfVec2f): Integer;
    procedure AddBlock(atPos: TdfVec2f);

    procedure RebuildLevel();

    procedure Update(const dt: Double);

    procedure RemoveAllBlocks();
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
    gl.LineWidth(5);
    with colorOrange do
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
  if (atIndex < L) and (atIndex >= 0) then
  begin
    Move(Points[atIndex], Points[atIndex + 1], SizeOf(TdfVec2f) * (L - atIndex));
    Points[atIndex] := atPos;
  end    //*
  else if atIndex = L then
  begin
    Points[L] := atPos;
  end;

end;

procedure TpdLevel.AddBlock(atPos: TdfVec2f);
var
  L: Integer;
begin
  L := Length(DynBlocks);
  SetLength(DynBlocks, L + 1);
  SetLength(b2DynBlocks, L + 1);
  DynBlocks[L] := Factory.NewSprite();
  with DynBlocks[L] do
  begin
    Material.Texture := atlasMain.LoadTexture(CUBE_TEXTURE);
    Material.Diffuse := colorYellow;
    UpdateTexCoords();
    Width := 24;
    Height := Width;
    PivotPoint := ppCenter;
    Position := dfVec3f(atPos, Z_BLOCKS);
  end;
  mainScene.RootNode.AddChild(DynBlocks[L]);

  b2DynBlocks[L] := dfb2InitBox(b2world, DynBlocks[L], 0.02, 0.4, 0.4, MASK_DYNAMIC, CAT_DYNAMIC, 0);
end;

procedure TpdLevel.AddPoint(atPos: TdfVec2f);
var
  i: Integer;
begin
  for i := 0 to High(Points) - 1 do
    if (atPos.x > Points[i].x) and (atPos.x < Points[i + 1].x) then
    begin
      AddPoint(atPos, i + 1);
      Exit();
    end;
  AddPoint(atPos, High(Points) + 1);
end;

constructor TpdLevel.Create;
begin
  inherited;
  EarthRenderer := Factory.NewUserRender();
  EarthRenderer.OnRender := OnEarthRender;
  mainScene.RootNode.AddChild(EarthRenderer);

  ExplainText := Factory.NewText();
  ExplainText2 := Factory.NewText();

  with ExplainText do
  begin
    Font := fontSouvenir;
    Material.Diffuse := colorWhite;
    Text := TEXT_LEVEL;
    Position := dfVec3f(400, 200, Z_BACKGROUND + 5);
  end;

  with ExplainText2 do
  begin
    Font := fontSouvenir;
    Material.Diffuse := colorWhite;
    Text := TEXT_LEVEL2;
    Position := dfVec3f(1200, 200, Z_BACKGROUND + 5);
  end;

  mainScene.RootNode.AddChild(ExplainText);
  mainScene.RootNode.AddChild(ExplainText2);
end;

destructor TpdLevel.Destroy;
begin
//  mainScene.RootNode.RemoveChild(Earth);
  mainScene.RootNode.RemoveChild(EarthRenderer);
  inherited;
end;

function TpdLevel.GetDynBlocksIndexAt(aPos, aThreshold: TdfVec2f): Integer;
begin

end;

function TpdLevel.GetLevelMax: TdfVec2f;
begin
  Result.x := Points[High(Points)].x - 300;
  Result.y := Points[High(Points)].y;
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
  dyn: array of TdfVec2f;
begin
  Result := TpdLevel.Create();
  AssignFile(f, aFileName);
  Reset(f, 1);
  BlockRead(f, Count, SizeOf(Word));
  SetLength(Result.Points, Count);
  BlockRead(f, Result.Points[0], SizeOf(TdfVec2f) * Count);

  BlockRead(f, Count, SizeOf(Word));
  SetLength(dyn, Count);
  BlockRead(f, Dyn[0], SizeOf(TdfVec2f) * Count);
  CloseFile(f);

  with Result do
  begin
    SetLength(b2EarthBlocks, 1);
    RebuildLevel();
    tBoxCounter := triggers.AddBoxTrigger(Points[High(Points)] + dfVec2f(-130, 110), 250, 220, MASK_SENSOR, True);
    tBoxCounter.Visible := True;
    tBoxCounter.OnEnter := OnBoxIn;
    tBoxCounter.OnLeave := OnBoxOut;
    for i := 0 to Count - 1 do
      AddBlock(dyn[i]);
  end;
end;

procedure TpdLevel.OnBoxIn(Trigger: TpdTrigger; Catched: Tb2Fixture);
begin
  Inc(BoxesIn);
end;

procedure TpdLevel.OnBoxOut(Trigger: TpdTrigger; Catched: Tb2Fixture);
begin
  Dec(BoxesIn);
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
      1.0, 0.8, 0.1, MASK_EARTH, CAT_STATIC, 0);
  SetUserData(b2EarthBlocks[0]);
end;

procedure TpdLevel.RemoveAllBlocks;
var
  i: Integer;
begin
  for i := 0 to High(DynBlocks) do
  begin
    mainScene.RootNode.RemoveChild(DynBlocks[i]);
    b2world.DestroyBody(b2DynBlocks[i]);
  end;
  SetLength(DynBlocks, 0);
  SetLength(b2DynBlocks, 0);
end;

procedure TpdLevel.SaveToFile(const aFileName: String);
var
  f: File;
  Count, DynCount: Word;
  i: Integer;
  dyn: array of TdfVec2f;
begin
  Count := Length(Points);
  DynCount := Length(DynBlocks);
  SetLength(dyn, DynCount);
  for i := 0 to DynCount - 1 do
    dyn[i] := DynBlocks[i].Position2D;
  AssignFile(f, aFileName);
  Rewrite(f, 1);
  BlockWrite(f, Count, SizeOf(Word));
  BlockWrite(f, Points[0], SizeOf(TdfVec2f) * Count);
  BlockWrite(f, DynCount, SizeOf(Word));
//  BlockWrite(f, dyn[0], SizeOf(TdfVec2f) * DynCount);
  CloseFile(f);
end;

procedure TpdLevel.Update(const dt: Double);
var
  i: Integer;
begin
  for i := 0 to High(DynBlocks) do
    SyncObjects(b2DynBlocks[i], DynBlocks[i]);
end;

end.

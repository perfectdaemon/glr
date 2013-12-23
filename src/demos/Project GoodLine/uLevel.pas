unit uLevel;

interface

uses
  glr, glrMath, uPhysics2D,
  uTrigger;

const
  TIMER = 130;

  TEXT_LEVEL = 'Left, Right Ч ехать или тормозить'#13#10 +
    'Space Ч ручной тормоз (заднее колесо)'#13#10 +
    'Tab Ч Ђ—броситьї машину у старта'#13#10#13#10 +

    'ƒотолкай до финиша как можно больше €щиков'#13#10'за отведенное врем€';

  TEXT_LEVEL2 = 'M Ч режим трансмиссии'#13#10 +
    'A/Z Ч переключение передач в ручном режиме';

  TEXT_LEVEL3 = 'ћожно сделать несколько заходов,'#13#10 +
    'пока есть врем€.'#13#10 +
    'Tab Ч Ђ—броситьї машину у старта';

type
  TpdLevel = class
  private
    procedure OnBoxIn(Trigger: TpdTrigger; Catched: Tb2Fixture);
    procedure OnBoxOut(Trigger: TpdTrigger; Catched: Tb2Fixture);
    procedure OnTimerEnter(Trigger: TpdTrigger; Catched: Tb2Fixture);
  public
    IsTimerStarted, FirstTime: Boolean;
    TimeLeft: Double;
    BoxesIn: Integer;

    b2EarthBlocks: array of Tb2Body;
    b2DynBlocks: array of Tb2Body;
    DynBlocks: array of IglrSprite;
    EarthRenderer: IglrUserRenderable;
    Points: array of TdfVec2f;

    tBoxCounter, tTimerStart: TpdTrigger;

    ExplainText, ExplainText2, ExplainText3, StartText: IglrText;

    constructor Create();
    destructor Destroy(); override;

    class function LoadFromFile(const aFileName: String): TpdLevel;
    procedure SaveToFile(const aFileName: String);

    function GetLevelMax(): TdfVec2f;
    function GetLevelMin(): TdfVec2f;

    //Editor features
    function GetPointIndexAt(aPos: TdfVec2f; aThreshold: TdfVec2f): Integer;
    procedure AddPoint(atPos: TdfVec2f; atIndex: Integer); overload;
    procedure AddPoint(atPos: TdfVec2f); overload;
    function GetDynBlocksIndexAt(aPos, aThreshold: TdfVec2f): Integer;
    procedure AddBlock(atPos: TdfVec2f);
    procedure RemoveAllBlocks();

    procedure RebuildLevel();

    procedure Update(const dt: Double);

    procedure TimerStart();
    procedure TimerEnd();
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
  if atPos.x > Points[High(Points)].x then
    AddPoint(atPos, High(Points) + 1)
  else
    AddPoint(atPos, 0);
end;

constructor TpdLevel.Create;
begin
  inherited;
  EarthRenderer := Factory.NewUserRender();
  EarthRenderer.OnRender := OnEarthRender;
  mainScene.RootNode.AddChild(EarthRenderer);

  ExplainText := Factory.NewText();
  ExplainText2 := Factory.NewText();
  ExplainText3 := Factory.NewText();
  StartText := Factory.NewText();

  with ExplainText do
  begin
    Font := fontSouvenir;
    Material.Diffuse := colorWhite;
    Text := TEXT_LEVEL;
    Position := dfVec3f(400, 250, Z_BACKGROUND + 5);
  end;

  with ExplainText2 do
  begin
    Font := fontSouvenir;
    Material.Diffuse := colorWhite;
    Text := TEXT_LEVEL2;
    Position := dfVec3f(1200, 250, Z_BACKGROUND + 5);
  end;

  with ExplainText3 do
  begin
    Font := fontSouvenir;
    Material.Diffuse := colorWhite;
    Text := TEXT_LEVEL3;
    PivotPoint := ppCenter;
    //Set position after load level
    //Position := dfVec3f(1200, 250, Z_BACKGROUND + 5);
  end;

  with StartText do
  begin
    Font := fontSouvenir;
    Material.Diffuse := colorWhite;
    Text := '—тарт';
    Position := dfVec3f(350, 540, Z_BACKGROUND + 5);
  end;

  mainScene.RootNode.AddChild(ExplainText);
  mainScene.RootNode.AddChild(ExplainText2);
  mainScene.RootNode.AddChild(ExplainText3);
  mainScene.RootNode.AddChild(StartText);

  IsTimerStarted := False;
  FirstTime := True;
end;

destructor TpdLevel.Destroy;
begin
  mainScene.RootNode.RemoveChild(EarthRenderer);
  tBoxCounter.Free();
  tTimerStart.Free();
  b2world.DestroyBody(b2EarthBlocks[0]);
  RemoveAllBlocks();
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

    tTimerStart := triggers.AddBoxTrigger(Points[6] - dfVec2f(0, 50), 10, 100, CAT_PLAYER, True);
    tTimerStart.Visible := True;
    tTimerStart.OnEnter := OnTimerEnter;
    for i := 0 to Count - 1 do
      AddBlock(dyn[i]);

    ExplainText3.Position := dfVec3f(tBoxCounter.Sprite.Position2D + dfVec2f(0, -310), Z_BACKGROUND - 5);
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

procedure TpdLevel.OnTimerEnter(Trigger: TpdTrigger; Catched: Tb2Fixture);
begin
  if FirstTime then
  begin
    TimerStart();
    FirstTime := False;
  end;
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
    if Assigned(b2DynBlocks[i]) then
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
  BlockWrite(f, dyn[0], SizeOf(TdfVec2f) * DynCount);
  CloseFile(f);
end;

procedure TpdLevel.TimerEnd;
begin
  IsTimerStarted := False;
  game.OnGameOver();
end;

procedure TpdLevel.TimerStart;
begin
  TimeLeft := TIMER;
  IsTimerStarted := True;
end;

procedure TpdLevel.Update(const dt: Double);
var
  i: Integer;
begin
  if IsTimerStarted then
  begin
    TimeLeft := TimeLeft - dt;
    if TimeLeft <= 0 then
      TimerEnd();
  end;

  for i := 0 to High(DynBlocks) do
    if Assigned(b2DynBlocks[i]) then
    begin
      SyncObjects(b2DynBlocks[i], DynBlocks[i]);
      if DynBlocks[i].Position.y > 1000 then
      begin
        b2world.DestroyBody(b2DynBlocks[i]);
        b2DynBlocks[i] := nil;
        mainScene.RootNode.RemoveChild(DynBlocks[i]);
      end;
    end;

end;

end.

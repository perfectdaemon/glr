unit uLevel;

interface

uses
  glr, glrMath,
  uArrow;

const
  MAGIC: Word = $AF32;

type
  TpdLevel = class
  private
    FEditorMode: Boolean;
    CloudsInitial: array of TdfVec3f;
    procedure SetEditorMode(const Value: Boolean);
  public
    Arrow: TpdArrow;
    Target: IglrSprite;
    Walls, Clouds: array of IglrSprite;

    //Helpers for level editor
    SprStartPos, SprMoveDir: IglrSprite;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure LoadFromFile(const aFileName: WideString);
    procedure SaveToFile(const aFileName: WideString);

    procedure GenerateClouds();
    procedure AddWall(const aPos: TdfVec2f);
    procedure RemoveWall(Index: Integer);

    procedure Update(const dt: Double);

    property EditorMode: Boolean read FEditorMode write SetEditorMode;
  end;

implementation

uses
  uGlobal;

{ TpdLevel }

procedure TpdLevel.AddWall(const aPos: TdfVec2f);
var
  i: Integer;
begin
  i := Length(Walls);
  SetLength(Walls, i + 1);
  Walls[i] := Factory.NewSprite();
  with Walls[i] do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(WALL_TEXTURE);
    Material.Diffuse := colorWhite;
    SetSizeToTextureSize();
    UpdateTexCoords();

    Position := dfVec3f(aPos, Z_WALLS);
  end;
  mainScene.RootNode.AddChild(Walls[i]);
end;

constructor TpdLevel.Create;
begin
  inherited;
  Target := Factory.NewSprite();
  with Target do
  begin
    PivotPoint := ppCenter;
    Material.Texture := atlasMain.LoadTexture(TARGET_TEXTURE);
    Material.Diffuse := colorWhite;
    SetSizeToTextureSize();
    UpdateTexCoords();
    Position := dfVec3f(0, 0, Z_TARGET);
  end;

  SprStartPos := Factory.NewHudSprite();
  with SprStartPos do
  begin
    PivotPoint := ppCenter;
    Width := 20;
    Height := 20;
    Material.Diffuse := colorRed;

    Visible := False;
  end;

  SprMoveDir := Factory.NewHudSprite();
  with SprMoveDir do
  begin
    PivotPoint := ppCenter;
    Width := 100;
    Height := 10;
    Material.Diffuse := colorRed;

    Visible := False;
  end;

  mainScene.RootNode.AddChild(Target);
  Arrow := TpdArrow.Create();

  mainScene.RootNode.AddChild(SprStartPos);
  mainScene.RootNode.AddChild(SprMoveDir);
end;

destructor TpdLevel.Destroy;
var
  i: Integer;
begin
  Arrow.Free();
  for i := 0 to Length(Walls) - 1 do
    mainScene.RootNode.RemoveChild(Walls[i]);
  inherited;
end;

procedure TpdLevel.GenerateClouds;
var
  count, i: Integer;
begin
  count := 15 + Random(15);
  SetLength(Clouds, count);
  SetLength(CloudsInitial, count);
  for i := 0 to count - 1 do
  begin
    CloudsInitial[i] := dfVec3f(
      50 + Random(R.WindowWidth - 50),
      Arrow.StartPos.y + 400 - Random(Abs(Round(Target.Position.y - Arrow.StartPos.y)) + 400),
      Z_CLOUDS + Random(2));
    Clouds[i] := Factory.NewSprite();
    with Clouds[i] do
    begin
      PivotPoint := ppCenter;
      Material.Texture := atlasMain.LoadTexture(CLOUD_TEXTURE);
      UpdateTexCoords();
      SetSizeToTextureSize();
      Position := CloudsInitial[i];
      ScaleMult(0.5 + 2.0 * Random());
      Material.PDiffuse.w := 0.1 + 0.5 * Random();
    end;
    mainScene.RootNode.AddChild(Clouds[i]);
  end;
end;

procedure TpdLevel.LoadFromFile(const aFileName: WideString);
var
  f: File;
  wordBuffer: Word;
  vec2fBuffer: TdfVec2f;
  i: Integer;
begin
  AssignFile(f, aFileName);
  Reset(f, 1);

  BlockRead(f, wordBuffer, SizeOf(Word));
  Assert(wordBuffer = MAGIC, aFileName + ' is not a level file');

  //Target pos
  BlockRead(f, vec2fBuffer, SizeOf(TdfVec2f));
  Target.Position := dfVec3f(vec2fBuffer, Z_TARGET);

  //Arrow start pos and start move dir
  with Arrow do
  begin
    BlockRead(f, vec2fBuffer, SizeOf(TdfVec2f));
    Sprite.Position2D := vec2fBuffer;
    StartPos := vec2fBuffer;
    BlockRead(f, vec2fBuffer, SizeOf(TdfVec2f));
    MoveDir := vec2fBuffer;
  end;

  //Walls
  BlockRead(f, wordBuffer, SizeOf(Word));
  SetLength(Walls, wordBuffer);
  for i := 0 to Length(Walls) - 1 do
  begin
    Walls[i] := Factory.NewSprite();
    with Walls[i] do
    begin
      PivotPoint := ppCenter;
      Material.Texture := atlasMain.LoadTexture(WALL_TEXTURE);
      Material.Diffuse := colorWhite;
      SetSizeToTextureSize();
      UpdateTexCoords();

      BlockRead(f, vec2fBuffer, SizeOf(TdfVec2f));

      Position := dfVec3f(vec2fBuffer, Z_WALLS);
    end;
    mainScene.RootNode.AddChild(Walls[i]);
  end;

  CloseFile(f);
end;

procedure TpdLevel.RemoveWall(Index: Integer);
begin
  mainScene.RootNode.RemoveChild(Walls[Index]);
  Walls[Index] := nil;
  Move(Walls[Index + 1], Walls[Index], Length(Walls) - Index - 1);
  SetLength(Walls, Length(Walls) - 1);
end;

procedure TpdLevel.SaveToFile(const aFileName: WideString);
var
  f: File;
  count: Word;
  targetPos, arrowPos, arrowMoveDir: TdfVec2f;
  wallsPos: array of TdfVec2f;
  i: Integer;
begin
  AssignFile(f, aFileName);
  Rewrite(f, 1);

  Assert(Assigned(Target), 'Target for level is not set');
  Assert(Assigned(Arrow), 'Arrow params for level is not set');

  count := Length(Walls);
  SetLength(wallsPos, count);
  for i := 0 to count - 1 do
    wallsPos[i] := Walls[i].Position2D;
  targetPos := Target.Position2D;
  arrowPos := Arrow.Sprite.Position2D;
  arrowMoveDir := Arrow.MoveDir;

  BlockWrite(f, MAGIC, SizeOf(Word));
  BlockWrite(f, targetPos, SizeOf(TdfVec2f));
  BlockWrite(f, arrowPos, SizeOf(TdfVec2f));
  BlockWrite(f, arrowMoveDir, SizeOf(TdfVec2f));
  BlockWrite(f, count, SizeOf(Word));
  BlockWrite(f, wallsPos[0], SizeOf(TdfVec2f) * count);

  CloseFile(f);
end;

procedure TpdLevel.SetEditorMode(const Value: Boolean);
begin
  FEditorMode := Value;
  SprStartPos.Visible := Value;
  SprMoveDir.Visible := Value;
end;

procedure TpdLevel.Update(const dt: Double);
var
  i: Integer;
begin
  if not FEditorMode then
  begin
    Arrow.Update(dt);
    for i := 0 to High(Clouds) do
    begin
      Clouds[i].Position2D := dfVec2f(CloudsInitial[i] - (CloudsInitial[i].z - Z_CLOUDS) * (R.Camera.Position));
    end;
  end
  else
  begin

  end;
end;

end.

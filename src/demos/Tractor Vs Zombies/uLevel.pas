{
  TODO: почистить ненужный код в (* *)
}

unit uLevel;

interface

uses
  Windows, SysUtils, Classes,

  dfHRenderer, dfMath,

  UPhysics2D;

type
  TtzBlock = record
    b2Body: Tb2Body;
    glSprite: IglrSprite;
  end;

  TtzLevel = class
  private
    FBlocks: array of TtzBlock;
    FLevelBorders: array[0..2] of Tb2Body;
    FLevelNode: IglrNode;
    FPlayerPosition: TdfVec2f;
  protected
  public
    constructor Create(RootNode: IglrNode); virtual;
    destructor Destroy(); override;

    procedure Update(const dt: Double);

    procedure LoadFromFile(aFileName: String);
    procedure SaveToFile(aFileName: String);

    procedure Clear();

    property PlayerStartPosition: TdfVec2f read FPlayerPosition;

    {DEBUG!!}
    procedure SetBlocks();
    procedure SetBlocks2();
  end;

implementation

uses
  uBox2DImport, uUtils, uSingletons, uMainFunctions,

  uLevel_SaveLoad;

{ TtzLevel }

procedure TtzLevel.Clear;
var
  i: Integer;
begin
  SetLength(FBlocks, 0);
  for i := 0 to High(FLevelBorders) do
    if Assigned(FLevelBorders[i]) then
      vb2World.DestroyBody(FLevelBorders[i]);
end;

constructor TtzLevel.Create(RootNode: IglrNode);
begin
  inherited Create();
  FLevelNode := RootNode.AddNewChild();
end;

destructor TtzLevel.Destroy;
begin

  inherited;
end;


procedure TtzLevel.LoadFromFile(aFileName: String);

  procedure CreateBlock(aIndex: Integer; blockRec: TTZLBlockRec);
  begin
    with FBLocks[aIndex], blockRec do
    begin
      glSprite := dfNewSpriteWithNode(FLevelNode);
      SetSpriteParams(glSprite, aPos, aSize.x, aSize.y, aRot, dfVec4f(0.1, 0.5, 0.1, 1), ppCenter);
      b2Body := dfb2InitBoxStatic(vb2World, glSprite, 1, 1, 0, $0004, $0002, 1)
    end;
  end;

var
  tzlFile: TTZLFile;
  i: Integer;
begin
  Clear();
  tzlFile := TTZLFile.LoadFromFile(aFileName);
  SetLength(FBlocks, Length(tzlFile.Blocks));
  for i := 0 to Length(FBlocks) - 1 do
    CreateBlock(i, tzlFile.Blocks[i]);

  FPlayerPosition := tzlFile.Player.aPos;

  //TODO: Считывать землю

  tzlFile.Free;
end;

(*
procedure TtzLevel.LoadFromFile(aFileName: String);

  procedure CreateBlock(bl_rec: TTZLBlockRec);
  var
    ind: Integer;
  begin
    ind := Length(FBlocks);
    SetLength(FBlocks, ind + 1);
    with FBLocks[ind], bl_rec do
    begin
      glSprite := dfNewSpriteWithNode(FLevelNode);
      SetSpriteParams(glSprite, aPos, aSize.x, aSize.y, aRot, dfVec4f(0.1, 0.5, 0.1, 1), ppCenter);
      b2Body := dfb2InitBoxStatic(vb2World, glSprite, 1, 1, 0, $0004, $0002)
    end;
  end;

var
  fs: TFileStream;
  _type: Word;
  bl_rec: TTZLBlockRec;
begin
  Clear();
  //Без верха
  {init borders}
  FLevelBorders[0] := dfb2InitBoxStatic(vb2World, dfVec2f(0, 300), dfVec2f(5, 600), 0, 1, 1, 0, $0004, $0002);
  FLevelBorders[1] := dfb2InitBoxStatic(vb2World, dfVec2f(800, 300), dfVec2f(5, 600), 0, 1, 1, 0, $0004, $0002);
  FLevelBorders[2] := dfb2InitBoxStatic(vb2World, dfVec2f(400, 600), dfVec2f(800, 2), 0, 1, 1, 0, $0004, $0002);

  fs := TFileStream.Create(aFileName, fmOpenRead);
  if fs.Handle = INVALID_HANDLE_VALUE then
  begin
    MessageBox(0, PChar('Error loading level from ' + aFile), PChar('uLevel unit'), MB_OK);
    Exit();
  end;
  while fs.Position < fs.Size do
  begin
    fs.Read(_type, SizeOf(Word));
    if _type = LEVEL_BLOCK then
    begin
      fs.Read(bl_rec, SizeOf(TtzBlockRec));
      CreateBlock(bl_rec);
    end;
  end;
  fs.Free;
end;

*)

(*

procedure TtzLevel.SaveToFile(aFileName: String);

  procedure WriteBlock(F: THandle; aBlock: TtzBlock);
  var
    _type: Word;
    bytes_written: Cardinal;
    bl_rec: TtzBlockRec;
  begin
    with aBlock.b2Body, aBlock.glSprite do
    begin
      with bl_rec do
      begin
        aPos := Position;
        aSize := dfVec2f(Width, Height);
        aRot := Rotation;
      end;
      _type := LEVEL_BLOCK;
      WriteFile(f, _type, SizeOf(Word), bytes_written, nil);
      WriteFile(f, bl_rec, SizeOf(bl_rec), bytes_written, nil);
    end;
  end;

var
  f: THandle;
  i: Integer;
begin
  f := CreateFile(PChar(aFile), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then
  begin
    MessageBox(0, PChar('Error saving level into ' + aFile), PChar('uLevel unit'), MB_OK);
    Exit();
  end;
  for i := Low(FBlocks) to High(FBlocks) do
    WriteBlock(F, FBlocks[i]);
  CloseHandle(f);
end;
*)

//procedure TtzLevel.SaveToFile(aFile: String);
//
////function SetBuffer(aBlock: TtzBlock): String;
////begin
////  with aBlock.b2Body, aBlock.glSprite do
////    Result := 'block ' +
////    {coords} FloatToStr(Position.x) + ' ' + FloatToStr(Position.y) + ' ' +
////    {rotation} FloatToStr(Rotation) + ' ' +
////    {size} FloatToStr(Width) + ' ' + FloatToStr(Height) + #13#10;
////end;
//
//var
////  f: THandle;
//  i: Integer;
//  fs: TFileStream;
////  bytes_written: Cardinal;
//  buffer: String;
//begin
//  fs := TFileStream.Create(aFile, fmOpenWrite);
//  fs.Seek(0, soFromBeginning);
//  for i := Low(FBlocks) to High(FBlocks) do
//  begin
//    buffer := SetBuffer(FBlocks[i]);
//    fs.WriteBuffer(buffer[1], SizeOf(buffer[1]) * Length(buffer));
//  end;
//  fs.Free;
////    f := CreateFile(PChar(aFile), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
////    if f = INVALID_HANDLE_VALUE then
////    begin
////      MessageBox(0, PChar('Error saving level into ' + aFile), PChar('uLevel unit'), MB_OK);
////      Exit();
////    end;
////  try
////    for i := Low(FBlocks) to High(FBlocks) do
////    begin
////      buffer := SetBuffer(FBlocks[i]);
////      WriteFile(f, buffer[1], SizeOf(buffer[1]) * Length(buffer), bytes_written, nil);
////    end;
////  finally
////    CloseHandle(f);
////  end;
//end;

procedure TtzLevel.SaveToFile(aFileName: String);
//var
//  tzlFile: TTZLFile;
begin
//  tzlFile := TTZLFile.Create();
//
//  tzlFile.SaveToFile(aFileName);
//  tzlFile.Free;
end;

procedure TtzLevel.SetBlocks;
begin
  //Без верха
  {init borders}
  FLevelBorders[0] := dfb2InitBoxStatic(vb2World, dfVec2f(0, 300), dfVec2f(5, 600), 0, 1, 1, 0, $0004, $0002, 1);
  FLevelBorders[1] := dfb2InitBoxStatic(vb2World, dfVec2f(800, 300), dfVec2f(5, 600), 0, 1, 1, 0, $0004, $0002, 1);
  FLevelBorders[2] := dfb2InitBoxStatic(vb2World, dfVec2f(400, 600), dfVec2f(800, 2), 0, 1, 1, 0, $0004, $0002, 1);

  SetLength(FBlocks, 3);

  FBlocks[0].glSprite := dfNewSpriteWithNode(vRootNode);
  SetSpriteParams(FBlocks[0].glSprite, dfVec2f(100, 120), 200, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
  FBlocks[0].b2Body := dfb2InitBoxStatic(vb2World, FBlocks[0].glSprite, 1, 1, 0, $0004, $0002, 1);

  FBlocks[1].glSprite := dfNewSpriteWithNode(vRootNode);
  SetSpriteParams(FBlocks[1].glSprite, dfVec2f(400, 180), 200, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
  FBlocks[1].b2Body := dfb2InitBoxStatic(vb2World, FBlocks[1].glSprite, 1, 1, 0, $0004, $0002, 1);

  FBlocks[2].glSprite := dfNewSpriteWithNode(vRootNode);
  SetSpriteParams(FBlocks[2].glSprite, dfVec2f(350, 380), 680, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
  FBlocks[2].b2Body := dfb2InitBoxStatic(vb2World, FBlocks[2].glSprite, 1, 1, 0, $0004, $0002, 1);
end;

procedure TtzLevel.SetBlocks2();
begin
  //Без верха
  {init borders}
  FLevelBorders[0] := dfb2InitBoxStatic(vb2World, dfVec2f(0, 300), dfVec2f(5, 600), 0, 1, 1, 0, $0004, $0002, 1);
//  FLevelBorders[1] := dfb2InitBoxStatic(vb2World, dfVec2f(800, 300), dfVec2f(5, 600), 0, 1, 1, 0, $0004, $0002, 1);
  FLevelBorders[2] := dfb2InitBoxStatic(vb2World, dfVec2f(400, 600), dfVec2f(800, 2), 0, 1, 1, 0, $0004, $0002, 1);

  SetLength(FBlocks, 1);

  FBlocks[0].glSprite := dfNewSpriteWithNode(vRootNode);
  SetSpriteParams(FBlocks[0].glSprite, dfVec2f(350, 380), 1024, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
  FBlocks[0].b2Body := dfb2InitBoxStatic(vb2World, FBlocks[0].glSprite, 1, 1, 0, $0004, $0002, 1);

//  FBlocks[1].glSprite := dfNewSpriteWithNode(vRootNode);
//  SetSpriteParams(FBlocks[1].glSprite, dfVec2f(400, 180), 200, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
//  FBlocks[1].b2Body := dfb2InitBoxStatic(vb2World, FBlocks[1].glSprite, 1, 1, 0, $0004, $0002, 1);
//
//  FBlocks[2].glSprite := dfNewSpriteWithNode(vRootNode);
//  SetSpriteParams(FBlocks[2].glSprite, dfVec2f(350, 380), 680, 20, 0, dfVec4f(0.3, 0.8, 0.3, 1), ppCenter);
//  FBlocks[2].b2Body := dfb2InitBoxStatic(vb2World, FBlocks[2].glSprite, 1, 1, 0, $0004, $0002, 1);
end;

procedure TtzLevel.Update(const dt: Double);
begin

end;

end.

unit uGame;

interface

uses
  Contnrs,
  glr, glrMath, uPhysics2D;

const
  WORDS: array[0..51] of WideString =
  (
  'buy it', 'use it', 'break it', 'fix it',
  'trash it', 'change it', 'mail - upgrade it',
  'charge it', 'point it', 'zoom it', 'press it',
  'snap it', 'work it', 'quick - erase it',
  'write it', 'cut it', 'paste it', 'save it',
  'load it', 'check it', 'quick - rewrite it',
  'plug it', 'play it', 'burn it', 'rip it',
  'drag and drop it', 'zip - unzip it',
  'lock it', 'fill it', 'call it', 'find it',
  'view it', 'code it', 'jam - unlock it',
  'surf it', 'scroll it', 'pause it, click it',
  'cross it', 'crack it', 'switch - update it',
  'name it', 'rate it', 'tune it, print it',
  'scan it', 'send it', 'fax - rename it',
  'touch it', 'bring it', 'pay it, watch it',
  'turn it', 'leave it', 'start - format it'
  );

type
  TpdBlock = class
  private
    FText: IglrText;
    FBody: Tb2Body;
    function GetText(): String;
  public
    class function InitBlock(aText: String; aPos: TdfVec2f; aRot: Single): TpdBlock;

    constructor Create();
    destructor Destroy(); override;
    procedure Update(const dt: Double);

    property Text: String read GetText;
  end;

  TpdGame = class
  private
    t, period: Double;
    FBlocks: TObjectList;
    procedure InitPhysics();
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Update(const dt: Double);
    procedure OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
    procedure OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState);
    procedure OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState);
  end;

implementation

uses
  uGlobal, uBox2DImport, UPhysics2DTypes;

{ TpdGame }

constructor TpdGame.Create;
begin
  inherited;
  FBlocks := TObjectList.Create();
  InitPhysics();
  period := 2;
end;

destructor TpdGame.Destroy;
begin
  FBlocks.Free();
  b2world.Free();
  inherited;
end;

procedure TpdGame.InitPhysics();
var
  mask: Word;
begin
  if Assigned(b2world) then
    b2world.Free();
  b2world := Tglrb2World.Create(TVector2.From(0, 9.8), True, 1 / 60, 8);

  mask := CAT_STATIC or CAT_BLOCK;

  //left, right, bottom, top
  dfb2InitBoxStatic(b2world, dfVec2f(0, R.WindowHeight div 2), dfVec2f(6, R.WindowHeight), 0, 1, 1, 0, mask, CAT_STATIC, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth, R.WindowHeight div 2), dfVec2f(6, R.WindowHeight), 0, 1, 1, 0, mask, CAT_STATIC, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth div 2, R.WindowHeight), dfVec2f(R.WindowWidth, 10), 0, 1, 1, 0, mask, CAT_STATIC, 0);
  dfb2InitBoxStatic(b2world, dfVec2f(R.WindowWidth div 2, 0), dfVec2f(R.WindowWidth, 10), 0, 1, 1, 0, mask, CAT_STATIC, 0);
end;

procedure TpdGame.OnMouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin

end;

procedure TpdGame.OnMouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin

end;

procedure TpdGame.OnMouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin

end;

procedure TpdGame.Update(const dt: Double);
var
  i: Integer;
begin
  b2world.Update(dt);
  for i := 0 to FBlocks.Count - 1 do
    (FBlocks[i] as TpdBlock).Update(dt);

  t := t + dt;
  if t > period then
  begin
    t := 0;
    FBlocks.Add(TpdBlock.InitBlock(WORDS[Random(Length(Words))], dfVec2f(100 + Random(700), 30), -90 + Random(180)));
  end;

end;

{ TpdBlock }

constructor TpdBlock.Create();
begin
  inherited;
  FText := Factory.NewText();
end;

destructor TpdBlock.Destroy;
begin
  mainScene.RootNode.RemoveChild(FText);
  b2world.DestroyBody(FBody);
  inherited;
end;

function TpdBlock.GetText: String;
begin
  Result := FText.Text;
end;

class function TpdBlock.InitBlock(aText: String; aPos: TdfVec2f;
  aRot: Single): TpdBlock;
var
  color: TdfVec4f;
begin
  Result := TpdBlock.Create();
  with Result do
  begin
    with FText do
    begin
      Font := fontBaltica;
      Text := aText;
      color := dfVec4f(Random(360), 90 + Random(10), 90 + Random(10) ,1);
      color := Hsva2Rgba(color);
//      Material.Diffuse := colors[Random(Length(colors))];
      Material.Diffuse := color;
      PivotPoint := ppCenter;
      Position := dfVec3f(aPos, Z_BLOCKS);
    end;
    mainScene.RootNode.AddChild(FText);

    FBody := dfb2InitBox(b2world, aPos, dfVec2f(FText.Width, FText.Height), aRot,
      1.0, 0.5, 0.5, CAT_BLOCK or CAT_STATIC, CAT_BLOCK, 0);
  end;
end;

procedure TpdBlock.Update(const dt: Double);
begin
  SyncObjects(FBody, FText);
end;

end.

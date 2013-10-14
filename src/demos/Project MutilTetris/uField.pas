unit uField;

interface

uses
  glr, glrMath;

const
  FIELD_SIZE_X = 24; //Размеры поля в клетках
  FIELD_SIZE_Y = 24;

  CELL_SIZE_X = 24; //Размер клетки в пикселях
  CELL_SIZE_Y = 24;
  CELL_SPACE  = 2;

  BLOCK_CENTER_X = 1; //Центр фигуры в матрице в координатах 0..3
  BLOCK_CENTER_Y = 1;

  SPEED_START = 3; //1 cell per second

type
  TpdBlockOrigin = (boRight, boLeft, boTop, boBottom);

  TpdBlock = class
  private
    procedure CalcBounds();
  public
    Matrices: array of array[0..3, 0..3] of Integer;
    Color: TdfVec4f;
    X, Y: Integer;
    RotateIndex: Integer;
    MoveDirection: TpdBlockOrigin;
    Bounds: array of TglrBBi;
    class function CreateRandomBlock(): TpdBlock;
    procedure Rotate();
  end;

  TpdField = class
  private
    timeToMove: Single;
    function IsInBounds(X, Y: Integer): Boolean;
    procedure RedrawField(const dt: Double);
    procedure PlayerControl(const dt: Double);
    procedure MoveCurrentBlock(const dt: Double);
  public
    CurrentBlock: TpdBlock;
    CurrentSpeed: Single;
    F: array[0..FIELD_SIZE_X - 1, 0..FIELD_SIZE_Y - 1] of Integer;
    Sprites: array[0..FIELD_SIZE_X - 1, 0..FIELD_SIZE_Y - 1] of IglrSprite;
    cross: IglrUserRenderable;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure AddBlock(Origin: TpdBlockOrigin);
    procedure Update(const dt: Double);
  end;

implementation

uses
  ogl,
  Windows, SysUtils,
  uGlobal;

const
  CROSS_LINE_WIDTH = 4;

  cI1 = '0000'+'1111'+'0000'+'0000';
  cI2 = '0100'+'0100'+'0100'+'0100';
  cT1 = '0000'+'1110'+'0100'+'0000';
  cT2 = '0100'+'1100'+'0100'+'0000';
  cT3 = '0100'+'1110'+'0000'+'0000';
  cT4 = '0100'+'0110'+'0100'+'0000';
  cL1 = '0000'+'1110'+'1000'+'0000';
  cL2 = '1100'+'0100'+'0100'+'0000';
  cL3 = '0010'+'1110'+'0000'+'0000';
  cL4 = '0100'+'0100'+'0110'+'0000';
  cJ1 = '1000'+'1110'+'0000'+'0000';
  cJ2 = '0110'+'0100'+'0100'+'0000';
  cJ3 = '0000'+'1110'+'0010'+'0000';
  cJ4 = '0100'+'0100'+'1100'+'0000';
  cZ1 = '0000'+'1100'+'0110'+'0000';
  cZ2 = '0010'+'0110'+'0100'+'0000';
  cS1 = '0000'+'0110'+'1100'+'0000';
  cS2 = '0100'+'0110'+'0010'+'0000';
  cO1 = '0110'+'0110'+'0000'+'0000';

procedure CrossRender(); stdcall;
begin
  gl.Disable(TGLConst.GL_LIGHTING);
  gl.Enable(TGLConst.GL_BLEND);
  gl.Beginp(TGLConst.GL_QUADS);
    gl.Color4f(0.8, 0.5, 0.5, 0.3);
    gl.Vertex3f(R.WindowWidth div 2 - CROSS_LINE_WIDTH div 2 - 1, 0, Z_BLOCKS - 1);
    gl.Vertex3f(R.WindowWidth div 2 - CROSS_LINE_WIDTH div 2 - 1, R.WindowHeight, Z_BLOCKS - 1);
    gl.Vertex3f(R.WindowWidth div 2 + CROSS_LINE_WIDTH div 2 - 1, R.WindowHeight, Z_BLOCKS - 1);
    gl.Vertex3f(R.WindowWidth div 2 + CROSS_LINE_WIDTH div 2 - 1, 0, Z_BLOCKS - 1);

    gl.Vertex3f(0,             R.WindowHeight div 2 - CROSS_LINE_WIDTH div 2 - 1, Z_BLOCKS - 1);
    gl.Vertex3f(0,             R.WindowHeight div 2 + CROSS_LINE_WIDTH div 2 - 1, Z_BLOCKS - 1);
    gl.Vertex3f(R.WindowWidth, R.WindowHeight div 2 + CROSS_LINE_WIDTH div 2 - 1, Z_BLOCKS - 1);
    gl.Vertex3f(R.WindowWidth, R.WindowHeight div 2 - CROSS_LINE_WIDTH div 2 - 1, Z_BLOCKS - 1);
  gl.Endp();
  gl.Enable(TGLConst.GL_LIGHTING);
end;

{ TpdBlock }

procedure TpdBlock.CalcBounds;
var
  rot, i, j: Integer;
begin
  SetLength(Bounds, Length(Matrices));
  for rot := 0 to High(Matrices) do
  begin
    //top
    Bounds[rot].Top := -1;
    for i := 0 to 3 do
    begin
      for j := 0 to 3 do
        if Matrices[rot][i, j] <> 0 then
        begin
          Bounds[rot].Top := i;
          break;
        end;
      if Bounds[rot].Top <> -1 then
        break;
    end;
    //Bottom
    Bounds[rot].Bottom := -1;
    for i := 3 downto 0 do
    begin
      for j := 0 to 3 do
        if Matrices[rot][i, j] <> 0 then
        begin
          Bounds[rot].Bottom := i;
          break;
        end;
      if Bounds[rot].Bottom <> -1 then
        break;
    end;
    //Left
    Bounds[rot].Left := -1;
    for i := 0 to 3 do
    begin
      for j := 0 to 3 do
        if Matrices[rot][j, i] <> 0 then
        begin
          Bounds[rot].Left := i;
          break;
        end;
      if Bounds[rot].Left <> -1 then
        break;
    end;
    //Left
    Bounds[rot].Right := -1;
    for i := 3 downto 0 do
    begin
      for j := 0 to 3 do
        if Matrices[rot][j, i] <> 0 then
        begin
          Bounds[rot].Right := i;
          break;
        end;
      if Bounds[rot].Right <> -1 then
        break;
    end;
  end;
end;

class function TpdBlock.CreateRandomBlock: TpdBlock;

  procedure FillMatrixFromString(aBlock: TpdBlock; aRotIndex: Integer; aString: String; aColor: Integer);
  var
    i, j: Integer;
  begin
    for i := 0 to 3 do
      for j := 0 to 3 do
        aBlock.Matrices[aRotIndex][i][j] := StrToInt(aString[1 + 4 * i + j]) * aColor;
  end;

var
  ind, colorInd: Integer;
begin
  Result := TpdBlock.Create();
  ind := Random(7); //0..6
  colorInd := 1 + Random(Length(colorUsed));
  case ind of
    0: //I
    begin
      SetLength(Result.Matrices, 2);
      FillMatrixFromString(Result, 0, cI1, colorInd);
      FillMatrixFromString(Result, 1, cI2, colorInd);
    end;
    1: //T
    begin
      SetLength(Result.Matrices, 4);
      FillMatrixFromString(Result, 0, cT1, colorInd);
      FillMatrixFromString(Result, 1, cT2, colorInd);
      FillMatrixFromString(Result, 2, cT3, colorInd);
      FillMatrixFromString(Result, 3, cT4, colorInd);
    end;
    2: //L
    begin
      SetLength(Result.Matrices, 4);
      FillMatrixFromString(Result, 0, cL1, colorInd);
      FillMatrixFromString(Result, 1, cL2, colorInd);
      FillMatrixFromString(Result, 2, cL3, colorInd);
      FillMatrixFromString(Result, 3, cL4, colorInd);
    end;
    3: //J
    begin
      SetLength(Result.Matrices, 4);
      FillMatrixFromString(Result, 0, cJ1, colorInd);
      FillMatrixFromString(Result, 1, cJ2, colorInd);
      FillMatrixFromString(Result, 2, cJ3, colorInd);
      FillMatrixFromString(Result, 3, cJ4, colorInd);
    end;
    4: //Z
    begin
      SetLength(Result.Matrices, 2);
      FillMatrixFromString(Result, 0, cZ1, colorInd);
      FillMatrixFromString(Result, 1, cZ2, colorInd);
    end;
    5: //S
    begin
      SetLength(Result.Matrices, 2);
      FillMatrixFromString(Result, 0, cS1, colorInd);
      FillMatrixFromString(Result, 1, cS2, colorInd);
    end;
    6:
    begin
      SetLength(Result.Matrices, 1);
      FillMatrixFromString(Result, 0, cO1, colorInd);
    end;
  end;

  Result.CalcBounds();
  Result.RotateIndex := Random(Length(Result.Matrices));
end;

procedure TpdBlock.Rotate;
begin
  if RotateIndex = High(Matrices) then
    RotateIndex := 0
  else
    RotateIndex := RotateIndex + 1;
end;

{ TpdField }

procedure TpdField.AddBlock(Origin: TpdBlockOrigin);
begin
  CurrentBlock := TpdBlock.CreateRandomBlock();
  with CurrentBlock do
    case Origin of
      boRight:
      begin
        X := FIELD_SIZE_X - Bounds[RotateIndex].Right - 1;
        Y := FIELD_SIZE_Y div 2 - BLOCK_CENTER_Y;
        MoveDirection := boLeft;
      end;
      boLeft:
      begin
        X := -Bounds[RotateIndex].Left;
        Y := FIELD_SIZE_Y div 2 - BLOCK_CENTER_Y;
        MoveDirection := boRight;
      end;
      boTop:
      begin
        X := FIELD_SIZE_X div 2  - BLOCK_CENTER_X;
        Y := -Bounds[RotateIndex].Top;
        MoveDirection := boBottom;
      end;
      boBottom:
      begin
        X := FIELD_SIZE_X div 2 - BLOCK_CENTER_X;
        Y := FIELD_SIZE_Y - Bounds[RotateIndex].Bottom - 1;
        MoveDirection := boTop;
      end;
    end;
  timeToMove := 1 / CurrentSpeed;
end;

constructor TpdField.Create();
var
  i, j: Integer;
  origin: TdfVec3f;
begin
  inherited Create();

  cross := Factory.NewUserRender();
  cross.OnRender := CrossRender;
  mainScene.RootNode.AddChild(cross);

  CurrentBlock := nil;
  timeToMove := 0;
  CurrentSpeed := SPEED_START;
  origin := dfVec3f(R.WindowWidth div 2, R.WindowHeight div 2, Z_BLOCKS)
    - dfVec3f((FIELD_SIZE_X div 2) * (CELL_SIZE_X + CELL_SPACE), (FIELD_SIZE_Y div 2) * (CELL_SIZE_Y + CELL_SPACE), 0);
  for i := 0 to FIELD_SIZE_X -1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
    begin
      Sprites[i, j] := Factory.NewSprite();
      mainScene.RootNode.AddChild(Sprites[i, j]);
      with Sprites[i, j] do
      begin
        Position := origin + dfVec3f(i * (CELL_SIZE_X + CELL_SPACE), j * (CELL_SIZE_Y + CELL_SPACE), 0);
        Width := CELL_SIZE_X;
        Height := CELL_SIZE_Y;
        Material.Texture := atlasMain.LoadTexture(BLOCK_TEXTURE);
        Material.Diffuse := colorUnused;
        UpdateTexCoords();
        PivotPoint := ppTopLeft;
      end;
    end;
  //debug
  AddBlock(boTop);
end;

destructor TpdField.Destroy();
var
  i, j: Integer;
begin
  for i := 0 to FIELD_SIZE_X - 1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
      Sprites[i, j] := nil;

  inherited;
end;

function TpdField.IsInBounds(X, Y: Integer): Boolean;
begin
  Result := (X >= 0) and (x < FIELD_SIZE_X) and (y >= 0) and (y < FIELD_SIZE_Y);
end;

procedure TpdField.MoveCurrentBlock(const dt: Double);

  procedure BlockMove();
  begin
    with CurrentBlock do
      case MoveDirection of
        boRight: X := X + 1;
        boLeft: X := X - 1;
        boTop: Y := Y - 1;
        boBottom: Y := Y + 1;
      end;
  end;

  procedure BlockSet();
  var
    i, j: Integer;
  begin
    for i := 0 to 3 do
      for j := 0 to 3 do
        with CurrentBlock do
          if IsInBounds(X + i, Y + j) and (Matrices[RotateIndex][j, i] > 0) then
            F[X + i, Y + j] := Matrices[RotateIndex][j, i] + 10;
  end;

  function CouldBlockMove(): Boolean;
  var
    i, j: Integer;
    flag: Boolean;
  begin
    with CurrentBlock do
      case MoveDirection of
        boRight: ;
        boLeft: ;
        boTop: ;
        boBottom:
        begin
          for j := 3 downto 0 do
            for i := 0 to 3 do
            begin
              flag := not IsInBounds(i + X, j + Y + 1);
              flag := flag or ((F[i + X, j + Y + 1] > 10) and (Matrices[RotateIndex][j, i] > 0));
              flag := flag or (j + Y + 1 > FIELD_SIZE_Y div 2);
              if flag then
                Exit(False);
            end;

        end;
      end;
    Exit(True);
  end;

begin
  if Assigned(CurrentBlock) then
    if CouldBlockMove() then
      BlockMove
    else
    begin
      BlockSet();
      CurrentBlock.Free();
      //debug!!!
      AddBlock(boTop);
    end;
end;

procedure TpdField.PlayerControl(const dt: Double);
begin
  if Assigned(CurrentBlock) then
    with CurrentBlock do
    begin
      if R.Input.IsKeyPressed(VK_SPACE) then
        CurrentBlock.Rotate();
      case MoveDirection of
        boRight: ;
        boLeft: ;
        boTop: ;
        boBottom:
        begin
          if R.Input.IsKeyPressed(VK_LEFT) or R.Input.IsKeyPressed('a') then
            //todo:check for ability
            X := X - 1;
          if R.Input.IsKeyPressed(VK_RIGHT) or R.Input.IsKeyPressed('d') then
            //todo:check for ability
            X := X + 1;
        end;
      end;
    end;


  //debug
  if R.Input.IsKeyPressed('1') then
    AddBlock(boTop);
  if R.Input.IsKeyPressed('2') then
    AddBlock(boBottom);
  if R.Input.IsKeyPressed('3') then
    AddBlock(boLeft);
  if R.Input.IsKeyPressed('4') then
    AddBlock(boRight);
end;

procedure TpdField.RedrawField(const dt: Double);
var
  i, j: Integer;
begin
  //erase all dynamic
  for i := 0 to FIELD_SIZE_X - 1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
      if F[i, j] < 10 then //dynamic only
        F[i, j] := 0;

  //"draw" current block
  for i := 0 to 3 do
    for j := 0 to 3 do
      with CurrentBlock do
        if IsInBounds(X + i, Y + j) and (Matrices[RotateIndex][j, i] > 0) then
          //!!!! У Block-ов транспонированная матрица
          //Поле - столбец, строка
          //Блок - строка, столбец
          F[X + i, Y + j] := Matrices[RotateIndex][j, i];

  //paint sprites
  for i := 0 to FIELD_SIZE_X - 1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
      with Sprites[i, j] do
      begin
        if F[i, j] = 0 then
          Material.Diffuse := colorUnused
        else
          //1,2,3... - цвета дин. блоков, 11, 12, 13... - цвета стат. блоков
          Material.Diffuse := colorUsed[F[i, j] mod 10];
      end;
end;

procedure TpdField.Update(const dt: Double);
begin
  PlayerControl(dt);

  timeToMove := timeToMove - dt;
  if timeToMove < 0 then
  begin
    MoveCurrentBlock(dt);
    timeToMove := 1 / CurrentSpeed;
  end;

  RedrawField(dt);
end;

end.

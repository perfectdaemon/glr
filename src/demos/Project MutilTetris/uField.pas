unit uField;

interface

uses
  glr, glrMath;

const
  FIELD_SIZE_X = 24; //Размеры поля в клетках
  FIELD_SIZE_Y = 24;
  FIELD_OFFSET_X = -130;
  FIELD_OFFSET_Y = 0;

  CELL_SIZE_X = 24; //Размер клетки в пикселях
  CELL_SIZE_Y = 24;
  CELL_SPACE  = 2;

  BLOCK_CENTER_X = 1; //Центр фигуры в матрице в координатах 0..3
  BLOCK_CENTER_Y = 1;

  SPEED_START = 1; //1 cell per second

  CLEAN_PERIOD = 8;
  CLEAN_BLOCK_THRESHOLD = 6;

type
  TpdDirection = (boRight, boLeft, boTop, boBottom);

  TpdBlock = class
  private
    procedure CalcBounds();
  public
    Matrices: array of array[0..3, 0..3] of Integer;
    Color: TdfVec4f;
    X, Y: Integer;
    RotateIndex: Integer;
    MoveDirection: TpdDirection;
    Bounds: array of TglrBBi;
    class function CreateRandomBlock(): TpdBlock;
    procedure Rotate();
    function GetNextRotation(): Integer;
  end;

  TpdField = class
  private
    timeToMove: Single;
    function IsInBounds(X, Y: Integer): Boolean;
    function CouldBlockMove(Direction: TpdDirection): Boolean;
    function CouldBlockRotate(): Boolean;
    function CouldBlockSet(): Boolean;
    procedure RedrawField(const dt: Double);
    procedure PlayerControl(const dt: Double);
    procedure MoveCurrentBlock(const dt: Double);
    procedure CleanBlocks();
  public
    CurrentBlock: TpdBlock;
    CurrentSpeed: Single;
    Scores: Integer;
    F: array[0..FIELD_SIZE_X - 1, 0..FIELD_SIZE_Y - 1] of Integer;
    Sprites: array[0..FIELD_SIZE_X - 1, 0..FIELD_SIZE_Y - 1] of IglrSprite;
    cross: IglrUserRenderable;

    BeforeCleanCounter: Integer;

    onGameOver: procedure of object;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure AddBlock(Origin: TpdDirection);
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

var
  alphaVertLine, alphaHorLine: Single;
  horLine, vertLine: array[0..3] of TdfVec3f;

procedure CrossRender(); stdcall;
begin
  gl.Disable(TGLConst.GL_LIGHTING);
  gl.Enable(TGLConst.GL_BLEND);
  gl.Beginp(TGLConst.GL_QUADS);
    gl.Color4f(0.8, 0.5, 0.5, alphaVertLine);
    gl.Vertex3fv(vertLine[0]);
    gl.Vertex3fv(vertLine[1]);
    gl.Vertex3fv(vertLine[2]);
    gl.Vertex3fv(vertLine[3]);

    gl.Color4f(0.8, 0.5, 0.5, alphaHorLine);
    gl.Vertex3fv(horLine[0]);
    gl.Vertex3fv(horLine[1]);
    gl.Vertex3fv(horLine[2]);
    gl.Vertex3fv(horLine[3]);
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

function TpdBlock.GetNextRotation: Integer;
begin
  if RotateIndex = High(Matrices) then
    Result := 0
  else
    Result := RotateIndex + 1;
end;

procedure TpdBlock.Rotate;
begin
  RotateIndex := GetNextRotation();
end;

{ TpdField }

procedure TpdField.AddBlock(Origin: TpdDirection);
begin
  CurrentBlock := TpdBlock.CreateRandomBlock();
  with CurrentBlock do
    case Origin of
      boRight:
      begin
        X := FIELD_SIZE_X - Bounds[RotateIndex].Right - 1;
        Y := FIELD_SIZE_Y div 2 - BLOCK_CENTER_Y;
        MoveDirection := boLeft;
        alphaHorLine := 0.3;
        alphaVertLine := 1.0;
      end;
      boLeft:
      begin
        X := -Bounds[RotateIndex].Left;
        Y := FIELD_SIZE_Y div 2 - BLOCK_CENTER_Y;
        MoveDirection := boRight;
        alphaHorLine := 0.3;
        alphaVertLine := 1.0;
      end;
      boTop:
      begin
        X := FIELD_SIZE_X div 2 - 1 - BLOCK_CENTER_X;
        Y := -Bounds[RotateIndex].Top;
        MoveDirection := boBottom;
        alphaHorLine := 1.0;
        alphaVertLine := 0.3;
      end;
      boBottom:
      begin
        X := FIELD_SIZE_X div 2 - BLOCK_CENTER_X;
        Y := FIELD_SIZE_Y - Bounds[RotateIndex].Bottom - 1;
        MoveDirection := boTop;
        alphaHorLine := 1.0;
        alphaVertLine := 0.3;
      end;
    end;

  BeforeCleanCounter := BeforeCleanCounter - 1;
  if BeforeCleanCounter = 0 then
  begin
    CleanBlocks();
    BeforeCleanCounter := CLEAN_PERIOD;
  end;

  if CouldBlockSet() then
    timeToMove := 1 / CurrentSpeed
  else
    onGameOver();
end;

procedure TpdField.CleanBlocks;

  function CheckCell(c, r: Integer; value: Integer): Integer;
  begin
    if IsInBounds(c, r) then
      if F[c, r] = value then
      begin
        Result := 1;
        F[c, r] := value + 100;
        Inc(Result, CheckCell(c - 1, r, value));
        Inc(Result, CheckCell(c + 1, r, value));
        Inc(Result, CheckCell(c, r + 1, value));
        Inc(Result, CheckCell(c, r - 1, value));
        Exit();
      end;
    Exit(0);
  end;

  procedure MinusBlocksToClean(OnlyRevert: Boolean);
  var
    i, j: Integer;
  begin
    for i := 0 to FIELD_SIZE_X - 1 do
      for j := 0 to FIELD_SIZE_Y - 1 do
        if (F[i, j] > 100) then
        begin
          F[i, j] := F[i, j] - 100;
          if not OnlyRevert then
            F[i, j] := -F[i, j];
        end;
  end;

var
  i, j, Res, ResSum: Integer;
  hasMove: Boolean;
begin
  ResSum := 0;
  for i := 0 to FIELD_SIZE_X - 1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
      if (F[i, j] > 0) and (F[i, j] < 100) then
      begin
        Res := CheckCell(i, j, F[i, j]);
        if Res >= CLEAN_BLOCK_THRESHOLD then
        begin
          MinusBlocksToClean(False);
          ResSum := ResSum + Res;
        end
        else
          MinusBlocksToClean(True);
      end;
  Scores := Scores + ResSum;

  //TODO: Таймер на ожидание

  //смещаем все сначало сверхну и снизу, потом слева и справа
  hasMove := True;
  while (hasMove) do
  begin
    hasMove := False;
    for j := 1 to (FIELD_SIZE_Y div 2) - 1 do
      for i := 0 to FIELD_SIZE_X - 1 do
      begin
        //Bottom
        if (F[i, (FIELD_SIZE_Y div 2) + j] > 0) and
           (F[i, (FIELD_SIZE_Y div 2) + j - 1] <= 0) then
        begin
          F[i, (FIELD_SIZE_Y div 2) + j - 1] := F[i, (FIELD_SIZE_Y div 2) + j];
          F[i, (FIELD_SIZE_Y div 2) + j]     := 0;
          hasMove := True;
        end;

        //Top
        if (F[i, (FIELD_SIZE_Y div 2) - j] > 0) and
           (F[i, (FIELD_SIZE_Y div 2) - j + 1] <= 0) then
        begin
          F[i, (FIELD_SIZE_Y div 2) - j + 1] := F[i, (FIELD_SIZE_Y div 2) - j];
          F[i, (FIELD_SIZE_Y div 2) - j]     := 0;
          hasMove := True;
        end;
      end;
  end;
      

end;

function TpdField.CouldBlockMove(Direction: TpdDirection): Boolean;
var
  i, j: Integer;
  stop: Boolean;
begin
  with CurrentBlock do
    case Direction of
      boRight:
      begin
        for i := 3 downto 0 do
          for j := 0 to 3 do
          begin
            if Matrices[RotateIndex][j, i] = 0 then
              continue;
            stop := false; //not IsInBounds(i + X + 1, j + Y);
            stop := stop or (F[i + X + 1, j + Y] > 10);
            if Direction = MoveDirection then
              stop := stop or (i + X + 1 > FIELD_SIZE_X div 2 - 1)
            else
              stop := stop or (i + X + 1 > FIELD_SIZE_X - 1);
            if stop then
              Exit(False);
          end;
      end;
      boLeft:
      begin
        for i := 0 to 3 do
          for j := 0 to 3 do
          begin
            if Matrices[RotateIndex][j, i] = 0 then
              continue;
            stop := false; //not IsInBounds(i + X - 1, j + Y);
            stop := stop or (F[i + X - 1, j + Y] > 10);
            if Direction = MoveDirection then
              stop := stop or (i + X - 1 < FIELD_SIZE_X div 2)
            else
              stop := stop or (i + X - 1 < 0);
            if stop then
              Exit(False);
          end;
      end;
      boTop:
      begin
        for j := 0 to 3 do
          for i := 0 to 3 do
          begin
            if Matrices[RotateIndex][j, i] = 0 then
              continue;
            stop := false; //not IsInBounds(i + X, j + Y - 1);
            stop := stop or (F[i + X, j + Y - 1] > 10);
            if Direction = MoveDirection then
              stop := stop or (j + Y - 1 < FIELD_SIZE_Y div 2)
            else
              stop := stop or (j + Y - 1 < 0);
            if stop then
              Exit(False);
          end;
      end;
      boBottom:
      begin
        for j := 3 downto 0 do
          for i := 0 to 3 do
          begin
            if Matrices[RotateIndex][j, i] = 0 then
              continue;
            stop := false; //not IsInBounds(i + X, j + Y + 1);
            stop := stop or (F[i + X, j + Y + 1] > 10);
            if Direction = MoveDirection then
              stop := stop or (j + Y + 1 > FIELD_SIZE_Y div 2 - 1)
            else
              stop := stop or (j + Y + 1 > FIELD_SIZE_Y - 1);
            if stop then
              Exit(False);
          end;
      end;
    end;
  Exit(True);
end;

function TpdField.CouldBlockRotate(): Boolean;
var
  nextRotation, i, j: Integer;
begin
  if Assigned(CurrentBlock) then
    with CurrentBlock do
    begin
      nextRotation := GetNextRotation();
      for i := 0 to 3 do
        for j := 0 to 3 do
          if (Matrices[nextRotation][j, i] > 0) and (F[X + i, Y + j] > 10) then
            Exit(False);
      Exit(True);
    end;
end;

function TpdField.CouldBlockSet: Boolean;
var
  i, j: Integer;
begin
  with CurrentBlock do
    for i := 0 to 3 do
      for j := 0 to 3 do
        if (F[X + i, Y + j] > 10) and (Matrices[RotateIndex][j, i] > 0) then
          Exit(False);
  Exit(True);
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
  Scores := 0;
  origin := dfVec3f(R.WindowWidth div 2 + FIELD_OFFSET_X, R.WindowHeight div 2 + FIELD_OFFSET_Y, Z_BLOCKS)
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
  //top left
  vertLine[0] := dfVec3f(R.WindowWidth div 2 - CROSS_LINE_WIDTH div 2 - 1 + FIELD_OFFSET_X,
    Sprites[0, 0].Position.y - CELL_SIZE_Y, Z_BLOCKS - 1);
  //bottom left
  vertLine[1] := dfVec3f(R.WindowWidth div 2 - CROSS_LINE_WIDTH div 2 - 1 + FIELD_OFFSET_X,
    Sprites[0, FIELD_SIZE_Y - 1].Position.y + 2 * CELL_SIZE_Y, Z_BLOCKS - 1);
  //bottom right
  vertLine[2] := dfVec3f(R.WindowWidth div 2 + CROSS_LINE_WIDTH div 2 - 1 + FIELD_OFFSET_X,
    Sprites[0, FIELD_SIZE_Y - 1].Position.y + 2 * CELL_SIZE_Y,  Z_BLOCKS - 1);
  //top right
  vertLine[3] := dfVec3f(R.WindowWidth div 2 + CROSS_LINE_WIDTH div 2 - 1 + FIELD_OFFSET_X,
    Sprites[0, 0].Position.y - CELL_SIZE_Y, Z_BLOCKS - 1);

  //top left
  horLine[0] := dfVec3f(Sprites[0, 0].Position.x - CELL_SIZE_X,
    R.WindowHeight div 2 - CROSS_LINE_WIDTH div 2 - 1 + FIELD_OFFSET_Y,
    Z_BLOCKS - 1);
  //bottom left
  horLine[1] := dfVec3f(Sprites[0, 0].Position.x - CELL_SIZE_X,
    R.WindowHeight div 2 + CROSS_LINE_WIDTH div 2 - 1 + FIELD_OFFSET_Y,
    Z_BLOCKS - 1);
  //bottom right
  horLine[2] := dfVec3f(Sprites[FIELD_SIZE_X - 1, 0].Position.x + 2 * CELL_SIZE_X,
    R.WindowHeight div 2 + CROSS_LINE_WIDTH div 2 - 1 + FIELD_OFFSET_Y,
    Z_BLOCKS - 1);
  //top right
  horLine[3] := dfVec3f(Sprites[FIELD_SIZE_X - 1, 0].Position.x + 2 * CELL_SIZE_X,
    R.WindowHeight div 2 - CROSS_LINE_WIDTH div 2 - 1 + FIELD_OFFSET_Y,
    Z_BLOCKS - 1);

  //Start the game!
  AddBlock(boTop);
  BeforeCleanCounter := CLEAN_PERIOD;
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

begin
  if Assigned(CurrentBlock) then
    if CouldBlockMove(CurrentBlock.MoveDirection) then
      BlockMove()
    else
    begin
      BlockSet();
      CurrentBlock.Free();
      case CurrentBlock.MoveDirection of
        boRight: AddBlock(boBottom);
        boLeft: AddBlock(boTop);
        boTop: AddBlock(boRight);
        boBottom: AddBlock(boLeft);
      end;
    end;
end;

procedure TpdField.PlayerControl(const dt: Double);
begin
  if Assigned(CurrentBlock) then
    with CurrentBlock do
    begin
      if R.Input.IsKeyPressed(VK_SPACE) and CouldBlockRotate() then
      begin
        //todo: проверить возможность поворота
        Rotate();
        if (X + Bounds[RotateIndex].Right > FIELD_SIZE_X - 1) then
          X := X - (X + Bounds[RotateIndex].Right - FIELD_SIZE_X + 1);
        if (X + Bounds[RotateIndex].Left < 0) then
          X := X + (X + Bounds[RotateIndex].Left);
        if (Y + Bounds[RotateIndex].Top < 0) then
          Y := Y + (Y + Bounds[RotateIndex].Top);
        if (Y + Bounds[RotateIndex].Bottom > FIELD_SIZE_Y - 1) then
          Y := Y - (Y + Bounds[RotateIndex].Bottom - FIELD_SIZE_Y + 1);
      end;

      case MoveDirection of
        boRight:
        begin
          if R.Input.IsKeyPressed(VK_UP) or R.Input.IsKeyPressed(VK_W) then
            if CouldBlockMove(boTop) then
              Y := Y - 1;
          if R.Input.IsKeyPressed(VK_DOWN) or R.Input.IsKeyPressed(VK_S) then
            if CouldBlockMove(boBottom) then
              Y := Y + 1;
          if R.Input.IsKeyPressed(VK_RIGHT) or R.Input.IsKeyPressed(VK_D) then
          begin
            MoveCurrentBlock(dt);
            timeToMove := 1 / CurrentSpeed;
          end;
        end;
        boLeft:
        begin
          if R.Input.IsKeyPressed(VK_UP) or R.Input.IsKeyPressed(VK_W) then
            if CouldBlockMove(boTop) then
              Y := Y - 1;
          if R.Input.IsKeyPressed(VK_DOWN) or R.Input.IsKeyPressed(VK_S) then
            if CouldBlockMove(boBottom) then
              Y := Y + 1;
          if R.Input.IsKeyPressed(VK_LEFT) or R.Input.IsKeyPressed(VK_A) then
          begin
            MoveCurrentBlock(dt);
            timeToMove := 1 / CurrentSpeed;
          end;
        end;
        boTop:
        begin
          if R.Input.IsKeyPressed(VK_LEFT) or R.Input.IsKeyPressed(VK_A) then
            if CouldBlockMove(boLeft) then
              X := X - 1;
          if R.Input.IsKeyPressed(VK_RIGHT) or R.Input.IsKeyPressed(VK_D) then
            if CouldBlockMove(boRight) then
              X := X + 1;
          if R.Input.IsKeyPressed(VK_UP) or R.Input.IsKeyPressed(VK_W) then
          begin
            MoveCurrentBlock(dt);
            timeToMove := 1 / CurrentSpeed;
          end;
        end;
        boBottom:
        begin
          if R.Input.IsKeyPressed(VK_LEFT) or R.Input.IsKeyPressed(VK_A) then
            if CouldBlockMove(boLeft) then
              X := X - 1;
          if R.Input.IsKeyPressed(VK_RIGHT) or R.Input.IsKeyPressed(VK_D) then
            if CouldBlockMove(boRight) then
              X := X + 1;
          if R.Input.IsKeyPressed(VK_DOWN) or R.Input.IsKeyPressed(VK_S) then
          begin
            MoveCurrentBlock(dt);
            timeToMove := 1 / CurrentSpeed;
          end;
        end;
      end;
    end;
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

  if Assigned(CurrentBlock) then
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
        else if F[i, j] < 100 then
          //1,2,3... - цвета дин. блоков, 11, 12, 13... - цвета стат. блоков
          Material.Diffuse := colorUsed[F[i, j] mod 10]
        //debug
        else
        begin
          Material.Diffuse := colorUsed[F[i, j] mod 10];
          Material.PDiffuse.w := 0.5;
        end;
      end;
end;

procedure TpdField.Update(const dt: Double);
begin
  PlayerControl(dt);

  if Assigned(CurrentBlock) then
  begin
    timeToMove := timeToMove - dt;
    if timeToMove < 0 then
    begin
      MoveCurrentBlock(dt);
      timeToMove := 1 / CurrentSpeed;
    end;
  end;

  RedrawField(dt);
end;

end.

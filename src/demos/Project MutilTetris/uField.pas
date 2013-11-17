unit uField;

interface

uses
  glr, glrMath, uParticles;

const
  FIELD_SIZE_X = 24; //Размеры поля в клетках
  FIELD_SIZE_Y = 24;
  FIELD_OFFSET_X = -155;
  FIELD_OFFSET_Y = 30;

  CELL_SIZE_X = 24; //Размер клетки в пикселях
  CELL_SIZE_Y = 24;
  CELL_SPACE  = 2;

  BLOCK_CENTER_X = 1; //Центр фигуры в матрице в координатах 0..3
  BLOCK_CENTER_Y = 1;

  SPEED_START = 1; //1 cell per second
  SPEED_INC   = 0.5;

  CLEAN_PERIOD_START = 8;
  CLEAN_BLOCK_THRESHOLD = 6;

  NEXT_BLOCK_OFFSET_X = -200;
  NEXT_BLOCK_OFFSET_Y = -280;

  //Через сколько секунд перейти к непрерывному управлению
  SWITCH_TO_CONTINIOUS_CONTROL_SEC = 0.2;

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
    ctrlTimers: array[TpdDirection] of Single;
    ctrlAllowMove: array[TpdDirection] of Boolean;
    timeToMove, timeToClean: Single;
    FN: array[0..3, 0..3] of IglrSprite;

    procedure AddBlock(Origin: TpdDirection);
    function IsInBounds(X, Y: Integer): Boolean;
    function CouldBlockMove(Direction: TpdDirection): Boolean;
    function CouldBlockRotate(): Boolean;
    function CouldBlockSet(): Boolean;
    procedure RedrawField(const dt: Double);
    procedure PlayerControl(const dt: Double);
    procedure MoveCurrentBlock(const dt: Double);
    procedure FindBlocksToClean();
    procedure CleanBlocks();
    function BlockPosToScreenPos(X, Y: Integer): TdfVec2f;
  public
    CurrentBlock, NextBlock: TpdBlock;
    NextBlockDir: IglrSprite;
    CurrentSpeed: Single;
    CurrentCleanPeriod: Integer;
    Scores: Integer;
    F: array[0..FIELD_SIZE_X - 1, 0..FIELD_SIZE_Y - 1] of Integer;
    Sprites: array[0..FIELD_SIZE_X - 1, 0..FIELD_SIZE_Y - 1] of IglrSprite;
    cross: IglrUserRenderable;
    particles: TpdParticles;

    BeforeCleanCounter: Integer;

    onGameOver: procedure of object;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure AddNextBlock();
    procedure Update(const dt: Double);
  end;

implementation

uses
  ogl, dfTweener,
  Windows, SysUtils,
  uGlobal;

const
  CROSS_LINE_WIDTH = 4;
  LINE_ACTIVE_ALPHA = 1.0;
  LINE_INACTIVE_ALPHA = 0.3;

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


procedure SPriteTween(aSprite: IInterface; aValue: Single);
begin
  (aSprite as IglrSprite).Material.PDiffuse.w := aValue;
end;

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

{$REGION 'Block'}

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
  Result.Color := colorUsed[colorInd];
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

{$ENDREGION}

{ TpdField }

procedure RotateArrow(Arrow: IdfTweenObject; Value: Single);
begin
  with Arrow as IglrSprite do
    Rotation := Value;
end;

procedure TpdField.AddBlock(Origin: TpdDirection);
begin
  if Assigned(CurrentBlock) then
    CurrentBlock.Free();
  if not Assigned(NextBlock) then
    NextBlock := TpdBlock.CreateRandomBlock();

  CurrentBlock := NextBlock;
  NextBlock := TpdBlock.CreateRandomBlock();
  NextBlockDir.Material.Diffuse := NextBlock.Color;
  with CurrentBlock do
    case Origin of
      boRight:
      begin
        X := FIELD_SIZE_X - Bounds[RotateIndex].Right - 1;
        Y := FIELD_SIZE_Y div 2 - BLOCK_CENTER_Y;
        MoveDirection := boLeft;
        alphaHorLine := LINE_INACTIVE_ALPHA;
        alphaVertLine := LINE_ACTIVE_ALPHA;
        //next dir is from top
        Tweener.AddTweenInterface(NextBlockDir, RotateArrow, tsElasticEaseIn, NextBlockDir.Rotation, 90, 1.2, 0.0);
//        NextBlockDir.Rotation := 90;
      end;
      boLeft:
      begin
        X := -Bounds[RotateIndex].Left;
        Y := FIELD_SIZE_Y div 2 - BLOCK_CENTER_Y;
        MoveDirection := boRight;
        alphaHorLine := LINE_INACTIVE_ALPHA;
        alphaVertLine := LINE_ACTIVE_ALPHA;
        Tweener.AddTweenInterface(NextBlockDir, RotateArrow, tsElasticEaseIn, NextBlockDir.Rotation, -90, 1.2, 0.0);
//        NextBlockDir.Rotation := -90;
      end;
      boTop:
      begin
        X := FIELD_SIZE_X div 2 - 1 - BLOCK_CENTER_X;
        Y := -Bounds[RotateIndex].Top;
        MoveDirection := boBottom;
        alphaHorLine := LINE_ACTIVE_ALPHA;
        alphaVertLine := LINE_INACTIVE_ALPHA;
        Tweener.AddTweenInterface(NextBlockDir, RotateArrow, tsElasticEaseIn, NextBlockDir.Rotation, 0, 1.2, 0.0);
        //NextBlockDir.Rotation := 0;
      end;
      boBottom:
      begin
        X := FIELD_SIZE_X div 2 - BLOCK_CENTER_X;
        Y := FIELD_SIZE_Y - Bounds[RotateIndex].Bottom - 1;
        MoveDirection := boTop;
        alphaHorLine := LINE_ACTIVE_ALPHA;
        alphaVertLine := LINE_INACTIVE_ALPHA;
        Tweener.AddTweenInterface(NextBlockDir, RotateArrow, tsElasticEaseIn, 270, 180, 1.2, 0.0);
//        NextBlockDir.Rotation := 180;
      end;
    end;
end;

procedure TpdField.FindBlocksToClean;

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

  procedure MinusBlocksToClean(OnlyRevert: Boolean; var TotalTime: Single);
  var
    p: Single;
    i, j: Integer;
  begin
    p := TotalTime;
    for i := 0 to FIELD_SIZE_X - 1 do
      for j := 0 to FIELD_SIZE_Y - 1 do
        if (F[i, j] > 100) then
        begin
          F[i, j] := F[i, j] - 100;
          if not OnlyRevert then
          begin
            F[i, j] := -F[i, j];
            p := p + 0.05;
            Tweener.AddTweenInterface(Sprites[i, j], SpriteTween, tsSimple, 1.0, 0.3, 1.0, p);
          end;
        end;
    TotalTime := p;
  end;

var
  i, j, Res, ResSum: Integer;
  //hasMove: Boolean;
  total: Single;

begin
  ResSum := 0;
  total := 0;
  for i := 0 to FIELD_SIZE_X - 1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
      if (F[i, j] > 0) and (F[i, j] < 100) then
      begin
        Res := CheckCell(i, j, F[i, j]);
        if Res >= CLEAN_BLOCK_THRESHOLD then
        begin
          MinusBlocksToClean(False, total);
          ResSum := ResSum + Res;
        end
        else
          MinusBlocksToClean(True, total);
      end;
  Scores := Scores + ResSum;

  timeToClean := 1.0 + total + 0.2;

end;

procedure TpdField.CleanBlocks;
var
  i, j: Integer;
  hasMove: Boolean;
begin
  //смещаем все сначало сверхну и снизу, потом слева и справа
  hasMove := True;
  while (hasMove) do
  begin
    hasMove := False;
    for j := 1 to (FIELD_SIZE_Y div 2) - 1 do
      for i := 0 to FIELD_SIZE_X - 1 do
      begin
        //Bottom
        if (F[i, (FIELD_SIZE_Y div 2) + j]     >  0) and
           (F[i, (FIELD_SIZE_Y div 2) + j - 1] <= 0) then
        begin
          F[i, (FIELD_SIZE_Y div 2) + j - 1] := F[i, (FIELD_SIZE_Y div 2) + j];
          F[i, (FIELD_SIZE_Y div 2) + j]     := 0;
          hasMove := True;
        end;

        //Top
        if (F[i, (FIELD_SIZE_Y div 2) - j - 1] >  0) and
           (F[i, (FIELD_SIZE_Y div 2) - j]     <= 0) then
        begin
          F[i, (FIELD_SIZE_Y div 2) - j]     := F[i, (FIELD_SIZE_Y div 2) - j - 1];
          F[i, (FIELD_SIZE_Y div 2) - j - 1] := 0;
          hasMove := True;
        end;
      end;

    //reright this!!!!!
    //left block index 12
    //right block index 11
    for i := 1 to (FIELD_SIZE_X div 2) - 1 do
      for j := 0 to FIELD_SIZE_Y - 1 do
      begin
        //Right
        if (F[(FIELD_SIZE_X div 2) + i,     j] >  0) and
           (F[(FIELD_SIZE_X div 2) + i - 1, j] <= 0) then
        begin
          F[(FIELD_SIZE_X div 2) + i - 1, j] := F[(FIELD_SIZE_X div 2) + i, j];
          F[(FIELD_SIZE_X div 2) + i,     j] := 0;
          hasMove := True;
        end;

        //Left
        if (F[(FIELD_SIZE_X div 2) - i - 1, j] >  0) and
           (F[(FIELD_SIZE_X div 2) - i,     j] <= 0) then
        begin
          F[(FIELD_SIZE_X div 2) - i,     j] := F[(FIELD_SIZE_X div 2) - i - 1, j];
          F[(FIELD_SIZE_X div 2) - i - 1, j] := 0;
          hasMove := True;
        end;
      end;
  end;

  //Удалить все следы
  for i := 0 to FIELD_SIZE_X - 1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
      if F[i, j] < 0 then
        F[i, j] := 0;
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
          if {not IsInBounds(X, Y) or }((Matrices[nextRotation][j, i] > 0) and (F[X + i, Y + j] > 10)) then
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

  for i := 0 to 3 do
    for j := 0 to 3 do
    begin
      FN[i, j] := Factory.NewSprite();
      mainScene.RootNode.AddChild(FN[i, j]);
      with FN[i, j] do
      begin
        Position := dfVec3f(R.WindowWidth + NEXT_BLOCK_OFFSET_X, R.WindowHeight + NEXT_BLOCK_OFFSET_Y, Z_BLOCKS)
         + dfVec3f(i * (CELL_SIZE_X + CELL_SPACE), j * (CELL_SIZE_Y + CELL_SPACE), 0);
        Width := CELL_SIZE_X;
        Height := CELL_SIZE_Y;
        Material.Texture := atlasMain.LoadTexture(BLOCK_TEXTURE);
        Material.Diffuse := colorUnused;
        UpdateTexCoords();
        PivotPoint := ppTopLeft;
      end;
    end;

  NextBlockDir := Factory.NewHudSprite();
  with NextBlockDir do
  begin
    Material.Texture := atlasMain.LoadTexture(ARROW_TEXTURE);
    UpdateTexCoords();
    SetSizeToTextureSize();
    PivotPoint := ppCenter;
    Position := FN[0, 0].Position + dfVec3f(-40, 1.5 * (CELL_SIZE_Y + CELL_SPACE), 0);
  end;
  mainScene.RootNode.AddChild(NextBlockDir);

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

  particles := TpdParticles.Initialize(mainScene);

  //Start the game!
  CurrentSpeed := SPEED_START;
  CurrentCleanPeriod := CLEAN_PERIOD_START;
  timeToMove := 1 / CurrentSpeed;
  timeToClean := 0;
  Scores := 0;
  CurrentBlock := nil;
  AddBlock(boTop);
  BeforeCleanCounter := CurrentCleanPeriod;
end;

destructor TpdField.Destroy();
var
  i, j: Integer;
begin
  for i := 0 to FIELD_SIZE_X - 1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
      Sprites[i, j] := nil;

  particles.Free();
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
      sound.PlaySample(sDown);
      with CurrentBlock do
        particles.AddBlock(BlockPosToScreenPos(X + 1, Y + 1));
      BeforeCleanCounter := BeforeCleanCounter - 1;
      if BeforeCleanCounter = 0 then
      begin
        FindBlocksToClean();
        Inc(CurrentCleanPeriod);
        BeforeCleanCounter := CurrentCleanPeriod;
        CurrentSpeed := CurrentSpeed + SPEED_INC;
      end
      else
        AddNextBlock();
    end;
end;

procedure TpdField.AddNextBlock;
begin
  case CurrentBlock.MoveDirection of
    boRight: AddBlock(boBottom);
    boLeft: AddBlock(boTop);
    boTop: AddBlock(boRight);
    boBottom: AddBlock(boLeft);
  end;

  if CouldBlockSet() then
    timeToMove := 1 / CurrentSpeed
  else
    onGameOver();
end;

function TpdField.BlockPosToScreenPos(X, Y: Integer): TdfVec2f;
var
  origin: TdfVec2f;
begin
  origin := dfVec2f(R.WindowWidth div 2 + FIELD_OFFSET_X, R.WindowHeight div 2 + FIELD_OFFSET_Y)
    - dfVec2f((FIELD_SIZE_X div 2) * (CELL_SIZE_X + CELL_SPACE), (FIELD_SIZE_Y div 2) * (CELL_SIZE_Y + CELL_SPACE));
  Result := origin + dfVec2f(X * (CELL_SIZE_X + CELL_SPACE), Y * (CELL_SIZE_Y + CELL_SPACE));
end;

procedure TpdField.PlayerControl(const dt: Double);

  procedure CalculateKeyboardTimeouts();
  begin
    with R.Input do
    begin
      if IsKeyDown(VK_UP) or IsKeyDown(VK_W) then
        ctrlTimers[boTop] := Clamp(ctrlTimers[boTop] - dt, 0, SWITCH_TO_CONTINIOUS_CONTROL_SEC)
      else
        ctrlTimers[boTop] := SWITCH_TO_CONTINIOUS_CONTROL_SEC;

      if IsKeyDown(VK_DOWN) or IsKeyDown(VK_S) then
        ctrlTimers[boBottom] := Clamp(ctrlTimers[boBottom] - dt, 0, SWITCH_TO_CONTINIOUS_CONTROL_SEC)
      else
        ctrlTimers[boBottom] := SWITCH_TO_CONTINIOUS_CONTROL_SEC;

      if IsKeyDown(VK_LEFT) or IsKeyDown(VK_A) then
        ctrlTimers[boLeft] := Clamp(ctrlTimers[boLeft] - dt, 0, SWITCH_TO_CONTINIOUS_CONTROL_SEC)
      else
        ctrlTimers[boLeft] := SWITCH_TO_CONTINIOUS_CONTROL_SEC;

      if IsKeyDown(VK_RIGHT) or IsKeyDown(VK_D) then
        ctrlTimers[boRight] := Clamp(ctrlTimers[boRight] - dt, 0, SWITCH_TO_CONTINIOUS_CONTROL_SEC)
      else
        ctrlTimers[boRight] := SWITCH_TO_CONTINIOUS_CONTROL_SEC;

      ctrlAllowMove[boTop] := (Abs(ctrlTimers[boTop]) < cEPS) or
        (Abs(ctrlTimers[boTop] - SWITCH_TO_CONTINIOUS_CONTROL_SEC) < cEPS);
      ctrlAllowMove[boBottom] := (Abs(ctrlTimers[boBottom]) < cEPS) or
        (Abs(ctrlTimers[boBottom] - SWITCH_TO_CONTINIOUS_CONTROL_SEC) < cEPS);
      ctrlAllowMove[boLeft] := (Abs(ctrlTimers[boLeft]) < cEPS) or
        (Abs(ctrlTimers[boLeft] - SWITCH_TO_CONTINIOUS_CONTROL_SEC) < cEPS);
      ctrlAllowMove[boRight] := (Abs(ctrlTimers[boRight]) < cEPS) or
        (Abs(ctrlTimers[boRight] - SWITCH_TO_CONTINIOUS_CONTROL_SEC) < cEPS);
    end;
  end;

begin
  if Assigned(CurrentBlock) then
    with CurrentBlock do
    begin
      if R.Input.IsKeyPressed(VK_SPACE) and CouldBlockRotate() then
      begin
        Rotate();
        sound.PlaySample(sRotate);
        if (X + Bounds[RotateIndex].Right > FIELD_SIZE_X - 1) then
          X := FIELD_SIZE_X - Bounds[RotateIndex].Right - 1;
        if (X + Bounds[RotateIndex].Left < 0) then
          X := -Bounds[RotateIndex].Left;
        if (Y + Bounds[RotateIndex].Top < 0) then
          Y := -Bounds[RotateIndex].Top;
        if (Y + Bounds[RotateIndex].Bottom > FIELD_SIZE_Y - 1) then
          Y := FIELD_SIZE_Y - Bounds[RotateIndex].Bottom - 1;
      end;

      case MoveDirection of
        boRight:
        begin
          if (R.Input.IsKeyDown(VK_UP) or R.Input.IsKeyDown(VK_W)) and ctrlAllowMove[boTop] then
            if CouldBlockMove(boTop) then
            begin
              ctrlTimers[boTop] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
              Y := Y - 1;
            end;
          if (R.Input.IsKeyDown(VK_DOWN) or R.Input.IsKeyDown(VK_S)) and ctrlAllowMove[boBottom] then
            if CouldBlockMove(boBottom) then
            begin
              ctrlTimers[boBottom] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
              Y := Y + 1;
            end;
          if (R.Input.IsKeyDown(VK_RIGHT) or R.Input.IsKeyDown(VK_D)) and ctrlAllowMove[boRight] then
          begin
            ctrlTimers[boRight] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
            MoveCurrentBlock(dt);
            timeToMove := 1 / CurrentSpeed;
          end;
        end;
        boLeft:
        begin
          if (R.Input.IsKeyDown(VK_UP) or R.Input.IsKeyDown(VK_W)) and ctrlAllowMove[boTop] then
            if CouldBlockMove(boTop) then
            begin
              ctrlTimers[boTop] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
              Y := Y - 1;
            end;
          if (R.Input.IsKeyDown(VK_DOWN) or R.Input.IsKeyDown(VK_S)) and ctrlAllowMove[boBottom] then
            if CouldBlockMove(boBottom) then
            begin
              ctrlTimers[boBottom] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
              Y := Y + 1;
            end;
          if (R.Input.IsKeyDown(VK_LEFT) or R.Input.IsKeyDown(VK_A)) and ctrlAllowMove[boLeft] then
          begin
            ctrlTimers[boLeft] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
            MoveCurrentBlock(dt);
            timeToMove := 1 / CurrentSpeed;
          end;
        end;
        boTop:
        begin
          if (R.Input.IsKeyDown(VK_LEFT) or R.Input.IsKeyDown(VK_A)) and ctrlAllowMove[boLeft]  then
            if CouldBlockMove(boLeft) then
            begin
              X := X - 1;
              ctrlTimers[boLeft] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
            end;
          if (R.Input.IsKeyDown(VK_RIGHT) or R.Input.IsKeyDown(VK_D)) and ctrlAllowMove[boRight]  then
            if CouldBlockMove(boRight) then
            begin
              X := X + 1;
              ctrlTimers[boRight] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
            end;
          if (R.Input.IsKeyDown(VK_UP) or R.Input.IsKeyDown(VK_W)) and ctrlAllowMove[boTop]  then
          begin
            ctrlTimers[boTop] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
            MoveCurrentBlock(dt);
            timeToMove := 1 / CurrentSpeed;
          end;
        end;
        boBottom:
        begin
          if (R.Input.IsKeyDown(VK_LEFT) or R.Input.IsKeyDown(VK_A)) and ctrlAllowMove[boLeft] then
            if CouldBlockMove(boLeft) then
            begin
              X := X - 1;
              ctrlTimers[boLeft] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
            end;
          if (R.Input.IsKeyDown(VK_RIGHT) or R.Input.IsKeyDown(VK_D)) and ctrlAllowMove[boRight] then
            if CouldBlockMove(boRight) then
            begin
              X := X + 1;
              ctrlTimers[boRight] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
            end;
          if (R.Input.IsKeyDown(VK_DOWN) or R.Input.IsKeyDown(VK_S)) and ctrlAllowMove[boBottom] then
          begin
            ctrlTimers[boBottom] := SWITCH_TO_CONTINIOUS_CONTROL_SEC / 2;
            MoveCurrentBlock(dt);
            timeToMove := 1 / CurrentSpeed;
          end;
        end;
      end;

      CalculateKeyboardTimeouts();
    end;
end;

procedure TpdField.RedrawField(const dt: Double);
var
  i, j: Integer;
begin
  //erase all dynamic
  for i := 0 to FIELD_SIZE_X - 1 do
    for j := 0 to FIELD_SIZE_Y - 1 do
      if (F[i, j] < 10) and (F[i, j] > 0) then //dynamic only
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
        else if F[i, j] > 0 then
          //1,2,3... - цвета дин. блоков, 11, 12, 13... - цвета стат. блоков
          Material.Diffuse := colorUsed[F[i, j] mod 10];
      end;

  if Assigned(NextBlock) then
    with NextBlock do
      for i := 0 to 3 do
        for j := 0 to 3 do
          FN[i, j].Material.Diffuse := colorUsed[Matrices[RotateIndex][j, i]];
end;

procedure TpdField.Update(const dt: Double);
begin
  particles.Update(dt);
  if timeToClean > 0 then
    begin
      timeToClean := timeToClean - dt;
      if timeToClean <= 0 then
      begin
        CleanBlocks();
        AddNextBlock();
      end;
    end
  else
    if Assigned(CurrentBlock) then
    begin
      PlayerControl(dt);
      RedrawField(dt);
      timeToMove := timeToMove - dt;
      if timeToMove < 0 then
      begin
        MoveCurrentBlock(dt);
        timeToMove := 1 / CurrentSpeed;
      end;
    end;
end;

end.

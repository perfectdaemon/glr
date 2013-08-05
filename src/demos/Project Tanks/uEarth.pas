unit uEarth;

interface

uses
  dfHRenderer;

const
  TILE_SIZE = 16; //32x32
  TILES_X = 1024 div TILE_SIZE;   //1024
  TILES_Y = 640 div TILE_SIZE;   //640

  TILE_EMPTY  = $00;
  TILE_EARTH  = $01;
  TILE_PLAYER = $02;
  TILE_ENEMY  = $03;

type
  TpdTileStatus = Byte;

  TpdEarth = class
  protected
    boomSpr: IglrSprite;
    constructor Create(); virtual;
    destructor Destroy(); override;
    procedure MoveTileSprite(col, row, toRow: Integer; speed, pause: Single);
  public
    tiles: array[0..TILES_X - 1, 0..TILES_Y - 1] of TpdTileStatus;
    tileSprites: array[0..TILES_X - 1, 0..TILES_Y - 1] of IglrSprite;

    class function Initialize(const aBMPFileName: String; aScene: Iglr2DScene): TpdEarth;
    procedure BombAt(const tX, tY: Integer; bombRadius: Integer);
    procedure UpdateEarth(FromCol, ToCol: Integer);
    procedure UpdateTileSprites();
  end;

implementation

uses
  uGlobal, dfMath, dfTweener,
  Graphics;

{ TpdEarth }

procedure TpdEarth.BombAt(const tX, tY: Integer; bombRadius: Integer);
var
  row, col, i, j,
  left, right, top, bottom: Integer;
  distance: Single;
begin
  col := tX;
  row := tY;
  top := Clamp(row - bombRadius, 0, TILES_Y - 1);
  bottom := Clamp(row + bombRadius, 0, TILES_Y - 1);

  //Верхняя полусфера
  for i := top to row do
  begin
    left := Clamp(col - (i - top), 0, TILES_X - 1);
    right := Clamp(col + (i - top), 0, TILES_X - 1);
    for j := left to right do
      if tiles[j, i] = TILE_EARTH then
        tiles[j, i] := TILE_EMPTY
      else if tiles[j, i] = TILE_PLAYER then
      begin
        distance := TilePosToRealPos(tX, tY).Dist(TilePosToRealPos(j, i));
        player.DecreaseHealth(0.17);
      end
      else if tiles[j, i] = TILE_ENEMY then
      begin
        distance := TilePosToRealPos(tX, tY).Dist(TilePosToRealPos(j, i));
        enemy.DecreaseHealth(0.17);
      end
  end;

  //Нижняя
  for i := row + 1 to bottom do
  begin
    left := Clamp(col - (bottom - i), 0, TILES_X - 1);
    right := Clamp(col + (bottom - i), 0, TILES_X - 1);
    for j := left to right do
      tiles[j, i] := TILE_EMPTY;
  end;

  UpdateEarth(Clamp(col - bombRadius, 0, TILES_X - 1), Clamp(col + bombRadius, 0, TILES_X - 1));
  player.CheckForFall();
  enemy.CheckForFall();

  sound.PlaySample(soundExp);

  boomSpr.Width := TILE_SIZE * bombRadius * 2;
  boomSpr.Height := boomSpr.Width;
  boomSpr.Position := TilePosToRealPos(tX, tY);
  with boomSpr.Material.MaterialOptions do
    Tweener.AddTweenPSingle(@PDiffuse.w, tsExpoEaseIn, 1.0, 0.0, 0.7);
end;

constructor TpdEarth.Create;
begin
  inherited;
  boomSpr := Factory.NewSprite();
  boomSpr.Z := Z_TANK + 3;
  boomSpr.Material.Texture := texCircle;
  boomSpr.Material.MaterialOptions.Diffuse := colorExpl;
  boomSpr.UpdateTexCoords();
  boomSpr.SetSizeToTextureSize();
  boomSpr.PivotPoint := ppCenter;
end;

destructor TpdEarth.Destroy;
begin

  inherited;
end;

class function TpdEarth.Initialize(const aBMPFileName: String; aScene: Iglr2DScene): TpdEarth;

type
  TdfRGB = record
    B, G, R: Byte;
  end;

  TdfRGBArray = array[0..MaxInt div SizeOf(TdfRGB)-1] of TdfRGB;
  PdfRGBArray = ^TdfRGBArray;

  function IsWhite(aRGB: TdfRGB): Boolean;
  begin
    with aRGB do
      Result := (B = $FF) and (G = $FF) and (R = $FF);
  end;

  procedure LoadMap(var aEarth: TpdEarth);
  var
    bmp24: TBitmap;
    i, j: Integer;
    line: PdfRGBArray;
  begin
    bmp24 := TBitmap.Create();
    bmp24.LoadFromFile(aBMPFileName);
    with aEarth, bmp24 do
      for i := 0 to Height - 1 do
      begin
        line := ScanLine[i];
        for j := 0 to Width - 1 do
          if IsWhite(line[j]) then
            tiles[j, i] := TILE_EMPTY
          else
            tiles[j, i] := TILE_EARTH;
      end;
    bmp24.Free();
  end;

  procedure InitializeTileSprite(var aSpr: IglrSprite; const aPos: TdfVec2f);
  begin
    aSpr := Factory.NewSprite();
    with aSpr do
    begin
      Z := Z_TILES;
      Position := aPos;
      PivotPoint := ppTopLeft;
      Material.Texture := texTile;
      Material.MaterialOptions.Diffuse := dfVec4f(1, 1, 1, 1);
      UpdateTexCoords();
      Width := TILE_SIZE;
      Height := TILE_SIZE;
    end;
    aScene.RegisterElement(aSpr);
  end;

var
  i, j: Integer;

begin
  Result := TpdEarth.Create();
  LoadMap(Result);
  with Result do
  begin
    for i := 0 to TILES_Y - 1 do
      for j := 0 to TILES_X - 1 do
      begin
        InitializeTileSprite(tileSprites[j, i], dfVec2f(j * TILE_SIZE, i * TILE_SIZE));
        if tiles[j, i] = TILE_EMPTY then
          tileSprites[j, i].Visible := False;
      end;
    aScene.RegisterElement(boomSpr);
  end;
end;

procedure TpdEarth.MoveTileSprite(col, row, toRow: Integer; speed,
  pause: Single);
begin
  Tweener.AddTweenPSingle(@tileSprites[col, row].PPosition.y, tsSimple,
    tileSprites[col, row].Position.y, tileSprites[col, toRow].Position.y, 1 / speed, pause);
  tileSprites[col, toRow] := tileSprites[col, row];
end;

procedure TpdEarth.UpdateEarth(FromCol, ToCol: Integer);

  function GetEarthAbove(col, row: Integer): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    for i := row - 1 downto 0 do
      if tiles[col, i] = TILE_EARTH then
        Exit(i);
  end;

var
  i, j, earthAbove{, count}: Integer;
begin
  UpdateTileSprites();
  for i := FromCol to ToCol do
  begin
//    count := 0;
    for j := TILES_Y - 1 downto 0 do
      if (tiles[i, j] = TILE_EMPTY) then
      begin
        earthAbove := GetEarthAbove(i, j);
        if earthAbove <> -1 then
        begin
          MoveTileSprite(i, earthAbove, j, 2, 0); //count * 0.0.1 для пошагового
//          inc(Count);
          //Todo - красивое падение
          tiles[i, j] := tiles[i, earthAbove];
          tiles[i, earthAbove] := TILE_EMPTY;
        end
        else
          Break;
      end;
  end;
end;

procedure TpdEarth.UpdateTileSprites;
var
  i, j: Integer;
begin
  for i := 0 to TILES_Y - 1 do
    for j := 0 to TILES_X - 1 do
    begin
      tileSprites[j, i].Visible := (tiles[j, i] = TILE_EARTH);
//      with tileSprites[j, i].Material.MaterialOptions do
//        if tiles[j, i] = TILE_EARTH then
//          Diffuse := dfVec4f(1, 1, 1, 1)
//        else if tiles[j, i] = TILE_PLAYER then
//          Diffuse := dfVec4f(1, 0, 0, 1)
//        else if tiles[j, i] = TILE_ENEMY then
//          Diffuse := dfVec4f(0, 1, 0, 1);
    end;
end;

end.

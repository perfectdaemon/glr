unit uFont;

interface

uses
  Windows,
  Graphics,
  dfHRenderer, dfMath;

type
  TglrCharData = record
    ID   : WideChar; //символ
    w, h : Word;  //Размеры в пикселях
    tx, ty, tw, th : Single; //текстурные координаты и размер в текстурных единицах
  end;
  PdfCharData = ^TglrCharData;

  TglrFont = class(TInterfacedObject, IglrFont)
  private
    FFontName: String;
    FFontSize: Integer;
    FFontStyle: TFontStyles;

    //Список символов
    FChars: array of WideChar;
    FLastIndex: Integer;

    FTable: array[WideChar] of PdfCharData;

    FTexture: IglrTexture;

    function AlreadyHaveSymbol(aSymbol: Word): Boolean;
    procedure CreateFontResource(aFile: String);
    procedure RenderRangesToTexture();
    procedure ExpandCharArray();
  protected
    function GetTexture(): IglrTexture;
    function GetFontSize(): Integer;
    procedure SetFontSize(aSize: Integer);
    function GetFontStyle(): TFontStyles;
    procedure SetFontStyle(aStyle: TFontStyles);
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure AddRange(aStart, aStop: Word); overload;
    procedure AddRange(aStart, aStop: Char); overload;
    procedure AddSymbols(aText: WideString);

    property FontSize: Integer read GetFontSize write SetFontSize;
    property FontStyle: TFontStyles read GetFontStyle write SetFontStyle;

    procedure GenerateFromTTF(aFile: WideString; aFontName: WideString = '');
    procedure GenerateFromFont(aFontName: WideString);

    property Texture: IglrTexture read GetTexture;

    procedure PrintText(aText: IglrText);

    function GetTextLength(aText: WideString): Single;
    function GetTextSize(aText: IglrText): TdfVec2f;
    function IsSymbolExist(aSymbol: WideChar): Boolean;
  end;

implementation

uses
  dfHGL,
  uLogger,
  SysUtils,
  Classes,
  ExportFunc;

//Вся эта херота не работает, ибо формат ttf разный, в зависимости от
//одному богу известного расположения звезд (а не только от количества)
//шрифтов в ttf-файле
//Сраные идиоты из ms
{$REGION 'TTF file read - rewrite of c++ shitty code'}

{
type
  //This is TTF file header
  _tagTT_OFFSET_TABLE = record
    uMajorVersion,
    uMinorVersion,
    uNumOfTables,
    uSearchRange,
    uEntrySelector,
    uRangeShift: Word;
  end;

  //Tables in TTF file and there placement and name (tag)
  _tagTT_TABLE_DIRECTORY = record
    szTag: array[0..3] of AnsiChar; //table name
    uCheckSum,
    uOffset,
    uLength: LongWord;
  end;

  //Header of names table
  _tagTT_NAME_TABLE_HEADER = record
    uFSelector, //format selector. Always 0
    uNRCount, //Name Records count
    uStorageOffset: Word; //Offset for strings storage,
  end;

  //Record in names table
  _tagTT_NAME_RECORD = record
    uPlatformID,
    uEncodingID,
    uLanguageID,
    uNameID,
    uStringLength,
    uStringOffset: Word //from start of storage area
  end;


function SwapWord(w: Word): Word;
begin
  Result := MakeWord(HIBYTE(w), LOBYTE(w));
end;

function SwapLongWord(w: LongWord): LongWord;
begin
  Result := MakeLong(SwapWord(HIWORD(w)), SwapWord(LOWORD(w)));
end;


function GetFontNameFromTTF(const aFileName: String): String;
var
  s: TdfStream;
  offsetTable: _tagTT_OFFSET_TABLE;
  tableDir: _tagTT_TABLE_DIRECTORY;
  nameTable: _tagTT_NAME_TABLE_HEADER;
  nameRec: _tagTT_NAME_RECORD;

  bFound: Boolean;
  tmp: WideString;
  tmp2: AnsiString;
  i, aPos: Integer;
begin
  s := TdfStream.Init(aFileName);
  s.Read(offsetTable, SizeOf(_tagTT_OFFSET_TABLE));
  OffsetTable.uNumOfTables  := SwapWord(OffsetTable.uNumOfTables);
  OffsetTable.uMajorVersion := SwapWord(OffsetTable.uMajorVersion);
  OffsetTable.uMinorVersion := SwapWord(OffsetTable.uMinorVersion);

  if (OffsetTable.uMajorVersion <> 1) or
     (OffsetTable.uMinorVersion <> 0) then
  begin
    Exit('');
    s.Free();
  end;


  for i := 0 to OffsetTable.uNumOfTables - 1 do
  begin
    s.Read(tableDir, sizeof(tableDir));

    //the table's tag cannot exceed 4 characters
    tmp := tableDir.szTag;
    if (tmp = 'name') then
    begin
      //we found our table. Rearrange order and quit the loop
      bFound := True;
      tableDir.uLength := SwapLongWord(tableDir.uLength);
      tableDir.uOffset := SwapLongWord(tableDir.uOffset);
      break;
    end;
  end;

  if bFound then
  begin
    //move to offset we got from Offsets Table
    s.Pos := tableDir.uOffset;
    s.Read(nameTable, sizeof(nameTable));

    //again, don't forget to swap bytes!
    nameTable.uNRCount := SwapWord(nameTable.uNRCount);
    nameTable.uStorageOffset := SwapWord(nameTable.uStorageOffset);

    bFound := False;
    for i := 0 to nameTable.uNRCount - 1 do
    begin
      s.Read(nameRec, sizeof(nameRec));
      nameRec.uNameID := SWAPWORD(nameRec.uNameID);

      //1 says that this is font name. 0 for example determines copyright info
      if nameRec.uNameID = 1 then
      begin
        nameRec.uStringLength := SwapWord(nameRec.uStringLength);
        nameRec.uStringOffset := SwapWord(nameRec.uStringOffset);

        //save file position, so we can return to continue with search
        aPos := s.Pos;
        s.Pos := tableDir.uOffset + nameRec.uStringOffset + nameTable.uStorageOffset;
        SetLength(tmp2, nameRec.uStringLength);
        s.Read(tmp2[1], nameRec.uStringLength);

        if tmp2 <> '' then
        begin
          Result := tmp2;
          break;
        end;
        s.Pos := aPos;
      end;
    end;
  end;


  s.Free();
end;
}

{$ENDREGION}

{ TdfFont }

procedure TglrFont.AddRange(aStart, aStop: Word);
var
  i: Word;
begin
  for i := aStart to aStop do
    if not AlreadyHaveSymbol(i) then
    begin
      Inc(FLastIndex);
      if FLastIndex >= Length(FChars) then
        ExpandCharArray();
      FChars[FLastIndex] := WideChar(i);
    end;
end;

procedure TglrFont.AddRange(aStart, aStop: WideChar);
begin
  AddRange(Word(aStart), Word(aStop));
end;

procedure TglrFont.AddSymbols(aText: WideString);
var
  i: Word;
begin
  for i := 1 to Length(aText) do
    if not AlreadyHaveSymbol(Word(aText[i])) then
    begin
      Inc(FLastIndex);
      if FLastIndex >= Length(FChars) then
        ExpandCharArray();
      FChars[FLastIndex] := aText[i];
    end;
end;

function TglrFont.AlreadyHaveSymbol(aSymbol: Word): Boolean;
var
  i: Integer;
begin
  for i := 0 to FLastIndex do
    if FChars[i] = WideChar(aSymbol) then
      Exit(True);
  Exit(False);
end;

constructor TglrFont.Create;
begin
  inherited Create();
  FFontSize := 10;
  FFontStyle := [];
  ExpandCharArray();
  FLastIndex := -1;
end;

procedure TglrFont.CreateFontResource(aFile: String);
begin
  if (FileExists(aFile)) then
    if AddFontResourceEx(PChar(aFile), FR_PRIVATE, nil) <> 1 then
      logWriteError('uFont.pas: Ошибка добавления шрифта ' + aFile + ' в систему', true, true, true);
end;

destructor TglrFont.Destroy;
var
  i: WideChar;
begin
  for i := Low(FTable) to High(FTable) do
    if Assigned(FTable[i]) then
      Dispose(FTable[i]);
  FTexture := nil;
  SetLength(FChars, 0);
  inherited;
end;

procedure TglrFont.ExpandCharArray;
var
  l: Integer;
begin
  l := Length(FChars);
  if l = 0 then
    SetLength(FChars, 512)
  else
    SetLength(FChars, l + 256);
end;

function TglrFont.GetFontSize: Integer;
begin
  Result := FFontSize;
end;

function TglrFont.GetFontStyle: TFontStyles;
begin
  Result := FFontStyle;
end;

function TglrFont.GetTextLength(aText: WideString): Single;
begin

end;

function TglrFont.GetTextSize(aText: IglrText): TdfVec2f;
var
  i: Integer;
  tmpWidth: Single;
begin
  tmpWidth := 0;
  Result.Reset();
  for i := 1 to Length(aText.Text) do
    if FTable[aText.Text[i]] <> nil then
      with FTable[aText.Text[i]]^ do
      begin
        if ID = #10 then
        begin
          Result.y := Result.y + h + 1;
          if tmpWidth > Result.x then
            Result.x := tmpWidth;
          tmpWidth := 0;
          continue;
        end;
        tmpWidth := tmpWidth + w;
      end;
  Result.x := Max(Result.x, tmpWidth);
  Result := Result * aText.Scale;
end;

function TglrFont.GetTexture: IglrTexture;
begin
  Result := FTexture;
end;

function TglrFont.IsSymbolExist(aSymbol: WideChar): Boolean;
begin
  Result := (FTable[aSymbol] <> nil) or (aSymbol = #10) or (aSymbol = #13);
end;

procedure TglrFont.PrintText(aText: IglrText);
var
  i: Integer;
  px, py: Single;
  scale, pivot: TdfVec2f;
  z: Single;
begin
  FTexture.Bind;
  scale := aText.Scale;
  pivot := aText.Coords[2]; //Top left corner coordinates
  z := aText.GetInternalZ();
  gl.Beginp(GL_QUADS);
    px := pivot.x;
    py := pivot.y;
    for i := 1 to Length(aText.Text) do
      if FTable[aText.Text[i]] <> nil then
        with FTable[aText.Text[i]]^ do
        begin
          if ID = #10 then
          begin
            px := pivot.x;
            py := py + h + 1;
            continue;
          end;

          gl.TexCoord2f(tx, ty);           gl.Vertex3f(px * scale.x, scale.y * py, z);
          gl.TexCoord2f(tx, ty + th);      gl.Vertex3f(px * scale.x, scale.y * (py + h), z);
          gl.TexCoord2f(tx + tw, ty + th); gl.Vertex3f((px + w) * scale.x, scale.y * (py + h), z);
          gl.TexCoord2f(tx + tw, ty);      gl.Vertex3f((px + w) * scale.x, scale.y * py, z);
          px := px + w;
        end;
  gl.Endp;
  FTexture.Unbind();
end;

procedure TglrFont.GenerateFromFont(aFontName: WideString);
begin
  FFontName := aFontName;
  RenderRangesToTexture();
  logWriteMessage('uFont.pas: Шрифт «' + FFontName + '» отрендерен в текстуру');
end;

procedure TglrFont.GenerateFromTTF(aFile: WideString; aFontName: WideString = '');
begin
  if aFontName = '' then
    FFontName := Copy(ExtractFileName(aFile), 0, Pos('.', ExtractFileName(aFile)) - 1)
  else
    FFontName := aFontName;
  logWriteMessage('uFont.pas: Загрузка шрифта «' + FFontName + '» из ' + aFile);
  CreateFontResource(aFile);
  logWriteMessage('uFont.pas: Шрифт «' + FFontName + '» добавлен в систему');
  RenderRangesToTexture();
  logWriteMessage('uFont.pas: Шрифт «' + FFontName + '» отрендерен в текстуру');
end;

procedure TglrFont.RenderRangesToTexture;

{Данные типы используются для считывания и записи информации в битмапах
 при помощи TBitmap.ScanLine()}
type
  TdfRGBA = record
    B, G, R, A: Byte;
  end;
  TdfRGBAArray = array[0..MaxInt div SizeOf(TdfRGBA)-1] of TdfRGBA;
  PdfRGBAArray = ^TdfRGBAArray;

  TdfRGB = record
    B, G, R: Byte;
  end;
  TdfRGBArray = array[0..MaxInt div SizeOf(TdfRGB)-1] of TdfRGB;
  PdfRGBArray = ^TdfRGBArray;

var
  bmp24, bmp32: TBitmap;
  rect: TRect; //используется для заливки тексуры
  row_height: Integer; //счетчики и высота строки
  i: Integer;
  offsetX, offsetY: Integer; //смещение внутри битмапа для текущего выводимого символа
  cdata: PdfCharData;

//  tmpStream: TMemoryStream;
//  mem: Pointer;
//  siz: Integer;
//  texStream: TdfStream;

  {
  function GetTextSize(DC: HDC; Str: PWideChar; Count: Integer): TSize;
    var tm: TTextMetricW;
  begin
    Result.cx := 0;
    Result.cy := 0;
    GetTextExtentPoint32W(DC, Str, Count, Result);
    GetTextMetricsW(DC, tm);
    if tm.tmPitchAndFamily and TMPF_TRUETYPE <> 0 then
      Result.cx := Result.cx - tm.tmOverhang
    else
      Result.cx := tm.tmAveCharWidth * Count;
  end;
  }


  {Перемещаем информацию из 24-битного битмапа в 32-битный
   Используем RGB-составляющие входящего битмапа и записываем их среднее
   арифметическое в алька-канал 32-битного белого битмапа}
  function CreateBitmap32FromBitmap24(bmp24: TBitmap): TBitmap;
  var
    line1: PdfRGBArray;
    line2: PdfRGBAArray;
    i, j: Integer;
  begin
    Result := TBitmap.Create();
    Result.PixelFormat := pf32bit;
    Result.Width := bmp24.Width;
    Result.Height := bmp24.Height;

    for i := 0 to bmp24.Height - 1 do
    begin
      line1 := bmp24.ScanLine[i];
      line2 := Result.ScanLine[i];
      for j := 0 to bmp24.Width - 1 do
        line2[j].A := (line1[j].B + line1[j].G + line1[j].R) div 3;
    end;
  end;

begin
  bmp24 := TBitmap.Create();
  with bmp24 do
  begin
    {DEBUG!!!}
    Width := 512;
    Height := 256;
    {/DEBUG}
    PixelFormat := pf24bit;
    with Canvas.Font do
    begin
      Name := FFontName;
      Color := clWhite;
      Size := FFontSize;
      Style := FFontStyle;
    end;
  end;


  with rect do
  begin
    Left := 0;
    Top := 0;
    Right := bmp24.Width;
    Bottom := bmp24.Height;
  end;
  bmp24.Canvas.Brush.Color := clBlack;
  bmp24.Canvas.FillRect(rect);

  offsetX := 1;
  offsetY := 0;
  row_height := bmp24.Canvas.TextExtent('A').cy + 2;
  i := 0;

  while i <= FLastIndex do
  begin
    while (offsetX + bmp24.Canvas.TextExtent(FChars[i] + ' ').cx < bmp24.Width) and (i <= FLastIndex) do
    begin
      New(cdata);
      with cdata^ do
      begin
        ID := FChars[i];
        w := bmp24.Canvas.TextExtent(ID).cx;
        if w = 0 then
        begin
          Dispose(cdata);
          Inc(i);
          continue;
        end;
        h := row_height;
        tx := offsetX / bmp24.Width;
        ty := offsetY / bmp24.Height;
        tw := w / bmp24.Width;
        th := h / bmp24.Height;
        bmp24.Canvas.TextOut(offsetX, offsetY, ID);
        offsetX := offsetX + w + 2;
      end;
      FTable[FChars[i]] := cdata;
      Inc(i);
    end;
    offsetY := offsetY + row_height;
    offsetX := 1;
  end;
//  i := Low(FTable);

//  repeat
//    if FTable[i] <> nil then
//    begin
//      repeat
//        if FTable[i] <> nil then
//          with FTable[i]^ do
//          begin
//            w := bmp24.Canvas.TextExtent(ID).cx;//GetTextSize(bmp24.Canvas.Handle, @ID, 1).cx;
//            h := row_height;
//            tx := offsetX / bmp24.Width;
//            ty := offsetY / bmp24.Height;
//            tw := w / bmp24.Width;
//            th := h / bmp24.Height;
//            bmp24.Canvas.TextOut(offsetX, offsetY, ID);
//            if w > 0 then
//              offsetX := offsetX + w + 2
//            else
//              Dispose(FTable[i]);
//          end;
//        Inc(i);
//      until (offsetX + bmp24.Canvas.TextExtent(i + ' ').cx > bmp24.Width) or (i >= High(FTable));
//      offsetY := offsetY + row_height;
//      offsetX := 1;
//    end
//    else
//      Inc(i);
//  until i >= High(FTable);

  bmp32 := CreateBitmap32FromBitmap24(bmp24);
  {DEBUG}
  //bmp24.SaveToFile('data\2.bmp');
  bmp32.SaveToFile('textcache.bmp');
  {/DEBUG}
  FTexture := GetObjectFactory().NewTexture();
  FTexture.Load2D('textcache.bmp'); //DEBUG
//  FTexture.Load2D(texStream, 'BMP');
  FTexture.CombineMode := tcmModulate;
  FTexture.BlendingMode := tbmTransparency;
  FTexture.MinFilter := tmnLinear;
  FTexture.MagFilter := tmgLinear;

  bmp24.Free;
  bmp32.Free;
  DeleteFile('textcache.bmp');
//  tmpStream.Free;
//  texStream.Free;
end;

procedure TglrFont.SetFontSize(aSize: Integer);
begin
  if aSize > 0 then
    FFontSize := aSize;
end;

procedure TglrFont.SetFontStyle(aStyle: TFontStyles);
begin
  FFontStyle := aStyle;
end;

end.

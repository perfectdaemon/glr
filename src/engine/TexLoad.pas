{
Все переписано, теперь нижеописанное неактуально

- Pirate copy from Fantom's project glsnewton from code.google

-  Куча говнокода, в который не вникал.

+ TODO: Переписать загрузку tga и bmp. Полный аврал

 =)
}

unit TexLoad;

interface

uses
  dfHGL, dfHRenderer,
  Windows, Graphics, {Classes,} SysUtils;

function LoadTexture(const Stream: TglrStream; ext: String; var iFormat,cFormat,dType: TGLConst; var pSize: Integer; var Width, Height: Integer): Pointer; overload;
//function LoadTexture(Filename: String; var Format: TGLConst; var Width, Height: Integer): Pointer;overload;
function LoadTexture(Filename: String; var iFormat,cFormat,dType: TGLConst; var pSize: Integer; var Width, Height: Integer): Pointer; overload;

implementation

uses
  uLogger;

{------------------------------------------------------------------}
{  Swap bitmap format from BGR to RGB                              }
{------------------------------------------------------------------}
//procedure SwapRGB(data : Pointer; Size : Integer);
//asm
//  mov ebx, eax
//  mov ecx, size
//
//@@loop :
//  mov al,[ebx+0]
//  mov ah,[ebx+2]
//  mov [ebx+2],al
//  mov [ebx+0],ah
//  add ebx,3
//  dec ecx
//  jnz @@loop
//end;

procedure flipSurface(chgData: Pbyte; w, h, pSize: integer);
var
  lineSize: integer;
  sliceSize: integer;
  tempBuf: Pbyte;
  j: integer;
  top, bottom: Pbyte;
begin
  lineSize := pSize * w;
  sliceSize := lineSize * h;
  GetMem(tempBuf, lineSize);

  top := chgData;
  bottom := top;
  Inc(bottom, sliceSize - lineSize);

  for j := 0 to (h div 2) - 1 do begin
    Move(top^, tempBuf^, lineSize);
    Move(bottom^, top^, lineSize);
    Move(tempBuf^, bottom^, lineSize);
    Inc(top, lineSize);
    Dec(bottom, lineSize);
  end;
  FreeMem(tempBuf);
end;

function myLoadBMPTexture(Stream: TglrStream; var Format : TGLConst; var Width, Height: Integer): Pointer;
var
  FileHeader: BITMAPFILEHEADER;
  InfoHeader: BITMAPINFOHEADER;
  BytesPP: Integer;
  imageSize: Integer;
  image: Pointer;
  sLength, fLength, tmp: Integer;
  absHeight: Integer;
  i: Integer;
begin
  Result := nil;

  Stream.Read(FileHeader, SizeOf(FileHeader));
  Stream.Read(InfoHeader, SizeOf(InfoHeader));

  if InfoHeader.biClrUsed <> 0 then
  begin
    logWriteError('TexLoad: Ошибка загрузки BMP из потока. ColorMaps не поддерживаются');
    Exit(nil);
  end;

  Width := InfoHeader.biWidth;
  Height := InfoHeader.biHeight;
  //Если высота отрицательная, то битмап читается сверху вниз
  //flip не нужен
  absHeight := Abs(Height);
  BytesPP := InfoHeader.biBitCount div 8;
  case BytesPP of
    3: Format := GL_BGR;
    4: Format := GL_BGRA;
  end;
  imageSize := Width * absHeight * BytesPP;

  sLength := Width * BytesPP;
  fLength := 0;
  if frac(sLength / 4) > 0 then
    fLength := ((sLength div 4) + 1) * 4 - sLength;
  GetMem(image, imageSize);
  Result := image;
  for i := 0 to absHeight - 1 do
  begin
    Stream.Read(image^, sLength);
    Stream.Read(tmp, fLength);
    Inc(integer(image), sLength);
  end;
end;
(*

{------------------------------------------------------------------}
{  Load BMP textures                                               }
{------------------------------------------------------------------}
function LoadBMPTexture(Filename: String; var Format : TGLConst; var Width, Height: Integer): Pointer;
var
  FileHeader: BITMAPFILEHEADER;
  InfoHeader: BITMAPINFOHEADER;
  Palette: array of RGBQUAD;
  BitmapFile: THandle;
  BitmapLength: LongWord;
  PaletteLength: LongWord;
  ReadBytes: LongWord;
  pData : Pointer;
  //For 256 color bitmap
  bmp: TBitmap;
  bpp:byte;
  i,j, offs: integer;
  p: PByteArray;
  sLength: integer;
  fLength,temp: integer;
begin
  result :=nil;
  Width:=-1; Height:=-1;
  // Load image from file
    BitmapFile := CreateFile(PChar(Filename), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
    if (BitmapFile = INVALID_HANDLE_VALUE) then begin
      MessageBox(0, PChar('Error opening ' + Filename), PChar('BMP Unit'), MB_OK);
      Exit;
    end;

    // Get header information
    ReadFile(BitmapFile, FileHeader, SizeOf(FileHeader), ReadBytes, nil);
    ReadFile(BitmapFile, InfoHeader, SizeOf(InfoHeader), ReadBytes, nil);
    Width  := InfoHeader.biWidth;
    Height := InfoHeader.biHeight;

    if InfoHeader.biClrUsed<>0 then begin
       CloseHandle(BitmapFile);
       bmp:=TBitmap.Create; bmp.LoadFromFile(Filename);
       bmp.PixelFormat:=pf24bit; bpp:=3;
       getmem(pData,bmp.Width*bmp.Height*bpp);
       for i:=bmp.Height-1 downto 0 do begin
         p:=bmp.ScanLine[i]; offs:=i*bmp.Width*bpp;
         for j:=0 to bmp.Width-1 do begin
            PByteArray(pData)[offs+j*bpp]:=p[j*bpp+2];
            PByteArray(pData)[offs+j*bpp+1]:=p[j*bpp+1];
            PByteArray(pData)[offs+j*bpp+2]:=p[j*bpp];
         end;
       end; Width:=bmp.Width; Height:=bmp.Height;
       result:=pData; Format:=GL_RGB; bmp.Free; exit;
    end;

    //BitmapLength := InfoHeader.biSizeImage;
    //if BitmapLength = 0 then
    bpp:=InfoHeader.biBitCount Div 8;
    BitmapLength := Width * Height * bpp;
    sLength:=Width*bpp; fLength:=0;
    if frac(sLength/4)>0 then fLength:=((sLength div 4)+1)*4-sLength;
    // Get the actual pixel data
    GetMem(pData, BitmapLength);
    result:=pData;
    for i:=0 to Height-1 do begin
      ReadFile(BitmapFile, pData^, sLength , ReadBytes, nil);
      ReadFile(BitmapFile, Temp, fLength , ReadBytes, nil);
      inc(integer(pData),sLength);
    end;
{    ReadFile(BitmapFile, pData^, BitmapLength, ReadBytes, nil);
    if (ReadBytes <> BitmapLength) then begin
      MessageBox(0, PChar('Error reading bitmap data'), PChar('BMP Unit'), MB_OK);
      Exit;
    end;
}
    CloseHandle(BitmapFile);

  // Bitmaps are stored BGR and not RGB, so swap the R and B bytes.
  if bpp=3 then begin SwapRGB(Result, Width*Height); Format:=GL_RGB; end;
  if bpp=4 then begin Format:=GL_BGRA; end;

end;

*)


{------------------------------------------------------------------}
{  Loads 24 and 32bpp (alpha channel) TGA textures                 }
{------------------------------------------------------------------}

type
   TTGAHeader = packed record
     IDLength          : Byte;
     ColorMapType      : Byte;
     ImageType         : Byte;
     ColorMapOrigin    : Word;
     ColorMapLength    : Word;
     ColorMapEntrySize : Byte;
     XOrigin           : Word;
     YOrigin           : Word;
     Width             : Word;
     Height            : Word;
     PixelSize         : Byte;
     ImageDescriptor   : Byte;
  end;

function myLoadTGATexture(Stream: TglrStream; var Format: TGLConst; var Width, Height: Integer): Pointer; overload;
var
  //tgaFile: File;
  tgaHeader: TTGAHeader;
  colorDepth: Integer; //число бит на пиксель
  bytesPP: Integer; //число байт на пиксель
  imageSize: Integer; //размер изображения в байтах

  image: Pointer; //само изображение

  procedure ReadUncompressedTGA();
  var
    bytesRead: Integer;
    i: Integer;
    Blue, Red: ^Byte;
    Tmp: Byte;
  begin
    bytesRead := Stream.Read(image^, imageSize);
    //Считано меньше, чем необходимо
    if (bytesRead <> imageSize) then
    begin
      logWriteError('TexLoad: Ошибка загрузки TGA из потока. Ошибка при чтении несжатых данных');
      Exit();
    end;
    //Флипаем bgr(a) в rgb(a)
    for i :=0 to Width * Height - 1 do
    begin
      Blue := Pointer(Integer(image) + i * bytesPP + 0);
      Red  := Pointer(Integer(image) + i * bytesPP + 2);
      Tmp := Blue^;
      Blue^ := Red^;
      Red^ := Tmp;
    end;
  end;

  procedure CopySwapPixel(const Source, Destination: Pointer);
  asm
    push ebx
    mov bl,[eax+0]
    mov bh,[eax+1]
    mov [edx+2],bl
    mov [edx+1],bh
    mov bl,[eax+2]
    mov bh,[eax+3]
    mov [edx+0],bl
    mov [edx+3],bh
    pop ebx
  end;

  procedure ReadCompressedTGA();
  var
    bufferIndex, currentByte, currentPixel: Integer;
    compressedImage: Pointer;

    bytesRead: Integer;

    i: Integer;

    First: ^Byte;
  begin
    currentByte := 0;
    currentPixel := 0;
    bufferIndex := 0;

    GetMem(compressedImage, Stream.Size - SizeOf(tgaHeader));
    bytesRead := Stream.Read(compressedImage^, Stream.Size - SizeOf(tgaHeader));
    if bytesRead <> Stream.Size - SizeOf(tgaHeader) then
    begin
      logWriteError('TexLoad: Ошибка загрузки TGA из потока. Ошибка при чтении сжатых данных');
      Exit();
    end;

    //Извлекаем данные о пикселях, сжатых по RLE
    repeat
      First := Pointer(Integer(compressedImage) + BufferIndex);
      Inc(BufferIndex);
      if First^ < 128 then //Незапакованные данные
      begin
        for i := 0 to First^ do
        begin
          CopySwapPixel(Pointer(Integer(compressedImage)+ BufferIndex + i * bytesPP), Pointer(Integer(image) + CurrentByte));
          CurrentByte := CurrentByte + bytesPP;
          inc(CurrentPixel);
        end;
        BufferIndex := BufferIndex + (First^ + 1) * bytesPP
      end
      else  //Запакованные данные
      begin
        for i := 0 to First^ - 128 do
        begin
          CopySwapPixel(Pointer(Integer(compressedImage) + BufferIndex), Pointer(Integer(image) + CurrentByte));
          CurrentByte := CurrentByte + bytesPP;
          inc(CurrentPixel);
        end;
        BufferIndex := BufferIndex + bytesPP;
      end;
    until CurrentPixel >= Width * Height;

    FreeMem(compressedImage, Stream.Size - SizeOf(tgaHeader));
  end;

begin
  Result := nil;
  //Читаем заголовок
  Stream.Read(tgaHeader, SizeOf(TTGAHeader));

  Width := tgaHeader.Width;
  Height := tgaHeader.Height;
  colorDepth := tgaHeader.PixelSize;
  bytesPP := ColorDepth div 8;
  imageSize := Width * Height * bytesPP;

  GetMem(image, ImageSize);

  case bytesPP of
    3: Format := GL_RGB;
    4: Format := GL_RGBA;
  end;

  {$REGION ' Неподдерживаемые типы tga '}

  if (colorDepth <> 24) and (colorDepth <> 32) then
  begin
    logWriteError('TexLoad: Ошибка загрузки TGA из потока. BPP отлично от 24 и 32');
    Exit(nil);
  end;

  if tgaHeader.ColorMapType <> 0 then
  begin
    logWriteError('TexLoad: Ошибка загрузки TGA из потока. ColorMap не поддерживаются');
    Exit(nil);
  end;

  {$ENDREGION}

  case tgaHeader.ImageType of
    2: {Несжатый tga} ReadUncompressedTGA();
    10: {Сжатый tga} ReadCompressedTGA();
    else
    begin
      logWriteError('TexLoad: Ошибка загрузки TGA из потока. Поддерживаются только несжатые и RLE-сжатые tga');
      Exit(nil);
    end;
  end;
  Result := image;
end;

(*

function myLoadTGATexture(FileName: String; var Format: TGLConst; var Width, Height: Integer): Pointer; overload;
var
  tgaFile: File;
  tgaHeader: TTGAHeader;
  colorDepth: Integer; //число бит на пиксель
  bytesPP: Integer; //число байт на пиксель
  imageSize: Integer; //размер изображения в байтах

  image: Pointer; //само изображение

  procedure ReadUncompressedTGA();
  var
    bytesRead: Integer;
    i: Integer;
    Blue, Red: ^Byte;
    Tmp: Byte;
  begin
    BlockRead(tgaFile, image^, imageSize, bytesRead);
    //Считано меньше, чем необходимо
    if (bytesRead <> imageSize) then
    begin
      logWriteError('TexLoad: Ошибка загрузки '+ FileName + '. Ошибка при чтении несжатых данных');
      CloseFile(tgaFile);
      Exit();
    end;
    //Флипаем bgr(a) в rgb(a)
    for i :=0 to Width * Height - 1 do
    begin
      Blue := Pointer(Integer(image) + i * bytesPP + 0);
      Red  := Pointer(Integer(image) + i * bytesPP + 2);
      Tmp := Blue^;
      Blue^ := Red^;
      Red^ := Tmp;
    end;
  end;

  procedure CopySwapPixel(const Source, Destination: Pointer);
  asm
    push ebx
    mov bl,[eax+0]
    mov bh,[eax+1]
    mov [edx+2],bl
    mov [edx+1],bh
    mov bl,[eax+2]
    mov bh,[eax+3]
    mov [edx+0],bl
    mov [edx+3],bh
    pop ebx
  end;

  procedure ReadCompressedTGA();
  var
    bufferIndex, currentByte, currentPixel: Integer;
    compressedImage: Pointer;

    bytesRead: Integer;

    i: Integer;

    First: ^Byte;
  begin
    currentByte := 0;
    currentPixel := 0;
    bufferIndex := 0;

    GetMem(compressedImage, FileSize(tgaFile) - SizeOf(tgaHeader));
    BlockRead(tgaFile, compressedImage^, FileSize(tgaFile) - SizeOf(tgaHeader), BytesRead);
    if bytesRead <> FileSize(tgaFile) - SizeOf(tgaHeader) then
    begin
      logWriteError('TexLoad: Ошибка загрузки '+ FileName + '. Ошибка при чтении сжатых данных');
      CloseFile(tgaFile);
      Exit();
    end;

    //Извлекаем данные о пикселях, сжатых по RLE
    repeat
      First := Pointer(Integer(compressedImage) + BufferIndex);
      Inc(BufferIndex);
      if First^ < 128 then //Незапакованные данные
      begin
        for i := 0 to First^ do
        begin
          CopySwapPixel(Pointer(Integer(compressedImage)+ BufferIndex + i * bytesPP), Pointer(Integer(image) + CurrentByte));
          CurrentByte := CurrentByte + bytesPP;
          inc(CurrentPixel);
        end;
        BufferIndex := BufferIndex + (First^ + 1) * bytesPP
      end
      else  //Запакованные данные
      begin
        for i := 0 to First^ - 128 do
        begin
          CopySwapPixel(Pointer(Integer(compressedImage) + BufferIndex), Pointer(Integer(image) + CurrentByte));
          CurrentByte := CurrentByte + bytesPP;
          inc(CurrentPixel);
        end;
        BufferIndex := BufferIndex + bytesPP;
      end;
    until CurrentPixel >= Width * Height;

    FreeMem(compressedImage, FileSize(tgaFile) - SizeOf(tgaHeader));
  end;

begin
  Result := nil;

  AssignFile(tgaFile, FileName);
  Reset(tgaFile, 1);
  //Читаем заголовок
  BlockRead(tgaFile, tgaHeader, SizeOf(TTGAHeader));

  Width := tgaHeader.Width;
  Height := tgaHeader.Height;
  colorDepth := tgaHeader.PixelSize;
  bytesPP := ColorDepth div 8;
  imageSize := Width * Height * bytesPP;

  GetMem(image, ImageSize);

  case bytesPP of
    3: Format := GL_RGB;
    4: Format := GL_RGBA;
  end;

  {$REGION ' Неподдерживаемые типы tga '}

  if (colorDepth <> 24) and (colorDepth <> 32) then
  begin
    logWriteError('TexLoad: Ошибка загрузки '+ FileName + '. BPP отлично от 24 и 32');
    CloseFile(tgaFile);
    Exit(nil);
  end;

  if tgaHeader.ColorMapType <> 0 then
  begin
    logWriteError('TexLoad: Ошибка загрузки '+ FileName + '. ColorMap tga не поддерживаются');
    CloseFile(tgaFile);
    Exit(nil);
  end;

  {$ENDREGION}

  case tgaHeader.ImageType of
    2: {Несжатый tga} ReadUncompressedTGA();
    10: {Сжатый tga} ReadCompressedTGA();
    else
    begin
      logWriteError('TexLoad: Ошибка загрузки '+ FileName + '. Поддерживаются только несжатые и RLE-сжатые tga');
      CloseFile(tgaFile);
      Exit(nil);
    end;
  end;
  CloseFile(tgaFile);
  Result := image;
end;

*)

//function myLoadTGATexture(FileName: String; var Format: TGLConst; var Width, Height: Integer): Pointer; overload;
//var
//  stream: TdfStream;
//begin
//  stream := TdfStream.Init(FileName, False);
//  Result := myLoadTGATexture(stream, Format, Width, Height);
//  stream.Free;
//end;

(*

function LoadTGATexture(Filename: String; var Format: TGLConst; var Width, Height: integer): pointer;
var
  TGAHeader : packed record   // Header type for TGA images
    FileType     : Byte;
    ColorMapType : Byte;
    ImageType    : Byte;
    ColorMapSpec : Array[0..4] of Byte;
    OrigX  : Array [0..1] of Byte;
    OrigY  : Array [0..1] of Byte;
    Width  : Array [0..1] of Byte;
    Height : Array [0..1] of Byte;
    BPP    : Byte;
    ImageInfo : Byte;
  end;
  TGAFile   : File;
  bytesRead : Integer;
  image     : Pointer;    {or PRGBTRIPLE}
  CompImage : Pointer;
  ColorDepth    : Integer;
  ImageSize     : Integer;
  BufferIndex : Integer;
  currentByte : Integer;
  CurrentPixel : Integer;
  I : Integer;
  Front: ^Byte;
  Back: ^Byte;
  Temp: Byte;

  ResStream : TResourceStream;      // used for loading from resource

  // Copy a pixel from source to dest and Swap the RGB color values
  procedure CopySwapPixel(const Source, Destination : Pointer);
  asm
    push ebx
    mov bl,[eax+0]
    mov bh,[eax+1]
    mov [edx+2],bl
    mov [edx+1],bh
    mov bl,[eax+2]
    mov bh,[eax+3]
    mov [edx+0],bl
    mov [edx+3],bh
    pop ebx
  end;
var loaded: boolean;
begin
  result :=nil;
  if FileExists(Filename) then begin
    AssignFile(TGAFile, Filename);
    Reset(TGAFile, 1);

    // Read in the bitmap file header
    BlockRead(TGAFile, TGAHeader, SizeOf(TGAHeader));
    loaded:=true;
  end
  else
  begin
    MessageBox(0, PChar('File not found  - ' + Filename), PChar('TGA Texture'), MB_OK);
    Exit;
  end;

  if loaded then begin
    Result := nil;

    // Only support 24, 32 bit images
    if (TGAHeader.ImageType <> 2) AND    { TGA_RGB }
       (TGAHeader.ImageType <> 10) then  { Compressed RGB }
    begin
      Result := nil;
      CloseFile(tgaFile);
      MessageBox(0, PChar('Couldn''t load "'+ Filename +'". Only 24 and 32bit TGA supported.'), PChar('TGA File Error'), MB_OK);
      Exit;
    end;

    // Don't support colormapped files
    if TGAHeader.ColorMapType <> 0 then
    begin
      Result := nil;
      CloseFile(TGAFile);
      MessageBox(0, PChar('Couldn''t load "'+ Filename +'". Colormapped TGA files not supported.'), PChar('TGA File Error'), MB_OK);
      Exit;
    end;

    // Get the width, height, and color depth
    Width  := TGAHeader.Width[0]  + TGAHeader.Width[1]  * 256;
    Height := TGAHeader.Height[0] + TGAHeader.Height[1] * 256;
    ColorDepth := TGAHeader.BPP;
    ImageSize  := Width*Height*(ColorDepth div 8);

    if ColorDepth < 24 then
    begin
      Result := nil;
      CloseFile(TGAFile);
      MessageBox(0, PChar('Couldn''t load "'+ Filename +'". Only 24 and 32 bit TGA files supported.'), PChar('TGA File Error'), MB_OK);
      Exit;
    end;

    GetMem(Image, ImageSize);

    if TGAHeader.ImageType = 2 then begin  // Standard 24, 32 bit TGA file
        BlockRead(TGAFile, image^, ImageSize, bytesRead);
        if bytesRead <> ImageSize then begin
          Result := nil;
          CloseFile(TGAFile);
          MessageBox(0, PChar('Couldn''t read file "'+ Filename +'".'), PChar('TGA File Error'), MB_OK);
          Exit;
        end;
      // TGAs are stored BGR and not RGB, so swap the R and B bytes.
      // 32 bit TGA files have alpha channel and gets loaded differently
      if TGAHeader.BPP = 24 then begin
        for I :=0 to Width * Height - 1 do begin
          Front := Pointer(Integer(Image) + I*3);
          Back := Pointer(Integer(Image) + I*3 + 2);
          Temp := Front^;
          Front^ := Back^;
          Back^ := Temp;
        end;
        Result := Image; Format := GL_RGB;
      end else begin
        for I :=0 to Width * Height - 1 do begin
          Front := Pointer(Integer(Image) + I*4);
          Back := Pointer(Integer(Image) + I*4 + 2);
          Temp := Front^;
          Front^ := Back^;
          Back^ := Temp;
        end;
        Result := Image; Format := GL_RGBA;
      end;
    end;

    // Compressed 24, 32 bit TGA files
    if TGAHeader.ImageType = 10 then begin
      ColorDepth :=ColorDepth DIV 8;
      CurrentByte :=0;
      CurrentPixel :=0;
      BufferIndex :=0;

        GetMem(CompImage, FileSize(TGAFile)-sizeOf(TGAHeader));
        BlockRead(TGAFile, CompImage^, FileSize(TGAFile)-sizeOf(TGAHeader), BytesRead);   // load compressed data into memory
        if bytesRead <> FileSize(TGAFile)-sizeOf(TGAHeader) then
        begin
          Result := nil;
          CloseFile(TGAFile);
          MessageBox(0, PChar('Couldn''t read file "'+ Filename +'".'), PChar('TGA File Error'), MB_OK);
          Exit;
        end;

      // Extract pixel information from compressed data
      repeat
        Front := Pointer(Integer(CompImage) + BufferIndex);
        Inc(BufferIndex);
        if Front^ < 128 then begin
          for I := 0 to Front^ do begin
            CopySwapPixel(Pointer(Integer(CompImage)+BufferIndex+I*ColorDepth), Pointer(Integer(image)+CurrentByte));
            CurrentByte := CurrentByte + ColorDepth;
            inc(CurrentPixel);
          end;
          BufferIndex :=BufferIndex + (Front^+1)*ColorDepth
        end else begin
          for I := 0 to Front^ -128 do begin
            CopySwapPixel(Pointer(Integer(CompImage)+BufferIndex), Pointer(Integer(image)+CurrentByte));
            CurrentByte := CurrentByte + ColorDepth;
            inc(CurrentPixel);
          end;
          BufferIndex :=BufferIndex + ColorDepth
        end;
      until CurrentPixel >= Width*Height;
      Result := Image;
      if ColorDepth = 3 then Format := GL_RGB
      else Format := GL_RGBA;
    end;
  end;
end;

             *)


{------------------------------------------------------------------}
{  Determines file type and sends to correct function              }
{------------------------------------------------------------------}
//function LoadTexture(Filename: String; var Format: TGLConst;
//  var Width, Height: integer): Pointer; overload;
//var
//  ext: string;
//  ColorFormat,DataType: TGLConst;
//  eSize: Integer;
//begin
//  Result := nil;
//  ext := copy(Uppercase(filename), length(filename) - 3, 4);
//  if ext = '.BMP' then
//    Result := LoadBMPTexture(Filename, Format, Width, Height);
//  if ext = '.TGA' then
//    Result := LoadTGATexture(Filename, Format, Width, Height);
//  if ext = '.PNG' then
//  begin
//    //LoadPNG(result,PWideChar(FileName),ColorFormat,Format,DataType,eSize,Width,Height);
//  end;
//
////  flipSurface(result,Width,Height,eSize);
//end;

function LoadTexture(const Stream: TglrStream; ext: String; var iFormat, cFormat, dType: TGLConst;
  var pSize: Integer; var Width, Height: Integer): Pointer; overload;
begin
  Result := nil;
  if ext = 'BMP' then
  begin
    Result := myLoadBMPTexture(Stream, cFormat, Width, Height);
    if cFormat = GL_BGRA then
    begin
      iFormat := GL_RGBA8;
      dType := GL_UNSIGNED_BYTE;
      pSize := 4;
    end
    else
    begin
      iFormat := GL_RGB8;
      dType := GL_UNSIGNED_BYTE;
      pSize := 3;
    end;
    if Height > 0 then
      flipSurface(Result, Width, Height, pSize);
  end;
  if ext = 'TGA' then
  begin
    Result := myLoadTGATexture(Stream, cFormat, Width, Height);
    if cFormat = GL_RGB then
    begin
      iFormat := GL_RGB8;
      pSize := 3;
    end
    else
    begin
      iFormat := GL_RGBA8;
      pSize := 4;
    end;
    dType := GL_UNSIGNED_BYTE;

    flipSurface(Result, Width, Height, pSize);
  end;

  if ext = 'PNG' then
  begin
    Assert(ext <> 'PNG', 'PNG is not supported yet');
    //LoadPNG(result,PWideChar(FileName),iFormat,cFormat,dType,pSize,Width,Height);
  end;
end;
(*

function LoadTexture(Filename: String; var iFormat,cFormat,dType: TGLConst; var pSize: Integer;
  var Width, Height: integer): pointer; overload;
var
  ext: String;
begin
  Result := nil;
  ext := copy(Uppercase(filename), length(filename) - 3, 4);
  if ext = '.BMP' then
  begin
    Result := LoadBMPTexture(Filename, cFormat, Width, Height);
    if cFormat = GL_BGRA then
    begin
      iFormat := GL_RGBA8;
      dType := GL_UNSIGNED_BYTE;
      pSize := 4;
    end
    else
    begin
      iFormat := GL_RGB8;
      dType := GL_UNSIGNED_BYTE;
      pSize := 3;
    end;
  end;
  if ext = '.TGA' then
  begin
    Result := myLoadTGATexture(Filename, cFormat, Width, Height);
    if cFormat = GL_RGB then
    begin
      iFormat := GL_RGB8;
      pSize := 3;
    end
    else
    begin
      iFormat := GL_RGBA8;
      pSize := 4;
    end;
    dType := GL_UNSIGNED_BYTE;
  end;

  if ext = '.PNG' then
  begin
    //LoadPNG(result,PWideChar(FileName),iFormat,cFormat,dType,pSize,Width,Height);
  end;

  flipSurface(result,Width,Height,pSize)
end;

*)

function LoadTexture(Filename: String; var iFormat, cFormat, dType: TGLConst;
  var pSize: Integer; var Width, Height: Integer): Pointer; overload;
var
  ext: String;
  Stream: TglrStream;
begin
  ext := Copy(UpperCase(FileName), Length(FileName) - 2, 3);
  Stream := TglrStream.Init(FileName, False);
  Result := LoadTexture(Stream, ext, iFormat, cFormat, dType, pSize, Width, Height);
  if Assigned(Stream) then
    Stream.Free;
end;


end.
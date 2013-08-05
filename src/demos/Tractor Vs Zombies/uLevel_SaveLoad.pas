{
  Класс для загрузки и сохранения информации об уровне
  Игра использует его внутри класса TtzLevel
  Редактор использует его напрямую
}

unit uLevel_SaveLoad;

interface

uses
  dfHRenderer, dfMath;

const
  //Самые первые два байта - магическое число для идентификации файла уровня
  TZL_MAGIC = $0F32;

  TZL_CHUNK_EARTH          = $0001;
  TZL_CHUNK_STATIC_OBJECTS = $0002;
  TZL_CHUNK_PLAYER         = $0003;


type
  TTZLFileHeader = packed record
    magic: Word;
    chunkCount: Word;
  end;

  TTZLChunkHeader = packed record
    type_id: Word;
    size: Word;
  end;

  TTZLBlockRec = packed record
    aPos, aSize: TdfVec2f;
    aRot: Single;
  end;

  TTZLEarthRec = packed record
    aPos: TdfVec2f;
  end;

  TTZLPlayerRec = packed record
    aPos: TdfVec2f;
  end;

type
  TTZLFile = class
    class function LoadFromFile(aFileName: String): TTZLFile;
  public
    Earth: array of TTZLEarthRec;
    Blocks: array of TTZLBlockRec;
    Player: TTZLPlayerRec;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure SaveToFile(aFileName: String);
  end;

implementation

{ TTZLFile }

constructor TTZLFile.Create;
begin
  inherited;
  SetLength(Earth, 0);
  SetLength(Blocks, 0);
end;

destructor TTZLFile.Destroy;
begin
  SetLength(Earth, 0);
  SetLength(Blocks, 0);
  inherited;
end;

class function TTZLFile.LoadFromFile(aFileName: String): TTZLFile;
var
  Stream: TglrStream;
  fileHeader: TTZLFileHeader;
  i: Integer;
  chunkHeader: TTZLChunkHeader;

  procedure ReadEarthChunk();
  var
    count: Integer;
  begin
    count := chunkHeader.size div SizeOf(TTZLEarthRec);
    SetLength(Result.Earth, count);
    Stream.Read(Result.Earth[0], count * SizeOf(TTZLEarthRec));
  end;

  procedure ReadStaticObjects();
  var
    count: Integer;
  begin
    count := chunkHeader.size div SizeOf(TTZLBlockRec);
    SetLength(Result.Blocks, count);
    Stream.Read(Result.Blocks[0], count * SizeOf(TTZLBlockRec));
  end;

  procedure ReadPlayer();
  begin
    Stream.Read(Result.Player, SizeOf(TTZLPlayerRec));
  end;

begin
  {
    Формат файла
    MAGIC         2 bytes     Магическое чисо, идентифицирующее что это наш файл
    CHUNK_COUNT   2 bytes     Количество чанков (кусков)

    До конца файла CHUNK_COUNT блоков памяти вида:

    CHUNK_TYPE    2 bytes     Тип чанка
    CHUNK_SIZE    2 bytes     Размер чанка
    CHUNK_DATA    CHUNK_SIZE  Информация по конкретному чанку

    -- CHUNK_EARTH:
    POINT_DATA    n * TTZLEarthRec  Сама информация по точкам

  }

  Result := TTZLFile.Create();
  Stream := TglrStream.Init(aFileName);
  Stream.Read(fileHeader, SizeOf(TTZLFileHeader));

  if fileHeader.magic <> TZL_MAGIC then
  begin
    Stream.Free;
    Result.Free;
    Exit(nil);
  end;

  for i := 0 to fileHeader.chunkCount - 1 do
  begin
    Stream.Read(chunkHeader, SizeOf(TTZLChunkHeader));
    case chunkHeader.type_id of
      TZL_CHUNK_EARTH         : ReadEarthChunk();
      TZL_CHUNK_STATIC_OBJECTS: ReadStaticObjects();
      TZL_CHUNK_PLAYER        : ReadPlayer;
      else
        Stream.Pos := Stream.Pos + chunkHeader.size;
    end

  end;

  Stream.Free;
end;

procedure TTZLFile.SaveToFile(aFileName: String);
var
  Stream: TglrStream;
  fileHeader: TTZLFileHeader;
  chunkHeader: TTZLChunkHeader;
begin
  Stream := TglrStream.Init(aFileName, True);

  fileHeader.magic := TZL_MAGIC;
  fileHeader.chunkCount := 1 {player} + Length(Earth) + Length(Blocks);

  Stream.Write(fileHeader, SizeOf(TTZLFileHeader));

  //Пишем землю
  chunkHeader.type_id := TZL_CHUNK_EARTH;
  chunkHeader.size := Length(Earth) * SizeOf(TTZLEarthRec);
  Stream.Write(chunkHeader, SizeOf(TTZLChunkHeader));
  Stream.Write(Earth[0], Length(Earth) * SizeOf(TTZLEarthRec));

  //Пишем блоки
  chunkHeader.type_id := TZL_CHUNK_STATIC_OBJECTS;
  chunkHeader.size := Length(Blocks) * SizeOf(TTZLBlockRec);
  Stream.Write(chunkHeader, SizeOf(TTZLChunkHeader));
  Stream.Write(Blocks[0], Length(Blocks) * SizeOf(TTZLBlockRec));

  //Пишем игрока
  chunkHeader.type_id := TZL_CHUNK_PLAYER;
  chunkHeader.size := SizeOf(TTZLPlayerRec);

  Stream.Free;
end;

end.

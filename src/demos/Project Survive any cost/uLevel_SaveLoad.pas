{
  Класс для загрузки и сохранения информации об уровне
}

unit uLevel_SaveLoad;

interface

uses
  dfHRenderer, dfMath;

const
  //Самые первые два байта - магическое число для идентификации файла уровня
  SUR_MAGIC = $0F32;

  SUR_CHUNK_STATIC_OBJECTS = $0001;
  //SUR_CHUNK_PLAYER         = $0002;
  SUR_CHUNK_WATER          = $0003;

  //Типы объектов на карте
  SUR_OBJ_BUSH     = $00; //Кустарник
  SUR_OBJ_TWIG     = $01; //Ветка
  SUR_OBJ_BACKPACK = $02; //Рюкзак
  SUR_OBJ_FLOWER   = $03; //Ромааашка
  SUR_OBJ_BOTTLE   = $04; //Фляга
  SUR_OBJ_KNIFE    = $05; //Нож
  SUR_OBJ_MUSHROOM = $06; //Грибооочек
  SUR_OBJ_OLDGRASS = $07; //Старая сухая трава
  SUR_OBJ_WIRE     = $08; //Моток лески(?)
  SUR_OBJ_NEWGRASS = $09; //Обычная трава
  SUR_OBJ_IGNORE   = $FF; //Ошибочный объект



type
  TSURFileHeader = packed record
    magic: Word;
    chunkCount: Word;
  end;

  TSURChunkHeader = packed record
    type_id: Word;
    size: Word;
  end;

  TSURObjectRec = packed record
    aType: Byte;
    aPos: TdfVec2f;
    aRot: Single;
  end;

  TSURWaterRec = packed record
    aPos, aScale: TdfVec2f;
    aRot: Single;
  end;

//  TSURPlayerRec = packed record
//    aPos: TdfVec2f;
//  end;

type
  TSURFile = class
    class function LoadFromFile(const aFileName: String): TSURFile;
  public
    Objects: array of TSURObjectRec;
    Water: array of TSURWaterRec;
    //Player: TSURPlayerRec;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure SaveToFile(const aFileName: String);
  end;

implementation

{ TSURFile }

constructor TSURFile.Create;
begin
  inherited;
  SetLength(Objects, 0);
end;

destructor TSURFile.Destroy;
begin
  SetLength(Objects, 0);
  inherited;
end;

class function TSURFile.LoadFromFile(const aFileName: String): TSURFile;
var
  Stream: TglrStream;
  fileHeader: TSURFileHeader;
  i: Integer;
  chunkHeader: TSURChunkHeader;

  procedure ReadStaticObjects();
  var
    count: Integer;
  begin
    count := chunkHeader.size div SizeOf(TSURObjectRec);
    SetLength(Result.Objects, count);
    Stream.Read(Result.Objects[0], count * SizeOf(TSURObjectRec));
  end;

//  procedure ReadPlayer();
//  begin
//    Stream.Read(Result.Player, SizeOf(TSURPlayerRec));
//  end;

  procedure ReadWater();
  var
    count: Integer;
  begin
    count := chunkHeader.size div SizeOf(TSURWaterRec);
    SetLength(Result.Water, count);
    Stream.Read(Result.Water[0], count * SizeOf(TSURWaterRec));
  end;

begin
  {
    Формат файла

    ИДЕНТ.        РАЗМЕР      НАЗНАЧЕНИЕ
    ------------------------------------
    MAGIC         2 bytes     Магическое чисо, идентифицирующее что это наш файл
    CHUNK_COUNT   2 bytes     Количество чанков (кусков)

    До конца файла CHUNK_COUNT блоков памяти вида:

    ИДЕНТ.        РАЗМЕР      НАЗНАЧЕНИЕ
    ------------------------------------
    CHUNK_TYPE    2 bytes     Тип чанка
    CHUNK_SIZE    2 bytes     Размер чанка
    CHUNK_DATA    CHUNK_SIZE  Информация по конкретному чанку

  }

  Result := TSURFile.Create();
  Stream := TglrStream.Init(aFileName);
  Stream.Read(fileHeader, SizeOf(TSURFileHeader));

  if fileHeader.magic <> SUR_MAGIC then
  begin
    Stream.Free;
    Result.Free;
    Exit(nil);
  end;

  for i := 0 to fileHeader.chunkCount - 1 do
  begin
    Stream.Read(chunkHeader, SizeOf(TSURChunkHeader));
    case chunkHeader.type_id of
      SUR_CHUNK_STATIC_OBJECTS: ReadStaticObjects();
//      SUR_CHUNK_PLAYER        : ReadPlayer;
      SUR_CHUNK_WATER         : ReadWater();
      else
        Stream.Pos := Stream.Pos + chunkHeader.size;
    end
  end;

  Stream.Free;
end;

procedure TSURFile.SaveToFile(const aFileName: String);
var
  Stream: TglrStream;
  fileHeader: TSURFileHeader;
  chunkHeader: TSURChunkHeader;
begin
  Stream := TglrStream.Init(aFileName, True);

  fileHeader.magic := SUR_MAGIC;
  fileHeader.chunkCount := Length(Objects) + Length(Water);

  Stream.Write(fileHeader, SizeOf(TSURFileHeader));

  //Пишем статические объекты
  chunkHeader.type_id := SUR_CHUNK_STATIC_OBJECTS;
  chunkHeader.size := Length(Objects) * SizeOf(TSURObjectRec);
  Stream.Write(chunkHeader, SizeOf(TSURChunkHeader));
  Stream.Write(Objects[0], Length(Objects) * SizeOf(TSURObjectRec));

  //Пишем воду
  chunkHeader.type_id := SUR_CHUNK_WATER;
  chunkHeader.size := Length(Water) * SizeOf(TSURWaterRec);
  Stream.Write(chunkHeader, SizeOf(TSURChunkHeader));
  Stream.Write(Water[0], Length(Water) * SizeOf(TSURWaterRec));

  Stream.Free;
end;

end.

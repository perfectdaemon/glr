{
  Абстрактный класс для реализации идеи "аккумулятора":
    Пули и другие игровые объекты, которые постоянно появляются и исчезают,
    и как следствие, требующие постоянного создания и удаления, могут использовать
    аккумулятор (другие названия - пул) объектов.

    Когда объект перестает быть нужным, он не удаляется, а помечается как
    неиспользованный и отправляется в аккумулятор. Когда возникает необходимость
    в новом объекте, он берется из аккумулятора, его характеристкии сбрасываются.
    Если в аккумуляторе нет свободных объектов, то он автоматически увеличивается

    Доступны две реализации - на классах и на интерфейсах

    Реализация на классах удобна во всех случаях, когда вы имеете возможность
    начать наследование вашего класса с TpdAccumItem, то есть:
    TMyClass = class(TpdAccumItem)

    Реализация интерфейсов удобна в случае, если наследование невозможно. Однако,
    придется реализовывать дополнительный интерфейс для взаимодействия с вашим
    объектом после Get(), так как нельзя просто так взять и получить из
    интерфейсной переменной ссылку на объект

    1. Классы
      TpdAccumItem - объект, помещаемый в аккумулятор
        + Необходимо перегрузить методы OnCreate, OnGet, onFree

      TpdAccum - сам аккумулятор
        + Необходимо перегрузить метод NewAccumItem() для того, чтобы он
          возвращал объект вашего класса. Например:

          function TMyAccum.NewAccumItem(): TpdAccumItem;
          begin
            Result := TMyAccumItem.Create();
          end;

        + Можно (но не обязательно) переобъявить метод GetItem для приведения
          его результата к вашему типу данных. Например:

          function TMyAccum.GetItem(): TMyAccumItem; reintroduce;

          function TMyAccum.GetItem(): TMyAccumItem;
          begin
            Result := inherited GetItem() as TMyAccumItem;
          end;

    2. Интерфейсы
      IpdAccumItem - объект, помещаемый в аккумулятор, должен реализовывать
        этот интерфейс. Назначение методов описано в объявлении интерфейса.

        + Дополнительно (относительно реализации на классах) необходиом реализовать
          механизм IsUsed.

      TpdAccumI - сам аккумулятор, оперирующий интерфейсами
        + Необходимо перегрузить метод NewAccumItem() для того, чтобы он
          возвращал объект вашего класса. Например:

          function TMyAccumI.NewAccumItem(): IpdAccumItem;
          begin
            Result := TMyClass.Create();
          end;

        + Можно (но не обязательно) переобъявить метод GetItem для приведения Result
          к вашему интерфейсу (получить объект из интерфейса не получится).
          Например:

          function TMyAccumI.GetItem(): IMyClassInterface; reintroduce;

          function TMyAccumI.GetItem(): IMyClassInterface;
          begin
            Result := inherited GetItem() as IMyClassInterface;
            //или     inherited GetItem().QueryInterface(IMyClassInterface);
          end;

  Автор: perfect.daemon
}

unit uAccum;

interface

//Реализация на классах

type
  TpdAccumItem = class
  protected
    FUsed: Boolean;
  public
    {Процедура вызывается после создания нового объекта, т. е. один раз за все время}
    procedure OnCreate(); virtual;
    {Процедура вызывается каждый раз, когда объект достают из аккумулятора}
    procedure OnGet(); virtual;
    {Процедура вызывается, когда обект помещают в аккумулятор}
    procedure OnFree(); virtual;

    property Used: Boolean read FUsed;
  end;

  TpdAccum = class
  protected
    procedure Expand();
  public
    Items: array of TpdAccumItem;
    constructor Create(aInitialCapacity: Integer); virtual;
    destructor Destroy(); override;

    function NewAccumItem(): TpdAccumItem; virtual; abstract;

    function GetItem(): TpdAccumItem; virtual;
    procedure FreeItem(aItem: TpdAccumItem); virtual;

    procedure Clear(); virtual;
  end;


//Реализация на интерфейсах

type
  IpdAccumItem = interface
    {Процедура вызывается после создания нового объекта, т. е. один раз за все время
     IsUsed должен после этого должен возвращать Fakkse}
    procedure OnCreate();
    {Процедура вызывается каждый раз, когда объект достают из аккумулятора
     IsUsed должен после этого должен возвращать True}
    procedure OnGet();
    {Процедура вызывается, когда объект помещают в аккумулятор
     IsUsed должен после этого должен возвращать False}
    procedure OnFree();

    {Проверяет, используется ли объект.
     Необходимо реализовать }
    function IsUsed(): Boolean;
  end;

  TpdAccumI = class
  protected
    FAccum: array of IpdAccumItem;
    procedure Expand();
  public
    constructor Create(aInitialCapacity: Integer); virtual;
    destructor Destroy(); override;

    {Необходимо переопределить эту функцию,
    В ней необходимо реализовать
      Result := TYourClass.Create();}
    function NewAccumItem(): IpdAccumItem; virtual; abstract;

    function Get(): IpdAccumItem; virtual;
    procedure Free(aItem: IpdAccumItem); virtual;
  end;


implementation

{$REGION 'Реализация на классах'}

{ TpdAccumItem }

procedure TpdAccumItem.OnCreate();
begin
  FUsed := False;
end;

procedure TpdAccumItem.OnFree();
begin
  FUsed := False;
end;

procedure TpdAccumItem.OnGet();
begin
  FUsed := True;
end;

{ TpdAccum }

procedure TpdAccum.Clear;
var
  i: Integer;
begin
  for i := 0 to Length(Items) - 1 do
  begin
    Items[i].Free();
    Items[i] := NewAccumItem();
    Items[i].OnCreate();
  end;
end;

constructor TpdAccum.Create(aInitialCapacity: Integer);
var
  i: Integer;
begin
  if aInitialCapacity > 4 then
    SetLength(Items, aInitialCapacity)
  else
    SetLength(Items, 4);
  for i := 0 to High(Items) do
  begin
    Items[i] := NewAccumItem();
    Items[i].OnCreate();
  end;
end;

destructor TpdAccum.Destroy();
var
  i: Integer;
begin
  for i := 0 to High(Items) do
  begin
    Items[i].Free;
  end;
  SetLength(Items, 0);
  inherited;
end;

procedure TpdAccum.Expand();
var
  l, i: Integer;
begin
  l := Length(Items);
  SetLength(Items, l + l div 4); // + 1/4 текущего размера аккумулятора
  for i := l to Length(Items) - 1 do
  begin
    Items[i] := NewAccumItem();
    Items[i].OnCreate();
  end;
end;

procedure TpdAccum.FreeItem(aItem: TpdAccumItem);
begin
  aItem.OnFree();
end;

function TpdAccum.GetItem(): TpdAccumItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(Items) do
    if not Items[i].Used then
    begin
      Result := Items[i];
      Break;
    end;

  if Result = nil then
  begin
    i := Length(Items); //Перестраховка, i = Length, но это неоднозначно
    Expand();
    Result := Items[i];
  end;

  Result.OnGet();
end;

{$ENDREGION}

{$REGION 'реализация на интерфейсах'}

{ TpdAccumI }

constructor TpdAccumI.Create(aInitialCapacity: Integer);
var
  i: Integer;
begin
  if aInitialCapacity > 4 then
    SetLength(FAccum, aInitialCapacity)
  else
    SetLength(FAccum, 4);
  for i := 0 to High(FAccum) do
  begin
    FAccum[i] := NewAccumItem();
    FAccum[i].OnCreate();
  end;
end;

destructor TpdAccumI.Destroy();
var
  i: Integer;
begin
  //Перестраховка
  for i := 0 to High(FAccum) do
    FAccum[i] := nil;
  SetLength(FAccum, 0);
  inherited;
end;

procedure TpdAccumI.Expand();
var
  l, i: Integer;
begin
  l := Length(FAccum);
  SetLength(FAccum, l + l div 4); // + 1/4 текущего размера аккумулятора
  for i := l to Length(FAccum) - 1 do
  begin
    FAccum[i] := NewAccumItem();
    FAccum[i].OnCreate();
  end;
end;

procedure TpdAccumI.Free(aItem: IpdAccumItem);
begin
  aItem.OnFree();
end;

function TpdAccumI.Get(): IpdAccumItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(FAccum) do
    if not FAccum[i].IsUsed() then
    begin
      Result := FAccum[i];
      Break;
    end;

  if Result = nil then
  begin
    i := Length(FAccum); //Перестраховка, i = Length, но это неоднозначно
    Expand();
    Result := FAccum[i];
  end;

  Result.OnGet();
end;

{$ENDREGION}

end.

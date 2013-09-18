unit uNode;

interface

uses
  Classes,
  glr, glrMath, uBaseInterfaceObject;

type

  TglrNode = class(TglrInterfacedObject, IglrNode)
  private
    function GetChildIndex(aChild: IglrNode): Integer;
  protected
    FParent: IglrNode;
    FChilds: TInterfaceList;

    FVisible: Boolean;

    FDir, FRight, FUp, FPos: TdfVec3f;
    FModelMatrix: TdfMat4f;

    function GetPos(): TdfVec3f;
    procedure SetPos(const aPos: TdfVec3f); virtual;
    function GetUp(): TdfVec3f;
    procedure SetUp(const aUp: TdfVec3f);
    function GetDir(): TdfVec3f;
    procedure SetDir(const aDir: TdfVec3f);
    function GetRight(): TdfVec3f;
    procedure SetRight(const aRight: TdfVec3f);
    function GetModel(): TdfMat4f;
    procedure SetModel(const aModel: TdfMat4f);
    function GetVis(): Boolean;
    procedure SetVis(const aVis: Boolean); virtual;
    function GetChild(Index: Integer): IglrNode;
    procedure SetChild(Index: Integer; aChild: IglrNode);
    function GetParent(): IglrNode;
    procedure SetParent(aParent: IglrNode);
    function GetChildsCount: Integer;

    procedure UpdateDirUpRight(NewDir, NewUp, NewRight: TdfVec3f); virtual;

    procedure RenderChilds(); virtual;
  public

    constructor Create; virtual;
    destructor Destroy; override;

    property Position: TdfVec3f read GetPos write SetPos;
    property Up: TdfVec3f read GetUp write SetUp;
    property Direction: TdfVec3f read GetDir write SetDir;
    property Right: TdfVec3f read GetRight write SetRight;
    property ModelMatrix: TdfMat4f read GetModel write SetModel;

    property Visible: Boolean read GetVis write SetVis;
    property Parent: IglrNode read GetParent write SetParent;
    property Childs[Index: Integer]: IglrNode read GetChild write SetChild;
    property ChildsCount: Integer read GetChildsCount;
    //Добавить уже существующий рендер-узел себе в потомки
    function AddChild(aChild: IglrNode): Integer;
    //Добавить нового потомка
    function AddNewChild(): IglrNode;
    //Удалить потомка из списка по индексу. Физически объект остается в памяти.
    procedure RemoveChild(Index: Integer); overload;
    //Удалить потомка из списка по указателю. Физически объект остается в памяти.
    procedure RemoveChild(aChild: IglrNode); overload;
    //Удалить потомка из списка по индексу. Физически объект уничтожается.
    procedure FreeChild(Index: Integer);

    procedure Render(); virtual;
  end;

implementation

uses
  ogl;

{ TdfNode }

function TglrNode.AddChild(aChild: IglrNode): Integer;
var
  Index: Integer;
begin
  Index := GetChildIndex(aChild);
  if Index <> -1 then //Такой потомок уже есть
    Exit(Index)  //Возвращаем его индекс
  else
  begin
    aChild.Parent := Self;
    Result := FChilds.Add(aChild);
  end;
end;

function TglrNode.AddNewChild: IglrNode;
begin
  Result := TglrNode.Create;
  Result.Parent := Self;
  Self._Release();
  FChilds.Add(Result);
end;

constructor TglrNode.Create;
begin
  inherited;
  FChilds := TInterfaceList.Create;
  FModelMatrix.Identity;
  SetModel(FModelMatrix);
  FVisible := True;
end;

destructor TglrNode.Destroy;
//var
//  i: Integer;
begin
//  for i := 0 to FChilds.Count - 1 do
//    IdfNode(FChilds[i]).Parent := nil;
  FChilds.Free; //InterfaceList зануляет ссылки
  FChilds := nil;
  inherited;
end;

procedure TglrNode.FreeChild(Index: Integer);
begin
  if (Index >= 0) and (Index < FChilds.Count) then
    if Assigned(FChilds[Index]) then
    begin
//      RemoveChild(Index);
      //Это зануляет ссылку в листе. Значит, объект должен освободиться,
      //если на него нет других ссылок
      FChilds.Delete(Index);
    end;
end;

function TglrNode.GetChild(Index: Integer): IglrNode;
begin
  if (Index >= 0) and (Index < FChilds.Count) then
    if Assigned(FChilds[Index]) then
      Result := IglrNode(FChilds[Index]);
end;

function TglrNode.GetChildIndex(aChild: IglrNode): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FChilds.Count - 1 do
    if IInterface(FChilds[i]) = aChild then
      Exit(i);
end;

function TglrNode.GetChildsCount: Integer;
begin
  Result := FChilds.Count;
end;

function TglrNode.GetDir: TdfVec3f;
begin
  Result := FDir;
end;

function TglrNode.GetRight: TdfVec3f;
begin
  Result := FRight;
end;

function TglrNode.GetModel: TdfMat4f;
begin
  Result := FModelMatrix;
end;

function TglrNode.GetParent: IglrNode;
begin
  Result := FParent;
end;

function TglrNode.GetPos: TdfVec3f;
begin
  Result := FPos;
end;

function TglrNode.GetUp: TdfVec3f;
begin
  Result := FUp;
end;

function TglrNode.GetVis: Boolean;
begin
  Result := FVisible;
end;

procedure TglrNode.RemoveChild(Index: Integer);
begin
  //Аналогично FreeChild, так как удалить чайлда напрямую с интерфейсной ссылкой
  // нельзя, AFAIK
  if (Index >= 0) and (Index < FChilds.Count) then
    if Assigned(FChilds[Index]) then
      FChilds.Delete(Index);
end;

procedure TglrNode.RemoveChild(AChild: IglrNode);
begin
  //Не проверяем, так как внутри TInterfaceList есть проверка
  FChilds.Remove(aChild);
end;

procedure TglrNode.Render();
begin
  if not FVisible then
    Exit();
  gl.PushMatrix();
    gl.MultMatrixf(FModelMatrix);
    RenderChilds();
  gl.PopMatrix();
end;

procedure TglrNode.RenderChilds;
var
  i: Integer;
begin
  for i := 0 to FChilds.Count - 1 do
    IglrNode(FChilds[i]).Render;
end;

procedure TglrNode.SetChild(Index: Integer; aChild: IglrNode);
begin
  FChilds[Index] := aChild;
end;

procedure TglrNode.SetDir(const aDir: TdfVec3f);
var
  NewUp, NewLeft: TdfVec3f;
begin
  NewLeft := FUp.Cross(aDir);
  NewLeft.Negate;
  NewLeft.Normalize;
  NewUp := aDir.Cross(NewLeft);
  NewUp.Normalize;
  UpdateDirUpRight(aDir, NewUp, NewLeft);
end;

procedure TglrNode.SetRight(const aRight: TdfVec3f);
var
  NewDir, NewUp: TdfVec3f;
begin
  NewDir := aRight.Cross(FUp);
  NewDir.Normalize;
  NewUp := NewDir.Cross(aRight);
  NewUp.Normalize;
  UpdateDirUpRight(NewDir, NewUp, aRight);
end;

procedure TglrNode.SetModel(const aModel: TdfMat4f);
begin
  FModelMatrix := aModel;
  with FModelMatrix do
  begin
    FRight := dfVec3f(e00, e01, e02);
    FUp   := dfVec3f(e10, e11, e12);
    FDir  := dfVec3f(e20, e21, e22);
  end;
end;

procedure TglrNode.SetParent(aParent: IglrNode);
begin
  if Assigned(Parent) and (Parent <> aParent) then
    FParent.RemoveChild(Self);
  FParent := aParent;
end;

procedure TglrNode.SetPos(const aPos: TdfVec3f);
begin
  FPos := aPos;
  FModelMatrix.Pos := FPos;
end;

procedure TglrNode.SetUp(const aUp: TdfVec3f);
var
  NewDir, NewLeft: TdfVec3f;
begin
  NewLeft := aUp.Cross(FDir);
  NewLeft.Negate;
  NewLeft.Normalize;
  NewDir := NewLeft.Cross(aUp);
  NewDir.Normalize;
  UpdateDirUpRight(NewDir, aUp, NewLeft);
end;

procedure TglrNode.SetVis(const aVis: Boolean);
begin
  FVisible := aVis;
end;

procedure TglrNode.UpdateDirUpRight(NewDir, NewUp, NewRight: TdfVec3f);
begin
  with FModelMatrix do
  begin
    e00 := NewRight.x; e01 := NewRight.y; e02 := NewRight.z; e03 := FPos.Dot(NewRight);
    e10 := NewUp.x;   e11 := NewUp.y;   e12 := NewUp.z;   e13 := FPos.Dot(NewUp);
    e20 := NewDir.x;  e21 := NewDir.y;  e22 := NewDir.z;  e23 := FPos.Dot(NewDir);
    e30 := 0;         e31 := 0;         e32 := 0;         e33 := 1;
  end;
  FRight := NewRight;
  FUp   := NewUp;
  FDir  := NewDir;
end;

end.

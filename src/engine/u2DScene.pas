unit u2DScene;

interface

uses
  Classes,
  glrMath, glr, uBaseInterfaceObject;

type
  Tglr2DScene = class(TglrInterfacedObject, Iglr2DScene)
  private
    FElements: TInterfaceList;
    FUpdProc: TglrOnUpdateProc;
    vp: TglrViewportParams;

    FOrigin: TdfVec2f;
    current: Iglr2DRenderable;
  protected
    function GetUpdateProc(): TglrOnUpdateProc;
    procedure SetUpdateProc(aProc: TglrOnUpdateProc);

    function GetElement(aIndex: Integer): Iglr2DRenderable;
    procedure SetElement(aIndex: Integer; const aElement: Iglr2DRenderable);

    function GetOrigin(): TdfVec2f;
    procedure SetOrigin(const aVec: TdfVec2f);
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    function RegisterElement(const aElement: Iglr2DRenderable): Integer;
    procedure UnregisterElement(const aElement: Iglr2DRenderable);
    procedure UnregisterElements();
    function IsElementRegistered(const aElement: Iglr2DRenderable): Boolean;
    procedure SortFarthestFirst();

    property Elements[Index: Integer]: Iglr2DRenderable read GetElement write SetElement;

    property OnUpdate: TglrOnUpdateProc read GetUpdateProc write SetUpdateProc;

    procedure Render();
    procedure Update(const deltaTime: Double);

    property Origin: TdfVec2f read GetOrigin write SetOrigin;
  end;

implementation

uses
  uRenderer,
  ogl;

{ Tdf2DScene }

constructor Tglr2DScene.Create;
begin
  inherited;
  FElements := TInterfaceList.Create;
  FUpdProc := nil;
  FOrigin := dfVec2f(0, 0);
end;

destructor Tglr2DScene.Destroy;
begin
  current := nil;
  UnregisterElements();
  FElements.Free;
  inherited;
end;

function Tglr2DScene.GetElement(aIndex: Integer): Iglr2DRenderable;
begin
  Result := Iglr2DRenderable(FElements[aIndex]);
end;

function Tglr2DScene.GetOrigin: TdfVec2f;
begin
  Result := FOrigin;
end;

function Tglr2DScene.GetUpdateProc: TglrOnUpdateProc;
begin
  Result := FUpdProc;
end;

function Tglr2DScene.IsElementRegistered(const aElement: Iglr2DRenderable): Boolean;
begin
  Result := (FElements.IndexOf(aElement) <> - 1);
end;

function Tglr2DScene.RegisterElement(const aElement: Iglr2DRenderable): Integer;
var
  ind: Integer;
begin
  ind := FElements.IndexOf(aElement);
  if ind = -1 then
  begin
    Result := FElements.Add(aElement);
    aElement.AbsolutePosition := False;
    aElement.ParentScene := Self;
  end
  else
    Result := ind;
end;

procedure Tglr2DScene.Render;
var
  i: Integer;
begin
  gl.MatrixMode(GL_PROJECTION);
  gl.PushMatrix();
  gl.LoadIdentity();
  vp := TheRenderer.Camera.GetViewport();
  gl.Ortho(vp.X, vp.W, vp.H, vp.Y, vp.ZNear, vp.ZFar);
  gl.MatrixMode(GL_MODELVIEW);

  gl.PushMatrix();
    gl.LoadIdentity();
    gl.Translatef(FOrigin.x, FOrigin.y, 0);
    for i := 0 to  FElements.Count - 1 do
      Iglr2DRenderable(FElements[i]).Render();
  gl.PopMatrix();

  gl.MatrixMode(GL_PROJECTION);
  gl.PopMatrix();
  gl.MatrixMode(GL_MODELVIEW);
end;

procedure Tglr2DScene.SetElement(aIndex: Integer;
  const aElement: Iglr2DRenderable);
begin
  FElements[aIndex] := aElement;
end;

procedure Tglr2DScene.SetOrigin(const aVec: TdfVec2f);
begin
  FOrigin := aVec;
end;

procedure Tglr2DScene.SetUpdateProc(aProc: TglrOnUpdateProc);
begin
  FUpdProc := aProc;
end;

procedure Tglr2DScene.SortFarthestFirst;
var
  i, j, max: Integer;
  tmp: IInterface;
begin
  for i := 0 to FElements.Count - 2 do
  begin
    max := i;
    for j := i + 1 to FElements.Count - 2 do
    begin
      if (FElements[j] as Iglr2DRenderable).Position.z > (FElements[max] as Iglr2DRenderable).Position.z then
        max := j;
    end;
    //--Μενÿεμ
    if max <> i then
    begin
      tmp := FElements[i];
      FElements[i] := FElements[max];
      FElements[max] := tmp;
    end;
  end;
end;

procedure Tglr2DScene.UnregisterElement(const aElement: Iglr2DRenderable);
begin
  if FElements.Remove(aElement) <> -1 then
    aElement.ParentScene := nil;
end;

procedure Tglr2DScene.UnregisterElements;
var
  i: Integer;
begin
  for i := 0 to FElements.Count - 1 do
    (FElements[i] as Iglr2DRenderable).ParentScene := nil;
  FElements.Clear();
end;

procedure Tglr2DScene.Update(const deltaTime: Double);
begin
  if Assigned(FUpdProc) then
    FUpdProc(deltaTime);
end;

end.

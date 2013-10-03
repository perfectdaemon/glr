unit uScene;

interface

uses
  Classes,
  glrMath, glr, uBaseInterfaceObject;

type
  TglrBaseScene = class (TglrInterfacedObject, IglrBaseScene)
  protected
    FUpdProc: TglrOnUpdateProc;
    FRoot: IglrNode;
    function GetRoot: IglrNode;
    procedure SetRoot(aRoot: IglrNode);
    function GetUpdateProc(): TglrOnUpdateProc;
    procedure SetUpdateProc(aProc: TglrOnUpdateProc);
  public
    property OnUpdate: TglrOnUpdateProc read GetUpdateProc write SetUpdateProc;
    property RootNode: IglrNode read GetRoot write SetRoot;

    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Render(); virtual;
    procedure Update(const deltaTime: Double);
  end;


  Tglr2DScene = class(TglrBaseScene, Iglr2DScene)
  protected
    vp: TglrViewportParams;
  public
    procedure SortFarthestFirst();
    procedure Render(); override;
  end;

  Tglr3DScene = class (TglrBaseScene, Iglr3DScene)
  public
  end;

implementation

uses
  uRenderer, ExportFunc,
  ogl;

{ Tdf2DScene }


procedure Tglr2DScene.Render;
var
  i: Integer;
begin
  gl.MatrixMode(GL_PROJECTION);
  gl.PushMatrix();
    gl.LoadIdentity();
    vp := TheRenderer.Camera.GetViewport();
    with vp do
      gl.Ortho(X, W, H, Y, -100, 100);
    gl.MatrixMode(GL_MODELVIEW);
    gl.PushMatrix();
      gl.LoadIdentity();
      FRoot.Render();
    gl.PopMatrix();
  gl.MatrixMode(GL_PROJECTION);
  gl.PopMatrix();
  gl.MatrixMode(GL_MODELVIEW);
end;

procedure Tglr2DScene.SortFarthestFirst;
var
  i, j, max: Integer;
  tmp: IInterface;
begin
//  for i := 0 to FElements.Count - 2 do
//  begin
//    max := i;
//    for j := i + 1 to FElements.Count - 2 do
//    begin
//      if (FElements[j] as Iglr2DRenderable).Position.z > (FElements[max] as Iglr2DRenderable).Position.z then
//        max := j;
//    end;
//    //--Μενÿεμ
//    if max <> i then
//    begin
//      tmp := FElements[i];
//      FElements[i] := FElements[max];
//      FElements[max] := tmp;
//    end;
//  end;
end;

{ TglrBaseScene }

function TglrBaseScene.GetUpdateProc: TglrOnUpdateProc;
begin
  Result := FUpdProc;
end;

procedure TglrBaseScene.Render;
begin

end;

procedure TglrBaseScene.SetUpdateProc(aProc: TglrOnUpdateProc);
begin
  FUpdProc := aProc;
end;

procedure TglrBaseScene.Update(const deltaTime: Double);
begin
  if Assigned(FUpdProc) then
    FUpdProc(deltaTime);
end;

constructor TglrBaseScene.Create;
begin
  inherited;
  FRoot := GetObjectFactory().NewNode();
end;

destructor TglrBaseScene.Destroy;
begin
  FRoot := nil;
end;

function TglrBaseScene.GetRoot: IglrNode;
begin
  Result := FRoot;
end;

procedure TglrBaseScene.SetRoot(aRoot: IglrNode);
begin
  FRoot := aRoot;
end;

{ Tglr3DScene }


end.

unit uCamera;

interface

uses
  glrMath, ogl, glr, uNode;

type
  TglrCameraTargetMode = (mPoint, mTarget, mFree);

  TglrCamera = class (TglrNode, IglrCamera)
  protected
    FProjMode: TglrCameraProjectionMode;
    FProjMatrix: TdfMat4f;
    FMode: TglrCameraTargetMode;
    FTargetPoint: TdfVec3f;
    FTarget: IglrNode;
    FFOV, FZNear, FZFar: Single;
    FX, FY, FW, FH: Integer;
    function GetProjMode(): TglrCameraProjectionMode;
    procedure SetProjMode(aMode: TglrCameraProjectionMode);
    procedure SetPerspective();
    procedure SetOrtho();
  public
    procedure Viewport(x, y, w, h: Integer; FOV, ZNear, ZFar: Single);
    procedure ViewportOnly(x, y, w, h: Integer);

    procedure Pan(X, Y: Single);
    procedure Scale(aScale: Single);
    procedure Rotate(delta: Single; Axis: TdfVec3f);

    function GetViewport(): TglrViewportParams;

    procedure Update;

    procedure SetCamera(aPos, aTargetPos, aUp: TdfVec3f);
    procedure SetTarget(aPoint: TdfVec3f); overload;
    procedure SetTarget(aTarget: IglrNode); overload;

    property ProjectionMode: TglrCameraProjectionMode read GetProjMode write SetProjMode;
  end;

implementation

//uses
  //Windows;

procedure TglrCamera.Viewport(x, y, w, h: Integer; FOV, ZNear, ZFar: Single);
begin
  FFOV := FOV;
  FZNear := ZNear;
  FZFar := ZFar;
  FX := x;
  FY := y;
  if w > 0 then
    FW := w
  else
    FW := 1;
  if h > 0 then
    FH := h
  else
    FH := 1;

  ProjectionMode := FProjMode; //Обновляем
end;

procedure TglrCamera.ViewportOnly(x, y, w, h: Integer);
begin
  FX := x;
  FY := y;
  if w > 0 then
    FW := w
  else
    FW := 1;
  if h > 0 then
    FH := h
  else
    FH := 1;
  ProjectionMode := FProjMode; //Обновляем
end;

function TglrCamera.GetProjMode: TglrCameraProjectionMode;
begin
  Result := FProjMode;
end;

function TglrCamera.GetViewport: TglrViewportParams;
begin
  with Result do
  begin
    X := FX;
    Y := FY;
    W := FW;
    H := FH;
    FOV := FFOV;
    ZNear := FZNear;
    ZFar := FZFar;
  end;
end;

procedure TglrCamera.Pan(X, Y: Single);
var
  v: TdfVec3f;
begin
  v := Up * X * 0.01;
  v := v + Left * Y * 0.01;
  FModelMatrix.Translate(v);
end;

procedure TglrCamera.Scale(aScale: Single);
begin
  FModelMatrix.Scale(dfVec3f(aScale, aScale, aScale));
// Мастштабирование смещением камеры вперед:
//  ModelMatrix.Translate(dfVec3f(0,0,0) - (Direction * AScale));
end;

procedure TglrCamera.Update();
begin
//Вероятно, не нужно.
//  gl.MatrixMode(GL_PROJECTION);
//  gl.LoadMatrixf(FProjMatrix);
  gl.MatrixMode(GL_MODELVIEW);
  gl.MultMatrixf(FModelMatrix);
end;

procedure TglrCamera.Rotate(delta: Single; Axis: TdfVec3f);
begin
  FModelMatrix.Rotate(Delta, Axis);
end;

procedure TglrCamera.SetCamera(aPos, aTargetPos, aUp: TdfVec3f);
var
  vDir, vUp, vLeft: TdfVec3f;
begin
  FModelMatrix.Identity;
  vUp := aUp;
  vUp.Normalize;
  vDir := aPos - aTargetPos;
  vDir.Normalize;
  vLeft := vUp.Cross(vDir);
  vLeft.Negate;
  vLeft.Normalize;
  vUp := vDir.Cross(vLeft);
  vUp.Normalize;

  Position := aPos;
  UpdateDirUpLeft(vDir, vUp, vLeft);

  FTargetPoint := aTargetPos;
  FMode := mPoint;
end;

procedure TglrCamera.SetOrtho;
begin
  gl.Viewport(FX, FY, FW, FH);
  FProjMatrix.Identity;
  FProjMatrix.Ortho(FX, FW, FH, FY, FZNear, FZFar);
  gl.MatrixMode(GL_PROJECTION);
  gl.LoadMatrixf(FProjMatrix);
end;

procedure TglrCamera.SetPerspective;
begin
  gl.Viewport(FX, FY, FW, FH);
  FProjMatrix.Identity;
  FProjMatrix.Perspective(FFOV, FW / FH, FZNear, FZFar);
  gl.MatrixMode(GL_PROJECTION);
  gl.LoadMatrixf(FProjMatrix);
end;

procedure TglrCamera.SetProjMode(aMode: TglrCameraProjectionMode);
begin
  case aMode of
    pmPerpective: SetPerspective();
    pmOrtho: SetOrtho();
  end;
end;

procedure TglrCamera.SetTarget(aPoint: TdfVec3f);
var
  vDir, vUp, vLeft: TdfVec3f;
begin
  FTargetPoint := aPoint;
  with FModelMatrix do
  begin
    vDir := Position - aPoint;
    vDir.Normalize;
    vUp := Up;
    vLeft := vDir.Cross(vUp);
    vLeft.Normalize;
    vUp :=vLeft.Cross(vDir);
    vUp.Normalize;
    vLeft.Negate;
    UpdateDirUpLeft(vDir, vUp, vLeft);
  end;
  FMode := mPoint;
end;

procedure TglrCamera.SetTarget(aTarget: IglrNode);
begin
  FTarget := aTarget;
  SetTarget(aTarget.Position);
  FMode := mTarget;
end;

end.

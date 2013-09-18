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
    procedure UpdateDirUpRight(NewDir, NewUp, NewRight: TdfVec3f); override;
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
  v := v + Right * Y * 0.01;
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
  vDir, vUp, vRight: TdfVec3f;
begin
  FModelMatrix.Identity;
  vUp := aUp;
  vUp.Normalize;
  vDir := aPos - aTargetPos;
  vDir.Normalize;
  vRight := vUp.Cross(vDir);
  vRight.Normalize;
  vUp := vDir.Cross(vRight);
  vUp.Normalize;

  Position := aPos;
  UpdateDirUpRight(vDir, vUp, vRight);

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
  FProjMode := aMode;
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
    UpdateDirUpRight(vDir, vUp, vLeft);
  end;
  FMode := mPoint;
end;

procedure TglrCamera.SetTarget(aTarget: IglrNode);
begin
  FTarget := aTarget;
  SetTarget(aTarget.Position);
  FMode := mTarget;
end;

procedure TglrCamera.UpdateDirUpRight(NewDir, NewUp, NewRight: TdfVec3f);
begin
  with FModelMatrix do
  begin
    e00 :=  NewRight.x; e01 :=  NewRight.y; e02 :=  NewRight.z; e03 := -FPos.Dot(NewRight);
    e10 :=  NewUp.x;   e11 :=  NewUp.y;   e12 :=  NewUp.z;   e13 := -FPos.Dot(NewUp);
    e20 :=  NewDir.x;  e21 :=  NewDir.y;  e22 :=  NewDir.z;  e23 := -FPos.Dot(NewDir);
    e30 :=  0;         e31 :=  0;         e32 :=  0;         e33 :=  1;
  end;
  FRight := NewRight;
  FUp   := NewUp;
  FDir  := NewDir;
end;

end.

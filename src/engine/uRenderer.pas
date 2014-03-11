{
  TODO: рефактор инициализации: Init, OpenGLInit, OpenGLInitContext, OpenGLInit
}

unit uRenderer;

interface

uses
  Windows, Messages, SysUtils, Classes,
  ogl, glr, glrMath,
  uBaseInterfaceObject, uCamera, uHudSprite, uTexture, uNode, uInput, uGUIManager;

type
  TglrRenderer = class(TglrInterfacedObject, IglrRenderer)
  private
    FEnabled: Boolean;
    //Готовность рендера к, собственно, рендеру
    FRenderReady: Boolean;

    //Параметры окна
    FWHandle: THandle;
    FWCaption: WideString;
    FWWidth, FWHeight, FWX, FWY: Integer;
    FdesRect: TRect;
    FWStyle: Cardinal;
    FWndClass: TWndClass;
    FWDC: hDC;

    //Собственное ли окно создано (True), или используем "паразитизм" (False)
    FSelfWindow: Boolean;
    //Для чужого окна сохраняем ссылку на его процедуру
    FParentWndProc: Integer;

    //Курсоры
    FhDefaultCursor, FhHandCursor: HICON;

    FPFD: TPixelFormatDescriptor;
    FnPixelFormat: Integer;

    //Рендер-контекст
    FGLRC: hglRC;

    //Параметры для высокоточного таймера
    FNewTicks, FOldTicks, FFreq: Int64;
    FDeltaTime, FFPS: Single;

    //Параметры буфера и рисования(рендера)
    FBackgroundColor: TdfVec3f;
    FDrawAxes: Boolean;

    //Активная камера
    FCamera: IglrCamera;

    //Корень сцены
    FRootNode: IglrNode;

    //Объект для отслеживания ввода
    FInput: IglrInput;

    FGUIManager: IglrGUIManager;

    //коллбэки для мыши
    FOnMouseDown: TglrOnMouseDownProc;
    FOnMouseUp: TglrOnMouseUpProc;
    FOnMouseMove: TglrOnMouseMoveProc;
    FOnMouseWheel: TglrOnMouseWheelProc;

    //Коллбэк на апдейт
    FOnUpdate: TglrOnUpdateProc;

    //Сцены
    FScenes: TInterfaceList;

    //debug
    FTexSwitches: Integer;

    function TryGetMultisampleFormat(var aFormat: Integer): Boolean;
    procedure OpenGLInitContext(aPixelFormat: Integer); //если 0, то делает choosePixelFormat
    procedure OpenGLInit(aVSync: Boolean; aFOV, aZNear, aZFar: Single; camPos, camLook, camUp: TdfVec3f);

    function GetWindowHandle(): Integer;
    function GetWindowCaption(): WideString;
    procedure SetWindowCaption(aCaption: WideString);
    function GetRenderReady(): Boolean;
    function GetFPS(): Single;
    function GetCamera(): IglrCamera;
    procedure SetCamera(const aCamera: IglrCamera);
    function GetRootNode: IglrNode;
    procedure SetRootNode(const aRoot: IglrNode);

    procedure SetOnMouseDown(aProc: TglrOnMouseDownProc);
    procedure SetOnMouseUp(aProc: TglrOnMouseUpProc);
    procedure SetOnMouseMove(aProc: TglrOnMouseMoveProc);
    procedure SetOnMouseWheel(aProc: TglrOnMouseWheelProc);

    function GetOnMouseDown(): TglrOnMouseDownProc;
    function GetOnMouseUp(): TglrOnMouseUpProc;
    function GetOnMouseMove(): TglrOnMouseMoveProc;
    function GetOnMouseWheel() : TglrOnMouseWheelProc;

    function GetOnUpdate(): TglrOnUpdateProc;
    procedure SetOnUpdate(aProc: TglrOnUpdateProc);

    function GetEnabled(): Boolean;
    procedure SetEnabled(aEnabled: Boolean);

    function GetSelfVersion(): PWideChar;

    function GetDC(): hDC;
    function GetRC(): hglRC;

    function GetWidth(): Integer;
    function GetHeight(): Integer;

    function GetInput(): IglrInput;
    procedure SetInput(const aInput: IglrInput);

    function GetManager(): IglrGUIManager;
    procedure SetManager(const aManager: IglrGUIManager);

    function GetTexSwitches(): Integer;

    procedure WMLButtonDown    (var Msg: TMessage); message WM_LBUTTONDOWN;
    procedure WMLButtonUp      (var Msg: TMessage); message WM_LBUTTONUP;
    procedure WMLButtonDblClick(var Msg: TMessage); message WM_LBUTTONDBLCLK;

    procedure WMRButtonDown    (var Msg: TMessage); message WM_RBUTTONDOWN;
    procedure WMRButtonUp      (var Msg: TMessage); message WM_RBUTTONUP;
    procedure WMRButtonDblClick(var Msg: TMessage); message WM_RBUTTONDBLCLK;

    procedure WMMButtonDown    (var Msg: TMessage); message WM_MBUTTONDOWN;
    procedure WMMButtonUp      (var Msg: TMessage); message WM_MBUTTONUP;
    procedure WMMButtonDblClick(var Msg: TMessage); message WM_MBUTTONDBLCLK;

    procedure WMMouseMove      (var Msg: TMessage); message WM_MOUSEMOVE;
    procedure WMMouseWheel     (var Msg: TMessage); message WM_MOUSEWHEEL;

    procedure WMSize           (var Msg: TWMSize); message WM_SIZE;
    procedure WMActivate       (var Msg: TWMActivate); message WM_ACTIVATE;
    procedure WMClose          (var Msg: TWMClose); message WM_CLOSE;

    procedure WMSetCursor      (var Msg: TWMSetCursor); message WM_SETCURSOR;

    procedure WMKeyDown        (var Msg: TWMKeyDown); message WM_KEYDOWN;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Init(FileName: PAnsiChar); overload;
    procedure Init(Handle: THandle; FileName: PAnsiChar); overload; deprecated;
    procedure Step(deltaTime: Double);
    procedure Start();
    procedure Stop();
    procedure DeInit();

    property WindowHandle: Integer read GetWindowHandle;
    property WindowCaption: WideString read GetWindowCaption write SetWindowCaption;
    property WindowWidth: Integer read GetWidth;
    property WindowHeight: Integer read GetHeight;


    property DC: hDC read GetDC;
    property RC: hglRC read GetRC;

    property RenderReady: Boolean read GetRenderReady;
    property FPS: Single read GetFPS;

    property VersionText: PWideChar read GetSelfVersion;

    property Camera: IglrCamera read GetCamera write SetCamera;

    property RootNode: IglrNode read GetRootNode write SetRootNode;

    property Input: IglrInput read GetInput write SetInput;

    property GUIManager: IglrGUIManager read GetManager write SetManager;

    property OnMouseDown: TglrOnMouseDownProc read GetOnMouseDown write SetOnMouseDown;
    property OnMouseUp: TglrOnMouseUpProc read GetOnMouseUp write SetOnMouseUp;
    property OnMouseMove: TglrOnMouseMoveProc read GetOnMouseMove write SetOnMouseMove;
    property OnMouseWheel: TglrOnMouseWheelProc read GetOnMouseWheel write SetOnMouseWheel;

    property OnUpdate: TglrOnUpdateProc read GetOnUpdate write SetOnUpdate;

    {Функционал для работы со сценами}
    function RegisterScene(const aScene: IglrBaseScene): Integer;
    procedure UnregisterScene(const aScene: IglrBaseScene);
    procedure UnregisterScenes();
  end;


  function WindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

var
  TheRenderer: IglrRenderer;

implementation

uses
  uRenderable, uLogger;


const
  cDefWindowW = 640;
  cDefWindowH = 480;
  cDefWindowX = 0;
  cDefWindowY = 0;
  cDefWindowCaption = 'Window';

function WindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  MsgRec: TMessage;
begin
  case Msg of
    WM_DESTROY:
    begin
      PostQuitMessage(0);
      Result := 0;
    end;
  end;
  MsgRec.Msg := Msg;
  MsgRec.WParam := wParam;
  MsgRec.LParam := lParam;
  MsgRec.Result := Result;
  if Assigned(TheRenderer) and TheRenderer.RenderReady then
    TheRenderer.Dispatch(MsgRec);
  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;

{$REGION 'Класс TdfRenderer'}

function TglrRenderer.GetWindowHandle(): Integer;
begin
  if FRenderReady then
    Result := FWHandle
  else
    Result := 0;
end;

procedure TglrRenderer.OpenGLInit(aVSync: Boolean; aFOV, aZNear, aZFar: Single; camPos, camLook, camUp: TdfVec3f);
var
  aStr: WideString;
begin
  gl.Enable(GL_DEPTH_TEST);
  gl.Enable(GL_LIGHTING);
  gl.Enable(GL_CULL_FACE);
  gl.Enable(GL_COLOR_MATERIAL);
  gl.Enable(GL_TEXTURE_2D);
  gl.Enable(GL_MULTISAMPLE);

  gl.ClearColor(FBackgroundColor.x, FBackgroundColor.y, FBackgroundColor.z, 1.0);
  if aVSync then
    gl.SwapInterval(1)
  else
    gl.SwapInterval(0);

  ShowWindow(FWHandle, CmdShow);
  UpdateWindow(FWHandle);

  FCamera := TglrCamera.Create();
  FCamera.Viewport(0, 0, FWWidth, FWHeight, aFOV, aZNear, aZFar);
  FCamera.SetCamera(camPos, camLook, camUp);

  QueryPerformanceFrequency(FFreq);

  logWriteMessage('--');
  aStr := gl.GetString(TGLConst.GL_VENDOR);
  logWriteMessage('Производитель: ' + aStr);
  aStr := gl.GetString(TGLConst.GL_RENDERER);
  logWriteMessage('Визуализатор: ' + aStr);
  aStr := gl.GetString(TGLConst.GL_VERSION);
  logWriteMessage('Версия OpenGL: ' + aStr);
  aStr := gl.GetString(TGLConst.GL_SHADING_LANGUAGE_VERSION);
  logWriteMessage('Версия GLSL: ' + aStr);
  logWriteMessage('--');
end;

procedure TglrRenderer.OpenGLInitContext(aPixelFormat: Integer);
begin
  FWDC := Windows.GetDC(FWHandle);

  if FWDC = 0 then
  begin
    logWriteError('Ошибка получения Device Context, возвращен нулевой контекст', True, True, True);
    Exit;
  end;

  logWriteMessage('Успешное получение Device Context: ' + IntToStr(FWDC));
  ZeroMemory(@Fpfd, SizeOf(TPixelFormatDescriptor));
  Fpfd.nSize := SizeOf(PIXELFORMATDESCRIPTOR);
  Fpfd.nVersion := 1;
  Fpfd.dwFlags  := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
  Fpfd.iPixelType := PFD_TYPE_RGBA;
  Fpfd.cColorBits := 32;

  if aPixelFormat = 0 then
    FnPixelFormat := ChoosePixelFormat(FWDC, @Fpfd)
  else
    FnPixelFormat := aPixelFormat;

  if FnPixelFormat = 0 then
  begin
    logWriteError('Ошибка получения пиксельного формата, возвращено нулевое значение', True, True, True);
    Exit;
  end;

  logWriteMessage('Успешное получение пиксельного формата: ' + IntToStr(FnPixelFormat));

  if not SetPixelFormat(FWDC, FnPixelFormat, @Fpfd) then
  begin
    logWriteError('Ошибка установки пиксельного формата', True, True, True);
    Exit;
  end;

  FGLRC := wglCreateContext(FWDC);

  if FGLRC = 0 then
  begin
    logWriteError('Ошибка получения рендер-контекста, возвращен нулевой контекст', True, True, True);
    Exit;
  end;

  logWriteMessage('Успешное получение рендер-контекста: ' + IntToStr(FGLRC));

  wglMakeCurrent(FWDC, FGLRC);

  gl.Init;
end;

const
  WGL_SAMPLE_BUFFERS_ARB = $2041;
  WGL_SAMPLES_ARB	= $2042;
  WGL_DRAW_TO_WINDOW_ARB = $2001;
  WGL_SUPPORT_OPENGL_ARB = $2010;
  WGL_ACCELERATION_ARB = $2003;
  WGL_FULL_ACCELERATION_ARB = $2027;
  WGL_COLOR_BITS_ARB = $2014;
  WGL_ALPHA_BITS_ARB = $201B;
  WGL_DEPTH_BITS_ARB = $2022;
  WGL_STENCIL_BITS_ARB = $2023;
  WGL_DOUBLE_BUFFER_ARB = $2011;

function TglrRenderer.TryGetMultisampleFormat(var aFormat: Integer): Boolean;
var
  iAttributes: array of Integer;
  formatCount: Integer;
begin
  Result := False;
  if Assigned(gl.ChoosePixelFormat) then
  begin
    //Инициализируем параметры для мультисэмплинга
    SetLength(iAttributes, 22);
    iAttributes[0]  := WGL_DRAW_TO_WINDOW_ARB;  iAttributes[1]  := 1;
    iAttributes[2]  := WGL_SUPPORT_OPENGL_ARB;  iAttributes[3]  := 1;
    iAttributes[4]  := WGL_ACCELERATION_ARB;
    iAttributes[5]  := WGL_FULL_ACCELERATION_ARB;
    iAttributes[6]  := WGL_COLOR_BITS_ARB;      iAttributes[7]  := 32;
    iAttributes[8]  := WGL_ALPHA_BITS_ARB;      iAttributes[9]  := 8;
    iAttributes[10] := WGL_DEPTH_BITS_ARB;      iAttributes[11] := 24;
    iAttributes[12] := WGL_STENCIL_BITS_ARB;    iAttributes[13] := 8;
    iAttributes[14] := WGL_DOUBLE_BUFFER_ARB;   iAttributes[15] := 1;
    iAttributes[16] := WGL_SAMPLE_BUFFERS_ARB;  iAttributes[17] := 1;
    iAttributes[18] := WGL_SAMPLES_ARB;         iAttributes[19] := 8;
    iAttributes[20] := 0;
    iAttributes[21] := 0;

    Result := gl.ChoosePixelFormat(FWDC, @iattributes[0], nil, 10, @aFormat, @formatCount);
    if not Result then
    begin
      //Попробуем FSAA на 2x
      iAttributes[19] := 2;
      Result := gl.ChoosePixelFormat(FWDC, @iattributes[0], nil, 10, @aFormat, @formatCount);
    end;
    SetLength(iAttributes, 0);
  end
  else
  begin
    logWriteError('wglChoosePixelFormat не обнаружен. Используем обычный');
    aFormat := 0;
    Result := False;
    Exit;
  end;
end;

function TglrRenderer.RegisterScene(const aScene: IglrBaseScene): Integer;
begin
  Result := FScenes.Add(aScene)
end;

function TglrRenderer.GetWidth: Integer;
begin
  Result := FWWidth;
end;

function TglrRenderer.GetWindowCaption(): WideString;
begin
  Result := FWCaption;
end;

procedure TglrRenderer.SetWindowCaption(aCaption: WideString);
begin
  SetWindowText(FWHandle, aCaption);
  FWCaption := aCaption;
end;

function TglrRenderer.GetRC: hglRC;
begin
  Result := FGLRC;
end;

function TglrRenderer.GetRenderReady(): Boolean;
begin
  Result := FRenderReady;
end;

function TglrRenderer.GetRootNode: IglrNode;
begin
  Result := FRootNode;
end;

function TglrRenderer.GetSelfVersion: PWideChar;
var
  FileName: String;
  VerInfoSize: Cardinal;
  VerValueSize: Cardinal;
  Dummy: Cardinal;
  PVerInfo: Pointer;
  PVerValue: PVSFixedFileInfo;
begin
  FileName := glr.dllName;
  Result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(FileName), Dummy);
  GetMem(PVerInfo, VerInfoSize);
  try
    if GetFileVersionInfo(PChar(FileName), 0, VerInfoSize, PVerInfo) then
      if VerQueryValue(PVerInfo, '\', Pointer(PVerValue), VerValueSize) then
        with PVerValue^ do
          Result := PWideChar(Format('v%d.%d.%d build %d', [
            HiWord(dwFileVersionMS), //Major
            LoWord(dwFileVersionMS), //Minor
            HiWord(dwFileVersionLS), //Release
            LoWord(dwFileVersionLS)])); //Build
  finally
    FreeMem(PVerInfo, VerInfoSize);
  end;
end;

function TglrRenderer.GetTexSwitches: Integer;
begin
  Result := FTexSwitches;
end;

function TglrRenderer.GetFPS(): Single;
begin
  Result := FFPS;
end;

function TglrRenderer.GetHeight: Integer;
begin
  Result := FWHeight;
end;

function TglrRenderer.GetInput: IglrInput;
begin
  Result := FInput;
end;

function TglrRenderer.GetManager: IglrGUIManager;
begin
  Result := FGUIManager;
end;

function TglrRenderer.GetOnMouseDown: TglrOnMouseDownProc;
begin
  Result := FOnMouseDown;
end;

function TglrRenderer.GetOnMouseMove: TglrOnMouseMoveProc;
begin
  Result := FOnMouseMove;
end;

function TglrRenderer.GetOnMouseUp: TglrOnMouseUpProc;
begin
  Result := FOnMouseUp;
end;

function TglrRenderer.GetOnMouseWheel: TglrOnMouseWheelProc;
begin
  Result := FOnMouseWheel;
end;

function TglrRenderer.GetOnUpdate: TglrOnUpdateProc;
begin
  Result := FOnUpdate;
end;

function TglrRenderer.GetCamera(): IglrCamera;
begin
  Result := FCamera;
end;

function TglrRenderer.GetDC: hDC;
begin
  Result := FWDC;
end;

function TglrRenderer.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

procedure TglrRenderer.SetCamera(const aCamera: IglrCamera);
begin
  FCamera := aCamera;
end;

procedure TglrRenderer.SetEnabled(aEnabled: Boolean);
begin
  FEnabled := aEnabled;
end;

procedure TglrRenderer.SetInput(const aInput: IglrInput);
begin
  FInput := aInput;
end;

procedure TglrRenderer.SetManager(const aManager: IglrGUIManager);
begin
  FGUIManager := aManager;
end;

procedure TglrRenderer.SetOnMouseDown(aProc: TglrOnMouseDownProc);
begin
  FOnMouseDown := aProc;
end;

procedure TglrRenderer.SetOnMouseMove(aProc: TglrOnMouseMoveProc);
begin
  FOnMouseMove := aProc;
end;

procedure TglrRenderer.SetOnMouseUp(aProc: TglrOnMouseUpProc);
begin
  FOnMouseUp := aProc;
end;

procedure TglrRenderer.SetOnMouseWheel(aProc: TglrOnMouseWheelProc);
begin
  FOnMouseWheel := aProc;
end;

procedure TglrRenderer.SetOnUpdate(aProc: TglrOnUpdateProc);
begin
  FOnUpdate := aProc;
end;

procedure TglrRenderer.SetRootNode(const aRoot: IglrNode);
begin
  FRootNode := aRoot;
end;

{$REGION 'Коллбэки'}

procedure TglrRenderer.WMLButtonDown(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();
  
  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseDown) then
  begin
//    Include(ShiftState, ssLeft);
    FOnMouseDown(X, Y, mbLeft, []);
  end;

  FGUIManager.MouseDown(X, Y, mbLeft, []);
end;

procedure TglrRenderer.WMLButtonUp(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseUp) then
  begin
//    Exclude(ShiftState, ssLeft);
    FOnMouseUp(X, Y, mbLeft, []);
  end;

  FGUIManager.MouseUp(X, Y, mbLeft, []);
end;

procedure TglrRenderer.WMActivate(var Msg: TWMActivate);
begin
  if not FRenderReady then Exit();

  FInput.AllowKeyCapture := (Msg.Active <> WA_INACTIVE);
end;

procedure TglrRenderer.WMClose(var Msg: TWMClose);
begin
  if not FRenderReady then Exit();

  Stop();
end;

procedure TglrRenderer.WMKeyDown(var Msg: TWMKeyDown);
begin
  if not FRenderReady then Exit();

  FGUIManager.KeyDown(Msg.CharCode, Msg.KeyData);
end;

procedure TglrRenderer.WMLButtonDblClick(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseDown) then
  begin
    FOnMouseDown(X, Y, mbLeft, [ssDouble]);
  end;

  FGUIManager.MouseDown(X, Y, mbLeft, [ssDouble]);
end;

procedure TglrRenderer.WMRButtonDown(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseDown) then
  begin
//    Include(ShiftState, ssRight);
    FOnMouseDown(X, Y, mbRight, []);
  end;

  FGUIManager.MouseDown(X, Y, mbRight, []);
end;

procedure TglrRenderer.WMRButtonUp(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseUp) then
  begin
//    Exclude(ShiftState, ssRight);
    FOnMouseUp(X, Y, mbRight, []);
  end;

  FGUIManager.MouseUp(X, Y, mbRight, []);
end;

procedure TglrRenderer.WMRButtonDblClick(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseDown) then
  begin
    FOnMouseDown(X, Y, mbRight, [ssDouble]);
  end;

  FGUIManager.MouseDown(X, Y, mbRight, [ssDouble]);
end;

procedure TglrRenderer.WMMButtonDown(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseDown) then
  begin
//    Include(ShiftState, ssMiddle);
    FOnMouseDown(X, Y, mbMiddle, []);
  end;

  FGUIManager.MouseDown(X, Y, mbMiddle, []);
end;

procedure TglrRenderer.WMMButtonUp(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseUp) then
  begin
//    Exclude(ShiftState, ssMiddle);
    FOnMouseUp(X, Y, mbMiddle, []);
  end;

  FGUIManager.MouseUp(X, Y, mbMiddle, []);
end;

procedure TglrRenderer.WMMButtonDblClick(var Msg: TMessage);
var
  X, Y: Integer;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  if Assigned(FOnMouseDown) then
  begin
    FOnMouseDown(X, Y, mbMiddle, [ssDouble]);
  end;

  FGUIManager.MouseDown(X, Y, mbMiddle, [ssDouble]);
end;

procedure TglrRenderer.WMMouseMove(var Msg: TMessage);
var
  X, Y: Integer;
  Shift: TglrMouseShiftState;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  Shift := [];
  if Msg.wParam and MK_LBUTTON <> 0 then
    Include(Shift, ssLeft);
  if Msg.wParam and MK_RBUTTON <> 0 then
    Include(Shift, ssRight);
  if Msg.wParam and MK_MBUTTON <> 0 then
    Include(Shift, ssMiddle);
  if Assigned(FOnMouseMove) then
  begin
    FOnMouseMove(X, Y, Shift);
  end;

  FGUIManager.MouseMove(X, Y, Shift);
end;

procedure TglrRenderer.WMMouseWheel(var Msg: TMessage);
var
  X, Y: Integer;
  delta: SmallInt;
begin
  if not FRenderReady then Exit();

  X := LOWORD(Msg.LParam);
  Y := HIWORD(Msg.LParam);
  delta := HIWORD(Msg.WParam);
  FInput.KeyboardNotifyWheelMoved(delta);

  FGUIManager.MouseWheel(X, Y, [], delta);
end;

procedure TglrRenderer.WMSize(var Msg: TWMSize);
begin
  if not FRenderReady then Exit();

  if (Camera <> nil) then
  begin
    Camera.ViewportOnly(0, 0, Msg.Width, Msg.Height);
  end;
end;

procedure TglrRenderer.WMSetCursor(var Msg: TWMSetCursor);
begin
  if not FRenderReady then Exit();

  if (Msg.HitTest = HTCLIENT) and (FhDefaultCursor = 0) then
  begin
    SetCursor(0);
    Msg.Result := 1;
  end;
  
end;

{$ENDREGION}

constructor TglrRenderer.Create;
begin
  inherited;
  FRenderReady := False;
  FWHandle := 0;
  FWCaption := cDefWindowCaption;
  FEnabled := True;

  FRootNode := TglrNode.Create();

  FScenes := TInterfaceList.Create;

  FInput := TglrInput.Create();

  FGUIManager := TglrGUIManager.Create();

  uLogger.LogInit();
end;

destructor TglrRenderer.Destroy;
begin
  FRenderReady := False;
  FScenes.Free();
  FCamera := nil;
  FRootNode := nil;
  FInput := nil;
  FGUIManager := nil;

  uLogger.LogDeinit();
  inherited;
end;

procedure TglrRenderer.Init(FileName: PAnsiChar);
var
  camPos, camLook, camUp: TdfVec3f;

  cFOV, cZNear, cZFar: Single;
  bVSync, bCursor: Boolean;
  useMultisample: Boolean;
  msFormat: Integer;

  procedure LoadSettings();
  var
    strData: TFileStream;
    par: TParser;
  begin
    if FileExists(FileName) then
      strData := TFileStream.Create(FileName, fmOpenRead)
    else
    begin
      logWriteError('Отсутствует файл конфига ' + FileName, True, True, True);
      Exit;
    end;
    par := TParser.Create(strData);
    repeat
      if par.TokenString = 'decimalseparator' then
      begin
        par.NextToken;
        DecimalSeparator := par.TokenString[1];
      end
      //Окно
      else if par.TokenString = 'rendermode' then
      begin
        //Пока только оконный рендер
        par.NextToken;
        if par.TokenString = 'window' then
        begin
          //Bla-Bla
        end
        else
        begin
          //Bla-Bla
        end;
      end
      else if par.TokenString = 'resolution' then
      begin
        par.NextToken;
        FWWidth := par.TokenInt;
        par.NextToken;
        FWHeight := par.TokenInt;
      end
      else if par.TokenString = 'windowPos' then
      begin
        par.NextToken;
        FWX := par.TokenInt;
        par.NextToken;
        FWY := par.TokenInt;
      end
      else if par.TokenString = 'caption' then
      begin
        par.NextToken;
        FWCaption := PWideChar(par.TokenString);
      end
      else if par.TokenString = 'backgroundColor' then
      begin
        par.NextToken;
        FBackgroundColor.x := par.TokenFloat;
        par.NextToken;
        FBackgroundColor.y := par.TokenFloat;
        par.NextToken;
        FBackgroundColor.z := par.TokenFloat;
      end
      else if par.TokenString = 'axes' then
      begin
        par.NextToken;
        FDrawAxes := (par.TokenString = 'true');
      end
      else if par.TokenString = 'vsync' then
      begin
        par.NextToken;
        bVSync := (par.TokenString = 'true');
      end
      //Курсор
      else if par.TokenString = 'cursor' then
      begin
        par.NextToken;
        bCursor := (par.TokenString = 'true');
      end
      //Камера
      else if par.TokenString = 'FOV' then
      begin
        par.NextToken;
        cFOV := par.TokenFloat;
      end
      else if par.TokenString = 'zNear' then
      begin
        par.NextToken;
        czNear := par.TokenFloat;
      end
      else if par.TokenString = 'zFar' then
      begin
        par.NextToken;
        czFar := par.TokenFloat;
      end
      else if par.TokenString = 'cameraPos' then
      begin
        par.NextToken;
        camPos.x := par.TokenFloat;
        par.NextToken;
        camPos.y := par.TokenFloat;
        par.NextToken;
        camPos.z := par.TokenFloat;
      end
      else if par.TokenString = 'cameraLook' then
      begin
        par.NextToken;
        camLook.x := par.TokenFloat;
        par.NextToken;
        camLook.y := par.TokenFloat;
        par.NextToken;
        camLook.z := par.TokenFloat;
      end
      else if par.TokenString = 'cameraUp' then
      begin
        par.NextToken;
        camUp.x := par.TokenFloat;
        par.NextToken;
        camUp.y := par.TokenFloat;
        par.NextToken;
        camUp.z := par.TokenFloat;
      end
      else if par.TokenString = 'multisample' then
      begin
        par.NextToken();
        useMultisample := (par.TokenString() = 'true');
      end;

    until par.NextToken = toEOF;
    par.Free;
    strData.Free;
    logWriteMessage('Успешная загрузка параметров из конфиг-файла ' + FileName);
  end;

  procedure InitWindow();
  begin
    //Инициализация
    FWStyle := WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_CLIPSIBLINGS or WS_CLIPCHILDREN;

    SetRect(FdesRect, 0, 0, FWWidth, FWHeight);
    AdjustWindowRect(FdesRect, FWStyle, False);
    ZeroMemory(@FWndClass, SizeOf(TWndClass));
    with FWndClass do
    begin
      style := CS_VREDRAW or CS_HREDRAW or CS_OWNDC;
      hInstance := 0;
      hIcon := LoadIcon(0, IDI_WINLOGO);
      if bCursor then
        hCursor := LoadCursor(0, IDC_ARROW)
      else
        hCursor := 0;
      FhDefaultCursor := hCursor;
      hbrBackground := GetStockObject (White_Brush);
      lpfnWndProc := @WindowProc;
      lpszClassName := 'TdfWindow';
    end;
    FhHandCursor := LoadCursor(0, IDC_HAND);

    Windows.RegisterClass(FWndClass);
//    tmpString := FWCaption + ' [glRenderer ' + GetSelfVersion + ']';
    FWHandle := CreateWindow('TdfWindow', PWideChar(FWCaption), FWStyle,
                            FWX, FWY, FdesRect.Right - FdesRect.Left, FdesRect.Bottom - FdesRect.Top, 0, 0, FWndClass.hInstance, nil);
    if FWHandle = 0 then
    begin
      logWriteError('Ошибка инициализации окна. Возвращен нулевой handle', True, True, True);
      Exit;
    end;
    logWriteMessage('Успешная инициализация окна, полученный handle: ' + IntToStr(FWHandle));
  end;

  procedure FreeContext();
  begin
    wglMakeCurrent(FWDC, 0);
    wglDeleteContext(FGLRC);
    ReleaseDC(FWHandle, FWDC);
    FWDC := 0;
    FGLRC := 0;
  end;

  procedure FreeWindow();
  begin
    CloseWindow(FWHandle);
    DestroyWindow(FWHandle);
  end;

begin
  FSelfWindow := True;

  FWWidth := cDefWindowW;
  FWHeight := cDefWindowH;
  FWX := cDefWindowX;
  FWY := cDefWindowY;

  try
    LoadSettings();

    InitWindow();
    OpenGLInitContext(0); //обычный pixel format
    msFormat := 0;
    if useMultisample then
      if TryGetMultisampleFormat(msFormat) then
      begin
        FreeContext();
        FreeWindow();
        InitWindow();
        OpenGLInitContext(msFormat);
      end;

    OpenGLInit(bVSync, cFOV, cZNear, cZFar, camPos, camLook, camUp);

    FRenderReady := True;

    logWriteMessage('Успешная инициализация');
  except

  end;
end;

procedure TglrRenderer.Init(Handle: THandle; FileName: PAnsiChar);
var
  camPos, camLook, camUp: TdfVec3f;

  cFOV, cZNear, cZFar: Single;
  bVSync: Boolean;
  //tmpString: String;

  procedure LoadSettings();
  var
    strData: TFileStream;
    par: TParser;
  begin
    if FileExists(FileName) then
      strData := TFileStream.Create(FileName, fmOpenRead)
    else
    begin
      logWriteError('Отсутствует файл конфига ' + FileName, True, True, True);
      Exit;
    end;
    par := TParser.Create(strData);
    repeat
      if par.TokenString = 'decimalseparator' then
      begin
        par.NextToken;
        DecimalSeparator := par.TokenString[1];
      end
      else if par.TokenString = 'caption' then
      begin
        par.NextToken;
        FWCaption := PWideChar(par.TokenString);
      end
      else if par.TokenString = 'backgroundColor' then
      begin
        par.NextToken;
        FBackgroundColor.x := par.TokenFloat;
        par.NextToken;
        FBackgroundColor.y := par.TokenFloat;
        par.NextToken;
        FBackgroundColor.z := par.TokenFloat;
      end
      else if par.TokenString = 'axes' then
      begin
        par.NextToken;
        FDrawAxes := (par.TokenString = 'true');
      end
      else if par.TokenString = 'vsync' then
      begin
        par.NextToken;
        bVSync := (par.TokenString = 'true');
      end
      //Камера
      else if par.TokenString = 'FOV' then
      begin
        par.NextToken;
        cFOV := par.TokenFloat;
      end
      else if par.TokenString = 'zNear' then
      begin
        par.NextToken;
        czNear := par.TokenFloat;
      end
      else if par.TokenString = 'zFar' then
      begin
        par.NextToken;
        czFar := par.TokenFloat;
      end
      else if par.TokenString = 'cameraPos' then
      begin
        par.NextToken;
        camPos.x := par.TokenFloat;
        par.NextToken;
        camPos.y := par.TokenFloat;
        par.NextToken;
        camPos.z := par.TokenFloat;
      end
      else if par.TokenString = 'cameraLook' then
      begin
        par.NextToken;
        camLook.x := par.TokenFloat;
        par.NextToken;
        camLook.y := par.TokenFloat;
        par.NextToken;
        camLook.z := par.TokenFloat;
      end
      else if par.TokenString = 'cameraUp' then
      begin
        par.NextToken;
        camUp.x := par.TokenFloat;
        par.NextToken;
        camUp.y := par.TokenFloat;
        par.NextToken;
        camUp.z := par.TokenFloat;
      end
    until par.NextToken = toEOF;
    par.Free;
    strData.Free;
    logWriteMessage('Успешная загрузка параметров из конфиг-файла ' + FileName);
  end;

begin
  FSelfWindow := False;

  FWHandle := Handle;
  GetWindowRect(FWHandle, FdesRect);
  FWWidth := FdesRect.Right - FdesRect.Left;
  FWHeight := FdesRect.Bottom - FdesRect.Top;
  FParentWndProc := GetWindowLong(FWHandle, GWL_WNDPROC);
  SetWindowLong(FWHandle, GWL_WNDPROC, Integer(@WindowProc));
  FWX := 0;
  FWY := 0;
  try
    LoadSettings();

    OpenGLInit(bVSync, cFOV, cZNear, cZFar, camPos, camLook, camUp);

    FRenderReady := True;

    logWriteMessage('Успешная инициализация');
  except

  end;
end;

procedure TglrRenderer.Step(deltaTime: Double);
  procedure DrawAxes();
  begin
    //Draw axes
    gl.Disable(GL_LIGHTING);
    gl.Beginp(GL_LINES);
      gl.Color4ub(255, 0, 0, 255);
      gl.Vertex3f(0, 0, 0);
      gl.Vertex3f(100, 0, 0);

      gl.Color4ub(0, 255, 0, 255);
      gl.Vertex3f(0, 0, 0);
      gl.Vertex3f(0, 100, 0);

      gl.Color4ub(0, 0, 255, 255);
      gl.Vertex3f(0, 0, 0);
      gl.Vertex3f(0, 0, 100);
    gl.Endp();
    gl.Enable(GL_LIGHTING);
  end;
var
  i: Integer;

begin
  if Assigned(FOnUpdate) then
    FOnUpdate(deltaTime);
  uTexture.textureSwitches := 0;
//  wglMakeCurrent(FWDC, FGLRC);
  gl.Clear(GL_COLOR_BUFFER_BIT);
  gl.Clear(GL_DEPTH_BUFFER_BIT);
  gl.MatrixMode(GL_MODELVIEW);
  gl.LoadIdentity();
  FCamera.Update();
  if FDrawAxes then
    DrawAxes();

    for i := 0 to FScenes.Count - 1 do
      IglrBaseScene(FScenes[i]).Render();

  FRootNode.Render();
  Windows.SwapBuffers(FWDC);
  FTexSwitches := uTexture.textureSwitches;
//  wglMakeCurrent(0, 0);
end;

procedure TglrRenderer.Stop;
begin
  FEnabled := False;
end;

procedure TglrRenderer.UnregisterScene(const aScene: IglrBaseScene);
begin
  FScenes.Remove(aScene);
end;

procedure TglrRenderer.UnregisterScenes;
begin
  FScenes.Clear();
end;

procedure TglrRenderer.Start();
var
  msg: TMsg;
begin
  SendMessage(FWHandle, WM_ACTIVATE, WA_ACTIVE, FWHandle);
  repeat
    while PeekMessage(msg, 0, 0, 0, 1) do
    begin
      TranslateMessage(msg);
      DispatchMessageW(msg);
    end;
    QueryPerformanceCounter(FNewTicks);
    FDeltaTime := (FNewTicks - FOldTicks) / FFreq;
    FOldTicks := FNewTicks;
    if FDeltaTime > 0.1 then
      FDeltaTime := 0.1;
    FFPS :=  1 / FDeltaTime;
    if RenderReady then
      Step(FDeltaTime);
  until not FEnabled;
end;

procedure TglrRenderer.DeInit();
begin
  logWriteMessage('Деинициализация рендера');
  UnregisterScenes();
  FRenderReady := False;
  wglMakeCurrent(FWDC, 0);
  wglDeleteContext(FGLRC);
  ReleaseDC(FWHandle, FWDC);
  FWDC := 0;
  FGLRC := 0;
  if FSelfWindow then
  begin
    CloseWindow(FWHandle);
    DestroyWindow(FWHandle);
  end
  else
    SetWindowLong(FWHandle, GWL_WNDPROC, FParentWndProc);
  FWHandle := 0;
end;

{$ENDREGION}

initialization
  TheRenderer := TglrRenderer.Create();

finalization
  TheRenderer := nil;
end.

{
  Last developed:

  TODO: Сохранение уровня
        Загрузка уровня
        Расстановка статичных объектов

  2012-08-29 - LD - uLevel_SaveLoad.

}


unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Menus, Spin,

  dfHRenderer, dfMath, dfHUtility;

type
  TtzEditorMode = (emSelect, emEarth, emStaticObjects, emDynamicObjects, emPlayer);

  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    gbEarthTools: TGroupBox;
    btnEarthPathCreate: TButton;
    btnEarthPathSelect: TButton;
    btnSelect: TButton;
    btnEarth: TButton;
    btnObjects: TButton;
    gbEarthProperties: TGroupBox;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    menuNewLevel: TMenuItem;
    menuLoadLevel: TMenuItem;
    menuSaveLevel: TMenuItem;
    menuSaveLevelAs: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    menuExit: TMenuItem;
    editEarthPosX: TLabeledEdit;
    editEarthPosY: TLabeledEdit;
    editEarthIndex: TSpinEdit;
    Label1: TLabel;
    gbObjectProperties: TGroupBox;
    editObjectPosY: TLabeledEdit;
    editObjectPosX: TLabeledEdit;
    editObjectSizeY: TLabeledEdit;
    editObjectSizeX: TLabeledEdit;
    editObjectRot: TLabeledEdit;
    gbObjectTools: TGroupBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnEarthPathSelectClick(Sender: TObject);
    procedure btnEarthPathCreateClick(Sender: TObject);
    procedure menuExitClick(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure btnEarthClick(Sender: TObject);
    procedure btnObjectsClick(Sender: TObject);
  private
    FEditorMode: TtzEditorMode;
    function GetGroupBox1Pos(): TSize;
    function GetGroupBox2Pos(): TSize;
    procedure SetEditorMode(aMode: TtzEditorMode);
  public
    procedure EnableAllButtons(aEnable: Boolean);

    property EditorMode: TtzEditorMode read FEditorMode write SetEditorMode;
    property GroupBox1Pos: TSize read GetGroupBox1Pos;
    property GroupBox2Pos: TSize read GetGroupBox2Pos;
  end;

  procedure glrOnUpdate(const dt: Double);
  procedure glrOnMouseDown(X, Y: Integer; MouseButton: TdfMouseButton; Shift: TdfMouseShiftState);
  procedure glrOnMouseUp(X, Y: Integer; MouseButton: TdfMouseButton; Shift: TdfMouseShiftState);
  procedure glrOnMouseMove(X, Y: Integer; Shift: TdfMouseShiftState);

const
  C_POINTSPRTE_SIZE = 10;
  C_SELECT_RADIUS = C_POINTSPRTE_SIZE + 5;
  C_NORMAL_COLOR: TdfVec4f = (X: 0.5; Y: 0.5; z: 0.5; w: 1.0);
  C_SELECT_COLOR: TdfVec4f = (X: 1.0; Y: 0.5; z: 0.5; w: 1.0);

var
  Form1: TForm1;

  FRenderer: IdfRenderer;

implementation

uses
  uEarthTools, uLevel_SaveLoad,
  dfHGL;

procedure glrOnUpdate(const dt: Double);
begin
  //*
end;

procedure glrOnMouseDown(X, Y: Integer; MouseButton: TdfMouseButton; Shift: TdfMouseShiftState);

  procedure EarthMouseDown(X, Y: Integer);
  begin
    with EarthTools do
      case Mode of
        emNewPoints: AddNewPointToEarthPath(X, Y, -1);
        emSelectPoints:
        begin
          if Selected = TrySelectPoint(X, Y) then
            Mode := emDragPoint;
        end;
      end;
  end;


begin
  if MouseButton = mbLeft then
    case Form1.EditorMode of
      emSelect: ;
      emEarth: EarthMouseDown(X, Y);
      emStaticObjects: ;
      emDynamicObjects: ;
      emPlayer: ;
    end;

//    end;
end;

procedure glrOnMouseUp(X, Y: Integer; MouseButton: TdfMouseButton; Shift: TdfMouseShiftState);
begin
  case Form1.EditorMode of
      emSelect: ;
      emEarth:
        if EarthTools.Mode = emDragPoint then
          EarthTools.Mode := emSelectPoints;
      emStaticObjects: ;
      emDynamicObjects: ;
      emPlayer: ;
  end;
end;

procedure glrOnMouseMove(X, Y: Integer; Shift: TdfMouseShiftState);
begin
  case Form1.EditorMode of
      emSelect: ;
      emEarth:
        if EarthTools.Mode = emDragPoint then
          EarthTools.MoveSelectedPoint(X, Y);
      emStaticObjects: ;
      emDynamicObjects: ;
      emPlayer: ;
  end;
end;

{$R *.dfm}

procedure TForm1.btnEarthClick(Sender: TObject);
begin
  SetEditorMode(emEarth);
end;

procedure TForm1.btnEarthPathCreateClick(Sender: TObject);
begin
  EarthTools.Mode := emNewPoints;
  btnEarthPathCreate.Enabled := False;
  btnEarthPathSelect.Enabled := True;
end;

procedure TForm1.btnEarthPathSelectClick(Sender: TObject);
begin
  EarthTools.Mode := emSelectPoints;
  btnEarthPathSelect.Enabled := False;
  btnEarthPathCreate.Enabled := True;
end;

procedure TForm1.btnObjectsClick(Sender: TObject);
begin
  SetEditorMode(emStaticObjects);
end;

procedure TForm1.btnSelectClick(Sender: TObject);
begin
  SetEditorMode(emSelect);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  //Инициализация
  //*
  Button1.Enabled := False;
  FRenderer := dfCreateRenderer();
  Caption := 'glRenderer in VCL :: ' + FRenderer.VersionText;
  FRenderer.Init(Panel1.Handle, 'settings_TvsZ.txt');
  FRenderer.OnUpdate := glrOnUpdate;
  FRenderer.OnMouseDown := glrOnMouseDown;
  FRenderer.OnMouseUp := glrOnMouseUp;
  FRenderer.OnMouseMove := glrOnMouseMove;
  Button2.Enabled := True;
//  btnEarthPathSelectClick(Self);

//  EnableAllButtons(True);
  SetEditorMode(emSelect);

  EarthTools := TtzEarthTools.Create(FRenderer.RootNode);

  //Создаем рендерер земли
  FRenderer.Start();
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  //Деинициализация
  Button2.Enabled := False;
  EnableAllButtons(False);
  if Assigned(FRenderer) then
  begin
    FRenderer.Stop();
    FRenderer.DeInit();
    FRenderer := nil;
  end;
  Button1.Enabled := True;
  EarthTools.Free;
end;

procedure TForm1.EnableAllButtons(aEnable: Boolean);
begin
  btnSelect.Enabled := aEnable;
  btnEarth.Enabled := aEnable;
  btnObjects.Enabled := aEnable;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FRenderer) then
    Button2Click(Sender);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadRendererLib();
  gl.Init();
  SetEditorMode(emSelect);
  EnableAllButtons(False);
end;

function TForm1.GetGroupBox1Pos: TSize;
begin
  Result.cx := Panel1.Width + 14;
  Result.cy := 104;
end;

function TForm1.GetGroupBox2Pos: TSize;
begin
  Result.cx := Panel1.Width + 14;
  Result.cy := 304;
end;

procedure TForm1.menuExitClick(Sender: TObject);
begin
  Close();
end;

procedure TForm1.SetEditorMode(aMode: TtzEditorMode);

  procedure SetModeSelect();
  begin
    gbEarthTools.Visible := False;
    gbEarthProperties.Visible := False;
    gbObjectTools.Visible := False;
    gbObjectProperties.Visible := False;

    btnSelect.Enabled := False;
    btnEarth.Enabled := True;
    btnObjects.Enabled := True;
  end;

  procedure SetModeEarth();
  var
    pos1, pos2: TSize;
  begin
    pos1 := GroupBox1Pos;
    pos2 := GroupBox2Pos;

    gbEarthTools.Visible := True;
    gbEarthTools.Left := pos1.cx;
    gbEarthTools.Top := pos1.cy;

    gbEarthProperties.Visible := True;
    gbEarthProperties.Left := pos2.cx;
    gbEarthProperties.Top := pos2.cy;

    gbObjectTools.Visible := False;
    gbObjectProperties.Visible := False;

    btnSelect.Enabled := True;
    btnEarth.Enabled := False;
    btnObjects.Enabled := True;
  end;

  procedure SetModeStaticObjects();
  var
    pos1, pos2: TSize;
  begin
    pos1 := GroupBox1Pos;
    pos2 := GroupBox2Pos;

    gbObjectTools.Visible := True;
    gbObjectTools.Left := pos1.cx;
    gbObjectTools.Top := pos1.cy;

    gbObjectProperties.Visible := True;
    gbObjectProperties.Left := pos2.cx;
    gbObjectProperties.Top := pos2.cy;

    gbEarthTools.Visible := False;
    gbEarthProperties.Visible := False;

    btnSelect.Enabled := True;
    btnEarth.Enabled := True;
    btnObjects.Enabled := False;
  end;

begin
  FEditorMode := aMode;
  case aMode of
    emSelect: SetModeSelect();
    emEarth: SetModeEarth();
    emStaticObjects: SetModeStaticObjects();
    emDynamicObjects: ;
    emPlayer: ;
  end;
end;

end.

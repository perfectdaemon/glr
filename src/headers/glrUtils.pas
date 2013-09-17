{‘ункции, облегчающие жизнь}

unit glrUtils;

interface

uses
  glr, glrMath;

const
  FONT_USUAL_CHARS = 'јЅ¬√ƒ≈®∆«»… ЋћЌќѕ–—“”‘’÷„ЎўЏџ№ЁёяабвгдеЄжзийклмнопрстуфхцчшщъыьэю€'
                    +'QWERTYUIIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm'
                    +'1234567890`~!@#$%^&*()"є;%:?-+ЧЂї[]{}'':<>.,\|/ ' + #10;

type
  TglrFPSCounter = class
  private
    FFrames: Integer;
    FNode: IglrNode;
    FScene: Iglr2DScene;
    FTime, FFreq: Double;
    FText: String;

    FPS: Double;
    constructor _Create(aText: String; aFreq: Double; aFont: IglrFont = nil);
  public
    TextObject: IglrText;
    FontObject: IglrFont;
//    constructor Create(aRootNode: IglrNode; aText: String; aFreq: Double; aFont: IglrFont = nil); overload; virtual;
//    constructor Create(aRoot: IglrRenderable; aText: String; aFreq: Double; aFont: IglrFont = nil); overload; virtual;
    constructor Create(aScene: Iglr2DScene; aText: String; aFreq: Double; aFont: IglrFont = nil); overload; virtual;
    destructor Destroy; override;

    procedure Update(const dt: Double);
  end;

  //“екстурные атласы
  TglrTextureInfo = record
    name: String;
    X, Y, W, H: Integer;
    texture: IglrTexture;
    //rotated: Boolean;
  end;

  PglrTextureInfo = ^TglrTextureInfo;

  TglrAtlas = class
  private
    FTexture: IglrTexture;
    FTextureInfo: array of TglrTextureInfo;
    function FindTexture(const aName: String): PglrTextureInfo;
  public
    //ќткрывает файл формата .atlas Cheetah Texture Packer
    //¬ращение пока запрещено
    class function InitCheetahAtlas(const aFileName: String): TglrAtlas;

    constructor Create(); virtual;
    destructor Destroy(); override;

    function LoadTexture(const aTextureName: String; aOnlyNew: Boolean = False): IglrTexture;
  end;

const
  C_PRECISION = 4;
  C_DIGITS = 1;

type
  TglrDebugRec = record
    sCaption, sParam: String;
    bVisible: Boolean;
  end;

  TglrDebugInfo = class
  private
    FScene: Iglr2DScene;
    FDebugs: array of TglrDebugRec;
    procedure ReconstructText();
  public
    FText: IglrText;
    function AddNewString(aCaption: String): Integer;
    procedure ShowString(aIndex: Integer);
    procedure HideString(aIndex: Integer);

    procedure UpdateParam(aIndex: Integer; aParam: Single); overload;
    procedure UpdateParam(aIndex: Integer; aParam: Integer); overload;
    procedure UpdateParam(aIndex: Integer; aParam: WideString); overload;
    procedure UpdateParam(aIndex: Integer; aParam: TdfVec2f); overload;
    procedure UpdateParam(aIndex: Integer; aParam: TdfVec3f); overload;

    constructor Create(aScene: Iglr2DScene); virtual;
    destructor Destroy; override;
  end;

  {—оздает шрифт с заполненными по умолчанию значени€ми}
  function glrNewFilledFont(aFontName: String; aFontSize: Integer = 10): IglrFont;

implementation

uses
  Windows, SysUtils;

function glrNewFilledFont(aFontName: String; aFontSize: Integer = 10): IglrFont;
begin
  Result := glrGetObjectFactory.NewFont();
  with Result do
  begin
    AddSymbols('јЅ¬√ƒ≈®∆«»… ЋћЌќѕ–—“”‘’÷„ЎўЏџ№ЁёяабвгдеЄжзийклмнопрстуфхцчшщъыьэю€');
    AddSymbols('QWERTYUIIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm');
    AddSymbols('1234567890');
    AddSymbols('`~!@#$%^&*()"є;%:?-+ЧЂї[]{}'':<>.,\|/ ' + #13+#10);
    FontSize := aFontSize;
    FontStyle := [];
    GenerateFromFont(aFontName);
  end;
end;

{ TdfFPSCounter }

//constructor TglrFPSCounter.Create(aRootNode: IglrNode; aText: String; aFreq: Double; aFont: IglrFont);
//begin
//  _Create(aText, aFreq, aFont);
//
//  FNode := aRootNode.AddNewChild();
//  FNode.Renderable := TextObject;
//
//  FScene := nil;
//end;

constructor TglrFPSCounter.Create(aScene: Iglr2DScene; aText: String;
  aFreq: Double; aFont: IglrFont);
begin
  _Create(aText, aFreq, aFont);

  FScene := aScene;
  FScene.RegisterElement(TextObject);

  FNode := nil;
end;

destructor TglrFPSCounter.Destroy;
begin
  FontObject := nil;
  TextObject := nil;
  FNode := nil;
  if Assigned(FScene) then
    FScene.UnregisterElement(TextObject);
  FScene := nil;
  inherited;
end;

procedure TglrFPSCounter.Update(const dt: Double);
begin
  FTime := FTime + dt;
  Inc(FFrames);
  if FTime >= FFreq then
  begin
    FPS := FFrames / FTime;
    TextObject.Text := FText + ' ' + Format('%.2f', [FPS]);
    FTime := 0.0;
    FFrames := 0;
  end;
end;

constructor TglrFPSCounter._Create(aText: String; aFreq: Double; aFont: IglrFont);
begin
  inherited Create();
  FFreq := aFreq;
  FText := aText;
  if not Assigned(aFont) then
  begin
    FontObject := glrGetObjectFactory().NewFont();
    FontObject.AddSymbols(FText + ' :.,0123456789');
    FontObject.FontSize := 14;
    FontObject.GenerateFromFont('Courier New');
  end
  else
    FontObject := aFont;

  TextObject := glrGetObjectFactory().NewText;
  TextObject.Font := FontObject;
  TextObject.Position := dfVec2f(1, 1);
end;

constructor TglrAtlas.Create;
begin
  inherited;
  FTexture := glrGetObjectFactory().NewTexture();
end;

destructor TglrAtlas.Destroy;
var
  i: Integer;
begin
  FTexture := nil;
  for i := 0 to Length(FTextureInfo) - 1 do
    FTextureInfo[i].texture := nil;
  SetLength(FTextureInfo, 0);
  inherited;
end;

function TglrAtlas.FindTexture(const aName: String): PglrTextureInfo;
var
  i: Integer;
begin
  for i := 0 to High(FTextureInfo) do
    if FTextureInfo[i].name = aName then
      Exit(@FTextureInfo[i]);
end;

class function TglrAtlas.InitCheetahAtlas(const aFileName: String): TglrAtlas;
var
  f: TextFile;
  tmpStr, aAtlasFilename, textureName, dir: String;
  startIndex, current: Integer;
  charBuf: WideChar;
begin
  Result := TglrAtlas.Create();
  with Result do
  begin
    AssignFile(f, aFileName);
    Reset(f);
    //--„итаем им€ файла текстуры атласа
    ReadLn(f, tmpStr);
    startIndex := Pos(':', tmpStr) + 2;
    aAtlasFileName := Copy(tmpStr, startIndex, Length(tmpStr) - startIndex + 1);
    dir := ExtractFileDir(aFileName);
    //--«агружаем текстуру
    FTexture.Load2D(dir +'\'+ aAtlasFilename);
    FTexture.BlendingMode := tbmTransparency;
    FTexture.CombineMode := tcmModulate;
    //--„итаем информацию о других участках
    while not Eof(f) do
    begin
      current := Length(FTextureInfo);
      SetLength(FTextureInfo, current + 1);
      //--„итаем им€ текстуры
      textureName := '';
      Read(f, charBuf);
      while charBuf <> #9 do //табул€ци€
      begin
        textureName := textureName + charBuf;
        Read(f, charBuf);
      end;
      //--„итаем информацию о других свойствах
      with FTextureInfo[current] do
      begin
        name := textureName;
        Read(f, X); Read(f, Y);
        Read(f, W); Read(f, H);
      end;
      //--ќстальное нам не интересно
      ReadLn(f, tmpStr);
    end;
    CloseFile(f);
  end;
end;

function TglrAtlas.LoadTexture(const aTextureName: String;
  aOnlyNew: Boolean = False): IglrTexture;
begin

  with FindTexture(aTextureName)^ do
  begin
    //“екстура не была найдена, возвращаем пустую
    if name <> aTextureName then
      Exit(glrGetObjectFactory().NewTexture());
    if aOnlyNew then
    begin
      Result := glrGetObjectFactory().NewTexture();
      Result.Load2DRegion(FTexture, X, Y, W, H);
    end
    else
      if Assigned(texture) then
        Result := texture
      else
      begin
        texture := glrGetObjectFactory().NewTexture();
        texture.Load2DRegion(FTexture, X, Y, W, H);
        Result := texture;
      end;
  end;
end;

{ TpdDebugInfo }

function TglrDebugInfo.AddNewString(aCaption: String): Integer;
var
  i: Integer;
begin
  i := Length(FDebugs);
  SetLength(FDebugs, i + 1);
  FDebugs[i].sCaption := aCaption;
  FDebugs[i].sParam := '';
  FDebugs[i].bVisible := True;
  Result := i;
end;

constructor TglrDebugInfo.Create(aScene: Iglr2DScene);
begin
  inherited Create();
  SetLength(FDebugs, 0);
  FText := glrGetObjectFactory().NewText();
  FText.Font := glrNewFilledFont('Courier New', 12);
  FText.Z := 100;
  FText.Position := dfVec2f(0, 0);
  FScene := aScene;
  FScene.RegisterElement(FText);
end;

destructor TglrDebugInfo.Destroy;
begin
  FScene.UnregisterElement(FText);
  FScene := nil;
  FText := nil;

  SetLength(FDebugs, 0);
  inherited;
end;

procedure TglrDebugInfo.HideString(aIndex: Integer);
begin
  FDebugs[aIndex].bVisible := False;
end;

procedure TglrDebugInfo.ReconstructText;
var
  i: Integer;
  sText: WideString;
begin
//  Text :=
  sText := '';
  for i := 0 to Length(FDebugs) - 1 do
    if FDebugs[i].bVisible then
      sText := sText + FDebugs[i].sCaption + ': ' + FDebugs[i].sParam + ';' + #13#10;

  FText.Text := sText;
end;

procedure TglrDebugInfo.ShowString(aIndex: Integer);
begin
  FDebugs[aIndex].bVisible := True;
end;

procedure TglrDebugInfo.UpdateParam(aIndex, aParam: Integer);
begin
  UpdateParam(aIndex, IntToStr(aParam));
end;

procedure TglrDebugInfo.UpdateParam(aIndex: Integer; aParam: Single);
begin
  UpdateParam(aIndex, FloatToStrF(aParam, ffGeneral, C_PRECISION, C_DIGITS));
end;

procedure TglrDebugInfo.UpdateParam(aIndex: Integer; aParam: TdfVec2f);
begin
  UpdateParam(aIndex,
    '['+FloatToStrF(aParam.x, ffGeneral, C_PRECISION, C_DIGITS) + '] [' +
        FloatToStrF(aParam.y, ffGeneral, C_PRECISION, C_DIGITS) + ']');
end;

procedure TglrDebugInfo.UpdateParam(aIndex: Integer; aParam: TdfVec3f);
begin
  UpdateParam(aIndex,
    '['+FloatToStrF(aParam.x, ffGeneral, C_PRECISION, C_DIGITS) + '] [' +
    '['+FloatToStrF(aParam.y, ffGeneral, C_PRECISION, C_DIGITS) + '] [' +
    '['+FloatToStrF(aParam.z, ffGeneral, C_PRECISION, C_DIGITS) + ']');
end;

procedure TglrDebugInfo.UpdateParam(aIndex: Integer; aParam: WideString);
begin
  if FDebugs[aIndex].sParam <> aParam then
  begin
    FDebugs[aIndex].sParam := aParam;
    ReconstructText();
  end;
end;

end.

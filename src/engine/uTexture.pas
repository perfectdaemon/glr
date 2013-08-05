{
+ TODO: Начато внедрение TdfTextureDescription, отложено, так как нет особой нужды
        Сделано?
  TODO: Рефакторинг Load2D(File), Load2D(Stream), унифицировать

}

unit uTexture;

interface

uses
  dfHRenderer, dfHGL;

type
  TglrTexture = class(TInterfacedObject, IglrTexture)
  private
//    FName: String;
    FTex: TglrTextureDecription;
    FLoaded, FLoadedFromAtlas: Boolean;

    FWrapS, FWrapT, FWrapR: TglrTextureWrap;
    FMinFilter: TglrTextureMinFilter;
    FMagFilter: TglrTextureMagFilter;
    FBlendingMode: TglrTextureBlendingMode;
    FCombineMode: TglrTextureCombineMode;

    procedure _SetBlendingMode();
  protected
    function GetWidth(): Integer;
    function GetHeight(): Integer;

    function GetTexTarget(): TglrTextureTarget;
    function GetTexWrapS(): TglrTextureWrap;
    function GetTexWrapT(): TglrTextureWrap;
    function GetTexWrapR(): TglrTextureWrap;
    function GetTexMinFilter(): TglrTextureMinFilter;
    function GetTexMagFilter(): TglrTextureMagFilter;
    function GetTexBlendingMode(): TglrTextureBlendingMode;
    function GetTexCombineMode(): TglrTextureCombineMode;

    procedure SetTexWrapS(aWrap: TglrTextureWrap);
    procedure SetTexWrapT(aWrap: TglrTextureWrap);
    procedure SetTexWrapR(aWrap: TglrTextureWrap);
    procedure SetTexMinFilter(aFilter: TglrTextureMinFilter);
    procedure SetTexMagFilter(aFilter: TglrTextureMagFilter);
    procedure SetTexBlendingMode(aMode: TglrTextureBlendingMode);
    procedure SetTexCombineMode(aMode: TglrTextureCombineMode);
  public
    function GetTexDesc(): TglrTextureDecription;

    constructor Create; virtual;
    destructor Destroy; override;

    procedure Bind;
    procedure Unbind;
    {debug}
    procedure Load2D(const aFileName: String); overload;
    procedure Load2D(const aStream: TglrStream; aFormatExtension: String); overload;

    procedure Load2DRegion(const aTex: IglrTexture; aX, aY, aWidth, aHeight: Integer);

    property Target: TglrTextureTarget read GetTexTarget;
    property WrapS: TglrTextureWrap read GetTexWrapS write SetTexWrapS;
    property WrapT: TglrTextureWrap read GetTexWrapT write SetTexWrapT;
    property WrapR: TglrTextureWrap read GetTexWrapR write SetTexWrapR;
    property MinFilter: TglrTextureMinFilter read GetTexMinFilter write SetTexMinFilter;
    property MagFilter: TglrTextureMagFilter read GetTexMagFilter write SetTexMagFilter;
    property BlendingMode: TglrTextureBlendingMode read GetTexBlendingMode write SetTexBlendingMode;
    property CombineMode: TglrTextureCombineMode read GetTexCombineMode write SetTexCombineMode;

    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
  end;

var
  // !!! DEBUG
  textureSwitches: Integer = 0;

implementation

uses
  dfHEngine, TexLoad, uLogger, SysUtils;

var
  {Соответствие TGLConst параметров и свойств класса TdfTexture}
  aTarget: array[Low(TglrTextureTarget)..High(TglrTextureTarget)] of TGLConst =
    (GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_3D);
//     GL_TEXTURE_RECTANGLE,
//     GL_TEXTURE_RECTANGLE_NV,
//     GL_TEXTURE_CUBE_MAP,
//     GL_TEXTURE_CUBE_MAP_POSITIVE_X,
//     GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
//     GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
//     GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
//     GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
//     GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
//     GL_TEXTURE_1D_ARRAY, GL_TEXTURE_2D_ARRAY,
//     GL_TEXTURE_CUBE_MAP_ARRAY
//  );
  aWraps: array[Low(TglrTextureWrap)..High(TglrTextureWrap)] of TGLConst =
    (GL_CLAMP, GL_REPEAT, GL_CLAMP_TO_EDGE, GL_CLAMP_TO_BORDER, GL_MIRRORED_REPEAT);
  aMinFilters: array[Low(TglrTextureMinFilter)..High(TglrTextureMinFilter)] of TGLConst =
    (GL_NEAREST, GL_LINEAR, GL_NEAREST_MIPMAP_NEAREST, GL_NEAREST_MIPMAP_LINEAR,
     GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR_MIPMAP_LINEAR);
  aMagFilters: array[Low(TglrTextureMagFilter)..High(TglrTextureMagFilter)] of TGLConst =
    (GL_NEAREST, GL_LINEAR);
  aTextureMode: array[Low(TglrTextureCombineMode)..High(TglrTextureCombineMode)] of TGLConst =
    (GL_DECAL, GL_MODULATE, GL_BLEND, GL_REPLACE, GL_ADD);


  {DEBUG!!!!!}

  applied: Integer = 0;


{ TdfTexture }

procedure TglrTexture.Bind;
begin
  if not FLoaded then
  begin
    Inc(textureSwitches);
    gl.BindTexture(GL_TEXTURE_2D, 0);
    applied := 0;
  end
  else
    if FTex.Id <> applied then
    begin
      Inc(textureSwitches);
      gl.BindTexture(GL_TEXTURE_2D, FTex.Id);
      applied := FTex.Id;
    end;
  _SetBlendingMode();
  gl.TexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, aTextureMode[FCombineMode]);
end;

constructor TglrTexture.Create;
begin
  inherited;
  FLoaded := False;
//  FTex := 0;
end;

destructor TglrTexture.Destroy;
begin
  if not FLoadedFromAtlas and FLoaded then
  begin
    logWriteMessage('Удаление текстуры ID '+ IntToStr(FTex.Id));
    gl.DeleteTextures(1, @FTex.Id);
  end;
  inherited;
end;

function TglrTexture.GetHeight: Integer;
begin
  Result := FTex.RegionHeight;
end;

function TglrTexture.GetTexBlendingMode: TglrTextureBlendingMode;
begin
  Result := FBlendingMode;
end;

function TglrTexture.GetTexCombineMode: TglrTextureCombineMode;
begin
  Result := FCombineMode;
end;

function TglrTexture.GetTexDesc: TglrTextureDecription;
begin
  Result := FTex;
end;

function TglrTexture.GetTexMagFilter: TglrTextureMagFilter;
begin
  Result := FMagFilter;
end;

function TglrTexture.GetTexMinFilter: TglrTextureMinFilter;
begin
  Result := FMinFilter;
end;

function TglrTexture.GetTexTarget: TglrTextureTarget;
var
  i: TglrTextureTarget;
begin
  for i := Low(aTarget) to High(aTarget) do
    if aTarget[i] = FTex.Target then
    begin
      Result := i;
    end;
end;

function TglrTexture.GetTexWrapR: TglrTextureWrap;
begin
  Result := FWrapR;
end;

function TglrTexture.GetTexWrapS: TglrTextureWrap;
begin
  Result := FWrapS;
end;

function TglrTexture.GetTexWrapT: TglrTextureWrap;
begin
  Result := FWrapT;
end;

function TglrTexture.GetWidth: Integer;
begin
  Result := FTex.RegionWidth;
end;

procedure TglrTexture.Load2D(const aStream: TglrStream; aFormatExtension: String);
var
  Data: Pointer;
  eSize: Integer;
begin
  logWriteMessage('Загрузка текстуры из потока');
  gl.GenTextures(1, @FTex.Id);
  FTex.Target := GL_TEXTURE_2D;
  FTex.X := 0;
  FTex.Y := 0;
  gl.BindTexture(FTex.Target, FTex.Id);

  New(Data);
  Data := TexLoad.LoadTexture(aStream, aFormatExtension, FTex.InternalFormat, FTex.ColorFormat, FTex.DataType, eSize, FTex.Width, FTex.Height); //TexLoad.LoadTexture(aFileName, Format, W, H);
  FTex.FullSize := SizeOfP(Data);
  gl.TexImage2D(GL_TEXTURE_2D, 2, FTex.InternalFormat, FTex.Width, FTex.Height, 0, FTex.ColorFormat, FTex.DataType, Data);

  MinFilter := tmnLinear;
  MagFilter := tmgLinear;
  BlendingMode := tbmOpaque;
  CombineMode := tcmModulate;
  gl.BindTexture(GL_TEXTURE_2D, 0);
  logWriteMessage('Загрузка текстуры завершена. ID = ' + IntToStr(FTex.Id) +
    ' Размер текстуры: ' + IntToStr(FTex.Width) + 'x' + IntToStr(FTex.Height) + '; ' + IntToStr(FTex.FullSize) + ' байт');
  Dispose(Data);

  FLoaded := True;
  FLoadedFromAtlas := False;
end;

procedure TglrTexture.Load2DRegion(const aTex: IglrTexture; aX, aY, aWidth,
  aHeight: Integer);
begin
  FTex := aTex.GetTexDesc();
  FTex.RegionWidth := aWidth;
  FTex.RegionHeight := aHeight;
  FTex.X := aX;
  FTex.Y := aY;
  FLoaded := True;
  BlendingMode := aTex.BlendingMode;
  CombineMode := aTex.CombineMode;
  FLoadedFromAtlas := True;
end;

procedure TglrTexture.Load2D(const aFileName: String);
var
  Data: Pointer;
  eSize: Integer;
//  anisotropy: Single;
begin
  logWriteMessage('Загрузка текстуры ' + aFileName);
  gl.GenTextures(1, @FTex.Id);
  FTex.Target := GL_TEXTURE_2D;
  gl.BindTexture(FTex.Target, FTex.Id);

  New(Data);
  Data := TexLoad.LoadTexture(aFileName, FTex.InternalFormat, FTex.ColorFormat, FTex.DataType, eSize, FTex.Width, FTex.Height); //TexLoad.LoadTexture(aFileName, Format, W, H);
  FTex.FullSize := SizeOfP(Data);
  FTex.X := 0;
  FTex.Y := 0;
  FTex.RegionWidth := FTex.Width;
  FTex.RegionHeight := FTex.Height;
  gl.TexImage2D(GL_TEXTURE_2D, 0, FTex.InternalFormat, FTex.Width, FTex.Height, 0, FTex.ColorFormat, FTex.DataType, Data);

  //Some critical problems with anisotropic. Have to deal with it... later
//  if gl.IsExtensionSupported('GL_EXT_texture_filter_anisotropic') then
//  begin
//    gl.GetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY, @anisotropy);
//    gl.TexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY, 2);
//  end;

  MinFilter := tmnLinear;
  MagFilter := tmgLinear;
  BlendingMode := tbmOpaque;
  CombineMode := tcmModulate;

  gl.BindTexture(GL_TEXTURE_2D, 0);
  logWriteMessage('Загрузка текстуры завершена. ID = ' + IntToStr(FTex.Id) +
    ' Размер текстуры: ' + IntToStr(FTex.Width) + 'x' + IntToStr(FTex.Height) + '; ' + IntToStr(FTex.FullSize) + ' байт');
  Dispose(Data);

  FLoaded := True;
end;

procedure TglrTexture.SetTexBlendingMode(aMode: TglrTextureBlendingMode);
begin
  FBlendingMode := aMode;
end;

procedure TglrTexture.SetTexCombineMode(aMode: TglrTextureCombineMode);
begin
  FCombineMode := aMode;
end;

procedure TglrTexture.SetTexMagFilter(aFilter: TglrTextureMagFilter);
begin
  Assert(FTex.Target <> GL_FALSE, 'Текстура не загружена');
  FMagFilter := aFilter;
  FTex.magFilter := aMagFilters[FMagFilter];
  gl.BindTexture(FTex.Target, FTex.ID);
  gl.TexParameteri(FTex.Target, GL_TEXTURE_MAG_FILTER, FTex.magFilter);
  gl.BindTexture(FTex.Target, 0);
end;

procedure TglrTexture.SetTexMinFilter(aFilter: TglrTextureMinFilter);
begin
  Assert(FTex.Target <> GL_FALSE, 'Текстура не загружена');
  FMinFilter := aFilter;
  FTex.minFilter := aMinFilters[FMinFilter];
  gl.BindTexture(FTex.Target, FTex.ID);
  gl.TexParameteri(FTex.Target, GL_TEXTURE_MIN_FILTER, FTex.minFilter);
  gl.BindTexture(FTex.Target, 0);
end;

procedure TglrTexture.SetTexWrapR(aWrap: TglrTextureWrap);
begin
  Assert(FTex.Target <> GL_FALSE, 'Текстура не загружена');
  FWrapR := aWrap;
  FTex.WrapR := aWraps[FWrapR];
  gl.BindTexture(FTex.Target, FTex.ID);
  gl.TexParameteri(FTex.Target, GL_TEXTURE_WRAP_R, FTex.WrapR);
  gl.BindTexture(FTex.Target, 0);
end;

procedure TglrTexture.SetTexWrapS(aWrap: TglrTextureWrap);
begin
  Assert(FTex.Target <> GL_FALSE, 'Текстура не загружена');
  FWrapS := aWrap;
  FTex.WrapS := aWraps[FWrapS];
  gl.BindTexture(FTex.Target, FTex.ID);
  gl.TexParameteri(FTex.Target, GL_TEXTURE_WRAP_S, FTex.WrapS);
  gl.BindTexture(FTex.Target, 0);
end;

procedure TglrTexture.SetTexWrapT(aWrap: TglrTextureWrap);
begin
  Assert(FTex.Target <> GL_FALSE, 'Текстура не загружена');
  FWrapT := aWrap;
  FTex.WrapT := aWraps[FWrapT];
  gl.BindTexture(FTex.Target, FTex.ID);
  gl.TexParameteri(FTex.Target, GL_TEXTURE_WRAP_T, FTex.WrapT);
  gl.BindTexture(FTex.Target, 0);
end;

procedure TglrTexture.Unbind;
begin
//  gl.BindTexture(GL_TEXTURE_2D, 0);
  gl.Disable(GL_BLEND);
  gl.Disable(GL_ALPHA_TEST);
end;

procedure TglrTexture._SetBlendingMode;
begin
case FBlendingMode of
    tbmOpaque:
      begin
        gl.Disable(GL_BLEND);
        gl.Disable(GL_ALPHA_TEST);
      end;
    tbmTransparency:
      begin
        gl.Enable(GL_BLEND);
        gl.Enable(GL_ALPHA_TEST);
        gl.BlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        gl.AlphaFunc(GL_GREATER, 0);
      end;
    tbmAdditive:
      begin
        gl.Enable(GL_BLEND);
        gl.Enable(GL_ALPHA_TEST);
        gl.BlendFunc(GL_SRC_ALPHA,GL_ONE);
        gl.AlphaFunc(GL_GREATER, 0);
      end;
    tbmAlphaTest50:
      begin
        gl.Disable(GL_BLEND);
        gl.Enable(GL_ALPHA_TEST);
        gl.AlphaFunc(GL_GEQUAL, 0.5);
      end;
    tbmAlphaTest100:
      begin
        gl.Disable(GL_BLEND);
        gl.Enable(GL_ALPHA_TEST);
        gl.AlphaFunc(GL_GEQUAL, 1);
      end;
    tbmModulate:
      begin
        gl.Enable(GL_BLEND);
        gl.Enable(GL_ALPHA_TEST);
        gl.BlendFunc(GL_DST_COLOR,GL_ZERO);
        gl.AlphaFunc(GL_GREATER, 0);
      end;
    tbmCustom1:
    begin
      gl.Enable(GL_BLEND);
      gl.Enable(GL_ALPHA_TEST);
      gl.AlphaFunc(GL_GREATER, 0);
      gl.BlendFunc(GL_DST_ALPHA, GL_ONE);
    end;
  end;
end;

end.

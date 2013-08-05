unit uMaterial;

interface

uses
  dfHRenderer, dfMath;

type
  TglrMaterialOptions = class(TInterfacedObject, IglrMaterialOptions)
  private
    FDifColor: TdfVec4f;
    function GetDif(): TdfVec4f;
    procedure SetDif(const aDif: TdfVec4f);
    function GetPDif(): PdfVec4f;
    procedure SetPDif(const aDif: PdfVec4f);
  protected
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    procedure Apply();
    procedure UnApply();

    property Diffuse: TdfVec4f read GetDif write SetDif;
    property PDiffuse: PdfVec4f read GetPDif write SetPDif;
  end;


  TglrMaterial = class(TInterfacedObject, IglrMaterial)
  private
    FTexture: IglrTexture;
    FShader: IglrShaderProgram;
    FOptions: IglrMaterialOptions;
  protected
    function GetTexture: IglrTexture;
    procedure SetTexture(const aTexture: IglrTexture);
    function GetShader(): IglrShaderProgram;
    procedure SetShader(const aShader: IglrShaderProgram);
    function GetOptions(): IglrMaterialOptions;
    procedure SetOptions(const aOptions: IglrMaterialOptions);
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    property Texture: IglrTexture read GetTexture write SetTexture;
    property ShaderProgram: IglrShaderProgram read GetShader write SetShader;
    property MaterialOptions: IglrMaterialOptions read GetOptions write SetOptions;

    procedure Apply();
    procedure Unapply();
  end;

implementation

uses
  ExportFunc,
  dfHGL;

{ TdfMaterial }

procedure TglrMaterial.Apply;
begin
  if Assigned(FTexture) then
    FTexture.Bind();
  if Assigned(FOptions) then
    FOptions.Apply();
  if Assigned(FShader) then
    FShader.Use();
  //*
end;

constructor TglrMaterial.Create;
begin
  inherited;
  FOptions := TglrMaterialOptions.Create;
  FTexture := GetObjectFactory().NewTexture();
end;

destructor TglrMaterial.Destroy;
begin
  FOptions := nil;
  FTexture := nil;
  inherited;
end;

function TglrMaterial.GetOptions: IglrMaterialOptions;
begin
  Result := FOptions;
end;

function TglrMaterial.GetShader: IglrShaderProgram;
begin
  Result := FShader;
end;

function TglrMaterial.GetTexture: IglrTexture;
begin
  Result := FTexture;
end;

procedure TglrMaterial.SetOptions(const aOptions: IglrMaterialOptions);
begin
  FOptions :=  aOptions;
end;

procedure TglrMaterial.SetShader(const aShader: IglrShaderProgram);
begin
  FShader := aShader;
end;

procedure TglrMaterial.SetTexture(const aTexture: IglrTexture);
begin
  FTexture := aTexture;
end;

procedure TglrMaterial.Unapply;
begin
  if Assigned(FTexture) then
    FTexture.Unbind;
  if Assigned(FOptions) then
    FOptions.Unapply();
  if Assigned(FShader) then
    FShader.Unuse();
end;

{ TdfMaterialOptions }

procedure TglrMaterialOptions.Apply;
begin
  gl.Color4fv(FDifColor);
end;

constructor TglrMaterialOptions.Create;
begin
  inherited;
  FDifColor := dfVec4f(1, 1, 1, 1);
end;

destructor TglrMaterialOptions.Destroy;
begin

  inherited;
end;

function TglrMaterialOptions.GetDif: TdfVec4f;
begin
  Result := FDifColor;
end;

function TglrMaterialOptions.GetPDif: PdfVec4f;
begin
  Result := @FDifColor;
end;



procedure TglrMaterialOptions.SetDif(const aDif: TdfVec4f);
begin
  FDifColor := aDif;
end;

procedure TglrMaterialOptions.SetPDif(const aDif: PdfVec4f);
begin
  FDifColor := aDif^;
end;

procedure TglrMaterialOptions.UnApply;
begin
  //* ???
end;

end.

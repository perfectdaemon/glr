unit uMaterial;

interface

uses
  glr, glrMath, uBaseInterfaceObject;

type
  TglrMaterial = class(TglrInterfacedObject, IglrMaterial)
  protected
    FTexture: IglrTexture;
    FShader: IglrShaderProgram;
    FDifColor: TdfVec4f;
    function GetDif(): TdfVec4f;
    procedure SetDif(const aDif: TdfVec4f);
    function GetPDif(): PdfVec4f;
    procedure SetPDif(const aDif: PdfVec4f);
    function GetTexture: IglrTexture;
    procedure SetTexture(const aTexture: IglrTexture);
    function GetShader(): IglrShaderProgram;
    procedure SetShader(const aShader: IglrShaderProgram);
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    property Texture: IglrTexture read GetTexture write SetTexture;
    property ShaderProgram: IglrShaderProgram read GetShader write SetShader;

    property Diffuse: TdfVec4f read GetDif write SetDif;
    property PDiffuse: PdfVec4f read GetPDif write SetPDif;

    procedure Apply();
    procedure Unapply();
  end;

implementation

uses
  ExportFunc,
  ogl;

{ TdfMaterial }

procedure TglrMaterial.Apply;
begin
  if Assigned(FTexture) then
    FTexture.Bind();

  gl.Color4fv(FDifColor);

  if Assigned(FShader) then
    FShader.Use();
  //*
end;

constructor TglrMaterial.Create;
begin
  inherited;
  FDifColor := dfVec4f(1, 1, 1, 1);
  FTexture := GetObjectFactory().NewTexture();
end;

destructor TglrMaterial.Destroy;
begin
  FTexture := nil;
  inherited;
end;

function TglrMaterial.GetShader: IglrShaderProgram;
begin
  Result := FShader;
end;

function TglrMaterial.GetTexture: IglrTexture;
begin
  Result := FTexture;
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

  if Assigned(FShader) then
    FShader.Unuse();
end;

function TglrMaterial.GetDif(): TdfVec4f;
begin
  Result := FDifColor;
end;

function TglrMaterial.GetPDif(): PdfVec4f;
begin
  Result := @FDifColor;
end;

procedure TglrMaterial.SetDif(const aDif: TdfVec4f);
begin
  FDifColor := aDif;
end;

procedure TglrMaterial.SetPDif(const aDif: PdfVec4f);
begin
  FDifColor := aDif^;
end;

end.

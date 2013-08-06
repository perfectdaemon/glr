unit uShader;

interface

uses
  Classes,
  glr, glrMath, ogl;

type

  TglrShader = class
  private
    sh: LongWord;
    typ: TGLConst;
  public
    ShaderText: TStringList;
    constructor Create(_type: TGLConst);
    destructor Destroy(); override;

    procedure LoadFromFile(FileName: PAnsiChar);

  end;

  TglrShaderProgram = class
  private
    vs, fs: TglrShader;
    prog: Integer;
  public
    constructor Create();
    destructor Destroy; override;

    procedure AttachVertexShader(shader: TglrShader);
    procedure AttachFragmentShader(shader: TglrShader);

    procedure Link();

    procedure Use();
    procedure UseNull();

    function GetUniformLocation(const name: String): Integer;

    procedure SetUniforms(const name: String; const value: single;    count: Integer = 1);overload;
    procedure SetUniforms(const name: String; const value: TdfVec2f; count: Integer = 1);overload;
    procedure SetUniforms(const name: String; const value: TdfVec3f; count: Integer = 1);overload;
    procedure SetUniforms(const name: String; const value: TdfVec4f; count: Integer = 1);overload;
    procedure SetUniforms(const name: String; const value: integer;   count: Integer = 1);overload;

    //Впоследствии могут пригодиться

//    Procedure SetUniforms(const name : String; const value: TdfVec2i; count: Integer=1);overload;
//    Procedure SetUniforms(const name : String; const value: TdfVec3i; count: Integer=1);overload;
//    Procedure SetUniforms(const name : String; const value: TdfVec4i; count: Integer=1);overload;
//    Procedure SetUniforms(const name : String; const value: TdfMat2f; count: Integer=1; transpose: boolean=false);overload;
//    Procedure SetUniforms(const name : String; const value: TdfMat3f; count: Integer=1; transpose: boolean=false);overload;
    procedure SetUniforms(const name: String; const value: TdfMat4f; count: Integer = 1; transpose: Boolean = False);overload;

  end;

implementation

uses
  SysUtils,
  uLogger;

//var
//  slog: Integer;

constructor TglrShader.Create(_type: TGLConst);
begin
  inherited Create;
  ShaderText := TStringList.Create();
  typ := _type;
  sh := gl.CreateShader(typ);
end;

destructor TglrShader.Destroy;
var
  i: Integer;
begin
  gl.DeleteShader(sh);
  for i := 0 to ShaderText.Count - 1 do
    ShaderText[i] := '';
  inherited;
end;

procedure TglrShader.LoadFromFile(FileName: PAnsiChar);
var
  v, l: Integer;
  pLog: PAnsiChar;
  ptr: PAnsiChar;
  tmp: String;
begin
  case typ of
    GL_FRAGMENT_SHADER: tmp := 'фрагментного';
    GL_VERTEX_SHADER:   tmp := 'вершинного';
    GL_GEOMETRY_SHADER: tmp := 'геометрического';
  end;

  logWriteMessage('Загрузка ' + tmp + ' шейдера (ID ' + IntToStr(sh) + ') из файла ' + FileName + '...');
  ShaderText.LoadFromFile(FileName, TEncoding.ASCII);
  logWriteMessage('Загрузка завершена. Строк кода: ' + IntToStr(ShaderText.Count));
  ptr := PAnsiChar(AnsiString(ShaderText.Text));
  gl.ShaderSource(sh, 1, @ptr, nil);
  ShaderText.Free;
  logWriteMessage('Компиляция шейдера (ID ' + IntToStr(sh) + ')...');
  gl.CompileShader(sh);
  gl.GetShaderiv(sh, GL_COMPILE_STATUS, @v);
  if v = Ord(GL_FALSE) then
  begin
    gl.GetShaderiv(sh, GL_INFO_LOG_LENGTH, @v);
    getmem(pLog, v);
    gl.GetShaderInfoLog(sh, v, l, pLog);
    logWriteError('Компиляция шейдера завершилась неудачей. Подробный лог: ');
    logWriteError(pLog, False, True, True);
    FreeMem(pLog, v);
  end
  else
    logWriteMessage('Компиляция шейдера успешно завершена');
end;





constructor TglrShaderProgram.Create;
begin
  inherited;
  prog := gl.CreateProgram();
  logWriteMessage('Создание shader program (ID' + IntToStr(prog) + ')');
end;

destructor TglrShaderProgram.Destroy;
begin
  logWriteMessage('Удаление shader program (ID ' + IntToStr(prog) + ')');
  gl.DeleteProgram(prog);
  vs.Free;
  fs.Free;
  inherited Destroy;
end;

procedure TglrShaderProgram.AttachVertexShader(shader: TglrShader);
begin
  gl.AttachShader(prog, shader.sh);
  vs := shader;
  logWriteMessage('Присоединяем вершинный шейдер (ID ' + IntToStr(shader.sh) + ') к shader program ' + IntToStr(prog));
end;

procedure TglrShaderProgram.AttachFragmentShader(shader: TglrShader);
begin
  gl.AttachShader(prog, shader.sh);
  fs := shader;
  logWriteMessage('Присоединяем фрагментный шейдер (ID ' + IntToStr(shader.sh) + ') к shader program ' + IntToStr(prog));
end;

procedure TglrShaderProgram.Link;
var
  v, l: Integer;
  pLog: PAnsiChar;
begin
  logWriteMessage('Линковка шейдеров shader program (ID ' + IntToStr(prog) + ')...');
  gl.LinkProgram(prog);
  gl.GetProgramiv(prog, GL_LINK_STATUS, @v);
  if v = Ord(GL_FALSE) then
  begin
    gl.GetProgramiv(prog, GL_INFO_LOG_LENGTH, @v);
    getmem(pLog, v);
    gl.GetProgramInfoLog(prog, v, l, pLog);
    logWriteError('Линковка шейдеров завершилась неудачей. Подробный лог: ');
    logWriteError(pLog, False, True, True);
    FreeMem(pLog, v);
  end
  else
    logWriteMessage('Линковка шейдеров успешно завершена');
end;

procedure TglrShaderProgram.Use();
begin
  gl.UseProgram(prog);
end;

procedure TglrShaderProgram.UseNull();
begin
  gl.UseProgram(0);
end;

function TglrShaderProgram.GetUniformLocation(const name: String): Integer;
begin
  Result := gl.GetUniformLocation(prog, PAnsiChar(AnsiString(name)));
  if Result < 0 then
  begin
    logWriteWarning('Юниформа с именем ' + name + ' в shader program ' + IntToStr(prog) + ' не найдена');
  end;
end;

procedure TglrShaderProgram.SetUniforms(const name: String; const value: single; count: Integer = 1);
begin
  gl.Uniform1fv(GetUniformLocation(name), count, @value);
end;

procedure TglrShaderProgram.SetUniforms(const name: String; const value: TdfVec2f; count: Integer = 1);
begin
  gl.Uniform2fv(GetUniformLocation(name), count, @value);
end;

procedure TglrShaderProgram.SetUniforms(const name: String; const value: TdfVec3f; count: Integer = 1);
begin
  gl.Uniform3fv(GetUniformLocation(name), count, @value);
end;

procedure TglrShaderProgram.SetUniforms(const name: String; const value: TdfVec4f; count: Integer = 1);
begin
  gl.Uniform4fv(GetUniformLocation(name), count, @value);
end;

procedure TglrShaderProgram.SetUniforms(const name: String; const value: integer; count: Integer = 1);
begin
  gl.Uniform1iv(GetUniformLocation(name), count, @value);
end;

procedure TglrShaderProgram.SetUniforms(const name: String; const value: TdfMat4f; count: Integer = 1; transpose: boolean=false);
begin
  gl.UniformMatrix4fv(GetUniformLocation(name), count, transpose, @value);
end;

end.

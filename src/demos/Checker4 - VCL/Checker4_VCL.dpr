program Checker4_VCL;

uses
  Forms,
  uMain in 'uMain.pas' {Form1},
  dfHRenderer in '..\..\headers\dfHRenderer.pas',
  dfHEngine in '..\..\common\dfHEngine.pas',
  dfMath in '..\..\common\dfMath.pas',
  dfHUtility in '..\..\headers\dfHUtility.pas',
  dfHGL in '..\..\common\dfHGL.pas',
  uEarthTools in 'uEarthTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

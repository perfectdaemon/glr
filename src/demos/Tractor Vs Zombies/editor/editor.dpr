program editor;

uses
  Forms,
  uMain in 'uMain.pas' {Form1},
  uEarthTools in 'uEarthTools.pas',
  dfHGL in '..\..\..\common\dfHGL.pas',
  dfMath in '..\..\..\common\dfMath.pas',
  dfHRenderer in '..\..\..\headers\dfHRenderer.pas',
  dfHUtility in '..\..\..\headers\dfHUtility.pas',
  dfHEngine in '..\..\..\common\dfHEngine.pas',
  uLevel_SaveLoad in '..\uLevel_SaveLoad.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

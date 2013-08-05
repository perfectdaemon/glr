unit uSettings_SaveLoad;

interface


type
  TpdSetting = (stMusicVolume, stSoundVolume);

const
  SETTINGNAMES: array[TpdSetting] of String =
    ('musicvol', 'soundvol');

type
  TpdSettingsFile = class
  private
    FSettings: array[TpdSetting] of String;
    function GetSetting(aIndex: TpdSetting): String;
    procedure SetSetting(aIndex: TpdSetting; aValue: String);
  public
    property Settings[Index: TpdSetting]: String read GetSetting write SetSetting;
    class function Initialize(const aFileName: String): TpdSettingsFile;

    procedure SaveToFile(const aFileName: String);
  end;

implementation

uses
  Classes;

{ TpdSettingsFile }

function TpdSettingsFile.GetSetting(aIndex: TpdSetting): String;
begin
  Result := FSettings[aIndex];
end;

class function TpdSettingsFile.Initialize(
  const aFileName: String): TpdSettingsFile;
var
  f: TextFile;
  i: TpdSetting;
  tmpStr: String;
begin
  Result := TpdSettingsFile.Create();
  with Result do
  begin
    AssignFile(f, aFileName);
    Reset(f);
    for i := Low(FSettings) to High(FSettings) do
    begin
      Readln(f, tmpStr);
      FSettings[i] := Copy(tmpStr, 0, Pos(';', tmpStr) - 1);
      if Eof(f) then
        Break;
    end;

    CloseFile(f);
  end;
end;

procedure TpdSettingsFile.SaveToFile(const aFileName: String);
var
  f: TextFile;
  i: TpdSetting;
begin
  AssignFile(f, aFileName);
  Rewrite(f);
  for i := Low(FSettings) to High(FSettings) do
    WriteLn(f, FSettings[i] + ';'#9#9 + SETTINGNAMES[i]);
  CloseFile(f);
end;

procedure TpdSettingsFile.SetSetting(aIndex: TpdSetting; aValue: String);
begin
  FSettings[aIndex] := aValue;
end;

end.

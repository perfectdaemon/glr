{
  TODO: слезть с Indy на WinInet
}

unit uGameSync;

interface

uses
  Classes, WinInet;

type
  TpdCustomGameSync = class
  protected
    hInt, hCon, hReq: HINTERNET;
    InternetAgent: AnsiString;
    Port: Word;
  public
    function IsServerAvailable(aServerUrl: AnsiString): Boolean; virtual;
    function GetInfo(aServerUrl, aObjectUrl: AnsiString): AnsiString; virtual;
    function SendInfo(aServerUrl, aObjectUrl: AnsiString; aParamStr: AnsiString): Boolean; virtual;

    constructor Create(); virtual;
    destructor Destroy(); override;
  end;

  TpdScoreTableRow = record
    playerName: AnsiString;
    gameVersion: AnsiString;
    dt: TDateTime;
    score: Integer;
    maxPower: Integer;
  end;

const
  ROWS_COUNT = 5;

type
  TpdScoreTable = array of TpdScoreTableRow;

  TpdRagdollSportsGameSync = class (TpdCustomGameSync)
  public
    function IsServerAvailable(): Boolean; overload;
    function GetScoreTable(const aLimit: Integer = 10): TpdScoreTable;
    function AddScore(aPlayerName: AnsiString; aScore, aMaxPower: Integer): Boolean;

    constructor Create(); override;
  end;

implementation

uses
  uGlobal,
  SysUtils;

{ TpdCustomGameSync }

constructor TpdCustomGameSync.Create;
begin
  InternetAgent := 'Self-made browser :) ';
  Port := 80;
end;

destructor TpdCustomGameSync.Destroy;
begin
  inherited;
end;

function TpdCustomGameSync.GetInfo(aServerUrl, aObjectUrl: AnsiString): AnsiString;
var
  header: AnsiString;
  bytesRead: Cardinal;
  i: Integer;
  buffer: array[0..1023] of AnsiChar;
begin
  try
    hInt := InternetOpenA(PAnsiChar(InternetAgent),
      INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
    hCon := InternetConnectA(hInt, PAnsiChar(aServerUrl),
      Port, nil, nil, INTERNET_SERVICE_HTTP, 0, 1);
    hReq := HttpOpenRequestA(hCon, 'GET', PAnsiChar(aObjectUrl), nil, nil, nil, INTERNET_SERVICE_HTTP or INTERNET_FLAG_NO_CACHE_WRITE, 1);
    header := 'Host: ' + aServerUrl + #13#10 +
      'User-Agent: Custom program 1.0'  + #13#10 +
      'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' + #13#10 +
      'Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4' + #13#10 +
      'Accept-Charset: windows-1251,utf-16;q=0.7,*;q=0.3' + #13#10 + #13#10#13#10;
//      'Keep-Alive: 300' + #13#10 +
//      'Content-Type: application/x-www-form-urlencoded' + #13#10 +

    HttpAddRequestHeadersA(hReq, PAnsiChar(Header), Length(Header), HTTP_ADDREQ_FLAG_ADD);
    if HttpSendRequestA(hReq, nil, 0, nil, 0) then
      while InternetReadFile(hReq, @Buffer, SizeOf(Buffer), BytesRead) do
      begin
        if (BytesRead = 0) then
          break;
        i := Length(Result);
        SetLength(Result, i + LongInt(BytesRead));
        Move(Buffer, Result[i + 1], BytesRead);
      end;

//    InternetReadFile(hReq, @buffer, 1024, bytesRead);
//    SetLength(answer, bytesRead);
//    Move(buffer, answer[1], LongInt(bytesRead));

    InternetCloseHandle(hReq);
    InternetCloseHandle(hCon);
    InternetCloseHandle(hInt);
  except
    Result := '';
  end;
end;

function TpdCustomGameSync.IsServerAvailable(aServerUrl: AnsiString): Boolean;
begin
  try
    Result := True;
    hInt := InternetOpenA(PAnsiChar(InternetAgent),
      INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
    Result := Result and (hInt <> nil);
    hCon := InternetConnectA(hInt, PAnsiChar(aServerUrl),
      Port, nil, nil, INTERNET_SERVICE_HTTP, 0, 1);
    Result := Result and (hCon <> nil);
    hReq := HttpOpenRequestA(hCon, 'HEAD', '', nil, nil, nil, INTERNET_FLAG_KEEP_CONNECTION, 1);
    Result := Result and (hReq <> nil);
    Result := Result and HttpSendRequestA(hReq, nil, 0, nil, 0);

    InternetCloseHandle(hReq);
    InternetCloseHandle(hCon);
    InternetCloseHandle(hInt);
  except
    Result := False;
  end;
end;

function MyEncodeUrl(Source: Ansistring): Ansistring;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Source) do
   if not (Source[i] in ['A'..'Z','a'..'z','0','1'..'9','-','_','~','.', '=', '&']) then
     Result := Result + '%' + IntToHex(Ord(Source[i]), 2)
   else
    Result := Result + Source[i];
end;

function TpdCustomGameSync.SendInfo(aServerUrl, aObjectUrl: AnsiString; aParamStr: AnsiString): Boolean;
var
  par, header: AnsiString;
  answer: AnsiString;
  buffer: array[0..1023] of AnsiChar;
  bytesRead: Cardinal;
begin
  par := MyEncodeUrl(aParamStr);
  try
    hInt := InternetOpenA(PAnsiChar(InternetAgent),
      INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
    if hInt = nil then
      Exit(False);
    hCon := InternetConnectA(hInt, PAnsiChar(aServerUrl),
      Port, nil, nil, INTERNET_SERVICE_HTTP, 0, 1);
    if hCon = nil then
      Exit(False);
    hReq := HttpOpenRequestA(hCon, 'POST', PAnsiChar(aObjectUrl), nil, nil, nil, INTERNET_SERVICE_HTTP or INTERNET_FLAG_NO_CACHE_WRITE, 1);
    if hReq = nil then
      Exit(False);
    header := 'Host: ' + aServerUrl + #13#10 +
      'User-Agent: Custom program 1.0'  + #13#10 +
      'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' + #13#10 +
      'Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4' + #13#10 +
      'Accept-Charset: windows-1251,utf-16;q=0.7,*;q=0.3' + #13#10 +
      'Content-Type: application/x-www-form-urlencoded' + #13#10#13#10;
    HttpAddRequestHeadersA(hReq, PAnsiChar(Header), Length(Header), HTTP_ADDREQ_FLAG_ADD);
    Result := HttpSendRequestA(hReq, nil, 0, PAnsiChar(par), Length(par));
    if not Result then
      Exit();

    InternetReadFile(hReq, @buffer, 1024, bytesRead);
    SetLength(answer, bytesRead);
    Move(buffer, answer[1], LongInt(bytesRead));

    Result := Result and (answer = 'Success');

    InternetCloseHandle(hReq);
    InternetCloseHandle(hCon);
    InternetCloseHandle(hInt);
  except
    Result := False;
  end;
end;

{ TpdRagdollSportsGameSync }

const
  RS_SITE = 'perfect-daemon.ru';
  RS_PORT = 80;
  RS_GAMESYNC_URL = 'gamesync.php?type=raw&game=rs&';
  RS_GETSCORE_URL = 'action=getscore&limit=';
  RS_ADDSCORE_URL = 'action=addscore';
  RS_PARAM_PLAYERNAME = 'playername';
  RS_PARAM_GAMEVERSION = 'version';
  RS_PARAM_MAXPOWER = 'maxpower';
  RS_PARAM_SCORE = 'score';

  RS_VALUE_SCORELIMIT = 10;
  RS_VALUE_GAMEVERSION = uGlobal.GAMEVERSION;

function TpdRagdollSportsGameSync.AddScore(aPlayerName: AnsiString;
  aScore, aMaxPower: Integer): Boolean;
var
  params: AnsiString;
begin
  params := RS_PARAM_PLAYERNAME + '=' + aPlayerName + '&' +
    RS_PARAM_GAMEVERSION + '=' + RS_VALUE_GAMEVERSION + '&' +
    RS_PARAM_SCORE + '=' + IntToStr(aScore) + '&' +
    RS_PARAM_MAXPOWER + '=' + IntToStr(aMaxPower);
  Result := SendInfo(RS_SITE, RS_GAMESYNC_URL + RS_ADDSCORE_URL, params);
end;

constructor TpdRagdollSportsGameSync.Create;
begin
  inherited;
  Port := RS_PORT;
end;

function TpdRagdollSportsGameSync.GetScoreTable(const aLimit: Integer = 10): TpdScoreTable;
var
  aText: TStringList;
  i, e: Integer;
begin
  aText := TStringList.Create();
  aText.Text := GetInfo(RS_SITE, RS_GAMESYNC_URL + RS_GETSCORE_URL + IntToStr(RS_VALUE_SCORELIMIT));

  if aText.Count < ROWS_COUNT then
  begin
    aText.Free();
    Exit();
  end;

  //playerName
  //version
  //dt
  //score
  //maxpower
  SetLength(Result, aText.Count div ROWS_COUNT);
  for i := 0 to Length(Result) - 1  do
    with Result[i] do
    begin
      playerName := aText[i * ROWS_COUNT];
      gameVersion := aText[i * ROWS_COUNT + 1];
      //Пропускаем dt
      Val(aText[i * ROWS_COUNT + 3], score, e);
      Val(aText[i * ROWS_COUNT + 4], maxPower, e);
    end;
  aText.Free();
end;

function TpdRagdollSportsGameSync.IsServerAvailable: Boolean;
begin
  Result := inherited IsServerAvailable(RS_SITE);
end;

end.

unit uSound;

interface

uses
  Windows, Bass;

type
  {Класс для проигрывания музыки}
  TpdSoundSystem = class
  private
    FEnabled: Boolean;
    FMusic: HSTREAM;
    procedure SetEnabled(const aEnabled: Boolean);
  public
    constructor Create(aHandle: THandle); virtual;
    destructor Destroy(); override;

    function LoadMusic(const aFile: String): HSTREAM;
    procedure PlayMusic(const aMusic: HSTREAM);
    procedure PauseMusic();

    property Enabled: Boolean read FEnabled write SetEnabled;
  end;

implementation

{ TpdSoundSystem }

constructor TpdSoundSystem.Create(aHandle: THandle);
begin
  inherited Create();
	if (HIWORD(BASS_GetVersion) = BASSVERSION) then
	begin
  	BASS_Init(-1, 44100, 0, aHandle, nil);
    BASS_SetConfig(BASS_CONFIG_BUFFER, 4000); //Размер буфера (максимум 5000)
	end;

  FEnabled := True;
  FMusic := 0;
end;

destructor TpdSoundSystem.Destroy;
begin
  BASS_StreamFree(FMusic);
	BASS_Free();
  inherited;
end;

function TpdSoundSystem.LoadMusic(const aFile: String): HSTREAM;
begin
  Result := BASS_StreamCreateFile(False, PChar(aFile), 0, 0, BASS_SAMPLE_LOOP{$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
end;

procedure TpdSoundSystem.PlayMusic(const aMusic: HSTREAM);
begin
  if aMusic <> FMusic then
  begin
    BASS_ChannelStop(FMusic);
    FMusic := aMusic;
    BASS_ChannelPlay(FMusic, True);
  end;
end;

procedure TpdSoundSystem.SetEnabled(const aEnabled: Boolean);
begin
  if FEnabled <> aEnabled then
  begin
    FEnabled := aEnabled;
    if FEnabled then
    begin
      BASS_Start();
      if BASS_ChannelIsActive(FMusic) <> BASS_ACTIVE_PLAYING then //исправляет баг #12
        BASS_ChannelPlay(FMusic, True);
//      PlayMusic(FMusic);
    end
    else
    begin
      BASS_Pause();
//      PauseMusic();
    end;
  end;
end;

procedure TpdSoundSystem.PauseMusic;
begin
  BASS_ChannelPause(FMusic);
end;

end.

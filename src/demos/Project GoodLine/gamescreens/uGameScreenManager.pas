unit uGameScreenManager;

interface

uses
  uGameScreen;

const
  C_TIME_TO_QUIT = 0.1;

type
  {Наследник TpdAbstractGameScreenManager, реализующий функционал конкретной игры}
  TpdGSManager = class(TpdAbstractGSManager)
  private
    FCurrent, FTo: TpdGameScreen;
    FAction: TpdNotifyAction;

    //Таймер для выхода
    FQuitTimer: Double;
  public
    procedure Add(aScreen: TpdGameScreen); override;
    procedure Update(const dt: Double); override;
    procedure Notify(ToScreen: TpdGameScreen; Action: TpdNotifyAction); override;

    property Current: TpdGameScreen read FCurrent write FCurrent;
  end;

implementation

{ TpdGSManager }

procedure TpdGSManager.Add(aScreen: TpdGameScreen);
begin
  inherited;
  aScreen.OnNotify := Notify;
end;

procedure TpdGSManager.Notify(ToScreen: TpdGameScreen;
  Action: TpdNotifyAction);
begin
  inherited;
  FTo := ToScreen;
  FAction := Action;

  case Action of
    naSwitchTo:
    begin
      if Assigned(FCurrent) then
        FCurrent.Status := gssFadeOut;
//      else
//      begin
//        FTo.Load();
//        FTo.Status := gssFadeIn;
//      end;
    end;
    naSwitchToQ: ;
    naPreload: ToScreen.Load();
    naQuitGame: FQuitTimer := C_TIME_TO_QUIT;
    naShowModal: ;
  end;
end;

procedure TpdGSManager.Update(const dt: Double);
begin
  inherited;

  if Assigned(FTo) then
    case FAction of
      naNone: Exit;

      naSwitchTo:
      begin
        if Assigned(FCurrent) then
        begin
          if (FCurrent.Status = gssFadeOutComplete) or
             (FCurrent.Status = gssNone) then
          begin
            FCurrent.Unload;
            FCurrent := nil;
          end;
        end
        else
        begin
          if FTo.Status = gssPaused then
            FTo.Status := gssReady
          else
          begin
            FTo.Load();
            FTo.Status := gssFadeIn;
          end;
          FCurrent := FTo;
          FTo := nil;
        end;
      end;

      naSwitchToQ:
      begin
        FCurrent.Status := gssPaused;
        FCurrent.Unload;
        FTo.Load;
        FTo.Status := gssReady;
        FCurrent := FTo;
        FTo := nil;
      end;

      naPreload: Exit;


      //Показываем Subject поверх текущей ActiveScene
      naShowModal:
      begin
        FCurrent.Status := gssPaused;
        FTo.Load();
        FTo.Status := gssFadeIn;
        FCurrent := FTo;
        FTo := nil;
      end;
    end;

  if FAction = naQuitGame then
  begin
    FQuitTimer := FQuitTimer - dt;
    if FQuitTimer < 0 then
      FQuit := True;
  end;
end;

end.

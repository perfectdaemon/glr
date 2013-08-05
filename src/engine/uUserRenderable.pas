unit uUserRenderable;

interface

uses
  dfHRenderer,

  uRenderable;

type
  TglrUserRenderable = class(TglrRenderable, IglrUserRenderable)
  private
    FUserRender: TglrUserRenderableCallback;
  protected
    function GetUserCallback: TglrUserRenderableCallback;
    procedure SetUserCallback(urc: TglrUserRenderableCallback);
  public
    property OnRender: TglrUserRenderableCallback read GetUserCallback write SetUserCallback;

    procedure DoRender(); override;
  end;

implementation

uses
  Windows, uRenderer;

{ TdfUserRenderable }

procedure TglrUserRenderable.DoRender;
begin
  inherited;
  if Assigned(FUserRender) then
  begin
//    wglMakeCurrent(0, 0);
    FUserRender();
//    wglMakeCurrent(TheRenderer.DC, TheRenderer.RC);
  end;
end;

function TglrUserRenderable.GetUserCallback: TglrUserRenderableCallback;
begin
  Result := FUserRender;
end;

procedure TglrUserRenderable.SetUserCallback(urc: TglrUserRenderableCallback);
begin
  FUserRender := urc;
end;

end.

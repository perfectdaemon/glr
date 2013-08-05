program project1;

{$mode objfpc}{$H+}

//uses
//  {$IFDEF UNIX}{$IFDEF UseCThreads}
//  cthreads,
//  {$ENDIF}{$ENDIF}
//  Classes;

uses dfHEngine, dfHRenderer, dfHGL, dfMath, SysUtils;

var
  R: IdfRenderer;
  dx, dy: Integer;

  procedure OnMouseDown(X, Y: Integer; MouseButton: TdfMouseButton; Shift: TdfMouseShiftState);
  begin
    dx := x;
    dy := y;
    R.WindowCaption := WideString('Клик: ' + IntToStr(x) + ' : ' + IntToStr(y));
  end;

  procedure OnMouseMove(X, Y: Integer; Shift: TdfMouseShiftState);
  begin
    if Shift = [] then
      R.WindowCaption := UnicodeString('Мышь двигается: ' + IntToStr(x) + ' : ' + IntToStr(y))
    else if ssLeft in Shift then
    begin
      R.WindowCaption := UnicodeString('Мышь двигается: ' + IntToStr(x) + ' : ' + IntToStr(y) + ' с зажатой левой кнопкой');
      with R.Camera do
      begin
        Rotate(deg2rad*(x - dx), Up);
        Rotate(deg2rad*(y - dy), Left);
      end;
      dx := x;
      dy := y;
    end;
  end;

  procedure OnUpdate(const dt: Double);
  begin
    if R.Input.IsKeyDown(27) then
      R.Stop();
  end;


begin
  LoadRendererLib();

  R := dfCreateRenderer();
  R.Init('settings.txt');
  R.OnMouseDown := @OnMouseDown;
  R.OnMouseMove := @OnMouseMove;
  R.OnUpdate := @OnUpdate;

  R.Start();
  R.DeInit();
  R := nil;

  UnLoadRendererLib();
end.


unit ExportFunc;

interface

uses
  glr;

  function CreateRenderer(): IglrRenderer; stdcall;
  function DestroyRenderer(): Integer; stdcall;

  function GetObjectFactory(): IglrObjectFactory; stdcall;

implementation

uses
  uRenderer, uNode, uUserRenderable,
  uHudSprite, uTexture, uMaterial, uFont, uText,
  uGUIButton, uGUITextButton, uGUICheckbox, uGUITextBox, uGUISlider,
  u2DScene,
  uFactory;

function CreateRenderer(): IglrRenderer;
begin
  if not Assigned(TheRenderer) then
  begin
    TheRenderer := TglrRenderer.Create();
    Result := TheRenderer;
  end
  else
    Result := TheRenderer;
end;

function DestroyRenderer(): Integer;
begin
//  TheRenderer.Free;
//  Exit(0);
end;

function GetObjectFactory(): IglrObjectFactory;
begin
  if not Assigned(uFactory.MainFactory) then
    MainFactory := TglrObjectFactory.Create();
  Result := MainFactory;
end;

end.

unit ExportFunc;

interface

uses
  SysUtils,
  glr;

  function GetRenderer(): IglrRenderer; stdcall;
  function GetObjectFactory(): IglrObjectFactory; stdcall;

implementation

uses
  uRenderer, uNode, uUserRenderable,
  uHudSprite, uTexture, uMaterial, uFont, uText,
  uGUIButton, uGUITextButton, uGUICheckbox, uGUITextBox, uGUISlider,
  u2DScene,
  uFactory;

function GetRenderer(): IglrRenderer;
begin
//  if not Assigned(TheRenderer) then
//  begin
//    TheRenderer := TglrRenderer.Create();
//    Result := TheRenderer;
//  end
//  else
  Result := TheRenderer;// as IglrRenderer;
end;

function GetObjectFactory(): IglrObjectFactory;
begin
//  if not Assigned(uFactory.MainFactory) then
//    MainFactory := TglrObjectFactory.Create();
  Result := MainFactory;
end;

end.

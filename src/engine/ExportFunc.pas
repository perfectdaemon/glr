unit ExportFunc;

interface

uses
  dfHRenderer;

  function CreateRenderer(): IglrRenderer; stdcall;
  function DestroyRenderer(): Integer; stdcall;

  function GetObjectFactory(): IglrObjectFactory; stdcall;

//  function CreateNode(aParent: IglrNode): IglrNode; stdcall;
//  function CreateUserRender(): IglrUserRenderable; stdcall;
//  function CreateHUDSprite(): IglrSprite; stdcall;
//  function CreateMaterial: IglrMaterial; stdcall;
//  function CreateTexture(): IglrTexture; stdcall;
//  function CreateFont(): IglrFont; stdcall;
//  function CreateText(): IglrText; stdcall;
//
//  function CreateGUIButton(): IglrGUIButton; stdcall;
//  function CreateGUITextButton(): IglrGUITextButton; stdcall;
//  function CreateGUICheckBox(): IglrGUICheckBox; stdcall;
//  function CreateGUITextBox(): IglrGUITextBox; stdcall;
//  function CreateGUISlider(): IglrGUISlider; stdcall;
//
//  function Create2DScene(): Iglr2DScene; stdcall;

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
{

function CreateNode(aParent: IglrNode): IglrNode;
begin
  if aParent = nil then
    Result := TglrNode.Create
  else
    Result := aParent.AddNewChild();
end;

function CreateUserRender(): IglrUserRenderable;
begin
  Result := TglrUserRenderable.Create();
end;

function CreateHUDSprite(): IglrSprite;
begin
  Result := TglrHUDSprite.Create();
end;

function CreateMaterial(): IglrMaterial;
begin
  Result := TglrMaterial.Create();
end;

function CreateTexture(): IglrTexture;
begin
  Result := TglrTexture.Create();
end;

function CreateFont(): IglrFont;
begin
  Result := TglrFont.Create();
end;

function CreateText(): IglrText;
begin
  Result := TglrText.Create();
end;

function CreateGUIButton(): IglrGUIButton;
begin
  Result := TglrGUIButton.Create();
end;

function CreateGUITextButton(): IglrGUITextButton;
begin
  Result := TglrGUITextButton.Create();
end;

function CreateGUICheckBox(): IglrGUICheckBox;
begin
  Result := TglrGUICheckBox.Create();
end;

function CreateGUITextBox(): IglrGUITextBox;
begin
  Result := TglrGUITextBox.Create();
end;

function CreateGUISlider(): IglrGUISlider;
begin
  Result := TglrGUISlider.Create();
end;

function Create2DScene(): Iglr2DScene;
begin
  Result := Tglr2DScene.Create();
end;
                }
end.

unit uFactory;

interface

uses
  glr, uBaseInterfaceObject,
  Contnrs;

type
  TglrObjectFactory = class (TglrInterfacedObject, IglrObjectFactory)
  public
    function NewNode(): IglrNode;
    function NewUserRender(): IglrUserRenderable;
    function NewHudSprite(): IglrSprite;
    function NewSprite(): IglrSprite; //for future uses
    function NewMaterial(): IglrMaterial;
    function NewTexture(): IglrTexture;
    function NewFont(): IglrFont;
    function NewText(): IglrText;
    function NewGUIButton(): IglrGUIButton;
    function NewGUITextButton(): IglrGUITextButton;
    function NewGUICheckBox(): IglrGUICheckBox;
    function NewGUITextBox(): IglrGUITextBox;
    function NewGUISlider(): IglrGUISlider;
    function New2DScene(): Iglr2DScene;
    function New3DScene(): Iglr3DScene;
  end;

var
  MainFactory: IglrObjectFactory;

implementation

uses
  uRenderer, uNode, uUserRenderable,
  uHudSprite, uTexture, uMaterial, uFont, uText,
  uGUIButton, uGUITextButton, uGUICheckbox, uGUITextBox, uGUISlider,
  uScene;

function TglrObjectFactory.NewUserRender(): IglrUserRenderable;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrUserRenderable.Create();
  Result := obj as IglrUserRenderable;
end;

function TglrObjectFactory.NewHudSprite(): IglrSprite;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrHUDSprite.Create();
  Result := obj as IglrSprite;
end;

function TglrObjectFactory.NewSprite(): IglrSprite;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrHUDSprite.Create();
  Result := obj as IglrSprite;
end;

function TglrObjectFactory.NewMaterial(): IglrMaterial;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrMaterial.Create();
  Result := obj as IglrMaterial;
end;

function TglrObjectFactory.NewNode(): IglrNode;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrNode.Create();
  Result := obj as IglrNode;
end;

function TglrObjectFactory.NewTexture(): IglrTexture;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrTexture.Create();
  Result := obj as IglrTexture;
end;

function TglrObjectFactory.New3DScene: Iglr3DScene;
begin
  Result := Tglr3DScene.Create();
end;

function TglrObjectFactory.NewFont(): IglrFont;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrFont.Create();
  Result:= obj as IglrFont;
end;

function TglrObjectFactory.NewText(): IglrText;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrText.Create();
  Result := obj as IglrText;
end;

function TglrObjectFactory.NewGUIButton(): IglrGUIButton;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUIButton.Create();
  Result := obj as IglrGUIButton;
end;

function TglrObjectFactory.NewGUITextButton(): IglrGUITextButton;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUITextButton.Create();
  Result := obj as IglrGUITextButton;
end;

function TglrObjectFactory.NewGUICheckBox(): IglrGUICheckBox;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUICheckBox.Create();
  Result := obj as IglrGUICheckBox;
end;

function TglrObjectFactory.NewGUITextBox(): IglrGUITextBox;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUITextBox.Create();
  Result := obj as IglrGUITextBox;
end;

function TglrObjectFactory.NewGUISlider(): IglrGUISlider;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUISlider.Create();
  Result := obj as IglrGUISlider;
end;

function TglrObjectFactory.New2DScene(): Iglr2DScene;
var
  obj: TglrInterfacedObject;
begin
  obj := Tglr2DScene.Create();
  Result := obj as Iglr2DScene;
end;

initialization
  MainFactory := TglrObjectFactory.Create();

finalization
  MainFactory := nil;

end.

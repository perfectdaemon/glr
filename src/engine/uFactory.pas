unit uFactory;

interface

uses
  dfHRenderer;

type
  TglrObjectFactory = class (TInterfacedObject, IglrObjectFactory)
  public
    function NewNode(aParent: IglrNode): IglrNode;
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
  end;

var
  MainFactory: TglrObjectFactory;

implementation

uses
  uRenderer, uNode, uUserRenderable,
  uHudSprite, uTexture, uMaterial, uFont, uText,
  uGUIButton, uGUITextButton, uGUICheckbox, uGUITextBox, uGUISlider,
  u2DScene;

function TglrObjectFactory.NewUserRender(): IglrUserRenderable;
begin
  Result := TglrUserRenderable.Create();
end;

function TglrObjectFactory.NewHudSprite(): IglrSprite;
begin
  Result := TglrHUDSprite.Create();
end;

function TglrObjectFactory.NewSprite(): IglrSprite;
begin
  Result := TglrHUDSprite.Create();
end;

function TglrObjectFactory.NewMaterial(): IglrMaterial;
begin
  Result := TglrMaterial.Create();
end;

function TglrObjectFactory.NewNode(aParent: IglrNode): IglrNode;
begin
  if aParent = nil then
    Result := TglrNode.Create
  else
    Result := aParent.AddNewChild();
end;

function TglrObjectFactory.NewTexture(): IglrTexture;
begin
  Result := TglrTexture.Create();
end;

function TglrObjectFactory.NewFont(): IglrFont;
begin
  Result := TglrFont.Create();
end;

function TglrObjectFactory.NewText(): IglrText;
begin
  Result := TglrText.Create();
end;

function TglrObjectFactory.NewGUIButton(): IglrGUIButton;
begin
  Result := TglrGUIButton.Create();
end;

function TglrObjectFactory.NewGUITextButton(): IglrGUITextButton;
begin
  Result := TglrGUITextButton.Create();
end;

function TglrObjectFactory.NewGUICheckBox(): IglrGUICheckBox;
begin
  Result := TglrGUICheckBox.Create();
end;

function TglrObjectFactory.NewGUITextBox(): IglrGUITextBox;
begin
  Result := TglrGUITextBox.Create();
end;

function TglrObjectFactory.NewGUISlider(): IglrGUISlider;
begin
  Result := TglrGUISlider.Create();
end;

function TglrObjectFactory.New2DScene(): Iglr2DScene;
begin
  Result := Tglr2DScene.Create();
end;

end.

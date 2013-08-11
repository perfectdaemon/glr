unit uFactory;

interface

uses
  glr, uBaseInterfaceObject,
  Contnrs;

type
  TglrObjectFactory = class (TglrInterfacedObject, IglrObjectFactory)
  protected
//    FObjectList: TObjectList;
//
//    procedure FreeAllObjects();
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

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
  end;

var
  MainFactory: IglrObjectFactory;

implementation

uses
  uRenderer, uNode, uUserRenderable,
  uHudSprite, uTexture, uMaterial, uFont, uText,
  uGUIButton, uGUITextButton, uGUICheckbox, uGUITextBox, uGUISlider,
  u2DScene;

function TglrObjectFactory.NewUserRender(): IglrUserRenderable;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrUserRenderable.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrUserRenderable;
end;

function TglrObjectFactory.NewHudSprite(): IglrSprite;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrHUDSprite.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrSprite;
end;

function TglrObjectFactory.NewSprite(): IglrSprite;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrHUDSprite.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrSprite;
end;

function TglrObjectFactory.NewMaterial(): IglrMaterial;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrMaterial.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrMaterial;
end;

function TglrObjectFactory.NewNode(): IglrNode;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrNode.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrNode;
end;

function TglrObjectFactory.NewTexture(): IglrTexture;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrTexture.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrTexture;
end;

function TglrObjectFactory.NewFont(): IglrFont;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrFont.Create();
//  FObjectList.Add(obj);
  Result:= obj as IglrFont;
end;

function TglrObjectFactory.NewText(): IglrText;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrText.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrText;
end;

function TglrObjectFactory.NewGUIButton(): IglrGUIButton;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUIButton.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrGUIButton;
end;

function TglrObjectFactory.NewGUITextButton(): IglrGUITextButton;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUITextButton.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrGUITextButton;
end;

function TglrObjectFactory.NewGUICheckBox(): IglrGUICheckBox;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUICheckBox.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrGUICheckBox;
end;

function TglrObjectFactory.NewGUITextBox(): IglrGUITextBox;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUITextBox.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrGUITextBox;
end;

function TglrObjectFactory.NewGUISlider(): IglrGUISlider;
var
  obj: TglrInterfacedObject;
begin
  obj := TglrGUISlider.Create();
//  FObjectList.Add(obj);
  Result := obj as IglrGUISlider;
end;

function TglrObjectFactory.New2DScene(): Iglr2DScene;
var
  obj: TglrInterfacedObject;
begin
  obj := Tglr2DScene.Create();
//  FObjectList.Add(obj);
  Result := obj as Iglr2DScene;
end;


constructor TglrObjectFactory.Create;
begin
  inherited;
//  FObjectList := TObjectList.Create(False);
end;

destructor TglrObjectFactory.Destroy;
begin
//  FreeAllObjects();
//  FObjectList.Free();
  inherited;
end;

//procedure TglrObjectFactory.FreeAllObjects;
//var
//  i: Integer;
//begin
//  for i := 0 to FObjectList.Count - 1 do
//    if Assigned(FObjectList[i]) then
//      FObjectList[i].Free();
//end;

initialization
  MainFactory := TglrObjectFactory.Create();

finalization
  MainFactory := nil;

end.

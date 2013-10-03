unit uObjects;

interface

uses
  glr, glrMath, UPhysics2D, uAccum, uCharacter;

type
  TpdDropObject = class (TpdAccumItem)
  public
    aTimeRemain: Single;
    aText: IglrText;
    aSprite: IglrSprite;
    aBody: Tb2Body;
    aLastBodyPartTouched: TglrBodyPart;
    destructor Destroy(); override;
    procedure Update(const dt: Double);

    {Процедура вызывается после создания нового объекта, т. е. один раз за все время}
    procedure OnCreate(); override;
    {Процедура вызывается каждый раз, когда объект достают из аккумулятора}
    procedure OnGet(); override;
    {Процедура вызывается, когда обект помещают в аккумулятор}
    procedure OnFree(); override;

    function IsOut(): Boolean;
    procedure SetPosition(aPos: TdfVec2f);
  end;

  TpdDrops = class (TpdAccum)
  public
    function NewAccumItem(): TpdAccumItem; override;
    function GetItem(): TpdDropObject; reintroduce;
  end;

implementation

uses
  SysUtils, UPhysics2DTypes, uBox2DImport, uGlobal;

{ TglrDropObject }

const
  TIME_TO_LIVE = 15.0;
  TEXT_OFFSET_X = 0.0;
  TEXT_OFFSET_Y = -16.0;

destructor TpdDropObject.Destroy;
begin
  Dispose(aBody.UserData);
//  b2world.DestroyBody(aBody);
  inherited;
end;

function TpdDropObject.IsOut: Boolean;
begin
  Result := (aSprite.Position.x < 0 - aSprite.Width / 2) or
            (aSprite.Position.x > R.WindowWidth + aSprite.Width / 2);
end;

procedure TpdDropObject.OnCreate;
var
  userdata: ^TpdUserData;
begin
  inherited;
  aSprite := Factory.NewSprite();
  aText := Factory.NewText();
//  FScene := aScene;

  aSprite.Material.Texture := texHead;
  aSprite.PivotPoint := ppCenter;
  aSprite.UpdateTexCoords();
  aSprite.Width := 40;
  aSprite.Height := 40;
  aSprite.Material.Diffuse := dfVec4f(0.2, 0.2, 0.2, 1);
  aSprite.Position2D := dfVec2f(140, 140);
  with aSprite.Position do
    z := Z_DROPOBJECTS;

  aText.Font := fontCooper;
  aText.PivotPoint := ppCenter;
  aText.Position2D := aSprite.Position2D + dfVec2f(TEXT_OFFSET_X, TEXT_OFFSET_Y);
  with aText.Position do
    z := Z_DROPOBJECTS + 1;
  aText.Material.Diffuse := dfVec4f(1, 1, 1, 1);

  mainScene.RootNode.AddChild(aSprite);
  mainScene.RootNode.AddChild(aText);

  aBody := dfb2InitCircle(b2world, aSprite.Width / 2, aSprite.Position2D,
    0.2, 0.4, 0.7,
    $FFFF, $F000, 0);

  New(userdata);
  with userdata^ do
  begin
    aType := tSphere;
    aObject := Self;
    aObjectSprite := aSprite;
    aBodyPart := bpNone;
    aSprite._Release();
  end;
  aBody.UserData := userdata;

  OnFree();
end;

procedure TpdDropObject.OnFree;
begin
  inherited;
  aBody.SetActive(False);
  aSprite.Visible := False;
  aText.Visible := False;
end;

procedure TpdDropObject.OnGet;
begin
  inherited;
  aTimeRemain := TIME_TO_LIVE;
  aSprite.Visible := True;
  aText.Visible := True;
  aBody.SetActive(True);
  aLastBodyPartTouched := bpNone;
end;

procedure TpdDropObject.SetPosition(aPos: TdfVec2f);
begin
  aBody.SetTransform(ConvertGLToB2(aPos * C_COEF), 0);
  aBody.SetLinearVelocity(TVector2.From(0, 0));
  aBody.SetAngularVelocity(0);
end;

procedure TpdDropObject.Update(const dt: Double);
begin
  SyncObjects(aBody, aSprite);
  aText.Position2D := aSprite.Position2D + dfVec2f(TEXT_OFFSET_X, TEXT_OFFSET_Y);;
  aTimeRemain := aTimeRemain - dt;
  aText.Text := IntToStr(Trunc(aTimeRemain));
end;

{ TpdDrops }

function TpdDrops.GetItem: TpdDropObject;
begin
  Result := inherited GetItem() as TpdDropObject;
end;

function TpdDrops.NewAccumItem: TpdAccumItem;
begin
  Result := TpdDropObject.Create();
end;

end.

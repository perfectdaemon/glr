{
+ TODO: рефакторинг - убрать закомментированные строки - функционал ушел в TdfGUIElement
  TODO: добавить текстуру для disabled-состояния. Отлавливать Enabled := False
}

unit uGUIButton;

interface

uses
  glr,
  uGUIElement;

type
  TglrGUIButton = class(TglrGUIElement, IglrGUIButton)
  protected
    FTexNormal, FTexOver, FTexClick: IglrTexture;

    FTextureAutoChange: Boolean;

    procedure CalcHitZone(); override;

    function GetTextureNormal(): IglrTexture;
    function GetTextureOver(): IglrTexture;
    function GetTextureClick(): IglrTexture;

    procedure SetTextureNormal(aTexture: IglrTexture);
    procedure SetTextureOver(aTexture: IglrTexture);
    procedure SetTextureClick(aTexture: IglrTexture);

    function GetAutoChange: Boolean;
    procedure SetAutoChange(aChange: Boolean);
  public
    constructor Create(); override;
    destructor Destroy; override;

    procedure _MouseMove (X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure _MouseDown (X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure _MouseUp   (X, Y: Integer; MouseButton: TglrMouseButton; Shift: TglrMouseShiftState); override;
    procedure _MouseOver (X, Y: Integer; Shift: TglrMouseShiftState); override;
    procedure _MouseOut  (X, Y: Integer; Shift: TglrMouseShiftState); override;

    property TextureNormal: IglrTexture read GetTextureNormal write SetTextureNormal;
    property TextureOver:   IglrTexture read GetTextureOver   write SetTextureOver;
    property TextureClick:  IglrTexture read GetTextureClick  write SetTextureClick;

    //Текстуры будут меняться автоматически при наведении, клие и уходе мыши
    property TextureAutoChange: Boolean read GetAutoChange write SetAutoChange;

    procedure Reset(); override;
  end;

implementation

{ TdfGUIButton }

procedure TglrGUIButton.CalcHitZone;
begin
  if Assigned(FTexNormal) then
  begin

  end;
end;

constructor TglrGUIButton.Create;
begin
  inherited;
  FTexNormal := nil;
  FTexOver := nil;
  FTexClick := nil;

  FOnClick := nil;
  FOnOver := nil;
  FOnOut := nil;

  FTextureAutoChange := True;
  FHitMode := hmBox;
end;

destructor TglrGUIButton.Destroy;
begin
  FTexNormal := nil;
  FTexOver := nil;
  FTexClick := nil;
  inherited;
end;

function TglrGUIButton.GetAutoChange: Boolean;
begin
  Result := FTextureAutoChange;
end;

function TglrGUIButton.GetTextureClick: IglrTexture;
begin
  Result := FTexClick;
end;

function TglrGUIButton.GetTextureNormal: IglrTexture;
begin
  Result := FTexNormal;
end;

function TglrGUIButton.GetTextureOver: IglrTexture;
begin
  Result := FTexOver;
end;

procedure TglrGUIButton.Reset;
begin
  inherited;
  if Assigned(FTexNormal) then
  begin
    FMaterial.Texture := FTexNormal;
    UpdateTexCoords();
  end;
end;

procedure TglrGUIButton.SetAutoChange(aChange: Boolean);
begin
  FTextureAutoChange := aChange;
end;

procedure TglrGUIButton.SetTextureClick(aTexture: IglrTexture);
begin
  FTexClick := aTexture;
end;

procedure TglrGUIButton.SetTextureNormal(aTexture: IglrTexture);
begin
  FTexNormal := aTexture;

  if FHitMode in [hmAlpha0, hmAlpha50] then
    CalcHitZone();

  Material.Texture := FTexNormal;
end;

procedure TglrGUIButton.SetTextureOver(aTexture: IglrTexture);
begin
  FTexOver := aTexture;
end;

procedure TglrGUIButton._MouseDown(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  inherited;
  if FTextureAutoChange and Assigned(FTexClick) and FEnabled then
  begin
    Material.Texture := FTexClick;
    UpdateTexCoords();
  end;
end;

procedure TglrGUIButton._MouseMove(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  inherited;
  if FTextureAutoChange and Assigned(FTexOver) and not (ssLeft in Shift) and FEnabled then
  begin
    FMaterial.Texture := FTexOver;
    UpdateTexCoords();
  end;
end;

procedure TglrGUIButton._MouseOut(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  inherited;
  if FTextureAutoChange and Assigned(FTexNormal) and FEnabled then
  begin
    FMaterial.Texture := FTexNormal;
    UpdateTexCoords();
  end;
end;

procedure TglrGUIButton._MouseOver(X, Y: Integer; Shift: TglrMouseShiftState);
begin
  inherited;
  if FTextureAutoChange and Assigned(FTexOver) and FEnabled then
  begin
    FMaterial.Texture := FTexOver;
    UpdateTexCoords();
  end;
end;

procedure TglrGUIButton._MouseUp(X, Y: Integer; MouseButton: TglrMouseButton;
  Shift: TglrMouseShiftState);
begin
  inherited;
  if FTextureAutoChange and Assigned(FTexNormal) and FEnabled and CheckHit(X, Y) then
  begin
    Material.Texture := FTexOver;
    UpdateTexCoords();
  end;
end;

end.

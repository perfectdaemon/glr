unit uGUITextButton;

interface

uses
  glr, glrMath,
  uGUIButton;

type
  TglrGUITextButton = class (TglrGUIButton, IglrGUITextButton)
  protected
    FText: IglrText;
    FTextOffset: TdfVec2f;
    function GetText(): IglrText;
    procedure SetText(const aText: IglrText);
    function GetTextOffset(): TdfVec2f;
    procedure SetTextOffset(aOffset: TdfVec2f);
    procedure SetZ(const aValue: Integer); override;
    procedure SetVis(aVis: Boolean); override;
  public
    property TextObject: IglrText read GetText write SetText;
    property TextOffset: TdfVec2f read GetTextOffset write SetTextOffset;

    procedure DoRender(); override;

    constructor Create(); override;
    destructor Destroy(); override;
  end;

implementation

uses
  ExportFunc;

{ TdfGUITextButton }

constructor TglrGUITextButton.Create;
begin
  inherited;
  FText := GetObjectFactory().NewText();
  FText.AbsolutePosition := False;
end;

destructor TglrGUITextButton.Destroy;
begin
  FText := nil;
  inherited;
end;

procedure TglrGUITextButton.DoRender;
begin
  inherited;
  FText.Render();
end;

function TglrGUITextButton.GetText: IglrText;
begin
  Result := FText;
end;

function TglrGUITextButton.GetTextOffset: TdfVec2f;
begin
  Result := FTextOffset;
end;

procedure TglrGUITextButton.SetText(const aText: IglrText);
begin
  FText := aText;
end;

procedure TglrGUITextButton.SetTextOffset(aOffset: TdfVec2f);
begin
  FTextOffset := aOffset;
  FText.Position := aOffset;
end;

procedure TglrGUITextButton.SetVis(aVis: Boolean);
begin
  inherited;
  FText.Visible := aVis;
end;

procedure TglrGUITextButton.SetZ(const aValue: Integer);
begin
  inherited;
  FText.Z := aValue + 1;
end;

end.

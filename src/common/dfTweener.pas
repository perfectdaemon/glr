{Author: lampogolovii (lampogolovii.blogspot.com)

 I think, he won't be worried that I'm using his code :)

 Refactored

 TODO:
  пул для TweenItem}

unit dfTweener;

interface

uses
  dfMath,
  Classes;

type
  TdfVarType = (vtInteger, vtSingle, vtVector);
  PdfInteger = ^Integer;
  PdfSingle = PSingle;
  PdfVec3f = ^TdfVec3f;

  TdfTweenObject = TObject;
  IdfTweenObject = IInterface;

  TdfEasingFunc = function(aStartValue, aDiffValue, aUnitValue: Single): Single of object;
  TdfTweenStyle = (tsElasticEaseIn, tsElasticEaseOut, tsExpoEaseIn, tsBounce, tsSimple);
  TdfSetSingle = procedure(aObject: TdfTweenObject; aValue: Single);
  TdfSetSingleI = procedure(aInterface: IdfTweenObject; aValue: Single);
  TdfDoneCallback = procedure of object;

  TdfBaseTweenItem = class
  protected
    FPaused: Boolean;
    FTime: Single;
    FPauseOnStart: Single;
    FDone: Boolean;
    FOnDone: TdfDoneCallback;
    FDuration: Single;
  protected
    FEasingFunc: TdfEasingFunc;
    function GetUnitValue(): Single; virtual;
    function ShouldChange(): Boolean;
  public
    property Done: Boolean read FDone;
    property OnDone: TdfDoneCallback read FOnDone write FOnDone;
    procedure Play; virtual;
    procedure Pause; virtual;
    procedure SetPause(const aPause: Boolean); virtual;
    procedure Update(const aDeltaTime: Single); virtual;

    constructor Create(aDuration: Single; aPauseOnStart: Single);
  end;

  TdfBaseSingleTweenItem = class (TdfBaseTweenItem)
  protected
    FStartValue, FFinishValue: Single;
  public
    constructor Create(aStartValue, aFinishValue, aDuration: Single;
      aPauseOnStart: Single);
  end;

  TdfPSingleTweenItem = class (TdfBaseSingleTweenItem)
  protected
    FValue: PdfSingle;
  public
    procedure Update(const aDeltaTime: Single); override;
    constructor Create(aValue: PdfSingle; aStartValue, aFinishValue,
      aDuration: Single; aPauseOnStart: Single);
  end;

  TdfSingleTweenItem = class (TdfBaseSingleTweenItem)
  protected
    FSetSingleEvent: TdfSetSingle;
    FObject: TdfTweenObject;
  public
    property SetSingleEvent: TdfSetSingle read FSetSingleEvent write FSetSingleEvent;
    procedure Update(const aDeltaTime: Single); override;

    constructor Create(aObject: TdfTweenObject; aEvent: TdfSetSingle;
      aStartValue, aFinishValue, aDuration: Single; aPauseOnStart: Single);
  end;

  TdfInterfaceTweenItem = class (TdfBaseSingleTweenItem)
  protected
    FSetSingleEvent: TdfSetSingleI;
    FInt: IdfTweenObject;
  public
    property SetSingleEvent: TdfSetSingleI read FSetSingleEvent write FSetSingleEvent;
    procedure Update(const aDeltaTime: Single); override;

    constructor Create(aObject: IdfTweenObject; aEvent: TdfSetSingleI;
      aStartValue, aFinishValue, aDuration: Single; aPauseOnStart: Single);
  end;

  TdfBaseVectorTweenItem = class (TdfBaseTweenItem)
  protected
    FStartValue, FFinishValue: TdfVec3f;
  public
    constructor Create(aStartValue, aFinishValue: TdfVec3f; aDuration: Single;
      aPauseOnStart: Single);
  end;

  TdfPVectorTweenItem = class (TdfBaseVectorTweenItem)
  protected
    FValue: PdfVec3f;
  public
    procedure Update(const aDeltaTime: Single); override;
    constructor Create(aValue: PdfVec3f; aStartValue, aFinishValue: TdfVec3f;
      aDuration: Single; aPauseOnStart: Single);
  end;

  TdfBaseEasingFunctions = class
  public
    class function ExpoEaseIn(aStartValue, aDiffValue, aUnitValue: Single): Single;
    class function QuintEaseOut(aStartValue, aDiffValue, aUnitValue: Single): Single;
    class function ElasticEaseIn(aStartValue, aDiffValue, aUnitValue: Single): Single;
    class function Simple(aStartValue, aDiffValue, aUnitValue: Single): Single;
  end;

  TdfTweener = class
  protected
    FTweenItems: TList;
    FEasingFunctions: TdfBaseEasingFunctions;
    function GetTweenCount: Integer;
  public
    property TweenCount: Integer read GetTweenCount;

    // манипуляция с элементами списка
    function GetItemByIndex(const aIndex: integer): TdfBaseTweenItem;
    procedure FreeByIndex(const aIndex: integer);
    procedure FreeAll;
    function AddTweenItem(aTweenItem: TdfBaseTweenItem; aTweenStyle: TdfTweenStyle): Integer; virtual;

    // добавление типовых элементов
    function AddTweenPSingle(aVariable: PdfSingle; aTweenStyle: TdfTweenStyle;
       const aStartValue, aFinishValue, aDuration: Single;
       const aPauseOnStart: Single = 0): TdfPSingleTweenItem;

    function AddTweenPVector(aVariable: PdfVec3f; aTweenStyle: TdfTweenStyle;
      const aStartValue, aFinishValue: TdfVec3f; aDuration: Single;
      const aPauseOnStart: Single = 0): TdfPVectorTweenItem;

    function AddTweenSingle(aObject: TdfTweenObject; aSetValue: TdfSetSingle; aTweenStyle: TdfTweenStyle;
      const aStartValue, aFinishValue, aDuration: Single;
      const aPauseOnStart: Single = 0): TdfSingleTweenItem;

    function AddTweenInterface(aObject: IdfTweenObject; aSetValue: TdfSetSingleI; aTweenStyle: TdfTweenStyle;
      const aStartValue, aFinishValue, aDuration: Single;
      const aPauseOnStart: Single = 0): TdfInterfaceTweenItem;

    procedure Update(const aDeltaTime: Single);

    constructor Create;
    destructor Destroy; override;
  end;

var
  Tweener: TdfTweener;

implementation

uses

  SysUtils;

function TdfBaseTweenItem.GetUnitValue: Single;
begin
  if FTime <= FPauseOnStart then
    Result := 0
  else if FTime = FDuration + FPauseOnStart then
    Result := 1
  else
    Result := (FTime - FPauseOnStart) / FDuration;
end;

function TdfBaseTweenItem.ShouldChange: Boolean;
begin
  Result := FTime >= FPauseOnStart;
end;

Procedure TdfBaseTweenItem.Play;
begin
  SetPause(False);
end;

procedure TdfBaseTweenItem.Pause;
begin
  SetPause(True);
end;

procedure TdfBaseTweenItem.SetPause(const aPause: Boolean);
begin
  FPaused := aPause;
end;

procedure TdfBaseTweenItem.Update(const aDeltaTime: Single);
begin
  if FPaused then
    Exit;

  FTime := FTime + aDeltaTime;
  if FTime - FPauseOnStart >= FDuration then
  begin
    FTime := FDuration + FPauseOnStart;
    FDone := True;
    Pause;
    if Assigned(FOnDone) then
      FOnDone()
  end;  
end;

constructor TdfBaseTweenItem.Create(aDuration: Single; aPauseOnStart: Single);
begin
  inherited Create;
  FDuration := aDuration;
  FPauseOnStart := aPauseOnStart;
  FTime := 0;
  FDone := False;
end;

constructor TdfBaseSingleTweenItem.Create(aStartValue, aFinishValue,
  aDuration: Single; aPauseOnStart: Single);
begin
  inherited Create(aDuration, aPauseOnStart);
  FStartValue := aStartValue;
  FFinishValue := aFinishValue;
end;

procedure TdfPSingleTweenItem.Update(const aDeltaTime: Single);
begin
  inherited Update(aDeltaTime);
  if Assigned(FEasingFunc) then
    FValue^ := FEasingFunc(FStartValue, FFinishValue - FStartValue, GetUnitValue);
end;

constructor TdfPSingleTweenItem.Create(aValue: PdfSingle; aStartValue,
  aFinishValue, aDuration: Single; aPauseOnStart: Single);
begin
  inherited Create(aStartValue, aFinishValue, aDuration, aPauseOnStart);
  FValue := aValue;
end;

procedure TdfSingleTweenItem.Update(const aDeltaTime: Single);
begin
  inherited Update(aDeltaTime);
  if Assigned(FSetSingleEvent) and Assigned(FEasingFunc) then
    FSetSingleEvent(FObject, FEasingFunc(FStartValue, FFinishValue - FStartValue, GetUnitValue));
end;

constructor TdfSingleTweenItem.Create(aObject: TdfTweenObject; aEvent: TdfSetSingle;
  aStartValue, aFinishValue, aDuration: Single; aPauseOnStart: Single);
begin
  inherited Create(aStartValue, aFinishValue, aDuration, aPauseOnStart);
  FObject := aObject;
  FSetSingleEvent := aEvent;
end;

constructor TdfBaseVectorTweenItem.Create(aStartValue, aFinishValue: TdfVec3f;
  aDuration: Single; aPauseOnStart: Single);
begin
  inherited Create(aDuration, aPauseOnStart);
  FStartValue := aStartValue;
  FFinishValue := aFinishValue;
end;

procedure TdfPVectorTweenItem.Update(const aDeltaTime: Single);
begin
  inherited Update(aDeltaTime);
  if Assigned(FEasingFunc) and ShouldChange then
  begin
    FValue^.x := FEasingFunc(FStartValue.x, FFinishValue.x - FStartValue.x, GetUnitValue);
    FValue^.y := FEasingFunc(FStartValue.y, FFinishValue.y - FStartValue.y, GetUnitValue);
    FValue^.z := FEasingFunc(FStartValue.z, FFinishValue.z - FStartValue.z, GetUnitValue);
  end;
end;

constructor TdfPVectorTweenItem.Create(aValue: PdfVec3f; aStartValue, aFinishValue: TdfVec3f;
  aDuration: Single; aPauseOnStart: Single);
begin
  inherited Create(aStartValue, aFinishValue, aDuration, aPauseOnStart);
  FValue := aValue;
end;

class function TdfBaseEasingFunctions.ExpoEaseIn(aStartValue, aDiffValue, aUnitValue: Single): Single;
begin
  if (aUnitValue = 1) then
    Result := aStartValue + aDiffValue
  else
    Result := aDiffValue * (-Pow(2, -15*aUnitValue) + 1) + aStartValue;
end;

class function TdfBaseEasingFunctions.QuintEaseOut(aStartValue, aDiffValue, aUnitValue: Single): Single;
begin
  Result := aStartValue;
end;

class function TdfBaseEasingFunctions.Simple(aStartValue, aDiffValue,
  aUnitValue: Single): Single;
begin
  if aUnitValue = 1 then
    Result := aStartValue + aDiffValue
  else
    Result := aStartValue + aDiffValue * aUnitValue;
end;

class function TdfBaseEasingFunctions.ElasticEaseIn(aStartValue, aDiffValue, aUnitValue: Single): Single;
begin
  if (aDiffValue = 0) or (aUnitValue = 0) or (aUnitValue = 1) then
  begin
    if (aUnitValue = 1) then
      Result := aStartValue + aDiffValue
    else
      Result := aStartValue;
    Exit;
  end;
  Result := (aDiffValue * Pow(2, -10 * aUnitValue) * Sin((aUnitValue - 0.25/4)*(2*3.14)/0.25)) + aDiffValue + aStartValue;
end;

function TdfTweener.GetTweenCount: Integer;
begin
  Result := FTweenItems.Count;
end;

function TdfTweener.GetItemByIndex(const aIndex: integer): TdfBaseTweenItem;
begin
  Result := TdfBaseTweenItem(FTweenItems[aIndex]);
end;

procedure TdfTweener.FreeByIndex(const aIndex: integer);
var
  TweenItem: TdfBaseTweenItem;
begin
  TweenItem := GetItemByIndex(aIndex);
  FreeAndNil(TweenItem);
  FTweenItems.Delete(aIndex);
end;

procedure TdfTweener.FreeAll;
begin
  {TODO: rewrite}
  while FTweenItems.Count > 0 do
    FreeByIndex(0);  
end;

function TdfTweener.AddTweenInterface(aObject: IdfTweenObject;
  aSetValue: TdfSetSingleI; aTweenStyle: TdfTweenStyle; const aStartValue,
  aFinishValue, aDuration, aPauseOnStart: Single): TdfInterfaceTweenItem;
begin
  Result := TdfInterfaceTweenItem.Create(aObject, aSetValue, aStartValue, aFinishValue, aDuration, aPauseOnStart);
  AddTweenItem(Result, aTweenStyle);
end;

function TdfTweener.AddTweenItem(aTweenItem: TdfBaseTweenItem; aTweenStyle: TdfTweenStyle): Integer;
begin
  case aTweenStyle of
    tsElasticEaseIn:  aTweenItem.FEasingFunc := FEasingFunctions.ElasticEaseIn;
    tsElasticEaseOut: aTweenItem.FEasingFunc := FEasingFunctions.ElasticEaseIn;
    tsExpoEaseIn:     aTweenItem.FEasingFunc := FEasingFunctions.ExpoEaseIn;
    tsBounce:         aTweenItem.FEasingFunc := FEasingFunctions.ElasticEaseIn;
    tsSimple:         aTweenItem.FEasingFunc := FEasingFunctions.Simple;
  end;
  Result := FTweenItems.Add(aTweenItem);
end;

function TdfTweener.AddTweenPSingle(aVariable: PdfSingle; aTweenStyle: TdfTweenStyle;
  const aStartValue, aFinishValue, aDuration: Single;
  const aPauseOnStart: Single = 0): TdfPSingleTweenItem;
begin
  Result := TdfPSingleTweenItem.Create(aVariable, aStartValue, aFinishValue, aDuration, aPauseOnStart);
  AddTweenItem(Result, aTweenStyle);
end;

function TdfTweener.AddTweenPVector(aVariable: PdfVec3f; aTweenStyle: TdfTweenStyle;
  const aStartValue, aFinishValue: TdfVec3f; aDuration: Single;
  const aPauseOnStart: Single = 0): TdfPVectorTweenItem;
begin
  Result := TdfPVectorTweenItem.Create(aVariable, aStartValue, aFinishValue, aDuration, aPauseOnStart);
  AddTweenItem(Result, aTweenStyle);
end;

function TdfTweener.AddTweenSingle(aObject: TdfTweenObject; aSetValue: TdfSetSingle; aTweenStyle: TdfTweenStyle;
  const aStartValue, aFinishValue, aDuration: Single;
  const aPauseOnStart: Single = 0): TdfSingleTweenItem;
begin
  Result := TdfSingleTweenItem.Create(aObject, aSetValue, aStartValue, aFinishValue, aDuration, aPauseOnStart);
  AddTweenItem(Result, aTweenStyle);
end;
//------------------------------------------------------------------------------
Procedure TdfTweener.Update(const aDeltaTime: Single);
var
  i: integer;
  item: TdfBaseTweenItem;
begin
  {TODO: do not delete, sent to accum}
  i := 0;
  while (i < TweenCount)do
  begin
    item := GetItemByIndex(i);
    if item.Done then
      FreeByIndex(i)
    else
    begin
      item.Update(aDeltaTime);
      inc(i);
    end;
  end;
end;

constructor TdfTweener.Create;
begin
  inherited Create;
  FTweenItems := TList.Create;
  FEasingFunctions := TdfBaseEasingFunctions.Create;
end;

destructor TdfTweener.Destroy;
begin
  FreeAll;
  FreeAndNil(FEasingFunctions);
  FreeAndNil(FTweenItems);
  inherited Destroy;
end;

{ TdfInterfaceTweenItem }

constructor TdfInterfaceTweenItem.Create(aObject: IdfTweenObject;
  aEvent: TdfSetSingleI; aStartValue, aFinishValue, aDuration,
  aPauseOnStart: Single);
begin
  inherited Create(aStartValue, aFinishValue, aDuration, aPauseOnStart);
  FInt := aObject;
  FSetSingleEvent := aEvent;
end;

procedure TdfInterfaceTweenItem.Update(const aDeltaTime: Single);
begin
  inherited Update(aDeltaTime);
  if Assigned(FSetSingleEvent) and Assigned(FEasingFunc) then
    FSetSingleEvent(FInt, FEasingFunc(FStartValue, FFinishValue - FStartValue, GetUnitValue));
end;

initialization
  Tweener := TdfTweener.Create;

finalization
  Tweener.Free;
end.

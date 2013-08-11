unit uBaseInterfaceObject;

interface

type
  TglrInterfacedObject = TInterfacedObject;{ class (TObject, IInterface)
  protected
    FRefCount: Integer;
    FDestroyObject: Boolean;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    destructor Destroy(); override;

    procedure FreeInstance(); override;

    procedure BeforeDestruction; override;
    procedure AfterConstruction; override;
    property RefCount: Integer read FRefCount;
  end;                                      }


implementation
{
uses
  SysUtils;

function InterlockedIncrement(var Addend: Integer): Integer;
asm
      MOV   EDX,1
      XCHG  EAX,EDX
 LOCK XADD  [EDX],EAX
      INC   EAX
end;

function InterlockedDecrement(var Addend: Integer): Integer;
asm
      MOV   EDX,-1
      XCHG  EAX,EDX
 LOCK XADD  [EDX],EAX
      DEC   EAX
end;

procedure TglrInterfacedObject.AfterConstruction;
begin
  inherited;
  Dec(FRefCount);
end;

procedure TglrInterfacedObject.BeforeDestruction();
begin
  // The object is destroyed only if there are no references to it
  if FRefCount = 0 then
    inherited;
end;

destructor TglrInterfacedObject.Destroy();
begin
  // The object is destroyed only if there are no references to it
  if FRefCount = 0 then
    inherited
  else
    // Flag to call free on the last call to _Release
    FDestroyObject := True;
end;

procedure TglrInterfacedObject.FreeInstance();
begin
  // The object is destroyed only if there are no references to it
  if FRefCount = 0 then
    inherited;
end;

function TglrInterfacedObject.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TglrInterfacedObject._AddRef(): Integer;
begin
  // No reference count is taking place
  Result := -1;
  Inc(FRefCount);
end;

function TglrInterfacedObject._Release: Integer;
begin
  // No reference count is taking place
  Result := -1;
  Dec(FRefCount);
  if (FRefCount = 0) and FDestroyObject then
    Free;
end;               }

end.

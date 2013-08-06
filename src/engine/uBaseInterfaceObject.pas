unit uBaseInterfaceObject;

interface

type
  TglrInterfacedObject = class (TObject, IInterface)
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public

  end;

implementation

{ TglrInterfacedObject }

function TglrInterfacedObject.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TglrInterfacedObject._AddRef: Integer;
begin
  Result := 0;
end;

function TglrInterfacedObject._Release: Integer;
begin
  Result := 0;
end;

end.

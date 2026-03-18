unit hmiobjectcolletion;

interface

uses
  Classes, hmibasiccolletion, rttiutils, typinfo;

type
  {$IFDEF PORTUGUES}
  {:
  Implementa uma coleção de objetos.
  }
  {$ELSE}
  {:
  Object colletion class.
  }
  {$ENDIF}
  TObjectColletion = class(THMIBasicColletion);

  {$IFDEF PORTUGUES}
  {:
  Implementa um item da coleção de objetos.
  }
  {$ELSE}
  {:
  Object colletion class item.
  }
  {$ENDIF}
  TObjectColletionItem = class(THMIBasicColletionItem)
  private
    FTag: PtrUInt;
  protected
    FTargetObject: TComponent;
    FTargetObjectLoaded: TComponent;
    FTargetObjectProperty: Ansistring;
    FTargetObjectPropertyLoaded: Ansistring;

    procedure SetTargetObject(AValue: TComponent);
    procedure SetTargetObjectProperty(AValue: Ansistring);
  protected
    FRequiredTypeName: Ansistring;
    FRequiredTypeKind: TTypeKind;

    function AcceptObject(Obj: TComponent): Boolean; virtual;
    function AcceptObjectProperty(PropertyName: Ansistring): Boolean; virtual;
  published
    property Tag: PtrUInt read FTag write FTag;
    property TargetObject: TComponent read FTargetObject write SetTargetObject;
    property TargetObjectProperty: Ansistring read FTargetObjectProperty write SetTargetObjectProperty;
  public
    procedure Loaded; override;
    constructor Create(ACollection: TCollection); override;
  end;

  TObjectColletionItemClass = class of TObjectColletionItem;


implementation


{ TObjectColletionItem }

procedure TObjectColletionItem.SetTargetObject(AValue: TComponent);
begin
  if [csReading, csLoading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FTargetObjectLoaded := AValue;
    Exit;
  end;

  if FTargetObject = AValue then Exit;
  if AValue = Collection.Owner then Exit;

  if AValue = nil then
  begin
    if Assigned(FTargetObject) then
      FTargetObject.RemoveFreeNotification(TComponent(Collection.Owner));
    FTargetObject := nil;
    FTargetObjectProperty := '';
    Exit;
  end;

  if not AcceptObject(AValue) then Exit;
  FTargetObject := AValue;
  if Collection.Owner is TComponent then
    FTargetObject.FreeNotification(TComponent(Collection.Owner));
end;

procedure TObjectColletionItem.SetTargetObjectProperty(AValue: Ansistring);
begin
  if [csReading, csLoading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FTargetObjectPropertyLoaded := AValue;
    Exit;
  end;

  if FTargetObjectProperty = AValue then Exit;

  if AValue = '' then
  begin
    FTargetObjectProperty := '';
    Exit;
  end;

  if not Assigned(FTargetObject) then Exit;
  if not AcceptObject(FTargetObject) then Exit;
  if not AcceptObjectProperty(AValue) then Exit;

  FTargetObjectProperty := AValue;
end;

function TObjectColletionItem.AcceptObject(Obj: TComponent): Boolean;
var
  helper: TPropInfoList;
  pidx: Integer;
begin
  Result := False;
  helper := TPropInfoList.Create(Obj, [FRequiredTypeKind]);
  try
    for pidx := 0 to helper.Count - 1 do
    begin
      if helper.Items[pidx]^.PropType^.Name = FRequiredTypeName then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    helper.Free;
  end;
end;

function TObjectColletionItem.AcceptObjectProperty(PropertyName: Ansistring): Boolean;
var
  Helper: TPropInfoList;
  i: Integer;
begin
  Result := False;
  if FTargetObject = nil then Exit;
  Helper := TPropInfoList.Create(FTargetObject, [FRequiredTypeKind]);
  try
    for i := 0 to Helper.Count - 1 do
    begin
      if (LowerCase(Helper.Items[i]^.Name) = LowerCase(PropertyName)) and
        (Helper.Items[i]^.PropType^.Name = FRequiredTypeName) then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    Helper.Free;
  end;
end;

procedure TObjectColletionItem.Loaded;
begin
  inherited Loaded;
  SetTargetObject(FTargetObjectLoaded);
  SetTargetObjectProperty(FTargetObjectPropertyLoaded);
end;

constructor TObjectColletionItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FRequiredTypeName := '';
end;

end.

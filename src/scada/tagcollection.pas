{$i ../common/language.inc}
{:
  @abstract(Implements a tag collection.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
unit tagcollection;

interface

uses
  Classes, SysUtils, PLCTag, ProtocolTypes, pscommontypes
{$IFNDEF FPC}
  , StdCtrls
{$ENDIF}
  ;

type
  {: @abstract(Class of a tag collection item.)
     @author(Fabio Luis Girardi <fabio@pascalscada.com>) }
  TTagCollectionItem = class(TCollectionItem, IUnknown)
  private
    FTag: TPLCTag;
    procedure SetTag(AValue: TPLCTag);

    function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))} stdcall{$ELSE}cdecl{$IFEND};
    function _AddRef: Longint; {$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))} stdcall{$ELSE}cdecl{$IFEND};
    function _Release: Longint; {$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))} stdcall{$ELSE}cdecl{$IFEND};

    procedure WriteFaultCallBack(Sender: TObject);
    procedure TagChangeCallBack(Sender: TObject);
    procedure RemoveTagCallBack(Sender: TObject);
  protected
    //: Notifies the collection when a value a collection item changes.
    procedure NotifyChange;

    //: Returns the tag collection item description.
    function GetDisplayName: AnsiString; override;
  public
    //: @exclude
    constructor Create(ACollection: TCollection); override;
    //: @exclude
    destructor Destroy; override;

    {: The collection will call this method to notify the collection
    item when everything is fully loaded. }
    procedure Loaded;
  published
    //: Tag of collection.
    property PLCTag: TPLCTag read FTag write SetTag;
  end;

  {: @abstract(Class of collection of tags.)
     @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  Use this class if you need more than one tag, like as recipes and historics. }
  TTagCollection = class(TCollection)
  private
    FOnItemChange: TNotifyEvent;
    FOnValuesChange: TNotifyEvent;
    FOnNeedCompState: TNeedCompStateEvent;
    FComponentState: TComponentState;
  protected
    //: Returns the actual state of the collection owner.
    function GetComponentState: TComponentState;

    //: Request the actual owner state.
    procedure NeedCurrentCompState;
  published
    //: Tells when at least one collection item was changed.
    property OnItemChange: TNotifyEvent read FOnItemChange write FOnItemChange;
    //: Tells when a value of an collection item was changed.
    property OnValuesChange: TNotifyEvent read FOnValuesChange write FOnValuesChange;
    //: Event used to inform to collection the actual estate of the owner.
    property OnNeedCompState: TNeedCompStateEvent read FOnNeedCompState write FOnNeedCompState;
  public
    //: @exclude
    constructor Create(AItemClass: TCollectionItemClass);
    {: Method that the owner must call to inform the collection that it's fully
       loaded. }
    procedure Loaded;
    //: Tells the actual state of the collection owner.
    property ZonesState: TComponentState read GetComponentState;
  end;


implementation


uses
  hsstrings;


constructor TTagCollectionItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FTag := nil;
end;

destructor TTagCollectionItem.Destroy;
begin
  if FTag <> nil then
    FTag.RemoveAllHandlersFromObject(Self);
  inherited Destroy;
end;

procedure TTagCollectionItem.SetTag(AValue: TPLCTag);
begin
  if AValue = FTag then Exit;

  if (AValue <> nil) and (not Supports(AValue, ITagInterface)) then
    raise Exception.Create(SinvalidTag);

  if FTag <> nil then
    FTag.RemoveAllHandlersFromObject(Self);

  if AValue <> nil then
  begin
    FTag.AddRemoveTagHandler(@RemoveTagCallBack);
    FTag.AddWriteFaultHandler(@WriteFaultCallBack);
    FTag.AddTagChangeHandler(@TagChangeCallBack);
  end;

  FTag := AValue;

  NotifyChange;
end;

procedure TTagCollectionItem.NotifyChange;
begin
  with Collection as TTagCollection do
    if Assigned(OnItemChange) then
      OnItemChange(Self);
end;

function TTagCollectionItem.GetDisplayName: AnsiString;
begin
  if FTag = nil then
    Result := SEmpty
  else
    Result := FTag.Name;
end;

procedure TTagCollectionItem.Loaded;
begin
  // called when collection owner is completly loaded.
  // use this to do some actions that need to be
  // run only when object is loaded
end;

procedure TTagCollectionItem.WriteFaultCallBack(Sender: TObject);
begin
  TagChangeCallBack(Self);
end;

procedure TTagCollectionItem.TagChangeCallBack(Sender: TObject);
begin
  with Collection as TTagCollection do
    if Assigned(OnValuesChange) then
      OnValuesChange(Self);
end;

procedure TTagCollectionItem.RemoveTagCallBack(Sender: TObject);
begin
  if FTag = Sender then
    FTag := nil;
end;

function TTagCollectionItem.QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))} stdcall{$ELSE}cdecl{$IFEND};
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TTagCollectionItem._AddRef: Longint;{$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))} stdcall{$ELSE}cdecl{$IFEND};
begin
  Result := -1;
end;

function TTagCollectionItem._Release: Longint; {$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))} stdcall{$ELSE}cdecl{$IFEND};
begin
  Result := -1;
end;

//******************************************************************************
// TTagCollection
//******************************************************************************

constructor TTagCollection.Create(AItemClass: TCollectionItemClass);
begin
  inherited Create(AItemClass);
end;

function TTagCollection.GetComponentState: TComponentState;
begin
  NeedCurrentCompState;
  Result := FComponentState;
end;

procedure TTagCollection.NeedCurrentCompState;
begin
  if Assigned(FOnNeedCompState) then
    FOnNeedCompState(FComponentState);
end;

procedure TTagCollection.Loaded;
var
  i: Longint;
begin
  for i := 0 to Count - 1 do
    TTagCollectionItem(Items[i]).Loaded;
end;

end.

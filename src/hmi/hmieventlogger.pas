unit HMIEventLogger;

{$mode ObjFPC}
{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, PLCTag,
  Tag, ProtocolTypes, HMIDBConnection;

type

  { TEventCollectionItem }

  TEventCollectionItem = class(TCollectionItem)
  private
    FEventColor: TColor;
    FEventDescription: string;
    FEventValue: Integer;
    procedure SetEventColor(AValue: TColor);
    procedure SetEventDescription(AValue: string);
    procedure SetEventValue(AValue: Integer);
  protected
    function GetDisplayName: string; override;
  published
    property EventDescription: string read FEventDescription write SetEventDescription;
    property EventValue: Integer read FEventValue write SetEventValue;
    property EventColor: TColor read FEventColor write SetEventColor;
  end;

  { TEventCollection }

  TEventCollection = class(TOwnedCollection)
  public
    function Add: TEventCollectionItem;
    constructor Create(AOwner: TPersistent);
  end;

  { TEventTagColletionItem }

  TEventTagColletionItem = class(TCollectionItem)
  private
    FIgnoreDescriptionList: Boolean;
    FLastEventGUID: TGuid;
    FLastEventIntID: Int64;
    FLastEventPointerID: Pointer;
    FLastTagValue: Double;
    FPendingUpdate: Boolean;
    FPLCTag: TPLCTag;
    FTagDesc: string;
    FTagID: Integer;
    FTagPath: string;
    FLastValueInitialized: Boolean;
    procedure SetLastTagValue(AValue: Double);
    procedure SetPLCTag(AValue: TPLCTag);
    procedure SetTagDesc(AValue: string);
    procedure SetTagID(AValue: Integer);
    procedure SetTagPath(AValue: string);
  protected
    function GetDisplayName: string; override;
  public
    property LastEventGUID: TGuid read FLastEventGUID write FLastEventGUID;
    property LastEventPointerID: Pointer read FLastEventPointerID write FLastEventPointerID;
    property LastEventIntID: Int64 read FLastEventIntID write FLastEventIntID;
    property LastTagValue: Double read FLastTagValue write SetLastTagValue;
    property PendingUpdate: Boolean read FPendingUpdate write FPendingUpdate;
    function LastValueInitialized: Boolean;
  published
    property PLCTag: TPLCTag read FPLCTag write SetPLCTag;
    property TagID: Integer read FTagID write SetTagID;
    property TagPath: string read FTagPath write SetTagPath;
    property TagDesc: string read FTagDesc write SetTagDesc;
    property IgnoreDescriptionList: Boolean read FIgnoreDescriptionList write FIgnoreDescriptionList;
  end;

  { TEventTagColletion }

  TEventTagColletion = class(TOwnedCollection)
  public
    function Add: TEventTagColletionItem;
    constructor Create(AOwner: TPersistent);
  end;

  TTagEventFinished = procedure(Sender: TObject; EventIntID: Int64; EventGUID: TGuid; var FinishEventSQL: string) of object;
  TFinishAllTagEvents = procedure(Sender: TObject; var FinishAllEventsSQL: string) of object;
  TNewTagEvent = procedure(Sender: TObject; TagItem: TEventTagColletionItem; EventIntID: Int64; EventGUID: TGuid; EventDesc: TEventCollectionItem; var NewTagEventSQL: THMIDBConnectionStatementList) of object;
  TGenerateNewEventID = function(var EventIntID: Int64; var EventGUID: TGuid): Boolean of object;

  { THMIEventLogger }

  THMICustomEventLogger = class(TComponent)
  private
    FAsyncDBConnection: THMIDBConnection;
    FCurrentEventTimestamp: TDateTime;
    FEventDescriptions: TEventCollection;
    FEventTags: TEventTagColletion;
    FOnFinishAllTagEvents: TFinishAllTagEvents;
    FOnGenerateNewEventID: TGenerateNewEventID;
    FOnNewTagEvent: TNewTagEvent;
    FOnTagEventFinished: TTagEventFinished;
    FInternalEventIDCounter: Integer;
    procedure SetAsyncDBConnection(AValue: THMIDBConnection);
    procedure SetEventDescriptions(AValue: TEventCollection);
    procedure SetEventTags(AValue: TEventTagColletion);
    procedure TagChangedDelayed;
    procedure TagChangedDelayed2(Data: PtrInt);
    procedure TagFromListChanged(Sender: TObject);
    procedure FinishAllEventsDelayed;
  protected
    procedure FinishCurrentEvent(aItem: TEventTagColletionItem);
    procedure Loaded; override;
    procedure DoTagEventFinished(Sender: TObject; EventIntID: Int64; EventGUID: TGuid; var FinishEventSQL: string); virtual;
    procedure DoFinishAllTagEvents(Sender: TObject; var FinishAllEventsSQL: string); virtual;
    procedure DoNewTagEvent(Sender: TObject; TagItem: TEventTagColletionItem; EventIntID: Int64; EventGUID: TGuid; EventDesc: TEventCollectionItem; var NewEventSQL: THMIDBConnectionStatementList); virtual;
    function GenerateNewEventID(var EventIntID: Int64; var EventGUID: TGuid): Boolean; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  published
    property AsyncDBConnection: THMIDBConnection read FAsyncDBConnection write SetAsyncDBConnection;
    property EventDescriptions: TEventCollection read FEventDescriptions write SetEventDescriptions;
    property EventTags: TEventTagColletion read FEventTags write SetEventTags;
  protected
    property OnTagEventFinished: TTagEventFinished read FOnTagEventFinished write FOnTagEventFinished;
    property OnFinishAllTagEvents: TFinishAllTagEvents read FOnFinishAllTagEvents write FOnFinishAllTagEvents;
    property OnNewTagEvent: TNewTagEvent read FOnNewTagEvent write FOnNewTagEvent;
    property OnGenerateNewEventID: TGenerateNewEventID read FOnGenerateNewEventID write FOnGenerateNewEventID;
    property CurrentEventTimestamp: TDateTime read FCurrentEventTimestamp;
  end;

  THMIEventLogger = class(THMICustomEventLogger)
  published
    property OnTagEventFinished;
    property OnFinishAllTagEvents;
    property OnNewTagEvent;
    property OnGenerateNewEventID;
    property CurrentEventTimestamp;
  end;


implementation


{ TEventCollectionItem }

procedure TEventCollectionItem.SetEventColor(AValue: TColor);
begin
  if FEventColor = AValue then Exit;
  FEventColor := AValue;
end;

procedure TEventCollectionItem.SetEventDescription(AValue: string);
begin
  if FEventDescription = AValue then Exit;
  FEventDescription := AValue;
end;

procedure TEventCollectionItem.SetEventValue(AValue: Integer);
begin
  if FEventValue = AValue then Exit;
  FEventValue := AValue;
end;

function TEventCollectionItem.GetDisplayName: string;
begin
  Result := FEventValue.ToString + '="' + FEventDescription + '" (' + ColorToString(FEventColor) + ')';
end;

{ TEventCollection }

function TEventCollection.Add: TEventCollectionItem;
begin
  //Result:=TEventCollectionItem.Create(Self);
  Result := TEventCollectionItem(inherited Add);
end;

constructor TEventCollection.Create(AOwner: TPersistent);
begin
  //inherited Create(TEventCollectionItem);
  inherited Create(AOwner, TEventCollectionItem);
end;

{ TEventTagColletionItem }

procedure TEventTagColletionItem.SetPLCTag(AValue: TPLCTag);
begin
  if FPLCTag = AValue then Exit;

  if Collection.Owner is THMICustomEventLogger then
  begin
    if Assigned(FPLCTag) then
    begin
      FPLCTag.RemoveAllHandlersFromObject(Collection.Owner as THMICustomEventLogger);
      (Collection.Owner as THMICustomEventLogger).RemoveFreeNotification(FPLCTag);
    end;

    if Assigned(AValue) and ((((Collection as TOwnedCollection).Owner as TComponent).ComponentState * [csReading, csLoading]) = []) then
    begin
      AValue.AddTagChangeHandler(@THMICustomEventLogger(Collection.Owner).TagFromListChanged);
      (Collection.Owner as THMICustomEventLogger).FreeNotification(AValue);
    end;
  end;

  FPLCTag := AValue;
end;

procedure TEventTagColletionItem.SetLastTagValue(AValue: Double);
begin
  if FLastValueInitialized and (FLastTagValue = AValue) then Exit;
  FLastTagValue := AValue;
  FLastValueInitialized := True;
end;

procedure TEventTagColletionItem.SetTagDesc(AValue: string);
begin
  if FTagDesc = AValue then Exit;
  FTagDesc := AValue;
end;

procedure TEventTagColletionItem.SetTagID(AValue: Integer);
begin
  if FTagID = AValue then Exit;
  FTagID := AValue;
end;

procedure TEventTagColletionItem.SetTagPath(AValue: string);
begin
  if FTagPath = AValue then Exit;
  FTagPath := AValue;
end;

function TEventTagColletionItem.GetDisplayName: string;
begin
  Result := IntToStr(FTagID) + ' = ' + FTagDesc + ' (';
  if Assigned(FPLCTag) then
  begin
    if String(PLCTag.Name).IsEmpty then
      Result := Result + '<empty name>'
    else
      Result := Result + FPLCTag.Name;
  end
  else
    Result := Result + '<Nil>';

  Result := Result + ')';
end;

function TEventTagColletionItem.LastValueInitialized: Boolean;
begin
  Exit(FLastValueInitialized);
end;

{ TEventTagColletion }

function TEventTagColletion.Add: TEventTagColletionItem;
begin
  Result := TEventTagColletionItem(inherited Add);
end;

constructor TEventTagColletion.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TEventTagColletionItem);
end;

{ THMICustomEventLogger }

procedure THMICustomEventLogger.SetEventDescriptions(AValue: TEventCollection);
begin
  if Assigned(FEventDescriptions) then
    FEventDescriptions.Assign(AValue);
end;

procedure THMICustomEventLogger.SetAsyncDBConnection(AValue: THMIDBConnection);
begin
  if FAsyncDBConnection = AValue then Exit;

  if Assigned(FAsyncDBConnection) then
  begin
    FAsyncDBConnection.RemoveFreeNotification(self);
  end;

  if Assigned(AValue) then
    AValue.FreeNotification(self);

  FAsyncDBConnection := AValue;
end;

procedure THMICustomEventLogger.SetEventTags(AValue: TEventTagColletion);
begin
  if Assigned(FEventTags) then
    FEventTags.Assign(AValue);
end;

procedure THMICustomEventLogger.TagChangedDelayed;
var
  AuxItem: TEventTagColletionItem;
  i: Integer;
begin
  if Assigned(FEventTags) then
  begin
    for i := 0 to FEventTags.Count - 1 do
    begin
      AuxItem := TEventTagColletionItem(FEventTags.Items[i]);
      if Assigned(AuxItem.PLCTag) then
      begin
        if AuxItem.PendingUpdate then
        begin
          TagFromListChanged(AuxItem.PLCTag);
        end;
      end
      else
        AuxItem.PendingUpdate := False;
    end;
  end;
end;

procedure THMICustomEventLogger.TagChangedDelayed2(Data: PtrInt);
begin
  TagFromListChanged(TObject(Data));
end;

procedure THMICustomEventLogger.TagFromListChanged(Sender: TObject);
var
  i: Integer;
  j: Integer;
  AuxItem: TEventTagColletionItem;
  TagValue: Int64;
  NewIntID: Int64;
  AuxReal: Double;
  AuxItemEvt: TEventCollectionItem;
  NewGUID: TGuid;
  SQL: string;
  SQLCmds: THMIDBConnectionStatementList;
  B: Boolean;
  A: Boolean;
  C1: Boolean;
begin
  if ([csReading, csLoading] * ComponentState <> []) then
    Exit;

  if Assigned(FEventTags) then
  begin
    for i := 0 to FEventTags.Count - 1 do
    begin
      AuxItem := TEventTagColletionItem(FEventTags.Items[i]);
      if Assigned(AuxItem.PLCTag) and (AuxItem.PLCTag = Sender) then
      begin
        AuxReal := (AuxItem.PLCTag as ITagNumeric).GetValue;
        try
          if AuxItem.LastValueInitialized and (AuxReal = AuxItem.LastTagValue) then
            Exit;

          TagValue := trunc(AuxReal);
          FCurrentEventTimestamp := Now;

          FinishCurrentEvent(AuxItem);

          for j := 0 to FEventDescriptions.Count - 1 do
          begin
            AuxItemEvt := TEventCollectionItem(FEventDescriptions.Items[j]);
            if (AuxItemEvt.EventValue = TagValue) or ((AuxItem.FIgnoreDescriptionList) and ([csDesigning] * ComponentState = [])) then
            begin
              if not GenerateNewEventID(NewIntID, NewGUID) then Exit;
              try
                SQLCmds := THMIDBConnectionStatementList.Create;
                DoNewTagEvent(AuxItem.PLCTag, AuxItem, NewIntID, NewGUID, AuxItemEvt, SQLCmds);
                A := Assigned(FAsyncDBConnection);
                B := FAsyncDBConnection.Connected;
                C1 := (SQLCmds.Count > 0);
                if A and B and C1 then
                begin
                  FAsyncDBConnection.ExecTransaction(SQLCmds, nil, True, False);
                  AuxItem.PendingUpdate := False;
                end
                else
                begin
                  FreeAndNil(SQLCmds);
                  if FAsyncDBConnection.Connected = False then
                  begin
                    AuxItem.PendingUpdate := True;
                    AuxItem.FLastValueInitialized := False;
                    Application.QueueAsyncCall(@TagChangedDelayed2, PtrInt(Sender));
                  end;
                end;
                Exit;
              finally
                AuxItem.LastEventGUID := NewGUID;
                AuxItem.LastEventIntID := NewIntID;
              end;
              Break;
            end;
          end;
        finally
          if not AuxItem.PendingUpdate then
            AuxItem.LastTagValue := AuxReal;
        end;
      end;
    end;
  end;
end;

procedure THMICustomEventLogger.FinishAllEventsDelayed;
var
  SQL: string;
begin
  DoFinishAllTagEvents(self, SQL);
  if Assigned(FAsyncDBConnection) and FAsyncDBConnection.Connected then
    FAsyncDBConnection.ExecSQL(SQL, nil, False);
end;

procedure THMICustomEventLogger.FinishCurrentEvent(aItem: TEventTagColletionItem);
var
  AuxItem: TEventTagColletionItem;
  SQL: string;
begin
  AuxItem := aItem;
  if (not IsEqualGUID(AuxItem.LastEventGUID, GUID_NULL)) or (AuxItem.LastEventIntID <> 0) or Assigned(AuxItem.LastEventPointerID) then
  begin
    DoTagEventFinished(AuxItem.PLCTag, AuxItem.LastEventIntID, AuxItem.LastEventGUID, SQL);
    if Assigned(FAsyncDBConnection) and FAsyncDBConnection.Connected and not SQL.Trim.IsEmpty then
      FAsyncDBConnection.ExecSQL(SQL, nil, False);
    AuxItem.LastEventGUID := GUID_NULL;
    AuxItem.LastEventIntID := 0;
    AuxItem.LastEventPointerID := nil;
  end;
end;

procedure THMICustomEventLogger.Loaded;
var
  i: Integer;
  AuxItem: TEventTagColletionItem;
begin
  inherited Loaded;

  if Assigned(FEventTags) then
  begin
    for i := 0 to FEventTags.Count - 1 do
    begin
      AuxItem := TEventTagColletionItem(FEventTags.Items[i]);
      if Assigned(AuxItem.PLCTag) then
      begin
        AuxItem.PLCTag.FreeNotification(self);
        AuxItem.PLCTag.AddTagChangeHandler(@TagFromListChanged);
      end;
    end;
  end;

  TThread.ForceQueue(nil, @FinishAllEventsDelayed);
end;

procedure THMICustomEventLogger.DoTagEventFinished(Sender: TObject; EventIntID: Int64; EventGUID: TGuid; var FinishEventSQL: string);
begin
  if Assigned(FOnTagEventFinished) then
    FOnTagEventFinished(Sender, EventIntID, EventGUID, FinishEventSQL);
end;

procedure THMICustomEventLogger.DoFinishAllTagEvents(Sender: TObject; var FinishAllEventsSQL: string);
begin
  if Assigned(FOnFinishAllTagEvents) then
    FOnFinishAllTagEvents(Sender, FinishAllEventsSQL);
end;

procedure THMICustomEventLogger.DoNewTagEvent(Sender: TObject; TagItem: TEventTagColletionItem; EventIntID: Int64; EventGUID: TGuid; EventDesc: TEventCollectionItem; var NewEventSQL: THMIDBConnectionStatementList);
begin
  if Assigned(FOnNewTagEvent) then
    FOnNewTagEvent(Sender, TagItem, EventIntID, EventGUID, EventDesc, NewEventSQL);
end;

function THMICustomEventLogger.GenerateNewEventID(var EventIntID: Int64; var EventGUID: TGuid): Boolean;
begin
  Result := False;
  if Assigned(FOnGenerateNewEventID) then
    Result := FOnGenerateNewEventID(EventIntID, EventGUID)
  else
  begin
    Inc(FInternalEventIDCounter);
    EventIntID := FInternalEventIDCounter;

    CreateGUID(EventGUID);
    Exit(True);
  end;
end;

constructor THMICustomEventLogger.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEventTags := TEventTagColletion.Create(self);
  FEventDescriptions := TEventCollection.Create(self);
end;

destructor THMICustomEventLogger.Destroy;
var
  AuxItem: TEventTagColletionItem;
  i: Integer;
begin
  if Assigned(FEventDescriptions) then
    FreeAndNil(FEventDescriptions);

  AsyncDBConnection := nil; //release the connection

  if Assigned(FEventTags) then
  begin
    for i := FEventTags.Count - 1 downto 0 do
    begin
      AuxItem := TEventTagColletionItem(FEventTags.Items[i]);
      if Assigned(AuxItem.PLCTag) then
      begin
        AuxItem.PLCTag.RemoveFreeNotification(self);
      end;
    end;
    FreeAndNil(FEventTags);
  end;

  inherited Destroy;
end;

procedure THMICustomEventLogger.Notification(AComponent: TComponent; Operation: TOperation);
var
  AuxItem: TEventTagColletionItem;
  i: Integer;
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FEventTags) then
  begin
    if AComponent = FAsyncDBConnection then
    begin
      FAsyncDBConnection := nil;
      Exit;
    end;

    for i := FEventTags.Count - 1 downto 0 do
    begin
      AuxItem := TEventTagColletionItem(FEventTags.Items[i]);
      if (AuxItem.PLCTag = AComponent) and Assigned(AuxItem.PLCTag) then
      begin
        AuxItem.FPLCTag := nil;
        //TODO finish the active event?
        FEventTags.Delete(i);
      end;
    end;
  end;
end;

end.

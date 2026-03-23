{$i ../common/language.inc}
{$I ../common/delphiver.inc}
{:
  @abstract(Implements the base class of tags.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Avoid the use of Linux-Widget if fpc >= 2.7.1 (CONSOLEPASCALSCADA)
  @author(Juanjo Montero <juanjo.montero@gmail.com>)

  02/2019 - Use a single implementation to all targets and cut off GUI
            dependency (LCL) and the need of source defines
            (CONSOLEPASCALSCADA).
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  ***********************************************************************


}
unit Tag;

interface

uses
  SysUtils, Classes, crossthreads, MessageSpool, CrossEvent;

  {$IFNDEF FPC}
const
  PM_ASYNCVALUECHANGE = WM_USER + $0123;
  {$ENDIF}


type
  //: Defines the the update rate range of tags.
  TRefreshTime = 1..$7FFFFFFF;

  //: Dynamic array of double.
  TArrayOfDouble = array of Double;

  //: Points to a array of doubles.
  PArrayOfDouble = ^TArrayOfDouble;

  {: Enumerates all tag data types.
  @value(pttDefault  Word length and data type variable.)
  @value(pttShortInt Signed LongInt, 8 bits sized.)
  @value(pttByte     Unsigned LongInt, 8 bits sized.)
  @value(pttSmallInt Signed LongInt, 16 bits sized.)
  @value(pttWord,    Unsigned LongInt, 16 bits sized.)
  @value(pttLongInt  Signed LongInt, 32 bits sized.)
  @value(pttDWord,   Unsigned LongInt, 32 bits sized.)
  @value(pttFloat    Float, 32 bits sized.)
  @value(pttInt64    Signed LongInt, 64 bits sized)
  @value(pttQWord    Unsigned LongInt, 64 bits sized)
  @value(pttDouble   Float, 64 bits sized.) }
  TTagType = (
    pttDefault,                     // size variable
    pttShortInt, pttByte,           // 8 bits
    pttSmallInt, pttWord,           // 16 bits
    pttLongInt, pttDWord, pttFloat, // 32 bits
    pttInt64, pttQWord, pttDouble   // 64 bits
    );

  {: Enumerates all commands accept by the tag.
  @value(tcScanRead        Values are read using the driver scan.)
  @value(tcScanWrite       Values are write using the driver scan.)
  @value(tcRead            Values are read synchronous (without driver scan).)
  @value(tcWrite           Values are write synchronous (without driver scan).)
  @value(tcInternalUpdate  Internal tag update command.) }
  TTagCommand = (tcScanRead, tcScanWrite, tcRead, tcWrite, tcInternalUpdate, tcSingleScanRead);

  {: Enumerates all results that can be returned by the protocol driver to a
     read/write request of a tag.

  @value(ioDriverError            Internal driver error.)
  @value(ioCommError              Communication error.)
  @value(ioOk                     Sucessfull request.)
  @value(ioTimeout                Communication timeout.)
  @value(ioIllegalFunction        Invalid IO function.)
  @value(ioIllegalRegAddress      Invalid memory address.)
  @value(ioIllegalRegSize         Invalid memory size.)
  @value(ioIllegalValue           Invalid value.)
  @value(ioPLCError               Device error.)
  @value(ioTagError               Internal tag error.)
  @value(ioNullDriver             Tag without a driver.)
  @value(ioIllegalStationAddress  Invalid device address.)
  @value(ioIllegalRequest         The request is invalid or not supported.)
  @value(ioObjectNotExists        The requested object doesn't exists.)
  @value(ioIllegalMemoryAddress   The request is out of bound of the memory space of device.)
  @value(ioUnknownError           A invalid error code was returned.)
  @value(ioEmptyPacket            A empty packet was returned.)
  @value(ioPartialOk              An action was partially successful.) }
  TProtocolIOResult = (ioNone, ioOk, ioDriverError, ioCommError, ioTimeOut,
    ioIllegalFunction, ioIllegalRegAddress, ioIllegalValue,
    ioPLCError, ioTagError, ioNullDriver, ioIllegalRequest,
    ioIllegalStationAddress, ioObjectNotExists,
    ioObjectAccessNotAllowed, ioIllegalMemoryAddress, ioNACK,
    ioUnknownError, ioEmptyPacket, ioPartialOk, ioBusy,
    ioAcknowledge, ioMemoryParityError, ioIllegalRegSize,
    ioGatewayUnavailable, ioDeviceGatewayFailedToRespond,
    ioReadOnlyProtocol, ioCommPortClosed, ioNullCommPort,
    ioConnectPLCFailed, ioAdapterInitFail, ioNullTagBlock);

  {: Callback called by the protocol driver (TProtocolDriver) to return the result
     of an request and theirs values.
  @param(ReqID LongWord: The ScanRead/ScanWrite request id.)
  @param(Values TArrayOfDouble: Array with the values read/written.)
  @param(ValuesTimeStamp TDateTime: Date/Time when these values are read/written.)
  @param(TagCommand TTagCommand: Command type.)
  @param(LastResult TProtocolIOResult: I/O result after process this request.)
  @param(Offset Cardinal: Block Offset.) }
  TTagCommandCallBack = procedure(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDateTime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; OffSet: Longint) of object;

  {: Struture used internaly by the protocolo driver (TProtocolDriver) to process
     read and write requests. Represents the configuration of the tag being
     processed.
  @member Rack Value of PLCRack property.
  @member Slot Value of PLCSlot property.
  @member Station Value of PLCStation property.
  @member File_DB Value of MemFile_DB property.
  @member Address Value of MemAddress property.
  @member SubElement Value of MemSubElement property.
  @member Size Value of Size (Block tags) property.
  @member OffSet Index inside the block (Block Tags).
  @member Path Value of LongAddress property.
  @member ReadFunction Value of MemReadFunction property.
  @member WriteFunction Value of MemWriteFunction property.
  @member Retries Value of Retries property.
  @member UpdateTime Value of UpdateTime property.
  @member CallBack Procedure called when the request is done to return the data of the request. }
  TTagRec = record
    ID: Longword;
    Rack: Longint;
    Slot: Longint;
    Station: Longint;
    File_DB: Longint;
    Address: Longint;
    SubElement: Longint;
    Size: Longint;
    Count: Longint;
    OffSet: Longint;
    RealOffset: Longint;
    Path: AnsiString;
    ReadFunction: Longint;
    WriteFunction: Longint;
    Retries: Longint;
    UpdateTime: Longint;
    CallBack: TTagCommandCallBack;
  end;

  //: Points to a tag structure
  PTagRec = ^TTagRec;

  TTagNotificationList = array of TNotifyEvent;

  //: Interface of management of unique tag identification
  IManagedTagInterface = interface
    ['{5CC728FD-B75F-475E-BDE7-07A862B6B2B6}']
    //: Forces the tag to rebuild their identification to make it unique
    procedure RebuildTagGUID;
  end;

  //: Tag scan interface. Used by the protocol driver to know when a tag must be updated
  IScanableTagInterface = interface
    ['{6D57805C-D779-4607-BDA5-DF8A68F49973}']
    //: Tells how many time has elapsed from the last update of tag value
    function RemainingMiliseconds: Int64;
    //: Tells how many time has elapsed from the last scan of tag
    function RemainingMilisecondsForNextScan: Int64;
    //: Tells if the tag is set properly
    function IsValidTag: Boolean;
    //: Tells if callback belongs to the tag
    function IsMyCallBack(Cback: TTagCommandCallBack): Boolean;
    //: Sets the tag as valid or not
    procedure SetTagValidity(TagValidity: Boolean);
    //: Gets a structure with informations about the tag
    procedure BuildTagRec(out tr: TTagRec; Count, OffSet: Longint);

    function GetLastUpdateTimestamp: TDateTime;

    function GetUpdateTime: Int64;
  end;

  TASyncValueChangeNotify = procedure(Sender: TObject; const Value: TArrayOfDouble) of object;
  TASyncStringValueChange = procedure(Sender: TObject; const Value: AnsiString) of object;

{$IFNDEF FPC}
  TLMessage = TMessage;
  PtrInt = Longint;
{$ENDIF}

  TDelayedAsyncCaller = class(TpSCADACoreAffinityThreadWithLoop)
  private
    MsgQueue: TThreadList;
    ASomethingToDoEvt: TCrossEvent;
  protected
    procedure Loop; override;
  public
    constructor Create(CreateSuspended: Boolean; const StackSize: SizeUInt = DefaultStackSize);
    destructor Destroy; override;
    procedure QueueAsyncCall(AProc: TThreadMethod);
    procedure RemoveAllHandlesOfObj(AnObject: TObject);
  end;

  //: Base class for all tags
  TTag = class(TComponent)
  private
    FQueuedData: TList;
    procedure ASyncMethod(); virtual;
  protected
    FReadOKNotificationList: TTagNotificationList;
    FReadFaultNotificationList: TTagNotificationList;
    FWriteOKNotificationList: TTagNotificationList;
    FWriteFaultNotificationList: TTagNotificationList;
    FChangeNotificationList: TTagNotificationList;
    FTagRemovalNotificationList: TTagNotificationList;

    //: Call the assynchronous tag value change.
    procedure AsyncNotifyChange(Data: Pointer); virtual;
    //: Return a copy of the Tag value for each assynchronous event calls.
    function GetValueChangeData: Pointer; virtual;
    //: Release a copy of a tag value of one assynchronous event call.
    procedure ReleaseChangeData(Data: Pointer); virtual;
  protected
    //: Stores if the tag will be updated automatically.
    PAutoRead: Boolean;
    //: Stores if the tag will write their value automatically.
    PAutoWrite: Boolean;

    //: Stores the counter of failed reads.
    PCommReadErrors: Cardinal;
    //: Stores the counter of successful reads.
    PCommReadOK: Cardinal;
    //: Stores the counter of failed writes.
    PCommWriteErrors: Cardinal;
    //: Stores the counter of successful writes.
    PCommWriteOk: Cardinal;

    //: Stores the device Rack number of the tag.
    PRack: Cardinal;
    //: Stores the device Slot number of the tag.
    PSlot: Cardinal;
    //: Stores the device Station address of the tag.
    PStation: Cardinal;
    //: Stores the File/DB number of the tag.
    PFile_DB: Cardinal;
    //: Stores the device memory address of the tag.
    PAddress: Cardinal;
    //: Stores the device sub-memory address of the tag.
    PSubElement: Cardinal;
    //: Stores how many memories are being mapped.
    PSize: Cardinal;
    //: Stores the textual memory address of the tag.
    PPath: AnsiString;
    //: Stores the function code to read the values of the tag.
    PReadFunction: Cardinal;
    //: Stores the function code to write the values of the tag.
    PWriteFunction: Cardinal;
    //: Stores the
    PRetries: Cardinal;
    //: Stores the update time of the tag.
    PUpdateTime: TRefreshTime;

    //: Stores the event to be called when a read has success.
    POnReadOk: TNotifyEvent;
    //: Stores the event to be called when a read fail occurs.
    POnReadFail: TNotifyEvent;
    //: Stores the event to be called when a value is written successfully on device.
    POnWriteOk: TNotifyEvent;
    //: Stores the event called when a write of tag value has a failed.
    POnWriteFail: TNotifyEvent;
    //: Stores the event called when the tag value changes, BEFORE notify the dependents of the tag.
    POnValueChangeFirst: TNotifyEvent;
    //: Stores the event called when the tag value changes, AFTER notify the dependents of the tag.
    POnValueChangeLast: TNotifyEvent;
    //: Stores asynchronous event that notifies when the tag value changes.
    POnAsyncValueChange: TASyncValueChangeNotify;
    //: Stores the event called when the tag value was updated.
    POnUpdate: TNotifyEvent;

    //: Stores the unique tag identification.
    PGUID: AnsiString;
    //: First tag update? so fires
    PFirstUpdate: Boolean;

    //: Notifies when a successful read occurs.
    procedure NotifyReadOk;
    //: Notifies when a read fault occurs.
    procedure NotifyReadFault;
    //: Notifies when the tag value was updated.
    procedure NotifyUpdate;
    //: Notifies when a successful write occurs.
    procedure NotifyWriteOk;
    //: Notifies when a write fault occurs.
    procedure NotifyWriteFault;
    //: Notifies when the tag value changes.
    procedure NotifyChange;

    //: Increments the counter of successful reads.
    procedure IncCommReadOK(Value: Cardinal);
    //: Increments the counter of faulted reads.
    procedure IncCommReadFaults(Value: Cardinal);
    //: Increments the counter of successful writes.
    procedure IncCommWriteOK(Value: Cardinal);
    //: Increments the counter of faulted writes.
    procedure IncCommWriteFaults(Value: Cardinal);

    //: If @true, the tag will be updated automaticaly.
    property AutoRead: Boolean read PAutoRead;
    {: If @true, all values written on tags will be automaticaly written on the
    the memory of the linked device. }
    property AutoWrite: Boolean read PAutoWrite;

    //: Tell how many read errors occurred.
    // added the possibility of reset the comm error count
    property CommReadErrors: Cardinal read PCommReadErrors write PCommReadErrors;
    //: Tells the count of successful reads.
    property CommReadsOK: Cardinal read PCommReadOK;
    //: Tell how many write errors occurred.
    property CommWriteErrors: Cardinal read PCommWriteErrors;
    //: Tells the count of successful writes
    property CommWritesOk: Cardinal read PCommWriteOk;

    {: Device Rack that contains the memory being mapped, if applicable.
       @seealso(TISOTCPDriver)
       @seealso(TISOTCPDriver.PLCRack) }
    property PLCRack: Cardinal read PRack;
    {: Device Slot that contains the memory being mapped, if applicable.
       @seealso(TISOTCPDriver)
       @seealso(TISOTCPDriver.PLCSlot) }
    property PLCSlot: Cardinal read PSlot;
    {: Device address that contains the memory being mapped, if applicable.
       @seealso(TISOTCPDriver)
       @seealso(TISOTCPDriver.PLCStation)     }
    property PLCStation: Cardinal read PStation;

    //: Device File/DB that contains the memory being mapped, if applicable.
    property MemFile_DB: Cardinal read PFile_DB;
    //: The address of the memory being mapped.
    property MemAddress: Cardinal read PAddress;
    //: The sub-memory address, if applicable.
    property MemSubElement: Cardinal read PSubElement;
    //: Protocol driver function that will read the memory being mapped.
    property MemReadFunction: Cardinal read PReadFunction;
    //: Protocol driver function that will write values in the memory being mapped.
    property MemWriteFunction: Cardinal read PWriteFunction;
    //: Number of retries of read/write of this memory.
    property Retries: Cardinal read PRetries;
    //: Update time of the tag, in milliseconds.
    property RefreshTime: TRefreshTime read PUpdateTime stored False;
    //: Update time of the tag, in milliseconds.
    property UpdateTime: TRefreshTime read PUpdateTime;
    //: Number of memories being mapped, if applicable.
    property Size: Cardinal read PSize;
    //: Long address (text), if supported by the protocol driver.
    property LongAddress: AnsiString read PPath;

    //: Event called to notify when a successful read occurs.
    property OnReadOK: TNotifyEvent read POnReadOk write POnReadOk;
    //: Event called when a read fault occurs.
    property OnReadFail: TNotifyEvent read POnReadFail write POnReadFail;
    //: Event called to notify when a write of the tag value has success.
    property OnWriteOk: TNotifyEvent read POnWriteOk write POnWriteOk;
    //: Event called when a write fault occurs.
    property OnWriteFail: TNotifyEvent read POnWriteFail write POnWriteFail;
    //: Event called when the tag value changes, AFTER notify all tag dependents.
    property OnValueChange: TNotifyEvent read POnValueChangeLast write POnValueChangeLast stored False;
    //: Event called when the tag value changes, AFTER notify all tag dependents.
    property OnValueChangeLast: TNotifyEvent read POnValueChangeLast write POnValueChangeLast;
    //: Event called when the tag value changes, BEFORE notify all tag dependents.
    property OnValueChangeFirst: TNotifyEvent read POnValueChangeFirst write POnValueChangeFirst;
    //: Event called when the tag value was updated.
    property OnUpdate: TNotifyEvent read POnUpdate write POnUpdate;
    //: Asynchronous event called when the tag value changes.
    property OnAsyncValueChange: TASyncValueChangeNotify read POnAsyncValueChange write POnAsyncValueChange;

    function IndexOf(List: TTagNotificationList; AHandler: TNotifyEvent): Integer;
    procedure AddToList(var List: TTagNotificationList; const AHandler: TNotifyEvent);
    procedure DeleteFromList(var List: TTagNotificationList; const AIndex: Integer);
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    procedure AddReadOkHandler(ACallBack: TNotifyEvent);
    procedure AddReadFaultHandler(ACallBack: TNotifyEvent);
    procedure AddWriteOkHandler(ACallBack: TNotifyEvent);
    procedure AddWriteFaultHandler(ACallBack: TNotifyEvent);
    procedure AddTagChangeHandler(ACallBack: TNotifyEvent);
    procedure AddRemoveTagHandler(ACallBack: TNotifyEvent);
    procedure RemoveAllHandlersFromObject(aObject: TObject);

    function CountObjectsLinkedWithTagChangeHandler: Integer;
    function GetObjectLinkedWithTagChangeHandler(Index: Integer): TObject;
    procedure ForceNotifyChange;

    property TagGUID: AnsiString read PGUID;
  end;

  TScanUpdateRec = record
    CallBack: TTagCommandCallBack;
    ValueTimeStamp: TDateTime;
    LastResult: TProtocolIOResult;
    Values: TArrayOfDouble;
  end;

  TArrayOfScanUpdateRec = array of TScanUpdateRec;


function TagSizeInBits(const TagType: TTagType; const pttDefaultSize: Integer): Integer;
procedure QueueAsyncCall(AProc: TThreadMethod);
procedure RemoveAllDelayedCallsOfObj(AnObject: TObject);


implementation


uses
  syncobjs;


function TagSizeInBits(const TagType: TTagType; const pttDefaultSize: Integer): Integer;
var
  SizeInBits: array [Low(TTagType)..High(TTagType)] of Integer = (
    00,         // pttDefault
    08, 08,     // pttShortInt, pttByte,            // 8 bits
    16, 16,     // pttSmallInt, pttWord,            // 16 bits
    32, 32, 32, // pttLongInt,  pttDWord, pttFloat, // 32 bits
    64, 64, 64  // pttInt64,    pttQWord, pttDouble // 64 bits
    );
begin
  SizeInBits[pttDefault] := pttDefaultSize;
  Result := SizeInBits[TagType];
end;

{ TDelayedAsyncCaller }

procedure TDelayedAsyncCaller.Loop;
var
  AList: TList;
  AProc: Pointer;
begin
  if ASomethingToDoEvt.WaitFor(1000) = wrSignaled then
  begin
    AList := MsgQueue.LockList;
    try
      while AList.Count > 0 do
      begin
        ;
        AProc := AList.First;
        AList.Remove(AProc);
        Queue(TThreadMethod(AProc^));
        Dispose(PMethod(AProc));
      end;
      while not ASomethingToDoEvt.ResetEvent do ;
    finally
      MsgQueue.UnlockList;
    end;
  end;
end;

constructor TDelayedAsyncCaller.Create(CreateSuspended: Boolean; const StackSize: SizeUInt);
begin
  inherited Create(CreateSuspended, StackSize);
  MsgQueue := TThreadList.Create;
  MsgQueue.Duplicates := dupAccept;
  ASomethingToDoEvt := TCrossEvent.Create(True, False);
end;

destructor TDelayedAsyncCaller.Destroy;
begin
  Terminate;
  WaitForLoopTerminates;
  FreeAndNil(ASomethingToDoEvt);
  FreeAndNil(MsgQueue);
  RemoveQueuedEvents(Self);
  inherited Destroy;
end;

procedure TDelayedAsyncCaller.QueueAsyncCall(AProc: TThreadMethod);
var
  ARec: PMethod;
begin
  if Assigned(MsgQueue) then
  begin
    New(ARec);
    ARec^ := TMethod(AProc);
    MsgQueue.Add(ARec);
  end;
  while not ASomethingToDoEvt.SetEvent do ;
end;

procedure TDelayedAsyncCaller.RemoveAllHandlesOfObj(AnObject: TObject);
var
  AList: TList;
  AProc: Pointer;
  i: Integer;
begin
  AList := MsgQueue.LockList;
  try
    for i := AList.Count - 1 downto 0 do
    begin
      ;
      AProc := AList.Items[i];
      if TObject(TMethod(AProc^).Data) = AnObject then
        AList.Delete(i);
    end;
  finally
    MsgQueue.UnlockList;
  end;
end;

constructor TTag.Create(AOwner: TComponent);
var
  x: TGuid;
begin
  inherited Create(AOwner);

  FQueuedData := TList.Create;

  PCommReadErrors := 0;
  PCommReadOK := 0;
  PCommWriteErrors := 0;
  PCommWriteOk := 0;
  PUpdateTime := 1000;
  PFirstUpdate := True;

  if ComponentState * [csReading, csLoading] = [] then
  begin
    CreateGUID(x);
    PGUID := UpperCase(GUIDToString(x));
  end;
end;

destructor TTag.Destroy;
var
  i: Longint;
begin
  for i := 0 to high(FTagRemovalNotificationList) do
    FTagRemovalNotificationList[i](Self);

  SetLength(FReadOKNotificationList, 0);
  SetLength(FReadFaultNotificationList, 0);
  SetLength(FWriteOKNotificationList, 0);
  SetLength(FWriteFaultNotificationList, 0);
  SetLength(FChangeNotificationList, 0);
  SetLength(FTagRemovalNotificationList, 0);

  RemoveAllHandlersFromObject(Self);
  for i := FQueuedData.Count - 1 downto 0 do
  begin
    ReleaseChangeData(FQueuedData.Items[i]);
    FQueuedData.Delete(i);
  end;
  FreeAndNil(FQueuedData);

  inherited Destroy;
end;

function TTag.IndexOf(List: TTagNotificationList; AHandler: TNotifyEvent): Integer;
var
  i: Integer;
begin
  if AHandler <> nil then
    for i := 0 to high(List) do
    begin
      if (TMethod(List[i]).Code = TMethod(AHandler).Code) and (TMethod(List[i]).Data = TMethod(AHandler).Data) then
      begin
        Result := i;
        Exit;
      end;
    end;
  Result := -1;
end;

procedure TTag.AddToList(var List: TTagNotificationList; const AHandler: TNotifyEvent);
var
  h: Integer;
begin
  if IndexOf(List, AHandler) = -1 then
  begin
    h := Length(List);
    SetLength(List, h + 1);
    List[h] := AHandler;
  end;
end;

procedure TTag.DeleteFromList(var List: TTagNotificationList; const AIndex: Integer);
var
  h: Integer;
begin
  h := High(List);
  List[AIndex] := List[h];
  SetLength(List, h);
end;

procedure TTag.AddReadOkHandler(ACallBack: TNotifyEvent);
begin
  AddToList(FReadOKNotificationList, ACallBack);
end;

procedure TTag.AddReadFaultHandler(ACallBack: TNotifyEvent);
begin
  AddToList(FReadFaultNotificationList, ACallBack);
end;

procedure TTag.AddWriteOkHandler(ACallBack: TNotifyEvent);
begin
  AddToList(FWriteOKNotificationList, ACallBack);
end;

procedure TTag.AddWriteFaultHandler(ACallBack: TNotifyEvent);
begin
  AddToList(FWriteFaultNotificationList, ACallBack);
end;

procedure TTag.AddTagChangeHandler(ACallBack: TNotifyEvent);
begin
  AddToList(FChangeNotificationList, ACallBack);
end;

procedure TTag.AddRemoveTagHandler(ACallBack: TNotifyEvent);
begin
  AddToList(FTagRemovalNotificationList, ACallBack);
end;

procedure TTag.RemoveAllHandlersFromObject(aObject: TObject);
var
  i: Integer;
begin
  for i := high(FReadOKNotificationList) downto 0 do
  begin
    if TMethod(FReadOKNotificationList[i]).Data = Pointer(aObject) then
    begin
      DeleteFromList(FReadOKNotificationList, i);
    end;
  end;

  for i := high(FReadFaultNotificationList) downto 0 do
  begin
    if TMethod(FReadFaultNotificationList[i]).Data = Pointer(aObject) then
    begin
      DeleteFromList(FReadFaultNotificationList, i);
    end;
  end;

  for i := high(FWriteOKNotificationList) downto 0 do
  begin
    if TMethod(FWriteOKNotificationList[i]).Data = Pointer(aObject) then
    begin
      DeleteFromList(FWriteOKNotificationList, i);
    end;
  end;

  for i := high(FWriteFaultNotificationList) downto 0 do
  begin
    if TMethod(FWriteFaultNotificationList[i]).Data = Pointer(aObject) then
    begin
      DeleteFromList(FWriteFaultNotificationList, i);
    end;
  end;

  for i := high(FChangeNotificationList) downto 0 do
  begin
    if TMethod(FChangeNotificationList[i]).Data = Pointer(aObject) then
    begin
      DeleteFromList(FChangeNotificationList, i);
    end;
  end;

  for i := high(FTagRemovalNotificationList) downto 0 do
  begin
    if TMethod(FTagRemovalNotificationList[i]).Data = Pointer(aObject) then
    begin
      DeleteFromList(FTagRemovalNotificationList, i);
    end;
  end;
end;

function TTag.CountObjectsLinkedWithTagChangeHandler: Integer;
begin
  Result := Length(FChangeNotificationList);
end;

function TTag.GetObjectLinkedWithTagChangeHandler(Index: Integer): TObject;
begin
  if (Index >= 0) and (Index < Length(FChangeNotificationList)) then
  begin
    Result := TObject(TMethod(FChangeNotificationList[Index]).Data);
  end;
end;

procedure TTag.ForceNotifyChange;
begin
  NotifyChange;
end;

procedure TTag.NotifyChange;
var
  i: Longint;
begin
  // Notify the change before notify the dependent objects
  if Assigned(POnValueChangeFirst) then
    POnValueChangeFirst(Self);

  // Notify the dependent objects
  for i := 0 to high(FChangeNotificationList) do
  begin
    FChangeNotificationList[i](Self);
  end;

  // Notify the change after notify the dependent objects
  if Assigned(POnValueChangeLast) then
    POnValueChangeLast(Self);

  if Assigned(POnAsyncValueChange) and Assigned(FQueuedData) then
  begin
    FQueuedData.Add(GetValueChangeData);
    QueueAsyncCall(@ASyncMethod);
  end;
end;

procedure TTag.ASyncMethod();
var
  FUserData: Pointer;
begin
  if Assigned(FQueuedData) and (FQueuedData.Count > 0) then
  begin
    FUserData := FQueuedData.First;
    try
      FQueuedData.Remove(FUserData);
      AsyncNotifyChange(Pointer(FUserData));
    finally
      ReleaseChangeData(Pointer(FUserData));
    end;
  end;
end;

procedure TTag.AsyncNotifyChange(Data: Pointer);
begin
  // does nothing
end;

function TTag.GetValueChangeData: Pointer;
begin
  Result := nil;
end;

procedure TTag.ReleaseChangeData(Data: Pointer);
begin
  // does nothing
end;

procedure TTag.NotifyReadOk;
var
  i: Longint;
begin
  for i := 0 to high(FReadOKNotificationList) do
    FReadOKNotificationList[i](Self);

  if Assigned(POnReadOk) then
    POnReadOk(Self);
end;

procedure TTag.NotifyReadFault;
var
  i: Longint;
begin
  for i := 0 to high(FReadFaultNotificationList) do
    FReadFaultNotificationList[i](Self);

  if Assigned(POnReadFail) then
    POnReadFail(Self);
end;

procedure TTag.NotifyUpdate;
begin
  try
    if Assigned(POnUpdate) then
      POnUpdate(Self)
  finally
  end;
end;

procedure TTag.NotifyWriteOk;
var
  i: Longint;
begin
  for i := 0 to high(FWriteOKNotificationList) do
    FWriteOKNotificationList[i](Self);

  if Assigned(POnWriteOk) then
    POnWriteOk(Self);
end;

procedure TTag.NotifyWriteFault;
var
  i: Longint;
begin
  for i := 0 to high(FWriteFaultNotificationList) do
    FWriteFaultNotificationList[i](Self);

  if Assigned(POnWriteFail) then
    POnWriteFail(Self);
end;

procedure TTag.IncCommReadOK(Value: Cardinal);
begin
  Inc(PCommReadOK, Value);
  if Value > 0 then
    NotifyReadOk;
end;

procedure TTag.IncCommReadFaults(Value: Cardinal);
begin
  Inc(PCommReadErrors, Value);
  if Value > 0 then
    NotifyReadFault;
end;

procedure TTag.IncCommWriteOK(Value: Cardinal);
begin
  Inc(PCommWriteOk, Value);
  if Value > 0 then
    NotifyWriteOk;
end;

procedure TTag.IncCommWriteFaults(Value: Cardinal);
begin
  Inc(PCommWriteErrors, Value);
  if Value > 0 then
    NotifyWriteFault;
end;


var
  DelayedAsyncThread: TDelayedAsyncCaller;

procedure QueueAsyncCall(AProc: TThreadMethod);
begin
  DelayedAsyncThread.QueueAsyncCall(AProc);
end;

procedure RemoveAllDelayedCallsOfObj(AnObject: TObject);
begin
  DelayedAsyncThread.RemoveAllHandlesOfObj(AnObject);
end;


initialization
  DelayedAsyncThread := TDelayedAsyncCaller.Create(True);
  DelayedAsyncThread.Start;


finalization
  DelayedAsyncThread.Terminate;
  FreeAndNil(DelayedAsyncThread);


end.

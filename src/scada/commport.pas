{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit that implements the basis of a communication port driver)
}
unit CommPort;

{$IFDEF FPC}
{$IFDEF DEBUG}
  {$DEFINE FDEBUG}
{$ENDIF}
{$ENDIF}

interface

uses
  Commtypes, Classes, MessageSpool, CrossEvent, SyncObjs, crossthreads
{$IFNDEF FPC}
  , Windows
{$ENDIF}
{$IF defined(WIN32) or defined(WIN64)}
  , windows
{$IFEND}
  ;

type
{$IF defined(WIN32) or defined(WIN64)}
  TPortUniqueID = WINDOWS.LONGLONG;
{$ELSE}
  TPortUniqueID = QWord;
{$IFEND}

  {:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @name notifies the application and protocol drivers when the following events
  occurs on port driver: communication error and when it was open, closed or disconnected.
  This class is used internaly by the TCommPortDriver. }
  TEventNotificationThread = class(TpSCADACoreAffinityThreadWithLoop)
  private
    PMsg: TMSMsg;
    FOwner: TComponent;
    FEvent: Pointer;
    FError: TIOResult;
    FDoSomethingEvent: TCrossEvent;
    FSpool: TMessageSpool;
    procedure DoSomething;
    procedure WaitToDoSomething;

    procedure SyncCommErrorEvent;
    procedure SyncPortEvent;
  protected
    procedure Loop; override;
  public
    constructor Create(CreateSuspended: Boolean; AOwner: TComponent);
    destructor Destroy; override;
    procedure Terminate; override;
    //: Sends a communication error message to application;
    procedure DoCommErrorEvent(Event: TCommPortErrorEvent; Error: TIOResult; MainThread: Boolean);
    //: Sends a port event message (port open, closed or diconnected) to application;
    procedure DoCommPortEvent(Event: TNotifyEvent; MainThread: Boolean);
  end;

  {:
  @abstract(The base class of an communication port driver.)

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  This class was created to reduce the efforts to create new communication port
  drivers, both on single-thread and multi-threads environments.

  To make a minimal usable communication port driver, you must overwrite only
  five virtual methods that do all work (don't forget of the
  properties/procedures/functions particular of your communication port). The
  methods that you must overwrite are this:

  @code(function  ComSettingsOK:Boolean; virtual;)
  Overwrite this function to check if the setting of your communication port are
  rigth.

  @code(procedure PortStart(var Ok:Boolean); virtual;)
  Opens the communication port. If it was open successfully, return true on OK variable.

  @code(procedure PortStop(var Ok:Boolean); virtual;)
  Closes the communication port. If it was closed successfully, return true on OK variable.

  @code(procedure Read(Packet:PIOPacket); virtual; abstract;)
  Overwrite this method to read data of your communication port.

  @code(procedure Write(Packet:PIOPacket); virtual; abstract;)
  Overwrite this method to write data on your communication port.

  After do this, your communication port already is thread-safe! }

  { TCommPortDriver }

  TCommPortDriver = class(TComponent)
  private
    FLogActions: Boolean;
    FReadedLogActions: Boolean;
    FLogFile: AnsiString;
    FLogFileStream: TFileStream;
    FReadRetries: Cardinal;
    FWriteRetries: Cardinal;

    FTrafficReceiver1: AnsiString;
    FTrafficReceiver2: AnsiString;
    FTrafficReceiver: AnsiString;
    FTrafficSend: AnsiString;

    //: @exclude
    PLockedBy: Cardinal;
    //: @exclude
    PPacketID: Cardinal;
    //: @exclude
    FReadActive: Boolean;
    //: @exclude
    PEventUpdater: TEventNotificationThread;
    //: @exclude
    PIOCmdCS: SyncObjs.TCriticalSection;
    PLockCS: SyncObjs.TCriticalSection;
    //: @exclude
    PLockEvent: TCrossEvent;
    //: @exclude
    PUnlocked: Longint;
    //: @exclude
    FLastOSErrorNumber: Longint;
    //: @exclude
    FLastOSErrorMessage: AnsiString;
    //: @exclude
    FLastPkgId: Cardinal;
    //: @exclude
    FCommandsSecond: Longint;
    //: Communication statistics (Bytes sent/received and Bytes sent/received per second).
    FTXBytes: Int64;
    FRXBytes: Int64;
    FTXBytesLast: Int64;
    FRXBytesLast: Int64;
    FTXBytesSecond: Int64;
    FRXBytesSecond: Int64;

    FOwnerThread: TPSThreadID;
    //: Opens the communication port in design time
    //FOpenInEditMode:Boolean;

    //: @exclude
    FOnCommErrorReading: TCommPortErrorEvent;
    //: @exclude
    FOnCommErrorWriting: TCommPortErrorEvent;
    //: @exclude
    FOnCommPortOpened: TNotifyEvent;
    FOnCommPortOpenError: TNotifyEvent;
    //: @exclude
    FOnCommPortClosed: TNotifyEvent;
    FOnCommPortCloseError: TNotifyEvent;
    //: @exclude
    FOnCommPortDisconnected: TNotifyEvent;

    procedure OpenInEditMode(v: Boolean);
    procedure SetReadRetries(AValue: Cardinal);
    procedure SetWriteRetries(AValue: Cardinal);
    //: Updates the communication statistics.
    procedure TimerStatistics(Sender: TObject);
    //: @exclude
    function GetLocked: Boolean;
    //: Executes IO commands (thread-safe).
    procedure InternalIOCommand(Cmd: TIOCommand; Packet: PIOPacket);
    //: Opens the communication port (thread-safe).
    procedure InternalPortStart(var Ok: Boolean);
    //: Closes the communication port (thread-safe).
    procedure InternalPortStop(var Ok: Boolean);
    {: @name is called to do the I/O tasks of the communication port driver.

       @param(cmd TIOCommand. Contains the I/O commands and the sequence of your execution.)
       @param(Packet PIOPacket. Record that contains the information about what
              must be readed and/or write.)
       @return(Returns on variable Packet the result of the I/O's actions.) }
    procedure IOCommand(Cmd: TIOCommand; Packet: PIOPacket);

    //: @seealso(TCommPortDriver.LogIOActions)
    procedure SetLogActions(Log: Boolean);

    //: @seealso(TCommPortDriver.LogFile)
    procedure SetLogFile(NFile: AnsiString);
    //: Register an IO action on communications log.
    procedure LogAction(Cmd: TIOCommand; Packet: TIOPacket);
  protected
    FDelayBetweenCmds: Cardinal;
    //: Stores if the communication port is exclusive (like serial port)
    FExclusiveDevice: Boolean;

    // recolhe trafego de dados
    procedure Traffic(Cmd: TIOCommand; Packet: TIOPacket);

    ////////////////////////////////////////////////////////////////////////////
    //: If v = @true, opens the communication port, else closes.
    procedure SetActive(AValue: Boolean); virtual;
    //: Send a communication error message from the thread to the application.
    procedure CommError(WriteCmd: Boolean; Error: TIOResult);
    //: Sends a message to the application/protocol thread when the communication port was open.
    procedure CommPortOpened;
    //: Sends a message to the application/protocol thread, if communication port can't be open.
    procedure CommPortOpenError;
    //: Sends a message to the application/protocol thread when the communication port was close.
    procedure CommPortClose;
    //: Sends a message to the application/protocol thread, if the communication port can't be closed.
    procedure CommPortCloseError;
    //: Sends a message to the application/protocol thread, if the communication port was disconnected (TCP/IP).
    procedure CommPortDisconected;

    ////////////////////////////////////////////////////////////////////////////
    //: Notifies the OnCommErrorReading event about an read error.
    procedure DoReadError(Error: TIOResult); virtual;
    //: Notifies the OnCommErrorWriting event about an write error.
    procedure DoWriteError(Error: TIOResult); virtual;
    //: Notifies the OnCommPortOpened when the communication port opens.
    procedure DoPortOpened(Sender: TObject); virtual;
    //: Notifies the OnCommPortOpenError event if a error occurs when opening communication port.
    procedure DoPortOpenError(Sender: TObject); virtual;
    //: Notifies the OnCommPortClosed event when the communication port was closed.
    procedure DoPortClose(Sender: TObject); virtual;
    //: Notifies the OnCommPortCloseError event if a error occurs when closing communication port.
    procedure DoPortCloseError(Sender: TObject); virtual;
    //: Notifies the OnCommPortDisconnected event when a connection is lost (usefull in TCP/IP)
    procedure DoPortDisconnected(Sender: TObject); virtual;
  protected
    //: Stores the actual state of the communication port driver (Open or closed);
    PActive: Boolean;
    //: Stores if the buffers must be cleared after some communication error.
    PClearBufOnErr: Boolean;
    {: Array that stores what's protocols uses this communication port driver.
       @seealso(TProtocolDriver) }
    Protocols: array of TComponent;
    {: Array que armazena os drivers de protocolo dependentes.
       @seealso(TProtocolDriver) }
    EventInterfaces: IPortDriverEventNotificationArray;

    {: Procedure called when is needed to read something on communication port.
       To create a new communication port, you must overwritten this procedure.
    @param(Packet PIOPacket. Record with informations to execute the read command.)
    @seealso(TIOPacket) }
    procedure Read(Packet: PIOPacket); virtual; abstract;
    {: Procedure called when is needed to write something on communication port.
       To create a new communication port, you must overwritten this procedure.
    @param(Packet PIOPacket. Record with informations to execute the write command.).
    @seealso(TIOPacket) }
    procedure Write(Packet: PIOPacket); virtual; abstract;
    {: @name must be overwritten on communication ports that want's a delay between
       the read and write commands. }
    procedure NeedSleepBetweenRW; virtual; abstract;
    {: @name is called to opens the communication port. To create a new communication
             port driver, this procedure must be overwritten.
    @return(Returns @true in Ok param if the communication port was opened sucessfull.)
    @seealso(TDriverCommand) }
    procedure PortStart(var Ok: Boolean); virtual; abstract;
    {: @name is called to closes the communication port. To create a new communication
             port driver, this procedure must be overwritten.
    @return(Returns @true in Ok param if the communication port was closed sucessfull.)
    @seealso(TDriverCommand) }
    procedure PortStop(var Ok: Boolean); virtual; abstract;
    {: @name is called to check if the communication port settings are right. To
             create a new communication port driver, if this function was
             not overwritten, all combinations of settings will be invalidated
             and the communication port will not open.
    @return(Returns @true if the communication port settings are right. @false if not.)
    @seealso(TDriverCaller) }
    function ComSettingsOK: Boolean; virtual;
    {: @name is called when is needed clear the input/output buffers of the
             communication port.
       Is recommended overwriten this procedure on your communication port driver. }
    procedure ClearALLBuffers; virtual; abstract;
    //: @exclude
    procedure Loaded; override;
    //: @exclude
    procedure InternalClearALLBuffers;
    {: @name raises an exception if the communication port is active. Call this
       procedure to avoid changes in properties that cannot be changed with the
       communication port activated. }
    procedure DoExceptionInActive;
    {: @name refresh the properties LastOSErrorNumber and LastOSErrorMessage with
             the last OS error. }
    procedure RefreshLastOSError;
    //: Event called when a read error occurs on communication port.
    property OnCommErrorReading: TCommPortErrorEvent read FOnCommErrorReading write FOnCommErrorReading;
    //: Event called when a write error occurs on communication port.
    property OnCommErrorWriting: TCommPortErrorEvent read FOnCommErrorWriting write FOnCommErrorWriting;
    //: Event called when the communication port was open.
    property OnCommPortOpened: TNotifyEvent read FOnCommPortOpened write FOnCommPortOpened;
    //: Event called when the communication was not open successfully.
    property OnCommPortOpenError: TNotifyEvent read FOnCommPortOpenError write FOnCommPortOpenError;
    //: Event called when the communication port was closed.
    property OnCommPortClosed: TNotifyEvent read FOnCommPortClosed write FOnCommPortClosed;
    //: Event called when the communication was not closed successfully.
    property OnCommPortCloseError: TNotifyEvent read FOnCommPortCloseError write FOnCommPortCloseError;
    //: Event called when the communication port has been disconected.
    property OnCommPortDisconnected: TNotifyEvent read FOnCommPortDisconnected write FOnCommPortDisconnected;
    //: Number of read retries.
    property ReadRetries: Cardinal read FReadRetries write SetReadRetries default 3;
    //: Number of write retries.
    property WriteRetries: Cardinal read FWriteRetries write SetWriteRetries default 3;
  public
    //: Creates the communication port, initializing threads and internal variables.
    constructor Create(AOwner: TComponent); override;
    {: Destroys the communication port, closing and removing all references of protocols to it.
    @seealso(TProtocolDriver)
    @seealso(AddProtocol)
    @seealso(DelProtocol) }
    destructor Destroy; override;
    {: Adds a protocol driver as a dependent of the communicaton port.
    @param(Prot TProtocolDriver. Protocol driver to be added as a dependent.)
    @raises(Exception if the Prot is not a TProtocolDriver.)
    @seealso(TProtocolDriver) }
    procedure AddProtocol(Prot: TComponent);
    {: Removes a protocol driver of the list of dependents.
    @param(Prot TProtocolDriver. Protocol driver to be removed of the dependents list.)
    @seealso(TProtocolDriver)constructor }
    procedure DelProtocol(Prot: TComponent);
    {: Do a synchronous I/O request to the communication port (blocks your
       application until this action is done).
    @param(Cmd TIOCommand. The sequence of I/O to be executed.)
    @param(ToWrite Bytes. Data to be written on the communication port)
    @param(BytesToRead Cardinal. Number of @noAutoLink(Bytes) to be read on communication port.)
    @param(BytesToWrite Cardinal. Number of @noAutoLink(Bytes) to be written on communication port.)
    @param(DriverID Cardinal. Identifies the protocol that is calling the function.)
    @param(DelayBetweenCmds Cardinal. Delay in milliseconds between the commands of read and write.)
    @param(CallBack TDriverCallBack. Procedure called to return the data of the
           I/O command (with the write result and the Bytes received).)
    @param(Res1 TObject. Object to be passed to callback.)
    @param(Res2 Pointer. Pointer to be passed to callback.)
    @param(OnBegin TNotifyEvent. Procedure called by the communication port before
           start the communication operation. It can be used to start a timer or
           to release a mutex of a the protocol driver to improve the tag update rates.)
    @param(OnEnd TNotifyEvent. Procedure called after finish the communication operation.
           Can be used to finish the cronometer or to get again the mutex of the
           protocol driver, freed previously by the OnBegin.)
    @return(Returns the I/O command ID. Returns 0 if the communication port has
            been destroied or if the communication port is closed.)
    @seealso(TIOCommand)
    @seealso(Bytes)
    @seealso(TDriverCallBack)
    @seealso(IOCommandASync) }
    function IOCommandSync(Cmd: TIOCommand; ToWrite: Bytes; BytesToRead, BytesToWrite, DriverID, DelayBetweenCmds: Cardinal; CallBack: TDriverCallBack; Res1: TObject; Res2: Pointer; OnBegin: TNotifyEvent = nil; OnEnd: TNotifyEvent = nil): Cardinal; overload; deprecated;
    {: Do a synchronous I/O request to the communication port (blocks your
       application until this action is done).
    @param(Cmd TIOCommand. The sequence of I/O to be executed.)
    @param(BytesToWrite Cardinal. Number of @noAutoLink(Bytes) to be written on communication port.)
    @param(ToWrite Bytes. Data to be written on the communication port)
    @param(BytesToRead Cardinal. Number of @noAutoLink(Bytes) to be read on communication port.)
    @param(DriverID Cardinal. Identifies the protocol that is calling the function.)
    @param(DelayBetweenCmds Cardinal. Delay in milliseconds between the commands of read and write.)
    @param(pkt PIOPacket. Structure that will return informations about the command execution.
           If @code(Nil) you will not able to check result of the command.)
    @param(OnBegin TNotifyEvent. Procedure called by the communication port before
           start the communication operation. It can be used to start a timer or
           to release a mutex of a the protocol driver to improve the tag update rates.)
    @param(OnEnd TNotifyEvent. Procedure called after finish the communication operation.
           Can be used to a timer or to get again the mutex of the
           protocol driver, freed previously by the OnBegin.)
    @return(Returns the I/O command ID. Returns 0 if the communication port has
            been destroied or if the communication port is closed.)
    @seealso(TIOCommand)
    @seealso(Bytes)
    @seealso(TDriverCallBack)
    @seealso(IOCommandASync) }
    function IOCommandSync(Cmd: TIOCommand; BytesToWrite: Cardinal; ToWrite: Bytes; BytesToRead, DriverID, DelayBetweenCmds: Cardinal; Pkt: PIOPacket; OnBegin: TNotifyEvent = nil; OnEnd: TNotifyEvent = nil): Cardinal; overload;
    {: Locks the communication port for exclusive use.
       @param(DriverID Cardinal. Identifies who wants exclusive access.)
       @returns(@true if the communicaton port was locked, @false if not.) }
    function Lock(DriverID: Cardinal): Boolean;
    {: Remove the exclusive access on communication port.
       @param(DriverID Cardinal. Identifies who has the exclusive access on communication port.)
       @returns(@true if the communication port was released to be used on non-exclusive access.) }
    function Unlock(DriverID: Cardinal): Boolean;
    //: Return true if the communication port is open really.
    function ReallyActive: Boolean; virtual;
    //: Closes the current port handle and opens a new one.
    procedure RenewHandle; virtual;
    //: Returns a connection identifier.
    function GetPortId: TPortUniqueID; virtual;
  published
    //: Opens (@true) or close (@false) the communication port.
    property Active: Boolean read PActive write SetActive stored True default False;
    //: If @true, clears the input/output buffers of communication port if an I/O error has been found.
    property ClearBuffersOnCommErrors: Boolean read PClearBufOnErr write PClearBufOnErr default True;
    //: Identification of who have exclusive access on communication port.
    property LockedBy: Cardinal read PLockedBy;
    //: Returns @true if the communication port was locked for exclusive access.
    property Locked: Boolean read GetLocked;
    //: The last error code registered by the OS.
    property LastOSErrorNumber: Longint read FLastOSErrorNumber;
    //: The last error message registered by the OS.
    property LastOSErrorMessage: AnsiString read FLastOSErrorMessage;
    //: How many I/O commands are processed by second. Updated every 1 second.
    property CommandsPerSecond: Longint read FCommandsSecond;
    //: Total of @noAutoLink(Bytes) sent (written).
    property TXBytes: Int64 read FTXBytes;
    //: Total of @noAutoLink(Bytes) sent on the last second.
    property TXBytesSecond: Int64 read FTXBytesSecond;
    //: Total of @noAutoLink(Bytes) received (received).
    property RXBytes: Int64 read FRXBytes;
    //: Total of @noAutoLink(Bytes) received on the last second.
    property RXBytesSecond: Int64 read FRXBytesSecond;
    //: Enable/disables the log of I/O actions of the communication port.
    property LogIOActions: Boolean read FLogActions write SetLogActions default False;
    //: File to store the log of I/O actions of the communication port.
    property LogFile: AnsiString read FLogFile write SetLogFile;
    //: Variable where the received and sent bytes for the sample will be stored
    property Traffic_receiver: AnsiString read FTrafficReceiver;
    property Traffic_send: AnsiString read FTrafficSend;
  end;


{$IFNDEF FPC}
const
  LineEnding = #13#10;
{$ENDIF}


implementation


uses
  SysUtils,
  ProtocolDriver,
  hsstrings,
  crossdatetime,
  pascalScadaMTPCPU;


  ////////////////////////////////////////////////////////////////////////////////
  //  THREAD OF NOTIFICATION OF COMMUNICATION EVENTS.
  ////////////////////////////////////////////////////////////////////////////////

constructor TEventNotificationThread.Create(CreateSuspended: Boolean; AOwner: TComponent);
begin
  inherited Create(CreateSuspended);
  FOwner := AOwner;
  FSpool := TMessageSpool.Create;
  FDoSomethingEvent := TCrossEvent.Create(True, False);
end;

destructor TEventNotificationThread.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FDoSomethingEvent);
  FreeAndNil(FSpool);
end;

procedure TEventNotificationThread.DoSomething;
begin
  FDoSomethingEvent.SetEvent;
end;

procedure TEventNotificationThread.WaitToDoSomething;
begin
  FDoSomethingEvent.WaitFor(1);
  FDoSomethingEvent.ResetEvent;
end;

procedure TEventNotificationThread.Terminate;
begin
  inherited Terminate;
  DoSomething;
end;

procedure TEventNotificationThread.Loop;
var
  AtMainThread: Boolean;
  ANotifyEvent: TNotifyEvent;
begin
  //try
  WaitToDoSomething;
  while FSpool.PeekMessage(PMsg, PSM_COMMERROR, PSM_PORT_EVENT, True) do
  begin
    case PMsg.MsgID of
      PSM_COMMERROR:  begin
                        FEvent := PMsg.wParam;
                        FError := TIOResult(PtrUint(PMsg.lParam));
                        Synchronize(@SyncCommErrorEvent);
                        Dispose(PCommPortErrorEvent(FEvent));
                      end;
      PSM_PORT_EVENT: begin
                        FEvent := PMsg.wParam;
                        AtMainThread := PMsg.lParam <> nil;
                        if AtMainThread then
                          Synchronize(@SyncPortEvent)
                        else
                          begin
                            ANotifyEvent := PNotifyEvent(FEvent)^;
                            if Assigned(ANotifyEvent) then
                              ANotifyEvent(nil);
                          end;
                        Dispose(PNotifyEvent(FEvent));
                      end;
    end;
  end;
  //except
  //  on e:Exception do begin
  //    {$IFDEF FDEBUG}
  //    DebugLn('Exception in UpdateThread: '+ E.Message);
  //    DumpStack;
  //    {$ENDIF}
  //  end;
  //end;
end;

procedure TEventNotificationThread.DoCommErrorEvent(Event: TCommPortErrorEvent; Error: TIOResult; MainThread: Boolean);
var
  ACommPortErrorEvent: PCommPortErrorEvent;
begin
  New(ACommPortErrorEvent);
  ACommPortErrorEvent^ := Event;
  FSpool.PostMessage(PSM_COMMERROR, ACommPortErrorEvent, Pointer(PtrUint(Error)), False);
  DoSomething;
end;

procedure TEventNotificationThread.DoCommPortEvent(Event: TNotifyEvent; MainThread: Boolean);
var
  ANotifyEvent: PNotifyEvent;
  APointer: Pointer;
begin
  New(ANotifyEvent);
  ANotifyEvent^ := Event;

  APointer := nil;
  if MainThread then
    APointer := Pointer(1);

  FSpool.PostMessage(PSM_PORT_EVENT, ANotifyEvent, APointer, False);
  DoSomething;
end;

procedure TEventNotificationThread.SyncCommErrorEvent;
var
  ACommPortErrorEvent: TCommPortErrorEvent;
begin
  if FEvent = nil then Exit;
  try
    ACommPortErrorEvent := TCommPortErrorEvent(FEvent^);
    ACommPortErrorEvent(FError);
  finally
  end;
end;

procedure TEventNotificationThread.SyncPortEvent;
var
  ANotifyEvent: TNotifyEvent;
begin
  if FEvent = nil then Exit;
  try
    ANotifyEvent := TNotifyEvent(FEvent^);
    ANotifyEvent(FOwner);
  finally
  end;
end;


////////////////////////////////////////////////////////////////////////////////
//  CODE OF THE BASE OF COMMUNICATION PORT DRIVER CLASS.
////////////////////////////////////////////////////////////////////////////////

constructor TCommPortDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOwnerThread := GetCurrentThreadId;
  FExclusiveDevice := False;
  FLastOSErrorMessage := '';
  FLastOSErrorNumber := 0;
  FReadRetries := 3;
  FWriteRetries := 3;
  PIOCmdCS := SyncObjs.TCriticalSection.Create;
  PLockCS := SyncObjs.TCriticalSection.Create;
  PLockEvent := TCrossEvent.Create(True, True);
  PUnlocked := 0;
  PClearBufOnErr := True;

  PEventUpdater := TEventNotificationThread.Create(True, Self);
  PEventUpdater.WakeUp;
  PEventUpdater.WaitLoopStarts;
end;

destructor TCommPortDriver.Destroy;
var
  i: Longint;
begin
  for i := 0 to High(Protocols) do
    TProtocolDriver(Protocols[i]).CommunicationPort := nil;
  for i := 0 to High(EventInterfaces) do
    EventInterfaces[i].DoPortRemoved(Self);
  PEventUpdater.Terminate;
  while PEventUpdater.WaitEnd(1) <> wrSignaled do
    Sleep(1);
  PEventUpdater.Destroy;
  Active := False;
  SetLength(Protocols, 0);
  PIOCmdCS.Destroy;
  PLockCS.Destroy;
  PLockEvent.Destroy;
  inherited Destroy;
end;

procedure TCommPortDriver.AddProtocol(Prot: TComponent);
var
  i: Longint;
  Found: Boolean;
  Interfaced: Boolean;
begin
  Interfaced := Supports(Prot, IPortDriverEventNotification);
  if not Interfaced then
    if not (Prot is TProtocolDriver) then
      raise Exception.Create(SCompIsntADriver);

  Found := False;
  if Interfaced then
    begin
      for i := 0 to High(EventInterfaces) do
        if EventInterfaces[i] = (Prot as IPortDriverEventNotification) then
        begin
          Found := True;
          Break;
        end;
    end
  else
    begin
      for i := 0 to High(Protocols) do
        if Protocols[i] = Prot then
        begin
          Found := True;
          Break;
        end;
    end;

  if not Found then
  begin
    if Interfaced then
      begin
        i := Length(EventInterfaces);
        SetLength(EventInterfaces, i + 1);
        EventInterfaces[i] := (Prot as IPortDriverEventNotification);
      end
    else
      begin
        i := Length(Protocols);
        SetLength(Protocols, i + 1);
        Protocols[i] := Prot;
      end;
  end;
end;

procedure TCommPortDriver.DelProtocol(Prot: TComponent);
var
  Found: Boolean;
  Interfaced: Boolean;
  i: Longint;
begin
  Interfaced := Supports(Prot, IPortDriverEventNotification);
  Found := False;
  if Interfaced then
    begin
      for i := 0 to High(EventInterfaces) do
        if EventInterfaces[i] = (Prot as IPortDriverEventNotification) then
        begin
          Found := True;
          Break;
        end;
    end
  else
    begin
      for i := 0 to High(Protocols) do
        if Protocols[i] = Prot then
        begin
          Found := True;
          Break;
        end;
    end;

  if Found then
  begin
    if Interfaced then
      begin
        EventInterfaces[i] := EventInterfaces[High(EventInterfaces)];
        SetLength(EventInterfaces, High(EventInterfaces));
      end
    else
      begin
        Protocols[i] := Protocols[High(Protocols)];
        SetLength(Protocols, High(Protocols));
      end;
  end;
end;

function TCommPortDriver.ComSettingsOK: Boolean;
begin
  Result := False;
end;

procedure TCommPortDriver.IOCommand(Cmd: TIOCommand; Packet: PIOPacket);
begin
  if csDestroying in ComponentState then
    Exit;

  FDelayBetweenCmds := Packet^.DelayBetweenCommand;
  case Cmd of
    iocRead: Read(Packet);
    iocReadWrite: begin
                    Read(Packet);
                    NeedSleepBetweenRW;
                    Write(Packet);
                  end;
    iocWrite: Write(Packet);
    iocWriteRead: begin
                    Write(Packet);
                    NeedSleepBetweenRW;
                    Read(Packet);
                  end;
  end;
  FRXBytes := FRXBytes + Packet^.Received;
  FTXBytes := FTXBytes + Packet^.Written;
end;

procedure TCommPortDriver.CommError(WriteCmd: Boolean; Error: TIOResult);
var
  ACommPortErrorEvent: TCommPortErrorEvent;
begin
  if WriteCmd then
    begin
      ACommPortErrorEvent := @DoWriteError;
    end
  else
    begin
      ACommPortErrorEvent := @DoReadError;
    end;

  if Assigned(ACommPortErrorEvent) then
    if MainThreadID = GetCurrentThreadId then
      ACommPortErrorEvent(Error)
    else
      PEventUpdater.DoCommErrorEvent(ACommPortErrorEvent, Error, True);
end;

procedure TCommPortDriver.CommPortOpened;
var
  i: Longint;
begin
  if [csDestroying] * ComponentState <> [] then Exit;

  if MainThreadID = GetCurrentThreadId then
    DoPortOpened(Self)
  else
    PEventUpdater.DoCommPortEvent(@DoPortOpened, True);

  for i := 0 to High(EventInterfaces) do
    if ntePortOpen in EventInterfaces[i].NotifyThisEvents then
      PEventUpdater.DoCommPortEvent(EventInterfaces[i].GetPortOpenedEvent, False);
end;

procedure TCommPortDriver.CommPortOpenError;
begin
  if [csDestroying] * ComponentState <> [] then Exit;

  if MainThreadID = GetCurrentThreadId then
    DoPortOpenError(Self)
  else
    PEventUpdater.DoCommPortEvent(@DoPortOpenError, True);
end;

procedure TCommPortDriver.CommPortClose;
var
  i: Longint;
begin
  if [csDestroying] * ComponentState <> [] then Exit;

  if MainThreadID = GetCurrentThreadId then
    DoPortClose(Self)
  else
    PEventUpdater.DoCommPortEvent(@DoPortClose, True);

  for i := 0 to High(EventInterfaces) do
    if ntePortClosed in EventInterfaces[i].NotifyThisEvents then
      PEventUpdater.DoCommPortEvent(EventInterfaces[i].GetPortClosedEvent, False);
end;

procedure TCommPortDriver.CommPortCloseError;
begin
  if [csDestroying] * ComponentState <> [] then Exit;

  if MainThreadID = GetCurrentThreadId then
    DoPortCloseError(Self)
  else
    PEventUpdater.DoCommPortEvent(@DoPortCloseError, True);
end;

procedure TCommPortDriver.CommPortDisconected;
var
  i: Longint;
begin
  if [csDestroying] * ComponentState <> [] then Exit;

  if MainThreadID = GetCurrentThreadId then
    DoPortDisconnected(Self)
  else
    PEventUpdater.DoCommPortEvent(@DoPortDisconnected, True);
  for i := 0 to High(EventInterfaces) do
    if ntePortDisconnected in EventInterfaces[i].NotifyThisEvents then
      PEventUpdater.DoCommPortEvent(EventInterfaces[i].GetPortDisconnectedEvent, False);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TCommPortDriver.DoReadError(Error: TIOResult);
begin
  if Assigned(FOnCommErrorReading) then
    FOnCommErrorReading(Error);
end;

procedure TCommPortDriver.DoWriteError(Error: TIOResult);
begin
  if Assigned(FOnCommErrorWriting) then
    FOnCommErrorWriting(Error);
end;

procedure TCommPortDriver.DoPortOpened(Sender: TObject);
begin
  if Assigned(FOnCommPortOpened) then
    FOnCommPortOpened(Sender);
end;

procedure TCommPortDriver.DoPortOpenError(Sender: TObject);
begin
  if Assigned(FOnCommPortOpenError) then
    FOnCommPortOpenError(Sender);
end;

procedure TCommPortDriver.DoPortClose(Sender: TObject);
begin
  if Assigned(FOnCommPortClosed) then
    FOnCommPortClosed(Sender);
end;

procedure TCommPortDriver.DoPortCloseError(Sender: TObject);
begin
  if Assigned(FOnCommPortCloseError) then
    FOnCommPortCloseError(Sender);
end;

procedure TCommPortDriver.DoPortDisconnected(Sender: TObject);
begin
  if Assigned(FOnCommPortDisconnected) then
    FOnCommPortDisconnected(Sender);
end;

procedure TCommPortDriver.Loaded;
begin
  inherited Loaded;
  SetActive(FReadActive);
  SetLogActions(FReadedLogActions);
end;

procedure TCommPortDriver.TimerStatistics(Sender: TObject);
begin
  FCommandsSecond := PPacketID - FLastPkgId;
  FTXBytesSecond := FTXBytes - FTXBytesLast;
  FRXBytesSecond := FRXBytes - FRXBytesLast;

  FRXBytesLast := FRXBytes;
  FTXBytesLast := FTXBytes;
  FLastPkgId := PPacketID;
end;

function TCommPortDriver.GetLocked: Boolean;
begin
  Result := (PLockedBy <> 0);
end;

function TCommPortDriver.Lock(DriverID: Cardinal): Boolean;
begin
  // waits everyone finish their commands
  while PUnlocked > 0 do
    CrossThreadSwitch;

  try
    PLockCS.Enter;
    if PLockedBy = 0 then
    begin
      PLockedBy := DriverID;
      PLockEvent.ResetEvent;
      Result := True;
    end
    else
      Result := False;
  finally
    PLockCS.Leave;
  end;
end;

function TCommPortDriver.Unlock(DriverID: Cardinal): Boolean;
begin
  try
    PLockCS.Enter;
    if (PLockedBy = 0) or (DriverID = PLockedBy) then
    begin
      PLockedBy := 0;
      PLockEvent.SetEvent;
      Result := True;
    end
    else
      Result := False;
  finally
    PLockCS.Leave;
  end;
end;

function TCommPortDriver.ReallyActive: Boolean;
begin
  if [csDesigning] * ComponentState <> [] then
    begin
      if FExclusiveDevice then
        begin
          Result := False;
        end
      else
        begin
          Result := PActive;
        end;
    end
  else
    Result := PActive;
end;

procedure TCommPortDriver.RenewHandle;
begin

end;

function TCommPortDriver.GetPortId: TPortUniqueID;
begin

end;

procedure TCommPortDriver.SetActive(AValue: Boolean);
var
  x: Boolean;
begin
  // if it is being loading
  if csReading in ComponentState then
  begin
    FReadActive := AValue;
    Exit;
  end;
  // avoid the open/close of communication port in design-time if the communication
  // port is exclusive (like a serial port)
  if FExclusiveDevice and (csDesigning in ComponentState) then
    begin
      if AValue then
        begin
          if ComSettingsOK then
          begin
            PActive := True;
          end;
        end
      else
        begin
          PActive := False;
        end;
    end
  else
    begin
      if AValue then
        begin
          InternalPortStart(x);
          PActive := x;
        end
      else
        begin
          InternalPortStop(x);
          PActive := x = False;
        end;
    end;
end;

procedure TCommPortDriver.OpenInEditMode(v: Boolean);
begin

end;

procedure TCommPortDriver.SetReadRetries(AValue: Cardinal);
begin
  if FReadRetries = AValue then Exit;
  InterLockedExchange(Longint(FReadRetries), AValue);
end;

procedure TCommPortDriver.SetWriteRetries(AValue: Cardinal);
begin
  if FWriteRetries = AValue then Exit;
  InterLockedExchange(Longint(FWriteRetries), AValue);
end;

function TCommPortDriver.IOCommandSync(Cmd: TIOCommand; ToWrite: Bytes; BytesToRead, BytesToWrite, DriverID, DelayBetweenCmds: Cardinal; CallBack: TDriverCallBack; Res1: TObject; Res2: Pointer; OnBegin: TNotifyEvent = nil; OnEnd: TNotifyEvent = nil): Cardinal;
var
  PPacket: TIOPacket;
  InLockCS: Boolean;
  InIOCmdCS: Boolean;
begin
  try
    InLockCS := False;
    InIOCmdCS := False;

    Result := 0;

    if (csDestroying in ComponentState)
      or (FExclusiveDevice and (csDesigning in ComponentState)) then
      Exit;

    // verify if another driver is the owner of the comm port
    PLockCS.Enter;
    InLockCS := True;
    while (PLockedBy <> 0) and (PLockedBy <> DriverID) do
    begin
      PLockCS.Leave;
      InLockCS := False;
      PLockEvent.WaitFor($FFFFFFFF);
      PLockCS.Enter;
      InLockCS := True;
    end;
    InterLockedIncrement(PUnlocked);
    PLockCS.Leave;
    InLockCS := False;

    PIOCmdCS.Enter;
    InIOCmdCS := True;
    if (not ReallyActive) then
      Exit;

    if Assigned(OnBegin) then
      OnBegin(Self);

    Inc(PPacketID);

    // creates de command packet
    PPacket.PacketID := PPacketID;
    PPacket.WriteIOResult := iorNone;
    PPacket.ToWrite := BytesToWrite;
    PPacket.Written := 0;
    PPacket.WriteRetries := FWriteRetries;

    PPacket.BufferToWrite := ToWrite;

    PPacket.DelayBetweenCommand := DelayBetweenCmds;
    PPacket.ReadIOResult := iorNone;
    PPacket.ToRead := BytesToRead;
    PPacket.Received := 0;
    PPacket.ReadRetries := FReadRetries;
    PPacket.Res1 := Res1;
    PPacket.Res2 := Res2;
    SetLength(PPacket.BufferToRead, BytesToRead);

    // executes the I/O command
    InternalIOCommand(Cmd, @PPacket);
    if Assigned(CallBack) then
      CallBack(PPacket);

    // free the buffers
    SetLength(PPacket.BufferToWrite, 0);
    SetLength(PPacket.BufferToRead, 0);

    // return the command ID
    Result := PPacketID;

    if Assigned(OnEnd) then
      OnEnd(Self);
  finally
    if InIOCmdCS then
      PIOCmdCS.Leave;

    if InLockCS then
      PLockCS.Leave;

    InterLockedDecrement(PUnlocked);
  end;
end;

function TCommPortDriver.IOCommandSync(Cmd: TIOCommand; BytesToWrite: Cardinal; ToWrite: Bytes; BytesToRead, DriverID, DelayBetweenCmds: Cardinal; Pkt: PIOPacket; OnBegin: TNotifyEvent; OnEnd: TNotifyEvent): Cardinal;
var
  InLockCS: Boolean;
  InIOCmdCS: Boolean;
  PPacket: PIOPacket;
begin
  try
    InLockCS := False;
    InIOCmdCS := False;

    Result := 0;

    if Pkt = nil then
      New(PPacket)
    else
      PPacket := Pkt;

    if (csDestroying in ComponentState)
      or (FExclusiveDevice and (csDesigning in ComponentState)) then
      Exit;

    // verify if another driver is the owner of the comm port...
    PLockCS.Enter;
    InLockCS := True;
    while (PLockedBy <> 0) and (PLockedBy <> DriverID) do
    begin
      PLockCS.Leave;
      InLockCS := False;
      PLockEvent.WaitFor($FFFFFFFF);
      PLockCS.Enter;
      InLockCS := True;
    end;
    InterLockedIncrement(PUnlocked);
    PLockCS.Leave;
    InLockCS := False;

    PIOCmdCS.Enter;
    InIOCmdCS := True;
    //if (not ReallyActive) then
    //Exit;

    if Assigned(OnBegin) then
      OnBegin(Self);

    Inc(PPacketID);

    // creates de command packet
    PPacket^.PacketID := PPacketID;
    PPacket^.WriteIOResult := iorNone;
    PPacket^.ToWrite := BytesToWrite;
    PPacket^.Written := 0;
    PPacket^.WriteRetries := FWriteRetries;

    PPacket^.BufferToWrite := ToWrite;

    PPacket^.DelayBetweenCommand := DelayBetweenCmds;
    PPacket^.ReadIOResult := iorNone;
    PPacket^.ToRead := BytesToRead;
    PPacket^.Received := 0;
    PPacket^.ReadRetries := FReadRetries;
    PPacket^.Res1 := nil;
    PPacket^.Res2 := nil;
    SetLength(PPacket^.BufferToRead, BytesToRead);

    if (not ReallyActive) then
      Exit;
    // executes the I/O command
    InternalIOCommand(Cmd, @PPacket^);

    // free the buffers
    if Pkt = nil then
    begin
      SetLength(PPacket^.BufferToWrite, 0);
      SetLength(PPacket^.BufferToRead, 0);
    end;

    // return the command ID
    Result := PPacketID;

    if Assigned(OnEnd) then
      OnEnd(Self);
  finally
    if Pkt = nil then
      Dispose(PPacket);

    if InIOCmdCS then
      PIOCmdCS.Leave;

    if InLockCS then
      PLockCS.Leave;

    InterLockedDecrement(PUnlocked);
  end;
end;

procedure TCommPortDriver.InternalIOCommand(Cmd: TIOCommand; Packet: PIOPacket);
begin
  try
    PIOCmdCS.Enter;
    // verify if the communication port is active
    if ReallyActive then
      begin
        //try
        // executes the I/O command.
        IOCommand(Cmd, Packet);
        //except
        //  if Cmd in [iocRead, iocReadWrite, iocWriteRead] then
        //    Packet^.ReadIOResult := iorPortError;
        //  if Cmd in [iocWrite, iocReadWrite, iocWriteRead] then
        //    Packet^.WriteIOResult := iorPortError;
        //end;
      end
    else
      begin
        if Cmd in [iocRead, iocReadWrite, iocWriteRead] then
          Packet^.ReadIOResult := iorNotReady;
        if Cmd in [iocWrite, iocReadWrite, iocWriteRead] then
          Packet^.WriteIOResult := iorNotReady;
      end;
    // Bytes data
    Traffic(Cmd, Packet^);
    if FLogActions then
      LogAction(Cmd, Packet^);
  finally
    PIOCmdCS.Leave;
  end;
end;

procedure TCommPortDriver.InternalPortStart(var Ok: Boolean);
begin
  try
    PIOCmdCS.Enter;
    PortStart(Ok);
    RefreshLastOSError;
    if Ok then
      CommPortOpened
    else
      CommPortOpenError;
  finally
    PIOCmdCS.Leave;
  end;
end;

procedure TCommPortDriver.InternalPortStop(var Ok: Boolean);
begin
  try
    PIOCmdCS.Enter;
    PortStop(Ok);
    RefreshLastOSError;
    if Ok then
      CommPortClose
    else
      CommPortCloseError;
  finally
    PIOCmdCS.Leave;
  end;
end;

procedure TCommPortDriver.InternalClearALLBuffers;
begin
  try
    PIOCmdCS.Enter;
    ClearALLBuffers;
  finally
    PIOCmdCS.Leave;
  end;
end;

procedure TCommPortDriver.DoExceptionInActive;
begin
  if PActive then
  begin
    if (ComponentState * [csDesigning] = []) or ((ComponentState * [csDesigning] <> []) and FExclusiveDevice = False) then
      raise Exception.Create(SimpossibleToChangeWhenActive);
  end;
end;

procedure TCommPortDriver.RefreshLastOSError;
{$IFNDEF FPC}
  {$IF defined(WIN32) or defined(WIN64)}
var
  Buffer: PAnsiChar;
  {$IFEND}
{$ENDIF}
begin
{$IFDEF FPC}
  FLastOSErrorNumber := GetLastOSError;
  FLastOSErrorMessage := SysErrorMessage(FLastOSErrorNumber);
{$ELSE}
  {$IF defined(WIN32) or defined(WIN64)}
  FLastOSErrorNumber := GetLastError;
  GetMem(Buffer, 512);
  if FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, nil, FLastOSErrorNumber, LANG_NEUTRAL, Buffer, 512, nil) <> 0 then
    begin
      FLastOSErrorMessage := Buffer;
      FreeMem(Buffer);
    end
  else
    FLastOSErrorMessage := SFaultGettingLastOSError;
  {$IFEND}
{$ENDIF}
end;

procedure TCommPortDriver.SetLogActions(Log: Boolean);
var
  CanOpen: Boolean;
begin
  PIOCmdCS.Enter;
  try
    CanOpen := False;
    if Log = FLogActions then Exit;

    if [csReading] * ComponentState <> [] then
    begin
      FReadedLogActions := Log;
      Exit;
    end;

    if [csDesigning] * ComponentState <> [] then
    begin
      CanOpen := (Trim(FLogFile) <> '');
      Exit;
    end;

    if Log then
      begin
        if not FileExists(FLogFile) then
        begin
          FLogFileStream := TFileStream.Create(FLogFile, fmCreate);
          FLogFileStream.Destroy;
        end;
        FLogFileStream := TFileStream.Create(FLogFile, fmOpenReadWrite + fmShareDenyWrite);
        FLogFileStream.Position := FLogFileStream.Size;
      end
    else
      FLogFileStream.Destroy;
    CanOpen := True;
  finally
    FLogActions := Log and CanOpen;
    PIOCmdCS.Leave;
  end;
end;

procedure TCommPortDriver.SetLogFile(NFile: AnsiString);
var
  isLogging: Boolean;
begin
  PIOCmdCS.Enter;
  try
    if NFile = FLogFile then Exit;
    isLogging := FLogActions;
    LogIOActions := False;
    FLogFile := NFile;
    LogIOActions := isLogging;
  finally
    PIOCmdCS.Leave;
  end;
end;


const
  S_WRITE_IO_RESULT: array [TIOResult] of AnsiString = (
    'iorOK',
    'iorTimeOut',
    'iorNotReady',
    'iorNone',
    'iorPortError');


function BufferToHex(Buf: Bytes): AnsiString;
var
  i: Longint;
begin
  Result := '';
  for i := 0 to High(Buf) do
    Result := Result + IntToHex(Buf[i], 2) + ' ';
end;

function TranslateCmdName(Cmd: TIOCommand): AnsiString;
begin
  case Cmd of
    iocNone:      Result := 'iocNone     ';
    iocRead:      Result := 'iocRead     ';
    iocReadWrite: Result := 'iocReadWrite';
    iocWrite:     Result := 'iocWrite    ';
    iocWriteRead: Result := 'iocWriteRead';
  end;
end;

procedure TCommPortDriver.LogAction(Cmd: TIOCommand; Packet: TIOPacket);
var
  FS: TStringStream;
  TimeStamp: AnsiString;
begin
  if not FLogActions then Exit;

  if [csDesigning] * ComponentState <> [] then Exit;

  try
    FS := TStringStream.Create('');
    TimeStamp := FormatDateTime('mmm-dd hh:nn:ss.zzz', CrossNow);
    case Cmd of
      iocRead:      begin
                      FS.WriteString(TimeStamp + ', ' + TranslateCmdName(Cmd) +
                        ', Result=' + S_WRITE_IO_RESULT[Packet.ReadIOResult] +
                        ', Received: ' + BufferToHex(Packet.BufferToRead) + LineEnding);
                    end;
      iocReadWrite: begin
                      FS.WriteString(TimeStamp + ', ' + TranslateCmdName(Cmd) +
                        ', Result=' + S_WRITE_IO_RESULT[Packet.ReadIOResult] +
                        ', Received: ' + BufferToHex(Packet.BufferToRead) + LineEnding);
                      FS.WriteString(TimeStamp + ', ' + TranslateCmdName(Cmd) +
                        ', Result=' + S_WRITE_IO_RESULT[Packet.WriteIOResult] +
                        ', Written:    ' + BufferToHex(Packet.BufferToWrite) + LineEnding);
                    end;
      iocWriteRead: begin
                      FS.WriteString(TimeStamp + ', ' + TranslateCmdName(Cmd) +
                        ', Result=' + S_WRITE_IO_RESULT[Packet.WriteIOResult] +
                        ', Written:    ' + BufferToHex(Packet.BufferToWrite) + LineEnding);
                      FS.WriteString(TimeStamp + ', ' + TranslateCmdName(Cmd) +
                        ', Result=' + S_WRITE_IO_RESULT[Packet.ReadIOResult] +
                        ', Received: ' + BufferToHex(Packet.BufferToRead) + LineEnding);
                    end;
      iocWrite:     begin
                      FS.WriteString(TimeStamp + ', ' + TranslateCmdName(Cmd) +
                        ', Result=' + S_WRITE_IO_RESULT[Packet.WriteIOResult] +
                        ', Written:    ' + BufferToHex(Packet.BufferToWrite) + LineEnding);
                    end;
    end;
    FS.Position := 0;
    FLogFileStream.CopyFrom(FS, FS.Size);
  finally
    FS.Free;
  end;
end;


procedure TCommPortDriver.Traffic(Cmd: TIOCommand; Packet: TIOPacket);
// performs sampling of incoming and outgoing traffic
begin
  case Cmd of
    iocRead:      begin
                    FTrafficReceiver1 := BufferToHex(Packet.BufferToRead);
                  end;
    iocWriteRead: begin
                    FTrafficSend := BufferToHex(Packet.BufferToWrite);
                    FTrafficReceiver2 := BufferToHex(Packet.BufferToRead);
                  end;
  end;
  FTrafficReceiver := FTrafficReceiver2 + FTrafficReceiver1;
end;


end.

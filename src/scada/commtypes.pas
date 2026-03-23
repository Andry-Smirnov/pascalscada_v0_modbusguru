{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit with types/definitions commonly used on communication ports.)
}
unit commtypes;

interface

uses
  Classes;

type
  {: Sequence of bytes.
     @seealso(TCommPortDriver)
     @seealso(TIOPacket) }

  Bytes = array of Byte;

  {:
  @name define the commands and their sequence of execution.

  @value iocNone Does nothing;
  @value iocRead Executes a read;
  @value iocReadWrite Executes a read command and after this a write command;
  @value iocWrite Executes a write command;
  @value iocWriteRead Executes a write command and after this a read command;

  @seealso(TCommPortDriver)
  @seealso(TCommPortDriver.IOCommandASync)
  @seealso(TCommPortDriver.IOCommandSync)
  @seealso(TIOPacket) }
  TIOCommand = (iocNone, iocRead, iocReadWrite, iocWrite, iocWriteRead);

  {:
  @name define the results of an I/O request.

  @value iorOk The request was done with successfull.
  @value iorTimeOut The request has a timeout.
  @value iorNotReady The communication port isn't ready yet. Example: communication port closed.
  @value iorNone The command was not processed;
  @value iorPortError A fault occurred while processing the I/O command.
  @seealso(TIOPacket) }
  TIOResult = (iorOK, iorTimeOut, iorNotReady, iorNone, iorPortError);

  {:
  Return the results of an I/O request.

  @member PacketID Request identification.
  @member WriteIOResult Result of a write command, if exists. If not exists, return iorNone.
  @member ToWrite Number of @noAutoLink(bytes) to write.
  @member Written Number of @noAutoLink(bytes) written.
  @member WriteRetries Number of retries to write ToWrite @noAutoLink(bytes).
  @member BufferToWrite Sequence of @noAutoLink(bytes) to write. @bold(Must have at least ToWrite @noAutoLink(bytes) of length).
  @member DelayBetweenCommand Delay in milliseconds between the commands of Read and Write.
  @member ReadIOResult Result of a read command, if exists. If not exists, return iorNone.
  @member ToRead Number of @noAutoLink(bytes) to read.
  @member Received Number of @noAutoLink(bytes) received.
  @member ReadRetries Number of retries to read ToRead @noAutoLink(bytes).
  @member BufferToRead Buffer that stores @noAutoLink(bytes) received. Their length is adjusted to ToRead.

  @seealso(TCommPortDriver)
  @seealso(TDriverCallBack)
  @seealso(TCommPortDriver.IOCommandASync)
  @seealso(TCommPortDriver.IOCommandSync) }
  TIOPacket = record
    PacketID: Cardinal;
    WriteIOResult: TIOResult;
    ToWrite: Cardinal;
    Written: Cardinal;
    WriteRetries: Cardinal;
    BufferToWrite: Bytes;
    DelayBetweenCommand: Longint;
    ReadIOResult: TIOResult;
    ToRead: Cardinal;
    Received: Cardinal;
    ReadRetries: Cardinal;
    BufferToRead: Bytes;
    Res1: TObject;
    Res2: Pointer;
  end;

  {: Pointer to a TIOPacket record.
     @seealso(TIOPacket) }
  PIOPacket = ^TIOPacket;

  {:
  Defines the callback procedure to return the results of a I/O command done by
  TCommPortDriver.IOCommandSync. The result is returned by the Result variable.

  @seealso(TCommPortDriver)
  @seealso(TIOPacket)
  @seealso(TCommPortDriver.IOCommandASync)
  @seealso(TCommPortDriver.IOCommandSync) }
  TDriverCallBack = procedure(var Result: TIOPacket) of object;

  //: @exclude
{$IFDEF FPC}
  TPSThreadID = TThreadID;
{$ELSE}
  TPSThreadID = THandle;
{$ENDIF}

  //: Defines a method called when a communication error occurs.
  TCommPortErrorEvent = procedure(Error: TIOResult) of object;
  //: Points to a method used to report communications errors.
  PCommPortErrorEvent = ^TCommPortErrorEvent;

  //: Defines the types of events of communications port opens, closed and disconnected.
  TCommPortGenericError = procedure of object;
  //: Points to a method used to report communications errors.
  PCommPortGenericError = ^TCommPortGenericError;
  //: Points to a notification method.
  PNotifyEvent = ^TNotifyEvent;

  {:
  Defines the notifications that the protocol driver can register.
  @value ntePortOpen Notifies the protocol driver when the communication port was open.
  @value ntePortClose Notifies the protocol driver when the communication port was closed.
  @value ntePortDisconnected Notifies the protocol driver when the communication port was disconnected.
  @seealso(IPortDriverEventNotification) }
  TPortEvents = (ntePortOpen, ntePortClosed, ntePortDisconnected);

  {: Defines the set of notifications that a protocol driver can register.
     @seealso(TPortEvents) }
  TNotifyThisEvents = set of TPortEvents;
  //: Event notification interface for protocol drivers.
  IPortDriverEventNotification = interface
    ['{26B0F551-5B46-49D9-BCA1-AD621B3775CF}']
    //: Returns the event to be called when communication port opens.
    function GetPortOpenedEvent: TNotifyEvent;
    //: Returns the event to be called when communication port closed.
    function GetPortClosedEvent: TNotifyEvent;
    //: Returns the event to be called when communication port is disconnected.
    function GetPortDisconnectedEvent: TNotifyEvent;
    {: Set of events that the protocol driver wants be notified.
       @seealso(TPortEvents)
       @seealso(TNotifyThisEvents) }
    function NotifyThisEvents: TNotifyThisEvents;
    //: Procedure called when the communication port opens.
    procedure DoPortOpened(Sender: TObject);
    //: Procedure called when the communication port was closed.
    procedure DoPortClosed(Sender: TObject);
    //: Procedure called when the communication port was disconnected.
    procedure DoPortDisconnected(Sender: TObject);
    //: Procedure called when the communication port has been destroied.
    procedure DoPortRemoved(Sender: TObject);
  end;

  IPortDriverEventNotificationArray = array of IPortDriverEventNotification;

const
  //: Communication error messsage (read or write);
  PSM_COMMERROR = 4;
  //: Message of communication port open, closed or disconnected.
  PSM_PORT_EVENT = 5;

  {: Concatenate two @noAutoLink(bytes) buffers.
     @seealso(BYTES) }
function ConcatenateBYTES(const A, B: Bytes): Bytes;


implementation


// concatenate two buffers of Bytes
function ConcatenateBYTES(const A, B: Bytes): Bytes;
var
  i: Longint;
begin
  SetLength(Result, Length(A) + Length(B));
  for i := 0 to High(A) do
    Result[i] := A[i];
  for i := 0 to High(B) do
    Result[i + Length(A)] := B[i];
end;

end.

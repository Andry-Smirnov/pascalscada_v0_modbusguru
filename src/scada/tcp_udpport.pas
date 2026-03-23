{$i ../common/language.inc}
{:
  @abstract(Unit that implements a socket client TCP/UDP over IP.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
unit tcp_udpport;

{$I ../common/delphiver.inc}

interface

uses
  Classes,
  CommPort,
  commtypes,
  socket_types,
  CrossEvent,
  MessageSpool,
  syncobjs,
  crossthreads
  // delphi or lazarus over windows
{$IF defined(WIN32) or defined(WIN64)}
  , Windows,
  {$IF defined(WIN32)}
  JwaWinBase,
  {$ENDIF}
  {$IFDEF FPC}
  WinSock2,
  {$ELSE}
  WinSock,
  {$ENDIF}
  sockets_w32_w64
{$ELSE}
  {$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
  , Sockets
  {$IFDEF UNIX}
  , sockets_unix,
  netdb,
  Unix
  {$ENDIF}
  {$IFDEF WINCE}
  , sockets_wince
  {$ENDIF}
  {$IFDEF FDEBUG}
  , LCLProc
  {$ENDIF}
  {$IFEND}
{$IFEND}
  ;

type

  { TConnectThread }

  TConnectThread = class(TpSCADACoreAffinityThread)
  private
    FActive: Boolean;
    FCheckSocket: TConnectEvent;
    FConnectSocket: TConnectEvent;
    FDisconnectSocket: TConnectEvent;
    FEnd: TCrossEvent;
    FReconnectSocket: TConnectEvent;
    FMessageQueue: TMessageSpool;

    FAutoReconnect: Integer;
    FReconnectInterval: Integer;
    FReconnectRetries: Integer;

    function GetEnableAutoReconnect: Boolean;

    function GetReconnectInterval: Integer;
    function GetReconnectRetries: Integer;

    procedure SetReconnectInterval(AValue: Integer);
    procedure SetEnableAutoReconnect(AValue: Boolean);
    procedure SetReconnectRetries(AValue: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect;
    procedure NotifyDisconnect;
    procedure WaitEnd;
    procedure StopAutoReconnect;
  published
    property ConnectSocket: TConnectEvent read FConnectSocket write FConnectSocket;
    property ReconnectSocket: TConnectEvent read FReconnectSocket write FReconnectSocket;
    property DisconnectSocket: TConnectEvent read FDisconnectSocket write FDisconnectSocket;
    property CheckSocket: TConnectEvent read FCheckSocket write FCheckSocket;

    property EnableAutoReconnect: Boolean read GetEnableAutoReconnect write SetEnableAutoReconnect;
    property ReconnectInterval: Integer read GetReconnectInterval write SetReconnectInterval;
  end;

  {:
  @abstract(TCP/UDP over IP client port driver. Currently working on Windows,
            Linux and FreeBSD.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @seealso(TCommPortDriver) }

  { TTCP_UDPPort }

  TTCP_UDPPort = class(TCommPortDriver)
  private
    fPortID: TPortUniqueID;
    FHostName: AnsiString;
    FPortNumber: Longint;
    FTimeout: Longint;
    FSocket: TSocket;
    FPortType: TPortType;
    FExclusiveReaded: Boolean;

    FConnectThread: TConnectThread;

    procedure DoReconnect;

    function GetEnableAutoReconect: Boolean;
    function GetReconnectInterval: Integer;

    procedure SetEnableAutoReconnect(AValue: Boolean);
    procedure SetReconnectInterval(AValue: Integer);

    procedure SetHostname(AValue: AnsiString);
    procedure SetPortNumber(AValue: Longint);
    procedure SetTimeout(AValue: Longint);
    procedure SetPortType(AValue: TPortType);
    procedure SetExclusive(AValue: Boolean);
    procedure RecalcPortId;
  protected
    //: @exclude
    procedure Loaded; override;
    //: @seealso(TCommPortDriver.Read)
    procedure Read(Packet: PIOPacket); override;
    //: @seealso(TCommPortDriver.Write)
    procedure Write(Packet: PIOPacket); override;
    //: @seealso(TCommPortDriver.NeedSleepBetweenRW)
    procedure NeedSleepBetweenRW; override;
    //: @seealso(TCommPortDriver.PortStart)
    procedure PortStart(var Ok: Boolean); override;
    //: @seealso(TCommPortDriver.PortStop)
    procedure PortStop(var Ok: Boolean); override;
    //: @seealso(TCommPortDriver.ComSettingsOK)
    function ComSettingsOK: Boolean; override;
    //: @seealso(TCommPortDriver.ClearALLBuffers)
    procedure ClearALLBuffers; override;

    //: @seealso(TCommPortDriver.DoPortDisconnected)
    procedure DoPortDisconnected(Sender: TObject); override;
    //: @seealso(TCommPortDriver.DoPortOpenError)
    procedure DoPortOpenError(Sender: TObject); override;

    procedure ConnectSocket(var Ok: Boolean);
    procedure CloseMySocket(var Closed: Boolean);
    procedure ReconnectSocket(var Ok: Boolean);
    procedure CheckSocket(var Ok: Boolean);
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    //: @seealso TCommPortDriver.ReallyActive
    function ReallyActive: Boolean; override;

    //: @seealso TCommPortDriver.RenewHandle
    procedure RenewHandle; override;

    //: @seealso TCommPortDriver.GetPortId
    function GetPortId: TPortUniqueID; override;

    class function ValidIPv4(AIPv4: string): Boolean;
  published
    //: Hostname or address of the server to connect.
    property Host: AnsiString read FHostName write SetHostname nodefault;
    //: Server port to connect. To use Modbus, set this to 502 and to use Siemens ISOTCP set it to 102.
    property Port: Longint read FPortNumber write SetPortNumber default 102;
    //: Timeout in milliseconds to I/O operations.
    property Timeout: Longint read FTimeout write SetTimeout default 1000;
    {: Port kind (TCP or UDP).
       @seealso(TPortType). }
    property PortType: TPortType read FPortType write SetPortType default ptTCP;

    //: Tells if the communication port is exclusive (avoid it to be opened in design time).
    property ExclusiveDevice: Boolean read FExclusiveDevice write SetExclusive;
    //: Enables the auto reconnection if a connection is lost or failed.
    property EnableAutoReconnect: Boolean read GetEnableAutoReconect write SetEnableAutoReconnect stored True default True;
    //: Time to retry a lost connection in milliseconds.
    property ReconnectRetryInterval: Integer read GetReconnectInterval write SetReconnectInterval stored True default 5000;

    //: @seealso TCommPortDriver.OnCommPortOpened
    property OnCommPortOpened;
    //: @seealso TCommPortDriver.OnCommPortOpenError
    property OnCommPortOpenError;
    //: @seealso TCommPortDriver.OnCommPortClosed
    property OnCommPortClosed;
    //: @seealso TCommPortDriver.OnCommPortCloseError
    property OnCommPortCloseError;
    //: @seealso TCommPortDriver.OnCommErrorReading
    property OnCommErrorReading;
    //: @seealso TCommPortDriver.OnCommErrorWriting
    property OnCommErrorWriting;
    //: @seealso TCommPortDriver.OnCommPortDisconnected
    property OnCommPortDisconnected;
  end;


implementation


uses
  hsstrings,
  dateutils,
  SysUtils,
  hsutils;


  { TConnectThread }

function TConnectThread.GetEnableAutoReconnect: Boolean;
var
  Res: Longint;
begin
  InterLockedExchange(Res, FAutoReconnect);
  Result := Res = 1;
end;

function TConnectThread.GetReconnectInterval: Integer;
begin
  Result := 0;
  InterLockedExchange(Result, FReconnectInterval);
end;

function TConnectThread.GetReconnectRetries: Integer;
begin
  Result := 0;
  InterLockedExchange(Result, FReconnectRetries);
end;

procedure TConnectThread.SetReconnectInterval(AValue: Integer);
begin
  InterLockedExchange(FReconnectInterval, AValue);
end;

procedure TConnectThread.SetEnableAutoReconnect(AValue: Boolean);
begin
  if AValue then
    InterLockedExchange(FAutoReconnect, 1)
  else
    InterLockedExchange(FAutoReconnect, 0);
end;

procedure TConnectThread.SetReconnectRetries(AValue: Integer);
begin
  InterLockedExchange(FReconnectRetries, AValue);
end;

procedure TConnectThread.Execute;
var
  Msg: TMSMsg;
  Ok: Boolean;
  ReconnectTimerRunning: Boolean;
  ReconnectStarted: TDateTime;
  MsBetween: Int64;
begin
  ReconnectTimerRunning := False;
  ReconnectStarted := Now;
  while FEnd.ResetEvent = False do
    ;
  while not Terminated do
  begin
    while FMessageQueue.PeekMessage(Msg, 0, 100, True) and not Terminated do
    begin
      Ok := False;
      case Msg.MsgID of
        0:  begin
              FActive := True;
              if Assigned(FConnectSocket) then
              begin
                FConnectSocket(Ok);
                if (Ok) then
                  ReconnectTimerRunning := False
                else if (FAutoReconnect = 1) then
                  begin
                    if ReconnectTimerRunning = False then
                      ReconnectStarted := now;
                    ReconnectTimerRunning := True;
                  end;
              end;
            end;
        1:  begin
              if FActive then
              begin
                if ReconnectTimerRunning = False then
                  ReconnectStarted := now;
                ReconnectTimerRunning := True;
              end;
            end;
        2:  begin
              ReconnectTimerRunning := False;
            end;
        3:  begin
              FActive := False;
              if Assigned(DisconnectSocket) then
                DisconnectSocket(Ok);
              ReconnectTimerRunning := False;
            end;
      end;
    end;

    if FActive and not Terminated then
    begin
      Ok := True;
      if Assigned(FCheckSocket) then
        FCheckSocket(Ok);
      if not Ok then
      begin
        if ReconnectTimerRunning = False then
          ReconnectStarted := now;
        ReconnectTimerRunning := True;
      end;
    end;

    MsBetween := MilliSecondsBetween(now, ReconnectStarted);
    if (FAutoReconnect = 1)
      and (ReconnectTimerRunning)
      and (MsBetween >= ReconnectInterval)
      and not Terminated then
    begin
      ReconnectStarted := now;
      Ok := False;
      if Assigned(FReconnectSocket) then
        FReconnectSocket(Ok);
      if Ok then
        ReconnectTimerRunning := False;
    end;

    if not Terminated then
      Sleep(250);
  end;

  // terminated, close the socket
  FActive := False;
  if Assigned(DisconnectSocket) then
    DisconnectSocket(Ok);
  ReconnectTimerRunning := False;

  FEnd.SetEvent;
end;

constructor TConnectThread.Create;
begin
  inherited Create(True);
  FMessageQueue := TMessageSpool.Create;
  FEnd := TCrossEvent.Create(True, False);
end;

destructor TConnectThread.Destroy;
begin
  FreeAndNil(FMessageQueue);
  FreeAndNil(FEnd);
  inherited;
end;

procedure TConnectThread.Connect;
begin
  if Assigned(FMessageQueue) then
    FMessageQueue.PostMessage(0, nil, nil, False);
end;

procedure TConnectThread.Disconnect;
begin
  if Assigned(FMessageQueue) then
    FMessageQueue.PostMessage(3, nil, nil, False);
end;

procedure TConnectThread.NotifyDisconnect;
begin
  if Assigned(FMessageQueue) then
    FMessageQueue.PostMessage(1, nil, nil, False);
end;

procedure TConnectThread.WaitEnd;
begin
  while not (FEnd.WaitFor(5) = wrSignaled) do
    CheckSynchronize(5);
end;

procedure TConnectThread.StopAutoReconnect;
begin
  if Assigned(FMessageQueue) then
    FMessageQueue.PostMessage(2, nil, nil, False);
end;

////////////////////////////////////////////////////////////////////////////////

constructor TTCP_UDPPort.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPortNumber := 102;
  FTimeout := 1000;
  {$IF defined(WIN32) or defined(WIN64)}
  FSocket:=INVALID_SOCKET;
  {$ELSE}
  FSocket := -1;
  {$ENDIF}

  FConnectThread := TConnectThread.Create;
  FConnectThread.EnableAutoReconnect := True;
  FConnectThread.ReconnectInterval := 5000;
  FConnectThread.ConnectSocket := @ConnectSocket;
  FConnectThread.ReconnectSocket := @ReconnectSocket;
  FConnectThread.DisconnectSocket := @CloseMySocket;
  FConnectThread.CheckSocket := @CheckSocket;
  FConnectThread.WakeUp;
end;

destructor TTCP_UDPPort.Destroy;
begin
  Active := False;
  FConnectThread.Terminate;
  FConnectThread.WaitEnd;
  FreeAndNil(FConnectThread);
  inherited Destroy;
end;

function TTCP_UDPPort.ReallyActive: Boolean;
var
  ASocket: TSocket;
begin
{$IF defined(WINDOWS)}
  {$IF defined(CPU64)}
  InterLockedExchange64(ASocket, FSocket);
  {$ELSE}
  InterLockedExchange(LongInt(ASocket), LongInt(FSocket));
  {$ENDIF}
{$ELSE}
  InterLockedExchange(ASocket, FSocket);
{$ENDIF}

{$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
  Result := ASocket >= 0;
{$ELSE}
  Result := ASocket <> INVALID_SOCKET;
{$ENDIF}
end;

procedure TTCP_UDPPort.RenewHandle;
begin
  if ReallyActive then
  begin
    FConnectThread.Disconnect;
    FConnectThread.Connect;
  end;
end;

function TTCP_UDPPort.GetPortId: TPortUniqueID;
begin
  {$IFNDEF CPUARM}
  { TODO : ARMHF this not works }
  InterlockedExchange64(Result, fPortID);
  {$ENDIF}
end;

class function TTCP_UDPPort.ValidIPv4(AIPv4: string): Boolean;
var
  IP: TStringArray;
  i: Integer;
  ZeroCount: Integer;
  FFCount: Integer;
  Octet: Longint;
begin
  IP := ExplodeString('.', AIPv4);
  if Length(IP) <> 4 then
    Exit(False);

  ZeroCount := 0;
  FFCount := 0;
  for i := 0 to 3 do
  begin
    if TryStrToInt(IP[i], Octet) = False then
      Exit(False);
    if not (Octet in [0..255]) then
      Exit(False);
    if ((i = 0) or (i = 3)) and ((Octet = 0) or (Octet = 255)) then
      Exit(False);
    if Octet = 0 then
      ZeroCount := ZeroCount + 1;
    if Octet = 255 then
      FFCount := FFCount + 1;
  end;
  if ZeroCount = 4 then
    Exit(False);
  if FFCount = 4 then
    Exit(False);
  Result := True;
end;

procedure TTCP_UDPPort.ReconnectSocket(var Ok: Boolean);
begin
  CloseMySocket(Ok);
  ConnectSocket(Ok);
end;

procedure TTCP_UDPPort.CheckSocket(var Ok: Boolean);
begin
  Ok := ReallyActive;
end;

procedure TTCP_UDPPort.SetHostname(AValue: AnsiString);
begin
  DoExceptionInActive;

  if (FHostName = trim(AValue)) then Exit;

  if (trim(AValue) = '') then
  begin
    FHostName := trim(AValue);
    RecalcPortId;
    Exit;
  end;

  if (FHostName <> AValue) then
  begin
    if ValidIPv4(AValue) then
      begin
        FHostName := AValue;
        RecalcPortId;
        Exit;
      end
    else
      raise Exception.Create(Format('The address "%s" is not a valid IPv4 address', [AValue]));
  end;
end;

procedure TTCP_UDPPort.SetPortNumber(AValue: Longint);
begin
  DoExceptionInActive;
  if (AValue >= 1) or (AValue <= 65535) then
    FPortNumber := AValue
  else
    raise Exception.Create(SportNumberRangeError);

  RecalcPortId;
end;

procedure TTCP_UDPPort.SetTimeout(AValue: Longint);
begin
  DoExceptionInActive;
  FTimeout := AValue;
end;

procedure TTCP_UDPPort.SetPortType(AValue: TPortType);
begin
  DoExceptionInActive;
  FPortType := AValue;
  RecalcPortId;
end;

procedure TTCP_UDPPort.SetExclusive(AValue: Boolean);
var
  OldState: Boolean;
begin
  if csReading in ComponentState then
  begin
    FExclusiveReaded := AValue;
    Exit;
  end;

  // only at design-time
  if csDesigning in ComponentState then
    begin
      //stores the old state.
      OldState := Active;
      //close the communication port.
      Active := False;
      //set the new state.
      FExclusiveDevice := AValue;
      //restores the old state.
      Active := OldState;
    end
  else
    FExclusiveDevice := AValue;
end;

procedure TTCP_UDPPort.RecalcPortId;
var
  AID: TPortUniqueID = 0;
  ABytes: array [0..7] of Byte absolute AID;
  IP: TStringArray;
  Aux: Longint;
  i: Integer;
begin
  AID := 0;
  case FPortType of
    ptTCP: ABytes[7] := 2;
    ptUDP: ABytes[7] := 3;
  end;
  if ValidIPv4(FHostName) then
    begin
      IP := ExplodeString('.', FHostName);
      for i := 0 to 3 do
      begin
        if TryStrToInt(IP[i], Aux) then
          ABytes[i] := Aux
        else
          begin
            ABytes[0] := 0;
            ABytes[1] := 1;
            ABytes[2] := 2;
            ABytes[3] := 3;
            ABytes[7] := ABytes[7] or $80;
            Break;
          end;
      end;
    end
  else
    begin
      ABytes[7] := ABytes[7] or $80;
    end;

  PWord(@ABytes[4])^ := FPortNumber;

  {$IFNDEF CPUARM}
  { TODO : ARMHF this not works }
  InterlockedExchange64(fPortID, AID);
  {$ENDIF}
end;

procedure TTCP_UDPPort.SetEnableAutoReconnect(AValue: Boolean);
begin
  FConnectThread.EnableAutoReconnect := AValue;
  if AValue = False then
    FConnectThread.StopAutoReconnect;
end;

function TTCP_UDPPort.GetReconnectInterval: Integer;
begin
  Result := FConnectThread.ReconnectInterval;
end;

procedure TTCP_UDPPort.SetReconnectInterval(AValue: Integer);
begin
  FConnectThread.ReconnectInterval := AValue;
end;

procedure TTCP_UDPPort.Loaded;
begin
  ExclusiveDevice := FExclusiveReaded;
  inherited Loaded;
end;

procedure TTCP_UDPPort.Read(Packet: PIOPacket);
var
  ARead: Longint;
  AAttempts: Cardinal;
  AIncrements: Boolean;
begin
  AAttempts := 0;
  ARead := 0;

  Packet^.Received := 0;
  while (Packet^.Received < Packet^.ToRead) and (AAttempts < Packet^.ReadRetries) do
  begin
    try
      ARead := SocketRecv(FSocket, @Packet^.BufferToRead[Packet^.Received], Packet^.ToRead - Packet^.Received, 0, FTimeout);
    finally
    end;

    if ARead <= 0 then
      begin
        if not CheckConnection(Packet^.ReadIOResult, AIncrements, FSocket, @CloseMySocket, @CommPortDisconected) then
          Break;
        if AIncrements then
          Inc(AAttempts);
      end
    else
      Packet^.Received := Packet^.Received + ARead;
  end;

  Packet^.ReadRetries := AAttempts;
  if Packet^.ToRead > Packet^.Received then
    begin
      Packet^.ReadIOResult := iorTimeOut;
      if PClearBufOnErr then InternalClearALLBuffers;
    end
  else
    Packet^.ReadIOResult := iorOK;

  if Packet^.ReadIOResult <> iorOK then
    CommError(False, Packet^.ReadIOResult);
end;

procedure TTCP_UDPPort.Write(Packet: PIOPacket);
var
  AWritten: Longint;
  AAttempts: Cardinal;
  AIncrements: Boolean;
begin
  AAttempts := 0;
  AWritten := 0;

  Packet^.Written := 0;
  while (Packet^.Written < Packet^.ToWrite) and (AAttempts < Packet^.WriteRetries) do
  begin
    try
      AWritten := SocketSend(FSocket, @Packet^.BufferToWrite[Packet^.Written], Packet^.ToWrite - Packet^.Written, 0, FTimeout);
    finally
    end;

    if AWritten <= 0 then
      begin
        if not CheckConnection(Packet^.ReadIOResult, AIncrements, FSocket, @CloseMySocket, @CommPortDisconected) then
          Break;
        if AIncrements then
          Inc(AAttempts);
      end
    else
      Packet^.Written := Packet^.Written + AWritten;
  end;

  Packet^.WriteRetries := AAttempts;
  if Packet^.ToWrite > Packet^.Written then
    begin
      Packet^.WriteIOResult := iorTimeOut;
      if PClearBufOnErr then
        InternalClearALLBuffers;
    end
  else
    Packet^.WriteIOResult := iorOK;

  if Packet^.WriteIOResult <> iorOK then
    CommError(True, Packet^.WriteIOResult);
end;

procedure TTCP_UDPPort.NeedSleepBetweenRW;
begin
  if FDelayBetweenCmds > 0 then
    Sleep(FDelayBetweenCmds);
end;

procedure TTCP_UDPPort.PortStart(var Ok: Boolean);
begin
  if ([csDesigning] * ComponentState = []) or FExclusiveDevice then
    FConnectThread.Connect;
  Ok := True;
end;

procedure TTCP_UDPPort.CloseMySocket(var Closed: Boolean);
var
  Buffer: Bytes;
  ARead: Longint;
  ASocket: TSocket;
begin
{$IF defined(WINDOWS)}
  {$IF defined(CPU64)}
  InterLockedExchange64(ASocket, FSocket);
  InterLockedExchange64(FSocket, INVALID_SOCKET);
  {$ELSE}
  InterLockedExchange(LongInt(ASocket), LongInt(FSocket));
  InterLockedExchange(LongInt(FSocket), LongInt(INVALID_SOCKET));
  {$ENDIF}
{$ELSE}
  InterLockedExchange(ASocket, FSocket);
  InterLockedExchange(FSocket, -1);
{$ENDIF}

  Closed := False;
{$IFDEF WINDOWS}
  if ASocket <> INVALID_SOCKET then
{$ELSE}
  if ASocket >= 0 then
{$ENDIF}
  begin
    SetLength(Buffer, 5);
{$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
    fpshutdown(ASocket, SHUT_WR);
    ARead := fprecv(ASocket, @Buffer[0], 1, MSG_PEEK);
    while ARead > 0 do
    begin
      ARead := fprecv(ASocket, @Buffer[0], 1, 0);
      ARead := fprecv(ASocket, @Buffer[0], 1, MSG_PEEK);
    end;
{$ELSE}
    Shutdown(ASocket, 1);
    ARead := Recv(ASocket, Buffer[0], 1, MSG_PEEK);
    while ARead > 0 do
    begin
      ARead := Recv(ASocket, Buffer[0], 1, 0);
      ARead := Recv(ASocket, Buffer[0], 1, MSG_PEEK);
    end;
{$IFEND}
    CloseSocket(ASocket);
  end;
  Closed := True;
  SetLength(Buffer, 0);
end;

procedure TTCP_UDPPort.PortStop(var Ok: Boolean);
begin
  if (([csDesigning, csDestroying] * ComponentState = []) or FExclusiveDevice)
    and Assigned(FConnectThread) then
    FConnectThread.Disconnect;
  Ok := True;
end;

function TTCP_UDPPort.ComSettingsOK: Boolean;
begin
  Result := (FHostName <> '') and ((FPortNumber > 0) and (FPortNumber <= $FFFF));
end;

procedure TTCP_UDPPort.DoReconnect;
begin
  FConnectThread.NotifyDisconnect;
end;

function TTCP_UDPPort.GetEnableAutoReconect: Boolean;
begin
  Result := FConnectThread.EnableAutoReconnect;
end;

procedure TTCP_UDPPort.DoPortDisconnected(Sender: TObject);
begin
  DoReconnect;

  inherited DoPortDisconnected(Sender);
end;

procedure TTCP_UDPPort.DoPortOpenError(Sender: TObject);
begin
  DoReconnect;

  inherited DoPortOpenError(Sender);
end;

procedure TTCP_UDPPort.ConnectSocket(var Ok: Boolean);
var
  {$IF defined(FPC) and defined(UNIX)}
  ServerAddr: THostEntry;
  Channel: SockAddr_In;
  {$IFEND}
  {$IF defined(FPC) and defined(WINCE)}
  Channel: SockaAdr_In;
  {$IFEND}
  {$IF defined(WIN32) or defined(WIN64)}
  Channel: SockAddr_In;
  {$IFEND}
  Flag: Longint;
  BufSize: Longint;
  SockType: Longint;
  SockProto: Longint;
  ASocket: TSocket;
  MustCloseSocket: Boolean;
begin
  Ok := False;
  MustCloseSocket := False;
  try
    //##########################################################################
    // NAME RESOLUTION OVER LINUX/FREEBSD and others
    //##########################################################################
    {$IF defined(FPC) and defined(UNIX)}
      if not GetHostByName(FHostName, {%H-}ServerAddr) then
      begin
        ServerAddr.Addr := StrToHostAddr(FHostName);
        if ServerAddr.Addr.s_addr = 0 then
        begin
          RefreshLastOSError;
          Exit;
        end;
      end;
    {$IFEND}

    //##########################################################################
    // CREATE THE SOCKET
    //##########################################################################
    case FPortType of
      ptTCP:  begin
                SockProto := IPPROTO_TCP;
                SockType := SOCK_STREAM;
              end;
      ptUDP:  begin
                SockProto := IPPROTO_UDP;
                SockType := SOCK_DGRAM;
              end
      else
        begin
          Exit;
        end;
    end;

    {$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
    // UNIX and WINDOWS CE
    ASocket := fpSocket(PF_INET, SockType, SockProto);

    if ASocket < 0 then
    begin
      RefreshLastOSError;
      Exit;
    end;
    {$ELSE}
    // WINDOWS
    ASocket := Socket(PF_INET, SockType, SockProto);

    if ASocket = INVALID_SOCKET then
    begin
      RefreshLastOSError;
      Exit;
    end;
    {$IFEND}
    MustCloseSocket := True;

    //##########################################################################
    // SOCKET OPTIONS
    // TIMEOUT OPTIONS ARE MADE USING SELECT/FPSELECT, BECAUSE THIS OPTIONS
    // AREN'T SUPPORTED BY SOME OSes LIKE WINDOWS CE
    //##########################################################################
    Flag := 1;
    BufSize := 1024 * 16;
    //UNIX AND WINDOWS CE
{$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
    fpsetsockopt(ASocket, SOL_SOCKET,  SO_RCVBUF,    @BufSize,  SizeOf(LongInt));
    fpsetsockopt(ASocket, SOL_SOCKET,  SO_SNDBUF,    @BufSize,  SizeOf(LongInt));
    fpsetsockopt(ASocket, IPPROTO_TCP, TCP_NODELAY,  @Flag,     SizeOf(LongInt));
{$IFEND}
    // WINDOWS
{$IF defined(WIN32) or defined(WIN64)}
    setsockopt(ASocket, SOL_SOCKET,  SO_RCVBUF,    PAnsiChar(@BufSize), SizeOf(LongInt));
    setsockopt(ASocket, SOL_SOCKET,  SO_SNDBUF,    PAnsiChar(@BufSize), SizeOf(LongInt));
    setsockopt(ASocket, IPPROTO_TCP, TCP_NODELAY,  PAnsiChar(@Flag),    SizeOf(LongInt));
{$IFEND}

    //##########################################################################
    // SETS THE TARGET ADDRESS TO SOCKET CONNECT
    //##########################################################################
    Channel.sin_family := AF_INET;          // Family
    Channel.sin_port := htons(FPortNumber); // Port number

{$IF defined(FPC) AND defined(UNIX)}
    Channel.sin_addr.S_addr := LongWord(htonl(LongWord(ServerAddr.Addr.s_addr)));
{$IFEND}
{$IF defined(FPC) AND defined(WINCE)}
    Channel.sin_addr := StrToNetAddr(FHostName);
{$IFEND}
{$IF defined(WIN32) OR defined(WIN64)}
    Channel.sin_addr.S_addr := inet_addr(PAnsiChar(FHostName));
{$IFEND}

    //##########################################################################
    // SET THE NON-BLOCKING OPERATING MODE OF THE SOCKET
    //##########################################################################
    SetBlockingMode(ASocket, MODE_NONBLOCKING);

    if ConnectWithTimeout(ASocket, @Channel, SizeOf(Channel), FTimeout) <> 0 then
    begin
      RefreshLastOSError;
      Exit;
    end;

    Ok := True;
{$IF defined(WINDOWS)}
  {$IF defined(CPU64)}
    InterLockedExchange64(FSocket,ASocket);
  {$ELSE}
    InterLockedExchange(LongInt(FSocket), LongInt(ASocket));
  {$ENDIF}
{$ELSE}
    InterLockedExchange(FSocket, ASocket);
{$ENDIF}
    DoPortOpened(Self);
  finally
    if not Ok then
    begin
      if MustCloseSocket then
      begin
        {$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
        fpshutdown(ASocket, SHUT_WR);
        {$ELSE}
        Shutdown(ASocket, 1);
        {$IFEND}
        CloseSocket(ASocket);
      end;
      CloseMySocket(Ok);
      Ok := False;
      CommPortOpenError;
    end;
  end;
end;

procedure TTCP_UDPPort.ClearALLBuffers;
begin

end;

end.

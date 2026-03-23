{$i ../common/language.inc}
{:
  @abstract(Unit that implements a network mutex.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Removed Extctrls unit
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
unit MutexClient;

{$I ../common/delphiver.inc}
interface

uses
  Classes,
  SysUtils,
  socket_types,
  CrossEvent,
  crossthreads,
  syncobjs
  // delphi or lazarus over windows
{$IF defined(WIN32) or defined(WIN64)}
  {$IFDEF FPC}
  , WinSock2,
  {$ELSE}
  , WinSock,
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


const
  MUTEX_CLIENT_PORT = 52321;//51342;


type

  { TMutexClientThread }

  TMutexClientThread = class(TpSCADACoreAffinityThread)
  private
    FConnectionBroken: TNotifyEvent;
    FOwnMutex: Boolean;
    FServerHasBeenFinished: TNotifyEvent;
    FSocket: TSocket;
    FEnd: TCrossEvent;
    FSocketMutex: TCriticalSection;
    LastPingSent: TDateTime;
    Quit: Boolean;
  private
    procedure ConnectionIsGone;
  protected
    // called when client got the mutex
    procedure SetIntoServerMutexBehavior; virtual;
    // called when the client leaves the mutex
    procedure SetOutServerMutexBehavior; virtual;
    // check for ping commmands when client owns the mutex
    procedure Execute; override;
    // called when server sends a quit command
    procedure ServerHasBeenFinished; virtual;
    // ping server
    function PingServer: Boolean;
  public
    constructor Create(CreateSuspended: Boolean; aSocket: TSocket);
    destructor Destroy; override;
    // try enter on server mutex
    function TryEnter: Boolean;
    // leave the server mutex
    function Leave: Boolean;
    // send a quit command to server
    procedure DisconnectFromServer; virtual;
    // wait the client thread ends
    procedure WaitEnd;
  published
    property onServerHasBeenFinished: TNotifyEvent read FServerHasBeenFinished write FServerHasBeenFinished;
    property onConnectionBroken: TNotifyEvent read FConnectionBroken write FConnectionBroken;
  end;

  { TMutexClient }

  TMutexClient = class(TComponent)
  private
    FActive: Boolean;
    FActiveLoaded: Boolean;
    FConnected: Longint;
    FPort: Word;
    FServerHost: AnsiString;
    FSocket: TSocket;
    FDefaultBehavior: Boolean;
    FConnectionStatusThread: TMutexClientThread;
    procedure Connect;
    procedure Disconnect;
    procedure SetActive(AValue: Boolean);
    procedure SetPort(AValue: Word);
    procedure SetServerHost(AValue: AnsiString);
    procedure ConnectionFinished(Sender: TObject);
{$IFDEF FPC}
    function InterLockedExchangePointer(var Target: Pointer; Source : Pointer): Pointer;
{$ENDIF}
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function TryEnter: Boolean; overload;
    function TryEnter(out PickedTheDefaultBehavior: Boolean): Boolean; overload;
    function Leave: Boolean;
  published
    property Active: Boolean read FActive write SetActive stored True default False;
    property Host: AnsiString read FServerHost write SetServerHost stored True nodefault;
    property DefaultBehavior: Boolean read FDefaultBehavior write FDefaultBehavior stored True default False;
    property Port: Word read FPort write SetPort stored True default MUTEX_CLIENT_PORT;//52321;
  end;


implementation


uses
  hsstrings,
  dateutils,
  hsutils
  {$IFNDEF FPC}
  , Windows
  {$ENDIF}
  ;


{ TMutexClientThread }

procedure TMutexClientThread.ConnectionIsGone;
begin
  if Assigned(FConnectionBroken) then
    FConnectionBroken(Self);
end;

procedure TMutexClientThread.SetIntoServerMutexBehavior;
begin
  FOwnMutex := True;
end;

procedure TMutexClientThread.SetOutServerMutexBehavior;
begin
  FOwnMutex := False;
end;

procedure TMutexClientThread.Execute;
var
  ServerRequest: Byte;

  function SendPingCmd: Boolean;
  var
    Request: Byte;
  begin
    Request := 254;
    if SocketSend(FSocket, @Request, 1, 0, 1000) < 1 then
    begin
      ConnectionIsGone;
      Result := False;
    end
    else
      LastPingSent := Now;
  end;

  function InternalPingServer: Boolean;
  begin
    Result := True;
    if MilliSecondsBetween(Now, LastPingSent) >= 1000 then
    begin
      Result := SendPingCmd;
    end;
  end;

begin
  FEnd.ResetEvent;
  LastPingSent := Now;
  while (not Terminated) and (not Quit) do
  begin
    FSocketMutex.Enter;
    try
      repeat
        if SocketRecv(FSocket, @ServerRequest, 1, 0, 5) >= 1 then
        begin
          case ServerRequest of
            21: begin
                  SetIntoServerMutexBehavior;
                  Exit;
                end;
            20, 30,
            31, 32: begin
                      SetOutServerMutexBehavior;
                      Exit;
                    end;
            253:  begin
                    ServerHasBeenFinished;
                  end;
            255:  begin
                    if not SendPingCmd then
                    begin
                      ConnectionIsGone;
                      Break;
                    end;
                  end;
          end;
        end;
      until GetNumberOfBytesInReceiveBuffer(FSocket) <= 0;
      InternalPingServer;
    finally
      FSocketMutex.Leave;
    end;

    Sleep(1);
  end;
  FEnd.SetEvent;
end;

procedure TMutexClientThread.DisconnectFromServer;
var
  Request: Byte;
begin
  FSocketMutex.Enter;
  Request := 253;//try enter on mutex
  SocketSend(FSocket, @Request, 1, 0, 1000);
  Quit := True;
  ConnectionIsGone;
  FSocketMutex.Leave;
end;

procedure TMutexClientThread.WaitEnd;
begin
  while not (FEnd.WaitFor(10) = wrSignaled) do
    CheckSynchronize();
end;

procedure TMutexClientThread.ServerHasBeenFinished;
begin
  Quit := True;
  ConnectionIsGone;
end;

function TMutexClientThread.PingServer: Boolean;
var
  Request: Byte;
begin
  Result := False;
  Request := 254;
  if SocketSend(FSocket, @Request, 1, 0, 1000) < 1 then
    ConnectionIsGone
  else
    begin
      LastPingSent := Now;
      Result := True;
    end;
end;

constructor TMutexClientThread.Create(CreateSuspended: Boolean; aSocket: TSocket);
begin
  inherited Create(CreateSuspended);
  FSocketMutex := TCriticalSection.Create;
  FEnd := TCrossEvent.Create(True, False);
  FSocket := aSocket;
  Quit := False;
end;

destructor TMutexClientThread.Destroy;
begin
  FSocketMutex.Destroy;
  FEnd.Destroy;
  inherited Destroy;
end;

function TMutexClientThread.TryEnter: Boolean;
var
  Request: Byte;
  Response: Byte;
  ExpectedResponse: Boolean;
begin
  Result := False;
  ExpectedResponse := False;
  FSocketMutex.Enter;
  try
    // try enter on mutex
    Request := 2;
    if SocketSend(FSocket, @Request, 1, 0, 1000) >= 1 then
      begin
        repeat
          if SocketRecv(FSocket, @Response, 1, 0, 1000) >= 1 then
          begin
            case Response of
              20: begin
                    Result := False;
                    ExpectedResponse := True;
                    SetOutServerMutexBehavior;
                  end;
              21: begin
                    Result := True;
                    ExpectedResponse := True;
                    SetIntoServerMutexBehavior;
                  end;
              253:  begin
                      Result := False;
                      ExpectedResponse := False;
                      ServerHasBeenFinished;
                      Break;
                    end;
              255:  begin
                      ExpectedResponse := False;
                      PingServer;
                    end;
              else
                ExpectedResponse := False;
            end;
          end;
          CheckSynchronize(1);
        until (GetNumberOfBytesInReceiveBuffer(FSocket) <= 0) and ExpectedResponse;
      end
    else
      ConnectionIsGone;
  finally
    FSocketMutex.Leave;
  end;
end;

function TMutexClientThread.Leave: Boolean;
var
  Request: Byte;
  Response: Byte;
  ExpectedResponse: Boolean;
begin
  Result := False;
  ExpectedResponse := False;
  FSocketMutex.Enter;
  try
    // try enter on mutex
    Request := 3;
    if SocketSend(FSocket, @Request, 1, 0, 1000) >= 1 then
      begin
        repeat
          if SocketRecv(FSocket, @Response, 1, 0, 1000) >= 1 then
          begin
            case Response of
              30, 31, 32: begin
                            Result := True;
                            ExpectedResponse := True;
                            SetOutServerMutexBehavior;
                          end;
              253:  begin
                      ExpectedResponse := False;
                      ServerHasBeenFinished;
                      Break;
                    end;
              255:  begin
                      ExpectedResponse := False;
                      PingServer;
                    end;
              else
                ExpectedResponse := False;
            end;
          end;
        until (GetNumberOfBytesInReceiveBuffer(FSocket) <= 0) and ExpectedResponse;
      end
    else
      ConnectionIsGone;
  finally
    FSocketMutex.Leave;
  end;
end;

{ TMutexClient }

procedure TMutexClient.Connect;
var
{$IF defined(FPC) and defined(UNIX)}
  ServerAddr: THostEntry;
  Сhannel: sockaddr_in;
{$IFEND}
{$IF defined(FPC) and defined(WINCE)}
  Сhannel: sockaddr_in;
{$IFEND}
{$IF defined(WIN32) or defined(WIN64)}
  Channel: sockaddr_in;
{$IFEND}
  Flag: Longint;
  SocketOpen: Boolean;
begin
  if FConnected <> 0 then Exit;

  SocketOpen := False;

  try
    //##########################################################################
    // NAME RESOLUTION OVER LINUX/FREEBSD and others
    //##########################################################################
{$IF defined(FPC) and defined(UNIX)}
      if not GetHostByName(FServerHost, ServerAddr) then
      begin
        ServerAddr.Addr := StrToHostAddr(FServerHost);
        if ServerAddr.Addr.s_addr = 0 then
        begin
          //PActive := False;
          //RefreshLastOSError;
          Exit;
        end;
      end;
{$IFEND}

    //##########################################################################
    // CREATE THE SOCKET
    //##########################################################################

{$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
    // UNIX and WINDOWS CE
    FSocket := fpSocket(PF_INET, SOCK_STREAM, IPPROTO_TCP);

    if FSocket < 0 then
    begin
      //PActive := False;
      //RefreshLastOSError;
      Exit;
    end;
{$ELSE}
    // WINDOWS
    FSocket := Socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);

    if FSocket = INVALID_SOCKET then
    begin
      //PActive := False;
      //RefreshLastOSError;
      Exit;
    end;
{$IFEND}

    SocketOpen := True;

    //##########################################################################
    // SET THE NON-BLOCKING OPERATING MODE OF THE SOCKET
    //##########################################################################
    SetBlockingMode(FSocket, MODE_NONBLOCKING);

    //##########################################################################
    // SOCKET OPTIONS
    // TIMEOUT OPTIONS ARE MADE USING SELECT/FPSELECT, BECAUSE THIS OPTIONS
    // AREN'T SUPPORTED BY SOME OSes LIKE WINDOWS CE
    //##########################################################################
    Flag := 1;
    // UNIX AND WINDOWS CE
{$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
    fpsetsockopt(FSocket, IPPROTO_TCP, TCP_NODELAY,  @flag, SizeOf(LongInt));
{$IFEND}
    // WINDOWS
{$IF defined(WIN32) or defined(WIN64)}
    setsockopt(FSocket, IPPROTO_TCP, TCP_NODELAY, PAnsiChar(@Flag), SizeOf(LongInt));
{$IFEND}

    //##########################################################################
    // SETS THE TARGET ADDRESS TO SOCKET CONNECT
    //##########################################################################
    Channel.sin_family := AF_INET;    // Family
    Channel.sin_port := htons(FPort); // Port number
{$IF defined(FPC) AND defined(UNIX)}
    Channel.sin_addr.S_addr := LongWord(htonl(LongInt(ServerAddr.Addr.s_addr)));
{$IFEND}
{$IF defined(FPC) AND defined(WINCE)}
    Channel.sin_addr := StrToNetAddr(FServerHost);
{$IFEND}
{$IF defined(WIN32) OR defined(WIN64)}
    Channel.sin_addr.S_addr := inet_addr(PAnsiChar(FServerHost));
{$IFEND}

    if ConnectWithTimeout(FSocket, @Channel, SizeOf(Channel), 2000) <> 0 then
    begin
      Exit;
    end;
    FConnected := 1;
    FConnectionStatusThread := TMutexClientThread.Create(True, FSocket);
    FConnectionStatusThread.FreeOnTerminate := True;
    FConnectionStatusThread.OnTerminate := @ConnectionFinished;
    FConnectionStatusThread.onConnectionBroken := @ConnectionFinished;
    FConnectionStatusThread.onServerHasBeenFinished := @ConnectionFinished;

    // after setup the thread, wake up it
    FConnectionStatusThread.WakeUp;
  finally
    if SocketOpen and (FConnected = 0) then
      CloseSocket(FSocket);
  end;
end;

procedure TMutexClient.Disconnect;
var
  ThreadInstance: TMutexClientThread;
begin
  if FConnected <> 0 then
  begin
    if FConnectionStatusThread <> nil then
    begin
      ThreadInstance := FConnectionStatusThread;
      with ThreadInstance do
      begin
        FreeOnTerminate := False;
        DisconnectFromServer;
        WaitEnd;
        Destroy;
      end;
    end;
    FConnectionStatusThread := nil;
    CloseSocket(FSocket);
    FConnected := 0;
  end;
end;

procedure TMutexClient.SetActive(AValue: Boolean);
begin
  if [csLoading, csReading] * ComponentState <> [] then
  begin
    FActiveLoaded := AValue;
    Exit;
  end;

  if [csDesigning] * ComponentState <> [] then
  begin
    FActive := AValue;
    Exit;
  end;

  if AValue then
    Connect
  else
    Disconnect;

  FActive := AValue;
end;

procedure TMutexClient.SetPort(AValue: Word);
begin
  if FActive then
    raise Exception.Create(SimpossibleToChangeWhenActive);

  if FPort = AValue then Exit;

  FPort := AValue;
end;

procedure TMutexClient.SetServerHost(AValue: AnsiString);
var
  IP: TStringArray;
  i: Integer;
  ZeroCount: Integer;
  FFCount: Integer;
  Octet: Longint;
label
  Err;
begin
  if FActive then
    raise Exception.Create(SimpossibleToChangeWhenActive);

  if (FServerHost = trim(AValue)) then Exit;

  if (trim(AValue) = '') then
  begin
    FServerHost := trim(AValue);
    Exit;
  end;

  if FServerHost <> AValue then
  begin
    IP := ExplodeString('.', AValue);
    if Length(IP) <> 4 then
      goto Err;

    ZeroCount := 0;
    FFCount := 0;
    for i := 0 to 3 do
    begin
      if TryStrToInt(IP[i], Octet) = False then
        goto Err;
      if not (Octet in [0..255]) then
        goto Err;
      if ((i = 0) or (i = 3)) and ((Octet = 0) or (Octet = 255)) then
        goto Err;
      if Octet = 0 then
        ZeroCount := ZeroCount + 1;
      if Octet = 255 then
        FFCount := FFCount + 1;
    end;
    if ZeroCount = 4 then
      goto Err;
    if FFCount = 4 then
      goto Err;

    FServerHost := AValue;
    Exit;
  end;

Err:
  raise Exception.Create(Format('The address "%s" is not a valid IPv4 address', [AValue]));
end;

procedure TMutexClient.ConnectionFinished(Sender: TObject);
begin
  CloseSocket(FSocket);
  InterLockedExchange(FConnected, 0);

  // TSocket 32 bits sized
  {$IF SizeOf(TSocket)=4}
  InterLockedExchange(Integer(FSocket), 0);
  {$IFEND}

  {$IF SizeOf(TSocket)=8}
  InterLockedExchange64(Int64(FSocket), 0);
  {$IFEND}

  InterlockedExchangePointer(Pointer(FConnectionStatusThread), nil);
end;

{$IFDEF FPC}
function TMutexClient.InterLockedExchangePointer(var Target: Pointer; Source: Pointer): Pointer;
begin
  Result := InterLockedExchange (Target, Source);
end;
{$ENDIF}

procedure TMutexClient.Loaded;
begin
  inherited Loaded;
  SetActive(FActiveLoaded);
end;

constructor TMutexClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPort := MUTEX_CLIENT_PORT;//51342;
  FActive := False;
  FConnected := 0;
  FActiveLoaded := False;
end;

destructor TMutexClient.Destroy;
begin
  SetActive(False);
  inherited Destroy;
end;

function TMutexClient.TryEnter: Boolean;
var
  ADefaultBehavior: Boolean;
begin
  Result := TryEnter(ADefaultBehavior);
end;

function TMutexClient.TryEnter(out PickedTheDefaultBehavior: Boolean): Boolean;
begin
  Result := FDefaultBehavior;
  PickedTheDefaultBehavior := True;
  if FActive then
  begin
    // if not connected, connect
    if FConnected = 0 then
      Connect;

    // if still disconnected, Exit
    if FConnected = 0 then
      Exit;

    if FConnectionStatusThread = nil then
      Exit;

    PickedTheDefaultBehavior := False;
    Result := FConnectionStatusThread.TryEnter;
  end;
end;

function TMutexClient.Leave: Boolean;
begin
  Result := True;

  if FActive then
  begin
    // if not connected, connect
    if FConnected = 0 then
      Connect;

    // if still disconnected, Exit
    if FConnected = 0 then
      Exit;

    if FConnectionStatusThread = nil then
      Exit;

    Result := FConnectionStatusThread.Leave;
  end;
end;

end.

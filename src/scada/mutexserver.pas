{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Unit que implementa um mutex de rede.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Unit that implements a network mutex.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Removed Extctrls unit
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
{$ENDIF}
unit mutexserver;

{$I ../common/delphiver.inc}
interface


uses
  Classes,
  SysUtils,
  socket_types,
  CrossEvent,
  crossthreads,
  socketserver,
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
  MUTEX_SERVER_PORT = 52321;//51342;


type
  { TAcceptThread }

  TAcceptThread = class(TSocketAcceptThread)
  private
    FMutex: TCriticalSection;
  protected
    procedure LaunchNewThread; override;
  public
    constructor Create(CreateSuspended: Boolean; ServerSocket: TSocket; ServerMutex: syncobjs.TCriticalSection; AddClientThread, RemoveClientThread: TNotifyEvent);
  end;

  { TClientThread }

  TClientThread = class(TSocketClientThread)
  private
    FMutex: TCriticalSection;
    FIntoCriticalSection: Boolean;
  protected
    procedure ThreadLoop; override;
  public
    constructor Create(CreateSuspended: Boolean; ClientSocket: TSocket; ClientSockinfo: TSockAddr; ServerMutex: syncobjs.TCriticalSection; RemoveClientThread: TNotifyEvent);
  end;

  { TMutexServer }

  TMutexServer = class(TComponent)
  private
    FActive: Boolean;
    FActiveLoaded: Boolean;
    FPort: Word;
    FSocket: TSocket;
    FMutex: TCriticalSection;
    FAcceptThread: TAcceptThread;
    FClients: array of TClientThread;

    procedure SetActive(AValue: Boolean);
    procedure SetPort(AValue: Word);
    procedure AddClientThread(Sender: TObject);
    procedure RemoveClientThread(Sender: TObject);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Active: Boolean read FActive write SetActive stored True default False;
    property Port: Word read FPort write SetPort stored True default MUTEX_SERVER_PORT;//52321;
  end;


implementation


uses
  dateutils, hsstrings
{$IF defined(WIN32) or defined(WIN64)}
 , Windows
{$IFEND}
  ;


procedure TClientThread.ThreadLoop;
var
  ClientCmd: Byte;
  Response: Byte;
  FaultCount: Longint;
  Quit: Boolean;
  LastPingSent: TDateTime;
const
  FaultLimit = 10;

  procedure ProcClientCommand(Cmd: Byte);
  begin
    case Cmd of
      2:  begin
            if FIntoCriticalSection or FMutex.TryEnter then
            begin
              FIntoCriticalSection := True;
              LastPingSent := Now;
              Response := 21;
            end
            else
            begin
              FIntoCriticalSection := False;
              Response := 20;
            end;
            if SocketSend(FSocket, @Response, 1, 0, 1000) < 1 then
              FaultCount := FaultLimit + 1;
          end;
      3:  begin
            try
              if FIntoCriticalSection then
              begin
                FMutex.Leave;
                FIntoCriticalSection := False;
                Response := 30;
              end
              else
                Response := 31;
            except
              Response := 32;
            end;

            if SocketSend(FSocket, @Response, 1, 0, 1000) < 1 then
              FaultCount := FaultLimit + 1;
          end;
      253: Quit := True; // client was finished
      254:  begin // client ping response
              FaultCount := 0;
              LastPingSent := Now;
            end;
    end;
  end;

begin
  //command and responses id list:
  //2  - Try enter on server mutex.
  //20 - Out of server mutex
  //21 - Into server Mutex

  //3 - Leave the server mutex.
  //30 - Out server mutex
  //31 - The client dont own the mutex.

  //253 - Connection closed...
  //254 - Ping response (from client to server)
  //255 - Ping request (from server to client)
  FaultCount := 0;
  Quit := False;

  LastPingSent := Now;
  while ((not Terminated) and (not Quit)) and (FaultCount < FaultLimit) do
  begin
    // if more than one seconds was elapsed, send a ping command
    if MilliSecondsBetween(Now, LastPingSent) >= 1000 then
    begin
      Response := 255;

      if SocketSend(FSocket, @Response, 1, 0, 1000) < 1 then
      begin
        FaultCount := FaultLimit + 1;
        Break;
      end;

      LastPingSent := Now;
      if SocketRecv(FSocket, @Response, 1, 0, 1000) >= 1 then
        ProcClientCommand(Response)
      else
        Inc(FaultCount);
    end;

    if SocketRecv(FSocket, @ClientCmd, 1{byte to read}, 0{noflasgs}, 5{ms}) = 1 then
    begin
      ProcClientCommand(ClientCmd);
    end;
  end;

  // if server was terminated, quit the client side
  if Terminated or (FaultCount >= FaultLimit) then
  begin
    Response := 253;
    SocketSend(FSocket, Pbyte(@Response), 1, 0, 1000);
  end;

  // leaves the mutex
  if FIntoCriticalSection then
  begin
    FMutex.Leave;
    FIntoCriticalSection := False;
  end;
end;

constructor TClientThread.Create(CreateSuspended: Boolean; ClientSocket: TSocket; ClientSockinfo: TSockAddr; ServerMutex: syncobjs.TCriticalSection; RemoveClientThread: TNotifyEvent);
begin
  inherited Create(CreateSuspended, ClientSocket, ClientSockinfo, RemoveClientThread);
  FMutex := ServerMutex;
  FIntoCriticalSection := False;
end;

{ TAcceptThread }

procedure TAcceptThread.LaunchNewThread;
begin
  // launch a new thread that will handle this new connection
  SetBlockingMode(ClientSocket, MODE_NONBLOCKING);
  FClientThread := TClientThread.Create(True, ClientSocket, ClientSockinfo, FMutex, FRemoveClientThread);
  Synchronize(@AddClientToMainThread);
  FClientThread.WakeUp;
end;

constructor TAcceptThread.Create(CreateSuspended: Boolean; ServerSocket: TSocket; ServerMutex: syncobjs.TCriticalSection; AddClientThread, RemoveClientThread: TNotifyEvent);
begin
  inherited Create(CreateSuspended, ServerSocket, AddClientThread, RemoveClientThread);
  FMutex := ServerMutex;
end;

{ TMutexServer }

procedure TMutexServer.SetActive(AValue: Boolean);
var
{$IF defined(FPC) and defined(UNIX)}
  Channel: sockaddr;
{$IFEND}
{$IF defined(FPC) and defined(WINCE)}
  Channel: sockaddr_in;
{$IFEND}
{$IF defined(WIN32) or defined(WIN64)}
  Channel: sockaddr_in;
{$IFEND}
  ReuseAddr: Longint;
  i: Longint;
begin
  ReuseAddr := 1;

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

  if FActive = AValue then Exit;

  if AValue then
  begin
    // creates the socket
{$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
    // UNIX and Windows CE
    FSocket := fpSocket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if FSocket < 0 then
    begin
      FActive := False;
      //RefreshLastOSError;
      Exit;
    end;
{$ELSE}
    // Windows 32 and 64 bits
    FSocket := Socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if FSocket = INVALID_SOCKET then
    begin
      FActive := False;
      //RefreshLastOSError;
      Exit;
    end;
{$IFEND}

{$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
    fpsetsockopt(FSocket, SOL_SOCKET,  SO_REUSEADDR, @reuse_addr, SizeOf(reuse_addr));
{$IFEND}
{$IF defined(WIN32) or defined(WIN64)}
    // Windows
    setsockopt(FSocket, SOL_SOCKET, SO_REUSEADDR, @ReuseAddr, SizeOf(ReuseAddr));
{$IFEND}

    // set the non-blocking mode
    SetBlockingMode(FSocket, MODE_NONBLOCKING);

    Channel.sin_family := AF_INET;
    Channel.sin_addr.S_addr := INADDR_ANY;
    Channel.sin_port := htons(FPort); //PORT NUMBER

{$IF defined(FPC) AND (defined(UNIX) OR defined(WINCE))}
    if fpBind(FSocket,@channel,SizeOf(channel)) <> 0 then
    begin
      CloseSocket(FSocket);
      FActive := False;
      Exit;
    end;

    if fpListen(FSocket, SOMAXCONN) <> 0 then
    begin
      CloseSocket(FSocket);
      FActive := False;
      Exit;
    end;
{$IFEND}

{$IF defined(WIN32) OR defined(WIN64)}
    if bind(FSocket, Channel, SizeOf(Channel)) <> 0 then
    begin
      CloseSocket(FSocket);
      FActive := False;
      Exit;
    end;

    if listen(FSocket, SOMAXCONN) <> 0 then
    begin
      CloseSocket(FSocket);
      FActive := False;
      Exit;
    end;
{$IFEND}

    // wait for connections?? must be done on another thread, because accept
    // is a blocking call
    FAcceptThread := TAcceptThread.Create(True, FSocket, FMutex, @AddClientThread, @RemoveClientThread);
    FAcceptThread.WakeUp;
  end
  else
  begin
    // close the socket
    closesocket(FSocket);
    // destroy the threads from all clients and close the socket
    FAcceptThread.Terminate;
    FAcceptThread.Destroy;
    closesocket(FSocket);

    // destroy all client threads
    for i := High(FClients) downto 0 do
    begin
      FClients[i].Terminate;
      //FClients[i].de;
    end;
  end;
  FActive := AValue;
end;

procedure TMutexServer.SetPort(AValue: Word);
begin
  if FActive then
    raise Exception.Create(SimpossibleToChangeWhenActive);

  if FPort = AValue then Exit;

  FPort := AValue;
end;

procedure TMutexServer.AddClientThread(Sender: TObject);
var
  i: Longint;
  Found: Boolean;
begin
  if not (Sender is TClientThread) then
    raise Exception.Create(SInvalidClass);

  // find the object in object list
  Found := False;
  for i := 0 to High(FClients) do
  begin
    if FClients[i] = Sender then
    begin
      Found := True;
      Break;
    end;
  end;

  if not Found then
  begin
    i := Length(FClients);
    SetLength(FClients, i + 1);
    FClients[i] := TClientThread(Sender);
  end;
end;

procedure TMutexServer.RemoveClientThread(Sender: TObject);
var
  i: Longint;
  Found: Boolean;
  H: Longint;
begin
  if not (Sender is TClientThread) then
    raise Exception.Create(SInvalidClass);

  // find the object in object list
  Found := False;
  for i := 0 to High(FClients) do
  begin
    if FClients[i] = Sender then
    begin
      Found := True;
      Break;
    end;
  end;

  if Found then
  begin
    H := High(FClients);
    FClients[i] := FClients[H];
    SetLength(FClients, H);
  end;
end;

procedure TMutexServer.Loaded;
begin
  inherited Loaded;
  SetActive(FActiveLoaded);
end;

constructor TMutexServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPort := MUTEX_SERVER_PORT;//51342;
  FMutex := syncobjs.TCriticalSection.Create;
end;

destructor TMutexServer.Destroy;
begin
  SetActive(False);
  FMutex.Destroy;
  inherited Destroy;
end;

end.

{$i ../common/language.inc}
//: Unix socket functions.
unit sockets_unix;

interface

uses
  unix,
  baseunix,
  Sockets,
  socket_types,
  commtypes,
  termio;


{: Function that receive data of a socket. Their parameters are the same of the
function recv/fprecv, with a extra parameter that is the maximum timout to
receive all requested data on socket. }
function SocketRecv(Sock: TSocket; Buf: Pbyte; Len: Cardinal; Flags, Timeout: Longint): Longint;

{: Function that sends data through the socket. Their parameters are the same of
the function send/fpsend, with a extra parameter that is the maximum timout to
send all requested data. }
function SocketSend(Sock: TSocket; Buf: Pbyte; Len: Cardinal; Flags, Timeout: Longint): Longint;

{: Sets the socket operation mode.
@seealso(MODE_NONBLOCKING)
@seealso(MODE_BLOCKING) }
function SetBlockingMode(Fd: TSocket; Mode: Longint): Longint;

{: Connect function with timeout. Their parameters are the same of the functions
connect/fpconnect, with a extra parameter that is the maximum timeout of the
connection establishment in milliseconds.
@returns(0 if the connection was estabilished successful.) }
function ConnectWithTimeout(Sock: TSocket; Address: PSockAddr; AddressLen: t_socklen; Timeout: Longint): Longint;
function ConnectWithoutTimeout(Sock: TSocket; Address: PSockAddr; AddressLen: t_socklen): Longint;

{: Check the current connection state and updates the state of the communication port.
   @returns(@True if stills connected.) }
function CheckConnection(var CommResult: TIOResult; var IncRetries: Boolean; var FSocket: TSocket; CloseSocketProc: TConnectEvent; DoCommPortDisconected: TDisconnectNotifierProc): Boolean;

{: Waits for a incoming connection.
@returns(@True if a incoming connection was done.) }
function WaitForConnection(AListenerSocket: TSocket; timeout: Longint): Boolean;

{: Rerturn how many bytes are available on receive buffer.
@returns(A value bigger than zero if data are available on the receive
         buffer, zero if no data on the receive buffer and -1 on error.) }
function GetNumberOfBytesInReceiveBuffer(Socket: TSocket): Longint;


{$IFDEF DARWIN}
const
  MSG_NOSIGNAL = $20000;
{$ENDIF}


implementation


function SetBlockingMode(Fd: TSocket; Mode: Longint): Longint;
var
  OldFlags: Longint;
begin
  OldFlags := FpFcntl(Fd, F_GETFL, 0);
  if (OldFlags < 0) then
  begin
    Result := OldFlags;
    Exit;
  end;

  if Mode = MODE_NONBLOCKING then
    OldFlags := OldFlags or O_NONBLOCK
  else
    OldFlags := OldFlags xor O_NONBLOCK;

  Result := FpFcntl(Fd, F_SETFL, OldFlags);
end;

function ConnectWithTimeout(Sock: TSocket; Address: PSockAddr; AddressLen: t_socklen; Timeout: Longint): Longint;
var
  Sel: tpollfd;
  Mode: Longint;
begin
  Result := 0;

  if fpconnect(Sock, Address, AddressLen) <> 0 then
  begin
    if fpGetErrno = ESysEINPROGRESS then
      begin
        Sel.fd := Sock;
        Sel.events := POLLIN or POLLPRI or POLLOUT;
        Sel.revents := 0;

        Mode := FpPoll(@Sel, 1, Timeout);

        if (Mode > 0) then
          begin
            if   ((Sel.revents and POLLERR) = POLLERR)
              or ((Sel.revents and POLLHUP) = POLLHUP)
              or ((Sel.revents and POLLNVAL) = POLLNVAL) then
              Result := -1  // error
            else
              Result := 0;  // connection is fine
          end
        else if Mode = 0 then
          Result := -2  // timeout?
        else
          Result := -1; // error
      end
    else
      Result := -1;   // error
  end;
end;

function ConnectWithoutTimeout(Sock: TSocket; Address: PSockAddr; AddressLen: t_socklen): Longint;
begin
  Result := 0;

  if fpconnect(Sock, Address, AddressLen) <> 0 then
  begin
    Result := -1;   // error
  end;
end;

function SocketRecv(Sock: TSocket; Buf: Pbyte; Len: Cardinal; Flags, Timeout: Longint): Longint;
var
  Sel: tpollfd;
  Mode: Longint;
begin
  Result := fprecv(Sock, Buf, Len, Flags or msg_nosignal);

  if Result < 0 then
  begin
    if fpGetErrno in [ESysEINTR, ESysEAGAIN] then
      begin
        Sel.fd := Sock;
        Sel.events := POLLIN;

        Mode := FpPoll(@Sel, 1, Timeout);

        if (Mode > 0) then
          begin
            if   ((Sel.revents and POLLERR) = POLLERR)
              or ((Sel.revents and POLLHUP) = POLLHUP)
              or ((Sel.revents and POLLNVAL) = POLLNVAL) then
              Result := -1  // error
            else
              Result := fprecv(Sock, Buf, Len, Flags);  // connection is fine
          end
        else if Mode = 0 then
          Result := -2  // timeout?
        else
          Result := -1; // error
      end
    else
      Result := -1;
  end;
end;

function SocketSend(Sock: TSocket; Buf: Pbyte; Len: Cardinal; Flags, Timeout: Longint): Longint;
var
  Sel: tpollfd;
  Mode: Longint;
begin
  Result := fpsend(Sock, Buf, Len, Flags or msg_nosignal);

  if Result < 0 then
  begin
    if fpGetErrno in [ESysEINTR, ESysEAGAIN] then
      begin
        Sel.fd := Sock;
        Sel.events := POLLOUT;

        Mode := FpPoll(@Sel, 1, Timeout);

        if (Mode > 0) then
          begin
            if   ((Sel.revents and POLLERR) = POLLERR)
              or ((Sel.revents and POLLHUP) = POLLHUP)
              or ((Sel.revents and POLLNVAL) = POLLNVAL) then
              Result := -1  // error
            else
              Result := fpsend(Sock, Buf, Len, Flags);  // connection is fine
          end
        else if Mode = 0 then
          Result := -2  // timeout?
        else
          Result := -1; // error
      end
    else
      Result := -1;
  end;
end;

function CheckConnection(var CommResult: TIOResult; var IncRetries: Boolean; var FSocket: TSocket; CloseSocketProc: TConnectEvent; DoCommPortDisconected: TDisconnectNotifierProc): Boolean;
var
  RetVal: Longint;
  NBytes: Longint;
  Sel: tpollfd;
  Closed: Boolean;
begin
  Result := True;

  RetVal := 0;
  NBytes := 0;
  RetVal := FpIOCtl(FSocket, FIONREAD, @NBytes);

  if RetVal <> 0 then
  begin
    if Assigned(CloseSocketProc) then
      CloseSocketProc(Closed);
    if Assigned(DoCommPortDisconected) then
      DoCommPortDisconected();
    CommResult := iorPortError;
    Result := False;
    Exit;
  end;

  if NBytes > 0 then
  begin
    // there is something in receive buffer, it doesn't seem the socket has been closed
    Result := True;
    Exit;
  end;


  Sel.fd := FSocket;
  Sel.events := POLLIN or POLLOUT or POLLPRI;
  Sel.revents := 0;

  RetVal := FpPoll(@Sel, 1, 1);

  if RetVal = 0 then
  begin
    // timeout, appears to be ok
    Result := True;
    CommResult := iorTimeOut;
    IncRetries := True;
    Exit;
  end;

  if RetVal < 0 then
  begin
    // error on socket
    if Assigned(CloseSocketProc) then
      CloseSocketProc(Closed);
    if Assigned(DoCommPortDisconected) then
      DoCommPortDisconected();
    CommResult := iorPortError;
    Result := False;
    Exit;
  end;

  if RetVal = 1 then
  begin
    // seems there is something in our receive buffer
    if   ((Sel.revents and POLLERR) = POLLERR)
      or ((Sel.revents and POLLHUP) = POLLHUP)
      or ((Sel.revents and POLLNVAL) = POLLNVAL) then
    begin
      if Assigned(CloseSocketProc) then
        CloseSocketProc(Closed);
      if Assigned(DoCommPortDisconected) then
        DoCommPortDisconected();
      CommResult := iorPortError;
      Result := False;
      Exit;
    end;

    // now we check how many bytes are in receive buffer
    RetVal := FpIOCtl(FSocket, FIONREAD, @NBytes);

    if RetVal <> 0 then
    begin
      // some error occured
      if Assigned(CloseSocketProc) then
        CloseSocketProc(Closed);
      if Assigned(DoCommPortDisconected) then
        DoCommPortDisconected();
      CommResult := iorPortError;
      Result := False;
      Exit;
    end;

    if NBytes = 0 then
    begin
      if Assigned(CloseSocketProc) then
        CloseSocketProc(Closed);
      if Assigned(DoCommPortDisconected) then
        DoCommPortDisconected();
      CommResult := iorNotReady;
      Result := False;
      Exit;
    end;

    IncRetries := True;
  end;
end;

function WaitForConnection(AListenerSocket: TSocket; Timeout: Longint): Boolean;
var
  Sel: tpollfd;
  Mode: Longint;
begin
  Result := False;

  Sel.fd := AListenerSocket;
  Sel.events := POLLIN or POLLPRI or POLLOUT;
  Sel.revents := 0;

  Mode := FpPoll(@Sel, 1, Timeout);

  if Mode > 0 then
    begin
      if   ((Sel.revents and POLLERR) = POLLERR)
        or ((Sel.revents and POLLHUP) = POLLHUP)
        or ((Sel.revents and POLLNVAL) = POLLNVAL) then
        Result := False  // error
      else
        Result := True;  // connection is fine
    end
  else if Mode = 0 then
    Result := False  // timeout?
  else
    Result := False; // error
end;

function GetNumberOfBytesInReceiveBuffer(Socket: TSocket): Longint;
var
  RetVal: Longint;
  NBytes: Longint;
begin
  Result := 0;

  RetVal := FpIOCtl(Socket, FIONREAD, @NBytes);

  if RetVal <> 0 then
  begin
    Result := -1;
    Exit;
  end;

  if NBytes > 0 then
    Result := NBytes;
end;

end.

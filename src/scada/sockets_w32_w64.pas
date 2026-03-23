{$i ../common/language.inc}
//: Windows socket functions.
unit sockets_w32_w64;

interface

uses
  Windows,
{$IFDEF FPC}
  WinSock2,
{$ELSE}
  WinSock,
{$ENDIF}
  socket_types,
  hsstrings,
  commtypes;


{: Function that receive data of a socket. Their parameters are the same of the
function recv/fprecv, with a extra parameter that is the maximum timout to
receive all requested data on socket. }
function SocketRecv(Sock: TSocket; Buf: PByte; Len: Cardinal; Flags, TimeOut: Longint): Longint;

{: Function that sends data through the socket. Their parameters are the same of
the function send/fpsend, with a extra parameter that is the maximum timout to
send all requested data. }
function SocketSend(Sock: TSocket; Buf: PByte; Len: Cardinal; Flags, TimeOut: Longint): Longint;

{: Sets the socket operation mode.
@seealso(MODE_NONBLOCKING)
@seealso(MODE_BLOCKING) }
function SetBlockingMode(Sock: TSocket; Mode: u_long): Longint;

{: Connect function with timeout. Their parameters are the same of the functions
connect/fpconnect, with a extra parameter that is the maximum timeout of the
connection establishment in milliseconds.
@returns(0 if the connection was estabilished successful.) }
function ConnectWithTimeout(Sock: TSocket; Address: PSockAddr; AddressLen: t_socklen; TimeOut: Longint): Longint;

{: Check the current connection state and updates the state of the communication port.
   @returns(@True if stills connected.) }
function CheckConnection(var CommResult: TIOResult; var IncRetries: Boolean; var ASocket: TSocket; CloseSocketProc: TConnectEvent; DoCommPortDisconected: TDisconnectNotifierProc): Boolean;

{: Waits for a incoming connection.
   @returns(@True if a incoming connection was done.)}
function WaitForConnection(AListenerSocket: TSocket; TimeOut: Longint): Boolean;

{: Rerturn how many bytes are available on receive buffer.
@returns(A value bigger than zero if data are available on the receive
         buffer, zero if no data on the receive buffer and -1 on error.) }
function GetNumberOfBytesInReceiveBuffer(Socket: TSocket): Longint;


implementation


uses
  SysUtils;


function SetBlockingMode(Sock: TSocket; Mode: u_long): Longint;
begin
  if ioctlsocket(Sock, Longint(FIONBIO), Mode) = SOCKET_ERROR then
    Result := -1
  else
    Result := 0;
end;

function ConnectWithTimeout(Sock: TSocket; Address: PSockAddr; AddressLen: t_socklen; TimeOut: Longint): Longint;
var
  Sel: TFDSet;
  Mode: Longint;
  ATimeVal: TTimeVal;
  P: PTimeVal;
begin
  if TimeOut = -1 then
    P := nil
  else
    begin
      ATimeVal.tv_Sec := TimeOut div 1000;
      ATimeVal.tv_Usec := (TimeOut mod 1000) * 1000;
      P := @ATimeVal;
    end;

  Result := 0;

  if connect(Sock, Address^, AddressLen) <> 0 then
  begin
    if WSAGetLastError = WSAEWOULDBLOCK then
      begin
        FD_ZERO(Sel);
        FD_SET(Sock, Sel);
        Mode := select(Sock, nil, @Sel, nil, P);

        if Mode < 0 then
          Result := -1
        else if Mode > 0 then
          Result := 0
        else if Mode = 0 then
          Result := -2;
      end
    else
      Result := -1;
  end;
end;

function SocketRecv(Sock: TSocket; Buf: Pbyte; Len: Cardinal; Flags, TimeOut: Longint): Longint;
var
  Sel: TFDSet;
  Mode: Longint;
  ATimeVal: TTimeVal;
  P: PTimeVal;
begin
  if TimeOut = -1 then
    P := nil
  else
  begin
    ATimeVal.tv_Sec := TimeOut div 1000;
    ATimeVal.tv_Usec := (TimeOut mod 1000) * 1000;
    P := @ATimeVal;
  end;

  Result := recv(Sock, Buf^, Len, Flags);

  if Result = SOCKET_ERROR then
  begin
    if (WSAGetLastError = WSAEWOULDBLOCK) then
      begin
        FD_ZERO(Sel);
        FD_SET(Sock, Sel);
        Mode := select(Sock, @Sel, nil, nil, P);

        if (Mode < 0) then
          Result := -1
        else if (Mode > 0) then
          Result := recv(Sock, Buf^, Len, Flags)
        else if (Mode = 0) then
          Result := -2;
      end
    else
      Result := -1;
  end;
end;

function SocketSend(Sock: TSocket; Buf: Pbyte; Len: Cardinal; Flags, TimeOut: Longint): Longint;
var
  Sel: TFDSet;
  Mode: Longint;
  ATimeVal: TTimeVal;
  P: ptimeval;
begin
  if TimeOut = -1 then
    P := nil
  else
  begin
    ATimeVal.tv_Sec := TimeOut div 1000;
    ATimeVal.tv_Usec := (TimeOut mod 1000) * 1000;
    P := @ATimeVal;
  end;

  Result := send(Sock, Buf^, Len, Flags);

  if Result = SOCKET_ERROR then
  begin
    if WSAGetLastError = WSAEWOULDBLOCK then
    begin
      FD_ZERO(Sel);
      FD_SET(Sock, Sel);
      Mode := select(Sock, nil, @Sel, nil, P);

      if (Mode < 0) then
        Result := -1
      else if (Mode > 0) then
        Result := send(Sock, Buf^, Len, Flags)
      else if (Mode = 0) then
        Result := -2;
    end
    else
      Result := -1;
  end;
end;

function CheckConnection(var CommResult: TIOResult; var IncRetries: Boolean; var ASocket: TSocket; CloseSocketProc: TConnectEvent; DoCommPortDisconected: TDisconnectNotifierProc): Boolean;
var
  RetVal: Longint;
  NBytes: Longint;
  ATimaValue: TTimeVal;
  ReadSet: TFDSet;
  Closed: Boolean;
begin
  Result := True;

  RetVal := 0;
  NBytes := 0;
  RetVal := ioctlsocket(ASocket, FIONREAD, @NBytes);

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

  if (NBytes > 0) then
  begin
    // there is something in receive buffer, it doesn't seem the socket has been closed
    Result := True;
    Exit;
  end;

  ATimaValue.tv_Usec := 1;
  ATimaValue.tv_Sec := 0;

  FD_ZERO(ReadSet);
  FD_SET(ASocket, ReadSet);
  RetVal := select(ASocket, @ReadSet, nil, nil, @ATimaValue);

  if (RetVal = 0) then
  begin
    // timeout, appears to be ok
    Result := True;
    CommResult := iorTimeOut;
    IncRetries := True;
    Exit;
  end;

  if (RetVal < 0) then
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

  if (RetVal = 1) then
  begin
    // seems there is something in our receive buffer
    // now we check how many Bytes are in receive buffer
    RetVal := ioctlsocket(ASocket, FIONREAD, @NBytes);

    if (RetVal <> 0) then
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

    if (NBytes = 0) then
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

function WaitForConnection(AListenerSocket: TSocket; TimeOut: Longint): Boolean;
var
  Sel: TFDSet;
  Mode: u_long;
  ATimeVal: TTimeVal;
  P: ptimeval;
begin
  if TimeOut = -1 then
    P := nil
  else
    begin
      ATimeVal.tv_Sec := TimeOut div 1000;
      ATimeVal.tv_Usec := (TimeOut mod 1000) * 1000;
      P := @ATimeVal;
    end;

  FD_ZERO(Sel);
  FD_SET(AListenerSocket, Sel);
  Mode := select(AListenerSocket, @Sel, nil, nil, P);

  if (Mode <= 0) then
    Result := False
  else if (Mode > 0) then
    Result := True;
end;

function GetNumberOfBytesInReceiveBuffer(Socket: TSocket): Longint;
var
  RetVal: Longint;
  NBytes: Longint;
begin
  Result := 0;

{$IFDEF FPC}
  RetVal:=ioctlsocket(Socket, FIONREAD, @NBytes);
{$ELSE}
  RetVal := ioctlsocket(Socket, FIONREAD, NBytes);
{$ENDIF}

  if RetVal <> 0 then
  begin
    Result := -1;
    Exit;
  end;

  if (NBytes > 0) then
    Result := NBytes;
end;


{$IF defined(WIN32) or defined(WIN64)}
var
  WSAData: TWSAData;
  Version: Word;


initialization
  // Winsock initialization
  Version := MAKEWORD( 2, 0 );

  // Check for error
  if WSAStartup( Version, {%H-}WSAData ) <> 0 then
    raise Exception.Create(SerrorInitializingWinsock);

  // check for correct Version
  if (LOBYTE(WSAData.wVersion) <> 2) or (HIBYTE(WSAData.wVersion) <> 0) then
  begin
    // incorrect WinSock Version
    WSACleanup();
    raise Exception.Create(SinvalidWinSockVersion);
  end;


finalization
  WSACleanup;
{$IFEND}


end.

{$i ../common/language.inc}
{:
@abstract(Some types used by sockets.)
@author(Fabio Luis Girardi fabio@pascalscada.com)
}
unit socket_types;

interface

uses
  // delphi ou lazarus sobre windows
{$IF defined(WIN32) or defined(WIN64)}
  WinSock;
{$ELSE}
  {$IF defined(FPC) AND (defined(UNIX) or defined(WINCE))}
  Sockets;
  {$IFEND}
{$IFEND}

type
  TConnectEvent = procedure(var Ok: Boolean) of object;

  //@exclude
{$IF defined(FPC) AND (FPC_FULLVERSION >= 20400)}
  {$IF defined(WIN32) or defined(WIN64)}
  t_socklen = tOS_INT;
  {$ELSE}
  t_socklen = TSockLen;
  {$IFEND}
{$ELSE}
  t_socklen = LongInt;
{$IFEND}

  {: Enumerates all kinds of client ports.
  @value ptTCP = TCP port.
  @value ptUDP = UDP port. }
  TPortType = (ptTCP, ptUDP);

  TDisconnectNotifierProc = procedure of object;


const
  //: Defines the non-blocking mode of socket (don't waits the end of the action).
  MODE_NONBLOCKING = 1;
  //: Defines the blocking mode of socket (waits the end of the action).
  MODE_BLOCKING = 0;


implementation


end.

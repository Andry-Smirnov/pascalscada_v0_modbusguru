{$i ../common/language.inc}
{:
  @abstract(Implements a multi-platform serial port driver.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
unit SerialPort;

interface

uses
  commtypes, CommPort, SysUtils, Classes, ctypes,
{$IF defined(WIN32) or defined(WIN64) OR defined(WINCE)}
  Registry,
  Windows,
{$IFEND}
{$IFDEF UNIX}
  {$IFNDEF DARWIN}
  Serial,
  {$ENDIF}
  Unix,
  BaseUnix,
  termio,
{$ENDIF}
  DateUtils;

type
  {: @name enumerates all baud rates.
  This baud rates are supported on all OSes.

  @value br110    = 110 bps
  @value br300    = 300 bps
  @value br600    = 600 bps
  @value br1200   = 1200 bps
  @value br2400   = 2400 bps
  @value br4800   = 4800 bps
  @value br9600   = 9600 bps
  @value br19200  = 19200 bps
  @value br38400  = 38400 bps
  @value br57600  = 57600 bps
  @value br115200 = 115200 bps }
  TSerialBaudRate = (
    br110, br300, br600, br1200, br2400, br4800, br9600,
    br19200, br38400, br57600, br115200, br230400, br460800,
    br500000, br576000, br921600, br1000000, br1152000,
    br1500000, br2000000, br2500000, br3000000, br3500000,
    br4000000
  );

  {: @name enumarates all stop bits.
  This values are supported on all OSes

  @value sb1 = 1 stop bit
  @value sb2 = 2 stop bit }
  TSerialStopBits = (sb1, sb2);

  {: @name enumerates all parity modes.
  This values are supported on all OSes.

  @value spNone Don't check the parity.
  @value spOdd  Check errors using the odd parity.
  @value spEven Check errors using the even parity. }
  TSerialParity = (spNone, spOdd, spEven);

  {: @name enumerates all data byte sizes.
  This values are supported on all OSes.

  @value db5 The data byte will have 5 bits of size.
  @value db6 The data byte will have 6 bits of size.
  @value db7 The data byte will have 7 bits of size.
  @value db8 The data byte will have 8 bits of size. }
  TSerialDataBits= (db5, db6, db7, db8);

  {: @abstract(Serial port driver. Working on  Windows, Linux and FreeBSD.)
     @author(Fabio Luis Girardi <fabio@pascalscada.com>)
     @seealso(TCommPortDriver) }

{$IFDEF DARWIN}
  TSerialHandle = cint;

  TSerialState = record
    LineState: LongWord;
    tios: termios;
  end;
{$ENDIF}

  { TSerialPortDriver }

  TSerialPortDriver = class(TCommPortDriver)
  private
    FRenewHandleOnCommErr: Boolean;
    PActivatedOnLoad: Boolean;
    PPortNameLoaded: AnsiString;
    PPortName: AnsiString;
    PTimeout: LongInt;
    PBaundRate: TSerialBaudRate;
    PStopBits: TSerialStopBits;
    PParity: TSerialParity;
    PDataBits: TSerialDataBits;
    PAcceptAnyPortName: Boolean;
{$IF defined(WIN32) or defined(WIN64) OR defined(WINCE)}
    PPortEventName: AnsiString;
    PSavedDCB: DCB;
    PDCB: DCB;
    ComTimeouts: COMMTIMEOUTS;
    POverlapped: TOverlapped;
    PPortHandle: THandle;
{$ELSE}
    LockOpen: Boolean;
    PPortHandle: TSerialHandle;
    PSavedState: TSerialState;
{$IFEND}

    PPortDirPrefix : string;
    PBackupPortSettings: Boolean;
    PRWTimeout: LongInt;

    procedure SetRenewHandleOnCommErr(AValue: Boolean);
    procedure SetTimeOut(AValue: LongInt);
    procedure SetRWTimeout(AValue: LongInt);
    procedure SetBaundRate(AValue: TSerialBaudRate);
    procedure SetStopBits(AValue: TSerialStopBits);
    procedure SetParity(AValue: TSerialParity);
    procedure SetDataBits(AValue: TSerialDataBits);

    procedure SetDevDir(DDir: AnsiString);
    function GetDevDir: AnsiString;

    procedure SetCOMPort(AValue: AnsiString);
{$IF defined(WIN32) or defined(WIN64)}
    function MakeDCBString: AnsiString;
{$IFEND}
    //function COMExist(v: AnsiString): Boolean;
  protected
    procedure Read(Packet: PIOPacket); override;
    procedure Write(Packet: PIOPacket); override;
    //: @exclude
    procedure NeedSleepBetweenRW; override;
    //: @exclude
    procedure PortStart(var Ok: Boolean); override;
    //: @exclude
    procedure PortStop(var Ok: Boolean); override;
    //: @exclude
    function  ComSettingsOK: Boolean; override;
    //: @exclude
    procedure SetActive(AValue: Boolean); override;
    //: @exclude
    procedure Loaded; override;
  public
    //: @exclude
    procedure ClearALLBuffers; override;
    //: @seealso TCommPortDriver.RenewHandle
    procedure RenewHandle; override;
    //: @seealso TCommPortDriver.GetPortId
    function GetPortId: TPortUniqueID; override;

    function GetPendingInputBytes:LongInt;
  public
    {: Creates a new serial port driver with the following settings: baud rate 19200bps,
    8 data bits, 1 stop bits, without parity check and 100ms of timeout.
    @seealso(TCommPortDriver) }
    constructor Create(AOwner:TComponent); override;
    //: @exclude
    destructor  Destroy; override;
  published
    {: Serial port driver to be used. This names depends of operating system.
    On Windows the name is COMx, ob Linux is ttySx and on FreeBSD is cuadx. }
    property COMPort:AnsiString read PPortName write SetCOMPort;
    {: Folder where PascalSCADA will search and open (if Active=true) the serial
       port device on Linux/Unix operating systems.
    This property is useful for people that uses serial port emulators on these
    operating systems.
    On windows this property is useless, only visible by user project
    compatibility across multiple OS. }
    property DevDir : AnsiString read GetDevDir write SetDevDir;
    property RenewHandleOnCommError:Boolean read FRenewHandleOnCommErr write SetRenewHandleOnCommErr;
    //: How many time a read or write operation can take.
    property Timeout:LongInt read PTimeout write SetTimeOut stored true default 5;
    //: Delay between commands of read and write.
    property WriteReadDelay:LongInt read PRWTimeout write SetRWTimeout stored true default 20;
    {: Serial port baud rate.
    @seealso(TSerialBaundRate) }
    property BaudRate:TSerialBaudRate read PBaundRate write SetBaundRate stored true default br19200;
    {: Data byte size.
    @seealso(TSerialDataBits) }
    property DataBits:TSerialDataBits read PDataBits write SetDataBits stored true default db8;
    {: Parity check.
    @seealso(TSerialParity) }
    property Paridade:TSerialParity read PParity write SetParity stored true default spNone;
    {: Stop bits.
    @seealso(TSerialStopBits) }
    property StopBits: TSerialStopBits read PStopBits write SetStopBits stored true default sb1;
    {: If @true the driver will do a of the older settings of the serial port before
    open it, and restore when it's closed. }
    property BackupPortSettings: Boolean read PBackupPortSettings write PBackupPortSettings stored true default false;
    {: If @true the driver will accept any comm port name, even if it don´t
    exists on your system. }
    property AcceptAnyPortName: Boolean read PAcceptAnyPortName write PAcceptAnyPortName stored true default false;

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

    //: @seealso TCommPortDriver.ReadRetries
    property ReadRetries;
    //: @seealso TCommPortDriver.WriteRetries
    property WriteRetries;
    // tornar publica para o usuario saber e tomar medida quando desconectado
    function COMExist(AValue: AnsiString):Boolean;
{$IFDEF MSWINDOWS}
    function  GetPortas: string;
{$ENDIF}
  end;


{$IF defined(WIN32) or defined(WIN64) or defined(WINCE)}
function CTL_CODE( DeviceType, Func, Method, Access: Cardinal): Cardinal;

const
  METHOD_BUFFERED         = 0;
  METHOD_IN_DIRECT        = 1;
  METHOD_OUT_DIRECT       = 2;
  METHOD_NEITHER          = 3;
  FILE_DEVICE_SERIAL_PORT = $0000001B;
  FILE_ANY_ACCESS         = 0;
{$IFEND}

{$IFDEF UNIX}
  {$IFDEF LINUX}
var
  PortPrefix: array [0..7] of string = ('ttyADV', 'ttyAP', 'ttyS','ttyUSB', 'vttyAP', 'ttyMP', 'ttyr', 'ttyB');
//var PortPrefix:array [0..2] of AnsiString = ('tty', 'ttyUSB', 'ttyACM');
  {$ENDIF}
  {$IFDEF FREEBSD}
var
  PortPrefix: array [0..8] of string = ('cuad','cuau','cuaU','ttyu','ttyU', 'vttyAP', 'ttyMP', 'ttyr', 'ttyB');
//var PortPrefix:array [0..0] of AnsiString = ('cuad');
  {$ENDIF}
  {$IFDEF NETBSD}
var
  PortPrefix: array [0..8] of string = ('cuad','cuau','cuaU','ttyu','ttyU', 'vttyAP', 'ttyMP', 'ttyr', 'ttyB');
//var PortPrefix:array [0..0] of AnsiString = ('cuad');
  {$ENDIF}
  {$IFDEF OPENBSD}
var
  PortPrefix: array [0..8] of string = ('cuad','cuau','cuaU','ttyu','ttyU', 'vttyAP', 'ttyMP', 'ttyr', 'ttyB');
//var
//  PortPrefix:array [0..0] of AnsiString = ('cuad');
  {$ENDIF}
  {$ifdef SunOS}
var
  PortPrefix: array [0..0] of AnsiString = ('tty');
  {$ENDIF}
  {$ifdef Darwin}
var
  PortPrefix: array [0..0] of AnsiString = ('tty.');
  {$ENDIF}
{$ENDIF}


implementation


uses
  hsstrings
{$IFDEF UNIX}
  , crossdatetime
{$ENDIF}
  ;

{$IF defined(WIN32) or defined(WIN64) or defined(WINCE)}
function CTL_CODE( DeviceType, Func, Method, Access: Cardinal): Cardinal;
begin
  Result := (((DeviceType) shl 16) or ((Access) shl 14) or ((Func) shl 2) or (Method));
end;

var
 // copia a porta COM ajustada no Serialport.pas (SetCOMPort)
 CopyPort: AnsiString;
{$IFEND}


constructor TSerialPortDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PAcceptAnyPortName := False;
  FExclusiveDevice := True;
  PBaundRate := br19200;
  PDataBits := db8;
  PStopBits := sb1;
  PParity := spNone;
  PTimeout := 100;
  PRWTimeout := 20;
{$IFDEF UNIX}
  LockOpen := False;
  PPortDirPrefix := '/dev/';
{$ENDIF}
end;

destructor TSerialPortDriver.Destroy;
begin
  inherited Destroy;
end;

procedure TSerialPortDriver.NeedSleepBetweenRW;
begin
  if PRWTimeout > 0 then
    Sleep(PRWTimeout);
end;

{$IF defined(WIN32) or defined(WIN64)}
procedure TSerialPortDriver.Read(Packet: PIOPacket);
var
  Lidos: Cardinal;
  Tentativas: Cardinal;
begin
  // somente se a porta com existe
  if COMExist(CopyPort) then
  begin
    Tentativas := 0;

    Packet^.Received := 0;
    while (Packet^.Received < Packet^.ToRead) and (Tentativas < Packet^.ReadRetries) do
    begin
      ResetEvent(POverlapped.hEvent);
      POverlapped.Offset := 0;
      POverlapped.OffsetHigh := 0;
      ReadFile(PPortHandle, Packet^.BufferToRead[Packet^.Received], Packet^.ToRead-Packet^.Received, Lidos, @POverlapped);
      WaitForSingleObject(POverlapped.hEvent, PTimeout);
      // Foi mudado para FALSE para não travar em caso de desligamento do conversor USB
        // para maiores detalhes
        // https://learn.microsoft.com/en-us/windows/win32/api/ioapiset/nf-ioapiset-getoverlappedresult
        // procure pelo parametro "bWait"
      GetOverlappedResult(PPortHandle,POverlapped,Lidos,false);
      Packet^.Received := Packet^.Received + Lidos;
      Inc(Tentativas);
    end;
  end;
{$IFEND}

{$IFDEF UNIX}
procedure TSerialPortDriver.Read(Packet:PIOPacket);
var
  Lidos: LongInt;
  tentativas: Cardinal;
  Start: TDateTime;
  Req: TimeSpec;
  Rem: TimeSpec;
begin
  tentativas := 0;
  Start := CrossNow;

  Packet^.Received := 0;
  Packet^.ReadIOResult:=iorNone;
  while (Packet^.Received<Packet^.ToRead) and (tentativas<Packet^.ReadRetries) do
  begin
     fpseterrno(0);
     Lidos := FileRead(PPortHandle,Packet^.BufferToRead[Packet^.Received], Packet^.ToRead-Packet^.Received);
     if Lidos >= 0 then
     begin
       Packet^.Received := Packet^.Received + Lidos;
     end
     else
     begin
       Lidos := fpgeterrno;
       WriteLn('fpgeterrno=', Lidos);
       if Lidos = ESysEINVAL then
       begin
         WriteLn('Renew Handle called');
         RenewHandle;
       end;
     end;
     if (MilliSecondsBetween(CrossNow, Start) > PTimeout) then
     begin
        Inc(Tentativas);
        Start := CrossNow;
     end;
     // waits 0,1ms
     Req.tv_sec:=0;
     Req.tv_nsec:=100000;
     FpNanoSleep(@Req, @Rem);
  end;
{$ENDIF}

{$IF defined(WINCE)}
procedure TSerialPortDriver.Read(Packet: PIOPacket);
var
  Tentativas: LongInt;
begin
{$IFEND}
  Packet^.ReadRetries := Tentativas;
  if Packet^.ToRead > Packet^.Received then
    begin
      Packet^.ReadIOResult := iorTimeOut;
      if FRenewHandleOnCommErr then
         RenewHandle
      else if PClearBufOnErr then
        InternalClearALLBuffers;
    end
  else
    Packet^.ReadIOResult := iorOK;

  if Packet^.ReadIOResult <> iorOK then
    CommError(False, Packet^.ReadIOResult);
end;

{$IF defined(WIN32) or defined(WIN64)}
procedure TSerialPortDriver.Write(Packet: PIOPacket);
var
  Escritos: Cardinal;
begin
  // somente se a porta com existe
  if COMExist(CopyPort) then
  begin
    ResetEvent(POverlapped.hEvent);
    POverlapped.Offset := 0;
    POverlapped.OffsetHigh := 0;
    if not WriteFile(PPortHandle, Packet^.BufferToWrite[0], Packet^.ToWrite, Packet^.Written, @POverlapped) then
    begin
      case WaitForSingleObject(POverlapped.hEvent, PTimeout) of
        WAIT_OBJECT_0:  begin
                          Packet^.WriteIOResult := iorOK;
                          GetOverlappedResult(PPortHandle, POverlapped, Escritos, True);
                          Packet^.Written := Escritos;
                        end;
       else
         begin
           Packet^.WriteIOResult := iorTimeOut;
           if PClearBufOnErr then
             InternalClearALLBuffers;
         end;
      end;
    end
    else
      begin
        Packet^.WriteIOResult := iorOK;
      end;
  end;
{$IFEND}
{$IFDEF UNIX}
procedure TSerialPortDriver.Write(Packet: PIOPacket);
var
  Escritos: LongInt;
  Tentativas: Cardinal;
begin
  Tentativas := 0;

  Packet^.Written := 0;
  fpseterrno(0);
  while (Packet^.Written < Packet^.ToWrite) and (Tentativas < Packet^.WriteRetries) do
  begin
    Escritos := FileWrite(PPortHandle, Packet^.BufferToWrite[Packet^.Written], Packet^.ToWrite-Packet^.Written);
    if Escritos >= 0 then
    begin
      Packet^.Written := Packet^.Written + Escritos;
    end
    else
    begin
      Escritos := fpgeterrno;
      if Escritos = ESysEINVAL then
      begin
        WriteLn('Renew Handle called');
        RenewHandle;
      end;
    end;
    Inc(Tentativas);
  end;

  Packet^.WriteRetries := Tentativas;
  if Packet^.ToWrite>Packet^.Written then
  begin
    Packet^.WriteIOResult := iorTimeOut;
    if FRenewHandleOnCommErr then
      RenewHandle
    else
    begin
      if PClearBufOnErr then
        InternalClearALLBuffers;
    end;
  end
  else
    Packet^.WriteIOResult := iorOK;
{$ENDIF}
{$IF defined(WINCE)}
procedure TSerialPortDriver.Write(Packet: PIOPacket);
var
  Tentativas: LongInt;
begin
{$IFEND}
  if Packet^.WriteIOResult <> iorOK then
    CommError(True, Packet^.WriteIOResult);
end;

{$IF defined(WIN32) or defined(WIN64)}
procedure TSerialPortDriver.PortStart(var Ok: Boolean);
var
  StrDCB: AnsiString;
label
  Err1,
  Err2,
  Err3;
begin
  if PActive then
  begin
    Ok := True;
    Exit;
  end;
  PPortEventName := Name + '_' + PPortName;

  POverlapped.Offset := 0;
  POverlapped.OffsetHigh := 0;
  POverlapped.Internal := 0;
  POverlapped.InternalHigh := 0;
  POverlapped.hEvent :=  CreateEvent(nil, True, False, PChar(PPortEventName)) ;

  ComTimeouts.ReadIntervalTimeout := PTimeout;
  ComTimeouts.ReadTotalTimeoutMultiplier := 2;
  ComTimeouts.ReadTotalTimeoutConstant := (PTimeout div 4);
  ComTimeouts.WriteTotalTimeoutMultiplier := 2;
  ComTimeouts.WriteTotalTimeoutConstant := (PTimeout div 4);

  // desabilitado pois impedia a reconexão da porta serial após evendo de desconexão
  //if not COMExist(PPortName) then
  //  goto Err1;

  PPortHandle := CreateFile(PChar('\\.\'+ PPortName), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, FILE_FLAG_WRITE_THROUGH or FILE_FLAG_OVERLAPPED, 0);
  if PPortHandle=INVALID_HANDLE_VALUE then
  begin
    RefreshLastOSError;
    //goto Err1;
  end;

  // sets the length of the buffers of read and write
  if not SetupComm(PPortHandle, 8192, 8192) then
  begin
    RefreshLastOSError;
    goto Err1;
  end;

  // makes a DCB string
  StrDCB := MakeDCBString;
  // Fill with zeros the structure
  FillMemory(@PDCB, SizeOf(DCB), 0);
  PDCB.DCBlength := SizeOf(DCB);
  if not BuildCommDCB(PChar(StrDCB), PDCB) then
  begin
    RefreshLastOSError;
    goto Err2;
  end;

  // backup the old settings
  if PBackupPortSettings then
    GetCommState(PPortHandle, PSavedDCB);

  // sets the new DCB struture
  if not SetCommState(PPortHandle, PDCB) then
  begin
    RefreshLastOSError;
    goto Err3;
  end;

  // sets the timeouts
  if not SetCommTimeouts(PPortHandle,ComTimeouts) then
  begin
    RefreshLastOSError;
    goto Err3;
  end;

  InternalClearALLBuffers;

  Ok := True;
  PActive := True;
  Exit;

Err3:
  if PBackupPortSettings then
    SetCommState(PPortHandle, PSavedDCB);
Err2:
  CloseHandle(PPortHandle);
Err1:
  PPortEventName := '';
  CloseHandle(POverlapped.hEvent);
  POverlapped.hEvent := 0;
  Ok := False;
  PActive := False;
{$IFEND}
{$IF defined(WINCE)}
procedure TSerialPortDriver.PortStart(var Ok: Boolean);
begin
  //ToDO
{$IFEND}
{$IFDEF UNIX}
procedure TSerialPortDriver.PortStart(var Ok: Boolean);
var
  R: LongInt;
  Tios: termios;
begin
  RefreshLastOSError;
  // open the serial port
  PPortHandle := fpopen('/dev/' + PPortName, O_RDWR or O_NOCTTY or O_NONBLOCK);
  if PPortHandle<0 then begin
{$IFDEF UNIX}
     WriteLn('Failed to open serial port '+PPortName);
{$ENDIF}
     RefreshLastOSError;
     Ok := False;
     PActive := False;
     Exit;
  end;
  
  // backup the serial port settings
  {$IFNDEF DARWIN}
  if PBackupPortSettings then
    PSavedState := SerSaveState(PPortHandle);
  {$ENDIF}

  R := 0;
  fillchar(Tios, SizeOf(Tios), #0);

  Tios.c_oflag := 0;
  Tios.c_lflag := 0;

  // sets the baudrate
  case PBaundRate of
     br110:  begin
               Tios.c_ispeed := B110;
               Tios.c_ospeed := B110;
             end;
     br300:  begin
               Tios.c_ispeed := B300;
               Tios.c_ospeed := B300;
             end;
     br600:  begin
               Tios.c_ispeed := B600;
               Tios.c_ospeed := B600;
             end;
     br1200: begin
               Tios.c_ispeed := B1200;
               Tios.c_ospeed := B1200;
             end;
     br2400: begin
               Tios.c_ispeed := B2400;
               Tios.c_ospeed := B2400;
             end;
     br4800: begin
               Tios.c_ispeed := B4800;
               Tios.c_ospeed := B4800;
             end;
     br9600: begin
               Tios.c_ispeed := B9600;
               Tios.c_ospeed := B9600;
             end;
     br19200:  begin
                 Tios.c_ispeed := B19200;
                 Tios.c_ospeed := B19200;
               end;
     br38400:  begin
                 Tios.c_ispeed := B38400;
                 Tios.c_ospeed := B38400;
               end;
     br57600:  begin
                 Tios.c_ispeed := B57600;
                 Tios.c_ospeed := B57600;
               end;
     br115200: begin
                 Tios.c_ispeed := B115200;
                 Tios.c_ospeed := B115200;
               end;
     br230400: begin
                 Tios.c_ispeed := B230400;
                 Tios.c_ospeed := B230400;
               end;
     br460800: begin
                 Tios.c_ispeed := B460800;
                 Tios.c_ospeed := B460800;
               end;
     br500000: begin
                 Tios.c_ispeed := B500000;
                 Tios.c_ospeed := B500000;
               end;
     br576000: begin
                 Tios.c_ispeed := B576000;
                 Tios.c_ospeed := B576000;
               end;
     br921600:   begin
                   Tios.c_ispeed := B921600;
                   Tios.c_ospeed := B921600;
                 end;
     br1000000:  begin
                   Tios.c_ispeed := B1000000;
                   Tios.c_ospeed := B1000000;
                 end;
     br1152000:  begin
                   Tios.c_ispeed := B1152000;
                   Tios.c_ospeed := B1152000;
                 end;
     br1500000:  begin
                   Tios.c_ispeed := B1500000;
                   Tios.c_ospeed := B1500000;
                 end;
     br2000000:  begin
                   Tios.c_ispeed := B2000000;
                   Tios.c_ospeed := B2000000;
                 end;
     br2500000:  begin
                   Tios.c_ispeed := B2500000;
                   Tios.c_ospeed := B2500000;
                 end;
     br3000000:  begin
                   Tios.c_ispeed := B3000000;
                   Tios.c_ospeed := B3000000;
                 end;
     br3500000:  begin
                   Tios.c_ispeed := B3500000;
                   Tios.c_ospeed := B3500000;
                 end;
     br4000000:  begin
                   Tios.c_ispeed := B4000000;
                   Tios.c_ospeed := B4000000;
                 end;
*)
  end;
  
  Tios.c_cflag := Tios.c_ispeed or CREAD or CLOCAL;
  
  // databits
  case PDataBits of
     db5: Tios.c_cflag := Tios.c_cflag or CS5;
     db6: Tios.c_cflag := Tios.c_cflag or CS6;
     db7: Tios.c_cflag := Tios.c_cflag or CS7;
     else
       Tios.c_cflag := Tios.c_cflag or CS8;
  end;

  // data byte size, parity and stop bits
  case PParity of
    spOdd:  Tios.c_cflag := Tios.c_cflag or PARENB or PARODD;
    spEven: Tios.c_cflag := Tios.c_cflag or PARENB;
  end;

  if PStopBits = sb2 then
    Tios.c_cflag := Tios.c_cflag or CSTOPB;

  tcflush(PPortHandle, TCIFLUSH);

  R := tcsetattr(PPortHandle, TCSANOW, Tios);
  if (R = -1) then
  begin
     RefreshLastOSError;
     Ok := False;
     PActive := False;
     Exit;
  end;
  
  tcflush(PPortHandle, TCIOFLUSH);
  
  // makes the serial port for exclusive access
  fpioctl(LongInt(PPortHandle), TIOCEXCL, nil);

  InternalClearALLBuffers;

  PActive := True;
  Ok := True;
{$ENDIF}
end;

procedure TSerialPortDriver.PortStop(var Ok: Boolean);
begin
{$IF defined(WIN32) or defined(WIN64)}
  // close serial port
  if PActive then
  begin
    {$IFNDEF FPC}
    CancelIo(PPortHandle);
    {$ENDIF}

    PPortEventName := '';
    EscapeCommFunction(PPortHandle, CLRRTS);
    EscapeCommFunction(PPortHandle, CLRDTR);
    if PBackupPortSettings then
      SetCommState(PPortHandle, PSavedDCB);
    CloseHandle(PPortHandle);
    CloseHandle(POverlapped.hEvent);
    PActive := False;
    Ok := True;
  end
  else
    Ok := True;
{$IFEND}
{$IFDEF UNIX}
  if PActive then
  begin
    InternalClearALLBuffers;
    {$IFNDEF DARWIN}
    if PBackupPortSettings then
      SerRestoreState(PPortHandle, PSavedState);
    {$ENDIF}
    FpClose(PPortHandle);
  end;
  Ok := True;
{$ENDIF}
end;

{$IF defined(WIN32) or defined(WIN64)}
function TSerialPortDriver.ComSettingsOK: Boolean;
var
  StrDCB: AnsiString;
  VarDCB: DCB;
begin
  StrDCB := MakeDCBString;
  Result := COMExist(PPortName) and BuildCommDCB(PChar(StrDCB), VarDCB);
{$IFEND}
{$IF defined(WINCE)}
function TSerialPortDriver.ComSettingsOK: Boolean;
begin
  //ToDo
{$IFEND}
{$IFDEF UNIX}
function TSerialPortDriver.ComSettingsOK: Boolean;
begin
  Result := COMExist(PPortName);
{$ENDIF}
end;

function TSerialPortDriver.GetDevDir: AnsiString;
begin
  Result := PPortDirPrefix;
end;

procedure TSerialPortDriver.SetDevDir(DDir: AnsiString);
begin
  DoExceptionInActive;
  PPortDirPrefix := DDir;
  if (DDir = '(none)') or (DDir = '') then
    PPortDirPrefix := '/dev/';
end;

procedure TSerialPortDriver.SetCOMPort(AValue: AnsiString);
begin
  DoExceptionInActive;

  if ([csLoading,csReading]*ComponentState) <> [] then
  begin
    PPortNameLoaded := AValue;
    Exit;
  end;
{$IF defined(WIN32) or defined(WIN64)}
  CopyPort := AValue;
{$IFEND}
  if COMExist(AValue) then
    PPortName := AValue
  else if (AValue='(none)') or (AValue='') then
    PPortName:='';
  //else
     //raise Exception.Create(AValue + ': ' + SserialPortNotExist);
end;

function TSerialPortDriver.COMExist(AValue: AnsiString): Boolean;
{$IF defined(WIN32) or defined(WIN64)}
var
  DCBString: AnsiString;
  D: DCB;
  Str: Tstringlist;
  Y : integer;
  i : integer;
begin
  if PAcceptAnyPortName then
  begin
    Result := True;
    Exit;
  end;
  //DCBString := AValue+': baud=1200 parity=N data=8 stop=1';
  //Result := BuildCommDCB(PChar(DCBString),D)
  
  // com essa abordagem é possive listar as portas COM acima de 10 e tambem
  // portas Virtuais que tem nomes diferentes " qualquer nome ele lista"

  // cria uma lista de portas "ativas" do sistema
  Str:= TStringList.Create;
  // copia as portas da função Get portas
  Str.CommaText:= GetPortas;
  // faz uma contagem de portas ativas
  Y := 0;
  for i := 0 to (Str.Count - 1) do
  begin
     if(AValue = Str.ValueFromIndex[i]) then
       Y:= 1;
  end;
  if( Y = 1 ) then
    Result := True;
  if( Y = 0 ) then
    Result := False;
  // libera a lista
  Str.Free;
{$IFEND}
{$IF defined(WINCE)}
begin
  //ToDo
{$IFEND}
{$IFDEF UNIX}
var
   i: LongInt;
   //fd: cint;
begin
  if PAcceptAnyPortName then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
  for i := 0 to High(PortPrefix) do
    if (LeftStr(AValue, Length(PortPrefix[i])) = PortPrefix[i]) and FileExists(PPortDirPrefix + AValue) then
    begin // Added PDevDir
      //fd := fpopen('/dev/' + PPortName, O_RDWR or O_NOCTTY or O_NONBLOCK);

      Result := True;
      Exit;
    end;
{$ENDIF}
end;

procedure TSerialPortDriver.SetTimeOut(AValue: LongInt);
begin
  DoExceptionInActive;
  PTimeout := AValue;
end;

procedure TSerialPortDriver.SetRenewHandleOnCommErr(AValue: Boolean);
begin
  if FRenewHandleOnCommErr = AValue then Exit;
  DoExceptionInActive;
  FRenewHandleOnCommErr := AValue;
end;

procedure TSerialPortDriver.SetRWTimeout(AValue: LongInt);
begin
  DoExceptionInActive;
  PRWTimeout := AValue;
end;

procedure TSerialPortDriver.SetBaundRate(AValue: TSerialBaudRate);
{$IF defined(WIN32) or defined(WIN64)}
var
  DCBString: AnsiString;
  D: DCB;
  Old: TSerialBaudRate;
begin
  DoExceptionInActive;

  Old := PBaundRate;
  PBaundRate := AValue;
  DCBString := MakeDCBString;

  if not BuildCommDCB(PChar(DCBString), D) then
  begin
    RefreshLastOSError;
    PBaundRate := Old;
    raise Exception.Create(SinvalidMode);
  end;
{$IFEND}
{$IF defined(WINCE)}
begin
  //ToDo
{$IFEND}
{$IFDEF UNIX}
begin
  PBaundRate := AValue;
{$ENDIF}
end;

procedure TSerialPortDriver.SetStopBits(AValue: TSerialStopBits);
{$IF defined(WIN32) or defined(WIN64)}
var
  DCBString: AnsiString;
  D: DCB;
  Old: TSerialStopBits;
begin
  DoExceptionInActive;

  Old := PStopBits;
  PStopBits := AValue;
  DCBString := MakeDCBString;

  if not BuildCommDCB(PChar(DCBString), D) then
  begin
    RefreshLastOSError;
    PStopBits := Old;
    raise Exception.Create(SinvalidMode);
  end;
{$IFEND}
{$IF defined(WINCE)}
begin
  //ToDo
{$IFEND}
{$IFDEF UNIX}
begin
  PStopBits := AValue;
{$ENDIF}
end;

procedure TSerialPortDriver.SetParity(AValue: TSerialParity);
{$IF defined(WIN32) or defined(WIN64)}
var
  DCBString: AnsiString;
  D: DCB;
  Old: TSerialParity;
begin
  DoExceptionInActive;

  Old := PParity;
  PParity := AValue;
  DCBString := MakeDCBString;

  if not BuildCommDCB(PChar(DCBString), D) then
  begin
    RefreshLastOSError;
    PParity := Old;
    raise Exception.Create(SinvalidMode);
  end;
{$IFEND}
{$IF defined(WINCE)}
begin
  //ToDo
{$IFEND}
{$IFDEF UNIX}
begin
  PParity := AValue;
{$ENDIF}
end;

procedure TSerialPortDriver.SetDataBits(AValue: TSerialDataBits);
{$IF defined(WIN32) or defined(WIN64)}
var
  DCBString: AnsiString;
  D: DCB;
  Old: TSerialDataBits;
begin
  DoExceptionInActive;

  Old := PDataBits;
  PDataBits := AValue;
  DCBString := MakeDCBString;

  if not BuildCommDCB(PChar(DCBString), D) then
  begin
    RefreshLastOSError;
    PDataBits := Old;
    raise Exception.Create(SinvalidMode);
  end;
{$IFEND}
{$IF defined(WINCE)}
begin
  //ToDo
{$IFEND}
{$IFDEF UNIX}
begin
  PDataBits := AValue;
{$ENDIF}
end;

{$IF defined(WIN32) or defined(WIN64)}
function TSerialPortDriver.MakeDCBString:AnsiString;
begin
  Result := '';
  case PBaundRate of
    br110:     Result := 'baud=110 ';
    br300:     Result := 'baud=300 ';
    br600:     Result := 'baud=600 ';
    br1200:    Result := 'baud=1200 ';
    br2400:    Result := 'baud=2400 ';
    br4800:    Result := 'baud=4800 ';
    br9600:    Result := 'baud=9600 ';
    br19200:   Result := 'baud=19200 ';
    br38400:   Result := 'baud=38400 ';
    br57600:   Result := 'baud=57600 ';
    br115200:  Result := 'baud=115200 ';
    br230400:  Result := 'baud=230400 ';
    br460800:  Result := 'baud=460800 ';
    br500000:  Result := 'baud=500000 ';
    br576000:  Result := 'baud=576000 ';
    br921600:  Result := 'baud=921600 ';
    br1000000: Result := 'baud=1000000 ';
    br1152000: Result := 'baud=1152000 ';
    br1500000: Result := 'baud=1500000 ';
    br2000000: Result := 'baud=2000000 ';
    br2500000: Result := 'baud=2500000 ';
    br3000000: Result := 'baud=3000000 ';
    br3500000: Result := 'baud=3500000 ';
    br4000000: Result := 'baud=4000000 ';
    else
      Result := 'baud=19200 ';
  end;

  case PParity of
    spNone: Result := Result + 'parity=N ';
    spOdd:  Result := Result + 'parity=O ';
    spEven: Result := Result + 'parity=E ';
    else
      Result := Result + 'parity=N ';
  end;

  case PStopBits of
    sb1: Result := Result + 'stop=1 ';
    sb2: Result := Result + 'stop=2 ';
    else
      Result := Result + 'stop=1 ';
  end;

  case PDataBits of
    db5: Result := Result + 'data=5';
    db6: Result := Result + 'data=6';
    db7: Result := Result + 'data=7';
    db8: Result := Result + 'data=8';
    else
      Result := Result + 'data=8';
  end;
end;
{$IFEND}

procedure TSerialPortDriver.ClearALLBuffers;
{$IF defined(WIN32) or defined(WIN64)}
var
  IOCTL_SERIAL_CONFIG_SIZE: Cardinal;
  dwFlags,
  Buf: Cardinal;
  Buf2: array [0..8192] of char;
begin
  IOCTL_SERIAL_CONFIG_SIZE := CTL_CODE (FILE_DEVICE_SERIAL_PORT, 32, METHOD_BUFFERED, FILE_ANY_ACCESS);
  dwFlags := PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR;
  DeviceIoControl(PPortHandle, IOCTL_SERIAL_CONFIG_SIZE, @Buf2, 0, @Buf2, 0, Buf, nil);
  DeviceIoControl(PPortHandle, IOCTL_SERIAL_CONFIG_SIZE, @Buf2, 8192, @Buf2, 8192, Buf, nil);
  FlushFileBuffers(PPortHandle);
  PurgeComm(PPortHandle, dwFlags);
{$IFEND}
{$IF defined(WINCE)}
begin
  //ToDo
{$IFEND}
{$IFDEF UNIX}
var
  Zero: LongInt = 0;
begin
  // flush buffers
  tcflush(PPortHandle, TCIFLUSH);
  tcflush(PPortHandle, TCIOFLUSH);
  // purge comm
  {$IFDEF LINUX}
  fpioctl(LongInt(PPortHandle), TCIOFLUSH, @Zero);
  {$ELSE}
  fpioctl(LongInt(PPortHandle), TIOCFLUSH, @Zero);
  {$ENDIF}
{$ENDIF}
end;

procedure TSerialPortDriver.SetActive(AValue: Boolean);
begin
  if [csLoading, csReading] * ComponentState <> [] then
  begin
    PActivatedOnLoad := AValue;
    Exit;
  end;
  inherited SetActive(AValue);
end;

procedure TSerialPortDriver.Loaded;
begin
  inherited Loaded;
  COMPort := PPortNameLoaded;
  SetActive(PActivatedOnLoad);
end;

procedure TSerialPortDriver.RenewHandle;
var
  ABool: Boolean;
begin
{$IFNDEF WINDOWS}
  WriteLn('RenewHandle: Port Stop');
{$ENDIF}
  PortStop(ABool);
{$IFNDEF WINDOWS}
  WriteLn('RenewHandle: Port Start');
{$ENDIF}
  PortStart(ABool);
{$IFNDEF WINDOWS}
  WriteLn('RenewHandle: Done');
{$ENDIF}
end;

function TSerialPortDriver.GetPortId: TPortUniqueID;
begin
  Result := inherited getPortId;
  {TODO}
end;

function TSerialPortDriver.GetPendingInputBytes: LongInt;
var
  Aux: cint;
begin
{$IF defined(LINUX)}
  if FpIOCtl(PPortHandle, FIONREAD, @Result) < 0 then
    Result := 0;
{$ENDIF}
end;


{$IFDEF MSWINDOWS}
function TSerialPortDriver.GetPortas: string;
// For Windows only, it retrieves the value directly from the Windows registry.
// The advantage is that it's possible to list ports above COM9
// and also virtual ports with different names (any name)
var
  ARegistry: TRegistry;
  ALists: TStringList;
  AValue: TStringList;
  ANumber: Integer;
begin
  // Create port ALists
  ALists := TStringList.Create;
  // Create ALists of values
  AValue := TStringList.Create;
  // Creates the ARegistry data to be read
  ARegistry := TRegistry.Create;
  try
    // Specifies the path to the ARegistry
    ARegistry.RootKey := HKEY_LOCAL_MACHINE;
    // Open the path to the ARegistry where the serial ports are located
    ARegistry.OpenKeyReadOnly('\HARDWARE\DEVICEMAP\SERIALCOMM');
    // Retrieves values from the ARegistry (data in the ARegistry)
    ARegistry.GetValueNames(ALists);
    // based on the number of ports that were in the ARegistry
    for ANumber := 0 to ALists.Count - 1 do
      // Add the collected data from the string to AValue
      AValue.Add(PChar(ARegistry.ReadString(ALists[ANumber])));
    // the returned AValue separated by semicolons
    Result := AValue.CommaText;
  finally
    // concludes the ALists of ARegistry
    ARegistry.Free;
    // ends the use of ALists
    ALists.Free;
    // This concludes the use of ALists for values
    AValue.Free;
  end;
end;
{$ENDIF}


end.

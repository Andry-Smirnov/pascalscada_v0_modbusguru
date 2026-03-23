{$i ../common/language.inc}
{:
  @abstract(Implements the ISOTCP protocol.)
  This driver is based on ISOTCP of LibNODAVE library of
  Thomas Hergenhahn (thomas.hergenhahn@web.de).

  This driver does not uses LibNodave, it's a rewritten of it.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
unit ISOTCPDriver;

interface

uses
  Classes, SysUtils, S7Types, commtypes, s7family, Tag, ProtocolTypes;

type

  {: ISOTCP protocol driver. Based on LibNODAVE libray of
     Thomas Hergenhahn (thomas.hergenhahn@web.de).

  To address your tags, see the documentation of the class
  TSiemensProtocolFamily.

  @bold(Due to ISOTCP allow connect to a single PLC through a TCP/IP connection,
        the properties TTag.PLCStation, TTag.PLCSlot and TTag.PLCRack has no
        effect. Therefore these informations must be set through properties
        PLCStation, PLCSlot and PLCRack of each instance of this protocol.)

  @seealso(TSiemensProtocolFamily). }

  { TISOTCPDriver }

  TISOTCPDriver = class(TSiemensProtocolFamily)
  private
    FISOConnType: TISOTCPConnType;
    procedure SetISOConnType(AValue: TISOTCPConnType);
    procedure SetPLCRack(AValue: Longint);
    procedure SetPLCSlot(AValue: Longint);
    procedure SetPLCStation(AValue: Longint);
    procedure UpdatePLCs;
  protected
    FPLCRack: Longint;
    FPLCSlot: Longint;
    FPLCStation: Longint;
    FConnectionWay: TISOTCPConnectionWay;

    //: Defines the way to connect into the PLC.
    procedure SetISOConnectionWay(NewISOConWay: TISOTCPConnectionWay);

    //: seealso(TSiemensProtocolFamily.GetTagInfo)
    function GetTagInfo(tagobj: TTag): TTagRec; override;

    //: seealso(TProtocolDriver.NotifyThisEvents)
    function NotifyThisEvents: TNotifyThisEvents; override;
    //: seealso(TProtocolDriver.PortClosed)
    procedure PortClosed(Sender: TObject); override;
    //: seealso(TProtocolDriver.PortDisconnected)
    procedure PortDisconnected(Sender: TObject); override;
  protected
    //: seealso(TSiemensProtocolFamily.ConnectPLC)
    function connectPLC(var CPU: TS7CPU): Boolean; override;
    //: seealso(TSiemensProtocolFamily.Exchange)
    function exchange(var CPU: TS7CPU; var msgOut: Bytes; var MsgIn: Bytes; IsWrite: Boolean): Boolean; override;
    //: seealso(TSiemensProtocolFamily.getResponse)
    function getResponse(var MsgIn: Bytes; var BytesRead: Longint): TIOResult; override;
    //: seealso(TSiemensProtocolFamily.PrepareToSend)
    procedure PrepareToSend(var Msg: Bytes); override;
    //: @exclude
    procedure Loaded; override;

    //: seealso(TSiemensProtocolFamily.doRead)
    function DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
    procedure DoGetValue(TagRec: TTagRec; var Values: TScanReadRec); override;
    //: seealso(TSiemensProtocolFamily.doWrite)
    function DoWrite(const TagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
  public
    constructor Create(AOwner: TComponent); override;

    //: Updates in a single call, Rack, Slot and Station, avoiding overhead.
    procedure UpdatePLCAddress(Rack, Slot, Station: Longint);
  published
    //: @seealso(TSiemensProtocolFamily.ReadSomethingAlways)
    property ReadSomethingAlways;
    {: Defines the way to connect into the PLC.
       @seealso(TISOTCPConnectionWay) }
    property ConnectionWay: TISOTCPConnectionWay read FConnectionWay write SetISOConnectionWay;
    {: Defines connection type to the PLC.
       @seealso(TISOTCPConnType) }
    property ISOTCPConnType: TISOTCPConnType read FISOConnType write SetISOConnType default ctOP;
    {:
      Override the value TTag.PLCRack property by the value set here.

      @bold(Due to ISOTCP allow connect to a single PLC through a TCP/IP
            connection, the property TTag.PLCRack has no effect. Therefore
            these information must be set through property PLCRack of each
            instance of this protocol.)

      @seealso(TTag.PLCRack)
      @seealso(TISOTCPDriver) }
    property PLCRack: Longint read FPLCRack write SetPLCRack default 0;
    {:
      Override the value TTag.PLCSlot property by the value set here.

      @bold(Due to ISOTCP allow connect to a single PLC through a TCP/IP
            connection, the property TTag.PLCSlot has no effect. Therefore
            these information must be set through property PLCSlot of each
            instance of this protocol.)

      @seealso(TTag.PLCSlot)
      @seealso(TISOTCPDriver) }
    property PLCSlot: Longint read FPLCSlot write SetPLCSlot default 0;
    {:
      Override the value TTag.PLCStation property by the value set here.

      @bold(Due to ISOTCP allow connect to a single PLC through a TCP/IP
            connection, the property TTag.PLCStation has no effect. Therefore
            these information must be set through property PLCStation of each
            instance of this protocol.)

      @seealso(TTag.PLCStation)
      @seealso(TISOTCPDriver) }
    property PLCStation: Longint read FPLCStation write SetPLCStation default 2;

    property ReadOnly;
  end;


const
  ISOTCPMinPacketLen = 16;


implementation


uses
  Math,
  pascalScadaMTPCPU;


constructor TISOTCPDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPLCRack := 0;
  FPLCSlot := 0;
  FPLCStation := 2;

  PDUIncoming := 7;
  PDUOutgoing := 7;
  FISOConnType := ctOP;
end;

procedure TISOTCPDriver.UpdatePLCAddress(Rack, Slot, Station: Longint);
begin
  FPLCRack := Rack;
  FPLCSlot := Slot;
  FPLCStation := Station;
  UpdatePLCs;
end;

function TISOTCPDriver.connectPLC(var CPU: TS7CPU): Boolean;
var
  IOResult: TIOPacket;
  Msg: Bytes;
  Res: Longint;
  Len: Cardinal;
  Retries: Longint;
  ConnType: array [low(TISOTCPConnType)..high(TISOTCPConnType)] of Byte = (1, 2, 3);
begin
  CPU.Connected := False;
  Result := False;
  if (PCommPort = nil) or (PCommPort.ReallyActive = False) then Exit;

  //initiates the connection.
  SetLength(Msg, 22);
  Msg[04] := $11;  // $11,
  Msg[05] := $E0;  // $E0,
  Msg[06] := 0;    // 0,
  Msg[07] := 0;    // 0,
  Msg[08] := 0;    // 0,
  Msg[09] := 1;    // 1,
  Msg[10] := 0;    // 0,
  Msg[11] := $C1;  // $C1,
  Msg[12] := 2;    // 2,
  Msg[13] := IfThen(FConnectionWay = ISOTCP, 1, $4D);    //'M',
  Msg[14] := IfThen(FConnectionWay = ISOTCP, 0, $57);    //'W',
  Msg[15] := $C2;  // $C2,
  Msg[16] := 2;
  Msg[17] := IfThen(FConnectionWay = ISOTCP, ConnType[FISOConnType], $4D);
  Msg[18] := IfThen(FConnectionWay = ISOTCP, (CPU.Rack shl 5) or CPU.Slot, $57);
  Msg[19] := $C0;  // $C0,
  Msg[20] := 1;    // 1,
  Msg[21] := 11;   // 9 = TPDU 512 Bytes, 11=TPDU 2048 Bytes;
  PrepareToSend(Msg);

  try
    Res := PCommPort.IOCommandSync(iocWriteRead, 22, Msg, 4, DriverID, IfThen(FConnectionWay = ISOTCP_VIA_CP243, 1000, 0), @IOResult);
    if (Res = 0) then
      Exit;
    if (IOResult.ReadIOResult <> iorOK) or (IOResult.Received <> 4) then
      Exit;

    Len := IOResult.BufferToRead[2] * $100 + IOResult.BufferToRead[3];

    Res := PCommPort.IOCommandSync(iocRead, 0, nil, Len - 4, DriverID, 0, @IOResult);
    if (Res = 0) then
      Exit;
    if (IOResult.ReadIOResult <> iorOK) or (IOResult.Received <> (Len - 4)) then
      Exit;

    Retries := 1;
    while (Len <> 22) and (Retries < 3) do
    begin
      Res := PCommPort.IOCommandSync(iocRead, 0, nil, 4, DriverID, 0, @IOResult);
      if (Res = 0) then
        Exit;
      if (IOResult.ReadIOResult <> iorOK) or (IOResult.Received <> 4) then
        Exit;

      Len := IOResult.BufferToRead[2] * $100 + IOResult.BufferToRead[3];

      Res := PCommPort.IOCommandSync(iocRead, 0, nil, Len - 4, DriverID, 0, @IOResult);
      if (Res = 0) then
        Exit;
      if (IOResult.ReadIOResult <> iorOK) or (IOResult.Received <> (Len - 4)) then
        Exit;
    end;

    // negotiates the PDU size
    if Len = 22 then
      CPU.Connected := NegotiatePDUSize(CPU);
  finally
    SetLength(Msg, 0);
    SetLength(IOResult.BufferToRead, 0);
    SetLength(IOResult.BufferToWrite, 0);
    Result := CPU.Connected;
  end;
end;

function TISOTCPDriver.exchange(var CPU: TS7CPU; var msgOut: Bytes; var MsgIn: Bytes; IsWrite: Boolean): Boolean;
var
  Res: Longint;
  Retries: Longint;
  BytesRead: Longint;
  ResGet: TIOResult;
begin
  if (PCommPort = nil) or (PCommPort.ReallyActive = False) then Exit;

  Result := inherited exchange(CPU, msgOut, MsgIn, IsWrite);
  Result := False;

  if Length(msgOut) < 7 then
    SetLength(msgOut, 7);
  msgOut[04] := $02;
  msgOut[05] := $F0;
  msgOut[06] := $80;

  PrepareToSend(msgOut);

  HighLatencyOperationWillBegin(nil);
  try
    Res := PCommPort.IOCommandSync(iocWrite, Length(msgOut), msgOut, 0, DriverID, 0, nil);
    if Res = 0 then
    begin
      SetLength(MsgIn, 0);
      SetLength(msgOut, 0);
      Result := False;
      Exit;
    end;
    Retries := 0;

    BytesRead := 0;
    ResGet := getResponse(MsgIn, BytesRead);
    while (ResGet <> iorOK) and (Retries < 3) do
    begin
      if ResGet <> iorTimeOut then
        Inc(Retries)
      else
        Sleep(5);

      ResGet := getResponse(MsgIn, BytesRead);
    end;

    Result := BytesRead > ISOTCPMinPacketLen;
  finally
    HighLatencyOperationWasEnded(nil);
  end;
end;

function TISOTCPDriver.getResponse(var MsgIn: Bytes; var BytesRead: Longint): TIOResult;
var
  Res: Longint;
  Len: Longint;
  IOResult1: TIOPacket;
  IOResult2: TIOPacket;
begin
  Result := iorNotReady;

  try
    Res := PCommPort.IOCommandSync(iocRead, 0, nil, 7, DriverID, 0, @IOResult1);
    if (Res = 0) then
    begin
      BytesRead := 0;
      Result := iorNotReady;
      Exit;
    end;

    if (IOResult1.ReadIOResult <> iorOK) or (IOResult1.Received <> 7) then
    begin
      BytesRead := IOResult1.Received;
      Result := IOResult1.ReadIOResult;
      Exit;
    end;

    Len := IOResult1.BufferToRead[2] * $100 + IOResult1.BufferToRead[3];
    // Sometimes the PLC sends a useless packet, with 7 Bytes of Len.
    while Len = 7 do
    begin
      // reads again
      Res := PCommPort.IOCommandSync(iocRead, 0, nil, 7, DriverID, 0, @IOResult1);
      if (Res = 0) then
      begin
        BytesRead := 0;
        Result := iorNotReady;
        Exit;
      end;

      if (IOResult1.ReadIOResult <> iorOK) or (IOResult1.Received <> 7) then
      begin
        BytesRead := IOResult1.Received;
        Result := IOResult1.ReadIOResult;
        Exit;
      end;
      // calculate the size of the packet
      Len := IOResult1.BufferToRead[2] * $100 + IOResult1.BufferToRead[3];
    end;

    Res := PCommPort.IOCommandSync(iocRead, 0, nil, Len - 7, DriverID, 0, @IOResult2);
    if (Res = 0) then
    begin
      BytesRead := 0;
      Result := iorNotReady;
      Exit;
    end;
    // if the IO result aren't ok or the packet has less bytes than minimum size
    // Exit
    if (IOResult2.ReadIOResult <> iorOK) or (IOResult2.Received <> (Len - 7)) then
    begin
      BytesRead := IOResult2.Received;
      Result := IOResult2.ReadIOResult;
      Exit;
    end;

    SetLength(MsgIn, IOResult1.ToRead + IOResult2.ToRead);

    Move(IOResult1.BufferToRead[0], MsgIn[0], IOResult1.ToRead);
    Move(IOResult2.BufferToRead[0], MsgIn[IOResult1.ToRead], Length(IOResult2.BufferToRead));

    BytesRead := IOResult1.Received + IOResult2.Received;
    Result := iorOK;
  finally
    SetLength(IOResult1.BufferToRead, 0);
    SetLength(IOResult1.BufferToWrite, 0);
    SetLength(IOResult2.BufferToRead, 0);
    SetLength(IOResult2.BufferToWrite, 0);
  end;
end;

procedure TISOTCPDriver.PrepareToSend(var Msg: Bytes);
var
  Len: Longint;
begin
  Len := Length(Msg);
  if Len < 4 then
    SetLength(Msg, 4);
  Msg[00] := 3;
  Msg[01] := 0;
  Msg[02] := Len div $100;
  Msg[03] := Len mod $100;
end;

procedure TISOTCPDriver.Loaded;
begin
  inherited Loaded;
  UpdatePLCs;
end;

function TISOTCPDriver.DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  ATagRec: TTagRec;
begin
  ATagRec := TagRec;
  ATagRec.Rack := FPLCRack;
  ATagRec.Slot := FPLCSlot;
  ATagRec.Station := FPLCStation;
  Result := inherited DoRead(ATagRec, Values, Sync);
end;

procedure TISOTCPDriver.DoGetValue(TagRec: TTagRec; var Values: TScanReadRec);
begin
  TagRec.Station := FPLCStation;
  TagRec.Slot := FPLCSlot;
  TagRec.Rack := FPLCRack;
  inherited DoGetValue(TagRec, Values);
end;

function TISOTCPDriver.DoWrite(const TagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  ATagRec: TTagRec;
begin
  ATagRec := TagRec;
  ATagRec.Rack := FPLCRack;
  ATagRec.Slot := FPLCSlot;
  ATagRec.Station := FPLCStation;
  Result := inherited DoWrite(ATagRec, Values, Sync);
end;

procedure TISOTCPDriver.SetISOConnType(AValue: TISOTCPConnType);
begin
  if FISOConnType = AValue then Exit;
  FISOConnType := AValue;
  //TODO: reset the conection and stabilish it again using the new way.
end;

procedure TISOTCPDriver.SetPLCRack(AValue: Longint);
begin
  if FPLCRack = AValue then Exit;
  FPLCRack := AValue;
  if [csLoading] * ComponentState = [] then
    UpdatePLCs;
end;

procedure TISOTCPDriver.SetPLCSlot(AValue: Longint);
begin
  if FPLCSlot = AValue then Exit;
  FPLCSlot := AValue;
  if [csLoading] * ComponentState = [] then
    UpdatePLCs;
end;

procedure TISOTCPDriver.SetPLCStation(AValue: Longint);
begin
  if FPLCStation = AValue then Exit;
  FPLCStation := AValue;
  if [csLoading] * ComponentState = [] then
    UpdatePLCs;
end;

procedure TISOTCPDriver.UpdatePLCs;
var
  StillConnected: Boolean;
  i: Integer;
  CurTag: TTag;
  TagList: TList;
begin
  try
    //tenta entrar no Mutex
    //try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;

    case Length(FPLCs) of
      0:  begin
            // does nothing...;
          end;
      1:  with FPLCs[0] do
            begin
              StillConnected := Connected and (Rack = FPLCRack) and (Slot = FPLCSlot) and (Station = FPLCStation);
              Rack := FPLCRack;
              Slot := FPLCSlot;
              Station := FPLCStation;
              Connected := StillConnected;
              if not StillConnected then
                PDUId := 0;
            end;
      else
        begin
          TagList := TList.Create;
          try
            for i := TagCount - 1 downto 0 do
            begin
              CurTag := Tag[i];
              TagList.Add(CurTag);
              DoDelTag(CurTag);
            end;

            if Length(FPLCs) > 0 then
              raise Exception.Create('Something went wrong. At this point the ' +
                'size of FPLCs must be zero. Please inform ' +
                'this error to the PascalSCADA developer.');

            for i := 0 to TagList.Count - 1 do
            begin
              DoAddTag(TTag(TagList.Items[i]), False);
            end;
          finally
            TagList.Destroy;
          end;
        end;
    end;
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
  end;
end;

procedure TISOTCPDriver.SetISOConnectionWay(NewISOConWay: TISOTCPConnectionWay);
begin
  if NewISOConWay = FConnectionWay then Exit;
  FConnectionWay := NewISOConWay;
  //TODO: reset the conection and stabilish it again using the new way.
end;

function TISOTCPDriver.GetTagInfo(tagobj: TTag): TTagRec;
begin
  Result := inherited GetTagInfo(tagobj);
  // iso on TCP allows one PLC connection per TCP/IP connection
  // so, it allow only one Rack, Slot, and Station linked with
  // this connection. To avoid settings mistakes on user aplication
  // these method override the Tag settings (Rack, Slot,
  // and Station) with the settings of current instance of ISO on TCP protocol.
  Result.Slot := FPLCSlot;
  Result.Station := FPLCStation;
  Result.Rack := FPLCRack;
end;

function TISOTCPDriver.NotifyThisEvents: TNotifyThisEvents;
begin
  Result := [ntePortClosed, ntePortDisconnected];
end;

procedure TISOTCPDriver.PortClosed(Sender: TObject);
begin
  PortDisconnected(Self);
end;

procedure TISOTCPDriver.PortDisconnected(Sender: TObject);
var
  PLC: Longint;
begin
  for PLC := 0 to high(FPLCs) do
    FPLCs[PLC].Connected := False;
end;

end.

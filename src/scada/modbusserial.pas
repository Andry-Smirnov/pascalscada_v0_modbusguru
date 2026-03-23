{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Unit that implements the ModBus RTU protocol driver.)
}
unit ModBusSerial;

interface

uses
  Classes, ModBusDriver, Tag, commtypes, crc16utils;

type

  {:
  @abstract(Class of ModBus RTU protocol driver.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @bold(For more information, see the documentation of TModBusDriver class.)

  @seealso(TModBusDriver) }

  { TModBusRTUDriver }

  TModBusRTUDriver = class(TModBusDriver)
  protected
    function AllowBroadCast: Boolean; override;
    //: @seealso(TModBusDriver.EncodePkg)
    function EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes; override;
    //: @seealso(TModBusDriver.DecodePkg)
    function DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult; override;
    //: @seealso(TModBusDriver.RemainingBytes)
    function RemainingBytes(Buffer: Bytes): Longint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    //: @seealso(TModBusDriver.ReadSomethingAlways)
    property ReadSomethingAlways;
    //: @seealso(TModBusDriver.OutputMaxHole)
    property OutputMaxHole;
    //: @seealso(TModBusDriver.InputMaxHole)
    property InputMaxHole;
    //: @seealso(TModBusDriver.RegisterMaxHole)
    property RegisterMaxHole;
    //: @seealso(TModBusDriver.InputsMaxBlockSize)
    property InputsMaxBlockSize;
    //: @seealso(TModBusDriver.OutputsMaxBlockSize)
    property OutputsMaxBlockSize;
    //: @seealso(TModBusDriver.AnalogRegsMaxBlockSize)
    property AnalogRegsMaxBlockSize;
    //: @seealso(TModBusDriver.HoldingRegsMaxBlockSize)
    property HoldingRegsMaxBlockSize;
    property ReadOnly;
  end;


implementation


uses
  Math, PLCMemoryManager, SysUtils, crossdatetime;


constructor TModBusRTUDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PFirstRequestLen := 3;
  PFuncByteOffset := 1;
  PCRCLen := 2;
end;

function TModBusRTUDriver.AllowBroadCast: Boolean;
begin
  Result := True;
end;

function TModBusRTUDriver.EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes;
var
  i: Longint;
  c: Longint;
  c2: Longint;
begin
  //checa se é um pacote de escrita de valores ou de reading
  //que está sendo codificado.

  //Verify if is packet to write data on device that is being encoded.

  //de reading de valores...
  //read data from slave.
  if ToWrite = nil then
    begin
      case TagObj.ReadFunction of
        $01, $02,
        $03, $04: begin
                    // encode a packet to read input, outputs, register or analog registers
                    SetLength(Result, 8);
                    Result[0] := TagObj.Station and $FF;
                    Result[1] := TagObj.ReadFunction and $FF;
                    Result[2] := (TagObj.Address and $FF00) shr 8;
                    Result[3] := TagObj.Address and $FF;
                    Result[4] := (TagObj.Size and $FF00) shr 8;
                    Result[5] := TagObj.Size and $FF;
                    // computes the CRC
                    Calcul_CRC(Result);
                  end;
        $11:  begin
                //encode a packet to ID
                SetLength(Result, 4);
                Result[0] := TagObj.Station and $FF;
                Result[1] := TagObj.ReadFunction and $FF;
                // computes the CRC
                Calcul_CRC(Result);
              end;
        $07:  begin
                //encode a packet to read the device status.
                SetLength(Result, 4);
                Result[0] := TagObj.Station and $FF;
                Result[1] := $07;
                // computes the CRC
                Calcul_CRC(Result);
              end;
        $08:  begin
                // line test
                SetLength(Result, 8);
                Result[0] := TagObj.Station and $FF;
                Result[1] := $08;
                Result[2] := 0;
                Result[3] := 0;
                Result[4] := 0;
                Result[5] := 0;
                Calcul_CRC(Result);
              end;
        else
          begin
            SetLength(Result, 0);
          end;
      end;

      // computes the size of the incoming packet.
      case TagObj.ReadFunction of
        $01..$02: ResultLen := 5 + (TagObj.Size div 8) + IfThen((TagObj.Size mod 8) <> 0, 1, 0);
        $03..$04: ResultLen := 5 + (TagObj.Size * 2);
        $07:      ResultLen := 5;
        $08:      ResultLen := 8;
        $11:      ResultLen := 5 + (TagObj.Size);
        else
          begin
            ResultLen := 0;
          end;
      end;
    end
  else
    begin
      case TagObj.WriteFunction of
        $05:  begin
                //encodes a packet to write a single coil.
                SetLength(Result, 8);
                Result[0] := TagObj.Station and $FF;
                Result[1] := $05;
                Result[2] := (TagObj.Address and $FF00) shr 8;
                Result[3] := TagObj.Address and $FF;

                if (ToWrite[0] = 0) then
                  begin
                    Result[4] := $00;
                    Result[5] := $00;
                  end
                else
                  begin
                    Result[4] := $FF;
                    Result[5] := $00;
                  end;
                // computes the CRC
                Calcul_CRC(Result);
              end;
        $06:  begin
                // encodes a packet to write a single register.
                SetLength(Result, 8);
                Result[0] := TagObj.Station and $FF;
                Result[1] := $06;
                Result[2] := (TagObj.Address and $FF00) shr 8;
                Result[3] := TagObj.Address and $FF;
                Result[4] := (Trunc(ToWrite[0]) and $FF00) shr 8;
                Result[5] := Trunc(ToWrite[0]) and $FF;
                // computes the CRC
                Calcul_CRC(Result);
              end;
        $0F:  begin
                //encodes a packet to write multiple coils.
                SetLength(Result, (TagObj.Size div 8) + IfThen((TagObj.Size mod 8) > 0, 1, 0) + 9);
                Result[0] := TagObj.Station and $FF;
                Result[1] := $0F;
                Result[2] := ((TagObj.Address + TagObj.OffSet) and $FF00) shr 8;        // endereco
                Result[3] := (TagObj.Address + TagObj.OffSet) and $FF;                  // endereco
                Result[4] := (Min(TagObj.Size, Length(ToWrite)) and $FF00) shr 8;       // num de coils
                Result[5] := Min(TagObj.Size, Length(ToWrite)) and $FF;                 // num de coils
                Result[6] := (TagObj.Size div 8) + IfThen((TagObj.Size mod 8) > 0, 1, 0); // num de Bytes que seguem

                i := 0;
                c := 0;
                c2 := 7;
                Result[7] := 0;

                for c := 0 to Min(TagObj.Size, Length(ToWrite)) - 1 do
                begin
                  if ToWrite[c] <> 0 then
                  begin
                    Result[c2] := Result[c2] + (1 shl i);
                  end;

                  Inc(i);
                  if i > 7 then
                  begin
                    i := 0;
                    Inc(c2);
                    Result[c2] := 0;
                  end;
                end;
                // computes the CRC
                Calcul_CRC(Result);
              end;
        $10:  begin
                // encodes a packet to write multiple registers
                SetLength(Result, (TagObj.Size * 2) + 9);
                Result[0] := TagObj.Station and $FF;
                Result[1] := $10;
                Result[2] := ((TagObj.Address + TagObj.OffSet) and $FF00) shr 8; // endereco
                Result[3] := (TagObj.Address + TagObj.OffSet) and $FF;           // endereco
                Result[4] := ((TagObj.Size and $FF00) shr 8);                    // num de words
                Result[5] := TagObj.Size and $FF;                                // num de words
                Result[6] := (TagObj.Size * 2) and $FF;                          // num de Bytes que seguem = num de words * 2
                i := 0;
                while (i < TagObj.Size) do
                begin
                  Result[7 + i * 2] := ((Trunc(ToWrite[i]) and $FF00) shr 8);
                  Result[8 + i * 2] := Trunc(ToWrite[i]) and $FF;
                  Inc(i);
                end;
                // computes the CRC
                Calcul_CRC(Result);
              end;
        else
          begin
            SetLength(Result, 0);
          end;
      end;
      // computes the size of the incoming packet.
      case TagObj.WriteFunction of
        $05, $06,
        $0F, $10: ResultLen := 8;
        else
          begin
            ResultLen := 0;
          end;
      end;
    end;
end;

function TModBusRTUDriver.DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult;
var
  i: Longint;
  c: Longint;
  c2: Longint;
  PLC: Longint;
  Address: Cardinal;
  Len: Cardinal;
  FoundPLC: Boolean;
  Aux: TPLCMemoryManager;
begin
  // if some IO fail
  Result := ioOk;

  case Pkg.WriteIOResult of
    iorTimeOut:   Result := ioTimeOut;
    iorNotReady,
    iorNone:      Result := ioDriverError;
    iorPortError: Result := ioCommError;
  end;

  if (Result = ioOk) then
    case Pkg.ReadIOResult of
      iorTimeOut:   Result := ioTimeOut;
      iorNotReady,
      iorNone:      Result := ioDriverError;
      iorPortError: Result := ioCommError;
    end;

  if (Length(Pkg.BufferToWrite) = 0) or (Length(Pkg.BufferToRead) = 0) then
    Result := ioDriverError;

  // if the address in the incoming packet is different of the requested
  if (Result = ioOk) and (Pkg.BufferToWrite[0] <> Pkg.BufferToRead[0]) then
  begin
    Result := ioCommError;
  end;

  // verify the CRC of incoming packet
  if (Result = ioOk) and ((not Test_crc(Pkg.BufferToWrite)) or (not Test_crc(Pkg.BufferToRead))) then
    Result := ioCommError;

  // search de PLC
  FoundPLC := False;
  for PLC := 0 to High(PModbusPLC) do
    if PModbusPLC[PLC].Station = Pkg.BufferToWrite[0] then
    begin
      FoundPLC := True;
      Break;
    end;

  // decodes the packet

  // request to read the digital input/outpus (coils)
  if Length(Pkg.BufferToRead) < 2 then
  begin
    SetLength(Pkg.BufferToRead, 2);
    Pkg.BufferToRead[1] := 0;
  end;
  case Pkg.BufferToRead[1] of
    $01, $02: begin
                // where the data decoded will be stored
                if FoundPLC then
                begin
                  if Pkg.BufferToWrite[1] = $01 then
                    Aux := PModbusPLC[PLC].OutPuts
                  else
                    Aux := PModbusPLC[PLC].Inputs;
                end;

                Address := (Pkg.BufferToWrite[2] shl 8) + Pkg.BufferToWrite[3];
                Len := (Pkg.BufferToWrite[4] shl 8) + Pkg.BufferToWrite[5];
                if Result = ioOk then
                begin
                  SetLength(Values, Len);

                  i := 0;
                  c := 0;
                  c2 := 3;
                  while (i < Len) and (c2 < Length(Pkg.BufferToRead)) do
                  begin
                    if (c = 8) then
                    begin
                      c := 0;
                      Inc(c2);
                    end;
                    Values[i] := IfThen(((Longint(Pkg.BufferToRead[c2]) and (1 shl c)) = (1 shl c)), 1, 0);
                    Inc(i);
                    Inc(c);
                  end;
                  if FoundPLC then
                    Aux.SetValues(Address, Len, 1, Values, Result);
                end
                else if FoundPLC then
                  Aux.SetFault(Address, Len, 1, Result);
              end;

    $03, $04: begin // request to read registers/analog registers
                // where the data decoded will be stored
                if FoundPLC then
                begin
                  if Pkg.BufferToWrite[1] = $03 then
                    Aux := PModbusPLC[PLC].Registers
                  else
                    Aux := PModbusPLC[PLC].AnalogReg;
                end;

                Address := Cardinal((Pkg.BufferToWrite[2] shl 8) + Pkg.BufferToWrite[3]);
                Len := Cardinal((Pkg.BufferToWrite[4] shl 8) + Pkg.BufferToWrite[5]);

                if Result = ioOk then
                  begin
                    SetLength(Values, Len);

                    // data are ok
                    for i := 0 to Len - 1 do
                    begin
                      Values[i] := (Longint(Pkg.BufferToRead[3 + (i * 2)]) shl 8) + Longint(Pkg.BufferToRead[4 + i * 2]);
                    end;

                    if FoundPLC then
                      Aux.SetValues(Address, Len, 1, Values, Result);
                  end
                else if FoundPLC then
                  Aux.SetFault(Address, Len, 1, Result);
              end;
    $11:  begin
            // where the data decoded will be stored
            if FoundPLC then
            begin
              Aux := PModbusPLC[PLC].Registers;
            end;

            Address := 0;
            Len := Cardinal(Pkg.BufferToRead[2]) - 4;

            if Result = ioOk then
            begin
              SetLength(Values, Len);

              // data are ok
              for i := 0 to Len - 1 do
              begin
                Values[i] := Longint(Pkg.BufferToRead[3 + i]);
              end;

              if FoundPLC then
                Aux.SetValues(Address, Len, 1, Values, Result);
            end
            else if FoundPLC then
              Aux.SetFault(Address, Len, 1, Result);
          end;
    $05:  begin // decodes a write to a single coil
            Address := (Pkg.BufferToWrite[2] * 256) + Pkg.BufferToWrite[3];
            if Result = ioOk then
              begin
                SetLength(Values, 1);

                if (Pkg.BufferToWrite[4] = 0) and (Pkg.BufferToWrite[5] = 0) then
                  Values[0] := 0
                else
                  Values[0] := 1;

                if FoundPLC then
                  PModbusPLC[PLC].OutPuts.SetValues(Address, 1, 1, Values, Result);
              end
            else if FoundPLC then
              PModbusPLC[PLC].OutPuts.SetFault(Address, 1, 1, Result);
          end;
    $06:  begin // decodes a write to a single register
            Address := (Pkg.BufferToWrite[2] * 256) + Pkg.BufferToWrite[3];
            if Result = ioOk then
              begin
                SetLength(Values, 1);

                Values[0] := Pkg.BufferToWrite[4] * 256 + Pkg.BufferToWrite[5];
                if FoundPLC then
                  PModbusPLC[PLC].Registers.SetValues(Address, 1, 1, Values, Result);
              end
            else if FoundPLC then
              PModbusPLC[PLC].Registers.SetFault(Address, 1, 1, Result);
          end;
    $07:  begin // decodes a the current state of the slave
            if FoundPLC then
            begin
              if Result = ioOk then
              begin
                PModbusPLC[PLC].Status07Value := Longint(Pkg.BufferToRead[2]);
                PModbusPLC[PLC].Status07TimeStamp := CrossNow;
              end;
              PModbusPLC[PLC].Status07LastError := Result;
            end;
          end;
    $0F:  begin // decodes a write to multiple coils
            Address := (Pkg.BufferToWrite[2] * 256) + Pkg.BufferToWrite[3];
            Len := (Pkg.BufferToWrite[4] * 256) + Pkg.BufferToWrite[5];
            if Result = ioOk then
              begin
                SetLength(Values, Len);

                i := 0;
                c := 0;
                c2 := 7;
                while i < Len do
                begin
                  if (c = 8) then
                  begin
                    c := 0;
                    Inc(c2);
                  end;
                  Values[i] := IfThen(((Longint(Pkg.BufferToWrite[c2]) and (1 shl c)) = (1 shl c)), 1, 0);
                  Inc(i);
                  Inc(c);
                end;
                if FoundPLC then
                  PModbusPLC[PLC].OutPuts.SetValues(Address, Len, 1, Values, Result);
              end
            else if FoundPLC then
              PModbusPLC[PLC].OutPuts.SetFault(Address, Len, 1, Result);
          end;
    $10:  begin // decodes a write to a multiple registers
            Address := (Pkg.BufferToWrite[2] * 256) + Pkg.BufferToWrite[3];
            Len := (Pkg.BufferToWrite[4] * 256) + Pkg.BufferToWrite[5];
            if Result = ioOk then
              begin
                SetLength(Values, Len);

                i := 0;
                while (i < Len) do
                begin
                  Values[i] := Pkg.BufferToWrite[7 + i * 2] * 256 + Pkg.BufferToWrite[8 + i * 2];
                  Inc(i);
                end;
                if FoundPLC then
                  PModbusPLC[PLC].Registers.SetValues(Address, Len, 1, Values, Result);
              end
            else if FoundPLC then
              PModbusPLC[PLC].Registers.SetFault(Address, Len, 1, Result);
          end;
    else
      begin
        // modbus error handling
        case Pkg.BufferToRead[2] of
          $01: Result := ioIllegalFunction;
          $02: Result := ioIllegalRegAddress;
          $03: Result := ioIllegalValue;
          $04: Result := ioPLCError;
          $05: Result := ioAcknowledge;
          $06: Result := ioBusy;
          $07: Result := ioNACK;
          $08: Result := ioMemoryParityError;
          $0A: Result := ioGatewayUnavailable;
          $0B: Result := ioDeviceGatewayFailedToRespond;
          else
            begin
              if Pkg.ReadIOResult = iorTimeOut then
                Result := ioTimeOut
              else
                Result := ioCommError;
            end;
        end;

        Address := (Pkg.BufferToWrite[2] shl 8) + Pkg.BufferToWrite[3];
        Len := (Pkg.BufferToWrite[4] shl 8) + Pkg.BufferToWrite[5];

        case Pkg.BufferToWrite[1] of
          $01:  begin
                  if FoundPLC then
                    PModbusPLC[PLC].OutPuts.SetFault(Address, Len, 1, Result, True);
                end;
          $02:  begin
                  if FoundPLC then
                    PModbusPLC[PLC].Inputs.SetFault(Address, Len, 1, Result, True);
                end;
          $03,
          $11:  begin
                  if FoundPLC then
                    PModbusPLC[PLC].Registers.SetFault(Address, Len, 1, Result, True);
                end;
          $04:  begin
                  if FoundPLC then
                    PModbusPLC[PLC].AnalogReg.SetFault(Address, Len, 1, Result, True);
                end;
        end;
      end;
  end;
end;

function TModBusRTUDriver.RemainingBytes(Buffer: Bytes): Longint;
begin
  // if some communication error happens, set the next read
  Result := 255;
  // to read 255 Bytes and clear the remaining Buffer
  if Length(Buffer) >= 3 then
  begin
    if (Buffer[PFuncByteOffset] and $80) = $80 then
      begin
        // is remaining the CRC at the Buffer
        Result := 2;
      end
    else
      begin
        case Buffer[PFuncByteOffset] of
          $01, $02,
          $03, $04,
          $11:       Result := Buffer[PFuncByteOffset + 1] + 2;
          $05, $06,
          $0F, $10:  Result := 5;
        end;
      end;
  end;
end;

end.

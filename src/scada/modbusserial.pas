{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Implementa o driver ModBus RTU.)
}
{$ELSE}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Unit that implements the ModBus RTU protocol driver.)
}
{$ENDIF}
unit ModBusSerial;

interface

uses
  Classes, ModBusDriver, Tag, commtypes, crc16utils;

type

  {$IFDEF PORTUGUES}
  {:
  @abstract(Classe driver ModBus RTU.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @bold(Para informações de como endereçar seus tags veja a classe TModBusDriver.)

  @seealso(TModBusDriver)
  }
  {$ELSE}
  {:
  @abstract(Class of ModBus RTU protocol driver.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @bold(For more information, see the documentation of TModBusDriver class.)

  @seealso(TModBusDriver)
  }
  {$ENDIF}

  { TModBusRTUDriver }

  TModBusRTUDriver = class(TModBusDriver)
  protected
    function AllowBroadCast: Boolean; override;
    //:  @seealso(TModBusDriver.EncodePkg)
    function EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes; override;
    //:  @seealso(TModBusDriver.DecodePkg)
    function DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult; override;
    //:  @seealso(TModBusDriver.RemainingBytes)
    function RemainingBytes(buffer: Bytes): Longint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    //:  @seealso(TModBusDriver.ReadSomethingAlways)
    property ReadSomethingAlways;
    //:  @seealso(TModBusDriver.OutputMaxHole)
    property OutputMaxHole;
    //:  @seealso(TModBusDriver.InputMaxHole)
    property InputMaxHole;
    //:  @seealso(TModBusDriver.RegisterMaxHole)
    property RegisterMaxHole;
    //:  @seealso(TModBusDriver.InputsMaxBlockSize)
    property InputsMaxBlockSize;
    //:  @seealso(TModBusDriver.OutputsMaxBlockSize)
    property OutputsMaxBlockSize;
    //:  @seealso(TModBusDriver.AnalogRegsMaxBlockSize)
    property AnalogRegsMaxBlockSize;
    //:  @seealso(TModBusDriver.HoldingRegsMaxBlockSize)
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
  //checa se é um pacote de escrita de valores ou de leitura
  //que está sendo codificado.

  //Verify if is packet to write data on device that is being encoded.

  //de leitura de valores...
  //read data from slave.
  if ToWrite = nil then
  begin
    case TagObj.ReadFunction of
      $01,
      $02,
      $03,
      $04:  begin
              //codifica pedido de leitura de entradas, saidas,
              //bloco de registradores e registrador simples.

              //encode a packet to read input, outputs, register or analog registers
              SetLength(Result, 8);
              Result[0] := TagObj.Station and $FF;
              Result[1] := TagObj.ReadFunction and $FF;
              Result[2] := (TagObj.Address and $FF00) Shr 8;
              Result[3] := TagObj.Address and $FF;
              Result[4] := (TagObj.Size and $FF00) Shr 8;
              Result[5] := TagObj.Size and $FF;
              // Calcula CRC
              // computes the CRC
              Calcul_CRC(Result);
            end;
      $11:  begin
              //encode a packet to ID
              SetLength(Result, 4);
              Result[0] := TagObj.Station and $FF;
              Result[1] := TagObj.ReadFunction and $FF;
              // Calcula CRC
              // computes the CRC
              Calcul_CRC(Result);
            end;
      $07:  begin
              // Lê o Status
              //encode a packet to read the device status.
              SetLength(Result, 4);
              Result[0] := TagObj.Station and $FF;
              Result[1] := $07;
              // Calcula o CRC
              // computes the CRC
              Calcul_CRC(Result);
            end;

      $08:  begin
              // Teste de Linha...
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

    // Calcula o tamanho do pacote resposta
    // computes the size of the incoming packet.
    case TagObj.ReadFunction of
      $01..$02: ResultLen := 5 + (TagObj.Size Div 8) + IfThen((TagObj.Size Mod 8) <> 0, 1, 0);
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
              //escreve uma saida...
              //encodes a packet to write a single coil.
              SetLength(Result, 8);
              Result[0] := TagObj.Station and $FF;
              Result[1] := $05;
              Result[2] := (TagObj.Address and $FF00) Shr 8;
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
              // Calcula CRC
              // computes the CRC
              Calcul_CRC(Result);
            end;

      $06:  begin
              // escreve 1 registro
              // encodes a packet to write a single register.
              SetLength(Result, 8);
              Result[0] := TagObj.Station and $FF;
              Result[1] := $06;
              Result[2] := (TagObj.Address and $FF00) Shr 8;
              Result[3] := TagObj.Address and $FF;
              Result[4] := (Trunc(ToWrite[0]) and $FF00) Shr 8;
              Result[5] := Trunc(ToWrite[0]) and $FF;
              // Calcula o CRC
              // computes the CRC
              Calcul_CRC(Result);
            end;

      $0F:  begin
              //Num de saidas em Bytes + 9 Bytes fixos.
              //encodes a packet to write multiple coils.
              SetLength(Result, (TagObj.Size Div 8) + IfThen((TagObj.Size Mod 8) > 0, 1, 0) + 9);
              Result[0] := TagObj.Station and $FF;
              Result[1] := $0F;
              Result[2] := ((TagObj.Address + TagObj.OffSet) and $FF00) Shr 8;        //endereco
              Result[3] := (TagObj.Address + TagObj.OffSet) and $FF;                  //endereco
              Result[4] := (Min(TagObj.Size, Length(ToWrite)) and $FF00) Shr 8;      //num de coils
              Result[5] := Min(TagObj.Size, Length(ToWrite)) and $FF;                //num de coils
              Result[6] := (TagObj.Size Div 8) + IfThen((TagObj.Size Mod 8) > 0, 1, 0);   //num de Bytes que seguem

              i := 0;
              c := 0;
              c2 := 7;
              Result[7] := 0;

              for c := 0 to Min(TagObj.Size, Length(ToWrite)) - 1 do
              begin
                if ToWrite[c] <> 0 then
                begin
                  Result[c2] := Result[c2] + (1 Shl i);
                end;

                Inc(i);
                if i > 7 then
                begin
                  i := 0;
                  Inc(c2);
                  Result[c2] := 0;
                end;
              end;

              // Calcula CRC
              // computes the CRC
              Calcul_CRC(Result);
            end;

      $10:  begin
              // Escreve X Bytes
              // encodes a packet to write multiple registers
              SetLength(Result, (TagObj.Size * 2) + 9);
              Result[0] := TagObj.Station and $FF;
              Result[1] := $10;
              Result[2] := ((TagObj.Address + TagObj.OffSet) and $FF00) Shr 8; //endereco
              Result[3] := (TagObj.Address + TagObj.OffSet) and $FF;           //endereco
              Result[4] := ((TagObj.Size and $FF00) Shr 8);                  //num de words
              Result[5] := TagObj.Size and $FF;                              //num de words
              Result[6] := (TagObj.Size * 2) and $FF;                          //num de Bytes que seguem = num de words * 2
              i := 0;
              while (i < TagObj.Size) do
              begin
                Result[7 + i * 2] := ((Trunc(ToWrite[i]) and $FF00) Shr 8);
                Result[8 + i * 2] := Trunc(ToWrite[i]) and $FF;
                Inc(i);
              end;
              // Calcula o CRC
              // computes the CRC
              Calcul_CRC(Result);
            end;
      else
        begin
          SetLength(Result, 0);
        end;
    end;
    // Calcula o tamanho do pacote resposta
    // computes the size of the incoming packet.
    case TagObj.WriteFunction of
      $05,
      $06,
      $0F,
      $10: ResultLen := 8;
      else
        begin
          ResultLen := 0;
        end;
    end;
  end;
end;

function TModBusRTUDriver.DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult;
var
  i, c, c2, PLC: Longint;
  Address, Len: Cardinal;
  FoundPLC: Boolean;
  Aux: TPLCMemoryManager;
begin
  //se algumas das IOs falhou,
  //if some IO fail.
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

  //se o endereco retornado nao conferem com o selecionado...
  //if the address in the incoming packet is different of the requested
  if (Result = ioOk) and (Pkg.BufferToWrite[0] <> Pkg.BufferToRead[0]) then
  begin
    Result := ioCommError;
  end;

  //se a checagem crc nao bate, sai
  //verify the CRC of incoming packet.
  if (Result = ioOk) and ((not Test_crc(Pkg.BufferToWrite)) or (not Test_crc(Pkg.BufferToRead))) then
    Result := ioCommError;

  //procura o PLC
  //search de PLC
  FoundPLC := False;
  for PLC := 0 to High(PModbusPLC) do
    if PModbusPLC[PLC].Station = Pkg.BufferToWrite[0] then
    begin
      FoundPLC := True;
      Break;
    end;

  //comeca a decodificar o pacote...
  //decodes the packet.

  //leitura de bits das entradas ou saidas
  //request to read the digital input/outpus (coils)
  if Length(Pkg.BufferToRead) < 2 then
  begin
    SetLength(Pkg.BufferToRead, 2);
    Pkg.BufferToRead[1] := 0;
  end;
  case Pkg.BufferToRead[1] of
    $01,
    $02:  begin
            //acerta onde vao ser colocados os valores decodificados...
            //where the data decoded will be stored.
            if FoundPLC then
            begin
              if Pkg.BufferToWrite[1] = $01 then
                Aux := PModbusPLC[PLC].OutPuts
              else
                Aux := PModbusPLC[PLC].Inputs;
            end;

            Address := (Pkg.BufferToWrite[2] Shl 8) + Pkg.BufferToWrite[3];
            Len := (Pkg.BufferToWrite[4] Shl 8) + Pkg.BufferToWrite[5];
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
                Values[i] := IfThen(((Longint(Pkg.BufferToRead[c2]) and (1 Shl c)) = (1 Shl c)), 1, 0);
                Inc(i);
                Inc(c);
              end;
              if FoundPLC then
                Aux.SetValues(Address, Len, 1, Values, Result);
            end
            else if FoundPLC then
              Aux.SetFault(Address, Len, 1, Result);
          end;

    //leitura de words dos registradores ou das entradas analogicas
    //request to read registers/analog registers
    $03,
    $04:  begin
            //acerta onde vao ser colocados os valores decodificados...
            //where the data decoded will be stored.
            if FoundPLC then
            begin
              if Pkg.BufferToWrite[1] = $03 then
                Aux := PModbusPLC[PLC].Registers
              else
                Aux := PModbusPLC[PLC].AnalogReg;
            end;

            Address := Cardinal((Pkg.BufferToWrite[2] Shl 8) + Pkg.BufferToWrite[3]);
            Len := Cardinal((Pkg.BufferToWrite[4] Shl 8) + Pkg.BufferToWrite[5]);

            if Result = ioOk then
            begin
              SetLength(Values, Len);

              // data are ok
              for i := 0 to Len - 1 do
              begin
                Values[i] := (Longint(Pkg.BufferToRead[3 + (i * 2)]) Shl 8) + Longint(Pkg.BufferToRead[4 + i * 2]);
              end;

              if FoundPLC then
                Aux.SetValues(Address, Len, 1, Values, Result);
            end
            else if FoundPLC then
              Aux.SetFault(Address, Len, 1, Result);
          end;
    $11:  begin
            //acerta onde vao ser colocados os valores decodificados...
            //where the data decoded will be stored.
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

    // decodifica a escrita de uma saida digital
    // decodes a write to a single coil
    $05:  begin
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

    // decodifica a escrita de um registro
    // decodes a write to a single register
    $06:  begin
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

    // decodifica o status do escravo
    // decodes a the current state of the slave
    $07:  begin
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

    // decodifica a escrita de multiplos saidas digitais
    // decodes a write to multiple coils.
    $0F:  begin
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
                Values[i] := IfThen(((Longint(Pkg.BufferToWrite[c2]) and (1 Shl c)) = (1 Shl c)), 1, 0);
                Inc(i);
                Inc(c);
              end;
              if FoundPLC then
                PModbusPLC[PLC].OutPuts.SetValues(Address, Len, 1, Values, Result);
            end
            else if FoundPLC then
              PModbusPLC[PLC].OutPuts.SetFault(Address, Len, 1, Result);
          end;

    // decodifica a escrita de multiplos registros
    // decodes a write to a multiple registers
    $10:  begin
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
      //tratamento de erros modbus
      //modbus error handling.
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

      Address := (Pkg.BufferToWrite[2] Shl 8) + Pkg.BufferToWrite[3];
      Len := (Pkg.BufferToWrite[4] Shl 8) + Pkg.BufferToWrite[5];

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

function TModBusRTUDriver.RemainingBytes(buffer: Bytes): Longint;
begin
  Result := 255; //if some communication error happens, set the next read
  //to read 255 Bytes and clear the remaining buffer.
  if Length(buffer) >= 3 then
  begin
    if (buffer[PFuncByteOffset] and $80) = $80 then
    begin
      Result := 2; //is remaining the CRC at the buffer.
    end
    else
    begin
      case buffer[PFuncByteOffset] of
        $01,
        $02,
        $03,
        $04,
        $11: Result := buffer[PFuncByteOffset + 1] + 2;
        $05,
        $06,
        $0F,
        $10: Result := 5;
      end;
    end;
  end;
end;

end.

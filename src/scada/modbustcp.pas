{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Implementa o driver ModBus TCP.)
}
{$ELSE}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Unit that implements the ModBus TCP protocol driver.)
}
{$ENDIF}
unit ModBusTCP;

{$IFDEF FPC}
{$IFDEF DEBUG}
  {$DEFINE FDEBUG}
{$ENDIF}
{$ENDIF}

interface

uses
  ModBusDriver, Tag, commtypes, Classes;

type

  {$IFDEF PORTUGUES}
  {:
  @abstract(Classe driver ModBus para TCP/IP.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @bold(Para informações de como endereçar seus tags veja a classe TModBusDriver.)

  @seealso(TModBusDriver)
  }
  {$ELSE}
  {:
  @abstract(Class of ModBus TCP/IP protocol driver.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @bold(For more information, see the documentation of TModBusDriver class.)

  @seealso(TModBusDriver)
  }
  {$ENDIF}

  { TModBusTCPDriver }

  TModBusTCPDriver = class(TModBusDriver)
  protected
    //:  @seealso(TModBusDriver.EncodePkg)
    function EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes; override;
    //:  @seealso(TModBusDriver.DecodePkg)
    function DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult; override;
    //:  @seealso(TModBusDriver.RemainingBytes)
    function RemainingBytes(Buffer: Bytes): Longint; override;
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
  Math,
  PLCMemoryManager,
  SysUtils,
  crossdatetime
  {$IFDEF FDEBUG}
  , LCLProc
  {$ENDIF}
  ;


constructor TModBusTCPDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PInternalDelayBetweenCmds := 0;
  PFirstRequestLen := 9;
  PFuncByteOffset := 7;
  PCRCLen := 0;
end;

function TModBusTCPDriver.EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes;
var
  i: Longint;
  c: Longint;
  c2: Longint;
  Size: Longint;
begin
  //checa se é um pacote de escrita de valores ou de leitura
  //que está sendo codificado.

  //Verify if is packet to write data on device that is being encoded.

  //de leitura de valores...
  //read data from slave.
  if ToWrite = nil then
  begin
    case TagObj.ReadFunction of
      $01, $02, $03, $04: begin
        //codifica pedido de leitura de entradas, saidas,
        //bloco de registradores e registrador simples.

        //encode a packet to read input, outputs, register or analog registers
        SetLength(Result, 12);
        Result[00] := 0;
        Result[01] := 0;
        Result[02] := 0;
        Result[03] := 0;
        Result[04] := 0; //Size of the packet, bHi
        Result[05] := 6; //Size of the packet, bLo
        Result[06] := TagObj.Station and $FF;
        Result[07] := TagObj.ReadFunction and $FF;
        Result[08] := (TagObj.Address and $FF00) Shr 8;
        Result[09] := TagObj.Address and $FF;
        Result[10] := (TagObj.size and $FF00) Shr 8;
        Result[11] := TagObj.size and $FF;
      end;

      $07: begin
        // Lê o Status
        //encode a packet to read the device status.
        SetLength(Result, 8);
        Result[00] := 0;
        Result[01] := 0;
        Result[02] := 0;
        Result[03] := 0;
        Result[04] := 0; //Size of the packet, bHi
        Result[05] := 2; //Size of the packet, bLo
        Result[06] := TagObj.Station and $FF;
        Result[07] := $07;
      end;

      $08: begin
        // Teste de Linha...
        // line test
        SetLength(Result, 12);
        Result[00] := 0;
        Result[01] := 0;
        Result[02] := 0;
        Result[03] := 0;
        Result[04] := 0; //Size of the packet, bHi
        Result[05] := 6; //Size of the packet, bLo
        Result[06] := TagObj.Station and $FF;
        Result[07] := $08;
        Result[08] := 0;
        Result[09] := 0;
        Result[10] := 0;
        Result[11] := 0;
      end;
      else
      begin
        SetLength(Result, 0);
      end;
    end;

    // Calcula o tamanho do pacote resposta
    // computes the Size of the incoming packet.
    case TagObj.ReadFunction of
      $01..$02:
        ResultLen := 9 + (TagObj.size Div 8) + IfThen((TagObj.size Mod 8) <> 0, 1, 0);
      $03..$04:
        ResultLen := 9 + (TagObj.size * 2);
      $07:
        ResultLen := 9;
      $08:
        ResultLen := 12;
      else
      begin
        ResultLen := 0;
      end;
    end;
  end
  else
  begin
    case TagObj.WriteFunction of
      $05: begin
        //escreve uma saida...
        //encodes a packet to write a single coil.
        SetLength(Result, 12);
        Result[00] := 0;
        Result[01] := 0;
        Result[02] := 0;
        Result[03] := 0;
        Result[04] := 0; //Size of the packet, bHi
        Result[05] := 6; //Size of the packet, bLo
        Result[06] := TagObj.Station and $FF;
        Result[07] := $05;
        Result[08] := (TagObj.Address and $FF00) Shr 8;
        Result[09] := TagObj.Address and $FF;

        if (ToWrite[0] = 0) then
        begin
          Result[10] := $00;
          Result[11] := $00;
        end
        else
        begin
          Result[10] := $FF;
          Result[11] := $00;
        end;
      end;

      $06: begin
        // escreve 1 registro
        // encodes a packet to write a single register.
        SetLength(Result, 12);
        Result[00] := 0;
        Result[01] := 0;
        Result[02] := 0;
        Result[03] := 0;
        Result[04] := 0; //Size of the packet, bHi
        Result[05] := 6; //Size of the packet, bLo
        Result[06] := TagObj.Station and $FF;
        Result[07] := $06;
        Result[08] := (TagObj.Address and $FF00) Shr 8;
        Result[09] := TagObj.Address and $FF;
        Result[10] := (Trunc(ToWrite[0]) and $FF00) Shr 8;
        Result[11] := Trunc(ToWrite[0]) and $FF;
      end;

      $0F: begin
        //Num de saidas em Bytes + 9 Bytes fixos.
        //encodes a packet to write multiple coils.
        Size := (TagObj.size Div 8) + IfThen((TagObj.size Mod 8) > 0, 1, 0);
        SetLength(Result, Size + 13); //13 = end+func+address 2b,num bits 2b, pkg len 1b + 6 modbus tcp

        Result[00] := 0;
        Result[01] := 0;
        Result[02] := 0;
        Result[03] := 0;
        Result[04] := ((Size + 7) and $FF00) Div $100; //Size of the packet, bHi
        Result[05] := ((Size + 7) and $FF);            //Size of the packet, bLo
        Result[06] := TagObj.Station and $FF;
        Result[07] := $0F;
        Result[08] := ((TagObj.Address + TagObj.OffSet) and $FF00) Shr 8;      //endereco
        Result[09] := (TagObj.Address + TagObj.OffSet) and $FF;                //endereco
        Result[10] := (Min(TagObj.size, Length(ToWrite)) and $FF00) Shr 8;    //num de coils
        Result[11] := Min(TagObj.size, Length(ToWrite)) and $FF;              //num de coils
        Result[12] := (TagObj.size Div 8) + IfThen((TagObj.size Mod 8) > 0, 1, 0); //num de Bytes que seguem

        i := 0;
        c := 0;
        c2 := 13;
        Result[13] := 0;

        for c := 0 to Min(TagObj.size, Length(ToWrite)) - 1 do
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
      end;

      $10: begin
        // Escreve X Bytes
        // encodes a packet to write multiple registers
        Size := (TagObj.size * 2);
        SetLength(Result, Size + 13); //13 = address+func+address 2b,num bits 2b, pkg len 1b + 6 modbus tcp

        Result[00] := 0;
        Result[01] := 0;
        Result[02] := 0;
        Result[03] := 0;
        Result[04] := ((Size + 7) and $FF00) Div $100; //Size of the packet, bHi
        Result[05] := ((Size + 7) and $FF);            //Size of the packet, bLo

        Result[06] := TagObj.Station and $FF;
        Result[07] := $10;
        Result[08] := ((TagObj.Address + TagObj.OffSet) and $FF00) Shr 8;  //endereco
        Result[09] := (TagObj.Address + TagObj.OffSet) and $FF;            //endereco
        Result[10] := ((TagObj.size and $FF00) Shr 8);                   //num de words
        Result[11] := TagObj.size and $FF;                               //num de words
        Result[12] := (TagObj.size * 2) and $FF;                           //num de Bytes que seguem = num de words * 2
        i := 0;
        while (i < TagObj.size) do
        begin
          Result[13 + i * 2] := ((Trunc(ToWrite[i]) and $FF00) Shr 8);
          Result[14 + i * 2] := Trunc(ToWrite[i]) and $FF;
          Inc(i);
        end;
      end;
      else
      begin
        SetLength(Result, 0);
      end;
    end;
    // Calcula o tamanho do pacote resposta
    // computes the Size of the incoming packet.
    case TagObj.WriteFunction of
      $05, $06, $0F, $10:
        ResultLen := 12;
      else
      begin
        ResultLen := 0;
      end;
    end;
  end;
end;

function TModBusTCPDriver.DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult;
var
  i, c, c2, plc: Longint;
  Address, len: Cardinal;
  foundPLC: Boolean;
  aux: TPLCMemoryManager;
begin
  //se algumas das IOs falhou,
  //if some IO fail.
  Result := ioOk;
  case Pkg.WriteIOResult of
    iorTimeOut:
      Result := ioTimeOut;
    iorNotReady,
    iorNone:
      Result := ioDriverError;
    iorPortError:
      Result := ioCommError;
  end;

  if (Result <> ioOk) then
    case Pkg.ReadIOResult of
      iorTimeOut:
        Result := ioTimeOut;
      iorNotReady,
      iorNone:
        Result := ioDriverError;
      iorPortError:
        Result := ioCommError;
    end;

  //se o endereco retornado nao conferem com o selecionado...
  //if the address in the incoming packet is different of the requested
  if (Result = ioOk) and (Pkg.BufferToWrite[6] <> Pkg.BufferToRead[6]) then
  begin
    {$IFDEF FDEBUG}
    debug := '';
    for c := 0 to High(pkg.BufferToRead) do
      debug := debug + IntToHex(pkg.BufferToRead[c], 2);
    DebugLn('Pacotes diferem no endereço. Hex do pacote recebido:');
    DebugLn(debug);
    {$ENDIF}
    Result := ioCommError;
  end;

  //procura o plc
  //search de PLC
  foundPLC := False;
  for plc := 0 to High(PModbusPLC) do
    if PModbusPLC[plc].Station = Pkg.BufferToWrite[6] then
    begin
      foundPLC := True;
      Break;
    end;

  //comeca a decodificar o pacote...
  //decodes the packet.

  //leitura de bits das entradas ou saidas
  //request to read the digital input/outpus (coils)
  if Length(Pkg.BufferToRead) < 8 then
  begin
    SetLength(Pkg.BufferToRead, 8);
    Pkg.BufferToRead[7] := 0;
  end;
  case Pkg.BufferToRead[7] of
    $01, $02: begin
      //acerta onde vao ser colocados os valores decodificados...
      //where the data decoded will be stored.
      if foundPLC then
      begin
        if Pkg.BufferToWrite[7] = $01 then
          aux := PModbusPLC[plc].OutPuts
        else
          aux := PModbusPLC[plc].Inputs;
      end;

      if Result = ioOk then
      begin
        Address := (Pkg.BufferToWrite[08] Shl 8) + Pkg.BufferToWrite[09];
        len := (Pkg.BufferToWrite[10] Shl 8) + Pkg.BufferToWrite[11];
        SetLength(Values, len);

        i := 0;
        c := 0;
        c2 := 9;
        while (i < len) and (c2 < Length(Pkg.BufferToRead)) do
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
        if foundPLC then
          aux.SetValues(Address, len, 1, Values, Result);
      end
      else
      if foundPLC then
        aux.SetFault(Address, len, 1, Result);
    end;

    //leitura de words dos registradores ou das entradas analogicas
    //request to read registers/analog registers
    $03, $04: begin
      //acerta onde vao ser colocados os valores decodificados...
      //where the data decoded will be stored.
      if foundPLC then
      begin
        if Pkg.BufferToWrite[7] = $03 then
          aux := PModbusPLC[plc].Registers
        else
          aux := PModbusPLC[plc].AnalogReg;
      end;

      if Result = ioOk then
      begin
        Address := (Pkg.BufferToWrite[08] Shl 8) + Pkg.BufferToWrite[09];
        len := (Pkg.BufferToWrite[10] Shl 8) + Pkg.BufferToWrite[11];
        SetLength(Values, len);

        // data are ok
        for i := 0 to len - 1 do
        begin
          if (10 + i * 2) < Length(Pkg.BufferToRead) then
            Values[i] := (Longint(Pkg.BufferToRead[9 + (i * 2)]) Shl 8) + Longint(Pkg.BufferToRead[10 + i * 2])
          else
            Values[i] := 0;
        end;

        if foundPLC then
          aux.SetValues(Address, len, 1, Values, Result);
      end
      else
      if foundPLC then
        aux.SetFault(Address, len, 1, Result);
    end;

    // decodifica a escrita de uma saida digital
    // decodes a write to a single coil
    $05: begin
      if Result = ioOk then
      begin
        Address := (Pkg.BufferToWrite[8] * 256) + Pkg.BufferToWrite[9];
        SetLength(Values, 1);

        if (Pkg.BufferToWrite[10] = 0) and (Pkg.BufferToWrite[11] = 0) then
          Values[0] := 0
        else
          Values[0] := 1;

        if foundPLC then
          PModbusPLC[plc].OutPuts.SetValues(Address, 1, 1, Values, Result);
      end
      else
      if foundPLC then
        PModbusPLC[plc].OutPuts.SetFault(Address, 1, 1, Result);
    end;

    // decodifica a escrita de um registro
    // decodes a write to a single register
    $06: begin
      if Result = ioOk then
      begin
        Address := (Pkg.BufferToWrite[8] * 256) + Pkg.BufferToWrite[9];
        SetLength(Values, 1);

        Values[0] := Pkg.BufferToWrite[10] * 256 + Pkg.BufferToWrite[11];

        if foundPLC then
          PModbusPLC[plc].Registers.SetValues(Address, 1, 1, Values, Result);
      end
      else
      if foundPLC then
        PModbusPLC[plc].Registers.SetFault(Address, 1, 1, Result);
    end;

    // decodifica o status do escravo
    // decodes a the current state of the slave
    $07: begin
      if foundPLC then
      begin
        if Result = ioOk then
        begin
          PModbusPLC[plc].Status07Value := Longint(Pkg.BufferToRead[8]);
          PModbusPLC[plc].Status07TimeStamp := CrossNow;
        end;
        PModbusPLC[plc].Status07LastError := Result;
      end;
    end;

    // decodifica a escrita de multiplos saidas digitais
    // decodes a write to multiple coils.
    $0F: begin
      if Result = ioOk then
      begin
        Address := (Pkg.BufferToWrite[08] * 256) + Pkg.BufferToWrite[09];
        len := (Pkg.BufferToWrite[10] * 256) + Pkg.BufferToWrite[11];

        SetLength(Values, len);

        i := 0;
        c := 0;
        c2 := 13;
        while (i < len) and (c2 < Length(Pkg.BufferToRead)) do
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

        if foundPLC then
          PModbusPLC[plc].OutPuts.SetValues(Address, len, 1, Values, Result);
      end
      else
      if foundPLC then
        PModbusPLC[plc].OutPuts.SetFault(Address, len, 1, Result);
    end;

    // decodifica a escrita de multiplos registros
    // decodes a write to a multiple registers
    $10: begin
      if Result = ioOk then
      begin
        Address := (Pkg.BufferToWrite[08] * 256) + Pkg.BufferToWrite[09];
        len := (Pkg.BufferToWrite[10] * 256) + Pkg.BufferToWrite[11];

        SetLength(Values, len);

        i := 0;
        while (i < len) do
        begin
          Values[i] := Pkg.BufferToWrite[13 + i * 2] * 256 + Pkg.BufferToWrite[14 + i * 2];
          Inc(i);
        end;

        if foundPLC then
          PModbusPLC[plc].Registers.SetValues(Address, len, 1, Values, Result);
      end
      else
      if foundPLC then
        PModbusPLC[plc].Registers.SetFault(Address, len, 1, Result);
    end;
    else
    begin
      //tratamento de erros modbus
      //modbus error handling.
      case Pkg.BufferToRead[8] of
        $01:
          Result := ioIllegalFunction;
        $02:
          Result := ioIllegalRegAddress;
        $03:
          Result := ioIllegalValue;
        $04:
          Result := ioPLCError;
        $05:
          Result := ioAcknowledge;
        $06:
          Result := ioBusy;
        $07:
          Result := ioNACK;
        $08:
          Result := ioMemoryParityError;
        $0A:
          Result := ioGatewayUnavailable;
        $0B:
          Result := ioDeviceGatewayFailedToRespond;
        else
        begin
          if Pkg.ReadIOResult = iorTimeOut then
            Result := ioTimeOut
          else
            Result := ioCommError;
        end;
      end;

      Address := (Pkg.BufferToWrite[08] Shl 8) + Pkg.BufferToWrite[09];
      len := (Pkg.BufferToWrite[10] Shl 8) + Pkg.BufferToWrite[11];

      case Pkg.BufferToWrite[7] of
        $01: begin
          if foundPLC then
            PModbusPLC[plc].OutPuts.SetFault(Address, len, 1, Result, True);
        end;
        $02: begin
          if foundPLC then
            PModbusPLC[plc].Inputs.SetFault(Address, len, 1, Result, True);
        end;
        $03: begin
          if foundPLC then
            PModbusPLC[plc].Registers.SetFault(Address, len, 1, Result, True);
        end;
        $04: begin
          if foundPLC then
            PModbusPLC[plc].AnalogReg.SetFault(Address, len, 1, Result, True);
        end;
      end;
    end;
  end;
end;

function TModBusTCPDriver.RemainingBytes(Buffer: Bytes): Longint;
begin
  if High(Buffer) >= 5 then
    Result := Buffer[5] - 3;
end;

end.

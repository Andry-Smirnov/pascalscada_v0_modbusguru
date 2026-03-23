{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Implementa o driver MC PROTOCOL.)
}
{$ELSE}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Unit that implements the MC PROTOCOL driver.)
}
{$ENDIF}

unit MelsecTCP;

{$IFDEF FPC}
{$mode delphi}
{$IFDEF DEBUG}
  {$DEFINE FDEBUG}
{$ENDIF}
{$ENDIF}

interface

uses
  MelsecDriver, Tag, commtypes, Classes;

type
  TMelsecTCPDriver = class(TMelsecDriver)
  protected
    function EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes; override;
    function DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult; override;
    function RemainingBytesWrite(Buffer: Bytes): Longint; override;
    function RemainingBytesRead(Buffer: Bytes; TagObj: TTagRec): Longint; override;
    function PlcDeviceType(MemReadWriteFunction: Integer): Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ReadSomethingAlways;
    property Output_M_MaxHole;
    property Output_SM_MaxHole;
    property Output_L_MaxHole;
    property Output_F_MaxHole;
    property Output_V_MaxHole;
    property Output_X_MaxHole;
    property Output_Y_MaxHole;
    property Output_B_MaxHole;
    property Register_D_MaxHole;
    property Register_SD_MaxHole;
    property SerieCLP;
  end;

implementation

uses
  Math, PLCMemoryManager, SysUtils
  {$IFDEF FDEBUG}
  , LCLProc
  {$ENDIF}
  ;

  { TMelsecTCPDriver }

constructor TMelsecTCPDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PInternalDelayBetweenCmds := 0;
  PFirstRequestLen := 9;
  PFuncByteOffset := 11;
  PCRCLen := 0;
end;

function TMelsecTCPDriver.DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult;
var
  i: Longint;
  c: Longint;
  c2: Longint;
  PLC: Longint;
  Address,
  Len: Cardinal;
  FoundPLC: Boolean;
  {$IFDEF FDEBUG}
   debug:string;
  {$ENDIF}
begin
  // if some IO fail
  Result := ioOk;
  case Pkg.WriteIOResult of
    iorTimeOut:   Result := ioTimeOut;
    iorNotReady,
    iorNone:      Result := ioDriverError;
    iorPortError: Result := ioCommError;
  end;

  if (Result <> ioOk) then
    case Pkg.ReadIOResult of
      iorTimeOut:   Result := ioTimeOut;
      iorNotReady,
      iorNone:      Result := ioDriverError;
      iorPortError: Result := ioCommError;
    end;

  // if the Address in the incoming packet is different of the requested
  if (Result = ioOk) and (Pkg.BufferToWrite[6] <> Pkg.BufferToRead[6]) then
  begin
    {$IFDEF FDEBUG}
    Debug := '';
    for c := 0 to High(Pkg.BufferToRead) do
      Debug := Debug + IntToHex(Pkg.BufferToRead[c], 2);
    DebugLn('Pacotes diferem no endere�o. Hex do pacote recebido:');
    DebugLn(Debug);
    {$ENDIF}
    Result := ioCommError;
  end;

  // search de PLC
  FoundPLC := False;
  for PLC := 0 to High(PMelsecPLC) do
    //if PMelsecPLC[PLC].Station = Pkg.BufferToWrite[6] then begin
    if PMelsecPLC[PLC].Station = 1 then
    begin
      FoundPLC := True;
      Break;
    end;

  // decodes the packet

  // se for bit
  if (Pkg.BufferToWrite[13] = 1) then // byte
  begin
    if (Pkg.BufferToWrite[12] = 20) then // writing
    begin
      if Result = ioOk then
        begin
          Address := (Pkg.BufferToWrite[15]) + (Pkg.BufferToWrite[16] shl 8) + (Pkg.BufferToWrite[17] shl 16);
          Len := (Pkg.BufferToWrite[10] shl 8) + Pkg.BufferToWrite[11];

          SetLength(Values, Len);

          i := 0;
          while (i < Len) do
          begin
            Values[i] := Pkg.BufferToWrite[21] + Pkg.BufferToWrite[22];
            Inc(i);
          end;

          if Length(PMelsecPLC) > 0 then
          begin
            case Pkg.BufferToWrite[18] of
              144: PMelsecPLC[0].OutPuts_M.SetValues(Address, Len, 1, Values, Result);
              145: PMelsecPLC[0].OutPuts_SM.SetValues(Address, Len, 1, Values, Result);
              146: PMelsecPLC[0].OutPuts_L.SetValues(Address, Len, 1, Values, Result);
              147: PMelsecPLC[0].OutPuts_F.SetValues(Address, Len, 1, Values, Result);
              148: PMelsecPLC[0].OutPuts_V.SetValues(Address, Len, 1, Values, Result);
              156: PMelsecPLC[0].OutPuts_X.SetValues(Address, Len, 1, Values, Result);
              157: PMelsecPLC[0].OutPuts_Y.SetValues(Address, Len, 1, Values, Result);
              160: PMelsecPLC[0].OutPuts_B.SetValues(Address, Len, 1, Values, Result);
            end;
          end;
        end
      else if FoundPLC then
        begin
          case Pkg.BufferToWrite[18] of
            144: PMelsecPLC[PLC].OutPuts_M.SetFault(Address, Len, 1, Result);
            145: PMelsecPLC[PLC].OutPuts_SM.SetFault(Address, Len, 1, Result);
            146: PMelsecPLC[PLC].OutPuts_L.SetFault(Address, Len, 1, Result);
            147: PMelsecPLC[PLC].OutPuts_F.SetFault(Address, Len, 1, Result);
            148: PMelsecPLC[PLC].OutPuts_V.SetFault(Address, Len, 1, Result);
            156: PMelsecPLC[PLC].OutPuts_X.SetFault(Address, Len, 1, Result);
            157: PMelsecPLC[PLC].OutPuts_Y.SetFault(Address, Len, 1, Result);
            160: PMelsecPLC[PLC].OutPuts_B.SetFault(Address, Len, 1, Result);
          end;
        end;
    end;

    if (Pkg.BufferToWrite[12] = 4) then // reading
    begin
      // where the data decoded will be stored
      if Result = ioOk then
        begin
          Address := (Pkg.BufferToWrite[15]) + (Pkg.BufferToWrite[16] shl 8) + (Pkg.BufferToWrite[17] shl 16);
          Len := Pkg.BufferToWrite[19];
          SetLength(Values, Len);

          i := 0;

          for i := 0 to Len - 1 do
          begin
            SetLength(Values, 1);
            c2 := (i div 2) + 11;
            if (i mod 2 = 0) then
              Values[0] := Byte(Pkg.BufferToRead[c2] shr 4)
            else
              begin
                c := Longint(Byte(Pkg.BufferToRead[c2]));
                if c = 17 then
                  c := 1;
                if c = 16 then
                  c := 0;
                Values[0] := c;
              end;
            if Length(PMelsecPLC) > 0 then
            begin
              case Pkg.BufferToWrite[18] of
                144: PMelsecPLC[0].OutPuts_M.SetValues(Address, 1, 1, Values, Result);
                145: PMelsecPLC[0].OutPuts_SM.SetValues(Address, 1, 1, Values, Result);
                146: PMelsecPLC[0].OutPuts_L.SetValues(Address, 1, 1, Values, Result);
                147: PMelsecPLC[0].OutPuts_F.SetValues(Address, 1, 1, Values, Result);
                148: PMelsecPLC[0].OutPuts_V.SetValues(Address, 1, 1, Values, Result);
                156: PMelsecPLC[0].OutPuts_X.SetValues(Address, 1, 1, Values, Result);
                157: PMelsecPLC[0].OutPuts_Y.SetValues(Address, 1, 1, Values, Result);
                160: PMelsecPLC[0].OutPuts_B.SetValues(Address, 1, 1, Values, Result);
              end;
            end;
            Address := Address + 1;
          end;
        end
      else if FoundPLC then
        begin
          case Pkg.BufferToWrite[18] of
            144: PMelsecPLC[0].OutPuts_M.SetFault(Address, Len, 1, Result);
            145: PMelsecPLC[0].OutPuts_SM.SetFault(Address, Len, 1, Result);
            146: PMelsecPLC[0].OutPuts_L.SetFault(Address, Len, 1, Result);
            147: PMelsecPLC[0].OutPuts_F.SetFault(Address, Len, 1, Result);
            148: PMelsecPLC[0].OutPuts_V.SetFault(Address, Len, 1, Result);
            156: PMelsecPLC[0].OutPuts_X.SetFault(Address, Len, 1, Result);
            157: PMelsecPLC[0].OutPuts_Y.SetFault(Address, Len, 1, Result);
            160: PMelsecPLC[0].OutPuts_B.SetFault(Address, Len, 1, Result);
          end;
        end;
    end;
  end;

  ///////////////////////////////////////
  /// se for float
  if (Pkg.BufferToWrite[13] = 0) then // float
  begin
    if (Pkg.BufferToWrite[12] = 20) then // writing
    begin
      if Result = ioOk then
        begin
          Address := (Pkg.BufferToWrite[15]) + (Pkg.BufferToWrite[16] shl 8) + (Pkg.BufferToWrite[17] shl 16);
          Len := (Pkg.BufferToWrite[10] shl 8) + Pkg.BufferToWrite[11];

          SetLength(Values, Len);

          i := 0;
          while (i < Len) do
          begin
            Values[i] := Pkg.BufferToWrite[21] + Pkg.BufferToWrite[22];
            Inc(i);
          end;

          if Length(PMelsecPLC) > 0 then
          begin
            case Pkg.BufferToWrite[18] of
              168: PMelsecPLC[0].Registers_D.SetValues(Address, Len, 1, Values, Result);
              169: PMelsecPLC[0].Registers_SD.SetValues(Address, Len, 1, Values, Result);
            end;
          end;
        end
      else if FoundPLC then
        begin
          case Pkg.BufferToWrite[18] of
            168: PMelsecPLC[PLC].Registers_D.SetFault(Address, Len, 1, Result);
            169: PMelsecPLC[PLC].Registers_SD.SetFault(Address, Len, 1, Result);
          end;
        end;
    end;

    if (Pkg.BufferToWrite[12] = 4) then // reading
    begin
      if Result = ioOk then
      begin
        Address := (Pkg.BufferToWrite[15]) + (Pkg.BufferToWrite[16] shl 8) + (Pkg.BufferToWrite[17] shl 16);
        Len := Pkg.BufferToWrite[19];

        SetLength(Values, Len);

        for i := 0 to Len - 1 do
        begin
          SetLength(Values, 1);
          Values[0] := (Longint(Pkg.BufferToRead[11 + (i * 2)])) + Longint(Pkg.BufferToRead[12 + i * 2] shl 8);

          if Length(PMelsecPLC) > 0 then
          begin
            case Pkg.BufferToWrite[18] of
              168: PMelsecPLC[0].Registers_D.SetValues(Address, 1, 1, Values, Result);
              169: PMelsecPLC[0].Registers_SD.SetValues(Address, 1, 1, Values, Result);
            end;
          end;
          Address := Address + 1;
        end;
      end
      else if FoundPLC then
      begin
        case Pkg.BufferToWrite[18] of
          168: PMelsecPLC[0].Registers_D.SetFault(Address, Len, 1, Result);
          169: PMelsecPLC[0].Registers_SD.SetFault(Address, Len, 1, Result);
        end;
      end;
    end;
  end;
end;

function TMelsecTCPDriver.EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Integer): Bytes;
var
  NetworkNumber: Integer;
  PCNumber: Integer;
  IONumber: Integer;
  ChannelNumber: Integer;
  CPUTimer: Integer;
  AMainCommand: Integer;
  ASubCommand: Integer;
  Frame: Integer;
  DataLength: Integer;
begin
  // Verify if is packet to write data on device that is being encoded

  // read data from slave
  if ToWrite = nil then
    begin
      case TagObj.ReadFunction of
        $01..$08: begin
                    //codifica pedido de reading de entradas, saidas,
                    //bloco de registradores e registrador simples.
                    //encode a packet to read input, outputs, register or analog registers
                    Frame := 80;
                    NetworkNumber := 0;
                    PCNumber := 255;
                    IONumber := 1023;
                    ChannelNumber := 0;
                    DataLength := 12;
                    CPUTimer := 16;
                    AMainCommand := 1025;
                    ASubCommand := 1;

                    SetLength(Result, 22);
                    Result[00] := Frame;
                    Result[01] := Frame shr 8;
                    Result[02] := NetworkNumber;
                    Result[03] := PCNumber;
                    Result[04] := IONumber;
                    Result[05] := IONumber shr 8;
                    Result[06] := ChannelNumber;
                    Result[07] := DataLength;
                    Result[08] := DataLength shr 8;
                    Result[09] := CPUTimer;
                    Result[10] := CPUTimer shr 8;
                    Result[11] := AMainCommand;
                    Result[12] := AMainCommand shr 8;
                    Result[13] := ASubCommand;
                    Result[14] := ASubCommand shr 8;

                    Result[15] := TagObj.address;
                    Result[16] := TagObj.address shr 8;
                    Result[17] := TagObj.address shr 16;
                    Result[18] := PlcDeviceType(TagObj.ReadFunction);
                    Result[19] := TagObj.Size;
                    Result[20] := TagObj.Size shr 8;
                    Result[21] := 0;
                  end;
        $09, $10: begin
                    // encode a packet to read input, outputs, register or analog registers
                    // fixed values
                    Frame := 80;
                    NetworkNumber := 0;
                    PCNumber := 255;
                    IONumber := 1023;
                    ChannelNumber := 0;
                    CPUTimer := 16;
                    AMainCommand := 1025;
                    DataLength := 12;
                    ASubCommand := 0;

                    SetLength(Result, 22);
                    Result[00] := Frame;
                    Result[01] := Frame shr 8;
                    Result[02] := NetworkNumber;
                    Result[03] := PCNumber;
                    Result[04] := IONumber; //size of the packet, bHi
                    Result[05] := IONumber shr 8; //size of the packet, bLo
                    Result[06] := ChannelNumber;
                    Result[07] := DataLength;
                    Result[08] := DataLength shr 8;
                    Result[09] := CPUTimer;
                    Result[10] := CPUTimer shr 8;
                    Result[11] := AMainCommand;
                    Result[12] := AMainCommand shr 8;
                    Result[13] := ASubCommand;
                    Result[14] := ASubCommand shr 8;

                    Result[15] := TagObj.address;
                    Result[16] := TagObj.address shr 8;
                    Result[17] := TagObj.address shr 16;
                    Result[18] := PlcDeviceType(TagObj.ReadFunction);
                    Result[19] := TagObj.Size;
                    Result[20] := TagObj.Size shr 8;
                    Result[21] := 0;
                  end;

        else
          begin
            SetLength(Result, 0);
          end;
      end;

      // computes the size of the incoming packet
      case TagObj.ReadFunction of
        $01..$08: ResultLen := 9 + (TagObj.Size div 8) + IfThen((TagObj.Size mod 8) <> 0, 1, 0);
        $09..$10: ResultLen := 9 + (TagObj.Size * 2);
        else
          begin
            ResultLen := 0;
          end;
      end;
    end
  else
    begin
      case TagObj.WriteFunction of
        $01..$08: begin
                    //escreve uma saida...
                    //encodes a packet to write a single coil.
                    Frame := 80;
                    NetworkNumber := 0;
                    PCNumber := 255;
                    IONumber := 1023;
                    ChannelNumber := 0;
                    CPUTimer := 16;
                    AMainCommand := 5121;
                    DataLength := 13;
                    ASubCommand := 1;

                    SetLength(Result, 22);
                    Result[00] := Frame;
                    Result[01] := Frame shr 8;
                    Result[02] := NetworkNumber;
                    Result[03] := PCNumber;
                    Result[04] := IONumber; //size of the packet, bHi
                    Result[05] := IONumber shr 8; //size of the packet, bLo
                    Result[06] := ChannelNumber;
                    Result[07] := DataLength;
                    Result[08] := DataLength shr 8;
                    Result[09] := CPUTimer;
                    Result[10] := CPUTimer shr 8;
                    Result[11] := AMainCommand;
                    Result[12] := AMainCommand shr 8;
                    Result[13] := ASubCommand;
                    Result[14] := ASubCommand shr 8;

                    Result[15] := TagObj.address;
                    Result[16] := TagObj.address shr 8;
                    Result[17] := TagObj.address shr 16;
                    Result[18] := PlcDeviceType(TagObj.WriteFunction);
                    Result[19] := $01;
                    Result[20] := Byte($00 shr 8);
                    if Trunc(ToWrite[0]) = 0 then
                      Result[21] := Byte(0)
                    else
                      Result[21] := Byte(16);
                    Result[22] := 0;
                  end;
        $09, $10: begin
                    //PFirstRequestLen := 9;
                    // encode a packet to read input, outputs, register or analog registers
                    // fixed values
                    Frame := 80;
                    NetworkNumber := 0;
                    PCNumber := 255;
                    IONumber := 1023;
                    ChannelNumber := 0;
                    CPUTimer := 16;
                    AMainCommand := 5121;
                    DataLength := 14;
                    ASubCommand := 0;

                    SetLength(Result, 23);
                    Result[00] := Frame;
                    Result[01] := Frame shr 8;
                    Result[02] := NetworkNumber;
                    Result[03] := PCNumber;
                    Result[04] := IONumber; //size of the packet, bHi
                    Result[05] := IONumber shr 8; //size of the packet, bLo
                    Result[06] := ChannelNumber;
                    Result[07] := DataLength;
                    Result[08] := DataLength shr 8;
                    Result[09] := CPUTimer;
                    Result[10] := CPUTimer shr 8;
                    Result[11] := AMainCommand;
                    Result[12] := AMainCommand shr 8;
                    Result[13] := ASubCommand;
                    Result[14] := ASubCommand shr 8;

                    Result[15] := TagObj.address;
                    Result[16] := TagObj.address shr 8;
                    Result[17] := TagObj.address shr 16;
                    Result[18] := PlcDeviceType(TagObj.WriteFunction);
                    Result[19] := $01;
                    Result[20] := $00;
                    Result[21] := Trunc(ToWrite[0]);
                    Result[22] := Trunc(ToWrite[0]) shr 8;
                    Result[23] := 0;
                  end;
        else
          begin
            SetLength(Result, 0);
          end;
      end;
      // Calcula o tamanho do pacote resposta
      // computes the size of the incoming packet.
      case TagObj.WriteFunction of
        $01..$10: ResultLen := 12;
        else
          begin
            ResultLen := 0;
          end;
      end;
    end;
end;

function TMelsecTCPDriver.PlcDeviceType(MemReadWriteFunction: Integer): Integer;
begin
  case MemReadWriteFunction of
    $01: Result := $90; //memory M
    $02: Result := $91; //memory SM
    $03: Result := $92; //memory L
    $04: Result := $93; //memory F
    $05: Result := $94; //memory V
    $06: Result := $9C; //memory X
    $07: Result := $9D; //memory Y
    $08: Result := $A0; //memory B
    //    $09: Result := $A1; //memory SB
    //    $11: Result := $A2; //memory DX
    //    $12: Result := $A3; //memory DY
    $09: Result := $A8; //memory D
    $10: Result := $A9; //memory SD
  end;
end;

function TMelsecTCPDriver.RemainingBytesWrite(Buffer: Bytes): Longint;
begin
  if Buffer[7] = 4 then
    Result := 4
  else
    Result := 3;
  if Buffer[7] = 2 then
    Result := 0;
  if Buffer[2] = 166 then
    Result := 7;
  if Buffer[2] = 208 then
    Result := 6;
end;

function TMelsecTCPDriver.RemainingBytesRead(Buffer: Bytes; TagObj: TTagRec): Longint;
var
  QtTags: Integer;
begin
  if (TagObj.ReadFunction in [1, 2, 3, 4, 5, 6, 7, 8]) then //Bytes
  begin
    Result := 2;
    if Buffer[2] = 208 then
      Result := 4;
    if Buffer[2] = 166 then
      Result := 5;
    if ((Buffer[0] = 0) and (Buffer[1] = 0) and (Buffer[2] = 0)) then
      Result := 6;
    QtTags := TagObj.Size;
    if QtTags <= 2 then
      Result := Result + 1
    else
      begin
        if (QtTags mod 2 <> 0) then
          Result := Result + 1;
        Result := Result + (QtTags div 2);
      end;
  end;
  if (TagObj.ReadFunction in [9, 10, 16]) then //float
  begin
    Result := 3;
    if Buffer[2] = 208 then
      Result := 5;
    if Buffer[2] = 166 then
      Result := 6;
    if Buffer[7] = 2 then
      Result := 0;
    QtTags := TagObj.Size;
    Result := Result + (QtTags * 2) - 1;
  end;
end;

end.

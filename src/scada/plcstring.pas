{$i ../common/language.inc}
{:
  @abstract(Unit that implements a tag that can read/write string values.)
  @author(Fabio Luis Girardi fabio@pascalscada.com)
}
unit PLCString;

interface

uses
  SysUtils, Classes, Tag, TagBlock, ProtocolTypes, ProtocolDriver, Math,
  hsutils;

type
  CP437AnsiString = type AnsiString(437);
  CP646AnsiString = type AnsiString(20127);
  CP850AnsiString = type AnsiString(850);
  CP852AnsiString = type AnsiString(852);
  CP856AnsiString = type AnsiString(856);
  CP866AnsiString = type AnsiString(866);
  CP874AnsiString = type AnsiString(874);
  CP1250AnsiString = type AnsiString(1250);
  CP1251AnsiString = type AnsiString(1251);
  CP1252AnsiString = type AnsiString(1252);
  CP1253AnsiString = type AnsiString(1253);
  CP1254AnsiString = type AnsiString(1254);
  CP1255AnsiString = type AnsiString(1255);
  CP1256AnsiString = type AnsiString(1256);
  CP1257AnsiString = type AnsiString(1257);
  CP1258AnsiString = type AnsiString(1258);
  CP8859_1AnsiString = type AnsiString(28591);
  CP8859_2AnsiString = type AnsiString(28592);
  CP8859_5AnsiString = type AnsiString(28595);

  TStringEncodings = (
    UTF_8,
    CP437,
    CP646,
    CP850,
    CP852,
    CP856,
    CP866,
    CP874,
    CP1250,
    CP1251,
    CP1252,
    CP1253,
    CP1254,
    CP1255,
    CP1256,
    CP1257,
    CP1258,
    CP8859_1,
    CP8859_2,
    CP8859_5);


  {: @author(Fabio Luis Girardi fabio@pascalscada.com)

  Defines the how the string will be encoded/decoded:
  @value(stSIEMENS String on SIEMENS format. The first byte tells the maximum
  size of string and the second byte tells the actual length of the string.)
  @value(stC The string finishes when a ASCII char 0 (string terminator) is found.) }
  TPLCStringTypes = (stSIEMENS, stC, stROCKWELL);

  {: @abstract(Communication tag that can read/write string values on your device.)
     @author(Fabio Luis Girardi fabio@pascalscada.com) }

  { TPLCString }

  TPLCString = class(TTagBlock, IScanableTagInterface, ITagInterface, ITagString)
  private
    FStringEncoding: TStringEncodings;
    PValue: UTF8String;
    PByteSize: Byte;
    PStringType: TPLCStringTypes;
    PStringSize: Cardinal;
    POnAsyncStringValueChange: TASyncStringValueChange;

    procedure SetBlockSize(AValue: Cardinal);
    procedure SetStringEncoding(AValue: TStringEncodings);
    procedure SetStringSize(AValue: Cardinal);
    procedure SetByteSize(AValue: Byte);
    procedure SetStringType(AValue: TPLCStringTypes);
    procedure SetDummySize(AValue: Cardinal);

    function GetValue: UTF8String;
    procedure SetValue(Value: UTF8String);
    function CalcBlockSize(IsWrite: Boolean): Cardinal;
    function ArrayOfValuesToString(Values: TArrayOfDouble): UTF8String;
    function StringToArrayOfValues(Value: UTF8String): TArrayOfDouble;

    function GetValueAsText(Prefix, Sufix, Format: UTF8String; FormatDateTimeOptions: TFormatDateTimeOptions = []): UTF8String;
    function GetVariantValue: Variant;
    procedure SetVariantValue(AValue: Variant);
    function IsValidValue(AValue: Variant): Boolean;
    function GetValueTimestamp: TDatetime;
  protected
    //: @seealso(TTag.AsyncNotifyChange)
    procedure AsyncNotifyChange(Data: Pointer); override;
    //: @seealso(TTag.GetValueChangeData)
    function GetValueChangeData: Pointer; override;
    //: @seealso(TTag.ReleaseChangeData)
    procedure ReleaseChangeData(Data: Pointer); override;
    //: @seealso(TPLCTag.IsMyCallBack)
    function IsMyCallBack(Cback: TTagCommandCallBack): Boolean; override;
    //: @seealso(TPLCTag.SetPLCHack)
    procedure SetPLCHack(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetPLCSlot)
    procedure SetPLCSlot(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetPLCStation)
    procedure SetPLCStation(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetMemFileDB)
    procedure SetMemFileDB(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetMemAddress)
    procedure SetMemAddress(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetMemSubElement)
    procedure SetMemSubElement(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetMemReadFunction)
    procedure SetMemReadFunction(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetMemWriteFunction)
    procedure SetMemWriteFunction(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetPath)
    procedure SetPath(AValue: AnsiString); override;
    //: @seealso(TPLCTag.SetProtocolDriver)
    procedure SetProtocolDriver(AValue: TProtocolDriver); override;
    //: @seealso(TPLCTag.TagCommandCallBack)
    procedure TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDatetime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint); override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    class function ConvertRawByteStringToUTF8(AInput: Rawbytestring; AInputEncoding: TStringEncodings): UTF8String;
    class function ConvertUTF8CharToByte(AInput: UTF8String; AInputEncoding: TStringEncodings; APos: Integer): Byte;

    //: Read/writes a string value on your device
    property Value: UTF8String read PValue write SetValue;

    //: @seealso(TTagBlock.Read)
    procedure Read; override;
    {: @name writes asynchronously the values stored in the block.
       @bold(Only works if AutoWrite = @false.) }
    procedure WriteByScan;
    {: @name writes synchronously the values stored in the block.
       @bold(Only works if AutoWrite = @false.) }
    procedure WriteDirect;
  published
    //: Maximum length of your string.
    property StringSize: Cardinal read PStringSize write SetStringSize;
    {: String format.
       @seealso(TPLCStringTypes)}
    property StringType: TPLCStringTypes read PStringType write SetStringType default stC;
    //: Size in bits of each character of string.
    property ByteSize: Byte read PByteSize write SetByteSize default 8; deprecated;

    //: @seealso(TTag.OnValueChange)
    property OnValueChange stored False;
    //: @seealso(TTag.OnValueChangeFirst)
    property OnValueChangeFirst;
    //: @seealso(TTag.OnValueChangeLast)
    property OnValueChangeLast;
    //: Asynchronous event called when the tag value changes.
    property OnAsyncStringChange: TASyncStringValueChange read POnAsyncStringValueChange write POnAsyncStringValueChange;

    //: Real block size (read-only).
    property Size write SetDummySize;
    //: @seealso(TPLCTag.SyncWrites)
    property SyncWrites;

    property StringEncoding: TStringEncodings read FStringEncoding write SetStringEncoding default UTF_8;
  end;


implementation


uses
  variants,
  hsstrings
{$IFDEF FPC}
  , LazUTF8
{$ENDIF}
  ;

constructor TPLCString.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PStringSize := 10;
  PByteSize := 8;
  PStringType := stC;
  SetBlockSize(11);
end;

destructor TPLCString.Destroy;
begin
  inherited Destroy;
  SetLength(PValues, 0);
end;

procedure TPLCString.Read;
begin
  inherited Read;
end;

procedure TPLCString.WriteByScan;
var
  x: Boolean;
  Values: TArrayOfDouble;
begin
  x := PAutoWrite;
  PAutoWrite := True;
  Values := StringToArrayOfValues(PValue);
  ScanWrite(Values, PSize, 0);
  PAutoWrite := x;
  SetLength(Values, 0);
end;

procedure TPLCString.WriteDirect;
var
  Values: TArrayOfDouble;
begin
  Values := StringToArrayOfValues(PValue);
  Write(Values, PSize, 0);
  SetLength(Values, 0);
end;

class function TPLCString.ConvertRawByteStringToUTF8(AInput: Rawbytestring; AInputEncoding: TStringEncodings): UTF8String;
var
  CP437Str: CP437AnsiString;
  CP646Str: CP646AnsiString;
  CP850Str: CP850AnsiString;
  CP852Str: CP852AnsiString;
  CP856Str: CP856AnsiString;
  CP866Str: CP866AnsiString;
  CP874Str: CP874AnsiString;
  CP1250Str: CP1250AnsiString;
  CP1251Str: CP1251AnsiString;
  CP1252Str: CP1252AnsiString;
  CP1253Str: CP1253AnsiString;
  CP1254Str: CP1254AnsiString;
  CP1255Str: CP1255AnsiString;
  CP1256Str: CP1256AnsiString;
  CP1257Str: CP1257AnsiString;
  CP1258Str: CP1258AnsiString;
  CP8859_1Str: CP8859_1AnsiString;
  CP8859_2Str: CP8859_2AnsiString;
  CP8859_5Str: CP8859_5AnsiString;
  i: Integer;
begin
  case AInputEncoding of
    UTF_8:  begin
              Result := AInput;
            end;
    CP437:  begin
              CP437Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP437Str := CP437Str + AInput[i];
              end;
              Result := CP437Str;
            end;
    CP646:  begin
              CP646Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP646Str := CP646Str + AInput[i];
              end;
              Result := CP646Str;
            end;
    CP850:  begin
              CP850Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP850Str := CP850Str + AInput[i];
              end;
              Result := CP850Str;
            end;
    CP852:  begin
              CP852Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP852Str := CP852Str + AInput[i];
              end;
              Result := CP852Str;
            end;
    CP856:  begin
              CP856Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP856Str := CP856Str + AInput[i];
              end;
              Result := CP856Str;
            end;
    CP866:  begin
              CP866Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP866Str := CP866Str + AInput[i];
              end;
              Result := CP866Str;
            end;
    CP874:  begin
              CP874Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP874Str := CP874Str + AInput[i];
              end;
              Result := CP874Str;
            end;
    CP1250: begin
              CP1250Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1250Str := CP1250Str + AInput[i];
              end;
              Result := CP1250Str;
            end;
    CP1251: begin
              CP1251Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1251Str := CP1251Str + AInput[i];
              end;
              Result := CP1251Str;
            end;
    CP1252: begin
              CP1252Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1252Str := CP1252Str + AInput[i];
              end;
              Result := CP1252Str;
            end;
    CP1253: begin
              CP1253Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1253Str := CP1253Str + AInput[i];
              end;
              Result := CP1253Str;
            end;
    CP1254: begin
              CP1254Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1254Str := CP1254Str + AInput[i];
              end;
              Result := CP1254Str;
            end;
    CP1255: begin
              CP1255Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1255Str := CP1255Str + AInput[i];
              end;
              Result := CP1255Str;
            end;
    CP1256: begin
              CP1256Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1256Str := CP1256Str + AInput[i];
              end;
              Result := CP1256Str;
            end;
    CP1257: begin
              CP1257Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1257Str := CP1257Str + AInput[i];
              end;
              Result := CP1257Str;
            end;
    CP1258: begin
              CP1258Str := '';
              for i := 1 to Length(AInput) do
              begin
                CP1258Str := CP1258Str + AInput[i];
              end;
              Result := CP1258Str;
            end;
    CP8859_1: begin
                CP8859_1Str := '';
                for i := 1 to Length(AInput) do
                begin
                  CP8859_1Str := CP8859_1Str + AInput[i];
                end;
                Result := CP8859_1Str;
              end;
    CP8859_2: begin
                CP8859_2Str := '';
                for i := 1 to Length(AInput) do
                begin
                  CP8859_2Str := CP8859_2Str + AInput[i];
                end;
                Result := CP8859_2Str;
              end;
    CP8859_5: begin
                CP8859_5Str := '';
                for i := 1 to Length(AInput) do
                begin
                  CP8859_5Str := CP8859_5Str + AInput[i];
                end;
                Result := CP8859_5Str;
              end;
  end;
end;

class function TPLCString.ConvertUTF8CharToByte(AInput: UTF8String; AInputEncoding: TStringEncodings; APos: Integer): Byte;
var
  CP437Str: CP437AnsiString;
  CP646Str: CP646AnsiString;
  CP850Str: CP850AnsiString;
  CP852Str: CP852AnsiString;
  CP856Str: CP856AnsiString;
  CP866Str: CP866AnsiString;
  CP874Str: CP874AnsiString;
  CP1250Str: CP1250AnsiString;
  CP1251Str: CP1251AnsiString;
  CP1252Str: CP1252AnsiString;
  CP1253Str: CP1253AnsiString;
  CP1254Str: CP1254AnsiString;
  CP1255Str: CP1255AnsiString;
  CP1256Str: CP1256AnsiString;
  CP1257Str: CP1257AnsiString;
  CP1258Str: CP1258AnsiString;
  CP8859_1Str: CP8859_1AnsiString;
  CP8859_2Str: CP8859_2AnsiString;
  CP8859_5Str: CP8859_5AnsiString;
begin
  case AInputEncoding of
    UTF_8:  begin
              Result := Byte(AInput[APos]);
            end;
    CP437:  begin
              CP437Str := AInput;
              Result := Byte(CP437Str[APos]);
            end;
    CP646:  begin
              CP646Str := AInput;
              Result := Byte(CP646Str[APos]);
            end;
    CP850:  begin
              CP850Str := AInput;
              Result := Byte(CP850Str[APos]);
            end;
    CP852:  begin
              CP852Str := AInput;
              Result := Byte(CP852Str[APos]);
            end;
    CP856:  begin
              CP856Str := AInput;
              Result := Byte(CP856Str[APos]);
            end;
    CP866:  begin
              CP866Str := AInput;
              Result := Byte(CP866Str[APos]);
            end;
    CP874:  begin
              CP874Str := AInput;
              Result := Byte(CP874Str[APos]);
            end;
    CP1250: begin
              CP1250Str := AInput;
              Result := Byte(CP1250Str[APos]);
            end;
    CP1251: begin
              CP1251Str := AInput;
              Result := Byte(CP1251Str[APos]);
            end;
    CP1252: begin
              CP1252Str := AInput;
              Result := Byte(CP1252Str[APos]);
            end;
    CP1253: begin
              CP1253Str := AInput;
              Result := Byte(CP1253Str[APos]);
            end;
    CP1254: begin
              CP1254Str := AInput;
              Result := Byte(CP1254Str[APos]);
            end;
    CP1255: begin
              CP1255Str := AInput;
              Result := Byte(CP1255Str[APos]);
            end;
    CP1256: begin
              CP1256Str := AInput;
              Result := Byte(CP1256Str[APos]);
            end;
    CP1257: begin
              CP1257Str := AInput;
              Result := Byte(CP1257Str[APos]);
            end;
    CP1258: begin
              CP1258Str := AInput;
              Result := Byte(CP1258Str[APos]);
            end;
    CP8859_1: begin
                CP8859_1Str := AInput;
                Result := Byte(CP8859_1Str[APos]);
              end;
    CP8859_2: begin
                CP8859_2Str := AInput;
                Result := Byte(CP8859_2Str[APos]);
              end;
    CP8859_5: begin
                CP8859_5Str := AInput;
                Result := Byte(CP8859_5Str[APos]);
              end;
  end;
end;

//codifica uma array de valores em uma string

//encodes a string from a array of double.
function TPLCString.ArrayOfValuesToString(Values: TArrayOfDouble): UTF8String;
var
  Aux1: Longint;
  MaxBits: Longint;
  Bit: Longint;
  ValueAux2: Longint;
  ValueP: Longint;
  ByteP: Longint;
  ValueBitP: Longint;
  ByteBitP: Longint;
  ValueAux: Byte;
  StrLen: Byte;
  BitsByType: Byte;
  AResult: Rawbytestring;
begin
  // what's the current register size in bits
  if PProtocolDriver <> nil then
    BitsByType := Min(PProtocolDriver.SizeOfTag(Self, False, FProtocolTagType), 64)
  else
    BitsByType := 8;

  Result := '';

  if Length(Values) <= 0 then
  begin
    Exit;
  end;

  AResult := '';

  case PStringType of
    stSIEMENS:  begin // decodes a siemens string
                  MaxBits := Length(Values) * BitsByType;
                  Bit := 0;
                  ByteP := 0;
                  ByteBitP := 0;
                  ValueP := 0;
                  ValueBitP := 0;
                  ValueAux := 0;
                  StrLen := 255;
                  ValueAux2 := Trunc(Values[ValueP]);
                  //passa Bit a Bit para montar a string
                  //build the string, Bit by Bit
                  try
                    while Bit < MaxBits do
                    begin
                      Aux1 := Power(2, ValueBitP);
                      if ((ValueAux2 and Aux1) = Aux1) then
                        ValueAux := ValueAux + Power(2, ByteBitP);

                      Inc(Bit);
                      Inc(ByteBitP);
                      Inc(ValueBitP);

                      //incrementa os ponteiros
                      //increment pointers
                      if ByteBitP >= PByteSize then
                      begin
                        //se esta nos primeiros 2 bytes
                        //acha o tamanho real da string
                        //(o menor dos dois primeiros bytes)

                        //if looking at the first two bytes
                        //gets the real size of the string
                        if ByteP < 2 then
                        begin
                          StrLen := Min(StrLen, ValueAux);
                        end
                        else
                        begin
                          AResult := AResult + Char(ValueAux);
                          //se alcançou o tamanho da string.
                          //if all string is decoded, finish.
                          if Length(AResult) >= StrLen then
                            Exit;
                        end;
                        Inc(ByteP);
                        ByteBitP := 0;
                        ValueAux := 0;
                      end;
                      if ValueBitP >= BitsByType then
                      begin
                        ValueBitP := 0;
                        Inc(ValueP);
                        if ValueP > High(Values) then Exit;
                        ValueAux2 := Trunc(Values[ValueP]);
                      end;
                    end;
                    if ByteBitP <= PByteSize then
                      AResult := AResult + Char(ValueAux);
                  finally
                    Result := ConvertRawByteStringToUTF8(AResult, FStringEncoding);
                  end;
                end;
    stC:  begin // C string, 7 or 8 bits per character
            MaxBits := Length(Values) * BitsByType;
            Bit := 0;
            //ByteP := 1;
            ByteBitP := 0;
            ValueP := 0;
            ValueBitP := 0;
            ValueAux := 0;
            ValueAux2 := Trunc(Values[ValueP]);
            // build the string, Bit by Bit
            try
              while Bit < MaxBits do
              begin
                Aux1 := Power(2, ValueBitP);
                if ((ValueAux2 and Aux1) = Aux1) then
                  ValueAux := ValueAux + Power(2, ByteBitP);

                Inc(Bit);
                Inc(ByteBitP);
                Inc(ValueBitP);

                // increment the pointers
                if ByteBitP >= PByteSize then
                begin
                  // if found the terminator, finish the string
                  if ValueAux = 0 then
                    Exit
                  else
                    AResult := AResult + Char(ValueAux);
                  //inc(ByteP);
                  ByteBitP := 0;
                  ValueAux := 0;
                end;
                if ValueBitP >= BitsByType then
                begin
                  ValueBitP := 0;
                  Inc(ValueP);
                  if ValueP > High(Values) then Exit;
                  ValueAux2 := Trunc(Values[ValueP]);
                end;
              end;
              if ByteBitP <= PByteSize then
              begin
                AResult := AResult + Char(ValueAux);
              end;
            finally
              Result := ConvertRawByteStringToUTF8(AResult, FStringEncoding);
            end;
          end;
    else
      Result := ''; // unknown string type
  end;
end;

function TPLCString.StringToArrayOfValues(Value: UTF8String): TArrayOfDouble;
//encodes a string to a array of double.
var
  ValueAux: Longint;
  Aux1: Longint;
  MaxBits: Longint;
  Bit: Longint;
  Bs: Longint;
  ValueP: Longint;
  ByteP: Longint;
  ValueBitP: Longint;
  ByteBitP: Longint;
  MaxLen: Byte;
  StrLen: Byte;
  BitsByType: Byte;
begin
  if PProtocolDriver <> nil then
    BitsByType := Min(PProtocolDriver.SizeOfTag(Self, True, FProtocolTagType), 32)
  else
    BitsByType := 8;

  //use the writefunction to determine the block size.
  Bs := CalcBlockSize(True);
  SetLength(Result, Bs);

  case PStringType of
    stSIEMENS:  begin // encodes a SIEMENS string, 7 or 8 bits of length
                  MaxLen := Min(PStringSize, Power(2, PByteSize) - 1);
                  StrLen := Min(MaxLen, IfThen(FStringEncoding = UTF_8, Length(Value), UTF8Length(Value)));
                  MaxBits := PByteSize * (StrLen + 2);
                  Bit := 0;
                  ByteBitP := 0;
                  ByteP := 1;
                  ValueBitP := 0;
                  ValueP := 0;
                  ValueAux := 0;

                  while Bit < MaxBits do
                  begin
                    //processa os dois primeiros bytes do formato siemens
                    //que dizem o tamanho da string;

                    //stores in the first two bytes, the length of string.
                    if Bit < (2 * PByteSize) then
                    begin
                      Aux1 := Power(2, ByteBitP);
                      if Bit < PByteSize then
                      begin
                        if (MaxLen and Aux1) = Aux1 then
                          ValueAux := ValueAux + Power(2, ValueBitP);
                      end
                      else
                      begin
                        if (StrLen and Aux1) = Aux1 then
                          ValueAux := ValueAux + Power(2, ValueBitP);
                      end;
                    end
                    else
                    begin
                      if Bit = (2 * PByteSize) then
                      begin
                        ByteBitP := 0;
                        ByteP := 1;
                      end;
                      //processa os bytes da string
                      //processes the bytes of string.
                      Aux1 := Power(2, ByteBitP);
                      if (ConvertUTF8CharToByte(Value, FStringEncoding, ByteP) and Aux1) = Aux1 then
                      begin
                        ValueAux := ValueAux + Power(2, ValueBitP);
                      end;
                    end;

                    Inc(Bit);
                    Inc(ByteBitP);
                    Inc(ValueBitP);

                    //increment the pointes.
                    if ByteBitP >= PByteSize then
                    begin
                      Inc(ByteP);
                      ByteBitP := 0;
                    end;
                    if ValueBitP >= BitsByType then
                    begin
                      Result[ValueP] := ValueAux;
                      ValueAux := 0;
                      ValueBitP := 0;
                      Inc(ValueP);
                    end;
                  end;
                  if (ValueP < Bs) and (ValueBitP < BitsByType) then
                  begin
                    Result[ValueP] := ValueAux;
                  end;
                end;
    stC:  begin // C string format, 7 or 8 bits
            StrLen := Min(Length(Value), Power(2, PByteSize) - 1);
            MaxBits := PByteSize * (StrLen);
            Bit := 0;
            ByteBitP := 0;
            ByteP := 1;
            ValueBitP := 0;
            ValueP := 0;
            ValueAux := 0;
            while Bit < MaxBits do
            begin
              // processes the bytes of string
              Aux1 := Power(2, ByteBitP);
              if (ConvertUTF8CharToByte(Value, FStringEncoding, ByteP) and Aux1) = Aux1 then
                ValueAux := ValueAux + Power(2, ValueBitP);

              Inc(Bit);
              Inc(ByteBitP);
              Inc(ValueBitP);

              // increment the pointers
              if ByteBitP >= PByteSize then
              begin
                Inc(ByteP);
                ByteBitP := 0;
              end;
              if ValueBitP >= BitsByType then
              begin
                Result[ValueP] := ValueAux;
                ValueAux := 0;
                ValueBitP := 0;
                Inc(ValueP);
              end;
            end;
            if (ValueP < Bs) and (ValueBitP < BitsByType) then
            begin
              Result[ValueP] := ValueAux;
            end;
          end;
  end;

end;

function TPLCString.GetValueAsText(Prefix, Sufix, Format: UTF8String; FormatDateTimeOptions: TFormatDateTimeOptions = []): UTF8String;
begin
  Result := Prefix + Value + Sufix;
end;

function TPLCString.IsMyCallBack(Cback: TTagCommandCallBack): Boolean;
begin
  Result := inherited IsMyCallBack(Cback) and (TMethod(Cback).Code = Pointer(@TPLCString.TagCommandCallBack));
end;

procedure TPLCString.SetPLCHack(AValue: Cardinal);
begin
  inherited SetPLCHack(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetPLCSlot(AValue: Cardinal);
begin
  inherited SetPLCSlot(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetPLCStation(AValue: Cardinal);
begin
  inherited SetPLCStation(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetMemFileDB(AValue: Cardinal);
begin
  inherited SetMemFileDB(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetMemAddress(AValue: Cardinal);
begin
  inherited SetMemAddress(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetMemSubElement(AValue: Cardinal);
begin
  inherited SetMemSubElement(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetMemReadFunction(AValue: Cardinal);
begin
  inherited SetMemReadFunction(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetMemWriteFunction(AValue: Cardinal);
begin
  inherited SetMemWriteFunction(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetPath(AValue: AnsiString);
begin
  inherited SetPath(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetProtocolDriver(AValue: TProtocolDriver);
begin
  inherited SetProtocolDriver(AValue);
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDatetime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint);
var
  i: Longint;
  Notify: Boolean;
begin
  if (csDestroying in ComponentState) then Exit;
  try
    Notify := False;
    case TagCommand of
      tcScanRead,
      tcRead,
      tcInternalUpdate: begin
                          if LastResult in [ioOk, ioNullDriver] then
                          begin
                            for i := 0 to Length(Values) - 1 do
                            begin
                              Notify := Notify or (PValues[i + Offset] <> Values[i]);
                              PValues[i + Offset] := Values[i];
                            end;
                            PValueTimeStamp := ValuesTimeStamp;
                            if (TagCommand <> tcInternalUpdate) and (LastResult = ioOk) then
                              IncCommReadOK(1);
                          end
                          else
                          begin
                            if (TagCommand <> tcInternalUpdate) then
                            begin
                              IncCommReadFaults(1);
                            end;
                          end;
                        end;
      tcScanWrite,
      tcWrite:  begin
                  if LastResult in [ioOk, ioNullDriver] then
                  begin
                    if LastResult = ioOk then
                      IncCommWriteOK(1);
                    for i := 0 to Length(Values) - 1 do
                    begin
                      Notify := Notify or (PValues[i + Offset] <> Values[i]);
                      PValues[i + Offset] := Values[i];
                    end;
                  end
                  else
                    IncCommWriteFaults(1);
                end;
    end;

    case TagCommand of
      tcScanRead:  PLastASyncReadCmdResult := LastResult;
      tcScanWrite: PLastASyncWriteCmdResult := LastResult;
      tcRead:      PLastSyncReadCmdResult := LastResult;
      tcWrite:     PLastSyncWriteCmdResult := LastResult;
    end;

    if Notify or PFirstUpdate then
    begin
      if TagCommand in [tcRead, tcScanRead] then
        PFirstUpdate := False;
      PValue := ArrayOfValuesToString(PValues);
      NotifyChange;
    end;
  finally
  end;
end;

procedure TPLCString.SetBlockSize(AValue: Cardinal);
begin
  if Size > 0 then
  begin
    PSize := AValue;
    SetLength(PValues, PSize);
    if PProtocolDriver <> nil then
    begin
      if PAutoRead then
      begin
        PProtocolDriver.RemoveTag(Self);
        PProtocolDriver.AddTag(Self);
      end;
    end;
  end;
end;

procedure TPLCString.SetStringEncoding(AValue: TStringEncodings);
begin
  if FStringEncoding = AValue then Exit;
  FStringEncoding := AValue;
end;

procedure TPLCString.SetStringSize(AValue: Cardinal);
begin
  if (PByteSize = 8) and (Size > 255) or ((PByteSize = 7) and (AValue > 127)) or ((PStringType = stROCKWELL) and (AValue > 84)) then
    raise Exception.Create(SstringSizeOutOfBounds);
  PStringSize := AValue;
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetByteSize(AValue: Byte);
begin
  if (AValue < 7) or (AValue > 8) then
    raise Exception.Create(SsizeMustBe7or8);

  if (AValue = 7) and (PStringSize > 127) then
    PStringSize := 127;
  if (AValue = 8) and (PStringSize > 255) then
    PStringSize := 255;

  PByteSize := AValue;
  SetBlockSize(CalcBlockSize(False));
end;

procedure TPLCString.SetStringType(AValue: TPLCStringTypes);
begin
  if AValue = PStringType then Exit;
  PStringType := AValue;
  SetBlockSize(CalcBlockSize(False));
  PValue := ArrayOfValuesToString(PValues);
end;

procedure TPLCString.SetDummySize(AValue: Cardinal);
begin

end;

function TPLCString.GetValue: UTF8String;
begin
  Result := PValue;
end;

procedure TPLCString.SetValue(Value: UTF8String);
var
  x: TArrayOfDouble;
begin
  x := StringToArrayOfValues(Value);
  try
    if FSyncWrites then
      Write(x, Length(x), 0)
    else
      ScanWrite(x, Length(x), 0);
  finally
    SetLength(x, 0);
  end;
end;

function TPLCString.CalcBlockSize(IsWrite: Boolean): Cardinal;
var
  BitsByType: Byte;
  strLen: Longint;
begin
  if PProtocolDriver <> nil then
  begin
    BitsByType := PProtocolDriver.SizeOfTag(Self, IsWrite, FProtocolTagType);
    BitsByType := IfThen(BitsByType = 0, 1, BitsByType);
  end
  else
    BitsByType := 8;

  //calcula o tamanho da string conforme o tipo
  //calculate the string size depending of the format.
  case PStringType of
    stSIEMENS: strLen := (PStringSize + 2) * PByteSize;
    stC: strLen := (PStringSize + 1) * PByteSize;
    else
      strLen := 1;
  end;

  Result := strLen div BitsByType + IfThen((strLen mod BitsByType) = 0, 0, 1);
end;

function TPLCString.GetVariantValue: Variant;
begin
  Result := Value;
end;

procedure TPLCString.SetVariantValue(AValue: Variant);
begin
  Value := AValue;
end;

function TPLCString.IsValidValue(AValue: Variant): Boolean;
begin
  Result := VarIsNumeric(AValue) or VarIsStr(AValue) or
    VarIsType(AValue, vardate) or VarIsType(AValue, varboolean);
end;

function TPLCString.GetValueTimestamp: TDatetime;
begin
  Result := PValueTimeStamp;
end;

procedure TPLCString.AsyncNotifyChange(Data: Pointer);
var
  x: PString;
begin
  if Assigned(POnAsyncStringValueChange) then
  begin
    x := Data;
    POnAsyncStringValueChange(Self, x^);
  end;
end;

function TPLCString.GetValueChangeData: Pointer;
var
  x: PString;
begin
  New(x);
  x^ := Value;
  Result := x;
end;

procedure TPLCString.ReleaseChangeData(Data: Pointer);
var
  x: PString;
begin
  x := Data;
  SetLength(x^, 0);
  Dispose(x);
end;

end.

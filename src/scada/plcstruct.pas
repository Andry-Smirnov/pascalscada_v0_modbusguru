{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit that implements a structure communication tag.)

  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Moved OpenElementMapper to StructTagAssistant to remove form dependencies
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  10/2014 - Switched back to the old behavior but keeping the improvemnt
  of Juanjo (do not link with GUI);
  ***********************************************************************
}
unit PLCStruct;

interface

uses
  Classes, PLCBlock, Tag, ProtocolTypes;

type
  {: @author(Fabio Luis Girardi <fabio@pascalscada.com>)
     @abstract(Class of an structure communication tag.) }

  { TPLCStruct }

  TPLCStruct = class(TPLCBlock)
  protected
    //: @seealso(TPLCTag.IsMyCallBack)
    function IsMyCallBack(CallBack: TTagCommandCallBack): Boolean; override;
    //: @seealso(TPLCTag.TagCommandCallBack)
    procedure TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDateTime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint); override;
    //: @seealso(TPLCTag.SetTagType)
    procedure SetTagType(AValue: TTagType); override;
    //: @seealso(TPLCTag.SwapDWords)
    procedure SetSwapDWords(AValue: Boolean); override;
    //: @seealso(TPLCTag.SetSwapWords)
    procedure SetSwapWords(AValue: Boolean); override;
    //: @seealso(TPLCTag.SetSwapBytes)
    procedure SetSwapBytes(AValue: Boolean); override;
  public
    //: @xclude
    constructor Create(AOwner: TComponent); override;

    //: @seealso(TPLCBlock.MapElements)
    procedure MapElements(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); override;

    class procedure AddByte(AArray: TArrayOfDouble; Offset: Integer; AByte: Byte);
    class procedure AddDWord(AArray: TArrayOfDouble; Offset: Integer; ADWord: Longint; ASwapBytes, ASwapWords: Boolean);
    class procedure AddDWord(AArray: TArrayOfDouble; Offset: Integer; ADWord: DWord; ASwapBytes, ASwapWords: Boolean);
    class procedure AddDWord(AArray: TArrayOfDouble; Offset: Integer; ADWord: Single; ASwapBytes, ASwapWords: Boolean);
    class procedure AddQWord(AArray: TArrayOfDouble; Offset: Integer; AQWord: QWord; ASwapBytes, ASwapWords, ASwapDWords: Boolean);
    class procedure AddQWord(AArray: TArrayOfDouble; Offset: Integer; AQWord: Int64; ASwapBytes, ASwapWords, ASwapDWords: Boolean);
    class procedure AddQWord(AArray: TArrayOfDouble; Offset: Integer; AQWord: Double; ASwapBytes, ASwapWords, ASwapDWords: Boolean);
    class procedure AddWord(AArray: TArrayOfDouble; Offset: Integer; AWord: Word; ASwapBytes: Boolean);
    class procedure AddWord(AArray: TArrayOfDouble; Offset: Integer; AWord: Smallint; ASwapBytes: Boolean);

    class procedure AddCString(var AArray: TArrayOfDouble; Offset: Integer; AString: AnsiString);
    class procedure AddSiemensString(var AArray: TArrayOfDouble; Offset: Integer; AString: AnsiString; MaxSize: Byte);

    function GetByte(Offset: Integer): Byte;
    function GetWord(Offset: Integer; ASwapBytes: Boolean): Word;
    function GetSmallInt(Offset: Integer; ASwapBytes: Boolean): Smallint;
    function GetLongWord(Offset: Integer; ASwapBytes, ASwapWords: Boolean): Longword;
    function GetLongInt(Offset: Integer; ASwapBytes, ASwapWords: Boolean): Longint;
    function GetSingle(Offset: Integer; ASwapBytes, ASwapWords: Boolean): Single;

    function GetQWord(Offset: Integer; ASwapBytes, ASwapWords, ASwapDWords: Boolean): QWord;
    function GetInt64(Offset: Integer; ASwapBytes, ASwapWords, ASwapDWords: Boolean): Int64;
    function GetDouble(Offset: Integer; ASwapBytes, ASwapWords, ASwapDWords: Boolean): Double;

    function GetSiemensString(Offset: Integer; MaxStringSize: Integer = 255): string;

  end;


procedure SetStructItemMapper(StructItemMapperTool: TOpenTagEditor);


implementation


uses
  SysUtils, Math, hsstrings;


constructor TPLCStruct.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  inherited SetTagType(pttByte);
end;

function TPLCStruct.IsMyCallBack(CallBack: TTagCommandCallBack): Boolean;
begin
  Result := inherited IsMyCallBack(CallBack) and (TMethod(CallBack).Code = Pointer(@TPLCStruct.TagCommandCallBack));
end;

procedure TPLCStruct.TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDateTime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint);
begin
  inherited TagCommandCallBack(ReqID, Values, ValuesTimeStamp, TagCommand, LastResult, Offset);
end;

procedure TPLCStruct.SetTagType(AValue: TTagType);
begin
  inherited SetTagType(pttByte);
end;

procedure TPLCStruct.SetSwapDWords(AValue: Boolean);
begin
  inherited SetSwapDWords(False);
end;

procedure TPLCStruct.SetSwapWords(AValue: Boolean);
begin
  inherited SetSwapWords(False);
end;

procedure TPLCStruct.SetSwapBytes(AValue: Boolean);
begin
  inherited SetSwapBytes(False);
end;

class procedure TPLCStruct.AddByte(AArray: TArrayOfDouble; Offset: Integer; AByte: Byte);
begin
  if Offset < Length(AArray) then
    AArray[Offset] := AByte;
end;

class procedure TPLCStruct.AddWord(AArray: TArrayOfDouble; Offset: Integer; AWord: Word; ASwapBytes: Boolean);
var
  AInvertWordBytes: array [0..1] of Byte absolute AWord;
  Aux: Byte;
begin
  if ASwapBytes then
  begin
    Aux := AInvertWordBytes[0];
    AInvertWordBytes[0] := AInvertWordBytes[1];
    AInvertWordBytes[1] := Aux;
  end;

  AddByte(AArray, Offset + 0, AInvertWordBytes[0]);
  AddByte(AArray, Offset + 1, AInvertWordBytes[1]);
end;

class procedure TPLCStruct.AddWord(AArray: TArrayOfDouble; Offset: Integer; AWord: Smallint; ASwapBytes: Boolean);
begin
  AddWord(AArray, Offset, Word(AWord), ASwapBytes);
end;

class procedure TPLCStruct.AddDWord(AArray: TArrayOfDouble; Offset: Integer; ADWord: DWord; ASwapBytes, ASwapWords: Boolean);
var
  InvertedWordsOfDword: array [0..1] of Word absolute ADWord;
  Aux: Word;
begin
  if ASwapWords then
  begin
    Aux := InvertedWordsOfDword[0];
    InvertedWordsOfDword[0] := InvertedWordsOfDword[1];
    InvertedWordsOfDword[1] := Aux;
  end;

  AddWord(AArray, Offset + 0, InvertedWordsOfDword[0], ASwapBytes);
  AddWord(AArray, Offset + 2, InvertedWordsOfDword[1], ASwapBytes);
end;

class procedure TPLCStruct.AddDWord(AArray: TArrayOfDouble; Offset: Integer; ADWord: Longint; ASwapBytes, ASwapWords: Boolean);
begin
  AddDWord(AArray, Offset, DWord(ADWord), ASwapBytes, ASwapWords);
end;

class procedure TPLCStruct.AddDWord(AArray: TArrayOfDouble; Offset: Integer; ADWord: Single; ASwapBytes, ASwapWords: Boolean);
var
  AsDWord: DWord absolute ADWord;
begin
  AddDWord(AArray, Offset, AsDWord, ASwapBytes, ASwapWords);
end;

class procedure TPLCStruct.AddQWord(AArray: TArrayOfDouble; Offset: Integer; AQWord: QWord; ASwapBytes, ASwapWords, ASwapDWords: Boolean);
var
  InvertedWordsOfDword: array [0..1] of DWord absolute AQWord;
  Aux: DWord;
begin
  if ASwapDWords then
  begin
    Aux := InvertedWordsOfDword[0];
    InvertedWordsOfDword[0] := InvertedWordsOfDword[1];
    InvertedWordsOfDword[1] := Aux;
  end;
  AddDWord(AArray, Offset + 0, InvertedWordsOfDword[0], ASwapBytes, ASwapWords);
  AddDWord(AArray, Offset + 4, InvertedWordsOfDword[1], ASwapBytes, ASwapWords);
end;

class procedure TPLCStruct.AddQWord(AArray: TArrayOfDouble; Offset: Integer; AQWord: Int64; ASwapBytes, ASwapWords, ASwapDWords: Boolean);
begin
  AddQWord(AArray, Offset, QWord(AQWord), ASwapBytes, ASwapWords, ASwapDWords);
end;

class procedure TPLCStruct.AddQWord(AArray: TArrayOfDouble; Offset: Integer; AQWord: Double; ASwapBytes, ASwapWords, ASwapDWords: Boolean);
var
  AsQWord: QWord absolute AQWord;
begin
  AddQWord(AArray, Offset, AsQWord, ASwapBytes, ASwapWords, ASwapDWords);
end;

class procedure TPLCStruct.AddCString(var AArray: TArrayOfDouble; Offset: Integer; AString: AnsiString);
var
  i: Integer;
begin
  for i := 1 to Length(AString) do
    AddByte(AArray, Offset + (i - 1), Byte(AString[i]));
  AddByte(AArray, Length(AString), 0);
end;

class procedure TPLCStruct.AddSiemensString(var AArray: TArrayOfDouble; Offset: Integer; AString: AnsiString; MaxSize: Byte);
var
  ASize: Byte;
  i: Integer;
begin
  ASize := Min(MaxSize, Length(AString));

  AddByte(AArray, Offset + 0, MaxSize);
  AddByte(AArray, Offset + 1, ASize);

  for i := 1 to ASize do
    AddByte(AArray, Offset + (i + 1), Byte(AString[i]));
end;

function TPLCStruct.GetByte(Offset: Integer): Byte;
begin
  if ((Offset < 0) or (Offset > High(PValues))) then
    raise Exception.Create(SoutOfBounds);
  Result := trunc(PValues[Offset]);
end;

function TPLCStruct.GetWord(Offset: Integer; ASwapBytes: Boolean): Word;
var
  AResult: Word;
  ABytes: array [0..1] of Byte absolute AResult;
begin
  if ((Offset < 0) or ((Offset + 1) > High(PValues))) then
    raise Exception.Create(SoutOfBounds);

  if ASwapBytes then
  begin
    ABytes[0] := GetByte(Offset + 1);
    ABytes[1] := GetByte(Offset + 0);
  end
  else
  begin
    ABytes[0] := GetByte(Offset + 0);
    ABytes[1] := GetByte(Offset + 1);
  end;

  Result := AResult;
end;

function TPLCStruct.GetSmallInt(Offset: Integer; ASwapBytes: Boolean): Smallint;
begin
  Result := Smallint(GetWord(Offset, ASwapBytes));
end;

function TPLCStruct.GetLongWord(Offset: Integer; ASwapBytes, ASwapWords: Boolean): Longword;
var
  AResult: Longword;
  AWords: array [0..1] of Word absolute AResult;
begin
  if ((Offset < 0) or ((Offset + 3) > High(PValues))) then
    raise Exception.Create(SoutOfBounds);

  if ASwapWords then
  begin
    AWords[0] := GetWord(Offset + 2, ASwapBytes);
    AWords[1] := GetWord(Offset + 0, ASwapBytes);
  end
  else
  begin
    AWords[0] := GetWord(Offset + 0, ASwapBytes);
    AWords[1] := GetWord(Offset + 2, ASwapBytes);
  end;

  Result := AResult;
end;

function TPLCStruct.GetLongInt(Offset: Integer; ASwapBytes, ASwapWords: Boolean): Longint;
begin
  Result := Longint(GetLongWord(Offset, ASwapBytes, ASwapWords));
end;

function TPLCStruct.GetSingle(Offset: Integer; ASwapBytes, ASwapWords: Boolean): Single;
var
  AResult: Single;
  AResDWord: Longword absolute AResult;
begin
  AResDWord := GetLongWord(Offset, ASwapBytes, ASwapWords);
  Result := AResult;
end;

function TPLCStruct.GetQWord(Offset: Integer; ASwapBytes, ASwapWords, ASwapDWords: Boolean): QWord;
var
  AResult: QWord;
  ADWords: array [0..1] of Longword absolute AResult;
begin
  if ((Offset < 0) or ((Offset + 7) > High(PValues))) then
    raise Exception.Create(SoutOfBounds);

  if ASwapDWords then
  begin
    ADWords[0] := GetLongWord(Offset + 4, ASwapBytes, SwapWords);
    ADWords[1] := GetLongWord(Offset + 0, ASwapBytes, SwapWords);
  end
  else
  begin
    ADWords[0] := GetLongWord(Offset + 0, ASwapBytes, SwapWords);
    ADWords[1] := GetLongWord(Offset + 4, ASwapBytes, SwapWords);
  end;

  Result := AResult;
end;

function TPLCStruct.GetInt64(Offset: Integer; ASwapBytes, ASwapWords, ASwapDWords: Boolean): Int64;
begin
  Result := Int64(GetQWord(Offset, ASwapBytes, ASwapWords, ASwapDWords));
end;

function TPLCStruct.GetDouble(Offset: Integer; ASwapBytes, ASwapWords, ASwapDWords: Boolean): Double;
var
  AResult: Double;
  AResQWord: QWord absolute AResult;
begin
  AResQWord := GetQWord(Offset, ASwapBytes, ASwapWords, ASwapDWords);
  Result := AResQWord;
end;

function TPLCStruct.GetSiemensString(Offset: Integer; MaxStringSize: Integer): string;
var
  MaxSize: Byte;
  CurSize: Byte;
  B: Byte;
  i: Integer;
  Limit: Integer;
begin
  MaxSize := GetByte(Offset);
  CurSize := GetByte(Offset + 1);

  Result := '';
  Limit := Min(Min(Min(CurSize, MaxSize), MaxStringSize), Size - Offset);
  for i := 0 to Limit - 1 do
  begin
    B := GetByte(Offset + 2 + i);
    if B = 0 then Break;
    Result := Result + chr(GetByte(Offset + 2 + i));
  end;
end;


var
  StructItemMapperEditor: TOpenTagEditor = nil;

procedure TPLCStruct.MapElements(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  if Assigned(StructItemMapperEditor) then
    StructItemMapperEditor(Self, Self.Owner, InsertHook, CreateProc)
  else
    raise Exception.Create('None element mapper tool has been Assigned!');
end;

procedure SetStructItemMapper(StructItemMapperTool: TOpenTagEditor);
begin
  if Assigned(StructItemMapperEditor) then
    raise Exception.Create('A Bit Mapper editor was already Assigned.')
  else
    StructItemMapperEditor := StructItemMapperTool;
end;


end.

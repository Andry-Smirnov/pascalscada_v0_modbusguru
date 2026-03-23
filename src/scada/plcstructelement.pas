{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit that implements a tag item of an structure communication.)
}
unit PLCStructElement;

interface

uses
  Classes, SysUtils, Tag, PLCTag, PLCBlockElement, ProtocolTypes, PLCStruct;

type
  {: @author(Fabio Luis Girardi <fabio@pascalscada.com>)
     @abstract(Class of a tag item of a structure communication tag.) }

  { TPLCStructItem }

  TPLCStructItem = class(TPLCBlockElement, ITagInterface, ITagNumeric)
  private
    function GetBlock: TPLCStruct;
    function GetMySize(NewType: TTagType): Integer;
  protected
    procedure SetBlock(Blk: TPLCStruct);
    //: @seealso(TPLCTag.GetValueRaw)
    function GetValueRaw: Double; override;
    //: @seealso(TPLCNumber.SetValueRaw)
    procedure SetValueRaw(AValue: Double); override;
    //: @seealso(TPLCBlockElement.SetIndex)
    procedure SetIndex(AValue: Cardinal); override;
    //: @seealso(TPLCTag.SetTagType)
    procedure SetTagType(NewType: TTagType); override;

    //IHMITagInterface
    procedure TagChangeCallback(Sender: TObject); override;
    procedure RemoveTagCallBack(Sender: TObject); override;
    //: @exclude
    procedure Loaded; override;
    procedure UpdateTagSizeOnProtocol; override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    procedure SetMinMaxValues(AMin, AMax: Double); override;
    //: @seealso(TPLCTag.Write)
    procedure Write(Values: TArrayOfDouble; Count, Offset: Cardinal); override;
  published
    //: @seealso(TPLCTag.TagType);
    property TagType;
    //: @seealso(TPLCTag.SwapBytes);
    property SwapBytes;
    //: @seealso(TPLCTag.SwapWords);
    property SwapWords;
    //: @seealso(TPLCTag.SwapDWords)
    property SwapDWords;

    property PLCBlock: TPLCStruct read GetBlock write SetBlock;
  end;


implementation


uses
  ProtocolDriver, hsstrings, Math;


constructor TPLCStructItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProtocolTagType := ptByte;
  FProtocolWordSize := 8;
end;

procedure TPLCStructItem.SetMinMaxValues(AMin, AMax: Double);
begin
  inherited SetMinMaxValues(AMin, AMax);
end;

procedure TPLCStructItem.Write(Values: TArrayOfDouble; Count, Offset: Cardinal);
var
  BlkValues: TArrayOfDouble;
begin
  if Assigned(PBlock) then
  begin
    BlkValues := TagValuesToPLCValues(Values, 0);
    PBlock.Write(BlkValues, Length(BlkValues), PIndex + Offset);
  end;
end;

procedure TPLCStructItem.TagChangeCallback(Sender: TObject);
begin
  GetValueRaw();
end;

procedure TPLCStructItem.RemoveTagCallBack(Sender: TObject);
begin
  if PBlock = Sender then
    PBlock := nil;
end;

procedure TPLCStructItem.Loaded;
var
  oldwordsize: Byte;
begin
  oldwordsize := FCurrentWordSize;
  inherited Loaded;
  FCurrentWordSize := oldwordsize;

  UpdateTagSizeOnProtocol;
end;

procedure TPLCStructItem.UpdateTagSizeOnProtocol;
var
  OldProtocol: TProtocolDriver;
begin
  OldProtocol := PProtocolDriver;
  PProtocolDriver := TProtocolDriver(1);
  inherited UpdateTagSizeOnProtocol;
  PProtocolDriver := OldProtocol;
end;

procedure TPLCStructItem.SetBlock(Blk: TPLCStruct);
begin
  if Blk = PLCBlock then Exit;
  //se esta setando o bloco
  //if the block is being set
  if (Blk <> nil) then
  begin
    if (PIndex + GetMySize(FTagType)) > Blk.Size then
      raise Exception.Create(STagIdxMoreSizeExceedStructLen);

    Blk.AddRemoveTagHandler(@RemoveTagCallBack);
    Blk.AddTagChangeHandler(@TagChangeCallback);
    Blk.AddWriteFaultHandler(@WriteFaultCallback);
  end;

  //esta removendo do bloco.
  //removing the link with the block
  if Assigned(PBlock) then
  begin
    PBlock.RemoveAllHandlersFromObject(Self);
  end;

  PBlock := Blk;
end;

function TPLCStructItem.GetValueRaw: Double;
var
  Notify: Boolean;
  Data: TArrayOfDouble;
  ConvertedValue: TArrayOfDouble;
begin
  Result := 0;
  if Assigned(PBlock) then
  begin
    if FCurrentWordSize >= 8 then
    begin
      SetLength(Data, 1);
      Data[0] := PBlock.ValueRaw[PIndex];
    end;

    if FCurrentWordSize >= 16 then
    begin
      SetLength(Data, 2);
      Data[1] := PBlock.ValueRaw[PIndex + 1];
    end;

    if FCurrentWordSize >= 32 then
    begin
      SetLength(Data, 4);
      Data[2] := PBlock.ValueRaw[PIndex + 2];
      Data[3] := PBlock.ValueRaw[PIndex + 3];
    end;

    if FCurrentWordSize >= 64 then
    begin
      SetLength(Data, 8);
      Data[4] := PBlock.ValueRaw[PIndex + 4];
      Data[5] := PBlock.ValueRaw[PIndex + 5];
      Data[6] := PBlock.ValueRaw[PIndex + 6];
      Data[7] := PBlock.ValueRaw[PIndex + 7];
    end;

    ConvertedValue := PLCValuesToTagValues(Data, 0);

    if Length(ConvertedValue) <= 0 then Exit;

    Notify := (IsNan(ConvertedValue[0]) and (not IsNan(PValueRaw))) or
      ((not IsNan(ConvertedValue[0])) and IsNan(PValueRaw)) or (PValueRaw <> ConvertedValue[0]);
    PValueRaw := ConvertedValue[0];
    PValueTimeStamp := PBlock.ValueTimestamp;

    Result := PValueRaw;

    if Notify or PFirstUpdate then
    begin
      PFirstUpdate := False;
      NotifyChange();
    end;

    SetLength(Data, 0);
    SetLength(ConvertedValue, 0);
  end;
end;

procedure TPLCStructItem.SetValueRaw(AValue: Double);
var
  BlkValues: TArrayOfDouble;
  Values: TArrayOfDouble;
begin
  if Assigned(PBlock) then
    begin
      SetLength(Values, 1);
      Values[0] := AValue;
      BlkValues := TagValuesToPLCValues(Values, 0);
      if PBlock.SyncWrites then
        PBlock.Write(BlkValues, Length(BlkValues), PIndex)
      else
        PBlock.ScanWrite(BlkValues, Length(BlkValues), PIndex);
      SetLength(BlkValues, 0);
      SetLength(Values, 0);
    end
  else if PValueRaw <> Value then
    begin
      PValueRaw := Value;
      NotifyChange;
    end;
end;

procedure TPLCStructItem.SetIndex(AValue: Cardinal);
var
  MySize: Longint;
begin
  MySize := FCurrentWordSize div 8;
  if PBlock <> nil then
    if (AValue + MySize) > PBlock.Size then
      raise Exception.Create(SItemOutOfStructure);

  inherited SetIndex(AValue);
end;

function TPLCStructItem.GetBlock: TPLCStruct;
begin
  Result := nil;
  if Assigned(PBlock) then
    Result := PBlock as TPLCStruct;
end;

function TPLCStructItem.GetMySize(NewType: TTagType): Integer;
begin
  case NewType of
    pttDefault:   if FProtocolWordSize = 1 then
                    Result := 1
                  else
                    Result := FProtocolWordSize div 8;
    pttByte,
    pttShortInt:  Result := 1;
    pttSmallInt,
    pttWord:      Result := 2;
    pttLongInt,
    pttDWord,
    pttFloat:     Result := 4;
    pttInt64,
    pttQWord,
    pttDouble:    Result := 8;
  end;
end;

procedure TPLCStructItem.SetTagType(NewType: TTagType);
var
  MySize: Integer;
begin
  MySize := GetMySize(NewType);

  if PBlock <> nil then
    if (PIndex + MySize) > PBlock.Size then
      raise Exception.Create(SItemOutOfStructure);

  inherited SetTagType(NewType);
end;

end.

{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Implementação de tag item de uma estrutura de comunicação.)
}
{$ELSE}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Unit that implements a tag item of an structure communication.)
}
{$ENDIF}
unit PLCStructElement;

interface

uses
  Classes, SysUtils, Tag, PLCTag, PLCBlockElement, ProtocolTypes, PLCStruct;

type
  {$IFDEF PORTUGUES}
  {:
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)

    @abstract(Classe de tag item de uma estrutura de comunicação.)
  }
  {$ELSE}
  {:
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)

    @abstract(Class of a tag item of a structure communication tag.)
  }
  {$ENDIF}

  { TPLCStructItem }

  TPLCStructItem = class(TPLCBlockElement, ITagInterface, ITagNumeric)
  private
    function GetBlock: TPLCStruct;
    function GetMySize(newType: TTagType): Integer;
  protected
    procedure SetBlock(blk: TPLCStruct);
    //: @seealso(TPLCTag.GetValueRaw)
    function GetValueRaw: Double; override;
    //: @seealso(TPLCNumber.SetValueRaw)
    procedure SetValueRaw(aValue: Double); override;
    //: @seealso(TPLCBlockElement.SetIndex)
    procedure SetIndex(i: Cardinal); override;
    //: @seealso(TPLCTag.SetTagType)
    procedure SetTagType(newType: TTagType); override;

    //IHMITagInterface
    procedure TagChangeCallback(Sender: TObject); override;
    procedure RemoveTagCallBack(Sender: TObject); override;
    //: @exclude
    procedure Loaded; override;
    procedure UpdateTagSizeOnProtocol; override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    procedure SetMinMaxValues(aMin, aMax: Double); override;
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

    {$IFDEF PORTUGUES}
    //: Tag estrutura a que o item pertence.
    {$ELSE}
    //: Structure tag which the item belongs.
    {$ENDIF}
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

procedure TPLCStructItem.SetMinMaxValues(aMin, aMax: Double);
begin
  inherited SetMinMaxValues(aMin, aMax);
end;

procedure TPLCStructItem.Write(Values: TArrayOfDouble; Count, Offset: Cardinal);
var
  blkvalues: TArrayOfDouble;
begin
  if Assigned(PBlock) then
  begin
    blkvalues := TagValuesToPLCValues(Values, 0);
    PBlock.Write(blkvalues, Length(blkvalues), PIndex + Offset);
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
  oldprotocol: TProtocolDriver;
begin
  oldprotocol := PProtocolDriver;
  PProtocolDriver := TProtocolDriver(1);
  inherited UpdateTagSizeOnProtocol;
  PProtocolDriver := oldprotocol;
end;

procedure TPLCStructItem.SetBlock(blk: TPLCStruct);
begin
  if blk = PLCBlock then Exit;
  //se esta setando o bloco
  //if the block is being set
  if (blk <> nil) then
  begin
    if (PIndex + GetMySize(FTagType)) > blk.Size then
      raise Exception.Create(STagIdxMoreSizeExceedStructLen);

    blk.AddRemoveTagHandler(@RemoveTagCallBack);
    blk.AddTagChangeHandler(@TagChangeCallback);
    blk.AddWriteFaultHandler(@WriteFaultCallback);
  end;

  //esta removendo do bloco.
  //removing the link with the block
  if Assigned(PBlock) then
  begin
    PBlock.RemoveAllHandlersFromObject(Self);
  end;


  PBlock := blk;
end;

function TPLCStructItem.GetValueRaw: Double;
var
  notify: Boolean;
  Data, converted_value: TArrayOfDouble;
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

    converted_value := PLCValuesToTagValues(Data, 0);

    if Length(converted_value) <= 0 then Exit;

    notify := (IsNan(converted_value[0]) and (not IsNan(PValueRaw))) or
      ((not IsNan(converted_value[0])) and IsNan(PValueRaw)) or (PValueRaw <> converted_value[0]);
    PValueRaw := converted_value[0];
    PValueTimeStamp := PBlock.ValueTimestamp;

    Result := PValueRaw;

    if notify or PFirstUpdate then
    begin
      PFirstUpdate := False;
      NotifyChange();
    end;

    SetLength(Data, 0);
    SetLength(converted_value, 0);
  end;
end;

procedure TPLCStructItem.SetValueRaw(aValue: Double);
var
  blkvalues, Values: TArrayOfDouble;
begin
  if Assigned(PBlock) then
  begin
    SetLength(Values, 1);
    Values[0] := aValue;
    blkvalues := TagValuesToPLCValues(Values, 0);
    if PBlock.SyncWrites then
      PBlock.Write(blkvalues, Length(blkvalues), PIndex)
    else
      PBlock.ScanWrite(blkvalues, Length(blkvalues), PIndex);
    SetLength(blkvalues, 0);
    SetLength(Values, 0);
  end
  else
  if PValueRaw <> Value then
  begin
    PValueRaw := Value;
    NotifyChange;
  end;
end;

procedure TPLCStructItem.SetIndex(i: Cardinal);
var
  MySize: Longint;
begin
  MySize := FCurrentWordSize Div 8;
  if PBlock <> nil then
    if (i + MySize) > PBlock.Size then
      raise Exception.Create(SItemOutOfStructure);

  inherited SetIndex(i);
end;

function TPLCStructItem.GetBlock: TPLCStruct;
begin
  Result := nil;
  if Assigned(PBlock) then
    Result := PBlock as TPLCStruct;
end;

function TPLCStructItem.GetMySize(newType: TTagType): Integer;
begin
  case newType of
    pttDefault:
      if FProtocolWordSize = 1 then
        Result := 1
      else
        Result := FProtocolWordSize Div 8;
    pttByte, pttShortInt:
      Result := 1;
    pttSmallInt, pttWord:
      Result := 2;
    pttLongInt, pttDWord, pttFloat:
      Result := 4;
    pttInt64, pttQWord, pttDouble:
      Result := 8;
  end;
end;

procedure TPLCStructItem.SetTagType(newType: TTagType);
var
  MySize: Integer;
begin
  MySize := GetMySize(newType);

  if PBlock <> nil then
    if (PIndex + MySize) > PBlock.Size then
      raise Exception.Create(SItemOutOfStructure);

  inherited SetTagType(newType);
end;

end.

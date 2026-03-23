{$i ../common/language.inc}
{:
  @abstract(Implements a tag that maps bits from another tag.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Modified. Remove any reference to dialogs, forms ....
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
unit TagBit;

interface

uses
  SysUtils, Classes, PLCNumber, ProtocolTypes, variants, tag;

type
  //: Defines the acceptable range of bits.
  TBitRange = 0..63;

  {: @author(Fabio Luis Girardi <fabio@pascalscada.com>)
     @abstract(Tag that represents a set of bits of another tag.)

  For example, if the linked tag has the value 5 (00000101 bin).
  With StartBit=1 and Endbit=2, the value of the tag bit will be 2 (10 bin).
  With StartBit=0 and EndBit=2, the value of the tag bit will be 5 (101 bin).
  With StartBit=0 and EndBit=1, the value of the tag bit will be 1 (01 bin).
  With StartBit=0 and EndBit=0, the value of the tag bit will be 1 (1 bin).

  StartBit is the less significant bit of the tag and EndBit represents the most
  significant bit. Therefore Endbit must be greater or equal than StartBit. }
  TTagBit = class(TPLCNumber, ITagInterface, ITagNumeric)
  private
    PNumber: TPLCNumber;
    PUseRaw: Boolean;
    PStartBit: TBitRange;
    PEndBit: TBitRange;
    POldValue: Double;
    PNormalMask: QWord;
    PInvMask: QWord;

    procedure SetNumber(AValue: TPLCNumber);
    procedure SetUseRaw(AValue: Boolean);
    procedure SetStartBit(AValue: TBitRange);
    procedure SetEndBit(AValue: TBitRange);

    function GetBits(AValue: Double): Double;
    function SetBits(OriginalValue, AValue: Double): Double;
    function GetBitMask: QWord;
    function GetInvBitMask: QWord;

    function GetVariantValue: Variant;
    procedure SetVariantValue(AValue: Variant);
    function IsValidValue(AValue: Variant): Boolean;
    function GetValueTimestamp: TDatetime;

    procedure WriteFaultCallBack(Sender: TObject);
    procedure TagChangeCallBack(Sender: TObject);
    procedure RemoveTagCallBack(Sender: TObject);
  protected
    //: @seealso(TPLCNumber.SetValueRaw)
    procedure SetValueRaw(AValue: Double); override;
    //: @seealso(TPLCNumber.GetValueRaw)
    function GetValueRaw: Double; override;

    function GetLastAsyncReadStatus: TProtocolIOResult; override;
    function GetLastAsyncWriteStatus: TProtocolIOResult; override;
    function GetLastSyncReadStatus: TProtocolIOResult; override;
    function GetLastSyncWriteStatus: TProtocolIOResult; override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;
  published
    //: Tag where the bits will be mapped.
    property PLCTag: TPLCNumber read PNumber write SetNumber;
    //: If @true, the bits will be mapped from the raw value (ValueRaw property of the tag).
    property UseRawValue: Boolean read PUseRaw write SetUseRaw;
    //: First bit of the tag word to be mapped. Starts from 0 (ZERO).
    property StartBit: TBitRange read PStartBit write SetStartBit;
    //: Last bit of the tag word to be mapped. The Maximum value accept is 31.
    property EndBit: TBitRange read PEndBit write SetEndBit;
    //: @seealso(TPLCNumber.EnableMaxValue)
    property EnableMaxValue;
    //: @seealso(TPLCNumber.EnableMinValue)
    property EnableMinValue;
    //: @seealso(TPLCNumber.MaxValue)
    property MaxValue;
    //: @seealso(TPLCNumber.MinValue)
    property MinValue;

    property LastASyncReadStatus;
    property LastASyncWriteStatus;
    property LastSyncReadStatus;
    property LastSyncWriteStatus;
  end;


implementation


uses
  hsstrings, crossdatetime;


constructor TTagBit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PNumber := nil;
  AutoRead := False;
  AutoWrite := False;
  PNormalMask := GetBitMask;
  PInvMask := GetInvBitMask;
end;

destructor TTagBit.Destroy;
begin
  if PNumber <> nil then
    PNumber.RemoveAllHandlersFromObject(Self);
  PNumber := nil;
  inherited Destroy;
end;


procedure TTagBit.SetNumber(AValue: TPLCNumber);
begin
  if AValue = PNumber then Exit;

  if (AValue <> nil) and ((not Supports(AValue, ITagInterface)) or (not Supports(AValue, ITagNumeric))) then
    raise Exception.Create(SinvalidTag);

  // the link with tag is being removed
  if (PNumber <> nil) then
    PNumber.RemoveAllHandlersFromObject(Self);

  // a new tag link is being set
  if (AValue <> nil) then
  begin
    AValue.AddWriteFaultHandler(@WriteFaultCallBack);
    AValue.AddTagChangeHandler(@TagChangeCallBack);
    AValue.AddRemoveTagHandler(@RemoveTagCallBack);
    TagChangeCallBack(Self);
  end;
  PNumber := AValue;
end;

function TTagBit.GetValueRaw: Double;
begin
  if Assigned(PNumber) and Supports(PNumber, ITagNumeric) then
  begin
    if PUseRaw then
      Result := GetBits((PNumber as ITagNumeric).ValueRaw)
    else
      Result := GetBits((PNumber as ITagNumeric).Value);
  end
  else
    Result := PValueRaw;
end;

function TTagBit.GetLastAsyncReadStatus: TProtocolIOResult;
begin
  if Assigned(PNumber) then
    Result := PNumber.LastASyncReadStatus
  else
    Result := ioNullTagBlock;
end;

function TTagBit.GetLastAsyncWriteStatus: TProtocolIOResult;
begin
  if Assigned(PNumber) then
    Result := PNumber.LastASyncWriteStatus
  else
    Result := ioNullTagBlock;
end;

function TTagBit.GetLastSyncReadStatus: TProtocolIOResult;
begin
  if Assigned(PNumber) then
    Result := PNumber.LastSyncReadStatus
  else
    Result := ioNullTagBlock;
end;

function TTagBit.GetLastSyncWriteStatus: TProtocolIOResult;
begin
  if Assigned(PNumber) then
    Result := PNumber.LastSyncWriteStatus
  else
    Result := ioNullTagBlock;
end;

function TTagBit.GetVariantValue: Variant;
begin
  Result := Value;
end;

procedure TTagBit.SetVariantValue(AValue: Variant);
var
  Aux: Double;
begin
  if VarIsNumeric(AValue) then
    begin
      Value := AValue;
    end
  else if VarIsStr(AValue) then
    begin
      if TryStrToFloat(AValue, Aux) then
        Value := Aux
      else
        raise Exception.Create(SinvalidValue);
    end
  else if VarIsType(AValue, varBoolean) then
    begin
      if AValue then
        Value := 1
      else
        Value := 0;
    end
  else
    raise Exception.Create(SinvalidValue);
end;

function TTagBit.IsValidValue(AValue: Variant): Boolean;
var
  Aux: Double;
  AValueStr: AnsiString;
begin
  AValueStr := AValue;
  Result := VarIsNumeric(AValue)
    or (VarIsStr(AValue) and TryStrToFloat(AValueStr, Aux))
    or VarIsType(AValue, varBoolean);
end;

function TTagBit.GetValueTimestamp: TDatetime;
begin
  Result := PValueTimeStamp;
end;

procedure TTagBit.SetValueRaw(AValue: Double);
begin
  PValueRaw := AValue;
  if (PNumber <> nil) and Supports(PNumber, ITagNumeric) then
    with PNumber as ITagNumeric do
    begin
      if PUseRaw then
        ValueRaw := SetBits(ValueRaw, AValue)
      else
        Value := SetBits(Value, AValue);
    end;
end;

function TTagBit.GetBits(AValue: Double): Double;
var
  x: Int64;
begin
  x := (Trunc(AValue) and PNormalMask) shr Longint(PStartBit);
  Result := x;
end;

function TTagBit.SetBits(OriginalValue, AValue: Double): Double;
begin
  Result := ((Trunc(OriginalValue) and PInvMask)
    or ((Trunc(AValue) shl PStartBit) and PNormalMask));
end;

function TTagBit.GetBitMask: QWord;
var
  i: Byte;
begin
  Result := 0;
  for i := PStartBit to PEndBit do
  begin
    Result := Result or (QWord(1) shl i);
  end;
end;

function TTagBit.GetInvBitMask: QWord;
var
  i: Byte;
begin
  Result := QWord(-1);
  for i := PStartBit to PEndBit do
  begin
    Result := Result xor (QWord(1) shl i);
  end;
end;

procedure TTagBit.SetUseRaw(AValue: Boolean);
begin
  if AValue <> PUseRaw then
  begin
    PUseRaw := AValue;
    NotifyChange;
  end;
end;

procedure TTagBit.SetStartBit(AValue: TBitRange);
begin
  if AValue <> PStartBit then
  begin
    PStartBit := AValue;
    PNormalMask := GetBitMask;
    PInvMask := GetInvBitMask;
    NotifyChange;
  end;
end;

procedure TTagBit.SetEndBit(AValue: TBitRange);
begin
  if AValue <> PEndBit then
  begin
    PEndBit := AValue;
    PNormalMask := GetBitMask;
    PInvMask := GetInvBitMask;
    NotifyChange;
  end;
end;

procedure TTagBit.WriteFaultCallBack(Sender: TObject);
begin
  TagChangeCallBack(Sender);
  NotifyWriteFault;
end;

procedure TTagBit.TagChangeCallBack(Sender: TObject);
var
  AValue: Double;
  Bold: Double;
  BNew: Double;
begin
  if PNumber <> nil then
  begin
    if PUseRaw then
      AValue := PNumber.ValueRaw
    else
      AValue := PNumber.Value;

    Bold := GetBits(POldValue);
    BNew := GetBits(AValue);

    if (Bold <> BNew) or PFirstUpdate then
    begin
      PFirstUpdate := False;
      PValueRaw := BNew;
      PValueTimeStamp := CrossNow;

      NotifyChange();
    end;
    POldValue := AValue;
  end;
end;

procedure TTagBit.RemoveTagCallBack(Sender: TObject);
begin
  if PNumber = Sender then
    PNumber := nil;
end;

end.

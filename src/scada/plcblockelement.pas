{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit that implements a block element tag.)

  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - TPLCBlockElement is descendant of TPLCNumberMappable
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************

}
unit PLCBlockElement;

interface

uses
  SysUtils, Classes, PLCNumber, PLCBlock, ProtocolTypes, variants, Tag;

type
  {: @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  Class of Block element tag.
  Used to get a single value from a set of values (block).

  @seealso(TPLCBlock) }
  TPLCBlockElement = class(TPLCNumberMappable, ITagInterface, ITagNumeric)
  protected
    PBlock: TPLCBlock;
  protected
    PIndex: Cardinal;

    function GetLastAsyncReadStatus: TProtocolIOResult; override;
    function GetLastAsyncWriteStatus: TProtocolIOResult; override;
    function GetLastSyncReadStatus: TProtocolIOResult; override;
    function GetLastSyncWriteStatus: TProtocolIOResult; override;

    procedure SetBlock(Blk: TPLCBlock);
    procedure SetIndex(AValue: Cardinal); virtual;

    function GetVariantValue: Variant;
    procedure SetVariantValue(AValue: Variant);
    function IsValidValue(AValue: Variant): Boolean;
    function GetValueTimestamp: TDatetime;

    procedure WriteFaultCallback(Sender: TObject); virtual;
    procedure TagChangeCallback(Sender: TObject); virtual;
    procedure RemoveTagCallBack(Sender: TObject); virtual;
  protected
    //: @seealso(TPLCNumber.GetValueRaw)
    function GetValueRaw: Double; override;
    //: @seealso(TPLCNumber.SetValueRaw)
    procedure SetValueRaw(AValue: Double); override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;
    //: @seealso(TPLCTag.ScanRead)
    function ScanRead: Int64; override;
    //: @seealso(TPLCTag.ScanWrite)
    function ScanWrite(Values: TArrayOfDouble; Count, Offset: Cardinal; const IgnoreAutoWrite: Boolean = False): Int64; override;
    //: @seealso(TPLCTag.Read)
    procedure Read; override;
    //: @seealso(TPLCTag.Write)
    procedure Write(Values: TArrayOfDouble; Count, Offset: Cardinal); override;
  published
    //: Communication Block of the element.
    property PLCBlock: TPLCBlock read PBlock write SetBlock;
    //: Index of tag element on the Tag Block.
    property Index: Cardinal read PIndex write SetIndex;
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
  hsstrings,
  Math;


constructor TPLCBlockElement.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PBlock := nil;
  AutoRead := False;
  AutoWrite := False;
  PIndex := 0;
end;

destructor TPLCBlockElement.Destroy;
begin
  if Assigned(PBlock) then
    PBlock.RemoveAllHandlersFromObject(Self);
  PBlock := nil;
  inherited Destroy;
end;

function TPLCBlockElement.GetLastAsyncReadStatus: TProtocolIOResult;
begin
  if Assigned(PBlock) then
    Result := PBlock.LastASyncReadStatus
  else
    Result := ioNullTagBlock;
end;

function TPLCBlockElement.GetLastAsyncWriteStatus: TProtocolIOResult;
begin
  if Assigned(PBlock) then
    Result := PBlock.LastASyncWriteStatus
  else
    Result := ioNullTagBlock;
end;

function TPLCBlockElement.GetLastSyncReadStatus: TProtocolIOResult;
begin
  if Assigned(PBlock) then
    Result := PBlock.LastSyncReadStatus
  else
    Result := ioNullTagBlock;
end;

function TPLCBlockElement.GetLastSyncWriteStatus: TProtocolIOResult;
begin
  if Assigned(PBlock) then
    Result := PBlock.LastSyncWriteStatus
  else
    Result := ioNullTagBlock;
end;

procedure TPLCBlockElement.SetBlock(Blk: TPLCBlock);
begin
  if Blk = PLCBlock then Exit;
  //esta removendo do bloco.
  //removing the link with the block
  if Assigned(PBlock) then
  begin
    PBlock.RemoveAllHandlersFromObject(Self);
  end;

  //se esta setando o bloco
  //if the block is being set
  if (Blk <> nil) then
  begin
    Blk.AddRemoveTagHandler(@RemoveTagCallBack);
    Blk.AddTagChangeHandler(@TagChangeCallback);
    Blk.AddWriteFaultHandler(@WriteFaultCallback);
    if PIndex >= Blk.Size then
      PIndex := Blk.Size - 1;
  end;
  PBlock := Blk;
end;

procedure TPLCBlockElement.SetIndex(AValue: Cardinal);
begin
  if PBlock = nil then
  begin
    PIndex := AValue;
    Exit;
  end;

  if AValue >= PBlock.Size then
    raise Exception.Create(SoutOfBounds);
  PIndex := AValue;
end;

function TPLCBlockElement.GetValueRaw: Double;
begin
  if Assigned(PBlock) then
    Result := PBlock.ValueRaw[PIndex]
  else
    Result := PValueRaw;
end;

function TPLCBlockElement.GetVariantValue: Variant;
begin
  Result := Value;
end;

procedure TPLCBlockElement.SetVariantValue(AValue: Variant);
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
      if AValue = True then
        Value := 1
      else
        Value := 0;
    end
  else
    raise Exception.Create(SinvalidValue);
end;

function TPLCBlockElement.IsValidValue(AValue: Variant): Boolean;
var
  Aux: Double;
  AValueStr: AnsiString;
begin
  AValueStr := AValue;
  Result := VarIsNumeric(AValue)
    or (VarIsStr(AValue) and TryStrToFloat(AValueStr, Aux))
    or VarIsType(AValue, varboolean);
end;

function TPLCBlockElement.GetValueTimestamp: TDatetime;
begin
  Result := PValueTimeStamp;
end;

procedure TPLCBlockElement.SetValueRaw(AValue: Double);
begin
  if Assigned(PBlock) then
  begin
    PBlock.ValueRaw[PIndex] := AValue;
    PValueRaw := AValue;
  end
  else
  if PValueRaw <> Value then
  begin
    PValueRaw := Value;
    NotifyChange;
  end;
end;

function TPLCBlockElement.ScanRead: Int64;
begin
  if Assigned(PBlock) then
    Result := PBlock.ScanRead
  else
    Result := -1;
end;

function TPLCBlockElement.ScanWrite(Values: TArrayOfDouble; Count, Offset: Cardinal; const IgnoreAutoWrite: Boolean): Int64;
begin
  if Assigned(PBlock) then
    Result := PBlock.ScanWrite(Values, 1, PIndex, IgnoreAutoWrite)
  else
    Result := -1;
end;

procedure TPLCBlockElement.Read;
begin
  if Assigned(PBlock) then
  begin
    PBlock.Read;
  end;
end;

procedure TPLCBlockElement.Write(Values: TArrayOfDouble; Count, Offset: Cardinal);
begin
  if Assigned(PBlock) then
    PBlock.Write(Values, 1, PIndex);
end;

procedure TPLCBlockElement.WriteFaultCallback(Sender: TObject);
var
  Notify: Boolean;
begin
  if Assigned(PBlock) then
  begin
    Notify := (PValueRaw <> PBlock.ValueRaw[PIndex])
      or (IsNan(PBlock.ValueRaw[PIndex]) and (not IsNan(PValueRaw)));
    PValueRaw := PBlock.ValueRaw[PIndex];
    PValueTimeStamp := PBlock.ValueTimestamp;

    if Notify or PFirstUpdate then
    begin
      PFirstUpdate := False;
      NotifyWriteFault();
    end;
  end;
end;

procedure TPLCBlockElement.TagChangeCallback(Sender: TObject);
var
  Notify: Boolean;
begin
  if Assigned(PBlock) then
  begin
    Notify := (PValueRaw <> PBlock.ValueRaw[PIndex])
      or (IsNan(PBlock.ValueRaw[PIndex]) and (not IsNan(PValueRaw)));
    PValueRaw := PBlock.ValueRaw[PIndex];
    PValueTimeStamp := PBlock.ValueTimestamp;

    if Notify or PFirstUpdate then
    begin
      PFirstUpdate := False;
      NotifyChange();
    end;
  end;
end;

procedure TPLCBlockElement.RemoveTagCallBack(Sender: TObject);
begin
  if PBlock = Sender then
    PBlock := nil;
end;

end.

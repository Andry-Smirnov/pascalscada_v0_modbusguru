{$i ../common/language.inc}
{:
  @abstract(Unit that implements a numeric tag with communication.)
  @author(Fabio Luis Girardi fabio@pascalscada.com)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - TPLCTagNumber is descendant of TPLCNumberMappable
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************

}
unit PLCTagNumber;

interface

uses
  SysUtils, Classes, Tag, PLCNumber, ProtocolTypes, variants;

type

  {: @abstract(Single numeric tag with communication.)
     @author(Fabio Luis Girardi fabio@pascalscada.com) }
  TPLCTagNumber = class(TPLCNumberMappable, IScanableTagInterface, ITagInterface, ITagNumeric)
  private
    function GetVariantValue: Variant;
    procedure SetVariantValue(AValue: Variant);
    function IsValidValue(AValue: Variant): Boolean;
    function GetValueTimestamp: TDatetime;
  protected
    function IsMyCallBack(ACallBack: TTagCommandCallBack): Boolean; override;
    //: @seealso(TPLCNumber.SetValueRaw)
    function GetValueRaw: Double; override;
    //: @seealso(TPLCNumber.SetValueRaw)
    procedure SetValueRaw(AValue: Double); override;
    //: @seealso(TPLCTag.TagCommandCallBack)
    procedure TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDatetime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint); override;
    //: @seealso(TTag.Size)
    property Size nodefault;
  public
    //: @seealso(TPLCTag.ScanRead)
    function ScanRead: Int64; override;
    //: @seealso(TPLCTag.ScanWrite)
    function ScanWrite(Values: TArrayOfDouble; Count, Offset: Cardinal; const IgnoreAutoWrite: Boolean = False): Int64; override;
    //: @seealso(TPLCTag.Read)
    procedure Read; override;
    //: @seealso(TPLCTag.Write)
    procedure Write(Values: TArrayOfDouble; Count, Offset: Cardinal); override;

    procedure Write(AValue: Double); overload;

    procedure SetMinMaxValues(AMin, AMax: Double); override;
  published
    //: @seealso(TTag.AutoRead)
    property AutoRead;
    //: @seealso(TTag.AutoWrite)
    property AutoWrite;
    //: @seealso(TTag.CommReadErrors)
    property CommReadErrors;
    //: @seealso(TTag.CommReadsOK)
    property CommReadsOK;
    //: @seealso(TTag.CommWriteErrors)
    property CommWriteErrors;
    //: @seealso(TTag.CommWritesOk)
    property CommWritesOk;
    //: @seealso(TTag.PLCRack)
    property PLCRack;
    //: @seealso(TTag.PLCSlot)
    property PLCSlot;
    //: @seealso(TTag.PLCStation)
    property PLCStation;
    //: @seealso(TTag.MemFile_DB)
    property MemFile_DB;
    //: @seealso(TTag.MemAddress)
    property MemAddress;
    //: @seealso(TTag.MemSubElement)
    property MemSubElement;
    //: @seealso(TTag.MemReadFunction)
    property MemReadFunction;
    //: @seealso(TTag.MemWriteFunction)
    property MemWriteFunction;
    //: @seealso(TTag.Retries)
    property Retries;
    //: @seealso(TPLCTag.ProtocolDriver)
    property ProtocolDriver;
    //: @seealso(TPLCNumber.ScaleProcessor)
    property ScaleProcessor;
    //: @seealso(TTag.RefreshTime)
    property RefreshTime;
    //: @seealso(TTag.ScanRate)
    property UpdateTime;
    //: @seealso(TPLCTag.ValueTimestamp)
    property ValueTimestamp;
    //: @seealso(TTag.LongAddress)
    property LongAddress;
    //: @seealso(TPLCTag.SyncWrites)
    property SyncWrites;
    //: @seealso(TPLCTag.TagType)
    property TagType;
    //: @seealso(TPLCTag.SwapBytes)
    property SwapBytes;
    //: @seealso(TPLCTag.SwapWords)
    property SwapWords;
    //: @seealso(TPLCTag.SwapDWords)
    property SwapDWords;
    //: @seealso(TPLCTag.TagSizeOnProtocol)
    property TagSizeOnProtocol;
    //: @seealso(TPLCTag.AvgUpdateRate)
    property AvgUpdateRate;
    //: @seealso(TPLCNumber.EnableMaxValue)
    property EnableMaxValue;
    //: @seealso(TPLCNumber.EnableMinValue)
    property EnableMinValue;
    //: @seealso(TPLCNumber.MaxValue)
    property MaxValue;
    //: @seealso(TPLCNumber.MinValue)
    property MinValue;
    //: @seealso(TTag.OnUpdate)
    property OnUpdate;

    property LastScanReadReqID;
    property LastScanWriteReqID;
  end;


implementation


uses
  hsstrings, Math, crossdatetime, dateutils;


function TPLCTagNumber.IsMyCallBack(ACallBack: TTagCommandCallBack): Boolean;
begin
  Result := inherited IsMyCallBack(ACallBack) and (TMethod(ACallBack).Code = Pointer(@TPLCTagNumber.TagCommandCallBack));
end;

function TPLCTagNumber.GetValueRaw: Double;
begin
  Result := PValueRaw;
end;

function TPLCTagNumber.GetVariantValue: Variant;
begin
  Result := Value;
end;

procedure TPLCTagNumber.SetVariantValue(AValue: Variant);
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
  else if VarIsType(AValue, varboolean) then
    begin
      if AValue = True then
        Value := 1
      else
        Value := 0;
    end
  else
    raise Exception.Create(SinvalidValue);
end;

function TPLCTagNumber.IsValidValue(AValue: Variant): Boolean;
var
  Aux: Double;
  AValueStr: AnsiString;
begin
  AValueStr := AValue;
  Result := VarIsNumeric(AValue)
    or (VarIsStr(AValue) and TryStrToFloat(AValueStr, Aux))
    or VarIsType(AValue, varboolean);
end;

function TPLCTagNumber.GetValueTimestamp: TDatetime;
begin
  Result := PValueTimeStamp;
end;

procedure TPLCTagNumber.SetValueRaw(AValue: Double);
var
  ToWrite: TArrayOfDouble;
begin
  PModified := True;
  SetLength(ToWrite, 1);
  ToWrite[0] := AValue;
  if FSyncWrites then
    Write(ToWrite, 1, 0)
  else
    ScanWrite(ToWrite, 1, 0);
  SetLength(ToWrite, 0);
end;

function TPLCTagNumber.ScanRead: Int64;
var
  TagObj: TTagRec;
begin
  inherited ScanRead;
  if (PProtocolDriver <> nil) then
  begin
    BuildTagRec(TagObj, 0, 0);
    Result := PProtocolDriver.SingleScanRead(TagObj);
  end
  else
    Result := -1;
end;

function TPLCTagNumber.ScanWrite(Values: TArrayOfDouble; Count, Offset: Cardinal; const IgnoreAutoWrite: Boolean): Int64;
var
  TagObj: TTagRec;
  PLCValues: TArrayOfDouble;
begin
  PLCValues := TagValuesToPLCValues(Values, Offset);
  try
    if (PProtocolDriver <> nil) then
      begin
        if PAutoWrite or IgnoreAutoWrite then
          begin
            BuildTagRec(TagObj, 0, 0);
            Result := PProtocolDriver.ScanWrite(TagObj, PLCValues);
          end
        else
          begin
            TagCommandCallBack(0, PLCValues, CrossNow, tcScanWrite, ioOk, 0);
            Dec(PCommWriteOk);
            Result := -1;
          end;
      end
    else
      begin
        TagCommandCallBack(0, PLCValues, CrossNow, tcScanWrite, ioNullDriver, Offset);
        Result := -1;
      end;
  finally
    SetLength(PLCValues, 0);
  end;
end;

procedure TPLCTagNumber.Read;
var
  TagObj: TTagRec;
begin
  if PProtocolDriver <> nil then
  begin
    BuildTagRec(TagObj, 0, 0);
    PProtocolDriver.Read(TagObj);
  end;
end;

procedure TPLCTagNumber.Write(Values: TArrayOfDouble; Count, Offset: Cardinal);
var
  TagObj: TTagRec;
  PLCValues: TArrayOfDouble;
begin
  PLCValues := TagValuesToPLCValues(Values, Offset);
  if (PProtocolDriver <> nil) then
  begin
    BuildTagRec(TagObj, 0, 0);
    PProtocolDriver.Write(TagObj, PLCValues);
  end
  else
    TagCommandCallBack(0, PLCValues, CrossNow, tcWrite, ioNullDriver, Offset);
  SetLength(PLCValues, 0);
end;

procedure TPLCTagNumber.Write(AValue: Double);
var
  x: TArrayOfDouble;
begin
  SetLength(x, 1);
  try
    x[0] := AValue;
    Write(x, 1, 0);
  finally
    SetLength(x, 0);
  end;
end;

procedure TPLCTagNumber.SetMinMaxValues(AMin, AMax: Double);
begin
  inherited SetMinMaxValues(AMin, AMax);
end;

procedure TPLCTagNumber.TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDatetime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint);
var
  Notify: Boolean;
  TagValues: TArrayOfDouble;
  PreviousTimeStamp: TDatetime;
begin
  PreviousTimeStamp := PValueTimeStamp;
  if (csDestroying in ComponentState) then
    Exit;
  inherited TagCommandCallBack(ReqID, Values, ValuesTimeStamp, TagCommand, LastResult, Offset);

  TagValues := PLCValuesToTagValues(Values, Offset);

  try
    Notify := False;
    case TagCommand of
      tcScanRead,
      tcRead,
      tcInternalUpdate,
      tcSingleScanRead: begin
                          PValueTimeStamp := ValuesTimeStamp;

                          if (Length(TagValues) > 0) and (LastResult in [ioOk, ioNullDriver]) then
                            begin
                              Notify := (PValueRaw <> TagValues[0]) or (IsNan(TagValues[0]) and (not IsNan(PValueRaw)));
                              PValueRaw := TagValues[0];
                              if (TagCommand <> tcInternalUpdate) and (LastResult = ioOk) then
                              begin
                                PModified := False;
                                IncCommReadOK(1);
                              end;
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
                  PValueTimeStamp := ValuesTimeStamp;
                  if (Length(TagValues) > 0) and (LastResult in [ioOk, ioNullDriver]) then
                    begin
                      if LastResult = ioOk then
                      begin
                        PModified := False;
                        IncCommWriteOK(1);
                      end;
                      Notify := (PValueRaw <> TagValues[0]);
                      PValueRaw := TagValues[0];
                    end
                  else
                    IncCommWriteFaults(1);
                end;
    end;

    case TagCommand of
      tcScanRead,
      tcSingleScanRead: PLastASyncReadCmdResult := LastResult;
      tcScanWrite:      PLastASyncWriteCmdResult := LastResult;
      tcRead:           PLastSyncReadCmdResult := LastResult;
      tcWrite:          PLastSyncWriteCmdResult := LastResult;
    end;

    if Notify or PFirstUpdate then
    begin
      if (TagCommand in [tcRead, tcScanRead, tcSingleScanRead])
        or (ProtocolDriver = nil) then
        PFirstUpdate := False;
      NotifyChange;
    end;

    if (TagCommand in [tcRead, tcScanRead, tcSingleScanRead])
      and (LastResult = ioOk)
      and (PreviousTimeStamp <> PValueTimeStamp) then
      NotifyUpdate;
  finally
    SetLength(TagValues, 0);
  end;
end;

end.
 

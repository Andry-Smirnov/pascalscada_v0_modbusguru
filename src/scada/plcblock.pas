{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit that implements a block of tags of communication.)

  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Moved OpenElementMapper to BlockTagAssistant to remove TForm dependencies
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  10/2014 - Switched back to the old behavior but keeping the improvemnt
  of Juanjo (do not link with GUI);
  ***********************************************************************
}
unit PLCBlock;

interface

uses
  SysUtils, Classes, Tag, TagBlock, ProtocolTypes;

type
  {: @author(Fabio Luis Girardi <fabio@pascalscada.com>)
    Class of Block of tags of communication. }

  { TPLCBlock }

  TPLCBlock = class(TTagBlock, IScanableTagInterface)
  private
    procedure SetSize(isize: Cardinal);
    function GetValue(Index: Longint): Double;
    procedure SetValue(Index: Longint; Value: Double);

    function GetValues: TArrayOfDouble;
    procedure SetValues(Values: TArrayOfDouble);
  protected
    //: @seealso(TTag.AsyncNotifyChange)    
    procedure AsyncNotifyChange(Data: Pointer); override;
    //: @seealso(TTag.GetValueChangeData)
    function GetValueChangeData: Pointer; override;
    //: @seealso(TTag.ReleaseChangeData)
    procedure ReleaseChangeData(Data: Pointer); override;
    //: @seealso(TPLCTag.IsMyCallBack)
    function IsMyCallBack(ACallBack: TTagCommandCallBack): Boolean; override;
    //: @seealso(TPLCTag.TagCommandCallBack)
    procedure TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDateTime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint); override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    {: @name writes asynchronously the values stored in the block.
    @bold(Only works if AutoWrite = @false.) }
    procedure WriteByScan;
    {: @name writes synchronously the values stored in the block.
    @bold(Only works if AutoWrite = @false.) }
    procedure WriteDirect;

    //: @seealso(TPLCTag.ScanRead)
    function ScanRead: Int64; override;
    //: @seealso(TPLCTag.Read)
    procedure Read; override;

    //: @seealso(TPLCTag.ScanWrite)
    function ScanWrite(Values: TArrayOfDouble; Count, Offset: Cardinal; const IgnoreAutoWrite: Boolean = False): Int64; override;
    //: @seealso(TPLCTag.Write)
    procedure Write(Values: TArrayOfDouble; Count, Offset: Cardinal); override;

    //: Opens the block/struct item mapper wizard.
    procedure MapElements(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); virtual;
    //: Read/Writes a raw value asynchronously on a block item.
    property ValueRaw[Index: Longint]: Double read GetValue write SetValue;
    //: Read/Writes a raw values asynchronously on block.
    property ValuesRaw: TArrayOfDouble read GetValues write SetValues;
  published
    //: Number of elements of the block.
    property Size write SetSize;
    //: @seealso(TTag.OnValueChange)
    property OnValueChange stored False;
    //: @seealso(TTag.OnValueChangeFirst)
    property OnValueChangeFirst;
    //: @seealso(TTag.OnValueChangeLast)
    property OnValueChangeLast;
    //: @seealso(TTag.OnUpdate)
    property OnUpdate;
    //: @seealso(TTag.OnAsyncValueChange)
    property OnAsyncValueChange;
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
    //: @seealso(TPLCTag.Modified)
    property Modified;
  end;


procedure SetBlockElementMapper(ElementMapperTool: TOpenTagEditor);


implementation


uses
  hsstrings,
  Math;


constructor TPLCBlock.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PSize := 1;
  SetLength(PValues, PSize);
end;

destructor TPLCBlock.Destroy;
begin
  SetLength(PValues, 0);
  inherited Destroy;
end;

function TPLCBlock.IsMyCallBack(ACallBack: TTagCommandCallBack): Boolean;
begin
  Result := inherited IsMyCallBack(ACallBack) and (TMethod(ACallBack).Code = Pointer(@TPLCBlock.TagCommandCallBack));
end;

procedure TPLCBlock.TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp:
  TDateTime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint);
var
  c: Longint;
  Notify: Boolean;
  TagValues: TArrayOfDouble;
  PreviousTimestamp: TDateTime;
begin
  if (csDestroying in ComponentState) then Exit;
  PreviousTimestamp := PValueTimeStamp;
  try
    inherited TagCommandCallBack(ReqID, Values, ValuesTimeStamp, TagCommand, LastResult, Offset);
    TagValues := PLCValuesToTagValues(Values, Offset);
    Notify := False;
    case TagCommand of
      tcScanRead,
      tcRead,
      tcInternalUpdate,
      tcSingleScanRead: begin
                          PValueTimeStamp := ValuesTimeStamp;
                          if LastResult in [ioOk, ioNullDriver] then
                          begin
                            for c := low(TagValues) to High(TagValues) do
                            begin
                              if (c + Offset < Length(PValues)) then
                              begin
                                Notify := Notify or (PValues[c + Offset] <> TagValues[c])
                                  or (IsNan(TagValues[c]) and (not IsNan(PValues[c + Offset])));
                                PValues[c + Offset] := TagValues[c];
                              end
                              else
                              begin
                                {$IFNDEF WINDOWS}
                                WriteLn({$I %FILE%}, ' at line ', {$I %LINE%},
                                  ' (', {$I %CurrentRoutine%},
                                  '): Please fix-me: ', ClassName, '(', Name,
                                  ') PValuesLen=', Length(PValues), ' offset=', Offset,
                                  ' TagValues Len=', Length(TagValues));
                                {$ENDIF}
                                Break;
                              end;
                            end;
                            if (TagCommand <> tcInternalUpdate) and (LastResult = ioOk) then
                            begin
                              IncCommReadOK(1);
                              PModified := False;
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
                  if LastResult in [ioOk, ioNullDriver] then
                  begin
                    if LastResult = ioOk then
                    begin
                      IncCommWriteOK(1);
                      PModified := False;
                    end;
                    for c := 0 to High(TagValues) do
                    begin
                      Notify := Notify or (PValues[c + Offset] <> TagValues[c]);
                      PValues[c + Offset] := TagValues[c];
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
      if (TagCommand in [tcRead, tcScanRead, tcSingleScanRead]) or (ProtocolDriver = nil) then
        PFirstUpdate := False;
      NotifyChange;
    end;

    if (TagCommand in [tcRead, tcScanRead, tcSingleScanRead])
      and (LastResult = ioOk)
      and (PreviousTimestamp <> PValueTimeStamp) then
      NotifyUpdate;
  finally
    SetLength(TagValues, 0);
  end;
end;

procedure TPLCBlock.SetSize(isize: Cardinal);
begin
  if (isize > 0) and (PSize <> isize) then
  begin
    if (PProtocolDriver <> nil) and PAutoRead then
      PProtocolDriver.RemoveTag(Self);

    PSize := isize;
    SetLength(PValues, PSize);

    if ([csReading, csLoading] * ComponentState = []) then
      GetNewProtocolTagSize;

    if (PProtocolDriver <> nil) and PAutoRead then
      PProtocolDriver.AddTag(Self);
  end;
end;

function TPLCBlock.GetValue(Index: Longint): Double;
begin
  if ((Index < 0) or (Index > High(PValues))) then
  begin
    raise Exception.Create(Format(SoutOfBounds2, [ClassName, Name, Index, Length(PValues)]));
  end;
  Result := PValues[Index];
end;

procedure TPLCBlock.SetValue(Index: Longint; Value: Double);
var
  ToWrite: TArrayOfDouble;
begin
  PModified := True;
  SetLength(ToWrite, 1);
  try
    ToWrite[0] := Value;
    if FSyncWrites then
      Write(ToWrite, 1, Index)
    else
      ScanWrite(ToWrite, 1, Index);
  finally
    SetLength(ToWrite, 0);
  end;

end;

function TPLCBlock.GetValues: TArrayOfDouble;
begin
  Result := PValues;
end;

procedure TPLCBlock.SetValues(Values: TArrayOfDouble);
var
  ToWrite: TArrayOfDouble;
begin
  PModified := True;
  ToWrite := Values;
  try
    if FSyncWrites then
      Write(ToWrite, PSize, 0)
    else
      ScanWrite(ToWrite, PSize, 0);
  finally
    SetLength(ToWrite, 0);
  end;
end;

procedure TPLCBlock.AsyncNotifyChange(Data: Pointer);
var
  x: PArrayOfDouble;
begin
  if not Assigned(POnAsyncValueChange) then Exit;
  x := Data;
  POnAsyncValueChange(Self, x^);
end;

function TPLCBlock.GetValueChangeData: Pointer;
var
  x: PArrayOfDouble;
begin
  New(x);
  x^ := PValues;
  Result := x;
end;

procedure TPLCBlock.ReleaseChangeData(Data: Pointer);
var
  x: PArrayOfDouble;
begin
  x := Data;
  SetLength(x^, 0);
  Dispose(x);
end;

procedure TPLCBlock.WriteByScan;
var
  x: Boolean;
begin
  x := PAutoWrite;
  try
    PAutoWrite := True;
    ScanWrite(PValues, PSize, 0);
  finally
    PAutoWrite := x;
  end;
end;

procedure TPLCBlock.WriteDirect;
begin
  Write(PValues, PSize, 0);
end;

function TPLCBlock.ScanRead: Int64;
begin
  Result := inherited ScanRead;
end;

procedure TPLCBlock.Read;
begin
  inherited Read;
end;

function TPLCBlock.ScanWrite(Values: TArrayOfDouble; Count, Offset: Cardinal; const IgnoreAutoWrite: Boolean): Int64;
var
  PLCValues: TArrayOfDouble;
begin
  PLCValues := TagValuesToPLCValues(Values, Offset);
  try
    Result := inherited ScanWrite(PLCValues, Count, Offset, IgnoreAutoWrite);
  finally
    SetLength(PLCValues, 0);
  end;
end;

procedure TPLCBlock.Write(Values: TArrayOfDouble; Count, Offset: Cardinal);
var
  PLCValues: TArrayOfDouble;
begin
  PLCValues := TagValuesToPLCValues(Values, Offset);
  inherited Write(PLCValues, Count, Offset);
  SetLength(PLCValues, 0);
end;


var
  ElementMapperEditor: TOpenTagEditor = nil;


procedure TPLCBlock.MapElements(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  if Assigned(ElementMapperEditor) then
    ElementMapperEditor(Self, Self.Owner, InsertHook, CreateProc)
  else
    raise Exception.Create('None element mapper tool has been Assigned!');
end;

procedure SetBlockElementMapper(ElementMapperTool: TOpenTagEditor);
begin
  if Assigned(ElementMapperEditor) then
    raise Exception.Create('A Bit Mapper editor was already Assigned.')
  else
    ElementMapperEditor := ElementMapperTool;
end;


end.

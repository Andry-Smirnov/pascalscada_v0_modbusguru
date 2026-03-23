{$i ../common/language.inc}
{:
  @abstract(Unit that implements a numeric tag for general use.)
  @author(Fabio Luis Girardi fabio@pascalscada.com)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Moved OpenBitMapper to BitMapTagAssistant to remove form dependencies
  07/2013 - Added TPLCNumberMappable to avoid TTagBit to be BitMappable
  07/2013 - Remove Dialogs unit and replace MessageDlg with raising exceptions;
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
unit PLCNumber;

interface

uses
  SysUtils, Classes, PLCTag, ValueProcessor, ProtocolTypes, dateutils;

type

  {: @abstract(Base class of numeric tags.)
     @author(Fabio Luis Girardi fabio@pascalscada.com) }
  TPLCNumber = class(TPLCTag)
  protected
    //: @seealso(ITagInterface.GetValueAsText);
    function GetValueAsText(Prefix, Sufix, Format: UTF8String; FormatDateTimeOptions: TFormatDateTimeOptions = []): UTF8String; virtual;
    //: @seealso(TTag.AsyncNotifyChange)    
    procedure AsyncNotifyChange(Data: Pointer); override;
    //: @seealso(TTag.GetValueChangeData)
    function GetValueChangeData: Pointer; override;
    //: @seealso(TTag.ReleaseChangeData)
    procedure ReleaseChangeData(Data: Pointer); override;
    procedure SetMinMaxValues(AMin, AMax: Double); virtual;
  protected
    //: Stores if must be checked the minimum and maximum limits.
    FEnableMin: Boolean;
    FEnableMax: Boolean;
    //: Stores the minimum and maximum limits.
    FMinLimit: Double;
    FMaxLimit: Double;
    //: Store the scales linked with the tag.
    PScaleProcessor: TScaleProcessor;
    //: Stores the raw value (without scales).
    PValueRaw: Double;

    //: Returns the value processed by the linked scales or the value raw.
    function GetValue: Double; virtual;
    //: Returns the raw value.
    function GetValueRaw: Double; virtual; abstract;
    {: Processes the value using linked scales and writes the value processed on device.
    @param(Value Double: Value to be processed and written in device.)
    @seealso(SetValueRaw) }
    procedure SetValue(AValue: Double); virtual;
    {: Write the raw value on device.
       @param(Value Double: Value to be written.) }
    procedure SetValueRaw(AValue: Double); virtual; abstract;
    {: Sets the new scales sequence.
       @param(sp TPIPE: The new scale sequence.)
       @seealso(ScaleProcessor) }
    procedure SetScaleProcessor(AValue: TScaleProcessor);
    //: set the minimum limit.
    procedure SetMinLimit(AValue: Double);
    //: sets the maximum limit.
    procedure SetMaxLimit(AValue: Double);

    //: @exclude
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    //: Enables/disables the minimum limit.
    property EnableMinValue: Boolean read FEnableMin write FEnableMin stored True;
    //: Enables/disables the maximum limit.
    property EnableMaxValue: Boolean read FEnableMax write FEnableMax stored True;
    //: Minimum value acceptable if the minimum limit is enabled.
    property MinValue: Double read FMinLimit write SetMinLimit;
    //: Maximum value acceptable if the maximum limit is enabled.
    property MaxValue: Double read FMaxLimit write SetMaxLimit;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    //: @seealso(TPLCTag.Write)
    procedure Write; overload; virtual;
    //: @seealso(TPLCTag.Write)
    function ScanWrite: Int64; overload; virtual;
    //: Removes the scales sequence, it's being destroyed.
    procedure RemoveScaleProcessor;
    //: Tag Value processed by the scales.
    property Value: Double read GetValue write SetValue;
    //: Raw value of the tag.
    property ValueRaw: Double read PValueRaw write SetValueRaw;
  published
    //: Scale sequence of tag.
    property ScaleProcessor: TScaleProcessor read PScaleProcessor write SetScaleProcessor;
    //: Event called when the value of tag changes. Called AFTER updates all dependent components.
    property OnValueChange stored False;
    //: Event called when the value of tag changes. Called BEFORE updates all dependent components.
    property OnValueChangeFirst;
    //: Event called when the value of tag changes. Called AFTER updates all dependent components.
    property OnValueChangeLast;
    //: Asynchronous event called when the tag value changes.
    property OnAsyncValueChange;
  end;


  //: This abstract class avoid TTagbit component being listed in the property editor of TBitMapperTagAssistant

  { TPLCNumberMappable }

  TPLCNumberMappable = class(TPLCNumber)
    //: Opens the bit mapper wizard.
    procedure OpenBitMapper(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); virtual;
  end;


procedure SetTagBitMapper(BitMapperTool: TOpenTagEditor);


implementation


uses
  tag, hsstrings;


constructor TPLCNumber.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PValueRaw := 0;
end;

destructor TPLCNumber.Destroy;
begin
  SetScaleProcessor(nil);
  inherited Destroy;
end;

function TPLCNumber.GetValueAsText(Prefix, Sufix, Format: UTF8String; FormatDateTimeOptions: TFormatDateTimeOptions = []): UTF8String;
begin
  //if none of date time format chars is present, format as number.
  if    (Pos('c', Format) = 0)
    and (Pos('f', Format) = 0)
    and (Pos('d', Format) = 0)
    and (Pos('dd', Format) = 0)
    and (Pos('ddd', Format) = 0)
    and (Pos('dddd', Format) = 0)
    and (Pos('ddddd', Format) = 0)
    and (Pos('dddddd', Format) = 0)
    and (Pos('m', Format) = 0)
    and (Pos('mm', Format) = 0)
    and (Pos('mmm', Format) = 0)
    and (Pos('mmmm', Format) = 0)
    and (Pos('y', Format) = 0)
    and (Pos('yy', Format) = 0)
    and (Pos('yyyy', Format) = 0)
    and (Pos('h', Format) = 0)
    and (Pos('hh', Format) = 0)
    and (Pos('n', Format) = 0)
    and (Pos('nn', Format) = 0)
    and (Pos('s', Format) = 0)
    and (Pos('ss', Format) = 0)
    and (Pos('t', Format) = 0)
    and (Pos('tt', Format) = 0)
    and (Pos('am/pm', Format) = 0)
    and (Pos('a/p', Format) = 0)
    and (Pos('/', Format) = 0)
    and (Pos(':', Format) = 0)
    and (Pos('"xx"', Format) = 0)
    and (Pos('''xx''', Format) = 0)
    and (Pos('z', Format) = 0)
    and (Pos('zzz', Format) = 0) then
  begin
    if Trim(Format) <> '' then
      Result := Prefix + FormatFloat(Format, Value) + Sufix
    else
      Result := Prefix + FloatToStr(Value) + Sufix;
  end
  else
  begin
    // the datetime number must be in milliseconds (1 unit=1ms)
    {$IF defined(FPC_FULLVERSION) AND (FPC_FULLVERSION < 20701)}
    Result := Prefix + FormatDateTime(Format, TimeStampToDateTime(MSecsToTimeStamp(Trunc(Value)))) + Sufix;
    {$ELSE}
    Result:=Prefix + FormatDateTime(Format,TimeStampToDateTime(MSecsToTimeStamp(Trunc(Value))),FormatDateTimeOptions) + Sufix;
    {$IFEND}
  end;
end;

procedure TPLCNumber.AsyncNotifyChange(Data: Pointer);
var
  x: PArrayOfDouble;
begin
  if not Assigned(POnAsyncValueChange) then Exit;
  x := Data;
  POnAsyncValueChange(Self, x^);
end;

function TPLCNumber.GetValueChangeData: Pointer;
var
  x: PArrayOfDouble;
begin
  New(x);
  SetLength(x^, 1);
  x^[0] := Value;
  Result := x;
end;

procedure TPLCNumber.ReleaseChangeData(Data: Pointer);
var
  x: PArrayOfDouble;
begin
  x := Data;
  SetLength(x^, 0);
  Dispose(x);
end;

procedure TPLCNumber.SetMinMaxValues(AMin, AMax: Double);
begin
  if AMin > AMax then
    raise Exception.Create(SMinIsGreaterThanMax);
  FMinLimit := AMin;
  FMaxLimit := AMax;
end;

function TPLCNumber.GetValue: Double;
begin
  if Assigned(PScaleProcessor) then
    Result := PScaleProcessor.SetInGetOut(Self, GetValueRaw)
  else
    Result := GetValueRaw;
end;

procedure TPLCNumber.SetValue(AValue: Double);
var
  ToWrite: Double;
begin
  if (FEnableMin and (AValue < FMinLimit)) or (FEnableMax and (AValue > FMaxLimit)) then
  begin
    NotifyWriteFault;
    raise Exception.Create(SoutOfBounds);
  end;

  if Assigned(PScaleProcessor) then
    ToWrite := PScaleProcessor.SetOutGetIn(Self, AValue)
  else
    ToWrite := AValue;

  SetValueRaw(ToWrite);
end;

procedure TPLCNumber.SetScaleProcessor(AValue: TScaleProcessor);
var
  OldValue: Double;
begin
  if AValue = PScaleProcessor then Exit;
  OldValue := Value;
  if PScaleProcessor <> nil then
    PScaleProcessor.RemoveFreeNotification(Self);

  if AValue <> nil then
    AValue.FreeNotification(Self);

  PScaleProcessor := AValue;
  if Value <> OldValue then
    NotifyChange;
end;

procedure TPLCNumber.SetMinLimit(AValue: Double);
begin
  if ([csReading, csLoading] * ComponentState = []) and (AValue >= FMaxLimit) then
    raise Exception.Create(SminMustBeLessThanMax);

  FMinLimit := AValue;
end;

procedure TPLCNumber.SetMaxLimit(AValue: Double);
begin
  if ([csReading, csLoading] * ComponentState = []) and (AValue <= FMinLimit) then
    raise Exception.Create(SmaxMustBeGreaterThanMin);

  FMaxLimit := AValue;
end;

procedure TPLCNumber.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = PScaleProcessor) then
    PScaleProcessor := nil;
  inherited Notification(AComponent, Operation);
end;

procedure TPLCNumber.Write;
var
  ToWrite: TArrayOfDouble;
begin
  SetLength(ToWrite, 1);
  ToWrite[0] := PValueRaw;
  Write(ToWrite, 1, 0);
  SetLength(ToWrite, 0);
end;

function TPLCNumber.ScanWrite: Int64;
var
  ToWrite: TArrayOfDouble;
begin
  SetLength(ToWrite, 1);
  try
    ToWrite[0] := PValueRaw;
    Result := ScanWrite(ToWrite, 1, 0);
  finally
    SetLength(ToWrite, 0);
  end;
end;

procedure TPLCNumber.RemoveScaleProcessor;
begin
  PScaleProcessor := nil;
end;


var
  BitMapperEditor: TOpenTagEditor = nil;

  { TPLCNumberMappable }

procedure TPLCNumberMappable.OpenBitMapper(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  if Assigned(BitMapperEditor) then
    BitMapperEditor(Self, Self.Owner, InsertHook, CreateProc)
  else
    raise Exception.Create('None bit mapper tool has been Assigned!');
end;

procedure SetTagBitMapper(BitMapperTool: TOpenTagEditor);
begin
  if Assigned(BitMapperEditor) then
    raise Exception.Create('A Bit Mapper editor was already Assigned.')
  else
    BitMapperEditor := BitMapperTool;
end;

end.
 

{$i ../common/language.inc}
{: @abstract(Unit that implements common types for protocol drivers and tags.)
   @author(Fabio Luis Girardi <fabio@pascalscada.com>) }
unit ProtocolTypes;


interface


uses
  Tag,
  variants,
  Classes,
  SysUtils;

type
  {$IFNDEF FPC}
  PDWord = ^Cardinal;
  {$ENDIF}

  //: Object array.
  TArrayOfObject = array of TObject;

{$IF defined(FPC_FULLVERSION) AND (FPC_FULLVERSION < 20701)}
  TFormatDateTimeOption = (fdoInterval);
  TFormatDateTimeOptions = set of TFormatDateTimeOption;
{$IFEND}

  {: Enumerates all datatypes that can be returned by a protocol driver.
  @value(ptBit       1 bit.)
  @value(ptByte      Unsigned LongInt, 8 bits sized.)
  @value(ptShortInt  Signed LongInt, 8 bits sized.)
  @value(ptWord,     Unsigned LongInt, 16 bits sized.)
  @value(ptSmallInt, Signed LongInt, 16 bits sized.)
  @value(ptDWord,    Unsigned LongInt, 32 bits sized.)
  @value(ptLongInt   Signed LongInt, 32 bits sized.)
  @value(ptFloat     Float, 32 bits sized.)
  @value(ptInt64     Signed LongInt, 64 bits sized)
  @value(ptQWord     Unsigned LongInt, 64 bits sized)
  @value(ptDouble    Float, 64 bits sized.) }
  TProtocolTagType = (
    ptUnknown,
    ptBit,
    ptShortInt,
    ptByte,
    ptSmallInt,
    ptWord,
    ptLongInt,
    ptDWord,
    ptFloat,
    ptInt64,
    ptQWord,
    ptDouble
    );

  //: Add a tag in the form editor of Delphi/Lazarus.
  TAddTagInEditorHook = procedure(Tag: TTag) of object;

  //: Creates a component in design-time.
  TCreateTagProc = function(TagClass: TComponentClass): TComponent of object;

  {: Method signature that calls the Tag Builder tool of a protocol driver
     at design-time. }
  TOpenTagEditor = procedure(Target, OwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);


  {: Record used internaly by the protocol driver to process scan read commands.
     @member Values Values read by the Scan Read.
     @member ValuesTimestamp Date/time when the values was read.
     @member ReadsOK Number of sucessfull reads.
     @member ReadFaults Number of failed reads.
     @member LastQueryResult I/O result of the last read request.
     @member Offset block index. }
  TScanReadRec = record
    Values: TArrayOfDouble;
    ValuesTimestamp: TDateTime;
    ReadsOK: Cardinal;
    ReadFaults: Cardinal;
    LastQueryResult: TProtocolIOResult;
    Offset: Longint;
    RealOffset: Longint;
  end;
  PScanReadRec = ^TScanReadRec;


  {: Record used internaly by protocol driver to execute write by scan (asynchronous).
     @member SWID Identification of the scan write command.
     @member Tag Structure with informations about the tag.
     @member ValuesToWrite Array of values to be written.
     @member WriteResult I/O result of the write command.
     @member ValueTimeStamp Date/time when the values was written. }
  TScanReqRec = record
    Tag: TTagRec;
    Values: TArrayOfDouble;
    RequestResult: TProtocolIOResult;
    ValueTimeStamp: TDateTime;
  end;
  PScanReqRec = ^TScanReqRec;

  {: Defines the function that will execute a write by scan (asynchronous)
     @param(Tag TTagRec: structure with informations about the tag.)
     @param(values TArrayOfDouble: Array of values to be written.)
     @returns(See TProtocolIOResult.) }
  TScanWriteProc = function(const Tag: TTagRec; const Values: TArrayOfDouble): TProtocolIOResult of object;

  {:
  Defines the function that will execute a write by scan (asynchronous)
  @param(Tag TTagRec: structure with informations about the tag.)
  @param(values TArrayOfDouble: Array of values to be written.)
  @returns(See TProtocolIOResult.)
  }
  TSingleScanReadProc = function(var Tag: TTagRec; var Values: TArrayOfDouble): TProtocolIOResult of object;

  //: Points to scan write function.
  PScanWriteProc = ^TScanWriteProc;

  {: Defines the procedure that will execute the scan read commands.
     @param(Sender TObject: Thread object that is calling the procedure.)
     @param(Sleep LongInt: Tells to The caller thread if it must sleep or switch to
                        another thread.) }
  TScanReadProc = procedure(Sender: TObject; var NeedSleep: Longint) of object;

  {: Defines the procedure that will get values of one tag.
     @param(Tag TTagRec: structure with informations about the tag.)
     @param(values TArrayOfDouble: Array with tag values.) }
  TGetValues = procedure(const Tag: TTagRec; var Values: TScanReadRec) of object;

  {: Procedure that gets values of a set of tags simultaneously. Used by Scan
     Update thread.
     @param(MultiValues TArrayOfScanUpdateRec. Returns information to update a set
                of tags.) }
  TGetMultipleValues = function(var MultiValues: TArrayOfScanUpdateRec): Longint of object;

  //: Tag interface
  ITagInterface = interface
    ['{188FEF6D-036D-4B01-A854-421973AA7D58}']
    //: Returns the tag value as string, including the format (if applicable), prefix and suffix.
    function GetValueAsText(Prefix, Sufix, Format: UTF8String; FormatDateTimeOptions: TFormatDateTimeOptions = []): UTF8String;
    //: Returns the tag value as variant.
    function GetVariantValue: Variant;
    //: If possible, sets a variant as tag value.
    procedure SetVariantValue(AValue: Variant);
    //: Returns @true if the variant value will be accept by tag.
    function IsValidValue(Value: Variant): Boolean;
    //: Returns the date/time of the last time wich the tag was updated.
    function GetValueTimestamp: TDateTime;
    //: Read/Set a variant value on tag.
    property ValueVariant: Variant read GetVariantValue write SetVariantValue;
    //: Returns the date/time of the last time wich the tag was updated.
    property ValueTimeStamp: TDateTime read GetValueTimestamp;
  end;


  //: Numeric tag interface.
  ITagNumeric = interface(ITagInterface)
    ['{F15D0CCC-7C97-4611-A7F4-AD1BEAFA2C96}']
    //: Returns the value processed by the linked scales or the value raw.
    function GetValue: Double;
    {: Processes the value using linked scales and writes the value processed on device.
       @param(Value Double: Value to be processed and written in device.)}
    procedure SetValue(AValue: Double);
    //: Returns the raw value.
    function GetValueRaw: Double;
    {: Write the raw value on device.
       @param(Value Double: Value to be written.) }
    procedure SetValueRaw(AValue: Double);
    //: Tag Value processed by the scales.
    property Value: Double read GetValue write SetValue;
    //: Raw value of the tag.
    property ValueRaw: Double read GetValueRaw write SetValueRaw;
  end;

  //: Text tag interface
  ITagString = interface(ITagInterface)
    ['{D2CB0A30-B93B-4D8D-BD98-248AE9FC5F22}']
    //: Returns the text value of tag.
    function GetValue: UTF8String;
    //: Writes a text value on tag.
    procedure SetValue(AValue: UTF8String);
    //: Read/write a text value on tag.
    property Value: UTF8String read GetValue write SetValue;
  end;


const
  PROTOCOL_TAG_TYPE_SIZE_IN_BITS: array [low(TProtocolTagType)..high(TProtocolTagType)] of Integer = (
    0,
    1,
    8,
    8,
    16,
    16,
    32,
    32,
    32,
    64,
    64,
    64);

  //: Identifies a message that does a scan read.
  PSM_TAGSCANREAD = 204;

  //: Identifies a message that does a scan write.
  PSM_TAGSCANWRITE = 205;

  //: Identifies a message that does a scan write.
  PSM_SINGLESCANREAD = 206;


implementation


end.
 

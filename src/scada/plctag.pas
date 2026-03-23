{$i ../common/language.inc}
{:
@abstract(Unit that implements the base of an communication tag.)
@author(Fabio Luis Girardi fabio@pascalscada.com)


****************************** History  *******************************
***********************************************************************
08/2013 - Removed Extctrls unit
@author(Juanjo Montero <juanjo.montero@gmail.com>)
***********************************************************************
}
unit PLCTag;


interface


uses
  SysUtils, Classes, Tag, ProtocolDriver, ProtocolTypes, Math;

type

  {$IFDEF PORTUGUES}
  {:
  @abstract(Classe base para todos os tags de comunicação.)
  @author(Fabio Luis Girardi fabio@pascalscada.com)
  }
  {$ELSE}
  {:
  @abstract(Base class of a communication tag.)
  @author(Fabio Luis Girardi fabio@pascalscada.com)
  }
  {$ENDIF}
  TPLCTag = class(TTag, IManagedTagInterface)
  protected
    FRawProtocolValues: TArrayOfDouble;
    FLastScanReadReqID: Int64;
    FLastScanWriteReqID: Int64;
    FTotalTime: Int64;
    FReadCount: Int64;
    FFirtsRead: Boolean;
    FProtocoloOnLoading: TProtocolDriver;

    function GetLastScanReadReqID: Int64;
    function GetLastScanWriteReqID: Int64;
    procedure RebuildTagGUID;
    function GetTagSizeOnProtocol: Longint;
  protected
    PValidTag: Boolean;
    PModified: Boolean;

    function IsMyCallBack(ACallBack: TTagCommandCallBack): Boolean; virtual;
    procedure GetNewProtocolTagSize;
    function RemainingMiliseconds: Int64; virtual;
    function RemainingMilisecondsForNextScan: Int64; virtual;
    function GetUpdateTime: Int64; virtual;
    function IsValidTag: Boolean; virtual;
    procedure SetTagValidity(TagValidity: Boolean); virtual;
    property Modified: Boolean read PModified;
  protected
    //: Stores the tag manager.
    FTagManager: TObject;
    //: Tells if the write command will be synchronous or asynchronous.
    FSyncWrites: Boolean;
    //: Stores the protocol driver used by tag.
    PProtocolDriver: TProtocolDriver;
    //: Date/time of the last scan read request of tag.
    PLastScanTimeStamp: TDateTime;
    //: Date/time of the last update of the tag value.
    PValueTimeStamp: TDateTime;
    //: Stores the I/O result of the last synchronous read command done.
    PLastSyncReadCmdResult: TProtocolIOResult;
    //: Stores the I/O result of the last synchronous write command done.
    PLastSyncWriteCmdResult: TProtocolIOResult;
    //: Stores the I/O result of the last @bold(asynchronous) read command done.
    PLastASyncReadCmdResult: TProtocolIOResult;
    //: Stores the I/O result of the last synchronous write command done.
    PLastASyncWriteCmdResult: TProtocolIOResult;
    //: Stores the datatype returned by the protocol driver.
    FProtocolTagType: TProtocolTagType;
    //: Datatype of the tag.
    FTagType: TTagType;
    //: Tells if the DWords of an Double (64 bits) will be swaped.
    FSwapDWords: Boolean;
    //: Tells if the words of an DWORD (LongInt,cardinal and float) will be swaped.
    FSwapWords: Boolean;
    //: Tells if the bytes of an WORD (SmallInt, Word) will be swaped.
    FSwapBytes: Boolean;
    //: Word size returned by the protocol and current word size of the tag in bits.
    FProtocolWordSize: Byte;
    FCurrentWordSize: Byte;

    //: Convert values comming from the PLC to the datatype of the tag.
    function PLCValuesToTagValues(Values: TArrayOfDouble; Offset: Cardinal): TArrayOfDouble; virtual;
    //: Convert values of the datatype of the tag to the datatype of the driver.
    function TagValuesToPLCValues(Values: TArrayOfDouble; Offset: Cardinal): TArrayOfDouble; virtual;
    //: Average scan update rate.
    function GetAvgUpdateRate: Double;
    //: Returns the real size of the tag.
    procedure UpdateTagSizeOnProtocol; virtual;
    //: Rebuild the tag values.
    procedure RebuildValues; virtual;
    {: Enable/disables the swap of DWords. Valid only if your tag type is pttDouble.
       @param(v Boolean: @true enables the swap, @false disables.) }
    procedure SetSwapDWords(AValue: Boolean); virtual;
    {: Enable/disables the swap of words.
       @param(v Boolean: @true enables the swap, @false disables.) }
    procedure SetSwapWords(AValue: Boolean); virtual;
    {: Enable/disables the swap of bytes.
       @param(v Boolean: @true enables the swap, @false disables.) }
    procedure SetSwapBytes(AValue: Boolean); virtual;
    //: Sets a new unique tag identification. Called by the Tag Manager.
    procedure SetGUID(AValue: AnsiString);

    //##########################################################################

    {: Enable/disables the automatic tag read.
       @param(v Boolean: @true enables, @false disables (manual).) }
    procedure SetAutoRead(AValue: Boolean); virtual;
    {: Enable/disables the automatic write of values of the tag.
       @param(v Boolean: @true automatic, @false manual.) }
    procedure SetAutoWrite(AValue: Boolean); virtual;
    {: Sets the memory address.
       @param(v Cardinal. The memory address.) }
    procedure SetMemAddress(AValue: Cardinal); virtual;
    {: Sets the File/DB that contains the mapped memory.
       @param(v Cardinal. File/DB number of your memory.) }
    procedure SetMemFileDB(AValue: Cardinal); virtual;
    {: Sets the function to be used to read the memory.
       @param(v Cardinal. Function number to read the memory.) }
    procedure SetMemReadFunction(AValue: Cardinal); virtual;
    {: Sets the function to be used to write values on memory.
       @param(v Cardinal. Function number to write values on memory.) }
    procedure SetMemWriteFunction(AValue: Cardinal); virtual;
    {: Sets the sub-element of the memory being mapped.
       @param(v Cardinal. The sub-element number of the memory being mapped.) }
    procedure SetMemSubElement(AValue: Cardinal); virtual;
    {: Sets the long address (text) of the tag.
       @param(v String. The long address of the tag (text).) }
    procedure SetPath(AValue: AnsiString); virtual;
    {: Sets the address of device being mapped.
       @param(v Cardinal. The device address.) }
    procedure SetPLCStation(AValue: Cardinal); virtual;
    {: Sets the Rack of the device being mapped.
       @param(v Cardinal. The device Rack number.) }
    procedure SetPLCHack(AValue: Cardinal); virtual;
    {: Sets the Slot number of the device being mapped.
       @param(v Cardinal. The Slot number.) }
    procedure SetPLCSlot(AValue: Cardinal); virtual;
    {: Sets the scan rate of the tag in milliseconds.
       @param(v Cardinal. Scan rate in milliseconds.) }
    procedure SetRefreshTime(AValue: TRefreshTime); virtual;
    {: Sets the protocol driver to be used the read/write values on device.
       @param(p TProtocolDriver. The protocol driver to be used to read/write values of your device.) }
    procedure SetProtocolDriver(AValue: TProtocolDriver); virtual;
    //: Sets the datatype of the tag. @seealso(TTagType)
    procedure SetTagType(AValue: TTagType); virtual;

    //##########################################################################

    //: Procedure called by the protocol driver to update tag values.
    procedure TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDateTime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint); virtual;
    {: Returns a structure with all informations about the tag.
       @seealso(TTagRec) }
    procedure BuildTagRec(out TagObj: TTagRec; Count, Offset: Longint);
    //: Request a update of tag values.
    function ScanRead: Int64; virtual;
    {: Write values of the tag on your device @bold(asynchronous).
       @param(Values TArrayOfDouble: Array of values to be written.)
       @param(Count Cardinal: How many values will be written.)
       @param(Offset Cardinal: Tells offset after the address where the values will be written.) }
    function ScanWrite(Values: TArrayOfDouble; Count, Offset: Cardinal; const IgnoreAutoWrite: Boolean = False): Int64; virtual; abstract;
    //: Request a @bold(synchronous) read of the tag value.
    procedure Read; virtual; abstract;
    {: Write values of the tag on your device @bold(synchronous).
       @param(Values TArrayOfDouble: Array of values to be written.)
       @param(Count Cardinal: How many values will be written.)
       @param(Offset Cardinal: Tells offset after the address where the values will be written.) }
    procedure Write(Values: TArrayOfDouble; Count, Offset: Cardinal); overload; virtual; abstract;

    function GetLastAsyncReadStatus: TProtocolIOResult; virtual;
    function GetLastAsyncWriteStatus: TProtocolIOResult; virtual;
    function GetLastSyncReadStatus: TProtocolIOResult; virtual;
    function GetLastSyncWriteStatus: TProtocolIOResult; virtual;

    //: @exclude
    procedure Loaded; override;

    function GetLastUpdateTimestamp: TDateTime; virtual;

    //: @seealso(TTag.AutoRead)
    property AutoRead write SetAutoRead default True;
    //: @seealso(TTag.AutoWrite)
    property AutoWrite write SetAutoWrite default True;
    //: @seealso(TTag.CommReadErrors)
    property CommReadErrors default 0;
    //: @seealso(TTag.CommReadsOK)
    property CommReadsOK nodefault;
    //: @seealso(TTag.CommWriteErrors)
    property CommWriteErrors default 0;
    //: @seealso(TTag.CommWritesOK)
    property CommWritesOk nodefault;
    //: @seealso(TTag.PLCRack)
    property PLCRack write SetPLCHack nodefault;
    //: @seealso(TTag.PLCSlot)
    property PLCSlot write SetPLCSlot nodefault;
    //: @seealso(TTag.PLCStation)
    property PLCStation write SetPLCStation nodefault;
    //: @seealso(TTag.MemFile_DB)
    property MemFile_DB write SetMemFileDB nodefault;
    //: @seealso(TTag.MemAddress)
    property MemAddress write SetMemAddress nodefault;
    //: @seealso(TTag.MemSubElement)
    property MemSubElement write SetMemSubElement nodefault;
    //: @seealso(TTag.MemReadFunction)
    property MemReadFunction write SetMemReadFunction nodefault;
    //: @seealso(TTag.MemWriteFunction)
    property MemWriteFunction write SetMemWriteFunction nodefault;
    //: @seealso(TTag.Retries)
    property Retries write PRetries default 1;
    //: @seealso(TTag.RefreshTime)
    property RefreshTime write SetRefreshTime stored False;
    //: @seealso(TTag.ScanRate)
    property UpdateTime write SetRefreshTime default 1000;
    //: @seealso(TTag.Size)
    property Size nodefault;
    //: @seealso(TTag.LongAddress)
    property LongAddress write SetPath nodefault;
    {: Protocol driver used by tag to read/write values on your device.
       @seealso(TProtocolDriver) }
    property ProtocolDriver: TProtocolDriver read PProtocolDriver write SetProtocolDriver;
    //: Date/time of the last update of the tag value.
    property ValueTimestamp: TDateTime read PValueTimeStamp;
    //: If @true, the write of values will be @bold(synchronous).
    property SyncWrites: Boolean read FSyncWrites write FSyncWrites default False;
    //: Datatype of the tag.
    property TagType: TTagType read FTagType write SetTagType default pttDefault;
    //: Tells if the bytes of an WORD (SmallInt, Word) will be swaped.
    property SwapBytes: Boolean read FSwapBytes write SetSwapBytes default False;
    //: Tells if the words of an DWORD (LongInt, cardinal and float) will be swaped.
    property SwapWords: Boolean read FSwapWords write SetSwapWords default False;
    //: Tells if the DWords of an Double (float 64 bits) will be swaped.
    property SwapDWords: Boolean read FSwapDWords write SetSwapDWords default False;
    //: Tells the real size of the tag on protocol driver.
    property TagSizeOnProtocol: Longint read GetTagSizeOnProtocol;
    //: Average update rate of the tag.
    property AvgUpdateRate: Double read GetAvgUpdateRate;
    //: Last ScanRead request id.
    property LastScanReadReqID: Int64 read GetLastScanReadReqID;
    //: Last ScanWrite request id.
    property LastScanWriteReqID: Int64 read GetLastScanWriteReqID;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    constructor CreateWithGUID(AOwner: TComponent; AGuid: string); virtual;
    //: Called when the protocol driver is being destroyed.
    procedure RemoveDriver;
  published
    //: Tells the unique tag identification.
    property TagGUID: AnsiString read PGUID write SetGUID;
    {: I/O result of the last @bold(synchronous) read done.
       @seealso(TProtocolIOResult) }
    property LastSyncReadStatus: TProtocolIOResult read GetLastSyncReadStatus;
    {: I/O result of the last @bold(synchronous) write done.
       @seealso(TProtocolIOResult) }
    property LastSyncWriteStatus: TProtocolIOResult read GetLastSyncWriteStatus;
    {: I/O result of the last @bold(asynchronous) read done.
       @seealso(TProtocolIOResult) }
    property LastASyncReadStatus: TProtocolIOResult read GetLastAsyncReadStatus;
    {: I/O result of the last @bold(asynchronous) write done.
       @seealso(TProtocolIOResult) }
    property LastASyncWriteStatus: TProtocolIOResult read PLastASyncWriteCmdResult;
  end;

  TManagedTags = array of TPLCTag;

  TTagMananger = class
  private
    FTags: TManagedTags;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddTag(Tag: TPLCTag);
    procedure RemoveTag(Tag: TPLCTag);
  end;


function GetTagManager: TTagMananger;


implementation


uses
  hsutils,
  hsstrings,
  dateutils,
  crossdatetime;


constructor TPLCTag.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PValueTimeStamp := CrossNow;
  PAutoRead := True;
  PAutoWrite := True;
  PValidTag := False;
  PCommReadErrors := 0;
  PCommReadOK := 0;
  PCommWriteErrors := 0;
  PCommWriteOk := 0;
  PRack := 0;
  PSlot := 0;
  PStation := 0;
  PFile_DB := 0;
  PAddress := 0;
  PSubElement := 0;
  PSize := 1;
  PPath := '';
  PReadFunction := 0;
  PWriteFunction := 0;
  PRetries := 1;
  PUpdateTime := 1000;
  FTagType := pttDefault;
  FSwapBytes := False;
  FSwapWords := False;
  FSwapDWords := False;
  FCurrentWordSize := 1;
  FProtocolWordSize := 1;
  FFirtsRead := True;
  FTotalTime := 0;
  PProtocolDriver := nil;
  FTagManager := GetTagManager;
  SetLength(FRawProtocolValues, 1);
end;

destructor TPLCTag.Destroy;
begin
  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);
  PProtocolDriver := nil;
  (FTagManager as TTagMananger).RemoveTag(Self);
  inherited Destroy;
end;

constructor TPLCTag.CreateWithGUID(AOwner: TComponent; AGuid: string);
begin
  Create(AOwner);
  // EConvError should abort everything
  StringToGUID(AGuid);
  Self.PGUID := UpperCase(AGuid);
  TTagMananger(FTagManager).AddTag(Self);
end;

procedure TPLCTag.RemoveDriver;
begin
  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);
  PProtocolDriver := nil;
end;

procedure TPLCTag.SetProtocolDriver(AValue: TProtocolDriver);
begin
  // if the tag is being loaded.
  if ([csReading, csLoading] * ComponentState <> []) then
  begin
    FProtocoloOnLoading := AValue;
    Exit;
  end;

  if AValue = PProtocolDriver then Exit;

  // removes the link with the old driver.
  if (PProtocolDriver <> nil) then
  begin
    // removes the tag of the scan of the driver.
    if PAutoRead then
      PProtocolDriver.RemoveTag(Self);
    PProtocolDriver := nil;
  end;

  // sets the new protocol driver.
  if (AValue <> nil) then
  begin
    // add the tag to the scan of protocolo driver.
    PProtocolDriver := AValue;
    GetNewProtocolTagSize;

    if Self.PAutoRead then
      AValue.AddTag(Self);
  end;
end;

procedure TPLCTag.TagCommandCallBack(const ReqID: Longword; Values: TArrayOfDouble; ValuesTimeStamp: TDateTime; TagCommand: TTagCommand; LastResult: TProtocolIOResult; Offset: Longint);
var
  i: Longint;
  AOffset: Longint;
begin
  if (not FFirtsRead) and (TagCommand = tcScanRead) and (LastResult = ioOk) and (ValuesTimeStamp <> PValueTimeStamp) then
  begin
    Inc(FTotalTime, MilliSecondsBetween(ValuesTimeStamp, PValueTimeStamp));
    Inc(FReadCount);
  end;

  case TagCommand of
    tcScanRead: PLastScanTimeStamp := CrossNow;
    tcSingleScanRead: begin
                        PLastScanTimeStamp := CrossNow;
                        FLastScanReadReqID := ReqID;
                      end;
    tcScanWrite: FLastScanWriteReqID := ReqID;
  end;

  if (LastResult = ioOk) then
    FFirtsRead := False;

  if LastResult in [ioOk, ioNullDriver] then
  begin
    if FCurrentWordSize >= FProtocolWordSize then
      begin
        AOffset := (FCurrentWordSize div FProtocolWordSize) * Offset;
      end
    else
      begin
        AOffset := (Offset * FCurrentWordSize) div FProtocolWordSize;
      end;

    for i := 0 to High(Values) do
      if (i + AOffset) <= High(FRawProtocolValues) then
        FRawProtocolValues[i + AOffset] := Values[i];
  end;
end;

procedure TPLCTag.SetAutoRead(AValue: Boolean);
begin
  if PAutoRead = AValue then Exit;

  PAutoRead := AValue;

  if (PProtocolDriver <> nil) then
  begin
    if AValue then
      begin
        PLastScanTimeStamp := CrossNow;
        PProtocolDriver.AddTag(Self);
      end
    else
      PProtocolDriver.RemoveTag(Self);
  end;
end;

procedure TPLCTag.SetAutoWrite(AValue: Boolean);
begin
  PAutoWrite := AValue;
end;

procedure TPLCTag.SetPLCHack(AValue: Cardinal);
begin
  if PRack = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PRack := AValue;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;
end;

procedure TPLCTag.SetPLCSlot(AValue: Cardinal);
begin
  if PSlot = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PSlot := AValue;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;
end;

procedure TPLCTag.SetPLCStation(AValue: Cardinal);
begin
  if PStation = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PStation := AValue;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;
end;

procedure TPLCTag.SetMemFileDB(AValue: Cardinal);
begin
  if PFile_DB = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PFile_DB := AValue;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;
end;

procedure TPLCTag.SetMemAddress(AValue: Cardinal);
begin
  if PAddress = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PAddress := AValue;

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);
end;

procedure TPLCTag.SetMemSubElement(AValue: Cardinal);
begin
  if PSubElement = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PSubElement := AValue;

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);
end;

procedure TPLCTag.SetMemReadFunction(AValue: Cardinal);
begin
  if PReadFunction = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PReadFunction := AValue;

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);
end;

procedure TPLCTag.SetMemWriteFunction(AValue: Cardinal);
begin
  if PWriteFunction = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PWriteFunction := AValue;

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);
end;

procedure TPLCTag.SetPath(AValue: AnsiString);
begin
  if PPath = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead and (PPath.Trim <> '') then
    PProtocolDriver.RemoveTag(Self);

  PPath := AValue;

  if ([csReading, csLoading] * ComponentState = []) then
    GetNewProtocolTagSize;

  if (PProtocolDriver <> nil) and PAutoRead and (PPath.Trim <> '') then
    PProtocolDriver.AddTag(Self);
end;

procedure TPLCTag.SetRefreshTime(AValue: TRefreshTime);
begin
  if PUpdateTime = AValue then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  PUpdateTime := AValue;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);
end;

procedure TPLCTag.BuildTagRec(out TagObj: TTagRec; Count, Offset: Longint);
begin
  TagObj.Rack := PRack;
  TagObj.Slot := PSlot;
  TagObj.Station := PStation;
  TagObj.File_DB := PFile_DB;
  TagObj.Address := PAddress;
  TagObj.SubElement := PSubElement;
  Count := ifthen(Count = 0, PSize, Count);
  TagObj.Count := Count;

  // calculate the real size and the real offset depending
  // of the tag datatype and of protocol datatype.
  if FCurrentWordSize >= FProtocolWordSize then
    begin
      TagObj.Size := (FCurrentWordSize div FProtocolWordSize) * Count;
      TagObj.Offset := (FCurrentWordSize div FProtocolWordSize) * Offset;
    end
  else
    begin
      TagObj.Offset := (Offset * FCurrentWordSize) div FProtocolWordSize;
      TagObj.Size := (((Offset * FCurrentWordSize) + (Count * FCurrentWordSize)) div FProtocolWordSize) + ifthen((((Offset * FCurrentWordSize) + (Count * FCurrentWordSize)) mod FProtocolWordSize) <> 0, 1, 0) - TagObj.Offset;
    end;

  TagObj.RealOffset := Offset;

  TagObj.Path := PPath;
  TagObj.ReadFunction := PReadFunction;
  TagObj.WriteFunction := PWriteFunction;
  TagObj.Retries := PRetries;
  TagObj.UpdateTime := PUpdateTime;
  TagObj.CallBack := @TagCommandCallBack;
end;

function TPLCTag.ScanRead: Int64;
begin
  Result := -1;
end;

function TPLCTag.GetLastAsyncReadStatus: TProtocolIOResult;
begin
  Result := PLastASyncReadCmdResult;
end;

function TPLCTag.GetLastAsyncWriteStatus: TProtocolIOResult;
begin
  Result := PLastASyncWriteCmdResult;
end;

function TPLCTag.GetLastSyncReadStatus: TProtocolIOResult;
begin
  Result := PLastSyncReadCmdResult;
end;

function TPLCTag.GetLastSyncWriteStatus: TProtocolIOResult;
begin
  Result := PLastSyncWriteCmdResult;
end;

procedure TPLCTag.GetNewProtocolTagSize;
begin
  if PProtocolDriver = nil then
  begin
    FProtocolWordSize := 1;
    Exit;
  end;

  FProtocolWordSize := PProtocolDriver.SizeOfTag(Self, False, FProtocolTagType);
  if FTagType = pttDefault then
    FCurrentWordSize := FProtocolWordSize;

  UpdateTagSizeOnProtocol;
end;

function TPLCTag.GetTagSizeOnProtocol: Longint;
begin
  Result := Length(FRawProtocolValues);
end;

function TPLCTag.GetLastScanReadReqID: Int64;
begin
  Result := FLastScanReadReqID;
end;

function TPLCTag.GetLastScanWriteReqID: Int64;
begin
  Result := FLastScanWriteReqID;
end;

procedure TPLCTag.RebuildTagGUID;
var
  AGUID: TGuid;
begin
  CreateGUID(AGUID);
  PGUID := UpperCase(GUIDToString(AGUID));
end;

function TPLCTag.IsMyCallBack(ACallBack: TTagCommandCallBack): Boolean;
begin
  Result := (TMethod(ACallBack).Data = Pointer(Self));
end;

procedure TPLCTag.Loaded;
var
  OldDriver: TProtocolDriver;
begin
  inherited Loaded;

  ProtocolDriver := FProtocoloOnLoading;

  if PProtocolDriver = nil then
    begin
      OldDriver := PProtocolDriver;
      PProtocolDriver := TProtocolDriver(1);
      FCurrentWordSize := FProtocolWordSize;
      UpdateTagSizeOnProtocol;
      PProtocolDriver := OldDriver;
    end
  else
    begin
      UpdateTagSizeOnProtocol;
    end;

  RebuildValues;

  with FTagManager as TTagMananger do
    AddTag(Self);
end;

function TPLCTag.GetLastUpdateTimestamp: TDateTime;
begin
  Result := PValueTimeStamp;
end;

procedure TPLCTag.SetGUID(AValue: AnsiString);
begin
  if ComponentState * [csReading] = [] then Exit;
  PGUID := UpperCase(AValue);
end;

procedure TPLCTag.SetTagType(AValue: TTagType);
begin
  if AValue = FTagType then Exit;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.RemoveTag(Self);

  FTagType := AValue;

  if [csReading, csLoading] * ComponentState = [] then
  begin
    UpdateTagSizeOnProtocol;
    RebuildValues;
  end;

  if (PProtocolDriver <> nil) and PAutoRead then
    PProtocolDriver.AddTag(Self);
end;

procedure TPLCTag.UpdateTagSizeOnProtocol;
var
  ASize: Longint;
begin
  if PProtocolDriver = nil then
    Exit;

  case FTagType of
    pttDefault: FCurrentWordSize := FProtocolWordSize;
    pttShortInt,
    pttByte:    FCurrentWordSize := 8;
    pttSmallInt,
    pttWord:    FCurrentWordSize := 16;
    pttLongInt,
    pttDWord,
    pttFloat:   FCurrentWordSize := 32;
    pttDouble,
    pttQWord,
    pttInt64:   FCurrentWordSize := 64;
  end;

  if FProtocolWordSize = 0 then
    FProtocolWordSize := 1;

  if FCurrentWordSize >= FProtocolWordSize then
    begin
      ASize := (FCurrentWordSize div FProtocolWordSize) * PSize;
    end
  else
    begin
      ASize := ((PSize * FCurrentWordSize) div FProtocolWordSize) + ifthen(((PSize * FCurrentWordSize) mod FProtocolWordSize) <> 0, 1, 0);
    end;

  if Length(FRawProtocolValues) <> ASize then
    SetLength(FRawProtocolValues, ASize);
end;

procedure TPLCTag.SetSwapDWords(AValue: Boolean);
begin
  if AValue = FSwapDWords then Exit;

  FSwapDWords := AValue;

  if [csReading, csLoading] * ComponentState <> [] then Exit;

  RebuildValues;
end;

procedure TPLCTag.SetSwapWords(AValue: Boolean);
begin
  if AValue = FSwapWords then Exit;

  FSwapWords := AValue;

  if [csReading, csLoading] * ComponentState <> [] then Exit;

  RebuildValues;
end;

procedure TPLCTag.SetSwapBytes(AValue: Boolean);
begin
  if AValue = FSwapBytes then Exit;

  FSwapBytes := AValue;

  if [csReading, csLoading] * ComponentState <> [] then Exit;

  RebuildValues;
end;

procedure TPLCTag.RebuildValues;
begin
  TagCommandCallBack(0, FRawProtocolValues, ValueTimestamp, tcInternalUpdate, ioOk, 0);
end;

function TPLCTag.PLCValuesToTagValues(Values: TArrayOfDouble; Offset: Cardinal): TArrayOfDouble;
var
  PtrByte: PByte;
  PtrByteWalker: PByte;
  PtrWordWalker: PWord;
  PtrDWordWalker: PDWord;
  PtrQWordWalker: PQWord;

  AreaSize: Longint;
  AreaIndex: Longint;
  ValueIndex: Longint;

  DWordAux: Cardinal;
  WordAux: Word;
  ByteAux: Byte;

  PtrByte1: PByte;
  PtrByte2: PByte;
  PtrWord1: PWord;
  PtrWord2: PWord;
  PtrDWord1: PDWord;
  PtrDWord2: PDWord;
  ProtocolSize: Integer;
  ATagSize: Integer;
  ResIndex: Integer;

  procedure ResetPointers;
  begin
    PtrByteWalker := PtrByte;
    PtrWordWalker := PWord(PtrByte);
    PtrDWordWalker := PDWord(PtrByte);
    PtrQWordWalker := PQWord(PtrByte);
  end;

  procedure AddToResult(ValueToAdd: Double; var Result: TArrayOfDouble);
  var
    i: Longint;
  begin
    //i:=Length(Result);
    //SetLength(Result,i+1);
    Result[ResIndex] := ValueToAdd;
    ResIndex := ResIndex + 1;
  end;

begin
  ProtocolSize := PROTOCOL_TAG_TYPE_SIZE_IN_BITS[FProtocolTagType];
  ATagSize := TagSizeInBits(FTagType, ProtocolSize);
  ResIndex := 0;
  //if (FTagType=pttDefault) OR
  //   ((FProtocolTagType=ptByte) AND (FTagType=pttByte)) OR
  //   ((FProtocolTagType=ptShortInt) AND (FTagType=pttShortInt)) OR
  //   ((FProtocolTagType=ptWord) AND (FTagType=pttWord)) OR
  //   ((FProtocolTagType=ptSmallInt) AND (FTagType=pttSmallInt)) OR
  //   ((FProtocolTagType=ptDWord) AND (FTagType=pttDWord)) OR
  //   ((FProtocolTagType=ptLongInt) AND (FTagType=pttLongInt)) OR
  //   ((FProtocolTagType=ptFloat) AND (FTagType=pttFloat)) Or
  //   ((FProtocolTagType=ptInt64) AND (FTagType=pttInt64)) Or
  //   ((FProtocolTagType=ptQWord) AND (FTagType=pttQWord)) Or
  //   ((FProtocolTagType=ptDouble) AND (FTagType=pttDouble))
  if (ProtocolSize = ATagSize) or (FProtocolTagType = ptUnknown) then
  begin
    Result := Values;
    Exit;
  end;

  ResIndex := 0;
  SetLength(Result, ((Length(Values) * ProtocolSize) div ATagSize) + ifthen(((Length(Values) * ProtocolSize) mod ATagSize) <> 0, 1, 0));

  case FProtocolTagType of
    ptBit:      AreaSize := Length(Values) div 8 + ifthen((Length(Values) mod 8) <> 0, 1, 0);
    ptByte,
    ptShortInt: AreaSize := Length(Values);
    ptWord,
    ptSmallInt: AreaSize := Length(Values) * 2;
    ptDWord,
    ptLongInt,
    ptFloat:    AreaSize := Length(Values) * 4;
    ptQWord,
    ptInt64,
    ptDouble:   AreaSize := Length(Values) * 8;
  end;

  GetMem(PtrByte, AreaSize);
  FillByte(PtrByte^, AreaSize, 0);
  ResetPointers;

  //move os dados para area de trabalho.
  //move data to work memory.
  ValueIndex := 0;
  case FProtocolTagType of
    ptBit:  while ValueIndex < Length(Values) do
              begin
                if Values[ValueIndex] <> 0 then
                  PtrByteWalker^ := PtrByteWalker^ + (Power(2, ValueIndex mod 8) and $FF);

                Inc(ValueIndex);
                if (ValueIndex mod 8) = 0 then
                  Inc(PtrByteWalker);
              end;
    ptByte,
    ptShortInt: while ValueIndex < Length(Values) do
                  begin
                    PtrByteWalker^ := trunc(Values[ValueIndex]) and $FF;
                    Inc(ValueIndex);
                    Inc(PtrByteWalker);
                  end;
    ptWord,
    ptSmallInt: while ValueIndex < Length(Values) do
                  begin
                    PtrWordWalker^ := trunc(Values[ValueIndex]) and $FFFF;
                    Inc(ValueIndex);
                    Inc(PtrWordWalker);
                  end;
    ptDWord,
    ptLongInt,
    ptFloat:  while ValueIndex < Length(Values) do
                begin
                  if FProtocolTagType = ptFloat then
                    PSingle(PtrDWordWalker)^ := Values[ValueIndex]
                  else
                    PtrDWordWalker^ := trunc(Values[ValueIndex]) and $FFFFFFFF;

                  Inc(ValueIndex);
                  Inc(PtrDWordWalker);
                end;
    ptQWord,
    ptInt64,
    ptDouble: while ValueIndex < Length(Values) do
                begin
                  if FProtocolTagType = ptDouble then
                    PDouble(PtrQWordWalker)^ := Values[ValueIndex]
                  else
                    PtrQWordWalker^ := trunc(Values[ValueIndex]);

                  Inc(ValueIndex);
                  Inc(PtrQWordWalker);
                end;
  end;

  ResetPointers;
  AreaIndex := 0;

  //faz as inversoes caso necessário e move os dados para o resultado
  //swap bytes and words (if necessary)
  case FTagType of
    pttShortInt,
    pttByte:  begin
                Inc(PtrByteWalker, ((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize);
                Inc(AreaIndex, (((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize));
                while AreaIndex < AreaSize do
                begin
                  if FTagType = pttShortInt then
                    AddToResult(PShortInt(PtrByteWalker)^, Result)
                  else
                    AddToResult(PtrByteWalker^, Result);
                  Inc(AreaIndex);
                  Inc(PtrByteWalker);
                end;
              end;
    pttSmallInt,
    pttWord:  begin
                Inc(PtrWordWalker, ((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize);
                Inc(AreaIndex, (((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize) * 2);
                while AreaIndex < AreaSize do
                begin
                  if FSwapBytes then
                  begin
                    PtrByte1 := Pbyte(PtrWordWalker);
                    PtrByte2 := PtrByte1;
                    Inc(PtrByte2);
                    ByteAux := PtrByte1^;
                    PtrByte1^ := PtrByte2^;
                    PtrByte2^ := ByteAux;
                  end;
                  if FTagType = pttSmallInt then
                    AddToResult(PSmallInt(PtrWordWalker)^, Result)
                  else
                    AddToResult(PtrWordWalker^, Result);

                  Inc(AreaIndex, 2);
                  Inc(PtrWordWalker);
                end;
              end;
    pttLongInt,
    pttDWord,
    pttFloat: begin
                Inc(PtrDWordWalker, ((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize);
                Inc(AreaIndex, (((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize) * 4);
                while AreaIndex < AreaSize do
                begin
                  if FSwapWords or FSwapBytes then
                  begin
                    PtrWord1 := PWord(PtrDWordWalker);
                    PtrWord2 := PtrWord1;
                    Inc(PtrWord2);
                  end;

                  if FSwapWords then
                  begin
                    WordAux := PtrWord1^;
                    PtrWord1^ := PtrWord2^;
                    PtrWord2^ := WordAux;
                  end;

                  if FSwapBytes then
                  begin
                    PtrByte1 := Pbyte(PtrWord1);
                    PtrByte2 := PtrByte1;
                    Inc(PtrByte2);
                    ByteAux := PtrByte1^;
                    PtrByte1^ := PtrByte2^;
                    PtrByte2^ := ByteAux;

                    PtrByte1 := Pbyte(PtrWord2);
                    PtrByte2 := PtrByte1;
                    Inc(PtrByte2);
                    ByteAux := PtrByte1^;
                    PtrByte1^ := PtrByte2^;
                    PtrByte2^ := ByteAux;
                  end;

                  case FTagType of
                    pttDWord:   AddToResult(PtrDWordWalker^, Result);
                    pttLongInt: AddToResult(PLongInt(PtrDWordWalker)^, Result);
                    pttFloat:   begin
                                  if IsNan(PSingle(PtrDWordWalker)^) or IsInfinite(PSingle(PtrDWordWalker)^) then
                                    SetExceptionMask([exInvalidOp, exDenormalized, {exZeroDivide,} exOverflow, exUnderflow, exPrecision]);
                                  AddToResult(PSingle(PtrDWordWalker)^, Result);
                                end;
                  end;
                  Inc(AreaIndex, 4);
                  Inc(PtrDWordWalker);
                end;
              end;
    pttInt64,
    pttQWord,
    pttDouble:  begin
                  Inc(PtrQWordWalker, ((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize);
                  Inc(AreaIndex, (((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize) * 8);
                  while AreaIndex < AreaSize do
                  begin
                    if FSwapDWords then
                    begin
                      //initialize Dword Pointers
                      PtrDWord1 := PDWord(PtrQWordWalker);
                      PtrDWord2 := PtrDWord1;
                      Inc(PtrDWord2);

                      //swap dwords
                      DWordAux := PtrDWord1^;
                      PtrDWord1^ := PtrDWord2^;
                      PtrDWord2^ := DWordAux;
                    end;

                    if FSwapWords then
                    begin
                      //initializes DWord Pointers
                      PtrDWord1 := PDWord(PtrQWordWalker);
                      PtrDWord2 := PtrDWord1;
                      Inc(PtrDWord2);

                      //initializa first 2 word pointers
                      PtrWord1 := PWord(PtrDWord1);
                      PtrWord2 := PtrWord1;
                      Inc(PtrWord2);

                      //swap words
                      WordAux := PtrWord1^;
                      PtrWord1^ := PtrWord2^;
                      PtrWord2^ := WordAux;

                      //initializes next 2 word pointers
                      PtrWord1 := PWord(PtrDWord2);
                      PtrWord2 := PtrWord1;
                      Inc(PtrWord2);

                      //swap words.
                      WordAux := PtrWord1^;
                      PtrWord1^ := PtrWord2^;
                      PtrWord2^ := WordAux;
                    end;

                    if FSwapBytes then
                    begin
                      // initializes DWord Pointers
                      PtrDWord1 := PDWord(PtrQWordWalker);
                      PtrDWord2 := PtrDWord1;
                      Inc(PtrDWord2);

                      // initializes first 2 word pointers
                      PtrWord1 := PWord(PtrDWord1);
                      PtrWord2 := PtrWord1;
                      Inc(PtrWord2);

                      // initialize bytes 1 and 2
                      PtrByte1 := Pbyte(PtrWord1);
                      PtrByte2 := PtrByte1;
                      Inc(PtrByte2);

                      // swap bytes
                      ByteAux := PtrByte1^;
                      PtrByte1^ := PtrByte2^;
                      PtrByte2^ := ByteAux;

                      // initialize bytes 3 and 4
                      PtrByte1 := Pbyte(PtrWord2);
                      PtrByte2 := PtrByte1;
                      Inc(PtrByte2);

                      // swap bytes
                      ByteAux := PtrByte1^;
                      PtrByte1^ := PtrByte2^;
                      PtrByte2^ := ByteAux;

                      // initializes next 2 word pointers
                      PtrWord1 := PWord(PtrDWord2);
                      PtrWord2 := PtrWord1;
                      Inc(PtrWord2);

                      // initialize bytes 5 and 6
                      PtrByte1 := Pbyte(PtrWord1);
                      PtrByte2 := PtrByte1;
                      Inc(PtrByte2);

                      // swap bytes
                      ByteAux := PtrByte1^;
                      PtrByte1^ := PtrByte2^;
                      PtrByte2^ := ByteAux;

                      // initialize bytes 7 and 8
                      PtrByte1 := Pbyte(PtrWord2);
                      PtrByte2 := PtrByte1;
                      Inc(PtrByte2);

                      // swap bytes
                      ByteAux := PtrByte1^;
                      PtrByte1^ := PtrByte2^;
                      PtrByte2^ := ByteAux;
                    end;

                    case FTagType of
                      pttQWord:   AddToResult(PtrQWordWalker^, Result);
                      pttInt64:   AddToResult(PInt64(PtrQWordWalker)^, Result);
                      pttDouble:  begin
                                    if IsNan(PDouble(PtrQWordWalker)^) or IsInfinite(PDouble(PtrQWordWalker)^) then
                                      SetExceptionMask([exInvalidOp, exDenormalized, {exZeroDivide,} exOverflow, exUnderflow, exPrecision]);
                                    AddToResult(PDouble(PtrQWordWalker)^, Result);
                                  end;
                    end;

                    Inc(AreaIndex, 8);
                    Inc(PtrQWordWalker);
                  end;
                end;
  end;
  Freemem(PtrByte);
end;

function TPLCTag.TagValuesToPLCValues(Values: TArrayOfDouble; Offset: Cardinal): TArrayOfDouble;
var
  PtrByte: PByte;
  PtrByteWalker: PByte;
  PtrWordWalker: PWord;
  PtrDWordWalker: PDWord;
  PtrQWordWalker: PQWord;
  AreaSize: Longint;
  AreaIndex: Longint;
  ValueIndex: Longint;
  DWordAux: Cardinal;
  WordAux: Word;
  ByteAux: Byte;
  PtrByte1: PByte;
  PtrByte2: PByte;
  PtrWord1: PWord;
  PtrWord2: PWord;
  PtrDWord1: PDWord;
  PtrDWord2: PDWord;
  BitAux: Longint;
  ProtocolOffSet,
  ProtocolSize,
  Bit: Longint;

  procedure ResetPointers;
  begin
    PtrByteWalker := PtrByte;
    PtrWordWalker := PWord(PtrByte);
    PtrDWordWalker := PDWord(PtrByte);
    PtrQWordWalker := PQWord(PtrByte);
  end;

  procedure AddToResult(ValueToAdd: Double; var Result: TArrayOfDouble);
  var
    i: Longint;
  begin
    i := Length(Result);
    SetLength(Result, i + 1);
    Result[i] := ValueToAdd;
  end;

begin
  if (FProtocolTagType = ptUnknown) then
  begin
    Result := Values;
    Exit;
  end;

  if (FTagType = pttDefault)
    or ((FProtocolTagType = ptByte) and (FTagType = pttByte))
    or ((FProtocolTagType = ptShortInt) and (FTagType = pttShortInt))
    or ((FProtocolTagType = ptWord) and (FTagType = pttWord))
    or ((FProtocolTagType = ptSmallInt) and (FTagType = pttSmallInt))
    or ((FProtocolTagType = ptDWord) and (FTagType = pttDWord))
    or ((FProtocolTagType = ptLongInt) and (FTagType = pttLongInt))
    or ((FProtocolTagType = ptFloat) and (FTagType = pttFloat))
    or ((FProtocolTagType = ptDouble) and (FTagType = pttDouble)) then
  begin
    Result := Values;
    Exit;
  end;

  // calculate how many bytes must be allocated
  SetLength(Result, 0);

  if FCurrentWordSize >= FProtocolWordSize then
    begin
      ProtocolSize := (FCurrentWordSize div FProtocolWordSize) * Length(Values);
      ProtocolOffSet := (FCurrentWordSize div FProtocolWordSize) * Offset;
    end
  else
    begin
      ProtocolOffSet := (Offset * FCurrentWordSize) div FProtocolWordSize;
      ProtocolSize := (((Offset * FCurrentWordSize) + (Length(Values) * FCurrentWordSize)) div FProtocolWordSize) + ifthen((((Offset * FCurrentWordSize) + (Length(Values) * FCurrentWordSize)) mod FProtocolWordSize) <> 0, 1, 0) - ProtocolOffSet;
    end;

  case FProtocolTagType of
    ptBit:      AreaSize := ProtocolSize div 8;
    ptByte,
    ptShortInt: AreaSize := ProtocolSize;
    ptWord,
    ptSmallInt: AreaSize := ProtocolSize * 2;
    ptDWord,
    ptLongInt,
    ptFloat:    AreaSize := ProtocolSize * 4;
    ptQWord,
    ptInt64,
    ptDouble:   AreaSize := ProtocolSize * 8;
  end;

  GetMem(PtrByte, AreaSize);
  ResetPointers;

  // move the raw values to the work memory to don't loose data
  ValueIndex := 0;
  case FProtocolTagType of
    ptBit:  begin
              while ValueIndex < ProtocolSize do
              begin
                Bit := (ValueIndex + ProtocolOffSet) mod 8;

                PtrByteWalker^ := PtrByteWalker^ or (trunc(FRawProtocolValues[ValueIndex + ProtocolOffSet]) shl Bit);
                if Bit >= 7 then
                  Inc(PtrByteWalker);
                Inc(ValueIndex);
              end;
            end;
    ptByte,
    ptShortInt: while ValueIndex < ProtocolSize do
                  begin
                    PtrByteWalker^ := trunc(FRawProtocolValues[ValueIndex + ProtocolOffSet]) and $FF;
                    Inc(ValueIndex);
                    Inc(PtrByteWalker);
                  end;
    ptWord,
    ptSmallInt: while ValueIndex < ProtocolSize do
                  begin
                    PtrWordWalker^ := trunc(FRawProtocolValues[ValueIndex + ProtocolOffSet]) and $FFFF;
                    Inc(ValueIndex);
                    Inc(PtrWordWalker);
                  end;
    ptDWord,
    ptLongInt,
    ptFloat:  while ValueIndex < ProtocolSize do
                begin
                  case FProtocolTagType of
                    ptLongInt: PLongInt(PtrDWordWalker)^ := trunc(FRawProtocolValues[ValueIndex + ProtocolOffSet]);
                    ptDWord:   PtrDWordWalker^ := trunc(FRawProtocolValues[ValueIndex + ProtocolOffSet]) and $FFFFFFFF;
                    ptFloat:   PSingle(PtrDWordWalker)^ := FRawProtocolValues[ValueIndex + ProtocolOffSet];
                  end;
                  Inc(ValueIndex);
                  Inc(PtrDWordWalker);
                end;
    ptQWord,
    ptInt64,
    ptDouble: while ValueIndex < ProtocolSize do
                begin
                  case FProtocolTagType of
                    ptInt64:  PInt64(PtrQWordWalker)^ := trunc(FRawProtocolValues[ValueIndex + ProtocolOffSet]);
                    ptQWord:  PQWord(PtrQWordWalker)^ := trunc(FRawProtocolValues[ValueIndex + ProtocolOffSet]);
                    ptDouble: PDouble(PtrQWordWalker)^ := FRawProtocolValues[ValueIndex + ProtocolOffSet];
                  end;
                  Inc(ValueIndex);
                  Inc(PtrQWordWalker);
                end;
  end;

  ResetPointers;
  ValueIndex := 0;
  // move data to the work memory
  case FTagType of
    pttByte,
    pttShortInt:  begin
                    Inc(PtrByteWalker, ((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize);
                    while ValueIndex < Length(Values) do
                    begin
                      PtrByteWalker^ := trunc(Values[ValueIndex]) and $FF;
                      Inc(ValueIndex);
                      Inc(PtrByteWalker);
                    end;
                  end;
    pttWord,
    pttSmallInt:  begin
                    Inc(PtrWordWalker, ((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize);
                    while ValueIndex < Length(Values) do
                    begin
                      PtrWordWalker^ := trunc(Values[ValueIndex]) and $FFFF;

                      if FSwapBytes then
                      begin
                        PtrByte1 := Pbyte(PtrWordWalker);
                        PtrByte2 := PtrByte1;
                        Inc(PtrByte2);
                        ByteAux := PtrByte1^;
                        PtrByte1^ := PtrByte2^;
                        PtrByte2^ := ByteAux;
                      end;

                      Inc(ValueIndex);
                      Inc(PtrWordWalker);
                    end;
                  end;
    pttDWord,
    pttLongInt,
    pttFloat: begin
                Inc(PtrDWordWalker, ((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize);
                while ValueIndex < Length(Values) do
                begin
                  if FTagType = pttLongInt then
                    PLongInt(PtrDWordWalker)^ := trunc(Values[ValueIndex]);
                  if FTagType = pttDWord then
                    PtrDWordWalker^ := trunc(Values[ValueIndex]) and $FFFFFFFF;
                  if FTagType = pttFloat then
                    PSingle(PtrDWordWalker)^ := Values[ValueIndex];

                  if FSwapWords or FSwapBytes then
                  begin
                    PtrWord1 := PWord(PtrDWordWalker);
                    PtrWord2 := PtrWord1;
                    Inc(PtrWord2);
                  end;

                  if FSwapWords then
                  begin
                    WordAux := PtrWord1^;
                    PtrWord1^ := PtrWord2^;
                    PtrWord2^ := WordAux;
                  end;

                  if FSwapBytes then
                  begin
                    PtrByte1 := Pbyte(PtrWord1);
                    PtrByte2 := PtrByte1;
                    Inc(PtrByte2);
                    ByteAux := PtrByte1^;
                    PtrByte1^ := PtrByte2^;
                    PtrByte2^ := ByteAux;

                    PtrByte1 := Pbyte(PtrWord2);
                    PtrByte2 := PtrByte1;
                    Inc(PtrByte2);
                    ByteAux := PtrByte1^;
                    PtrByte1^ := PtrByte2^;
                    PtrByte2^ := ByteAux;
                  end;

                  Inc(ValueIndex);
                  Inc(PtrDWordWalker);
                end;
              end;
    pttQWord,
    pttInt64,
    pttDouble:  begin
                  Inc(PtrQWordWalker, ((Offset * FCurrentWordSize) mod FProtocolWordSize) div FCurrentWordSize);
                  while ValueIndex < Length(Values) do
                  begin
                    if FTagType = pttInt64 then
                      PInt64(PtrQWordWalker)^ := trunc(Values[ValueIndex]);
                    if FTagType = pttQWord then
                      PtrQWordWalker^ := QWord(trunc(Values[ValueIndex]));
                    if FTagType = pttDouble then
                      PDouble(PtrQWordWalker)^ := Values[ValueIndex];

                    if FSwapDWords then
                    begin
                      // initialize Dword Pointers
                      PtrDWord1 := PDWord(PtrQWordWalker);
                      PtrDWord2 := PtrDWord1;
                      Inc(PtrDWord2);

                      // swap dwords
                      DWordAux := PtrDWord1^;
                      PtrDWord1^ := PtrDWord2^;
                      PtrDWord2^ := DWordAux;
                    end;

                    if FSwapWords then
                    begin
                      // initializes DWord Pointers
                      PtrDWord1 := PDWord(PtrQWordWalker);
                      PtrDWord2 := PtrDWord1;
                      Inc(PtrDWord2);

                      // initializa first 2 word pointers
                      PtrWord1 := PWord(PtrDWord1);
                      PtrWord2 := PtrWord1;
                      Inc(PtrWord2);

                      // swap words
                      WordAux := PtrWord1^;
                      PtrWord1^ := PtrWord2^;
                      PtrWord2^ := WordAux;

                      // initializes next 2 word pointers
                      PtrWord1 := PWord(PtrDWord2);
                      PtrWord2 := PtrWord1;
                      Inc(PtrWord2);

                      // swap words.
                      WordAux := PtrWord1^;
                      PtrWord1^ := PtrWord2^;
                      PtrWord2^ := WordAux;
                    end;

                    if FSwapBytes then
                    begin
                      // initializes DWord Pointers
                      PtrDWord1 := PDWord(PtrQWordWalker);
                      PtrDWord2 := PtrDWord1;
                      Inc(PtrDWord2);

                      // initializes first 2 word pointers
                      PtrWord1 := PWord(PtrDWord1);
                      PtrWord2 := PtrWord1;
                      Inc(PtrWord2);

                      // initialize bytes 1 and 2
                      PtrByte1 := Pbyte(PtrWord1);
                      PtrByte2 := PtrByte1;
                      Inc(PtrByte2);

                      // swap bytes
                      ByteAux := PtrByte1^;
                      PtrByte1^ := PtrByte2^;
                      PtrByte2^ := ByteAux;

                      // initialize bytes 3 and 4
                      PtrByte1 := Pbyte(PtrWord2);
                      PtrByte2 := PtrByte1;
                      Inc(PtrByte2);

                      // swap bytes
                      ByteAux := PtrByte1^;
                      PtrByte1^ := PtrByte2^;
                      PtrByte2^ := ByteAux;

                      // initializes next 2 word pointers
                      PtrWord1 := PWord(PtrDWord2);
                      PtrWord2 := PtrWord1;
                      Inc(PtrWord2);

                      // initialize bytes 5 and 6
                      PtrByte1 := Pbyte(PtrWord1);
                      PtrByte2 := PtrByte1;
                      Inc(PtrByte2);

                      // swap bytes
                      ByteAux := PtrByte1^;
                      PtrByte1^ := PtrByte2^;
                      PtrByte2^ := ByteAux;

                      // initialize bytes 7 and 8
                      PtrByte1 := Pbyte(PtrWord2);
                      PtrByte2 := PtrByte1;
                      Inc(PtrByte2);

                      // swap bytes
                      ByteAux := PtrByte1^;
                      PtrByte1^ := PtrByte2^;
                      PtrByte2^ := ByteAux;
                    end;

                    Inc(ValueIndex);
                    Inc(PtrQWordWalker);
                  end;
                end;
  end;

  ResetPointers;
  AreaIndex := 0;
  // swap bytes and words (if necessary)
  case FProtocolTagType of
    ptBit:  begin
              while AreaIndex < AreaSize do
              begin
                BitAux := Power(2, AreaIndex mod 8);
                if (PtrByteWalker^ and BitAux) = BitAux then
                  AddToResult(1, Result)
                else
                  AddToResult(0, Result);

                Inc(AreaIndex);

                if (AreaIndex mod 8) = 0 then
                  Inc(PtrByteWalker);
              end;
            end;
    ptByte,
    ptShortInt: begin
                  while AreaIndex < AreaSize do
                  begin
                    if FProtocolTagType = ptShortInt then
                      AddToResult(PShortInt(PtrByteWalker)^, Result)
                    else
                      AddToResult(PtrByteWalker^, Result);
                    Inc(AreaIndex);
                    Inc(PtrByteWalker);
                  end;
                end;
    ptSmallInt,
    ptWord: begin
              while AreaIndex < AreaSize do
              begin
                if FProtocolTagType = ptSmallInt then
                  AddToResult(PSmallInt(PtrWordWalker)^, Result)
                else
                  AddToResult(PtrWordWalker^, Result);

                Inc(AreaIndex, 2);
                Inc(PtrWordWalker);
              end;
            end;
    ptLongInt,
    ptDWord,
    ptFloat:  begin
                while AreaIndex < AreaSize do
                begin
                  case FProtocolTagType of
                    ptDWord:   AddToResult(PtrDWordWalker^, Result);
                    ptLongInt: AddToResult(PLongInt(PtrDWordWalker)^, Result);
                    ptFloat:   AddToResult(PSingle(PtrDWordWalker)^, Result);
                  end;
                  Inc(AreaIndex, 4);
                  Inc(PtrDWordWalker);
                end;
              end;
    ptInt64,
    ptQWord,
    ptDouble: begin
                while AreaIndex < AreaSize do
                begin
                  case FProtocolTagType of
                    ptQWord:  AddToResult(PtrQWordWalker^, Result);
                    ptInt64:  AddToResult(PInt64(PtrQWordWalker)^, Result);
                    ptDouble: AddToResult(PDouble(PtrQWordWalker)^, Result);
                  end;
                  Inc(AreaIndex, 8);
                  Inc(PtrQWordWalker);
                end;
              end;
  end;
  Freemem(PtrByte);
end;

function TPLCTag.GetAvgUpdateRate: Double;
begin
  if FReadCount = 0 then
    Result := -1
  else
    Result := FTotalTime / FReadCount;
end;

function TPLCTag.RemainingMiliseconds: Int64;
begin
  Result := PUpdateTime - MilliSecondsBetween(CrossNow, PValueTimeStamp);
end;

function TPLCTag.RemainingMilisecondsForNextScan: Int64;
begin
  Result := PUpdateTime - MilliSecondsBetween(CrossNow, PLastScanTimeStamp);
end;

function TPLCTag.GetUpdateTime: Int64;
begin
  Result := PUpdateTime;
end;

function TPLCTag.IsValidTag: Boolean;
begin
  Result := PValidTag;
end;

procedure TPLCTag.SetTagValidity(TagValidity: Boolean);
begin
  PValidTag := TagValidity;
end;

////////////////////////////////////////////////////////////////////////////////
// PASCALSCADA TAG MANAGER
////////////////////////////////////////////////////////////////////////////////

constructor TTagMananger.Create;
begin
  SetLength(FTags, 0);
end;

destructor TTagMananger.Destroy;
begin
  if Length(FTags) > 0 then
    raise Exception.Create(SCannotDestroyBecauseTagsStillManaged);
end;

procedure TTagMananger.AddTag(Tag: TPLCTag);
var
  i: Longint;
  h: Longint;
begin
  for i := 0 to High(FTags) do
  begin
    if FTags[i] = Tag then
      Exit;
    if (FTags[i] <> Tag) and (FTags[i].TagGUID = Tag.TagGUID) then
    begin
      if Supports(Tag, IManagedTagInterface) then
        (Tag as IManagedTagInterface).RebuildTagGUID
      else
        raise Exception.Create(SCannotRebuildTagID);
    end;
  end;
  h := Length(FTags);
  SetLength(FTags, h + 1);
  FTags[h] := Tag;
end;

procedure TTagMananger.RemoveTag(Tag: TPLCTag);
var
  i: Longint;
  h: Longint;
  Found: Boolean;
begin
  Found := False;
  for i := 0 to High(FTags) do
    if FTags[i] = Tag then
    begin
      Found := True;
      Break;
    end;

  if Found then
  begin
    h := High(FTags);
    FTags[i] := FTags[h];
    SetLength(FTags, Max(0, h - 1));
  end;
end;


var
  QPascalTagManager: TTagMananger;


function GetTagManager: TTagMananger;
begin
  Result := QPascalTagManager;
end;


initialization
  QPascalTagManager := TTagMananger.Create;


finalization
  QPascalTagManager.Destroy;


end.

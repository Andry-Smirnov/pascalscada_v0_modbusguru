{$i ../common/language.inc}
{:
  @abstract(Implementation of ISOTCP protocol.)
  This driver is based on ISOTCP implementation of LibNODAVE library of Thomas
  Hergenhahn (thomas.hergenhahn@web.de).

  This driver doesn't use the Libnodave library, it's a rewritten of it.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Moved OpenTagEditor to SiemensTagAssistant to remove TForm dependencies
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
unit s7family;

interface

uses
  Classes, SysUtils, ProtocolDriver, S7Types, Tag, ProtocolTypes, fgl, s7scanreq,
  commtypes;

type
  TS7ScanReqList = specialize TFPGList<TS7ScanReqItem>;

  //TODO Documentation
  TS7PDUSize = (pduAuto, pdu240, pdu480, pdu960);

  //TODO Documentation
  TS7PLCType = (s7_300, s7_et200s, s7_400, s7_1200, s7_1500, s7_et200sp, s7_200);

  //TODO Documentation
  TS7Protection = record
    SchSchal: Byte; // Protection level set with the mode selector.
    SchPar: Byte;   // Password level, 0 : no password
    SchRel: Byte;   // Valid protection level of the CPU
    BartSch: Byte;  // Mode selector setting (1:RUN, 2:RUN-P, 3:STOP, 4:MRES, 0:undefined or cannot be determined)
    AnlSch: Byte;   // Startup switch setting (1:CRST, 2:WRST, 0:undefined, does not exist of cannot be determined)
  end;

  {: Siemens S7 protocol drivers family. Based on LibNodave library of
  Thomas Hergenhahn (thomas.hergenhahn@web.de).

  This driver doesn't use the Libnodave library, it's a rewritten of it.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  To setup a tag, you must set the properties PLCStation, PLCRack and PLCSlot
  to address your PLC. To address a memory inside the PLC, you must set the
  properties MemAddress and MemReadFunction (see the table below) and if is a DB
  that is being addressed, set the DB number on property MemFile_DB. The datatype
  of tag can be selected on property TagType.

  If the TagType is a Word, SmalltInt, LongInt, DWord or Float you must set too
  the properties SwapBytes and SwapWord to @true to get the PLC values correctly.

  To choose the memory area, set the property MemReadFunction as show below:

  Area:
  @table(
    @rowHead( @cell(Area)                            @cell(Value) @cell(Observation) )
    @row(     @cell(Inputs)                          @cell( 1)    @cell( - ))
    @row(     @cell(Outputs)                         @cell( 2)    @cell( - ))
    @row(     @cell(Flags or M's)                    @cell( 3)    @cell( - ))
    @row(     @cell(DB and V no S7-200 )             @cell( 4)    @cell( - ))
    @row(     @cell(Counter, S7 300/400)             @cell( 5)    @cell(TagType property must be pttWord))
    @row(     @cell(Timer, S7 300/400)               @cell( 6)    @cell(TagType property must be pttWord))

    @row(     @cell(Special Memory, SM, S7-200)      @cell( 7)    @cell( - ))
    @row(     @cell(Analog Input, S7-200)            @cell( 8)    @cell( - ))
    @row(     @cell(Analog Output, S7-200)           @cell( 9)    @cell( - ))
    @row(     @cell(Counter, S7-200)                 @cell(10)    @cell(TagType property must be pttWord))
    @row(     @cell(Timer, S7-200)                   @cell(11)    @cell(TagType property must be pttWord))

    @row(     @cell(Analog Input (PIW), S7 300/400)  @cell(12)    @cell(TagType property must be pttWord)))

  So, to address the IB3, you must set the property MemReadFunction the value 1,
  the MemAddress the value 3 and the property TagType the value pttByte. To
  address the MD100 (DWord) you must set MemReadFunction to 5, the MemAddres to
  100 and pttDword on TagType. }
  TSiemensProtocolFamily = class(TProtocolDriver)
  private
    FForcedPDUSize: TS7PDUSize;
    FPDUSizeInBytes: Cardinal;

    procedure SetPDUSize(AValue: TS7PDUSize);
  protected
    //: Returns a structure with informations about the tag.
    function GetTagInfo(tagobj: TTag): TTagRec; virtual;
    //: Gets a byte from a pointer of Bytes.
    //function  GetByte(Ptr:PByte; idx:LongInt):LongInt;
    //: Sets a byte in a pointer of Bytes.
    //procedure SetByte(Ptr:PByte; idx:LongInt; value:Byte);
    //: Sets a lot of Bytes in a pointer of Bytes.
    procedure SetBytes(Ptr: Pbyte; Idx: Longint; Values: Bytes);
  protected
    //: Where PDU starts on incoming and outgoing packets.
    PDUIncoming: Longint;
    PDUOutgoing: Longint;
    {: Lists all CPU's being read by the protocol driver.
    @seealso(TS7CPU) }
    FPLCs: TS7CPUs;
    //: If the protocol needs to initialize the adapter, stores if it was initialized.
    FAdapterInitialized: Boolean;

    //: Initializes the adapter, if needed.
    function InitAdapter: Boolean; virtual;
    //: Disconnects from adapter.
    function DisconnectAdapter: Boolean; virtual;
    {: Connects on a PLC.
    @param(CPU TS7CPU. Represents the PLC to connect.) }
    function ConnectPLC(var CPU: TS7CPU): Boolean; virtual;
    {: Disconnects from a PLC.
    @param(CPU TS7CPU. Represents the PLC to disconnect.) }
    function DisconnectPLC(var CPU: TS7CPU): Boolean; virtual;
    {: Exchange data with a PLC.
    @param(CPU TS7CPU. PLC to exchange data.)
    @param(msgOut Bytes. Packet to send to PLC.)
    @param(msgIn Bytes. Stores the received packet from PLC.)
    @param(IsWrite Boolean. Tells if the message to be send to PLC will write
           in PLC memory.)
    @returns(@True if successful.) }
    function Exchange(var CPU: TS7CPU; var MsgOut: Bytes; var MsgIn: Bytes; IsWrite: Boolean): Boolean; virtual;
    {: Sends a message.
    @param(msgOut Bytes. Message to send.) }
    procedure SendMessage(var MsgOut: Bytes); virtual;
    {: Gets a incoming packet from the communication port.
    @param(msgIn Bytes. Stores the incoming packet.)
    @param(BytesRead LongInt. Packet length.)
    @returns(iorOK if was come some packet.) }
    function getResponse(var MsgIn: Bytes; var BytesRead: Longint): TIOResult; virtual;

    //: @exclude
    procedure ListReachablePartners; virtual;
  protected
    {: Swap the Bytes of a word.
    @param(W Word. Word to swap their Bytes.)
    @returns(The word with their Bytes swaped.) }
    function SwapBytesInWord(W: Word): Word;
    {: Prepares a message to be sent.
    @param(msg Bytes. Message to be prepared.) }
    procedure PrepareToSend(var Msg: Bytes); virtual;
  protected
    {: Adds a parameter into the message to be sent.
    @param(MsgOut Bytes. Message to be sent.)
    @param(param Bytes. Parameter to be added.) }
    procedure AddParam(var MsgOut: Bytes; const Param: Bytes); virtual;
    {: Adds a dataset into the message to be sent.
    @param(MsgOut Bytes. Message to be sent.)
    @param(data Bytes. Data to be added.) }
    procedure AddData(var MsgOut: Bytes; const Data: Bytes); virtual;
    {: Initialize the PDU on outgoing message.
    @param(MsgOut Bytes. Outgoing message to initiate the PDU.)
    @param(PDUType LongInt. Kind of PDU to create.) }
    procedure InitiatePDUHeader(var MsgOut: Bytes; PDUType: Longint); virtual;
    {: Negotiate the maximum PDU size.
    @param(CPU TS7CPU. PLC to negotiate the maximum PDU size.) }
    function NegotiatePDUSize(var CPU: TS7CPU): Boolean; virtual;
    {: Creates a PDU structure from message.
    @param(msg Bytes. Menssage to get the PDU structure.)
    @param(MsgOutgoing Boolean. If @true the message will be sent to PLC, if not
           the message is comming from the PLC.)
    @param(PDU TPDU. The PDU structure extracted from message.)
    @returns(The error number of PDU, if exists.)}
    function SetupPDU(var Msg: Bytes; MsgOutgoing: Boolean; out PDU: TPDU; out Error: Integer): Boolean; virtual;
    {: Prepares the message to do a memory read request from PLC.
    @param(msgOut Bytes. Message to be sent to PLC requesting a memory read.) }
    procedure PrepareReadRequest(var MsgOut: Bytes); virtual;
    {: Prepares the message to write data into the PLC memory.
    @param(msgOut Bytes. Message to sent to write data into the PLC memory.) }
    procedure PrepareWriteRequest(var MsgOut: Bytes); virtual;
    {: Prepares the message to read or write on PLC.
    @param(WriteRequest Boolean. If @true, the message will write something in PLC memory.)
    @param(msgOut Bytes. Message to be prepared to request a read/write.) }
    procedure PrepareReadOrWriteRequest(const WriteRequest: Boolean; var MsgOut: Bytes); virtual;
    {: Add into the outgoing message, informations about what must be read from PLC.
    @param(msgOut Bytes. Message to be sent to PLC requesting a memory read.)
    @param(iArea LongInt. Wanted memory area.
           @seealso(vtS7_200_SysInfo)
           @seealso(vtS7_200_SM)
           @seealso(vtS7_200_AnInput)
           @seealso(vtS7_200_AnOutput)
           @seealso(vtS7_200_Counter)
           @seealso(vtS7_200_Timer)
           @seealso(vtS7_Peripheral)
           @seealso(vtS7_Inputs)
           @seealso(vtS7_Outputs)
           @seealso(vtS7_Flags)
           @seealso(vtS7_DB)
           @seealso(vtS7_DI)
           @seealso(vtS7_Local)
           @seealso(vtS7_V)
           @seealso(vtS7_Counter)
           @seealso(vtS7_Timer) )
    @param(iDBnum LongInt. If iArea is vtS7_DB, what's the DB number.)
    @param(iStart LongInt. Start address of memory.)
    @param(iByteCount LongInt. How many Bytes to read.) }
    procedure AddToReadRequest(var MsgOut: Bytes; iArea, iDBnum, iStart, iByteCount: Longint); virtual;
    {: Add into the outgoing message, informations about the data to be written on PLC.
    @param(msgOut Bytes. Message to be sent to write data on PLC.)
    @param(iArea LongInt. Wanted memory area.
           @seealso(vtS7_200_SysInfo)
           @seealso(vtS7_200_SM)
           @seealso(vtS7_200_AnInput)
           @seealso(vtS7_200_AnOutput)
           @seealso(vtS7_200_Counter)
           @seealso(vtS7_200_Timer)
           @seealso(vtS7_Peripheral)
           @seealso(vtS7_Inputs)
           @seealso(vtS7_Outputs)
           @seealso(vtS7_Flags)
           @seealso(vtS7_DB)
           @seealso(vtS7_DI)
           @seealso(vtS7_Local)
           @seealso(vtS7_V)
           @seealso(vtS7_Counter)
           @seealso(vtS7_Timer) )
    @param(iDBnum LongInt. If iArea is vtS7_DB, what's the DB number.)
    @param(iStart LongInt. Start address of memory.)
    @param(buffer Bytes. Data to be written on PLC.) }
    procedure AddParamToWriteRequest(var MsgOut: Bytes; iArea, iDBnum, iStart: Longint; Buffer: Bytes); virtual;
    {: Add into the outgoing message the data to be written on PLC.
    @param(msgOut Bytes. Message to be sent to write data on PLC.)
    @param(iArea LongInt. Wanted memory area.
           @seealso(vtS7_200_SysInfo)
           @seealso(vtS7_200_SM)
           @seealso(vtS7_200_AnInput)
           @seealso(vtS7_200_AnOutput)
           @seealso(vtS7_200_Counter)
           @seealso(vtS7_200_Timer)
           @seealso(vtS7_Peripheral)
           @seealso(vtS7_Inputs)
           @seealso(vtS7_Outputs)
           @seealso(vtS7_Flags)
           @seealso(vtS7_DB)
           @seealso(vtS7_DI)
           @seealso(vtS7_Local)
           @seealso(vtS7_V)
           @seealso(vtS7_Counter)
           @seealso(vtS7_Timer))
    @param(iDBnum LongInt. If iArea is vtS7_DB, what's the DB number.)
    @param(iStart LongInt. Start address of memory.)
    @param(buffer Bytes. Data to be written on PLC.) }
    procedure AddDataToWriteRequest(var msgOut: Bytes; iArea, iDBnum, iStart: Longint; buffer: Bytes); virtual;
  protected
    //: Put the PLC in RUN state, if possible. Don't work yet.
    procedure RunPLC(CPU: TS7CPU);
    //: Stops the PLC, if possible. Don't work yet.
    procedure StopPLC(CPU: TS7CPU);
    //: @exclude.
    procedure CopyRAMToROM(CPU: TS7CPU);
    //: @exclude.
    procedure CompressMemory(CPU: TS7CPU);

    //: Converts a Siemens error code to a protocol error code.
    function S7ErrorCodeToProtocolErrorCode(Code: Word): TProtocolIOResult;
  protected
    {: Converts TArrayOfDouble to Bytes.
    @param(Values TArrayOfDouble. Array to be converted.)
    @param(Start LongInt. First element of Values to be converted.)
    @param(Len LongInt. How many elements to convert from Start.)
    @returns(Converted Array of Bytes.) }
    function DoublesToBytes(const Values: TArrayOfDouble; Start, Len: Longint): Bytes;
    {: Converts Bytes to TArrayOfDouble.
    @param(ByteSeq Bytes. Array of byte to be converted to Double.)
    @param(Start LongInt. First element of ByteSeq to be converted.)
    @param(Len LongInt. How many elements to convert from Start.)
    @returns(Array of TArrayOfDouble.) }
    function BytesToDoubles(const ByteSeq: Bytes; Start, Len: Longint): TArrayOfDouble;
    {: Creates a  PLC in the addressed PLC's list.
    @param(iRack LongInt. PLC Rack.)
    @param(iSlot LongInt. PLC Slot.)
    @param(iStation LongInt. PLC Address.)
    @returns(The PLC index on PLC list.) }
    function CreatePLC(iRack, iSlot, iStation: Longint): Longint; virtual;
    {: Delete a PLC from the addressed PLC's list.
    @param(PLCIndex LongInt. Index of PLC in the PLC's list.) }
    procedure DeletePLC(PLCIndex: Integer); virtual;
    {: Updates the manager of non-continuous memory blocks.
    @param(pkgin Bytes. Message received from PLC)
    @param(pkgout Bytes. Message sent to PLC)
    @param(writepkg Boolean. If @true, the packet sent will change the PLC memory.)
    @param(ReqList TS7ReqList. List of all requests sent.)
    @param(ResultValues TArrayOfDouble. Values of the last request.) }
    procedure UpdateMemoryManager(PkgIn, PkgOut: Bytes; WritePkg: Boolean; ReqList: TS7ReqList; var ResultValues: TArrayOfDouble);
    //: @seealso(TProtocolDriver.DoAddTag)
    procedure DoAddTag(tagobj: TTag; TagValid: Boolean); override;
    //: @seealso(TProtocolDriver.DoDelTag)
    procedure DoDelTag(tagobj: TTag); override;
    //: @seealso(TProtocolDriver.DoScanRead)
    procedure DoScanRead(Sender: TObject; var NeedSleep: Longint); override;
    //: @seealso(TProtocolDriver.DoGetValue)
    procedure DoGetValue(TagRec: TTagRec; var values: TScanReadRec); override;

    //estas funcoes ficaram apenas por motivos compatibilidade com os tags
    //e seus metodos de reading e escrita diretas.

    //: @seealso(TProtocolDriver.DoWrite)
    function DoWrite(const TagRec: TTagRec; const values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
    //: @seealso(TProtocolDriver.DoRead)
    function DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;

    //: @exclude
    destructor Destroy; override;

    //: @seealso(TProtocolDriver.SizeOfTag)
    function SizeOfTag(aTag: TTag; IsWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte; override;

    //: @seealso(TProtocolDriver.LiteralTagAddress)
    function LiteralTagAddress(ATag: TTag; ABlockTag: TTag = nil): AnsiString; override;

    //: @seealso(TProtocolDriver.OpenTagEditor)
    procedure OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); override;
    //: @seealso(TProtocolDriver.HasTabBuilderEditor)
    function HasTabBuilderEditor: Boolean; override;
  published
    //: @seealso(TProtocolDriver.ReadSomethingAlways)
    property ReadSomethingAlways;

    property ForcePDUSize: TS7PDUSize read FForcedPDUSize write SetPDUSize;
  end;


procedure SetTagBuilderToolForSiemensS7ProtocolFamily(TagBuilderTool: TOpenTagEditor);


implementation


uses
  PLCTagNumber, PLCString, PLCStruct, hsstrings, PLCBlock, PLCMemoryManager,
  dateutils, strutils, Math;


  ////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTORS AND DESTRUCTORS
  ////////////////////////////////////////////////////////////////////////////////

function SortTagList(Item1, Item2: Pointer): Integer;
var
  ReqItem1: PS7ScanReqItem absolute Item1;
  ReqItem2: PS7ScanReqItem absolute Item2;
  BitCombination: Integer;
  ScanPercent1: Double;
  ScanPercent2: Double;
begin
  BitCombination := IfThen(ReqItem1^.NeedUpdate, 1, 0) + IfThen(ReqItem2^.NeedUpdate, 2, 0);
  case BitCombination of
    1: Result := -1;
    2: Result := 1;
    0, 3: begin
            //if ReqItem1.LastUpdate=ReqItem2.LastUpdate then
            //  Result:=0
            //else begin
            //  if ReqItem1.LastUpdate<ReqItem2.LastUpdate then
            //    Result:=-1
            //  else
            //    Result:=1;
            //end;
            ScanPercent1 := (MilliSecondsBetween(Now, ReqItem1^.LastUpdate) / ReqItem1^.UpdateRate);
            ScanPercent2 := (MilliSecondsBetween(Now, ReqItem2^.LastUpdate) / ReqItem2^.UpdateRate);
            if ScanPercent1 = ScanPercent2 then
              Result := 0
            else if ScanPercent1 > ScanPercent2 then
              Result := -1
            else
              Result := 1;
          end;
  end;
end;

function SortGenericTagList(const Item1, Item2: TS7ScanReqItem): Integer;
var
  BitCombination: Integer;
  ScanPercent1: Double;
  ScanPercent2: Double;
begin
  BitCombination := IfThen(Item1.NeedUpdate, 1, 0) + IfThen(Item2.NeedUpdate, 2, 0);
  case BitCombination of
    1: Result := -1;
    2: Result := 1;
    0, 3: begin
            ScanPercent1 := 0;
            if Item1.UpdateRate <> 0 then
              ScanPercent1 := (MilliSecondsBetween(Now, Item1.LastUpdate) / Item1.UpdateRate);

            ScanPercent2 := 0;
            if Item2.UpdateRate <> 0 then
              ScanPercent2 := (MilliSecondsBetween(Now, Item2.LastUpdate) / Item2.UpdateRate);
            if ScanPercent1 = ScanPercent2 then
              Result := 0
            else if ScanPercent1 > ScanPercent2 then
              Result := -1
            else
              Result := 1;
          end;
  end;
end;

constructor TSiemensProtocolFamily.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PReadSomethingAlways := True;
  FProtocolReady := False;
  PDUIncoming := 0;
  PDUOutgoing := 0;
  FForcedPDUSize := pduAuto;
  FPDUSizeInBytes := 960;
end;

destructor TSiemensProtocolFamily.Destroy;
var
  i: Integer;
begin
  inherited Destroy; // stops all drivers first.
  for i := 0 to High(FPLCs) do
    DeletePLC(i);
end;

function TSiemensProtocolFamily.SizeOfTag(aTag: TTag; IsWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte;
begin
  // all kinds of tags are returned as byte
  ProtocolTagType := ptByte;
  Result := 8;
end;

function TSiemensProtocolFamily.LiteralTagAddress(ATag: TTag; ABlockTag: TTag): AnsiString;

  function DescTagArea(Area: Longint): AnsiString;
  begin
    case Area of
      1:  Result := 'I';
      2:  Result := 'Q';
      3:  Result := 'M';
      4:  Result := 'DB';
      5:  Result := 'C';
      6:  Result := 'T';
      7:  Result := 'SM';
      8:  Result := 'S7200 I';
      9:  Result := 'S7200 Q';
      10: Result := 'S7200 C';
      11: Result := 'S7200 T';
      12: Result := 'PI';
      else
        Result := '(Unknown area)';
    end;
  end;

  function SiemensDescOfType(AType: TTagType): AnsiString;
  begin
    case AType of
      pttDefault,
      pttShortInt,
      pttByte:  Result := 'B';
      pttSmallInt,
      pttWord:  Result := 'W';
      pttLongInt,
      pttDWord,
      pttFloat: Result := 'D';
    end;
  end;

  function PascalDescOfType(AType: TTagType): AnsiString;
  begin
    case AType of
      pttDefault,
      pttByte:     Result := ' AS Byte [0..255]';
      pttShortInt: Result := ' AS ShortInt [-128..127]';
      pttSmallInt: Result := ' AS SmallInt [-32768..32767]';
      pttWord:     Result := ' AS Word [0..65535]';
      pttLongInt:  Result := ' AS LongInt [-2147483648..2147483647]';
      pttDWord:    Result := ' AS SmallInt [0..4294967295]';
      pttFloat:    Result := ' AS Float [±1.18×10E−38 to ±3.4×10E38]';
    end;
  end;

begin
  if ABlockTag = nil then
  begin
    if ATag is TPLCTagNumber then
    begin
      with ATag as TPLCTagNumber do
      begin
        case MemReadFunction of
          4: Result := 'DB' + IntToStr(MemFile_DB) + '.DB' + SiemensDescOfType(TagType) +
              IntToStr(MemAddress) + PascalDescOfType(TagType);
          1..3, 7: Result := DescTagArea(MemReadFunction) + SiemensDescOfType(TagType) +
              IntToStr(MemAddress) + PascalDescOfType(TagType);
          5..6,
          8..12:  begin
                    Result := DescTagArea(MemReadFunction) +
                      IntToStr(MemAddress) + PascalDescOfType(TagType);
                    if (TagType <> pttWord) and (TagType <> pttSmallInt) then
                      Result := Result + LineEnding + '(wrong Tag data type, set the Tag data type to pttWord or pttSmallInt)';
                  end;
          else
            Result := 'Unknown area';
        end;
      end;
      Exit;
    end;

    if ATag is TPLCString then
    begin
      with ATag as TPLCString do
      begin
        Result := 'String format ' + strutils.IfThen(StringType = stC, '"C" (null terminated)', '"Siemens" (with one byte to max size and other with the current string size)') +
          ',' + LineEnding + ' starting at ';

        case MemReadFunction of
          4: Result := Result + 'DB' + IntToStr(MemFile_DB) + '.DBB' + IntToStr(MemAddress);
          1..3, 7:  begin
                      Result := Result + DescTagArea(MemReadFunction) + 'B' +
                        IntToStr(MemAddress);
                      if MemReadFunction in [1..2] then
                        Result := Result + LineEnding + '(Digital inputs/outputs are a strange area to store a string, not?)';
                    end;
          5..6,
          8..12:  begin
                    Result := DescTagArea(MemReadFunction) + IntToStr(MemAddress) +
                      LineEnding + '(' + DescTagArea(MemReadFunction) + ' are a strange area to store a string, not?)';
                  end;
          else
            Result := 'Unknown area';
        end;
      end;
      Exit;
    end;

    if ATag is TPLCStruct then
    begin
      Result := 'Structure at ';
      with ATag as TPLCStruct do
      begin
        case MemReadFunction of
          4: Result := Result + 'DB' + IntToStr(MemFile_DB) + '.DB' +
               SiemensDescOfType(TagType) + IntToStr(MemAddress);
          1..3, 7: Result := Result + DescTagArea(MemReadFunction) +
                     SiemensDescOfType(TagType) + IntToStr(MemAddress);
          5..6,
          8..12:  begin
                    Result := Result + DescTagArea(MemReadFunction) +
                      IntToStr(MemAddress);
                  end;
          else
            Result := Result + 'Unknown area';
        end;
        Result := Result + LineEnding + 'with ' + IntToStr(TagSizeOnProtocol);
      end;
      Exit;
    end;

    if ATag is TPLCBlock then // block and plcstruct
    begin
      Result := 'Block of tags starting at ';
      with ATag as TPLCBlock do
      begin
        case MemReadFunction of
          4: Result := Result + 'DB' + IntToStr(MemFile_DB) + '.DB' +
               SiemensDescOfType(TagType) + IntToStr(MemAddress);
          1..3, 7: Result := Result + DescTagArea(MemReadFunction) +
                     SiemensDescOfType(TagType) + IntToStr(MemAddress);
          5..6,
          8..12:  begin
                    Result := Result + DescTagArea(MemReadFunction) +
                      IntToStr(MemAddress);
                    if (TagType <> pttWord) and (TagType <> pttSmallInt) then
                      Result := Result + LineEnding + '(with a strange Tag data type, set the data type to pttWord or pttSmallInt)';
                  end;
          else
            Result := Result + 'Unknown area';
        end;
        Result := Result + LineEnding + 'with ' + IntToStr(Size) + ' elements' + PascalDescOfType(TagType);
      end;
      Exit;
    end;
  end
  else
    begin
    end;
end;

////////////////////////////////////////////////////////////////////////////////
// Interface functions.
////////////////////////////////////////////////////////////////////////////////

function TSiemensProtocolFamily.InitAdapter: Boolean;
begin
  Result := True;
end;

function TSiemensProtocolFamily.DisconnectAdapter: Boolean;
begin
  Result := False;
end;

function TSiemensProtocolFamily.ConnectPLC(var CPU: TS7CPU): Boolean;
begin
  Result := False;
end;

function TSiemensProtocolFamily.DisconnectPLC(var CPU: TS7CPU): Boolean;
begin
  Result := False;
end;

function TSiemensProtocolFamily.Exchange(var CPU: TS7CPU; var MsgOut: Bytes; var MsgIn: Bytes; IsWrite: Boolean): Boolean;
var
  APDU: TPDU;
  Err: Integer;
begin
  if SetupPDU(MsgOut, True, APDU, Err) = False then
  begin
    Result := False;
    Exit;
  end;

  if CPU.PDUId = $FFFF then
    CPU.PDUId := 0
  else
    Inc(CPU.PDUId);

  PPDUHeader(APDU.Header)^.Number := SwapBytesInWord(CPU.PDUId);
  Result := False;
end;

procedure TSiemensProtocolFamily.SendMessage(var MsgOut: Bytes);
begin

end;

function TSiemensProtocolFamily.getResponse(var MsgIn: Bytes; var BytesRead: Longint): TIOResult;
begin
  Result := iorNone;
end;

function TSiemensProtocolFamily.SwapBytesInWord(W: Word): Word;
var
  BL,
  BH: Byte;
begin
  BL := W mod $100;
  BH := W div $100;
  Result := (BL * $100) + BH;
end;

procedure TSiemensProtocolFamily.PrepareToSend(var Msg: Bytes);
begin

end;

function TSiemensProtocolFamily.NegotiatePDUSize(var CPU: TS7CPU): Boolean;
var
  Param: Bytes;
  Msg: Bytes;
  MsgIn: Bytes;
  PDU: TPDU;
  Err: Integer;
  Db: Longint;
  ForcedPduSize: Cardinal;
begin
  Result := False;
  SetLength(Param, 8);
  SetLength(Msg, PDUOutgoing + 10 + 8); //ISO = 25 Bytes
  SetLength(MsgIn, 0);

  Param[0] := $F0;
  Param[1] := 0;
  Param[2] := 0;
  Param[3] := 1;
  Param[4] := 0;
  Param[5] := 1;
  Param[6] := 3;   // PDU size 960
  Param[7] := $C0; // PDU size 960

  InterLockedExchange(ForcedPduSize, FPDUSizeInBytes);

  InitiatePDUHeader(Msg, 1);
  AddParam(Msg, Param);
  if Exchange(CPU, Msg, MsgIn, False) then
  begin

    if SetupPDU(MsgIn, False, PDU, Err) then
    begin
      CPU.MaxPDULen := Min(ForcedPduSize, PDU.param[6] * 256 + PDU.param[7]);
      CPU.MaxBlockSize := CPU.MaxPDULen - 18; // 10 Bytes of header + 2 Bytes of error code + 2 Bytes of read request + 4 Bytes of informations about the request.
      //adjust the maximum block size.
      with CPU do
      begin
        Inputs.MaxBlockItems := MaxBlockSize;
        Outputs.MaxBlockItems := MaxBlockSize;
        Timers.MaxBlockItems := MaxBlockSize;
        Counters.MaxBlockItems := MaxBlockSize;
        Flags.MaxBlockItems := MaxBlockSize;
        PeripheralInputs.MaxBlockItems := MaxBlockSize;

        S7200SMs.MaxBlockItems := MaxBlockSize;
        S7200Timers.MaxBlockItems := MaxBlockSize;
        S7200Counters.MaxBlockItems := MaxBlockSize;
        S7200AnInput.MaxBlockItems := MaxBlockSize;
        S7200AnOutput.MaxBlockItems := MaxBlockSize;

        for Db := 0 to High(DBs) do
          DBs[Db].DBArea.MaxBlockItems := MaxBlockSize;
      end;
      Result := True;
    end;
  end;
end;

function TSiemensProtocolFamily.SetupPDU(var Msg: Bytes; MsgOutgoing: Boolean; out PDU: TPDU; out Error: Integer): Boolean;
var
  Position: Longint;
begin
  Result := False;

  if MsgOutgoing then
    Position := PDUOutgoing
  else
    Position := PDUIncoming;

  if Length(Msg) < Position then Exit;

  PDU.Header := @Msg[Position];
  PDU.HeaderLen := 10;
  if PPDUHeader(PDU.Header)^.PDUHeadertype in [2, 3] then
  begin
    PDU.HeaderLen := 12;
    //Result:=SwapBytesInWord(PPDUHeader(PDU.Header)^.Error);
  end;

  if High(Msg) >= (Position + PDU.HeaderLen) then
    begin
      PDU.Param := @Msg[Position + PDU.HeaderLen];
      PDU.ParamLen := SwapBytesInWord(PPDUHeader(PDU.Header)^.ParamLen);

      if High(Msg) >= (Position + PDU.HeaderLen + PDU.ParamLen) then
        begin
          PDU.Data := @Msg[Position + PDU.HeaderLen + PDU.ParamLen];
          PDU.DataLen := SwapBytesInWord(PPDUHeader(PDU.Header)^.DataLen);

          if Length(Msg) < (Position + PDU.HeaderLen + PDU.ParamLen + PDU.DataLen) then
            Exit;
        end
      else
        begin
          PDU.Data := nil;
          PDU.DataLen := 0;
        end;
      PDU.UserDataLen := 0;
      PDU.uData := nil;
    end
  else
    begin
      PDU.Param := nil;
      PDU.ParamLen := 0;

      PDU.Data := nil;
      PDU.DataLen := 0;

      PDU.UserDataLen := 0;
      PDU.uData := nil;
    end;

  Result := True;
end;

procedure TSiemensProtocolFamily.PrepareReadRequest(var MsgOut: Bytes);
begin
  PrepareReadOrWriteRequest(False, MsgOut);
end;

procedure TSiemensProtocolFamily.PrepareWriteRequest(var MsgOut: Bytes);
begin
  PrepareReadOrWriteRequest(True, MsgOut);
end;

procedure TSiemensProtocolFamily.PrepareReadOrWriteRequest(const WriteRequest: Boolean; var MsgOut: Bytes);
var
  param: Bytes;
begin
  SetLength(param, 2);

  param[0] := IfThen(WriteRequest, S7FuncWrite, S7FuncRead);
  param[1] := 0;
  InitiatePDUHeader(MsgOut, 1);
  AddParam(MsgOut, param);

  SetLength(param, 0);
end;

procedure TSiemensProtocolFamily.AddToReadRequest(var MsgOut: Bytes; iArea, iDBnum, iStart, iByteCount: Longint);
var
  param: Bytes;
  p: PS7Req;
  PDU: TPDU;
  NumReq: Byte;
  intArray: array [0..3] of Byte;
  intStart: Longint absolute intArray;
  err: Longint;
begin
  SetLength(param, 12);
  param[00] := $12;
  param[01] := $0a;
  param[02] := $10;
  param[03] := $02; //1=single bit, 2=byte, 4=word
  param[04] := $00; //size of request
  param[05] := $00; //size of request
  param[06] := $00; //DB Number
  param[07] := $00; //DB Number
  param[08] := $00; //area code;
  param[09] := $00; //start address in bits
  param[10] := $00; //start address in bits
  param[11] := $00; //start address in bits

  p := PS7Req(@param[00]);

  with p^ do
  begin
    case iArea of
      vtS7_200_AnInput, vtS7_200_AnOutput:
        WordLen := 4;

      vtS7_Counter,
      vtS7_Timer,
      vtS7_200_Counter,
      vtS7_200_Timer:
        WordLen := iArea;
      else
        intStart := iStart * 8;
    end;

    ReqLength := SwapBytesInWord(iByteCount);
    DBNumber := SwapBytesInWord(iDBnum);
    AreaCode := iArea;
    HiBytes := 0;
    //StartAddress:=SwapBytesInWord(iStart);
    param[09] := intArray[2];
    param[10] := intArray[1];
    param[11] := intArray[0];
  end;

  AddParam(MsgOut, param);

  SetupPDU(MsgOut, True, PDU, err);
  NumReq := PDU.param[1];
  NumReq := NumReq + 1;
  PDU.param[1] := NumReq;

  SetLength(param, 0);
end;

//executa somente uma escrita por vez!!!
//executes only one write per request.
procedure TSiemensProtocolFamily.AddParamToWriteRequest(var MsgOut: Bytes; iArea, iDBnum, iStart: Longint; Buffer: Bytes);
var
  param: Bytes;
  bufferLen: Longint;
  p: PS7Req;
  PDU: TPDU;
  NumReq: Byte;
  err: Longint;
  intArray: array [0..3] of Byte;
  intStart: Longint absolute intArray;
begin
  bufferLen := Length(Buffer);

  SetLength(param, 12);
  param[00] := $12;
  param[01] := $0a;
  param[02] := $10;
  param[03] := $02; //1=single bit, 2=byte, 4=word
  param[04] := $00; //size of request
  param[05] := $00; //size of request
  param[06] := $00; //DB Number
  param[07] := $00; //DB Number
  param[08] := $00; //area code;
  param[09] := $00; //start address in bits
  param[10] := $00; //start address in bits
  param[11] := $00; //start address in bits

  p := PS7Req(@param[00]);

  with p^ do
  begin
    case iArea of
      vtS7_200_AnInput, vtS7_200_AnOutput:
      begin
        WordLen := 4;
        ReqLength := SwapBytesInWord((bufferLen + 1) div 2);
      end;
      vtS7_Counter,
      vtS7_Timer,
      vtS7_200_Counter,
      vtS7_200_Timer:
      begin
        WordLen := iArea;
        ReqLength := SwapBytesInWord((bufferLen + 1) div 2);
      end;
      else
      begin
        intStart := iStart * 8;
        ReqLength := SwapBytesInWord(bufferLen);
      end;
    end;

    DBNumber := SwapBytesInWord(iDBnum);
    AreaCode := iArea;
    HiBytes := 0;
    //StartAddress:=SwapBytesInWord(iStart);
    param[09] := intArray[2];
    param[10] := intArray[1];
    param[11] := intArray[0];
  end;

  AddParam(MsgOut, param);

  SetupPDU(MsgOut, True, PDU, err);
  NumReq := PDU.param[1];
  NumReq := NumReq + 1;
  PDU.param[1] := NumReq;

  SetLength(param, 0);
end;

procedure TSiemensProtocolFamily.AddDataToWriteRequest(var msgOut: Bytes; iArea, iDBnum, iStart: Longint; buffer: Bytes);
var
  da: Bytes;
  //extra:LongInt;
  bufferLen: Longint;
  lastdatabyte: Longint;
begin
  bufferLen := Length(buffer);

  //extra := 0; //(bufferlen mod 2);

  SetLength(da, 4 + bufferLen{+extra});
  da[00] := $00;
  da[01] := $04; //04 bits,
  da[02] := (bufferLen * 8) div 256;
  da[03] := (bufferLen * 8) mod 256;
  Move(buffer[0], da[4], Length(buffer));

  //if extra=1 then begin
  //  lastdatabyte:=High(da);
  //  da[lastdatabyte]:=$80;
  //end;

  AddData(msgOut, da);
end;

procedure TSiemensProtocolFamily.AddParam(var MsgOut: Bytes; const Param: Bytes);
var
  PDU: TPDU;
  paramlen, extra, newparamlen, err: Longint;
begin
  SetupPDU(MsgOut, True, PDU, err);
  paramlen := SwapBytesInWord(PPDUHeader(PDU.Header)^.ParamLen);
  newparamlen := Length(param);

  extra := IfThen(PPDUHeader(PDU.Header)^.PDUHeadertype in [2, 3], 2, 0);

  if Length(MsgOut) < (PDUOutgoing + 10 + extra + paramlen + newparamlen) then
  begin
    SetLength(MsgOut, (PDUOutgoing + 10 + extra + paramlen + newparamlen));
    SetupPDU(MsgOut, True, PDU, err);
    paramlen := SwapBytesInWord(PPDUHeader(PDU.Header)^.ParamLen);
  end;

  SetBytes(PDU.param, paramlen, param);
  PPDUHeader(PDU.Header)^.ParamLen := SwapBytesInWord(paramlen + Length(param));
end;

procedure TSiemensProtocolFamily.AddData(var MsgOut: Bytes; const Data: Bytes);
var
  PDU: TPDU;
  paramlen, datalen, extra, newdatalen, err: Longint;
begin
  SetupPDU(MsgOut, True, PDU, err);
  paramlen := SwapBytesInWord(PPDUHeader(PDU.Header)^.ParamLen);
  datalen := SwapBytesInWord(PPDUHeader(PDU.Header)^.DataLen);
  newdatalen := Length(Data);

  extra := IfThen(PPDUHeader(PDU.Header)^.PDUHeadertype in [2, 3], 2, 0);

  if Length(MsgOut) < (PDUOutgoing + 10 + extra + paramlen + datalen + newdatalen) then
  begin
    SetLength(MsgOut, (PDUOutgoing + 10 + extra + paramlen + datalen + newdatalen));
    SetupPDU(MsgOut, True, PDU, err);
    paramlen := SwapBytesInWord(PPDUHeader(PDU.Header)^.ParamLen);
    datalen := SwapBytesInWord(PPDUHeader(PDU.Header)^.DataLen);
  end;

  SetBytes(PDU.Data, datalen, Data);
  PPDUHeader(PDU.Header)^.DataLen := SwapBytesInWord(datalen + Length(Data));
end;

procedure TSiemensProtocolFamily.InitiatePDUHeader(var MsgOut: Bytes; PDUType: Longint);
var
  pduh: PPDUHeader;
  extra: Longint;
begin
  extra := IfThen(PDUType in [2, 3], 2, 0);

  if Length(MsgOut) < (PDUOutgoing + 10 + extra) then
    SetLength(MsgOut, (PDUOutgoing + 10 + extra));

  pduh := @MsgOut[PDUOutgoing];
  with pduh^ do
  begin
    p := $32;
    PDUHeadertype := PDUType;
    A := 0;
    B := 0;
    Number := 0;
    ParamLen := 0;
    DataLen := 0;
    //evita escrever se não foi alocado.
    // avoid write if not allocated.
    if extra = 2 then
    begin
      error := 0;
    end;
  end;
end;

procedure TSiemensProtocolFamily.ListReachablePartners;
begin

end;

////////////////////////////////////////////////////////////////////////////////
// FUNCOES DE MANIPULAÇAO DO DRIVER
// FUNCTIONS OF DRIVER HANDLING.
////////////////////////////////////////////////////////////////////////////////

function TSiemensProtocolFamily.DoublesToBytes(const Values: TArrayOfDouble; Start, Len: Longint): Bytes;
var
  arraylen, c: Longint;
begin
  arraylen := Length(Values);
  if (Start + (Len - 1)) >= arraylen then
    raise Exception.Create(SoutOfBounds);

  SetLength(Result, Len);
  for c := 0 to Len - 1 do
  begin
    Result[c] := trunc(Values[c + Start]) and $FF;
  end;
end;

function TSiemensProtocolFamily.BytesToDoubles(const ByteSeq: Bytes; Start, Len: Longint): TArrayOfDouble;
var
  arraylen, c: Longint;
begin
  arraylen := Length(ByteSeq);
  if (Start + (Len - 1)) >= arraylen then
    raise Exception.Create(SoutOfBounds);

  SetLength(Result, Len);
  for c := 0 to Len - 1 do
  begin
    Result[c] := ByteSeq[c + Start];
  end;
end;

function TSiemensProtocolFamily.CreatePLC(iRack, iSlot, iStation: Longint): Longint;
begin
  Result := Length(FPLCs);
  SetLength(FPLCs, Result + 1);
  FPLCs[Result].MaxBlockSize := 0; //must be 0 instead of -1 to avoid fragmentation
  FPLCs[Result].MaxPDULen := 0;
  FPLCs[Result].Connected := False;
  FPLCs[Result].Slot := iSlot;
  FPLCs[Result].Rack := iRack;
  FPLCs[Result].Station := iStation;

  FPLCs[Result].Inputs := TPLCMemoryManager.Create;
  FPLCs[Result].Outputs := TPLCMemoryManager.Create;
  FPLCs[Result].PeripheralInputs := TPLCMemoryManager.Create;
  FPLCs[Result].Timers := TPLCMemoryManager.Create;
  FPLCs[Result].Counters := TPLCMemoryManager.Create;
  FPLCs[Result].Flags := TPLCMemoryManager.Create;

  FPLCs[Result].S7200SMs := TPLCMemoryManager.Create;
  FPLCs[Result].S7200Timers := TPLCMemoryManager.Create;
  FPLCs[Result].S7200Counters := TPLCMemoryManager.Create;
  FPLCs[Result].S7200AnInput := TPLCMemoryManager.Create;
  FPLCs[Result].S7200AnOutput := TPLCMemoryManager.Create;

  FPLCs[Result].Inputs.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].Outputs.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].PeripheralInputs.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].Timers.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].Counters.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].Flags.MaxBlockItems := FPLCs[Result].MaxBlockSize;

  FPLCs[Result].S7200SMs.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].S7200Timers.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].S7200Counters.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].S7200AnInput.MaxBlockItems := FPLCs[Result].MaxBlockSize;
  FPLCs[Result].S7200AnOutput.MaxBlockItems := FPLCs[Result].MaxBlockSize;
end;

procedure TSiemensProtocolFamily.DeletePLC(PLCIndex: Integer);
var
  hPLC: Integer;
  db: Integer;
begin
  hPLC := High(FPLCs);

  if (PLCIndex >= 0) and (PLCIndex <= hPLC) then
  begin
    FPLCs[PLCIndex].Inputs.Destroy;
    FPLCs[PLCIndex].Outputs.Destroy;
    FPLCs[PLCIndex].PeripheralInputs.Destroy;

    for db := 0 to High(FPLCs[PLCIndex].DBs) do
    begin
      FPLCs[PLCIndex].DBs[db].DBArea.Destroy;
    end;
    SetLength(FPLCs[PLCIndex].DBs, 0);

    FPLCs[PLCIndex].Timers.Destroy;
    FPLCs[PLCIndex].Counters.Destroy;
    FPLCs[PLCIndex].Flags.Destroy;

    FPLCs[PLCIndex].S7200SMs.Destroy;
    FPLCs[PLCIndex].S7200Timers.Destroy;
    FPLCs[PLCIndex].S7200Counters.Destroy;
    FPLCs[PLCIndex].S7200AnInput.Destroy;
    FPLCs[PLCIndex].S7200AnOutput.Destroy;

    FPLCs[PLCIndex] := FPLCs[hPLC];
    SetLength(FPLCs, hPLC);
  end;
end;

procedure TSiemensProtocolFamily.UpdateMemoryManager(PkgIn, PkgOut: Bytes; WritePkg: Boolean; ReqList: TS7ReqList; var ResultValues: TArrayOfDouble);
var
  PDU: TPDU;
  NumResults: Longint;
  CurResult: Longint;
  ADataLen: Longint;
  DataIdx: Longint;
  AResultLen: Longint;
  ResultCode: Longint;
  CurValue: Longint;
  Err: Longint;
  ProtocolErrorCode: TProtocolIOResult;
begin
  if WritePkg then
    begin
      if not SetupPDU(PkgOut, True, PDU, Err) then
        Exit;
      if (PDU.param = nil) or (PDU.param[0] <> S7FuncWrite) then
        Exit;
    end
  else
    begin
      if not SetupPDU(PkgIn, False, PDU, Err) then
        Exit;
      if (PDU.param = nil) or (PDU.param[0] <> S7FuncRead) then
        Exit;
    end;
  NumResults := Min(PDU.param[1], Length(ReqList));
  CurResult := 0;
  DataIdx := 0;
  ADataLen := PDU.DataLen;
  while CurResult < NumResults do
  begin
    ResultCode := PDU.Data[DataIdx];

    if WritePkg and (ResultCode = 0) then
      ProtocolErrorCode := ioOk
    else
      ProtocolErrorCode := S7ErrorCodeToProtocolErrorCode(ResultCode);

    if (WritePkg or (ResultCode = $FF)) and (ADataLen > 4) then
    begin
      AResultLen := PDU.Data[DataIdx + 2] * $100 + PDU.Data[DataIdx + 3];
      //o tamanho está em bits, precisa de ajuste.
      //if the size is in bits, adjust to Bytes
      if PDU.Data[DataIdx + 1] = 4 then
        AResultLen := AResultLen div 8
      else
      begin
        //3 o restultado já está em Bytes
        //e 9 o resultado está em bits, mas cada bit em um byte.
        //if 3, the result already is in Bytes
        //if 9, the result is in bits, but each byte stores one bit
        if not (PDU.Data[DataIdx + 1] in [3, 9]) then
          Exit;
      end;
    end
    else
    begin
      if ResultCode = $FF then
        ProtocolErrorCode := ioEmptyPacket;
      AResultLen := 0;
    end;

    //move os dados recebidos para as respectivas areas.
    //move the received data to their area.
    SetLength(ResultValues, 0);
    if AResultLen > 0 then
    begin
      SetLength(ResultValues, AResultLen);
      CurValue := 0;
      while (CurValue < AResultLen) and (CurValue < Length(ResultValues)) do
      begin
        ResultValues[CurValue] := PDU.Data[DataIdx + 4 + CurValue];
        Inc(CurValue);
      end;

      FProtocolReady := True;

      with ReqList[CurResult] do
      begin
        if (PLCIdx >= 0) and (PLCIdx <= High(FPLCs)) then
          case ReqType of
            vtS7_DB:
              if (DBIdx >= 0) and (DBIdx <= High(FPLCs[PLCIdx].DBs)) then
                FPLCs[PLCIdx].DBs[DBIdx].DBArea.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_Inputs:
              FPLCs[PLCIdx].Inputs.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_Outputs:
              FPLCs[PLCIdx].Outputs.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_200_AnInput:
              FPLCs[PLCIdx].S7200AnInput.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_200_AnOutput:
              FPLCs[PLCIdx].S7200AnOutput.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_Timer:
              FPLCs[PLCIdx].Timers.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_Counter:
              FPLCs[PLCIdx].Counters.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_Flags:
              FPLCs[PLCIdx].Flags.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_200_SM:
              FPLCs[PLCIdx].S7200SMs.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_200_Timer:
              FPLCs[PLCIdx].S7200Timers.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_200_Counter:
              FPLCs[PLCIdx].S7200Counters.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
            vtS7_Peripheral:
              FPLCs[PLCIdx].PeripheralInputs.SetValues(StartAddress, AResultLen, 1, ResultValues, ProtocolErrorCode);
          end;
      end;
    end
    else
    begin
      //seta a falha...
      //sets the fault.
      with ReqList[CurResult] do
      begin
        if (PLCIdx >= 0) and (PLCIdx <= High(FPLCs)) then
          case ReqType of
            vtS7_DB:
              if (DBIdx >= 0) and (DBIdx <= High(FPLCs[PLCIdx].DBs)) then
                FPLCs[PLCIdx].DBs[DBIdx].DBArea.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_Inputs:
              FPLCs[PLCIdx].Inputs.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_Outputs:
              FPLCs[PLCIdx].Outputs.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_200_AnInput:
              FPLCs[PLCIdx].S7200AnInput.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_200_AnOutput:
              FPLCs[PLCIdx].S7200AnOutput.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_Timer:
              FPLCs[PLCIdx].Timers.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_Counter:
              FPLCs[PLCIdx].Counters.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_Flags:
              FPLCs[PLCIdx].Flags.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_200_SM:
              FPLCs[PLCIdx].S7200SMs.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_200_Timer:
              FPLCs[PLCIdx].S7200Timers.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_200_Counter:
              FPLCs[PLCIdx].S7200Counters.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
            vtS7_Peripheral:
              FPLCs[PLCIdx].PeripheralInputs.SetFault(StartAddress, Size, 1, ProtocolErrorCode, True);
          end;
      end;
    end;

    DataIdx := DataIdx + AResultLen + 4;
    Dec(ADataLen, AResultLen);

    //pelo que entendi, um resultado nunca vem com tamanho impar
    //no pacote.
    //the size of result never is a odd number
    if (AResultLen mod 2) = 1 then
    begin
      Inc(DataIdx);
      Dec(ADataLen);
    end;

    //proximo resultado.
    //goto the next result.
    Inc(CurResult);
  end;
end;

procedure TSiemensProtocolFamily.DoAddTag(tagobj: TTag; TagValid: Boolean);
var
  plc, db: Longint;
  tr: TTagRec;
  foundplc, founddb, valido: Boolean;
begin
  tr := GetTagInfo(tagobj);
  foundplc := False;

  valido := True;

  for plc := 0 to High(FPLCs) do
    if (FPLCs[plc].Slot = tr.Slot) and (FPLCs[plc].Rack = tr.Rack) and (FPLCs[plc].Station = tr.Station) then
    begin
      foundplc := True;
      Break;
    end;

  if not foundplc then
  begin
    plc := CreatePLC(tr.Rack, tr.Slot, tr.Station);
  end;

  case tr.ReadFunction of
    1:
      FPLCs[plc].Inputs.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    2:
      FPLCs[plc].Outputs.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    3:
      FPLCs[plc].Flags.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    4: begin
      if tr.File_DB = 0 then
        tr.File_DB := 1;

      if (tr.File_DB < 0) or (tr.File_DB > 65535) then
      begin
        valido := False;
      end
      else
      begin

        founddb := False;
        for db := 0 to High(FPLCs[plc].DBs) do
          if FPLCs[plc].DBs[db].DBNum = tr.File_DB then
          begin
            founddb := True;
            Break;
          end;

        if not founddb then
        begin
          db := Length(FPLCs[plc].DBs);
          SetLength(FPLCs[plc].DBs, db + 1);
          FPLCs[plc].DBs[db].DBNum := tr.File_DB;
          FPLCs[plc].DBs[db].DBArea := TPLCMemoryManager.Create;
          FPLCs[plc].DBs[db].DBArea.MaxBlockItems := FPLCs[plc].MaxBlockSize;
        end;

        FPLCs[plc].DBs[db].DBArea.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
      end;
    end;
    5:
      FPLCs[plc].Counters.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    6:
      FPLCs[plc].Timers.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    7:
      FPLCs[plc].S7200SMs.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    8:
      FPLCs[plc].S7200AnInput.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    9:
      FPLCs[plc].S7200AnOutput.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    10:
      FPLCs[plc].S7200Counters.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    11:
      FPLCs[plc].S7200Timers.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    12:
      FPLCs[plc].PeripheralInputs.AddAddress(tr.Address, tr.Size, 1, tr.UpdateTime);
    else
      valido := False;
  end;

  inherited DoAddTag(tagobj, valido);
end;

procedure TSiemensProtocolFamily.DoDelTag(tagobj: TTag);
var
  plc, db: Longint;
  tr: TTagRec;
  foundplc, founddb: Boolean;
  TotalSize: Integer;
  hDB: Integer;
begin
  try
    tr := GetTagInfo(tagobj);
    foundplc := False;

    for plc := 0 to High(FPLCs) do
      if (FPLCs[plc].Slot = tr.Slot) and (FPLCs[plc].Rack = tr.Rack) and (FPLCs[plc].Station = tr.Station) then
      begin
        foundplc := True;
        Break;
      end;

    if not foundplc then Exit;

    case tr.ReadFunction of
      1: begin
        FPLCs[plc].Inputs.RemoveAddress(tr.Address, tr.Size, 1);
      end;
      2:
        FPLCs[plc].Outputs.RemoveAddress(tr.Address, tr.Size, 1);
      3:
        FPLCs[plc].Flags.RemoveAddress(tr.Address, tr.Size, 1);
      4: begin
        if tr.File_DB <= 0 then
          tr.File_DB := 1;

        founddb := False;
        for db := 0 to High(FPLCs[plc].DBs) do
          if FPLCs[plc].DBs[db].DBNum = tr.File_DB then
          begin
            founddb := True;
            Break;
          end;

        if not founddb then Exit;

        FPLCs[plc].DBs[db].DBArea.RemoveAddress(tr.Address, tr.Size, 1);

        //delete the DB if their size = 0
        if FPLCs[plc].DBs[db].DBArea.Size = 0 then
        begin
          hDB := High(FPLCs[plc].DBs);
          FreeAndNil(FPLCs[plc].DBs[db].DBArea);
          FPLCs[plc].DBs[db] := FPLCs[plc].DBs[hDB];
          SetLength(FPLCs[plc].DBs, hDB);
        end;
      end;
      5:
        FPLCs[plc].Counters.RemoveAddress(tr.Address, tr.Size, 1);
      6:
        FPLCs[plc].Timers.RemoveAddress(tr.Address, tr.Size, 1);
      7:
        FPLCs[plc].S7200SMs.RemoveAddress(tr.Address, tr.Size, 1);
      8:
        FPLCs[plc].S7200AnInput.RemoveAddress(tr.Address, tr.Size, 1);
      9:
        FPLCs[plc].S7200AnOutput.RemoveAddress(tr.Address, tr.Size, 1);
      10:
        FPLCs[plc].S7200Counters.RemoveAddress(tr.Address, tr.Size, 1);
      11:
        FPLCs[plc].S7200Timers.RemoveAddress(tr.Address, tr.Size, 1);
      12:
        FPLCs[plc].PeripheralInputs.RemoveAddress(tr.Address, tr.Size, 1);
    end;

    //check if current plc has something to be read...
    TotalSize := 0;
    Inc(TotalSize, FPLCs[plc].Inputs.Size);
    Inc(TotalSize, FPLCs[plc].Outputs.Size);
    Inc(TotalSize, FPLCs[plc].PeripheralInputs.Size);

    for db := 0 to High(FPLCs[plc].DBs) do
      Inc(TotalSize, FPLCs[plc].DBs[db].DBArea.Size);

    Inc(TotalSize, FPLCs[plc].Timers.Size);
    Inc(TotalSize, FPLCs[plc].Counters.Size);
    Inc(TotalSize, FPLCs[plc].Flags.Size);

    Inc(TotalSize, FPLCs[plc].S7200SMs.Size);
    Inc(TotalSize, FPLCs[plc].S7200Timers.Size);
    Inc(TotalSize, FPLCs[plc].S7200Counters.Size);
    Inc(TotalSize, FPLCs[plc].S7200AnInput.Size);
    Inc(TotalSize, FPLCs[plc].S7200AnOutput.Size);

    //if current plc has nothing to be read
    //delete it...
    if (TotalSize = 0) and (not FPLCs[plc].Connected) then
      DeletePLC(plc);
  finally
    inherited DoDelTag(tagobj);
  end;
end;

procedure TSiemensProtocolFamily.DoScanRead(Sender: TObject; var NeedSleep: Longint);
var
  plc, db, block, retries: Longint;
  FMaxUpdtRate: Integer = 0;
  msgOut, msgIn: Bytes;
  initialized: Boolean;
  ReqList: TS7ReqList;
  ReqOutOfScan: TS7ReqList;
  MsgOutSize: Longint;
  RequestsPendding: Boolean;

  OutgoingPDUSize, IncomingPDUSize: Longint;
  OutOffScanOutgoingPDUSize, OutOffScanIncomingPDUSize: Longint;

  ivalues: TArrayOfDouble;
  EntireTagList: TS7ScanReqList;
  ReqItem, ReqItem2: TS7ScanReqItem;
  c, c2, FNextReadIn: Integer;
  started: TDateTime;

  procedure pkg_initialized;
  begin
    if not initialized then
    begin
      OutgoingPDUSize := 10 + 2; //10 of header + 2 Bytes of read request;
      IncomingPDUSize := 10 + 2 + 2; //10 of header + 2 Bytes of the error code + 2 Bytes of the read request;
      MsgOutSize := PDUOutgoing + 12;
      SetLength(msgOut, MsgOutSize);
      PrepareReadRequest(msgOut);
      initialized := True;
    end;
  end;

  function AcceptThisRequest(CPU: TS7CPU; iSize: Longint): Boolean;
  begin
    if ((OutgoingPDUSize + 12) < CPU.MaxPDULen) and ((IncomingPDUSize + 4 + iSize) < CPU.MaxPDULen) then
      Result := True
    else
      Result := False;
  end;

  function OutOfScanAcceptThisRequest(CPU: TS7CPU; iSize: Longint): Boolean;
  begin
    if ((OutOffScanOutgoingPDUSize + 12) < CPU.MaxPDULen) and ((OutOffScanIncomingPDUSize + 4 + iSize) < CPU.MaxPDULen) then
      Result := True
    else
      Result := False;
  end;

  procedure QueueOutOfScanReq(iPLC, iDB, iReqType, iStartAddress, iSize: Longint);
  var
    h: Longint;
  begin
    h := Length(ReqOutOfScan);
    SetLength(ReqOutOfScan, h + 1);
    with ReqOutOfScan[h] do
    begin
      PLCIdx := iPLC;
      DBIdx := iDB;
      ReqType := iReqType;
      StartAddress := iStartAddress;
      Size := iSize;
    end;
    Inc(OutOffScanIncomingPDUSize, 4 + iSize);
    if (iSize mod 2) = 1 then
      Inc(OutOffScanIncomingPDUSize);

    Inc(OutOffScanOutgoingPDUSize, 12);
  end;

  procedure AddToReqList(iPLC, iDB, iReqType, iStartAddress, iSize: Longint);
  var
    h: Longint;
  begin
    h := Length(ReqList);
    SetLength(ReqList, h + 1);
    with ReqList[h] do
    begin
      PLCIdx := iPLC;
      DBIdx := iDB;
      ReqType := iReqType;
      StartAddress := iStartAddress;
      Size := iSize;
    end;
    Inc(MsgOutSize, 12);
    Inc(IncomingPDUSize, 4 + iSize);
    IncomingPDUSize := IncomingPDUSize + (iSize mod 2);

    Inc(OutgoingPDUSize, 12);

    SetLength(msgOut, MsgOutSize);
    RequestsPendding := True;
  end;

  procedure Reset;
  begin
    initialized := False;
    OutgoingPDUSize := 0;
    IncomingPDUSize := 0;
    MsgOutSize := 0;
    RequestsPendding := False;
    SetLength(ReqList, 0);
    SetLength(msgOut, 0);
    SetLength(msgIn, 0);
  end;

  procedure ReadQueuedRequests(var CPU: TS7CPU);
  begin
    if Exchange(CPU, msgOut, msgIn, False) then
    begin
      UpdateMemoryManager(msgIn, msgOut, False, ReqList, ivalues);
      NeedSleep := -1;
    end
    else
      NeedSleep := 1;
    Reset;
  end;

  procedure AddToTagList(iPLC, iDB, iDBnum, iReqType, iStartAddress, iSize, UpdateRate: Longint; LastUpdate: TDateTime; NeedUpdate: Boolean);
  var
    info: TS7ScanReqItem;
  begin
    //New(info);
    info.iPLC := iPLC;
    info.iDB := iDB;
    info.iDBnum := iDBnum;
    info.iReqType := iReqType;
    info.iStartAddress := iStartAddress;
    info.iSize := iSize;
    info.LastUpdate := LastUpdate;
    info.UpdateRate := UpdateRate;
    info.NeedUpdate := NeedUpdate;
    info.Read := False;
    info.NextUpdtInMs := MilliSecondsBetween(Now, LastUpdate); //just for debugging
    info.NextUpdtInMs := max(0, UpdateRate - info.NextUpdtInMs);
    if UpdateRate > 0 then
      FMaxUpdtRate := max(FMaxUpdtRate, UpdateRate);

    EntireTagList.add(info);
  end;

begin
  retries := 0;
  while (not FAdapterInitialized) and (retries < 3) do
  begin
    FAdapterInitialized := InitAdapter;
    Inc(retries);
  end;

  if retries >= 3 then
  begin
    NeedSleep := 500;
    Exit;
  end;

  NeedSleep := IfThen(Length(FPLCs) <= 0, 500, -10);
  FNextReadIn := $7FFFFFFF;

  EntireTagList := TS7ScanReqList.Create;
  try
    for plc := 0 to High(FPLCs) do
    begin
      if not FPLCs[plc].Connected then
        if not ConnectPLC(FPLCs[plc]) then
        begin
          NeedSleep := 500;
          Exit;
        end;
      Reset;
      OutOffScanOutgoingPDUSize := 0;
      OutOffScanIncomingPDUSize := 0;

      //DBs     //////////////////////////////////////////////////////////////////
      for db := 0 to High(FPLCs[plc].DBs) do
      begin
        for block := 0 to High(FPLCs[plc].DBs[db].DBArea.Blocks) do
        begin
          AddToTagList(plc,
            db,
            FPLCs[plc].DBs[db].DBNum,
            vtS7_DB,
            FPLCs[plc].DBs[db].DBArea.Blocks[block].AddressStart,
            FPLCs[plc].DBs[db].DBArea.Blocks[block].Size,
            FPLCs[plc].DBs[db].DBArea.Blocks[block].ScanTime,
            FPLCs[plc].DBs[db].DBArea.Blocks[block].LastUpdate,
            FPLCs[plc].DBs[db].DBArea.Blocks[block].NeedRefresh);
        end;
      end;

      //INPUTS////////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].Inputs.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_Inputs,
          FPLCs[plc].Inputs.Blocks[block].AddressStart,
          FPLCs[plc].Inputs.Blocks[block].Size,
          FPLCs[plc].Inputs.Blocks[block].ScanTime,
          FPLCs[plc].Inputs.Blocks[block].LastUpdate,
          FPLCs[plc].Inputs.Blocks[block].NeedRefresh);
      end;

      //OUTPUTS///////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].Outputs.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_Outputs,
          FPLCs[plc].Outputs.Blocks[block].AddressStart,
          FPLCs[plc].Outputs.Blocks[block].Size,
          FPLCs[plc].Outputs.Blocks[block].ScanTime,
          FPLCs[plc].Outputs.Blocks[block].LastUpdate,
          FPLCs[plc].Outputs.Blocks[block].NeedRefresh);
      end;

      //Timers///////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].Timers.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_Timer,
          FPLCs[plc].Timers.Blocks[block].AddressStart,
          FPLCs[plc].Timers.Blocks[block].Size,
          FPLCs[plc].Timers.Blocks[block].ScanTime,
          FPLCs[plc].Timers.Blocks[block].LastUpdate,
          FPLCs[plc].Timers.Blocks[block].NeedRefresh);
      end;

      //Counters//////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].Counters.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_Counter,
          FPLCs[plc].Counters.Blocks[block].AddressStart,
          FPLCs[plc].Counters.Blocks[block].Size,
          FPLCs[plc].Counters.Blocks[block].ScanTime,
          FPLCs[plc].Counters.Blocks[block].LastUpdate,
          FPLCs[plc].Counters.Blocks[block].NeedRefresh);
      end;

      //Flags///////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].Flags.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_Flags,
          FPLCs[plc].Flags.Blocks[block].AddressStart,
          FPLCs[plc].Flags.Blocks[block].Size,
          FPLCs[plc].Flags.Blocks[block].ScanTime,
          FPLCs[plc].Flags.Blocks[block].LastUpdate,
          FPLCs[plc].Flags.Blocks[block].NeedRefresh);
      end;

      //PeripheralInputs///////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].PeripheralInputs.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_Peripheral,
          FPLCs[plc].PeripheralInputs.Blocks[block].AddressStart,
          FPLCs[plc].PeripheralInputs.Blocks[block].Size,
          FPLCs[plc].PeripheralInputs.Blocks[block].ScanTime,
          FPLCs[plc].PeripheralInputs.Blocks[block].LastUpdate,
          FPLCs[plc].PeripheralInputs.Blocks[block].NeedRefresh);
      end;

      //S7200AnInput///////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].S7200AnInput.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_200_AnInput,
          FPLCs[plc].S7200AnInput.Blocks[block].AddressStart,
          FPLCs[plc].S7200AnInput.Blocks[block].Size,
          FPLCs[plc].S7200AnInput.Blocks[block].ScanTime,
          FPLCs[plc].S7200AnInput.Blocks[block].LastUpdate,
          FPLCs[plc].S7200AnInput.Blocks[block].NeedRefresh);
      end;

      //S7200AnOutput//////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].S7200AnOutput.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_200_AnOutput,
          FPLCs[plc].S7200AnOutput.Blocks[block].AddressStart,
          FPLCs[plc].S7200AnOutput.Blocks[block].Size,
          FPLCs[plc].S7200AnOutput.Blocks[block].ScanTime,
          FPLCs[plc].S7200AnOutput.Blocks[block].LastUpdate,
          FPLCs[plc].S7200AnOutput.Blocks[block].NeedRefresh);
      end;

      //S7200Timers///////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].S7200Timers.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_200_Timer,
          FPLCs[plc].S7200Timers.Blocks[block].AddressStart,
          FPLCs[plc].S7200Timers.Blocks[block].Size,
          FPLCs[plc].S7200Timers.Blocks[block].ScanTime,
          FPLCs[plc].S7200Timers.Blocks[block].LastUpdate,
          FPLCs[plc].S7200Timers.Blocks[block].NeedRefresh);
      end;

      //S7200Counters//////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].S7200Counters.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_200_Counter,
          FPLCs[plc].S7200Counters.Blocks[block].AddressStart,
          FPLCs[plc].S7200Counters.Blocks[block].Size,
          FPLCs[plc].S7200Counters.Blocks[block].ScanTime,
          FPLCs[plc].S7200Counters.Blocks[block].LastUpdate,
          FPLCs[plc].S7200Counters.Blocks[block].NeedRefresh);
      end;

      //S7200SMs//////////////////////////////////////////////////////////////////
      for block := 0 to High(FPLCs[plc].S7200SMs.Blocks) do
      begin
        AddToTagList(plc,
          0,
          0,
          vtS7_200_SM,
          FPLCs[plc].S7200SMs.Blocks[block].AddressStart,
          FPLCs[plc].S7200SMs.Blocks[block].Size,
          FPLCs[plc].S7200SMs.Blocks[block].ScanTime,
          FPLCs[plc].S7200SMs.Blocks[block].LastUpdate,
          FPLCs[plc].S7200SMs.Blocks[block].NeedRefresh);
      end;

      EntireTagList.Sort(@SortGenericTagList);
      started := Now;

      RequestsPendding := False;
      FNextReadIn := $7FFFFFFF;
      for c := 0 to EntireTagList.Count - 1 do
      begin
        ReqItem := EntireTagList.Items[c];
        //if tag was read on a previous PDU fill, go to next...
        if ReqItem.Read then Continue;

        //if ReadSomethingAlways is disabled and tag don't need to be updated, go to next.
        if (PReadSomethingAlways = False) and (ReqItem.NeedUpdate = False) then
        begin
          FNextReadIn := Min(FNextReadIn, ReqItem.NextUpdtInMs);
          Continue;
        end;

        if not AcceptThisRequest(FPLCs[ReqItem.iPLC], ReqItem.iSize) then
        begin
          for c2 := (c + 1) to EntireTagList.Count - 1 do
          begin
            ReqItem2 := EntireTagList.Items[c2];
            if ReqItem2.Read then Continue;

            if AcceptThisRequest(FPLCs[ReqItem2.iPLC], ReqItem2.iSize) then
            begin
              AddToReqList(ReqItem2.iPLC, ReqItem2.iDB, ReqItem2.iReqType, ReqItem2.iStartAddress, ReqItem2.iSize);
              AddToReadRequest(msgOut, ReqItem2.iReqType, ReqItem2.iDBnum, ReqItem2.iStartAddress, ReqItem2.iSize);
              ReqItem2.Read := True;
            end;
          end;
          ReadQueuedRequests(FPLCs[ReqItem.iPLC]);
          Reset;
          FNextReadIn := 0; //IO acts as a sleep
          Break;
          if ReqItem.NeedUpdate = False then Exit;
        end;
        pkg_initialized;

        AddToReqList(ReqItem.iPLC, ReqItem.iDB, ReqItem.iReqType, ReqItem.iStartAddress, ReqItem.iSize);
        AddToReadRequest(msgOut, ReqItem.iReqType, ReqItem.iDBnum, ReqItem.iStartAddress, ReqItem.iSize);

        ReqItem.Read := True;
      end;
      if RequestsPendding then
      begin
        ReadQueuedRequests(FPLCs[plc]);
      end;

      EntireTagList.Clear;
    end;
  finally
    if FNextReadIn <> $7fffffff then
    begin
      NeedSleep := Min(FMaxUpdtRate, FNextReadIn) - 1; //sleep and wakeup in X-1 ms
    end;

    if (PReadSomethingAlways) and (Length(FPLCs) > 0) and PCommPort.ReallyActive then
      NeedSleep := -10; //do not sleep

    FreeAndNil(EntireTagList);
  end;

  SetLength(ivalues, 0);
  SetLength(msgIn, 0);
  SetLength(msgOut, 0);
  SetLength(ReqList, 0);
end;

procedure TSiemensProtocolFamily.DoGetValue(TagRec: TTagRec; var values: TScanReadRec);
var
  plc, db: Longint;
  foundplc, founddb: Boolean;
begin
  foundplc := False;

  for plc := 0 to High(FPLCs) do
    if (FPLCs[plc].Slot = TagRec.Slot) and (FPLCs[plc].Rack = TagRec.Rack) and (FPLCs[plc].Station = TagRec.Station) then
    begin
      foundplc := True;
      Break;
    end;

  if not foundplc then Exit;

  SetLength(values.values, TagRec.Size);

  case TagRec.ReadFunction of
    1:
      FPLCs[plc].Inputs.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    2:
      FPLCs[plc].Outputs.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    3:
      FPLCs[plc].Flags.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    4: begin
      if TagRec.File_DB <= 0 then
        TagRec.File_DB := 1;

      founddb := False;
      for db := 0 to High(FPLCs[plc].DBs) do
        if FPLCs[plc].DBs[db].DBNum = TagRec.File_DB then
        begin
          founddb := True;
          Break;
        end;

      if not founddb then Exit;

      FPLCs[plc].DBs[db].DBArea.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    end;
    5:
      FPLCs[plc].Counters.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    6:
      FPLCs[plc].Timers.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    7:
      FPLCs[plc].S7200SMs.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    8:
      FPLCs[plc].S7200AnInput.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    9:
      FPLCs[plc].S7200AnOutput.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    10:
      FPLCs[plc].S7200Counters.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    11:
      FPLCs[plc].S7200Timers.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
    12:
      FPLCs[plc].PeripheralInputs.GetValues(TagRec.Address, TagRec.Size, 1, values.values, values.LastQueryResult, values.ValuesTimestamp);
  end;
end;

function TSiemensProtocolFamily.DoWrite(const TagRec: TTagRec; const values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  c, OutgoingPacketSize, MaxBytesToSend, retries, BytesToSend, BytesSent, ReqType, DBIdx, err: Longint;
  foundplc, hasAtLeastOneSuccess: Boolean;
  PLCPtr: PS7CPU;
  msgOut, msgIn, BytesBuffer: Bytes;
  incomingPDU: TPDU;
  ReqList: TS7ReqList;
  ivalues: TArrayOfDouble;
  founddb: Boolean;
begin
  PLCPtr := nil;
  foundplc := False;
  DBIdx := -1;
  SetLength(msgIn, 0);
  SetLength(ivalues, 0);
  for c := 0 to High(FPLCs) do
    if (FPLCs[c].Slot = TagRec.Slot) and (FPLCs[c].Rack = TagRec.Rack) and (FPLCs[c].Station = TagRec.Station) then
    begin
      PLCPtr := @FPLCs[c];
      foundplc := True;
      Break;
    end;

  if PLCPtr = nil then
  begin
    c := CreatePLC(TagRec.Rack, TagRec.Slot, TagRec.Station);
    PLCPtr := @FPLCs[c];
  end;

  retries := 0;
  while (not FAdapterInitialized) and (retries < 3) do
  begin
    FAdapterInitialized := InitAdapter;
    Inc(retries);
  end;

  if retries >= 3 then
  begin
    Result := ioAdapterInitFail;
    Exit;
  end;

  if not PLCPtr^.Connected then
    if not ConnectPLC(PLCPtr^) then
    begin
      Result := ioConnectPLCFailed;
      Exit;
    end;

  case TagRec.ReadFunction of
    1:
      ReqType := vtS7_Inputs;
    2:
      ReqType := vtS7_Outputs;
    3:
      ReqType := vtS7_Flags;
    4: begin
      ReqType := vtS7_DB;
      founddb := False;
      if foundplc then
        for DBIdx := 0 to High(PLCPtr^.DBs) do
          if PLCPtr^.DBs[DBIdx].DBNum = TagRec.File_DB then
          begin
            founddb := True;
            Break;
          end;
    end;
    5:
      ReqType := vtS7_Counter;
    6:
      ReqType := vtS7_Timer;
    7:
      ReqType := vtS7_200_SM;
    8:
      ReqType := vtS7_200_AnInput;
    9:
      ReqType := vtS7_200_AnOutput;
    10:
      ReqType := vtS7_200_Counter;
    11:
      ReqType := vtS7_200_Timer;
    12:
      ReqType := vtS7_Peripheral;
    else
    begin
      Result := ioTagError;
      Exit;
    end;
  end;

  MaxBytesToSend := PLCPtr^.MaxPDULen - 28;
  BytesSent := 0;
  hasAtLeastOneSuccess := False;

  while BytesSent < Length(values) do
  begin
    SetLength(msgOut, 0);

    BytesToSend := Min(MaxBytesToSend, Length(values) - BytesSent);

    OutgoingPacketSize := PDUOutgoing + 28 + BytesToSend;

    SetLength(msgOut, OutgoingPacketSize);

    PrepareWriteRequest(msgOut);

    BytesBuffer := DoublesToBytes(values, BytesSent, BytesToSend);

    if ReqType = vtS7_DB then
    begin
      if TagRec.File_DB = 0 then
      begin
        AddParamToWriteRequest(msgOut, vtS7_DB, 1, TagRec.Address + TagRec.OffSet + BytesSent, BytesBuffer);
        AddDataToWriteRequest(msgOut, vtS7_DB, 1, TagRec.Address + TagRec.OffSet + BytesSent, BytesBuffer);
      end
      else
      begin
        AddParamToWriteRequest(msgOut, vtS7_DB, TagRec.File_DB, TagRec.Address + TagRec.OffSet + BytesSent, BytesBuffer);
        AddDataToWriteRequest(msgOut, vtS7_DB, TagRec.File_DB, TagRec.Address + TagRec.OffSet + BytesSent, BytesBuffer);
      end;
    end
    else
    begin
      AddParamToWriteRequest(msgOut, ReqType, 0, TagRec.Address + TagRec.OffSet + BytesSent, BytesBuffer);
      AddDataToWriteRequest(msgOut, ReqType, 0, TagRec.Address + TagRec.OffSet + BytesSent, BytesBuffer);
    end;

    if Exchange(PLCPtr^, msgOut, msgIn, True) and SetupPDU(msgIn, False, incomingPDU, err) then
      begin
        if (incomingPDU.DataLen > 0) and (incomingPDU.Data[0] = $FF) then
          begin
            hasAtLeastOneSuccess := True;
            Result := ioOk;
            if foundplc then
            begin
              SetLength(ReqList, 1);
              ReqList[0].DBIdx := IfThen(founddb, DBIdx, -1);
              ReqList[0].PLCIdx := c;
              ReqList[0].ReqType := ReqType;
              ReqList[0].StartAddress := TagRec.Address + BytesSent + TagRec.OffSet;
              ReqList[0].Size := BytesToSend;
              UpdateMemoryManager(msgIn, msgOut, True, ReqList, ivalues);
            end;
          end
        else
          begin
            if hasAtLeastOneSuccess then
              begin
                Result := ioPartialOk;
              end
            else if incomingPDU.DataLen > 0 then
              begin
                Result := S7ErrorCodeToProtocolErrorCode(incomingPDU.Data[0]);
              end
            else
              Result := ioCommError;
            Exit;
          end;
      end
    else
      begin
        if hasAtLeastOneSuccess then
          begin
            Result := ioPartialOk;
          end
        else
          Result := ioCommError;

        Exit;
      end;

    Inc(BytesSent, BytesToSend);
  end;

  SetLength(ivalues, 0);
end;

function TSiemensProtocolFamily.DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  c: Longint;
  IncomingPacketSize: Longint;
  OutgoingPacketSize: Longint;
  MaxBytesToRecv: Longint;
  Retries: Longint;
  BytesToRecv: Longint;
  BytesReceived: Longint;
  ReqType: Longint;
  DBIdx: Longint;
  Err: Longint;
  FoundPLC: Boolean;
  hasAtLeastOneSuccess: Boolean;
  PLCPtr: PS7CPU;
  MsgOut: Bytes;
  MsgIn: Bytes;
  IncomingPDU: TPDU;
  ReqList: TS7ReqList;
  iValues: TArrayOfDouble;
  FoundDb: Boolean;
begin
  PLCPtr := nil;
  FoundPLC := False;
  DBIdx := -1;
  SetLength(iValues, 0);
  for c := 0 to High(FPLCs) do
    if (FPLCs[c].Slot = TagRec.Slot) and (FPLCs[c].Rack = TagRec.Rack) and (FPLCs[c].Station = TagRec.Station) then
    begin
      PLCPtr := @FPLCs[c];
      FoundPLC := True;
      Break;
    end;

  if PLCPtr = nil then
  begin
    c := CreatePLC(TagRec.Rack, TagRec.Slot, TagRec.Station);
    PLCPtr := @FPLCs[c];
    FoundPLC := True;
  end;

  Retries := 0;
  while (not FAdapterInitialized) and (Retries < 3) do
  begin
    FAdapterInitialized := InitAdapter;
    Inc(Retries);
  end;

  if Retries >= 3 then
  begin
    Result := ioDriverError;
    Exit;
  end;

  if not PLCPtr^.Connected then
    if not ConnectPLC(PLCPtr^) then
    begin
      Result := ioDriverError;
      Exit;
    end;

  case TagRec.ReadFunction of
    1:  ReqType := vtS7_Inputs;
    2:  ReqType := vtS7_Outputs;
    3:  ReqType := vtS7_Flags;
    4:  begin
          ReqType := vtS7_DB;
          FoundDb := False;
          if FoundPLC then
            for DBIdx := 0 to High(PLCPtr^.DBs) do
              if PLCPtr^.DBs[DBIdx].DBNum = TagRec.File_DB then
              begin
                FoundDb := True;
                Break;
              end;
        end;
    5:  ReqType := vtS7_Counter;
    6:  ReqType := vtS7_Timer;
    7:  ReqType := vtS7_200_SM;
    8:  ReqType := vtS7_200_AnInput;
    9:  ReqType := vtS7_200_AnOutput;
    10: ReqType := vtS7_200_Counter;
    11: ReqType := vtS7_200_Timer;
    12: ReqType := vtS7_Peripheral;
    else
      begin
        Result := ioTagError;
        Exit;
      end;
  end;

  MaxBytesToRecv := PLCPtr^.MaxPDULen - 18; //10 Bytes of header, 2 Bytes of error code, 2 Bytes of read request, 4 Bytes of result header.
  BytesReceived := 0;
  hasAtLeastOneSuccess := False;

  SetLength(Values, TagRec.Size);

  while BytesReceived < TagRec.Size do
  begin
    SetLength(MsgOut, 0);

    BytesToRecv := Min(MaxBytesToRecv, TagRec.Size - BytesReceived);

    IncomingPacketSize := PDUIncoming + 18 + BytesToRecv;
    OutgoingPacketSize := PDUOutgoing + 24; //10 Bytes of header, 2 Bytes of read request, 12 Bytes of read request header.

    SetLength(MsgOut, OutgoingPacketSize);
    SetLength(MsgIn, IncomingPacketSize);

    PrepareReadRequest(MsgOut);

    if ReqType = vtS7_DB then
      begin
        if TagRec.File_DB = 0 then
          begin
            AddToReadRequest(MsgOut, vtS7_DB, 1, TagRec.Address + TagRec.OffSet + BytesReceived, Min(MaxBytesToRecv, TagRec.Size - BytesReceived));
          end
        else
          begin
            AddToReadRequest(MsgOut, vtS7_DB, TagRec.File_DB, TagRec.Address + TagRec.OffSet + BytesReceived, Min(MaxBytesToRecv, TagRec.Size - BytesReceived));
          end;
      end
    else
      begin
        AddToReadRequest(MsgOut, ReqType, 0, TagRec.Address + TagRec.OffSet + BytesReceived, Min(MaxBytesToRecv, TagRec.Size - BytesReceived));
      end;

    if Exchange(PLCPtr^, MsgOut, MsgIn, False) then
    begin
      SetupPDU(MsgIn, False, IncomingPDU, Err);
      if (IncomingPDU.DataLen > 0) and (IncomingPDU.Data[0] = $FF) then
        begin
          hasAtLeastOneSuccess := True;
          Result := ioOk;
          if FoundPLC then
          begin
            SetLength(ReqList, 1);
            ReqList[0].DBIdx := IfThen(FoundDb, DBIdx, -1);
            ReqList[0].PLCIdx := c;
            ReqList[0].ReqType := ReqType;
            ReqList[0].StartAddress := TagRec.Address + BytesReceived + TagRec.OffSet;
            ReqList[0].Size := BytesToRecv;
            UpdateMemoryManager(MsgIn, MsgOut, False, ReqList, iValues);
            Move(iValues[0], Values[BytesReceived], Length(iValues) * SizeOf(Double));
          end;
        end
      else
        begin
          if hasAtLeastOneSuccess then
            begin
              Result := ioPartialOk;
            end
          else if IncomingPDU.DataLen > 0 then
            begin
              Result := S7ErrorCodeToProtocolErrorCode(IncomingPDU.Data[0]);
            end
          else
            Result := ioCommError;
          Exit;
        end;
    end
    else
      begin
        if hasAtLeastOneSuccess then
          begin
            Result := ioPartialOk;
          end
        else
          Result := ioCommError;

        Exit;
      end;

    Inc(BytesReceived, BytesToRecv);
  end;
end;

procedure TSiemensProtocolFamily.RunPLC(CPU: TS7CPU);
var
  ParamToRun: Bytes;
  MsgOut: Bytes;
  MsgIn: Bytes;
begin
  SetLength(ParamToRun, 20);
  SetLength(MsgOut, 0);
  SetLength(MsgIn, 0);
  ParamToRun[00] := $28;
  ParamToRun[01] := 0;
  ParamToRun[02] := 0;
  ParamToRun[03] := 0;
  ParamToRun[04] := 0;
  ParamToRun[05] := 0;
  ParamToRun[06] := 0;
  ParamToRun[07] := $FD;
  ParamToRun[08] := 0;
  ParamToRun[09] := 0;
  ParamToRun[10] := 9;
  ParamToRun[11] := $50; //P
  ParamToRun[12] := $5F; //_
  ParamToRun[13] := $50; //P
  ParamToRun[14] := $52; //R
  ParamToRun[15] := $4F; //O
  ParamToRun[16] := $47; //G
  ParamToRun[17] := $52; //R
  ParamToRun[18] := $41; //A
  ParamToRun[19] := $4D; //M

  InitiatePDUHeader(MsgOut, 1);
  AddParam(MsgOut, ParamToRun);

  if not Exchange(CPU, MsgOut, MsgIn, False) then
    raise Exception.Create('Cannot swicth the PLC to RUN');
end;

procedure TSiemensProtocolFamily.StopPLC(CPU: TS7CPU);
begin

end;

procedure TSiemensProtocolFamily.CopyRAMToROM(CPU: TS7CPU);
begin

end;

procedure TSiemensProtocolFamily.CompressMemory(CPU: TS7CPU);
begin

end;

function TSiemensProtocolFamily.S7ErrorCodeToProtocolErrorCode(Code: Word): TProtocolIOResult;
begin
  case Code of
    $FF: Result := ioOk;
    $06: Result := ioIllegalRequest;
    $0A: Result := ioObjectNotExists;
    $03: Result := ioObjectAccessNotAllowed;
    $05: Result := ioIllegalMemoryAddress;
    else
      Result := ioUnknownError;
  end;
end;

procedure TSiemensProtocolFamily.SetPDUSize(AValue: TS7PDUSize);
begin
  if FForcedPDUSize = AValue then Exit;
  FForcedPDUSize := AValue;
  case FForcedPDUSize of
    pduAuto: FPDUSizeInBytes := 1920; //negotiate PDU will use the smallest PDU size, In the future, this value should be increased?
    pdu240: FPDUSizeInBytes := 240;
    pdu480: FPDUSizeInBytes := 480;
    pdu960: FPDUSizeInBytes := 960;
  end;
end;

function TSiemensProtocolFamily.GetTagInfo(tagobj: TTag): TTagRec;
begin
  if tagobj is TPLCTagNumber then
  begin
    with Result do
    begin
      Rack := TPLCTagNumber(tagobj).PLCRack;
      Slot := TPLCTagNumber(tagobj).PLCSlot;
      Station := TPLCTagNumber(tagobj).PLCStation;
      File_DB := TPLCTagNumber(tagobj).MemFile_DB;
      Address := TPLCTagNumber(tagobj).MemAddress;
      SubElement := TPLCTagNumber(tagobj).MemSubElement;
      Size := TPLCTagNumber(tagobj).TagSizeOnProtocol;
      OffSet := 0;
      ReadFunction := TPLCTagNumber(tagobj).MemReadFunction;
      WriteFunction := TPLCTagNumber(tagobj).MemWriteFunction;
      UpdateTime := TPLCTagNumber(tagobj).UpdateTime;
      CallBack := nil;
    end;
    Exit;
  end;

  if tagobj is TPLCBlock then
  begin
    with Result do
    begin
      Rack := TPLCBlock(tagobj).PLCRack;
      Slot := TPLCBlock(tagobj).PLCSlot;
      Station := TPLCBlock(tagobj).PLCStation;
      File_DB := TPLCBlock(tagobj).MemFile_DB;
      Address := TPLCBlock(tagobj).MemAddress;
      SubElement := TPLCBlock(tagobj).MemSubElement;
      Size := TPLCBlock(tagobj).TagSizeOnProtocol;
      OffSet := 0;
      ReadFunction := TPLCBlock(tagobj).MemReadFunction;
      WriteFunction := TPLCBlock(tagobj).MemWriteFunction;
      UpdateTime := TPLCBlock(tagobj).UpdateTime;
      CallBack := nil;
    end;
    Exit;
  end;

  if tagobj is TPLCString then
  begin
    with Result do
    begin
      Rack := TPLCString(tagobj).PLCRack;
      Slot := TPLCString(tagobj).PLCSlot;
      Station := TPLCString(tagobj).PLCStation;
      File_DB := TPLCString(tagobj).MemFile_DB;
      Address := TPLCString(tagobj).MemAddress;
      SubElement := TPLCString(tagobj).MemSubElement;
      Size := TPLCString(tagobj).StringSize;
      OffSet := 0;
      ReadFunction := TPLCString(tagobj).MemReadFunction;
      WriteFunction := TPLCString(tagobj).MemWriteFunction;
      UpdateTime := TPLCString(tagobj).UpdateTime;
      CallBack := nil;
    end;
    Exit;
  end;
  raise Exception.Create(SinvalidTag);
end;

procedure TSiemensProtocolFamily.SetBytes(Ptr: Pbyte; Idx: Longint; Values: Bytes);
var
  InPtr: Pbyte;
begin
  InPtr := Ptr;
  Inc(InPtr, Idx);
  Move(Values[0], InPtr^, Length(Values));
end;

{

public int ReadSZL(int ID, int Index, ref S7SZL SZL, ref int Size)
{
  int Length;
  int DataSZL;
  int Offset = 0;
  bool Done = false;
  bool First = true;
  byte Seq_in = 0x00;
  ushort Seq_out = 0x0000;

  _LastError = 0;
  Time_ms = 0;
  int Elapsed = Environment.TickCount;
  SZL.Header.LENTHDR = 0;

  do
  {
    if (First)
    {
      S7.SetWordAt(S7_SZL_FIRST, 11, ++Seq_out);
      S7.SetWordAt(S7_SZL_FIRST, 29, (ushort)ID);
      S7.SetWordAt(S7_SZL_FIRST, 31, (ushort)Index);
      SendPacket(S7_SZL_FIRST);
    }
    else
    {
      S7.SetWordAt(S7_SZL_NEXT, 11, ++Seq_out);
      PDU[24] = (byte)Seq_in;
      SendPacket(S7_SZL_NEXT);
    }
    if (_LastError != 0)
      return _LastError;

    Length = RecvIsoPacket();
    if (_LastError == 0)
    {
      if (First)
      {
        if (Length > 32) // the minimum expected
        {
          if ((S7.GetWordAt(PDU, 27) == 0) && (PDU[29] == (byte)0xFF))
          {
            // Gets Amount of this slice
            DataSZL = S7.GetWordAt(PDU, 31) - 8; // Skips extra params (ID, Index ...)
            Done = PDU[26] == 0x00;
            Seq_in = (byte)PDU[24]; // Slice sequence
            SZL.Header.LENTHDR = S7.GetWordAt(PDU, 37);
            SZL.Header.N_DR = S7.GetWordAt(PDU, 39);
            Array.Copy(PDU, 41, SZL.Data, Offset, DataSZL);
            //                                SZL.Copy(PDU, 41, Offset, DataSZL);
            Offset += DataSZL;
            SZL.Header.LENTHDR += SZL.Header.LENTHDR;
          }
          else
            _LastError = S7Consts.errCliInvalidPlcAnswer;
        }
        else
          _LastError = S7Consts.errIsoInvalidPDU;
      }
      else
      {
        if (Length > 32) // the minimum expected
        {
          if ((S7.GetWordAt(PDU, 27) == 0) && (PDU[29] == (byte)0xFF))
          {
            // Gets Amount of this slice
            DataSZL = S7.GetWordAt(PDU, 31);
            Done = PDU[26] == 0x00;
            Seq_in = (byte)PDU[24]; // Slice sequence
            Array.Copy(PDU, 37, SZL.Data, Offset, DataSZL);
            Offset += DataSZL;
            SZL.Header.LENTHDR += SZL.Header.LENTHDR;
          }
          else
            _LastError = S7Consts.errCliInvalidPlcAnswer;
        }
        else
          _LastError = S7Consts.errIsoInvalidPDU;
      }
    }
    First = false;
  }
  while (!Done && (_LastError == 0));
  if (_LastError == 0)
  {
    Size = SZL.Header.LENTHDR;
    Time_ms = Environment.TickCount - Elapsed;
  }
  return _LastError;
}

function TSiemensProtocolFamily.SetSessionPassword(Password:String):Integer;
{
// S7 Set Session Password
byte[] S7_SET_PWD = {
  0x03, 0x00, 0x00, 0x25,
  0x02, 0xf0, 0x80, 0x32,
  0x07, 0x00, 0x00, 0x27,
  0x00, 0x00, 0x08, 0x00,
  0x0c, 0x00, 0x01, 0x12,
  0x04, 0x11, 0x45, 0x01,
  0x00, 0xff, 0x09, 0x00,
  0x08,
  // 8 Char Encoded Password
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

  byte[] pwd = { 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20 };
  int Length;
  _LastError = 0;
  int Elapsed = Environment.TickCount;
  // Encodes the Password
  S7.SetCharsAt(pwd, 0, Password);
  pwd[0] = (byte)(pwd[0] ^ 0x55);
  pwd[1] = (byte)(pwd[1] ^ 0x55);
  for (int c = 2; c < 8; c++)
  {
    pwd[c] = (byte)(pwd[c] ^ 0x55 ^ pwd[c - 2]);
  }
  Array.Copy(pwd, 0, S7_SET_PWD, 29, 8);
  // Sends the telegrem
  SendPacket(S7_SET_PWD);
  if (_LastError == 0)
  {
    Length = RecvIsoPacket();
    if (Length > 32) // the minimum expected
    {
      ushort Result = S7.GetWordAt(PDU, 27);
      if (Result != 0)
        _LastError = CpuError(Result);
    }
    else
      _LastError = S7Consts.errIsoInvalidPDU;
  }
  if (_LastError == 0)
    Time_ms = Environment.TickCount - Elapsed;
  return _LastError;
}

function TSiemensProtocolFamily.ClearSessionPassword:integer;
{

// S7 Clear Session Password
byte[] S7_CLR_PWD = {
  0x03, 0x00, 0x00, 0x1d,
  0x02, 0xf0, 0x80, 0x32,
  0x07, 0x00, 0x00, 0x29,
  0x00, 0x00, 0x08, 0x00,
  0x04, 0x00, 0x01, 0x12,
  0x04, 0x11, 0x45, 0x02,
  0x00, 0x0a, 0x00, 0x00,
  0x00
};

  int Length;
  _LastError = 0;
  int Elapsed = Environment.TickCount;
  SendPacket(S7_CLR_PWD);
  if (_LastError == 0)
  {
    Length = RecvIsoPacket();
    if (Length > 30) // the minimum expected
    {
      ushort Result = S7.GetWordAt(PDU, 27);
      if (Result != 0)
        _LastError = CpuError(Result);
    }
    else
      _LastError = S7Consts.errIsoInvalidPDU;
  }
  return _LastError;
}

function TSiemensProtocolFamily.GetProtection(out Protection:TS7Protection):Integer;
begin
  S7Client.S7SZL SZL = new S7Client.S7SZL();
  int Size = 256;
  SZL.Data = new byte[Size];
  _LastError = ReadSZL(0x0232, 0x0004, ref SZL, ref Size);
  if (_LastError == 0)
  {
    Protection.sch_schal = S7.GetWordAt(SZL.Data, 2);
    Protection.sch_par = S7.GetWordAt(SZL.Data, 4);
    Protection.sch_rel = S7.GetWordAt(SZL.Data, 6);
    Protection.bart_sch = S7.GetWordAt(SZL.Data, 8);
    Protection.anl_sch = S7.GetWordAt(SZL.Data, 10);
  }
  return _LastError;
end;

}

var
  TagBuilderEditor: TOpenTagEditor = nil;

procedure TSiemensProtocolFamily.OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  if Assigned(TagBuilderEditor) then
    TagBuilderEditor(Self, Self.Owner, InsertHook, CreateProc)
  else
    inherited OpenTagEditor(InsertHook, CreateProc);
end;

function TSiemensProtocolFamily.HasTabBuilderEditor: Boolean;
begin
  Result := True;
end;

procedure SetTagBuilderToolForSiemensS7ProtocolFamily(TagBuilderTool: TOpenTagEditor);
begin
  if Assigned(TagBuilderEditor) then
    raise Exception.Create('A Tag Builder editor for Siemens S7 protocol family was already Assigned.')
  else
    TagBuilderEditor := TagBuilderTool;
end;

end.

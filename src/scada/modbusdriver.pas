{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit that implements the base of ModBus RTU and ModBus TCP protocol drivers.)

  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Moved OpenTagEditor to TagBuilderAssistant to remove form dependencies
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
unit ModBusDriver;

interface

uses
  SysUtils, Classes, CommTypes, ProtocolDriver, ProtocolTypes, Tag, PLCTagNumber,
  PLCMemoryManager, PLCBlock, PLCString, fgl, modbus_tagscan_req
{$IFNDEF FPC}
  , Windows
{$ENDIF}
  ;

type

  TInputBlockSize = 0..2000;
  TOutputBlockSize = TInputBlockSize;
  THoldingRegistersBlockSize = 0..125;
  TAnalogBlockSize = THoldingRegistersBlockSize;

  TReqList = specialize TFPGList<TReqItem>;

  {:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  Record that represents a modbus slave device.

  @member Station Address of the modbus device.
  @member Inputs Memory mananger object that handles the digital inputs of your modbus device.
  @member Outputs Memory mananger object that handles the digital outputs of your modbus device (coils).
  @member Registers Memory mananger object that handles the registers of your modbus device.
  @member AnalogReg Memory mananger object that handles the analog registers of your modbus device.
  @member Status07Value Stores the value returned by the ModBus function 07.
  @member Status07TimeStamp Stores the date/time of the last action of ModBus function 07.
  @member Status07LastError Stores the IO result of the last ModBus function 07. }
  TModBusPLC = record
    Station: Longint;
    Inputs: TPLCMemoryManager;
    OutPuts: TPLCMemoryManager;
    Registers: TPLCMemoryManager;
    AnalogReg: TPLCMemoryManager;
    Status07Value: Double;
    Status07TimeStamp: TDateTime;
    Status07LastError: TProtocolIOResult;
  end;

  {:
  @abstract(Base class of ModBus protocol driver (RTU e TCP))
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  To configure your tag, you must set the following properties of your tag:

  @unorderedList(
    @item(@bold(PLCStation): Address of your modbus slave.)
    @item(@bold(MemAddress): Address of the digital input or output, register or
          analog register.)
    @item(@bold(MemReadFuntion): Modbus function that will be used to read the
          tag. See the table below.)
    @item(@bold(MemWriteFuntion): Modbus function that will be used to write the
          values of your tag on device. See the table below.)
  )

  The properties MemReadFunction and MemWriteFunction accept the following values,
  depending of the area (digital input, output, register) desejado:

  @table(
    @rowHead( @cell(Desired area)    @cell(MemReadFunction) @cell(MemWriteFunction) )
    @row(     @cell(Digital inputs)  @cell(2)               @cell(0) )
    @row(     @cell(Digital outputs) @cell(1)               @cell(5 (simple), 15 (block)) )
    @row(     @cell(Registers)       @cell(3)               @cell(6 (simple), 16 (block)) )
    @row(     @cell(Analog Inputs)   @cell(4)               @cell(0) )
    @row(     @cell(Device Status)   @cell(7)               @cell(0) )
  )

  You must know what's the supported functions of your modbus slave.

  @seealso(TModBusRTUDriver)
  @seealso(TModBusTCPDriver) }
  TModBusDriver = class(TProtocolDriver)
  private
    FMustReleaseResources: Boolean;
    PAnalogRegsMaxBlockSize: TAnalogBlockSize;
    PHoldingRegsMaxBlockSize: THoldingRegistersBlockSize;
    PInputBlockSize: TInputBlockSize;
    POutputBlockSize: TOutputBlockSize;

    procedure SetAnalogRegsMaxBlockSize(AValue: TAnalogBlockSize);
    procedure SetHoldingRegsMaxBlockSize(AValue: THoldingRegistersBlockSize);
    procedure SetInputBlockSize(AValue: TInputBlockSize);
    procedure SetOutputBlockSize(AValue: TOutputBlockSize);
  protected
    PFirstRequestLen: Longint;
    PFuncByteOffset: Longint;
    PCRCLen: Longint;
    POutputMaxHole: Cardinal;
    PInputMaxHole: Cardinal;
    PRegistersMaxHole: Cardinal;
    PInternalDelayBetweenCmds: Cardinal;
    PModbusPLC: array of TModBusPLC;

    function AllowBroadCast: Boolean; virtual;
    function GetTagProperts(TagObj: TTag; var Station, Address, Size, RegType, ScanTime: Longint): Boolean;
    procedure SetOutputMaxHole(AValue: Cardinal);
    procedure SetInputMaxHole(AValue: Cardinal);
    procedure SetRegisterMaxHole(AValue: Cardinal);
    procedure BuildTagRec(PLC, Func, StartAddress, Size: Longint; out ATagRec: TTagRec);

    //: Encode a modbus packet.
    function EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes; virtual;
    //: Decodes a modbus packet.
    function DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult; virtual;
    //: Returns the remaing Bytes on RX buffer of communication port.
    function RemainingBytes(Buffer: Bytes): Longint; virtual;

    //: @seealso(TProtocolDriver.DoAddTag)
    procedure DoAddTag(TagObj: TTag; TagValid: Boolean); override;
    //: @seealso(TProtocolDriver.DoDelTag)
    procedure DoDelTag(TagObj: TTag); override;

    //: @seealso(TProtocolDriver.DoScanRead)
    procedure DoScanRead(Sender: TObject; var NeedSleep: Longint); override;
    //: @seealso(TProtocolDriver.DoGetValue)
    procedure DoGetValue(TagObj: TTagRec; var Values: TScanReadRec); override;

    //: @seealso(TProtocolDriver.DoWrite)
    function DoWrite(const ATagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
    //: @seealso(TProtocolDriver.DoRead)
    function DoRead(const ATagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;

    {: How many digital outputs can be undeclared to keep the block continuous.
       @seealso(TPLCMemoryManager.MaxHole) }
    property OutputMaxHole: Cardinal read POutputMaxHole write SetOutputMaxHole default 50;
    {: How many digital inputs can be undeclared to keep the block continuous.
       @seealso(TPLCMemoryManager.MaxHole) }
    property InputMaxHole: Cardinal read PInputMaxHole write SetInputMaxHole default 50;
    {: How many registers can be undeclared to keep the block continuous.
       @seealso(TPLCMemoryManager.MaxHole) }
    property RegisterMaxHole: Cardinal read PRegistersMaxHole write SetRegisterMaxHole default 10;
    {: How many input bits can be read in single block.
       @seealso(TPLCMemoryManager.MaxBlockItems) }
    property InputsMaxBlockSize: TInputBlockSize read PInputBlockSize write SetInputBlockSize default 2000;
    {: How many output bits can be read in single block.
       @seealso(TPLCMemoryManager.MaxBlockItems) }
    property OutputsMaxBlockSize: TOutputBlockSize read POutputBlockSize write SetOutputBlockSize default 2000;
    {: How many analog inputs (words) can be read in single block.
       @seealso(TPLCMemoryManager.MaxBlockItems) }
    property AnalogRegsMaxBlockSize: TAnalogBlockSize read PAnalogRegsMaxBlockSize write SetAnalogRegsMaxBlockSize default 125;
    {: How many holding registers (words) can be read in single block.
       @seealso(TPLCMemoryManager.MaxBlockItems) }
    property HoldingRegsMaxBlockSize: THoldingRegistersBlockSize read PHoldingRegsMaxBlockSize write SetHoldingRegsMaxBlockSize default 125;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;
    //: @seealso(TProtocolDriver.SizeOfTag)
    function SizeOfTag(ATag: TTag; isWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte; override;
    //: @seealso(TProtocolDriver.OpenTagEditor)
    procedure OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); override;
    //: @seealso(TProtocolDriver.HasTabBuilderEditor)
    function HasTabBuilderEditor: Boolean; override;
  end;

procedure SetTagBuilderToolForModBusProtocolFamily(TagBuilderTool: TOpenTagEditor);


implementation


uses
  crossdatetime, pascalScadaMTPCPU, Math, dateutils;


function SortGenericTagList(const Item1, Item2: TReqItem): Integer;
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

constructor TModBusDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProtocolReady := False;
  POutputMaxHole := 50;
  PInputMaxHole := 50;
  PRegistersMaxHole := 10;
  PInputBlockSize := 2000;
  POutputBlockSize := 2000;
  PHoldingRegsMaxBlockSize := 125;
  PAnalogRegsMaxBlockSize := 125;
  PReadSomethingAlways := True;
  PInternalDelayBetweenCmds := 5;
  SetLength(PModbusPLC, 0);
end;

destructor TModBusDriver.Destroy;
var
  PLC: Longint;
begin
  inherited Destroy;
  for PLC := 0 to High(PModbusPLC) do
  begin
    PModbusPLC[PLC].Inputs.Destroy;
    PModbusPLC[PLC].OutPuts.Destroy;
    PModbusPLC[PLC].Registers.Destroy;
    PModbusPLC[PLC].AnalogReg.Destroy;
  end;
  SetLength(PModbusPLC, 0);
end;

procedure TModBusDriver.SetAnalogRegsMaxBlockSize(AValue: TAnalogBlockSize);
var
  PLC: Integer;
begin
  if PAnalogRegsMaxBlockSize = AValue then Exit;
  PAnalogRegsMaxBlockSize := AValue;

  for PLC := 0 to High(PModbusPLC) do
    PModbusPLC[PLC].AnalogReg.MaxBlockItems := AValue;
end;

procedure TModBusDriver.SetHoldingRegsMaxBlockSize(AValue: THoldingRegistersBlockSize);
var
  PLC: Integer;
begin
  if PHoldingRegsMaxBlockSize = AValue then Exit;
  PHoldingRegsMaxBlockSize := AValue;

  for PLC := 0 to High(PModbusPLC) do
    PModbusPLC[PLC].Registers.MaxBlockItems := AValue;
end;

procedure TModBusDriver.SetInputBlockSize(AValue: TInputBlockSize);
var
  PLC: Integer;
begin
  if PInputBlockSize = AValue then Exit;
  PInputBlockSize := AValue;

  for PLC := 0 to High(PModbusPLC) do
    PModbusPLC[PLC].Inputs.MaxBlockItems := AValue;
end;

procedure TModBusDriver.SetOutputBlockSize(AValue: TOutputBlockSize);
var
  PLC: Integer;
begin
  if POutputBlockSize = AValue then Exit;
  POutputBlockSize := AValue;

  for PLC := 0 to High(PModbusPLC) do
    PModbusPLC[PLC].OutPuts.MaxBlockItems := AValue;
end;

function TModBusDriver.AllowBroadCast: Boolean;
begin
  Result := False;
end;

function TModBusDriver.GetTagProperts(TagObj: TTag; var Station, Address, Size, RegType, ScanTime: Longint): Boolean;
var
  Found: Boolean;
begin
  Found := False;
  Result := False;
  //PLCTagNumber
  if (not Found) and (TagObj is TPLCTagNumber) then
  begin
    Found := True;
    Station := TPLCTagNumber(TagObj).PLCStation;
    Address := TPLCTagNumber(TagObj).MemAddress;
    Size := TPLCTagNumber(TagObj).TagSizeOnProtocol;
    RegType := TPLCTagNumber(TagObj).MemReadFunction;
    ScanTime := TPLCTagNumber(TagObj).RefreshTime;
    Result := Found;
  end;

  //TPLCBlock and TPLCStruct
  if (not Found) and (TagObj is TPLCBlock) then
  begin
    Found := True;
    Station := TPLCBlock(TagObj).PLCStation;
    Address := TPLCBlock(TagObj).MemAddress;
    Size := TPLCBlock(TagObj).TagSizeOnProtocol;
    RegType := TPLCBlock(TagObj).MemReadFunction;
    ScanTime := TPLCBlock(TagObj).RefreshTime;
    Result := Found;
  end;

  //TPLCString
  if (not Found) and (TagObj is TPLCString) then
  begin
    Found := True;
    Station := TPLCString(TagObj).PLCStation;
    Address := TPLCString(TagObj).MemAddress;
    Size := TPLCString(TagObj).Size;
    RegType := TPLCString(TagObj).MemReadFunction;
    ScanTime := TPLCString(TagObj).RefreshTime;
    Result := Found;
  end;
end;

procedure TModBusDriver.DoAddTag(TagObj: TTag; TagValid: Boolean);
var
  Station: Longint;
  Mem: Longint;
  Size: Longint;
  MemType: Longint;
  ScanTime: Longint;
  Found: Boolean;
  AValue: Boolean;
  PLC: Longint;
begin
  //Recupera as informações do tag;
  //retrieve informations of the tag.
  Station := 0;
  Mem := 0;
  Size := 0;
  MemType := 0;
  ScanTime := 0;
  AValue := False;

  Found := GetTagProperts(TagObj, Station, Mem, Size, MemType, ScanTime);

  if Found then
    //se o endereco do PLC esta numa faixa válida procura nos blocos de Memória.
    //check if the address of the slave is valid.
    if Station in [1..255] then
    begin
      Found := False;
      for PLC := 0 to High(PModbusPLC) do
        if PModbusPLC[PLC].Station = Station then
        begin
          Found := True;
          Break;
        end;
      //se nao encontrou o PLC, adiciona!
      //if not Found the slave, add it.
      if not Found then
      begin
        PLC := Length(PModbusPLC);
        SetLength(PModbusPLC, PLC + 1);
        PModbusPLC[PLC].Station := Station;
        PModbusPLC[PLC].Inputs := TPLCMemoryManager.Create();
        PModbusPLC[PLC].Inputs.MaxBlockItems := PInputBlockSize;
        PModbusPLC[PLC].Inputs.MaxHole := PInputMaxHole;
        PModbusPLC[PLC].OutPuts := TPLCMemoryManager.Create();
        PModbusPLC[PLC].OutPuts.MaxBlockItems := POutputBlockSize;
        PModbusPLC[PLC].OutPuts.MaxHole := POutputMaxHole;
        PModbusPLC[PLC].Registers := TPLCMemoryManager.Create();
        PModbusPLC[PLC].Registers.MaxBlockItems := PHoldingRegsMaxBlockSize;
        PModbusPLC[PLC].Registers.MaxHole := PRegistersMaxHole;
        PModbusPLC[PLC].AnalogReg := TPLCMemoryManager.Create();
        PModbusPLC[PLC].AnalogReg.MaxBlockItems := PAnalogRegsMaxBlockSize;
        PModbusPLC[PLC].AnalogReg.MaxHole := PRegistersMaxHole;
      end;

      AValue := (MemType in [1..4]);

      case MemType of
        1: PModbusPLC[PLC].OutPuts.AddAddress(Mem, Size, 1, ScanTime);
        2: PModbusPLC[PLC].Inputs.AddAddress(Mem, Size, 1, ScanTime);
        3: PModbusPLC[PLC].Registers.AddAddress(Mem, Size, 1, ScanTime);
        4: PModbusPLC[PLC].AnalogReg.AddAddress(Mem, Size, 1, ScanTime);
      end;
    end;
  inherited DoAddTag(TagObj, AValue);
end;

procedure TModBusDriver.DoDelTag(TagObj: TTag);
var
  Station: Longint;
  Mem: Longint;
  Size: Longint;
  MemType: Longint;
  ScanTime: Longint;
  Found: Boolean;
  PLC: Longint;
begin
  //Recupera as informações do tag;
  //retrieve informations about the tag.
  Station := 0;
  Mem := 0;
  Size := 0;
  MemType := 0;
  ScanTime := 0;
  Found := GetTagProperts(TagObj, Station, Mem, Size, MemType, ScanTime);

  if Found then
    //se o endereco do PLC esta numa faixa válida procura nos blocos de Memória.
    //check if the slave address is valid.
    if Station in [1..255] then
    begin
      Found := False;
      for PLC := 0 to High(PModbusPLC) do
        if PModbusPLC[PLC].Station = Station then
        begin
          Found := True;
          Break;
        end;

      //se encontrou o PLC remove a memoria que estou lendo dele.
      //if Found the slave, removes the tag.
      if Found then
      begin
        case MemType of
          1: PModbusPLC[PLC].OutPuts.RemoveAddress(Mem, Size, 1);
          2: PModbusPLC[PLC].Inputs.RemoveAddress(Mem, Size, 1);
          3: PModbusPLC[PLC].Registers.RemoveAddress(Mem, Size, 1);
          4: PModbusPLC[PLC].AnalogReg.RemoveAddress(Mem, Size, 1);
        end;
      end;
    end;
  inherited DoDelTag(TagObj);
end;



function TModBusDriver.SizeOfTag(ATag: TTag; isWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte;
var
  FunctionCode: Cardinal;
begin
  FunctionCode := 0;
  if (ATag is TPLCTagNumber) then
  begin
    if (isWrite) then
      FunctionCode := TPLCTagNumber(ATag).MemWriteFunction
    else
      FunctionCode := TPLCTagNumber(ATag).MemReadFunction;
  end;

  //TPLCBlock and TPLCStruct
  if (ATag is TPLCBlock) then
  begin
    if (isWrite) then
      FunctionCode := TPLCBlock(ATag).MemWriteFunction
    else
      FunctionCode := TPLCBlock(ATag).MemReadFunction;
  end;

  //TPLCString
  if (ATag is TPLCString) then
  begin
    if (isWrite) then
      FunctionCode := TPLCString(ATag).MemWriteFunction
    else
      FunctionCode := TPLCString(ATag).MemReadFunction;
  end;

  //retorna o tamanho em bits dos registradores lidos/escritos por
  //cada tipo de função de reading/escrita

  //return the size in bits of the ATag
  case FunctionCode of
    $01, $02,
    $05, $0F: begin
                Result := 1;
                ProtocolTagType := ptBit;
              end;
    $03, $04,
    $06, $10: begin
                Result := 16;
                ProtocolTagType := ptWord;
              end;
    $11:  begin
            Result := 8;
            ProtocolTagType := ptByte;
          end
    else
      begin
        Result := 16;
        ProtocolTagType := ptWord;
      end
  end;
end;

function TModBusDriver.EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes;
begin
  Result := nil;
end;

function TModBusDriver.DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult;
begin
  Result := ioDriverError;
end;

function TModBusDriver.RemainingBytes(Buffer: Bytes): Longint;
begin
  Result := 0;
end;

procedure TModBusDriver.DoScanRead(Sender: TObject; var NeedSleep: Longint);
var
  PLC: Longint;
  Block: Longint;
  ATagRec: TTagRec;
  Values: TArrayOfDouble;
  EntireTagList: TReqList;
  i: Integer;

  procedure AddToTagList(Station, Func, StartAddress, Size, UpdateRate: Longint; LastUpdate: TDateTime; NeedUpdate: Boolean);
  var
    Info: TReqItem;
  begin
    Info.Station := Station;
    Info.Func := Func;
    Info.StartAddress := StartAddress;
    Info.Size := Size;
    Info.LastUpdate := LastUpdate;
    Info.UpdateRate := UpdateRate;
    Info.NeedUpdate := NeedUpdate;
    Info.Read := False;

    EntireTagList.add(Info);
  end;

begin
  try
    if ([csDestroying] * ComponentState <> []) then
    begin
      CrossThreadSwitch;
      Exit;
    end;

    //avoid high cpu consumption with linked tags and not Assigned communcation port
    if (not Assigned(PCommPort)) or (PCommPort.ReallyActive = False) then
    begin
      NeedSleep := 1;
      Exit;
    end;

    EntireTagList := TReqList.Create;

    for PLC := 0 to High(PModbusPLC) do
    begin
      for Block := 0 to High(PModbusPLC[PLC].OutPuts.Blocks) do
      begin
        AddToTagList(PModbusPLC[PLC].Station, 1,
          PModbusPLC[PLC].OutPuts.Blocks[Block].AddressStart,
          PModbusPLC[PLC].OutPuts.Blocks[Block].Size,
          PModbusPLC[PLC].OutPuts.Blocks[Block].ScanTime,
          PModbusPLC[PLC].OutPuts.Blocks[Block].LastUpdate,
          PModbusPLC[PLC].OutPuts.Blocks[Block].NeedRefresh);
      end;

      for Block := 0 to High(PModbusPLC[PLC].Inputs.Blocks) do
      begin
        AddToTagList(PModbusPLC[PLC].Station, 2,
          PModbusPLC[PLC].Inputs.Blocks[Block].AddressStart,
          PModbusPLC[PLC].Inputs.Blocks[Block].Size,
          PModbusPLC[PLC].Inputs.Blocks[Block].ScanTime,
          PModbusPLC[PLC].Inputs.Blocks[Block].LastUpdate,
          PModbusPLC[PLC].Inputs.Blocks[Block].NeedRefresh);
      end;

      for Block := 0 to High(PModbusPLC[PLC].Registers.Blocks) do
      begin
        AddToTagList(PModbusPLC[PLC].Station, 3,
          PModbusPLC[PLC].Registers.Blocks[Block].AddressStart,
          PModbusPLC[PLC].Registers.Blocks[Block].Size,
          PModbusPLC[PLC].Registers.Blocks[Block].ScanTime,
          PModbusPLC[PLC].Registers.Blocks[Block].LastUpdate,
          PModbusPLC[PLC].Registers.Blocks[Block].NeedRefresh);
      end;

      for Block := 0 to High(PModbusPLC[PLC].AnalogReg.Blocks) do
      begin
        AddToTagList(PModbusPLC[PLC].Station, 4,
          PModbusPLC[PLC].AnalogReg.Blocks[Block].AddressStart,
          PModbusPLC[PLC].AnalogReg.Blocks[Block].Size,
          PModbusPLC[PLC].AnalogReg.Blocks[Block].ScanTime,
          PModbusPLC[PLC].AnalogReg.Blocks[Block].LastUpdate,
          PModbusPLC[PLC].AnalogReg.Blocks[Block].NeedRefresh);
      end;
    end;

    EntireTagList.Sort(@SortGenericTagList);

    //faz a reading do bloco que mais precisa ser lido

    //update the tag 
    if (EntireTagList.Count > 0) and (EntireTagList.Items[0].NeedUpdate or PReadSomethingAlways) then
    begin
      //compila o bloco do mais necessitado;
      //build the tagrec record.
      BuildTagRec(EntireTagList.Items[0].Station,
        EntireTagList.Items[0].Func,
        EntireTagList.Items[0].StartAddress,
        EntireTagList.Items[0].Size, ATagRec);
      FMustReleaseResources := True;
      DoRead(ATagRec, Values, False);
      FMustReleaseResources := False;
    end
    else
      NeedSleep := 1;

    for i := EntireTagList.Count - 1 downto 0 do
    begin
      EntireTagList.Delete(i);
    end;
    FreeAndNil(EntireTagList);
  finally
    FProtocolReady := True;
    SetLength(Values, 0);
  end;
end;

procedure TModBusDriver.DoGetValue(TagObj: TTagRec; var Values: TScanReadRec);
var
  PLC: Longint;
  i: Longint;
  Found: Boolean;
begin
  if Length(Values.values) < TagObj.Size then
    SetLength(Values.values, TagObj.Size);

  for i := 0 to Length(Values.values) - 1 do
    Values.values[i] := 0;

  Found := False;
  for PLC := 0 to High(PModbusPLC) do
    if PModbusPLC[PLC].Station = TagObj.Station then
    begin
      Found := True;
      Break;
    end;

  if not Found then
  begin
    Values.ValuesTimestamp := CrossNow;
    Values.ReadsOK := 0;
    Values.ReadFaults := 1;
    Values.LastQueryResult := ioDriverError;
    SetLength(Values.values, 0);
    Exit;
  end;

  case TagObj.ReadFunction of
    $01: PModbusPLC[PLC].OutPuts.GetValues(TagObj.Address, TagObj.Size, 1, Values.values, Values.LastQueryResult, Values.ValuesTimestamp);
    $02: PModbusPLC[PLC].Inputs.GetValues(TagObj.Address, TagObj.Size, 1, Values.values, Values.LastQueryResult, Values.ValuesTimestamp);
    $03,
    $11: PModbusPLC[PLC].Registers.GetValues(TagObj.Address, TagObj.Size, 1, Values.values, Values.LastQueryResult, Values.ValuesTimestamp);
    $04: PModbusPLC[PLC].AnalogReg.GetValues(TagObj.Address, TagObj.Size, 1, Values.values, Values.LastQueryResult, Values.ValuesTimestamp);
  end;

  if Values.LastQueryResult = ioOk then
    begin
      Values.ReadsOK := 1;
      Values.ReadFaults := 0;
    end
  else
    begin
      Values.ReadsOK := 0;
      Values.ReadFaults := 1;
    end;
end;

function TModBusDriver.DoWrite(const ATagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  IOResult1: TIOPacket;
  IOResult2: TIOPacket;
  Pkg: Bytes;
  FRemainingBytes: Longint;
  Rl: Longint;
  Res: Longint;
  TempValues: TArrayOfDouble;
begin
  try
    Pkg := EncodePkg(ATagRec, Values, Rl);
    if (PCommPort <> nil) and PCommPort.ReallyActive then
      begin
        PCommPort.Lock(DriverID);
        try
          if AllowBroadCast and (ATagRec.Station = 0) then
            begin
              Res := PCommPort.IOCommandSync(iocWrite, Length(Pkg), Pkg, 0, DriverID, 0, @IOResult1);
              case IOResult1.WriteIOResult of
                iorOK: Result := ioOk;
                iorTimeOut: Result := ioTimeOut;
                iorNotReady: Result := ioDriverError;
                iorNone: Result := ioNone;
                iorPortError: Result := ioDriverError;
              end;
              Exit;
            end
          else
            Res := PCommPort.IOCommandSync(iocWriteRead, Length(Pkg), Pkg, PFirstRequestLen, DriverID, PInternalDelayBetweenCmds, @IOResult1);

          // if the IO result is OK, reads the remaing packet...
          if (Res <> 0) and (IOResult1.ReadIOResult = iorOK) then
            begin
              // calculates the remaining package length at the communication buffer
              FRemainingBytes := RemainingBytes(IOResult1.BufferToRead);

              //clear the remaining buffer...
              if (IOResult1.BufferToRead[PFuncByteOffset - 1] <> Pkg[PFuncByteOffset - 1]) or
                ((IOResult1.BufferToRead[PFuncByteOffset] <> Pkg[PFuncByteOffset]) and
                (not (IOResult1.BufferToRead[PFuncByteOffset] in [$81..$88]))) then
              begin
                repeat
                  Res := PCommPort.IOCommandSync(iocRead, 0, nil, 1, DriverID, 0, @IOResult2);
                until IOResult2.ReadIOResult = iorTimeOut;
                Result := ioCommError;
                Exit;
              end;

              if FRemainingBytes > 0 then
              begin
                Res := PCommPort.IOCommandSync(iocRead, 0, nil, FRemainingBytes, DriverID, 0, @IOResult2);

                if Res <> 0 then
                begin
                  IOResult1.BufferToRead := ConcatenateBYTES(IOResult1.BufferToRead, IOResult2.BufferToRead);
                  IOResult1.Received := IOResult1.Received + IOResult2.Received;
                  if IOResult2.ReadIOResult <> iorOK then
                    IOResult1.ReadIOResult := IOResult2.ReadIOResult;
                end
                else
                  Result := ioDriverError;
              end;
              Result := DecodePkg(IOResult1, TempValues);
            end
          else
            Result := ioEmptyPacket;
        finally
          PCommPort.Unlock(DriverID);
        end;
      end
    else
      Result := ioNullDriver;
  finally
    SetLength(Pkg, 0);
    SetLength(TempValues, 0);
    SetLength(IOResult1.BufferToRead, 0);
    SetLength(IOResult1.BufferToWrite, 0);
    SetLength(IOResult2.BufferToRead, 0);
    SetLength(IOResult2.BufferToWrite, 0);
  end;
end;

function TModBusDriver.DoRead(const ATagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  IOResult1: TIOPacket;
  IOResult2: TIOPacket;
  FRemainingBytes: Longint;
  Pkg: Bytes;
  Rl: Longint;
  Res: Longint;
  Starts: TNotifyEvent;
  Ends: TNotifyEvent;
begin
  try
    if FMustReleaseResources then
      begin
        Starts := @HighLatencyOperationWillBegin;
        Ends := @HighLatencyOperationWasEnded;
      end
    else
      begin
        Starts := nil;
        Ends := nil;
      end;
    Pkg := EncodePkg(ATagRec, nil, Rl);
    if (PCommPort <> nil) and PCommPort.ReallyActive then
      begin
        PCommPort.Lock(DriverID);
        Res := PCommPort.IOCommandSync(iocWriteRead, Length(Pkg), Pkg, PFirstRequestLen, DriverID, PInternalDelayBetweenCmds, @IOResult1, Starts, Ends);

        //if the IO result is OK, reads the remaing packet...
        if (Res <> 0) and (IOResult1.ReadIOResult = iorOK) then
          begin
            //calculates the remaining package length at the communication buffer.
            FRemainingBytes := RemainingBytes(IOResult1.BufferToRead);

            //clear the remaining buffer...
            if (IOResult1.BufferToRead[PFuncByteOffset - 1] <> Pkg[PFuncByteOffset - 1]) or
              ((IOResult1.BufferToRead[PFuncByteOffset] <> Pkg[PFuncByteOffset]) and
              (not (IOResult1.BufferToRead[PFuncByteOffset] in [$81..$88]))) then
            begin
              repeat
                Res := PCommPort.IOCommandSync(iocRead, 0, nil, 1, DriverID, 0, @IOResult2, Starts, Ends);
              until IOResult2.ReadIOResult = iorTimeOut;
              Result := ioCommError;
              Exit;
            end;

            if FRemainingBytes > 0 then
            begin
              Res := PCommPort.IOCommandSync(iocRead, 0, nil, FRemainingBytes, DriverID, 0, @IOResult2, Starts, Ends);
              if Res <> 0 then
                begin
                  IOResult1.BufferToRead := ConcatenateBYTES(IOResult1.BufferToRead, IOResult2.BufferToRead);
                  IOResult1.Received := IOResult1.Received + IOResult2.Received;
                  if IOResult2.ReadIOResult <> iorOK then
                    IOResult1.ReadIOResult := IOResult2.ReadIOResult;
                end
              else
                Result := ioDriverError;
            end;
            Result := DecodePkg(IOResult1, Values);
          end
        else
          begin
            Result := DecodePkg(IOResult1, Values);
            //Result:=ioEmptyPacket;
          end;
        PCommPort.Unlock(DriverID);
      end
    else
      Result := ioNullDriver;
  finally
    SetLength(Pkg, 0);
    SetLength(IOResult1.BufferToRead, 0);
    SetLength(IOResult1.BufferToWrite, 0);
    SetLength(IOResult2.BufferToRead, 0);
    SetLength(IOResult2.BufferToWrite, 0);
  end;
end;

procedure TModBusDriver.SetOutputMaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutputMaxHole then Exit;

  POutputMaxHole := AValue;

  for PLC := 0 to High(PModbusPLC) do
    PModbusPLC[PLC].OutPuts.MaxHole := AValue;
end;

procedure TModBusDriver.SetInputMaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = PInputMaxHole then Exit;

  PInputMaxHole := AValue;

  for PLC := 0 to High(PModbusPLC) do
    PModbusPLC[PLC].Inputs.MaxHole := AValue;
end;

procedure TModBusDriver.SetRegisterMaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = PRegistersMaxHole then Exit;

  PRegistersMaxHole := AValue;

  for PLC := 0 to High(PModbusPLC) do
    PModbusPLC[PLC].Registers.MaxHole := AValue;
end;

procedure TModBusDriver.BuildTagRec(PLC, Func, StartAddress, Size: Longint; out ATagRec: TTagRec);
begin
  with ATagRec do
  begin
    Station := PLC;
    Rack := 0;
    Address := StartAddress;
    ReadFunction := Func;
    OffSet := 0;
    Slot := 0;
    File_DB := 0;
    SubElement := 0;
    WriteFunction := 0;
    Retries := 0;
    UpdateTime := 0;
  end;
  ATagRec.Size := Size;
end;


var
  ModbusTagBuilderEditor: TOpenTagEditor = nil;


procedure TModBusDriver.OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  if Assigned(ModbusTagBuilderEditor) then
    ModbusTagBuilderEditor(Self, Self.Owner, InsertHook, CreateProc)
  else
    inherited;
end;

function TModBusDriver.HasTabBuilderEditor: Boolean;
begin
  Result := True;
end;

procedure SetTagBuilderToolForModBusProtocolFamily(TagBuilderTool: TOpenTagEditor);
begin
  if Assigned(ModbusTagBuilderEditor) then
    raise Exception.Create('A Tag Builder editor for Modbus RTU/TCP protocol family was already Assigned.')
  else
    ModbusTagBuilderEditor := TagBuilderTool;
end;

end.

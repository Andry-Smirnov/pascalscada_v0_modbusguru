{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit that implements the base of MC PROTOCOL drivers.)
}

(*
The possible variables to be used in the PLC protocol by Mitsubishi " MC Protocol" for series Q/L are the following
Memories outputs: M, SM, L, F, V, X, Y, B
Memories records: D, SD
Table to set MemReadFunction, MemWriteFunction and MemAddress


Variavel/variables | MemReadFunction | MemWriteFunction | MemAddress
M                  |      1          |        1         | valor/value       internal relay
SM                 |      2          |        2         | valor/value       Special relay
L                  |      3          |        3         | valor/value       Latch relay
F                  |      4          |        4         | valor/value       Annunciator
V                  |      5          |        5         | valor/value       Edge relay
X                  |      6          |        6         | valor/value       Input
Y                  |      7          |        7         | valor/value       Output
B                  |      8          |        8         | valor/value       Link relay
D                  |      9          |        9         | valor/value       Data register
SD                 |      16         |        16        | valor/value       Special register

*)
unit MelsecDriver;


interface

uses
  SysUtils,
  Classes,
  CommTypes,
  ProtocolDriver,
  ProtocolTypes,
  Tag,
  PLCTagNumber,
  PLCMemoryManager,
  PLCBlock,
  PLCString
  {$IFNDEF FPC}
  , Windows
  {$ENDIF}
  ;

type
  TMelsecPLC = record
    Station: Longint;

    OutPuts_M: TPLCMemoryManager;
    OutPuts_SM: TPLCMemoryManager;
    OutPuts_L: TPLCMemoryManager;
    OutPuts_F: TPLCMemoryManager;
    OutPuts_V: TPLCMemoryManager;
    OutPuts_X: TPLCMemoryManager;
    OutPuts_Y: TPLCMemoryManager;
    OutPuts_B: TPLCMemoryManager;

    Registers_D: TPLCMemoryManager;
    Registers_SD: TPLCMemoryManager;

    Status07Value: Double;
    Status07TimeStamp: TDateTime;
    Status07LastError: TProtocolIOResult;
  end;

  TSeriesCLP = (Serie_Q_L, Serie_IQR);

  { TMelsecDriver }

  TMelsecDriver = class(TProtocolDriver)
  private
    FMustReleaseResources: Boolean;
  protected
    PFirstRequestLen: Longint;
    PFuncByteOffset: Longint;
    PCRCLen: Longint;

    POutput_M_MaxHole: Cardinal;
    POutput_SM_MaxHole: Cardinal;
    POutput_L_MaxHole: Cardinal;
    POutput_F_MaxHole: Cardinal;
    POutput_V_MaxHole: Cardinal;
    POutput_X_MaxHole: Cardinal;
    POutput_Y_MaxHole: Cardinal;
    POutput_B_MaxHole: Cardinal;

    PRegisters_D_MaxHole: Cardinal;
    PRegisters_SD_MaxHole: Cardinal;

    FSerieCLP: TSeriesCLP;

    PInternalDelayBetweenCmds: Cardinal;
    PMelsecPLC: array of TMelsecPLC;

    function GetTagProperts(TagObj: TTag; var Station, Address, Size, RegType, ScanTime: Longint): Boolean;
    procedure SetSerieCLP(NewSerieCLP: TSeriesCLP);

    procedure SetOutput_M_MaxHole(AValue: Cardinal);
    procedure SetOutput_SM_MaxHole(AValue: Cardinal);
    procedure SetOutput_L_MaxHole(AValue: Cardinal);
    procedure SetOutput_F_MaxHole(AValue: Cardinal);
    procedure SetOutput_V_MaxHole(AValue: Cardinal);
    procedure SetOutput_X_MaxHole(AValue: Cardinal);
    procedure SetOutput_Y_MaxHole(AValue: Cardinal);
    procedure SetOutput_B_MaxHole(AValue: Cardinal);

    procedure SetRegister_D_MaxHole(AValue: Cardinal);
    procedure SetRegister_SD_MaxHole(AValue: Cardinal);


    procedure BuildTagRec(PLC, Func, StartAddress, Size: Longint; var TagObj: TTagRec);
    function EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes; virtual;
    function DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult; virtual;
    function RemainingBytesWrite(Buffer: Bytes): Longint; virtual;
    function RemainingBytesRead(Buffer: Bytes; TagObj: TTagRec): Longint; virtual;
    procedure DoAddTag(TagObj: TTag; TagValid: Boolean); override;
    procedure DoDelTag(TagObj: TTag); override;
    procedure DoScanRead(Sender: TObject; var NeedSleep: Longint); override;
    procedure DoGetValue(TagObj: TTagRec; var Values: TScanReadRec); override;
    function DoWrite(const TagObj: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
    function DoRead(const TagObj: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;

    function PlcDeviceType(MemReadWriteFunction: Integer): Integer; virtual;

    property Output_M_MaxHole: Cardinal read POutput_M_MaxHole write SetOutput_M_MaxHole default 10;
    property Output_SM_MaxHole: Cardinal read POutput_SM_MaxHole write SetOutput_SM_MaxHole default 10;
    property Output_L_MaxHole: Cardinal read POutput_L_MaxHole write SetOutput_L_MaxHole default 10;
    property Output_F_MaxHole: Cardinal read POutput_F_MaxHole write SetOutput_F_MaxHole default 10;
    property Output_V_MaxHole: Cardinal read POutput_V_MaxHole write SetOutput_V_MaxHole default 10;
    property Output_X_MaxHole: Cardinal read POutput_X_MaxHole write SetOutput_X_MaxHole default 10;
    property Output_Y_MaxHole: Cardinal read POutput_Y_MaxHole write SetOutput_Y_MaxHole default 10;
    property Output_B_MaxHole: Cardinal read POutput_B_MaxHole write SetOutput_B_MaxHole default 10;

    property Register_D_MaxHole: Cardinal read PRegisters_D_MaxHole write SetRegister_D_MaxHole default 10;
    property Register_SD_MaxHole: Cardinal read PRegisters_SD_MaxHole write SetRegister_SD_MaxHole default 10;

    property SerieCLP: TSeriesCLP read FSerieCLP write SetSerieCLP default Serie_Q_L;

    property ReadOnly;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function SizeOfTag(ATag: TTag; isWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte; override;
    procedure OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); override;
    function HasTabBuilderEditor: Boolean; override;
  end;


procedure SetTagBuilderToolForMelsecProtocolFamily(TagBuilderTool: TOpenTagEditor);


implementation


uses
  crossdatetime,
  pascalScadaMTPCPU;


procedure TMelsecDriver.BuildTagRec(PLC, Func, StartAddress, Size: Longint; var TagObj: TTagRec);
begin
  with TagObj do
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
  TagObj.Size := Size;
end;

constructor TMelsecDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProtocolReady := False;

  POutput_M_MaxHole := 10;
  POutput_SM_MaxHole := 10;
  POutput_L_MaxHole := 10;
  POutput_F_MaxHole := 10;
  POutput_V_MaxHole := 10;
  POutput_X_MaxHole := 10;
  POutput_Y_MaxHole := 10;
  POutput_B_MaxHole := 10;

  PRegisters_D_MaxHole := 10;
  PRegisters_SD_MaxHole := 10;

  PReadSomethingAlways := True;
  PInternalDelayBetweenCmds := 5;
  SetLength(PMelsecPLC, 0);
end;

function TMelsecDriver.DecodePkg(Pkg: TIOPacket; out Values: TArrayOfDouble): TProtocolIOResult;
begin
  Result := ioDriverError;
end;

destructor TMelsecDriver.Destroy;
var
  PLC: Longint;
begin
  inherited Destroy;
  for PLC := 0 to High(PMelsecPLC) do
    begin
      PMelsecPLC[PLC].OutPuts_M.Destroy;
      PMelsecPLC[PLC].OutPuts_SM.Destroy;
      PMelsecPLC[PLC].OutPuts_L.Destroy;
      PMelsecPLC[PLC].OutPuts_F.Destroy;
      PMelsecPLC[PLC].OutPuts_V.Destroy;
      PMelsecPLC[PLC].OutPuts_X.Destroy;
      PMelsecPLC[PLC].OutPuts_Y.Destroy;
      PMelsecPLC[PLC].OutPuts_B.Destroy;
      PMelsecPLC[PLC].Registers_D.Destroy;
      PMelsecPLC[PLC].Registers_SD.Destroy;
    end;
  SetLength(PMelsecPLC, 0);
end;

procedure TMelsecDriver.DoAddTag(TagObj: TTag; TagValid: Boolean);
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
  // retrieve informations of the tag
  Station := 0;
  Mem := 0;
  Size := 0;
  MemType := 0;
  ScanTime := 0;
  AValue := False;

  Found := GetTagProperts(TagObj, Station, Mem, Size, MemType, ScanTime);

  if Found then
    // check if the address of the slave is valid
    if Station in [1..255] then
    begin
      Found := False;
      for PLC := 0 to High(PMelsecPLC) do
        if PMelsecPLC[PLC].Station = Station then
        begin
          Found := True;
          Break;
        end;
      // if not Found the slave, add it
      if not Found then
      begin
        PLC := Length(PMelsecPLC);
        SetLength(PMelsecPLC, PLC + 1);
        PMelsecPLC[PLC].Station := Station;

        PMelsecPLC[PLC].OutPuts_M := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].OutPuts_M.MaxBlockItems := 10;
        PMelsecPLC[PLC].OutPuts_M.MaxHole := POutput_M_MaxHole;

        PMelsecPLC[PLC].OutPuts_SM := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].OutPuts_SM.MaxBlockItems := 10;
        PMelsecPLC[PLC].OutPuts_SM.MaxHole := POutput_SM_MaxHole;

        PMelsecPLC[PLC].OutPuts_L := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].OutPuts_L.MaxBlockItems := 10;
        PMelsecPLC[PLC].OutPuts_L.MaxHole := POutput_L_MaxHole;

        PMelsecPLC[PLC].OutPuts_F := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].OutPuts_F.MaxBlockItems := 10;
        PMelsecPLC[PLC].OutPuts_F.MaxHole := POutput_F_MaxHole;

        PMelsecPLC[PLC].OutPuts_V := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].OutPuts_V.MaxBlockItems := 10;
        PMelsecPLC[PLC].OutPuts_V.MaxHole := POutput_V_MaxHole;

        PMelsecPLC[PLC].OutPuts_X := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].OutPuts_X.MaxBlockItems := 10;
        PMelsecPLC[PLC].OutPuts_X.MaxHole := POutput_X_MaxHole;

        PMelsecPLC[PLC].OutPuts_Y := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].OutPuts_Y.MaxBlockItems := 10;
        PMelsecPLC[PLC].OutPuts_Y.MaxHole := POutput_Y_MaxHole;

        PMelsecPLC[PLC].OutPuts_B := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].OutPuts_B.MaxBlockItems := 10;
        PMelsecPLC[PLC].OutPuts_B.MaxHole := POutput_B_MaxHole;

        PMelsecPLC[PLC].Registers_D := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].Registers_D.MaxBlockItems := 10;
        PMelsecPLC[PLC].Registers_D.MaxHole := PRegisters_D_MaxHole;

        PMelsecPLC[PLC].Registers_SD := TPLCMemoryManager.Create();
        PMelsecPLC[PLC].Registers_SD.MaxBlockItems := 10;
        PMelsecPLC[PLC].Registers_SD.MaxHole := PRegisters_SD_MaxHole;
      end;

      AValue := (MemType in [1..16]);

      case MemType of
        $01: PMelsecPLC[PLC].OutPuts_M.AddAddress(Mem, Size, 1, ScanTime);
        $02: PMelsecPLC[PLC].OutPuts_SM.AddAddress(Mem, Size, 1, ScanTime);
        $03: PMelsecPLC[PLC].OutPuts_L.AddAddress(Mem, Size, 1, ScanTime);
        $04: PMelsecPLC[PLC].OutPuts_F.AddAddress(Mem, Size, 1, ScanTime);
        $05: PMelsecPLC[PLC].OutPuts_V.AddAddress(Mem, Size, 1, ScanTime);
        $06: PMelsecPLC[PLC].OutPuts_X.AddAddress(Mem, Size, 1, ScanTime);
        $07: PMelsecPLC[PLC].OutPuts_Y.AddAddress(Mem, Size, 1, ScanTime);
        $08: PMelsecPLC[PLC].OutPuts_B.AddAddress(Mem, Size, 1, ScanTime);
        $09: PMelsecPLC[PLC].Registers_D.AddAddress(Mem, Size, 1, ScanTime);
        $10: PMelsecPLC[PLC].Registers_SD.AddAddress(Mem, Size, 1, ScanTime);
      end;
    end;
  inherited DoAddTag(TagObj, AValue);
end;

procedure TMelsecDriver.DoDelTag(TagObj: TTag);
var
  Station: Longint;
  Mem: Longint;
  Size: Longint;
  MemType: Longint;
  ScanTime: Longint;
  Found: Boolean;
  PLC: Longint;
begin
  // retrieve informations about the tag
  Station := 0;
  Mem := 0;
  Size := 0;
  MemType := 0;
  ScanTime := 0;
  Found := GetTagProperts(TagObj, Station, Mem, Size, MemType, ScanTime);

  if Found then
    // check if the slave address is valid
    if Station in [1..255] then
    begin
      Found := False;
      for PLC := 0 to High(PMelsecPLC) do
        if PMelsecPLC[PLC].Station = Station then
        begin
          Found := True;
          Break;
        end;

      // if Found the slave, removes the tag
      if Found then
      begin
        case MemType of
          $01: PMelsecPLC[PLC].OutPuts_M.RemoveAddress(Mem, Size, 1);
          $02: PMelsecPLC[PLC].OutPuts_SM.RemoveAddress(Mem, Size, 1);
          $03: PMelsecPLC[PLC].OutPuts_L.RemoveAddress(Mem, Size, 1);
          $04: PMelsecPLC[PLC].OutPuts_F.RemoveAddress(Mem, Size, 1);
          $05: PMelsecPLC[PLC].OutPuts_V.RemoveAddress(Mem, Size, 1);
          $06: PMelsecPLC[PLC].OutPuts_X.RemoveAddress(Mem, Size, 1);
          $07: PMelsecPLC[PLC].OutPuts_Y.RemoveAddress(Mem, Size, 1);
          $08: PMelsecPLC[PLC].OutPuts_B.RemoveAddress(Mem, Size, 1);
          $09: PMelsecPLC[PLC].Registers_D.RemoveAddress(Mem, Size, 1);
          $10: PMelsecPLC[PLC].Registers_SD.RemoveAddress(Mem, Size, 1);
        end;
      end;
    end;
  inherited DoDelTag(TagObj);
end;

procedure TMelsecDriver.DoGetValue(TagObj: TTagRec; var Values: TScanReadRec);
var
  PLC: Longint;
  Found: Boolean;
begin
  if Length(Values.Values) < TagObj.Size then
    SetLength(Values.Values, TagObj.Size);

  for PLC := 0 to Length(Values.Values) - 1 do
    Values.Values[PLC] := 0;

  Found := False;
  for PLC := 0 to High(PMelsecPLC) do
    if PMelsecPLC[PLC].Station = TagObj.Station then
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
      SetLength(Values.Values, 0);
      Exit;
    end;

  case TagObj.ReadFunction of
    $01: PMelsecPLC[PLC].OutPuts_M.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $02: PMelsecPLC[PLC].OutPuts_SM.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $03: PMelsecPLC[PLC].OutPuts_L.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $04: PMelsecPLC[PLC].OutPuts_F.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $05: PMelsecPLC[PLC].OutPuts_V.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $06: PMelsecPLC[PLC].OutPuts_X.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $07: PMelsecPLC[PLC].OutPuts_Y.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $08: PMelsecPLC[PLC].OutPuts_B.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $09: PMelsecPLC[PLC].Registers_D.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
    $10: PMelsecPLC[PLC].Registers_SD.GetValues(TagObj.Address, TagObj.Size, 1, Values.Values, Values.LastQueryResult, Values.ValuesTimestamp);
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

function TMelsecDriver.DoRead(const TagObj: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
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

    Pkg := EncodePkg(TagObj, nil, Rl);
    if PCommPort <> nil then
      begin
        PCommPort.Lock(DriverID);
        Res := PCommPort.IOCommandSync(iocWriteRead, Length(Pkg), Pkg, PFirstRequestLen, DriverID, PInternalDelayBetweenCmds, @IOResult1, Starts, Ends);

        // if the IO result is OK, reads the remaing packet...
        if (Res <> 0) and (IOResult1.ReadIOResult = iorOK) then
          begin
            //retorna o numero de Bytes que est� aguardando ser lido no buffer da porta de comunica��o.
            //calculates the remaining package length at the communication buffer.
            FRemainingBytes := RemainingBytesRead(IOResult1.BufferToRead, TagObj);

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
          Result := ioEmptyPacket;

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

procedure TMelsecDriver.DoScanRead(Sender: TObject; var NeedSleep: Longint);
var
  PLC: Longint;
  Block: Longint;
  Done: Boolean;
  First: Boolean;
  MinScan: Int64;
  LastType: Longint;
  LastBlock: TRegisterRange;
  LastPLC: Longint;
  TagObj: TTagRec;
  Values: TArrayOfDouble;
begin
  try
    MinScan := -1;
    First := True;
    Done := False;
    if ([csDestroying] * ComponentState <> []) then
    begin
      CrossThreadSwitch;
      Exit;
    end;

    for PLC := 0 to High(PMelsecPLC) do
    begin
      // memory "M"
      for Block := 0 to High(PMelsecPLC[PLC].OutPuts_M.Blocks) do
        if PMelsecPLC[PLC].OutPuts_M.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $01, PMelsecPLC[PLC].OutPuts_M.Blocks[Block].AddressStart, PMelsecPLC[PLC].OutPuts_M.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $01;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_M.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_M.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].OutPuts_M.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $01;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_M.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_M.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;

      // memory "SM"
      for Block := 0 to High(PMelsecPLC[PLC].OutPuts_SM.Blocks) do
        if PMelsecPLC[PLC].OutPuts_SM.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $02, PMelsecPLC[PLC].OutPuts_SM.Blocks[Block].AddressStart, PMelsecPLC[PLC].OutPuts_SM.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $02;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_SM.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_SM.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].OutPuts_SM.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $02;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_SM.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_SM.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;

      // memory "L"
      for Block := 0 to High(PMelsecPLC[PLC].OutPuts_L.Blocks) do
        if PMelsecPLC[PLC].OutPuts_L.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $03, PMelsecPLC[PLC].OutPuts_L.Blocks[Block].AddressStart, PMelsecPLC[PLC].OutPuts_L.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $03;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_L.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_L.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].OutPuts_L.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $03;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_L.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_L.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;

      // memory "F"
      for Block := 0 to High(PMelsecPLC[PLC].OutPuts_F.Blocks) do
        if PMelsecPLC[PLC].OutPuts_F.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $04, PMelsecPLC[PLC].OutPuts_F.Blocks[Block].AddressStart, PMelsecPLC[PLC].OutPuts_F.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $04;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_F.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_F.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].OutPuts_F.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $04;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_F.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_F.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;

      // memory "V"
      for Block := 0 to High(PMelsecPLC[PLC].OutPuts_V.Blocks) do
        if PMelsecPLC[PLC].OutPuts_V.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $05, PMelsecPLC[PLC].OutPuts_V.Blocks[Block].AddressStart, PMelsecPLC[PLC].OutPuts_V.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $05;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_V.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_V.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].OutPuts_V.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $05;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_V.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_V.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;

      // memory "X"
      for Block := 0 to High(PMelsecPLC[PLC].OutPuts_X.Blocks) do
        if PMelsecPLC[PLC].OutPuts_X.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $06, PMelsecPLC[PLC].OutPuts_X.Blocks[Block].AddressStart, PMelsecPLC[PLC].OutPuts_X.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $06;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_X.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_X.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].OutPuts_X.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $06;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_X.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_X.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;

      // memory "Y"
      for Block := 0 to High(PMelsecPLC[PLC].OutPuts_Y.Blocks) do
        if PMelsecPLC[PLC].OutPuts_Y.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $07, PMelsecPLC[PLC].OutPuts_Y.Blocks[Block].AddressStart, PMelsecPLC[PLC].OutPuts_Y.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $07;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_Y.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_Y.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].OutPuts_Y.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $07;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_Y.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_Y.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;

      // memory "B"
      for Block := 0 to High(PMelsecPLC[PLC].OutPuts_B.Blocks) do
        if PMelsecPLC[PLC].OutPuts_B.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $08, PMelsecPLC[PLC].OutPuts_B.Blocks[Block].AddressStart, PMelsecPLC[PLC].OutPuts_B.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $08;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_B.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_B.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].OutPuts_B.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $08;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].OutPuts_B.Blocks[Block];
              MinScan := PMelsecPLC[PLC].OutPuts_B.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;


      // memory "D"
      for Block := 0 to High(PMelsecPLC[PLC].Registers_D.Blocks) do
        if PMelsecPLC[PLC].Registers_D.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $09, PMelsecPLC[PLC].Registers_D.Blocks[Block].AddressStart, PMelsecPLC[PLC].Registers_D.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $09;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].Registers_D.Blocks[Block];
              MinScan := PMelsecPLC[PLC].Registers_D.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].Registers_D.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $09;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].Registers_D.Blocks[Block];
              MinScan := PMelsecPLC[PLC].Registers_D.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;

      // memory "SD"
      for Block := 0 to High(PMelsecPLC[PLC].Registers_SD.Blocks) do
        if PMelsecPLC[PLC].Registers_SD.Blocks[Block].NeedRefresh then
          begin
            Done := True;
            BuildTagRec(PMelsecPLC[PLC].Station, $10, PMelsecPLC[PLC].Registers_SD.Blocks[Block].AddressStart, PMelsecPLC[PLC].Registers_SD.Blocks[Block].Size, TagObj);
            FMustReleaseResources := True;
            DoRead(TagObj, Values, False);
            FMustReleaseResources := False;
          end
        else
          begin
            if First then
            begin
              LastType := $10;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].Registers_SD.Blocks[Block];
              MinScan := PMelsecPLC[PLC].Registers_SD.Blocks[Block].MilisecondsFromLastUpdate;
              First := False;
            end;
            if PMelsecPLC[PLC].Registers_SD.Blocks[Block].MilisecondsFromLastUpdate > MinScan then
            begin
              LastType := $10;
              LastPLC := PMelsecPLC[PLC].Station;
              LastBlock := PMelsecPLC[PLC].Registers_SD.Blocks[Block];
              MinScan := PMelsecPLC[PLC].Registers_SD.Blocks[Block].MilisecondsFromLastUpdate;
            end;
          end;
    end;
    // If no blocks have been read, refresh the Block that is nearing its scan timeout

    // if does nothing, update the tag with the oldest timestamp
    if (PReadSomethingAlways) and (Length(PMelsecPLC) > 0) and ((not Done) and (not First)) then
      begin
        // build the tagrec record.
        BuildTagRec(LastPLC, LastType, LastBlock.AddressStart, LastBlock.Size, TagObj);
        FMustReleaseResources := True;
        DoRead(TagObj, Values, False);
        FMustReleaseResources := False;
      end
    else
      NeedSleep := 1;
  finally
    FProtocolReady := True;
    SetLength(Values, 0);
  end;
end;

function TMelsecDriver.DoWrite(const TagObj: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
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
    Pkg := EncodePkg(TagObj, Values, Rl);
    if PCommPort <> nil then
      begin
        PCommPort.Lock(DriverID);
        Res := PCommPort.IOCommandSync(iocWriteRead, Length(Pkg), Pkg, PFirstRequestLen, DriverID, PInternalDelayBetweenCmds, @IOResult1);

        // if the IO result is OK, reads the remaing packet
        if (Res <> 0) and (IOResult1.ReadIOResult = iorOK) then
          begin

            // calculates the remaining package length at the communication buffer
            FRemainingBytes := RemainingBytesWrite(IOResult1.BufferToRead);

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

        PCommPort.Unlock(DriverID);
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

function TMelsecDriver.EncodePkg(TagObj: TTagRec; ToWrite: TArrayOfDouble; var ResultLen: Longint): Bytes;
begin
  Result := nil;
end;

function TMelsecDriver.GetTagProperts(TagObj: TTag; var Station, Address, Size, RegType, ScanTime: Longint): Boolean;
var
  Found: Boolean;
begin
  Found := False;
  Result := False;
  // PLCTagNumber
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

  // TPLCBlock and TPLCStruct
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

  // TPLCString
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

function TMelsecDriver.HasTabBuilderEditor: Boolean;
begin
  Result := True;
end;


var
  MelsecTagBuilderEditor: TOpenTagEditor = nil;


procedure TMelsecDriver.OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  if Assigned(MelsecTagBuilderEditor) then
    MelsecTagBuilderEditor(Self, Self.Owner, InsertHook, CreateProc)
  else
    inherited;
end;

function TMelsecDriver.PlcDeviceType(MemReadWriteFunction: Integer): Integer;
begin
  Result := 0;
end;

function TMelsecDriver.RemainingBytesWrite(Buffer: Bytes): Longint;
begin
  Result := 0;
end;

function TMelsecDriver.RemainingBytesRead(Buffer: Bytes; TagObj: TTagRec): Longint;
begin
  Result := 0;
end;

procedure TMelsecDriver.SetOutput_M_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutput_M_MaxHole then
    Exit;

  POutput_M_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].OutPuts_M.MaxHole := AValue;
end;

procedure TMelsecDriver.SetOutput_SM_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutput_SM_MaxHole then
    Exit;

  POutput_SM_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].OutPuts_SM.MaxHole := AValue;
end;

procedure TMelsecDriver.SetOutput_L_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutput_L_MaxHole then
    Exit;

  POutput_L_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].OutPuts_L.MaxHole := AValue;
end;

procedure TMelsecDriver.SetOutput_F_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutput_F_MaxHole then
    Exit;

  POutput_F_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].OutPuts_F.MaxHole := AValue;
end;

procedure TMelsecDriver.SetOutput_V_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutput_V_MaxHole then
    Exit;

  POutput_V_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].OutPuts_V.MaxHole := AValue;
end;

procedure TMelsecDriver.SetOutput_X_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutput_X_MaxHole then
    Exit;

  POutput_X_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].OutPuts_X.MaxHole := AValue;
end;

procedure TMelsecDriver.SetOutput_Y_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutput_Y_MaxHole then
    Exit;

  POutput_Y_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].OutPuts_Y.MaxHole := AValue;
end;

procedure TMelsecDriver.SetOutput_B_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = POutput_B_MaxHole then
    Exit;

  POutput_B_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].OutPuts_B.MaxHole := AValue;
end;

procedure TMelsecDriver.SetRegister_D_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = PRegisters_D_MaxHole then
    Exit;

  PRegisters_D_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].Registers_D.MaxHole := AValue;
end;

procedure TMelsecDriver.SetRegister_SD_MaxHole(AValue: Cardinal);
var
  PLC: Longint;
begin
  if AValue = PRegisters_SD_MaxHole then
    Exit;

  PRegisters_SD_MaxHole := AValue;

  for PLC := 0 to High(PMelsecPLC) do
    PMelsecPLC[PLC].Registers_SD.MaxHole := AValue;
end;

procedure TMelsecDriver.SetSerieCLP(NewSerieCLP: TSeriesCLP);
begin
  FSerieCLP := NewSerieCLP;
end;

function TMelsecDriver.SizeOfTag(ATag: TTag; isWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte;
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

  // TPLCBlock and TPLCStruct
  if (ATag is TPLCBlock) then
  begin
    if (isWrite) then
      FunctionCode := TPLCBlock(ATag).MemWriteFunction
    else
      FunctionCode := TPLCBlock(ATag).MemReadFunction;
  end;

  // TPLCString
  if (ATag is TPLCString) then
  begin
    if (isWrite) then
      FunctionCode := TPLCString(ATag).MemWriteFunction
    else
      FunctionCode := TPLCString(ATag).MemReadFunction;
  end;

  // Returns the size in bits of the registers read/written by each type
  // of read/write function

  // return the size in bits of the tag
  case FunctionCode of
    $01, $02,
    $03, $04,
    $05, $06,
    $07, $08: begin
                Result := $01;
                ProtocolTagType := ptBit;
              end;
    $09, $10: begin
                Result := $10;
                ProtocolTagType := ptWord;
              end
    else
      Result := $10;
  end;
end;

procedure SetTagBuilderToolForMelsecProtocolFamily(TagBuilderTool: TOpenTagEditor);
begin
  if Assigned(MelsecTagBuilderEditor) then
    raise Exception.Create('A Tag Builder editor for MC protocol family was already Assigned.')
  else
    MelsecTagBuilderEditor := TagBuilderTool;
end;


end.

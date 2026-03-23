{$i ../common/language.inc}
{:
  @abstract(Implmentation of West n6100 ASCII protocol driver.)

  ***********************************************************************
  07/2013 - Moved OpenTagEditor to TagBuilderAssistant to remove form dependencies
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
unit WestASCIIDriver;

interface

uses
  Classes, SysUtils, ProtocolDriver, Tag, ProtocolTypes, commtypes
{$IFNDEF FPC}
  , Windows
{$ENDIF}
  ;

type
  {: Identify a West n6100 parameter.
  @member ParameterID identifica o parametro West.
  @member FunctionAllowed funções West permitidas para esse parametro.
  @member ReadOnly Identifica um parametro somente reading.
  @member Decimal Identifica quantas casas decimais o parametro tem por padrão. }
  TParameter = record
    ParameterID: Byte;
    FunctionAllowed: Byte;
    ReadOnly: Boolean;
    Decimal: Byte;
  end;

  //: Update time of a West register.
  TScanTime = record
    ScanTime: Longint;
    RefCount: Longint;
  end;

  {: Identify a West n6100 register.
  @member Value register value.
  @member Decimal Decimal places of the register.
  @member Timestamp Date/time of the last update of the register.
  @member LastReadResult IO result of the last read request.
  @member LastWriteResult IO result of the last write request.
  @member ScanTimes List of all update times of the register.
  @member MinScanTime Smaller update time of the register. }
  TWestRegister = record
    Value: Double;
    Decimal: Byte;
    Timestamp: TDateTime;
    LastReadResult: TProtocolIOResult;
    LastWriteResult: TProtocolIOResult;
    ScanTimes: array of TScanTime;
    MinScanTime: Longint;
  end;

  //: List all West n6100 registers.
  TWestRegisters = array [$00..$1B] of TWestRegister;

  //: Identifies the address range of West n6100.
  TWestAddressRange = 0..99;

  //: Identifies a West n6100 device.
  TWestDevice = record
    Address: TWestAddressRange;
    Registers: TWestRegisters;
  end;

  //: Identifies a set of West n6100 devices.
  TWestDevices = array of TWestDevice;

  //: Represents a item of a West ScanTable request.
  TScanTableReg = record
    Value: Double;
    Decimal: Byte;
    IOResult: TProtocolIOResult;
    Timestamp: TDateTime;
  end;

  //: Represents a West ScanTable request.
  TScanTable = record
    PV: TScanTableReg;
    SP: TScanTableReg;
    Status: TScanTableReg;
    Out1: TScanTableReg;
    Out2: TScanTableReg;
    HaveOut2: Boolean;
  end;

  {: @abstract(Class of West n6100 ASCII protocol driver.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  To use this driver, you must set the following properties of your tag:

  @unorderedList(
    @item(@bold(TTag.MemAddress): Address of West  register. See the table below;)
    @item(@bold(TTag.PLCStation): Address of West n6100 device.) )

  To set the property MemAddress, use one of the following values:

  @table(
    @rowHead( @cell(MemAddres Value)  @cell(West register) )
    @row(     @cell(0)                @cell(SetPoint - SP) )
    @row(     @cell(1)                @cell(Process Variable - PV) )
    @row(     @cell(2)                @cell(Power Output value) )
    @row(     @cell(3)                @cell(Controller status) )
    @row(     @cell(4)                @cell(Scale Range Max) )
    @row(     @cell(5)                @cell(Scale Range Min) )
    @row(     @cell(6)                @cell(Scale Range Decimal Point) )
    @row(     @cell(7)                @cell(Input filter time constant) )
    @row(     @cell(8)                @cell(Output 1 Power Limit) )
    @row(     @cell(9)                @cell(Output 1 cycle time) )
    @row(     @cell(10)               @cell(Output 2 cycle time) )
    @row(     @cell(11)               @cell(Recorder output scale max) )
    @row(     @cell(12)               @cell(Recorder output scale min) )
    @row(     @cell(13)               @cell(SetPoint ramp rate) )
    @row(     @cell(14)               @cell(Setpoint high limit) )
    @row(     @cell(15)               @cell(Setpoint low limit) )
    @row(     @cell(16)               @cell(Alarm 1 value) )
    @row(     @cell(17)               @cell(Alarm 2 value) )
    @row(     @cell(18)               @cell(Rate - Derivative time constant) )
    @row(     @cell(19)               @cell(Reset - Integral time constant) )
    @row(     @cell(20)               @cell(Manual time reset - BIAS) )
    @row(     @cell(21)               @cell(ON/OFF diferential) )
    @row(     @cell(22)               @cell(Overlap/Deadband) )
    @row(     @cell(23)               @cell(Proportional band 1 value) )
    @row(     @cell(24)               @cell(Proportional band 2 value) )
    @row(     @cell(25)               @cell(PV Offset) )
    @row(     @cell(26)               @cell(Arithmetic deviation) )
    @row(     @cell(27)               @cell(Arithmetic deviation) ) )

  @bold(Caso um ou mais parametros possam ser lidos por scan table, o driver
  irá fazer isso para ganhar algum desempenho.) }

  { TWestASCIIDriver }

  TWestASCIIDriver = class(TProtocolDriver)
  private
    FWestDevices: TWestDevices;
    {d} procedure AssignScanTableToReg(const StableReg: TScanTableReg; var WestReg: TWestRegister);
    {d} function IOResultToProtocolResult(IORes: TIOResult): TProtocolIOResult;
    {d} procedure AddressToChar(Addr: TWestAddressRange; var Ret: Bytes);
    {d} function WestToDouble(const Buffer: array of Byte; var Value: Double): TProtocolIOResult; overload;
    {d} function WestToDouble(const Buffer: array of Byte; var Value: Double; var Dec: Byte): TProtocolIOResult; overload;
    {d} function DoubleToWestAuto(var Buffer: array of Byte; const Value: Double): TProtocolIOResult;
    {d} function DoubleToWestManual(var Buffer: array of Byte; const Value: Double; const Dec: Byte): TProtocolIOResult;

    {d} function ParameterValue(const DeviceID: TWestAddressRange; const Parameter: Byte; var Value: Double; var Dec: Byte): TProtocolIOResult;
    {d} function ModifyParameter(const DeviceID: TWestAddressRange; const Parameter: Byte; const Value: Double; const Dec: Byte): TProtocolIOResult;

    {d} function ScanTable(DeviceID: TWestAddressRange; var ScanTableValues: TScanTable): TProtocolIOResult;

    {d} procedure MinScanTimeOfReg(var WestReg: TWestRegister);
  protected
    //: @seealso(TProtocolDriver.DoAddTag)
    {d} procedure DoAddTag(TagObj: TTag; TagValid: Boolean); override;
    //: @seealso(TProtocolDriver.DoAddTag)
    {d} procedure DoDelTag(TagObj: TTag); override;
    //: @seealso(TProtocolDriver.DoAddTag)
    procedure DoScanRead(Sender: TObject; var NeedSleep: Longint); override;
    //: @seealso(TProtocolDriver.DoAddTag)
    {d} procedure DoGetValue(TagRec: TTagRec; var Values: TScanReadRec); override;
    //: @seealso(TProtocolDriver.DoAddTag)
    {d} function DoWrite(const TagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
    //: @seealso(TProtocolDriver.DoAddTag)
    {d} function DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    {: Checks if a West n6100 device is active on network.
    @param(DeviceID TWestAddressRange Address of _West n6100 device to check if is active on network.)
    @returns(ioOk if the device is active on network.) }
    function DeviceActive(DeviceID: TWestAddressRange): TProtocolIOResult;

    // @seealso(TProtocolDriver.SizeOfTag);
    function SizeOfTag(aTag: TTag; isWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte; override;

    // @seealso(TProtocolDriver.OpenTagEditor);
    procedure OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); override;

    // @seealso(TProtocolDriver.HasTabBuilderEditor);
    function HasTabBuilderEditor: Boolean; override;
  published
    //: @seealso(TProtocolDriver.ReadSomethingAlways)
    property ReadSomethingAlways;

    property ReadOnly;
  end;


procedure SetTagBuilderToolForWest6100Protocol(TagBuilderTool: TOpenTagEditor);


var
  ParameterList: array [$00..$1B] of TParameter;


implementation


uses
  PLCTagNumber,
  Math,
  dateutils,
  hsstrings,
  crossdatetime,
  pascalScadaMTPCPU;


constructor TWestASCIIDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PReadSomethingAlways := True;
end;

destructor TWestASCIIDriver.Destroy;
begin
  inherited Destroy;
  SetLength(FWestDevices, 0);
end;

procedure TWestASCIIDriver.DoAddTag(TagObj: TTag; TagValid: Boolean);
var
  PLC: Longint;
  ScanRate: Longint;
  FoundPLC: Boolean;
  FoundScanRate: Boolean;
  IsValid: Boolean;
  PLCTagObj: TPLCTagNumber;
begin
  if not (TagObj is TPLCTagNumber) then
    raise Exception.Create(SonlyPLCTagNumber);

  PLCTagObj := TPLCTagNumber(TagObj);

  IsValid := False;

  //se for um tag válido, registra ele no scan. senão só o coloca na lista de
  //tags dependentes...

  //if the tag is valid, register it on scan or on the list of dependent tags
  if (PLCTagObj.PLCStation in [1..99])
    and (PLCTagObj.MemAddress in [$00..$1B]) then
  begin
    FoundPLC := False;
    FoundScanRate := False;

    for PLC := 0 to High(FWestDevices) do
      if FWestDevices[PLC].Address = PLCTagObj.PLCStation then
      begin
        FoundPLC := True;
        Break;
      end;

    if not FoundPLC then
    begin
      PLC := Length(FWestDevices);
      SetLength(FWestDevices, PLC + 1);
      FWestDevices[PLC].Address := PLCTagObj.PLCStation;
    end;

    with FWestDevices[PLC].Registers[PLCTagObj.MemAddress] do
      for ScanRate := 0 to High(ScanTimes) do
        if ScanTimes[ScanRate].ScanTime = PLCTagObj.RefreshTime then
        begin
          FoundScanRate := True;
          Inc(ScanTimes[ScanRate].RefCount);
          Break;
        end;

    if not FoundScanRate then
      with FWestDevices[PLC].Registers[PLCTagObj.MemAddress] do
      begin
        ScanRate := Length(ScanTimes);
        SetLength(ScanTimes, ScanRate + 1);
        ScanTimes[ScanRate].ScanTime := PLCTagObj.RefreshTime;
        ScanTimes[ScanRate].RefCount := 1;
        if ScanRate = 0 then
          MinScanTime := PLCTagObj.RefreshTime;
      end;

    with FWestDevices[PLC].Registers[PLCTagObj.MemAddress] do
      MinScanTime := Min(MinScanTime, PLCTagObj.RefreshTime);

    IsValid := True;
  end;
  inherited DoAddTag(TagObj, IsValid);
end;

procedure TWestASCIIDriver.DoDelTag(TagObj: TTag);
var
  PLC: Longint;
  ScanRate: Longint;
  Reg: Longint;
  H: Longint;
  FoundPLC: Boolean;
  FoundScanRate: Boolean;
  FoundActiveReg: Boolean;
  PLCTagObj: TPLCTagNumber;
begin
  try
    if not (TagObj is TPLCTagNumber) then
      raise Exception.Create(SonlyPLCTagNumber);

    PLCTagObj := TPLCTagNumber(TagObj);

    if (PLCTagObj.PLCStation in [1..99])
      and (PLCTagObj.MemAddress in [$00..$1B]) then
    begin
      FoundPLC := False;
      FoundScanRate := False;

      for PLC := 0 to High(FWestDevices) do
        if FWestDevices[PLC].Address = PLCTagObj.PLCStation then
        begin
          FoundPLC := True;
          Break;
        end;
      // if don't found the PLC, has nothing to do,
      // because if the PLC don't exists, the memory don't exists too
      if not FoundPLC then
        Exit;

      with FWestDevices[PLC].Registers[PLCTagObj.MemAddress] do
      begin
        H := High(ScanTimes);
        for ScanRate := 0 to High(ScanTimes) do
          if ScanTimes[ScanRate].ScanTime = PLCTagObj.RefreshTime then
          begin
            FoundScanRate := True;

            Dec(ScanTimes[ScanRate].RefCount);

            // if the update time don't has dependents, remove
            if ScanTimes[ScanRate].RefCount = 0 then
            begin
              ScanTimes[ScanRate] := ScanTimes[H];
              SetLength(ScanTimes, H);
              MinScanTime := $7FFFFFFF;
            end;
            Break;
          end;
      end;

      if not FoundScanRate then
        Exit;

      // search active registers on scan
      FoundActiveReg := False;
      for Reg := 0 to High(FWestDevices[PLC].Registers) do
        if Length(FWestDevices[PLC].Registers[Reg].ScanTimes) > 0 then
        begin
          FoundActiveReg := True;
          Break;
        end;

      if FoundActiveReg then
        MinScanTimeOfReg(FWestDevices[PLC].Registers[PLCTagObj.MemAddress])
      else if (Length(FWestDevices) > 0) then
        begin
          // if has not found any other active register on PLC, removes the PLC
          H := High(FWestDevices);
          FWestDevices[PLC] := FWestDevices[H];
          SetLength(FWestDevices, H);
        end;
    end;
  finally
    inherited DoDelTag(TagObj);
  end;
end;

procedure TWestASCIIDriver.DoScanRead(Sender: TObject; var NeedSleep: Longint);
var
  PLC: Longint;
  PLCNeedy: Longint;
  Reg: Longint;
  RegNeedy: Longint;
  RegIni: Longint;
  Usados: Longint;
  MSBetween: Longint;
  MinStime: Longint;
  SomethingDone: Boolean;
  FirstReg: Boolean;
  Res: TProtocolIOResult;
  Stable: TScanTable;
  TagRec: TTagRec;
  Values: TArrayOfDouble;
begin
  if ([csDestroying] * ComponentState <> []) then
  begin
    CrossThreadSwitch;
    Exit;
  end;
  PLCNeedy := 0;
  RegNeedy := 0;
  SomethingDone := False;
  SetLength(Values, 1);
  FirstReg := True;
  try
    for PLC := 0 to High(FWestDevices) do
    begin
      RegIni := 0;
      Usados := 0;
      with FWestDevices[PLC] do
      begin
        Usados := IfThen((Length(Registers[0].ScanTimes) > 0)
          and (MilliSecondsBetween(CrossNow, Registers[0].Timestamp) >= Registers[0].MinScanTime), Usados + 1, Usados);
        Usados := IfThen((Length(Registers[1].ScanTimes) > 0)
          and (MilliSecondsBetween(CrossNow, Registers[1].Timestamp) >= Registers[1].MinScanTime), Usados + 1, Usados);
        Usados := IfThen((Length(Registers[2].ScanTimes) > 0)
          and (MilliSecondsBetween(CrossNow, Registers[2].Timestamp) >= Registers[2].MinScanTime), Usados + 1, Usados);
        Usados := IfThen((Length(Registers[3].ScanTimes) > 0)
          and (MilliSecondsBetween(CrossNow, Registers[3].Timestamp) >= Registers[3].MinScanTime), Usados + 1, Usados);
      end;

      TagRec.Station := FWestDevices[PLC].Address;

      // if exist more than one register used, Read it using ScanTable
      // command to reduce the use of bandwidth
      if Usados > 1 then
      begin
        Res := ScanTable(FWestDevices[PLC].Address, Stable);
        if Res = ioOk then
          begin
            AssignScanTableToReg(Stable.SP, FWestDevices[PLC].Registers[0]);
            AssignScanTableToReg(Stable.PV, FWestDevices[PLC].Registers[1]);
            AssignScanTableToReg(Stable.Out1, FWestDevices[PLC].Registers[2]);
            AssignScanTableToReg(Stable.Status, FWestDevices[PLC].Registers[3]);
          end
        else
          begin
            for Reg := 0 to 3 do
              FWestDevices[PLC].Registers[Reg].LastReadResult := Res;
          end;
        RegIni := 4;
        SomethingDone := True;
      end;

      // le os
      for Reg := RegIni to High(FWestDevices[PLC].Registers) do
        with FWestDevices[PLC].Registers[Reg] do
          if Length(ScanTimes) > 0 then
            begin
              MSBetween := MilliSecondsBetween(CrossNow, Timestamp);
              if MSBetween >= MinScanTime then
                begin
                  TagRec.Address := Reg;
                  DoRead(TagRec, Values, False);
                  SomethingDone := True;
                end
              else
                begin
                  if FirstReg then
                    begin
                      MinStime := MSBetween;
                      PLCNeedy := PLC;
                      RegNeedy := Reg;
                      FirstReg := False;
                    end
                  else
                  begin
                    if MSBetween > MinStime then
                    begin
                      MinStime := MSBetween;
                      PLCNeedy := PLC;
                      RegNeedy := Reg;
                    end;
                  end;
                end;
            end;
    end;

    if (not SomethingDone) and PReadSomethingAlways and (High(FWestDevices) >= PLCNeedy) then
    begin
      TagRec.Station := FWestDevices[PLCNeedy].Address;
      TagRec.Address := RegNeedy;
      DoRead(TagRec, Values, False);
    end
    else
      NeedSleep := 1;
  finally
    SetLength(Values, 0);
  end;
end;

procedure TWestASCIIDriver.DoGetValue(TagRec: TTagRec; var Values: TScanReadRec);
var
  PLC: Longint;
begin
  if (TagRec.Station < 1) or (TagRec.Station > 99) then
    Exit;

  if (TagRec.Address < $00) or (TagRec.Address > $1B) then
    Exit;

  for PLC := 0 to High(FWestDevices) do
    if FWestDevices[PLC].Address = TagRec.Station then
    begin
      SetLength(Values.values, 1);
      Values.values[0] := FWestDevices[PLC].Registers[TagRec.Address].Value;
      Values.LastQueryResult := FWestDevices[PLC].Registers[TagRec.Address].LastReadResult;
      Values.ValuesTimestamp := FWestDevices[PLC].Registers[TagRec.Address].Timestamp;
      Break;
    end;
end;

function TWestASCIIDriver.DoWrite(const TagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  PLC: Longint;
  Dec: Byte;
  FoundPLC: Boolean;
begin
  if (TagRec.Station < 1) or (TagRec.Station > 99) then
  begin
    Result := ioIllegalStationAddress;
    Exit;
  end;

  if (TagRec.Address < $00) or (TagRec.Address > $1b) then
  begin
    Result := ioIllegalRegAddress;
    Exit;
  end;

  if ParameterList[TagRec.Address].Decimal = 255 then
    begin
      FoundPLC := False;
      for PLC := 0 to High(FWestDevices) do
        if FWestDevices[PLC].Address = TagRec.Station then
        begin
          FoundPLC := True;
          Dec := FWestDevices[PLC].Registers[TagRec.Address].Decimal;
          Break;
        end;
      if not FoundPLC then
        Dec := 255;
    end
  else
    Dec := ParameterList[TagRec.Address].Decimal;

  if Length(Values) > 0 then
    Result := ModifyParameter(TagRec.Station, ParameterList[TagRec.Address].ParameterID, Values[0], Dec)
  else
    Result := ioIllegalValue;

  if FoundPLC then
  begin
    with FWestDevices[PLC].Registers[TagRec.Address] do
    begin
      if (Length(Values) > 0) and (Result = ioOk) then
      begin
        Value := Values[0];
        Timestamp := CrossNow;
      end;
      LastWriteResult := Result;
    end;
  end;
end;

function TWestASCIIDriver.DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  PLC: Longint;
  Dec: Byte;
  FoundPLC: Boolean;
begin
  if (TagRec.Station < 1) or (TagRec.Station > 99) then
  begin
    Result := ioIllegalStationAddress;
    Exit;
  end;

  if (TagRec.Address < $00) or (TagRec.Address > $1b) then
  begin
    Result := ioIllegalRegAddress;
    Exit;
  end;

  FoundPLC := False;
  for PLC := 0 to High(FWestDevices) do
    if FWestDevices[PLC].Address = TagRec.Station then
    begin
      FoundPLC := True;
      Break;
    end;

  if Length({%H-}Values) > 0 then
    Result := ParameterValue(TagRec.Station, ParameterList[TagRec.Address].ParameterID, Values[0], Dec)
  else
  begin
    Result := ioDriverError;
  end;

  if FoundPLC then
    with FWestDevices[PLC].Registers[TagRec.Address] do
    begin
      if (Length(Values) > 0) and (Result = ioOk) then
      begin
        Value := Values[0];
        Decimal := Dec;
        Timestamp := CrossNow;
      end;
      LastReadResult := Result;
    end;
end;

function TWestASCIIDriver.DeviceActive(DeviceID: TWestAddressRange): TProtocolIOResult;
var
  Buffer: Bytes;
  No: Bytes;
  Pkg: TIOPacket;
begin
  try
    SetLength(Buffer, 6);
    SetLength(No, 2);

    AddressToChar(DeviceID, No);

    Buffer[0] := $4C;
    Buffer[1] := No[0];
    Buffer[2] := No[1];
    Buffer[3] := $3F;
    Buffer[4] := $3F;
    Buffer[5] := $2A;

    if PCommPort = nil then
    begin
      Result := ioNullDriver;
      Exit;
    end;

    if PCommPort.IOCommandSync(iocWriteRead, 6, Buffer, 6, DriverID, 5, @Pkg) = 0 then
    begin
      Result := ioDriverError;
      Exit;
    end;

    Result := IOResultToProtocolResult(Pkg.WriteIOResult);
    if Result <> ioOk then
      Exit;
    Result := IOResultToProtocolResult(Pkg.ReadIOResult);
    if Result <> ioOk then
      Exit;

    SetLength(Buffer, 0);
    Buffer := Pkg.BufferToRead;

    if (Buffer[0] = $4C)
      and (Buffer[1] = No[0])
      and (Buffer[2] = No[1])
      and (Buffer[3] = $3F)
      and (Buffer[4] = $41)
      and (Buffer[5] = $2A) then
    begin
      Result := ioOk;
      Exit;
    end;

    if (Buffer[0] = $4C)
      and (Buffer[1] = No[1])
      and (Buffer[2] = $3F)
      and (Buffer[3] = $41)
      and (Buffer[4] = $2A) then
    begin
      Result := ioOk;
      Exit;
    end;

    Result := ioCommError;
  finally
    SetLength(Pkg.BufferToRead, 0);
    SetLength(Pkg.BufferToWrite, 0);
    SetLength(Buffer, 0);
    SetLength(No, 0);
  end;
end;

procedure TWestASCIIDriver.AddressToChar(Addr: TWestAddressRange; var Ret: Bytes);
var
  Dozens: Byte;
  AUnits: Byte;
begin
  if not Assigned(Ret) then Exit;

  // Test the conditions that would cause this procedure to fail
  if ((Addr < 1) or (Addr > 98)) then
    raise Exception.Create(SoutOfBounds);

  AUnits := Addr mod 10;
  Dozens := (Addr - AUnits) div 10;

  Ret[0] := (48 + Dozens);
  Ret[1] := (48 + AUnits);
end;

function TWestASCIIDriver.WestToDouble(const Buffer: array of Byte; var Value: Double; var Dec: Byte): TProtocolIOResult;
var
  a: Byte;
  b: Byte;
  c: Byte;
  d: Byte;
  R: Byte;
  i: Longint;
  Aux: Longint;
begin
  if    (Buffer[0] = $3C)
    and (Buffer[1] = $3F)
    and (Buffer[2] = $3F)
    and (Buffer[3] = $3E) then
  begin
    Result := ioIllegalValue;
    Exit;
  end;

  for i := 0 to 4 do
  begin
    Aux := (Buffer[i] - 48);
    if ((Aux < 0) or (Aux > 9)) then
    begin
      Result := ioCommError;
      Exit;
    end;
  end;

  a := Buffer[0] - 48; // ascii to decimal
  b := Buffer[1] - 48;
  c := Buffer[2] - 48;
  d := Buffer[3] - 48;
  R := Buffer[4];

  case R of
    $30:  begin
            Value := (a * 1000) + (b * 100) + (c * 10) + d;
            Dec := 0;
            Result := ioOk;
          end;
    $31:  begin
            Value := (a * 100) + (b * 10) + c + (d / 10);
            Dec := 1;
            Result := ioOk;
          end;
    $32:  begin
            Value := (a * 10) + b + (c / 10) + (d / 100);
            Dec := 2;
            Result := ioOk;
          end;
    $33:  begin
            Value := a + (b / 10) + (c / 100) + (d / 1000);
            Dec := 3;
            Result := ioOk;
          end;
    $35:  begin
            Value := ((a * 1000) + (b * 100) + (c * 10) + d) * (-1);
            Dec := 0;
            Result := ioOk;
          end;
    $36:  begin
            Value := ((a * 100) + (b * 10) + c + (d / 10)) * (-1);
            Dec := 1;
            Result := ioOk;
          end;
    $37:  begin
            Value := ((a * 10) + (b) + (c / 10) + (d / 100)) * (-1);
            Dec := 2;
            Result := ioOk;
          end;
    $38:  begin
            Value := (a + (b / 10) + (c / 100) + (d / 1000)) * (-1);
            Dec := 3;
            Result := ioOk;
          end;
    else
      Result := ioCommError;
  end;
end;

function TWestASCIIDriver.WestToDouble(const Buffer: array of Byte; var Value: Double): TProtocolIOResult;
var
  Cd: Byte;
begin
  Result := WestToDouble(Buffer, Value, Cd);
end;

function TWestASCIIDriver.DoubleToWestAuto(var Buffer: array of Byte; const Value: Double): TProtocolIOResult;
var
  ACase: Byte;
  NumAux: Extended;
  i: Longint;
  Aux: AnsiString;
begin
  ACase := 255;

  if (Value >= 10000) or (Value <= -10000) then
  begin
    Result := ioIllegalValue;
    Exit;
  end;

  ACase := IfThen((Value >= 1000) and (Value < 10000), $30, ACase);
  ACase := IfThen((Value >= 100) and (Value < 1000), $31, ACase);
  ACase := IfThen((Value >= 10) and (Value < 100), $32, ACase);
  ACase := IfThen((Value >= 0) and (Value < 10), $33, ACase);

  ACase := IfThen((Value <= -1000) and (Value > -10000), $35, ACase);
  ACase := IfThen((Value <= -100) and (Value > -1000), $36, ACase);
  ACase := IfThen((Value <= -10) and (Value > -100), $37, ACase);
  ACase := IfThen((Value < 0) and (Value > -10), $38, ACase);

  case ACase of
    $30: NumAux := Value;
    $31: NumAux := Value * 10;
    $32: NumAux := Value * 100;
    $33: NumAux := Value * 1000;
    $35: NumAux := Value * (-1);
    $36: NumAux := Value * (-10);
    $37: NumAux := Value * (-100);
    $38: NumAux := Value * (-1000);
    else
      begin
        Result := ioIllegalValue;
        Exit;
      end;
  end;

  Aux := FormatFloat('0000', Abs(NumAux));

  for i := 0 to 3 do
    Buffer[i] := StrToInt(Aux[1 + i]) + 48;

  Buffer[4] := ACase;
  Result := ioOk;
end;

function TWestASCIIDriver.DoubleToWestManual(var Buffer: array of Byte; const Value: Double; const Dec: Byte): TProtocolIOResult;
var
  ACase: Byte;
  i: Longint;
  NumAux: Double;
  Aux: AnsiString;
begin
  ACase := 255;

  if (Value >= 10000) or (Value <= -10000) then
  begin
    Result := ioIllegalValue;
    Exit;
  end;

  ACase := IfThen(((ACase = 255) and (Dec <= 0) and (Value < 10000) and (Value >= 0)), $30, ACase);
  ACase := IfThen(((ACase = 255) and (Dec <= 1) and (Value < 1000) and (Value >= 0)), $31, ACase);
  ACase := IfThen(((ACase = 255) and (Dec <= 2) and (Value < 100) and (Value >= 0)), $32, ACase);
  ACase := IfThen(((ACase = 255) and (Dec <= 3) and (Value < 10) and (Value >= 0)), $33, ACase);

  ACase := IfThen(((ACase = 255) and (Dec <= 0) and (Value > -10000) and (Value < 0)), $35, ACase);
  ACase := IfThen(((ACase = 255) and (Dec <= 1) and (Value > -1000) and (Value < 0)), $36, ACase);
  ACase := IfThen(((ACase = 255) and (Dec <= 2) and (Value > -100) and (Value < 0)), $37, ACase);
  ACase := IfThen(((ACase = 255) and (Dec <= 3) and (Value > -10) and (Value < 0)), $38, ACase);

  if (ACase = 255) then
  begin
    Result := ioIllegalValue;
    Exit;
  end;

  case ACase of
    $30: NumAux := Value;
    $31: NumAux := Value * 10;
    $32: NumAux := Value * 100;
    $33: NumAux := Value * 1000;
    $35: NumAux := Value * (-1);
    $36: NumAux := Value * (-10);
    $37: NumAux := Value * (-100);
    $38: NumAux := Value * (-1000);
    else
      begin
        Result := ioIllegalValue;
        Exit;
      end;
  end;

  Aux := FormatFloat('0000', Abs(NumAux));

  for i := 0 to 3 do
    Buffer[i] := StrToInt(Aux[1 + i]) + 48;

  Buffer[4] := ACase;
  Result := ioOk;
end;

function TWestASCIIDriver.ParameterValue(const DeviceID: TWestAddressRange; const Parameter: Byte; var Value: Double; var Dec: Byte): TProtocolIOResult;
var
  Buffer: Bytes;
  No: Bytes;
  b1: Boolean;
  b2: Boolean;
  Pkg: TIOPacket;
begin
  try
    SetLength(Buffer, 11);
    SetLength(No, 2);

    AddressToChar(DeviceID, No);

    Buffer[0] := $4C;
    Buffer[1] := No[0];
    Buffer[2] := No[1];
    Buffer[3] := Parameter;
    Buffer[4] := $3F;
    Buffer[5] := $2A;

    if PCommPort = nil then
    begin
      Result := ioNullDriver;
      Exit;
    end;


    if PCommPort.IOCommandSync(iocWriteRead, 6, Buffer, 11, DriverID, 5, @Pkg) = 0 then
    begin
      Result := ioDriverError;
      Exit;
    end;

    Result := IOResultToProtocolResult(Pkg.WriteIOResult);
    if Result <> ioOk then Exit;
    Result := IOResultToProtocolResult(Pkg.ReadIOResult);
    if Result <> ioOk then Exit;

    SetLength(Buffer, 0);
    Buffer := Pkg.BufferToRead;

    b1 := (Buffer[0] = $4C)
      and (Buffer[1] = No[0])
      and (Buffer[2] = No[1])
      and (Buffer[3] = Parameter)
      and (Buffer[9] = $4E)
      and (Buffer[10] = $2A);
    b2 := (Buffer[0] = $4C)
      and (Buffer[1] = No[1])
      and (Buffer[2] = Parameter)
      and (Buffer[8] = $4E)
      and (Buffer[9] = $2A);
    if (b1 or b2) then
      Result := ioIllegalFunction
    else
      begin
        b1 := (Buffer[0] = $4C)
          and (Buffer[1] = No[0])
          and (Buffer[2] = No[1])
          and (Buffer[3] = Parameter)
          and (Buffer[9] = $41)
          and (Buffer[10] = $2A);
        b2 := (Buffer[0] = $4C)
          and (Buffer[1] = No[1])
          and (Buffer[2] = Parameter)
          and (Buffer[8] = $41)
          and (Buffer[9] = $2A);
        if (b1 or b2) then
          begin
            b1 := (Buffer[4] = $3C)
              and (Buffer[5] = $3F)
              and (Buffer[6] = $3F)
              and (Buffer[7] = $3E);

            if b1 then
              Result := ioIllegalValue
            else
              begin
                Result := WestToDouble(Buffer[4], Value, Dec);
              end;
          end
        else
          Result := ioCommError;
      end;
  finally
    SetLength(Pkg.BufferToRead, 0);
    SetLength(Pkg.BufferToWrite, 0);
    SetLength(Buffer, 0);
    SetLength(No, 0);
  end;
end;

function TWestASCIIDriver.ModifyParameter(const DeviceID: TWestAddressRange; const Parameter: Byte; const Value: Double; const Dec: Byte): TProtocolIOResult;
var
  Buffer: Bytes;
  RespProg: Bytes;
  No: Bytes;
  Flag: Boolean;
  Pkg: TIOPacket;
  i: Longint;
begin
  try

    Flag := True;

    SetLength(No, 2);
    SetLength(Buffer, 20);
    SetLength(RespProg, 12);

    AddressToChar(DeviceID, No);
    Buffer[0] := $4C;
    Buffer[1] := No[0];
    Buffer[2] := No[1];
    Buffer[3] := Parameter;
    Buffer[4] := $23;
    if Dec = 255 then
      Result := DoubleToWestAuto(Buffer[5], Value)
    else
      Result := DoubleToWestManual(Buffer[5], Value, Dec);

    if Result <> ioOk then Exit;

    Buffer[10] := $2A;

    RespProg[0] := $4C;
    RespProg[1] := No[0];
    RespProg[2] := No[1];
    RespProg[3] := Parameter;
    if Dec = 255 then
      Result := DoubleToWestAuto(RespProg[4], Value)
    else
      Result := DoubleToWestManual(RespProg[4], Value, Dec);

    if Result <> ioOk then Exit;

    RespProg[9] := $49;
    RespProg[10] := $2A;

    if PCommPort = nil then
    begin
      Result := ioNullDriver;
      Exit;
    end;

    PCommPort.IOCommandSync(iocWriteRead, 11, Buffer, 11, DriverID, 10, @Pkg);

    Result := IOResultToProtocolResult(Pkg.WriteIOResult);
    if Result <> ioOk then Exit;
    Result := IOResultToProtocolResult(Pkg.ReadIOResult);
    if Result <> ioOk then Exit;

    for i := 0 to 10 do
      Flag := Flag and (RespProg[i] = Pkg.BufferToRead[i]);

    if (not Flag) then
    begin
      Result := ioCommError;
      Exit;
    end;

    SetLength(Buffer, 0);
    SetLength(Buffer, 12);

    SetLength(Pkg.BufferToRead, 0);
    SetLength(Pkg.BufferToWrite, 0);

    Buffer[0] := $4C;
    Buffer[1] := No[0];
    Buffer[2] := No[1];
    Buffer[3] := Parameter;
    Buffer[4] := $49;
    Buffer[5] := $2A;

    PCommPort.IOCommandSync(iocWriteRead, 6, Buffer, 11, DriverID, 10, @Pkg);

    Result := IOResultToProtocolResult(Pkg.WriteIOResult);
    if Result <> ioOk then Exit;
    Result := IOResultToProtocolResult(Pkg.ReadIOResult);
    if Result <> ioOk then
      Exit;

    if ((Pkg.BufferToRead[8] = $4E) or (Pkg.BufferToRead[9] = $4E)) then
    begin
      Result := ioIllegalFunction;
      Exit;
    end;
    Result := ioOk;
  finally
    SetLength(Pkg.BufferToRead, 0);
    SetLength(Pkg.BufferToWrite, 0);
    SetLength(No, 0);
    SetLength(Buffer, 0);
    SetLength(RespProg, 0);
  end;
end;

function TWestASCIIDriver.ScanTable(DeviceID: TWestAddressRange; var ScanTableValues: TScanTable): TProtocolIOResult;
var
  Buffer: Bytes;
  No: Bytes;
  b1: Boolean;
  b2: Boolean;
  Pkg: TIOPacket;
  OffsetSpace: Longint;
  OffsetNo: Longint;
  OffsetSize: Longint;
  Res: Longint;
begin
  try
    SetLength(Buffer, 35);
    SetLength(No, 2);

    AddressToChar(DeviceID, No);

    Buffer[0] := $4C;
    Buffer[1] := No[0];
    Buffer[2] := No[1];
    Buffer[3] := $5D;
    Buffer[4] := $3F;
    Buffer[5] := $2A;

    if PCommPort = nil then
    begin
      Result := ioNullDriver;
      Exit;
    end;

    PCommPort.Lock(DriverID);

    if PCommPort.IOCommandSync(iocWriteRead, 6, Buffer, 6, DriverID, 10, @Pkg) = 0 then
    begin
      Result := ioDriverError;
      Exit;
    end;

    if [csDestroying] * ComponentState <> [] then
    begin
      Result := ioDriverError;
      Exit;
    end;

    Result := IOResultToProtocolResult(Pkg.WriteIOResult);
    if Result <> ioOk then Exit;
    Result := IOResultToProtocolResult(Pkg.ReadIOResult);
    if Result <> ioOk then Exit;

    Buffer := Pkg.BufferToRead;

    b2 := (Buffer[0] = $4C) and (Buffer[1] = No[0]) and (Buffer[2] = No[1]) and (Buffer[3] = $5D) and (Buffer[4] = $32);
    b1 := (Buffer[0] = $4C) and (Buffer[1] = No[1]) and (Buffer[2] = $5D) and (Buffer[3] = $32);

    if (b1 = False) and (b2 = False) then
    begin
      Result := ioCommError;
      Exit;
    end;

    // if the response has two Bytes to device addres, increments the offset of the array
    OffsetNo := 0;
    if b2 then
      OffsetNo := 1;

    case Chr(Buffer[4 + OffsetNo]) of
      '0':  begin
              Res := PCommPort.IOCommandSync(iocRead, 0, nil, 21 + OffsetNo, DriverID, 10, @Pkg);
              OffsetSize := 0;
            end;
      '5':  begin
              Res := PCommPort.IOCommandSync(iocRead, 0, nil, 26 + OffsetNo, DriverID, 10, @Pkg);
              OffsetSize := 5;
            end;
      else
        begin
          Result := ioCommError;
          Exit;
        end;
    end;

    if Res = 0 then
    begin
      Result := ioDriverError;
      Exit;
    end;

    if [csDestroying] * ComponentState <> [] then
    begin
      Result := ioDriverError;
      Exit;
    end;

    PCommPort.Unlock(DriverID);

    Result := IOResultToProtocolResult(Pkg.ReadIOResult);
    if Result <> ioOk then Exit;

    if b2 and (Pkg.BufferToRead[0] = $20) then
      OffsetSpace := 1
    else
      OffsetSpace := 0;

    Buffer := Pkg.BufferToRead;

    if ((Buffer[20 + OffsetSize + OffsetSpace] <> $41) or (Buffer[21 + OffsetSize + OffsetSpace] <> $2A)) then
    begin
      Result := ioCommError;
      Exit;
    end;

    Result := WestToDouble(Buffer[0 + OffsetSpace], ScanTableValues.SP.Value, ScanTableValues.SP.Decimal);
    if (Result = ioCommError) then
      Exit;
    ScanTableValues.SP.Timestamp := CrossNow;
    ScanTableValues.SP.IOResult := Result;

    Result := WestToDouble(Buffer[5 + OffsetSpace], ScanTableValues.PV.Value, ScanTableValues.PV.Decimal);
    if (Result = ioCommError) then
      Exit;
    ScanTableValues.PV.Timestamp := CrossNow;
    ScanTableValues.PV.IOResult := Result;

    Result := WestToDouble(Buffer[10 + OffsetSpace], ScanTableValues.Out1.Value, ScanTableValues.Out1.Decimal);
    if (Result = ioCommError) then
      Exit;
    ScanTableValues.Out1.Timestamp := CrossNow;
    ScanTableValues.Out1.IOResult := Result;

    if OffsetSize = 0 then
      begin
        Result := WestToDouble(Buffer[15 + OffsetSpace], ScanTableValues.Status.Value, ScanTableValues.Status.Decimal);
        if (Result = ioCommError) then
          Exit;
        ScanTableValues.Status.Timestamp := CrossNow;
        ScanTableValues.Status.IOResult := Result;
      end
    else
      begin
        Result := WestToDouble(Buffer[15 + OffsetSpace], ScanTableValues.Out2.Value, ScanTableValues.Out2.Decimal);
        if (Result = ioCommError) then
          Exit;
        ScanTableValues.Out2.Timestamp := CrossNow;
        ScanTableValues.Out2.IOResult := Result;

        Result := WestToDouble(Buffer[20 + OffsetNo + OffsetSpace], ScanTableValues.Status.Value, ScanTableValues.Status.Decimal);
        if (Result = ioCommError) then
          Exit;
        ScanTableValues.Status.Timestamp := CrossNow;
        ScanTableValues.Status.IOResult := Result;
      end;
    Result := ioOk;
  finally
    if PCommPort <> nil then
      if PCommPort.LockedBy = DriverID then
        PCommPort.Unlock(DriverID);
  end;
end;

procedure TWestASCIIDriver.MinScanTimeOfReg(var WestReg: TWestRegister);
var
  Srate: Longint;
begin
  if Length(WestReg.ScanTimes) > 0 then
  begin
    WestReg.MinScanTime := WestReg.ScanTimes[0].ScanTime;
    for Srate := 1 to High(WestReg.ScanTimes) do
      WestReg.MinScanTime := Min(WestReg.MinScanTime, WestReg.ScanTimes[Srate].ScanTime);
  end;
end;

function TWestASCIIDriver.IOResultToProtocolResult(IORes: TIOResult): TProtocolIOResult;
begin
  case IORes of
    iorTimeOut: Result := ioTimeOut;
    iorOK:      Result := ioOk;
    else
      Result := ioDriverError;
  end;
end;

procedure TWestASCIIDriver.AssignScanTableToReg(const StableReg: TScanTableReg; var WestReg: TWestRegister);
begin
  if StableReg.IOResult = ioOk then
  begin
    WestReg.Value := StableReg.Value;
    WestReg.Timestamp := StableReg.Timestamp;
    WestReg.Decimal := StableReg.Decimal;
  end;
  WestReg.LastReadResult := StableReg.IOResult;
end;

function TWestASCIIDriver.SizeOfTag(aTag: TTag; isWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte;
begin
  // all west registers are float 32 bits sized
  Result := 32;
end;


var
  WestTagBuilderEditor: TOpenTagEditor = nil;

procedure TWestASCIIDriver.OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  if Assigned(WestTagBuilderEditor) then
    WestTagBuilderEditor(Self, Self.Owner, InsertHook, CreateProc)
  else
    inherited;
end;

function TWestASCIIDriver.HasTabBuilderEditor: Boolean;
begin
  Result := True;
end;

procedure SetTagBuilderToolForWest6100Protocol(TagBuilderTool: TOpenTagEditor);
begin
  if Assigned(WestTagBuilderEditor) then
    raise Exception.Create('A Tag Builder editor for West 6100 protocol was already Assigned.')
  else
    WestTagBuilderEditor := TagBuilderTool;
end;


initialization
  // creates a list of valid parameters

  // SetPoint
  ParameterList[$00].ParameterID := $53;
  ParameterList[$00].FunctionAllowed := 0;
  ParameterList[$00].ReadOnly := False;
  ParameterList[$00].Decimal := 255;

  // PV
  ParameterList[$01].ParameterID := $4D;   // Parameter ID
  ParameterList[$01].FunctionAllowed := 2; // Function that can use this register, 0 = all functions
  ParameterList[$01].ReadOnly := True;     // ReadOnly 1 := yes?
  ParameterList[$01].Decimal := 255;       // Number of decimal places of the parameter

  // Power Output value
  ParameterList[$02].ParameterID := $57;
  ParameterList[$02].FunctionAllowed := 0;
  ParameterList[$02].ReadOnly := False;
  ParameterList[$02].Decimal := 255;

  // Controller status
  ParameterList[$03].ParameterID := $4C;
  ParameterList[$03].FunctionAllowed := 2;
  ParameterList[$03].ReadOnly := True;
  ParameterList[$03].Decimal := 0;

  // Scale Range Max
  ParameterList[$04].ParameterID := $47;
  ParameterList[$04].FunctionAllowed := 0;
  ParameterList[$04].ReadOnly := False;
  ParameterList[$04].Decimal := 255;

  // Scale Range Min
  ParameterList[$05].ParameterID := $48;
  ParameterList[$05].FunctionAllowed := 0;
  ParameterList[$05].ReadOnly := False;
  ParameterList[$05].Decimal := 255;

  // Scale Range Dec. Point
  ParameterList[$06].ParameterID := $51;
  ParameterList[$06].FunctionAllowed := 0;
  ParameterList[$06].ReadOnly := False;
  ParameterList[$06].Decimal := 0;

  // Input filter time constant
  ParameterList[$07].ParameterID := $6D;
  ParameterList[$07].FunctionAllowed := 0;
  ParameterList[$07].ReadOnly := False;
  ParameterList[$07].Decimal := 255;

  // Output 1 Power Limit
  ParameterList[$08].ParameterID := $42;
  ParameterList[$08].FunctionAllowed := 0;
  ParameterList[$08].ReadOnly := False;
  ParameterList[$08].Decimal := 255;

  // Output 1 cycle time
  ParameterList[$09].ParameterID := $4E;
  ParameterList[$09].FunctionAllowed := 0;
  ParameterList[$09].ReadOnly := False;
  ParameterList[$09].Decimal := 1;

  // Output 2 cycle time
  ParameterList[$0a].ParameterID := $4F;
  ParameterList[$0a].FunctionAllowed := 0;
  ParameterList[$0a].ReadOnly := False;
  ParameterList[$0a].Decimal := 1;

  // Recorder output scale max
  ParameterList[$0b].ParameterID := $5B;
  ParameterList[$0b].FunctionAllowed := 0;
  ParameterList[$0b].ReadOnly := False;
  ParameterList[$0b].Decimal := 255;

  // Recorder output scale min
  ParameterList[$0c].ParameterID := $5C;
  ParameterList[$0c].FunctionAllowed := 0;
  ParameterList[$0c].ReadOnly := False;
  ParameterList[$0c].Decimal := 255;

  // SetPoint ramp rate
  ParameterList[$0d].ParameterID := $5E;
  ParameterList[$0d].FunctionAllowed := 0;
  ParameterList[$0d].ReadOnly := False;
  ParameterList[$0d].Decimal := 255;

  // Setpoint high limit
  ParameterList[$0e].ParameterID := $41;
  ParameterList[$0e].FunctionAllowed := 0;
  ParameterList[$0e].ReadOnly := False;
  ParameterList[$0e].Decimal := 255;

  // Setpoint low limit
  ParameterList[$0f].ParameterID := $54;
  ParameterList[$0f].FunctionAllowed := 0;
  ParameterList[$0f].ReadOnly := False;
  ParameterList[$0f].Decimal := 255;

  // alarm 1 value
  ParameterList[$10].ParameterID := $43;
  ParameterList[$10].FunctionAllowed := 0;
  ParameterList[$10].ReadOnly := False;
  ParameterList[$10].Decimal := 255;

  // alarm 2 value
  ParameterList[$11].ParameterID := $45;
  ParameterList[$11].FunctionAllowed := 0;
  ParameterList[$11].ReadOnly := False;
  ParameterList[$11].Decimal := 255;

  // Rate (Derivative time constant)
  ParameterList[$12].ParameterID := $44;
  ParameterList[$12].FunctionAllowed := 0;
  ParameterList[$12].ReadOnly := False;
  ParameterList[$12].Decimal := 2;

  // Reset (Integral time constant)
  ParameterList[$13].ParameterID := $49;
  ParameterList[$13].FunctionAllowed := 0;
  ParameterList[$13].ReadOnly := False;
  ParameterList[$13].Decimal := 2;

  // Manual time reset (BIAS)
  ParameterList[$14].ParameterID := $4A;
  ParameterList[$14].FunctionAllowed := 0;
  ParameterList[$14].ReadOnly := False;
  ParameterList[$14].Decimal := 255;

  // ON/OFF diferential
  ParameterList[$15].ParameterID := $46;
  ParameterList[$15].FunctionAllowed := 0;
  ParameterList[$15].ReadOnly := False;
  ParameterList[$15].Decimal := 1;

  // Overlap/Deadband
  ParameterList[$16].ParameterID := $4B;
  ParameterList[$16].FunctionAllowed := 0;
  ParameterList[$16].ReadOnly := False;
  ParameterList[$16].Decimal := 0;

  // Proportional band 1 value
  ParameterList[$17].ParameterID := $50;
  ParameterList[$17].FunctionAllowed := 0;
  ParameterList[$17].ReadOnly := False;
  ParameterList[$17].Decimal := 1;

  // Proportional band 2 value
  ParameterList[$18].ParameterID := $55;
  ParameterList[$18].FunctionAllowed := 0;
  ParameterList[$18].ReadOnly := False;
  ParameterList[$18].Decimal := 1;

  // PV Offset
  ParameterList[$19].ParameterID := $76;
  ParameterList[$19].FunctionAllowed := 0;
  ParameterList[$19].ReadOnly := False;
  ParameterList[$19].Decimal := 255;

  // Arithmetic deviation
  ParameterList[$1a].ParameterID := $56;
  ParameterList[$1a].FunctionAllowed := 2;
  ParameterList[$1a].ReadOnly := True;
  ParameterList[$1a].Decimal := 255;

  // Arithmetic deviation
  ParameterList[$1b].ParameterID := $5A;
  ParameterList[$1b].FunctionAllowed := 3;
  ParameterList[$1b].ReadOnly := False;
  ParameterList[$1b].Decimal := 0;


end.

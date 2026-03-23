{$i ../common/language.inc}
{:
  @abstract(Set of class to handle blocks of memory of an PLC.)
  @author(Fabio Luis Girardi fabio@pascalscada.com)
}
unit PLCMemoryManager;

interface

uses
  SysUtils, DateUtils, Tag, SyncObjs, Classes;

type

  {: @author(Fabio Luis Girardi fabio@pascalscada.com)
     Record used to handle a unique address inside the memory blocks manager. }
  TMemoryRec = record
    Address: Longint;
    Count: Longint;
    MinScan: Longint;
  end;

  {: @author(Fabio Luis Girardi fabio@pascalscada.com)
  Continuous memory block class.

  @bold(Attention: If are you developing a protocol driver, use the class
  TPLCMemoryManager, that implements the non-continuous memory blocks. This class
  uses @name and all their descendents.)

  @seealso(TPLCMemoryManager) }
  TRegisterRange = class
  private
    FStartAddress: Longint;
    FEndAddress: Longint;
    FLastUpdate: TDateTime;
    FMinScanTime: Cardinal;
    FReadOK: Cardinal;
    FReadFault: Cardinal;
    procedure SetReadOK(Value: Cardinal);
    procedure SetReadFault(Value: Cardinal);
    function GetSize: Longint;
    function GetMsecLastUpdate: Int64;
  protected
    //: @exclude
    function GetValue(Index: Longint): Double;
    //: @exclude
    procedure SetValue(Index: Longint; v: Double);
  public
    {$IFDEF PORTUGUES}
    //: Array that stores the block values.
    {$ELSE}
    //: Array that stores the values of the memory block
    {$ENDIF}
    FValues: TArrayOfDouble;
    //: Stores the last error that occurred with the block
    LastError: TProtocolIOResult;
    {:
    Creates a continuous memory block
    @param(AdrStart Cardinal. Start address of the block.)
    @param(AdrEnd Cardinal. Final address of the block.)

    AdrStart and AdrEnd must be passed in the memory unit of the smaller word
    available on your PLC. A example is the Siemens PLC's, that can use on the
    same memory area, bytes, Words e DWORDs. So to add the MD0, you must pass 0
    to AdrStart and 3 to AdrEnd, totalizing 4 bytes (which is the less word size
    on this PLC) which are the MB0, MB1, MB2, MB3, forming the MD0. }
    constructor Create(AdrStart, AdrEnd: Cardinal);
    destructor Destroy; override;

    //: Reads/writes a value at the specified index of the memory block.
    property Values[index: Longint]: Double read GetValue write SetValue;
    {: @name updates the timestamp of the block values. Call this method after read
       values of your device. }
    procedure Updated;
    {: @name tells if the memory block must be read from the device, because the
    scan time elapses (Now - time from the last update > smaller scan time of
    the block). }
    function NeedRefresh: Boolean;
  published
    //: Start address of the memory block.
    property AddressStart: Longint read FStartAddress;
    //: Final address of the memory block.
    property AddressEnd: Longint read FEndAddress;
    //: Tells the size of the block.
    property Size: Longint read GetSize;
    //: @name tells the timestamp of the last update.
    property LastUpdate: TDateTime read FLastUpdate write FLastUpdate;
    //: @name tells how many milliseconds are elapsed from the last update.
    property MilisecondsFromLastUpdate: Int64 read GetMsecLastUpdate;
    //: Tells the smaller scan time of the memory block.
    property ScanTime: Cardinal read FMinScanTime write FMinScanTime;
    //: Tells how many reads was successful.
    property ReadSuccess: Cardinal read FReadOK write SetReadOK;
    //: Tells how many reads was not successful.
    property ReadFaults: Cardinal read FReadFault write SetReadFault;
  end;

  //: Array of continuous memory blocks.
  TRegisterRangeArray = array of TRegisterRange;

  {: @author(Fabio Luis Girardi fabio@pascalscada.com)
  @abstract(Class that handles non-continuous memory blocks (fragmented)
            and the better organization of it.)  }
  TPLCMemoryManager = class
  private
    FAddress: array of TMemoryRec;
    FMaxHole: Longint;
    FMaxBlockSize: Longint;
    // binary search of memory address
    function FindAddress(const Address: Longint; var idx: Longint): Boolean;
    // segmented binary search of memory address
    function FindAddresBySegment(const Address, StartIndex, EndIndex: Longint; var idx: Longint): Boolean;
    procedure AddAddress(Add, Scan: Longint); overload;
    function GetMinScanTime: Cardinal;
    procedure RemoveAddress(Add: Longint); overload;
    procedure SetHoleSize(Size: Longint);
    procedure SetBlockSize(Size: Longint);
    // rebuild the blocks
    procedure RebuildBlocks;
    // returns the size of all block fragments.
    function GetSize: Longint;
    function CreateRegisterRange(AdrStart, AdrEnd: Longint): TRegisterRange;
  public
    //: Continous memory blocks.
    Blocks: TRegisterRangeArray;
    //: Creates the handler of non continuous memory block.
    constructor Create; virtual;
    //: Destroys the handler of non continuous memory block.
    destructor Destroy; override;

    {: Adds one or more memory into the manager.
    @param(Address Cardinal. Initial address of memory range.)
    @param(Size Cardinal. How many memories will be managed by the manager.)
    @param(RegSize Cardinal. Word size of your variable compared with the smaller word of your device.)
    @param(Scan Cardinal. Scan time of your variables)

    For example, to add the MW0, MW2 and MW4 of a Siemens PLC (the smaller word
    is the byte) with 1200ms of scan into the manager, you must call:
    @code(AddAddress(0,3,2,1200);)

    However, on a Schneider PLC (the smaller word has 16 bits), to add the address
    W0, W1 and W2, you must call:
    @code(AddAddress(0,3,1,1200);)

    @seealso(RemoveAddress)
    @seealso(SetValues)
    @seealso(GetValues) }
    procedure AddAddress(Address, Size, RegSize, Scan: Cardinal); overload; virtual;
    {: Removes one or more variables from the manager.
    @param(Address Cardinal. Initial address of memory range.)
    @param(Size Cardinal. How many memories will be removed from the manager.)
    @param(RegSize Cardinal. Word size of your variable compared with the smaller word of your device.)

    These parameters works like the of function AddAddress.

    @seealso(AddAddress)
    @seealso(SetValues)
    @seealso(GetValues) }
    procedure RemoveAddress(Address, Size, RegSize: Cardinal); overload; virtual;
    {: @name stores values in a range of memories, continuous or non continuous.
    @param(Address Cardinal. Initial address of memory range.)
    @param(Len Cardinal. How many memory will be stored on the manager.)
    @param(RegSize Cardinal. Word size of your variable compared with the smaller word of your device.)
    @param(Values TArrayOfDouble. Values that will be stored in the memory manager.)
    @param(LastResult TProtocolIOResult. Last I/O result of the values being stored.)

    One value on Values array represents the value of the smaller word of your device.

    For example: if you are storing the value of MW0 (word) of an Siemens PLC,
    you must call:

    @code(SetValues(0,1,2,[vb0_value,vb1_value]);)

    Because on Siemens PLC's the smaller word size is the byte, so, one word are two bytes.

    But, on a Schneider PLC, you must call:

    @code(SetValues(0,1,1,[valor_VW0]);)

    Because on this PLC, the smaller word size is the Word (16bits).

    @seealso(AddAddress)
    @seealso(RemoveAddress)
    @seealso(GetValues)    }
    function SetValues(AdrStart, Len, RegSize: Cardinal; Values: TArrayOfDouble; LastResult: TProtocolIOResult): Longint; virtual;
    {: @name gets the values stored in memory manager, continuous or non-continuous.
    @param(Address Cardinal. Initial address of memory range.)
    @param(Len Cardinal. How many memories will got from the manager.)
    @param(RegSize Cardinal. Word size of your variable compared with the smaller word of your device.)
    @param(Values TArrayOfDouble. Array that will return the values that are stored in the memory manager.)
    @param(LastResult TProtocolIOResult. Last I/O result of the memory range.)
    @param(ValueTimeStamp TDateTime. Date time of the last update of the values on the memory manager.)

    One value on Values array represents the value of the smaller word of your device.

    @seealso(AddAddress)
    @seealso(RemoveAddress)
    @seealso(SetValues)
    @seealso(GetValues)     }
    function GetValues(AdrStart, Len, RegSize: Cardinal; var Values: TArrayOfDouble; var LastResult: TProtocolIOResult; var ValueTimeStamp: TDateTime): Longint; virtual;
    {: @name updates the last I/O result of a range of memories on manager.

    @param(Address Cardinal. Initial address of memory range.)
    @param(Len Cardinal. How many memories will be updated on the manager.)
    @param(RegSize Cardinal. Word size of your variable compared with the smaller word of your device.)
    @param(Fault TProtocolIOResult. Last I/O result of the memory range.)

    @seealso(SetValues)    }
    procedure SetFault(AdrStart, Len, RegSize: Cardinal; Fault: TProtocolIOResult; const MarkAsUpdated: Boolean = False); virtual;
  published
    {: Tells how many memory address can be missing without break the block on
    two or more smaller blocks.

    For example, if are added the memory address [0, 1] and [3, 4] into the
    Manager with MaxHole=0, will be built two blocks, the first with the address
    [0, 1] and the second block with the address [3, 4].

    However, if the MaxHole is set to 1, will be built only one block with the
    address [0,1,2,3,4]. Will be included the address 2, to avoid the break the
    block on two pieces. }
    property MaxHole: Longint read FMaxHole write SetHoleSize;
    {: Tells the max size of the blocks. If has no limit, set @name to 0.

    For example, if are added the memory address [0,1,2,3,4] and  @name=0 will
    be created only one block with these address. However if @name=3, will be
    created two blocks, the first with the address [0,1,2] and the second with
    the address [3,4]. }
    property MaxBlockItems: Longint read FMaxBlockSize write SetBlockSize;
    //: How many memories are handled by the manager.
    property Size: Longint read GetSize;

    property MinScanTime: Cardinal read GetMinScanTime;
  end;

  TPLCMemoryManagerSafe = class(TPLCMemoryManager)
  private
    FMutex: TCriticalSection;
  public
    //: @seealso(TPLCMemoryManager.Create)
    constructor Create; override;
    //: @seealso(TPLCMemoryManager.Destroy)
    destructor Destroy; override;
    //: @seealso(TPLCMemoryManager.AddAddress)
    procedure AddAddress(Address, ASize, RegSize, Scan: Cardinal); override;
    //: @seealso(TPLCMemoryManager.RemoveAddress)
    procedure RemoveAddress(Address, ASize, RegSize: Cardinal); override;
    //: @seealso(TPLCMemoryManager.SetValues)
    function SetValues(AdrStart, Len, RegSize: Cardinal; Values: TArrayOfDouble; LastResult: TProtocolIOResult): Longint; override;
    //: @seealso(TPLCMemoryManager.GetValues)
    function GetValues(AdrStart, Len, RegSize: Cardinal; var Values: TArrayOfDouble; var LastResult: TProtocolIOResult; var ValueTimeStamp: TDateTime): Longint; override;
    //: @seealso(TPLCMemoryManager.SetFault)
    procedure SetFault(AdrStart, Len, RegSize: Cardinal; Fault: TProtocolIOResult; const MarkAsUpdated: Boolean = False); override;
  end;


implementation


uses
  Math, hsstrings, crossdatetime;


constructor TRegisterRange.Create(AdrStart, AdrEnd: Cardinal);
begin
  inherited Create;
  FStartAddress := AdrStart;
  FEndAddress := AdrEnd;
  FReadOK := 0;
  FReadFault := 0;
  SetLength(FValues, (AdrEnd - AdrStart) + 1);
end;

destructor TRegisterRange.Destroy;
begin
  SetLength(FValues, 0);
  inherited Destroy;
end;

procedure TRegisterRange.Updated;
begin
  FLastUpdate := CrossNow;
end;

function TRegisterRange.GetValue(Index: Longint): Double;
begin
  Result := FValues[Index];
end;

procedure TRegisterRange.SetValue(Index: Longint; v: Double);
begin
  FValues[Index] := v;
end;

function TRegisterRange.GetSize: Longint;
begin
  Result := (FEndAddress - FStartAddress) + 1;
end;

function TRegisterRange.GetMsecLastUpdate: Int64;
begin
  Result := MilliSecondsBetween(CrossNow, FLastUpdate);
end;

function TRegisterRange.NeedRefresh: Boolean;
var
  Aux: Int64;
begin
  Aux := FMinScanTime;
  Result := GetMsecLastUpdate >= Aux;
end;

procedure TRegisterRange.SetReadOK(Value: Cardinal);
begin
  FReadOK := Max(FReadOK, Value);
end;

procedure TRegisterRange.SetReadFault(Value: Cardinal);
begin
  FReadFault := Max(FReadFault, Value);
end;

////////////////////////////////////////////////////////////////////////////////
// implementation of TPLCMemoryManager
////////////////////////////////////////////////////////////////////////////////

constructor TPLCMemoryManager.Create;
begin
  //the block stay continuous if the number of missing address is <=5
  FMaxHole := 5;
  //size limits of the built blocks, 0 = no size limit.
  FMaxBlockSize := 0;
end;

destructor TPLCMemoryManager.Destroy;
var
  i: Longint;
begin
  for i := 0 to High(Blocks) do
    Blocks[i].Destroy;
  SetLength(FAddress, 0);
  SetLength(Blocks, 0);
end;

function TPLCMemoryManager.FindAddress(const Address: Longint; var idx: Longint): Boolean;
begin
  if Length(FAddress) = 0 then
    Result := False
  else
    Result := FindAddresBySegment(Address, 0, High(FAddress), idx);
end;

function TPLCMemoryManager.FindAddresBySegment(const Address, StartIndex, EndIndex: Longint; var idx: Longint): Boolean;
var
  Len: Longint;
  Middle: Longint;
begin
  Len := EndIndex - StartIndex + 1;

  if Len = 1 then
  begin
    if FAddress[StartIndex].Address = Address then
    begin
      Result := True;
      idx := StartIndex;
    end
    else
      Result := False;
  end
  else
  begin
    Middle := (Len div 2) + StartIndex;
    if Address < FAddress[Middle].Address then
      Result := FindAddresBySegment(Address, StartIndex, Middle - 1, idx)
    else
      Result := FindAddresBySegment(Address, Middle, EndIndex, idx);
  end;
end;

procedure TPLCMemoryManager.AddAddress(Add, Scan: Longint);
var
  c, h: Longint;
begin
  if Length(FAddress) = 0 then
  begin
    SetLength(FAddress, 1);
    FAddress[0].Address := Add;
    FAddress[0].Count := 1;
    FAddress[0].MinScan := Scan;
    Exit;
  end;
  if Length(FAddress) = 1 then
  begin
    if FAddress[0].Address = Add then
    begin
      Inc(FAddress[0].Count);
      FAddress[0].MinScan := Min(FAddress[0].MinScan, Scan);
      Exit;
    end
    else
    begin
      SetLength(FAddress, 2);
      if FAddress[0].Address < Add then
      begin
        FAddress[1].Address := Add;
        FAddress[1].Count := 1;
        FAddress[1].MinScan := Scan;
      end
      else
      begin
        FAddress[1].Address := FAddress[0].Address;
        FAddress[1].Count := FAddress[0].Count;
        FAddress[1].MinScan := FAddress[0].MinScan;
        FAddress[0].Address := Add;
        FAddress[0].Count := 1;
        FAddress[0].MinScan := Scan;
      end;
    end;
    Exit;
  end;

  //procura e adiciona no lugar correto...
  //search and adds on right place.
  if Length(FAddress) >= 2 then
  begin
    c := 0;
    //procura...
    //search
    if not FindAddress(Add, c) then
    begin
      c := 0;
      //if the address has not found using the binary search, try the normal
      //search to seek the nearest array index to insert the new address.
      while (c < Length(FAddress)) and (Add > FAddress[c].Address) do
        Inc(c);
    end;

    if (c < Length(FAddress)) and (FAddress[c].Address = Add) then
    begin
      //se encontrou o endereco...
      //if found the address...
      Inc(FAddress[c].Count);
      FAddress[c].MinScan := Min(FAddress[c].MinScan, Scan);
    end
    else
    begin
      h := Length(FAddress);
      //adiciona mais um na array
      //adds the address
      SetLength(FAddress, h + 1);
      //se se não chegou no fim, é pq é um endereco
      //que deve ficar no meio da lista para mante-la
      //ordenada

      //if isn't the end of the array, is because the address must be on the middle
      //of array to keep it ordered
      if c < High(FAddress) then
        Move(FAddress[c], FAddress[c + 1], (High(FAddress) - c) * SizeOf(TMemoryRec));

      FAddress[c].Address := Add;
      FAddress[c].Count := 1;
      FAddress[c].MinScan := Scan;
    end;
  end;
end;

function TPLCMemoryManager.GetMinScanTime: Cardinal;
var
  i: Integer;
begin
  Result := $7FFFFFFF;

  for i := 0 to High(Blocks) do
    Result := Min(Result, Blocks[i].ScanTime);
end;

procedure TPLCMemoryManager.RemoveAddress(Add: Longint);
var
  i: Longint;
begin
  i := 0;
  //se não encontrou cai fora...
  //if not found the addres, Exit.
  if not FindAddress(Add, i) then
    Exit;

  Dec(FAddress[i].Count);
  //caso zerou um endereco, é necessário remover ele da lista...
  //if the address isn't referenced anymore, remove it from the address list.
  if FAddress[i].Count = 0 then
    if Length(FAddress) = 1 then
    begin
      SetLength(FAddress, 0);
    end
    else
    begin
      if i < High(FAddress) then
        Move(FAddress[i + 1], FAddress[i], (High(FAddress) - i) * SizeOf(TMemoryRec));
      SetLength(FAddress, Length(FAddress) - 1);
    end;
end;

procedure TPLCMemoryManager.SetHoleSize(Size: Longint);
begin
  if Size = FMaxHole then Exit;
  FMaxHole := Size;
  RebuildBlocks;
end;

procedure TPLCMemoryManager.SetBlockSize(Size: Longint);
begin
  if Size = FMaxBlockSize then Exit;
  FMaxBlockSize := Size;
  RebuildBlocks; //rebuild the blocks.
end;

procedure TPLCMemoryManager.RebuildBlocks;
var
  i: Longint;
  j: Longint;
  k: Longint;
  NewBlocks: TRegisterRangeArray;
  AdrStart: Longint;
  AdrEnd: Longint;
  BlockItems: Longint;
  BlockEnd: Longint;
  MScan: Longint;
  BlockOldOffset: Longint;
  BlockNewOffset: Longint;
  BlockIndex: Longint;
  Found: Boolean;
begin
  SetLength(NewBlocks, 0);
  AdrEnd := 0;
  AdrStart := 0;
  BlockItems := 0;
  BlockEnd := 0;
  MScan := 0;
  BlockIndex := 0;
  // rebuild the memory blocks
  for i := 0 to High(FAddress) do
  begin
    if i = 0 then
    begin
      AdrStart := FAddress[0].Address;
      AdrEnd := AdrStart;
      BlockEnd := AdrEnd + FMaxHole + 1;
      MScan := FAddress[0].MinScan;
      BlockItems := 1;
      if i < High(FAddress) then Continue;
    end;

    if (FAddress[i].Address > BlockEnd) or ((FMaxBlockSize <> 0) and (BlockItems >= FMaxBlockSize)) then
    begin
      // the block can't be extended, starts another
      SetLength(NewBlocks, Length(NewBlocks) + 1);

      NewBlocks[BlockIndex] := CreateRegisterRange(AdrStart, AdrEnd);
      NewBlocks[BlockIndex].LastUpdate := CrossNow;
      NewBlocks[BlockIndex].ScanTime := MScan;
      Inc(BlockIndex);

      // get the address of the new block
      AdrStart := FAddress[i].Address;
      AdrEnd := AdrStart;
      BlockEnd := AdrEnd + FMaxHole + 1;
      MScan := FAddress[i].MinScan;
      BlockItems := 1;
    end
    else
    begin
      // the block can be extended, add the new address
      AdrEnd := FAddress[i].Address;
      BlockEnd := AdrEnd + FMaxHole + 1;
      MScan := Min(MScan, FAddress[i].MinScan);
      Inc(BlockItems);
    end;
    if i = High(FAddress) then
    begin
      SetLength(NewBlocks, Length(NewBlocks) + 1);
      NewBlocks[BlockIndex] := CreateRegisterRange(AdrStart, AdrEnd);
      NewBlocks[BlockIndex].LastUpdate := CrossNow;
      NewBlocks[BlockIndex].ScanTime := MScan;
      Inc(BlockIndex);
    end;
  end;

  // copy the data of the oldest blocks to the new blocks

  for i := 0 to High(FAddress) do
  begin
    Found := False;
    for j := 0 to High(Blocks) do
      if    (FAddress[i].Address >= Blocks[j].AddressStart)
        and (FAddress[i].Address <= Blocks[j].AddressEnd) then
      begin
        Found := True;
        Break;
      end;

    // if not Found the address here, it was added
    if not Found then Continue;

    Found := False;
    for k := 0 to High(NewBlocks) do
      if (FAddress[i].Address >= NewBlocks[k].AddressStart) and (FAddress[i].Address <= NewBlocks[k].AddressEnd) then
      begin
        Found := True;
        Break;
      end;

    // if not Found the address here, it was removed
    if not Found then Continue;
    BlockOldOffset := FAddress[i].Address - Blocks[j].AddressStart;
    BlockNewOffset := FAddress[i].Address - NewBlocks[k].AddressStart;
    NewBlocks[k].Values[BlockNewOffset] := Blocks[j].Values[BlockOldOffset];

    // set the the block with the small timestamp
    NewBlocks[k].LastUpdate := Min(NewBlocks[k].LastUpdate, Blocks[j].LastUpdate);
  end;
  // remove the old blocks
  for i := 0 to High(Blocks) do
    Blocks[i].Destroy;
  SetLength(Blocks, 0);

  // copy the values from the new block to the old block
  Blocks := NewBlocks;

  // releases the memory
  SetLength(NewBlocks, 0);
end;

function TPLCMemoryManager.GetSize: Longint;
var
  i: Longint;
begin
  Result := 0;
  for i := 0 to High(Blocks) do
    Result := Result + Blocks[i].Size;
end;

function TPLCMemoryManager.CreateRegisterRange(AdrStart, AdrEnd: Longint): TRegisterRange;
begin
  Result := TRegisterRange.Create(AdrStart, AdrEnd);
end;

procedure TPLCMemoryManager.AddAddress(Address, Size, RegSize, Scan: Cardinal);
var
  i: Cardinal;
  Items: Cardinal;
  Len: Longint;
begin
  if (Size <= 0) or (RegSize <= 0) then
    raise Exception.Create(SsizeMustBeAtLeastOne);

  // gets the size of address Array
  Len := Length(FAddress);

  i := Address;
  Items := Size * RegSize + Address;
  while i < Items do
  begin
    AddAddress(i, Scan);
    Inc(i);
  end;

  // rebuild the blocks, because address are added
  if Len <> Length(FAddress) then
    RebuildBlocks;
end;

procedure TPLCMemoryManager.RemoveAddress(Address, Size, RegSize: Cardinal);
var
  i: Cardinal;
  Items: Cardinal;
  Len: Longint;
begin
  if (Size <= 0) or (RegSize = 0) then
    raise Exception.Create(SsizeMustBeAtLeastOne);

  // gets the actual size of address array
  Len := Length(FAddress);
  i := Address;
  Items := Size * RegSize + Address;
  while i < Items do
  begin
    RemoveAddress(i);
    Inc(i);
  end;
  // rebuild the blocks, because address are removed
  if Len <> Length(FAddress) then
    RebuildBlocks;
end;

function TPLCMemoryManager.SetValues(AdrStart, Len, RegSize: Cardinal; Values: TArrayOfDouble; LastResult: TProtocolIOResult): Longint;
var
  i: Longint;
  AdrEnd: Longint;
  LenUtil: Longint;
  Moved: Longint;
  SrcIndex: Integer;
  DstIndex: Integer;
begin
  AdrEnd := AdrStart + Length(Values) - 1;
  Moved := 0;

  for i := 0 to High(Blocks) do
  begin
    LenUtil := 0;

    if   ((Blocks[i].AddressStart >= AdrStart) and (Blocks[i].AddressStart <= AdrEnd))  // if block starts is over the requested address range
      or ((Blocks[i].AddressEnd >= AdrStart) and (Blocks[i].AddressEnd <= AdrEnd))      // OR block end is over the requested address range
      or ((AdrStart >= Blocks[i].AddressStart) and (AdrStart <= Blocks[i].AddressEnd))  // OR the request start is over the block address range
      or ((AdrEnd >= Blocks[i].AddressStart) and (AdrEnd <= Blocks[i].AddressEnd)) then // OR the request end is over the block address range, So, ladies and gentlemen, we have a memory overlap
    begin
      LenUtil := Min(AdrEnd, Blocks[i].AddressEnd) - Max(AdrStart, Blocks[i].AddressStart) + 1;

      Blocks[i].Updated;
      Blocks[i].LastError := LastResult;
      Blocks[i].ReadSuccess := Blocks[i].ReadSuccess + 1;

      SrcIndex := 0;
      DstIndex := 0;
      if Blocks[i].AddressStart >= AdrStart then
        begin
          DstIndex := 0;
          SrcIndex := Blocks[i].AddressStart - AdrStart;
        end
      else
        begin
          DstIndex := AdrStart - Blocks[i].AddressStart;
          SrcIndex := 0;
        end;

      Move(Values[SrcIndex], Blocks[i].FValues[DstIndex], LenUtil * SizeOf(Double));
    end;

    Inc(Moved, LenUtil);
    if Moved >= Length(Values) then
      Break;
  end;
  Result := IfThen(Moved = Length(Values), 0, IfThen(Moved < Length(Values), -1, 1));
end;

procedure TPLCMemoryManager.SetFault(AdrStart, Len, RegSize: Cardinal; Fault: TProtocolIOResult; const MarkAsUpdated: Boolean);
var
  i: Longint;
  AdrEnd: Longint;
begin
  AdrEnd := AdrStart + Len * RegSize - 1;

  for i := 0 to High(Blocks) do
  begin
    if   ((Blocks[i].AddressStart >= AdrStart) and (Blocks[i].AddressStart <= AdrEnd))    // if block starts is over the requested address range
      or ((Blocks[i].AddressEnd >= AdrStart) and (Blocks[i].AddressEnd <= AdrEnd))      // OR block end is over the requested address range
      or ((AdrStart >= Blocks[i].AddressStart) and (AdrStart <= Blocks[i].AddressEnd))  // OR the request start is over the block address range
      or ((AdrEnd >= Blocks[i].AddressStart) and (AdrEnd <= Blocks[i].AddressEnd)) then // OR the request end is over the block address range, So, ladies and gentlemen, we have a memory overlap
    begin
      Blocks[i].ReadFaults := Blocks[i].ReadFaults + 1;
      Blocks[i].LastError := Fault;
      if MarkAsUpdated then
        Blocks[i].Updated;
    end;
  end;
end;

function TPLCMemoryManager.GetValues(AdrStart, Len, RegSize: Cardinal; var Values: TArrayOfDouble; var LastResult: TProtocolIOResult; var ValueTimeStamp: TDateTime): Longint;
var
  i: Longint;
  AdrEnd: Longint;
  LenUtil: Longint;
  Moved: Longint;
  SrcIndex: Integer;
  DstIndex: Integer;
begin
  AdrEnd := AdrStart + Min(Length(Values), Len) - 1;
  Moved := 0;

  for i := 0 to High(Blocks) do
  begin
    LenUtil := 0;

    if   ((Blocks[i].AddressStart >= AdrStart) and (Blocks[i].AddressStart <= AdrEnd))  // if block starts is over the requested address range...
      or ((Blocks[i].AddressEnd >= AdrStart) and (Blocks[i].AddressEnd <= AdrEnd))      // OR block end is over the requested address range...
      or ((AdrStart >= Blocks[i].AddressStart) and (AdrStart <= Blocks[i].AddressEnd))  // OR the request start is over the block address range.
      or ((AdrEnd >= Blocks[i].AddressStart) and (AdrEnd <= Blocks[i].AddressEnd)) then // OR the request end is over the block address range, So, ladies and gentlemen, we have a memory overlap
    begin
      LenUtil := Min(AdrEnd, Blocks[i].AddressEnd) - Max(AdrStart, Blocks[i].AddressStart) + 1;

      LastResult := Blocks[i].LastError;
      ValueTimeStamp := Blocks[i].LastUpdate;

      SrcIndex := 0;
      DstIndex := 0;
      if Blocks[i].AddressStart >= AdrStart then
        begin
          SrcIndex := 0;
          DstIndex := Blocks[i].AddressStart - AdrStart;
        end
      else
        begin
          SrcIndex := AdrStart - Blocks[i].AddressStart;
          DstIndex := 0;
        end;

      Move(Blocks[i].FValues[SrcIndex], Values[DstIndex], LenUtil * SizeOf(Double));
    end;
    Inc(Moved, LenUtil);
    if Moved >= Length(Values) then
      Break;
  end;
  Result := IfThen(Moved = Length(Values), 0, IfThen(Moved < Length(Values), -1, 1));
end;

constructor TPLCMemoryManagerSafe.Create;
begin
  inherited Create;
  FMutex := TCriticalSection.Create;
end;

destructor TPLCMemoryManagerSafe.Destroy;
begin
  FMutex.Destroy;
  inherited Destroy;
end;

procedure TPLCMemoryManagerSafe.AddAddress(Address, ASize, RegSize, Scan: Cardinal);
begin
  try
    FMutex.Enter;
    inherited AddAddress(Address, ASize, RegSize, Scan);
  finally
    FMutex.Leave;
  end;
end;

procedure TPLCMemoryManagerSafe.RemoveAddress(Address, ASize, RegSize: Cardinal);
begin
  try
    FMutex.Enter;
    inherited RemoveAddress(Address, ASize, RegSize);
  finally
    FMutex.Leave;
  end;
end;

function TPLCMemoryManagerSafe.SetValues(AdrStart, Len, RegSize: Cardinal; Values: TArrayOfDouble; LastResult: TProtocolIOResult): Longint;
begin
  try
    FMutex.Enter;
    Result := inherited SetValues(AdrStart, Len, RegSize, Values, LastResult);
  finally
    FMutex.Leave;
  end;
end;

function TPLCMemoryManagerSafe.GetValues(AdrStart, Len, RegSize: Cardinal; var Values: TArrayOfDouble; var LastResult: TProtocolIOResult; var ValueTimeStamp: TDateTime): Longint;
begin
  try
    FMutex.Enter;
    Result := inherited GetValues(AdrStart, Len, RegSize, Values, LastResult, ValueTimeStamp);
  finally
    FMutex.Leave;
  end;
end;

procedure TPLCMemoryManagerSafe.SetFault(AdrStart, Len, RegSize: Cardinal; Fault: TProtocolIOResult; const MarkAsUpdated: Boolean);
begin
  try
    FMutex.Enter;
    inherited SetFault(AdrStart, Len, RegSize, Fault, MarkAsUpdated);
  finally
    FMutex.Leave;
  end;
end;

end.

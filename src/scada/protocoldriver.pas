{$i ../common/language.inc}
{:
@abstract(Unit that implements a base class of protocol driver.)
@author(Fabio Luis Girardi fabio@pascalscada.com)


****************************** History  *******************************
***********************************************************************
07/2013 - Moved OpenTagEditor to TagBuilderAssistant to remove form dependencies
@author(Juanjo Montero <juanjo.montero@gmail.com>)
***********************************************************************
}
unit ProtocolDriver;

interface

uses
  SysUtils, Classes, CommPort, CommTypes, ProtocolTypes, protscanupdate,
  protscan, CrossEvent, Tag, syncobjs, fgl
  {$IFNDEF FPC}
  , Windows
  {$ENDIF}
  ;

type
  TTagList = specialize TFPGList<TTag>;

  {:
  @abstract(Classe base para drivers de protocolo.)

  @author(Fabio Luis Girardi fabio@pascalscada.com)

  Para você criar um novo driver, basta sobrescrever alguns métodos e funções,
  de acordo com as necessidades de seu driver de protocolo. São eles:

  @code(procedure DoAddTag(TagObj:TTag);)
  Sobrescreva esse procedimento para adicionar tags ao scan do driver. Faça as
  devidas verificações do tag nesse método e caso ele não seja um tag válido
  gere uma excessão para abortar a adição do tag no driver.
  Não esqueça de chamar o método herdado com @code(inherited DoAddTag(TagObj:TTag))
  para adicionar o tag na classe base (@name).

  @code(procedure DoDelTag(TagObj:TTag);)
  Procedimento por remover tags do scan do driver. Não esqueça de chamar o
  método herdado com @code(inherited DoDelTag(TagObj:TTag)) para remover o tag
  da classe base (@name).

  @code(procedure DoScanRead(Sender:TObject; var NeedSleep:LongInt);)
  Prodimento chamado para verificar se há algum tag necessitando ser lido.

  @code(procedure DoGetValue(TagObj:TTagRec; var values:TScanReadRec);)
  Procedimento chamado pelo driver para retornar os valores lidos que estão
  em algum gerenciador de memória para os tags.

  @code(function DoWrite(const tagrec:TTagRec; const Values:TArrayOfDouble; Sync:Boolean):TProtocolIOResult;)
  Executa as escritas de valores sincronas e assincronas dos tags. É este método
  que escreve os valores do tag no seu equipamento.

  @code(function DoRead (const tagrec:TTagRec; var   Values:TArrayOfDouble; Sync:Boolean):TProtocolIOResult;)
  Executa as leituras sincronas e assincronas dos tags. É o método que vai
  buscar os valores no seu equipamento.

  @code(function  SizeOfTag(Tag:TTag; isWrite:Boolean; var ProtocolTagType:TProtocolTagType):BYTE; )
  Função responsável por informar o tamanho das palavras de dados em bits
  que o tag está referenciando.

  Sobrescrevendo esses métodos e rotinas, seu driver estará pronto. @bold(Veja
  a documentação detalhada de cada método para enteder como cada um funciona.)
  }

  { TProtocolDriver }

  TProtocolDriver = class(TComponent, IPortDriverEventNotification)
  private
    //Array de tags associados ao driver.
    //Array of linked tags.
    PTags: TTagList;

    //Armazena se o protocolo está em modo somente reading
    //stores if the protocol is in read-only mode
    FReadOnly: Longint;

    //Tempo de gasto em millisegundos atualizando valores dos tags (e seus dependentes)
    //Time used in milliseconds to update the tag value and their dependents. 
    FUserUpdateTime: Double;

    //thread de execução do scan dos tags
    //Scan read thread object
    PScanReadThread: TScanThread;
    ////Thread de execução de escritas
    ////scan write thead object
    //PScanWriteThread:TScanThread;
    //thread de atualização dos pedidos dos tags
    //thread that updates tag values.
    PScanUpdateThread: TScanUpdate;

    //excessao caso o index to tag esteja fora dos limites
    //raises an exception if the that index is out of bounds.
    procedure DoExceptionIndexOut(index: Longint);
    function GetIsReadOnly: Boolean;

    //metodos para manipulação da lista de tags
    //procedures to handle the taglist.
    function GetTagCount: Longint;
    function GetTag(index: Longint): TTag;
    function GetTagName(index: Longint): AnsiString;
    function GetTagByName(AName: AnsiString): TTag;

    //metodo chamado pela thread de scan para ler valores do dispositivo.
    //procedure called to read data from your device.
    procedure SafeScanRead(Sender: TObject; var NeedSleep: Longint);
    //metodo chamado pela thred de scan de escrita para escrever valores no dispositivo.
    //procedure called by the scan write thread to write data on your device.
    function SafeScanWrite(const TagRec: TTagRec; const Values: TArrayOfDouble): TProtocolIOResult;
    //metodo chamado para atualizar o valor de um tag (simples ou bloco)
    //procedure called to update the value of an tag (single or block)
    procedure SafeGetValue(const TagRec: TTagRec; var Values: TScanReadRec);
    //metodo chamado para atualizar o valores de varios tags (simples ou bloco)
    //procedure called to update values of multiples tag (single or block)
    function GetMultipleValues(var MultiValues: TArrayOfScanUpdateRec): Longint;

    function SafeSingleScanRead(var TagRec: TTagRec; var Values: TArrayOfDouble): TProtocolIOResult;

    procedure DoPortOpened(Sender: TObject);
    procedure DoPortClosed(Sender: TObject);
    procedure DoPortDisconnected(Sender: TObject);
    procedure DoPortRemoved(Sender: TObject);

    procedure SetIsReadOnly(AValue: Boolean);
    procedure UpdateUserTime(usertime: Double);
  protected
    {: Tells to driver that a high latency operation will begins, releasing some
    resources of the driver. }
    procedure HighLatencyOperationWillBegin(Sender: TObject);
    {: Tells to driver that a high latency operation was ended, taking back some
    resources back to driver. }
    procedure HighLatencyOperationWasEnded(Sender: TObject);
  protected
    //: Tells if at least one item must be read at each scan cycle of protocol driver.
    PReadSomethingAlways: Boolean;
    //: Missing comment.
    PUpdatingMultipleTags: Integer;
    //: Tells if the protocol driver is ready
    FProtocolReady: Boolean;
    //: Stores the unique identification of protocol driver.
    PDriverID: Cardinal;
    //: Stores the communication port driver used by protocol driver.
    PCommPort: TCommPortDriver;
    //: Stores the unique identification of each kind of request.
    FScanReadID: Cardinal;
    FScanWriteID: Cardinal;
    FReadID: Cardinal;
    FWriteID: Cardinal;
    //: Mutex that protect the protocol driver.
    FReadCS: TCriticalSection;
    FWriteCS: TCriticalSection;
    //: Stop thread to keep the normal execution of the all system.
    FPause: TCrossEvent;
    //: Mutex that protect the scan procedures of the protocol driver.
    PCallersCS: TCriticalSection;

    {: Returns the procedure of protocol driver that must be called when the
       communication port was open.
    @seealso(PortOpened)
    @seealso(NotifyThisEvents) }
    function GetPortOpenedEvent: TNotifyEvent;
    {: Returns the procedure of protocol driver that must be called when the
       communication port was closed.
    @seealso(PortClosed)
    @seealso(NotifyThisEvents) }
    function GetPortClosedEvent: TNotifyEvent;
    {: Returns the procedure of protocol driver that must be called when the
       communication port was disconnected.
    @seealso(PortDisconnected)
    @seealso(NotifyThisEvents) }
    function GetPortDisconnectedEvent: TNotifyEvent;

    {: Returns what's the events of communication port driver must be notified to
       protocol driver.
    @seealso(PortOpened)
    @seealso(PortClosed)
    @seealso(PortDisconnected)
    @seealso(TNotifyEvent) }
    function NotifyThisEvents: TNotifyThisEvents; virtual;

    function NeedsExternalPort: Boolean; virtual;
    {: Procedure called by the communication port when it was open.
    @seealso(NotifyThisEvents)
    @seealso(GetPortOpenedEvent) }
    procedure PortOpened(Sender: TObject); virtual;
    {: Procedure called by the communication port when it was closed.
    @seealso(NotifyThisEvents)
    @seealso(GetPortClosedEvent) }
    procedure PortClosed(Sender: TObject); virtual;
    {: Procedure called by the communication port when it was disconnected.
    @seealso(NotifyThisEvents)
    @seealso(GetPortDisconnectedEvent) }
    procedure PortDisconnected(Sender: TObject); virtual;

    //: Sets the communication port driver that will be used by the protocol driver.
    procedure SetCommPort(CommPort: TCommPortDriver);
    {: Copies a TIOPacket to another
    @param(Source TIOPacket. Source record.)
    @param(Dest TIOPacket. Destination record.) }
    procedure CopyIOPacket(const Source: TIOPacket; var Dest: TIOPacket);
    {: Callback called by the communication port driver to returns the result of I/O.
    @param(Result TIOPacket. Record with the data and I/O results returned by
    the communication port. @bold(Is destroyed automaticaly.) }
    procedure CommPortCallBack(var Result: TIOPacket); virtual;
    {: Procedure called to add a tag into the scan of the protocol driver.
    @param(TagObj TTag. Tag to be added into the scan of protocol driver.)
    @seealso(AddTag) }
    procedure DoAddTag(TagObj: TTag; TagValid: Boolean); virtual;
    {: Procedure called to remove a tag from the scan of the protocol driver.
    @param(TagObj TTag. Tag to be removed of the scan of protocol driver.)
    @seealso(RemoveTag) }
    procedure DoDelTag(TagObj: TTag); virtual;
    {: Procedure called by the protocol driver threads to check if has some tags
       that must be updated/readed from device.
    @param(Sender TObject. Thread that's calling the procedure.)
    @param(NeedSleep LongInt. If the procedure did not found anything to be
    read/updated, write in this variable a negative value to force the scheduler
    of the OS to switch to another thread, or a positive value to make the caller
    thread sleep. The time of the sleep is the value of this variable. If this
    procedure found some tag that was updated, write 0 (zero) on this variable.)
    @seealso(TProtocolDriver.DoRead) }
    procedure DoScanRead(Sender: TObject; var NeedSleep: Longint); virtual; abstract;
    {: Procedure called by the protocol driver threads to update the tag values.
    @param(TagRec TTagRec. Structure with informations about the tag.)
    @param(values TScanReadRec. Array with the tag values.) }
    procedure DoGetValue(TagRec: TTagRec; var values: TScanReadRec); virtual; abstract;
    {: Function called to write tag values (single or block) on device.
    @param(tagrec TTagRec. Strucutre with informations about the tag.)
    @param(Values TArrayOfDouble. Values to be written on device.)
    @returns(TProtocolIOResult). }
    function DoWrite(const TagRec: TTagRec; const values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; virtual; abstract;
    {: Function called to read values from your device.
    @param(tagrec TTagRec. Strucutre with informations about the tag.)
    @param(Values TArrayOfDouble. Array that will store the values read from your device.)
    @returns(TProtocolIOResult). }
    function DoRead(const TagRec: TTagRec; out values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; virtual; abstract;

    //: Tells if the protocol driver must read something on each scan cycle.
    property ReadSomethingAlways: Boolean read PReadSomethingAlways write PReadSomethingAlways default True;
    //: Average time in milliseconds used to update values of tags and their dependents.
    property ReadOnly: Boolean read GetIsReadOnly write SetIsReadOnly;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;

    //: @exclude
    procedure AfterConstruction; override;

    //: @exclude
    destructor Destroy; override;

    {: Add a tag into the scan cycle of the protocol driver.
    @param(Tag TTag. Tag to be added into scan cycle of the protocol driver.)
    @raises(Exception if something is wrong.) }
    procedure AddTag(TagObj: TTag);

    procedure StartUpdateMultipleTags;
    procedure StopUpdateMultipleTags;

    {: Remove a tag from the scan cycle of the protocol driver.
    @param(Tag TTag. Tag to be removed.) }
    procedure RemoveTag(TagObj: TTag);
    {: Function that returns if the tag is already linked with the protocol driver.
    @param(TagObj TTag. Tag to be checked if it's linked.)
    @returns(@true if the tag is linked with protocol.) }
    function IsMyTag(TagObj: TTag): Boolean;
    {: Returns the word size of the tag on protocol, in bits.
    @param(Tag TTag. Tag that wants know the word size.)
    @param(isWrite Boolean. If @true, returns the word size if want know the size
           using the write function.)
    @returns(The current word size on protocol of the tag, OR 0 (zero) if it fails.) }
    function SizeOfTag(aTag: TTag; isWrite: Boolean; var ProtocolTagType: TProtocolTagType): Byte; virtual; abstract;

    {: Requests a tag update.
    @param(tagrec TTagRec. Record with informations about the tag.)
    @returns(Cardinal. The unique identification number of the request.) }
    function SingleScanRead(const TagRec: TTagRec): Cardinal;
    {: Write values @bold(asynchronous) using the scan of the protocol driver.
    @param(tagrec TTagRec. Record with informations about the tag.)
    @param(Values TArrayOfDouble Values to be written.)
    @returns(Cardinal. The unique identification number of the request.) }
    function ScanWrite(const TagRec: TTagRec; const Values: TArrayOfDouble): Cardinal;
    {: Read the tag value from the device (synchronous).
    @param(tagrec TTagRec. Record with informations about the tag.) }
    procedure Read(const TagRec: TTagRec);
    {: Write the tag values (synchronous).
    @param(tagrec TTagRec. Record with informations about the tag.)
    @param(Values TArrayOfDouble Values to be written.) }
    procedure Write(const TagRec: TTagRec; const Values: TArrayOfDouble);

    //: Returns the literal address of the tag.
    function LiteralTagAddress(aTag: TTag; aBlockTag: TTag = nil): AnsiString; virtual;

    //: Return how many tags are on scan cycle of the protocol driver.
    property TagCount: Longint read GetTagCount;
    //: Return the tags using the index.
    property Tag[index: Longint]: TTag read GetTag;
    //: Return the tag names.
    property TagName[index: Longint]: AnsiString read GetTagName;
    //: Returns the tag by the name index.
    property TagByName[Nome: AnsiString]: TTag read GetTagByName;
    //: Opens the Tag Builder of the protocol driver (if exists)
    procedure OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); virtual;
    //: Tell to the protocol editor if the current protocol has a tab builder tool defined.
    function HasTabBuilderEditor: Boolean; virtual;
  published
    {: Communication port driver used by the protocol driver.
    @seealso(TCommPortDriver) }
    property CommunicationPort: TCommPortDriver read PCommPort write SetCommPort nodefault;
    //: Unique protocol identification.
    property DriverID: Cardinal read PDriverID;
    //: Average time in milliseconds used to update values of tags and their dependents.
    property AvgTagUpdateTime: Double read FUserUpdateTime;
  end;

var
  {: Protocol driver counter, used to generate unique names of events, mutexes and
     semaphores on Windows platforms.
  @bold(Don't change the value of this variable.) }
  DriverCount: Cardinal;


implementation


uses
  dateutils, PLCTag, hsstrings, Math, crossdatetime, pascalScadaMTPCPU;


  ////////////////////////////////////////////////////////////////////////////////
  //                 implementation of TProtocolDriver
  ////////////////////////////////////////////////////////////////////////////////

constructor TProtocolDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FScanReadID := 0;
  FScanWriteID := 0;
  FReadID := 0;
  FWriteID := 0;

  PUpdatingMultipleTags := 0;

  FReadOnly := 0;
  PDriverID := DriverCount;
  Inc(DriverCount);
  PTags := TTagList.Create;

  FProtocolReady := True;

  FReadCS := TCriticalSection.Create;
  FWriteCS := TCriticalSection.Create;

  FPause := TCrossEvent.Create(True, True);

  PCallersCS := TCriticalSection.Create;

  PScanUpdateThread := TScanUpdate.Create(True, Self, @UpdateUserTime);
  {$IFNDEF WINCE}
  PScanUpdateThread.Priority := tpHighest;
  {$ENDIF}
  PScanUpdateThread.OnGetValue := @SafeGetValue;
  PScanUpdateThread.OnScanTags := @GetMultipleValues;

  PScanReadThread := TScanThread.Create(True, PScanUpdateThread);
  {$IFNDEF WINCE}
  PScanReadThread.Priority := tpTimeCritical;
  {$ENDIF}
  PScanReadThread.OnDoScanRead := @SafeScanRead;
  PScanReadThread.OnDoScanWrite := @SafeScanWrite;
  PScanReadThread.OnDoSingleScanRead := @SafeSingleScanRead;
end;

procedure TProtocolDriver.AfterConstruction;
begin
  inherited AfterConstruction;
  PScanUpdateThread.WakeUp;

  PScanReadThread.WakeUp;
  PScanReadThread.WaitLoopStarts;

  //PScanWriteThread.WakeUp;
  //PScanWriteThread.WaitInit;
end;

destructor TProtocolDriver.Destroy;
var
  i: Longint;
begin
  PScanReadThread.Terminate;
  PScanReadThread.WaitFor;
  PScanReadThread.Destroy;

  //PScanWriteThread.Terminate;
  //PScanWriteThread.WaitFor;
  //PScanWriteThread.Destroy;

  PScanUpdateThread.Terminate;
  PScanUpdateThread.WaitFor;
  PScanUpdateThread.Destroy;

  for i := PTags.Count - 1 downto 0 do
    TPLCTag(PTags.Items[i]).RemoveDriver;

  SetCommPort(nil);

  FReadCS.Destroy;
  FWriteCS.Destroy;

  FPause.Destroy;

  FreeAndNil(PTags);
  PCallersCS.Destroy;
  inherited Destroy;
end;


procedure TProtocolDriver.SetCommPort(CommPort: TCommPortDriver);
begin
  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;

    // if is the same communication port, Exit
    if CommPort = PCommPort then Exit;

    if PCommPort <> nil then
    begin
      if PCommPort.LockedBy = PDriverID then
        PCommPort.Unlock(PDriverID);
      PCommPort.DelProtocol(Self);
    end;

    if CommPort <> nil then
    begin
      CommPort.AddProtocol(Self);
    end;
    PCommPort := CommPort;
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
  end;
end;

procedure TProtocolDriver.DoAddTag(TagObj: TTag; TagValid: Boolean);
begin
  if PTags.IndexOf(TagObj) <> -1 then
    raise Exception.Create(STagAlreadyRegiteredWithThisDriver);

  PTags.Add(TagObj);

  (TagObj as IScanableTagInterface).SetTagValidity(TagValid);
end;

procedure TProtocolDriver.DoDelTag(TagObj: TTag);
begin
  if PTags.Count <= 0 then Exit;

  if PTags.IndexOf(TagObj) <> -1 then
  begin
    (TagObj as IScanableTagInterface).SetTagValidity(False);
    PTags.Remove(TagObj);
  end;
end;

procedure TProtocolDriver.AddTag(TagObj: TTag);
begin
  if not Supports(TagObj, IScanableTagInterface) then
    raise Exception.Create(SScanableNotSupported);

  try
    // try enter on mutex
    if InterLockedExchange(PUpdatingMultipleTags, PUpdatingMultipleTags) = 0 then
    begin
      while not FPause.ResetEvent do
        CrossThreadSwitch;
      FWriteCS.Enter;
      FReadCS.Enter;
    end;

    DoAddTag(TagObj, False);
  finally
    if InterLockedExchange(PUpdatingMultipleTags, PUpdatingMultipleTags) = 0 then
    begin
      FReadCS.Leave;
      FWriteCS.Leave;
      while not FPause.SetEvent do
        CrossThreadSwitch;
    end;
  end;
end;

procedure TProtocolDriver.StartUpdateMultipleTags;
begin
  // if I'm the first starting this multiple tags update,
  // gets the mutexes
  if InterLockedIncrement(PUpdatingMultipleTags) = 1 then
  begin
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;
  end;
end;

procedure TProtocolDriver.StopUpdateMultipleTags;
begin
  if InterLockedDecrement(PUpdatingMultipleTags) <= 0 then
  begin
    FReadCS.Leave;
    FWriteCS.Leave;

    while not FPause.SetEvent do
      CrossThreadSwitch;

    InterLockedExchange(PUpdatingMultipleTags, 0);
  end;
end;

procedure TProtocolDriver.RemoveTag(TagObj: TTag);
begin
  try
    // try enter on mutex
    if InterLockedExchange(PUpdatingMultipleTags, PUpdatingMultipleTags) = 0 then
    begin
      while not FPause.ResetEvent do
        CrossThreadSwitch;

      FWriteCS.Enter;
      FReadCS.Enter;
    end;

    DoDelTag(TagObj);
  finally
    if InterLockedExchange(PUpdatingMultipleTags, PUpdatingMultipleTags) = 0 then
    begin
      FReadCS.Leave;
      FWriteCS.Leave;

      while not FPause.SetEvent do
        CrossThreadSwitch;
    end;
  end;
end;

procedure TProtocolDriver.DoExceptionIndexOut(index: Longint);
begin
  if (index >= PTags.Count) then
    raise Exception.Create(SoutOfBounds);
end;

function TProtocolDriver.GetIsReadOnly: Boolean;
var
  FInReadOnlyMode: Longint;
begin
  InterLockedExchange(FInReadOnlyMode, FReadOnly);
  Result := FInReadOnlyMode = 1;
end;

function TProtocolDriver.GetTagCount: Longint;
begin
  //FCritical.Enter;
  try
    InterLockedExchange(Result, PTags.Count);
  finally
    //FCritical.Leave;
  end;
end;

function TProtocolDriver.GetTag(index: Longint): TTag;
begin
  //FCritical.Enter;
  try
    DoExceptionIndexOut(index);
    Result := PTags[index];
  finally
    //FCritical.Leave;
  end;
end;

function TProtocolDriver.GetTagName(index: Longint): AnsiString;
begin
  Result := '';
  //FCritical.Enter;
  try
    DoExceptionIndexOut(index);
    Result := PTags[index].Name;
  finally
    //FCritical.Leave;
  end;
end;

function TProtocolDriver.GetTagByName(AName: AnsiString): TTag;
var
  i: Longint;
begin
  Result := nil;
  //FCritical.Enter;
  try
    for i := 0 to PTags.Count - 1 do
      if PTags.Items[i].Name = AName then
      begin
        Result := PTags.Items[i];
        Break;
      end;
  finally
    //FCritical.Leave;
  end;
end;

function TProtocolDriver.IsMyTag(TagObj: TTag): Boolean;
begin
  Result := False;
  //FCritical.Enter;
  try
    Result := PTags.IndexOf(TagObj) <> -1;
  finally
    //FCritical.Leave;
  end;
end;

function TProtocolDriver.SingleScanRead(const TagRec: TTagRec): Cardinal;
var
  Pkg: PScanReqRec;
begin
  try
    PCallersCS.Enter;
    // check if is in design-time
    if (csReading in ComponentState) or
      (csDestroying in ComponentState) then
    begin
      Result := 0;
      Exit;
    end;
    // increment the scan read unique identification
    if FScanReadID = $FFFFFFFF then
      FScanReadID := 1
    else
      Inc(FScanReadID);

    // creates the message of scan read
    New(Pkg);
    // copy the tagrec
    Pkg^.Tag := TagRec;
    // copy the request id
    Pkg^.Tag.ID := FScanReadID;
    // copy the values
    SetLength(Pkg^.values, 0);
    Pkg^.RequestResult := ioNone;
    Pkg^.ValueTimeStamp := CrossNow;

    // send a message requesting a scanread
    if (PScanUpdateThread <> nil) then
      PScanReadThread.SingleScanRead(Pkg);

    Result := FScanReadID;
  finally
    PCallersCS.Leave;
  end;
end;

function TProtocolDriver.ScanWrite(const TagRec: TTagRec; const Values: TArrayOfDouble): Cardinal;
var
  Pkg: PScanReqRec;
begin
  // read only protocol
  if GetIsReadOnly then
  begin
    TagRec.CallBack(0, Values, Now, tcScanWrite, ioReadOnlyProtocol, TagRec.RealOffset);
    Result := 0;
    Exit;
  end;

  try
    PCallersCS.Enter;
    // check if is in design-time
    if (csReading in ComponentState) or
      (csDestroying in ComponentState) then
    begin
      Result := 0;
      Exit;
    end;
    // increment the scan write unique identification
    if FScanWriteID = $FFFFFFFF then
      FScanWriteID := 1
    else
      Inc(FScanWriteID);

    // creates the message of scan write
    New(Pkg);
    FillByte(Pkg^, SizeOf(Pkg^), 0);
    // copy the tagrec
    Pkg^.Tag := TagRec;
    Pkg^.Tag.Path := TagRec.Path;
    // copy the request id
    Pkg^.Tag.ID := FScanWriteID;
    // copy the Values
    Pkg^.values := Values;
    Pkg^.RequestResult := ioNone;
    Pkg^.ValueTimeStamp := CrossNow;

    // send the scanwrite message to thread.
    if (PScanReadThread <> nil) then
    begin
      PScanReadThread.ScanWrite(Pkg);
      CrossThreadSwitch;
    end;

    Result := FScanWriteID;
  finally
    PCallersCS.Leave;
  end;
end;

procedure TProtocolDriver.Read(const TagRec: TTagRec);
var
  Res: TProtocolIOResult;
  Values: TArrayOfDouble;
begin
  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;
    Res := DoRead(TagRec, Values, True);
    if Assigned(TagRec.CallBack) then
      TagRec.CallBack(0, Values, CrossNow, tcRead, Res, TagRec.RealOffset);
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
    SetLength(Values, 0);
  end;
end;

procedure TProtocolDriver.Write(const TagRec: TTagRec; const Values: TArrayOfDouble);
var
  Res: TProtocolIOResult;
begin
  if GetIsReadOnly then
  begin
    TagRec.CallBack(0, Values, Now, tcWrite, ioReadOnlyProtocol, TagRec.RealOffset);
    Exit;
  end;

  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;

    Res := DoWrite(TagRec, Values, True);
    if Assigned(TagRec.CallBack) then
      TagRec.CallBack(0, Values, CrossNow, tcWrite, Res, TagRec.RealOffset);
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
  end;
end;

function TProtocolDriver.LiteralTagAddress(aTag: TTag; aBlockTag: TTag): AnsiString;
begin
  Result := '';
end;

procedure TProtocolDriver.OpenTagEditor(InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  raise Exception.Create('This protocol driver do not have a Tag Builder tool defined.');
end;

function TProtocolDriver.HasTabBuilderEditor: Boolean;
begin
  Result := False;
end;

procedure TProtocolDriver.CommPortCallBack(var Result: TIOPacket);
begin
  if Result.Res2 <> nil then
    CopyIOPacket(Result, PIOPacket(Result.Res2)^);
  if Result.res1 is TCrossEvent then
    TCrossEvent(Result.res1).SetEvent;
end;

procedure TProtocolDriver.CopyIOPacket(const Source: TIOPacket; var Dest: TIOPacket);
begin
  Dest.PacketID := Source.PacketID;
  Dest.WriteIOResult := Source.WriteIOResult;
  Dest.ToWrite := Source.ToWrite;
  Dest.Written := Source.Written;
  Dest.WriteRetries := Source.WriteRetries;
  Dest.DelayBetweenCommand := Source.DelayBetweenCommand;
  Dest.ReadIOResult := Source.ReadIOResult;
  Dest.ToRead := Source.ToRead;
  Dest.Received := Source.Received;
  Dest.ReadRetries := Source.ReadRetries;
  SetLength(Dest.BufferToRead, 0);
  SetLength(Dest.BufferToWrite, 0);
  Dest.BufferToRead := Source.BufferToRead;
  Dest.BufferToWrite := Source.BufferToWrite;
  Dest.res1 := Source.res1;
  Dest.Res2 := Source.Res2;
end;

procedure TProtocolDriver.SafeScanRead(Sender: TObject; var NeedSleep: Longint);
begin
  try
    FPause.WaitFor($FFFFFFFF);
    FWriteCS.Enter;
    FReadCS.Enter;
    DoScanRead(Sender, NeedSleep);
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    CrossThreadSwitch;
  end;
end;

function TProtocolDriver.SafeScanWrite(const TagRec: TTagRec; const Values: TArrayOfDouble): TProtocolIOResult;
begin
  if GetIsReadOnly then
    begin
      Result := ioReadOnlyProtocol;
      Exit;
    end;
  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;

    Result := DoWrite(TagRec, Values, False)
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
  end;
end;

function TProtocolDriver.SafeSingleScanRead(var TagRec: TTagRec; var Values: TArrayOfDouble): TProtocolIOResult;
begin
  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;

    Result := DoRead(TagRec, Values, False)
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
  end;
end;

procedure TProtocolDriver.SafeGetValue(const TagRec: TTagRec; var Values: TScanReadRec);
begin
  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FReadCS.Enter;

    DoGetValue(TagRec, Values);
  finally
    FReadCS.Leave;
    FPause.SetEvent;
  end;
end;

function TProtocolDriver.GetMultipleValues(var MultiValues: TArrayOfScanUpdateRec): Longint;
var
  i: Longint;
  ValueSet: Longint;
  IntTagCount: Longint;
  First: Boolean;
  TagInterface: IScanableTagInterface;
  TagRec: TTagRec;
  RemainingMs: Int64;
  ScanReadRec: TScanReadRec;
  DoneOne: Boolean;
  PortError: Boolean;
  ErrorStatus: TProtocolIOResult;
begin
  DoneOne := False;
  try
    Result := 0;
    ValueSet := -1;
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FReadCS.Enter;

    if ComponentState * [csDestroying] <> [] then Exit;
    PortError := False;

    if NeedsExternalPort then
    begin
      if (PCommPort = nil) then
        begin
          PortError := True;
          ErrorStatus := ioNullCommPort;
        end
      else
        begin
          if (PCommPort.ReallyActive = False) then
          begin
            PortError := True;
            ErrorStatus := ioCommPortClosed;
          end;
        end;
    end;

    IntTagCount := TagCount;

    for i := 0 to TagCount - 1 do
    begin
      if Supports(Tag[i], IScanableTagInterface) then
      begin
        TagInterface := Tag[i] as IScanableTagInterface;
        if TagInterface.IsValidTag then
        begin
          if PReadSomethingAlways then
            RemainingMs := TagInterface.RemainingMiliseconds
          else
            RemainingMs := TagInterface.RemainingMilisecondsForNextScan;
          // if the remaining time is greater than zero
          if RemainingMs > 0 then
            begin
              if First then
              begin
                Result := RemainingMs;
                First := False;
              end
              else
                Result := Min(RemainingMs, Result);
            end
          else
            begin

              TagInterface.BuildTagRec(TagRec, 0, 0);
              SetLength(ScanReadRec.values, TagRec.Size);
              if PortError then
                begin
                  ScanReadRec.ValuesTimestamp := CrossNow;
                  ScanReadRec.LastQueryResult := ErrorStatus;
                  ScanReadRec.Offset := 0;
                  ScanReadRec.ReadFaults := 0;
                  ScanReadRec.ReadsOK := 0;
                  ScanReadRec.RealOffset := 0;
                end
              else
                DoGetValue(TagRec, ScanReadRec);

              if ScanReadRec.ValuesTimestamp > TagInterface.GetLastUpdateTimestamp then
              begin
                // calcula o tempo para a proxima atualização
                if First then
                  begin
                    Result := TagInterface.GetUpdateTime - MilliSecondsBetween(CrossNow, ScanReadRec.ValuesTimestamp);
                    First := False;
                  end
                else
                  Result := Min(TagInterface.GetUpdateTime - MilliSecondsBetween(CrossNow, ScanReadRec.ValuesTimestamp), Result);

                DoneOne := True;
                Inc(ValueSet);
                SetLength(MultiValues, ValueSet + 1);

                MultiValues[ValueSet].LastResult := ScanReadRec.LastQueryResult;
                MultiValues[ValueSet].CallBack := TagRec.CallBack;
                MultiValues[ValueSet].values := ScanReadRec.values;
                MultiValues[ValueSet].ValueTimeStamp := ScanReadRec.ValuesTimestamp;
              end;
            end;
        end;
      end;
    end;
  finally
    FReadCS.Leave;
    FPause.SetEvent;
    if (ErrorStatus in [ioNullCommPort, ioCommPortClosed]) or (IntTagCount <= 0) then
      Sleep(50);
  end;
end;

function TProtocolDriver.GetPortOpenedEvent: TNotifyEvent;
begin
  Result := @DoPortOpened;
end;

function TProtocolDriver.GetPortClosedEvent: TNotifyEvent;
begin
  Result := @DoPortClosed;
end;

function TProtocolDriver.GetPortDisconnectedEvent: TNotifyEvent;
begin
  Result := @DoPortDisconnected;
end;

function TProtocolDriver.NotifyThisEvents: TNotifyThisEvents;
begin
  Result := [];
end;

function TProtocolDriver.NeedsExternalPort: Boolean;
begin
  Result := True;
end;

procedure TProtocolDriver.DoPortOpened(Sender: TObject);
begin
  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;

    PortOpened(Sender);
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
  end;
end;

procedure TProtocolDriver.DoPortClosed(Sender: TObject);
begin
  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;

    PortClosed(Sender);
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
  end;
end;

procedure TProtocolDriver.DoPortDisconnected(Sender: TObject);
begin
  try
    // try enter on mutex
    while not FPause.ResetEvent do
      CrossThreadSwitch;

    FWriteCS.Enter;
    FReadCS.Enter;

    PortDisconnected(Sender);
  finally
    FReadCS.Leave;
    FWriteCS.Leave;
    FPause.SetEvent;
  end;
end;

procedure TProtocolDriver.DoPortRemoved(Sender: TObject);
begin
  if CommunicationPort = Sender then
    CommunicationPort := nil;
end;

procedure TProtocolDriver.SetIsReadOnly(AValue: Boolean);
begin
  if AValue then
    InterLockedExchange(FReadOnly, 1)
  else
    InterLockedExchange(FReadOnly, 0);
end;

procedure TProtocolDriver.UpdateUserTime(usertime: Double);
begin
  FUserUpdateTime := usertime;
end;

procedure TProtocolDriver.HighLatencyOperationWillBegin(Sender: TObject);
begin
  FReadCS.Leave;
end;

procedure TProtocolDriver.HighLatencyOperationWasEnded(Sender: TObject);
begin
  FReadCS.Enter;
end;

procedure TProtocolDriver.PortOpened(Sender: TObject);
begin

end;

procedure TProtocolDriver.PortClosed(Sender: TObject);
begin

end;

procedure TProtocolDriver.PortDisconnected(Sender: TObject);
begin

end;


initialization
  DriverCount := 1;


end.

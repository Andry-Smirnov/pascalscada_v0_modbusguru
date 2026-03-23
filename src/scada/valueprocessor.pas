{$i ../common/language.inc}
{:
  @abstract(Implements the scale processors.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
unit ValueProcessor;

interface

uses
  SysUtils, Classes, PLCTag;

type
  {: @abstract(Base class for all scale processors.)
     @author(Fabio Luis Girardi <fabio@pascalscada.com>) }
  TScaleProcessor = class(TComponent)
  private
    FValueIn: Double;
    FQueueItems: array of TCollectionItem;
    procedure SetInput(Value: Double);
    function GetOutput: Double;
    procedure SetOutput(Value: Double);
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    //: Adds a object to dependents list.
    procedure AddQueueItem(QueueItem: TCollectionItem);

    //: Removes a object from the dependent object list.
    procedure DelQueueItem(QueueItem: TCollectionItem);

    {: Returns a value in engineering scale based on a raw value and in the scales
       parameters, if there exists.
    @bold(Usually, this value is comming from device and going to user.)
    @param(Sender TComponent: Who is requesting this transformation.)
    @param(Input Double: Input value to be processed.)
    @returns(Double. The value tranformed to engineering scale.) }
    function SetInGetOut(Sender: TComponent; Input: Double): Double; virtual;

    {: Returns a raw value based on a value in engineering scale and in scales
       parameters, if there exists.
    @bold(Usually, this value is comming from a user input going to device.)
    @param(Sender TComponent: Who is requesting this value transformation.)
    @param(Output Double: Value in engineering scale to be processed to a raw value.)
    @returns(Double. The tranformed raw value.) }
    function SetOutGetIn(Sender: TComponent; Output: Double): Double; virtual;
  published
    {: Property to test the scale processor.
    If something is written in @name, the transformed value will be returned on OutPut property.
    If something is written in OutPut, the transformed value will be returned on @name property.
    @seealso(OutPut) }
    property Input: Double read FValueIn write SetInput stored False;

    {: Property to test the scale processor.
    If something is written in @name, the transformed value will be returned on Input property.
    If something is written in Input, the transformed value will be returned on @name property.
    @seealso(Input) }
    property Output: Double read GetOutput write SetOutput stored False;
  end;

  //: Implements a item of a scales processors collection
  TScaleQueueItem = class(TCollectionItem)
  private
    SProcessor: TScaleProcessor;
    procedure SetScaleProcessor(SP: TScaleProcessor);
  protected
    //: @exclude
    function GetDisplayName: AnsiString; override;
  public
    {: Procedure called to remove a dependency with a scale processor object that
       is being destroyed. }
    procedure RemoveScaleProcessor;

    {: Calls the procedure SetInGetOut of the scale processor, if it's set.

    @param(Sender TComponent: Object that did the request.)
    @param(Input Double: Value to be processed.)

    @returns(The value processed by the scale processor. If there isn't an
    object associated, returns the value of Input.)

    @seealso(TScaleProcessor.SetInGetOut) }
    function SetInGetOut(Sender: TComponent; Input: Double): Double;

    {: Calls the procedure SetOutGetIn of the scale processor, if it's set.

    @param(Sender TComponent: Object that did the request.)
    @param(Output Double: Value to be processed.)

    @returns(The value processed by the scale processor. If there isn't an
    object associated, returns the value of Output parameter.)

    @seealso(TScaleProcessor.SetInGetOut) }
    function SetOutGetIn(Sender: TComponent; Output: Double): Double;
  published
    //: Scale processor object that does the values transformations of this item.
    property ScaleProcessor: TScaleProcessor read SProcessor write SetScaleProcessor;
  end;

  //: Implements a collection of scale processors
  TScaleQueue = class(TCollection)
  private
    FOwner: TPersistent;
  protected
    //: @exclude
    function GetOwner: TPersistent; override;
  public
    //: @exclude
    constructor Create(AOwner: TPersistent);

    {: Adds a new item to collection.
    @returns(The new item of the collection.) }
    function Add: TScaleQueueItem;

    {: Process a raw value (Input) to a value in engineering scale, processed by
       each scale processors of the collection.

    To do this, this method passes the Input parameter to TScalePIPEItem.SetInGetOut
    of the first item of the collection, takes the result and passes it again as
    Input of TScalePIPEItem.SetInGetOut of the next item of the collection,
    until reach the end of the collection.

    @bold(So, the first item of the collection is the first that will be called
    when the value is comming from device and going to User AND so as the last
    item of the collection o is the first to be called when the value is comming
    from the user and going to device.)

    @param(Sender TComponent: Object that has requested the value transformation.)
    @param(Input Double: Value to be transformed to a value in engineering scale.)
    @returns(Returns the value processed by all items of the collection. If the
             collection is empty or all items of the collection aren't set
             correctly (a value processor isn't set), returns the value given in
             Input parameter.)
    @seealso(TScalePIPEItem.SetInGetOut) }
    function SetInGetOut(Sender: TComponent; Input: Double): Double;

    {: Process a raw value in engineering scale to a raw value, processed by each
       scale processors of the collection.

    Para fazer isso, esse método passa o parâmetro de entrada para
    TScalePIPEItem.SetInGetOut do último item da coleção, leva o resultado e
    passa-lo novamente como entrada de TScalePIPEItem.SetInGetOut do item que
    precede o item atual da coleção, até chegar ao início da coleção.

    @bold(So, the last item of the collection is the first that will be called
          when the value is comming from the user and going to device AND so as
          the first item of the collection o is the last to be called when the
          value is comming from the device and going to user.)

    @param(Sender TComponent: Object that has requested the value transformation.)
    @param(Output Double: Value in engineering scale to be transformed to a raw value.)
    @returns(Returns the value processed by all items of the collection. If the
             collection is empty or all items of the collection aren't set
             correctly (a value processor isn't set), returns the value given in
             Outpu parameter.)
    @seealso(TScalePIPEItem.SetInGetOut) }
    function SetOutGetIn(Sender: TComponent; Output: Double): Double;
  end;


  //: Scale processors queue.
  TScalesQueue = class(TScaleProcessor)
  private
    FScaleQueue: TScaleQueue;
    FTags: array of TPLCTag;

    function GetScaleQueue: TScaleQueue;
    procedure SetScaleQueue(ScaleQueue: TScaleQueue);
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;

    //: @seealso(TScalePIPE.SetInGetOut)
    function SetInGetOut(Sender: TComponent; AInput: Double): Double; override;
    //: @seealso(TScalePIPE.SetOutGetIn)
    function SetOutGetIn(Sender: TComponent; AOutput: Double): Double; override;
  published
    //: Collection of scale processors.
    property Scales: TScaleQueue read GetScaleQueue write SetScaleQueue stored False; // to be removed after 1.0
    property ScalesQueue: TScaleQueue read GetScaleQueue write SetScaleQueue stored True;
  end;


implementation


uses
  PLCNumber, hsstrings;


////////////////////////////////////////////////////////////////////////////////
// TScaleQueueItem implementation
////////////////////////////////////////////////////////////////////////////////
procedure TScaleQueueItem.SetScaleProcessor(SP: TScaleProcessor);
begin
  if SP = Collection.Owner then
    raise Exception.Create(SInvalidQueueOperation);

  if SP = SProcessor then Exit;

  if SProcessor <> nil then
    SProcessor.DelQueueItem(Self);

  if SP <> nil then
    SP.AddQueueItem(Self);

  DisplayName := SP.Name;
  SProcessor := SP;
end;

function TScaleQueueItem.GetDisplayName: AnsiString;
begin
  if SProcessor <> nil then
    Result := SProcessor.Name
  else
    Result := SEmpty;
end;

function TScaleQueueItem.SetInGetOut(Sender: TComponent; Input: Double): Double;
begin
  if SProcessor <> nil then
    Result := SProcessor.SetInGetOut(Sender, Input)
  else
    Result := Input;
end;

function TScaleQueueItem.SetOutGetIn(Sender: TComponent; Output: Double): Double;
begin
  if SProcessor <> nil then
    Result := SProcessor.SetOutGetIn(Sender, Output)
  else
    Result := Output;
end;

procedure TScaleQueueItem.RemoveScaleProcessor;
begin
  SProcessor := nil;
end;

////////////////////////////////////////////////////////////////////////////////
// TScalePIPE implementation
////////////////////////////////////////////////////////////////////////////////

constructor TScaleQueue.Create(AOwner: TPersistent);
begin
  inherited Create(TScaleQueueItem);
  FOwner := AOwner;
end;

function TScaleQueue.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TScaleQueue.Add: TScaleQueueItem;
begin
  Result := TScaleQueueItem(inherited Add);
end;

function TScaleQueue.SetInGetOut(Sender: TComponent; Input: Double): Double;
var
  c: Longint;
begin
  Result := Input;
  for c := 0 to Count - 1 do
    if GetItem(c) is TScaleQueueItem then
      Result := TScaleQueueItem(GetItem(c)).SetInGetOut(Sender, Result);
end;

function TScaleQueue.SetOutGetIn(Sender: TComponent; Output: Double): Double;
var
  c: Longint;
begin
  Result := Output;
  for c := (Count - 1) downto 0 do
    if GetItem(c) is TScaleQueueItem then
      Result := TScaleQueueItem(GetItem(c)).SetOutGetIn(Sender, Result);
end;

////////////////////////////////////////////////////////////////////////////////
// TPIPE implementation
////////////////////////////////////////////////////////////////////////////////

constructor TScalesQueue.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FScaleQueue := TScaleQueue.Create(Self);
end;

destructor TScalesQueue.Destroy;
var
  t: Longint;
begin
  for t := High(FTags) downto 0 do
  begin
    TPLCNumber(FTags[t]).ScaleProcessor := nil;
  end;
  FScaleQueue.Destroy;
  inherited Destroy;
end;

function TScalesQueue.GetScaleQueue: TScaleQueue;
begin
  Result := FScaleQueue;
end;

procedure TScalesQueue.SetScaleQueue(ScaleQueue: TScaleQueue);
begin
  FScaleQueue.Assign(ScaleQueue);
end;

function TScalesQueue.SetInGetOut(Sender: TComponent; AInput: Double): Double;
begin
  Result := FScaleQueue.SetInGetOut(Sender, AInput);
end;

function TScalesQueue.SetOutGetIn(Sender: TComponent; AOutput: Double): Double;
begin
  Result := FScaleQueue.SetOutGetIn(Sender, AOutput);
end;

////////////////////////////////////////////////////////////////////////////////
// TScaleProcessor implementation
////////////////////////////////////////////////////////////////////////////////
constructor TScaleProcessor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TScaleProcessor.Destroy;
var
  c: Longint;
begin
  for c := 0 to High(FQueueItems) do
    TScaleQueueItem(FQueueItems[c]).RemoveScaleProcessor;
  SetLength(FQueueItems, 0);
  inherited Destroy;
end;

procedure TScaleProcessor.AddQueueItem(QueueItem: TCollectionItem);
var
  found: Boolean;
  c: Longint;
begin
  if not (QueueItem is TScaleQueueItem) then
    raise Exception.Create(SinvalidType);

  found := False;
  for c := 0 to High(FQueueItems) do
    if FQueueItems[c] = QueueItem then
    begin
      found := True;
      Break;
    end;

  if not found then
  begin
    c := Length(FQueueItems);
    SetLength(FQueueItems, c + 1);
    FQueueItems[c] := QueueItem;
  end;
end;

procedure TScaleProcessor.DelQueueItem(QueueItem: TCollectionItem);
var
  found: Boolean;
  c, h: Longint;
begin
  found := False;
  h := High(FQueueItems);
  for c := 0 to h do
    if FQueueItems[c] = QueueItem then
    begin
      found := True;
      Break;
    end;

  if found then
  begin
    FQueueItems[c] := FQueueItems[h];
    SetLength(FQueueItems, h);
  end;
end;

function TScaleProcessor.SetInGetOut(Sender: TComponent; Input: Double): Double;
begin
  Result := Input;
end;

function TScaleProcessor.SetOutGetIn(Sender: TComponent; Output: Double): Double;
begin
  Result := Output;
end;

procedure TScaleProcessor.SetInput(Value: Double);
begin
  FValueIn := Value;
end;

procedure TScaleProcessor.SetOutput(Value: Double);
begin
  FValueIn := SetOutGetIn(Self, Value);
end;

function TScaleProcessor.GetOutput: Double;
begin
  Result := SetInGetOut(Self, FValueIn);
end;

end.

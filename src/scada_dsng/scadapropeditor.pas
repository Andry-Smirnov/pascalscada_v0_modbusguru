{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Implementação dos editores de algumas propriedades de componentes
            do PascalSCADA.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Implements some property editors of PascalSCADA.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - Replaced ProtocolDriver with TagAssistant. (unit, properties and classes)
  07/2013 - Implemented Double-Click for the assistants.
  07/2013 - Replaced PlcNumber with BitMapTagAssistant. (unit, properties and classes)
  07/2013 - Replaced PlcBlock with BLockTagAssistant. (unit, properties and classes)
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
{$ENDIF}
unit scadapropeditor;

{$I ../common/delphiver.inc}

interface

uses
  {$IF defined(WIN32) or defined(WIN64) OR defined(WINCE)}
  Windows,
  {$ELSE}
  Unix,
  {$IFEND}
  Classes, SysUtils, SerialPort, PLCBlockElement, PLCStruct, Tag,
  bitmappertagassistant, blockstructtagassistant, ProtocolDriver,
  {$IFDEF FPC}
  PropEdits,
  ComponentEditors,
  typinfo,
  {$ELSE}
  Types,
  //Delphi 6 ou superior
  {$IF defined(DELPHI6_UP)}
  DesignIntf, DesignEditors,
  {$ELSE}
    //demais versoes do delphi
    DsgnIntf,
  {$IFEND}
  {$ENDIF}
  PLCNumber,
  plcstructstring,
  comptagedt,
  fpexprpars;

type
  //: Property editor of TSerialPortDriver.COMPort property.
  TPortPropertyEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: AnsiString; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: AnsiString); override;
    // somente para windows
    {$IFDEF MSWINDOWS}
    function GetPortas: string;
    {$ENDIF}
  end;

  {$IFDEF PORTUGUES}
  //: Editor da propriedade TPLCBlockElement.Index
  {$ELSE}
  //: Property editor of TPLCBlockElement.Index property.
  {$ENDIF}

  { TIntegerExpressionPropertyEditor }

  TIntegerExpressionPropertyEditor = class(TIntegerProperty)
  private
    procedure SetValue(const Index: Integer; const NewValue: Int64);
  protected
    procedure RegisterExpressionVariables(const AIndex: Integer; var Parser: TFPExpressionParser); virtual;
  public
    function GetPropType(Index: Integer): PTypeInfo;
    procedure SetValue(const NewValue: AnsiString); override;
  end;

  { TElementIndexPropertyEditor }

  TElementIndexPropertyEditor = class(TIntegerExpressionPropertyEditor)
  protected
    procedure RegisterExpressionVariables(const i: Integer; var Parser: TFPExpressionParser); override;
  public
    procedure GetValues(Proc: TGetStrProc); override;
    function GetAttributes: TPropertyAttributes; override;
  end;

  { TTagAddressPropertyEditor }

  TTagAddressPropertyEditor = class(TIntegerExpressionPropertyEditor)
  protected
    procedure RegisterExpressionVariables(const AIndex: Integer; var Parser: TFPExpressionParser); override;
  end;

  { TWinControlBoundsEditor }

  TWinControlBoundsEditor = class(TIntegerExpressionPropertyEditor)
    procedure RegisterExpressionVariables(const AIndex: Integer; var Parser: TFPExpressionParser); override;
  end;

  {$IFNDEF FPC}
  //: @exclude
  TDefaultComponentEditor = class(TComponentEditor);
  {$ENDIF}

  {$IFDEF PORTUGUES}
  {:
    Editor de componente base para todos os demais editores que irão inserir
    componentes na aplicação.
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
    Base class of Component editor for all component editors that will insert
    others componentes in application.
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TInsertTagsOnFormComponentEditor = class(TDefaultComponentEditor)
  protected
    procedure AddTagInEditor(Tag: TTag);
    function CreateComponent(tagclass: TComponentClass): TComponent;
    function GetTheOwner: TComponent; virtual;
  end;

  {$IFDEF PORTUGUES}
  {:
  Editor de componente TagBuilder.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @seealso(TInsertTagsOnFormComponentEditor)
  }
  {$ELSE}
  {:
  TagBuilder component editor tool.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @seealso(TInsertTagsOnFormComponentEditor)
  }
  {$ENDIF}
  TProtocolDriverComponentEditor = class(TInsertTagsOnFormComponentEditor)
  private
    procedure OpenTagBuilder;
  protected
    function GetTheOwner: TComponent; override;
  public
    procedure ExecuteVerb(Index: Longint); override;
    function GetVerb(Index: Longint): AnsiString; override;
    function GetVerbCount: Longint; override;
    procedure Edit; override;
    function ProtocolDriver: TProtocolDriver; virtual;
  end;

  {$IFDEF PORTUGUES}
  {:
  Editor de componente BitMapper. Mapeia bits de um tag.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @seealso(TInsertTagsOnFormComponentEditor)
  }
  {$ELSE}
  {:
  BitMapper component editor tool. Map bits of a tag.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @seealso(TInsertTagsOnFormComponentEditor)
  }
  {$ENDIF}
  TTagBitMapperComponentEditor = class(TInsertTagsOnFormComponentEditor)
  private
    procedure OpenBitMapper;
  protected
    function GetTheOwner: TComponent; override;
  public
    procedure ExecuteVerb(Index: Longint); override;
    function GetVerb(Index: Longint): AnsiString; override;
    function GetVerbCount: Longint; override;
    procedure Edit; override;
  end;

  {$IFDEF PORTUGUES}
  {:
  Editor de componente BlockElementMapper. Mapeia elementos de um tag bloco.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @seealso(TInsertTagsOnFormComponentEditor)
  }
  {$ELSE}
  {:
  BlockElementMapper component editor tool. Map elements of a tag block.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @seealso(TInsertTagsOnFormComponentEditor)
  }
  {$ENDIF}
  TBlockElementMapperComponentEditor = class(TInsertTagsOnFormComponentEditor)
  private
    procedure OpenElementMapper;
  protected
    function GetTheOwner: TComponent; override;
  public
    procedure ExecuteVerb(Index: Longint); override;
    {$if declared(has_customhints)}
    function GetCustomHint: AnsiString; override;
    {$ifend}
    function GetVerb(Index: Longint): AnsiString; override;
    function GetVerbCount: Longint; override;
    procedure Edit; override;
  end;


procedure ChangeComponentTag(Sender: TObject);


implementation


uses
  PLCBlock,
  PLCTagNumber,
  PLCString,
  RtlConsts,
  FormEditingIntf,
  Controls
  {$IFDEF WINDOWS}
  , Registry
  {$ENDIF}
  ;

procedure ChangeComponentTag(Sender: TObject);
var
  ASelected: TPersistentSelectionList;
  AForm: TfrmTComponentTagEditor;
begin
  ASelected := TPersistentSelectionList.Create;
  try
    if Assigned(GlobalDesignHook) then
    begin
      GlobalDesignHook.GetSelection(ASelected);
      if (ASelected.Count = 1) and (ASelected.Items[0] is TComponent) then
      begin
        AForm := TfrmTComponentTagEditor.Create(nil);
        try
          AForm.Label1.Caption := Format('Set new value %s.Tag', [TComponent(ASelected.Items[0]).Name]);
          AForm.Edit1.Text := IntToStr(TComponent(ASelected.Items[0]).Tag);
          AForm.Edit1.SelectAll;
          if AForm.ShowModal = mrOk then
          begin
            TComponent(ASelected.Items[0]).Tag := AForm.Value;
            GlobalDesignHook.Modified(ASelected.Items[0]);
          end;
        finally
          FreeAndNil(AForm);
        end;
      end;
    end;
  finally
    FreeAndNil(ASelected);
  end;
end;

function TPortPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  if (GetComponent(0) is TSerialPortDriver)
    and (GetComponent(0) as TSerialPortDriver).AcceptAnyPortName = False then
    Result := [paValueList
      {$IFDEF FPC}
      , paPickList
      {$ELSE}
      {$IFDEF DELPHI2005_UP}
      , paReadOnly,
      paValueEditable
      {$ENDIF}
      {$ENDIF}
      ]
  else
    Result := inherited GetAttributes;
end;

function TPortPropertyEditor.GetValue: AnsiString;
begin
  Result := GetStrValue;
end;

procedure TPortPropertyEditor.GetValues(Proc: TGetStrProc);
{$IF defined(WIN32) or defined(WIN64)}
var
  i: LongInt;
  DcbString: AnsiString;
  ComName: AnsiString;
  D: DCB;
  Str: TStringList;
begin
{ com essa abordagem é possive listar as portas COM acima de 10 e tambem
  portas Virtuais que tem nomes diferentes " qualquer nome ele lista"}

  // cria a primeira porta
  Proc('(none)');
  // cria uma lista de portas "ativas" do sistema
  Str := Tstringlist.Create;
  // copia as portas da função Get portas
  Str.CommaText := GetPortas ;
  // faz uma contagem de portas ativas
  for i := 0 to Str.Count-1 do
  begin
    // transfere os valores para a listagem COMport
    Proc(Str.ValueFromIndex[i]);
  end;
  // libera a lista
  Str.Free;
  {
  Proc('(none)');
  for i := 1 to 255 do
  begin
    ComName := 'COM' + IntToStr(i);
    DcbString := ComName + ': baud=1200 parity=N data=8 stop=1';
    if BuildCommDCB(PChar(DcbString),D) then
      Proc(ComName);
  end;
}
end;
{$IFEND}
{$IFDEF UNIX}
var
   c: LongInt;
   d: LongInt;
   PName: AnsiString;

   function PortDirPrefix:AnsiString;
   begin
     if Assigned(GetComponent(0)) and (GetComponent(0) is TSerialPortDriver) then
       Result:=(GetComponent(0) as TSerialPortDriver).DevDir
     else
       Result:='/dev/';
   end;

begin
   Proc('(none)');
   for d := 0 to High(PortPrefix) do
      {$IFDEF SunOS}
      for c := Ord('a') to ord('z') do
      begin
         PName := PortPrefix[d] + Char(c);
      {$ELSE}
      for c := 0 to 255 do
      begin
         PName := PortPrefix[d] + IntToStr(c);
      {$ENDIF}
         if FileExists(PortDirPrefix + PName) then // Added DevDir property.
            Proc(PName);
      end;
end;
{$ENDIF}
{$IFDEF WINCE}
begin
  //ToDo
end;
{$ENDIF}


procedure TPortPropertyEditor.SetValue(const Value: AnsiString);
begin
  SetStrValue(Value);
  if GetComponent(0) is TSerialPortDriver then
    TSerialPortDriver(GetComponent(0)).Active := False;
end;

////////////////////////////////////////////////////////////////////////////////
//TIntegerExpressionPropertyEditor
////////////////////////////////////////////////////////////////////////////////
procedure TIntegerExpressionPropertyEditor.RegisterExpressionVariables(const AIndex: Integer; var Parser: TFPExpressionParser);
begin
  //virtual method.
end;

function TIntegerExpressionPropertyEditor.GetPropType(Index: Integer): PTypeInfo;
begin
  Result := GetInstProp[Index].PropInfo^.PropType;
end;

procedure TIntegerExpressionPropertyEditor.SetValue(const NewValue: AnsiString);
var
  Aux: Longint;
  Parser: TFPExpressionParser;
  Rt: TFPExpressionResult;
  i: Integer;
begin
  if (not (NewValue[1] in ['+', '-', '*', '/'])) and TryStrToInt(NewValue, Aux) then
    inherited SetValue(NewValue)
  else
  begin
    Parser := TFPExpressionParser.Create(nil);
    try
      Parser.BuiltIns := [bcMath];
      for i := 0 to PropCount - 1 do
      begin
        RegisterExpressionVariables(i, Parser);

        if (NewValue[1] = '+') or (NewValue[1] = '-') or (NewValue[1] = '*') or (NewValue[1] = '/') then
        begin
          Parser.Expression := OrdValueToVisualValue(GetOrdValueAt(i)) + NewValue;
        end
        else
          Parser.Expression := NewValue;
        Rt := Parser.Evaluate;
        case Rt.ResultType of
          rtInteger: SetValue(i, Parser.AsInteger);
          rtFloat: SetValue(i, Trunc(Parser.AsFloat));
        end;
      end;
    finally
      FreeAndNil(Rt);
    end;
  end;
end;

procedure TIntegerExpressionPropertyEditor.SetValue(const Index: Integer; const NewValue: Int64);

  procedure Error(const Args: array of const);
  begin
    raise EPropertyError.CreateResFmt(@SOutOfRange, Args);
  end;

var
  L: Int64;
begin
  L := NewValue;
  with GetTypeData(GetPropType(Index))^ do
    if OrdType = otULong then
      begin   // unsigned compare and reporting needed
        if (L < Cardinal(MinValue)) or (L > Cardinal(MaxValue)) then
        begin
          // bump up to Int64 to get past the %d in the format string
          Error([Int64(Cardinal(MinValue)), Int64(Cardinal(MaxValue))]);
          Exit;
        end;
      end
    else if (L < MinValue) or (L > MaxValue) then
      begin
        Error([MinValue, MaxValue]);
        Exit;
      end;
  with GetInstProp[Index] do
    SetOrdProp(Instance, PropInfo, NewValue);
  Modified;
end;

////////////////////////////////////////////////////////////////////////////////
//TElementIndexPropertyEditor
////////////////////////////////////////////////////////////////////////////////
function TElementIndexPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  if (GetComponent(0) is TPLCBlockElement)
    or (GetComponent(0) is TPLCStructString) then
    Result := [paValueList, paMultiSelect];
end;

procedure TElementIndexPropertyEditor.RegisterExpressionVariables(const i: Integer; var Parser: TFPExpressionParser);
begin
  if Assigned(Parser) then
  begin
    //unregister all possible registered variables.
    Parser.Identifiers.Clear;

    if (GetComponent(i) is TPLCBlockElement) then
    begin
      //register only if the property is not being edited,
      //to avoid circular references.
      if (LowerCase(GetPropInfo^.Name) <> 'tag') then
        Parser.Identifiers.AddIntegerVariable('tag', (GetComponent(i) as TPLCBlockElement).Tag);
    end;

    if (GetComponent(i) is TPLCStructString) then
    begin
      //register only if the property is not being edited,
      //to avoid circular references.
      if (LowerCase(GetPropInfo^.Name) <> 'tag') then
        Parser.Identifiers.AddIntegerVariable('tag', (GetComponent(i) as TPLCStructString).Tag);
    end;
  end;
end;

procedure TElementIndexPropertyEditor.GetValues(Proc: TGetStrProc);
var
  i: Longint;
begin
  if (GetComponent(0) is TPLCBlockElement)
    and (TPLCBlockElement(GetComponent(0)).PLCBlock <> nil) then
    for i := 0 to Longint(TPLCBlockElement(GetComponent(0)).PLCBlock.Size) - 1 do
    begin
      Proc(IntToStr(i));
    end;
end;

////////////////////////////////////////////////////////////////////////////////
//TTagAddressPropertyEditor
////////////////////////////////////////////////////////////////////////////////
procedure TTagAddressPropertyEditor.RegisterExpressionVariables(const AIndex: Integer; var Parser: TFPExpressionParser);
var
  PropertyName: string;
begin
  if Assigned(Parser) then
  begin
    //unregister all possible registered variables.
    Parser.Identifiers.Clear;

    PropertyName := LowerCase(GetPropInfo^.Name);

    if (GetComponent(AIndex) is TPLCTagNumber) then
    begin
      //register only if the property is not being edited,
      //to avoid circular references.
      if (PropertyName <> 'plcrack') then
        Parser.Identifiers.AddIntegerVariable('plcrack', (GetComponent(AIndex) as TPLCTagNumber).plcrack);

      if (PropertyName <> 'plcslot') then
        Parser.Identifiers.AddIntegerVariable('plcslot', (GetComponent(AIndex) as TPLCTagNumber).plcslot);

      if (PropertyName <> 'plcstation') then
        Parser.Identifiers.AddIntegerVariable('plcstation', (GetComponent(AIndex) as TPLCTagNumber).plcstation);

      if (PropertyName <> 'memfile_db') then
        Parser.Identifiers.AddIntegerVariable('memfile_db', (GetComponent(AIndex) as TPLCTagNumber).memfile_db);

      if (PropertyName <> 'memaddress') then
        Parser.Identifiers.AddIntegerVariable('memaddress', (GetComponent(AIndex) as TPLCTagNumber).memaddress);

      if (PropertyName <> 'memsubelement') then
        Parser.Identifiers.AddIntegerVariable('memsubelement', (GetComponent(AIndex) as TPLCTagNumber).memsubelement);

      if (PropertyName <> 'memreadfunction') then
        Parser.Identifiers.AddIntegerVariable('memreadfunction', (GetComponent(AIndex) as TPLCTagNumber).memreadfunction);

      if (PropertyName <> 'memwritefunction') then
        Parser.Identifiers.AddIntegerVariable('memwritefunction', (GetComponent(AIndex) as TPLCTagNumber).memwritefunction);

      if (PropertyName <> 'tag') then
        Parser.Identifiers.AddIntegerVariable('tag', (GetComponent(AIndex) as TPLCTagNumber).Tag);
    end;

    if (GetComponent(AIndex) is TPLCBlock) then
    begin
      //register only if the property is not being edited,
      //to avoid circular references.
      if (PropertyName <> 'plcrack') then
        Parser.Identifiers.AddIntegerVariable('plcrack', (GetComponent(AIndex) as TPLCBlock).plcrack);

      if (PropertyName <> 'plcslot') then
        Parser.Identifiers.AddIntegerVariable('plcslot', (GetComponent(AIndex) as TPLCBlock).plcslot);

      if (PropertyName <> 'plcstation') then
        Parser.Identifiers.AddIntegerVariable('plcstation', (GetComponent(AIndex) as TPLCBlock).plcstation);

      if (PropertyName <> 'memfile_db') then
        Parser.Identifiers.AddIntegerVariable('memfile_db', (GetComponent(AIndex) as TPLCBlock).memfile_db);

      if (PropertyName <> 'memaddress') then
        Parser.Identifiers.AddIntegerVariable('memaddress', (GetComponent(AIndex) as TPLCBlock).memaddress);

      if (PropertyName <> 'memsubelement') then
        Parser.Identifiers.AddIntegerVariable('memsubelement', (GetComponent(AIndex) as TPLCBlock).memsubelement);

      if (PropertyName <> 'memreadfunction') then
        Parser.Identifiers.AddIntegerVariable('memreadfunction', (GetComponent(AIndex) as TPLCBlock).memreadfunction);

      if (PropertyName <> 'memwritefunction') then
        Parser.Identifiers.AddIntegerVariable('memwritefunction', (GetComponent(AIndex) as TPLCBlock).memwritefunction);

      if (PropertyName <> 'tag') then
        Parser.Identifiers.AddIntegerVariable('tag', (GetComponent(AIndex) as TPLCBlock).Tag);
    end;

    if (GetComponent(AIndex) is TPLCString) then
    begin
      //register only if the property is not being edited,
      //to avoid circular references.
      if (PropertyName <> 'plcrack') then
        Parser.Identifiers.AddIntegerVariable('plcrack', (GetComponent(AIndex) as TPLCString).plcrack);

      if (PropertyName <> 'plcslot') then
        Parser.Identifiers.AddIntegerVariable('plcslot', (GetComponent(AIndex) as TPLCString).plcslot);

      if (PropertyName <> 'plcstation') then
        Parser.Identifiers.AddIntegerVariable('plcstation', (GetComponent(AIndex) as TPLCString).plcstation);

      if (PropertyName <> 'memfile_db') then
        Parser.Identifiers.AddIntegerVariable('memfile_db', (GetComponent(AIndex) as TPLCString).memfile_db);

      if (PropertyName <> 'memaddress') then
        Parser.Identifiers.AddIntegerVariable('memaddress', (GetComponent(AIndex) as TPLCString).memaddress);

      if (PropertyName <> 'memsubelement') then
        Parser.Identifiers.AddIntegerVariable('memsubelement', (GetComponent(AIndex) as TPLCString).memsubelement);

      if (PropertyName <> 'memreadfunction') then
        Parser.Identifiers.AddIntegerVariable('memreadfunction', (GetComponent(AIndex) as TPLCString).memreadfunction);

      if (PropertyName <> 'memwritefunction') then
        Parser.Identifiers.AddIntegerVariable('memwritefunction', (GetComponent(AIndex) as TPLCString).memwritefunction);

      if (PropertyName <> 'tag') then
        Parser.Identifiers.AddIntegerVariable('tag', (GetComponent(AIndex) as TPLCString).Tag);
    end;
  end;
end;

{ TWinControlBoundsEditor }

procedure TWinControlBoundsEditor.RegisterExpressionVariables(const AIndex: Integer; var Parser: TFPExpressionParser);
var
  PropertyName: string;
begin
  if Assigned(Parser) then
  begin
    //unregister all possible registered variables.
    Parser.Identifiers.Clear;

    PropertyName := LowerCase(GetPropInfo^.Name);

    if (GetComponent(AIndex) is TWinControl) then
    begin
      //register only if the property is not being edited,
      //to avoid circular references.
      if (PropertyName <> 'width') then
        Parser.Identifiers.AddIntegerVariable('width', (GetComponent(AIndex) as TWinControl).Width);

      if (PropertyName <> 'height') then
        Parser.Identifiers.AddIntegerVariable('height', (GetComponent(AIndex) as TWinControl).Height);

      if (PropertyName <> 'left') then
        Parser.Identifiers.AddIntegerVariable('left', (GetComponent(AIndex) as TWinControl).Left);

      if (PropertyName <> 'top') then
        Parser.Identifiers.AddIntegerVariable('top', (GetComponent(AIndex) as TWinControl).Top);

      if (PropertyName <> 'tag') then
        Parser.Identifiers.AddIntegerVariable('tag', (GetComponent(AIndex) as TWinControl).Tag);
    end;
  end;
end;

///////////////////////////////////////
//editor base para os demais editores.
///////////////////////////////////////
procedure TInsertTagsOnFormComponentEditor.AddTagInEditor(Tag: TTag);
{$IFDEF FPC}
var
  Hook: TPropertyEditorHook;
{$ENDIF}
begin
  {$IFDEF FPC}
  Hook:=nil;
  if not GetHook(Hook) then Exit;
  Hook.PersistentAdded(Tag,false);
  Modified;
  {$ELSE}
  Designer.Modified;
  {$ENDIF}
end;

function TInsertTagsOnFormComponentEditor.CreateComponent(tagclass: TComponentClass): TComponent;
begin
  {$IFDEF FPC}
  Result := tagclass.Create(GetTheOwner);
  {$ELSE}
  Result := Designer.CreateComponent(tagclass, GetTheOwner, 0, 0, 0, 0);
  {$ENDIF}
end;

function TInsertTagsOnFormComponentEditor.GetTheOwner: TComponent;
begin
  Result := nil;
end;

///////////////////////////////////////
//editor TAG BUILDER
///////////////////////////////////////

function TProtocolDriverComponentEditor.GetTheOwner: TComponent;
begin
  Result := ProtocolDriver.Owner;
end;

procedure TProtocolDriverComponentEditor.OpenTagBuilder;
begin
  ProtocolDriver.OpenTagEditor(@AddTagInEditor, @CreateComponent);
end;

procedure TProtocolDriverComponentEditor.ExecuteVerb(Index: Longint);
begin
  if Index = 0 then
    OpenTagBuilder();
end;

function TProtocolDriverComponentEditor.GetVerb(Index: Longint): AnsiString;
begin
  if Index = 0 then
    Result := 'Tag Builder';
end;

function TProtocolDriverComponentEditor.GetVerbCount: Longint;
begin
  if ProtocolDriver.HasTabBuilderEditor then
    Result := 1
  else
    Result := 0;
end;

procedure TProtocolDriverComponentEditor.Edit;
begin
  inherited Edit;
  OpenTagBuilder();
end;

function TProtocolDriverComponentEditor.ProtocolDriver: TProtocolDriver;
begin
  Result := TProtocolDriver(GetComponent);
end;

///////////////////////////////////////////////////////////////////////////////
// BIT MAPPER
///////////////////////////////////////////////////////////////////////////////

function TTagBitMapperComponentEditor.GetTheOwner: TComponent;
begin
  Result := GetComponent().Owner;
end;

procedure TTagBitMapperComponentEditor.OpenBitMapper;
begin
  if (GetComponent is TPLCNumberMappable) then
    TPLCNumberMappable(GetComponent).OpenBitMapper(@AddTagInEditor, @CreateComponent);
end;

procedure TTagBitMapperComponentEditor.ExecuteVerb(Index: Longint);
begin
  if Index = 0 then
    OpenBitMapper();
end;

function TTagBitMapperComponentEditor.GetVerb(Index: Longint): AnsiString;
begin
  if Index = 0 then
    Result := 'Map bits';
end;

function TTagBitMapperComponentEditor.GetVerbCount: Longint;
begin
  Result := 1;
end;

procedure TTagBitMapperComponentEditor.Edit;
begin
  inherited Edit;
  OpenBitMapper();
end;

///////////////////////////////////////////////////////////////////////////////
// ELEMENT BLOCK MAPPER
///////////////////////////////////////////////////////////////////////////////

procedure TBlockElementMapperComponentEditor.OpenElementMapper;
begin
  if (GetComponent is TPLCBlock) then
    TPLCBlock(GetComponent).MapElements(@AddTagInEditor, @CreateComponent);
end;

function TBlockElementMapperComponentEditor.GetTheOwner: TComponent;
begin
  Result := GetComponent().Owner;
end;

procedure TBlockElementMapperComponentEditor.ExecuteVerb(Index: Longint);
begin
  if Index = 0 then
    OpenElementMapper();
end;

{$if declared(has_customhints)}
function TBlockElementMapperComponentEditor.GetCustomHint: AnsiString;
begin
  if GetComponent is TPLCStruct then
  begin
    Result := Result + 'Structure size in bytes:' + IntToStr(TPLCStruct(GetComponent).Size);
    Exit;
  end;

  if GetComponent is TPLCBlock then
  begin
    Result := Result + 'Number of elements: ' + IntToStr(TPLCBlock(GetComponent).Size);
    Exit;
  end;
end;
{$ifend}

function TBlockElementMapperComponentEditor.GetVerb(Index: Longint): AnsiString;
begin
  Result := 'Unknow option...';
  if Index = 0 then
  begin
    if GetComponent is TPLCStruct then
    begin
      Result := 'Map structure items...';
      Exit;
    end;
    if GetComponent is TPLCBlock then
    begin
      Result := 'Map block elements...';
      Exit;
    end;
  end;
end;

function TBlockElementMapperComponentEditor.GetVerbCount: Longint;
begin
  Result := 0;
  if GetComponent is TPLCBlock then
    Result := 1;
end;

procedure TBlockElementMapperComponentEditor.Edit;
begin
  inherited Edit;
  OpenElementMapper();
end;

// For Windows only, it retrieves the value directly from the Windows registry.
// The advantage is that it's possible to list ports above COM9 and
// also virtual ports with different names (any name).
{$IFDEF MSWINDOWS}
function TPortPropertyEditor.GetPortas: string;
var
  ARegistry: TRegistry;
  AList: TStringList;
  AValue: TStringList;
  i: Integer;
begin  GetPortas
  AList := TStringList.Create;
  AValue := TStringList.Create;
  ARegistry := TRegistry.Create;
  try
    // especifica o caminho do ARegistry
    ARegistry.RootKey := HKEY_LOCAL_MACHINE;
    // abre o caminho do ARegistry onde tem as portas seriais
    ARegistry.OpenKeyReadOnly('\HARDWARE\DEVICEMAP\SERIALCOMM');
    // recolhe valores do ARegistry  ( dados no ARegistry)
    ARegistry.GetValueNames(AList);
    // conforme a quantidade de portas que estavam no ARegistry
    for i := 0 to AList.Count - 1 do
      // adicionar no AValue os dados recolhido na string
      AValue.Add(PChar(ARegistry.ReadString(AList[i])));
    // the returned AValue separated by semicolons
    Result := AValue.CommaText;
  finally
    ARegistry.Free;
    AList.Free;
    AValue.Free;
  end;
end;
{$ENDIF}

end.

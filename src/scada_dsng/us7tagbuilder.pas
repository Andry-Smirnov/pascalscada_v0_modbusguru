{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Unit do formul�rio TagBuilder para a familia de drivers da Siemens.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Unit of Siemens TagBuilder wizard.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
unit us7tagbuilder;

interface

uses
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Spin, tag
  {$IFDEF FPC}
  , LCLIntf, LResources
  {$ENDIF}
  ;

type
  {$IFDEF PORTUGUES}
  //: Rotina de checagem de nomes.
  {$ELSE}
  //: Name check routine.
  {$ENDIF}
  TCheckNames = procedure(Sender: TObject; NewName: Ansistring; var AcceptNewName: Boolean) of object;

  {$IFDEF PORTUGUES}
  {:
  Editor de bits de um item da estrtura.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Bit editor of a structure item.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TTagBitItemEditor = class(TPanel)
  private
    FTagName: Ansistring;
    FStartBit: Longint;
    FEndBit: Longint;
    FCheckNames: TCheckNames;
    fedtItemName: TEdit;
    lblStart: TLabel;
    lblEnd: TLabel;
    spinStart: TSpinEdit;
    spinEnd: TSpinEdit;
    btnDel: TButton;
    FOnDelClick: TNotifyEvent;
    procedure SetTagName(NewName: Ansistring);
    procedure SetStartBit(BitIndex: Longint);
    procedure SetEndBit(BitIndex: Longint);
  private
    procedure SpinEditChanges(Sender: TObject);
    procedure edtItemNameExit(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property TagName: Ansistring read FTagName write SetTagName;
    property StartBit: Longint read FStartBit write SetStartBit;
    property EndBit: Longint read FEndBit write SetEndBit;
    property OnCheckNames: TCheckNames read FCheckNames write FCheckNames;
    property OnDelClick: TNotifyEvent read FOnDelClick write FOnDelClick;
  end;

  {$IFDEF PORTUGUES}
  {:
  Editor de itens da estrtura.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Structure item editor.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TS7TagItemEditor = class(TPanel)
  private
    FTagName: Ansistring;
    FTagType: TTagType;
    FTagScan: TRefreshTime;
    FSwapWords: Boolean;
    FSwapBytes: Boolean;
    FSkip: Boolean;
    edtItemName: TEdit;
    cmbItemType: TComboBox;
    spinScan: TSpinEdit;
    optSwapBytes: TCheckBox;
    optSwapWords: TCheckBox;
    optSkip: TCheckBox;
    btnUp: TButton;
    btnDown: TButton;
    btnDel: TButton;
    btnBits: TButton;
    TagArea: TPanel;
    BitArea: TPanel;
    FCheckNames: TCheckNames;
    FUpClickEvent: TNotifyEvent;
    FDownClickEvent: TNotifyEvent;
    FDelClickEvent: TNotifyEvent;
    FBitsClickEvent: TNotifyEvent;
    BitList: TList;
    DelTimer: TTimer;
    DelList: TList;
    FOnTypeChange: TNotifyEvent;
    FOnSkipChange: TNotifyEvent;
    FOnDelBitItem: TNotifyEvent;
    procedure SetTagName(NewName: Ansistring);
    procedure SetTagType(NewType: TTagType);
    procedure SetTagScan(NewScan: TRefreshTime);
    procedure SetSwapBytes(Swap: Boolean);
    procedure SetSwapWords(Swap: Boolean);
    procedure SetSkipTag(Skip: Boolean);
  private
    procedure CheckNames(Sender: TObject; NewName: Ansistring; var AcceptNewName: Boolean);
    procedure btnClick(Sender: TObject);
    procedure optChange(Sender: TObject);
    procedure edtItemNameExit(Sender: TObject);
    procedure DelBitItem(Sender: TObject);
  private
    function GetBitCount: Longint;
    function GetBit(Index: Longint): TTagBitItemEditor;
    procedure OnDelTimer(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PopulateCombo;

    procedure EnableTagType(ToEnable: Boolean);
    procedure EnableScanRate(ToEnable: Boolean);
    procedure EnableSwapBytes(ToEnable: Boolean);
    procedure EnableSwapWords(ToEnable: Boolean);

    property Bit[Index: Longint]: TTagBitItemEditor read GetBit;
  published
    property BitCount: Longint read GetBitCount;
    function AddBit: TTagBitItemEditor;
    procedure DelBit(Index: Longint);
    function GetIndex(TagBitEditor: TTagBitItemEditor): Longint;
    function AcceptName(TheName: Ansistring): Boolean;
  published
    property TagName: Ansistring read FTagName write SetTagName;
    property TagType: TTagType read FTagType write SetTagType;
    property TagScan: TRefreshTime read FTagScan write SetTagScan;
    property SwapBytes: Boolean read FSwapBytes write SetSwapBytes;
    property SwapWords: Boolean read FSwapWords write SetSwapWords;
    property SkipTag: Boolean read FSkip write SetSkipTag;
    property OnCheckNames: TCheckNames read FCheckNames write FCheckNames;
    property OnUpClick: TNotifyEvent read FUpClickEvent write FUpClickEvent;
    property OnDownClickEvent: TNotifyEvent read FDownClickEvent write FDownClickEvent;
    property OnDelClickEvent: TNotifyEvent read FDelClickEvent write FDelClickEvent;
    property OnBitsClickEvent: TNotifyEvent read FBitsClickEvent write FBitsClickEvent;
    property OnTypeChange: TNotifyEvent read FOnTypeChange write FOnTypeChange;
    property OnSkipChange: TNotifyEvent read FOnSkipChange write FOnSkipChange;
    property OnDelBitItem: TNotifyEvent read FOnDelBitItem write FOnDelBitItem;
  end;

  {$IFDEF PORTUGUES}
  {:
  Tag builder da familia de protocolos da Siemens.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  TagBuilder of siemens protocol family.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}

  { TfrmS7TagBuilder }

  TfrmS7TagBuilder = class(TForm)
    BlockName: TEdit;
    lblDBNumber1: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    PageControl1: TPageControl;
    spinFinalDBNumber: TSpinEdit;
    TabSheet1: TTabSheet;
    MemoryArea: TRadioGroup;
    Panel3: TPanel;
    Panel4: TPanel;
    PLCAddress: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    PLCStation: TSpinEdit;
    PLCSlot: TSpinEdit;
    PLCRack: TSpinEdit;
    grptagtype: TGroupBox;
    optPLCTagNumber: TRadioButton;
    optPLCBlock: TRadioButton;
    optplcStruct: TRadioButton;
    TabSheet4: TTabSheet;
    Panel5: TPanel;
    lblNumItems: TLabel;
    spinNumItens: TSpinEdit;
    spinStartAddress: TSpinEdit;
    lblStartAddress: TLabel;
    spinDBNumber: TSpinEdit;
    lblDBNumber: TLabel;
    ScrollBox1: TScrollBox;
    lblBlockType: TLabel;
    BlockType: TComboBox;
    Button1: TButton;
    BlockScan: TSpinEdit;
    lblBlockScan: TLabel;
    BlockSwapBytes: TCheckBox;
    BlockSwapWords: TCheckBox;
    StructScan: TSpinEdit;
    lblStructScan: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Timer1: TTimer;
    btnCancel: TButton;
    btnBack: TButton;
    btnNext: TButton;
    btnFinish: TButton;
    lblBlockName: TLabel;
    procedure btnFinishClick(Sender: TObject);
    procedure MemoryAreaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var AAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnBitsClick(Sender: TObject);
    procedure spinDBNumberChange(Sender: TObject);
    procedure spinFinalDBNumberChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TabSheet1Show(Sender: TObject);
    procedure BlockTypeChange(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure PageControl1Changing(Sender: TObject; var AllowChange: Boolean);
    procedure TabSheet4Show(Sender: TObject);
    procedure optPLCBlockClick(Sender: TObject);
    procedure spinStartAddressChange(Sender: TObject);
  private
    OldPage: TTabSheet;
    FItemId: Longint;
    FStructureModified: Boolean;
    TagList: TList;
    ItemsToDel: TList;
    procedure UpdateStatusAndBlockName;
    procedure UpdateStructItems;
    procedure SkipChanged(Sender: TObject);
    procedure StructItemTypeChanged(Sender: TObject);
    procedure CheckNames(Sender: TObject; NewName: Ansistring; var AcceptNewName: Boolean);
    function GetStructItemsCount: Longint;
    function GetStructItem(Index: Longint): TS7TagItemEditor;
    function GetStructureSizeInBytes: Longint;
    function GetRealStartOffset: Longint;
    function GetRealEndOffset: Longint;
    function GetStartOffset: Longint;
    function GetEndOffset: Longint;
    function AtLeastOneItemIsValid: Boolean;
    procedure BitItemDeleted(Sender: TObject);
    procedure UpdateFlagDBandVStrucItemName;
  public
    destructor Destroy; override;
    function GetTagType: Longint;
    function CurBlockType: TTagType;
    function GetTheLastItemOffset: Longint;
    property StructItemsCount: Longint read GetStructItemsCount;
    property StructItem[Index: Longint]: TS7TagItemEditor read GetStructItem;
    property StructureSizeInBytes: Longint read GetStructureSizeInBytes;
    property RealStartOffset: Longint read GetRealStartOffset;
    property RealEndOffset: Longint read GetRealEndOffset;
    property StartOffset: Longint read GetStartOffset;
    property EndOffset: Longint read GetEndOffset;
  end;

var
  frmS7TagBuilder: TfrmS7TagBuilder;


implementation


uses
  ubitmapper, hsstrings;


{$IFDEF FPC }
  {$IF defined(FPC) AND (FPC_FULLVERSION >= 20400) }
  {$R us7tagbuilder.lfm}
  {$IFEND}
{$ELSE}
  {$R *.dfm}

{$ENDIF}

///////////////////////////////////////////////////////////////////////////////
//TagBitEditor
///////////////////////////////////////////////////////////////////////////////
constructor TTagBitItemEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alTop;
  BevelOuter := bvNone;
  Height := 25;
  Caption := '';

  fedtItemName := TEdit.Create(Self);
  with fedtItemName do
  begin
    Parent := Self;
    Left := 16;
    Top := 2;
    Width := 137;
    OnExit := @edtItemNameExit;
  end;

  lblStart := TLabel.Create(Self);
  with lblStart do
  begin
    Parent := Self;
    AutoSize := False;
    Alignment := taRightJustify;
    Layout := tlCenter;
    Caption := 'Start Bit';
    Height := 21;
    Width := 49;
    Left := 168;
    Top := 2;
  end;

  lblEnd := TLabel.Create(Self);
  with lblEnd do
  begin
    Parent := Self;
    AutoSize := False;
    Alignment := taRightJustify;
    Layout := tlCenter;
    Caption := 'End Bit';
    Height := 21;
    Width := 49;
    Left := 272;
    Top := 2;
  end;

  spinStart := TSpinEdit.Create(Self);
  with spinStart do
  begin
    Parent := Self;
    Height := 22;
    Left := 224;
    MaxValue := 31;
    MinValue := 0;
    Top := 2;
    Width := 41;
    OnChange := @SpinEditChanges;
  end;

  spinEnd := TSpinEdit.Create(Self);
  with spinEnd do
  begin
    Parent := Self;
    Height := 22;
    Left := 328;
    MaxValue := 31;
    MinValue := 0;
    Top := 2;
    Width := 41;
    OnChange := @SpinEditChanges;
  end;

  btnDel := TButton.Create(Self);
  with btnDel do
  begin
    Parent := Self;
    Caption := 'Del';
    Height := 22;
    Left := 503;
    Top := 3;
    Width := 33;
    OnClick := @btnDelClick;
  end;
end;

destructor TTagBitItemEditor.Destroy;
begin
  fedtItemName.Destroy;
  lblStart.Destroy;
  lblEnd.Destroy;
  spinStart.Destroy;
  spinEnd.Destroy;
  btnDel.Destroy;
  inherited Destroy;
end;

procedure TTagBitItemEditor.SetTagName(NewName: Ansistring);
var
  Accept: Boolean;
begin
  Accept := True;
  if Assigned(FCheckNames) then
    FCheckNames(Self, NewName, Accept);

  if Accept then
  begin
    FTagName := NewName;
    fedtItemName.Text := NewName;
    fedtItemName.Modified := False;
  end;
end;

procedure TTagBitItemEditor.SetStartBit(BitIndex: Longint);
begin
  FStartBit := BitIndex;
  spinStart.Value := BitIndex;

  if FStartBit > FEndBit then
  begin
    FEndBit := BitIndex;
    spinEnd.Value := FEndBit;
  end;
end;

procedure TTagBitItemEditor.SetEndBit(BitIndex: Longint);
begin
  FEndBit := BitIndex;
  spinEnd.Value := BitIndex;

  if FStartBit > FEndBit then
  begin
    FStartBit := BitIndex;
    spinStart.Value := FStartBit;
  end;
end;

procedure TTagBitItemEditor.SpinEditChanges(Sender: TObject);
begin
  if (Sender = spinStart) then
  begin
    FStartBit := spinStart.Value;
    if (spinStart.Value > spinEnd.Value) then
    begin
      spinEnd.Value := spinStart.Value;
      FEndBit := spinEnd.Value;
    end;
  end;

  if (Sender = spinEnd) then
  begin
    FEndBit := spinEnd.Value;
    if (spinStart.Value > spinEnd.Value) then
    begin
      spinStart.Value := spinEnd.Value;
      FStartBit := spinStart.Value;
    end;
  end;
end;

procedure TTagBitItemEditor.edtItemNameExit(Sender: TObject);
var
  Accept: Boolean;
begin
  if not fedtItemName.Modified then Exit;
  Accept := True;
  if Assigned(FCheckNames) then
    FCheckNames(Self, fedtItemName.Text, Accept);

  if Accept then
  begin
    fedtItemName.Modified := False;
    FTagName := fedtItemName.Text;
  end
  else
  begin
    fedtItemName.Text := FTagName;
    fedtItemName.Modified := False;
  end;
end;

procedure TTagBitItemEditor.btnDelClick(Sender: TObject);
begin
  if Assigned(FOnDelClick) then
    FOnDelClick(Self);
end;

///////////////////////////////////////////////////////////////////////////////
//S7TagEditor
///////////////////////////////////////////////////////////////////////////////

constructor TS7TagItemEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alTop;
  BevelOuter := bvNone;
  Height := 30;
  Caption := '';
  Top := $0FFFFFFF;

  BitList := TList.Create;
  DelList := TList.Create;
  DelTimer := TTimer.Create(Self);
  DelTimer.Enabled := False;
  DelTimer.Interval := 10;
  DelTimer.OnTimer := @OnDelTimer;

  FSkip := False;
  FSwapWords := False;
  FSwapBytes := False;
  FTagType := pttDefault;

  TagArea := TPanel.Create(Self);
  with TagArea do
  begin
    Parent := Self;
    Align := alTop;
    BevelOuter := bvNone;
    Height := 25;
    Caption := '';
  end;

  BitArea := TPanel.Create(Self);
  with BitArea do
  begin
    Parent := Self;
    Align := alClient;
    BevelOuter := bvNone;
    Top := 31;
    Height := 0;
    Caption := '';
  end;

  edtItemName := TEdit.Create(Self);
  with edtItemName do
  begin
    Parent := TagArea;
    Height := 21;
    Width := 152;
    Left := 2;
    Top := 2;
    OnExit := @edtItemNameExit;
  end;

  //corre��o
  //desenha um bot�o que n�o faz nada
  //para forcar a perda de foco por tab do
  //edit anterior

  //FIX
  //draw a button that does nothing
  //to force the focus lost using of the previos edit
  btnUp := TButton.Create(Self);
  with btnUp do
  begin
    Parent := TagArea;
    Height := 22;
    Left := 155;
    Top := 3;
    Width := 4;
  end;

  cmbItemType := TComboBox.Create(Self);
  with cmbItemType do
  begin
    Parent := TagArea;
    Left := 160;
    Top := 2;
    Style := csDropDownList;
    Width := 78;
    OnChange := @optChange;
    OnEnter := @edtItemNameExit;
    OnClick := @edtItemNameExit;
    OnDropDown := @edtItemNameExit;
  end;

  spinScan := TSpinEdit.Create(Self);
  with spinScan do
  begin
    Parent := TagArea;
    Height := 22;
    Left := 238;
    MaxValue := $7FFFFFFF;
    MinValue := 0;
    Value := 1000;
    Top := 2;
    Width := 55;
    OnChange := @optChange;
  end;

  optSwapBytes := TCheckBox.Create(Self);
  with optSwapBytes do
  begin
    Parent := TagArea;
    Caption := 'Bytes';
    Height := 17;
    Left := 297;
    Top := 4;
    Width := 50;
    Checked := FSwapBytes;
    Enabled := False;
    OnClick := @optChange;
  end;

  optSwapWords := TCheckBox.Create(Self);
  with optSwapWords do
  begin
    Parent := TagArea;
    Caption := 'Words';
    Height := 17;
    Left := 347;
    Top := 4;
    Width := 51;
    Checked := FSwapWords;
    Enabled := False;
    OnClick := @optChange;
  end;

  optSkip := TCheckBox.Create(Self);
  with optSkip do
  begin
    Parent := TagArea;
    Caption := '';
    Height := 17;
    Left := 409;
    Top := 4;
    Width := 15;
    Checked := FSkip;
    OnClick := @optChange;
  end;

  btnUp := TButton.Create(Self);
  with btnUp do
  begin
    Parent := TagArea;
    Caption := 'UP';
    Height := 22;
    Left := 437;
    Top := 3;
    Width := 33;
    OnClick := @btnClick;
  end;

  btnDown := TButton.Create(Self);
  with btnDown do
  begin
    Parent := TagArea;
    Caption := 'Down';
    Height := 22;
    Left := 470;
    Top := 3;
    Width := 33;
    OnClick := @btnClick;
  end;

  btnDel := TButton.Create(Self);
  with btnDel do
  begin
    Parent := TagArea;
    Caption := 'Del';
    Height := 22;
    Left := 503;
    Top := 3;
    Width := 33;
    OnClick := @btnClick;
  end;

  btnBits := TButton.Create(Self);
  with btnBits do
  begin
    Parent := TagArea;
    Caption := 'Bits';
    Height := 22;
    Left := 536;
    Top := 3;
    Width := 28;
    OnClick := @btnClick;
  end;
end;

destructor TS7TagItemEditor.Destroy;
var
  i: Longint;
begin
  for i := GetBitCount - 1 downto 0 do
    DelBit(i);
  BitList.Destroy;
  inherited Destroy;
end;

procedure TS7TagItemEditor.PopulateCombo;
begin
  with cmbItemType do
  begin
    Items.Clear;
    Items.Clear;
    Items.Add('pttDefault');
    Items.Add('pttShortInt');
    Items.Add('pttByte');
    Items.Add('pttSmallInt');
    Items.Add('pttWord');
    Items.Add('pttLongInt');
    Items.Add('pttDWord');
    Items.Add('pttFloat');
    ItemIndex := 0;
  end;
end;

procedure TS7TagItemEditor.EnableTagType(ToEnable: Boolean);
begin
  cmbItemType.Enabled := ToEnable;
end;

procedure TS7TagItemEditor.EnableScanRate(ToEnable: Boolean);
begin
  spinScan.Enabled := ToEnable;
end;

procedure TS7TagItemEditor.EnableSwapBytes(ToEnable: Boolean);
begin
  optSwapBytes.Enabled := ToEnable;
  optSwapBytes.Checked := ToEnable;
end;

procedure TS7TagItemEditor.EnableSwapWords(ToEnable: Boolean);
begin
  optSwapWords.Enabled := ToEnable;
  optSwapWords.Checked := ToEnable;
end;

function TS7TagItemEditor.GetBitCount: Longint;
begin
  Result := BitList.Count;
end;

function TS7TagItemEditor.GetBit(Index: Longint): TTagBitItemEditor;
begin
  Result := TTagBitItemEditor(BitList.Items[Index]);
end;

function TS7TagItemEditor.AddBit: TTagBitItemEditor;
var
  ATagBitEditor: TTagBitItemEditor;
begin
  ATagBitEditor := TTagBitItemEditor.Create(Self);
  ATagBitEditor.Parent := BitArea;
  ATagBitEditor.OnDelClick := @DelBitItem;
  ATagBitEditor.OnCheckNames := @CheckNames;
  ATagBitEditor.Top := BitList.Count * ATagBitEditor.Height + 1;
  BitList.Add(ATagBitEditor);
  Self.Height := TagArea.Height + (ATagBitEditor.Height * BitList.Count) + 3;
  Result := ATagBitEditor;
end;

procedure TS7TagItemEditor.OnDelTimer(Sender: TObject);
var
  c: Longint;
  i: Longint;
begin
  for c := DelList.Count - 1 downto 0 do
  begin
    i := GetIndex(TTagBitItemEditor(DelList.Items[c]));
    DelBit(i);
    DelList.Delete(c);
  end;
  DelTimer.Enabled := False;

  if Assigned(FOnDelBitItem) then
    FOnDelBitItem(Self);
end;

procedure TS7TagItemEditor.DelBit(Index: Longint);
var
  ATagBitEditor: TTagBitItemEditor;
begin
  ATagBitEditor := TTagBitItemEditor(BitList.Items[Index]);
  BitList.Remove(ATagBitEditor);
  Self.Height := TagArea.Height + (ATagBitEditor.Height * BitList.Count);
  ATagBitEditor.Destroy;
end;

function TS7TagItemEditor.GetIndex(TagBitEditor: TTagBitItemEditor): Longint;
begin
  Result := BitList.IndexOf(TagBitEditor);
end;

function TS7TagItemEditor.AcceptName(TheName: Ansistring): Boolean;
var
  Accept1: Boolean;
  Accept2: Boolean;
begin
  Accept1 := True;
  Accept2 := True;

  //checa o nome com os bits...
  //check the new name with bit names.
  CheckNames(Self, TheName, Accept1);

  //checa o nome com os demais itens...
  //check the new name with other struct item names.
  if Accept1 and Assigned(FCheckNames) then
    FCheckNames(Self, TheName, Accept2);

  //Ok caso passe nos dois testes...
  //Ok if everything is ok.
  Result := Accept1 and Accept2;
end;

procedure TS7TagItemEditor.SetTagName(NewName: Ansistring);
var
  Accept: Boolean;
begin
  Accept := True;
  if Assigned(FCheckNames) then
    FCheckNames(Self, NewName, Accept);

  if Accept then
  begin
    FTagName := NewName;
    edtItemName.Text := NewName;
    edtItemName.Modified := False;
  end;
end;

procedure TS7TagItemEditor.SetTagType(NewType: TTagType);
begin
  FTagType := NewType;
  case NewType of
    pttDefault: cmbItemType.ItemIndex := 0;
    pttShortInt: cmbItemType.ItemIndex := 1;
    pttByte: cmbItemType.ItemIndex := 2;
    pttSmallInt: cmbItemType.ItemIndex := 3;
    pttWord: cmbItemType.ItemIndex := 4;
    pttLongInt: cmbItemType.ItemIndex := 5;
    pttDWord: cmbItemType.ItemIndex := 6;
    pttFloat: cmbItemType.ItemIndex := 7;
  end;
  optChange(cmbItemType);
end;

procedure TS7TagItemEditor.SetTagScan(NewScan: TRefreshTime);
begin
  FTagScan := NewScan;
  spinScan.Value := FTagScan;
end;

procedure TS7TagItemEditor.SetSwapBytes(Swap: Boolean);
begin
  FSwapBytes := Swap;
  optSwapBytes.Checked := FSwapBytes;
end;

procedure TS7TagItemEditor.SetSwapWords(Swap: Boolean);
begin
  FSwapWords := Swap;
  optSwapWords.Checked := FSwapWords;
end;

procedure TS7TagItemEditor.SetSkipTag(Skip: Boolean);
begin
  FSkip := Skip;
  optSkip.Checked := FSkip;
  edtItemName.Enabled := not FSkip;
end;

procedure TS7TagItemEditor.edtItemNameExit(Sender: TObject);
var
  Accept1: Boolean;
  Accept2: Boolean;
  i: Longint;
  OldName: Ansistring;
begin
  if not edtItemName.Modified then Exit;

  Accept1 := True;
  Accept2 := True;

  //checa o nome com os bits...
  //check the new name with bits names.
  CheckNames(Sender, edtItemName.Text, Accept1);

  //checa o nome com os demais itens...
  //check the new name with other struct names.
  if Accept1 and Assigned(FCheckNames) then
    FCheckNames(Self, edtItemName.Text, Accept2);

  //se pelo menos um falhou, volta o nome anterior...
  //to accept the new name, everything must be ok.
  if (Accept1 = True) and (Accept2 = True) then
  begin
    edtItemName.Modified := False;
    OldName := FTagName;
    FTagName := edtItemName.Text;

    //atualiza nome dos bits
    //update the name of the bits.
    for i := 0 to BitCount - 1 do
      TTagBitItemEditor(Bit[i]).TagName := StringReplace(TTagBitItemEditor(Bit[i]).TagName, OldName, FTagName, [rfReplaceAll, rfIgnoreCase]);
  end
  else
  begin
    edtItemName.Text := FTagName;
    edtItemName.Modified := False;
  end;
end;

procedure TS7TagItemEditor.DelBitItem(Sender: TObject);
begin
  if not (Sender is TTagBitItemEditor) then
    Exit;

  if MessageDlg(SDeleteTheItem + (Sender as TTagBitItemEditor).TagName + '"?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    Exit;

  DelList.Add(Sender);
  DelTimer.Enabled := True;
end;

procedure TS7TagItemEditor.optChange(Sender: TObject);
begin
  if Sender = optSwapBytes then
    FSwapBytes := optSwapBytes.Checked;

  if Sender = optSwapWords then
    FSwapWords := optSwapWords.Checked;

  if Sender = optSkip then
  begin
    FSkip := optSkip.Checked;
    edtItemName.Enabled := not FSkip;
    if Assigned(FOnSkipChange) then
      FOnSkipChange(optSkip);
  end;

  if Sender = spinScan then
    FTagScan := spinScan.Value;

  if Sender = cmbItemType then
  begin
    case cmbItemType.ItemIndex of
      0: FTagType := pttDefault;
      1: FTagType := pttShortInt;
      2: FTagType := pttByte;
      3: FTagType := pttSmallInt;
      4: FTagType := pttWord;
      5: FTagType := pttLongInt;
      6: FTagType := pttDWord;
      7: FTagType := pttFloat;
    end;
    case cmbItemType.ItemIndex of
      0,
      1,
      2: begin
        optSwapBytes.Checked := False;
        optSwapBytes.Enabled := False;
        optSwapWords.Checked := False;
        optSwapWords.Enabled := False;
      end;
      3,
      4: begin
        optSwapBytes.Checked := True;
        optSwapBytes.Enabled := True;
      end;
      5,
      6,
      7: begin
        optSwapBytes.Checked := True;
        optSwapBytes.Enabled := True;
        optSwapWords.Checked := True;
        optSwapWords.Enabled := True;
      end;
    end;
    if Assigned(FOnTypeChange) then
      FOnTypeChange(Self);
  end;
end;

//evento chamado pelos bits do tag para verificar seu nome...
//event called by bit itens to check theirs names.
procedure TS7TagItemEditor.CheckNames(Sender: TObject; NewName: Ansistring; var AcceptNewName: Boolean);
var
  i: Longint;
begin
  if (Sender <> Self) and (NewName = TagName) then
  begin
    AcceptNewName := False;
  end
  else
  begin
    for i := 0 to GetBitCount - 1 do
      if (Sender <> Bit[i]) and (Bit[i].TagName = NewName) then
      begin
        AcceptNewName := False;
        Exit;
      end;

    if Assigned(FCheckNames) then
      FCheckNames(Sender, NewName, AcceptNewName);
  end;
end;

procedure TS7TagItemEditor.btnClick(Sender: TObject);
begin
  if (Sender = btnUp) and Assigned(FUpClickEvent) then
    FUpClickEvent(Self);

  if (Sender = btnDown) and Assigned(FDownClickEvent) then
    FDownClickEvent(Self);

  if (Sender = btnBits) and Assigned(FBitsClickEvent) then
    FBitsClickEvent(Self);

  //esta linha tem q ficar por ultimo sempre!!!
  //this condition must be the last ALWAYS!
  if (Sender = btnDel) and Assigned(FDelClickEvent) then
    FDelClickEvent(Self);
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


procedure TfrmS7TagBuilder.MemoryAreaClick(Sender: TObject);
begin
  lblDBNumber.Enabled := False;
  lblDBNumber1.Enabled := False;
  spinDBNumber.Enabled := False;
  spinFinalDBNumber.Enabled := False;
  BlockType.Enabled := False;
  case MemoryArea.ItemIndex of
    0: begin
      lblStartAddress.Caption := SDigitalInputInitialByte;
      BlockType.ItemIndex := 2;
    end;
    1: begin
      lblStartAddress.Caption := SDigitalOutputInitialByte;
      BlockType.ItemIndex := 2;
    end;
    2: begin
      lblStartAddress.Caption := SFlagInitialAddress;
      BlockType.Enabled := optPLCBlock.Checked;
    end;
    3: begin
      lblStartAddress.Caption := SInitialAddressInsideDB;
      lblDBNumber.Enabled := True;
      spinDBNumber.Enabled := True;
      lblDBNumber1.Enabled := True;
      spinFinalDBNumber.Enabled := True;
      BlockType.Enabled := optPLCBlock.Checked;
    end;
    4,
    9: begin
      lblStartAddress.Caption := SCounterInitialAddress;
      BlockType.ItemIndex := 4;
    end;
    5,
    10: begin
      lblStartAddress.Caption := STimerInitialAddress;
      BlockType.ItemIndex := 4;
    end;
    6: begin
      lblStartAddress.Caption := SSMInitialByte;
      BlockType.ItemIndex := 2;
    end;
    7: begin
      lblStartAddress.Caption := SAIWInitialAddress;
      BlockType.ItemIndex := 4;
    end;
    8: begin
      lblStartAddress.Caption := SAQWInitialAddress;
      BlockType.ItemIndex := 4;
    end;
    11: begin
      lblStartAddress.Caption := SPIWInitialAddress;
      BlockType.ItemIndex := 4;
    end;
    12: begin
      lblStartAddress.Caption := SVInitialAddress;
      BlockType.Enabled := optPLCBlock.Checked;
    end;
  end;

  if MemoryArea.ItemIndex <> 3 then
  begin
    spinDBNumber.Value := 1;
    spinFinalDBNumber.Value := 1;
  end;

  BlockTypeChange(Sender);
  UpdateStructItems;
end;

procedure TfrmS7TagBuilder.btnFinishClick(Sender: TObject);
begin
  if (TagList.Count = 0) or (not AtLeastOneItemIsValid) then
    raise Exception.Create(SYouMustHaveAtLeastOneStructureItem);
  if Trim(BlockName.Text) = '' then
    raise Exception.Create(SInvalidBlockName);
end;

procedure TfrmS7TagBuilder.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePageIndex := 0;
  TagList := TList.Create;
  ItemsToDel := TList.Create;
  FStructureModified := False;

  // translated captions
  TabSheet1.Caption := us7tb_tabsheet1_caption;
  PLCAddress.Caption := us7tb_plcaddres_caption;
  MemoryArea.Caption := us7tb_memoryarea_caption;
  grptagtype.Caption := us7tb_grptagtype_caption;
  optPLCTagNumber.Caption := us7tb_optplctagnumber_caption;
  optPLCBlock.Caption := us7tb_optplcblock_caption;
  optplcStruct.Caption := us7tb_optplcstruct_caption;
  lblBlockType.Caption := us7tb_lblblocktype_caption;
  BlockSwapBytes.Caption := us7tb_blockswapbytes_caption;
  BlockSwapWords.Caption := us7tb_blockswapwords_caption;
  lblBlockScan.Caption := us7tb_blockscan_caption;
  lblStructScan.Caption := us7tb_structscan_caption;

  TabSheet4.Caption := us7tb_tabsheet4_caption;
  lblNumItems.Caption := us7tb_lblnumitems_caption;
  lblStartAddress.Caption := us7tb_startaddress_caption;
  lblBlockName.Caption := us7tb_lblblockname_caption;
  lblDBNumber.Caption := us7tb_lblDBNumber_caption;
  lblDBNumber1.Caption := us7tb_lblDBNumber1_caption;
  Label28.Caption := us7tb_label28_caption;
  Label29.Caption := us7tb_label29_caption;
  Label30.Caption := us7tb_label30_caption;
  Label32.Caption := us7tb_label31_caption;
  Label32.Caption := us7tb_label32_caption;
end;

procedure TfrmS7TagBuilder.FormShow(Sender: TObject);
begin
  MemoryAreaClick(Sender);
  optPLCBlockClick(Sender);
end;

procedure TfrmS7TagBuilder.FormClose(Sender: TObject; var AAction: TCloseAction);
begin

end;

procedure TfrmS7TagBuilder.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  //onclose query
end;

procedure TfrmS7TagBuilder.Button1Click(Sender: TObject);
var
  ATag: TS7TagItemEditor;
  LastItem: TS7TagItemEditor;
begin
  Inc(FItemId);

  ATag := TS7TagItemEditor.Create(Self);
  ATag.Parent := ScrollBox1;
  ATag.PopulateCombo;
  ATag.OnCheckNames := @CheckNames;
  ATag.OnUpClick := @btnUpClick;
  ATag.OnDownClickEvent := @btnDownClick;
  ATag.OnDelClickEvent := @btnDelClick;
  ATag.OnBitsClickEvent := @btnBitsClick;
  ATag.OnTypeChange := @StructItemTypeChanged;
  ATag.OnSkipChange := @SkipChanged;
  ATag.OnDelBitItem := @BitItemDeleted;
  ATag.TagScan := 1000;
  ATag.TagType := pttDefault;
  ATag.SwapBytes := False;
  ATag.SwapWords := False;
  if TagList.Count > 0 then
  begin
    LastItem := TS7TagItemEditor(TagList.Items[TagList.Count - 1]);
    ATag.Top := LastItem.Top + LastItem.Height;
  end
  else
  begin
    ATag.Top := 0;
  end;

  ATag.EnableScanRate(optPLCTagNumber.Checked);
  case MemoryArea.ItemIndex of
    0,
    1,
    6: begin
      ATag.TagType := pttByte;
    end;
    4,
    5,
    7..11: begin
      ATag.TagType := pttWord;
    end;
    2,
    3,
    12: begin
      // does nothing...
    end;
  end;

  ATag.EnableTagType((not optPLCBlock.Checked) and (MemoryArea.ItemIndex in [2, 3, 12]));

  TagList.Add(ATag);

  while not ATag.AcceptName('StructItem' + IntToStr(FItemId)) do
    Inc(FItemId);
  ATag.TagName := 'StructItem' + IntToStr(FItemId);
  UpdateStatusAndBlockName;
  FStructureModified := True;
end;

procedure TfrmS7TagBuilder.btnUpClick(Sender: TObject);
var
  Idx: Longint;
  PriorTop: Longint;
  ActualTop: Longint;
  Prior: TS7TagItemEditor;
begin
  if not (Sender is TS7TagItemEditor) then Exit;

  Idx := TagList.IndexOf(Sender);
  if Idx > 0 then
  begin
    FStructureModified := True;
    Prior := TS7TagItemEditor(TagList.Items[Idx - 1]);

    PriorTop := Prior.Top;
    ActualTop := (Sender as TS7TagItemEditor).Top;

    TagList.Exchange(Idx - 1, Idx);

    (Sender as TS7TagItemEditor).Top := PriorTop;
    (Sender as TS7TagItemEditor).TabOrder := Prior.TabOrder;
    Prior.Top := ActualTop;
  end;
  UpdateStatusAndBlockName;
end;

procedure TfrmS7TagBuilder.btnDownClick(Sender: TObject);
var
  Idx: Longint;
  NextTop: Longint;
  ActualTop: Longint;
  ANext: TS7TagItemEditor;
begin
  if not (Sender is TS7TagItemEditor) then Exit;

  Idx := TagList.IndexOf(Sender);
  if (Idx <> -1) and (Idx < (TagList.Count - 1)) then
  begin
    FStructureModified := True;
    ANext := TS7TagItemEditor(TagList.Items[Idx + 1]);

    NextTop := ANext.Top;
    ActualTop := (Sender as TS7TagItemEditor).Top;

    TagList.Exchange(Idx + 1, Idx);

    (Sender as TS7TagItemEditor).Top := NextTop;
    ANext.TabOrder := (Sender as TS7TagItemEditor).TabOrder;
    ANext.Top := ActualTop;
  end;
  UpdateStatusAndBlockName;
end;

procedure TfrmS7TagBuilder.btnDelClick(Sender: TObject);
begin
  if ItemsToDel.IndexOf(Sender) = -1 then
    if MessageDlg(SRemoveaStructItemCalled + TS7TagItemEditor(Sender).TagName + '"?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      FStructureModified := True;
      ItemsToDel.Add(Sender);
      Timer1.Enabled := True;
    end;
end;

procedure TfrmS7TagBuilder.btnBitsClick(Sender: TObject);
var
  BitForm: TfrmBitMapper;
  ATagBitEditor: TTagBitItemEditor;
  S7TagEditor: TS7TagItemEditor;
  BitNum: Longint;
  ByteNum: Longint;
  WordNum: Longint;
  StartBit: Longint;
  EndBit: Longint;
  CurBit: Longint;

  procedure UpdateNumbers;
  begin
    BitNum := CurBit;
    if BitForm.BitNameStartsFrom1.Checked then
      Inc(BitNum);

    ByteNum := CurBit div 8;
    if BitForm.ByteNameStartsFrom1.Checked then
      Inc(ByteNum);

    WordNum := CurBit div 16;
    if BitForm.WordNameStartsFrom1.Checked then
      Inc(WordNum);
  end;

  function GetNewTagBitName: Ansistring;
  var
    N: Ansistring;
  begin
    N := IntToStr(BitNum);
    Result := BitForm.edtNamePattern.Text;
    Result := StringReplace(Result, '%b', N, [rfReplaceAll]);

    N := IntToStr(ByteNum);
    Result := StringReplace(Result, '%B', N, [rfReplaceAll]);

    N := IntToStr(WordNum);
    Result := StringReplace(Result, '%w', N, [rfReplaceAll]);

    N := (Sender as TS7TagItemEditor).TagName;
    Result := StringReplace(Result, '%t', N, [rfReplaceAll]);
  end;

begin
  if not (Sender is TS7TagItemEditor) then Exit;

  S7TagEditor := (Sender as TS7TagItemEditor);

  BitForm := TfrmBitMapper.Create(Self);
  try
    if BitForm.ShowModal = mrOk then
    begin
      FStructureModified := True;
      StartBit := 31 - BitForm.StringGrid1.Selection.Right;
      EndBit := 31 - BitForm.StringGrid1.Selection.Left;
      CurBit := StartBit;
      if BitForm.EachBitAsTag.Checked then
      begin
        while CurBit <= EndBit do
        begin
          UpdateNumbers;
          ATagBitEditor := S7TagEditor.AddBit;
          ATagBitEditor.TagName := GetNewTagBitName;
          ATagBitEditor.EndBit := CurBit;
          ATagBitEditor.StartBit := CurBit;
          Inc(CurBit);
        end;
      end
      else
      begin
        UpdateNumbers;
        ATagBitEditor := S7TagEditor.AddBit;
        ATagBitEditor.TagName := GetNewTagBitName;
        ATagBitEditor.EndBit := EndBit;
        ATagBitEditor.StartBit := StartBit;
      end;
    end;
  finally
    BitForm.Destroy;
  end;
end;

procedure TfrmS7TagBuilder.spinDBNumberChange(Sender: TObject);
begin
  if spinDBNumber.Value > spinFinalDBNumber.Value then
    spinFinalDBNumber.Value := spinDBNumber.Value;
end;

procedure TfrmS7TagBuilder.spinFinalDBNumberChange(Sender: TObject);
begin
  if spinDBNumber.Value > spinFinalDBNumber.Value then
    spinDBNumber.Value := spinFinalDBNumber.Value;
end;

procedure TfrmS7TagBuilder.SkipChanged(Sender: TObject);
begin
  FStructureModified := True;
  UpdateStatusAndBlockName;
end;

procedure TfrmS7TagBuilder.StructItemTypeChanged(Sender: TObject);
begin
  if MemoryArea.ItemIndex in [2, 3, 12] then
  begin
    if not FStructureModified then
    begin
      UpdateFlagDBandVStrucItemName;
      FStructureModified := False;
    end;
    UpdateStatusAndBlockName;
  end;
end;

destructor TfrmS7TagBuilder.Destroy;
var
  i: Longint;
  j: Longint;
begin
  for i := TagList.Count - 1 downto 0 do
  begin
    for j := TS7TagItemEditor(TagList.Items[i]).BitCount - 1 downto 0 do
    begin
      TS7TagItemEditor(TagList.Items[i]).DelBit(j);
    end;
    TS7TagItemEditor(TagList.Items[i]).Destroy;
    TagList.Delete(i);
  end;
  TagList.Destroy;
  ItemsToDel.Destroy;
  inherited Destroy;
end;

function TfrmS7TagBuilder.GetTagType: Longint;
begin
{
0  Digital Inputs, S7 200/300/400/1200        Inputs, Entradas)        @cell( 1
1  Digital Outputs, S7 200/300/400/1200       Outputs, Saidas)         @cell( 2
2  Flags, M's, S7 200/300/400/1200            Flags and M's)           @cell( 3
3  DB's, S7 300/400/1200                      DB and VM no S7-200 )    @cell( 4
4  Counter, S7 300/400/1200                   Counter, S7 300/400)     @cell( 5
5  Timer, S7 300/400/1200                     Timer, S7 300/400)       @cell( 6
6  Special Memory, SM, S7-200                 SM, S7-200)              @cell( 7
7  Analog Input, S7-200                       AIW, S7-200)             @cell( 8
8  Analog output, S7-200                      AQW, S7-200)             @cell( 9
9  Counter, S7-200                            Counter, S7-200)         @cell(10
10 Timer, S7-200                              Timer, S7-200)           @cell(11
11 Analog Input (PIW), S7-300/400/1200        PIW, S7 300/400)         @cell(12
12 VB, VW, VD, S7-200
}
  Result := 0;
  if MemoryArea.ItemIndex in [0..11] then
    Result := MemoryArea.ItemIndex + 1
  else if MemoryArea.ItemIndex = 12 then
    Result := 4;
end;

procedure TfrmS7TagBuilder.CheckNames(Sender: TObject; NewName: Ansistring; var AcceptNewName: Boolean);
var
  i: Longint;
  j: Longint;
begin
  for i := 0 to TagList.Count - 1 do
  begin
    if TObject(TagList.Items[i]) = Sender then
      Continue;
    if TS7TagItemEditor(TagList.Items[i]).TagName = NewName then
    begin
      AcceptNewName := False;
      Exit;
    end;
    for j := 0 to TS7TagItemEditor(TagList.Items[i]).BitCount - 1 do
    begin
      if TS7TagItemEditor(TagList.Items[i]).Bit[j] = Sender then
        Continue;
      if TTagBitItemEditor(TS7TagItemEditor(TagList.Items[i]).Bit[j]).TagName = NewName then
      begin
        AcceptNewName := False;
        Exit;
      end;
    end;
  end;
  FStructureModified := True;
end;

function TfrmS7TagBuilder.GetStructItemsCount: Longint;
begin
  Result := TagList.Count;
end;

function TfrmS7TagBuilder.GetStructItem(Index: Longint): TS7TagItemEditor;
begin
  Result := TS7TagItemEditor(TagList.Items[Index]);
end;

function TfrmS7TagBuilder.GetStructureSizeInBytes: Longint;
var
  TypeSize: Longint;
  CurItem: Longint;
begin
  if optPLCBlock.Checked then
  begin
    case BlockType.ItemIndex of
      3..4: begin
        TypeSize := 2;
      end;
      5..7: begin
        TypeSize := 4;
      end;
      else
      begin
        TypeSize := 1;
      end;
    end;
    Result := TagList.Count * TypeSize;
  end
  else
  begin
    Result := 0;
    for CurItem := 0 to TagList.Count - 1 do
    begin
      with TS7TagItemEditor(TagList.Items[CurItem]) do
      begin
        case TagType of
          pttSmallInt,
          pttWord: TypeSize := 2;
          pttLongInt,
          pttDWord,
          pttFloat: TypeSize := 4;
          else
            TypeSize := 1
        end;
      end;
      Inc(Result, TypeSize);
    end;
  end;
end;

function TfrmS7TagBuilder.GetRealStartOffset: Longint;
var
  CurItem: Longint;
  CurTagType: TTagType;
begin
  if AtLeastOneItemIsValid then
  begin
    if MemoryArea.ItemIndex in [4, 5, 9, 10] then
      Result := spinStartAddress.Value * 2
    else
      Result := spinStartAddress.Value;

    for CurItem := 0 to TagList.Count - 1 do
      with TS7TagItemEditor(TagList.Items[CurItem]) do
      begin
        if optPLCBlock.Checked then
        begin
          CurTagType := CurBlockType;
        end
        else
          CurTagType := TagType;

        if not SkipTag then
          Break
        else
        begin
          case CurTagType of
            pttDefault,
            pttShortInt,
            pttByte:    Inc(Result, 1);
            pttSmallInt,
            pttWord:    Inc(Result, 2);
            pttLongInt,
            pttDWord,
            pttFloat:   Inc(Result, 4);
          end;
        end;
      end;
  end
  else
    Result := -1;
end;

function TfrmS7TagBuilder.GetRealEndOffset: Longint;
var
  CurItem: Longint;
  CurTagType: TTagType;
begin
  if AtLeastOneItemIsValid then
  begin
    Result := EndOffset;
    for CurItem := TagList.Count - 1 downto 0 do
      with TS7TagItemEditor(TagList.Items[CurItem]) do
      begin
        if optPLCBlock.Checked then
        begin
          CurTagType := CurBlockType;
        end
        else
          CurTagType := TagType;

        if not SkipTag then
          Break
        else
        begin
          case CurTagType of
            pttDefault,
            pttShortInt,
            pttByte:     Dec(Result, 1);
            pttSmallInt,
            pttWord:     Dec(Result, 2);
            pttLongInt,
            pttDWord,
            pttFloat:    Dec(Result, 4);
          end;
        end;
      end;
  end
  else
    Result := -1;
end;

function TfrmS7TagBuilder.GetTheLastItemOffset: Longint;
var
  CurItem: Longint;
  CurTagType: TTagType;
begin
  if AtLeastOneItemIsValid then
  begin
    Result := EndOffset;
    for CurItem := TagList.Count - 1 downto 0 do
      with TS7TagItemEditor(TagList.Items[CurItem]) do
      begin
        if optPLCBlock.Checked then
        begin
          CurTagType := CurBlockType;
        end
        else
          CurTagType := TagType;

        case CurTagType of
          pttSmallInt,
          pttWord:   Dec(Result, 1);
          pttLongInt,
          pttDWord,
          pttFloat:  Dec(Result, 3);
        end;
        if not SkipTag then
          Break;
      end;
  end
  else
    Result := -1;
end;

function TfrmS7TagBuilder.GetStartOffset: Longint;
begin
  if MemoryArea.ItemIndex in [4, 5, 9, 10] then
    Result := (spinStartAddress.Value * 2)
  else
    Result := spinStartAddress.Value;
end;

function TfrmS7TagBuilder.GetEndOffset: Longint;
begin
  if MemoryArea.ItemIndex in [4, 5, 9, 10] then
    Result := (spinStartAddress.Value * 2) + (spinNumItens.Value * StructureSizeInBytes) - 1
  else
    Result := spinStartAddress.Value + (spinNumItens.Value * StructureSizeInBytes) - 1;
end;

function TfrmS7TagBuilder.AtLeastOneItemIsValid: Boolean;
var
  CurItem: Longint;
begin
  Result := False;
  for CurItem := 0 to TagList.Count - 1 do
    with TS7TagItemEditor(TagList.Items[CurItem]) do
      if not SkipTag then
      begin
        Result := True;
        Break;
      end;
end;

function TfrmS7TagBuilder.CurBlockType: TTagType;
begin
  case BlockType.ItemIndex of
    1: Result := pttShortInt;
    2: Result := pttByte;
    3: Result := pttSmallInt;
    4: Result := pttWord;
    5: Result := pttLongInt;
    6: Result := pttDWord;
    7: Result := pttFloat;
    else
      Result := pttDefault;
  end;
end;

procedure TfrmS7TagBuilder.BitItemDeleted(Sender: TObject);
begin
  FStructureModified := True;
end;

procedure TfrmS7TagBuilder.UpdateFlagDBandVStrucItemName;
var
  AName: Ansistring;
  AName2: Ansistring;
  CurType: TTagType;
begin
  if TagList.Count <= 0 then Exit;

  if MemoryArea.ItemIndex = 2 then
    AName := 'M%s'
  else if MemoryArea.ItemIndex = 3 then
    AName := 'DB%d_DB%s'
  else
    AName := 'V%s';

  if optPLCBlock.Checked then
    CurType := CurBlockType
  else
    CurType := TS7TagItemEditor(TagList.Items[0]).TagType;

  case CurType of
    pttDefault,
    pttShortInt,
    pttByte:  AName2 := 'B';
    pttSmallInt,
    pttWord:  AName2 := 'W';
    pttLongInt,
    pttDWord,
    pttFloat: AName2 := 'D';
  end;

  if MemoryArea.ItemIndex = 3 then
    AName := Format(AName, [spinDBNumber.Value, AName2])
  else
    AName := Format(AName, [AName2]) + '%a';

  with TS7TagItemEditor(TagList.Items[0]) do
  begin
    TagName := AName;
  end;
end;

procedure TfrmS7TagBuilder.Timer1Timer(Sender: TObject);
var
  i: Longint;
begin
  for i := ItemsToDel.Count - 1 downto 0 do
  begin
    TagList.Remove(ItemsToDel.Items[i]);
    TS7TagItemEditor(ItemsToDel.Items[i]).Destroy;
    ItemsToDel.Delete(i);
  end;
  Timer1.Enabled := False;
  UpdateStatusAndBlockName;
  FStructureModified := (TagList.Count <> 0);
end;

procedure TfrmS7TagBuilder.TabSheet1Show(Sender: TObject);
begin
  btnBack.Enabled := False;
  btnFinish.Enabled := False;
  btnNext.Enabled := True;
end;

procedure TfrmS7TagBuilder.BlockTypeChange(Sender: TObject);
begin
  if BlockType.ItemIndex in [0..2] then
  begin
    BlockSwapBytes.Checked := False;
    BlockSwapWords.Checked := False;
    BlockSwapBytes.Enabled := False;
    BlockSwapWords.Enabled := False;
  end;
  if BlockType.ItemIndex in [3..4] then
  begin
    BlockSwapBytes.Checked := optPLCBlock.Checked;
    BlockSwapWords.Checked := False;
    BlockSwapBytes.Enabled := optPLCBlock.Checked;
    BlockSwapWords.Enabled := False;
  end;
  if BlockType.ItemIndex in [5..7] then
  begin
    BlockSwapBytes.Checked := optPLCBlock.Checked;
    BlockSwapWords.Checked := optPLCBlock.Checked;
    BlockSwapBytes.Enabled := optPLCBlock.Checked;
    BlockSwapWords.Enabled := optPLCBlock.Checked;
  end;
  UpdateStatusAndBlockName;
end;

procedure TfrmS7TagBuilder.UpdateStructItems;
var
  i: Longint;
  toEnableScan: Boolean;
  toEnableType: Boolean;
  toEnableSwap: Boolean;
begin
  toEnableScan := optPLCTagNumber.Checked;
  toEnableType := (not optPLCBlock.Checked) and (MemoryArea.ItemIndex in [2, 3, 12]);
  toEnableSwap := (not optPLCBlock.Checked);

  for i := 0 to TagList.Count - 1 do
    with TS7TagItemEditor(TagList.Items[i]) do
    begin
      EnableScanRate(toEnableScan);
      EnableSwapBytes(toEnableSwap);
      EnableSwapWords(toEnableSwap);
      case MemoryArea.ItemIndex of
        0,
        1,
        6: begin
          TagType := pttByte;
        end;
        4,
        5,
        7..11: begin
          TagType := pttWord;
        end;
      end;
      EnableTagType(toEnableType);
    end;
end;


procedure TfrmS7TagBuilder.btnNextClick(Sender: TObject);
var
  CurItem: Longint;
  Nome: Ansistring;
  Nome2: Ansistring;
begin
  if (FStructureModified = False) and
    (MessageDlg('Do you want initialize the structure?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    for CurItem := TagList.Count - 1 downto 0 do
      TS7TagItemEditor(TagList.Items[CurItem]).Destroy;

    TagList.Clear;

    Button1Click(Sender);

    case MemoryArea.ItemIndex of
      0,
      1: begin
        if MemoryArea.ItemIndex = 0 then
        begin
          Nome := 'IB%a';
          Nome2 := 'I%a_';
        end
        else
        begin
          Nome := 'QB%a';
          Nome2 := 'Q%a_';
        end;

        with TS7TagItemEditor(TagList.Items[0]) do
        begin
          TagName := Nome;
          for CurItem := 0 to 7 do
            with AddBit do
            begin
              TagName := Nome2 + IntToStr(CurItem);
              StartBit := CurItem;
              EndBit := CurItem;
            end;
        end;
      end;
      2,
      3,
      12: UpdateFlagDBandVStrucItemName;

      4,
      9,
      5,
      10: begin
        if MemoryArea.ItemIndex in [4, 9] then
          Nome := 'C%a'
        else
          Nome := 'T%a';

        with TS7TagItemEditor(TagList.Items[0]) do
        begin
          TagName := Nome;
        end;
      end;
      6: begin
        with TS7TagItemEditor(TagList.Items[0]) do
        begin
          TagName := 'SMB%a';
        end;
      end;
      7,
      8,
      11: begin
        if MemoryArea.ItemIndex = 7 then
          Nome := 'AIW%a'
        else if MemoryArea.ItemIndex = 8 then
          Nome := 'AQW%a'
        else
          Nome := 'PIW%a';

        with TS7TagItemEditor(TagList.Items[0]) do
        begin
          TagName := Nome;
        end;
      end;
    end;

    FStructureModified := False;
  end;
  PageControl1.ActivePage := TabSheet4;
end;

procedure TfrmS7TagBuilder.btnBackClick(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
end;

procedure TfrmS7TagBuilder.PageControl1Changing(Sender: TObject; var AllowChange: Boolean);
begin
  OldPage := PageControl1.ActivePage;
end;

procedure TfrmS7TagBuilder.TabSheet4Show(Sender: TObject);
begin
  btnBack.Enabled := True;
  btnFinish.Enabled := True;
  btnNext.Enabled := False;
end;

procedure TfrmS7TagBuilder.optPLCBlockClick(Sender: TObject);
begin
  lblBlockType.Enabled := optPLCBlock.Checked;
  BlockType.Enabled := optPLCBlock.Checked;
  lblBlockScan.Enabled := optPLCBlock.Checked;
  BlockScan.Enabled := optPLCBlock.Checked;
  BlockSwapBytes.Enabled := optPLCBlock.Checked;
  BlockSwapWords.Enabled := optPLCBlock.Checked;

  lblStructScan.Enabled := optplcStruct.Checked;
  StructScan.Enabled := optplcStruct.Checked;

  lblBlockName.Enabled := optplcStruct.Checked or optPLCBlock.Checked;
  BlockName.Enabled := optplcStruct.Checked or optPLCBlock.Checked;

  MemoryAreaClick(Sender);
end;

procedure TfrmS7TagBuilder.UpdateStatusAndBlockName;
var
  StrBlockName: Ansistring;
  StartType: Ansistring;
  EndType: Ansistring;
  CurItem: Longint;
begin
  if BlockName.Modified then
    Exit;
  case MemoryArea.ItemIndex of
    0: begin
      StrBlockName := 'InputBytes_From_IB%d_to_IB%d';
    end;
    1: begin
      StrBlockName := 'OutputBytes_From_QB%d_to_QB%d';
    end;
    2: begin
      StrBlockName := 'Flags_From_M%s%d_to_M%s%d';
    end;
    3: begin
      StrBlockName := 'DB%d_From_DB%s%d_to_DB%s%d';
    end;
    4,
    9: begin
      StrBlockName := 'Counters_From_C%d_to_C%d';
    end;
    5,
    10: begin
      StrBlockName := 'Timers_From_T%d_to_T%d';
    end;
    6: begin
      StrBlockName := 'SM_From_SMB%d_to_SMB%d';
    end;
    7: begin
      StrBlockName := 'AnalogInput_From_AIW%d_to_AIW%d';
    end;
    8: begin
      StrBlockName := 'AnalogOutput_From_AQW%d_to_AQW%d';
    end;
    11: begin
      StrBlockName := 'AnalogIW_From_PIW%d_to_PIW%d';
    end;
    12: begin
      StrBlockName := 'Vs_From_V%s%d_to_V%s%d';
    end;
  end;

  if optPLCBlock.Checked then
  begin
    case BlockType.ItemIndex of
      0..2: begin
        StartType := 'B';
      end;
      3..4: begin
        StartType := 'W';
      end;
      5..7: begin
        StartType := 'D';
      end;
    end;
    EndType := StartType;
  end
  else
  begin
    StartType := '';
    EndType := '';
    if AtLeastOneItemIsValid then
      for CurItem := 0 to TagList.Count - 1 do
      begin
        with TS7TagItemEditor(TagList.Items[CurItem]) do
          if (StartType = '') and (not SkipTag) then
          begin
            case TagType of
              pttDefault,
              pttShortInt,
              pttByte: StartType := 'B';
              pttSmallInt,
              pttWord: StartType := 'W';
              pttLongInt,
              pttDWord,
              pttFloat: StartType := 'D';
            end;
          end;

        with TS7TagItemEditor(TagList.Items[(TagList.Count - 1) - CurItem]) do
          if (EndType = '') and (not SkipTag) then
          begin
            case TagType of
              pttDefault,
              pttShortInt,
              pttByte: EndType := 'B';
              pttSmallInt,
              pttWord: EndType := 'W';
              pttLongInt,
              pttDWord,
              pttFloat: EndType := 'D';
            end;
          end;
      end;
  end;

  case MemoryArea.ItemIndex of
    2,
    12: BlockName.Text := Format(StrBlockName, [StartType, GetRealStartOffset, EndType, GetTheLastItemOffset]);
    3: BlockName.Text := Format(StrBlockName, [spinDBNumber.Value, StartType, GetRealStartOffset, EndType, GetTheLastItemOffset]);
    4,
    5,
    9,
    10: BlockName.Text := Format(StrBlockName, [GetRealStartOffset div 2, GetTheLastItemOffset div 2]);
    else
      BlockName.Text := Format(StrBlockName, [GetRealStartOffset, GetTheLastItemOffset]);
  end;
  BlockName.Modified := False;
end;

procedure TfrmS7TagBuilder.spinStartAddressChange(Sender: TObject);
begin
  UpdateStatusAndBlockName;
end;

{$IFDEF FPC }
  {$IF defined(FPC) AND (FPC_FULLVERSION < 20400) }
initialization
  {$i us7tagbuilder.lrs}
  {$IFEND}
{$ENDIF}

end.

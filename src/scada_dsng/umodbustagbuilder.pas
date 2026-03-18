{$i ../common/language.inc}
{$IFDEF PORTUGUES}
//: Unit do assistente Modbus TagBuilder.
{$ELSE}
//: Unit of Modbus TagBuilder wizard.
{$ENDIF}
unit uModbusTagBuilder;

interface

uses
  {$IFDEF FPC}
LCLIntf, LResources,
  {$ELSE}
  Windows,
  {$ENDIF}
  SysUtils,
  Classes, Graphics, Controls, Forms, Dialogs, ComCtrls, StdCtrls, ExtCtrls, Spin;

type
  TTagNamesItemEditor = class(TPanel)
  private
    FOnDelClick: TNotifyEvent;
    procedure UpClick(Sender: TObject);
    procedure DownClick(Sender: TObject);
    procedure DelClick(Sender: TObject);
  public
    Nome: TEdit;
    CountEmpty: TCheckBox;
    Scan: TSpinEdit;
    ZeroFill: TCheckBox;
    QtdDigitos: TSpinEdit;
    PIPES: TComboBox;
    Up: TButton;
    Down: TButton;
    Del: TButton;
    Prior: TPanel;
    Next: TPanel;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property OnDelClick: TNotifyEvent read FOnDelClick write FOnDelClick;
  end;

  { TfrmModbusTagBuilder }
  Strings = array of AnsiString;

  TfrmModbusTagBuilder = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    txtTagType: TLabel;
    Type1: TRadioButton;
    Type2: TRadioButton;
    Type3: TRadioButton;
    Type4: TRadioButton;
    Panel1: TPanel;
    btnCancel: TButton;
    btnPrior: TButton;
    btnNext: TButton;
    btnFinish: TButton;
    TabSheet2: TTabSheet;
    Label2: TLabel;
    optPLCTagNumber: TRadioButton;
    optPLCBlock: TRadioButton;
    optPLCString: TRadioButton;
    txtMemCount: TLabel;
    MemCount: TSpinEdit;
    FirstMemAddress: TSpinEdit;
    txtFirstMemAddress: TLabel;
    txtStationAddress: TLabel;
    StationAddress: TSpinEdit;
    optSimpleFunctions: TCheckBox;
    MaxStringSize: TSpinEdit;
    txtMaxStringSize: TLabel;
    txtMaxBlockSize: TLabel;
    MaxBlockSize: TSpinEdit;
    txtStringFormat: TLabel;
    Panel2: TPanel;
    optSTR_C: TRadioButton;
    optSTR_SIEMENS: TRadioButton;
    TabSheet3: TTabSheet;
    txtStringByteSize: TLabel;
    ByteSize: TSpinEdit;
    ScrollBox1: TScrollBox;
    Panel4: TPanel;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Button1: TButton;
    optStartFromZero: TCheckBox;
    txtScanOfEachBlock: TLabel;
    ScanOfEachBlock: TSpinEdit;
    NameOfEachBlock: TEdit;
    txtNameOfEachBlock: TLabel;
    procedure btnFinishClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnPriorClick(Sender: TObject);
    procedure DelItem(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure optPLCTagNumberClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    Names: Strings;
  public
    CurItem: TTagNamesItemEditor;
    constructor Create(nomes: Strings); overload;
    destructor Destroy; override;
    procedure AfterConstruction; override;
  end;


var
  frmModbusTagBuilder: TfrmModbusTagBuilder;


implementation


uses
  hsstrings;


{$IFDEF FPC }
  {$IF defined(FPC) AND (FPC_FULLVERSION >= 20400) }
  {$R umodbustagbuilder.lfm}
  {$IFEND}
{$ELSE}
  {$R *.dfm}

{$ENDIF}


constructor TTagNamesItemEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alTop;
  BevelOuter := bvNone;
  Height := 24;

  Nome := TEdit.Create(Self);
  with Nome do
  begin
    Parent := Self;
    Top := 0;
    Left := 0;
    Height := 21;
    Width := 160;
    Text := 'Tag';
  end;

  CountEmpty := TCheckBox.Create(Self);
  with CountEmpty do
  begin
    Parent := Self;
    Top := 3;
    Left := 174;
    Height := 18;
    Width := 17;
    Checked := False;
  end;

  Scan := TSpinEdit.Create(Self);
  with Scan do
  begin
    Parent := Self;
    Top := 0;
    Left := 202;
    Height := 21;
    Width := 57;
    Value := 1000;
    MaxValue := 7200000;
    MinValue := 0;
  end;

  ZeroFill := TCheckBox.Create(Self);
  with ZeroFill do
  begin
    Parent := Self;
    Top := 3;
    Left := 267;
    Height := 18;
    Width := 17;
    Checked := False;
  end;

  QtdDigitos := TSpinEdit.Create(Self);
  with QtdDigitos do
  begin
    Parent := Self;
    Top := 0;
    Left := 296;
    Height := 21;
    Width := 57;
  end;

  PIPES := TComboBox.Create(Self);
  with PIPES do
  begin
    Parent := Self;
    Top := 0;
    Left := 351;
    Height := 21;
    Width := 135;
    Style := csDropDownList;
  end;

  Up := TButton.Create(Self);
  with Up do
  begin
    Parent := Self;
    Top := 0;
    Left := 487;
    Height := 21;
    Width := 22;
    Caption := 'Up';
    OnClick := @UpClick;
  end;

  Down := TButton.Create(Self);
  with Down do
  begin
    Parent := Self;
    Top := 0;
    Left := 509;
    Height := 21;
    Width := 34;
    Caption := 'Down';
    OnClick := @DownClick;
  end;

  Del := TButton.Create(Self);
  with Del do
  begin
    Parent := Self;
    Top := 0;
    Left := 543;
    Height := 21;
    Width := 25;
    Caption := 'Del';
    OnClick := @DelClick;
  end;
end;

destructor TTagNamesItemEditor.Destroy;
begin
  if (Prior <> nil) and (Prior is TTagNamesItemEditor) then
    TTagNamesItemEditor(Prior).Next := Next;
  if (Next <> nil) and (Next is TTagNamesItemEditor) then
    TTagNamesItemEditor(Next).Prior := Prior;

  Nome.Destroy;
  CountEmpty.Destroy;
  Scan.Destroy;
  ZeroFill.Destroy;
  QtdDigitos.Destroy;
  PIPES.Destroy;
  Up.Destroy;
  Down.Destroy;
  Del.Destroy;
  inherited Destroy;
end;

procedure TTagNamesItemEditor.UpClick(Sender: TObject);
var
  PriorItem: TTagNamesItemEditor;
  PriorItem1: TTagNamesItemEditor;
  NextItem: TTagNamesItemEditor;
begin
  PriorItem := TTagNamesItemEditor(Self.Prior);
  NextItem := TTagNamesItemEditor(Self.Next);
  if PriorItem = nil then
  begin
    Exit;
  end
  else
  begin
    Self.Top := PriorItem.Top - 1;
    PriorItem1 := TTagNamesItemEditor(PriorItem.Prior);
    TTagNamesItemEditor(PriorItem).Next := NextItem;
  end;

  if NextItem <> nil then
    TTagNamesItemEditor(NextItem).Prior := PriorItem;

  if PriorItem1 <> nil then
    PriorItem1.Next := Self;
  Self.Prior := PriorItem1;
  Self.Next := PriorItem;
  PriorItem.Prior := Self;
end;

procedure TTagNamesItemEditor.DownClick(Sender: TObject);
var
  PriorItem: TTagNamesItemEditor;
  NextItem: TTagNamesItemEditor;
  NextItem1: TTagNamesItemEditor;
begin
  PriorItem := TTagNamesItemEditor(Self.Prior);
  NextItem := TTagNamesItemEditor(Self.Next);
  if NextItem = nil then
  begin
    Exit;
  end
  else
  begin
    Self.Top := NextItem.Top + 1;
    NextItem1 := TTagNamesItemEditor(NextItem.Next);
    TTagNamesItemEditor(NextItem).Prior := PriorItem;
  end;

  if PriorItem <> nil then
    TTagNamesItemEditor(PriorItem).Next := NextItem;

  if NextItem1 <> nil then
    NextItem1.Prior := Self;
  Self.Next := NextItem1;
  Self.Prior := NextItem;
  NextItem.Next := Self;
end;

procedure TTagNamesItemEditor.DelClick(Sender: TObject);
begin
  if Assigned(FOnDelClick) then
    FOnDelClick(Self);
end;

////////////////////////////////////////////////////////////////////////////////
constructor TfrmModbusTagBuilder.Create(nomes: Strings);
begin
  inherited Create(nil);
  Names := nomes;
end;

destructor TfrmModbusTagBuilder.Destroy;
var
  Item: TTagNamesItemEditor;
begin
  while CurItem <> nil do
  begin
    Item := TTagNamesItemEditor(CurItem.Prior);
    CurItem.Destroy;
    CurItem := Item;
  end;
  inherited Destroy;
end;

procedure TfrmModbusTagBuilder.AfterConstruction;
begin
  inherited AfterConstruction;
  Button1Click(Self);
end;

procedure TfrmModbusTagBuilder.PageControl1Change(Sender: TObject);
begin
  btnPrior.Enabled := PageControl1.TabIndex <> 0;
  btnNext.Enabled := PageControl1.TabIndex <> 2;
  optPLCTagNumberClick(Sender);
  btnFinish.Enabled := PageControl1.TabIndex = 2;
end;

procedure TfrmModbusTagBuilder.DelItem(Sender: TObject);
var
  Item: TTagNamesItemEditor;
  NextItem: TTagNamesItemEditor;
  PriorItem: TTagNamesItemEditor;
begin
  //se so ha um Item.
  if (CurItem.Prior = nil) and (CurItem.Next = nil) then Exit;

  if MessageDlg(SDoYouWantDeleteThisItem, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Item := CurItem;
    if Sender = CurItem then
    begin
      CurItem := TTagNamesItemEditor(Item.Prior);
      Item.Destroy;
    end
    else
    begin
      while Item <> nil do
      begin
        if Item = Sender then
        begin
          NextItem := TTagNamesItemEditor(Item.Next);
          PriorItem := TTagNamesItemEditor(Item.Prior);
          if PriorItem <> nil then
            PriorItem.Next := NextItem;

          if NextItem <> nil then
            NextItem.Prior := PriorItem;
          Item.Destroy;
          Break;
        end;
        Item := TTagNamesItemEditor(Item.Prior);
      end;
    end;
  end;
end;

procedure TfrmModbusTagBuilder.FormCreate(Sender: TObject);
begin
  PageControl1.TabIndex := 0;
  btnFinish.ModalResult := mrNone;
  CurItem := nil;
  txtStationAddress.Caption := SMBTBStatiomAddress;
  txtTagType.Caption := SMBTBTagType;
  txtMemCount.Caption := SMBTBMemCount;
  optStartFromZero.Caption := SMBTBStartFromZero;
  txtFirstMemAddress.Caption := SMBTBFirstMemAddress;
  TabSheet1.Caption := SMBTBTabSheet1;
  TabSheet2.Caption := SMBTBTabSheet2;
  TabSheet3.Caption := SMBTBTabSheet3;
  btnCancel.Caption := SMBTBCancel;
  btnPrior.Caption := SMBTBPrior;
  btnNext.Caption := SMBTBNext;
  btnFinish.Caption := SMBTBFinish;
  Label2.Caption := SMBTBLabel2;
  optSimpleFunctions.Caption := SMBTBSimpleFunctions;
  txtMaxBlockSize.Caption := SMBTBMaxBlockSize;
  txtScanOfEachBlock.Caption := SMBTBScanOfEachBlock;
  txtNameOfEachBlock.Caption := SMBTBNameOfEachBlock;
  txtMaxStringSize.Caption := SMBTBMaxStringSize;
  txtStringFormat.Caption := SMBTBStringFormat;
  txtStringByteSize.Caption := SMBTBStringByteSize;
  Label1.Caption := SMBTBLabel1;
  Label3.Caption := SMBTBLabel3;
  Label4.Caption := SMBTBLabel4;
  Label5.Caption := SMBTBLabel5;
  Label6.Caption := SMBTBLabel6;
  Label7.Caption := SMBTBLabel7;
end;

procedure TfrmModbusTagBuilder.optPLCTagNumberClick(Sender: TObject);
begin
  optSimpleFunctions.Enabled := optPLCTagNumber.Checked;
  txtMaxBlockSize.Enabled := optPLCBlock.Checked;
  MaxBlockSize.Enabled := optPLCBlock.Checked;
  txtScanOfEachBlock.Enabled := optPLCBlock.Checked;
  ScanOfEachBlock.Enabled := optPLCBlock.Checked;
  txtNameOfEachBlock.Enabled := optPLCBlock.Checked;
  NameOfEachBlock.Enabled := optPLCBlock.Checked;
  txtMaxStringSize.Enabled := optPLCString.Checked;
  MaxStringSize.Enabled := optPLCString.Checked;
  txtStringFormat.Enabled := optPLCString.Checked;
  optSTR_C.Enabled := optPLCString.Checked;
  optSTR_SIEMENS.Enabled := optPLCString.Checked;
  txtStringByteSize.Enabled := optPLCString.Checked;
  ByteSize.Enabled := optPLCString.Checked;
end;

procedure TfrmModbusTagBuilder.btnFinishClick(Sender: TObject);
var
  Item: TTagNamesItemEditor;
begin
  Item := CurItem;
  while Item <> nil do
  begin
    if (Trim(Item.Nome.Text) <> '') and (not (Item.Nome.Text[1] in ['a'..'z', 'A'..'Z', '_'])) then
    begin
      MessageDlg(SInvalidTagNameInTagBuilder, mtError, [mbOK], 0);
      Exit;
    end;
    Item := TTagNamesItemEditor(Item.Prior);
  end;

  if optPLCBlock.Checked and ((Trim(NameOfEachBlock.Text) = '') or (not (NameOfEachBlock.Text[1] in ['a'..'z', 'A'..'Z', '_']))) then
  begin
    MessageDlg(SInvalidBlockName, mtError, [mbOK], 0);
    Exit;
  end;

  if CurItem = nil then
  begin
    MessageDlg(SWithoutAtLeastOneValidName, mtError, [mbOK], 0);
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TfrmModbusTagBuilder.btnNextClick(Sender: TObject);
begin
  PageControl1.TabIndex := PageControl1.TabIndex + 1;
  PageControl1Change(Sender);
end;

procedure TfrmModbusTagBuilder.btnPriorClick(Sender: TObject);
begin
  PageControl1.TabIndex := PageControl1.TabIndex - 1;
  PageControl1Change(Sender);
end;

procedure TfrmModbusTagBuilder.Button1Click(Sender: TObject);
var
  NewItem: TTagNamesItemEditor;
  i: Longint;
begin
  NewItem := TTagNamesItemEditor.Create(Self);
  NewItem.Parent := ScrollBox1;
  NewItem.Prior := CurItem;
  NewItem.Next := nil;
  NewItem.OnDelClick := @DelItem;
  NewItem.Top := 200;

  if CurItem <> nil then
    CurItem.Next := NewItem;

  CurItem := NewItem;

  for i := 0 to High(Names) do
    NewItem.PIPES.Items.Add(Names[i]);

  NewItem.PIPES.ItemIndex := 0;
end;


{$IFDEF FPC }
  {$IF defined(FPC) AND (FPC_FULLVERSION < 20400) }
initialization
  {$I umodbustagbuilder.lrs}
  {$IFEND}
{$ENDIF}


end.

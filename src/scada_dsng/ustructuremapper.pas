{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Unit do formul�rio assistente de cria��o de estruturas do tag TPLCStruct.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Unit of Struct item mapper wizard.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
unit ustructuremapper;

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, ExtCtrls, Buttons, us7tagbuilder
  {$IFDEF FPC}
, LCLIntf, LResources
  {$ENDIF}
  ;

type

  {$IFDEF PORTUGUES}
  {:
  Assistente de cria��o de estruturas usando o tag TPLCStruct.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Struct mapper wizard.

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TfrmStructureEditor = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    SpinEdit1: TSpinEdit;
    Button1: TButton;
    ScrollBox1: TScrollBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var aAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FTagList: TList;
    ItemsToDel: TList;
    FItemId: Longint;
    procedure CheckNames(Sender: TObject; NewName: AnsiString; var AcceptNewName: Boolean);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnBitsClick(Sender: TObject);
    procedure BitItemDeleted(Sender: TObject);
    function GetStructItemsCount: Longint;
    function GetStructItem(Index: Longint): TS7TagItemEditor;
  public
    destructor Destroy; override;
    function HasAtLeastOneValidItem: Boolean;
    property StructItemsCount: Longint read GetStructItemsCount;
    property StructItem[index: Longint]: TS7TagItemEditor read GetStructItem;
  end;

var
  frmStructureEditor: TfrmStructureEditor;


implementation


uses
  Tag, ubitmapper, hsstrings;


{$IFDEF FPC }
  {$IF defined(FPC) AND (FPC_FULLVERSION >= 20400) }
  {$R ustructuremapper.lfm}
  {$IFEND}
{$ELSE}
  {$R *.dfm}
{$ENDIF}


destructor TfrmStructureEditor.Destroy;
begin
  FTagList.Destroy;
  ItemsToDel.Destroy;
  inherited Destroy;
end;

procedure TfrmStructureEditor.Button1Click(Sender: TObject);
var
  ATag: TS7TagItemEditor;
  LastItem: TS7TagItemEditor;
begin
  ATag := TS7TagItemEditor.Create(Self);
  ATag.Parent := ScrollBox1;
  ATag.PopulateCombo;
  ATag.OnCheckNames := @CheckNames;
  ATag.OnUpClick := @btnUpClick;
  ATag.OnDownClickEvent := @btnDownClick;
  ATag.OnDelClickEvent := @btnDelClick;
  ATag.OnBitsClickEvent := @btnBitsClick;
  ATag.OnDelBitItem := @BitItemDeleted;
  ATag.TagScan := 1000;
  ATag.TagType := pttDefault;
  ATag.SwapBytes := False;
  ATag.SwapWords := False;
  if FTagList.Count > 0 then
  begin
    LastItem := TS7TagItemEditor(FTagList.Items[FTagList.Count - 1]);
    ATag.Top := LastItem.Top + LastItem.Height;
  end
  else
  begin
    ATag.Top := 0;
  end;

  while not ATag.AcceptName('StructItem' + IntToStr(FItemId)) do
    Inc(FItemId);
  ATag.TagName := 'StructItem' + IntToStr(FItemId);

  FTagList.Add(ATag);
end;

procedure TfrmStructureEditor.BitBtn2Click(Sender: TObject);
begin

end;

procedure TfrmStructureEditor.BitBtn1Click(Sender: TObject);
begin
  if not HasAtLeastOneValidItem then
    raise Exception.Create(SYouMustHaveAtLeastOneStructureItem);
end;

procedure TfrmStructureEditor.FormCreate(Sender: TObject);
begin
  FItemId := 1;
  FTagList := TList.Create;
  ItemsToDel := TList.Create;
end;

procedure TfrmStructureEditor.FormClose(Sender: TObject; var aAction: TCloseAction);
begin

end;

procedure TfrmStructureEditor.FormShow(Sender: TObject);
begin
  Button1Click(Sender);
end;

procedure TfrmStructureEditor.CheckNames(Sender: TObject; NewName: AnsiString; var AcceptNewName: Boolean);
var
  i: Longint;
  j: Longint;
begin
  for i := 0 to FTagList.Count - 1 do
  begin
    if TObject(FTagList.Items[i]) = Sender then
      Continue;
    if TS7TagItemEditor(FTagList.Items[i]).TagName = NewName then
    begin
      AcceptNewName := False;
      Exit;
    end;
    for j := 0 to TS7TagItemEditor(FTagList.Items[i]).BitCount - 1 do
    begin
      if TS7TagItemEditor(FTagList.Items[i]).Bit[j] = Sender then
        Continue;
      if TTagBitItemEditor(TS7TagItemEditor(FTagList.Items[i]).Bit[j]).TagName = NewName then
      begin
        AcceptNewName := False;
        Exit;
      end;
    end;
  end;
end;

procedure TfrmStructureEditor.btnUpClick(Sender: TObject);
var
  Idx: Longint;
  PriorTop: Longint;
  ActualTop: Longint;
  Prior: TS7TagItemEditor;
begin
  if not (Sender is TS7TagItemEditor) then Exit;

  Idx := FTagList.IndexOf(Sender);
  if Idx > 0 then
  begin
    Prior := TS7TagItemEditor(FTagList.Items[Idx - 1]);

    PriorTop := Prior.Top;
    ActualTop := (Sender as TS7TagItemEditor).Top;

    FTagList.Exchange(Idx - 1, Idx);

    (Sender as TS7TagItemEditor).Top := PriorTop;
    (Sender as TS7TagItemEditor).TabOrder := Prior.TabOrder;
    Prior.Top := ActualTop;
  end;
end;

procedure TfrmStructureEditor.btnDownClick(Sender: TObject);
var
  Idx: Longint;
  NextTop: Longint;
  ActualTop: Longint;
  ANext: TS7TagItemEditor;
begin
  if not (Sender is TS7TagItemEditor) then Exit;

  Idx := FTagList.IndexOf(Sender);
  if (Idx <> -1) and (Idx < (FTagList.Count - 1)) then
  begin
    ANext := TS7TagItemEditor(FTagList.Items[Idx + 1]);

    NextTop := ANext.Top;
    ActualTop := (Sender as TS7TagItemEditor).Top;

    FTagList.Exchange(Idx + 1, Idx);

    (Sender as TS7TagItemEditor).Top := NextTop;
    ANext.TabOrder := (Sender as TS7TagItemEditor).TabOrder;
    ANext.Top := ActualTop;
  end;
end;

procedure TfrmStructureEditor.btnDelClick(Sender: TObject);
begin
  if ItemsToDel.IndexOf(Sender) = -1 then
    if MessageDlg('Remove the structure item called "' + TS7TagItemEditor(Sender).TagName + '"?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ItemsToDel.Add(Sender);
      Timer1.Enabled := True;
    end;
end;

procedure TfrmStructureEditor.btnBitsClick(Sender: TObject);
var
  BitForm: TfrmBitMapper;
  TagItemEditor: TTagBitItemEditor;
  S7TagEditor: TS7TagItemEditor;
  BitNum: Longint;
  ByteNum: Longint;
  WordNum: Longint;
  StartBit: Longint;
  EndBit: Longint;
  CurBit: Longint;

  procedure updatenumbers;
  begin
    BitNum := CurBit;
    if BitForm.BitNameStartsFrom1.Checked then
      Inc(BitNum);

    ByteNum := CurBit Div 8;
    if BitForm.ByteNameStartsFrom1.Checked then
      Inc(ByteNum);

    WordNum := CurBit Div 16;
    if BitForm.WordNameStartsFrom1.Checked then
      Inc(WordNum);
  end;

  function GetNewTagBitName: AnsiString;
  var
    N: AnsiString;
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
      StartBit := 31 - BitForm.StringGrid1.Selection.Right;
      EndBit := 31 - BitForm.StringGrid1.Selection.Left;
      CurBit := StartBit;
      if BitForm.EachBitAsTag.Checked then
      begin
        while CurBit <= EndBit do
        begin
          updatenumbers;
          TagItemEditor := S7TagEditor.AddBit;
          TagItemEditor.TagName := GetNewTagBitName;
          TagItemEditor.endbit := CurBit;
          TagItemEditor.startbit := CurBit;
          Inc(CurBit);
        end;
      end
      else
      begin
        updatenumbers;
        TagItemEditor := S7TagEditor.AddBit;
        TagItemEditor.TagName := GetNewTagBitName;
        TagItemEditor.endbit := EndBit;
        TagItemEditor.startbit := StartBit;
      end;
    end;
  finally
    BitForm.Destroy;
  end;
end;

procedure TfrmStructureEditor.BitItemDeleted(Sender: TObject);
begin

end;

function TfrmStructureEditor.GetStructItemsCount: Longint;
begin
  Result := FTagList.Count;
end;

function TfrmStructureEditor.GetStructItem(Index: Longint): TS7TagItemEditor;
begin
  Result := TS7TagItemEditor(FTagList.Items[Index]);
end;

function TfrmStructureEditor.HasAtLeastOneValidItem: Boolean;
var
  i: Longint;
begin
  Result := False;
  for i := 0 to StructItemsCount - 1 do
    if not StructItem[i].SkipTag then
    begin
      Result := True;
      Break;
    end;
end;

procedure TfrmStructureEditor.Timer1Timer(Sender: TObject);
var
  i: Longint;
begin
  for i := ItemsToDel.Count - 1 downto 0 do
  begin
    FTagList.Remove(ItemsToDel.Items[i]);
    TS7TagItemEditor(ItemsToDel.Items[i]).Destroy;
    ItemsToDel.Delete(i);
  end;
  Timer1.Enabled := False;
  if FTagList.Count = 0 then FItemId := 1;
end;


{$IFDEF FPC }
  {$IF defined(FPC) AND (FPC_FULLVERSION < 20400) }
initialization
  {$i ustructuremapper.lrs}
  {$IFEND}
{$ENDIF}


end.

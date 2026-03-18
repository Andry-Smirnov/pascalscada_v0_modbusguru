{$i ../common/language.inc}
{:
  @abstract(Implementation of TagAssistant for ModBus.)
  @author(Juanjo Montero <juanjo.montero@gmail.com>)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - New Unit
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
unit modbustagassistant;

{$IFDEF FPC}
 {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, modbusdriver, ProtocolTypes, uModbusTagBuilder;

type

  { TModBusTagAssistant }

  TModBusTagAssistant = class
  private
    FDriver: TModBusDriver;
    function SelectedReadFuntion(ADialog: TfrmModbusTagBuilder): Longint;
    function SelectedWriteFuntion(ADialog: TfrmModbusTagBuilder): Longint;
    function SeekFirstItem(LastItem: TTagNamesItemEditor): TTagNamesItemEditor;
    function BuildItemName(NamePrefix: AnsiString; ZeroFill: Boolean; Index, NumZeros: Longint): AnsiString;
  public
    //: Opens the Tag Builder of the ModBus protocol driver
    procedure OpenTagEditor(OwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);

  published
    property Driver: TModBusDriver read FDriver write FDriver;
  end;

procedure OpenTagEditor(AProtocolDriver, AOwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);


implementation


uses
  PLCBlockElement, ValueProcessor, PLCTagNumber, PLCString,
  PLCBlock, Controls, Dialogs, hsstrings, ProtocolDriver;


procedure OpenTagEditor(AProtocolDriver, AOwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
var
  Wizard: TModBusTagAssistant;
begin
  if not (AProtocolDriver is TModBusDriver) then
    raise Exception.Create('A Modbus RTU/TCP driver required as protocol.');

  Wizard := TModBusTagAssistant.Create;
  try
    Wizard.Driver := TModBusDriver(AProtocolDriver);
    Wizard.OpenTagEditor(AOwnerOfNewTags, InsertHook, CreateProc);
  finally
    FreeAndNil(Wizard);
  end;
end;

{ TModBusTagAssistant }

procedure TModBusTagAssistant.OpenTagEditor(OwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
var
  i: Longint;
  Count: Longint;
  ADialog: TfrmModbusTagBuilder;
  TPLC: TPLCTagNumber;
  TStr: TPLCString;
  TBlk: TPLCBlock;
  TBlockElement: TPLCBlockElement;
  CurMemtAdress: Longint;
  NameItem: Longint;
  BlockNo: Longint;
  Element: Longint;
  ConfItem: TTagNamesItemEditor;
  KnowStringSize: Boolean;
  TStrDummy: TPLCString;
  DefaultStringSize: Longint;
  ItemName: Strings;
  ItemPtr: array of TComponent;
begin
  if not Assigned(FDriver) then
  begin
    ShowMessage(SDriverRequired);
    Exit;
  end;

  Count := 1;
  SetLength(ItemName, 1);
  SetLength(ItemPtr, 1);
  ItemName[0] := '(none)';
  ItemPtr[0] := nil;
  for i := 0 to OwnerOfNewTags.ComponentCount - 1 do
  begin
    if OwnerOfNewTags.Components[i] is TScaleProcessor then
    begin
      Inc(Count);
      SetLength(ItemName, Count);
      SetLength(ItemPtr, Count);
      ItemName[Count - 1] := OwnerOfNewTags.Components[i].Name;
      ItemPtr[Count - 1] := OwnerOfNewTags.Components[i];
    end;
  end;

  ADialog := TfrmModbusTagBuilder.Create(ItemName);
  try
    if ADialog.ShowModal = mrOk then
    begin
      if Assigned(InsertHook) and Assigned(CreateProc) then
      begin
        KnowStringSize := False;

        CurMemtAdress := ADialog.FirstMemAddress.Value;

        if ADialog.optStartFromZero.Checked then
          NameItem := 0
        else
          NameItem := 1;

        ConfItem := SeekFirstItem(ADialog.CurItem);
        if ConfItem = nil then Exit;

        ////////////////////////////////////////////////////////////////////////
        //plcnumber and string
        ////////////////////////////////////////////////////////////////////////
        if ADialog.optPLCTagNumber.Checked or ADialog.optPLCString.Checked then
        begin
          i := 1;
          while i <= ADialog.MemCount.Value do
          begin
            if Trim(ConfItem.Nome.Text) <> '' then
            begin
              if ADialog.optPLCTagNumber.Checked then
              begin
                TPLC := TPLCTagNumber(CreateProc(TPLCTagNumber));
                TPLC.Name := BuildItemName(ConfItem.Nome.Text, ConfItem.ZeroFill.Checked, NameItem, ConfItem.QtdDigitos.Value);
                TPLC.MemAddress := CurMemtAdress;
                TPLC.MemReadFunction := SelectedReadFuntion(ADialog);
                TPLC.MemWriteFunction := SelectedWriteFuntion(ADialog);
                TPLC.PLCStation := ADialog.StationAddress.Value;
                TPLC.RefreshTime := ConfItem.Scan.Value;
                TPLC.ProtocolDriver := FDriver;
                if ConfItem.PIPES.ItemIndex <> -1 then
                  TPLC.ScaleProcessor := TScalesQueue(ItemPtr[ConfItem.PIPES.ItemIndex]);
                InsertHook(TPLC);
              end
              else
              begin
                TStr := TPLCString(CreateProc(TPLCString));
                TStr.Name := BuildItemName(ConfItem.Nome.Text, ConfItem.ZeroFill.Checked, NameItem, ConfItem.QtdDigitos.Value);
                TStr.MemAddress := CurMemtAdress;
                TStr.MemReadFunction := SelectedReadFuntion(ADialog);
                TStr.MemWriteFunction := SelectedWriteFuntion(ADialog);
                TStr.PLCStation := ADialog.StationAddress.Value;
                TStr.RefreshTime := ConfItem.Scan.Value;
                TStr.ProtocolDriver := FDriver;
                if ADialog.optSTR_C.Checked then
                  TStr.StringType := stC
                else
                  TStr.StringType := stSIEMENS;
                TStr.ByteSize := Byte(ADialog.ByteSize.Value);
                TStr.StringSize := ADialog.MaxStringSize.Value;
                InsertHook(TStr);

                if not KnowStringSize then
                begin
                  KnowStringSize := True;
                  DefaultStringSize := TStr.Size;
                end;
              end;
            end;

            if ADialog.optPLCTagNumber.Checked then
              Inc(CurMemtAdress)
            else
            begin
              //se o tamanho do bloco da string ainda não é conhecido.
              //if the string size is unknown.
              if not KnowStringSize then
              begin
                try
                  TStrDummy := TPLCString.Create(nil);
                  TStrDummy.MemAddress := CurMemtAdress;
                  TStrDummy.MemReadFunction := SelectedReadFuntion(ADialog);
                  TStrDummy.MemWriteFunction := SelectedWriteFuntion(ADialog);
                  TStrDummy.PLCStation := ADialog.StationAddress.Value;
                  TStrDummy.RefreshTime := ConfItem.Scan.Value;
                  TStrDummy.ProtocolDriver := FDriver;
                  if ADialog.optSTR_C.Checked then
                    TStrDummy.StringType := stC
                  else
                    TStrDummy.StringType := stSIEMENS;
                  TStrDummy.ByteSize := Byte(ADialog.ByteSize.Value);
                  TStrDummy.StringSize := ADialog.MaxStringSize.Value;
                  DefaultStringSize := TStrDummy.Size;
                  KnowStringSize := True;
                finally
                  TStrDummy.Destroy;
                end;
              end;
              Inc(CurMemtAdress, DefaultStringSize);
            end;

            if (Trim(ConfItem.Nome.Text) <> '') or ConfItem.CountEmpty.Checked then
              Inc(i);

            if ConfItem.Next = nil then
            begin
              ConfItem := SeekFirstItem(ADialog.CurItem);
              Inc(NameItem);
            end
            else
              ConfItem := TTagNamesItemEditor(ConfItem.Next);
          end;
        end;

        ////////////////////////////////////////////////////////////////////////
        //TPLCBlock
        ////////////////////////////////////////////////////////////////////////
        if ADialog.optPLCBlock.Checked then
        begin
          i := 1;
          BlockNo := 1;
          while i <= ADialog.MemCount.Value do
          begin
            Element := 0;
            TBlk := TPLCBlock(CreateProc(TPLCBlock));
            TBlk.Name := BuildItemName(ADialog.NameOfEachBlock.Text, False, BlockNo, 9);
            TBlk.MemAddress := CurMemtAdress;
            TBlk.MemReadFunction := SelectedReadFuntion(ADialog);
            TBlk.MemWriteFunction := SelectedWriteFuntion(ADialog);
            TBlk.PLCStation := ADialog.StationAddress.Value;
            TBlk.RefreshTime := ADialog.ScanOfEachBlock.Value;
            TBlk.Size := 1;
            TBlk.ProtocolDriver := FDriver;
            InsertHook(TBlk);

            //cria os elementos do bloco
            //create the block elements.
            while Element < ADialog.MaxBlockSize.Value do
            begin
              if Trim(ConfItem.Nome.Text) <> '' then
              begin
                TBlockElement := TPLCBlockElement(CreateProc(TPLCBlockElement));
                TBlockElement.Name := BuildItemName(ConfItem.Nome.Text, ConfItem.ZeroFill.Checked, NameItem, ConfItem.QtdDigitos.Value);
                TBlockElement.PLCBlock := TBlk;
                TBlk.Size := Element + 1;
                TBlockElement.index := Element;
                if ConfItem.PIPES.ItemIndex <> -1 then
                  TBlockElement.ScaleProcessor := TScalesQueue(ItemPtr[ConfItem.PIPES.ItemIndex]);
                InsertHook(TBlockElement);
              end;

              Inc(Element);
              Inc(CurMemtAdress);

              if (Trim(ConfItem.Nome.Text) <> '') or ConfItem.CountEmpty.Checked then
                Inc(i);

              if ConfItem.Next = nil then
              begin
                ConfItem := SeekFirstItem(ADialog.CurItem);
                Inc(NameItem);
              end
              else
                ConfItem := TTagNamesItemEditor(ConfItem.Next);
            end;

            //incrementa o numero do bloco.
            //inc the block number.
            Inc(BlockNo);
          end;
        end;
      end;
    end;
  finally
    ADialog.Destroy;
  end;
end;


function TModBusTagAssistant.SelectedReadFuntion(ADialog: TfrmModbusTagBuilder): Longint;
begin
  Result := 0;
  if ADialog.Type1.Checked then
    Result := 1;
  if ADialog.Type2.Checked then
    Result := 2;
  if ADialog.Type3.Checked then
    Result := 3;
  if ADialog.Type4.Checked then
    Result := 4;
end;

function TModBusTagAssistant.SelectedWriteFuntion(ADialog: TfrmModbusTagBuilder): Longint;
begin
  Result := 0;
  case SelectedReadFuntion(ADialog) of
    1:  begin
          if ADialog.optSimpleFunctions.Checked then
            Result := 5
          else
            Result := 15;
        end;
    3:  begin
          if ADialog.optSimpleFunctions.Checked then
            Result := 6
          else
            Result := 16;
        end;
  end;
end;

function TModBusTagAssistant.SeekFirstItem(LastItem: TTagNamesItemEditor): TTagNamesItemEditor;
begin
  Result := LastItem;
  while (Result <> nil) and (Result.Prior <> nil) do
    Result := TTagNamesItemEditor(Result.Prior);
end;

function TModBusTagAssistant.BuildItemName(NamePrefix: AnsiString; ZeroFill: Boolean; Index, NumZeros: Longint): AnsiString;
var
  IndexFormat: AnsiString;
  NumFormat: AnsiString;
  i: Longint;
begin
  if ZeroFill then
  begin
    IndexFormat := '0';
    for i := 2 to NumZeros do
      IndexFormat := IndexFormat + '0';
  end
  else
    IndexFormat := '#0';

  NumFormat := FormatFloat(IndexFormat, Index);

  if Pos('%s', NamePrefix) = 0 then
    Result := NamePrefix + NumFormat
  else
    Result := Format(NamePrefix, [NumFormat]);
end;


initialization
  SetTagBuilderToolForModBusProtocolFamily(@OpenTagEditor)


end.

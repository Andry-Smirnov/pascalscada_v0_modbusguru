{$i ../common/language.inc}
{:
  @abstract(Implementation of TagAssistant for Siemens.)
  @author(Juanjo Montero <juanjo.montero@gmail.com>)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - New Unit
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  02/2014
  Changed to the old behavior (Right click on ISOTCP protocol ->
  Tag Builder to open the tag editor, whithout link with gui.
  ***********************************************************************
}
unit siemenstagassistant;

{$IFDEF FPC}
 {$mode objfpc}{$H+}
{$ENDIF}

interface

implementation

uses
  Classes, SysUtils, ProtocolTypes, PLCTagNumber, PLCStructElement,
  us7tagbuilder, PLCBlockElement, PLCNumber, TagBit, plcblock, tag, Controls,
  PLCStruct, Dialogs, StrUtils, ProtocolDriver, s7family;

procedure OpenTagEditor(AProtocolDriver, AOwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
var
  S7TagBuilderForm: TfrmS7TagBuilder;
  CurItem: Longint;
  CurStructItem: Longint;
  CurAddress: Longint;
  CurIdx: Longint;
  CurTCAddress: Longint;
  CurBit: Longint;
  CurDb: Longint;
  Block: TPLCBlock;
  Item: TPLCNumber;
  BitItem: TTagBit;
  MoreThanOneDb: Boolean;
  MoreThanOneItem: Boolean;
  Started: Boolean;

  function GetCurWordSize: Longint;
  var
    ATagType: TTagType;
  begin
    if S7TagBuilderForm.optPLCBlock.Checked then
      ATagType := S7TagBuilderForm.CurBlockType
    else
      ATagType := S7TagBuilderForm.StructItem[CurStructItem].TagType;

    case ATagType of
      pttDefault,
      pttShortInt,
      pttByte:    Result := 1;
      pttSmallInt,
      pttWord:    Result := 2;
      pttLongInt,
      pttDWord,
      pttFloat:   Result := 4;
    end;
  end;

  function GetValueWithZeros(Value, EndValue: Longint; ToFill: Boolean): AnsiString;
  var
    NumDig: Longint;
    Dig: Longint;
    StrEndVal: AnsiString;
    Fill: AnsiString;
  begin
    StrEndVal := IntToStr(EndValue);

    Fill := '';
    NumDig := Length(StrEndVal);
    for Dig := 1 to NumDig do
      Fill := Fill + '0';

    if ToFill then
      Result := RightStr(Fill + IntToStr(Value), NumDig)
    else
      Result := IntToStr(Value);
  end;

  function ReplaceBlockNamePattern(NamePattern: AnsiString): AnsiString;
  var
    HasAtLestOneReplacement: Boolean;
  begin
    {
    %db  - DB number.
    %di  - DB counter, starting from 1.
    %de  - DB counter, starting from 0.
    %0db - DB number, filled with zeroes.
    %0di - DB counter, starting from 1, filled with zeroes.
    %0de - DB counter, starting from 0, filled with zeroes.
    }
    HasAtLestOneReplacement := (Pos('%db', NamePattern) <> 0)
      or (Pos('%di', NamePattern) <> 0)
      or (Pos('%de', NamePattern) <> 0)
      or (Pos('%0db', NamePattern) <> 0)
      or (Pos('%0di', NamePattern) <> 0)
      or (Pos('%0de', NamePattern) <> 0);

    if (not HasAtLestOneReplacement) and MoreThanOneDb then
      NamePattern := NamePattern + '%di';

    Result := NamePattern;

    Result := StringReplace(Result, '%db', IntToStr(CurDb), [rfReplaceAll]);
    Result := StringReplace(Result, '%di', IntToStr(CurDb - S7TagBuilderForm.spinDBNumber.Value + 1), [rfReplaceAll]);
    Result := StringReplace(Result, '%de', IntToStr(CurDb - S7TagBuilderForm.spinDBNumber.Value + 0), [rfReplaceAll]);

    Result := StringReplace(Result, '%0db', GetValueWithZeros(CurDb, S7TagBuilderForm.spinFinalDBNumber.Value, True), [rfReplaceAll]);
    Result := StringReplace(Result, '%0di', GetValueWithZeros(CurDb - S7TagBuilderForm.spinDBNumber.Value + 1, S7TagBuilderForm.spinFinalDBNumber.Value - S7TagBuilderForm.spinDBNumber.Value + 1, True), [rfReplaceAll]);
    Result := StringReplace(Result, '%0di', GetValueWithZeros(CurDb - S7TagBuilderForm.spinDBNumber.Value, S7TagBuilderForm.spinFinalDBNumber.Value - S7TagBuilderForm.spinDBNumber.Value, True), [rfReplaceAll]);
  end;

  function GetItemName(NamePattern: AnsiString): AnsiString;
  var
    HasAtLeastOneReplacement: Boolean;
    HasAtLeastOneDBReplacement: Boolean;
  begin
    {
    %a    - Item address
    %i    - Item number starting from 1.
    %e    - Item number starting from 0.
    %0a   - Item address filled with zeros.
    %0i   - Item number starting from 1, filled with zeroes.
    %0e   - Item number starting from 0, filled with zeroes.
    }
    HasAtLeastOneDBReplacement := (Pos('%db', NamePattern) <> 0)
      or (Pos('%di', NamePattern) <> 0)
      or (Pos('%de', NamePattern) <> 0)
      or (Pos('%0db', NamePattern) <> 0)
      or (Pos('%0di', NamePattern) <> 0)
      or (Pos('%0de', NamePattern) <> 0);

    HasAtLeastOneReplacement := (Pos('%a', NamePattern) <> 0)
      or (Pos('%i', NamePattern) <> 0)
      or (Pos('%e', NamePattern) <> 0)
      or (Pos('%0a', NamePattern) <> 0)
      or (Pos('%0i', NamePattern) <> 0)
      or (Pos('%0e', NamePattern) <> 0);

    if MoreThanOneDb and (not HasAtLeastOneDBReplacement) then
      NamePattern := NamePattern + '%di';

    if MoreThanOneItem and (not HasAtLeastOneReplacement) then
    begin
      if MoreThanOneDb then
        NamePattern := NamePattern + '_%i'
      else
        NamePattern := NamePattern + '%i';
    end;

    //replaces the Block name patterns present on Item names.
    Result := ReplaceBlockNamePattern(NamePattern);

    if S7TagBuilderForm.MemoryArea.ItemIndex in [4, 9, 5, 10] then
    begin
      Result := StringReplace(Result, '%a', IntToStr(CurTCAddress), [rfReplaceAll]);
      Result := StringReplace(Result, '%0a', GetValueWithZeros(CurTCAddress, S7TagBuilderForm.GetTheLastItemOffset Div 2, True), [rfReplaceAll]);
    end
    else
    begin
      Result := StringReplace(Result, '%a', IntToStr(CurAddress), [rfReplaceAll]);
      Result := StringReplace(Result, '%0a', GetValueWithZeros(CurAddress, S7TagBuilderForm.RealEndOffset, True), [rfReplaceAll]);
    end;
    Result := StringReplace(Result, '%i', IntToStr(CurItem), [rfReplaceAll]);
    Result := StringReplace(Result, '%0i', GetValueWithZeros(CurItem, S7TagBuilderForm.spinNumItens.Value, True), [rfReplaceAll]);
    Result := StringReplace(Result, '%e', IntToStr(CurItem - 1), [rfReplaceAll]);
    Result := StringReplace(Result, '%0e', GetValueWithZeros(CurItem - 1, S7TagBuilderForm.spinNumItens.Value - 1, True), [rfReplaceAll]);
  end;

begin
  { What's missing??
    On form:
    ** Check of missing replacements to avoid name duplicity...

    REPLACEMENTS:

    %a  - Item address
    %i  - Item number starting from 1
    %e  - Item number starting from 0
    %0a - Item address filled with zeros.
    %0i - Item number starting from 1, filled with zeroes.
    %0e - Item number starting from 0, filled with zeroes.
  }
  if not (AProtocolDriver is TProtocolDriver) then
    raise Exception.Create('Protocol driver must be a instance of TProtocolDriver.');

  S7TagBuilderForm := TfrmS7TagBuilder.Create(nil);
  try
    with S7TagBuilderForm do
    begin
      if ShowModal = mrOk then
      begin
        MoreThanOneDb := spinDBNumber.Value <> spinFinalDBNumber.Value;
        MoreThanOneItem := spinNumItens.Value > 1;

        for CurDb := spinDBNumber.Value to spinFinalDBNumber.Value do
        begin
          //cria o bloco simples ou bloco estrutura e faz sua configuração.
          //create the Block or struture and configure it.
          if optPLCBlock.Checked or optplcStruct.Checked then
          begin
            //cria o bloco
            //creates the Block
            if optPLCBlock.Checked then
              Block := TPLCBlock(CreateProc(TPLCBlock))
            else
              Block := TPLCStruct(CreateProc(TPLCStruct));

            Block.PLCRack := PLCRack.Value;
            Block.PLCSlot := PLCSlot.Value;
            Block.PLCStation := PLCStation.Value;
            Block.MemReadFunction := GetTagType;
            Block.Name := ReplaceBlockNamePattern(BlockName.Text);
            if Block.MemReadFunction = 4 then
              Block.MemFile_DB := CurDb;
            Block.MemAddress := RealStartOffset;

            if optPLCBlock.Checked then
            begin
              Block.RefreshTime := BlockScan.Value;
              Block.TagType := CurBlockType;
              Block.SwapBytes := BlockSwapBytes.Checked;
              Block.SwapWords := BlockSwapWords.Checked;
            end
            else
              Block.RefreshTime := StructScan.Value;

            Block.ProtocolDriver := TProtocolDriver(AProtocolDriver);
            InsertHook(Block);
          end;

          //comeca a criar os itens da estrutura
          //creates the structure items
          CurAddress := spinStartAddress.Value;
          CurTCAddress := spinStartAddress.Value;
          CurIdx := 0;
          Started := False;
          for CurItem := 1 to spinNumItens.Value do
          begin
            for CurStructItem := 0 to StructItemsCount - 1 do
            begin
              //se é para criar o tag.
              //if the tag must be created.
              if not StructItem[CurStructItem].SkipTag then
              begin
                Started := True;
                if optPLCTagNumber.Checked then
                  begin
                    Item := TPLCTagNumber(CreateProc(TPLCTagNumber));

                    with TPLCTagNumber(Item) do
                    begin
                      PLCRack := S7TagBuilderForm.PLCRack.Value;
                      PLCSlot := S7TagBuilderForm.PLCSlot.Value;
                      PLCStation := S7TagBuilderForm.PLCStation.Value;
                      MemReadFunction := GetTagType;
                      if MemReadFunction = 4 then
                        MemFile_DB := CurDb;
                      MemAddress := CurAddress;

                      RefreshTime := StructItem[CurStructItem].TagScan;
                      TagType := StructItem[CurStructItem].TagType;
                      SwapBytes := StructItem[CurStructItem].SwapBytes;
                      SwapWords := StructItem[CurStructItem].SwapWords;

                      ProtocolDriver := TProtocolDriver(AProtocolDriver);
                    end;
                  end
                else if optPLCBlock.Checked then
                  begin
                    TPLCBlock(Block).Size := CurIdx + 1;
                    Item := TPLCBlockElement(CreateProc(TPLCBlockElement));
                    TPLCBlockElement(Item).plcblock := Block;
                    TPLCBlockElement(Item).Index := CurIdx;
                  end
                else
                  begin
                    Item := TPLCStructItem(CreateProc(TPLCStructItem));
                    TPLCStruct(Block).Size := CurIdx + GetCurWordSize;
                    TPLCStructItem(Item).PLCBlock := TPLCStruct(Block);
                    TPLCStructItem(Item).Index := CurIdx;
                    TPLCStructItem(Item).TagType := StructItem[CurStructItem].TagType;
                    TPLCStructItem(Item).SwapBytes := StructItem[CurStructItem].SwapBytes;
                    TPLCStructItem(Item).SwapWords := StructItem[CurStructItem].SwapWords;
                  end;

                Item.Name := GetItemName(StructItem[CurStructItem].TagName);
                InsertHook(Item);

                for CurBit := 0 to StructItem[CurStructItem].BitCount - 1 do
                begin
                  BitItem := TTagBit(CreateProc(TTagBit));
                  BitItem.EndBit := StructItem[CurStructItem].Bit[CurBit].EndBit;
                  BitItem.StartBit := StructItem[CurStructItem].Bit[CurBit].StartBit;
                  BitItem.Name := GetItemName(StructItem[CurStructItem].Bit[CurBit].TagName);
                  BitItem.PLCTag := Item;
                  InsertHook(BitItem);
                end;
              end;

              Inc(CurTCAddress);
              Inc(CurAddress, GetCurWordSize);
              if Started then
              begin
                if optPLCBlock.Checked then
                  Inc(CurIdx)
                else
                  Inc(CurIdx, GetCurWordSize);
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    S7TagBuilderForm.Destroy;
  end;
end;


initialization
  SetTagBuilderToolForSiemensS7ProtocolFamily(@OpenTagEditor)


end.

{$i ../common/language.inc}
{:
  @abstract(Implementation of BlockElementMapper for TPLCBlock.)
  @author(Juanjo Montero <juanjo.montero@gmail.com>)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - New Unit
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
unit blockstructtagassistant;

{$IFDEF FPC}
 {$mode objfpc}{$H+}
{$ENDIF}

interface

implementation

uses
  Classes, SysUtils, ProtocolTypes, plcblock, uelementmapper, ustructuremapper,
  plcblockelement, plcstructelement, tag, plcstruct, hsstrings, Controls,
  Dialogs, Math, StrUtils;

procedure BlockElementMapper(Target, OwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
var
  ADialog: TfrmMapElements;
  StartElement: Longint;
  EndElement: Longint;
  CurElement: Longint;
  ElementNumber: Longint;
  TagElement: TPLCBlockElement;
  FBlockStructTag: TPLCBlock;

  function GetNewTagElementName: Ansistring;
  var
    N: Ansistring;
  begin
    N := IntToStr(ElementNumber);
    Result := ADialog.ElementNames.Text;
    Result := StringReplace(Result, '%e', N, [rfReplaceAll]);

    N := Target.Name;
    Result := StringReplace(Result, '%t', N, [rfReplaceAll]);
  end;

begin
  if not Assigned(Target) then
  begin
    ShowMessage(SBlockRequired);
    Exit;
  end;

  if not (Target is TPLCBlock) then
  begin
    ShowMessage(SBlockRequired);
    Exit;
  end;

  FBlockStructTag := TPLCBlock(Target);

  ADialog := TfrmMapElements.Create(nil);
  try
    ADialog.StartIndex.MinValue := 0;
    ADialog.StartIndex.MaxValue := FBlockStructTag.Size - 1;

    ADialog.EndIndex.MinValue := 0;
    ADialog.EndIndex.MaxValue := FBlockStructTag.Size - 1;

    if ADialog.ShowModal = mrOk then
    begin

      if Pos('%e', ADialog.ElementNames.Text) = 0 then
        ADialog.ElementNames.Text := ADialog.ElementNames.Text + '%e';

      StartElement := ADialog.StartIndex.Value;
      EndElement := ADialog.EndIndex.Value;
      CurElement := StartElement;
      while CurElement <= EndElement do
      begin
        ElementNumber := IfThen(ADialog.ElementsStartFromOne.Checked, CurElement + 1, CurElement);
        TagElement := TPLCBlockElement(CreateProc(TPLCBlockElement));
        TagElement.Name := GetNewTagElementName;
        TagElement.plcblock := FBlockStructTag;
        TagElement.Index := CurElement;
        InsertHook(TagElement);
        Inc(CurElement);
      end;
    end;
  finally
    FreeAndNil(ADialog);
  end;
end;

procedure StructElementMapper(Target, OwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
var
  StructEditForm: TfrmStructureEditor;
  CurItem: Longint;
  CurIdx: Longint;
  CurStructItem: Longint;
  Item: TPLCStructItem;
  FBlockStructTag: TPLCStruct;

  function GetCurWordSize: Longint;
  begin
    case StructEditForm.StructItem[CurStructItem].TagType of
      pttDefault,
      pttShortInt,
      pttByte:  Result := 1;
      pttSmallInt,
      pttWord:  Result := 2;
      pttLongInt,
      pttDWord,
      pttFloat: Result := 4;
    end;
  end;

  function GetValueWithZeros(Value, EndValue: Longint; ToFill: Boolean): Ansistring;
  var
    NumDig: Longint;
    Dig: Longint;
    StrEndVal: Ansistring;
    Fill: Ansistring;
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

  function GetName(NamePattern: Ansistring): Ansistring;
  var
    HasAtLeastOneReplacement: Boolean;
  begin
    {
    %i  - Numero do Item comecando de 1
    %e  - Numero do Item comecando de 0
    %0i - Numero do Item comecando de 1, preenchido com zeros
    %0e - Numero do Item comecando de 0, preenchido com zeros

    %i  - Structure Item number, starting of 1
    %e  - Structure Item number, starting of 0
    %0i - Structure Item number, starting of 1, filled with zeros at the left
    %0e - Structure Item number, starting of 0, filled with zeros at the left
    }

    HasAtLeastOneReplacement := (Pos('%i', NamePattern) <> 0) or
      (Pos('%e', NamePattern) <> 0) or
      (Pos('%0i', NamePattern) <> 0) or
      (Pos('%0e', NamePattern) <> 0);
    if not HasAtLeastOneReplacement then
      NamePattern := NamePattern + '%i';

    Result := NamePattern;
    Result := StringReplace(Result, '%i', IntToStr(CurItem), [rfReplaceAll]);
    Result := StringReplace(Result, '%0i', GetValueWithZeros(CurItem, StructEditForm.SpinEdit1.Value, True), [rfReplaceAll]);
    Result := StringReplace(Result, '%e', IntToStr(CurItem - 1), [rfReplaceAll]);
    Result := StringReplace(Result, '%0e', GetValueWithZeros(CurItem - 1, StructEditForm.SpinEdit1.Value - 1, True), [rfReplaceAll]);
  end;

begin
  if not Assigned(Target) then
  begin
    ShowMessage(SBlockRequired);
    Exit;
  end;

  if not (Target is TPLCStruct) then
  begin
    ShowMessage(SBlockRequired);
    Exit;
  end;

  FBlockStructTag := TPLCStruct(Target);

  StructEditForm := TfrmStructureEditor.Create(nil);
  try
    if StructEditForm.ShowModal = mrOk then
    begin
      CurIdx := 0;
      for CurItem := 1 to StructEditForm.SpinEdit1.Value do
      begin
        for CurStructItem := 0 to StructEditForm.StructItemsCount - 1 do
        begin
          if not StructEditForm.StructItem[CurStructItem].SkipTag then
          begin
            Item := TPLCStructItem(CreateProc(TPLCStructItem));
            with Item do
            begin
              Name := GetName(StructEditForm.StructItem[CurStructItem].TagName);
              TagType := StructEditForm.StructItem[CurStructItem].TagType;
              SwapBytes := StructEditForm.StructItem[CurStructItem].SwapBytes;
              SwapWords := StructEditForm.StructItem[CurStructItem].SwapWords;
              Index := CurIdx;
              FBlockStructTag.Size := Max(FBlockStructTag.Size, CurIdx + GetCurWordSize);
              PLCBlock := FBlockStructTag as TPLCStruct;
            end;
            InsertHook(Item);
          end;
          Inc(CurIdx, GetCurWordSize);
        end;
      end;
    end;
  finally
    StructEditForm.Destroy;
  end;
end;


initialization
  SetBlockElementMapper(@BlockElementMapper);
  SetStructItemMapper(@StructElementMapper);


end.

{$i ../common/language.inc}
{:
  @abstract(Implementation of BitMapper for TPLCNumber.)
  @author(Juanjo Montero <juanjo.montero@gmail.com>)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - New Unit
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  02/2014 - Changed to the old behavior (Right click on PLCNumber Tag ->
  "Map bits" to open the bit mapper editor, whithout link with gui.
  ***********************************************************************
}
unit bitmappertagassistant;

{$IFDEF FPC}
 {$mode objfpc}{$H+}
{$ENDIF}

interface

implementation

uses
  Classes, SysUtils, ProtocolTypes, plcnumber, ubitmapper, hsstrings, Controls,
  Dialogs, TagBit;

  { TBitMapTagAssistant }

procedure OpenBitMapper(Target, OwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
var
  ADialog: TfrmBitMapper;
  BitNum: Longint;
  ByteNum: Longint;
  WordNum: Longint;
  StartBit: Longint;
  EndBit: Longint;
  CurBit: Longint;
  ABit: TTagBit;
  FNumberTag: TPLCNumberMappable;

  procedure _UpdateNumbers;
  begin
    BitNum := CurBit;
    if ADialog.BitNameStartsFrom1.Checked then
      Inc(BitNum);

    ByteNum := CurBit div 8;
    if ADialog.ByteNameStartsFrom1.Checked then
      Inc(ByteNum);

    WordNum := CurBit div 16;
    if ADialog.WordNameStartsFrom1.Checked then
      Inc(WordNum);
  end;

  function GetNewTagBitName: Ansistring;
  var
    N: Ansistring;
  begin
    N := IntToStr(BitNum);
    Result := ADialog.edtNamePattern.Text;
    Result := StringReplace(Result, '%b', N, [rfReplaceAll]);

    N := IntToStr(ByteNum);
    Result := StringReplace(Result, '%B', N, [rfReplaceAll]);

    N := IntToStr(WordNum);
    Result := StringReplace(Result, '%w', N, [rfReplaceAll]);

    N := FNumberTag.Name;
    Result := StringReplace(Result, '%t', N, [rfReplaceAll]);
  end;

begin
  if not Assigned(Target) then
  begin
    ShowMessage(SNumberTagRequired);
    Exit;
  end;

  if not (Target is TPLCNumberMappable) then
  begin
    ShowMessage(SNumberTagRequired);
    Exit;
  end;

  FNumberTag := TPLCNumberMappable(Target);

  ADialog := TfrmBitMapper.Create(nil);
  try
    if ADialog.ShowModal = mrOk then
    begin
      StartBit := 31 - ADialog.StringGrid1.Selection.Right;
      EndBit := 31 - ADialog.StringGrid1.Selection.Left;
      CurBit := StartBit;
      if ADialog.EachBitAsTag.Checked then
      begin
        while CurBit <= EndBit do
        begin
          _UpdateNumbers;
          ABit := TTagBit(CreateProc(TTagBit));
          ABit.Name := GetNewTagBitName;
          ABit.PLCTag := FNumberTag;
          ABit.endbit := CurBit;
          ABit.startbit := CurBit;
          InsertHook(ABit);
          Inc(CurBit);
        end;
      end
      else
      begin
        _UpdateNumbers;
        ABit := TTagBit(CreateProc(TTagBit));
        ABit.Name := GetNewTagBitName;
        ABit.PLCTag := FNumberTag;
        ABit.endbit := EndBit;
        ABit.startbit := StartBit;
        InsertHook(ABit);
      end;
    end;
  finally
    ADialog.Destroy;
  end;
end;

initialization

  SetTagBitMapper(@OpenBitMapper);

end.

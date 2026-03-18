unit tagstatuslist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, typinfo, FileUtil, Forms, Controls, Graphics, Dialogs,
  ButtonPanel, Grids, ExtCtrls, PLCTagNumber, ProtocolDriver, PLCBlock;

type
  TfrmTagStatusList = class(TForm)
    ButtonPanel1: TButtonPanel;
    StringGrid1: TStringGrid;
    Timer1: TTimer;
    procedure StringGrid1PrepareCanvas(Sender: TObject; ACol, ARow: Integer; AState: TGridDrawState);
    procedure Timer1Timer(Sender: TObject);
  end;

var
  frmTagStatusList: TfrmTagStatusList;

procedure ShowTagStatusList(const AProtocol: TProtocolDriver);


implementation


{$R *.lfm}


procedure ShowTagStatusList(const AProtocol: TProtocolDriver);
var
  AForm: TfrmTagStatusList;
begin
  AForm := TfrmTagStatusList.Create(AProtocol);
  try
    AForm.Timer1Timer(AForm.Timer1);
    AForm.ShowModal;
  finally
    FreeAndNil(AForm);
  end;
end;

procedure TfrmTagStatusList.Timer1Timer(Sender: TObject);
var
  AProtocol: TProtocolDriver;
  i: Integer;
begin
  if not (Owner is TProtocolDriver) then
    raise Exception.Create('Tag status list owner must be a TProtocolDriver!');

  AProtocol := Owner as TProtocolDriver;

  //StringGrid1.RowCount:=1;
  StringGrid1.RowCount := AProtocol.TagCount + 1;
  for i := 0 to AProtocol.TagCount - 1 do
  begin
    while StringGrid1.Rows[i + 1].Count < 15 do StringGrid1.Rows[i + 1].Add('');
    StringGrid1.Rows[i + 1].Strings[0] := AProtocol.TagName[i];
    StringGrid1.Rows[i + 1].Strings[1] := AProtocol.Tag[i].ClassName;

    if AProtocol.Tag[i] is TPLCTagNumber then
    begin
      with AProtocol.Tag[i] as TPLCTagNumber do
      begin
        StringGrid1.Rows[i+1].Strings[02] := GetEnumName(TypeInfo(LastSyncReadStatus), Integer(LastASyncReadStatus));
        StringGrid1.Rows[i+1].Strings[03] := IntToStr(MemAddress);
        StringGrid1.Rows[i+1].Strings[04] := IntToStr(MemFile_DB);
        StringGrid1.Rows[i+1].Strings[05] := IntToStr(MemReadFunction);
        StringGrid1.Rows[i+1].Strings[06] := IntToStr(MemSubElement);
        StringGrid1.Rows[i+1].Strings[07] := IntToStr(MemWriteFunction);
        StringGrid1.Rows[i+1].Strings[08] := ''; //inttostr(MemAddress);
        StringGrid1.Rows[i+1].Strings[09] := IntToStr(PLCRack);
        StringGrid1.Rows[i+1].Strings[10] := IntToStr(PLCSlot);
        StringGrid1.Rows[i+1].Strings[11] := IntToStr(PLCStation);
        StringGrid1.Rows[i+1].Strings[12] := IntToStr(RefreshTime);
        StringGrid1.Rows[i+1].Strings[13] := GetEnumName(TypeInfo(TagType), Integer(TagType));
        StringGrid1.Rows[i+1].Strings[14] := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', ValueTimestamp);
      end;
      Continue;
    end;

    if AProtocol.Tag[i] is TPLCBlock then
    begin
      with AProtocol.Tag[i] as TPLCBlock do
      begin
        StringGrid1.Rows[i+1].Strings[02] := GetEnumName(TypeInfo(LastSyncReadStatus), Integer(LastASyncReadStatus));
        StringGrid1.Rows[i+1].Strings[03] := IntToStr(MemAddress);
        StringGrid1.Rows[i+1].Strings[04] := IntToStr(MemFile_DB);
        StringGrid1.Rows[i+1].Strings[05] := IntToStr(MemReadFunction);
        StringGrid1.Rows[i+1].Strings[06] := IntToStr(MemSubElement);
        StringGrid1.Rows[i+1].Strings[07] := IntToStr(MemWriteFunction);
        StringGrid1.Rows[i+1].Strings[08] := ''; //inttostr(MemAddress);
        StringGrid1.Rows[i+1].Strings[09] := IntToStr(PLCRack);
        StringGrid1.Rows[i+1].Strings[10] := IntToStr(PLCSlot);
        StringGrid1.Rows[i+1].Strings[11] := IntToStr(PLCStation);
        StringGrid1.Rows[i+1].Strings[12] := IntToStr(RefreshTime);
        StringGrid1.Rows[i+1].Strings[13] := GetEnumName(TypeInfo(TagType), Integer(TagType));
        StringGrid1.Rows[i+1].Strings[14] := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', ValueTimestamp);
      end;
      Continue;
    end;
  end;
end;

procedure TfrmTagStatusList.StringGrid1PrepareCanvas(Sender: TObject; ACol, ARow: Integer; AState: TGridDrawState);
begin
  if ARow > 0 then
  begin
    if LowerCase(StringGrid1.Rows[ARow].Strings[2]) <> 'iook' then
    begin
      StringGrid1.Canvas.Brush.Color := clYellow;
      StringGrid1.Canvas.Pen.Color := clBlack;
    end;
  end;
end;

end.

{$i ../common/language.inc}
{:
  @abstract(Implementation of TagAssistant for WestASCII.)
  @author(Juanjo Montero <juanjo.montero@gmail.com>)


  ****************************** History  *******************************
  ***********************************************************************
  07/2013 - New Unit
  @author(Juanjo Montero <juanjo.montero@gmail.com>)
  ***********************************************************************
}
unit westasciitagassistant;

{$IFDEF FPC}
 {$mode objfpc}{$H+}
{$ENDIF}

interface

implementation

uses
  Classes, SysUtils, westasciidriver, ProtocolTypes, PLCTagNumber,
  uwesttagbuilder, Controls, Dialogs;

procedure OpenTagEditor(AProtocolDriver, AOwnerOfNewTags: TComponent; InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
var
  APLCTag: TPLCTagNumber;
  Ctrl: Longint;
  Variable: Longint;
  AForm: TWestTagBuilder;
  SCtrl: AnsiString;
  FormatMask: AnsiString;
begin
  AForm := TWestTagBuilder.Create(nil);
  try
    if AForm.ShowModal = mrOk then
    begin
      if AForm.ZeroFill.Checked and (AForm.AdrEnd.Value > 9) then
        FormatMask := '#00'
      else
        FormatMask := '#0';

      for Ctrl := AForm.AdrStart.Value to AForm.AdrEnd.Value do
      begin
        SCtrl := FormatFloat(FormatMask, Ctrl);
        for Variable := 0 to $1b do
        begin
          if AForm.Variaveis[Variable].Enabled.Checked then
          begin
            if Pos('%a', AForm.Variaveis[Variable].TagName.Text) = 0 then
            begin
              AForm.Variaveis[Variable].TagName.Text := AForm.Variaveis[Variable].TagName.Text + '%a';
            end;
            APLCTag := TPLCTagNumber(CreateProc(TPLCTagNumber));
            APLCTag.Name := StringReplace(AForm.Variaveis[Variable].TagName.Text, '%a', SCtrl, [rfReplaceAll]);
            APLCTag.MemAddress := Variable;
            APLCTag.PLCStation := Ctrl;
            APLCTag.RefreshTime := AForm.Variaveis[Variable].Scan.Value;
            APLCTag.ProtocolDriver := TWestASCIIDriver(AProtocolDriver);
            InsertHook(APLCTag);
          end;
        end;
      end;
    end;
  finally
    AForm.Destroy;
  end;
end;


initialization
  SetTagBuilderToolForWest6100Protocol(@OpenTagEditor);


end.

{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
Unit que implementa o West 6100+ TagBuilder assistente.
@author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
Unit that implements the West 6100+ TagBuilder wizard.
@author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
unit uwesttagbuilder;

interface

uses
  {$IFDEF FPC}
  LCLIntf, LResources,
  {$ENDIF}
  SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, Spin, ExtCtrls;

type
  TVarItem = record
    Enabled: TCheckBox;
    TagName: TEdit;
    Scan: TSpinEdit;
  end;

  TWestTagBuilder = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    AdrStart: TSpinEdit;
    Label2: TLabel;
    AdrEnd: TSpinEdit;
    ZeroFill: TCheckBox;
    ScrollBox1: TScrollBox;
    Panel2: TPanel;
    Panel3: TPanel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure OnTagNameExit(Sender: TObject);
    procedure OnTagNameEnter(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    VarDesc: array [$00..$1B] of AnsiString;
    TagNames: array [$00..$1B] of AnsiString;
    OldTagName: array [$00..$1B] of AnsiString;
  public
    Variaveis: array [$00..$1B] of TVarItem;
    destructor Destroy; override;
  end;

var
  WestTagBuilder: TWestTagBuilder;

implementation


{$IFNDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$IF defined(FPC) AND (FPC_FULLVERSION >= 20400) }
    {$R uwesttagbuilder.lfm}
  {$IFEND}
{$ENDIF}

uses
  hsstrings;


procedure TWestTagBuilder.Button1Click(Sender: TObject);
var
  i: Longint;
  AtLeastOne: Boolean;
begin
  AtLeastOne := False;
  for i := 0 to $1B do
    AtLeastOne := AtLeastOne or Variaveis[i].Enabled.Checked;

  if not AtLeastOne then
    raise Exception.Create(SCheckAtLeastOneVariable);
end;

destructor TWestTagBuilder.Destroy;
var
  i: Longint;
begin
  for i := 0 to $1b do
  begin
    Variaveis[i].Enabled.Destroy;
    Variaveis[i].TagName.Destroy;
    Variaveis[i].Scan.Destroy;
  end;

  inherited Destroy;
end;

procedure TWestTagBuilder.FormCreate(Sender: TObject);
var
  i: Longint;
begin
  VarDesc[$00] := 'SetPoint (SP)';
  VarDesc[$01] := 'Process Variable (PV)';
  VarDesc[$02] := 'Power Output value';
  VarDesc[$03] := 'Controller status';
  VarDesc[$04] := 'Scale Range Max';
  VarDesc[$05] := 'Scale Range Min';
  VarDesc[$06] := 'Scale Range Dec. Point';
  VarDesc[$07] := 'Input filter time constant';
  VarDesc[$08] := 'Output 1 Power Limit';
  VarDesc[$09] := 'Output 1 cycle time';
  VarDesc[$0A] := 'Output 2 cycle time';
  VarDesc[$0B] := 'Recorder output scale max';
  VarDesc[$0C] := 'Recorder output scale min';
  VarDesc[$0D] := 'SetPoint ramp rate';
  VarDesc[$0E] := 'Setpoint high limit';
  VarDesc[$0F] := 'Setpoint low limit';
  VarDesc[$10] := 'Alarm 1 value';
  VarDesc[$11] := 'Alarm 2 value';
  VarDesc[$12] := 'Rate (Derivative time constant)';
  VarDesc[$13] := 'Reset (Integral time constant)';
  VarDesc[$14] := 'Manual time reset (BIAS)';
  VarDesc[$15] := 'ON/OFF diferential';
  VarDesc[$16] := 'Overlap/Deadband';
  VarDesc[$17] := 'Proportional band 1 value';
  VarDesc[$18] := 'Proportional band 2 value';
  VarDesc[$19] := 'PV Offset';
  VarDesc[$1A] := 'Arithmetic deviation';
  VarDesc[$1B] := 'Arithmetic deviation'; // checar estas descri��es.

  TagNames[$00] := 'WEST%a_SP';
  TagNames[$01] := 'WEST%a_PV';
  TagNames[$02] := 'WEST%a_Power_Output_value';
  TagNames[$03] := 'WEST%a_Controller_status';
  TagNames[$04] := 'WEST%a_Scale_Range_Max';
  TagNames[$05] := 'WEST%a_Scale_Range_Min';
  TagNames[$06] := 'WEST%a_Scale_Range_Decimal_Point';
  TagNames[$07] := 'WEST%a_Input_filter_time_constant';
  TagNames[$08] := 'WEST%a_Output_1_Power_Limit';
  TagNames[$09] := 'WEST%a_Output_1_cycle_time';
  TagNames[$0A] := 'WEST%a_Output_2_cycle_time';
  TagNames[$0B] := 'WEST%a_Recorder_output_scale_max';
  TagNames[$0C] := 'WEST%a_Recorder_output_scale_min';
  TagNames[$0D] := 'WEST%a_SetPoint_ramp_rate';
  TagNames[$0E] := 'WEST%a_Setpoint_high_limit';
  TagNames[$0F] := 'WEST%a_Setpoint_low_limit';
  TagNames[$10] := 'WEST%a_Alarm_1_value';
  TagNames[$11] := 'WEST%a_Alarm_2_value';
  TagNames[$12] := 'WEST%a_Derivative_time_constant';
  TagNames[$13] := 'WEST%a_Integral_time_constant';
  TagNames[$14] := 'WEST%a_Manual_time_reset';
  TagNames[$15] := 'WEST%a_ON_OFF_diferential';
  TagNames[$16] := 'WEST%a_Overlap_Deadband';
  TagNames[$17] := 'WEST%a_Proportional_band_1_value';
  TagNames[$18] := 'WEST%a_Proportional_band_2_value';
  TagNames[$19] := 'WEST%a_PV_Offset';
  TagNames[$1A] := 'WEST%a_Arithmetic_deviation1';
  TagNames[$1B] := 'WEST%a_Arithmetic_deviation2'; //_checar_estas_descri��es.

  ScrollBox1.Visible := False;

  for i := 0 to $1b do
  begin
    Variaveis[i].Enabled := TCheckBox.Create(Self);
    Variaveis[i].Enabled.Parent := ScrollBox1;
    Variaveis[i].Enabled.Left := 5;
    Variaveis[i].Enabled.Top := 4 + (i * 24);
    Variaveis[i].Enabled.Width := 186;
    Variaveis[i].Enabled.Caption := VarDesc[i];

    Variaveis[i].TagName := TEdit.Create(Self);
    Variaveis[i].TagName.Parent := ScrollBox1;
    Variaveis[i].TagName.Left := 196;
    Variaveis[i].TagName.Top := 2 + (i * 24);
    Variaveis[i].TagName.Height := 22;
    Variaveis[i].TagName.Width := 202;
    Variaveis[i].TagName.Text := TagNames[i];
    Variaveis[i].TagName.Tag := i;

    Variaveis[i].Scan := TSpinEdit.Create(Self);
    Variaveis[i].Scan.Parent := ScrollBox1;
    Variaveis[i].Scan.Left := 402;
    Variaveis[i].Scan.Top := 2 + (i * 24);
    Variaveis[i].Scan.Height := 22;
    Variaveis[i].Scan.Width := 84;
    Variaveis[i].Scan.MinValue := 1; //1 milisegundo
    Variaveis[i].Scan.MaxValue := 7200000; //2 horas m�ximo
    Variaveis[i].Scan.Value := 1000; //1 segundo
  end;

  ScrollBox1.Visible := True;
end;

procedure TWestTagBuilder.OnTagNameEnter(Sender: TObject);
begin
  if Sender is TEdit then
    with Sender as TEdit do
    begin
      OldTagName[Tag] := Text;
    end;
end;

procedure TWestTagBuilder.OnTagNameExit(Sender: TObject);
var
  i: Longint;
begin
  if Sender is TEdit then
    with Sender as TEdit do
    begin
      if (trim(Text) = '') or (not (Text[1] in ['A'..'Z', 'a'..'z', '_'])) then
      begin
        Text := OldTagName[Tag];
        Exit;
      end;

      for i := 0 to $1b do
        if Tag <> i then
          if Text = Variaveis[i].TagName.Text then
          begin
            Text := OldTagName[Tag];
            Exit;
          end;
    end;
end;


{$IFDEF FPC }
  {$IF defined(FPC) AND (FPC_FULLVERSION < 20400) }
initialization
  {$i uwesttagbuilder.lrs}
  {$IFEND}
{$ENDIF}


end.

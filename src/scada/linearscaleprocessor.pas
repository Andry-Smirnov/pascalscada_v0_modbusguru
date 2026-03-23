{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Unit that implements a linear scale.)
}
unit LinearScaleProcessor;

interface

uses
  SysUtils, Classes, ValueProcessor;

type

  {:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  Linear scale component.
  @seealso(TPIPE)
  @seealso(TScaleProcessor) }
  TLinearScaleProcessor = class(TScaleProcessor)
  private
    function GetSysMin: Double;
    function GetSysMax: Double;
    function GetPLCMin: Double;
    function GetPLCMax: Double;
    procedure SetSysMin(AValue: Double);
    procedure SetSysMax(AValue: Double);
    procedure SetPLCMin(AValue: Double);
    procedure SetPLCMax(AValue: Double);
  protected
    FSysMin: Double;
    FSysMax: Double;
    FRawMin: Double;
    FRawMax: Double;
    FSysMinLoaded: Double;
    FSysMaxLoaded: Double;
    FRawMinLoaded: Double;
    FRawMaxLoaded: Double;
    //: @exclude
    procedure Loaded; override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    {: Convert a value from the device scale to the system scale.
    @param(sender Object that calls the convertion.)
    @param(Entrada Device value to be converted.)
    @returns(The value converted to the system Scale.) }
    function SetInGetOut(Sender: TComponent; Entrada: Double): Double; override;
    {: Convert a value from the device scale to the system scale.
    @param(sender Object that calls the convertion.)
    @param(Entrada Device value to be converted.)
    @returns(The value converted to the system Scale.) }
    function SetOutGetIn(Sender: TComponent; Saida: Double): Double; override;
  published
    //: Minimum value of the system scale (output).
    property SysMin: Double read GetSysMin write SetSysMin stored True;
    //: Maximum value of the device (PLC) scale (input).
    property SysMax: Double read GetSysMax write SetSysMax stored True;
    //: Minimum value of the device (PLC) scale (input).
    property PLCMin: Double read GetPLCMin write SetPLCMin stored True;
    //: Maximum value of the device (PLC) scale (input).
    property PLCMax: Double read GetPLCMax write SetPLCMax stored True;
  end;


implementation


uses
  hsstrings;

constructor TLinearScaleProcessor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSysMin := 0;
  FSysMax := 100;
  FRawMin := 0;
  FRawMax := 32000;
end;

function TLinearScaleProcessor.GetSysMin: Double;
begin
  Result := FSysMin;
end;

function TLinearScaleProcessor.GetSysMax: Double;
begin
  Result := FSysMax;
end;

function TLinearScaleProcessor.GetPLCMin: Double;
begin
  Result := FRawMin;
end;

function TLinearScaleProcessor.GetPLCMax: Double;
begin
  Result := FRawMax;
end;

procedure TLinearScaleProcessor.SetSysMin(AValue: Double);
begin
  if [csLoading, csReading] * ComponentState = [] then
    FSysMin := AValue
  else
    FSysMinLoaded := AValue;
end;

procedure TLinearScaleProcessor.SetSysMax(AValue: Double);
begin
  if [csLoading, csReading] * ComponentState = [] then
    FSysMax := AValue
  else
    FSysMaxLoaded := AValue;
end;

procedure TLinearScaleProcessor.SetPLCMin(AValue: Double);
begin
  if [csLoading, csReading] * ComponentState = [] then
    FRawMin := AValue
  else
    FRawMinLoaded := AValue;
end;

procedure TLinearScaleProcessor.SetPLCMax(AValue: Double);
begin
  if [csLoading, csReading] * ComponentState = [] then
    FRawMax := AValue
  else
    FRawMaxLoaded := AValue;
end;

function TLinearScaleProcessor.SetInGetOut(Sender: TComponent; Entrada: Double): Double;
var
  Divisor: Double;
begin
  Divisor := (FRawMax - FRawMin);
  if Divisor = 0 then Divisor := 1;
  Result := (Entrada - FRawMin) * (FSysMax - FSysMin) / Divisor + FSysMin;
end;

function TLinearScaleProcessor.SetOutGetIn(Sender: TComponent; Saida: Double): Double;
var
  Divisor: Double;
begin
  Divisor := (FSysMax - FSysMin);
  if Divisor = 0 then Divisor := 1;
  Result := (Saida - FSysMin) * (FRawMax - FRawMin) / Divisor + FRawMin;
end;

procedure TLinearScaleProcessor.Loaded;
begin
  inherited Loaded;

  FSysMin := FSysMinLoaded;
  FSysMax := FSysMaxLoaded;
  FRawMin := FRawMinLoaded;
  FRawMax := FRawMaxLoaded;

  //if (FSysMin=FSysMax) or (FRawMin=FRawMax) then
  //  raise Exception.Create(SinvalidValue);
end;

end.

{$i ../common/language.inc}
{:
  @abstract(User defined scales.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
unit
UserScale;

interface

uses
  Classes, ValueProcessor;

type
  //: Definition of event used to process values.
  TScaleEvent = procedure(Sender: TObject; const Input: Double; var Output: Double) of object;

   {: @abstract(Classe para processamento de escalas personalizaveis pelo usuário.)
   @author(Fabio Luis Girardi <fabio@pascalscada.com>) }
  TUserScale = class(TScaleProcessor)
  private
    PPLCToUser: TScaleEvent;
    PUserToPLC: TScaleEvent;
  public
     {: @seealso(TScaleProcessor.SetInGetOut)
        @seealso(OnPLCToUser) }
    function SetInGetOut(Sender: TComponent; Entrada: Double): Double; override;
     {: @seealso(TScaleProcessor.SetOutGetIn)
        @seealso(OnUserToPLC) }
    function SetOutGetIn(Sender: TComponent; Saida: Double): Double; override;
  published
     {: Event called from procedure SetInGetOut to allow the developer make your own scale.
        The value is comming from device and going to final user.
     The event paremeters are the fallowing:
     Sender => Scale that call the conversion.
     Input  => Value comming from device.
     Output => Converted value. }
    property OnPLCToUser: TScaleEvent read PPLCToUser write PPLCToUser;
     {: Event called from procedure SetOutGetIn to allow the developer make your own scale.
        The value is comming from the user (a tag write) and going to device.
     The event paremeters are the fallowing:
     Sender => Scale that call the conversion.
     Input  => Value comming from user.
     Output => Converted value to sent to device. }
    property OnUserToPLC: TScaleEvent read PUserToPLC write PUserToPLC;
  end;


implementation


function TUserScale.SetInGetOut(Sender: TComponent; Entrada: Double): Double;
begin
  if Assigned(PPLCToUser) then
  begin
    Result := Entrada;
    PPLCToUser(Sender, Entrada, Result);
  end
  else
    Result := Entrada;
end;

function TUserScale.SetOutGetIn(Sender: TComponent; Saida: Double): Double;
begin
  if Assigned(PUserToPLC) then
  begin
    Result := Saida;
    PUserToPLC(Sender, Saida, Result);
  end
  else
    Result := Saida;
end;

end.

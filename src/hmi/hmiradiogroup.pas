{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Define um controle de opções para reading/escrita de valores de tags numéricos.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Unit that implements a multiple-options control to read and write
  values in numeric tags.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
unit HMIRadioGroup;

interface

uses
  Classes, SysUtils,
  {$IFDEF FPC}
  LResources,
  {$ENDIF}
  Controls, Graphics,
  Dialogs, ExtCtrls, HMITypes, PLCTag, ProtocolTypes, Tag;

type
  {$IFDEF PORTUGUES}
  {:
    @abstract(Classe de controle de multiplas opções para reading/escrita de
    valores de tags numéricos.)
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
    @abstract(Class of multiple-options control to read and write
    values in numeric tags.)
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  THMIRadioGroup = class(TRadioGroup, IHMIInterface)
  private
    FRegInSecMan: Boolean;
    FTag: TPLCTag;
    FIsEnabled: Boolean;
    FIsEnabledBySecurity: Boolean;
    FDefaultIndex: Longint;
    FIgnore: Boolean;
    FLoaded: Boolean;

    FSecurityCode: UTF8String;

    procedure SetSecurityCode(ASecurityCode: UTF8String);

    //: @seealso(IHMIInterface.SetHMITag)
    procedure SetHMITag(APLCTag: TPLCTag);                    //seta um tag
    //: @seealso(IHMIInterface.GetHMITag)
    function GetHMITag: TPLCTag;

    //: @seealso(IHMIInterface.GetControlSecurityCode)
    function GetControlSecurityCode: UTF8String;
    //: @seealso(IHMIInterface.CanBeAccessed)
    procedure CanBeAccessed(A: Boolean);
    //: @seealso(IHMIInterface.MakeUnsecure)
    procedure MakeUnsecure;

    procedure SetDefaultIndex(AValue: Longint);
    function GetIndex: Longint;
    procedure SetIndex(AValue: Longint);

    procedure WriteFaultCallBack(Sender: TObject);
    procedure TagChangeCallBack(Sender: TObject);
    procedure RemoveTagCallBack(Sender: TObject);
  protected
    {$IFNDEF FPC}
    procedure Click; override;
    {$ENDIF}
    //: @exclude
    procedure SetEnabled(AEnabled: Boolean); override;
    //: @exclude
    procedure CheckItemIndexChanged; {$IFDEF FPC} override; {$ENDIF}
    //: @exclude
    procedure Loaded; override;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor Destroy; override;
    procedure RefreshRadioGroup(Data: PtrInt);
  published
    {$IFDEF PORTUGUES}
    //: @name retorna qual a opção selecionada.
    {$ELSE}
    //: @name tells what's the index of selected option.
    {$ENDIF}
    property ItemIndex: Longint read GetIndex write SetIndex;

    //: @exclude
    property Enabled: Boolean read FIsEnabled write SetEnabled;

    {$IFDEF PORTUGUES}
    {:
    Tag numérico que será usado pelo controle.
    @seealso(TPLCTag)
    @seealso(TPLCTagNumber)
    @seealso(TPLCBlockElement)
    @seealso(TPLCStructItem)
    }
    {$ELSE}
    {:
    Numeric tag that will be linked with the control.
    @seealso(TPLCTag)
    @seealso(TPLCTagNumber)
    @seealso(TPLCBlockElement)
    @seealso(TPLCStructItem)
    }
    {$ENDIF}
    property PLCTag: TPLCTag read GetHMITag write SetHMITag;

    {$IFDEF PORTUGUES}
    {:
    Caso o valor inteiro do tag não esteja entre as opções oferecidas, usa o valor
    de @name.
    }
    {$ELSE}
    {:
    If the LongInt value of tag doesn't match with one of the control list, uses
    the value of @name.
    }
    {$ENDIF}
    property DefaultIndex: Longint read FDefaultIndex write SetDefaultIndex default -1;

    {$IFDEF PORTUGUES}
    //: Codigo de segurança que libera acesso ao controle
    {$ELSE}
    //: Security code that allows access to control.
    {$ENDIF}
    property SecurityCode: UTF8String read FSecurityCode write SetSecurityCode;
  end;


implementation


uses
  hsstrings, ControlSecurityManager, Forms;


constructor THMIRadioGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRegInSecMan := GetControlSecurityManager.RegisterControl(Self as IHMIInterface);
  if not FRegInSecMan then
  begin
    {$IFNDEF WINDOWS}
    WriteLn('FIX-ME: Failed to register class ', ClassName, ' instace with name="', Name, '" in the ControlSecurityManager?', {$i %FILE%}, ':', {$i %LINE%});
    {$ENDIF}
  end;
  FIgnore := False;
  FLoaded := False;
  FIsEnabled := True;
  FDefaultIndex := -1;
end;

destructor THMIRadioGroup.Destroy;
begin
  if FRegInSecMan then
    GetControlSecurityManager.UnRegisterControl(Self as IHMIInterface)
  else
  begin
    {$IFNDEF WINDOWS}
    WriteLn('FIX-ME: Why class ', ClassName, ', instace name="', Name, '" ins''t registered in ControlSecurityManager?', {$i %FILE%}, ':', {$i %LINE%});
    {$ENDIF}
  end;

  Application.RemoveAsyncCalls(Self);
  if FTag <> nil then
    FTag.RemoveAllHandlersFromObject(Self);
  inherited Destroy;
end;

procedure THMIRadioGroup.RefreshRadioGroup(Data: PtrInt);
var
  Value: Double;
begin
  if [csReading, csLoading, csDestroying] * ComponentState <> [] then Exit;

  Value := 0;

  if (FTag <> nil) and Supports(FTag, ITagNumeric) then
    Value := (FTag as ITagNumeric).Value;

  FIgnore := True;
  if (Value >= 0) and (Value < Items.Count) then
    inherited ItemIndex := Trunc(Value)
  else
    inherited ItemIndex := FDefaultIndex;
  FIgnore := False;
end;

procedure THMIRadioGroup.SetSecurityCode(ASecurityCode: UTF8String);
begin
  if Trim(ASecurityCode) = '' then
    Self.CanBeAccessed(True)
  else
    with GetControlSecurityManager do
    begin
      ValidateSecurityCode(ASecurityCode);
      if not SecurityCodeExists(ASecurityCode) then
        RegisterSecurityCode(ASecurityCode);

      Self.CanBeAccessed(CanAccess(ASecurityCode));
    end;

  FSecurityCode := ASecurityCode;
end;

//link with tags
procedure THMIRadioGroup.SetHMITag(APLCTag: TPLCTag);
begin
  //se o tag esta entre um dos aceitos.

  //Check if the tag is valid (only numeric tags).
  if (APLCTag <> nil) and (not Supports(APLCTag, ITagNumeric)) then
    raise Exception.Create(SonlyNumericTags);

  //se ja estou associado a um tag, remove
  //remove the old link.
  if FTag <> nil then
  begin
    FTag.RemoveAllHandlersFromObject(Self);
  end;

  //adiona o callback para o novo tag
  //link with the new tag.
  if APLCTag <> nil then
  begin
    APLCTag.AddWriteFaultHandler(@WriteFaultCallBack);
    APLCTag.AddTagChangeHandler(@TagChangeCallBack);
    APLCTag.AddRemoveTagHandler(@RemoveTagCallBack);
    FTag := APLCTag;
    RefreshRadioGroup(0);
  end;
  FTag := APLCTag;
end;

function THMIRadioGroup.GetHMITag: TPLCTag;
begin
  Result := FTag;
end;

function THMIRadioGroup.GetControlSecurityCode: UTF8String;
begin
  Result := FSecurityCode;
end;

procedure THMIRadioGroup.CanBeAccessed(A: Boolean);
begin
  FIsEnabledBySecurity := A;
  SetEnabled(FIsEnabled);
end;

procedure THMIRadioGroup.MakeUnsecure;
begin
  FSecurityCode := '';
  CanBeAccessed(True);
end;

procedure THMIRadioGroup.SetEnabled(AEnabled: Boolean);
begin
  FIsEnabled := AEnabled;
  inherited SetEnabled(FIsEnabled and FIsEnabledBySecurity);
end;

procedure THMIRadioGroup.CheckItemIndexChanged;
begin
  {$IFDEF FPC}
   inherited CheckItemIndexChanged;
  {$ENDIF}

  if [csLoading, csReading, csDestroying] * ComponentState <> [] then
    Exit;

  if (FLoaded) and (not FIgnore) then
    if (FTag <> nil) and Supports(FTag, ITagNumeric) then
      (FTag as ITagNumeric).Value := ItemIndex;
end;

procedure THMIRadioGroup.Loaded;
begin
  inherited Loaded;
  CanBeAccessed(GetControlSecurityManager.CanAccess(GetControlSecurityCode));
  FLoaded := True;
  TagChangeCallBack(Self);
end;

procedure THMIRadioGroup.SetDefaultIndex(AValue: Longint);
begin
  if AValue < (-1) then
    FDefaultIndex := -1
  else
    FDefaultIndex := AValue;
  RefreshRadioGroup(0);
end;

function THMIRadioGroup.GetIndex: Longint;
begin
  Result := inherited ItemIndex;
end;

procedure THMIRadioGroup.SetIndex(AValue: Longint);
begin
  inherited ItemIndex := AValue;
end;

{$IFNDEF FPC}
procedure THMIRadioGroup.Click;
begin
  CheckItemIndexChanged;
  inherited Click;
end;
{$ENDIF}

procedure THMIRadioGroup.WriteFaultCallBack(Sender: TObject);
begin
  TagChangeCallBack(Self);
end;

procedure THMIRadioGroup.TagChangeCallBack(Sender: TObject);
begin
  if Application.Flags * [AppDoNotCallAsyncQueue] = [] then
    Application.QueueAsyncCall(@RefreshRadioGroup, 0);
end;

procedure THMIRadioGroup.RemoveTagCallBack(Sender: TObject);
begin
  if FTag = Sender then
    FTag := nil;
end;

end.

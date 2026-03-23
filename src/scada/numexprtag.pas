unit numexprtag;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpexprpars, PLCNumber, ProtocolTypes, Tag;

type

  { TNumericExprTag }

  TNumericExprTag = class(TPLCNumberMappable, ITagInterface, ITagNumeric)
  private
    FExpr: string;
    FLastASyncWriteStatus: TProtocolIOResult;
    FLastEvalutionError: string;
    FLastSyncReadStatus: TProtocolIOResult;
    FLastSyncWriteStatus: TProtocolIOResult;
    FVarA: TPLCNumber;
    FVarB: TPLCNumber;
    FVarC: TPLCNumber;
    FVarD: TPLCNumber;
    FVarE: TPLCNumber;
    FVarF: TPLCNumber;
    FVarG: TPLCNumber;
    FVarH: TPLCNumber;
    FVarI: TPLCNumber;
    FVarJ: TPLCNumber;
    procedure CalculateValue;
    procedure ExprIfThen(var Result: TFPExpressionResult; const Args: TExprParameterArray);
    function GetValueTimestamp: TDatetime;
    function GetVariantValue: Variant;
    function IsValidValue(AValue: Variant): Boolean;
    procedure SetExpr(AValue: string);
    procedure SetVarA(AValue: TPLCNumber);
    procedure SetVarB(AValue: TPLCNumber);
    procedure SetVarC(AValue: TPLCNumber);
    procedure SetVarD(AValue: TPLCNumber);
    procedure SetVarE(AValue: TPLCNumber);
    procedure SetVarF(AValue: TPLCNumber);
    procedure SetVarG(AValue: TPLCNumber);
    procedure SetVarH(AValue: TPLCNumber);
    procedure SetVarI(AValue: TPLCNumber);
    procedure SetVariantValue(AValue: Variant);
    procedure SetVarJ(AValue: TPLCNumber);
    procedure TagRemovedCallback(Sender: TObject);
    procedure VarTagChanged(Sender: TObject);
  protected
    procedure SetValueRaw(AValue: Double); override;
    function GetValueRaw: Double; override;
  public
    procedure Loaded; override;
    destructor Destroy; override;
  published
    property A: TPLCNumber read FVarA write SetVarA;
    property B: TPLCNumber read FVarB write SetVarB;
    property C: TPLCNumber read FVarC write SetVarC;
    property D: TPLCNumber read FVarD write SetVarD;
    property E: TPLCNumber read FVarE write SetVarE;
    property F: TPLCNumber read FVarF write SetVarF;
    property G: TPLCNumber read FVarG write SetVarG;
    property H: TPLCNumber read FVarH write SetVarH;
    property I: TPLCNumber read FVarI write SetVarI;
    property J: TPLCNumber read FVarJ write SetVarJ;
    property Expression: string read FExpr write SetExpr;
    property ScaleProcessor;
    property LastEvalutionError: string read FLastEvalutionError;
    property OnValueChangeFirst;
    property OnValueChangeLast;
    property OnReadFail;
    property OnWriteFail;
  end;


implementation


uses
  Variants, Math, hsstrings;


  { TNumericExprTag }

function TNumericExprTag.GetVariantValue: Variant;
begin
  Result := Value;
end;

procedure TNumericExprTag.SetVariantValue(AValue: Variant);
var
  Aux: Double;
begin
  if VarIsNumeric(AValue) then
    begin
      Value := AValue;
    end
  else if VarIsStr(AValue) then
    begin
      if TryStrToFloat(AValue, Aux) then
        Value := Aux
      else
        raise Exception.Create(SinvalidValue);
    end
  else if VarIsType(AValue, varboolean) then
    begin
      if AValue = True then
        Value := 1
      else
        Value := 0;
    end
  else
    raise Exception.Create(SinvalidValue);
end;

function TNumericExprTag.IsValidValue(AValue: Variant): Boolean;
var
  Aux: Double;
  AValueStr: AnsiString;
begin
  AValueStr := AValue;
  Result := VarIsNumeric(AValue) or
    (VarIsStr(AValue) and TryStrToFloat(AValueStr, Aux)) or
    VarIsType(AValue, varboolean);
end;

function TNumericExprTag.GetValueTimestamp: TDatetime;
begin
  Result := PValueTimeStamp;
end;

procedure TNumericExprTag.ExprIfThen(var Result: TFPExpressionResult; const Args: TExprParameterArray);
const
{$IF FPC_FULLVERSION >= 030200}
  TypeNames: array [Low(TResultType)..High(TResultType)] of string = ('Boolean', 'Integer', 'Float', 'DateTime', 'String', 'Currency');
{$ELSE}
  TypeNames: array [Low(TResultType)..High(TResultType)] of string = ('Boolean', 'Integer', 'Float', 'DateTime', 'String');
{$ENDIF}
begin
  if Length(Args) <> 3 then
    raise Exception.Create('IfThen param count mismatch.');

  if Args[0].ResultType <> rtBoolean then
    raise Exception.Create('IfThen param0 (condition) type mismatch. Expected Boolean, got ' + TypeNames[Args[0].ResultType]);

  if Args[1].ResultType <> rtFloat then
    raise Exception.Create('IfThen param1 (valueTrue) type mismatch. Expected Float, got ' + TypeNames[Args[1].ResultType]);

  if Args[2].ResultType <> rtFloat then
    raise Exception.Create('IfThen param2 (valueFalse) type mismatch. Expected Float, got ' + TypeNames[Args[2].ResultType]);

  Result.resFloat := IfThen(Args[0].ResBoolean, Args[1].resFloat, Args[2].resFloat);
end;

procedure TNumericExprTag.CalculateValue;
var
  AParser: TFPExpressionParser;
  ExprValue: TExprFloat;
begin
  if [csLoading, csReading] * ComponentState = [] then
  begin
    AParser := TFPExpressionParser.Create(Self);
    try
      AParser.BuiltIns := [bcMath, bcBoolean, bcUser];
      AParser.Identifiers.AddFunction('IfThen', 'F', 'BFF', @ExprIfThen);
      if Assigned(FVarA) then
        AParser.Identifiers.AddFloatVariable('A', (FVarA as ITagNumeric).GetValue);

      if Assigned(FVarB) then
        AParser.Identifiers.AddFloatVariable('B', (FVarB as ITagNumeric).GetValue);

      if Assigned(FVarC) then
        AParser.Identifiers.AddFloatVariable('C', (FVarC as ITagNumeric).GetValue);

      if Assigned(FVarD) then
        AParser.Identifiers.AddFloatVariable('D', (FVarD as ITagNumeric).GetValue);

      if Assigned(FVarE) then
        AParser.Identifiers.AddFloatVariable('E', (FVarE as ITagNumeric).GetValue);

      if Assigned(FVarF) then
        AParser.Identifiers.AddFloatVariable('F', (FVarF as ITagNumeric).GetValue);

      if Assigned(FVarG) then
        AParser.Identifiers.AddFloatVariable('G', (FVarG as ITagNumeric).GetValue);

      if Assigned(FVarH) then
        AParser.Identifiers.AddFloatVariable('H', (FVarH as ITagNumeric).GetValue);

      if Assigned(FVarI) then
        AParser.Identifiers.AddFloatVariable('I', (FVarI as ITagNumeric).GetValue);

      if Assigned(FVarJ) then
        AParser.Identifiers.AddFloatVariable('J', (FVarJ as ITagNumeric).GetValue);

      FLastEvalutionError := 'OK';
      try
        AParser.Expression := FExpr;
        ExprValue := AParser.Evaluate.ResFloat;
        if ExprValue <> PValueRaw then
        begin
          PValueRaw := ExprValue;
          PValueTimeStamp := Now;
          NotifyChange;
        end;
      except
        on E: Exception do
        begin
          FLastEvalutionError := E.Message;
          NotifyReadFault;
        end;
      end;
    finally
      AParser.Free;
    end;
  end;
end;

procedure TNumericExprTag.SetExpr(AValue: string);
begin
  if FExpr = AValue then Exit;
  FExpr := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarA(AValue: TPLCNumber);
begin
  if FVarA = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarA) then
  begin
    FVarA.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarA := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarB(AValue: TPLCNumber);
begin
  if FVarB = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarB) then
  begin
    FVarB.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarB := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarC(AValue: TPLCNumber);
begin
  if FVarC = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarC) then
  begin
    FVarC.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarC := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarD(AValue: TPLCNumber);
begin
  if FVarD = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarD) then
  begin
    FVarD.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarD := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarE(AValue: TPLCNumber);
begin
  if FVarE = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarE) then
  begin
    FVarE.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarE := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarF(AValue: TPLCNumber);
begin
  if FVarF = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarF) then
  begin
    FVarF.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarF := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarG(AValue: TPLCNumber);
begin
  if FVarG = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarG) then
  begin
    FVarG.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarG := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarH(AValue: TPLCNumber);
begin
  if FVarH = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarH) then
  begin
    FVarH.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarH := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarI(AValue: TPLCNumber);
begin
  if FVarI = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarI) then
  begin
    FVarI.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarI := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.SetVarJ(AValue: TPLCNumber);
begin
  if FVarJ = AValue then
    Exit;
  if Assigned(AValue) and (not Supports(AValue, ITagNumeric)) then
    Exit;

  if Assigned(FVarJ) then
  begin
    FVarJ.RemoveAllHandlersFromObject(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@VarTagChanged);
    AValue.AddWriteFaultHandler(@VarTagChanged);
    AValue.AddRemoveTagHandler(@TagRemovedCallback);
  end;

  FVarJ := AValue;

  CalculateValue;
end;

procedure TNumericExprTag.TagRemovedCallback(Sender: TObject);
begin
  if Sender = FVarA then
    FVarA := nil;
  if Sender = FVarB then
    FVarB := nil;
  if Sender = FVarC then
    FVarC := nil;
  if Sender = FVarD then
    FVarD := nil;
  if Sender = FVarE then
    FVarE := nil;
  if Sender = FVarF then
    FVarF := nil;
  if Sender = FVarG then
    FVarG := nil;
  if Sender = FVarH then
    FVarH := nil;
  if Sender = FVarI then
    FVarI := nil;
  if Sender = FVarJ then
    FVarJ := nil;
  CalculateValue;
end;

procedure TNumericExprTag.VarTagChanged(Sender: TObject);
begin
  CalculateValue;
end;

procedure TNumericExprTag.SetValueRaw(AValue: Double);
begin
  NotifyWriteFault;
end;

function TNumericExprTag.GetValueRaw: Double;
begin
  Result := PValueRaw;
end;

procedure TNumericExprTag.Loaded;
begin
  inherited Loaded;
  CalculateValue;
end;

destructor TNumericExprTag.Destroy;
begin
  if Assigned(FVarA) then
     FVarA.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarB) then
    FVarB.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarC) then
    FVarC.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarD) then
    FVarD.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarE) then
    FVarE.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarF) then
    FVarF.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarG) then
    FVarG.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarH) then
    FVarH.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarI) then
    FVarI.RemoveAllHandlersFromObject(Self);
  if Assigned(FVarJ) then
    FVarJ.RemoveAllHandlersFromObject(Self);
  inherited Destroy;
end;

end.

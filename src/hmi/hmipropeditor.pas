{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Implementacao dos editores de algumas propriedades de controles
            do PascalSCADA.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Implements the some properties editors of the controls of the
            PascalSCADA.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
unit hmipropeditor;

{$IFDEF FPC}
{$MACRO ON}
{$ENDIF}

{$I ../common/delphiver.inc}

interface

uses
  Classes, SysUtils, HMIZones, Dialogs, Menus, ProtocolDriver, typinfo,
  HMIControlDislocatorAnimation, hmiobjectcolletion, Controls,
  ControlSecurityManager, Graphics, scadapropeditor, fpexprpars,
{$IFDEF FPC}
  PropEdits,
  ComponentEditors,
  GraphPropEdits,
  ImgList,
  hmibooleanpropertyconnector,
  hmicolorpropertyconnector,
  hmi_polyline;
{$ELSE}
  Types,
  //if is a delphi 6+
  {$IF defined(DELPHI6_UP)}
  DesignIntf,
  DesignEditors;
  {$ELSE}
  //delphi 5-
  DsgnIntf;
  {$IFEND}
{$ENDIF}

type
  {$IFDEF PORTUGUES}
  {:
  Editor da propriedade TGraphicZone.FileName
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Property editor of TGraphicZone.FileName property.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TZoneFileNamePropertyEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: Ansistring; override;
    procedure Edit; override;
    procedure SetValue(const Value: Ansistring); override;
  end;

{$IFDEF FPC}
  {$IFDEF PORTUGUES}
  {:
  Editor da propriedade TGraphicZone.ImageIndex
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Property editor of TGraphicZone.ImageIndex property.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TGraphiZoneImageIndexPropertyEditor = class(TImageIndexPropertyEditor)
  protected
    function GetImageList: TCustomImageList; override;
  public
    procedure SetValue(const NewValue: ansistring); override;
    procedure ListDrawValue(const CurValue: ansistring; Index: integer;
      ACanvas: TCanvas; const ARect: TRect; AState: TPropEditDrawState); override;
  end;

  TPascalSCADALoginLogoutImageIndexPropertyEditor = class(TImageIndexPropertyEditor)
  protected
    function GetImageList: TCustomImageList; override;
  public
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: ansistring); override;
  end;


  {$IFNDEF DELPHI4_UP}
  TSelectObjectPropPropertyEditor = class(TStringPropertyEditor)
  protected
    FOnlyPropertiesOfType:AnsiString;
    FExpectedClass:TObjectColletionItemClass;
  public
    constructor Create(Hook: TPropertyEditorHook; APropCount: Integer);
      override;
    function  GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: AnsiString); override;
  end;

  { TSelectOnlyBooleanPropPropertyEditor }

  TSelectOnlyBooleanPropPropertyEditor = Class(TSelectObjectPropPropertyEditor)
  public
    constructor Create(Hook: TPropertyEditorHook; APropCount: Integer);
       override;
  end;

  { TSelectOnlyTColorPropPropertyEditor }

  TSelectOnlyTColorPropPropertyEditor = Class(TSelectObjectPropPropertyEditor)
  public
    constructor Create(Hook: TPropertyEditorHook; APropCount: Integer);
       override;
  end;

  {$ENDIF}
{$ENDIF}

  {$IFDEF PORTUGUES}
  {:
  Editor das seguintes propriedades de THMIControlDislocatorAnimation:
  @unorderedList(
    @item(THMIControlDislocatorAnimation.Gets_P0_Position)
    @item(THMIControlDislocatorAnimation.Gets_P1_Position)
    @item(THMIControlDislocatorAnimation.GoTo_P0_Position)
  )

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Property editor of the following properties of THMIControlDislocatorAnimation:
  @unorderedList(
    @item(THMIControlDislocatorAnimation.Gets_P0_Position)
    @item(THMIControlDislocatorAnimation.Gets_P1_Position)
    @item(THMIControlDislocatorAnimation.GoTo_P0_Position)
  )

  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TPositionPropertyEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: Ansistring; override;
    procedure Edit; override;
  end;

  {$IFDEF PORTUGUES}
  {:
  Editor da propriedade
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Property editor of TZone.BlinkWith property.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TZoneBlinkWithPropertyEditor = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  {$IFDEF PORTUGUES}
  {:
  Editor da propriedade SecurityCode, responsavel pela seguranca de cada controle.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Property editor of SecurityCode property, that makes controls secure.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TSecurityCodePropertyEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  THMIPolylineAccess = class(THMIPolyline);

  { THMIPolylineComponentEditor }

  THMIPolylineComponentEditor = class(TDefaultComponentEditor)
  protected
    procedure DrawPolyline;
    procedure DrawEmptyPolyline;
    procedure OptimizePolyline;
  public
    procedure ExecuteVerb(Index: Longint); override;
    function GetVerb(Index: Longint): Ansistring; override;
    function GetVerbCount: Longint; override;
    function Polyline: THMIPolyline; virtual;
  end;

  TControlPosSizePropertyEditor = class(TIntegerExpressionPropertyEditor)
  protected
    procedure RegisterExpressionVariables(const i: Integer; var Parser: TFPExpressionParser); override;
  end;


implementation


uses
  HMITypes;


  { TControlPosSizePropertyEditor }

procedure TControlPosSizePropertyEditor.RegisterExpressionVariables(const i: Integer; var Parser: TFPExpressionParser);
const
  S_PROP_LEFT = 'left';
  S_PROP_TOP = 'top';
  S_PROP_WIDTH = 'width';
  S_PROP_HEIGHT = 'height';
  S_PROP_TAG = 'tag';
var
  PropertyName: Ansistring;
begin
  if Assigned(Parser) then
  begin
    //unregister all possible registered variables.
    Parser.Identifiers.Clear;

    PropertyName := LowerCase(GetPropInfo^.Name);

    if (GetComponent(i) is TControl) then
    begin
      //register only if the property is not being edited,
      //to avoid circular references.

      if (PropertyName <> S_PROP_LEFT) then
        Parser.Identifiers.AddIntegerVariable(S_PROP_LEFT, (GetComponent(i) as TControl).Left);

      if (PropertyName <> S_PROP_TOP) then
        Parser.Identifiers.AddIntegerVariable(S_PROP_TOP, (GetComponent(i) as TControl).Top);

      if (PropertyName <> S_PROP_WIDTH) then
        Parser.Identifiers.AddIntegerVariable(S_PROP_WIDTH, (GetComponent(i) as TControl).Width);

      if (PropertyName <> S_PROP_HEIGHT) then
        Parser.Identifiers.AddIntegerVariable(S_PROP_HEIGHT, (GetComponent(i) as TControl).Height);

      if (PropertyName <> S_PROP_TAG) then
        Parser.Identifiers.AddIntegerVariable(S_PROP_TAG, (GetComponent(i) as TControl).Tag);
    end;
  end;
end;

{ THMIPolylineComponentEditor }

procedure THMIPolylineComponentEditor.DrawPolyline;
begin
  THMIPolylineAccess(Polyline).BeginDrawPolyline;
end;

procedure THMIPolylineComponentEditor.DrawEmptyPolyline;
begin
  THMIPolylineAccess(Polyline).BeginEmptyPolyline;
end;

procedure THMIPolylineComponentEditor.OptimizePolyline;
begin
  THMIPolylineAccess(Polyline).OptimizeDraw;
end;

procedure THMIPolylineComponentEditor.ExecuteVerb(Index: Longint);
begin
  case Index of
    0: DrawPolyline;
    1: DrawEmptyPolyline;
    2: OptimizePolyline;
  end;
end;

function THMIPolylineComponentEditor.GetVerb(Index: Longint): Ansistring;
begin
  case Index of
    0: Result := 'Continue draw';
    1: Result := 'Clear draw';
    2: Result := 'Optimize';
    else
      Result := inherited GetVerb(Index);
  end;
end;

function THMIPolylineComponentEditor.GetVerbCount: Longint;
begin
  Result := 3;
end;

function THMIPolylineComponentEditor.Polyline: THMIPolyline;
begin
  Result := THMIPolyline(GetComponent);
end;

{ TSelectOnlyTColorPropPropertyEditor }

constructor TSelectOnlyTColorPropPropertyEditor.Create(Hook: TPropertyEditorHook; APropCount: Integer);
begin
  inherited Create(Hook, APropCount);
  FOnlyPropertiesOfType := PTypeInfo(TypeInfo(TColor))^.Name;
  FExpectedClass := TObjectWithColorPropetiesColletionItem;
end;

{ TSelectOnlyBooleanPropPropertyEditor }

constructor TSelectOnlyBooleanPropPropertyEditor.Create(Hook: TPropertyEditorHook; APropCount: Integer);
begin
  inherited Create(Hook, APropCount);
  FOnlyPropertiesOfType := PTypeInfo(TypeInfo(Boolean))^.Name;
  FExpectedClass := TObjectWithBooleanPropetiesColletionItem;
end;

{ TTargetObjectPropPropertyEditor }

constructor TSelectObjectPropPropertyEditor.Create(Hook: TPropertyEditorHook; APropCount: Integer);
begin
  inherited Create(Hook, APropCount);
  FOnlyPropertiesOfType := '';
  FExpectedClass := TObjectColletionItem;
end;

function TSelectObjectPropPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  if GetComponent(0) is FExpectedClass then
    Result := [paValueList
{$IFDEF FPC}
      , paPickList
{$ELSE}
  {$IFDEF DELPHI2005_UP}
      , paReadOnly
      , paValueEditable
  {$ENDIF}
{$ENDIF}
    ];
end;

procedure TSelectObjectPropPropertyEditor.GetValues(Proc: TGetStrProc);
var
  PL: PPropList;
  ATypeData: PTypeData;
  NProps: Integer;
  i: Integer;
  Obj: TComponent;
begin
  Proc('(none)');
  if GetComponent(0) is FExpectedClass then
    if Assigned((GetComponent(0) as FExpectedClass).TargetObject) then
    begin
      Obj := (GetComponent(0) as FExpectedClass).TargetObject;

      ATypeData := GetTypeData(Obj.ClassInfo);

      GetMem(PL, ATypeData^.PropCount * SizeOf(Pointer));
      try
        NProps := GetPropList(Obj, PL);
        for i := 0 to NProps - 1 do
        begin
          if (LowerCase(PL^[i]^.PropType^.Name) = LowerCase(FOnlyPropertiesOfType)) or (FOnlyPropertiesOfType = '') then
          begin
            Proc(PL^[i]^.Name);
          end;
        end;
      finally
        Freemem(PL);
      end;
    end;
end;

procedure TSelectObjectPropPropertyEditor.SetValue(const NewValue: Ansistring);
begin
  if NewValue = '(none)' then
    inherited SetValue('')
  else
    inherited SetValue(NewValue);
end;

function TZoneFileNamePropertyEditor.GetAttributes: TPropertyAttributes;
begin
  if GetComponent(0) is TGraphicZone then
    Result := [paDialog
{$IFNDEF FPC}
  {$IFDEF DELPHI2005_UP}
        , paReadOnly,
        paValueEditable
  {$ENDIF}
{$ENDIF}
      ];
end;

function TZoneFileNamePropertyEditor.GetValue: Ansistring;
begin
  Result := GetStrValue;
end;

procedure TZoneFileNamePropertyEditor.Edit;
var
  Od: TOpenDialog;
begin
  if GetComponent(0) is TGraphicZone then
  begin
    Od := TOpenDialog.Create(nil);
    {$IFDEF FPC}
    Od.Filter := 'Imagens *.ico *.ppm *.pgm *.pbm *.png *.xpm *.bpm|*.ico;*.ppm;*.pgm;*.pbm;*.png;*.xpm;*.bpm';
    {$ELSE}
    od.Filter := 'Imagens *.jpg *.jpeg *.bmp *.ico *.emf *.wmf|*.jpg;*.jpeg;*.bmp;*.ico;*.emf;*.wmf';
    {$ENDIF}
    try
      if Od.Execute then
        TGraphicZone(GetComponent(0)).FileName := Od.FileName;
    finally
      Od.Destroy;
    end;
  end;
end;

procedure TZoneFileNamePropertyEditor.SetValue(const Value: Ansistring);
begin
  SetStrValue(Value);
  if GetComponent(0) is TGraphicZone then
    TGraphicZone(GetComponent(0)).ImageListAsDefault := False;
end;

{$IFDEF FPC}
procedure TGraphiZoneImageIndexPropertyEditor.SetValue(const NewValue: ansistring);
var
  AValue: LongInt;
begin
  try
    if NewValue='(none)' then
       inherited SetValue('-1')
    else
    begin
    if GetImageList <> nil then
    begin
      AValue := StrToInt(NewValue);
      if (AValue >= 0) and (AValue < GetImageList.Count) then
        inherited SetValue(NewValue)
      else
        inherited SetValue('-1');
    end
    else
      inherited SetValue('-1');
    end;
  except
    inherited SetValue('-1');
  end;
end;

procedure TGraphiZoneImageIndexPropertyEditor.ListDrawValue(
  const CurValue: ansistring; Index: integer; ACanvas: TCanvas;
  const ARect: TRect; AState: TPropEditDrawState);
var
  Images: TCustomImageList;
  R: TRect;
  OldColor: TColor;

  procedure DrawText;
  var
    Style: TTextStyle;
  begin
    FillChar(Style{%H-}, SizeOf(Style), 0);
    With Style do begin
      Alignment := taLeftJustify;
      Layout := tlCenter;
      Opaque := False;
      Clipping := True;
      ShowPrefix := True;
      WordBreak := False;
      SingleLine := True;
      SystemFont := False;
    end;
    ACanvas.TextRect(ARect, ARect.Left+2, ARect.Top, CurValue, Style);
  end;

begin
  if Index = 0 then
  begin
    DrawText;
    Exit;
  end;
  Dec(Index);
  Images := GetImageList;
  R := ARect;
  if Assigned(Images) then
  begin
    if (pedsInComboList in AState) and not (pedsInEdit in AState) then
    begin
      OldColor := ACanvas.Brush.Color;
      if pedsSelected in AState then
        ACanvas.Brush.Color := clHighlight
      else
        ACanvas.Brush.Color := clWhite;
      ACanvas.FillRect(R);
      ACanvas.Brush.Color := OldColor;
    end;

    Images.Draw(ACanvas, R.Left + Images.Width + 3, R.Top + 1, Index, True);
    R.Left := R.Left + Images.Width + 2;
  end;
  DrawText;
end;

function TGraphiZoneImageIndexPropertyEditor.GetImageList: TCustomImageList;
begin
  if GetComponent(0) is TGraphicZone then
    Result := TGraphicZone(GetComponent(0)).ImageList
  else
    Result := nil;
end;

procedure TPascalSCADALoginLogoutImageIndexPropertyEditor.SetValue(const NewValue: ansistring);
var
  x: LongInt;
begin
  try
    if NewValue = '(none)' then
       inherited SetValue('-1')
    else
    begin
      if GetImageList<>nil then
      begin
        x:=StrToInt(NewValue);
        if x in [0..GetImageList.Count-1] then
          inherited SetValue(NewValue)
        else
          inherited SetValue('-1');
      end
      else
        inherited SetValue('-1');
    end;
  except
    inherited SetValue('-1');
  end;
end;

function TPascalSCADALoginLogoutImageIndexPropertyEditor.GetImageList: TCustomImageList;
begin
  if GetComponent(0) is TPascalSCADALogin_LogoutAction then
    Result := TPascalSCADALogin_LogoutAction(GetComponent(0)).ActionList.Images
  else
    Result := nil;
end;

procedure TPascalSCADALoginLogoutImageIndexPropertyEditor.GetValues(Proc: TGetStrProc);
begin
  Proc('(none)');
  inherited GetValues(Proc);
end;
{$ENDIF}

function TZoneBlinkWithPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  if GetComponent(0) is TZone then
    Result := [paValueList
      {$IFNDEF FPC}
      {$IFDEF DELPHI2005_UP}
      , paReadOnly,
                 paValueEditable
      {$ENDIF}
      {$ENDIF}
      ];
end;

procedure TZoneBlinkWithPropertyEditor.GetValues(Proc: TGetStrProc);
var
  i: Longint;
begin
  Proc('-1');
  if (GetComponent(0) is TZone) and (TZone(GetComponent(0)).Collection is TZones) then
    for i := 0 to TZone(GetComponent(0)).Collection.Count - 1 do
    begin
      if TZone(GetComponent(0)).Collection.Items[i] <> GetComponent(0) then
        Proc(IntToStr(i));
    end;
end;

function TSecurityCodePropertyEditor.GetAttributes: TPropertyAttributes;
begin
  if Supports(GetComponent(0), IHMIInterface) or (GetComponent(0) is TPascalSCADACheckSpecialTokenAction) then
    Result := [paValueList
      {$IFNDEF FPC}
      {$IFDEF DELPHI2005_UP}
      , paReadOnly,
                 paValueEditable
      {$ENDIF}
      {$ENDIF}
      ];
end;

procedure TSecurityCodePropertyEditor.GetValues(Proc: TGetStrProc);
var
  i: Longint;
  x: TStringList;
begin
  Proc('');
  x := GetControlSecurityManager.GetRegisteredAccessCodes;
  for i := 0 to x.Count - 1 do
  begin
    Proc(x.Strings[i]);
  end;
  x.Destroy;
end;

///////////////////////////////////////////////////////////////////////////////

function TPositionPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  if GetComponent(0) is THMIControlDislocatorAnimation then
    Result := [paDialog
      {$IFNDEF FPC}
      {$IFDEF DELPHI2005_UP}
      , paReadOnly,
                 paValueEditable
      {$ENDIF}
      {$ENDIF}
      ];
end;

function TPositionPropertyEditor.GetValue: Ansistring;
begin
  Result := GetStrValue;
end;

procedure TPositionPropertyEditor.Edit;
var
  PName: Ansistring;
begin
  if GetComponent(0) is THMIControlDislocatorAnimation then
  begin
    with GetComponent(0) as THMIControlDislocatorAnimation do
    begin
      if Control = nil then Exit;
      PName := LowerCase(GetName);
      if PName = 'gets_p0_position' then
      begin
        P0_X := Control.Left;
        P0_Y := Control.top;
        Exit;
      end;

      if PName = 'gets_p1_position' then
      begin
        P1_X := Control.Left;
        P1_Y := Control.top;
        Exit;
      end;
      if PName = 'goto_p0_position' then
      begin
        Control.Left := P0_X;
        Control.top := P0_Y;
        Exit;
      end;
    end;
  end;
end;

end.

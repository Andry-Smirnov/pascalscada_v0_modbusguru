unit HMIBandeja;

{$mode ObjFPC}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  PLCNumber, plcstructstring;

type
  TOnConvertDintToColor = function(Sender: TObject; const AColorDint: Longint; out Lum: Longint): TColor of object;

  { THMIBandeja }

  THMIBandeja = class(TCustomPanel)
  private
    fOnConvertDintToColor: TOnConvertDintToColor;
    procedure TagBackgroundColorChanged(Sender: TObject);
    procedure TagBandejaTextChanged(Sender: TObject);
    procedure TagBorderColorChanged(Sender: TObject);
  protected
    FBackgroundColorPLCTag: TPLCNumber;
    FBandejaTextPLCTag: TPLCStructString;
    FBorderColorPLCTag: TPLCNumber;
    function DIntToColor(ADInt: Longint; out Lumin: Longint): TColor;
    procedure SetBackgroundColorPLCTag(AValue: TPLCNumber); virtual;
    procedure SetBandejaTextPLCTag(AValue: TPLCStructString); virtual;
    procedure SetBorderColorPLCTag(AValue: TPLCNumber); virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    destructor Destroy; override;
  published
    property BorderColorPLCTag: TPLCNumber read FBorderColorPLCTag write SetBorderColorPLCTag;
    property BackgroundColorPLCTag: TPLCNumber read FBackgroundColorPLCTag write SetBackgroundColorPLCTag;
    property BandejaTextPLCTag: TPLCStructString read FBandejaTextPLCTag write SetBandejaTextPLCTag;
    property OnConvertDintToColor: TOnConvertDintToColor read fOnConvertDintToColor write fOnConvertDintToColor;
  published
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    //property BevelColor;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BidiMode;
    property BorderWidth;
    property BorderStyle;
    //property Caption;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    //property Color;
    property Constraints;
    property DockSite;
    property DoubleBuffered;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property FullRepaint;
    property ParentBackground;
    property ParentBidiMode;
    property ParentColor;
    property ParentDoubleBuffered;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    //property ShowAccelChar;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property UseDockManager default True;
    //property VerticalAlignment;
    property Visible;
    property Wordwrap;
    property OnChangeBounds;
    property OnClick;
    property OnContextPopup;
    property OnDockDrop;
    property OnDockOver;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnGetDockCaption;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnMouseWheelHorz;
    property OnMouseWheelLeft;
    property OnMouseWheelRight;
    property OnPaint;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
  end;

implementation

{ THMIBandeja }

procedure THMIBandeja.SetBorderColorPLCTag(AValue: TPLCNumber);
begin
  if FBorderColorPLCTag = AValue then Exit;

  if Assigned(FBorderColorPLCTag) then
  begin
    FBorderColorPLCTag.RemoveAllHandlersFromObject(Self);
    FBorderColorPLCTag.RemoveFreeNotification(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@TagBorderColorChanged);
    AValue.FreeNotification(Self);
  end;

  FBorderColorPLCTag := AValue;
end;

procedure THMIBandeja.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FBorderColorPLCTag then
    begin
      FBorderColorPLCTag := nil;
    end;

    if AComponent = FBackgroundColorPLCTag then
    begin
      FBackgroundColorPLCTag := nil;
    end;

    if AComponent = FBandejaTextPLCTag then
    begin
      FBandejaTextPLCTag := nil;
    end;
  end;
end;

destructor THMIBandeja.Destroy;
begin
  SetBorderColorPLCTag(nil);
  SetBackgroundColorPLCTag(nil);
  SetBandejaTextPLCTag(nil);
  inherited Destroy;
end;

procedure THMIBandeja.TagBackgroundColorChanged(Sender: TObject);
var
  Lum: Longint;
begin
  if Assigned(FBackgroundColorPLCTag) then
  begin
    if Assigned(fOnConvertDintToColor) then
      Color := fOnConvertDintToColor(Self, Trunc(FBackgroundColorPLCTag.Value), Lum)
    else
      Color := DIntToColor(Trunc(FBackgroundColorPLCTag.Value), Lum);

    Visible := not (Color = 0);

    if Lum > 127 then
      Font.Color := clBlack
    else
      Font.Color := clWhite;
  end;
end;

procedure THMIBandeja.TagBandejaTextChanged(Sender: TObject);
begin
  if Assigned(FBandejaTextPLCTag) then
    Caption := FBandejaTextPLCTag.Value;
end;

procedure THMIBandeja.TagBorderColorChanged(Sender: TObject);
var
  Aux: Longint;
begin
  if Assigned(FBorderColorPLCTag) then
  begin
    if Assigned(fOnConvertDintToColor) then
      Color := fOnConvertDintToColor(Self, Trunc(FBorderColorPLCTag.Value), Aux)
    else
      BevelColor := DIntToColor(Trunc(FBorderColorPLCTag.Value), Aux);
  end;
end;

function THMIBandeja.DIntToColor(ADInt: Longint; out Lumin: Longint): TColor;
var
  R: Longint;
  G: Longint;
  B: Longint;
begin
  R := (ADInt and $00ff0000) div $10000;
  G := (ADInt and $0000ff00) div $100;
  B := (ADInt and $000000ff);
  Lumin := Trunc((R * 0.3) + (G * 0.59) + (B * 0.11));
  Result := RGBToColor(R, G, B);
end;

procedure THMIBandeja.SetBackgroundColorPLCTag(AValue: TPLCNumber);
begin
  if FBackgroundColorPLCTag = AValue then Exit;

  if Assigned(FBackgroundColorPLCTag) then
  begin
    FBackgroundColorPLCTag.RemoveAllHandlersFromObject(Self);
    FBackgroundColorPLCTag.RemoveFreeNotification(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@TagBackgroundColorChanged);
    AValue.FreeNotification(Self);
  end;

  FBackgroundColorPLCTag := AValue;
end;

procedure THMIBandeja.SetBandejaTextPLCTag(AValue: TPLCStructString);
begin
  if FBandejaTextPLCTag = AValue then Exit;

  if Assigned(FBandejaTextPLCTag) then
  begin
    FBandejaTextPLCTag.RemoveAllHandlersFromObject(Self);
    FBandejaTextPLCTag.RemoveFreeNotification(Self);
  end;

  if Assigned(AValue) then
  begin
    AValue.AddTagChangeHandler(@TagBandejaTextChanged);
    AValue.FreeNotification(Self);
  end;

  FBandejaTextPLCTag := AValue;
end;

end.

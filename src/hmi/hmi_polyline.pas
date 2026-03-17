unit hmi_polyline;

{$mode objfpc}{$H+}

interface

uses
  Controls, SysUtils, Graphics, Classes, hmi_draw_basiccontrol, BGRABitmap,
  BGRABitmapTypes, hmibasiccolletion, LMessages;

type

  { TPointCollectionItem }

  TPointCollectionItem = class(THMIBasicColletionItem)
  private
    FX: Integer;
    FY: Integer;

    procedure setX(AValue: Integer);
    procedure setY(AValue: Integer);
  protected
    function GetDisplayName: Ansistring; override;
  published
    property X: Integer read FX write setX;
    property Y: Integer read FY write setY;
  end;

  TPointCollection = class(THMIBasicColletion)
  protected
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
  public
    constructor Create(AOwner: TComponent);
    function Add: TPointCollectionItem;
  end;


  { THMIPolyline }

  THMIPolyline = class(THMIBasicControl)
  private
    FPenStyle: TPenStyle;
    procedure SetPenStyle(AValue: TPenStyle);
    procedure setPointCoordinates(AValue: TPointCollection);
    procedure CollectionNeedsComponentState(var CurState: TComponentState);
    procedure PointChanged(Sender: TObject);
  protected
    FPointCoordinates: TPointCollection;
    FDesignDrawing: Boolean;
    FCtrlOnLastMouseMove: Boolean;
    FPointInfo: Ansistring;
    FPointInfoWidth: Integer;
    FOldAlign: TAlign;

    procedure SetBorderWidth(AValue: Integer); override;
    procedure SetLineColor(AValue: TColor); virtual;

    procedure DoLineColorChange; virtual;

    procedure DrawControl; override;

    procedure BeginDrawPolyline; virtual;
    procedure BeginEmptyPolyline; virtual;
    procedure EndDrawPolyline; virtual;
    procedure OptimizeDraw; virtual;
    procedure OptimizeDrawAfterFinish; virtual;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;

    procedure CMDesignHitTest(var Message: TLMessage); message CM_DESIGNHITTEST;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property LineColor: TColor read FBorderColor write SetLineColor default clBlack;
    property LineWidth: Integer read FBorderWidth write SetBorderWidth default 2;
    property PenStyle: TPenStyle read FPenStyle write SetPenStyle default psSolid;
    property PointCoordinates: TPointCollection read FPointCoordinates write setPointCoordinates;
    property Visible;
  end;

  THMIFlowPolyline = class;

  IColorChangeNotification = interface
    ['{7A61F363-CBE0-4271-8E5E-BBDCE708084E}']
    procedure AddNotifyCallback(WhoNotify: IColorChangeNotification);
    procedure RemoveNotifyCallback(WhoRemove: IColorChangeNotification);
    procedure NotifyFree(const WhoWasDestroyed: THMIFlowPolyline);
    procedure NotifyChange(const WhoChanged: THMIFlowPolyline);
  end;

  { THMIFlowSourceCollectionItem }

  THMIFlowSourceCollectionItem = class(THMIBasicColletionItem)
  private
    FHMIObject: THMIFlowPolyline;
    procedure setHMIObject(AValue: THMIFlowPolyline);
  protected
    function GetDisplayName: string; override;
  published
    property HMIObject: THMIFlowPolyline read FHMIObject write setHMIObject;
  end;


  THMIFlowSourceCollection = class(THMIBasicColletion)
  public
    constructor Create(AOwner: TComponent);
    function Add: THMIFlowSourceCollectionItem;
  end;

  TColorMixBehavior = (cmbLastColor, cmbAnd, cmbOr, cmbXor, cmbEmpty, cmbMultipleColorsReplace);
  TPointDirection = (pdVertical, pdHorizontal);

  { THMIFlowPolyline }

  THMIFlowPolyline = class(THMIPolyline, IColorChangeNotification)
  private
    FStartPInit: Boolean;
    FEndPInit: Boolean;
    FStartP: TPoint;
    FEndP: TPoint;
    FAutoHeightDistribution: Smallint;
    FAutoEndPointOffset: Integer;
    FAutoRoute: Boolean;
    FAutoStartPointOffset: Integer;
    FEmptyColor: TColor;
    FEndDireciton: TPointDirection;
    FFlowSources: THMIFlowSourceCollection;

    FFlowDest: array of IColorChangeNotification;
    FMultipleColorBehavior: TColorMixBehavior;
    FMultipleColorsReplace: TColor;
    FOnColorChange: TNotifyEvent;
    FStartDireciton: TPointDirection;

    procedure AddNotifyCallback(WhoNotify: IColorChangeNotification);
    function GetAutoHeightDistribution: Double;
    procedure RemoveNotifyCallback(WhoRemove: IColorChangeNotification);
    procedure NotifyFree(const WhoWasDestroyed: THMIFlowPolyline);
    procedure NotifyChange(const WhoChanged: THMIFlowPolyline);
    procedure SetAutoEndPointDirection(AValue: TPointDirection);
    procedure SetAutoEndPointOffset(AValue: Integer);
    procedure SetAutoHeightDistribution(AValue: Double);
    procedure SetAutoRoute(AValue: Boolean);
    procedure SetAutoStartPointDirection(AValue: TPointDirection);
    procedure SetAutoStartPointOffset(AValue: Integer);
    procedure SetEmptyColor(AValue: TColor);
    procedure setFlowSources(AValue: THMIFlowSourceCollection);
    procedure setMultipleColorsBehavior(AValue: TColorMixBehavior);
    procedure setMultipleColorsReplace(AValue: TColor);
  protected
    procedure AdjustCoordinates; virtual;
    procedure RecalculateMidPoints; virtual;
    procedure DoLineColorChange; override;
    procedure RecalculateColor(WhoChanged: THMIFlowPolyline = nil); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure UpdateEndPoints(EndPoint: Boolean; ScreenPoint: TPoint);
  published
    property AutoRoute: Boolean read FAutoRoute write SetAutoRoute default False;
    property AutoStartPointDirection: TPointDirection read FStartDireciton write SetAutoStartPointDirection;
    property AutoStartPointOffset: Integer read FAutoStartPointOffset write SetAutoStartPointOffset;
    property AutoEndPointDirection: TPointDirection read FEndDireciton write SetAutoEndPointDirection;
    property AutoEndPointOffset: Integer read FAutoEndPointOffset write SetAutoEndPointOffset;
    property AutoHeightDistribution: Double read GetAutoHeightDistribution write SetAutoHeightDistribution;
    property EmptyColor: TColor read FEmptyColor write SetEmptyColor default clBlack;
    property MultipleColorBehavior: TColorMixBehavior read FMultipleColorBehavior write setMultipleColorsBehavior;
    property MultipleColorsReplace: TColor read FMultipleColorsReplace write setMultipleColorsReplace;
    property FlowSource: THMIFlowSourceCollection read FFlowSources write setFlowSources;
    property OnColorChange: TNotifyEvent read FOnColorChange write FOnColorChange;
  end;

implementation

uses
  Math;

  { THMIFlowPolyline }

procedure THMIFlowPolyline.AddNotifyCallback(WhoNotify: IColorChangeNotification);
var
  i: Integer;
begin
  for i := 0 to High(FFlowDest) do
    if FFlowDest[i] = WhoNotify then
      Exit;

  i := Length(FFlowDest);
  SetLength(FFlowDest, i + 1);
  FFlowDest[i] := WhoNotify;
end;

function THMIFlowPolyline.GetAutoHeightDistribution: Double;
begin
  Result := FAutoHeightDistribution / 100;
end;

procedure THMIFlowPolyline.RemoveNotifyCallback(WhoRemove: IColorChangeNotification);
var
  h: Integer;
  i: Integer;
  Found: Boolean;
begin
  h := High(FFlowDest);
  for i := 0 to h do
    if FFlowDest[i] = WhoRemove then
    begin
      Found := True;
      Break;
    end;

  if Found then
  begin
    FFlowDest[i] := FFlowDest[h];
    SetLength(FFlowDest, h);
  end;
end;

procedure THMIFlowPolyline.NotifyFree(const WhoWasDestroyed: THMIFlowPolyline);
var
  i: Integer;
begin
  for i := 0 to FFlowSources.Count - 1 do
  begin
    if THMIFlowSourceCollectionItem(FFlowSources.Items[i]).HMIObject = WhoWasDestroyed then
    begin
      FFlowSources.Delete(i);
      Exit;
    end;
  end;

  RemoveNotifyCallback(WhoWasDestroyed as IColorChangeNotification);
end;

procedure THMIFlowPolyline.NotifyChange(const WhoChanged: THMIFlowPolyline);
begin
  RecalculateColor(WhoChanged);
end;

procedure THMIFlowPolyline.SetAutoEndPointDirection(AValue: TPointDirection);
begin
  if FEndDireciton = AValue then Exit;
  FEndDireciton := AValue;
end;

procedure THMIFlowPolyline.SetAutoEndPointOffset(AValue: Integer);
begin
  if FAutoEndPointOffset = AValue then Exit;
  FAutoEndPointOffset := AValue;
end;

procedure THMIFlowPolyline.SetAutoHeightDistribution(AValue: Double);
var
  Aux: Int64;
begin
  if (AValue < 0) or (AValue > 100) then
    Exit;

  Aux := Trunc(AValue * 100.0);

  if Aux = FAutoHeightDistribution then
    Exit;

  FAutoHeightDistribution := Aux;

  RecalculateMidPoints;
  InvalidateShape;
end;

procedure THMIFlowPolyline.SetAutoRoute(AValue: Boolean);
begin
  if FAutoRoute = AValue then Exit;
  FAutoRoute := AValue;
  UpdateEndPoints(False, FStartP);
  UpdateEndPoints(True, FEndP);
  RecalculateMidPoints;
end;

procedure THMIFlowPolyline.SetAutoStartPointDirection(AValue: TPointDirection);
begin
  if FStartDireciton = AValue then Exit;
  FStartDireciton := AValue;
end;

procedure THMIFlowPolyline.SetAutoStartPointOffset(AValue: Integer);
begin
  if FAutoStartPointOffset = AValue then Exit;
  FAutoStartPointOffset := AValue;
end;

procedure THMIFlowPolyline.SetEmptyColor(AValue: TColor);
begin
  if FEmptyColor = AValue then Exit;
  FEmptyColor := AValue;
  RecalculateColor;
end;

procedure THMIFlowPolyline.setFlowSources(AValue: THMIFlowSourceCollection);
begin
  if FFlowSources = AValue then Exit;
  FFlowSources.Assign(AValue);
end;

procedure THMIFlowPolyline.setMultipleColorsBehavior(AValue: TColorMixBehavior);
begin
  if FMultipleColorBehavior = AValue then Exit;
  FMultipleColorBehavior := AValue;
  RecalculateColor;
end;

procedure THMIFlowPolyline.setMultipleColorsReplace(AValue: TColor);
begin
  if FMultipleColorsReplace = AValue then Exit;
  FMultipleColorsReplace := AValue;
  RecalculateColor;
end;

procedure THMIFlowPolyline.AdjustCoordinates;
begin
  if FAutoRoute and (PointCoordinates.Count <> 6) then
  begin
    while PointCoordinates.Count > 6 do
      PointCoordinates.Delete(0);

    while PointCoordinates.Count < 6 do
      PointCoordinates.Add;
  end;
end;

procedure THMIFlowPolyline.RecalculateMidPoints;
var
  h: Integer;
  p1y: Integer;
  p5y: Integer;
  Diff: Integer;
  sh: Int64;
begin
  if FAutoRoute = False then Exit;
  AdjustCoordinates;
  //pt1
  case FStartDireciton of
    pdVertical: begin
                  TPointCollectionItem(PointCoordinates.Items[1]).FX := TPointCollectionItem(PointCoordinates.Items[0]).FX;
                  TPointCollectionItem(PointCoordinates.Items[1]).FY := TPointCollectionItem(PointCoordinates.Items[0]).FY + FAutoStartPointOffset;
                end;
    pdHorizontal: begin
                    TPointCollectionItem(PointCoordinates.Items[1]).FX := TPointCollectionItem(PointCoordinates.Items[0]).FX + FAutoStartPointOffset;
                    TPointCollectionItem(PointCoordinates.Items[1]).FY := TPointCollectionItem(PointCoordinates.Items[0]).FY;
                  end;
  end;

  h := PointCoordinates.Count - 1;
  //pt4
  case FEndDireciton of
    pdVertical: begin
                  TPointCollectionItem(PointCoordinates.Items[h - 1]).FX := TPointCollectionItem(PointCoordinates.Items[h]).FX;
                  TPointCollectionItem(PointCoordinates.Items[h - 1]).FY := TPointCollectionItem(PointCoordinates.Items[h]).FY + FAutoEndPointOffset;
                end;
    pdHorizontal: begin
                    TPointCollectionItem(PointCoordinates.Items[h - 1]).FX := TPointCollectionItem(PointCoordinates.Items[h]).FX + FAutoEndPointOffset;
                    TPointCollectionItem(PointCoordinates.Items[h - 1]).FY := TPointCollectionItem(PointCoordinates.Items[h]).FY;
                  end;
  end;

  p1y := TPointCollectionItem(PointCoordinates.Items[1]).FY;
  p5y := TPointCollectionItem(PointCoordinates.Items[h]).FY;
  Diff := p5y - p1y;
  sh := Trunc(Diff * (FAutoHeightDistribution / 10000));

  //pt2
  TPointCollectionItem(PointCoordinates.Items[2]).FX := TPointCollectionItem(PointCoordinates.Items[1]).FX;
  TPointCollectionItem(PointCoordinates.Items[2]).FY := TPointCollectionItem(PointCoordinates.Items[1]).FY + sh;

  //pt3 //NOTE: Must be tested.
  TPointCollectionItem(PointCoordinates.Items[h - 2]).FX := TPointCollectionItem(PointCoordinates.Items[h - 1]).FX;
  TPointCollectionItem(PointCoordinates.Items[h - 2]).FY := TPointCollectionItem(PointCoordinates.Items[2]).FY;

  //TPointCollectionItem(PointCoordinates.Items[3]).FX := TPointCollectionItem(PointCoordinates.Items[2]).FX;
  //TPointCollectionItem(PointCoordinates.Items[3]).FY := TPointCollectionItem(PointCoordinates.Items[h-2]).FY;
  OptimizeDraw;
end;

procedure THMIFlowPolyline.DoLineColorChange;
var
  i: Integer;
begin
  for i := 0 to High(FFlowDest) do
  try
    FFlowDest[i].NotifyChange(Self);
  finally
  end;

  if Assigned(FOnColorChange) then
    FOnColorChange(Self);
end;

procedure THMIFlowPolyline.RecalculateColor(WhoChanged: THMIFlowPolyline);
var
  fs, validObject: THMIFlowSourceCollectionItem;
  i: Integer;
  MultipleColors: Boolean;
  CalculatedColor: TColor;
begin
  validObject := nil;
  fs := nil;
  MultipleColors := False;
  for i := 0 to FFlowSources.Count - 1 do
  begin
    fs := THMIFlowSourceCollectionItem(FFlowSources.Items[i]);
    if fs.HMIObject = nil then Continue;
    if fs.HMIObject.LineColor = FEmptyColor then Continue;

    if validObject = nil then
      validObject := fs
    else
    begin
      if validObject.HMIObject.LineColor <> fs.HMIObject.LineColor then
      begin
        MultipleColors := True;
        Break;
      end;
    end;
  end;

  if MultipleColors then
    case FMultipleColorBehavior of
      cmbLastColor: if Assigned(WhoChanged) and (WhoChanged.LineColor <> FEmptyColor) then
                      LineColor := WhoChanged.LineColor;
      cmbEmpty: LineColor := FEmptyColor;
      cmbMultipleColorsReplace: LineColor := FMultipleColorsReplace;
      cmbAnd,
      cmbOr,
      cmbXor: begin
                CalculatedColor := FEmptyColor;
                for i := 0 to FFlowSources.Count - 1 do
                begin
                  fs := THMIFlowSourceCollectionItem(FFlowSources.Items[i]);
                  if fs.HMIObject.LineColor = FEmptyColor then Continue;
                  if CalculatedColor = FEmptyColor then
                    CalculatedColor := fs.HMIObject.LineColor
                  else
                    case FMultipleColorBehavior of
                      cmbAnd: CalculatedColor := CalculatedColor and fs.HMIObject.LineColor;
                      cmbOr:  CalculatedColor := CalculatedColor or fs.HMIObject.LineColor;
                      cmbXor: CalculatedColor := CalculatedColor xor fs.HMIObject.LineColor;
                    end;
                end;
                LineColor := CalculatedColor;
              end;
    end
  else
  if Assigned(validObject) and Assigned(validObject.HMIObject) then
    LineColor := validObject.HMIObject.LineColor
  else
    LineColor := FEmptyColor;
end;

constructor THMIFlowPolyline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFlowSources := THMIFlowSourceCollection.Create(Self);
  FAutoHeightDistribution := 5000;
end;

destructor THMIFlowPolyline.Destroy;
var
  i: Integer;
begin
  for i := 0 to High(FFlowDest) do
    FFlowDest[i].NotifyFree(Self);
  for i := 0 to FFlowSources.Count - 1 do
    THMIFlowSourceCollectionItem(FFlowSources.Items[i]).HMIObject := nil;
  FreeAndNil(FFlowSources);
  inherited Destroy;
end;

procedure THMIFlowPolyline.Notification(AComponent: TComponent; Operation: TOperation);
var
  i: Integer;
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent <> Self) then
  begin
    for i := 0 to FFlowSources.Count - 1 do
      if THMIFlowSourceCollectionItem(FFlowSources.Items[i]).FHMIObject = AComponent then
      begin
        THMIFlowSourceCollectionItem(FFlowSources.Items[i]).FHMIObject := nil;
      end;
  end;
end;

procedure THMIFlowPolyline.UpdateEndPoints(EndPoint: Boolean; ScreenPoint: TPoint);
var
  PCIndex: Integer = 0;
  APoint: TPoint;
begin

  if EndPoint then
    FEndP := ScreenPoint
  else
    FStartP := ScreenPoint;

  if FAutoRoute = False then
    Exit;

  AdjustCoordinates;
  if EndPoint then
    PCIndex := PointCoordinates.Count - 1;

  APoint := ScreenToControl(ScreenPoint);
  TPointCollectionItem(PointCoordinates.Items[PCIndex]).FX := APoint.X;
  TPointCollectionItem(PointCoordinates.Items[PCIndex]).FY := APoint.Y;

  RecalculateMidPoints;
end;

{ THMIFlowObjectCollection }

constructor THMIFlowSourceCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, THMIFlowSourceCollectionItem);
end;

function THMIFlowSourceCollection.Add: THMIFlowSourceCollectionItem;
begin
  Result := THMIFlowSourceCollectionItem(inherited Add);
end;

{ THMIFlowObjectCollectionItem }

procedure THMIFlowSourceCollectionItem.setHMIObject(AValue: THMIFlowPolyline);
begin
  if FHMIObject = AValue then Exit;
  if supports(Collection.Owner, IColorChangeNotification) then
  begin
    if Assigned(FHMIObject) then
    begin
      (FHMIObject as IColorChangeNotification).RemoveNotifyCallback(Collection.Owner as IColorChangeNotification);
      FHMIObject.RemoveFreeNotification(TComponent(Collection.Owner));
    end;

    if AValue = nil then
    begin
      FHMIObject := AValue;
    end
    else
    begin
      if supports(AValue, IColorChangeNotification) then
      begin
        (AValue as IColorChangeNotification).AddNotifyCallback(Collection.Owner as IColorChangeNotification);
        AValue.FreeNotification(TComponent(Collection.Owner));
        FHMIObject := AValue;
      end
      else
        raise Exception.Create('Object don´t support the IColorChangeNotification interface!');
    end;
  end;
end;

function THMIFlowSourceCollectionItem.GetDisplayName: string;
begin
  if Assigned(FHMIObject) then
    Result := FHMIObject.Name
  else
    Result := '(Unassigned)';
end;

{ TPointCollection }

procedure TPointCollection.Notify(Item: TCollectionItem; Action: TCollectionNotification);
begin
  inherited Notify(Item, Action);
  if Assigned(OnCollectionItemChange) then
    OnCollectionItemChange(Self);
end;

constructor TPointCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TPointCollectionItem);
end;

function TPointCollection.Add: TPointCollectionItem;
begin
  Result := TPointCollectionItem(inherited Add);
end;

{ TPointCollectionItem }

procedure TPointCollectionItem.setX(AValue: Integer);
begin
  if FX = AValue then Exit;
  FX := AValue;
  NotifyChange;
end;

procedure TPointCollectionItem.setY(AValue: Integer);
begin
  if FY = AValue then Exit;
  FY := AValue;
  NotifyChange;
end;

function TPointCollectionItem.GetDisplayName: Ansistring;
begin
  Result := '(x=' + IntToStr(FX) + ', y=' + IntToStr(FY) + ')';
end;

{ THMIPolyline }

procedure THMIPolyline.CollectionNeedsComponentState(var CurState: TComponentState);
begin
  CurState := ComponentState;
end;

procedure THMIPolyline.PointChanged(Sender: TObject);
begin
  if [csLoading, csReading, csDestroying] * ComponentState = [] then
  begin
    InvalidateShape;
  end;
end;

procedure THMIPolyline.SetLineColor(AValue: TColor);
begin
  if FBorderColor = AValue then Exit;

  FBorderColor := AValue;
  Visible := (AValue <> clNone);

  try
    DoLineColorChange;
  finally
  end;

  if not Visible then Exit;

  if [csLoading, csReading] * ComponentState = [] then
  begin
    InvalidateDraw;
  end;
end;

procedure THMIPolyline.DoLineColorChange;
begin
end;

procedure THMIPolyline.SetBorderWidth(AValue: Integer);
begin
  inherited;
end;

procedure THMIPolyline.SetPenStyle(AValue: TPenStyle);
begin
  if FPenStyle = AValue then Exit;
  FPenStyle := AValue;
  InvalidateShape;
end;

procedure THMIPolyline.setPointCoordinates(AValue: TPointCollection);
begin
  FPointCoordinates.Assign(AValue);
  if [csLoading, csReading] * ComponentState = [] then
  begin
    InvalidateShape;
  end;
end;

procedure THMIPolyline.DrawControl;
var
  Points: array of TPointF;
  i: Integer;
  AFillColor: TBGRAPixel;
  ABorderColor: TBGRAPixel;
  PCItem: TPointCollectionItem;
begin
  inherited DrawControl;

  SetLength(Points, FPointCoordinates.Count);
  for i := 0 to FPointCoordinates.Count - 1 do
  begin
    PCItem := TPointCollectionItem(FPointCoordinates.Items[i]);
    Points[i].X := PCItem.X + ifthen((FBorderWidth Mod 2) = 1, ifthen((PCItem.X Mod 2) = 0, 1), 0.5);
    Points[i].Y := PCItem.Y + ifthen((FBorderWidth Mod 2) = 0, 0.5);
  end;

  FControlArea.PenStyle := FPenStyle;
  if Visible or (csDesigning in ComponentState) then
    FControlArea.DrawPolyLineAntialias(Points, ColorToBGRA(FBorderColor), FBorderWidth);

  if csDesigning in ComponentState then
  begin
    if (FPointInfo = '') or (FDesignDrawing = False) then Exit;
    AFillColor := ColorToBGRA(FBodyColor);
    ABorderColor := ColorToBGRA(FBorderColor);

    AFillColor.alpha := 160;
    ABorderColor.alpha := 160;

    FControlArea.Rectangle(Width - FPointInfoWidth - 5, -1,
      Width + 1,
      FControlArea.CanvasBGRA.TextHeight(FPointInfo) + 5,
      ABorderColor,
      AFillColor,
      dmDrawWithTransparency);
    FControlArea.TextOut(Width - 2, 1, FPointInfo, ColorToBGRA(FBorderColor), taRightJustify);
  end;
end;

procedure THMIPolyline.OptimizeDraw;
var
  i: Integer;
  MinX: Integer;
  MaxX: Integer;
  MinY: Integer;
  MaxY: Integer;
  sTop: Integer;
  sLeft: Integer;
  PCItem: TPointCollectionItem;
begin
  sLeft := Left;
  sTop := Top;
  //find min/max of x,y coordinates...
  for i := 0 to PointCoordinates.Count - 1 do
  begin
    PCItem := TPointCollectionItem(PointCoordinates.Items[i]);
    if i = 0 then
    begin
      MinX := Left + PCItem.X;
      MaxX := MinX;
      MinY := Top + PCItem.Y;
      MaxY := MinY;
      Continue;
    end;
    MinX := Min(Left + PCItem.X, MinX);
    MaxX := Max(Left + PCItem.X, MaxX);

    MinY := Min(Top + PCItem.Y, MinY);
    MaxY := Max(Top + PCItem.Y, MaxY);
  end;


  DisableAutoSizing;
  Left := MinX - (FBorderWidth Div 2);
  Top := MinY - (FBorderWidth Div 2);
  Width := (MaxX - MinX) + 2 * FBorderWidth;
  Height := (MaxY - MinY) + 2 * FBorderWidth;
  EnableAutoSizing;
  for i := 0 to PointCoordinates.Count - 1 do
  begin
    PCItem := TPointCollectionItem(PointCoordinates.Items[i]);
    PCItem.X := PCItem.X + (FBorderWidth Div 2) - (MinX - sLeft);
    PCItem.Y := PCItem.Y + (FBorderWidth Div 2) - (MinY - sTop);
  end;
end;

procedure THMIPolyline.OptimizeDrawAfterFinish;
var
  i: Integer;
  MinX,
  MaxX,
  MinY,
  MaxY,
  sTop,
  sLeft: Integer;
  PCItem: TPointCollectionItem;
begin
  sLeft := Left;
  sTop := Top;
  //find min/max of x,y coordinates...
  for i := 0 to PointCoordinates.Count - 1 do
  begin
    PCItem := TPointCollectionItem(PointCoordinates.Items[i]);
    if i = 0 then
    begin
      MinX := PCItem.X;
      MaxX := MinX;
      MinY := PCItem.Y;
      MaxY := MinY;
      Continue;
    end;
    MinX := Min(PCItem.X, MinX);
    MaxX := Max(PCItem.X, MaxX);

    MinY := Min(PCItem.Y, MinY);
    MaxY := Max(PCItem.Y, MaxY);
  end;


  DisableAutoSizing;
  Left := Max(MinX - (FBorderWidth Div 2), 0);
  Top := Max(MinY - (FBorderWidth Div 2), 0);
  Width := (MaxX - MinX) + 2 * FBorderWidth;
  Height := (MaxY - MinY) + 2 * FBorderWidth;
  EnableAutoSizing;
  for i := 0 to PointCoordinates.Count - 1 do
  begin
    PCItem := TPointCollectionItem(PointCoordinates.Items[i]);
    PCItem.X := PCItem.X + (FBorderWidth Div 2) - MinX;
    PCItem.Y := PCItem.Y + (FBorderWidth Div 2) - MinY;
  end;
end;

procedure THMIPolyline.BeginDrawPolyline;
var
  i: Integer;
  PCItem: TPointCollectionItem;
begin
  if FDesignDrawing then Exit;

  for i := 0 to PointCoordinates.Count - 1 do
  begin
    PCItem := TPointCollectionItem(PointCoordinates.Items[i]);
    PCItem.X := PCItem.X + Left; //+(FBorderWidth div 2);
    PCItem.Y := PCItem.Y + Top; //+(FBorderWidth div 2);
  end;
  FOldAlign := Align;
  Align := alClient;
  FDesignDrawing := True;

end;

procedure THMIPolyline.BeginEmptyPolyline;
begin
  if FDesignDrawing then Exit;

  PointCoordinates.Clear;
  FOldAlign := Align;
  Align := alClient;
  FDesignDrawing := True;
end;

procedure THMIPolyline.EndDrawPolyline;
begin
  Align := FOldAlign;
  FDesignDrawing := False;
  OptimizeDrawAfterFinish;
end;

procedure THMIPolyline.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  APoint: TPointCollectionItem;
  LastPoint: TPointCollectionItem;
  p45: Longint;
  CurDegrees: Double;
begin
  if csDesigning in ComponentState then
  begin
    if Shift = [ssShift, ssLeft] then
    begin
      EndDrawPolyline;
      Exit;
    end;

    if PointCoordinates.Count = 0 then
      LastPoint := nil
    else
      LastPoint := TPointCollectionItem(PointCoordinates.Items[PointCoordinates.Count - 1]);

    if (LastPoint <> nil) and (Shift = [ssCtrl, ssLeft]) then
    begin
      APoint := FPointCoordinates.Add;
      CurDegrees := Degrees(X, LastPoint.X, Y, LastPoint.Y);
      case Trunc(CurDegrees) of
        0..15:  begin     //0 degrees
                  APoint.Y := LastPoint.Y;
                  APoint.X := X;
                end;
        16..37,
        54..75: begin    //30 e 60 degrees
                  if Y >= LastPoint.Y then
                    APoint.Y := LastPoint.Y + Trunc(sin(degtorad(CurDegrees)) * Hipotenusa(X, LastPoint.X, Y, LastPoint.Y))
                  else
                    APoint.Y := LastPoint.Y - Trunc(sin(degtorad(CurDegrees)) * Hipotenusa(X, LastPoint.X, Y, LastPoint.Y));
                  APoint.X := X;
                end;
        38..53: begin    //45 degrees
                  p45 := max(Cateto(X, LastPoint.X), Cateto(Y, LastPoint.Y));
                  if X >= LastPoint.X then
                    APoint.X := LastPoint.X + p45
                  else
                    APoint.X := LastPoint.X - p45;

                  if Y >= LastPoint.Y then
                    APoint.Y := LastPoint.Y + p45
                  else
                    APoint.Y := LastPoint.Y - p45;
                end;
        76..90: begin    //30 degrees
                  APoint.X := LastPoint.X;
                  APoint.Y := Y;
                end;
      end;
    end;

    if (LastPoint = nil) or (Shift = [ssLeft]) then
    begin
      APoint := FPointCoordinates.Add;
      APoint.X := X;
      APoint.Y := Y;
    end;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure THMIPolyline.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LastPoint: TPointCollectionItem;
  ATextWidth: Integer;
begin
  if csDesigning in ComponentState then
  begin
    if PointCoordinates.Count = 0 then
      LastPoint := nil
    else
      LastPoint := TPointCollectionItem(PointCoordinates.Items[PointCoordinates.Count - 1]);

    if Shift = [ssCtrl] then
    begin
      FCtrlOnLastMouseMove := True;

      if LastPoint = nil then
        FPointInfo := Format('x=%d, y=%d', [X, Y])
      else
        FPointInfo := Format('x=%d, y=%d, Degrees=%d', [X, Y, Trunc(Degrees(X, LastPoint.X, Y, LastPoint.Y))]);

      ATextWidth := FControlArea.CanvasBGRA.TextWidth(FPointInfo);
      if ATextWidth = FPointInfoWidth then
        InvalidateDraw
      else
      begin
        FPointInfoWidth := ATextWidth;
        InvalidateShape;
      end;
    end
    else
    begin
      if FCtrlOnLastMouseMove then
      begin
        FCtrlOnLastMouseMove := False;
        FPointInfo := '';
        FPointInfoWidth := 0;
        InvalidateShape;
      end;
    end;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure THMIPolyline.CMDesignHitTest(var Message: TLMessage);
begin
  if FDesignDrawing then
    Message.Result := 1;
end;

constructor THMIPolyline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPointCoordinates := TPointCollection.Create(Self);
  FPointCoordinates.OnCollectionItemChange := @PointChanged;
  FPointCoordinates.OnNeedCompState := @CollectionNeedsComponentState;
  FBorderWidth := 2;
  FCtrlOnLastMouseMove := False;
  FBorderColor := clBlack;
  FPenStyle := psSolid;
end;

destructor THMIPolyline.Destroy;
begin
  FreeAndNil(FPointCoordinates);
  inherited Destroy;
end;

end.

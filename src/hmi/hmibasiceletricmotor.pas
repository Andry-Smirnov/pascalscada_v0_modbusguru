unit HMIBasicEletricMotor;

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  hmi_draw_basiccontrol, BGRABitmap, BGRABitmapTypes;

type

  { THMICustomBasicEletricMotor }

  THMICustomBasicEletricMotor = class(THMIBasicControl)
  private
    FDrawPump: Boolean;
    FMirrored: Boolean;
    procedure SetDrawPump(AValue: Boolean);
    procedure SetMirrored(AValue: Boolean);
  protected
    procedure DrawControl; override;
    property Mirrored: Boolean read FMirrored write SetMirrored default False;
    property DrawPump: Boolean read FDrawPump write SetDrawPump default True;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  THMIBasicEletricMotor = class(THMICustomBasicEletricMotor)
  published
    property Action;
    property DrawPump;
    property OnClick;
    property OnMouseDown;
    property OnMouseLeave;
    property OnMouseMove;
    property PopupMenu;
    property Enabled;

    property BorderColor;
    property BorderWidth;
    property BodyColor;
    property Mirrored;
  end;


implementation


{ THMIBasicEletricMotor }

procedure THMICustomBasicEletricMotor.SetMirrored(AValue: Boolean);
begin
  if FMirrored = AValue then Exit;
  FMirrored := AValue;
  invalidateShape;
end;

procedure THMICustomBasicEletricMotor.SetDrawPump(AValue: Boolean);
begin
  if FDrawPump = AValue then Exit;
  FDrawPump := AValue;
  invalidateShape;
end;

procedure THMICustomBasicEletricMotor.DrawControl;
var
  Rotate: Boolean;
  w, h: Integer;
  aux: TBGRABitmap;
  aux2: TBGRACustomBitmap;
begin
  inherited DrawControl;

  FControlArea.CanvasBGRA.Brush.Color := FBodyColor;
  FControlArea.CanvasBGRA.Pen.Color := FBorderColor;
  FControlArea.CanvasBGRA.Pen.Width := FBorderWidth;

  if Width >= Height then
  begin
    w := Width;
    h := Height;
    Rotate := False;
  end
  else
  begin
    w := Height;
    h := Width;
    Rotate := True;
  end;

  aux := TBGRABitmap.Create(w, h);
  try
    if FDrawPump then
    begin
      aux.CanvasBGRA.Rectangle(Trunc(0.07 * w), 0 + FBorderWidth, Trunc((0.07 * w) + (0.09) * w), Trunc(0.10 * h), True);

      aux.CanvasBGRA.Rectangle(0 + FBorderWidth,
        Trunc(20 / 52 * h),
        Trunc(0.07 * w),
        Trunc(32 / 52 * h), True);
    end;
    aux.RoundRectAntialias(Trunc(0.19 * w) - 1,
      Trunc(0.06 * h),
      w - FBorderWidth,
      Trunc(0.94 * h),
      Trunc(0.2 * w),
      Trunc(0.2 * w),
      ColorToBGRA(FBorderColor),
      FBorderWidth,
      ColorToBGRA(FBodyColor));
    if FDrawPump then
      aux.RoundRectAntialias(Trunc(0.04 * w),
        Trunc(0.06 * h),
        Trunc(0.19 * w),
        Trunc(0.94 * h),
        Trunc(0.075 * w),
        Trunc(0.075 * w),
        ColorToBGRA(FBorderColor),
        FBorderWidth,
        ColorToBGRA(FBodyColor));
    aux.RoundRectAntialias(Trunc(0.39 * w),
      Trunc((15 / 52) * h),
      Trunc(0.73 * w),
      Trunc((38 / 52) * h),
      Trunc(0.09 * w),
      Trunc(0.09 * w),
      ColorToBGRA(FBorderColor),
      FBorderWidth,
      ColorToBGRA(FBodyColor));
    aux.CanvasBGRA.Polyline([point(Trunc(0.81 * w) - FBorderWidth, Trunc(48 / 52 * h) - FBorderWidth Div 2),
      point(Trunc(0.81 * w) - FBorderWidth, Trunc(3 / 52 * h) + FBorderWidth Div 2)]);

    if Rotate then
    begin

      if Mirrored then
        aux2 := aux.RotateCW
      else
        aux2 := aux.RotateCCW;

      try
        FControlArea.Assign(aux2);
      finally
        FreeAndNil(aux2);
      end;
    end
    else
    begin
      FControlArea.Assign(aux);
      if FMirrored then
        FControlArea.HorizontalFlip;
    end;
  finally
    FreeAndNil(aux);
  end;

end;

constructor THMICustomBasicEletricMotor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDrawPump := True;
end;

end.

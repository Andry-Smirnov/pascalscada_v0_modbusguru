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
  InvalidateShape;
end;

procedure THMICustomBasicEletricMotor.SetDrawPump(AValue: Boolean);
begin
  if FDrawPump = AValue then Exit;
  FDrawPump := AValue;
  InvalidateShape;
end;

procedure THMICustomBasicEletricMotor.DrawControl;
var
  Rotate: Boolean;
  AWidth,
  AHeight: Integer;
  Aux: TBGRABitmap;
  Aux2: TBGRACustomBitmap;
begin
  inherited DrawControl;

  FControlArea.CanvasBGRA.Brush.Color := FBodyColor;
  FControlArea.CanvasBGRA.Pen.Color := FBorderColor;
  FControlArea.CanvasBGRA.Pen.Width := FBorderWidth;

  if Width >= Height then
  begin
    AWidth := Width;
    AHeight := Height;
    Rotate := False;
  end
  else
  begin
    AWidth := Height;
    AHeight := Width;
    Rotate := True;
  end;

  Aux := TBGRABitmap.Create(AWidth, AHeight);
  try
    if FDrawPump then
    begin
      Aux.CanvasBGRA.Rectangle(Trunc(0.07 * AWidth),
        0 + FBorderWidth,
        Trunc((0.07 * AWidth) + (0.09) * AWidth),
        Trunc(0.10 * AHeight), True);

      Aux.CanvasBGRA.Rectangle(0 + FBorderWidth,
        Trunc(20 / 52 * AHeight),
        Trunc(0.07 * AWidth),
        Trunc(32 / 52 * AHeight), True);
    end;
    Aux.RoundRectAntialias(Trunc(0.19 * AWidth) - 1,
      Trunc(0.06 * AHeight),
      AWidth - FBorderWidth,
      Trunc(0.94 * AHeight),
      Trunc(0.2 * AWidth),
      Trunc(0.2 * AWidth),
      ColorToBGRA(FBorderColor),
      FBorderWidth,
      ColorToBGRA(FBodyColor));
    if FDrawPump then
      Aux.RoundRectAntialias(Trunc(0.04 * AWidth),
        Trunc(0.06 * AHeight),
        Trunc(0.19 * AWidth),
        Trunc(0.94 * AHeight),
        Trunc(0.075 * AWidth),
        Trunc(0.075 * AWidth),
        ColorToBGRA(FBorderColor),
        FBorderWidth,
        ColorToBGRA(FBodyColor));
    Aux.RoundRectAntialias(Trunc(0.39 * AWidth),
      Trunc((15 / 52) * AHeight),
      Trunc(0.73 * AWidth),
      Trunc((38 / 52) * AHeight),
      Trunc(0.09 * AWidth),
      Trunc(0.09 * AWidth),
      ColorToBGRA(FBorderColor),
      FBorderWidth,
      ColorToBGRA(FBodyColor));
    Aux.CanvasBGRA.Polyline([point(Trunc(0.81 * AWidth) - FBorderWidth,
      Trunc(48 / 52 * AHeight) - FBorderWidth div 2),
      point(Trunc(0.81 * AWidth) - FBorderWidth, Trunc(3 / 52 * AHeight) + FBorderWidth div 2)]);

    if Rotate then
    begin
      if Mirrored then
        Aux2 := Aux.RotateCW
      else
        Aux2 := Aux.RotateCCW;
      try
        FControlArea.Assign(Aux2);
      finally
        FreeAndNil(Aux2);
      end;
    end
    else
    begin
      FControlArea.Assign(Aux);
      if FMirrored then
        FControlArea.HorizontalFlip;
    end;
  finally
    FreeAndNil(Aux);
  end;
end;

constructor THMICustomBasicEletricMotor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDrawPump := True;
end;

end.

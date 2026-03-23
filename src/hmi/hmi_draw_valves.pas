unit HMI_Draw_Valves;

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  hmi_draw_basiccontrol, BGRABitmap, BGRABitmapTypes;

type

  TValveType = (vtSimple, vtPneumaticOnOff, vtPneumaticProportional, vtMotorisedProportional, vtPneumaticDrawer);

  { THMIBasicValve }

  THMICustomBasicValve = class(THMIBasicControl)
  private
    FMirrored: Boolean;
    FValveBodyPercent: Double;
    FValveType: TValveType;
    procedure SetMirrored(AValue: Boolean);
    procedure SetValveBodyPercent(AValue: Double);
    procedure SetValveType(AValue: TValveType);
  protected
    procedure DrawControl; override;

    property Mirrored: Boolean read FMirrored write SetMirrored default False;
    property ValveBodyPercent: Double read FValveBodyPercent write SetValveBodyPercent;
    property ValveType: TValveType read FValveType write SetValveType default vtSimple;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  THMIBasicValve = class(THMICustomBasicValve)
  published
    property BodyColor;
    property BorderColor;
    property BorderWidth;

    property Mirrored;
    property ValveBodyPercent;
    property ValveType;

    property OnClick;
    property Action;
  end;


implementation


uses
  Math;


procedure THMICustomBasicValve.SetMirrored(AValue: Boolean);
begin
  if FMirrored = AValue then Exit;
  FMirrored := AValue;
  InvalidateShape;
end;

procedure THMICustomBasicValve.SetValveBodyPercent(AValue: Double);
begin
  if FValveBodyPercent = AValue then Exit;
  if (FValveBodyPercent < 0) or (FValveBodyPercent > 1) then
    raise Exception.Create('ValveBodyPercent accepts values between [0.0 .. 1.0]');
  FValveBodyPercent := AValue;
  InvalidateShape;
end;

procedure THMICustomBasicValve.SetValveType(AValue: TValveType);
begin
  if FValveType = AValue then Exit;
  FValveType := AValue;
  InvalidateShape;
end;

procedure THMICustomBasicValve.DrawControl;
var
  Points: array of TPointF;
  IdealHeight: Real;
  IdealWidth: Real;
  SquareWidth: Real;
begin
  inherited DrawControl;

  FControlArea.CanvasBGRA.Brush.Color := FBodyColor;
  FControlArea.CanvasBGRA.Pen.Color := FBorderColor;
  FControlArea.CanvasBGRA.Pen.Width := FBorderWidth;

  SetLength(Points, 4);
  if Width >= Height then
  begin
    if ValveType = vtPneumaticDrawer then
    begin
      Points[0].x := 0 + (FBorderWidth mod 2);
      Points[0].y := 0 + (FBorderWidth mod 2);

      Points[1].x := Width - (FBorderWidth mod 2);
      Points[1].y := 0 + (FBorderWidth mod 2);

      Points[2].x := Width - (FBorderWidth mod 2);
      Points[2].y := Height - (FBorderWidth mod 2);

      Points[3].x := 0 + (FBorderWidth mod 2);
      Points[3].y := Height - (FBorderWidth mod 2);

      FControlArea.CanvasBGRA.PolygonF(Points);
    end
    else
    begin
      Points[0].x := FBorderWidth div 2 + FBorderWidth mod 2;
      Points[0].y := (1 - FValveBodyPercent) * Height;

      Points[1].x := Width - (FBorderWidth div 2) - (FBorderWidth mod 2);
      Points[1].y := Height - (FBorderWidth / 2);

      Points[2].x := Width - (FBorderWidth div 2) - (FBorderWidth mod 2);
      Points[2].y := (1 - FValveBodyPercent) * Height;

      Points[3].x := FBorderWidth div 2 + FBorderWidth mod 2;
      Points[3].y := Height - (FBorderWidth / 2);

      FControlArea.CanvasBGRA.PolygonF(Points);

      //risco
      case FValveType of
        vtPneumaticProportional,
        vtPneumaticOnOff,
        vtMotorisedProportional:
          FControlArea.CanvasBGRA.PolylineF([PointF(IfThen(((Width + FBorderWidth) mod 2) = 1, Width, Width + 1) / 2,
            (FBorderWidth)),
            PointF(IfThen(((Width + FBorderWidth) mod 2) = 1, Width, Width + 1) / 2,
            (1 - (FValveBodyPercent / 2)) * Height - (FBorderWidth / 2))]);
      end;

      case FValveType of
        vtPneumaticProportional, vtMotorisedProportional: begin
          IdealWidth := Width / 2 - FBorderWidth;
          IdealHeight := (Width / 4) * (FValveBodyPercent * Height) / Width + ((1 - FValveBodyPercent) * Height) - FBorderWidth;
          SquareWidth := min(IdealWidth, IdealHeight);
          Points[0].x := (Width - SquareWidth) / 2;
          Points[0].y := FBorderWidth div 2 + FBorderWidth mod 2;

          Points[1].x := Width - ((Width - SquareWidth) / 2);
          Points[1].y := Points[0].y;

          Points[2].x := Points[1].x;
          Points[2].y := SquareWidth + (FBorderWidth div 2 + FBorderWidth mod 2);

          Points[3].x := Points[0].x;
          Points[3].y := Points[2].y;
          FControlArea.CanvasBGRA.PolygonF(Points);

          if FValveType = vtMotorisedProportional then
          begin
            FControlArea.FontHeight := trunc(SquareWidth * 0.9 - 2 * FBorderWidth);
            FControlArea.FontOrientation := 0;
            FControlArea.TextOut(Width / 2, trunc((SquareWidth - FControlArea.FontHeight) / 2), 'M', colortobgra(FBorderColor), taCenter);

          end;
        end;
        vtPneumaticOnOff: begin
          FControlArea.Pie(Width / 2,
            ((1 - FValveBodyPercent) * Height) + (FBorderWidth / 2),
            Width / 4,
            Height * (1 - FValveBodyPercent),
            0,
            180 * 0.0174532925,
            colortobgra(FBorderColor),
            FBorderWidth,
            colortobgra(FBodyColor));
        end;
      end;
    end;
  end
  else
  begin
    if ValveType = vtPneumaticDrawer then
    begin
      Points[0].x := 0 + (FBorderWidth mod 2);
      Points[0].y := 0 + (FBorderWidth mod 2);

      Points[1].x := Width - (FBorderWidth mod 2);
      Points[1].y := 0 + (FBorderWidth mod 2);

      Points[2].x := Width - (FBorderWidth mod 2);
      Points[2].y := Height - (FBorderWidth mod 2);

      Points[3].x := 0 + (FBorderWidth mod 2);
      Points[3].y := Height - (FBorderWidth mod 2);

      FControlArea.CanvasBGRA.PolygonF(Points);
    end
    else
    begin
      Points[0].x := (1 - FValveBodyPercent) * Width;
      Points[0].y := FBorderWidth div 2 + FBorderWidth mod 2;

      Points[1].x := Width - (FBorderWidth / 2);
      Points[1].y := Height - (FBorderWidth div 2) - (FBorderWidth mod 2);

      Points[2].x := (1 - FValveBodyPercent) * Width;
      Points[2].y := Height - (FBorderWidth div 2) - (FBorderWidth mod 2);

      Points[3].x := Width - (FBorderWidth / 2);
      Points[3].y := FBorderWidth div 2 + FBorderWidth mod 2;

      FControlArea.CanvasBGRA.PolygonF(Points);

      //risco
      case FValveType of
        vtPneumaticProportional,
        vtPneumaticOnOff,
        vtMotorisedProportional:
          FControlArea.CanvasBGRA.PolylineF([PointF(FBorderWidth, IfThen(((Height + FBorderWidth) mod 2) = 1, Height, Height + 1) / 2),
            PointF((1 - (FValveBodyPercent / 2)) * Width - (BorderWidth / 2), IfThen(((Height + FBorderWidth) mod 2) = 1, Height, Height + 1) / 2)]);
      end;

      case FValveType of
        vtPneumaticProportional, vtMotorisedProportional: begin
          IdealWidth := Height / 2 - FBorderWidth;
          IdealHeight := (Height / 4) * (FValveBodyPercent * Width) / Height + ((1 - FValveBodyPercent) * Width) - FBorderWidth;
          SquareWidth := min(IdealWidth, IdealHeight);
          Points[0].x := FBorderWidth div 2 + FBorderWidth mod 2;
          Points[0].y := (Height - SquareWidth) / 2;

          Points[1].x := SquareWidth + (FBorderWidth div 2 + FBorderWidth mod 2);
          Points[1].y := Points[0].y;

          Points[2].x := Points[1].x;
          Points[2].y := Height - ((Height - SquareWidth) / 2);

          Points[3].x := Points[0].x;
          Points[3].y := Points[2].y;
          FControlArea.CanvasBGRA.PolygonF(Points);

          if FValveType = vtMotorisedProportional then
          begin
            FControlArea.FontHeight := trunc(SquareWidth * 0.9 - FBorderWidth);
            FControlArea.FontOrientation := 900;
            FControlArea.TextOut(trunc((SquareWidth - FControlArea.FontHeight) / 2), Height / 2, 'M', colortobgra(FBorderColor), taCenter);

          end;
        end;
        vtPneumaticOnOff: begin
          FControlArea.Pie(((1 - FValveBodyPercent) * Width) + (FBorderWidth / 2),
            Height / 2,
            Width * (1 - FValveBodyPercent),
            Height / 4,
            90 * 0.0174532925,
            270 * 0.0174532925,
            colortobgra(FBorderColor),
            FBorderWidth,
            colortobgra(FBodyColor));
        end;
      end;
    end;
  end;

  if FMirrored and (ValveType <> vtPneumaticDrawer) then
  begin
    if Height <= Width then
      FControlArea.VerticalFlip
    else
      FControlArea.HorizontalFlip;
  end;
end;

constructor THMICustomBasicValve.Create(AOwner: TComponent);
begin
  FMirrored := False;
  FValveBodyPercent := 0.7;
  inherited Create(AOwner);
end;

end.

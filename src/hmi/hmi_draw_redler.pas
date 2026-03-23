unit hmi_draw_redler;

{$mode objfpc}{$H+}

interface

uses
  Controls, SysUtils, Graphics, Classes, hmi_draw_basic_horizontal_control,
  BGRABitmap, BGRABitmapTypes, hmi_polyline;

type

  { THMICustomBasicRedler }

  THMICustomBasicRedler = class(THMIBasicHorizontalControl)
  protected
    procedure UpdateShape; override;
    procedure SetBodyHeight(AValue: Byte); override;
    procedure DrawControl; override;
  end;

  THMIRedlerBasico = class(THMICustomBasicRedler)
  published
    property OnClick;
    property BodyColor;
    property BorderColor;
  end;

implementation

{ THMICustomBasicRedler }

procedure THMICustomBasicRedler.UpdateShape;
begin
  //evita chamar o metodo herdado
  //pois este e um controle retangular
  //e nao necessita de cortes.
end;

procedure THMICustomBasicRedler.SetBodyHeight(AValue: Byte);
var
  MinHeight: Integer;
begin
  {espaco para as pás e mais um pixel para o eixo central.}
  MinHeight := 2 * FBorderWidth + 2 + 1;
  if AValue < MinHeight then Exit;
  inherited SetBodyHeight(AValue);
end;

procedure THMICustomBasicRedler.DrawControl;
var
  EixoH: Integer;
  EixoTop: Integer;
  PaH: Integer;
  PaX: Integer;
  EmptyArea: TBGRABitmap;
begin
  EmptyArea := TBGRABitmap.Create(Width, Height);
  try
    FControlArea.Assign(EmptyArea);
  finally
    FreeAndNil(EmptyArea);
  end;

  //###############################################################################
  // Redler filling, line color, and diameter
  //###############################################################################
  FControlArea.CanvasBGRA.Brush.Color := FBodyColor;
  FControlArea.CanvasBGRA.Pen.Color := FBorderColor;
  FControlArea.CanvasBGRA.Pen.Width := FBorderWidth;

  // desenha o quadrado da fita.
  FControlArea.CanvasBGRA.Rectangle(0, 0, Width, FBodyHeight);

  // evita um lado menor que o outro.
  if (FBodyHeight mod 2) = 1 then
    EixoH := (FBodyHeight - (2 * FBorderWidth)) div 3
  else
    EixoH := (FBodyHeight - (2 * FBorderWidth)) div 4;

  // Smallest shaft size
  if EixoH < 1 then
    EixoH := 1;

  //###############################################################################
  // Redler shaft, color, and line diameter
  //###############################################################################
  FControlArea.CanvasBGRA.Brush.Color := FBorderColor;
  FControlArea.CanvasBGRA.Pen.Color := FBorderColor;
  FControlArea.CanvasBGRA.Pen.Width := FBorderWidth;

  EixoTop := (FBodyHeight - EixoH) div 2;

  // Draw the square of the tape.
  FControlArea.CanvasBGRA.Rectangle(0, EixoTop, Width, EixoTop + EixoH);

  // Draws the Redler paddles
  PaH := FBodyHeight - (2 * FBorderWidth) - EixoH;
  PaX := FBodyHeight div 2;
  while (PaX + EixoH) < (Width - (2 * FBorderWidth)) do
  begin
    // Draw below the axis
    if (PaX mod 12) = 0 then
      FControlArea.CanvasBGRA.Rectangle(PaX, EixoTop + EixoH, PaX + EixoH, EixoTop + EixoH + PaH)
    else
      FControlArea.CanvasBGRA.Rectangle(PaX, 0, PaX + EixoH, PaH - 1);
    Inc(PaX, FBodyHeight div 2);
  end;
end;

end.

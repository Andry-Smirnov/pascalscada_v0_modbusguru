unit hmi_draw_rosca;

{$mode objfpc}{$H+}

interface

uses
  Controls, SysUtils, Graphics, Classes, hmi_draw_basic_horizontal_control,
  BGRABitmap, BGRABitmapTypes;

type

  { THMIRoscaBasica }

  THMIRoscaBasica = class(THMIBasicHorizontalControl)
  protected
    procedure DrawControl; override;
    procedure UpdateShape; override;

  published
    property BorderColor;
    property BodyColor;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
  end;

implementation

{ TRoscaBasica }

procedure THMIRoscaBasica.DrawControl;
var
  LineX: Integer;
  X: array of TPoint;
  H: Integer;
  EixoH: Integer;
  EixoTop: Integer;
  EmptyArea: TBGRABitmap;
begin
  EmptyArea := TBGRABitmap.Create(Width, Height);
  try
    FControlArea.Assign(EmptyArea);
  finally
    FreeAndNil(EmptyArea);
  end;

  //###############################################################################
  //preenchimento do redlers, cor e diametro da linha.
  //###############################################################################
  FControlArea.CanvasBGRA.Brush.Color := FBodyColor;
  FControlArea.CanvasBGRA.Pen.Color := FBorderColor;
  FControlArea.CanvasBGRA.Pen.Width := FBorderWidth;

  //desenha o quadrado da rosca.
  FControlArea.CanvasBGRA.Rectangle(0, 0, Width, FBodyHeight);

  LineX := 0;
  while LineX < (Width + FBodyHeight) do
  begin
    H := Length(X);
    //adiciona os pontos a poliline da rosca..
    SetLength(X, H + 1);
    X[H].x := LineX;
    if (LineX mod (2 * FBodyHeight)) = 0 then
    begin
      X[H].Y := 0;
    end
    else
    begin
      X[H].Y := FBodyHeight;
    end;

    Inc(LineX, FBodyHeight);
  end;
  // Draw the "thread"
  FControlArea.CanvasBGRA.Pen.Width := FBorderWidth + 1;
  FControlArea.CanvasBGRA.Polyline(X);
end;

procedure THMIRoscaBasica.UpdateShape;
begin
  //evita chamar o metodo herdado
  //pois este e um controle retangular
  //e nao necessita de cortes.
end;

end.

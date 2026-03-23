unit hmifaceplatecontainer;

{$mode ObjFPC}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  LCLType, PLCStruct, PLCStructElement, plcstructstring, LMessages;

type

  { TFaceplateFrame }

  TFaceplateFrame = class(TFrame)
  private
    ffaceplatetag: TPLCStruct;
    FOnLoaded: TNotifyEvent;
    FTransparent: Boolean;
    procedure setTransparent(AValue: Boolean);
  protected

    function IsControlArea(X, Y: Integer): Boolean; virtual;

    procedure setfaceplateTag(AValue: TPLCStruct);
    procedure Loaded; override;
    procedure CMHitTest(var Message: TCMHittest); message CM_HITTEST;
    //procedure CMDesigerHitTest(var Message: TCMHittest) ; message CM_DESIGNERHITTEST;
  public
    constructor Create(TheOwner: TComponent); override;
    procedure Paint; override;
  published
    property FaceplatePLCTag: TPLCStruct read ffaceplatetag write setfaceplateTag;
    property OnLoaded: TNotifyEvent read FOnLoaded write FOnLoaded;
    property Transparent: Boolean read FTransparent write setTransparent;
  end;

  TFaceplateFormClass = class of TFaceplateFrame;


implementation


uses
  StdCtrls, LazRegions, LCLIntf, Math;

  { TFaceplate }

procedure TFaceplateFrame.Paint;
begin
  //EraseBackground(Canvas.Handle);
  inherited Paint;
end;

procedure TFaceplateFrame.setTransparent(AValue: Boolean);
begin
  if FTransparent = AValue then Exit;
  FTransparent := AValue;
end;

function TFaceplateFrame.IsControlArea(X, Y: Integer): Boolean;
begin
  Result := not FTransparent;
end;

procedure TFaceplateFrame.setfaceplateTag(AValue: TPLCStruct);
var
  i: Integer;
begin
  for i := 0 to ComponentCount - 1 do
  begin
    //TODO mudar somente tags de faceplate. Change only faceplate tags
    if (Components[i] is TPLCStructItem) {and Tag.Faceplate} then
    begin
      (Components[i] as TPLCStructItem).PLCBlock := AValue;
      Continue;
    end;
    if (Components[i] is TPLCStructString) {and Tag.Faceplate} then
    begin
      (Components[i] as TPLCStructString).PLCBlock := AValue;
      Continue;
    end;
  end;
end;

procedure TFaceplateFrame.Loaded;
var
  i: Integer;
  Rgn: HRGN;
  Rgn2: HRGN;
begin
  inherited Loaded;
  Rgn := CreateRectRgn(0, 0, 0, 0);
  try
    for i := 0 to ControlCount - 1 do
    begin
      try
        Rgn2 := CreateRectRgn(
          Controls[i].Left,
          Controls[i].Top,
          Controls[i].Left + Controls[i].Width,
          Controls[i].Top + Controls[i].Height);
        CombineRgn(Rgn, Rgn, Rgn2, RGN_OR);
        Controls[i].ControlStyle := Controls[i].ControlStyle + [csNoDesignSelectable];
      finally
        DeleteObject(Rgn2);
      end;
    end;
    SetWindowRgn(Handle, Rgn, True);
  finally
    DeleteObject(Rgn);
  end;

  if Assigned(FOnLoaded) then
    FOnLoaded(Self);
end;

procedure TFaceplateFrame.CMHitTest(var Message: TCMHittest);
begin
  Message.Result := IfThen(FTransparent, 0, 1);
end;

constructor TFaceplateFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  ControlStyle := ControlStyle + [csOwnedChildrenNotSelectable];// + [csOpaque];
end;

end.

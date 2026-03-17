unit ChipCardReader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs;

type

  { TChipCardReader }

  TChipCardReader = class(TComponent)
  public
    function InitializeChipCard: Boolean; virtual;
    function ChipCardReady: Boolean; virtual;
    function IsEmptyChipCard: Boolean; virtual;
    function ChipCardRead(var aChipCardCode: UTF8String): Boolean; virtual;
    function FinishChipCard: Boolean; virtual;
  end;

implementation

{ TChipCardReader }

function TChipCardReader.InitializeChipCard: Boolean;
begin
  Exit(False);
end;

function TChipCardReader.ChipCardReady: Boolean;
begin
  Exit(False);
end;

function TChipCardReader.IsEmptyChipCard: Boolean;
begin
  Result := True;
end;

function TChipCardReader.ChipCardRead(var aChipCardCode: UTF8String): Boolean;
begin
  Result := False;
end;

function TChipCardReader.FinishChipCard: Boolean;
begin
  Exit(False);
end;

end.

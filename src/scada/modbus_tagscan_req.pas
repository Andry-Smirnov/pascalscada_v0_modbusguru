unit modbus_tagscan_req;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

type
  TReqItem = record
    LastUpdate: TDateTime;

    Station: LongInt;
    Func: LongInt;
    StartAddress: LongInt;
    Size: LongInt;

    UpdateRate: LongInt;
    Read: Boolean;
    NeedUpdate: Boolean;
    class operator Equal(A, B: TReqItem) R: Boolean;
  end;
  PReqItem = ^TReqItem;


implementation


class operator TReqItem.Equal(A, B: TReqItem) R: Boolean;
begin
  R := True;
end;


end.


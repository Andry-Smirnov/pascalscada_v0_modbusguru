unit s7scanreq;

//{$mode objfpc}{$H+}
{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

type

  { TReqItem }

  TS7ScanReqItem = record
    LastUpdate: TDateTime;
    iPLC: LongInt;
    iDB: LongInt;
    iDBNum: LongInt;
    iReqType: LongInt;
    iStartAddress: LongInt;
    iSize: LongInt;
    NextUpdtInMs: LongInt;
    UpdateRate: LongInt;
    Read: Boolean;
    NeedUpdate: Boolean;
    class operator Equal (A, B: TS7ScanReqItem) R: Boolean;
  end;
  PS7ScanReqItem = ^TS7ScanReqItem;

implementation

{ TReqItem }

class operator TS7ScanReqItem.Equal(A, B: TS7ScanReqItem) R: Boolean;
begin
  R := (A.LastUpdate = B.LastUpdate)
    and (A.iPLC = B.iPLC)
    and (A.iDB = B.iDB)
    and (A.iDBNum = B.iDBNum)
    and (A.iReqType = B.iReqType)
    and (A.iStartAddress = B.iStartAddress)
    and (A.iSize = B.iSize)
    and (A.UpdateRate = B.UpdateRate)
    and (A.NeedUpdate = B.NeedUpdate);
end;

end.


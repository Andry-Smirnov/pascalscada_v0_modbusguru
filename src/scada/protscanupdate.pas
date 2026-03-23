{$i ../common/language.inc}
{:
@abstract(Updates the tag values.)
@author(Fabio Luis Girardi fabio@pascalscada.com)
}
unit protscanupdate;

{$IFDEF FPC}
{$IFDEF DEBUG}
  {$DEFINE FDEBUG}
{$ENDIF}
{$ENDIF}

interface

uses
  Classes, SysUtils, CrossEvent, ProtocolTypes, MessageSpool, syncobjs, tag,
  crossthreads;

type

  TUserUpdateTimeProc = procedure(UserTime: Double) of object;

  {: @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  Class of thread that updates the tag values. Used by TProtocolDriver.
  @seealso(TProtocolDriver) }
  TScanUpdate = class(TpSCADACoreAffinityThreadWithLoop)
  private
    FUserUpdateTimePRoc: TUserUpdateTimeProc;
    FOwnerProtocolDriver: TComponent;
    FSleepInterruptable: TCrossEvent;
    TagCBack: TTagCommandCallBack;
    FTagRec: PTagRec;
    Fvalues: TScanReadRec;
    FCmd: TTagCommand;
    PGetValues: TGetValues;
    PScanTags: TGetMultipleValues;
    FSpool: TMessageSpool;
    PScannedValues: TArrayOfScanUpdateRec;
    procedure SyncCallBack;
    procedure SyncException;
    procedure UpdateMultipleTags;
    procedure CheckScanReadOrWrite;
  protected
    //: @exclude
    procedure Loop; override;
  public
    //: @exclude
    constructor Create(StartSuspended: Boolean; OwnerProtocol: TComponent; UsrUpdTime: TUserUpdateTimeProc);
    //: @exclude
    destructor Destroy; override;
    //: Requests the thread finalization.
    procedure Terminate; override;
    {: Updates the tag that requested a scan read.
    @param(Tag TTagRec. Structure with informations about the tag.)
    @raises(Exception if the thread was not initialized.) }
    procedure ScanRead(tag: TTagRec);
    {: Updates the the tag that requested a scan write.
       @param(SWPkg PScanWriteRec. Points to a structure with informations about
           the scan write and Tag.)
       @raises(Exception if the thread was not initialized.) }
    procedure ScanRequestCallBack(SReqPkg: PScanReqRec; IsScanWrite: Boolean = True);
  published
    //: Event called by thread to get values and update a tag.
    property OnGetValue: TGetValues read PGetValues write PGetValues;
    //: Returns the lists of tags to be updated or the next time to check has tags to be updated.
    property OnScanTags: TGetMultipleValues read PScanTags write PScanTags;
  end;


implementation


uses
  {$IFDEF FDEBUG}
LCLProc,
  {$ENDIF}
  ProtocolDriver,
  hsstrings,
  crossdatetime,
  dateutils;


////////////////////////////////////////////////////////////////////////////////
// implementation of TScanUpdate class
////////////////////////////////////////////////////////////////////////////////
constructor TScanUpdate.Create(StartSuspended: Boolean; OwnerProtocol: TComponent; UsrUpdTime: TUserUpdateTimeProc);
begin
  inherited Create(StartSuspended);
  if not (OwnerProtocol is TProtocolDriver) then
    raise Exception.Create(STheOwnerMustBeAProtocolDriver);

  FOwnerProtocolDriver := OwnerProtocol;
  Priority := tpHighest;
  FUserUpdateTimePRoc := UsrUpdTime;
  FSpool := TMessageSpool.Create;
  FSleepInterruptable := TCrossEvent.Create(False, False);
end;

destructor TScanUpdate.Destroy;
begin
  inherited Destroy;

  FSleepInterruptable.SetEvent;
  FreeAndNil(FSleepInterruptable);
  FreeAndNil(FSpool);
end;

procedure TScanUpdate.Terminate;
begin
  inherited Terminate;
  FSleepInterruptable.SetEvent;
  repeat
    CheckSynchronize(1);
  until WaitEnd(1) = wrSignaled;
end;

procedure TScanUpdate.Loop;
var
  i,
  FValor,
  Timeout: Longint;
  AStart: TDateTime;
begin
  try
    CheckScanReadOrWrite;
    if Assigned(PScanTags) then
    begin
      SetLength(PScannedValues, 0);
      Timeout := PScanTags(PScannedValues);
      if Length(PScannedValues) > 0 then
      begin
        AStart := CrossNow;
        Synchronize(@UpdateMultipleTags);
        FValor := MilliSecondsBetween(CrossNow, AStart);

        for i := 0 to High(PScannedValues) do
          SetLength(PScannedValues[i].Values, 0);

        SetLength(PScannedValues, 0);

        Timeout := Timeout - FValor;
      end;
    end
    else
      Timeout := 1;

    if not FSleepInterruptable.ResetEvent then FSleepInterruptable.ResetEvent;
    if (Timeout) > 0 then
    begin
      FSleepInterruptable.WaitFor(Timeout);
    end
    else
      FSleepInterruptable.WaitFor(1);
  except
    //  on E: Exception do begin
    //    {$IFDEF FDEBUG}
    //    DebugLn('TScanUpdate.Execute:: ' + e.Message);
    //    DumpStack;
    //    {$ENDIF}
    //    Ferro := E;
    //    Synchronize(@SyncException);
    //  end;
  end;

end;

procedure TScanUpdate.ScanRead(tag: TTagRec);
var
  TagPkg: PTagRec;
begin
  New(TagPkg);
  Move(tag, TagPkg^, SizeOf(TTagRec));
  FSpool.PostMessage(PSM_TAGSCANREAD, TagPkg, nil, False);
  FSleepInterruptable.SetEvent;
end;

procedure TScanUpdate.ScanRequestCallBack(SReqPkg: PScanReqRec; IsScanWrite: Boolean);
begin
  if IsScanWrite then
    FSpool.PostMessage(PSM_TAGSCANWRITE, SReqPkg, nil, True)
  else
    FSpool.PostMessage(PSM_SINGLESCANREAD, SReqPkg, nil, True);

  FSleepInterruptable.SetEvent;
end;

procedure TScanUpdate.SyncException;
begin
  //try
  //  Application.ShowException(Ferro);
  //except
  //end;
end;

procedure TScanUpdate.UpdateMultipleTags;
var
  i: Longint;
  found: Boolean;
begin
  for i := 0 to High(PScannedValues) do
  begin
    found := False;
    if TProtocolDriver(FOwnerProtocolDriver).IsMyTag(TTag(TMethod(PScannedValues[i].CallBack).Data)) and ((TTag(TMethod(PScannedValues[i].CallBack).Data).ComponentState * [csDestroying]) = []) then
    begin
      found := True;
    end;
    if not found then
      Continue;
    with PScannedValues[i] do
    try
      CallBack(0, Values, ValueTimeStamp, tcScanRead, LastResult, 0);
    finally
    end;
  end;
end;

procedure TScanUpdate.CheckScanReadOrWrite;
var
  x: PScanReqRec;
  PMsg: TMSMsg;
begin
  while (not Terminated) and FSpool.PeekMessage(PMsg, PSM_TAGSCANREAD, PSM_SINGLESCANREAD, True) do
  begin
    //try
    case PMsg.MsgID of
      PSM_TAGSCANWRITE,
      PSM_SINGLESCANREAD: begin
                            x := PScanReqRec(PMsg.wParam);

                            TagCBack := x^.tag.CallBack;
                            Fvalues.Values := x^.Values;
                            Fvalues.Offset := x^.tag.Offset;
                            Fvalues.RealOffset := x^.tag.RealOffset;
                            Fvalues.ValuesTimestamp := x^.ValueTimeStamp;
                            Fvalues.LastQueryResult := x^.RequestResult;
                            if PMsg.MsgID = PSM_TAGSCANWRITE then
                              FCmd := tcScanWrite
                            else
                              FCmd := tcSingleScanRead;

                            // sync tag (update it)
                            FTagRec := @x^.tag;
                            try
                              Synchronize(@SyncCallBack);
                            finally
                              FTagRec := nil;
                            end;
                            // free the memory of the request
                            SetLength(x^.Values, 0);
                            Dispose(x);
                            TagCBack := nil;
            end;
      PSM_TAGSCANREAD:  begin
                          FTagRec := PTagRec(PMsg.wParam);
                          TagCBack := FTagRec^.CallBack;
                          Fvalues.Offset := FTagRec^.Offset;
                          Fvalues.RealOffset := FTagRec^.RealOffset;

                          if Assigned(PGetValues) then
                          begin
                            PGetValues(FTagRec^, Fvalues);
                          end
                          else
                            Fvalues.LastQueryResult := ioDriverError;

                          FCmd := tcScanRead;

                          Synchronize(@SyncCallBack);

                          // free the memory of the request
                          SetLength(Fvalues.Values, 0);
                          Dispose(FTagRec);
                          TagCBack := nil;
                        end;
    end;
    //except
    //  on E: Exception do begin
    //    {$IFDEF FDEBUG}
    //    DebugLn('TScanUpdate.Execute:: ' + e.Message);
    //    DumpStack;
    //    {$ENDIF}
    //    Ferro := E;
    //    Synchronize(@SyncException);
    //  end;
    //end;
  end;
end;

procedure TScanUpdate.SyncCallBack;
var
  ReqID: Longword;
begin
  if Terminated then Exit;
  //try
  if Assigned(FTagRec) then
    ReqID := FTagRec^.ID
  else
    ReqID := 0;

  if Assigned(TagCBack) then
    TagCBack(ReqID, Fvalues.Values, Fvalues.ValuesTimestamp, FCmd, Fvalues.LastQueryResult, Fvalues.RealOffset);
  //except
  //  on erro:Exception do begin
  //    Ferro:=erro;
  //    SyncException;
  //  end;
  //end;
end;

end.

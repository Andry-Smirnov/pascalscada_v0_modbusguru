{$i ../common/language.inc}
{:
@abstract(Process request of read and write by scan (asynchronous).)
@author(Fabio Luis Girardi fabio@pascalscada.com)
}
unit protscan;

{$IFDEF FPC}
  {$IFDEF DEBUG}
    {$DEFINE FDEBUG}
  {$ENDIF}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  CrossEvent,
  protscanupdate,
  MessageSpool,
  syncobjs,
  crossthreads,
  ProtocolTypes
  {$IFNDEF FPC}
  , Windows
  {$ENDIF}
  ;


type

  {: @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  Thread class that processes the requests the reads and writes by scan (asynchronous)
  and keep the tag values updated. Used by the class TProtocolDriver.
  @seealso(TProtocolDriver) }
  TScanThread = class(TpSCADACoreAffinityThreadWithLoop)
  private
    FDoSingleScanRead: TSingleScanReadProc;
    FWaitToWrite: TCrossEvent;

    FDoScanRead: TScanReadProc;
    FDoScanWrite: TScanWriteProc;

    FMinScan: Cardinal;
    FSpool: TMessageSpool;
    PScanUpdater: TScanUpdate;

    procedure SyncException;
  protected
    //: Verifies if the thread has write requests on queue.
    procedure CheckScanWriteCmd;

    //: @exclude
    procedure Loop; override;
  public
    //: @exclude
    constructor Create(StartSuspended: Boolean; ScanUpdater: TScanUpdate);
    //: @exclude
    destructor Destroy; override;

    //: Requests the thread finalization.
    procedure Terminate; override;

    {: Put a values write request to be processed by the scan (queue) of protocol.
    @param(SWPkg PScanReadRec. Points to a structure with informations about
           the write command.)
    @raises(Exception if the thread didn't responds.) }
    procedure ScanWrite(SWPkg: PScanReqRec);
    {: Put a read request to be processed by the scan (queue) of protocol.
    @param(SWPkg PScanReadRec. Points to a structure with informations about
           the write command.)
    @raises(Exception if the thread didn't responds.) }
    procedure SingleScanRead(SRPkg: PScanReqRec);
  published
    {: How many milliseconds the thread will sleep if it didn't nothing, to avoid
    the high CPU usage. }
    property MinTimeOfScan: Cardinal read FMinScan write FMinScan nodefault;
    //: Event called to execute a scan read command.
    property OnDoScanRead: TScanReadProc read FDoScanRead write FDoScanRead;
    {: Event called to execute a scan write command.
    @seealso(TScanWriteProc) }
    property OnDoScanWrite: TScanWriteProc read FDoScanWrite write FDoScanWrite;
    //: Event called to execute a single scan read.
    property OnDoSingleScanRead: TSingleScanReadProc read FDoSingleScanRead write FDoSingleScanRead;
  end;


implementation


uses
  hsstrings,
  pascalScadaMTPCPU
  {$IFDEF FDEBUG}
  , LCLProc
  {$ENDIF}
  ;


  ////////////////////////////////////////////////////////////////////////////////
  // implementation of TScanThread Class
  ////////////////////////////////////////////////////////////////////////////////

constructor TScanThread.Create(StartSuspended: Boolean; ScanUpdater: TScanUpdate);
begin
  inherited Create(StartSuspended);
  Priority := tpHighest;
  FSpool := TMessageSpool.Create;
  PScanUpdater := ScanUpdater;
  FWaitToWrite := TCrossEvent.Create(True, False);
  FMinScan := 0;
end;

destructor TScanThread.Destroy;
begin
  Terminate;
  FreeAndNil(FWaitToWrite);
  FreeAndNil(FSpool);
  inherited Destroy;
end;

procedure TScanThread.Loop;
var
  NeedSleep: Longint;
begin
  CheckScanWriteCmd;
  if Assigned(FDoScanRead) then
  begin
    try
      NeedSleep := 0;
      FDoScanRead(Self, NeedSleep);
      if NeedSleep > 0 then
        Sleep(NeedSleep);
      if NeedSleep < 0 then
        CrossThreadSwitch;
    except
      //on E: Exception do begin
      //  {$IFDEF FDEBUG}
      //  DebugLn('TScanThread.Execute::' + e.Message);
      //  DumpStack;
      //  {$ENDIF}
      //  erro := E;
      //  Synchronize(@SyncException);
      //end;
    end;
  end;

  if FMinScan > 0 then
    Sleep(FMinScan);
end;

procedure TScanThread.CheckScanWriteCmd;
var
  PMsg: TMSMsg;
  Pkg: PScanReqRec;
begin
  while (not Terminated) and FSpool.PeekMessage(PMsg, PSM_TAGSCANWRITE, PSM_SINGLESCANREAD, True) do
  begin
    case PMsg.MsgID of
      PSM_SINGLESCANREAD: begin
                            if Assigned(FDoSingleScanRead) then
                              begin
                                //TODO -oFabio: Why we should wait 1ms?
                                FWaitToWrite.WaitFor(1);
                                FWaitToWrite.ResetEvent;

                                Pkg := PScanReqRec(PMsg.wParam);

                                Pkg^.RequestResult := FDoSingleScanRead(Pkg^.Tag, Pkg^.Values);

                                if PScanUpdater <> nil then
                                  PScanUpdater.ScanRequestCallBack(Pkg, False);
                              end
                            else
                              Dispose(PScanReqRec(PMsg.wParam));
                          end;
      PSM_TAGSCANWRITE: begin
                          if Assigned(FDoScanWrite) then
                            begin
                              FWaitToWrite.WaitFor(1); //TODO -oFabio: Why we should wait 1ms?
                              FWaitToWrite.ResetEvent;

                              Pkg := PScanReqRec(PMsg.wParam);

                              Pkg^.RequestResult := FDoScanWrite(Pkg^.Tag, Pkg^.Values);

                              if PScanUpdater <> nil then
                                PScanUpdater.ScanRequestCallBack(Pkg);
                            end
                          else
                            Dispose(PScanReqRec(PMsg.wParam));
                        end;
    end;
  end;
end;

procedure TScanThread.SyncException;
begin
  //try
  //  Application.ShowException(erro);
  //except
  //end;
end;

procedure TScanThread.ScanWrite(SWPkg: PScanReqRec);
begin
  WaitLoopStarts;

  // sends the message
  FSpool.PostMessage(PSM_TAGSCANWRITE, SWPkg, nil, True);
  FWaitToWrite.SetEvent;
end;

procedure TScanThread.SingleScanRead(SRPkg: PScanReqRec);
begin
  WaitLoopStarts;

  // sends the message
  FSpool.PostMessage(PSM_SINGLESCANREAD, SRPkg, nil, True);
  FWaitToWrite.SetEvent;
end;

procedure TScanThread.Terminate;
begin
  inherited Terminate;
  repeat
    CheckSynchronize(1);
  until WaitEnd(1) = wrSignaled;
end;

end.

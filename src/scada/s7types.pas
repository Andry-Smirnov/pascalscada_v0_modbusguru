{$i ../common/language.inc}
{:
  @abstract(Common types used by Siemens PLC's.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
unit S7Types;

interface

uses
  PLCMemoryManager;

type
  {:
  Represents the PDU header.

  @member P             Allways 0x32
  @member PDUHeadertype Header type, one of 1,2,3 or 7. type 2 and 3 headers are two bytes longer.
  @member a             Currently unknown. Maybe it can be used for long numbers?
  @member b             Currently unknown. Maybe it can be used for long numbers?
  @member number        A number. This can be used to make sure a received answer corresponds to the request with the same number.
  @member param_len     Length of parameters which follow this header.
  @member data_len      Length of data which follow the parameters.
  @member Error         Only present in type 2 and 3 headers. This contains error information.
  }
  TPDUHeader = record
    P: Byte;
    PDUHeadertype: Byte;
    A: Byte;
    B: Byte;
    Number: Word;
    ParamLen: Word;
    DataLen: Word;
    Error: Word;
  end;

  //: Points to a PDU structure header.
  PPDUHeader = ^TPDUHeader;

  {: PDU structure.
  @member header        Point to start of PDU (PDU header)
  @member param         Point to start of parameters inside PDU
  @member data          Point to start of data inside PDU
  @member udata         Point to start of data inside PDU
  @member header_len    Header length
  @member param_len     Parameter length
  @member data_len      Data length
  @member user_data_len User or result data length }
  TPDU = record
    Header: Pbyte;
    Param: Pbyte;
    Data: Pbyte;
    uData: Pbyte;
    HeaderLen: Longint;
    ParamLen: Longint;
    DataLen: Longint;
    UserDataLen: Longint;
  end;
  PPDU = ^TPDU;

  {: Identifies a DB of S7-1200/S7-300/S7-400 PLC's.
  @member DBNum DB Number.
  @member DBArea Manager of non-continuous memory blocks. }
  TS7DB = record
    DBNum: Cardinal;
    DBArea: TPLCMemoryManager;
  end;

  //: Identifies a set of DB's of S7-1200/S7-300/S7-400 PLC's.
  TS7DBs = array of TS7DB;

  {: Represents one request on a set of read requests.
  @member PLC          Index of PLC on PLC's list.
  @member DB           DB Number.
  @member ReqType      Request type
  @member StartAddress Start address.
  @member Size         Request length. }
  TS7ReqListItem = record
    PLCIdx: Longint;
    DBIdx: Longint;
    ReqType: Longint;
    StartAddress: Longint;
    Size: Longint;
  end;

  //: A request list.
  TS7ReqList = array of TS7ReqListItem;

  {: Represents a Siemens S7-200/300/400/1200 PLC.
  @member Station      PLC address.
  @member Rack         PLC Rack.
  @member Slot         PLC Slot.
  @member PDUId        PDU identification.
  @member MaxPDULen    Maximum PDU size.
  @member MaxBlockSize Maximum block size.
  @member Connected    Tells if the connect process already done.

  @member Inputs           Manager of non-continuous memory blocks of digital inputs.
  @member Outputs          Manager of non-continuous memory blocks of digital outputs.
  @member PeripheralInputs Manager of non-continuous memory blocks of analog inputs of S7-300/400.
  @member DBs              Lista de DB's em uso.
  @member Timers           Manager of non-continuous memory blocks of Timers of S7-300/400.
  @member Counters         Manager of non-continuous memory blocks of Counters of S7-300/400.
  @member Flags            Manager of non-continuous memory blocks of Flags (M's).

  @member S7200SMs         Manager of non-continuous memory blocks of SM's of S7-200.
  @member S7200Timers      Manager of non-continuous memory blocks Timers of S7-200.
  @member S7200Counters    Manager of non-continuous memory blocks of Counters of S7-200.
  @member S7200AnInput     Manager of non-continuous memory blocks of analog inputs of S7-200.
  @member S7200AnOutput    Manager of non-continuous memory blocks of analog outputs of S7-200. }
  TS7CPU = record
    Station: Longint;
    Rack: Longint;
    Slot: Longint;
    PDUId: Word;
    MaxPDULen: Word;
    MaxBlockSize: Longint;
    Connected: Boolean;

    Inputs: TPLCMemoryManager;
    Outputs: TPLCMemoryManager;
    PeripheralInputs: TPLCMemoryManager;
    DBs: TS7DBs;
    Timers: TPLCMemoryManager;
    Counters: TPLCMemoryManager;
    Flags: TPLCMemoryManager;

    S7200SMs: TPLCMemoryManager;
    S7200Timers: TPLCMemoryManager;
    S7200Counters: TPLCMemoryManager;
    S7200AnInput: TPLCMemoryManager;
    S7200AnOutput: TPLCMemoryManager;
  end;

  //: Points to a PLC.
  PS7CPU = ^TS7CPU;

  //: Represents a set of Siemens S7-200/300/400 PLC's.
  TS7CPUs = array of TS7CPU;

  {: Struture that identifies a request of read/write of PLC memories.
  @member header       Request header. Always is the sequence 0x12, 0x0a, 0x10.
  @member WordLen      Word length (1=single bit, 2=byte, 4=word)
  @member ReqLength    Request length.
  @member DBNumber     DB Number.
  @member AreaCode     Requested area code.
  @member HiBytes      Start address high byte.
  @member StartAddress Start address lower word.

  @seealso(vtS7_200_SysInfo)
  @seealso(vtS7_200_SM)
  @seealso(vtS7_200_AnInput)
  @seealso(vtS7_200_AnOutput)
  @seealso(vtS7_200_Counter)
  @seealso(vtS7_200_Timer)
  @seealso(vtS7_Peripheral)
  @seealso(vtS7_Inputs)
  @seealso(vtS7_Outputs)
  @seealso(vtS7_Flags)
  @seealso(vtS7_DB)
  @seealso(vtS7_DI)
  @seealso(vtS7_Local)
  @seealso(vtS7_V)
  @seealso(vtS7_Counter)
  @seealso(vtS7_Timer) }
  TS7Req = record
    header: array [0..2] of Byte;
    WordLen: Byte;
    ReqLength: Word;
    DBNumber: Word;
    AreaCode: Byte;
    HiBytes: Byte;
    StartAddress: Word; //bits and low bytes
  end;

  PS7Req = ^TS7Req;

  //: Identifies the connection way with PLC.
  TISOTCPConnectionWay = (ISOTCP, ISOTCP_VIA_CP243);

  //: PLC connection type
  TISOTCPConnType = (ctPG, ctOP, ctBasic);

const
  //: Identifies a S7-200 information area.
  vtS7_200_SysInfo = $03;
  //: Identifies the S7-200 SM's
  vtS7_200_SM = $05;
  //: Identifies the analog inputs of S7-200.
  vtS7_200_AnInput = $06;
  //: Identifies the analog outpus of S7-200.
  vtS7_200_AnOutput = $07;
  //: Identifies the counters of S7-200.
  vtS7_200_Counter = 30;
  //: Identifies the Timers of S7-200.
  vtS7_200_Timer = 31;
  //: Identifies the analog inputs of S7-300/400.
  vtS7_Peripheral = $80;
  //: Identifies the digital inputs.
  vtS7_Inputs = $81;
  //: Identifies the digital outputs.
  vtS7_Outputs = $82;
  //: Identifies the Flags (M's).
  vtS7_Flags = $83;
  //: Identifies the DB's and V's area of S7-200.
  vtS7_DB = $84;
  //: Identifies the instantiated DB's.
  vtS7_DI = $85;  //DB Instanciado
  //: Unknown.
  vtS7_Local = $86;  //not tested
  //: Unknown.
  vtS7_V = $87;
  //: Identifies the Counters of S7-300/400.
  vtS7_Counter = 28;  //S7 counters
  //: Identifies the Timers of S7-300/400.
  vtS7_Timer = 29;  // S7 timers

  //: Unknown/Not tested.
  S7FuncOpenS7Connection = $F0;
  //: Identifies a read request.
  S7FuncRead = $04;
  //: Identifies a write request.
  S7FuncWrite = $05;
  //: Unknown/Not tested.
  S7FuncRequestDownload = $1A;
  //: Unknown/Not tested.
  S7FuncDownloadBlock = $1B;
  //: Unknown/Not tested.
  S7FuncDownloadEnded = $1C;
  //: Unknown/Not tested.
  S7FuncStartUpload = $1D;
  //: Unknown/Not tested.
  S7FuncUpload = $1E;
  //: Unknown/Not tested.
  S7FuncEndUpload = $1F;
  //: Unknown/Not tested.
  S7FuncInsertBlock = $28;

implementation

end.

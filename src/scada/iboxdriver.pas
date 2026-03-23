{$i ../common/language.inc}
{:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  @abstract(Driver de protocolo Ibox, usado para comunicar com unidades
  de refrigeração da Thermo-King.)
}
unit IBoxDriver;

interface

uses
  Classes, SysUtils, ProtocolDriver, commtypes, Tag, ProtocolTypes;

type
  {:
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)

    Identifica um registrador simples do Ibox.
    @member RefCount Conta quantas vezes o registro foi referenciado.
    @member MinScanTime Guarda o menor tempo de Scan dos tags que estão refeenciando o registro.
    @member Value Guarda o último valor lido do registro.
    @member TimeStamp Quando foi a última vez que o registro foi lido.
    @member LastReadResult Qual foi o resultado da última tentativa de reading.
  }
  TIBoxRegister = record
    RefCount: Cardinal;
    MinScanTime: Cardinal;
    Value: Double;
    TimeStamp: TDateTime;
    LastReadResult: TProtocolIOResult;
  end;

  {:
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)

    Representa os registradores 200,201 e 202 do Ibox.
    @member RefCount Conta quantas vezes o registro foi referenciado.
    @member MinScanTime Guarda o menor tempo de Scan dos tags que estão refeenciando o registro.
    @member TimeStamp Quando foi a última vez que o registro foi lido.
    @member LastReadResult Qual foi o resultado da última tentativa de reading.

    @member ActiveZones Retornado apenas no PID 200. Informa se os pids 201 e 202 são validos.
    @member ActiveAlarme Retorna a severidade do alarme. 15 o mais severo e 1 para o menos severo.
    @member ManufacturerAlarmCode Retorna o código especifico de alarme (Alarme do fabricante).

    @member ReturnAir1Active Informa se o sensor da temperatura do Retorno do Ar 1 está instalado. 1=Instalado, 0=Não instalado.
    @member Supply1Active Informa se o sensor de entrada de Ar 1 está instalado. 1=Instalado, 0=Não instalado.
    @member SetPointActive Informa se o setpoint está presente. 1=Presente, 0=Ausente.
    @member EvaporatorCoilActive Informa se o sensor de temperatura da bobina do está instalado. 1=Instalado, 0=Não instalado.
    @member ReturnAir2Active Informa se o sensor de temperatura do Retorno de Ar 2 está instalado. 1=Instalado, 0=Não instalado.
    @member Supply2Active Informa se o sensor de entrada de Ar 2 está instalado. 1=Instalado, 0=Não instalado.
    @member OperatingModeActive Informa se o modo de operação está disponível. 1=Disponível, 0=Indisponível.

    @member ReturnAir1 Temperatura do Retorno de Ar 1, caso o sensor esteja instalado.
    @member Supply1 Temperatura da Entrada de Ar 1, caso o sensor esteja instalado.
    @member SetPoint Valor desejado de temperatura na camara fria.
    @member EvaporatorCoil Temperatura da bobina do evaporador, caso o sensor esteja instalado.
    @member ReturnAir2 Temperatura do Retorno de Ar 2, caso o sensor esteja instalado.
    @member Supply2 Temperatura da Entrada de Ar 2, caso o sensor esteja instalado.
    @member OperatingMode Modo de operação da unidade, caso essa informação esteja disponível.
  }
  TPID20xRegister = record
    RefCount: Cardinal;
    TimeStamp: TDateTime;
    LastReadResult: TProtocolIOResult;
    MinScanTime: Cardinal;

    ActiveZones: Byte;
    ActiveAlarme: Byte;
    ManufacturerAlarmCode: Byte;

    // 1 if the variable has a valid value, 0 for invalid values
    ReturnAir1Active: Byte;
    Supply1Active: Byte;
    SetPointActive: Byte;
    EvaporatorCoilActive: Byte;
    ReturnAir2Active: Byte;
    Supply2Active: Byte;
    OperatingModeActive: Byte;

    ReturnAir1: Double;
    Supply1: Double;
    SetPoint: Double;
    EvaporatorCoil: Double;
    ReturnAir2: Double;
    Supply2: Double;
    OperatingMode: Double;
  end;

  {:
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)

    Estrutura que representa o registrador 203 do Ibox.
    @member RefCount Conta quantas vezes o registro foi referenciado.
    @member MinScanTime Guarda o menor tempo de Scan dos tags que estão referenciando o registro.
    @member TimeStamp Quando foi a última vez que o registro foi lido.
    @member LastReadResult Qual foi o resultado da última tentativa de reading.

    @member DigitalInput0State Informa se a entrada Digital 0 está presente no Ibox.
    @member DigitalInput1State Informa se a entrada Digital 1 está presente no Ibox.
    @member DigitalInput2State Informa se a entrada Digital 2 está presente no Ibox.
    @member DigitalInput3State Informa se a entrada Digital 3 está presente no Ibox.
    @member DigitalInput0Value Caso a entrada digital 0 esteja presente no ibox, informa seu estado atual (0 desligado, 1 ligado).
    @member DigitalInput1Value Caso a entrada digital 1 esteja presente no ibox, informa seu estado atual (0 desligado, 1 ligado).
    @member DigitalInput2Value Caso a entrada digital 2 esteja presente no ibox, informa seu estado atual (0 desligado, 1 ligado).
    @member DigitalInput3Value Caso a entrada digital 3 esteja presente no ibox, informa seu estado atual (0 desligado, 1 ligado).
    @member Reserved Valor reservado.
    @member Sensor1Active Informa se o sensor 1 esta instalado no Ibox.
    @member Sensor2Active Informa se o sensor 2 esta instalado no Ibox.
    @member Sensor3Active Informa se o sensor 3 esta instalado no Ibox.
    @member Sensor4Active Informa se o sensor 4 esta instalado no Ibox.
    @member Sensor5Active Informa se o sensor 5 esta instalado no Ibox.
    @member Sensor6Active Informa se o sensor 6 esta instalado no Ibox.
    @member HumidityActive Informa se o sensor de umidade esta instalado no Ibox.
    @member Sensor1Value Caso o sensor 1 esteja instalado, informa o valor que foi lido.
    @member Sensor2Value Caso o sensor 2 esteja instalado, informa o valor que foi lido.
    @member Sensor3Value Caso o sensor 3 esteja instalado, informa o valor que foi lido.
    @member Sensor4Value Caso o sensor 4 esteja instalado, informa o valor que foi lido.
    @member Sensor5Value Caso o sensor 5 esteja instalado, informa o valor que foi lido.
    @member Sensor6Value Caso o sensor 6 esteja instalado, informa o valor que foi lido.
    @member HumidityValue Caso o sensor de umidade esteja instalado, informa o valor que foi lido. }
  TPID203Register = record
    RefCount: Cardinal;
    TimeStamp: TDateTime;
    LastReadResult: TProtocolIOResult;
    MinScanTime: Cardinal;

    DigitalInput0State: Byte;
    DigitalInput1State: Byte;
    DigitalInput2State: Byte;
    DigitalInput3State: Byte;
    DigitalInput0Value: Byte;
    DigitalInput1Value: Byte;
    DigitalInput2Value: Byte;
    DigitalInput3Value: Byte;
    Reserved: Byte;
    Sensor1Active: Byte;
    Sensor2Active: Byte;
    Sensor3Active: Byte;
    Sensor4Active: Byte;
    Sensor5Active: Byte;
    Sensor6Active: Byte;
    HumidityActive: Byte;
    Sensor1Value: Double;
    Sensor2Value: Double;
    Sensor3Value: Double;
    Sensor4Value: Double;
    Sensor5Value: Double;
    Sensor6Value: Double;
    HumidityValue: Double;
  end;

  {:
   @author(Fabio Luis Girardi <fabio@pascalscada.com>)

   Identifica uma estação Ibox da ThermoKing.
   @member PID0 Registrador PID0 do ibox.
   @member PID96 Nível de combustível (em %).
   @member PID168 Diferença de potencial da bateria do ThermoKing (em volts).
   @member PID200 Pid 200. Ver TPID20xRegister.
   @member PID201 Pid 201. Ver TPID20xRegister.
   @member PID202 Pid 202. Ver TPID20xRegister.
   @member PID203 Pid 203. Ver TPID203Register.
   @member PID204 Estado do Thermo King
   @member PID205 Reseta o circuito de Keep Alive no i-Box.
   @member PID247 Total de horas trabalhadas pelo ThermoKing.
   @seealso() }
  TIBoxStation = record
    Address: Byte;
    PID0: TIBoxRegister;
    PID96: TIBoxRegister;
    PID168: TIBoxRegister;
    PID200: TPID20xRegister;
    PID201: TPID20xRegister;
    PID202: TPID20xRegister;
    PID203: TPID203Register;
    PID204: TIBoxRegister;
    PID205: TIBoxRegister;
    PID247: TIBoxRegister;
  end;

  {:
   @author(Fabio Luis Girardi <fabio@pascalscada.com>)
   Conjunto de estações i-Box. }
  TIBoxStations = array of TIBoxStation;

  {:
   @author(Fabio Luis Girardi <fabio@pascalscada.com>)

   @abstract(Communication driver for i-Box devices.)

   It only supports tags of the TPLCTagNumber class..

   To address a tag, fill in the following tag properties:

   @bold(PLCStation:) i-Box address. Accepts values between 0 and 255.
   @bold(MemAddress:) Register (PID) to be read. Accepts the following values:
                      0, 96, 168, 200, 201, 202, 203, 204, 205 and 247.

   @bold(MemSubElement:) Index of the item within the structure if its register
                         is 200, 201, 202, or 203. It starts at zero and varies
                         according to the chosen PID. }
  TIBoxDriver = class(TProtocolDriver)
  private
    PStations: TIBoxStations;
    // Checks if a byte string has a checksum of OK
    function CheckSumOk(const Pkg: Bytes): Boolean;
    // Calculate the checksum up to position 1..n-1 and place the calculation at position n
    procedure CalculateCheckSum(var Pkg: Bytes);
  protected
    //: @seealso(TProtocolDriver.DoAddTag)
    procedure DoAddTag(TagObj: TTag; TagValid: Boolean); override;
    //: @seealso(TProtocolDriver.DoDelTag)
    procedure DoDelTag(TagObj: TTag); override;
    //: @seealso(TProtocolDriver.DoScanRead)
    procedure DoScanRead(Sender: TObject; var NeedSleep: Longint); override;
    //: @seealso(TProtocolDriver.DoGetValue)
    procedure DoGetValue(TagRec: TTagRec; var Values: TScanReadRec); override;
    //: @seealso(TProtocolDriver.DoWrite)
    function DoWrite(const TagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
    //: @seealso(TProtocolDriver.DoRead)
    function DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult; override;
  public
    //constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
  published
  end;


implementation


uses
  PLCTagNumber, dateutils, Math, hsstrings, crossdatetime;


destructor TIBoxDriver.Destroy;
begin
  inherited Destroy;
  SetLength(PStations, 0);
end;

function TIBoxDriver.CheckSumOk(const Pkg: Bytes): Boolean;
var
  i: Longint;
  h: Longint;
  Sum: Cardinal;
begin
  //try
  Result := False;
  if Length(Pkg) < 2 then Exit;
  Sum := 0;
  h := High(Pkg);
  for i := 0 to h - 1 do
    Sum := Sum + Pkg[i];
  Sum := (Sum xor $FFFFFFFF) + 1;
  Result := (Pkg[h] = (Sum and $FF));
  //except
  //  Result := false;
  //end;
end;

procedure TIBoxDriver.CalculateCheckSum(var Pkg: Bytes);
var
  i: Longint;
  h: Longint;
  Sum: Cardinal;
begin
  if Length(Pkg) < 2 then Exit;
  Sum := 0;
  h := High(Pkg);
  for i := 0 to h - 1 do
    Sum := Sum + Pkg[i];
  Sum := (Sum xor $FFFFFFFF) + 1;
  Pkg[h] := (Sum and $FF);
end;

procedure TIBoxDriver.DoAddTag(TagObj: TTag; TagValid: Boolean);
var
  PLC: Longint;
  h: Longint;
  Found: Boolean;
  AValue: Boolean;
begin
  if not (TagObj is TPLCTagNumber) then
    raise Exception.Create(SinvalidTag);

  AValue := False;

  with TPLCTagNumber(TagObj) do
  begin
    if not (PLCStation in [0..255]) then
      Exit;
    if not (MemAddress in [0, 96, 168, 200..205, 247]) then
      Exit;

    AValue := True;

    h := High(PStations);
    Found := False;
    for PLC := 0 to h do
      if PStations[PLC].Address = PLCStation then
      begin
        Found := True;
        Break;
      end;

    if not Found then
    begin
      PLC := Length(PStations);
      SetLength(PStations, PLC + 1);
      PStations[PLC].Address := PLCStation;
    end;

    case MemAddress of
      0:  begin
            if not Found then
            begin
              PStations[PLC].PID0.RefCount := 0;
              PStations[PLC].PID0.MinScanTime := RefreshTime;
            end;

            Inc(PStations[PLC].PID0.RefCount);
            PStations[PLC].PID0.MinScanTime := Min(PStations[PLC].PID0.MinScanTime, RefreshTime);
          end;
      96: begin
            if not Found then
            begin
              PStations[PLC].PID96.RefCount := 0;
              PStations[PLC].PID96.MinScanTime := RefreshTime;
            end;

            Inc(PStations[PLC].PID96.RefCount);
            PStations[PLC].PID96.MinScanTime := Min(PStations[PLC].PID96.MinScanTime, RefreshTime);
          end;
      168:  begin
              if not Found then
              begin
                PStations[PLC].PID168.RefCount := 0;
                PStations[PLC].PID168.MinScanTime := RefreshTime;
              end;

              Inc(PStations[PLC].PID168.RefCount);
              PStations[PLC].PID168.MinScanTime := Min(PStations[PLC].PID168.MinScanTime, RefreshTime);
            end;
      200:  begin
              if not Found then
              begin
                PStations[PLC].PID202.RefCount := 0;
                PStations[PLC].PID202.MinScanTime := RefreshTime;
              end;

              Inc(PStations[PLC].PID200.RefCount);
              PStations[PLC].PID200.MinScanTime := Min(PStations[PLC].PID200.MinScanTime, RefreshTime);
            end;
      201:  begin
              if not Found then
              begin
                PStations[PLC].PID201.RefCount := 0;
                PStations[PLC].PID201.MinScanTime := RefreshTime;
              end;

              Inc(PStations[PLC].PID201.RefCount);
              PStations[PLC].PID201.MinScanTime := Min(PStations[PLC].PID201.MinScanTime, RefreshTime);
            end;
      202:  begin
              if not Found then
              begin
                PStations[PLC].PID202.RefCount := 0;
                PStations[PLC].PID202.MinScanTime := RefreshTime;
              end;

              Inc(PStations[PLC].PID202.RefCount);
              PStations[PLC].PID202.MinScanTime := Min(PStations[PLC].PID202.MinScanTime, RefreshTime);
            end;
      203:  begin
              if not Found then
              begin
                PStations[PLC].PID203.RefCount := 0;
                PStations[PLC].PID203.MinScanTime := RefreshTime;
              end;

              Inc(PStations[PLC].PID203.RefCount);
              PStations[PLC].PID203.MinScanTime := Min(PStations[PLC].PID203.MinScanTime, RefreshTime);
            end;
      204:  begin
              if not Found then
              begin
                PStations[PLC].PID204.RefCount := 0;
                PStations[PLC].PID204.MinScanTime := RefreshTime;
              end;

              Inc(PStations[PLC].PID204.RefCount);
              PStations[PLC].PID204.MinScanTime := Min(PStations[PLC].PID204.MinScanTime, RefreshTime);
            end;
      205:  begin
              if not Found then
              begin
                PStations[PLC].PID205.RefCount := 0;
                PStations[PLC].PID205.MinScanTime := RefreshTime;
              end;

              Inc(PStations[PLC].PID205.RefCount);
              PStations[PLC].PID205.MinScanTime := Min(PStations[PLC].PID205.MinScanTime, RefreshTime);
            end;
      247:  begin
              if not Found then
              begin
                PStations[PLC].PID247.RefCount := 0;
                PStations[PLC].PID247.MinScanTime := RefreshTime;
              end;

              Inc(PStations[PLC].PID247.RefCount);
              PStations[PLC].PID247.MinScanTime := Min(PStations[PLC].PID247.MinScanTime, RefreshTime);
            end;
    end;
  end;

  inherited DoAddTag(TagObj, AValue);
end;

procedure TIBoxDriver.DoDelTag(TagObj: TTag);
var
  RefCount: Cardinal;
  PLC: Longint;
  h: Longint;
  Found: Boolean;
begin
  if not (TagObj is TPLCTagNumber) then
    raise Exception.Create(SinvalidTag);

  with TagObj as TPLCTagNumber do
  begin
    if not (PLCStation in [0..255]) then
      Exit;
    if not (MemAddress in [0, 96, 168, 200..205, 247]) then
      Exit;

    h := High(PStations);
    for PLC := 0 to h do
      if PStations[PLC].Address = PLCStation then
      begin
        Found := True;
        Break;
      end;

    if not Found then Exit;

    case MemAddress of
      0:   Dec(PStations[PLC].PID0.RefCount);
      96:  Dec(PStations[PLC].PID96.RefCount);
      168: Dec(PStations[PLC].PID168.RefCount);
      200: Dec(PStations[PLC].PID200.RefCount);
      201: Dec(PStations[PLC].PID201.RefCount);
      202: Dec(PStations[PLC].PID202.RefCount);
      203: Dec(PStations[PLC].PID203.RefCount);
      204: Dec(PStations[PLC].PID204.RefCount);
      205: Dec(PStations[PLC].PID205.RefCount);
      247: Dec(PStations[PLC].PID247.RefCount);
    end;
    RefCount := PStations[PLC].PID0.RefCount + PStations[PLC].PID96.RefCount +
      PStations[PLC].PID168.RefCount + PStations[PLC].PID200.RefCount +
      PStations[PLC].PID201.RefCount + PStations[PLC].PID202.RefCount +
      PStations[PLC].PID203.RefCount + PStations[PLC].PID204.RefCount +
      PStations[PLC].PID205.RefCount + PStations[PLC].PID247.RefCount;
    //se este mid nao tem mais ninguem o requisitando
    //remove ele da fila de scan.
    if RefCount = 0 then
    begin
      h := High(PStations);
      PStations[PLC] := PStations[h];
      SetLength(PStations, h);
    end;
  end;
  inherited DoDelTag(TagObj);
end;

procedure TIBoxDriver.DoScanRead(Sender: TObject; var NeedSleep: Longint);
var
  PLC: Longint;
  DoSomething: Boolean;
  TagObj: TTagRec;
  DummyValue: TArrayOfDouble;
begin
  DoSomething := False;
  NeedSleep := 0;
  for PLC := 0 to High(PStations) do
  begin
    // initializes part of the request structure
    TagObj.Station := PStations[PLC].Address;
    TagObj.SubElement := 0;

    with PStations[PLC].PID96 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        TagObj.Address := 96;
        DoSomething := True;
        DoRead(TagObj, DummyValue, False);
      end;

    with PStations[PLC].PID168 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        TagObj.Address := 168;
        DoSomething := True;
        DoRead(TagObj, DummyValue, False);
      end;

    with PStations[PLC].PID200 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        TagObj.Address := 200;
        DoSomething := True;
        DoRead(TagObj, DummyValue, False);
      end;
    with PStations[PLC].PID201 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        TagObj.Address := 201;
        DoSomething := True;
        DoRead(TagObj, DummyValue, False);
      end;
    with PStations[PLC].PID202 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        TagObj.Address := 202;
        DoSomething := True;
        DoRead(TagObj, DummyValue, False);
      end;

    with PStations[PLC].PID203 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        TagObj.Address := 203;
        DoSomething := True;
        DoRead(TagObj, DummyValue, False);
      end;

    with PStations[PLC].PID204 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        TagObj.Address := 204;
        DoSomething := True;
        DoRead(TagObj, DummyValue, False);
      end;
    /////////////////////////////////////////////
    // pid 205 is a command, leave it out of the scam
    /////////////////////////////////////////////
    with PStations[PLC].PID247 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        TagObj.Address := 247;
        DoSomething := True;
        DoRead(TagObj, DummyValue, False);
      end;
    if not DoSomething then
      NeedSleep := -1;
  end;

  // If it's not going to do anything, switch threads to improve performance
  if not DoSomething then
    NeedSleep := -1;
end;

procedure TIBoxDriver.DoGetValue(TagRec: TTagRec; var Values: TScanReadRec);
var
  PLC: Longint;
  Found: Boolean;
  PID20x: TPID20xRegister;
begin
  if not (TagRec.Station in [0..255]) then
  begin
    Values.LastQueryResult := ioIllegalStationAddress;
    Values.ValuesTimestamp := CrossNow;
    Exit;
  end;

  if not (TagRec.Address in [0, 96, 168, 200..205, 247]) then
  begin
    Values.LastQueryResult := ioIllegalRegAddress;
    Values.ValuesTimestamp := CrossNow;
    Exit;
  end;

  if (TagRec.Address in [200..202]) and (not (TagRec.SubElement in [0..16])) then
  begin
    Values.LastQueryResult := ioIllegalRegAddress;
    Values.ValuesTimestamp := CrossNow;
    Exit;
  end;

  Found := False;
  for PLC := 0 to High(PStations) do
    if PStations[PLC].Address = TagRec.Station then
    begin
      Found := True;
      Break;
    end;

  if not Found then
  begin
    Values.LastQueryResult := ioDriverError;
    Values.ValuesTimestamp := CrossNow;
    Exit;
  end;

  SetLength(Values.Values, 1);
  case TagRec.Address of
    96:   begin
            Values.Values[0] := PStations[PLC].PID96.Value;
            Values.ValuesTimestamp := PStations[PLC].PID96.TimeStamp;
            Values.LastQueryResult := PStations[PLC].PID96.LastReadResult;
          end;
    168:  begin
            Values.Values[0] := PStations[PLC].PID168.Value;
            Values.ValuesTimestamp := PStations[PLC].PID168.TimeStamp;
            Values.LastQueryResult := PStations[PLC].PID168.LastReadResult;
          end;
    200..202: begin
                if TagRec.Address = 200 then
                  PID20x := PStations[PLC].PID200;
                if TagRec.Address = 201 then
                  PID20x := PStations[PLC].PID201;
                if TagRec.Address = 202 then
                  PID20x := PStations[PLC].PID202;

                Values.ValuesTimestamp := PID20x.TimeStamp;
                Values.LastQueryResult := PID20x.LastReadResult;

                with PID20x do
                begin
                  case TagRec.SubElement of
                    0:  Values.Values[0] := ActiveZones;
                    1:  Values.Values[0] := ActiveAlarme;
                    2:  Values.Values[0] := ManufacturerAlarmCode;
                    3:  Values.Values[0] := ReturnAir1Active;
                    4:  Values.Values[0] := Supply1Active;
                    5:  Values.Values[0] := SetPointActive;
                    6:  Values.Values[0] := EvaporatorCoilActive;
                    7:  Values.Values[0] := ReturnAir2Active;
                    8:  Values.Values[0] := Supply2Active;
                    9:  Values.Values[0] := OperatingModeActive;
                    10: Values.Values[0] := ReturnAir1;
                    11: Values.Values[0] := Supply1;
                    12: Values.Values[0] := SetPoint;
                    13: Values.Values[0] := EvaporatorCoil;
                    14: Values.Values[0] := ReturnAir2;
                    15: Values.Values[0] := Supply2;
                    16: Values.Values[0] := OperatingMode;
                    else
                      begin
                        Values.ValuesTimestamp := CrossNow;
                        Values.LastQueryResult := ioIllegalRegAddress;
                      end;
                  end;
                end;
              end;
    203:  begin
          end;
    204:  begin
            Values.Values[0] := PStations[PLC].PID204.Value;
            Values.ValuesTimestamp := PStations[PLC].PID204.TimeStamp;
            Values.LastQueryResult := PStations[PLC].PID204.LastReadResult;
          end;
    205:  begin
            Values.Values[0] := PStations[PLC].PID205.Value;
            Values.ValuesTimestamp := PStations[PLC].PID205.TimeStamp;
            Values.LastQueryResult := PStations[PLC].PID205.LastReadResult;
          end;
    247:  begin
            Values.Values[0] := PStations[PLC].PID247.Value;
            Values.ValuesTimestamp := PStations[PLC].PID247.TimeStamp;
            Values.LastQueryResult := PStations[PLC].PID247.LastReadResult;
          end;
  end;
end;

function TIBoxDriver.DoWrite(const TagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
begin
  // There is no value writing in this driver
  Result := ioIllegalFunction;
end;

function TIBoxDriver.DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  Pkg: Bytes;
  PkgTotal: Bytes;
  CmdPkg: TIOPacket;
  PLC: Longint;
  Offset: Longint;
  BytesRemaim: Longint;
  b2: Longint;
  b3: Longint;
  b4: Longint;
  b5: Longint;
  b6: Longint;
  b7: Longint;
  b8: Longint;
  Found: Boolean;
  PID20x: TPID20xRegister;
begin
  if not (TagRec.Station in [0..255]) then
  begin
    Result := ioIllegalStationAddress;
    Exit;
  end;

  if not (TagRec.Address in [0, 96, 168, 200..205, 247]) then
  begin
    Result := ioIllegalRegAddress;
    Exit;
  end;

  if (TagRec.Address in [200..202]) and (not (TagRec.SubElement in [0..16])) then
  begin
    Result := ioIllegalRegAddress;
    Exit;
  end;

  Found := False;
  for PLC := 0 to High(PStations) do
    if PStations[PLC].Address = TagRec.Station then
    begin
      Found := True;
      Break;
    end;

  SetLength(Values, 1);
  try
    if PCommPort = nil then
    begin
      Result := ioNullDriver;
      Exit;
    end;

    SetLength(Pkg, 4);
    Pkg[0] := Byte(TagRec.Station);
    Pkg[1] := 0;
    Pkg[2] := Byte(TagRec.Address);
    CalculateCheckSum(Pkg);

    case TagRec.Address of
      96: begin // Fuel level
            if PCommPort.IOCommandSync(iocWriteRead, 4, Pkg, 4, PDriverID, 5, @CmdPkg) = 0 then
            begin
              Result := ioDriverError;
              Exit;
            end;

            if not CheckSumOk(CmdPkg.BufferToRead) then
            begin
              Result := ioCommError;
              Exit;
            end;

            if (CmdPkg.BufferToRead[0] <> CmdPkg.BufferToWrite[0])
              or (CmdPkg.BufferToRead[0] <> TagRec.Station) then
            begin
              Result := ioCommError;
              Exit;
            end;

            if (CmdPkg.BufferToRead[1] <> CmdPkg.BufferToWrite[2])
              or (CmdPkg.BufferToRead[1] <> TagRec.Address) then
            begin
              Result := ioCommError;
              Exit;
            end;

            Values[0] := CmdPkg.BufferToRead[2] / 2;
            Result := ioOk;
            if Found then
            begin
              PStations[PLC].PID96.Value := Values[0];
              PStations[PLC].PID96.LastReadResult := Result;
              PStations[PLC].PID96.TimeStamp := CrossNow;
            end;
          end;
      168:  begin // Battery voltage
              if PCommPort.IOCommandSync(iocWriteRead, 4, Pkg, 5, PDriverID, 5, @CmdPkg) = 0 then
              begin
                Result := ioDriverError;
                Exit;
              end;

              if not CheckSumOk(CmdPkg.BufferToRead) then
              begin
                Result := ioCommError;
                Exit;
              end;

              if (CmdPkg.BufferToRead[0] <> CmdPkg.BufferToWrite[0])
                or (CmdPkg.BufferToRead[0] <> TagRec.Station) then
              begin
                Result := ioCommError;
                Exit;
              end;

              if (CmdPkg.BufferToRead[1] <> CmdPkg.BufferToWrite[2])
                or (CmdPkg.BufferToRead[1] <> TagRec.Address) then
              begin
                Result := ioCommError;
                Exit;
              end;

              Values[0] := (CmdPkg.BufferToRead[2] * 256 + CmdPkg.BufferToRead[3]) / 20;
              Result := ioOk;
              if Found then
              begin
                PStations[PLC].PID168.Value := Values[0];
                PStations[PLC].PID168.LastReadResult := Result;
                PStations[PLC].PID168.TimeStamp := CrossNow;
              end;
            end;
      200..202: begin
                  // Initializes the auxiliary package,
                  // so as not to lose the variable information at the end
                  if Found then
                  begin
                    if TagRec.Address = 200 then
                    begin
                      PID20x.RefCount := PStations[PLC].PID200.RefCount;
                      PID20x.MinScanTime := PStations[PLC].PID200.MinScanTime;
                    end;
                    if TagRec.Address = 201 then
                    begin
                      PID20x.RefCount := PStations[PLC].PID201.RefCount;
                      PID20x.MinScanTime := PStations[PLC].PID201.MinScanTime;
                    end;
                    if TagRec.Address = 202 then
                    begin
                      PID20x.RefCount := PStations[PLC].PID202.RefCount;
                      PID20x.MinScanTime := PStations[PLC].PID202.MinScanTime;
                    end;
                  end;

                  PCommPort.Lock(PDriverID);
                  if PCommPort.IOCommandSync(iocWriteRead, 4, Pkg, 5, PDriverID, 5, @CmdPkg) = 0 then
                  begin
                    Result := ioDriverError;
                    Exit;
                  end;

                  if (CmdPkg.BufferToRead[0] <> CmdPkg.BufferToWrite[0]) or
                    (CmdPkg.BufferToRead[0] <> TagRec.Station) then
                  begin
                    Result := ioCommError;
                    Exit;
                  end;

                  if (CmdPkg.BufferToRead[1] <> CmdPkg.BufferToWrite[2]) or
                    (CmdPkg.BufferToRead[1] <> TagRec.Address) then
                  begin
                    Result := ioCommError;
                    Exit;
                  end;

                  // If you've reached this point, the request appears to be okay,
                  // so start decoding the data
                  PID20x.ActiveZones := (CmdPkg.BufferToRead[2] and $F0) div $10;
                  PID20x.ActiveAlarme := (CmdPkg.BufferToRead[2] and $0F);
                  Offset := 0;
                  if PID20x.ActiveAlarme > 0 then
                  begin
                    PID20x.ManufacturerAlarmCode := CmdPkg.BufferToRead[3];
                    Offset := 1;
                  end
                  else
                    PID20x.ManufacturerAlarmCode := 0;

                  // This bit cannot be set... if it is set, it's a communication failure
                  if (CmdPkg.BufferToRead[3 + Offset] and 1) = 1 then
                  begin
                    Result := ioCommError;
                    Exit;
                  end;

                  // Offset also indicates whether it is necessary to read one more byte
                  BytesRemaim := Offset;
                  b2 := IfThen((CmdPkg.BufferToRead[3 + Offset] and $02) = $02, 1, 0);
                  b3 := IfThen((CmdPkg.BufferToRead[3 + Offset] and $04) = $04, 2, 0);
                  b4 := IfThen((CmdPkg.BufferToRead[3 + Offset] and $08) = $08, 2, 0);
                  b5 := IfThen((CmdPkg.BufferToRead[3 + Offset] and $10) = $10, 2, 0);
                  b6 := IfThen((CmdPkg.BufferToRead[3 + Offset] and $20) = $20, 2, 0);
                  b7 := IfThen((CmdPkg.BufferToRead[3 + Offset] and $40) = $40, 2, 0);
                  b8 := IfThen((CmdPkg.BufferToRead[3 + Offset] and $80) = $80, 2, 0);

                  Inc(BytesRemaim, b2);
                  Inc(BytesRemaim, b3);
                  Inc(BytesRemaim, b4);
                  Inc(BytesRemaim, b5);
                  Inc(BytesRemaim, b6);
                  Inc(BytesRemaim, b7);
                  Inc(BytesRemaim, b8);

                  PID20x.ReturnAir1Active := IfThen(b8 <> 0, 1, 0);
                  PID20x.Supply1Active := IfThen(b7 <> 0, 1, 0);
                  PID20x.SetPointActive := IfThen(b6 <> 0, 1, 0);
                  PID20x.EvaporatorCoilActive := IfThen(b5 <> 0, 1, 0);
                  PID20x.ReturnAir2Active := IfThen(b4 <> 0, 1, 0);
                  PID20x.Supply2Active := IfThen(b3 <> 0, 1, 0);
                  PID20x.OperatingModeActive := IfThen(b2 <> 0, 1, 0);

                  //se sobrou Bytes oara ler...
                  if BytesRemaim > 0 then
                  begin
                    //copia os primeiros Bytes do pacote
                    Pkg := CmdPkg.BufferToRead;

                    if PCommPort.IOCommandSync(iocRead, 0, nil, BytesRemaim, PDriverID, 5, @CmdPkg) = 0 then
                    begin
                      Result := ioDriverError;
                      Exit;
                    end;

                    PkgTotal := ConcatenateBYTES(Pkg, CmdPkg.BufferToRead);

                    if not CheckSumOk(PkgTotal) then
                    begin
                      Result := ioCommError;
                      Exit;
                    end;

                    //o trem comeca da pos 4 + Offset...
                    //incrementa o Offset pra nao mudar os indices.
                    //Offset trabalha como cursor.
                    if PID20x.ReturnAir1Active = 1 then
                    begin
                      PID20x.ReturnAir1 := ((PkgTotal[4 + Offset] * 256) + PkgTotal[5 + Offset]) / 10;
                      Inc(Offset, 2);
                    end;
                    if PID20x.Supply1Active = 1 then
                    begin
                      PID20x.Supply1 := ((PkgTotal[4 + Offset] * 256) + PkgTotal[5 + Offset]) / 10;
                      Inc(Offset, 2);
                    end;
                    if PID20x.SetPointActive = 1 then
                    begin
                      PID20x.SetPoint := ((PkgTotal[4 + Offset] * 256) + PkgTotal[5 + Offset]) / 10;
                      Inc(Offset, 2);
                    end;
                    if PID20x.EvaporatorCoilActive = 1 then
                    begin
                      PID20x.EvaporatorCoil := ((PkgTotal[4 + Offset] * 256) + PkgTotal[5 + Offset]) / 10;
                      Inc(Offset, 2);
                    end;
                    if PID20x.ReturnAir2Active = 1 then
                    begin
                      PID20x.ReturnAir2 := ((PkgTotal[4 + Offset] * 256) + PkgTotal[5 + Offset]) / 10;
                      Inc(Offset, 2);
                    end;
                    if PID20x.Supply2Active = 1 then
                    begin
                      PID20x.Supply2 := ((PkgTotal[4 + Offset] * 256) + PkgTotal[5 + Offset]) / 10;
                      Inc(Offset, 2);
                    end;
                    if PID20x.OperatingModeActive = 1 then
                    begin
                      PID20x.OperatingModeActive := PkgTotal[4 + Offset];
                      Inc(Offset, 2);
                    end;
                  end;

                  Result := ioOk;
                  PID20x.LastReadResult := Result;
                  PID20x.TimeStamp := CrossNow;

                  if Found then
                    case TagRec.Address of
                      200: PStations[PLC].PID200 := PID20x;
                      201: PStations[PLC].PID201 := PID20x;
                      202: PStations[PLC].PID202 := PID20x;
                    end;


                  with PID20x do
                  begin
                    case TagRec.SubElement of
                      0:  Values[0] := ActiveZones;
                      1:  Values[0] := ActiveAlarme;
                      2:  Values[0] := ManufacturerAlarmCode;
                      3:  Values[0] := ReturnAir1Active;
                      4:  Values[0] := Supply1Active;
                      5:  Values[0] := SetPointActive;
                      6:  Values[0] := EvaporatorCoilActive;
                      7:  Values[0] := ReturnAir2Active;
                      8:  Values[0] := Supply2Active;
                      9:  Values[0] := OperatingModeActive;
                      10: Values[0] := ReturnAir1;
                      11: Values[0] := Supply1;
                      12: Values[0] := SetPoint;
                      13: Values[0] := EvaporatorCoil;
                      14: Values[0] := ReturnAir2;
                      15: Values[0] := Supply2;
                      16: Values[0] := OperatingMode;
                      else
                      begin
                        Result := ioIllegalRegAddress;
                      end;
                    end;
                  end;
                end;
      204, 205: begin // engine status and reset
                  if PCommPort.IOCommandSync(iocWriteRead, 4, Pkg, 4, PDriverID, 5, @CmdPkg) = 0 then
                  begin
                    Result := ioDriverError;
                    Exit;
                  end;

                  if not CheckSumOk(CmdPkg.BufferToRead) then
                  begin
                    Result := ioCommError;
                    Exit;
                  end;

                  if (CmdPkg.BufferToRead[0] <> CmdPkg.BufferToWrite[0]) or
                    (CmdPkg.BufferToRead[0] <> TagRec.Station) then
                  begin
                    Result := ioCommError;
                    Exit;
                  end;

                  if (CmdPkg.BufferToRead[1] <> CmdPkg.BufferToWrite[2]) or
                    (CmdPkg.BufferToRead[1] <> TagRec.Address) then
                  begin
                    Result := ioCommError;
                    Exit;
                  end;

                  Values[0] := CmdPkg.BufferToRead[2];
                  Result := ioOk;

                  if Found then
                  begin
                    if TagRec.Address = 204 then
                    begin
                      PStations[PLC].PID204.Value := Values[0];
                      PStations[PLC].PID204.LastReadResult := Result;
                      PStations[PLC].PID204.TimeStamp := CrossNow;
                    end
                    else
                    begin
                      PStations[PLC].PID205.Value := Values[0];
                      PStations[PLC].PID205.LastReadResult := Result;
                      PStations[PLC].PID205.TimeStamp := CrossNow;
                    end;
                  end;
                end;
      247:  begin // Engine hour meter
              if PCommPort.IOCommandSync(iocWriteRead, 4, Pkg, 7, PDriverID, 5, @CmdPkg) = 0 then
              begin
                Result := ioDriverError;
                Exit;
              end;

              if not CheckSumOk(CmdPkg.BufferToRead) then
              begin
                Result := ioCommError;
                Exit;
              end;

              if (CmdPkg.BufferToRead[0] <> CmdPkg.BufferToWrite[0]) or
                (CmdPkg.BufferToRead[0] <> TagRec.Station) then
              begin
                Result := ioCommError;
                Exit;
              end;

              if (CmdPkg.BufferToRead[1] <> CmdPkg.BufferToWrite[2]) or
                (CmdPkg.BufferToRead[1] <> TagRec.Address) then
              begin
                Result := ioCommError;
                Exit;
              end;

              Values[0] := ((CmdPkg.BufferToRead[2] * 16777216) + (CmdPkg.BufferToRead[3] * 65536) + (CmdPkg.BufferToRead[4] * 256) + CmdPkg.BufferToRead[5]) / 20;
              Result := ioOk;
              if Found then
              begin
                PStations[PLC].PID247.Value := Values[0];
                PStations[PLC].PID247.LastReadResult := Result;
                PStations[PLC].PID247.TimeStamp := CrossNow;
              end;
            end;
    end;
  finally
    SetLength(PkgTotal, 0);
    SetLength(Pkg, 0);
    SetLength(CmdPkg.BufferToRead, 0);
    SetLength(CmdPkg.BufferToWrite, 0);
  end;
end;

end.

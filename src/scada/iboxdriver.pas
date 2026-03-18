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
    @member LastReadResult Qual foi o resultado da última tentativa de leitura.
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
    @member LastReadResult Qual foi o resultado da última tentativa de leitura.

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

    //1 caso a variavel tenha valor valido, 0 para invalidos
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
    @member LastReadResult Qual foi o resultado da última tentativa de leitura.

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
    @member HumidityValue Caso o sensor de umidade esteja instalado, informa o valor que foi lido.
  }
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
   @seealso(
  }
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
   Conjunto de estações i-Box.
  }
  TIBoxStations = array of TIBoxStation;

  {:
   @author(Fabio Luis Girardi <fabio@pascalscada.com>)

   @abstract(Driver de comunicação para dispositivos i-Box.)

   Suporta apenas tags da classe TPLCTagNumber.

   Para endereçar um tag, preencha com os seguintes propriedades do tag:

   @bold(PLCStation:) Endereço do i-Box. Aceita valores entre 0 e 255.
   @bold(MemAddress:) Registrador (PID) que se deseja ler. Aceita os seguintes
                      valores: 0, 96, 168, 200, 201, 202, 203, 204, 205 e 247.

   @bold(MemSubElement:) Indice do item dentro da estrutura caso o seu registrador
                         seja o 200, 201, 202 e 203. Comeca de zero e varia
                         conforme o PID escolhido.

  }
  TIBoxDriver = class(TProtocolDriver)
  private
    PStations: TIBoxStations;
    //Verifica se uma cadeia de Bytes tem a sua soma de verificacao OK
    function CheckSumOk(const Pkg: Bytes): Boolean;
    //calcula o checksum ate 1..n-1 posicao e coloca o calculo na posicao n
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
    { Published declarations }
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
  PLC, h: Longint;
  Found: Boolean;
begin
  if not (TagObj is TPLCTagNumber) then
    raise Exception.Create(SinvalidTag);

  with TagObj as TPLCTagNumber do
  begin
    if not (PLCStation in [0..255]) then Exit;
    if not (MemAddress in [0, 96, 168, 200..205, 247]) then Exit;

    h := High(PStations);
    for PLC := 0 to h do
      if PStations[PLC].Address = PLCStation then
      begin
        Found := True;
        Break;
      end;

    if not Found then Exit;

    case MemAddress of
      0:
        Dec(PStations[PLC].PID0.RefCount);
      96:
        Dec(PStations[PLC].PID96.RefCount);
      168:
        Dec(PStations[PLC].PID168.RefCount);
      200:
        Dec(PStations[PLC].PID200.RefCount);
      201:
        Dec(PStations[PLC].PID201.RefCount);
      202:
        Dec(PStations[PLC].PID202.RefCount);
      203:
        Dec(PStations[PLC].PID203.RefCount);
      204:
        Dec(PStations[PLC].PID204.RefCount);
      205:
        Dec(PStations[PLC].PID205.RefCount);
      247:
        Dec(PStations[PLC].PID247.RefCount);
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
  plc: Longint;
  dosomething: Boolean;
  tr: TTagRec;
  dummyValue: TArrayOfDouble;
begin
  dosomething := False;
  NeedSleep := 0;
  for plc := 0 to High(PStations) do
  begin
    //inicializa parte da estrutura de requisiçao.
    tr.Station := PStations[plc].Address;
    tr.SubElement := 0;

    with PStations[plc].PID96 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        tr.Address := 96;
        dosomething := True;
        DoRead(tr, dummyValue, False);
      end;

    with PStations[plc].PID168 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        tr.Address := 168;
        dosomething := True;
        DoRead(tr, dummyValue, False);
      end;

    with PStations[plc].PID200 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        tr.Address := 200;
        dosomething := True;
        DoRead(tr, dummyValue, False);
      end;
    with PStations[plc].PID201 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        tr.Address := 201;
        dosomething := True;
        DoRead(tr, dummyValue, False);
      end;
    with PStations[plc].PID202 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        tr.Address := 202;
        dosomething := True;
        DoRead(tr, dummyValue, False);
      end;

    with PStations[plc].PID203 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        tr.Address := 203;
        dosomething := True;
        DoRead(tr, dummyValue, False);
      end;

    with PStations[plc].PID204 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        tr.Address := 204;
        dosomething := True;
        DoRead(tr, dummyValue, False);
      end;
    /////////////////////////////////////////////
    //pid 205 é um comando, deixe-o fora do scan.
    /////////////////////////////////////////////
    with PStations[plc].PID247 do
      if (RefCount > 0) and (MilliSecondsBetween(CrossNow, TimeStamp) > MinScanTime) then
      begin
        tr.Address := 247;
        dosomething := True;
        DoRead(tr, dummyValue, False);
      end;
    if not dosomething then
      NeedSleep := -1;
  end;

  //se nao ira fazer nada troca de thread para melhorar o desempenho.
  if not dosomething then
    NeedSleep := -1;
end;

procedure TIBoxDriver.DoGetValue(TagRec: TTagRec; var Values: TScanReadRec);
var
  plc: Longint;
  found: Boolean;
  pid20x: TPID20xRegister;
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

  found := False;
  for plc := 0 to High(PStations) do
    if PStations[plc].Address = TagRec.Station then
    begin
      found := True;
      Break;
    end;

  if not found then
  begin
    Values.LastQueryResult := ioDriverError;
    Values.ValuesTimestamp := CrossNow;
    Exit;
  end;

  SetLength(Values.values, 1);
  case TagRec.Address of
    96: begin
      Values.values[0] := PStations[plc].PID96.Value;
      Values.ValuesTimestamp := PStations[plc].PID96.TimeStamp;
      Values.LastQueryResult := PStations[plc].PID96.LastReadResult;
    end;
    168: begin
      Values.values[0] := PStations[plc].PID168.Value;
      Values.ValuesTimestamp := PStations[plc].PID168.TimeStamp;
      Values.LastQueryResult := PStations[plc].PID168.LastReadResult;
    end;
    200..202: begin
      if TagRec.Address = 200 then
        pid20x := PStations[plc].PID200;
      if TagRec.Address = 201 then
        pid20x := PStations[plc].PID201;
      if TagRec.Address = 202 then
        pid20x := PStations[plc].PID202;

      Values.ValuesTimestamp := pid20x.TimeStamp;
      Values.LastQueryResult := pid20x.LastReadResult;

      with pid20x do
      begin
        case TagRec.SubElement of
          0:
            Values.values[0] := ActiveZones;
          1:
            Values.values[0] := ActiveAlarme;
          2:
            Values.values[0] := ManufacturerAlarmCode;
          3:
            Values.values[0] := ReturnAir1Active;
          4:
            Values.values[0] := Supply1Active;
          5:
            Values.values[0] := SetPointActive;
          6:
            Values.values[0] := EvaporatorCoilActive;
          7:
            Values.values[0] := ReturnAir2Active;
          8:
            Values.values[0] := Supply2Active;
          9:
            Values.values[0] := OperatingModeActive;
          10:
            Values.values[0] := ReturnAir1;
          11:
            Values.values[0] := Supply1;
          12:
            Values.values[0] := SetPoint;
          13:
            Values.values[0] := EvaporatorCoil;
          14:
            Values.values[0] := ReturnAir2;
          15:
            Values.values[0] := Supply2;
          16:
            Values.values[0] := OperatingMode;
          else
          begin
            Values.ValuesTimestamp := CrossNow;
            Values.LastQueryResult := ioIllegalRegAddress;
          end;
        end;
      end;
    end;
    203: begin
    end;
    204: begin
      Values.values[0] := PStations[plc].PID204.Value;
      Values.ValuesTimestamp := PStations[plc].PID204.TimeStamp;
      Values.LastQueryResult := PStations[plc].PID204.LastReadResult;
    end;
    205: begin
      Values.values[0] := PStations[plc].PID205.Value;
      Values.ValuesTimestamp := PStations[plc].PID205.TimeStamp;
      Values.LastQueryResult := PStations[plc].PID205.LastReadResult;
    end;
    247: begin
      Values.values[0] := PStations[plc].PID247.Value;
      Values.ValuesTimestamp := PStations[plc].PID247.TimeStamp;
      Values.LastQueryResult := PStations[plc].PID247.LastReadResult;
    end;
  end;
end;

function TIBoxDriver.DoWrite(const TagRec: TTagRec; const Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
begin
  //não há escrita de valores nesse driver.
  Result := ioIllegalFunction;
end;

function TIBoxDriver.DoRead(const TagRec: TTagRec; out Values: TArrayOfDouble; Sync: Boolean): TProtocolIOResult;
var
  pkg, pkgtotal: Bytes;
  cmdpkg: TIOPacket;
  plc, offset, bytesRemaim, b2, b3, b4, b5, b6, b7, b8: Longint;
  found: Boolean;
  pid20x: TPID20xRegister;
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

  found := False;
  for plc := 0 to High(PStations) do
    if PStations[plc].Address = TagRec.Station then
    begin
      found := True;
      Break;
    end;

  SetLength(Values, 1);
  try
    if PCommPort = nil then
    begin
      Result := ioNullDriver;
      Exit;
    end;

    SetLength(pkg, 4);
    pkg[0] := Byte(TagRec.Station);
    pkg[1] := 0;
    pkg[2] := Byte(TagRec.Address);
    CalculateCheckSum(pkg);

    case TagRec.Address of
      //Nível de combustivel.
      96: begin
        if PCommPort.IOCommandSync(iocWriteRead, 4, pkg, 4, PDriverID, 5, @cmdpkg) = 0 then
        begin
          Result := ioDriverError;
          Exit;
        end;

        if not CheckSumOk(cmdpkg.BufferToRead) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[0] <> cmdpkg.BufferToWrite[0]) or
          (cmdpkg.BufferToRead[0] <> TagRec.Station) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[1] <> cmdpkg.BufferToWrite[2]) or
          (cmdpkg.BufferToRead[1] <> TagRec.Address) then
        begin
          Result := ioCommError;
          Exit;
        end;

        Values[0] := cmdpkg.BufferToRead[2] / 2;
        Result := ioOk;
        if found then
        begin
          PStations[plc].PID96.Value := Values[0];
          PStations[plc].PID96.LastReadResult := Result;
          PStations[plc].PID96.TimeStamp := CrossNow;
        end;
      end;
      //Voltagem da bateria.
      168: begin
        if PCommPort.IOCommandSync(iocWriteRead, 4, pkg, 5, PDriverID, 5, @cmdpkg) = 0 then
        begin
          Result := ioDriverError;
          Exit;
        end;

        if not CheckSumOk(cmdpkg.BufferToRead) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[0] <> cmdpkg.BufferToWrite[0]) or
          (cmdpkg.BufferToRead[0] <> TagRec.Station) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[1] <> cmdpkg.BufferToWrite[2]) or
          (cmdpkg.BufferToRead[1] <> TagRec.Address) then
        begin
          Result := ioCommError;
          Exit;
        end;

        Values[0] := (cmdpkg.BufferToRead[2] * 256 + cmdpkg.BufferToRead[3]) / 20;
        Result := ioOk;
        if found then
        begin
          PStations[plc].PID168.Value := Values[0];
          PStations[plc].PID168.LastReadResult := Result;
          PStations[plc].PID168.TimeStamp := CrossNow;
        end;
      end;
      200..202: begin
        //inicializa o pacote auxiliar, para nao perder
        //as informações da variavel no final
        if found then
        begin
          if TagRec.Address = 200 then
          begin
            pid20x.RefCount := PStations[plc].PID200.RefCount;
            pid20x.MinScanTime := PStations[plc].PID200.MinScanTime;
          end;
          if TagRec.Address = 201 then
          begin
            pid20x.RefCount := PStations[plc].PID201.RefCount;
            pid20x.MinScanTime := PStations[plc].PID201.MinScanTime;
          end;
          if TagRec.Address = 202 then
          begin
            pid20x.RefCount := PStations[plc].PID202.RefCount;
            pid20x.MinScanTime := PStations[plc].PID202.MinScanTime;
          end;
        end;

        PCommPort.Lock(PDriverID);
        if PCommPort.IOCommandSync(iocWriteRead, 4, pkg, 5, PDriverID, 5, @cmdpkg) = 0 then
        begin
          Result := ioDriverError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[0] <> cmdpkg.BufferToWrite[0]) or
          (cmdpkg.BufferToRead[0] <> TagRec.Station) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[1] <> cmdpkg.BufferToWrite[2]) or
          (cmdpkg.BufferToRead[1] <> TagRec.Address) then
        begin
          Result := ioCommError;
          Exit;
        end;

        //se chegou até aqui, a requisição aparentemente está ok
        //entao comeca a decodificar os dados.
        pid20x.ActiveZones := (cmdpkg.BufferToRead[2] and $F0) Div $10;
        pid20x.ActiveAlarme := (cmdpkg.BufferToRead[2] and $F);
        offset := 0;
        if pid20x.ActiveAlarme > 0 then
        begin
          pid20x.ManufacturerAlarmCode := cmdpkg.BufferToRead[3];
          offset := 1;
        end
        else
          pid20x.ManufacturerAlarmCode := 0;

        //este bit não pode estar ligado... se estiver ligado, é falha
        //de comunicação.
        if (cmdpkg.BufferToRead[3 + offset] and 1) = 1 then
        begin
          Result := ioCommError;
          Exit;
        end;

        //offset tbm diz se é necessario
        //ler mais um byte.
        bytesRemaim := offset;
        b2 := ifthen((cmdpkg.BufferToRead[3 + offset] and $02) = $02, 1, 0);
        b3 := ifthen((cmdpkg.BufferToRead[3 + offset] and $04) = $04, 2, 0);
        b4 := ifthen((cmdpkg.BufferToRead[3 + offset] and $08) = $08, 2, 0);
        b5 := ifthen((cmdpkg.BufferToRead[3 + offset] and $10) = $10, 2, 0);
        b6 := ifthen((cmdpkg.BufferToRead[3 + offset] and $20) = $20, 2, 0);
        b7 := ifthen((cmdpkg.BufferToRead[3 + offset] and $40) = $40, 2, 0);
        b8 := ifthen((cmdpkg.BufferToRead[3 + offset] and $80) = $80, 2, 0);

        Inc(bytesRemaim, b2);
        Inc(bytesRemaim, b3);
        Inc(bytesRemaim, b4);
        Inc(bytesRemaim, b5);
        Inc(bytesRemaim, b6);
        Inc(bytesRemaim, b7);
        Inc(bytesRemaim, b8);

        pid20x.ReturnAir1Active := ifthen(b8 <> 0, 1, 0);
        pid20x.Supply1Active := ifthen(b7 <> 0, 1, 0);
        pid20x.SetPointActive := ifthen(b6 <> 0, 1, 0);
        pid20x.EvaporatorCoilActive := ifthen(b5 <> 0, 1, 0);
        pid20x.ReturnAir2Active := ifthen(b4 <> 0, 1, 0);
        pid20x.Supply2Active := ifthen(b3 <> 0, 1, 0);
        pid20x.OperatingModeActive := ifthen(b2 <> 0, 1, 0);

        //se sobrou Bytes oara ler...
        if bytesRemaim > 0 then
        begin
          //copia os primeiros Bytes do pacote
          pkg := cmdpkg.BufferToRead;

          if PCommPort.IOCommandSync(iocRead, 0, nil, bytesRemaim, PDriverID, 5, @cmdpkg) = 0 then
          begin
            Result := ioDriverError;
            Exit;
          end;

          pkgtotal := ConcatenateBYTES(pkg, cmdpkg.BufferToRead);

          if not CheckSumOk(pkgtotal) then
          begin
            Result := ioCommError;
            Exit;
          end;

          //o trem comeca da pos 4 + offset...
          //incrementa o offset pra nao mudar os indices.
          //offset trabalha como cursor.
          if pid20x.ReturnAir1Active = 1 then
          begin
            pid20x.ReturnAir1 := ((pkgtotal[4 + offset] * 256) + pkgtotal[5 + offset]) / 10;
            Inc(offset, 2);
          end;
          if pid20x.Supply1Active = 1 then
          begin
            pid20x.Supply1 := ((pkgtotal[4 + offset] * 256) + pkgtotal[5 + offset]) / 10;
            Inc(offset, 2);
          end;
          if pid20x.SetPointActive = 1 then
          begin
            pid20x.SetPoint := ((pkgtotal[4 + offset] * 256) + pkgtotal[5 + offset]) / 10;
            Inc(offset, 2);
          end;
          if pid20x.EvaporatorCoilActive = 1 then
          begin
            pid20x.EvaporatorCoil := ((pkgtotal[4 + offset] * 256) + pkgtotal[5 + offset]) / 10;
            Inc(offset, 2);
          end;
          if pid20x.ReturnAir2Active = 1 then
          begin
            pid20x.ReturnAir2 := ((pkgtotal[4 + offset] * 256) + pkgtotal[5 + offset]) / 10;
            Inc(offset, 2);
          end;
          if pid20x.Supply2Active = 1 then
          begin
            pid20x.Supply2 := ((pkgtotal[4 + offset] * 256) + pkgtotal[5 + offset]) / 10;
            Inc(offset, 2);
          end;
          if pid20x.OperatingModeActive = 1 then
          begin
            pid20x.OperatingModeActive := pkgtotal[4 + offset];
            Inc(offset, 2);
          end;
        end;

        Result := ioOk;
        pid20x.LastReadResult := Result;
        pid20x.TimeStamp := CrossNow;

        if found then
          case TagRec.Address of
            200:
              PStations[plc].PID200 := pid20x;
            201:
              PStations[plc].PID201 := pid20x;
            202:
              PStations[plc].PID202 := pid20x;
          end;


        with pid20x do
        begin
          case TagRec.SubElement of
            0:
              Values[0] := ActiveZones;
            1:
              Values[0] := ActiveAlarme;
            2:
              Values[0] := ManufacturerAlarmCode;
            3:
              Values[0] := ReturnAir1Active;
            4:
              Values[0] := Supply1Active;
            5:
              Values[0] := SetPointActive;
            6:
              Values[0] := EvaporatorCoilActive;
            7:
              Values[0] := ReturnAir2Active;
            8:
              Values[0] := Supply2Active;
            9:
              Values[0] := OperatingModeActive;
            10:
              Values[0] := ReturnAir1;
            11:
              Values[0] := Supply1;
            12:
              Values[0] := SetPoint;
            13:
              Values[0] := EvaporatorCoil;
            14:
              Values[0] := ReturnAir2;
            15:
              Values[0] := Supply2;
            16:
              Values[0] := OperatingMode;
            else
            begin
              Result := ioIllegalRegAddress;
            end;
          end;
        end;
      end;
      //status do motor e reset.
      204, 205: begin
        if PCommPort.IOCommandSync(iocWriteRead, 4, pkg, 4, PDriverID, 5, @cmdpkg) = 0 then
        begin
          Result := ioDriverError;
          Exit;
        end;

        if not CheckSumOk(cmdpkg.BufferToRead) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[0] <> cmdpkg.BufferToWrite[0]) or
          (cmdpkg.BufferToRead[0] <> TagRec.Station) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[1] <> cmdpkg.BufferToWrite[2]) or
          (cmdpkg.BufferToRead[1] <> TagRec.Address) then
        begin
          Result := ioCommError;
          Exit;
        end;

        Values[0] := cmdpkg.BufferToRead[2];
        Result := ioOk;

        if found then
        begin
          if TagRec.Address = 204 then
          begin
            PStations[plc].PID204.Value := Values[0];
            PStations[plc].PID204.LastReadResult := Result;
            PStations[plc].PID204.TimeStamp := CrossNow;
          end
          else
          begin
            PStations[plc].PID205.Value := Values[0];
            PStations[plc].PID205.LastReadResult := Result;
            PStations[plc].PID205.TimeStamp := CrossNow;
          end;
        end;
      end;
      //Horimetro do motor.
      247: begin
        if PCommPort.IOCommandSync(iocWriteRead, 4, pkg, 7, PDriverID, 5, @cmdpkg) = 0 then
        begin
          Result := ioDriverError;
          Exit;
        end;

        if not CheckSumOk(cmdpkg.BufferToRead) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[0] <> cmdpkg.BufferToWrite[0]) or
          (cmdpkg.BufferToRead[0] <> TagRec.Station) then
        begin
          Result := ioCommError;
          Exit;
        end;

        if (cmdpkg.BufferToRead[1] <> cmdpkg.BufferToWrite[2]) or
          (cmdpkg.BufferToRead[1] <> TagRec.Address) then
        begin
          Result := ioCommError;
          Exit;
        end;

        Values[0] := ((cmdpkg.BufferToRead[2] * 16777216) + (cmdpkg.BufferToRead[3] * 65536) + (cmdpkg.BufferToRead[4] * 256) + cmdpkg.BufferToRead[5]) / 20;
        Result := ioOk;
        if found then
        begin
          PStations[plc].PID247.Value := Values[0];
          PStations[plc].PID247.LastReadResult := Result;
          PStations[plc].PID247.TimeStamp := CrossNow;
        end;
      end;
    end;
  finally
    SetLength(pkgtotal, 0);
    SetLength(pkg, 0);
    SetLength(cmdpkg.BufferToRead, 0);
    SetLength(cmdpkg.BufferToWrite, 0);
  end;
end;

end.

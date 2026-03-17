{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  Unit que implementa a classe de conexão a vários sistemas gerenciadores de
  banco de dados.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  Unit that implements a class to connnect on many database servers.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
{$H+}
unit HMIDBConnection;

interface

uses
  Classes, SysUtils, ZConnection, MessageSpool, CrossEvent,
  syncobjs, ZDataset, psbufdataset, fgl, crossthreads;

type

  THMIDBConnectionStatementList = specialize TFPGList<UTF8String>;

  {$IFDEF PORTUGUES}
  //: Método usado pela thread para execução de uma consulta.
  {$ELSE}
  //: Procedure called by thread to execute the query.
  {$ENDIF}
  TExecSQLProc = procedure(SQLCmd: UTF8String; OutputDataset: TFPSBufDataSet; out Error: Boolean; NewConnection: Boolean) of object;

  TStartTransaction = procedure(NewConnection: Boolean) of object;

  TCommitTransaction = procedure of object;

  TRollbackTransaction = procedure of object;

  {$IFDEF PORTUGUES}
  //: Método usado pela thread para retornar um dataset após a execução da consulta.
  {$ELSE}
  //: Procedure called by thread to return the dataset after the query execution.
  {$ENDIF}
  TReturnDataSetProc = procedure(Sender: TObject; DS: TFPSBufDataSet; Error: Exception) of object;

  TReturnTransactionStatementsProc = procedure(Sender: TObject; AStatements: THMIDBConnectionStatementList; Sucess: Boolean; LineOfError: Integer; Error: Exception) of object;

  {$IFDEF PORTUGUES}
  //: Inteface para interação com objetos privados do THMIDBConnection
  {$ELSE}
  //: Interface to interact with private objects of THMIDBConnection
  {$ENDIF}
  IHMIDBConnection = interface
    ['{C5AEA572-D7F8-4116-9A4B-3C3B972DC021}']
    {$IFDEF PORTUGUES}
    //: Retorna um TZConnection para os editores de propriedade.
    {$ELSE}
    //: Returns the TZConnection to be used by property editors.
    {$ENDIF}
    function GetSyncConnection: TZConnection;

    {$IFDEF PORTUGUES}
    {:
      Função que executa uma consulta assincrona.
      @param(sql String. Commando SQL. Se for uma consulta de seleção onde se
                         deseja obter os dados retornados, é necessário informar
                         uma procedure válida no parametro ReturnDatasetCallback.)
      @param(ReturnDatasetCallback TReturnDataSetProc. Ponteiro para o procedimento
                         que vai ser chamado quando para retornar os dados a aplicação.)
    }
    {$ELSE}
    {:
      Executes a assynchronous query.
      @param(sql String. SQL command. If the query is a SELECT and you want get
                         the returned data, you must supply a callback procedure
                         in ReturnDatasetCallback param.)
      @param(ReturnDatasetCallback TReturnDataSetProc. Callback that will be
                         called to return the data to the application.)
    }
    {$ENDIF}
    procedure ExecSQL(SQL: UTF8String; ReturnDatasetCallback: TReturnDataSetProc; ReturnSync: Boolean = True; NewConnection: Boolean = True);
  end;

  {$IFDEF PORTUGUES}
  {:
  Estrutura de comando SQL que é enviado a thread.
  @seealso(TProcessSQLCommandThread.ExecSQLWithoutResultSet)
  @seealso(TProcessSQLCommandThread.ExecSQLWithResultSet)
  }
  {$ELSE}
  {:
  SQL command message. It's queued on thread.
  @seealso(TProcessSQLCommandThread.ExecSQLWithoutResultSet)
  @seealso(TProcessSQLCommandThread.ExecSQLWithResultSet)
  }
  {$ENDIF}
  TSQLCmdRec = record
    SQLCmd: string;
    ReturnSync, NewConnection: Boolean;
    ReturnDatasetCallback: TReturnDataSetProc;
  end;

  {$IFDEF PORTUGUES}
  {:
  Pointeiro de estrutura de mensagem de comando SQL.
  @seealso(TProcessSQLCommandThread.ExecSQLWithoutResultSet)
  @seealso(TProcessSQLCommandThread.ExecSQLWithResultSet)
  }
  {$ELSE}
  {:
  Pointer of a SQL command message.
  @seealso(TProcessSQLCommandThread.ExecSQLWithoutResultSet)
  @seealso(TProcessSQLCommandThread.ExecSQLWithResultSet)
  }
  {$ENDIF}
  PSQLCmdRec = ^TSQLCmdRec;

  TStatementCmdRec = record
    Statements: THMIDBConnectionStatementList;
    ReturnTransactionResult: TReturnTransactionStatementsProc;
    FreeStatemensAfterExecute: Boolean;
    ReturnSync: Boolean;
    NewConnection: Boolean;
  end;
  PStatementCmdRec = ^TStatementCmdRec;

  {$IFDEF PORTUGUES}
  {:
  Fila de execução assincrona de comandos SQL.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Asynchronous SQL command execution queue.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TProcessSQLCommandThread = class(TpSCADACoreAffinityThread)
  private
    FProcessingCmd: Integer;
    FQueue: TMessageSpool;
    FEnd: TCrossEvent;
    Cmd: PSQLCmdRec;
    Statements: PStatementCmdRec;
    FDs: TFPSBufDataSet;
    FError: Exception;
    FLineError: Integer;
    FErrorOnSync: Boolean;
    FOnExecSQL: TExecSQLProc;
    FStartTransaction: TStartTransaction;
    FCommitTransaction: TCommitTransaction;
    FRollbackTransaction: TRollbackTransaction;
    function GetPendingMsgs: Integer;
    procedure ProcessMessages;
  protected
    //: @exclude
    procedure Execute; override;
    //: @exclude
    procedure ReturnData;
    procedure ReturnStatementsResults;
  public
    {$IFDEF PORTUGUES}
    {:
    Cria a fila de processamento assincrono.

    @param(CreateSuspended  Boolean. Se verdadeiro, a fila é criada suspensa,
                                     sendo necessário chamar o procedimento
                                     Resume posteriormente para que ela comece a
                                     trabalhar.)
    @param(ExecSQLProc TExecSQLProc. Ponteiro para o procedimento que será chamado
                                     para executar as consultas SQL.)
    }
    {$ELSE}
    {:
    Creates the assynchronous queue.

    @param(CreateSuspended  Boolean. If @true, the spool is created suspended,
                                     and you must call the procedure Resume  to
                                     start the queue.)
    @param(ExecSQLProc TExecSQLProc. Points to a procedure that will be called
                                     to executes the SQL queries.)
    }
    {$ENDIF}
    constructor Create(CreateSuspended: Boolean; ExecSQLProc: TExecSQLProc; StartTransactionProc: TStartTransaction; CommitTransactionProc: TCommitTransaction; RollbackTransactionProc: TRollbackTransaction);
    //: @exclude
    destructor Destroy; override;
    {$IFDEF PORTUGUES}
    {:
    Espera determinado tempo pela finalização da thread.
    @param(Timeout Cardinal. Tempo máximo de espera.)
    @returns(Retorna wrSignaled caso a thread seja finalizada antes do tempo
             máximo de espera (Timeout). Caso a fila não termine antes do tempo
             máximo retorna wrTimeout. Caso o procedimento Destroy for chamado
             antes do método Terminate seguido @name, pode retornar wrAbandoned
             ou wrError.)
    }
    {$ELSE}
    {:
    Waits the end of the thread.
    @param(Timeout Cardinal. Maximum timeout to wait the ends.)
    @returns(Returns wrSignaled if the thread was ended before the timeout
             elapses. If the thread don't terminate before the timeout, return
             wrTimeout. If the Destroy was called before of the Terminate
             procedure, it can return wrAbandoned or wrError.)
    }
    {$ENDIF}
    function WaitEnd(Timeout: Cardinal): TWaitResult;
  public
    {$IFDEF PORTUGUES}
    {:
    Executa uma consulta SQL sem retornar um DataSet para a aplicação.
    @param(sql String. Comando SQL a executar.)
    }
    {$ELSE}
    {:
    Executes a SQL query without return a Dataset.
    @param(sql String. SQL query command.)
    }
    {$ENDIF}
    procedure ExecSQLWithoutResultSet(SQL: UTF8String; ReturnSync: Boolean = True; NewConnection: Boolean = True);

    {$IFDEF PORTUGUES}
    {:
    Executa uma consulta SQL e rotorna um DataSet para a aplicação.
    @param(sql String. Comando SQL a executar.)
    @param(ReturnDataCallback TReturnDataSetProc. Procedimento que é chamado para
                                                  retornar o dataset resultante da
                                                  consulta para a aplicação.)
    }
    {$ELSE}
    {:
    Executes a SQL query, returning a Dataset.
    @param(sql String. SQL query command.)
    @param(ReturnDataCallback TReturnDataSetProc. Procedure that will be called
                                                  to return the dataset.)
    }
    {$ENDIF}
    procedure ExecSQLWithResultSet(SQL: UTF8String; ReturnDataCallback: TReturnDataSetProc; ReturnSync, NewConnection: Boolean);

    procedure ExecTransaction(AStatements: THMIDBConnectionStatementList; ReturnTransactionResult: TReturnTransactionStatementsProc; FreeStatemensAfterExecute: Boolean; ReturnSync, NewConnection: Boolean);
    property PendingMsgs: Integer read GetPendingMsgs;
  end;

  {$IFDEF PORTUGUES}
  {:
  Componente de banco de dados do PascalSCADA.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Database component of PascalSCADA.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @bold(Uses the ZeosLib project.)
  }
  {$ENDIF}
  THMIDBConnection = class(TComponent, IHMIDBConnection)
  private
    FConnectRead: Boolean;
    FCustomCommitTransaction: TNotifyEvent;
    FCustomExecSQL: TExecSQLProc;
    FCustomRollbackTransaction: TNotifyEvent;
    FCustomStartTransaction: TNotifyEvent;
    FLibraryLocation: string;
    FReadOnly: Boolean;
    FSyncConnection, FASyncConnection: TZConnection;
    FASyncQuery: TZQuery;
    FCS: TCriticalSection;
    FSQLSpooler: TProcessSQLCommandThread;
    function GetPendingSQLCmds: Integer;
    function getProperties: TStrings;
    function GetSyncConnection: TZConnection;
    procedure ExecuteSQLCommand(SQLCmd: UTF8String; OutputDataset: TFPSBufDataSet; out Error: Boolean; NewConnection: Boolean);
    procedure SetLibraryLocation(AValue: string);
    procedure SetProperties(AValue: TStrings);
    procedure SetReadOnly(AValue: Boolean);
  protected
    FProtocol: string;
    FHostName: string;
    FPort: Longint;
    FDatabase: string;
    FUser: string;
    FPassword: string;
    FCatalog: string;
    FProperties: TStringList;
    procedure Loaded; override;
  protected
    function GetConnected: Boolean;

    procedure SetConnected(x: Boolean);
    procedure SetProtocol(x: string);
    procedure SetHostName(x: string);
    procedure SetPort(x: Longint);
    procedure SetDatabase(x: string);
    procedure SetUser(x: string);
    procedure SetPassword(x: string);
    procedure SetCatalog(x: string);
    procedure StartTransaction(NewConnection: Boolean);
    procedure CommitTransaction;
    procedure RollBackTransaction;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ExecSQL(SQL: UTF8String; ReturnDatasetCallback: TReturnDataSetProc; ReturnSync: Boolean = True; NewConnection: Boolean = False);
    procedure ExecTransaction(Statements: THMIDBConnectionStatementList; ReturnTransactionResult: TReturnTransactionStatementsProc; FreeStatemensAfterExecute: Boolean; ReturnSync: Boolean = True; NewConnection: Boolean = False);
    property GetPendingSQLCommands: Integer read GetPendingSQLCmds;
  public
    class function FormatPGDatetime(ADateTime: TDateTime): string;
    class function FormatSQLNumber(ANumber: Double; DecimalPlaces: Byte = 0): string;
    class function FormatSQLString(AStr: string; EmptyIsNull: Boolean = False): string;
    class function FormatSQLUUID(AUUID: TGuid): string;
  published
    {$IFDEF PORTUGUES}
    //: Caso @true, conecta ou está conectado ao banco de dados.
    {$ELSE}
    //: If true, connects or are connected on database.
    {$ENDIF}
    property Connected: Boolean read GetConnected write SetConnected;

    {$IFDEF PORTUGUES}
    //: Força o ZeosLib usar a biblioteca de acesso nativo apontada por este caminho.
    {$ELSE}
    //: If true, connects or are connected on database.
    {$ENDIF}
    property LibraryLocation: string read FLibraryLocation write SetLibraryLocation nodefault;

    {$IFDEF PORTUGUES}
    //: Driver de banco de dados em uso para conexão ao banco de dados.
    {$ELSE}
    //: Database protocol driver used to connect on database.
    {$ENDIF}
    property Protocol: string read FProtocol write SetProtocol;

    {$IFDEF PORTUGUES}
    //: Endereço ou nome da máquina onde está o banco de dados.
    {$ELSE}
    //: Address or machine name where is the database.
    {$ENDIF}
    property HostName: string read FHostName write SetHostName;

    {$IFDEF PORTUGUES}
    //: Número da porta usada para conectar no banco de dados (conexões TCP/UDP)
    {$ELSE}
    //: Port number to connect on database (TCP/UDP connections)
    {$ENDIF}
    property Port: Longint read FPort write SetPort default 0;

    {$IFDEF PORTUGUES}
    //: Lista de propriedades da conexão
    {$ELSE}
    //: Connections properties.
    {$ENDIF}
    property Properties: TStrings read getProperties write SetProperties;

    {$IFDEF PORTUGUES}
    //: Banco de dados a conectar.
    {$ELSE}
    //: Database name.
    {$ENDIF}
    property Database: string read FDatabase write SetDatabase;

    {$IFDEF PORTUGUES}
    //: Usuário a conectar no banco de dados.
    {$ELSE}
    //: Username to connect on database.
    {$ENDIF}
    property User: string read FUser write SetUser;

    {$IFDEF PORTUGUES}
    //: Senha do usuário para conectar ao banco de dados.
    {$ELSE}
    //: Password of the user to connect on database.
    {$ENDIF}
    property Password: string read FPassword write SetPassword;

    {$IFDEF PORTUGUES}
    //: Verifique a documentação do TZConnection.Catalog do ZeosLib para maiores informações.
    {$ELSE}
    //: See the documentation of TZConnection.Catalog of ZeosLib for more information.
    {$ENDIF}
    property Catalog: string read FCatalog write SetCatalog;

    {$IFDEF PORTUGUES}
    //: Verifique a documentação do TZConnection.ReadOnly do ZeosLib para maiores informações.
    {$ELSE}
    //: See the documentation of TZConnection.ReadOnly of ZeosLib for more information.
    {$ENDIF}
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;

    property OnCustomStartTransaction: TNotifyEvent read FCustomStartTransaction write FCustomStartTransaction;
    property OnCustomCommitTransaction: TNotifyEvent read FCustomCommitTransaction write FCustomCommitTransaction;
    property OnCustomRollbackTransaction: TNotifyEvent read FCustomRollbackTransaction write FCustomRollbackTransaction;
    property OnCustomExecSQL: TExecSQLProc read FCustomExecSQL write FCustomExecSQL;
  end;

const
  SQLCommandMSG = 0;
  StatementsCommandMSG = 1;

implementation

uses StrUtils, hsutils;

  //##############################################################################
  //THREAD DE EXECUÇÃO DOS COMANDOS SQL THMIDBCONNECTION
  //SQL COMMANDS QUEUE THREAD CLASS.
  //##############################################################################

constructor TProcessSQLCommandThread.Create(CreateSuspended: Boolean; ExecSQLProc: TExecSQLProc; StartTransactionProc: TStartTransaction; CommitTransactionProc: TCommitTransaction; RollbackTransactionProc: TRollbackTransaction);
begin
  inherited Create(CreateSuspended);
  FQueue := TMessageSpool.Create;
  FEnd := TCrossEvent.Create(True, False);
  FOnExecSQL := ExecSQLProc;
  FStartTransaction := StartTransactionProc;
  FCommitTransaction := CommitTransactionProc;
  FRollbackTransaction := RollbackTransactionProc;
end;

destructor TProcessSQLCommandThread.Destroy;
begin
  inherited Destroy;
  ProcessMessages;
  FQueue.Destroy;
  FEnd.Destroy;
end;

procedure TProcessSQLCommandThread.Execute;
begin
  FEnd.ResetEvent;
  while not Terminated do
  begin
    ProcessMessages;
    Sleep(1);
  end;
  ProcessMessages;
  FEnd.SetEvent;
end;

procedure TProcessSQLCommandThread.ProcessMessages;
var
  Msg: TMSMsg;
  i: Integer;
  Err: Boolean;
  isASelect: Boolean;
  SQL: string;
begin
  while FQueue.PeekMessage(Msg, 0, 0, True) do
  begin
    //executa o comando SQL
    //executes the SQL commmand.
    FErrorOnSync := False;
    if (Msg.MsgID = SQLCommandMSG) and (Msg.wParam <> nil) then
    begin
      Cmd := PSQLCmdRec(Msg.wParam);
      InterlockedExchange(FProcessingCmd, 1);
      try
        try
          //se é necessario retornar algo
          //cria o dataset de retorno de dados.

          //if are to return the data,
          //creates the dataset.
          FError := nil;

          isASelect := False;
          SQL := Trim(LowerCase(Cmd^.SQLCmd));
          isASelect := pos('select', SQL) = 1;

          if Assigned(Cmd^.ReturnDatasetCallback) and isASelect then
          begin
            FDs := TFPSBufDataSet.Create(nil);
          end
          else
          begin
            FDs := nil;
          end;

          if Assigned(FOnExecSQL) then
          try
            FOnExecSQL(Cmd^.SQLCmd, FDs, Err, Cmd^.NewConnection);
          finally
          end;

          if Assigned(Cmd^.ReturnDatasetCallback) then
          begin
            if Cmd^.ReturnSync then
            begin
              FErrorOnSync := True;
              Synchronize(@ReturnData);
            end
            else
              ReturnData;
          end;
        except
          on E: Exception do
          begin
            if not FErrorOnSync then
            begin
              FError := E;
              if Assigned(Cmd^.ReturnDatasetCallback) then
                Synchronize(@ReturnData);
            end;
          end;
        end;
      finally
        if Assigned(Cmd) then Dispose(Cmd);
        InterlockedExchange(FProcessingCmd, 0);
      end;
    end;

    if (Msg.MsgID = StatementsCommandMSG) and (Msg.wParam <> nil) then
    begin
      Statements := PStatementCmdRec(Msg.wParam);
      try
        InterlockedExchange(FProcessingCmd, 1);
        if Statements^.Statements = nil then
          Exit;
        if not Assigned(FStartTransaction) then
          Exit;
        if not Assigned(FCommitTransaction) then
          Exit;
        if not Assigned(FRollbackTransaction) then
          Exit;
        if not Assigned(FOnExecSQL) then
          Exit;

        try
          FStartTransaction(Statements^.NewConnection);
          FError := nil;
          try
            FLineError := 0;
            for i := 0 to Statements^.Statements.Count - 1 do
            begin
              FOnExecSQL(Statements^.Statements.Items[i], nil, Err, False);
              if Err then Break;
            end;
          except
            on e: Exception do
            begin
              FError := e;
              FLineError := i;
              Exit;
            end;
          end;
        finally
          if (Err = False) and (FError = nil) then
            FCommitTransaction()
          else
            FRollbackTransaction();

          if Assigned(Statements^.ReturnTransactionResult) then
          begin
            if Statements^.ReturnSync then
              Synchronize(@ReturnStatementsResults)
            else
            begin
              if (Err = False) and (FError = nil) then
                Statements^.ReturnTransactionResult(self, Statements^.Statements, True, -1, nil)
              else
                Statements^.ReturnTransactionResult(self, Statements^.Statements, False, FLineError, FError);
            end;
          end;
        end;
      finally
        if Statements^.FreeStatemensAfterExecute then
        begin
          Statements^.Statements.Clear;
          FreeAndNil(Statements^.Statements);
        end;
        Dispose(Statements);
        InterlockedExchange(FProcessingCmd, 0);
      end;
    end;
  end;
end;

function TProcessSQLCommandThread.GetPendingMsgs: Integer;
begin
  Result := FQueue.GetMsgCount + InterlockedExchange(FProcessingCmd, FProcessingCmd);
end;

procedure TProcessSQLCommandThread.ReturnData;
begin
  if FError <> nil then
    Cmd^.ReturnDatasetCallback(self, nil, FError)
  else
    Cmd^.ReturnDatasetCallback(self, FDs, nil);
end;

procedure TProcessSQLCommandThread.ReturnStatementsResults;
begin
  if FError = nil then
    Statements^.ReturnTransactionResult(self, Statements^.Statements, True, -1, nil)
  else
    Statements^.ReturnTransactionResult(self, Statements^.Statements, False, FLineError, FError);
end;

function TProcessSQLCommandThread.WaitEnd(Timeout: Cardinal): TWaitResult;
begin
  Result := FEnd.WaitFor(Timeout);
end;

procedure TProcessSQLCommandThread.ExecSQLWithoutResultSet(SQL: UTF8String; ReturnSync: Boolean; NewConnection: Boolean);
begin
  ExecSQLWithResultSet(SQL, nil, ReturnSync, NewConnection);
end;

procedure TProcessSQLCommandThread.ExecSQLWithResultSet(SQL: UTF8String; ReturnDataCallback: TReturnDataSetProc; ReturnSync, NewConnection: Boolean);
var
  SQLCmd: PSQLCmdRec;
begin
  if Terminated then Exit;
  new(SQLCmd);
  SQLCmd^.SQLCmd := SQL;
  SQLCmd^.ReturnSync := ReturnSync;
  SQLCmd^.NewConnection := NewConnection;
  SQLCmd^.ReturnDatasetCallback := ReturnDataCallback;
  FQueue.PostMessage(SQLCommandMSG, SQLCmd, nil, True);
end;

procedure TProcessSQLCommandThread.ExecTransaction(AStatements: THMIDBConnectionStatementList; ReturnTransactionResult: TReturnTransactionStatementsProc; FreeStatemensAfterExecute: Boolean; ReturnSync, NewConnection: Boolean);
var
  statementcmd: PStatementCmdRec;
begin
  if Terminated then Exit;
  if AStatements = nil then Exit;

  new(statementcmd);
  statementcmd^.Statements := AStatements;
  statementcmd^.ReturnTransactionResult := ReturnTransactionResult;
  statementcmd^.FreeStatemensAfterExecute := FreeStatemensAfterExecute;
  statementcmd^.ReturnSync := ReturnSync;
  statementcmd^.NewConnection := NewConnection;

  FQueue.PostMessage(StatementsCommandMSG, statementcmd, nil, True);
end;


//##############################################################################
// THMIDBConnection class
//##############################################################################

constructor THMIDBConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCS := TCriticalSection.Create;
  FSyncConnection := TZConnection.Create(nil);
  FASyncConnection := TZConnection.Create(nil);
  FASyncQuery := TZQuery.Create(FASyncConnection);
  FASyncQuery.Connection := FASyncConnection;
  FProperties := TStringList.Create;

  FSQLSpooler := TProcessSQLCommandThread.Create(True, @ExecuteSQLCommand, @StartTransaction, @CommitTransaction, @RollBackTransaction);
  FSQLSpooler.WakeUp;
end;

destructor THMIDBConnection.Destroy;
begin
  inherited Destroy;
  //destroi a thread

  //Destroys the thread.
  FSQLSpooler.Terminate;
  while FSQLSpooler.WaitEnd(1) <> wrSignaled do
    if MainThreadID = GetCurrentThreadID then
      CheckSynchronize(1)
    else
      Sleep(1);

  FreeAndNil(FSQLSpooler);
  FreeAndNil(FASyncQuery);
  FreeAndNil(FSyncConnection);
  FreeAndNil(FASyncConnection);
  FreeAndNil(FProperties);
  FCS.Destroy;
end;

procedure THMIDBConnection.Loaded;
begin
  inherited Loaded;
  Connected := FConnectRead;
end;

function THMIDBConnection.GetSyncConnection: TZConnection;
begin
  Result := FSyncConnection;
end;

function THMIDBConnection.getProperties: TStrings;
begin
  Result := FProperties;
end;

function THMIDBConnection.GetPendingSQLCmds: Integer;
begin
  Result := FSQLSpooler.PendingMsgs;
end;

procedure THMIDBConnection.ExecSQL(SQL: UTF8String; ReturnDatasetCallback: TReturnDataSetProc; ReturnSync: Boolean; NewConnection: Boolean);
begin
  if Assigned(FSQLSpooler) then
    FSQLSpooler.ExecSQLWithResultSet(SQL, ReturnDatasetCallback, ReturnSync, NewConnection);
end;

procedure THMIDBConnection.ExecTransaction(Statements: THMIDBConnectionStatementList; ReturnTransactionResult: TReturnTransactionStatementsProc; FreeStatemensAfterExecute: Boolean; ReturnSync: Boolean; NewConnection: Boolean);
begin
  if Assigned(FSQLSpooler) then
    FSQLSpooler.ExecTransaction(Statements, ReturnTransactionResult, FreeStatemensAfterExecute, ReturnSync, NewConnection);
end;

procedure THMIDBConnection.StartTransaction(NewConnection: Boolean);
begin
  if Assigned(FCustomStartTransaction) then
    FCustomStartTransaction(self)
  else
  begin
    FCS.Enter;
    try
      try
        if NewConnection then
        begin
          FASyncConnection.Disconnect;
          FASyncConnection.Connect;
        end;
        FASyncConnection.StartTransaction;
      except
        on e: Exception do
        begin
          {$IFNDEF WINDOWS}
          writeln('Start transaction exception: ', e.Message);
          {$ENDIF}
        end;
      end;
    finally
      FCS.Leave;
    end;
  end;
end;

procedure THMIDBConnection.CommitTransaction;
begin
  if Assigned(FCustomCommitTransaction) then
    FCustomCommitTransaction(self)
  else
  begin
    FCS.Enter;
    try
      FASyncConnection.Commit;
    finally
      FCS.Leave;
    end;
  end;
end;

procedure THMIDBConnection.RollBackTransaction;
begin
  if Assigned(FCustomRollbackTransaction) then
    FCustomRollbackTransaction(self)
  else
  begin
    FCS.Enter;
    try
      FASyncConnection.Rollback;
    finally
      FCS.Leave;
    end;
  end;
end;

procedure THMIDBConnection.ExecuteSQLCommand(SQLCmd: UTF8String; OutputDataset: TFPSBufDataSet; out Error: Boolean; NewConnection: Boolean);
var
  AStringStream: TStringStream;
  Msg: string;
begin
  if Assigned(FCustomExecSQL) then
    FCustomExecSQL(SQLCmd, OutputDataset, Error, NewConnection)
  else
  begin
    FCS.Enter;
    try
      if FASyncConnection.ReadOnly then
      begin
        Error := True;
        Exit;
      end;

      try
        if NewConnection then
        begin
          FASyncConnection.Disconnect;
          FASyncConnection.Connect;
        end;

        Error := False;
        FASyncQuery.SQL.Clear;
        FASyncQuery.SQL.Add(SQLCmd);
        if OutputDataset = nil then
        begin
          try
            FASyncQuery.ExecSQL
          except
            Error := True;
          end;
        end
        else
        begin
          FASyncQuery.Open;
          OutputDataset.CopyFromDataset(FASyncQuery);
          FASyncQuery.Close;
        end;
      except
        on e: Exception do
        begin
          Msg := e.Message;
          {$IFNDEF WINDOWS}
          writeln(e.Message);
          writeln(SQLCmd);
          {$ENDIF}
          //AStringStream:=TStringStream.Create(sqlcmd);
          //AStringStream.SaveToFile('/tmp/teste.txt');
          //AStringStream.Free;
          Error := True;
        end;
      end;
    finally
      FCS.Leave;
    end;
  end;
end;

procedure THMIDBConnection.SetLibraryLocation(AValue: string);
begin
  FSyncConnection.LibraryLocation := AValue;
  FCS.Enter;
  try
    FASyncConnection.LibraryLocation := AValue;
  finally
    FCS.Leave;
  end;
  FHostName := FSyncConnection.LibraryLocation;
end;

procedure THMIDBConnection.SetProperties(AValue: TStrings);
begin
  FSyncConnection.Properties.Assign(AValue);
  FCS.Enter;
  try
    FASyncConnection.Properties.Assign(AValue);
  finally
    FCS.Leave;
  end;
  FProperties.Assign(AValue);
end;

procedure THMIDBConnection.SetReadOnly(AValue: Boolean);
begin
  FSyncConnection.ReadOnly := AValue;
  FCS.Enter;
  try
    FASyncConnection.ReadOnly := AValue;
  finally
    FCS.Leave;
  end;
  FReadOnly := FSyncConnection.ReadOnly;
end;

function THMIDBConnection.GetConnected: Boolean;
begin
  Result := FSyncConnection.Connected;
end;

procedure THMIDBConnection.SetProtocol(x: string);
begin
  FSyncConnection.Protocol := x;
  FCS.Enter;
  try
    FASyncConnection.Protocol := x;
  finally
    FCS.Leave;
  end;
  FProtocol := FSyncConnection.Protocol;
end;

procedure THMIDBConnection.SetHostName(x: string);
begin
  FSyncConnection.HostName := x;
  FCS.Enter;
  try
    FASyncConnection.HostName := x;
  finally
    FCS.Leave;
  end;
  FHostName := FSyncConnection.HostName;
end;

procedure THMIDBConnection.SetPort(x: Longint);
begin
  FSyncConnection.Port := x;
  FCS.Enter;
  try
    FASyncConnection.Port := x;
  finally
    FCS.Leave;
  end;
  FPort := FSyncConnection.Port;
end;

procedure THMIDBConnection.SetDatabase(x: string);
begin
  FSyncConnection.Database := x;
  FCS.Enter;
  try
    FASyncConnection.Database := x;
  finally
    FCS.Leave;
  end;
  FDatabase := FSyncConnection.Database;
end;

procedure THMIDBConnection.SetUser(x: string);
begin
  FSyncConnection.User := x;
  FCS.Enter;
  try
    FASyncConnection.User := x;
  finally
    FCS.Leave;
  end;
  FUser := FSyncConnection.User;
end;

procedure THMIDBConnection.SetPassword(x: string);
begin
  FSyncConnection.Password := x;
  FCS.Enter;
  try
    FASyncConnection.Password := x;
  finally
    FCS.Leave;
  end;
  FPassword := FSyncConnection.Password;
end;

procedure THMIDBConnection.SetCatalog(x: string);
begin
  FSyncConnection.Catalog := x;
  FCS.Enter;
  try
    FASyncConnection.Catalog := x;
  finally
    FCS.Leave;
  end;
  FCatalog := FSyncConnection.Catalog;
end;

procedure THMIDBConnection.SetConnected(x: Boolean);
begin
  if [csReading, csLoading] * ComponentState <> [] then
  begin
    FConnectRead := x;
    Exit;
  end;
  FSyncConnection.Connected := x;
  if FSyncConnection.Connected = x then
  begin
    FCS.Enter;
    try
      FASyncConnection.Connected := x;
    finally
      FCS.Leave;
    end;
  end;
end;

class function THMIDBConnection.FormatPGDatetime(ADateTime: TDateTime): string;
var
  AFormatSettings: TFormatSettings;
begin
  AFormatSettings := DefaultFormatSettings;
  AFormatSettings.DateSeparator := '-';
  Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', ADateTime, AFormatSettings) + '''';
end;

class function THMIDBConnection.FormatSQLNumber(ANumber: Double; DecimalPlaces: Byte): string;
var
  AFormatSettings: TFormatSettings;
  FmtMask: string;
begin
  AFormatSettings := DefaultFormatSettings;
  AFormatSettings.DecimalSeparator := '.';
  FmtMask := '#0';
  if DecimalPlaces > 0 then
    FmtMask := FmtMask + AFormatSettings.DecimalSeparator + AddChar('0', '', DecimalPlaces);
  Result := FormatFloat(FmtMask, ANumber, AFormatSettings);
end;

class function THMIDBConnection.FormatSQLString(AStr: string; EmptyIsNull: Boolean = False): string;
var
  AStringArray: TStringArray;
  i: Integer;
  Sep: string;
begin
  if (AStr = '') and EmptyIsNull then
  begin
    Result := 'NULL';
    Exit;
  end;

  AStringArray := ExplodeString('''', AStr);
  Result := '';
  Sep := '';
  for i := 0 to High(AStringArray) do
  begin
    Result := Result + Sep + AStringArray[i];
    Sep := '''''';
  end;
  Result := '''' + Result + '''';
end;

class function THMIDBConnection.FormatSQLUUID(AUUID: TGuid): string;
begin
  Result := '''' + GUIDToString(AUUID) + '''';
end;

end.

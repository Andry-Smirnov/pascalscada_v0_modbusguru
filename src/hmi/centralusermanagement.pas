unit CentralUserManagement;

{$mode ObjFPC}

interface

uses
  BasicUserManagement, ControlSecurityManager, fpjson, jsonparser, StrUtils,
  Classes, fphttpclient, SysUtils, Forms, fpopenssl, sslsockets, opensslsockets;

type
  TCheckUserChanges = function(out ChangeData: UTF8String): Integer of object;
  TRemoteUserChanged = procedure(AUID: Integer; AUserName: string; AuthData: TJSONObject) of object;

  TSyncRec = record
    UID: Integer;
    UserName: string;
    AuthData: TJSONObject;
  end;
  PSyncRec = ^TSyncRec;

  TCheckUserChangeThread = class(TThread)
  private
    FCheckUserChanged: TCheckUserChanges;
    FOnUserChanged: TRemoteUserChanged;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean; const StackSize: SizeUInt = DefaultStackSize);
    property OnUserChanged: TRemoteUserChanged read FOnUserChanged write FOnUserChanged;
    property CheckUserChanged: TCheckUserChanges read FCheckUserChanged write FCheckUserChanged;
  end;

  { TCentralUserManagement }

  TCentralUserManagement = class(TBasicUserManagement)
  private
    FAuthServer: string;
    FAuthServerPort: Word;
    FRaiseExceptOnConnFailure: Boolean;
    FUseCachedAuthorizations: Boolean;
    FUseCentralUserAsLocalUser: Boolean;
    FWait: Boolean;
    FUseSSL: Boolean;
    FCacheUpdateCount: Integer;
    FCheckUserChangedThread: TCheckUserChangeThread;
    function CheckServerUserChanged(out ChangeData: UTF8String): Integer;
    function GetCacheUptCount: Integer;
    function PostMethod(AAPIEndpoint: string; AJsonData: TJSONData; var ReturnData: UTF8String): Boolean;
    function PostMethodInt(AAPIEndpoint: string; AJsonData: TJSONData; var ReturnData: UTF8String): Integer;
    procedure RemoteUserChanged(AUID: Integer; AUserName: string; AuthData: TJSONObject);
    procedure RemoteUserChangedRemotely(Data: PtrInt);
    procedure setAuthServer(AValue: string);
    procedure SetAuthServerPort(AValue: Word);
    procedure SetUseCentralUserAsLocalUser(AValue: Boolean);
    procedure UpdateControlSecureState(Data: PtrInt);

  protected
    FCachedAuthorizations: TJSONObject;
    FRegisteredSC: TStringList;
    FUseCentralUserAsLocalUserLoading: Boolean;
    FValidatedSC: TStringList;
    FRegisteredSCLastQuery: TDateTime;
    function CheckUserAndPassword(User, Pass: UTF8String; out UserID: Integer; LoginAction: Boolean): Boolean; override;
    function CanAccess(ASecurityCode: UTF8String; AUID: Integer): Boolean; override; overload;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetRegisteredAccessCodes: TStringList; override;
    procedure Manage; override;
    procedure Logout; override;

    //Security codes management
    procedure ValidateSecurityCode(ASecurityCode: UTF8String); override;
    procedure RegisterSecurityCode(ASecurityCode: UTF8String); override;
    function SecurityCodeExists(sc: UTF8String): Boolean; override;

    function CanAccess(ASecurityCode: UTF8String): Boolean; override;
  published
    property UID;
    property ChipCardReader;
    property CurrentUserName;
    property CurrentUserLogin;
    property LoggedSince;

    property LoginRetries;
    property LoginFrozenTime;

    property SuccessfulLogin;
    property FailureLogin;
    property UserChanged;
  published
    property RaiseExceptOnConnFailure: Boolean read FRaiseExceptOnConnFailure write FRaiseExceptOnConnFailure;
    property AuthServer: string read FAuthServer write setAuthServer;
    property AuthServerPort: Word read FAuthServerPort write SetAuthServerPort;
    property UseCachedAuthorizations: Boolean read FUseCachedAuthorizations write FUseCachedAuthorizations;
    property UseCentralUserAsLocalUser: Boolean read FUseCentralUserAsLocalUser write SetUseCentralUserAsLocalUser;
    property UseSSL: Boolean read FUseSSL write FUseSSL;
    property CachedUpdateCount: Integer read GetCacheUptCount;
  end;


const
  _S_USER = 'user';
  _S_PASSWORD = 'password';
  _S_CHECK_USER_PASSWORD = 'checkuserpwd';
  _S_ENUM_SECURITY_CODES = 'enumsecuritycodes';
  _S_MANAGEMENT_NOT_AVAILABLE = 'User management not available, check the user management on the server!';
  _S_MANAGEMENT_VALIDATE_SC = 'User can not access Security Code';
  _S_MANAGEMENT_VALIDATE_RSC = 'Security Code is not found';
  _S_CANNOT_CONNECT_ON_SEC_SERVER = 'Conneciton to security server failed';
  _S_SECURITY_SERVER_REJECTED_SC = 'Security server has been rejected this security code';
  _S_SECURITY_SERVER_CANNOT_REGISTER_SC = 'Security server cannot register this security code';
  _S_UID_CAN_ACCESS = 'uidcanaccess';
  _S_SECURITY_CODE = 'securitycode';
  _S_UID = 'uid';
  _S_LOGIN = 'login';
  _S_REGISTER_SECURITY_CODE = 'registersecuritycode';
  _S_VALIDADE_SECURITY_CODE = 'validadesecuritycode';
  _S_F_USE_CENTRAL_USER_AS_LOCAL_USER = 'UseCentralUserAsLocalUser';
  _S_AUTHORIZATIONS = 'authorizations';
  _S_USER_CHANGED = 'userchanged';
  _S_USER_NAME = 'username';


implementation


uses
  DateUtils, Dialogs;

  { TCheckUserChangeThread }

procedure TCheckUserChangeThread.Execute;
var
  Aux: Integer;
  JsonData: UTF8String;
  UserData: TJSONData;
  JAux: TJSONObject;
  JNumber: TJSONNumber;
  JStr: TJSONString;

  procedure DoUserChange(AUID2: Integer; AUserName: string; AData2: TJSONObject);
  begin
    if (not Terminated) and (Aux = 200) and Assigned(FOnUserChanged) then
      FOnUserChanged(AUID2, AUserName, AData2);
  end;

begin
  while not Terminated do
  begin
    try
      if Assigned(FCheckUserChanged) then
      begin
        Aux := FCheckUserChanged(JsonData);
        if Aux = 0 then
        begin
          Sleep(100);
          Continue;
        end;
        try
          UserData := GetJSON(JsonData);
          try
            if (UserData is TJSONObject) and TJSONObject(UserData).Find(_S_AUTHORIZATIONS, JAux) and TJSONObject(UserData).Find(_S_UID, JNumber) and TJSONObject(UserData).Find(_S_USER_NAME, JStr) then
            begin
              DoUserChange(JNumber.AsInteger, JStr.AsString, JAux.Clone as TJSONObject);
            end
            else
            begin
              DoUserChange(-1, '', nil);
            end;
          finally
            FreeAndNil(UserData);
          end;
        except
          DoUserChange(-1, '', nil);
        end;
      end;
    except
    end;
  end;
end;

constructor TCheckUserChangeThread.Create(CreateSuspended: Boolean; const StackSize: SizeUInt);
begin
  inherited Create(CreateSuspended, StackSize);
end;

{ TCentralUserManagement }

function TCentralUserManagement.PostMethod(AAPIEndpoint: string; AJsonData: TJSONData; var ReturnData: UTF8String): Boolean;
begin
  Exit(PostMethodInt(AAPIEndpoint, AJsonData, ReturnData) = 200);
end;

function TCentralUserManagement.CheckServerUserChanged(out ChangeData: UTF8String): Integer;
var
  JObj: TJSONObject;
  Aux: UTF8String;
begin
  JObj := TJSONObject.Create;
  try
    JObj.Add('wait', FWait); //fist cycle dont have to wait.
    Result := PostMethodInt(_S_USER_CHANGED, JObj, ChangeData);
    FWait := Result = 200;
  finally
    FreeAndNil(JObj);
  end;
end;

function TCentralUserManagement.GetCacheUptCount: Integer;
begin
  Exit(FCacheUpdateCount);
end;

function TCentralUserManagement.PostMethodInt(AAPIEndpoint: string; AJsonData: TJSONData; var ReturnData: UTF8String): Integer;
var
  AClient: TFPHTTPClient;
  MStream: TStringStream;
  SStream: TStringStream;
begin
  AClient := TFPHTTPClient.Create(Self);
  try
    MStream := TStringStream.Create(AJsonData.AsJSON);
    try
      MStream.Position := 0;
      AClient.RequestBody := MStream;
      SStream := TStringStream.Create;
      try
        try
          AClient.Post(IfThen(FUseSSL, 'https', 'http') + '://' + FAuthServer
            + ':' + FAuthServerPort.ToString + '/' + AAPIEndpoint, SStream);
        except
        end;
        SStream.Position := 0;
        ReturnData := SStream.DataString;
        //Clipboard.AsText:=ReturnData
      finally
        FreeAndNil(SStream)
      end;
      Exit(AClient.ResponseStatusCode);
    finally
      FreeAndNil(MStream);
    end;
  finally
    FreeAndNil(AClient);
  end;
end;

procedure TCentralUserManagement.RemoteUserChanged(AUID: Integer; AUserName: string; AuthData: TJSONObject);
var
  Aux: PSyncRec;
begin
  New(Aux);
  Aux^.UserName := AUserName;
  Aux^.UID := AUID;
  Aux^.AuthData := AuthData;
  if Application.Flags * [AppDoNotCallAsyncQueue] = [] then
  begin
    Application.QueueAsyncCall(@RemoteUserChangedRemotely, PtrInt(Aux));
  end;
end;

procedure TCentralUserManagement.RemoteUserChangedRemotely(Data: PtrInt);
var
  Aux: PSyncRec;
  Sender: TObject;
  UpdateCtrls: Boolean = False;
begin
  //Sender:=TObject(Data);
  Aux := PSyncRec(Data);
  try
    if (Data <> 0) and Assigned(Aux^.AuthData)
      and (Aux^.AuthData is TJSONObject) then
    begin
      if Assigned(FCachedAuthorizations) then
        FreeAndNil(FCachedAuthorizations);

      FCachedAuthorizations := Aux^.AuthData;
      UpdateCtrls := FUID <> Aux^.UID;
      FUID := Aux^.UID;
      FCurrentUserLogin := Aux^.UserName;
      FCurrentUserName := Aux^.UserName;
      Inc(FCacheUpdateCount);
      //end else begin
      //  FCachedAuthorizations.Clear;
    end;
  finally
    if Assigned(Aux) then
      Dispose(Aux);
  end;

  if UpdateCtrls then
    GetControlSecurityManager.UpdateControls;
end;

procedure TCentralUserManagement.setAuthServer(AValue: string);
begin
  if FAuthServer = AValue then Exit;
  FAuthServer := AValue;
  Logout;
end;

procedure TCentralUserManagement.SetAuthServerPort(AValue: Word);
begin
  if FAuthServerPort = AValue then Exit;
  FAuthServerPort := AValue;
  Logout;
end;

procedure TCentralUserManagement.SetUseCentralUserAsLocalUser(AValue: Boolean);
begin
  if FUseCentralUserAsLocalUser = AValue then
    Exit;
  if [csReading, csLoading] * ComponentState <> [] then
  begin
    FUseCentralUserAsLocalUserLoading := AValue;
    Exit;
  end;
  FUseCentralUserAsLocalUser := AValue;
  GetControlSecurityManager.UpdateControls;
  if AValue then
  begin
    FWait := False;
    FCheckUserChangedThread := TCheckUserChangeThread.Create(True);
    FCheckUserChangedThread.CheckUserChanged := @CheckServerUserChanged;
    FCheckUserChangedThread.OnUserChanged := @RemoteUserChanged;
    FCheckUserChangedThread.FreeOnTerminate := True;
    FCheckUserChangedThread.Start;
  end
  else
  begin
    FCheckUserChangedThread.CheckUserChanged := nil;
    FCheckUserChangedThread.OnUserChanged := nil;
    FCheckUserChangedThread.Terminate;
    FCheckUserChangedThread := nil;
  end;
end;

procedure TCentralUserManagement.UpdateControlSecureState(Data: PtrInt);
begin
  GetControlSecurityManager.UpdateControls;
end;

function TCentralUserManagement.CheckUserAndPassword(User, Pass: UTF8String; out UserID: Integer; LoginAction: Boolean): Boolean;
var
  JObj: TJSONObject;
  UserInfo: UTF8String;
  UserData: TJSONData;
  JUID: TJSONNumber;
begin
  JObj := TJSONObject.Create;
  try
    JObj.Add(_S_USER, User);
    JObj.Add(_S_PASSWORD, Pass);
    if PostMethod(_S_CHECK_USER_PASSWORD, JObj, UserInfo) then
    begin
      try
        UserData := GetJSON(UserInfo);
      except
        Exit(False);
      end;
      try
        if LoginAction and Assigned(FCachedAuthorizations) then
          FreeAndNil(FCachedAuthorizations);

        if (UserData is TJSONObject) and TJSONObject(UserData).Find(_S_UID, JUID) then
        begin
          UserID := JUID.AsInteger;
          if LoginAction and TJSONObject(UserData).Find(_S_AUTHORIZATIONS, FCachedAuthorizations) then
            FCachedAuthorizations := TJSONObject(FCachedAuthorizations.Clone);
          Exit(True);
        end
        else
          Exit(False);
      finally
        if Assigned(UserData) then
          FreeAndNil(UserData);
      end;
    end
    else
      Exit(False);
  finally
    FreeAndNil(JObj);
  end;
end;

function TCentralUserManagement.CanAccess(ASecurityCode: UTF8String; AUID: Integer): Boolean;
var
  JObj: TJSONObject;
  JAux: TJSONObject;
  Aux: UTF8String;
  CentralData: TJSONData;
  JUID: TJSONNumber;
  JLogin: TJSONString;
  ABoolVar: TJSONBoolean;
begin
  if (AUID < 0) and (FUID < 0) then
    Exit(False);

  if (FUID > 0) and (AUID = FUID) and FUseCachedAuthorizations and Assigned(FCachedAuthorizations) then
  begin
    Result := FCachedAuthorizations.Find(ASecurityCode, ABoolVar) or FCachedAuthorizations.Find(Utf8ToAnsi(ASecurityCode), ABoolVar); //TODO Check
    Exit;
  end;

  JObj := TJSONObject.Create;
  try
    JObj.Add(_S_UID, AUID);
    JObj.Add(_S_SECURITY_CODE, ASecurityCode);
    JObj.Add(_S_F_USE_CENTRAL_USER_AS_LOCAL_USER, FUseCentralUserAsLocalUser);
    Result := PostMethod(_S_UID_CAN_ACCESS, JObj, Aux);
    if FUseCentralUserAsLocalUser then
    begin
      try
        CentralData := GetJSON(Aux);
      except
        Exit;
      end;

      if (CentralData is TJSONObject) then
      begin
        if TJSONObject(CentralData).Find(_S_UID, JUID) then
        begin
          if FUID <> JUID.AsInteger then
          begin
            if TJSONObject(CentralData).Find(_S_AUTHORIZATIONS, JAux) then
            begin
              if Assigned(FCachedAuthorizations) then
                FreeAndNil(FCachedAuthorizations);
              FCachedAuthorizations := TJSONObject(JAux.Clone);
            end;

            //delay a Control security refresh
            if Application.Flags * [AppDoNotCallAsyncQueue] = [] then
              Application.QueueAsyncCall(@UpdateControlSecureState, 0);
          end;
          Result := FCachedAuthorizations.Find(ASecurityCode, ABoolVar);
          FUID := JUID.AsInteger;
        end;

        if TJSONObject(CentralData).Find(_S_LOGIN, JLogin) then
        begin
          FCurrentUserLogin := JLogin.AsString;
        end;

        Exit;
      end;
    end;
  finally
    FreeAndNil(JObj);
  end;
end;

procedure TCentralUserManagement.Loaded;
begin
  inherited Loaded;
  SetUseCentralUserAsLocalUser(FUseCentralUserAsLocalUserLoading);
end;

constructor TCentralUserManagement.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWait := False;
  FRaiseExceptOnConnFailure := False;
  FCachedAuthorizations := TJSONObject.Create;
  FValidatedSC := TStringList.Create;
end;

destructor TCentralUserManagement.Destroy;
begin
  if Assigned(FCheckUserChangedThread) then
    SetUseCentralUserAsLocalUser(False);
  if Assigned(Application) then
    Application.RemoveAllHandlersOfObject(Self);
  if Assigned(FValidatedSC) then
    FreeAndNil(FValidatedSC);
  inherited Destroy;
end;

function TCentralUserManagement.GetRegisteredAccessCodes: TStringList;
var
  SecurityCodeList: UTF8String;
  SecCodeJArr: TJSONData;
  JObj: TJSONObject;
  i: Integer;
  Aux: TJSONParser;
begin
  Result := TStringList.Create;
  JObj := TJSONObject.Create;
  try
    if PostMethod(_S_ENUM_SECURITY_CODES, JObj, SecurityCodeList) then
    begin
      try
        Aux := TJSONParser.Create(SecurityCodeList);
        try
          SecCodeJArr := Aux.Parse;
        finally
          FreeAndNil(Aux);
        end;
      except
        Exit;
      end;

      try
        if (SecCodeJArr is TJSONArray) then
        begin
          for i := 0 to SecCodeJArr.Count - 1 do
            Result.Add(SecCodeJArr.Items[i].AsString);
        end
        else
          Exit;
      finally
        if Assigned(SecCodeJArr) then
          FreeAndNil(SecCodeJArr);
      end;
    end
    else
      Exit;
  finally
    FreeAndNil(JObj);
  end;
end;

procedure TCentralUserManagement.Manage;
begin
  raise Exception.Create(_S_MANAGEMENT_NOT_AVAILABLE);
end;

procedure TCentralUserManagement.Logout;
begin
  if Assigned(FCachedAuthorizations) then
    FreeAndNil(FCachedAuthorizations);

  FCachedAuthorizations := TJSONObject.Create;

  inherited Logout;
end;

procedure TCentralUserManagement.ValidateSecurityCode(ASecurityCode: UTF8String);
var
  JObj: TJSONObject;
  Aux: UTF8String;
begin
  if Assigned(FValidatedSC) and (FValidatedSC.IndexOf(ASecurityCode) >= 0) then
    Exit;
  JObj := TJSONObject.Create;
  try
    JObj.Add(_S_SECURITY_CODE, ASecurityCode);
    case PostMethodInt(_S_VALIDADE_SECURITY_CODE, JObj, Aux) of
      0:  if FRaiseExceptOnConnFailure then
            raise Exception.Create(_S_CANNOT_CONNECT_ON_SEC_SERVER);
      200: FValidatedSC.Add(ASecurityCode);
      404: ;
      405: raise Exception.Create(_S_SECURITY_SERVER_REJECTED_SC);
      else
        begin
        end;
    end;
  finally
    FreeAndNil(JObj);
  end;
end;

procedure TCentralUserManagement.RegisterSecurityCode(ASecurityCode: UTF8String);
var
  JObj: TJSONObject;
  Aux: UTF8String;
begin
  if SecurityCodeExists(ASecurityCode) then
    Exit;
  JObj := TJSONObject.Create;
  try
    JObj.Add(_S_SECURITY_CODE, ASecurityCode);
    case PostMethodInt(_S_REGISTER_SECURITY_CODE, JObj, Aux) of
      0:  if FRaiseExceptOnConnFailure then
            raise Exception.Create(_S_CANNOT_CONNECT_ON_SEC_SERVER);
      200: ;
      404: ;
      405: raise Exception.Create(_S_SECURITY_SERVER_CANNOT_REGISTER_SC);
      else
        begin
        end;
    end;
  finally
    FreeAndNil(JObj);
  end;
end;

function TCentralUserManagement.SecurityCodeExists(sc: UTF8String): Boolean;
var
  i: Longint;
begin
  if SecondsBetween(Now, FRegisteredSCLastQuery) > 300 then
  begin
    if Assigned(FRegisteredSC) then
      FreeAndNil(FRegisteredSC);
    FRegisteredSC := GetRegisteredAccessCodes;
    FRegisteredSCLastQuery := Now;
  end;

  Result := Assigned(FRegisteredSC) and (FRegisteredSC.IndexOf(sc) >= 0);
end;

function TCentralUserManagement.CanAccess(ASecurityCode: UTF8String): Boolean;
begin
  Result := CanAccess(ASecurityCode, FUID);
end;

end.

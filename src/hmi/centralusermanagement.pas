unit CentralUserManagement;

{$mode ObjFPC}

interface

uses
  BasicUserManagement, ControlSecurityManager, fpjson, jsonparser, StrUtils,
  Classes, fphttpclient, SysUtils, Forms, fpopenssl, sslsockets, opensslsockets;

type
  TCheckUserChanges = function(out ChangeData: UTF8String): Integer of object;
  TRemoteUserChanged = procedure(aUID: Integer; aUserName: string; AuthData: TJSONObject) of object;

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
    FWait, FUseSSL: Boolean;
    FCacheUpdateCount: Integer;
    FCheckUserChangedThread: TCheckUserChangeThread;
    function CheckServerUserChanged(out ChangeData: UTF8String): Integer;
    function GetCacheUptCount: Integer;
    function PostMethod(aAPIEndpoint: string; aJsonData: TJSONData; var ReturnData: UTF8String): Boolean;
    function PostMethodInt(aAPIEndpoint: string; aJsonData: TJSONData; var ReturnData: UTF8String): Integer;
    procedure RemoteUserChanged(aUID: Integer; aUserName: string; AuthData: TJSONObject);
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
    function CanAccess(sc: UTF8String; aUID: Integer): Boolean; override; overload;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetRegisteredAccessCodes: TStringList; override;
    procedure Manage; override;
    procedure Logout; override;

    //Security codes management
    procedure ValidateSecurityCode(sc: UTF8String); override;
    procedure RegisterSecurityCode(sc: UTF8String); override;
    function SecurityCodeExists(sc: UTF8String): Boolean; override;

    function CanAccess(sc: UTF8String): Boolean; override;
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
  _User = 'user';
  _Password = 'password';
  _checkuserpwd = 'checkuserpwd';
  _enumsecuritycodes = 'enumsecuritycodes';
  _ManagementNotAvailable = 'User management not available, check the user management on the server!';
  _ManagementValidateSC = 'User can not access Security Code';
  _ManagementValidateRSC = 'Security Code is not found';
  _CannotConnectOnSecServer = 'Conneciton to security server failed';
  _SecurityServerRejectedSC = 'Security server has been rejected this security code';
  _SecurityServerCannotRegisterSC = 'Security server cannot register this security code';
  _uidcanaccess = 'uidcanaccess';
  _securitycode = 'securitycode';
  _uid = 'uid';
  _login = 'login';
  _registersecuritycode = 'registersecuritycode';
  _validadesecuritycode = 'validadesecuritycode';
  _FUseCentralUserAsLocalUser = 'UseCentralUserAsLocalUser';
  _authorizations = 'authorizations';
  _userchanged = 'userchanged';
  _username = 'username';

implementation

uses DateUtils, Dialogs;

  { TCheckUserChangeThread }

procedure TCheckUserChangeThread.Execute;
var
  aux: Integer;
  JsonData: UTF8String;
  UserData: TJSONData;
  jAux: TJSONObject;
  jNumber: TJSONNumber;
  jStr: TJSONString;

  procedure DoUserChange(aUID2: Integer; aUserName: string; aData2: TJSONObject);
  begin
    if (not Terminated) and (aux = 200) and Assigned(FOnUserChanged) then
      FOnUserChanged(aUID2, aUserName, aData2);
  end;

begin
  while not Terminated do
  begin
    try
      if Assigned(FCheckUserChanged) then
      begin
        aux := FCheckUserChanged(JsonData);
        if aux = 0 then
        begin
          Sleep(100);
          Continue;
        end;
        try
          UserData := GetJSON(JsonData);
          try
            if (UserData is TJSONObject) and TJSONObject(UserData).Find(_authorizations, jAux) and TJSONObject(UserData).Find(_uid, jNumber) and TJSONObject(UserData).Find(_username, jStr) then
            begin
              DoUserChange(jNumber.AsInteger, jStr.AsString, jAux.Clone as TJSONObject);
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

function TCentralUserManagement.PostMethod(aAPIEndpoint: string; aJsonData: TJSONData; var ReturnData: UTF8String): Boolean;
begin
  Exit(PostMethodInt(aAPIEndpoint, aJsonData, ReturnData) = 200);
end;

function TCentralUserManagement.CheckServerUserChanged(out ChangeData: UTF8String): Integer;
var
  jobj: TJSONObject;
  aux: UTF8String;
begin
  jobj := TJSONObject.Create;
  try
    jobj.Add('wait', FWait); //fist cycle dont have to wait.
    Result := PostMethodInt(_userchanged, jobj, ChangeData);
    FWait := Result = 200;
  finally
    FreeAndNil(jobj);
  end;
end;

function TCentralUserManagement.GetCacheUptCount: Integer;
begin
  Exit(FCacheUpdateCount);
end;

function TCentralUserManagement.PostMethodInt(aAPIEndpoint: string; aJsonData: TJSONData; var ReturnData: UTF8String): Integer;
var
  wc: TFPHTTPClient;
  ms, sl: TStringStream;
begin
  wc := TFPHTTPClient.Create(Self);
  try
    ms := TStringStream.Create(aJsonData.AsJSON);
    try
      ms.Position := 0;
      wc.RequestBody := ms;
      sl := TStringStream.Create;
      try
        try
          wc.Post(ifthen(FUseSSL, 'https', 'http') + '://' + FAuthServer + ':' + FAuthServerPort.ToString + '/' + aAPIEndpoint, sl);
        except
        end;
        sl.Position := 0;
        ReturnData := sl.DataString;
        //Clipboard.AsText:=ReturnData
      finally
        FreeAndNil(sl)
      end;
      Exit(wc.ResponseStatusCode);
    finally
      FreeAndNil(ms);
    end;
  finally
    FreeAndNil(wc);
  end;
end;

procedure TCentralUserManagement.RemoteUserChanged(aUID: Integer; aUserName: string; AuthData: TJSONObject);
var
  aux: PSyncRec;
begin
  new(aux);
  aux^.UserName := aUserName;
  aux^.UID := aUID;
  aux^.AuthData := AuthData;
  if Application.Flags * [AppDoNotCallAsyncQueue] = [] then
  begin
    Application.QueueAsyncCall(@RemoteUserChangedRemotely, PtrInt(aux));
  end;
end;

procedure TCentralUserManagement.RemoteUserChangedRemotely(Data: PtrInt);
var
  aux: PSyncRec;
  Sender: TObject;
  updateCtrls: Boolean = False;
begin
  //Sender:=TObject(Data);
  aux := PSyncRec(Data);
  try
    if (Data <> 0) and Assigned(aux^.AuthData) and (aux^.AuthData is TJSONObject) then
    begin
      if Assigned(FCachedAuthorizations) then
        FreeAndNil(FCachedAuthorizations);

      FCachedAuthorizations := aux^.AuthData;
      updateCtrls := FUID <> aux^.UID;
      FUID := aux^.UID;
      FCurrentUserLogin := aux^.UserName;
      FCurrentUserName := aux^.UserName;
      Inc(FCacheUpdateCount);
      //end else begin
      //  FCachedAuthorizations.Clear;
    end;
  finally
    if Assigned(aux) then
      Dispose(aux);
  end;

  if updateCtrls then
    GetControlSecurityManager.UpdateControls;
  ;

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
  if FUseCentralUserAsLocalUser = AValue then Exit;
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
  jobj: TJSONObject;
  UserInfo: UTF8String;
  UserData: TJSONData;
  aUID: TJSONNumber;
begin
  jobj := TJSONObject.Create;
  try
    jobj.Add(_User, User);
    jobj.Add(_Password, Pass);
    if PostMethod(_checkuserpwd, jobj, UserInfo) then
    begin
      try
        UserData := GetJSON(UserInfo);
      except
        Exit(False);
      end;
      try
        if LoginAction and Assigned(FCachedAuthorizations) then
          FreeAndNil(FCachedAuthorizations);

        if (UserData is TJSONObject) and TJSONObject(UserData).Find(_uid, aUID) then
        begin
          UserID := aUID.AsInteger;
          if LoginAction and TJSONObject(UserData).Find(_authorizations, FCachedAuthorizations) then
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
    FreeAndNil(jobj);
  end;
end;

function TCentralUserManagement.CanAccess(sc: UTF8String; aUID: Integer): Boolean;
var
  jobj, jAux: TJSONObject;
  aux: UTF8String;
  CentralData: TJSONData;
  jUID: TJSONNumber;
  jLogin: TJSONString;
  aBoolVar: TJSONBoolean;
begin
  if (aUID < 0) and (FUID < 0) then
    Exit(False);

  if (FUID > 0) and (aUID = FUID) and FUseCachedAuthorizations and Assigned(FCachedAuthorizations) then
  begin
    Result := FCachedAuthorizations.Find(sc, aBoolVar) or FCachedAuthorizations.Find(Utf8ToAnsi(sc), aBoolVar); //TODO Check
    Exit;
  end;

  jobj := TJSONObject.Create;
  try
    jobj.Add(_uid, aUID);
    jobj.Add(_securitycode, sc);
    jobj.Add(_FUseCentralUserAsLocalUser, FUseCentralUserAsLocalUser);
    Result := PostMethod(_uidcanaccess, jobj, aux);
    if FUseCentralUserAsLocalUser then
    begin
      try
        CentralData := GetJSON(aux);
      except
        Exit;
      end;

      if (CentralData is TJSONObject) then
      begin
        if TJSONObject(CentralData).Find(_uid, jUID) then
        begin
          if FUID <> jUID.AsInteger then
          begin
            if TJSONObject(CentralData).Find(_authorizations, jAux) then
            begin
              if Assigned(FCachedAuthorizations) then
                FreeAndNil(FCachedAuthorizations);
              FCachedAuthorizations := TJSONObject(jAux.Clone);
            end;

            //delay a Control security refresh
            if Application.Flags * [AppDoNotCallAsyncQueue] = [] then
              Application.QueueAsyncCall(@UpdateControlSecureState, 0);
          end;
          Result := FCachedAuthorizations.Find(sc, aBoolVar);
          FUID := jUID.AsInteger;
        end;

        if TJSONObject(CentralData).Find(_login, jLogin) then
        begin
          FCurrentUserLogin := jLogin.AsString;
        end;

        Exit;
      end;
    end;
  finally
    FreeAndNil(jobj);
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
  jobj: TJSONObject;
  i: Integer;
  aux: TJSONParser;
begin
  Result := TStringList.Create;
  jobj := TJSONObject.Create;
  try
    if PostMethod(_enumsecuritycodes, jobj, SecurityCodeList) then
    begin
      try
        aux := TJSONParser.Create(SecurityCodeList);
        try
          SecCodeJArr := aux.Parse;
        finally
          FreeAndNil(aux);
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
    FreeAndNil(jobj);
  end;
end;

procedure TCentralUserManagement.Manage;
begin
  raise Exception.Create(_ManagementNotAvailable);
end;

procedure TCentralUserManagement.Logout;
begin
  if Assigned(FCachedAuthorizations) then
    FreeAndNil(FCachedAuthorizations);

  FCachedAuthorizations := TJSONObject.Create;

  inherited Logout;
end;

procedure TCentralUserManagement.ValidateSecurityCode(sc: UTF8String);
var
  jobj: TJSONObject;
  aux: UTF8String;
begin
  if Assigned(FValidatedSC) and (FValidatedSC.IndexOf(sc) >= 0) then Exit;

  jobj := TJSONObject.Create;
  try
    jobj.Add(_securitycode, sc);
    case PostMethodInt(_validadesecuritycode, jobj, aux) of
      0: if FRaiseExceptOnConnFailure then
          raise Exception.Create(_CannotConnectOnSecServer);
      200: FValidatedSC.Add(sc);
      404: ;
      405:
        raise Exception.Create(_SecurityServerRejectedSC);
      else
      begin

      end;
    end;
  finally
    FreeAndNil(jobj);
  end;
end;

procedure TCentralUserManagement.RegisterSecurityCode(sc: UTF8String);
var
  jobj: TJSONObject;
  aux: UTF8String;
begin
  if SecurityCodeExists(sc) then
    Exit;
  jobj := TJSONObject.Create;
  try
    jobj.Add(_securitycode, sc);
    case PostMethodInt(_registersecuritycode, jobj, aux) of
      0:
        if FRaiseExceptOnConnFailure then
          raise Exception.Create(_CannotConnectOnSecServer);
      200: ;
      404: ;
      405:
        raise Exception.Create(_SecurityServerCannotRegisterSC);
      else
      begin

      end;
    end;
  finally
    FreeAndNil(jobj);
  end;
end;

function TCentralUserManagement.SecurityCodeExists(sc: UTF8String): Boolean;
var
  c: Longint;
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

function TCentralUserManagement.CanAccess(sc: UTF8String): Boolean;
begin
  Result := CanAccess(sc, FUID);
end;

end.

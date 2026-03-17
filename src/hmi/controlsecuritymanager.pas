unit ControlSecurityManager;

interface

uses
  Classes, SysUtils, HMITypes, ActnList, PLCTag, BasicUserManagement, Controls,
  LCLType;

type

  { TControlSecurityManager }

  TControlSecurityManager = class(TComponent)
  private
    FControls: array of IHMIInterface;
    FUserManagement: TBasicUserManagement;

    procedure SetUserManagement(AUserManagement: TBasicUserManagement);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Login(Userlogin, Userpassword: UTF8String; var UID: Integer): Boolean; overload;
    function Login: Boolean; overload;

    procedure Logout;
    procedure Manage;
    function GetCurrentUserlogin: UTF8String;
    function GetCurrentUserName: UTF8String;
    procedure TryAccess(ASecurityCode: UTF8String);
    function RegisterControl(Control: IHMIInterface): Boolean;
    procedure UnRegisterControl(Control: IHMIInterface);
    procedure UpdateControls;
    function CanAccess(ASecurityCode: UTF8String): Boolean;
    procedure ValidateSecurityCode(ASecurityCode: UTF8String);
    procedure RegisterSecurityCode(ASecurityCode: UTF8String);
    procedure UnregisterSecurityCode(ASecurityCode: UTF8String);
    function SecurityCodeExists(ASecurityCode: UTF8String): Boolean;
    function GetRegisteredAccessCodes: TStringList;
    function CheckIfUserIsAllowed(ASecurityCode: UTF8String; RequireUserLogin: Boolean; var Userlogin: UTF8String; const UserHint: string): Boolean;
  published
    property UserManagement: TBasicUserManagement read FUserManagement write SetUserManagement;
  end;

  //actions...

  { TPascalSCADACheckSpecialTokenAction }

  TPascalSCADACheckSpecialTokenAction = class(TAction)
  private
    FAuthorizedBy: UTF8String;
    FRequireLoginAlways: Boolean;
    FSecurityCode: UTF8String;
    procedure SetSecurityCode(AValue: UTF8String);
  public
    function Execute: Boolean; override;
    function HandlesTarget({%H-}Target: TObject): Boolean; override;
  published
    property AuthorizedBy: UTF8String read FAuthorizedBy;
    property SecurityCode: UTF8String read FSecurityCode write SetSecurityCode;
    property RequireLoginAlways: Boolean read FRequireLoginAlways write FRequireLoginAlways;
  end;

  { TPascalSCADAUserManagementAction }

  TPascalSCADAUserManagementAction = class(TAction, IHMIInterface)
  private
    FRegInSecMan: Boolean;
    FDisableIfNotAuthorized: Boolean;
    procedure SetDisableIfNotAuthorized(AValue: Boolean);
  protected
    FEnabled, FAccessAllowed: Boolean;
    FSecurityCode: UTF8String;

    procedure SetEnabled(AValue: Boolean); virtual;

    function GetControlSecurityCode: UTF8String; virtual;
    procedure MakeUnsecure; virtual;
    procedure CanBeAccessed(A: Boolean); virtual;

    //unused procedures
    procedure SetHMITag({%H-}t: TPLCTag);
    function GetHMITag: TPLCTag;
    procedure Loaded; override;
  public
    function HandlesTarget({%H-}Target: TObject): Boolean; override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property DisableIfNotAuthorized: Boolean read FDisableIfNotAuthorized write SetDisableIfNotAuthorized default True;
  end;

  { TPascalSCADALoginAction }

  TPascalSCADALoginAction = class(TPascalSCADAUserManagementAction)
  protected
    procedure CanBeAccessed({%H-}A: Boolean); override;
  public
    procedure UpdateTarget({%H-}Target: TObject); override;
    procedure ExecuteTarget({%H-}Target: TObject); override;
  end;

  { TPascalSCADALogoutAction }

  TPascalSCADALogoutAction = class(TPascalSCADAUserManagementAction)
  protected
    procedure CanBeAccessed({%H-}A: Boolean); override;
  public
    procedure UpdateTarget({%H-}Target: TObject); override;
    procedure ExecuteTarget({%H-}Target: TObject); override;
  end;

  { TPascalSCADALogin_LogoutAction }

  TPascalSCADALogin_LogoutAction = class(TPascalSCADAUserManagementAction)
  private
    FAfterLogin: TNotifyEvent;
    FBeforeLogin: TNotifyEvent;
    FWithUserLoggedInImageIndex, FWithoutUserLoggedInImageIndex: Longint;
    FWithUserLoggedInCaption, FWithoutUserLoggedInCaption: TCaption;
    FWithUserLoggedInHint, FWithoutUserLoggedInHint: TTranslateString;
    function GetCurrentCaption: TCaption;
    function GetCurrentHintMessage: TTranslateString;
    function GetCurrentImageIndex: Longint;
    procedure SetWithUserLoggedInCaption(const AValue: TCaption);
    procedure SetWithUserLoggedInHint(const AValue: TTranslateString);
    procedure SetWithUserLoggedInImageIndex(const AValue: Longint);
    procedure SetWithoutUserLoggedInCaption(const AValue: TCaption);
    procedure SetWithoutUserLoggedInHint(const AValue: TTranslateString);
    procedure SetWithoutUserLoggedInImageIndex(const AValue: Longint);
    procedure UpdateMyState;
  protected
    procedure CanBeAccessed({%H-}A: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure UpdateTarget({%H-}Target: TObject); override;
    procedure ExecuteTarget({%H-}Target: TObject); override;
  published
    property Caption: TCaption read GetCurrentCaption;
    property Hint: TTranslateString read GetCurrentHintMessage;
    property ImageIndex: Longint read GetCurrentImageIndex;
    property WithUserLoggedInCaption: TCaption read FWithUserLoggedInCaption write SetWithUserLoggedInCaption;
    property WithUserLoggedInHint: TTranslateString read FWithUserLoggedInHint write SetWithUserLoggedInHint;
    property WithUserLoggedInImageIndex: Longint read FWithUserLoggedInImageIndex write SetWithUserLoggedInImageIndex;

    property WithoutUserLoggedInCaption: TCaption read FWithoutUserLoggedInCaption write SetWithoutUserLoggedInCaption;
    property WithoutUserLoggedInHint: TTranslateString read FWithoutUserLoggedInHint write SetWithoutUserLoggedInHint;
    property WithoutUserLoggedInImageIndex: Longint read FWithoutUserLoggedInImageIndex write SetWithoutUserLoggedInImageIndex;
    property BeforeLogin: TNotifyEvent read FBeforeLogin write FBeforeLogin;
    property AfterLogin: TNotifyEvent read FAfterLogin write FAfterLogin;
  end;

  { TPascalSCADAManageUsersAction }

  TPascalSCADAManageUsersAction = class(TPascalSCADAUserManagementAction)
  protected
    procedure CanBeAccessed({%H-}A: Boolean); override;
  public
    procedure UpdateTarget({%H-}Target: TObject); override;
    procedure ExecuteTarget({%H-}Target: TObject); override;
  end;

  { TPascalSCADASecureAction }

  TPascalSCADASecureAction = class(TPascalSCADAUserManagementAction)
  protected
    procedure SetSecurityCode(ASecurityCode: UTF8String);
  public
    procedure UpdateTarget(Target: TObject); override;
    function Execute: Boolean; override;
  published
    {$IFDEF PORTUGUES}
    //: Codigo de segurança que libera acesso ao controle
    {$ELSE}
    //: Security code that allows access to control.
    {$ENDIF}
    property SecurityCode: UTF8String read FSecurityCode write SetSecurityCode;
  end;

function GetControlSecurityManager: TControlSecurityManager;

implementation

uses hsstrings, Dialogs;

  { TPascalSCADACheckSpecialTokenAction }

procedure TPascalSCADACheckSpecialTokenAction.SetSecurityCode(AValue: UTF8String);
begin
  if FSecurityCode = AValue then Exit;

  if Trim(AValue) <> '' then
    with GetControlSecurityManager do
    begin
      ValidateSecurityCode(AValue);
      if not SecurityCodeExists(AValue) then
        RegisterSecurityCode(AValue);
    end;

  FSecurityCode := AValue;
end;

function TPascalSCADACheckSpecialTokenAction.Execute: Boolean;
begin
  if GetControlSecurityManager.CheckIfUserIsAllowed(FSecurityCode, FRequireLoginAlways, FAuthorizedBy, Hint) then
    Result := inherited Execute
  else
    Result := False;
end;

function TPascalSCADACheckSpecialTokenAction.HandlesTarget(Target: TObject): Boolean;
begin
  Result := True;
end;

{ TPascalSCADALogin_LogoutAction }

function TPascalSCADALogin_LogoutAction.GetCurrentCaption: TCaption;
begin
  Result := inherited Caption;
end;

function TPascalSCADALogin_LogoutAction.GetCurrentHintMessage: TTranslateString;
begin
  Result := inherited Hint;
end;

function TPascalSCADALogin_LogoutAction.GetCurrentImageIndex: Longint;
begin
  Result := inherited ImageIndex;
end;

procedure TPascalSCADALogin_LogoutAction.SetWithUserLoggedInCaption(const AValue: TCaption);
begin
  if FWithUserLoggedInCaption = AValue then Exit;
  FWithUserLoggedInCaption := AValue;
  UpdateMyState;
end;

procedure TPascalSCADALogin_LogoutAction.SetWithUserLoggedInHint(const AValue: TTranslateString);
begin
  if FWithUserLoggedInHint = AValue then Exit;
  FWithUserLoggedInHint := AValue;
  UpdateMyState;
end;

procedure TPascalSCADALogin_LogoutAction.SetWithUserLoggedInImageIndex(const AValue: Longint);
begin
  if FWithUserLoggedInImageIndex = AValue then Exit;
  FWithUserLoggedInImageIndex := AValue;
  UpdateMyState;
end;

procedure TPascalSCADALogin_LogoutAction.SetWithoutUserLoggedInCaption(const AValue: TCaption);
begin
  if FWithoutUserLoggedInCaption = AValue then Exit;
  FWithoutUserLoggedInCaption := AValue;
  UpdateMyState;
end;

procedure TPascalSCADALogin_LogoutAction.SetWithoutUserLoggedInHint(const AValue: TTranslateString);
begin
  if FWithoutUserLoggedInHint = AValue then Exit;
  FWithoutUserLoggedInHint := AValue;
  UpdateMyState;
end;

procedure TPascalSCADALogin_LogoutAction.SetWithoutUserLoggedInImageIndex(const AValue: Longint);
begin
  if FWithoutUserLoggedInImageIndex = AValue then Exit;
  FWithoutUserLoggedInImageIndex := AValue;
  UpdateMyState;
end;

procedure TPascalSCADALogin_LogoutAction.UpdateMyState;
begin
  if GetControlSecurityManager.UserManagement <> nil then
    if TBasicUserManagement(GetControlSecurityManager.UserManagement).UserLogged then
    begin
      inherited Caption := FWithUserLoggedInCaption;
      inherited Hint := FWithUserLoggedInHint;
      inherited ImageIndex := FWithUserLoggedInImageIndex;
    end
    else
    begin
      inherited Caption := FWithoutUserLoggedInCaption;
      inherited Hint := FWithoutUserLoggedInHint;
      inherited ImageIndex := FWithoutUserLoggedInImageIndex;
    end;
end;

procedure TPascalSCADALogin_LogoutAction.CanBeAccessed(A: Boolean);
begin
  inherited CanBeAccessed(True); //it can be accessed always.
  UpdateMyState;
end;

constructor TPascalSCADALogin_LogoutAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWithUserLoggedInImageIndex := -1;
  FWithoutUserLoggedInImageIndex := -1;
end;

procedure TPascalSCADALogin_LogoutAction.UpdateTarget(Target: TObject);
begin
  CanBeAccessed(True);
end;

procedure TPascalSCADALogin_LogoutAction.ExecuteTarget(Target: TObject);
begin
  if GetControlSecurityManager.UserManagement <> nil then
    if TBasicUserManagement(GetControlSecurityManager.UserManagement).UserLogged then
    begin
      GetControlSecurityManager.Logout;
    end
    else
    begin
      if Assigned(FBeforeLogin) then
        FBeforeLogin(Self);

      GetControlSecurityManager.Login;

      if Assigned(FAfterLogin) then
        FAfterLogin(Self);
    end;
  UpdateMyState;
end;

constructor TControlSecurityManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUserManagement := nil;
  SetLength(FControls, 0);
end;

destructor TControlSecurityManager.Destroy;
begin
  if Length(FControls) > 0 then
    writeln('FIX-ME: ', SSecurityControlBusy, ' ', {$i %FILE%}, ':', {$i %LINE%});
  inherited Destroy;
end;

function TControlSecurityManager.Login(Userlogin, Userpassword: UTF8String; var UID: Integer): Boolean; overload;
begin
  if FUserManagement <> nil then
    Result := TBasicUserManagement(FUserManagement).Login(Userlogin, Userpassword, UID)
  else
    Result := False;
end;

function TControlSecurityManager.Login: Boolean;
begin
  if FUserManagement <> nil then
    Result := TBasicUserManagement(FUserManagement).Login
  else
    Result := False;
end;

procedure TControlSecurityManager.Logout;
begin
  if FUserManagement <> nil then
    TBasicUserManagement(FUserManagement).Logout;
end;

procedure TControlSecurityManager.Manage;
begin
  if FUserManagement <> nil then
    TBasicUserManagement(FUserManagement).Manage;
end;

function TControlSecurityManager.GetCurrentUserlogin: UTF8String;
begin
  Result := '';
  if FUserManagement <> nil then
    Result := TBasicUserManagement(FUserManagement).CurrentUserLogin;
end;

function TControlSecurityManager.GetCurrentUserName: UTF8String;
begin
  Result := '';
  if FUserManagement <> nil then
    Result := TBasicUserManagement(FUserManagement).CurrentUserName;
end;

procedure TControlSecurityManager.TryAccess(ASecurityCode: UTF8String);
begin
  if FUserManagement <> nil then
    if not TBasicUserManagement(FUserManagement).CanAccess(ASecurityCode) then
      raise Exception.Create(SAccessDenied);
end;

procedure TControlSecurityManager.SetUserManagement(AUserManagement: TBasicUserManagement);
begin
  if (AUserManagement <> nil) and (not (AUserManagement is TBasicUserManagement)) then
    raise Exception.Create(SInvalidUserManager);

  if (AUserManagement <> nil) and (FUserManagement <> nil) then
    raise Exception.Create(SUserManagementIsSet);

  FUserManagement := AUserManagement;
  UpdateControls;
end;

function TControlSecurityManager.RegisterControl(Control: IHMIInterface): Boolean;
var
  ALast: Longint;
begin
  Result := False;
  try
    ALast := Length(FControls);
    SetLength(FControls, ALast + 1);
    FControls[ALast] := Control;
    Result := True;
  except
  end;
end;

procedure TControlSecurityManager.UnRegisterControl(Control: IHMIInterface);
var
  i: Longint;
  h: Longint;
  Found: Boolean;
begin
  h := High(FControls);
  for i := 0 to h do
    if FControls[i] = Control then
    begin
      FControls[i] := FControls[h];
      SetLength(FControls, h);
      Break;
      Found := True;
    end;

  {$IFNDEF WINDOWS}
  if not found then
    writeln('FIX-ME: Control not found! ', {$i %FILE%}, ':', {$i %LINE%});
  {$ENDIF}
end;

procedure TControlSecurityManager.UpdateControls;
var
  i: Longint;
begin
  for i := 0 to High(FControls) do
    FControls[i].CanBeAccessed(CanAccess(FControls[i].GetControlSecurityCode));
end;

function TControlSecurityManager.CanAccess(ASecurityCode: UTF8String): Boolean;
begin
  Result := True;

  if ASecurityCode = '' then Exit;

  if (FUserManagement <> nil) and (FUserManagement is TBasicUserManagement) then
    Result := TBasicUserManagement(FUserManagement).CanAccess(ASecurityCode);
end;

procedure TControlSecurityManager.ValidateSecurityCode(ASecurityCode: UTF8String);
begin
  if FUserManagement <> nil then
    TBasicUserManagement(FUserManagement).ValidateSecurityCode(ASecurityCode);
end;

procedure TControlSecurityManager.RegisterSecurityCode(ASecurityCode: UTF8String);
begin
  if FUserManagement <> nil then
    TBasicUserManagement(FUserManagement).RegisterSecurityCode(ASecurityCode);
end;

procedure TControlSecurityManager.UnregisterSecurityCode(ASecurityCode: UTF8String);
var
  BeingUsed: Boolean;
  i: Longint;
begin
  BeingUsed := False;
  for i := 0 to Length(FControls) do
    BeingUsed := BeingUsed or (FControls[i].GetControlSecurityCode = ASecurityCode);

  if BeingUsed then
  begin
    case MessageDlg(SSecurityCodeBusyWantRemove, mtConfirmation, mbYesNoCancel, 0) of
      mrYes:  for i := 0 to Length(FControls) do
                if FControls[i].GetControlSecurityCode = ASecurityCode then
                  FControls[i].MakeUnsecure;
      mrNo: raise Exception.Create(SSecurityCodeStillBusy);
      mrCancel: Exit;
    end;
  end;

  if FUserManagement <> nil then
    TBasicUserManagement(FUserManagement).UnregisterSecurityCode(ASecurityCode);
end;

function TControlSecurityManager.SecurityCodeExists(ASecurityCode: UTF8String): Boolean;
begin
  Result := False;
  if FUserManagement <> nil then
    Result := TBasicUserManagement(FUserManagement).SecurityCodeExists(ASecurityCode);
end;

function TControlSecurityManager.GetRegisteredAccessCodes: TStringList;
begin
  if FUserManagement = nil then
  begin
    Result := TStringList.Create;
  end
  else
    Result := TBasicUserManagement(FUserManagement).GetRegisteredAccessCodes;
end;

function TControlSecurityManager.CheckIfUserIsAllowed(ASecurityCode: UTF8String; RequireUserLogin: Boolean; var Userlogin: UTF8String; const UserHint: string): Boolean;
begin
  Result := (Trim(ASecurityCode) = '');
  if FUserManagement <> nil then
    Result := TBasicUserManagement(FUserManagement).CheckIfUserIsAllowed(ASecurityCode, RequireUserLogin, Userlogin, UserHint);
end;

////////////////////////////////////////////////////////////////////////////////
//PascaSCADA user management Standart actions
////////////////////////////////////////////////////////////////////////////////

procedure TPascalSCADAUserManagementAction.SetDisableIfNotAuthorized(AValue: Boolean);
begin
  if FDisableIfNotAuthorized = AValue then Exit;
  FDisableIfNotAuthorized := AValue;
  CanBeAccessed(GetControlSecurityManager.CanAccess(FSecurityCode));
end;

procedure TPascalSCADAUserManagementAction.SetEnabled(AValue: Boolean);
begin
  if FEnabled = AValue then Exit;
  FEnabled := AValue;
  inherited Enabled := FEnabled and FAccessAllowed;
end;

function TPascalSCADAUserManagementAction.GetControlSecurityCode: UTF8String;
begin
  Result := FSecurityCode;
end;

procedure TPascalSCADAUserManagementAction.MakeUnsecure;
begin
  FSecurityCode := '';
  CanBeAccessed(True);
end;

procedure TPascalSCADAUserManagementAction.CanBeAccessed(A: Boolean);
begin
  FAccessAllowed := A or (FDisableIfNotAuthorized = False);
  inherited Enabled := FEnabled and FAccessAllowed;
end;

procedure TPascalSCADAUserManagementAction.SetHMITag(t: TPLCTag);
begin
  //does nothing
end;

function TPascalSCADAUserManagementAction.GetHMITag: TPLCTag;
begin
  Result := nil;
  //does nothing
end;

procedure TPascalSCADAUserManagementAction.Loaded;
begin
  inherited Loaded;
  CanBeAccessed(GetControlSecurityManager.CanAccess(GetControlSecurityCode));
end;

function TPascalSCADAUserManagementAction.HandlesTarget(Target: TObject): Boolean;
begin
  Result := True;
end;

constructor TPascalSCADAUserManagementAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRegInSecMan := GetControlSecurityManager.RegisterControl(Self as IHMIInterface);
  if not FRegInSecMan then
  begin
    {$IFNDEF WINDOWS}
    writeln('FIX-ME: Failed to register class ', ClassName, ' instace with name="', Name, '" in the ControlSecurityManager?', {$i %FILE%}, ':', {$i %LINE%});
    {$ENDIF}
  end;
  FEnabled := True;
  FDisableIfNotAuthorized := True;
end;

destructor TPascalSCADAUserManagementAction.Destroy;
begin
  if FRegInSecMan then
    GetControlSecurityManager.UnRegisterControl(Self as IHMIInterface)
  else
  begin
    {$IFNDEF WINDOWS}
    writeln('FIX-ME: Why class ', ClassName, ', instace name="', Name, '" ins''t registered in ControlSecurityManager?', {$i %FILE%}, ':', {$i %LINE%});
    {$ENDIF}
  end;
  inherited Destroy;
end;

////////////////////////////////////////////////////////////////////////////////
//PascaSCADA Login Action
////////////////////////////////////////////////////////////////////////////////

procedure TPascalSCADALoginAction.CanBeAccessed(A: Boolean);
begin
  if GetControlSecurityManager.UserManagement <> nil then
    with GetControlSecurityManager.UserManagement as TBasicUserManagement do
      inherited CanBeAccessed(not UserLogged);
end;

procedure TPascalSCADALoginAction.UpdateTarget(Target: TObject);
begin
  CanBeAccessed(True);
end;

procedure TPascalSCADALoginAction.ExecuteTarget(Target: TObject);
begin
  GetControlSecurityManager.Login;
end;

////////////////////////////////////////////////////////////////////////////////
//PascaSCADA Logout Action
////////////////////////////////////////////////////////////////////////////////

procedure TPascalSCADALogoutAction.CanBeAccessed(A: Boolean);
begin
  if GetControlSecurityManager.UserManagement <> nil then
    with GetControlSecurityManager.UserManagement as TBasicUserManagement do
      inherited CanBeAccessed(UserLogged);
end;

procedure TPascalSCADALogoutAction.UpdateTarget(Target: TObject);
begin
  CanBeAccessed(True);
end;

procedure TPascalSCADALogoutAction.ExecuteTarget(Target: TObject);
begin
  GetControlSecurityManager.Logout;
end;

////////////////////////////////////////////////////////////////////////////////
//PascaSCADA User management action
////////////////////////////////////////////////////////////////////////////////

procedure TPascalSCADAManageUsersAction.CanBeAccessed(A: Boolean);
begin
  if GetControlSecurityManager.UserManagement <> nil then
    with GetControlSecurityManager.UserManagement as TBasicUserManagement do
      inherited CanBeAccessed(UserLogged);
end;

procedure TPascalSCADAManageUsersAction.UpdateTarget(Target: TObject);
begin
  CanBeAccessed(False);
end;

procedure TPascalSCADAManageUsersAction.ExecuteTarget(Target: TObject);
begin
  GetControlSecurityManager.Manage;
end;

////////////////////////////////////////////////////////////////////////////////
//PascaSCADA General purpose secure action
////////////////////////////////////////////////////////////////////////////////

procedure TPascalSCADASecureAction.UpdateTarget(Target: TObject);
begin
  CanBeAccessed(FAccessAllowed);
  inherited UpdateTarget(Target);
end;

function TPascalSCADASecureAction.Execute: Boolean;
begin
  if GetControlSecurityManager.CanAccess(FSecurityCode) then
    Result := inherited Execute
  else
  begin
    MessageDlg('Error', 'Access denied', mtInformation, [mbOK], 0);
    Result := False;
  end;
end;

procedure TPascalSCADASecureAction.SetSecurityCode(ASecurityCode: UTF8String);
begin
  if Trim(ASecurityCode) = '' then
    Self.CanBeAccessed(True)
  else
    with GetControlSecurityManager do
    begin
      ValidateSecurityCode(ASecurityCode);
      if not SecurityCodeExists(ASecurityCode) then
        RegisterSecurityCode(ASecurityCode);

      Self.CanBeAccessed(CanAccess(ASecurityCode));
    end;

  FSecurityCode := ASecurityCode;
end;

////////////////////////////////////////////////////////////////////////////////
//END PascaSCADA user management Standart actions
////////////////////////////////////////////////////////////////////////////////

var
  QPascalControlSecurityManager: TControlSecurityManager;

function GetControlSecurityManager: TControlSecurityManager;
begin
  Result := QPascalControlSecurityManager;
end;

initialization
  QPascalControlSecurityManager := TControlSecurityManager.Create(nil);

finalization
  QPascalControlSecurityManager.Destroy;

end.

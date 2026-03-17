unit BasicUserManagement;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, ExtCtrls, Dialogs, Controls, Forms, StdCtrls, Graphics,
  usrmgnt_login, ChipCardReader;

type
  TVKType = (vktNone, vktAlphaNumeric, vktNumeric);

  TUserChangedEvent = procedure(Sender: TObject; const OldUsername, NewUserName: UTF8String) of object;

  { TBasicUserManagement }

  TBasicUserManagement = class(TComponent)
  private
    FChipCardReader: TChipCardReader;

    procedure CheckIfCardHasBeenRemoved(Sender: TObject);
    procedure ChipCardReaderProc(Data: PtrInt);
    procedure SetChipCardReader(AValue: TChipCardReader);
    procedure WarningCanBeClosed(Sender: TObject; var CanClose: Boolean);
  protected
    FLoggedUser: Boolean;
    FCurrentUserName: UTF8String;
    FCurrentUserLogin: UTF8String;
    FUID: Integer;
    FLoggedSince: TDateTime;
    FInactiveTimeOut: Cardinal;
    FLoginRetries: Cardinal;
    FFrozenTime: Cardinal;
    FVirtualKeyboardType: TVKType;

    FSuccessfulLogin: TNotifyEvent;
    FFailureLogin: TNotifyEvent;
    FUserChanged: TUserChangedEvent;

    FRegisteredSecurityCodes: TStringList;

    LoginDialogForm: TpsHMIfrmUserAuthentication;

    function GetLoginTime: TDateTime;
    procedure SetInactiveTimeOut({%H-}ATimeout: Cardinal);
    procedure UnfreezeLogin(Sender: TObject);
    function GetUID: Integer;
  protected
    procedure DoUserChanged; virtual;

    procedure DoSuccessfulLogin; virtual;
    procedure DoFailureLogin; virtual;

    function CheckUserAndPassword({%H-}User, {%H-}Pass: UTF8String; out {%H-}UserID: Integer; {%H-}LoginAction: Boolean): Boolean; virtual;
    function CheckUserChipCard(AChipCardCode: UTF8String; var UserLogin: UTF8String; var {%H-}UserID: Integer; {%H-}LoginAction: Boolean): Boolean; virtual;

    function GetLoggedUser: Boolean; virtual;
    function GetCurrentUserName: UTF8String; virtual;
    function GetCurrentUserLogin: UTF8String; virtual;

    //read only properties.
    property LoggedSince: TDateTime read GetLoginTime;

    //read-write properties.
    //property VirtualKeyboardType:TVKType read FVirtualKeyboardType write FVirtualKeyboardType;
    property InactiveTimeout: Cardinal read FInactiveTimeOut write SetInactiveTimeOut;
    property LoginRetries: Cardinal read FLoginRetries write FLoginRetries;
    property LoginFrozenTime: Cardinal read FFrozenTime write FFrozenTime;

    property SuccessfulLogin: TNotifyEvent read FSuccessfulLogin write FSuccessfulLogin;
    property FailureLogin: TNotifyEvent read FFailureLogin write FFailureLogin;
    property UserChanged: TUserChangedEvent read FUserChanged write FUserChanged;
    function CanAccess({%H-}ASecurityCodes: UTF8String; {%H-}AUID: Integer): Boolean; virtual; overload;
    property ChipCardReader: TChipCardReader read FChipCardReader write SetChipCardReader;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure WaitForEmptyChipCard; virtual;
    procedure StartDelayedChipCardRead;
    procedure StopDelayedChipCardRead;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Login: Boolean; virtual; overload;
    function Login(UserLogin, UserPassword: UTF8String; var UID: Integer): Boolean; virtual;
    procedure Logout; virtual;
    procedure Manage; virtual;

    //Security codes management
    procedure ValidateSecurityCode({%H-}ASecurityCodes: UTF8String); virtual;
    function SecurityCodeExists({%H-}ASecurityCodes: UTF8String): Boolean; virtual;
    procedure RegisterSecurityCode({%H-}ASecurityCodes: UTF8String); virtual;
    procedure UnregisterSecurityCode({%H-}ASecurityCodes: UTF8String); virtual;

    function CanAccess({%H-}ASecurityCodes: UTF8String): Boolean; virtual;
    function GetRegisteredAccessCodes: TStringList; virtual;

    function CheckIfUserIsAllowed({%H-}ASecurityCodes: UTF8String; RequireUserLogin: Boolean; var UserLogin: UTF8String; const UserHint: UTF8String): Boolean; virtual;

    //read only properties.
    property UID: Integer read GetUID;
    property UserLogged: Boolean read GetLoggedUser;
    property CurrentUserName: UTF8String read GetCurrentUserName;
    property CurrentUserLogin: UTF8String read GetCurrentUserLogin;
  end;


const
  mrOKChipCard = mrLast + 1;


implementation


uses
  ControlSecurityManager, hsstrings;


constructor TBasicUserManagement.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  if GetControlSecurityManager.UserManagement = nil then
    GetControlSecurityManager.UserManagement := Self
  else
    raise Exception.Create(SUserManagementIsSet);

  FLoggedUser := False;
  FCurrentUserName := '';
  FCurrentUserLogin := '';
  FUID := -1;
  FLoggedSince := Now;

  FRegisteredSecurityCodes := TStringList.Create;
end;

destructor TBasicUserManagement.Destroy;
begin
  Application.RemoveAllHandlersOfObject(Self);
  if GetControlSecurityManager.UserManagement = Self then
    GetControlSecurityManager.UserManagement := nil;

  if FRegisteredSecurityCodes <> nil then
    FRegisteredSecurityCodes.Destroy;
  inherited Destroy;
end;

function TBasicUserManagement.Login: Boolean;
var
  FrozenTimer: TTimer;
  Retries: Longint;
  Aborted: Boolean;
  LoggedIn: Boolean;
  AUserIDCC: Integer;
  PreferredWidth: Integer;
  PreferredHeight: Integer;
  Res: Integer;
  AUserIDDlg: Integer;
  AUserLogin: UTF8String;
begin
  if Assigned(LoginDialogForm) then
  begin
    LoginDialogForm.ShowOnTop;
    Exit;
  end;

  FrozenTimer := TTimer.Create(nil);
  FrozenTimer.Enabled := False;
  FrozenTimer.Interval := LoginFrozenTime;
  FrozenTimer.Tag := 1; //login
  FrozenTimer.OnTimer := @UnfreezeLogin;

  Retries := 0;
  Aborted := False;
  LoggedIn := False;
  Result := False;

  LoginDialogForm := TpsHMIfrmUserAuthentication.Create(nil);
  try
    LoginDialogForm.edtusername.Text := '';
    LoginDialogForm.FocusControl := fcUserName;

    LoginDialogForm.AutoSize := True;
    LoginDialogForm.HandleNeeded;
    LoginDialogForm.GetPreferredSize(PreferredWidth, PreferredHeight);

    while (not LoggedIn) and (not Aborted) do
    begin
      LoginDialogForm.edtPassword.Text := '';
      try
        if Assigned(FChipCardReader) then
        begin
          if not FChipCardReader.ChipCardReady then
            FChipCardReader.InitializeChipCard;
          if FChipCardReader.ChipCardReady then
          begin
            WaitForEmptyChipCard;
            StartDelayedChipCardRead;
          end;
        end;

        Res := LoginDialogForm.ShowModal;
        if Res in [mrOk, mrOKChipCard] then
        begin
          if ((Res = mrOk) and CheckUserAndPassword(LoginDialogForm.edtusername.Text, LoginDialogForm.edtPassword.Text, AUserIDDlg, True))
            or ((Res = mrOKChipCard) and CheckUserChipCard(LoginDialogForm.ChipCardCode, AUserLogin, AUserIDCC, True)) then
          begin
            FLoggedUser := True;
            LoggedIn := True;

            if Res = mrOk then
            begin
              FUID := AUserIDDlg;
              FCurrentUserLogin := LoginDialogForm.edtusername.Text;
            end
            else
            begin
              FUID := AUserIDCC;
              FCurrentUserLogin := AUserLogin;
            end;

            FLoggedSince := Now;
            Result := True;
            GetControlSecurityManager.UpdateControls;
            DoSuccessfulLogin;
            DoUserChanged;
          end
          else
          begin
            DoFailureLogin;
            Inc(Retries);
            if (FLoginRetries > 0) and (Retries >= FLoginRetries) then
            begin
              LoginDialogForm.DisableEntry;
              FrozenTimer.Enabled := True;
              LoginDialogForm.ShowModal;
              Retries := 0;
            end;
          end;
        end
        else
          Aborted := True;

        LoginDialogForm.FocusControl := fcPassword;
      finally
        if Assigned(FChipCardReader) then
        begin
          if FChipCardReader.ChipCardReady then
          begin
            StopDelayedChipCardRead;
            FChipCardReader.FinishChipCard;
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(LoginDialogForm);
    FreeAndNil(FrozenTimer);
  end;
end;

function TBasicUserManagement.Login(UserLogin, UserPassword: UTF8String; var UID: Integer): Boolean;
begin
  Result := CheckUserAndPassword(UserLogin, UserPassword, UID, True);
  if Result then
  begin
    FLoggedUser := True;
    FUID := UID;
    FCurrentUserLogin := UserLogin;
    FLoggedSince := Now;
    Result := True;
    GetControlSecurityManager.UpdateControls;
    DoSuccessfulLogin;
    DoUserChanged;
  end;
end;

procedure TBasicUserManagement.Logout;
var
  AUserChanged: Boolean;
begin
  AUserChanged := FLoggedUser or (FUID >= 0);
  FLoggedUser := False;
  FCurrentUserName := '';
  FCurrentUserLogin := '';
  FUID := -1;
  FLoggedSince := Now;
  GetControlSecurityManager.UpdateControls;
  if AUserChanged then
    DoUserChanged;
end;

procedure TBasicUserManagement.Manage;
begin
  // has nothing to do here!
end;

procedure TBasicUserManagement.ValidateSecurityCode(ASecurityCodes: UTF8String);
begin
  // raise a exception if the security code is invalid.
end;

function TBasicUserManagement.SecurityCodeExists(ASecurityCodes: UTF8String): Boolean;
begin
  Result := FRegisteredSecurityCodes.IndexOf(ASecurityCodes) >= 0;
end;

procedure TBasicUserManagement.RegisterSecurityCode(ASecurityCodes: UTF8String);
begin
  if not SecurityCodeExists(ASecurityCodes) then
    FRegisteredSecurityCodes.Add(ASecurityCodes);
end;

procedure TBasicUserManagement.UnregisterSecurityCode(ASecurityCodes: UTF8String);
begin
  if SecurityCodeExists(ASecurityCodes) then
    FRegisteredSecurityCodes.Delete(FRegisteredSecurityCodes.IndexOf(ASecurityCodes));
end;

function TBasicUserManagement.CanAccess(ASecurityCodes: UTF8String): Boolean;
begin
  Result := False;
end;

function TBasicUserManagement.GetRegisteredAccessCodes: TStringList;
begin
  Result := TStringList.Create;
  Result.Assign(FRegisteredSecurityCodes);
end;

function TBasicUserManagement.CheckIfUserIsAllowed(ASecurityCodes: UTF8String; RequireUserLogin: Boolean; var UserLogin: UTF8String; const UserHint: UTF8String): Boolean;
var
  FrozenTimer: TTimer;
  AUserID: Integer;
  PreferredWidth: Integer;
  PreferredHeight: Integer;
  Res: Integer;
  AUserLogin: UTF8String;
begin
  Result := False;

  // If the logged-in user has permission, it prevents opening the dialog
  // that would request permission from another user.
  if UserLogged and CanAccess(ASecurityCodes) and (RequireUserLogin = False) then
  begin
    UserLogin := GetCurrentUserLogin;
    Result := True;
    Exit;
  end;

  // If a special permission dialog is open, bring it to the foreground
  if Assigned(LoginDialogForm) then
  begin
    LoginDialogForm.ShowOnTop;
    Exit;
  end;

  FrozenTimer := TTimer.Create(nil);
  FrozenTimer.Enabled := False;
  FrozenTimer.Interval := LoginFrozenTime;
  FrozenTimer.Tag := 2; //Check
  FrozenTimer.OnTimer := @UnfreezeLogin;

  Result := False;

  LoginDialogForm := TpsHMIfrmUserAuthentication.Create(nil);
  try
    LoginDialogForm.FormStyle := fsSystemStayOnTop;

    LoginDialogForm.Caption := SLoginRequired;
    if trim(ASecurityCodes) <> '' then
    begin
      LoginDialogForm.lblRequiredPerm.BorderSpacing.Around := 3;
      LoginDialogForm.lblRequiredPerm.Caption := format(SRequiredPerm, [ASecurityCodes]);
    end;
    if trim(UserHint) <> '' then
    begin
      LoginDialogForm.lblHint.BorderSpacing.Around := 3;
      LoginDialogForm.lblHint.BorderSpacing.Top := 8;
      LoginDialogForm.lblHint.Caption := UserHint;
    end;

    LoginDialogForm.FocusControl := fcUserName;
    LoginDialogForm.edtusername.Text := '';
    LoginDialogForm.edtPassword.Text := '';

    LoginDialogForm.AutoSize := True;
    LoginDialogForm.HandleNeeded;
    LoginDialogForm.GetPreferredSize(PreferredWidth, PreferredHeight);

    try
      if Assigned(FChipCardReader) then
      begin
        if not FChipCardReader.ChipCardReady then
          FChipCardReader.InitializeChipCard;
        if FChipCardReader.ChipCardReady then
        begin
          WaitForEmptyChipCard;
          StartDelayedChipCardRead;
        end;
      end;

      Res := LoginDialogForm.ShowModal;
      if Res in [mrOk, mrOKChipCard] then
      begin
        if ((Res = mrOk) and CheckUserAndPassword(LoginDialogForm.edtusername.Text, LoginDialogForm.edtPassword.Text, AUserID, False)) or
          ((Res = mrOKChipCard) and CheckUserChipCard(LoginDialogForm.ChipCardCode, AUserLogin, AUserID, False)) then
        begin
          if CanAccess(ASecurityCodes, AUserID) then
          begin
            Result := True;

            if Res = mrOk then
              UserLogin := LoginDialogForm.edtusername.Text
            else
              UserLogin := AUserLogin;
          end
          else
            Result := False;
        end;
      end;
    finally
      if Assigned(FChipCardReader) then
      begin
        if FChipCardReader.ChipCardReady then
        begin
          StopDelayedChipCardRead;
          FChipCardReader.FinishChipCard;
        end;
      end;
    end;
  finally
    FreeAndNil(LoginDialogForm);
    FreeAndNil(FrozenTimer);
  end;
end;

function TBasicUserManagement.GetUID: Integer;
begin
  Result := FUID;
end;

procedure TBasicUserManagement.SetChipCardReader(AValue: TChipCardReader);
begin
  if FChipCardReader = AValue then Exit;

  if Assigned(FChipCardReader) then
    FChipCardReader.RemoveFreeNotification(Self);

  if Assigned(AValue) then
    AValue.FreeNotification(Self);

  FChipCardReader := AValue;
end;

procedure TBasicUserManagement.CheckIfCardHasBeenRemoved(Sender: TObject);
begin
  if Assigned(FChipCardReader) and (Sender is TTimer) and (TTimer(Sender).Owner is TForm) then
  begin
    if FChipCardReader.IsEmptyChipCard then
    begin
      TForm(TTimer(Sender).Owner).ModalResult := mrOk;
      TTimer(Sender).Enabled := False;
    end;
  end;
end;

procedure TBasicUserManagement.ChipCardReaderProc(Data: PtrInt);
begin
  if Assigned(FChipCardReader) and Assigned(LoginDialogForm) then
  begin
    if FChipCardReader.ChipCardRead(LoginDialogForm.ChipCardCode) then
    begin
      LoginDialogForm.ModalResult := mrOKChipCard;
    end
    else
      StartDelayedChipCardRead;
  end;
end;

procedure TBasicUserManagement.WarningCanBeClosed(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(FChipCardReader) then
    CanClose := FChipCardReader.IsEmptyChipCard
  else
    CanClose := True;
end;

function TBasicUserManagement.GetLoginTime: TDateTime;
begin
  if FLoggedUser then
    Result := FLoggedSince
  else
    Result := Now;
end;

procedure TBasicUserManagement.SetInactiveTimeOut(ATimeout: Cardinal);
begin

end;

function TBasicUserManagement.CheckUserAndPassword(User, Pass: UTF8String; out UserID: Integer; LoginAction: Boolean): Boolean;
begin
  Result := False;
end;

function TBasicUserManagement.CheckUserChipCard(AChipCardCode: UTF8String; var UserLogin: UTF8String; var UserID: Integer; LoginAction: Boolean): Boolean;
begin
  Result := False;
end;

function TBasicUserManagement.GetLoggedUser: Boolean;
begin
  Result := FLoggedUser;
end;

function TBasicUserManagement.GetCurrentUserName: UTF8String;
begin
  Result := FCurrentUserName;
end;

function TBasicUserManagement.GetCurrentUserLogin: UTF8String;
begin
  Result := FCurrentUserLogin;
end;

function TBasicUserManagement.CanAccess(ASecurityCodes: UTF8String; AUID: Integer): Boolean;
begin
  Result := False;
end;

procedure TBasicUserManagement.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FChipCardReader) then
    FChipCardReader := nil;
end;

procedure TBasicUserManagement.WaitForEmptyChipCard;
var
  AForm: TForm;
  ALabel: TLabel;
  ATimer: TTimer;
begin
  if Assigned(FChipCardReader) then
  begin
    AForm := TForm.CreateNew(Self);
    try
      AForm.SetBounds(0, 0, 320, 240);
      AForm.Position := poScreenCenter;
      AForm.BorderStyle := bsNone;
      ALabel := TLabel.Create(AForm);
      ALabel.Align := alClient;
      ALabel.WordWrap := True;
      ALabel.Alignment := taCenter;
      ALabel.Layout := tlCenter;
      ALabel.font.Style := [fsBold];
      ALabel.font.Height := 16;
      ALabel.Caption := SRemoveChipCard;
      ALabel.Parent := AForm;
      ATimer := TTimer.Create(AForm);
      ATimer.Interval := 100;
      ATimer.OnTimer := @CheckIfCardHasBeenRemoved;
      AForm.OnCloseQuery := @WarningCanBeClosed;
      repeat
        if not FChipCardReader.IsEmptyChipCard then
          AForm.ShowModal;
      until FChipCardReader.IsEmptyChipCard;
    finally
      FreeAndNil(AForm);
    end;
  end;
end;

procedure TBasicUserManagement.StartDelayedChipCardRead;
begin
  if Assigned(FChipCardReader) and ((Application.Flags * [AppDoNotCallAsyncQueue]) = []) then
  begin
    Application.QueueAsyncCall(@ChipCardReaderProc, 0);
  end;
end;

procedure TBasicUserManagement.StopDelayedChipCardRead;
begin
  Application.RemoveAsyncCalls(Self);
end;

procedure TBasicUserManagement.DoSuccessfulLogin;
begin
  if Assigned(FSuccessfulLogin) then
    FSuccessfulLogin(Self);
end;

procedure TBasicUserManagement.DoFailureLogin;
begin
  if Assigned(FFailureLogin) then
    FFailureLogin(Self);
end;

procedure TBasicUserManagement.UnfreezeLogin(Sender: TObject);
begin
  if Sender is TTimer then
  begin
    TTimer(Sender).Enabled := False;
    case TTimer(Sender).Tag of
      1, 2: if Assigned(LoginDialogForm) then
              begin
                LoginDialogForm.Close;
                LoginDialogForm.EnableEntry;
              end;
    end;
  end;
end;

procedure TBasicUserManagement.DoUserChanged;
begin
  if Assigned(FUserChanged) then
  try
    FUserChanged(Self, FCurrentUserLogin, GetCurrentUserLogin);
  finally
  end;
end;

end.
 

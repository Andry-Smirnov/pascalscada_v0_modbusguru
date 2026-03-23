unit CustomizedUserManagement;

{$mode objfpc}{$H+}

interface

uses
  Classes, BasicUserManagement;

type
  TCheckUserAndPasswordEvent = procedure(User, Pass: UTF8String; out AUID: Integer; var ValidUser: Boolean; LoginAction: Boolean) of object;
  TCheckUserChipCard = procedure(AChipCardCode: UTF8String; var UserLogin: UTF8String; var UserID: Integer; var ValidChipCard: Boolean; LoginAction: Boolean) of object;
  TUserStillLoggedEvent = procedure(var StillLogged: Boolean) of object;
  TGetUserNameAndLogin = procedure(var UserInfo: UTF8String) of object;
  TManageUsersAndGroupsEvent = TNotifyEvent;
  TValidadeSecurityCode = procedure(const ASecurityCode: UTF8String) of object;
  TRegisterSecurityCode = procedure(const ASecurityCode: UTF8String) of object;
  TLogoutEvent = TNotifyEvent;
  TCanAccessEvent = procedure(ASecurityCode: UTF8String; var CanAccess: Boolean) of object;
  TUIDCanAccessEvent = procedure(AUID: Integer; ASecurityCode: UTF8String; var CanAccess: Boolean) of object;

  { TCustomizedUserManagement }

  TCustomizedUserManagement = class(TBasicUserManagement)
  private
    FCheckUserAndPasswordEvent: TCheckUserAndPasswordEvent;
    FCheckUserChipCardEvent: TCheckUserChipCard;
    FGetUserName: TGetUserNameAndLogin;
    FGetUserLogin: TGetUserNameAndLogin;
    FManageUsersAndGroupsEvent: TManageUsersAndGroupsEvent;
    FRegisterSecurityCode: TRegisterSecurityCode;
    FUIDCanAccessEvent: TUIDCanAccessEvent;
    FValidadeSecurityCode: TValidadeSecurityCode;
    FCanAccessEvent: TCanAccessEvent;
    FLogoutEvent: TLogoutEvent;
  protected
    function CheckUserAndPassword(User, Pass: UTF8String; out UserID: Integer; LoginAction: Boolean): Boolean; override;
    function CheckUserChipCard(AChipCardCode: UTF8String; var UserLogin: UTF8String; var UserID: Integer; LoginAction: Boolean): Boolean; override;

    function GetCurrentUserName: UTF8String; override;
    function GetCurrentUserLogin: UTF8String; override;
    function CanAccess(ASecurityCode: UTF8String; AUID: Integer): Boolean; override; overload;
  public
    procedure Logout; override;
    procedure Manage; override;

    //Security codes management
    procedure ValidateSecurityCode(ASecurityCode: UTF8String); override;
    procedure RegisterSecurityCode(ASecurityCode: UTF8String); override;

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

  published
    property OnCheckUserAndPass: TCheckUserAndPasswordEvent read FCheckUserAndPasswordEvent write FCheckUserAndPasswordEvent;
    property OnCheckUserChipCard: TCheckUserChipCard read FCheckUserChipCardEvent write FCheckUserChipCardEvent;
    property OnGetUserName: TGetUserNameAndLogin read FGetUserName write FGetUserName;
    property OnGetUserLogin: TGetUserNameAndLogin read FGetUserLogin write FGetUserLogin;
    property OnManageUsersAndGroups: TManageUsersAndGroupsEvent read FManageUsersAndGroupsEvent write FManageUsersAndGroupsEvent;
    property OnValidadeSecurityCode: TValidadeSecurityCode read FValidadeSecurityCode write FValidadeSecurityCode;
    property OnRegisterSecurityCode: TRegisterSecurityCode read FRegisterSecurityCode write FRegisterSecurityCode;
    property OnCanAccess: TCanAccessEvent read FCanAccessEvent write FCanAccessEvent;
    property OnUIDCanAccess: TUIDCanAccessEvent read FUIDCanAccessEvent write FUIDCanAccessEvent;
    property OnLogout: TLogoutEvent read FLogoutEvent write FLogoutEvent;
  end;

implementation

uses SysUtils;

function TCustomizedUserManagement.CheckUserAndPassword(User, Pass: UTF8String; out UserID: Integer; LoginAction: Boolean): Boolean;
begin
  Result := False;
  try
    if Assigned(FCheckUserAndPasswordEvent) then
      FCheckUserAndPasswordEvent(User, Pass, UserID, Result, LoginAction);
  except
    Result := False;
  end;
end;

function TCustomizedUserManagement.CheckUserChipCard(AChipCardCode: UTF8String; var UserLogin: UTF8String; var UserID: Integer; LoginAction: Boolean): Boolean;
begin
  Result := False;
  try
    if Assigned(FCheckUserChipCardEvent) then
      FCheckUserChipCardEvent(AChipCardCode,
        UserLogin,
        UserID,
        Result,
        LoginAction);
  except
    Result := False;
  end;
end;

function TCustomizedUserManagement.GetCurrentUserName: UTF8String;
begin
  Result := '';
  if FLoggedUser then
  try
    if Assigned(FGetUserName) then
      FGetUserName(Result);
  except
    Result := '';
  end;
end;

function TCustomizedUserManagement.GetCurrentUserLogin: UTF8String;
begin
  Result := '';
  if FLoggedUser then
  try
    if Assigned(FGetUserLogin) then
      FGetUserLogin(Result);
  except
    Result := '';
  end;
end;

function TCustomizedUserManagement.CanAccess(ASecurityCode: UTF8String; AUID: Integer): Boolean;
begin
  Result := (Trim(ASecurityCode) = '');
  if AUID >= 0 then
  try
    if Assigned(FUIDCanAccessEvent) then
      FUIDCanAccessEvent(AUID, ASecurityCode, Result);
  except
    Result := (Trim(ASecurityCode) = '');
  end;
end;

procedure TCustomizedUserManagement.Logout;
begin
  inherited Logout;
  if Assigned(FLogoutEvent) then
  try
    FLogoutEvent(Self);
  except
  end;
end;

procedure TCustomizedUserManagement.Manage;
begin
  if Assigned(FManageUsersAndGroupsEvent) then
    FManageUsersAndGroupsEvent(Self);
end;

procedure TCustomizedUserManagement.ValidateSecurityCode(ASecurityCode: UTF8String);
begin
  if Assigned(FValidadeSecurityCode) then
    FValidadeSecurityCode(ASecurityCode);
end;

procedure TCustomizedUserManagement.RegisterSecurityCode(ASecurityCode: UTF8String);
begin
  inherited RegisterSecurityCode(ASecurityCode);
  if Assigned(FRegisterSecurityCode) then
    FRegisterSecurityCode(ASecurityCode);
end;

function TCustomizedUserManagement.CanAccess(ASecurityCode: UTF8String): Boolean;
begin
  Result := (Trim(ASecurityCode) = '');
  if FLoggedUser then
  try
    if Assigned(FCanAccessEvent) then
      FCanAccessEvent(ASecurityCode, Result);
  except
    Result := (Trim(ASecurityCode) = '');
  end;
end;

end.

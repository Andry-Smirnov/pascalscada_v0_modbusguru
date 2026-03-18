unit HMIKeyboardManager;

interface

uses
  Classes, Forms, Controls, SysUtils, unumerickeyboard, ualfakeyboard;

type

  TOnScreenKeyboard = (oskNone, oskNumeric, oskAlphaNumeric);

  TNumericScreenKeyboardOption = (nskoShowMinus, nskoShowDecimalPoint);
  TNumericScreenKeyboardOptions = set of TNumericScreenKeyboardOption;

  TAlphaNumericScreenKeyBoardOption = (
    askoShowFxxKeys,
    askoShowTab,
    askoShowCaps,
    askoShowShift,
    askoShowCtrl,
    askoShowAlt,
    askoShowSymbols,
    askoShowNumbers,
    askoShowFastNavigation,
    askoShowNavigation,
    askoCloseOnPressEnter);
  TAlphaNumericScreenKeyBoardOptions = set of TAlphaNumericScreenKeyBoardOption;


  THMIFocusChangeEvent = procedure(FocusedControl: TControl; var KeyboarTypeForControl: TOnScreenKeyboard; var NumericKBOptions: TNumericScreenKeyboardOptions; var AlphaNumKBOptions: TAlphaNumericScreenKeyBoardOptions; var ShowKeyboardNow: Boolean) of object;

  { THMIKeyboardManager }

  THMIKeyboardManager = class(TComponent)
  private
    FShowKeyboardOnEnter: Boolean;
    FShowKeyBoardNow: Boolean;
    function SameMethod(AMethod1, AMethod2: TNotifyEvent): Boolean;
  protected
    FOldOnEnterEvent: TNotifyEvent;
    FOldOnClickEvent: TNotifyEvent;
    FOldOnExitEvent: TNotifyEvent;
    FNumericKeyBoard: TpsHMIfrmNumericKeyBoard;
    FAlphaNumericKeyboard: TpsHMIfrmAlphaKeyboard;
    FOnFocusChange: THMIFocusChangeEvent;
    FLastFocusedControl: TWinControl;
    FKeyboarTypeForControl: TOnScreenKeyboard;
    FNumericKBOptions: TNumericScreenKeyboardOptions;
    FAlphaNumKBOptions: TAlphaNumericScreenKeyBoardOptions;

    procedure ControlFocusChanged(Sender: TObject; LastControl: TControl);
    procedure NumKBClosed(Sender: TObject; var CloseAction: TCloseAction);
    procedure AlphaKBClosed(Sender: TObject; var CloseAction: TCloseAction);
    procedure ShowKeyboard(Sender: TObject);
    procedure ClickEvent(Sender: TObject);
    procedure EnterEvent(Sender: TObject);
    procedure ExitEvent(Sender: TObject);
    procedure CloseNumKB;
    procedure CloseAlphaKB;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PassFocusToLastValidControl(Data: PtrInt);
  published
    property ShowKeyboardOnEnter: Boolean read FShowKeyboardOnEnter write FShowKeyboardOnEnter default False;
    property OnFocusChange: THMIFocusChangeEvent read FOnFocusChange write FOnFocusChange;
  end;


implementation


{$IFDEF DEBUG}
uses
  LCLProc;
{$ENDIF}


{ THMIKeyboardManager }

procedure THMIKeyboardManager.ControlFocusChanged(Sender: TObject; LastControl: TControl);
var
  ALastControl: TWinControl;
begin
  {$IFDEF DEBUG}
  DebugLn('=====================================================================');
  if FLastFocusedControl<>nil then
    DebugLn('Last control name:', FLastFocusedControl.Name)
  else
    DebugLn('Last Focused Control IS NULL (FLastFocusedControl=nil)');

  if LastControl<>nil then
    DebugLn('Current control name:', LastControl.Name)
  else
    DebugLn('Current focused control IS NULL (LastControl=nil)');
  {$ENDIF}

  if LastControl = FNumericKeyBoard then
  begin
    {$IFDEF DEBUG}
    DebugLn('LastControl=FNumericKeyBoard EXITING!');
    {$ENDIF}
    Exit;
  end;

  if LastControl = FAlphaNumericKeyboard then
  begin
    {$IFDEF DEBUG}
    DebugLn('LastControl=FAlphaNumericKeyboard EXITING!');
    {$ENDIF}
    Exit;
  end;

  if LastControl = FLastFocusedControl then
  begin
    {$IFDEF DEBUG}
    DebugLn('LastControl=FLastFocusedControl EXITING!');
    {$ENDIF}
    Exit;
  end;

  if Assigned(LastControl) and (LastControl is TWinControl) then
  begin
    {$IFDEF DEBUG}
    DebugLn('Cur focused control is TWinControl');
    {$ENDIF}
    if (not SameMethod(TWinControl(LastControl).OnClick, @ClickEvent)) or
      (not SameMethod(TWinControl(LastControl).OnEnter, @EnterEvent)) or
      (not SameMethod(TWinControl(LastControl).OnExit, @ExitEvent)) then
    begin
      ALastControl := TWinControl(LastControl);
      {$IFDEF DEBUG}
      DebugLn('fLastControl:=TWinControl(LastControl)');
      {$ENDIF}
    end
    else
    begin
      {$IFDEF DEBUG}
      DebugLn('Cur focused control has all events Assigned to current handler?!?');
      if not SameMethod(TWinControl(LastControl).OnClick,ClickEvent) then
        DebugLn('TWinControl(LastControl).OnClick<>ClickEvent');
      if not SameMethod(TWinControl(LastControl).OnEnter,EnterEvent) then
        DebugLn('TWinControl(LastControl).OnEnter<>EnterEvent');
      if not SameMethod(TWinControl(LastControl).OnExit, ExitEvent)  then
        DebugLn('TWinControl(LastControl).OnExit<>ExitEvent');
      {$ENDIF}
      Exit;
    end;
  end
  else
  begin
    ALastControl := nil;
    {$IFDEF DEBUG}
    DebugLn('Cur focused control IS NOT a TWinControl');
    {$ENDIF}
  end;

  if (ALastControl <> FLastFocusedControl) and (ALastControl <> FNumericKeyBoard) and (ALastControl <> FAlphaNumericKeyboard) then
  begin
    {$IFDEF DEBUG}
    DebugLn('Closing all keyboards...');
    {$ENDIF}
    CloseAlphaKB;
    CloseNumKB;
  end;

  if FLastFocusedControl <> nil then
  begin
    FLastFocusedControl.RemoveFreeNotification(Self);
    {$IFDEF DEBUG}
    DebugLn('Restoring the default event handles for control ',FLastFocusedControl.Name);
    {$ENDIF}
    if SameMethod(FLastFocusedControl.OnClick, @ClickEvent) then
    begin
      {$IFDEF DEBUG}
      DebugLn('Restoring OnClick');
      {$ENDIF}
      FLastFocusedControl.OnClick := FOldOnClickEvent;
    end;

    if SameMethod(FLastFocusedControl.OnEnter, @EnterEvent) then
    begin
      {$IFDEF DEBUG}
      DebugLn('Restoring OnEnter');
      {$ENDIF}
      FLastFocusedControl.OnEnter := FOldOnEnterEvent;
    end;

    if SameMethod(FLastFocusedControl.OnExit, @ExitEvent) then
    begin
      {$IFDEF DEBUG}
      DebugLn('Restoring OnEnter');
      {$ENDIF}
      FLastFocusedControl.OnExit := FOldOnExitEvent;
    end;
  end;

  try
    if ALastControl <> nil then
    begin
      {$IFDEF DEBUG}
      DebugLn('Backup of event handlers of the new focused control ',fLastControl.Name);
      {$ENDIF}
      FOldOnClickEvent := ALastControl.OnClick;
      FOldOnEnterEvent := ALastControl.OnEnter;
      FOldOnExitEvent := ALastControl.OnExit;

      FKeyboarTypeForControl := oskNone;
      if Assigned(FOnFocusChange) then
      begin
        OnFocusChange(ALastControl,
          FKeyboarTypeForControl,
          FNumericKBOptions,
          FAlphaNumKBOptions,
          FShowKeyBoardNow);
        {$IFDEF DEBUG}
        DebugLn('OnFocusChange fired');
        {$ENDIF}
      end
      else
      begin
        {$IFDEF DEBUG}
        DebugLn('FOnFocusChange event is NULL');
        {$ENDIF}
      end;

      if FKeyboarTypeForControl = oskNone then
      begin
        {$IFDEF DEBUG}
        DebugLn('FKeyboarTypeForControl=oskNone');
        {$ENDIF}
        ALastControl := nil;
        FLastFocusedControl := nil;
      end
      else
      begin
        {$IFDEF DEBUG}
        DebugLn('FKeyboarTypeForControl<>oskNone');
        {$ENDIF}
        ALastControl.OnClick := @ClickEvent;
        ALastControl.OnEnter := @EnterEvent;
        ALastControl.OnExit := @ExitEvent;
        ALastControl.FreeNotification(Self);
        {$IFDEF DEBUG}
        DebugLn('setup up of new event handlers...');
        {$ENDIF}
      end;
    end
    else
    begin
      {$IFDEF DEBUG}
      DebugLn('fLastControl=nil');
      {$ENDIF}
    end;
  finally
    if ((ALastControl <> FNumericKeyBoard) and (ALastControl <> FAlphaNumericKeyboard)) or (ALastControl = nil) then
    begin
      {$IFDEF DEBUG}
      if fLastControl = nil then
        DebugLn('FLastFocusedControl:=fLastControl(NULL)')
      else
        DebugLn('FLastFocusedControl:=fLastControl');
      {$ENDIF}
      FLastFocusedControl := ALastControl;
    end;
  end;
end;

function THMIKeyboardManager.SameMethod(AMethod1, AMethod2: TNotifyEvent): Boolean;
begin
  Result := (TMethod(AMethod1).Code = TMethod(AMethod2).Code) and (TMethod(AMethod1).Data = TMethod(AMethod2).Data);
end;

procedure THMIKeyboardManager.NumKBClosed(Sender: TObject; var CloseAction: TCloseAction);
begin
  FNumericKeyBoard := nil;
end;

procedure THMIKeyboardManager.AlphaKBClosed(Sender: TObject; var CloseAction: TCloseAction);
begin
  FAlphaNumericKeyboard := nil;
end;

procedure THMIKeyboardManager.ShowKeyboard(Sender: TObject);
begin
  case FKeyboarTypeForControl of
    oskNone: ExitEvent(nil);
    oskNumeric: begin
                  CloseAlphaKB;
                  FNumericKeyBoard := TpsHMIfrmNumericKeyBoard.CreateOrGetLast(Self,
                    FLastFocusedControl,
                    nskoShowMinus in FNumericKBOptions,
                    nskoShowDecimalPoint in FNumericKBOptions);
                  FNumericKeyBoard.OnClose := @NumKBClosed;
                  FNumericKeyBoard.ShowAlongsideOfTheTarget;
                end;
    oskAlphaNumeric:  begin
                        CloseNumKB;
                        FAlphaNumericKeyboard := TpsHMIfrmAlphaKeyboard.CreateOrGetLast(Self,
                          FLastFocusedControl,
                          askoShowFxxKeys in FAlphaNumKBOptions,
                          askoShowTab in FAlphaNumKBOptions,
                          askoShowCaps in FAlphaNumKBOptions,
                          askoShowShift in FAlphaNumKBOptions,
                          askoShowCtrl in FAlphaNumKBOptions,
                          askoShowAlt in FAlphaNumKBOptions,
                          askoShowSymbols in FAlphaNumKBOptions,
                          askoShowNumbers in FAlphaNumKBOptions,
                          askoShowFastNavigation in FAlphaNumKBOptions,
                          askoShowNavigation in FAlphaNumKBOptions,
                          askoCloseOnPressEnter in FAlphaNumKBOptions);
                        FAlphaNumericKeyboard.OnClose := @AlphaKBClosed;
                        FAlphaNumericKeyboard.ShowAlongsideOfTheTarget;
                      end;
  end;
end;

procedure THMIKeyboardManager.ClickEvent(Sender: TObject);
begin
  ShowKeyboard(Sender);

  PassFocusToLastValidControl(0);

  if Assigned(FOldOnClickEvent) then
    FOldOnClickEvent(Sender);
end;

procedure THMIKeyboardManager.EnterEvent(Sender: TObject);
begin
  if FShowKeyboardOnEnter or FShowKeyBoardNow then
  begin
    FShowKeyBoardNow := False;
    ShowKeyboard(Sender);

    PassFocusToLastValidControl(0);
  end;

  if Assigned(FOldOnEnterEvent) then
    FOldOnEnterEvent(Sender);
end;

procedure THMIKeyboardManager.ExitEvent(Sender: TObject);
begin
  CloseAlphaKB;
  CloseNumKB;

  if Assigned(FOldOnExitEvent) then
    FOldOnExitEvent(Sender);
end;

procedure THMIKeyboardManager.CloseNumKB;
begin
  if Assigned(FNumericKeyBoard) then
  begin
    FNumericKeyBoard.Close;
    FNumericKeyBoard := nil;
  end;
end;

procedure THMIKeyboardManager.CloseAlphaKB;
begin
  if Assigned(FAlphaNumericKeyboard) then
  begin
    FAlphaNumericKeyboard.Close;
    FAlphaNumericKeyboard := nil;
  end;
end;

procedure THMIKeyboardManager.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FLastFocusedControl = AComponent) then
  begin
    FLastFocusedControl := nil;
    CloseAlphaKB;
    CloseNumKB;
  end;
end;

constructor THMIKeyboardManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlphaNumericKeyboard := nil;
  FNumericKeyBoard := nil;
  FLastFocusedControl := nil;
  FShowKeyboardOnEnter := False;
  Screen.AddHandlerActiveControlChanged(@ControlFocusChanged);
end;

destructor THMIKeyboardManager.Destroy;
begin
  Screen.RemoveHandlerActiveControlChanged(@ControlFocusChanged);
  inherited Destroy;
end;

procedure THMIKeyboardManager.PassFocusToLastValidControl(Data: PtrInt);
begin
  if FLastFocusedControl <> nil then
  begin
    GetParentForm(FLastFocusedControl).ShowOnTop;
  end;
end;

end.

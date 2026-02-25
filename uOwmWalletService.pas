unit uOwmWalletService;

interface

uses
  System.SysUtils,
  uOwmTypes,
  uOwmToolsDetector,
  uOwmLogger;

type
  TOwmWalletService = class
  private
    FTools: TOwmToolsInfo;
    FLogger: TOwmLogger;
    FLock: TObject;
    function QuoteArg(const AValue: string): string;
    function BuildPwdArg(const APassword: string): string;
    function MaskSensitiveArgs(const AArgsLine: string): string;
    function TryNormalizeWalletPath(const AWalletPath: string; out ANormalizedPath,
      AError, AErrorCode: string): Boolean;
    function RunOrapki(const AArgsLine: string; out AOutput, AError: string): Boolean;
    function ParseCertificates(const AOutput: string): TCertInfoArray;
    function ParseDate(const AText: string; out ADate: TDateTime): Boolean;
  public
    constructor Create(const ATools: TOwmToolsInfo; ALogger: TOwmLogger);
    destructor Destroy; override;

    procedure UpdateTools(const ATools: TOwmToolsInfo);
    function CanUseWallet: Boolean;

    function ListCertificates(const AWalletPath, APassword: string;
      out ACerts: TCertInfoArray; out AError: string): Boolean;
    function AddCertificate(const AWalletPath, APassword, ACertFile: string;
      out AError: string): Boolean;
    function RemoveCertificate(const AWalletPath, APassword, ACertSubject: string;
      out AError: string): Boolean;
    function CreateWallet(const AWalletPath, APassword: string; AAutoLogin,
      AAutoLoginLocal: Boolean; out AError: string): Boolean; overload;
    function CreateWallet(const AWalletPath, APassword: string; AAutoLogin,
      AAutoLoginLocal: Boolean; out AError, AErrorCode: string): Boolean; overload;
    function RemoveAllCertificates(const AWalletPath, APassword: string;
      const ACerts: TCertInfoArray; out ARemoved, AFailed: Integer; out AError: string): Boolean;
    function AddFromFolder(const AWalletPath, APassword, AFolder: string;
      out AAdded, ASkipped, AFailed: Integer; out AError: string): Boolean;
  end;

implementation

uses
  System.Classes,
  System.StrUtils,
  System.IOUtils,
  System.DateUtils,
  System.Generics.Collections,
  uOwmProcessRunner,
  uOwmI18n;

function SplitLines(const AText: string): TArray<string>;
var
  LList: TStringList;
  I: Integer;
begin
  LList := TStringList.Create;
  try
    LList.Text := AText;
    SetLength(Result, LList.Count);
    for I := 0 to LList.Count - 1 do
      Result[I] := LList[I];
  finally
    LList.Free;
  end;
end;

{ TOwmWalletService }

constructor TOwmWalletService.Create(const ATools: TOwmToolsInfo; ALogger: TOwmLogger);
begin
  inherited Create;
  FLock := TObject.Create;
  FTools := ATools;
  FLogger := ALogger;
end;

destructor TOwmWalletService.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TOwmWalletService.UpdateTools(const ATools: TOwmToolsInfo);
begin
  TMonitor.Enter(FLock);
  try
    FTools := ATools;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TOwmWalletService.CanUseWallet: Boolean;
begin
  TMonitor.Enter(FLock);
  try
    Result := FTools.OrapkiAvailable;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TOwmWalletService.QuoteArg(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '\"', [rfReplaceAll]) + '"';
end;

function TOwmWalletService.BuildPwdArg(const APassword: string): string;
begin
  if Trim(APassword) = '' then
    Result := ''
  else
    Result := ' -pwd ' + QuoteArg(APassword);
end;

function TOwmWalletService.MaskSensitiveArgs(const AArgsLine: string): string;
var
  LTokens: TStringList;
  LPos: Integer;
  LLen: Integer;
  LToken: string;
  I: Integer;

  function ReadNextToken: string;
  var
    LStart: Integer;
    LInQuotes: Boolean;
  begin
    while (LPos <= LLen) and CharInSet(AArgsLine[LPos], [#9, ' ']) do
      Inc(LPos);

    LStart := LPos;
    LInQuotes := False;
    while LPos <= LLen do
    begin
      if AArgsLine[LPos] = '"' then
      begin
        LInQuotes := not LInQuotes;
        Inc(LPos);
        Continue;
      end;

      if (not LInQuotes) and CharInSet(AArgsLine[LPos], [#9, ' ']) then
        Break;

      Inc(LPos);
    end;

    Result := Copy(AArgsLine, LStart, LPos - LStart);
  end;

  function IsSensitiveFlag(const AToken: string): Boolean;
  var
    LTokenLower: string;
  begin
    LTokenLower := LowerCase(AToken);
    Result :=
      (LTokenLower = '-pwd') or
      (LTokenLower = '-newpwd') or
      (LTokenLower = '-password');
  end;

  function IsSensitiveFlagWithValue(const AToken: string): Boolean;
  var
    LTokenLower: string;
  begin
    LTokenLower := LowerCase(AToken);
    Result :=
      StartsText('-pwd=', LTokenLower) or
      StartsText('-newpwd=', LTokenLower) or
      StartsText('-password=', LTokenLower);
  end;

begin
  Result := Trim(AArgsLine);
  if Result = '' then
    Exit;

  LTokens := TStringList.Create;
  try
    LPos := 1;
    LLen := Length(AArgsLine);
    while LPos <= LLen do
    begin
      LToken := ReadNextToken;
      if LToken <> '' then
        LTokens.Add(LToken);

      while (LPos <= LLen) and CharInSet(AArgsLine[LPos], [#9, ' ']) do
        Inc(LPos);
    end;

    for I := 0 to LTokens.Count - 1 do
    begin
      if IsSensitiveFlag(LTokens[I]) then
      begin
        if I + 1 < LTokens.Count then
          LTokens[I + 1] := '***';
      end
      else if IsSensitiveFlagWithValue(LTokens[I]) then
      begin
        if StartsText('-pwd=', LowerCase(LTokens[I])) then
          LTokens[I] := '-pwd=***'
        else if StartsText('-newpwd=', LowerCase(LTokens[I])) then
          LTokens[I] := '-newpwd=***'
        else
          LTokens[I] := '-password=***';
      end;
    end;

    Result := '';
    for I := 0 to LTokens.Count - 1 do
    begin
      if I > 0 then
        Result := Result + ' ';
      Result := Result + LTokens[I];
    end;
  finally
    LTokens.Free;
  end;
end;

function TOwmWalletService.TryNormalizeWalletPath(const AWalletPath: string;
  out ANormalizedPath, AError, AErrorCode: string): Boolean;
var
  LDrive: string;
begin
  Result := False;
  AError := '';
  AErrorCode := '';
  ANormalizedPath := '';

  if Trim(AWalletPath) = '' then
  begin
    AErrorCode := 'PathEmpty';
    AError := OwmText('wallet.err.path_empty', 'Wallet path is empty');
    Exit;
  end;

  try
    ANormalizedPath := ExcludeTrailingPathDelimiter(TPath.GetFullPath(Trim(AWalletPath)));
  except
    on Exception do
    begin
      AErrorCode := 'InvalidPath';
      AError := OwmText('wallet.err.invalid_path', 'Invalid path');
      Exit;
    end;
  end;

  if (ANormalizedPath = '') or SameText(ANormalizedPath, '\') then
  begin
    AErrorCode := 'InvalidPath';
    AError := OwmText('wallet.err.invalid_path', 'Invalid path');
    Exit;
  end;

  if TFile.Exists(ANormalizedPath) then
  begin
    AErrorCode := 'InvalidPath';
    AError := OwmText('wallet.err.invalid_path', 'Invalid path');
    Exit;
  end;

  if not StartsText('\\', ANormalizedPath) then
  begin
    LDrive := ExtractFileDrive(ANormalizedPath);
    if (LDrive <> '') and (not System.SysUtils.DirectoryExists(
      IncludeTrailingPathDelimiter(LDrive))) then
    begin
      AErrorCode := 'InvalidPath';
      AError := OwmText('wallet.err.invalid_path', 'Invalid path');
      Exit;
    end;
  end;

  Result := True;
end;

function TOwmWalletService.RunOrapki(const AArgsLine: string; out AOutput,
  AError: string): Boolean;
var
  LResult: TProcessRunResult;
  LExePath: string;
  LArgs: string;
  LExt: string;
  LComSpec: string;
begin
  Result := False;
  AOutput := '';
  AError := '';

  if not FTools.OrapkiAvailable then
  begin
    AError := OwmText('wallet.err.orapki_not_found', 'orapki.exe not found');
    Exit;
  end;

  if Assigned(FLogger) then
    FLogger.Debug('orapki ' + MaskSensitiveArgs(AArgsLine));

  LExePath := FTools.OrapkiPath;
  LArgs := AArgsLine;

  LExt := LowerCase(ExtractFileExt(LExePath));
  if (LExt = '') or (LExt = '.bat') or (LExt = '.cmd') then
  begin
    LComSpec := Trim(GetEnvironmentVariable('ComSpec'));
    if LComSpec = '' then
      LComSpec := 'cmd.exe';
    LExePath := LComSpec;
    LArgs := '/d /s /c ""' + FTools.OrapkiPath + '" ' + AArgsLine + '"';
  end;

  if not RunProcessCapture(LExePath, LArgs, 60000, LResult) then
  begin
    AError := LResult.ErrorMessage;
    Exit;
  end;

  AOutput := Trim(LResult.OutputText);
  if LResult.TimedOut then
  begin
    AError := OwmText('wallet.err.timeout', 'orapki timeout');
    Exit;
  end;

  if LResult.ExitCode <> 0 then
  begin
    AError := Trim(AOutput);
    if AError = '' then
      AError := OwmTextFmt('wallet.err.exit_code', 'orapki exited with code %d', [LResult.ExitCode]);
    Exit;
  end;

  Result := True;
end;

function TOwmWalletService.ParseDate(const AText: string; out ADate: TDateTime): Boolean;
var
  LText: string;
  LNormText: string;
  LFs: TFormatSettings;
  LPos: Integer;
begin
  Result := False;
  ADate := 0;
  LText := Trim(AText);
  if LText = '' then
    Exit;

  Result := TryISO8601ToDate(LText, ADate, True);
  if Result then
    Exit;

  LFs := TFormatSettings.Create('en-US');
  Result := TryStrToDateTime(LText, ADate, LFs);
  if Result then
    Exit;

  // Common orapki variant: "Mon Jan 01 12:00:00 GMT 2030"
  LNormText := LText;
  LPos := Pos(' GMT ', UpperCase(LNormText));
  if LPos > 0 then
  begin
    LNormText := Trim(Copy(LNormText, 1, LPos - 1) + ' ' + Copy(LNormText, LPos + 5, MaxInt));
    Result := TryStrToDateTime(LNormText, ADate, LFs);
    if Result then
      Exit;
  end;

  LFs := TFormatSettings.Create;
  Result := TryStrToDateTime(LText, ADate, LFs);
end;

function TOwmWalletService.ParseCertificates(const AOutput: string): TCertInfoArray;
var
  LLines: TArray<string>;
  LItems: TList<TCertInfo>;
  LCurrent: TCertInfo;
  LHasCurrent: Boolean;
  LLine: string;
  LWorkLine: string;
  LKey: string;
  LValue: string;
  LPos: Integer;
  LNotAfterText: string;

  procedure PushCurrent;
  begin
    if not LHasCurrent then
      Exit;

    if (Trim(LCurrent.Subject) = '') and (Trim(LCurrent.DisplayName) = '') and (Trim(LCurrent.Thumbprint) = '') then
      Exit;

    LCurrent.DisplayName := CertDisplayName(LCurrent);
    LItems.Add(LCurrent);
    LCurrent := Default(TCertInfo);
    LHasCurrent := False;
  end;

  procedure EnsureCurrent;
  begin
    if not LHasCurrent then
    begin
      LCurrent := Default(TCertInfo);
      LHasCurrent := True;
    end;
  end;

  procedure SetNotAfterValue(const AValue: string);
  begin
    EnsureCurrent;
    LCurrent.NotAfterText := Trim(AValue);
    ParseDate(LCurrent.NotAfterText, LCurrent.NotAfter);
  end;

  function IsNotAfterKey(const AKey: string): Boolean;
  var
    LK: string;
  begin
    LK := UpperCase(Trim(AKey));
    Result :=
      (Pos('NOT VALID AFTER', LK) > 0) or
      (Pos('NOT AFTER', LK) > 0) or
      (Pos('NOTAFTER', LK) > 0) or
      (Pos('VALID UNTIL', LK) > 0) or
      (Pos('VALID TILL', LK) > 0) or
      (Pos('VALID TO', LK) > 0) or
      (Pos('VALIDITY END', LK) > 0);
  end;

  function TrimLeadingSeparators(const AText: string): string;
  begin
    Result := Trim(AText);
    while (Result <> '') and CharInSet(Result[1], [':', '=', '-', ' ']) do
      Result := Trim(Copy(Result, 2, MaxInt));
  end;

  function TryExtractNotAfterFromLine(const ALine: string; out AValue: string): Boolean;
  var
    LLineUpper: string;
    LTokenPos: Integer;
    LTail: string;
    LTailUpper: string;
  begin
    Result := False;
    AValue := '';

    LLineUpper := UpperCase(ALine);
    if Pos('VALIDITY', LLineUpper) > 0 then
    begin
      LTokenPos := Pos('TO:', LLineUpper);
      if LTokenPos > 0 then
      begin
        LTail := Trim(Copy(ALine, LTokenPos + 3, MaxInt));
        LTail := TrimLeadingSeparators(LTail);
        if LTail <> '' then
        begin
          AValue := LTail;
          Exit(True);
        end;
      end;
    end;

    if Pos('NOT VALID AFTER', LLineUpper) > 0 then
      LTokenPos := Pos('NOT VALID AFTER', LLineUpper)
    else if Pos('NOT AFTER', LLineUpper) > 0 then
      LTokenPos := Pos('NOT AFTER', LLineUpper)
    else if Pos('NOTAFTER', LLineUpper) > 0 then
      LTokenPos := Pos('NOTAFTER', LLineUpper)
    else if Pos('VALID UNTIL', LLineUpper) > 0 then
      LTokenPos := Pos('VALID UNTIL', LLineUpper)
    else if Pos('VALID TILL', LLineUpper) > 0 then
      LTokenPos := Pos('VALID TILL', LLineUpper)
    else if Pos('VALID TO', LLineUpper) > 0 then
      LTokenPos := Pos('VALID TO', LLineUpper)
    else
      LTokenPos := 0;

    if LTokenPos <= 0 then
      Exit;

    LTail := Trim(Copy(ALine, LTokenPos, MaxInt));
    if Pos(':', LTail) > 0 then
      LTail := Copy(LTail, Pos(':', LTail) + 1, MaxInt)
    else if Pos('=', LTail) > 0 then
      LTail := Copy(LTail, Pos('=', LTail) + 1, MaxInt)
    else
    begin
      LTailUpper := UpperCase(LTail);
      if Pos('NOT VALID AFTER', LTailUpper) = 1 then
        LTail := Copy(LTail, Length('NOT VALID AFTER') + 1, MaxInt)
      else if Pos('NOT AFTER', LTailUpper) = 1 then
        LTail := Copy(LTail, Length('NOT AFTER') + 1, MaxInt)
      else if Pos('NOTAFTER', LTailUpper) = 1 then
        LTail := Copy(LTail, Length('NOTAFTER') + 1, MaxInt)
      else if Pos('VALID UNTIL', LTailUpper) = 1 then
        LTail := Copy(LTail, Length('VALID UNTIL') + 1, MaxInt)
      else if Pos('VALID TILL', LTailUpper) = 1 then
        LTail := Copy(LTail, Length('VALID TILL') + 1, MaxInt)
      else if Pos('VALID TO', LTailUpper) = 1 then
        LTail := Copy(LTail, Length('VALID TO') + 1, MaxInt);
    end;

    LTail := TrimLeadingSeparators(LTail);
    if LTail = '' then
      Exit;

    AValue := LTail;
    Result := True;
  end;

begin
  LLines := SplitLines(AOutput);
  LItems := TList<TCertInfo>.Create;
  try
    LCurrent := Default(TCertInfo);
    LHasCurrent := False;

    for LLine in LLines do
    begin
      LWorkLine := Trim(LLine);
      if LWorkLine = '' then
        Continue;

      if TryExtractNotAfterFromLine(LWorkLine, LNotAfterText) then
      begin
        SetNotAfterValue(LNotAfterText);
        Continue;
      end;

      LPos := Pos(':', LWorkLine);
      if LPos > 0 then
      begin
        LKey := Trim(Copy(LWorkLine, 1, LPos - 1));
        LValue := Trim(Copy(LWorkLine, LPos + 1, MaxInt));

        if SameText(LKey, 'Subject') or SameText(LKey, 'User Certificate') or SameText(LKey, 'DN') then
        begin
          PushCurrent;
          LCurrent := Default(TCertInfo);
          LHasCurrent := True;
          LCurrent.Subject := LValue;
          Continue;
        end;

        EnsureCurrent;

        if SameText(LKey, 'Issuer') then
          LCurrent.Issuer := LValue
        else if SameText(LKey, 'SHA1 Fingerprint') or SameText(LKey, 'Fingerprint') then
          LCurrent.Thumbprint := LValue
        else if IsNotAfterKey(LKey) then
          SetNotAfterValue(LValue);

        Continue;
      end;

      if Pos('CN=', UpperCase(LWorkLine)) > 0 then
      begin
        PushCurrent;
        LCurrent := Default(TCertInfo);
        LHasCurrent := True;
        LCurrent.Subject := LWorkLine;
      end;
    end;

    PushCurrent;
    Result := LItems.ToArray;
  finally
    LItems.Free;
  end;
end;

function TOwmWalletService.ListCertificates(const AWalletPath, APassword: string;
  out ACerts: TCertInfoArray; out AError: string): Boolean;
var
  LOut: string;
  LArgs: string;
begin
  Result := False;
  AError := '';
  SetLength(ACerts, 0);

  if Trim(AWalletPath) = '' then
  begin
    AError := OwmText('wallet.err.path_empty', 'Wallet path is empty');
    Exit;
  end;

  TMonitor.Enter(FLock);
  try
    LArgs := 'wallet display -wallet ' + QuoteArg(AWalletPath) + ' -complete' + BuildPwdArg(APassword);
    if not RunOrapki(LArgs, LOut, AError) then
      Exit;

    ACerts := ParseCertificates(LOut);
    if Assigned(FLogger) then
      FLogger.Info(OwmTextFmt('wallet.log.loaded', 'Wallet loaded: %d certificate(s)', [Length(ACerts)]));
    Result := True;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TOwmWalletService.AddCertificate(const AWalletPath, APassword,
  ACertFile: string; out AError: string): Boolean;
var
  LOut: string;
  LArgs: string;
begin
  Result := False;
  AError := '';

  if not FileExists(ACertFile) then
  begin
    AError := OwmTextFmt('wallet.err.file_not_found', 'Certificate file not found: %s', [ACertFile]);
    Exit;
  end;

  TMonitor.Enter(FLock);
  try
    LArgs := 'wallet add -wallet ' + QuoteArg(AWalletPath) +
      ' -trusted_cert -cert ' + QuoteArg(ACertFile) + BuildPwdArg(APassword);

    Result := RunOrapki(LArgs, LOut, AError);
    if Result then
    begin
      if Assigned(FLogger) then
        FLogger.Info(OwmTextFmt('wallet.log.added', 'Certificate added: %s', [ExtractFileName(ACertFile)]));
    end
    else if Assigned(FLogger) then
      FLogger.Warn(OwmTextFmt('wallet.log.add_failed', 'Add certificate failed: %s', [AError]));
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TOwmWalletService.RemoveCertificate(const AWalletPath, APassword,
  ACertSubject: string; out AError: string): Boolean;
var
  LOut: string;
  LArgs: string;
begin
  Result := False;
  AError := '';

  if Trim(ACertSubject) = '' then
  begin
    AError := OwmText('wallet.err.subject_empty', 'Certificate subject is empty');
    Exit;
  end;

  TMonitor.Enter(FLock);
  try
    LArgs := 'wallet remove -wallet ' + QuoteArg(AWalletPath) +
      ' -trusted_cert -dn ' + QuoteArg(ACertSubject) + BuildPwdArg(APassword);

    Result := RunOrapki(LArgs, LOut, AError);
    if Result then
    begin
      if Assigned(FLogger) then
        FLogger.Info(OwmTextFmt('wallet.log.removed', 'Certificate removed: %s', [ACertSubject]));
    end
    else if Assigned(FLogger) then
      FLogger.Warn(OwmTextFmt('wallet.log.remove_failed', 'Remove certificate failed: %s', [AError]));
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TOwmWalletService.CreateWallet(const AWalletPath, APassword: string;
  AAutoLogin, AAutoLoginLocal: Boolean; out AError: string): Boolean;
var
  LErrorCode: string;
begin
  Result := CreateWallet(AWalletPath, APassword, AAutoLogin, AAutoLoginLocal,
    AError, LErrorCode);
end;

function TOwmWalletService.CreateWallet(const AWalletPath, APassword: string;
  AAutoLogin, AAutoLoginLocal: Boolean; out AError, AErrorCode: string): Boolean;
var
  LOut: string;
  LArgs: string;
  LWalletPath: string;
  LEwalletPath: string;
  LCwalletPath: string;
begin
  Result := False;
  AError := '';
  AErrorCode := '';

  if Trim(APassword) = '' then
  begin
    AErrorCode := 'PasswordEmpty';
    AError := OwmText('wallet.err.password_empty', 'Wallet password is empty');
    Exit;
  end;

  if not TryNormalizeWalletPath(AWalletPath, LWalletPath, AError, AErrorCode) then
    Exit;

  TMonitor.Enter(FLock);
  try
    if not TDirectory.Exists(LWalletPath) then
    begin
      try
        TDirectory.CreateDirectory(LWalletPath);
      except
        on Exception do
        begin
          AErrorCode := 'InvalidPath';
          AError := OwmText('wallet.err.invalid_path', 'Invalid path');
          Exit;
        end;
      end;
    end;

    LEwalletPath := TPath.Combine(LWalletPath, 'ewallet.p12');
    LCwalletPath := TPath.Combine(LWalletPath, 'cwallet.sso');

    if FileExists(LEwalletPath) or FileExists(LCwalletPath) then
    begin
      AErrorCode := 'WalletExists';
      AError := OwmTextFmt('wallet.err.already_exists',
        'Wallet already exists in folder: %s', [LWalletPath]);
      Exit;
    end;

    LArgs := 'wallet create -wallet ' + QuoteArg(LWalletPath) + BuildPwdArg(APassword);
    if AAutoLoginLocal then
      LArgs := LArgs + ' -auto_login_local'
    else if AAutoLogin then
      LArgs := LArgs + ' -auto_login';

    Result := RunOrapki(LArgs, LOut, AError);
    if Result then
    begin
      if Assigned(FLogger) then
        FLogger.Info(OwmTextFmt('wallet.log.created', 'Wallet created: %s', [LWalletPath]));
    end
    else if Assigned(FLogger) then
      FLogger.Warn(OwmTextFmt('wallet.log.create_failed', 'Create wallet failed: %s', [AError]));
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TOwmWalletService.RemoveAllCertificates(const AWalletPath, APassword: string;
  const ACerts: TCertInfoArray; out ARemoved, AFailed: Integer; out AError: string): Boolean;
var
  LCert: TCertInfo;
  LErr: string;
begin
  AError := '';
  ARemoved := 0;
  AFailed := 0;

  for LCert in ACerts do
  begin
    if RemoveCertificate(AWalletPath, APassword, LCert.Subject, LErr) then
      Inc(ARemoved)
    else
    begin
      Inc(AFailed);
      if AError = '' then
        AError := LErr;
    end;
  end;

  Result := AFailed = 0;
end;

function TOwmWalletService.AddFromFolder(const AWalletPath, APassword,
  AFolder: string; out AAdded, ASkipped, AFailed: Integer; out AError: string): Boolean;
const
  CExts: array[0..3] of string = ('*.crt', '*.cer', '*.pem', '*.der');
var
  LFiles: TList<string>;
  LMask: string;
  LFile: string;
  LErr: string;
begin
  AError := '';
  AAdded := 0;
  ASkipped := 0;
  AFailed := 0;

  if not TDirectory.Exists(AFolder) then
  begin
    AError := OwmTextFmt('wallet.err.folder_not_found', 'Folder not found: %s', [AFolder]);
    Exit(False);
  end;

  LFiles := TList<string>.Create;
  try
    for LMask in CExts do
      LFiles.AddRange(TDirectory.GetFiles(AFolder, LMask, TSearchOption.soTopDirectoryOnly));

    for LFile in LFiles do
    begin
      if AddCertificate(AWalletPath, APassword, LFile, LErr) then
      begin
        Inc(AAdded);
      end
      else if ContainsText(LErr, 'already exists') then
      begin
        Inc(ASkipped);
      end
      else
      begin
        Inc(AFailed);
        if AError = '' then
          AError := LErr;
      end;
    end;
  finally
    LFiles.Free;
  end;

  Result := AFailed = 0;
end;

end.

unit uOwmEnhancedAclService;

interface

uses
  System.SysUtils,
  uOwmSettings,
  uOwmToolsDetector,
  uOwmLogger;

type
  TOwmAclRequest = record
    SchemaName: string;
    Host: string;
    Port: Integer; // 0 means "no port"
    AclType: string; // connect | resolve | http
  end;

  TOwmAclEntry = record
    Host: string;
    LowerPort: Integer;
    UpperPort: Integer;
    Principal: string;
    Privilege: string;
    IsGrant: Boolean;
  end;

  TOwmAclEntryArray = TArray<TOwmAclEntry>;

  TOwmEnhancedAclService = class
  private
    FLock: TObject;
    FTools: TOwmToolsInfo;
    FSettings: TOwmSettings;
    FLogger: TOwmLogger;

    function IsSimpleIdentifier(const AValue: string): Boolean;
    function IsSafeHost(const AValue: string): Boolean;
    function IsSafeNetService(const AValue: string): Boolean;
    function NormalizeAclType(const AValue: string): string;
    function EscapeSqlLiteral(const AValue: string): string;
    function EscapeSqlPlusQuoted(const AValue: string): string;
    function BuildTempSqlPath: string;
    function RunSql(const ASqlBody: string; out AOutput, AError: string): Boolean;
    function ParseAclListOutput(const AOutput: string): TOwmAclEntryArray;
    function ValidateRequest(const ARequest: TOwmAclRequest; out AError: string): Boolean;
  public
    constructor Create(const ATools: TOwmToolsInfo; ALogger: TOwmLogger);
    destructor Destroy; override;

    procedure ApplySettings(const ASettings: TOwmSettings);
    function GrantAcl(const ARequest: TOwmAclRequest; out AError: string): Boolean;
    function RevokeAcl(const ARequest: TOwmAclRequest; out AError: string): Boolean;
    function ListAcl(const ASchema, AHost: string; out AItems: TOwmAclEntryArray;
      out AError: string): Boolean;
    function SupportedAclTypes: TArray<string>;
  end;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.StrUtils,
  System.Math,
  System.IOUtils,
  uOwmCrypto,
  uOwmProcessRunner,
  uOwmI18n;

function QuoteArg(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '\"', [rfReplaceAll]) + '"';
end;

function ParseBoolLike(const AValue: string): Boolean;
var
  LValue: string;
begin
  LValue := Trim(LowerCase(AValue));
  Result := (LValue = 'true') or (LValue = 'yes') or (LValue = 'y') or (LValue = '1');
end;

{ TOwmEnhancedAclService }

constructor TOwmEnhancedAclService.Create(const ATools: TOwmToolsInfo; ALogger: TOwmLogger);
begin
  inherited Create;
  FLock := TObject.Create;
  FSettings := TOwmSettings.Create;
  FTools := ATools;
  FLogger := ALogger;
end;

destructor TOwmEnhancedAclService.Destroy;
begin
  FSettings.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TOwmEnhancedAclService.ApplySettings(const ASettings: TOwmSettings);
begin
  TMonitor.Enter(FLock);
  try
    FSettings.Assign(ASettings);
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TOwmEnhancedAclService.IsSimpleIdentifier(const AValue: string): Boolean;
var
  I: Integer;
  LValue: string;
begin
  LValue := Trim(AValue);
  if LValue = '' then
    Exit(False);

  if not CharInSet(LValue[1], ['A'..'Z', 'a'..'z']) then
    Exit(False);

  for I := 1 to Length(LValue) do
    if not CharInSet(LValue[I], ['A'..'Z', 'a'..'z', '0'..'9', '_', '$', '#']) then
      Exit(False);

  Result := True;
end;

function TOwmEnhancedAclService.IsSafeHost(const AValue: string): Boolean;
var
  I: Integer;
  LValue: string;
begin
  LValue := Trim(AValue);
  if LValue = '' then
    Exit(False);

  if Pos('..', LValue) > 0 then
    Exit(False);

  for I := 1 to Length(LValue) do
    if not CharInSet(LValue[I], ['A'..'Z', 'a'..'z', '0'..'9', '.', '-', '_', '*']) then
      Exit(False);

  Result := True;
end;

function TOwmEnhancedAclService.IsSafeNetService(const AValue: string): Boolean;
var
  I: Integer;
  LValue: string;
begin
  LValue := Trim(AValue);
  if LValue = '' then
    Exit(False);

  for I := 1 to Length(LValue) do
    if not CharInSet(LValue[I], ['A'..'Z', 'a'..'z', '0'..'9', '_', '.', '-', '$', '#']) then
      Exit(False);

  Result := True;
end;

function TOwmEnhancedAclService.NormalizeAclType(const AValue: string): string;
begin
  Result := LowerCase(Trim(AValue));
end;

function TOwmEnhancedAclService.EscapeSqlLiteral(const AValue: string): string;
begin
  Result := StringReplace(AValue, '''', '''''', [rfReplaceAll]);
end;

function TOwmEnhancedAclService.EscapeSqlPlusQuoted(const AValue: string): string;
begin
  Result := StringReplace(AValue, '"', '""', [rfReplaceAll]);
end;

function TOwmEnhancedAclService.BuildTempSqlPath: string;
var
  LDir: string;
begin
  LDir := TPath.Combine(TPath.GetTempPath, 'KappsWalletManager');
  if not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);

  Result := TPath.Combine(LDir,
    'acl_' + FormatDateTime('yyyymmdd_hhnnss_zzz', Now) + '_' + IntToStr(Random(10000)) + '.sql');
end;

function TOwmEnhancedAclService.RunSql(const ASqlBody: string; out AOutput,
  AError: string): Boolean;
var
  LResult: TProcessRunResult;
  LSqlFile: string;
  LSqlText: string;
  LSqlPlusPath: string;
  LTnsPath: string;
  LTnsAdmin: string;
  LOldTnsAdmin: string;
  LUser: string;
  LPassword: string;
  LPdb: string;
  LConnect: string;
  LRunArgs: string;
begin
  Result := False;
  AOutput := '';
  AError := '';

  TMonitor.Enter(FLock);
  try
    if not FSettings.EnhancedApiEnabled then
    begin
      AError := OwmText('api.err.enhanced_disabled', 'Enhanced API is disabled');
      Exit;
    end;

    if not FTools.SqlPlusAvailable then
    begin
      AError := OwmText('api.err.sqlplus_missing', 'sqlplus.exe not found');
      Exit;
    end;

    LSqlPlusPath := Trim(FTools.SqlPlusPath);
    LTnsPath := Trim(FSettings.Tns);
    LPdb := Trim(FSettings.PdbName);
    LUser := Trim(FSettings.AclAdminUser);
    LPassword := DecryptString(FSettings.AclAdminPasswordEnc);
  finally
    TMonitor.Exit(FLock);
  end;

  if LSqlPlusPath = '' then
  begin
    AError := OwmText('api.err.sqlplus_missing', 'sqlplus.exe not found');
    Exit;
  end;

  if not IsSafeNetService(LPdb) then
  begin
    AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['pdb']);
    Exit;
  end;

  if not IsSimpleIdentifier(LUser) then
  begin
    AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['aclAdminUser']);
    Exit;
  end;

  if LPassword = '' then
  begin
    AError := OwmText('settings.validation.acl_password',
      'ACL admin password is required when Enhanced API is enabled');
    Exit;
  end;

  if SameText(LUser, 'sys') then
    LConnect := 'connect "' + EscapeSqlPlusQuoted(LUser) + '"/"' +
      EscapeSqlPlusQuoted(LPassword) + '"@' + LPdb + ' as sysdba'
  else
    LConnect := 'connect "' + EscapeSqlPlusQuoted(LUser) + '"/"' +
      EscapeSqlPlusQuoted(LPassword) + '"@' + LPdb;

  LSqlText :=
    'set define off' + sLineBreak +
    'set echo off' + sLineBreak +
    'set verify off' + sLineBreak +
    'set heading off' + sLineBreak +
    'set feedback off' + sLineBreak +
    'set pagesize 0' + sLineBreak +
    'set linesize 32767' + sLineBreak +
    'set trimspool on' + sLineBreak +
    'set serveroutput on size 1000000' + sLineBreak +
    'whenever sqlerror exit sql.sqlcode' + sLineBreak +
    'whenever oserror exit 9' + sLineBreak +
    'connect /nolog' + sLineBreak +
    LConnect + sLineBreak +
    'alter session set container = "' + EscapeSqlPlusQuoted(LPdb) + '";' + sLineBreak +
    ASqlBody + sLineBreak +
    'exit' + sLineBreak;

  LSqlFile := BuildTempSqlPath;
  TFile.WriteAllText(LSqlFile, LSqlText, TEncoding.ASCII);
  try
    LOldTnsAdmin := GetEnvironmentVariable('TNS_ADMIN');
    LTnsAdmin := '';
    if FileExists(LTnsPath) then
      LTnsAdmin := ExcludeTrailingPathDelimiter(ExtractFilePath(LTnsPath));

    if LTnsAdmin <> '' then
      SetEnvironmentVariable('TNS_ADMIN', PChar(LTnsAdmin));
    try
      LRunArgs := '-L -S @' + QuoteArg(LSqlFile);
      if not RunProcessCapture(LSqlPlusPath, LRunArgs, 120000, LResult) then
      begin
        AError := LResult.ErrorMessage;
        Exit;
      end;
    finally
      if LOldTnsAdmin = '' then
        SetEnvironmentVariable('TNS_ADMIN', nil)
      else
        SetEnvironmentVariable('TNS_ADMIN', PChar(LOldTnsAdmin));
    end;
  finally
    if FileExists(LSqlFile) then
      TFile.Delete(LSqlFile);
  end;

  AOutput := Trim(LResult.OutputText);
  if LResult.TimedOut then
  begin
    AError := OwmText('api.err.sqlplus_timeout', 'sqlplus execution timeout');
    Exit;
  end;

  if LResult.ExitCode <> 0 then
  begin
    if AOutput <> '' then
      AError := AOutput
    else
      AError := OwmTextFmt('api.err.sqlplus_exit_code', 'sqlplus exited with code %d', [LResult.ExitCode]);
    Exit;
  end;

  Result := True;
end;

function TOwmEnhancedAclService.ValidateRequest(const ARequest: TOwmAclRequest;
  out AError: string): Boolean;
var
  LAclType: string;
begin
  AError := '';
  Result := False;

  if not IsSimpleIdentifier(ARequest.SchemaName) then
  begin
    AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['schema']);
    Exit;
  end;

  if not IsSafeHost(ARequest.Host) then
  begin
    AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['host']);
    Exit;
  end;

  LAclType := NormalizeAclType(ARequest.AclType);
  if (LAclType <> 'connect') and (LAclType <> 'resolve') and (LAclType <> 'http') then
  begin
    AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['aclType']);
    Exit;
  end;

  if (LAclType = 'connect') or (LAclType = 'http') then
  begin
    if not InRange(ARequest.Port, 1, 65535) then
    begin
      AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['port']);
      Exit;
    end;
  end
  else
  begin
    if (ARequest.Port <> 0) and (not InRange(ARequest.Port, 1, 65535)) then
    begin
      AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['port']);
      Exit;
    end;
  end;

  Result := True;
end;

function TOwmEnhancedAclService.GrantAcl(const ARequest: TOwmAclRequest;
  out AError: string): Boolean;
var
  LOutput: string;
  LAclType: string;
  LPortSql: string;
  LSql: string;

  function BuildAppendAceBlock(const APrivilege: string;
    AWithPort: Boolean): string;
  begin
    Result :=
      '  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(' + sLineBreak +
      '    host => ''' + EscapeSqlLiteral(ARequest.Host) + ''',' + sLineBreak;
    if AWithPort then
      Result := Result +
        '    lower_port => ' + LPortSql + ',' + sLineBreak +
        '    upper_port => ' + LPortSql + ',' + sLineBreak
    else
      Result := Result +
        '    lower_port => NULL,' + sLineBreak +
        '    upper_port => NULL,' + sLineBreak;
    Result := Result +
      '    ace => xs$ace_type(' + sLineBreak +
      '      privilege_list => xs$name_list(''' + APrivilege + '''),' + sLineBreak +
      '      principal_name => ''' + EscapeSqlLiteral(ARequest.SchemaName) + ''',' + sLineBreak +
      '      principal_type => xs_acl.ptype_db' + sLineBreak +
      '    )' + sLineBreak +
      '  );' + sLineBreak;
  end;

begin
  Result := False;
  AError := '';

  if not ValidateRequest(ARequest, AError) then
    Exit;

  LAclType := NormalizeAclType(ARequest.AclType);
  LPortSql := IntToStr(Max(0, ARequest.Port));

  LSql := 'BEGIN' + sLineBreak;
  if LAclType = 'connect' then
    LSql := LSql + BuildAppendAceBlock('connect', True)
  else if LAclType = 'resolve' then
    LSql := LSql + BuildAppendAceBlock('resolve', False)
  else
  begin
    // "http" = connect (port based) + resolve (host based)
    LSql := LSql + BuildAppendAceBlock('connect', True);
    LSql := LSql + BuildAppendAceBlock('resolve', False);
  end;
  LSql := LSql + 'END;' + sLineBreak + '/' + sLineBreak;

  Result := RunSql(LSql, LOutput, AError);
  if Result and Assigned(FLogger) then
    FLogger.Info(OwmTextFmt('api.msg.acl_granted', 'ACL granted for %s (%s)',
      [ARequest.SchemaName, ARequest.Host]));
end;

function TOwmEnhancedAclService.RevokeAcl(const ARequest: TOwmAclRequest;
  out AError: string): Boolean;
var
  LOutput: string;
  LAclType: string;
  LPortSql: string;
  LSql: string;

  function BuildRemoveAceBlock(const APrivilege: string;
    AWithPort: Boolean): string;
  begin
    Result :=
      '  DBMS_NETWORK_ACL_ADMIN.REMOVE_HOST_ACE(' + sLineBreak +
      '    host => ''' + EscapeSqlLiteral(ARequest.Host) + ''',' + sLineBreak;
    if AWithPort then
      Result := Result +
        '    lower_port => ' + LPortSql + ',' + sLineBreak +
        '    upper_port => ' + LPortSql + ',' + sLineBreak
    else
      Result := Result +
        '    lower_port => NULL,' + sLineBreak +
        '    upper_port => NULL,' + sLineBreak;
    Result := Result +
      '    ace => xs$ace_type(' + sLineBreak +
      '      privilege_list => xs$name_list(''' + APrivilege + '''),' + sLineBreak +
      '      principal_name => ''' + EscapeSqlLiteral(ARequest.SchemaName) + ''',' + sLineBreak +
      '      principal_type => xs_acl.ptype_db' + sLineBreak +
      '    )' + sLineBreak +
      '  );' + sLineBreak;
  end;

begin
  Result := False;
  AError := '';

  if not ValidateRequest(ARequest, AError) then
    Exit;

  LAclType := NormalizeAclType(ARequest.AclType);
  LPortSql := IntToStr(Max(0, ARequest.Port));

  LSql := 'BEGIN' + sLineBreak;
  if LAclType = 'connect' then
    LSql := LSql + BuildRemoveAceBlock('connect', True)
  else if LAclType = 'resolve' then
    LSql := LSql + BuildRemoveAceBlock('resolve', False)
  else
  begin
    LSql := LSql + BuildRemoveAceBlock('connect', True);
    LSql := LSql + BuildRemoveAceBlock('resolve', False);
  end;
  LSql := LSql + 'END;' + sLineBreak + '/' + sLineBreak;

  Result := RunSql(LSql, LOutput, AError);
  if Result and Assigned(FLogger) then
    FLogger.Info(OwmTextFmt('api.msg.acl_revoked', 'ACL revoked for %s (%s)',
      [ARequest.SchemaName, ARequest.Host]));
end;

function TOwmEnhancedAclService.ParseAclListOutput(
  const AOutput: string): TOwmAclEntryArray;
var
  LLines: TStringList;
  LParts: TStringList;
  I: Integer;
  LLine: string;
  LItem: TOwmAclEntry;
  LCount: Integer;
begin
  SetLength(Result, 0);

  LLines := TStringList.Create;
  LParts := TStringList.Create;
  try
    LLines.Text := AOutput;
    LParts.StrictDelimiter := True;
    LParts.Delimiter := '|';

    for I := 0 to LLines.Count - 1 do
    begin
      LLine := Trim(LLines[I]);
      if (LLine = '') or (Pos('|', LLine) <= 0) then
        Continue;

      LParts.DelimitedText := LLine;
      if LParts.Count < 6 then
        Continue;

      LItem.Host := Trim(LParts[0]);
      LItem.LowerPort := StrToIntDef(Trim(LParts[1]), 0);
      LItem.UpperPort := StrToIntDef(Trim(LParts[2]), 0);
      LItem.Principal := Trim(LParts[3]);
      LItem.Privilege := Trim(LParts[4]);
      LItem.IsGrant := ParseBoolLike(LParts[5]);

      LCount := Length(Result);
      SetLength(Result, LCount + 1);
      Result[LCount] := LItem;
    end;
  finally
    LParts.Free;
    LLines.Free;
  end;
end;

function TOwmEnhancedAclService.ListAcl(const ASchema, AHost: string;
  out AItems: TOwmAclEntryArray; out AError: string): Boolean;
var
  LSchema: string;
  LHost: string;
  LSql: string;
  LOutput: string;
begin
  Result := False;
  AError := '';
  SetLength(AItems, 0);

  LSchema := Trim(ASchema);
  LHost := Trim(AHost);

  if not IsSimpleIdentifier(LSchema) then
  begin
    AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['schema']);
    Exit;
  end;

  if (LHost <> '') and (not IsSafeHost(LHost)) then
  begin
    AError := OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['host']);
    Exit;
  end;

  LSql :=
    'select host||''|''||nvl(to_char(lower_port),'''')||''|''||nvl(to_char(upper_port),'''')||' +
    '''|''||principal||''|''||privilege||''|''||is_grant' + sLineBreak +
    '  from dba_host_aces' + sLineBreak +
    ' where upper(principal) = upper(''' + EscapeSqlLiteral(LSchema) + ''')';
  if LHost <> '' then
    LSql := LSql + sLineBreak +
      '   and upper(host) = upper(''' + EscapeSqlLiteral(LHost) + ''')';

  LSql := LSql + sLineBreak +
    ' order by host, lower_port, upper_port, privilege;' + sLineBreak;

  if not RunSql(LSql, LOutput, AError) then
    Exit;

  AItems := ParseAclListOutput(LOutput);
  Result := True;
end;

function TOwmEnhancedAclService.SupportedAclTypes: TArray<string>;
begin
  SetLength(Result, 3);
  Result[0] := 'connect';
  Result[1] := 'resolve';
  Result[2] := 'http';
end;

end.

unit uOwmToolsDetector;

interface

uses
  System.SysUtils;

type
  TOwmToolsInfo = record
    OrapkiAvailable: Boolean;
    SqlPlusAvailable: Boolean;
    OrapkiPath: string;
    SqlPlusPath: string;
  end;

function DetectOracleTools: TOwmToolsInfo;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils,
  Registry,
  uOwmProcessRunner;

function ExpandModulePath(const APath: string): string;
begin
  Result := ExpandFileName(Trim(APath));
end;

function NormalizeValue(const AValue: string): string;
begin
  Result := Trim(AValue);
  if Result = '' then
    Exit;

  Result := StringReplace(Result, '"', '', [rfReplaceAll]);
  Result := Trim(Result);
end;

function ExpandEnv(const AValue: string): string;
var
  LExpandedLen: DWORD;
  LSource: string;
begin
  LSource := NormalizeValue(AValue);
  if LSource = '' then
    Exit;

  Result := LSource;
  LExpandedLen := Winapi.Windows.ExpandEnvironmentStrings(PChar(LSource), nil, 0);
  if LExpandedLen > 0 then
  begin
    SetLength(Result, LExpandedLen - 1);
    if LExpandedLen > 1 then
      Winapi.Windows.ExpandEnvironmentStrings(PChar(LSource), PChar(Result), LExpandedLen);
  end;

  Result := NormalizeValue(Result);
end;

procedure AddUniqueString(ADest: TStrings; const AValue: string);
var
  I: Integer;
  LNorm: string;
begin
  LNorm := NormalizeValue(AValue);
  if LNorm = '' then
    Exit;

  for I := 0 to ADest.Count - 1 do
    if SameText(NormalizeValue(ADest[I]), LNorm) then
      Exit;

  ADest.Add(LNorm);
end;

procedure CollectPathDirectories(ADirs: TStrings);
var
  LPathEnv: string;
  LPathParts: TStringList;
  I: Integer;
  LDir: string;
begin
  LPathEnv := GetEnvironmentVariable('PATH');
  if LPathEnv = '' then
    Exit;

  LPathParts := TStringList.Create;
  try
    LPathParts.StrictDelimiter := True;
    LPathParts.Delimiter := ';';
    LPathParts.DelimitedText := LPathEnv;

    for I := 0 to LPathParts.Count - 1 do
    begin
      LDir := ExpandEnv(LPathParts[I]);
      if LDir <> '' then
        AddUniqueString(ADirs, LDir);
    end;
  finally
    LPathParts.Free;
  end;
end;

procedure ReadOracleHomesFromRegistry(const ABaseKey: string; AReg: TRegistry; ADest: TStrings;
  ASubKeys: TStrings);
var
  I: Integer;
  LHome: string;
  LKeyPath: string;
begin
  if not AReg.OpenKeyReadOnly(ABaseKey) then
    Exit;
  try
    if AReg.ValueExists('ORACLE_HOME') then
    begin
      LHome := ExpandEnv(AReg.ReadString('ORACLE_HOME'));
      if LHome <> '' then
        AddUniqueString(ADest, LHome);
    end;

    ASubKeys.Clear;
    AReg.GetKeyNames(ASubKeys);
  finally
    AReg.CloseKey;
  end;

  for I := 0 to ASubKeys.Count - 1 do
  begin
    LKeyPath := ABaseKey + '\' + ASubKeys[I];
    if not AReg.OpenKeyReadOnly(LKeyPath) then
      Continue;
    try
      if AReg.ValueExists('ORACLE_HOME') then
      begin
        LHome := ExpandEnv(AReg.ReadString('ORACLE_HOME'));
        if LHome <> '' then
          AddUniqueString(ADest, LHome);
      end;
    finally
      AReg.CloseKey;
    end;
  end;
end;

procedure CollectOracleHomes(ADest: TStrings);
var
  LReg: TRegistry;
  LSubKeys: TStringList;
  LHome: string;
begin
  LHome := ExpandEnv(GetEnvironmentVariable('ORACLE_HOME'));
  if LHome <> '' then
    AddUniqueString(ADest, LHome);

  LHome := ExpandEnv(GetEnvironmentVariable('ORACLE_BASE_HOME'));
  if LHome <> '' then
    AddUniqueString(ADest, LHome);

  LReg := TRegistry.Create(KEY_READ);
  LSubKeys := TStringList.Create;
  try
    LReg.RootKey := HKEY_LOCAL_MACHINE;
    ReadOracleHomesFromRegistry('SOFTWARE\Oracle', LReg, ADest, LSubKeys);
    ReadOracleHomesFromRegistry('SOFTWARE\WOW6432Node\Oracle', LReg, ADest, LSubKeys);
  finally
    LSubKeys.Free;
    LReg.Free;
  end;
end;

function ResolveFromDirectory(const ADirectory, ABaseName: string): string;
const
  CExts: array[0..3] of string = ('.exe', '.bat', '.cmd', '.com');
var
  J: Integer;
  LDir: string;
  LCandidate: string;
begin
  Result := '';
  LDir := ExpandEnv(ADirectory);
  if LDir = '' then
    Exit;

  for J := Low(CExts) to High(CExts) do
  begin
    LCandidate := IncludeTrailingPathDelimiter(LDir) + ABaseName + CExts[J];
    if TFile.Exists(LCandidate) then
      Exit(ExpandModulePath(LCandidate));
  end;
end;

function DetectViaWhere(const ACommandName: string): string;
var
  LResult: TProcessRunResult;
  LComSpec: string;
  LArgs: string;
  LLines: TStringList;
  I: Integer;
  LLine: string;
  LFirstCandidate: string;
begin
  Result := '';
  LFirstCandidate := '';

  LComSpec := ExpandEnv(GetEnvironmentVariable('ComSpec'));
  if LComSpec = '' then
    LComSpec := 'cmd.exe';

  LArgs := '/d /s /c where ' + ACommandName;
  if not RunProcessCapture(LComSpec, LArgs, 8000, LResult) then
    Exit;
  if LResult.ExitCode <> 0 then
    Exit;

  LLines := TStringList.Create;
  try
    LLines.Text := LResult.OutputText;
    for I := 0 to LLines.Count - 1 do
    begin
      LLine := ExpandEnv(Trim(LLines[I]));
      if LLine = '' then
        Continue;

      if LFirstCandidate = '' then
        LFirstCandidate := LLine;

      if TFile.Exists(LLine) then
        Exit(ExpandModulePath(LLine));
    end;
  finally
    LLines.Free;
  end;

  if LFirstCandidate <> '' then
    Result := LFirstCandidate;
end;

function ContainsTextCI(const AText, ASubText: string): Boolean;
begin
  Result := Pos(UpperCase(ASubText), UpperCase(AText)) > 0;
end;

function IsCommandNotFoundOutput(const AOutput: string): Boolean;
begin
  Result :=
    ContainsTextCI(AOutput, 'is not recognized as an internal or external command') or
    ContainsTextCI(AOutput, 'не является внутренней или внешней командой');
end;

function IsProbeOutputValid(const ACommandName, AOutput: string): Boolean;
var
  LCmd: string;
begin
  LCmd := UpperCase(Trim(ACommandName));
  if LCmd = 'ORAPKI' then
    Result := ContainsTextCI(AOutput, 'Oracle PKI Tool') or ContainsTextCI(AOutput, 'orapki [')
  else if LCmd = 'SQLPLUS' then
    Result := ContainsTextCI(AOutput, 'SQL*Plus')
  else
    Result := False;
end;

function DetectViaProbe(const ACommandName, AProbeArgs: string): string;
var
  LResult: TProcessRunResult;
  LComSpec: string;
  LArgs: string;
begin
  Result := '';

  LComSpec := ExpandEnv(GetEnvironmentVariable('ComSpec'));
  if LComSpec = '' then
    LComSpec := 'cmd.exe';

  LArgs := '/d /s /c "' + ACommandName;
  if Trim(AProbeArgs) <> '' then
    LArgs := LArgs + ' ' + AProbeArgs;
  LArgs := LArgs + '"';

  if not RunProcessCapture(LComSpec, LArgs, 8000, LResult) then
    Exit;
  if LResult.TimedOut then
    Exit;

  if IsCommandNotFoundOutput(LResult.OutputText) then
    Exit;

  if LResult.ExitCode = 9009 then
    Exit;

  if IsProbeOutputValid(ACommandName, LResult.OutputText) then
    Result := ACommandName;
end;

function DetectBinary(const ACommandName, AProbeArgs: string): string;
var
  LBaseName: string;
  LDirs: TStringList;
  LHomes: TStringList;
  I: Integer;
  LResolved: string;
begin
  Result := '';
  LBaseName := ChangeFileExt(ACommandName, '');

  LDirs := TStringList.Create;
  LHomes := TStringList.Create;
  try
    CollectPathDirectories(LDirs);
    CollectOracleHomes(LHomes);

    for I := 0 to LHomes.Count - 1 do
    begin
      AddUniqueString(LDirs, IncludeTrailingPathDelimiter(LHomes[I]) + 'bin');
      AddUniqueString(LDirs, LHomes[I]);
    end;

    for I := 0 to LDirs.Count - 1 do
    begin
      LResolved := ResolveFromDirectory(LDirs[I], LBaseName);
      if LResolved <> '' then
        Exit(LResolved);
    end;

    Result := DetectViaWhere(LBaseName);
    if Result <> '' then
      Exit;
  finally
    LHomes.Free;
    LDirs.Free;
  end;

  Result := DetectViaProbe(LBaseName, AProbeArgs);
end;

function DetectOracleTools: TOwmToolsInfo;
begin
  Result.OrapkiPath := DetectBinary('orapki', '-help');
  Result.SqlPlusPath := DetectBinary('sqlplus', '-v');
  Result.OrapkiAvailable := Result.OrapkiPath <> '';
  Result.SqlPlusAvailable := Result.SqlPlusPath <> '';
end;

end.

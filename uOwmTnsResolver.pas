unit uOwmTnsResolver;

interface

uses
  System.SysUtils;

function DetectTnsNamesFile(const APreferredPath: string = ''): string;
function ExtractTnsAliases(const ATnsFileName: string): TArray<string>;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils,
  System.StrUtils;

function NormalizePathValue(const AValue: string): string;
begin
  Result := Trim(AValue);
  if Result = '' then
    Exit;

  Result := StringReplace(Result, '"', '', [rfReplaceAll]);
  Result := Trim(Result);
end;

function ExpandEnvPath(const AValue: string): string;
var
  LExpandedLen: DWORD;
  LSource: string;
begin
  LSource := NormalizePathValue(AValue);
  if LSource = '' then
    Exit('');

  Result := LSource;
  LExpandedLen := Winapi.Windows.ExpandEnvironmentStrings(PChar(LSource), nil, 0);
  if LExpandedLen > 0 then
  begin
    SetLength(Result, LExpandedLen - 1);
    if LExpandedLen > 1 then
      Winapi.Windows.ExpandEnvironmentStrings(PChar(LSource), PChar(Result), LExpandedLen);
  end;

  Result := NormalizePathValue(Result);
end;

procedure AddUniquePath(ADest: TStrings; const APath: string);
var
  I: Integer;
  LNorm: string;
begin
  LNorm := NormalizePathValue(APath);
  if LNorm = '' then
    Exit;

  for I := 0 to ADest.Count - 1 do
    if SameText(NormalizePathValue(ADest[I]), LNorm) then
      Exit;

  ADest.Add(LNorm);
end;

function IsOraFile(const AFileName: string): Boolean;
begin
  Result := SameText(ExtractFileName(AFileName), 'tnsnames.ora');
end;

function FolderToTnsFile(const AFolder: string): string;
var
  LFolder: string;
begin
  LFolder := ExpandEnvPath(AFolder);
  if LFolder = '' then
    Exit('');

  Result := IncludeTrailingPathDelimiter(LFolder) + 'tnsnames.ora';
end;

function EnsureTnsFileCandidate(const APath: string): string;
var
  LPath: string;
begin
  LPath := ExpandEnvPath(APath);
  if LPath = '' then
    Exit('');

  if IsOraFile(LPath) then
    Result := LPath
  else
    Result := FolderToTnsFile(LPath);
end;

function FirstExistingFile(const AFiles: TStrings): string;
var
  I: Integer;
  LFile: string;
begin
  Result := '';
  for I := 0 to AFiles.Count - 1 do
  begin
    LFile := ExpandEnvPath(AFiles[I]);
    if (LFile <> '') and TFile.Exists(LFile) then
      Exit(ExpandFileName(LFile));
  end;
end;

procedure AddPathDerivedCandidates(ADest: TStrings);
var
  LPathEnv: string;
  LParts: TStringList;
  I: Integer;
  LDir: string;
  LParent: string;
begin
  LPathEnv := GetEnvironmentVariable('PATH');
  if LPathEnv = '' then
    Exit;

  LParts := TStringList.Create;
  try
    LParts.StrictDelimiter := True;
    LParts.Delimiter := ';';
    LParts.DelimitedText := LPathEnv;

    for I := 0 to LParts.Count - 1 do
    begin
      LDir := ExpandEnvPath(LParts[I]);
      if LDir = '' then
        Continue;

      if SameText(ExtractFileName(ExcludeTrailingPathDelimiter(LDir)), 'bin') then
      begin
        LParent := ExtractFileDir(ExcludeTrailingPathDelimiter(LDir));
        if LParent <> '' then
          AddUniquePath(ADest, FolderToTnsFile(TPath.Combine(LParent, 'network\admin')));
      end;
    end;
  finally
    LParts.Free;
  end;
end;

function DetectTnsNamesFile(const APreferredPath: string = ''): string;
var
  LCandidates: TStringList;
  LTnsAdmin: string;
  LOracleHome: string;
  LOracleBaseHome: string;
  LProgramFiles: string;
  LProgramFilesX86: string;
begin
  LCandidates := TStringList.Create;
  try
    AddUniquePath(LCandidates, EnsureTnsFileCandidate(APreferredPath));

    LTnsAdmin := ExpandEnvPath(GetEnvironmentVariable('TNS_ADMIN'));
    if LTnsAdmin <> '' then
      AddUniquePath(LCandidates, EnsureTnsFileCandidate(LTnsAdmin));

    LOracleHome := ExpandEnvPath(GetEnvironmentVariable('ORACLE_HOME'));
    if LOracleHome <> '' then
      AddUniquePath(LCandidates, FolderToTnsFile(TPath.Combine(LOracleHome, 'network\admin')));

    LOracleBaseHome := ExpandEnvPath(GetEnvironmentVariable('ORACLE_BASE_HOME'));
    if LOracleBaseHome <> '' then
      AddUniquePath(LCandidates, FolderToTnsFile(TPath.Combine(LOracleBaseHome, 'network\admin')));

    LProgramFiles := ExpandEnvPath(GetEnvironmentVariable('ProgramFiles'));
    if LProgramFiles <> '' then
      AddUniquePath(LCandidates, FolderToTnsFile(TPath.Combine(LProgramFiles, 'Oracle\network\admin')));

    LProgramFilesX86 := ExpandEnvPath(GetEnvironmentVariable('ProgramFiles(x86)'));
    if LProgramFilesX86 <> '' then
      AddUniquePath(LCandidates, FolderToTnsFile(TPath.Combine(LProgramFilesX86, 'Oracle\network\admin')));

    AddUniquePath(LCandidates, FolderToTnsFile(ExtractFilePath(ParamStr(0))));
    AddPathDerivedCandidates(LCandidates);

    Result := FirstExistingFile(LCandidates);
  finally
    LCandidates.Free;
  end;
end;

procedure AddUniqueAlias(AAliases: TStrings; const AAlias: string);
var
  I: Integer;
  LAlias: string;
begin
  LAlias := Trim(AAlias);
  if LAlias = '' then
    Exit;

  if ((Length(LAlias) >= 2) and (LAlias[1] = '"') and (LAlias[Length(LAlias)] = '"')) or
     ((Length(LAlias) >= 2) and (LAlias[1] = '''') and (LAlias[Length(LAlias)] = '''')) then
    LAlias := Trim(Copy(LAlias, 2, Length(LAlias) - 2));

  if (LAlias = '') or (Pos(' ', LAlias) > 0) or (Pos(#9, LAlias) > 0) then
    Exit;

  for I := 0 to AAliases.Count - 1 do
    if SameText(AAliases[I], LAlias) then
      Exit;

  AAliases.Add(LAlias);
end;

function StripLineComment(const ALine: string): string;
var
  LPosHash: Integer;
  LPosDoubleDash: Integer;
begin
  Result := ALine;

  LPosHash := Pos('#', Result);
  if LPosHash > 0 then
    Result := Copy(Result, 1, LPosHash - 1);

  LPosDoubleDash := Pos('--', Result);
  if LPosDoubleDash > 0 then
    Result := Copy(Result, 1, LPosDoubleDash - 1);

  Result := Trim(Result);
end;

procedure UpdateBracketLevel(const ALine: string; var ALevel: Integer);
var
  I: Integer;
begin
  for I := 1 to Length(ALine) do
  begin
    if ALine[I] = '(' then
      Inc(ALevel)
    else if ALine[I] = ')' then
    begin
      if ALevel > 0 then
        Dec(ALevel);
    end;
  end;
end;

procedure AddAliasesFromLeftPart(const ALeftPart: string; ADest: TStrings);
var
  LParts: TStringList;
  I: Integer;
begin
  LParts := TStringList.Create;
  try
    LParts.StrictDelimiter := True;
    LParts.Delimiter := ',';
    LParts.DelimitedText := ALeftPart;

    for I := 0 to LParts.Count - 1 do
      AddUniqueAlias(ADest, LParts[I]);
  finally
    LParts.Free;
  end;
end;

function ExtractTnsAliases(const ATnsFileName: string): TArray<string>;
var
  LLines: TStringList;
  LAliases: TStringList;
  I: Integer;
  LLine: string;
  LEqPos: Integer;
  LLeftPart: string;
  LLevel: Integer;
begin
  SetLength(Result, 0);

  if not TFile.Exists(ATnsFileName) then
    Exit;

  LLines := TStringList.Create;
  LAliases := TStringList.Create;
  try
    try
      LLines.LoadFromFile(ATnsFileName, TEncoding.UTF8);
    except
      LLines.LoadFromFile(ATnsFileName);
    end;

    LLevel := 0;
    for I := 0 to LLines.Count - 1 do
    begin
      LLine := StripLineComment(LLines[I]);
      if LLine = '' then
        Continue;

      LEqPos := Pos('=', LLine);
      if (LLevel = 0) and (LEqPos > 1) then
      begin
        LLeftPart := Trim(Copy(LLine, 1, LEqPos - 1));
        if (LLeftPart <> '') and (Pos('(', LLeftPart) = 0) then
          AddAliasesFromLeftPart(LLeftPart, LAliases);
      end;

      UpdateBracketLevel(LLine, LLevel);
    end;

    SetLength(Result, LAliases.Count);
    for I := 0 to LAliases.Count - 1 do
      Result[I] := LAliases[I];
  finally
    LAliases.Free;
    LLines.Free;
  end;
end;

end.

unit uOwmSettings;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections;

type
  TOwmApiAuthType = (aatHeader, aatBasic);
  TOwmAllowedHostsMode = (ahmAll, ahmList);

  TOwmSettings = class
  public
    Language: string;

    WalletPath: string;
    WalletPasswordEnc: string;

    ApiEnabled: Boolean;
    ApiRunning: Boolean;
    ApiPort: Integer;
    ApiAuthType: TOwmApiAuthType;
    ApiKeyEnc: string;
    ApiBasicLoginEnc: string;
    ApiBasicPasswordEnc: string;

    AllowedHostsMode: TOwmAllowedHostsMode;
    AllowedIps: TArray<string>;

    EnhancedApiEnabled: Boolean;
    PdbName: string;
    AclAdminUser: string;
    AclAdminPasswordEnc: string;
    Tns: string;

    constructor Create;
    procedure Assign(const ASource: TOwmSettings);
  end;

  TOwmSettingsService = class
  private
    FBaseDir: string;
    FConfigDir: string;
    FSettingsPath: string;
    procedure EnsureFolders;
    function SettingsToJson(const ASettings: TOwmSettings): TJSONObject;
    function SettingsFromJson(AObj: TJSONObject): TOwmSettings;
  public
    constructor Create(const ABaseDir: string);
    function Load: TOwmSettings;
    procedure Save(const ASettings: TOwmSettings);
    function CreateDefault: TOwmSettings;
    property SettingsPath: string read FSettingsPath;
  end;

function ApiAuthTypeToString(AValue: TOwmApiAuthType): string;
function StringToApiAuthType(const AValue: string): TOwmApiAuthType;
function AllowedHostsModeToString(AValue: TOwmAllowedHostsMode): string;
function StringToAllowedHostsMode(const AValue: string): TOwmAllowedHostsMode;

implementation

uses
  System.IOUtils,
  System.StrUtils;

function JsonString(const AObj: TJSONObject; const AName, ADefault: string): string;
var
  LValue: TJSONValue;
begin
  Result := ADefault;
  if AObj = nil then
    Exit;

  LValue := AObj.Values[AName];
  if LValue <> nil then
    Result := LValue.Value;
end;

function JsonBoolean(const AObj: TJSONObject; const AName: string; ADefault: Boolean): Boolean;
var
  LValue: TJSONValue;
begin
  Result := ADefault;
  if AObj = nil then
    Exit;

  LValue := AObj.Values[AName];
  if LValue = nil then
    Exit;

  if LValue is TJSONTrue then
    Exit(True);
  if LValue is TJSONFalse then
    Exit(False);

  if SameText(LValue.Value, 'true') then
    Result := True
  else if SameText(LValue.Value, 'false') then
    Result := False;
end;

function JsonInteger(const AObj: TJSONObject; const AName: string; ADefault: Integer): Integer;
var
  LValue: TJSONValue;
  LInt: Integer;
begin
  Result := ADefault;
  if AObj = nil then
    Exit;

  LValue := AObj.Values[AName];
  if LValue = nil then
    Exit;

  if TryStrToInt(LValue.Value, LInt) then
    Result := LInt;
end;

function JsonArrayToStrings(const AObj: TJSONObject; const AName: string): TArray<string>;
var
  LArray: TJSONArray;
  I: Integer;
begin
  SetLength(Result, 0);
  if AObj = nil then
    Exit;

  LArray := AObj.Values[AName] as TJSONArray;
  if LArray = nil then
    Exit;

  SetLength(Result, LArray.Count);
  for I := 0 to LArray.Count - 1 do
    Result[I] := LArray.Items[I].Value;
end;

function StringsToJsonArray(const AValues: TArray<string>): TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;
  for I := 0 to High(AValues) do
    Result.Add(AValues[I]);
end;

function ApiAuthTypeToString(AValue: TOwmApiAuthType): string;
begin
  case AValue of
    aatHeader:
      Result := 'header';
    aatBasic:
      Result := 'basic';
  else
    Result := 'header';
  end;
end;

function StringToApiAuthType(const AValue: string): TOwmApiAuthType;
begin
  if SameText(Trim(AValue), 'basic') then
    Result := aatBasic
  else
    Result := aatHeader;
end;

function AllowedHostsModeToString(AValue: TOwmAllowedHostsMode): string;
begin
  case AValue of
    ahmAll:
      Result := 'all';
    ahmList:
      Result := 'list';
  else
    Result := 'all';
  end;
end;

function StringToAllowedHostsMode(const AValue: string): TOwmAllowedHostsMode;
begin
  if SameText(Trim(AValue), 'list') then
    Result := ahmList
  else
    Result := ahmAll;
end;

{ TOwmSettings }

constructor TOwmSettings.Create;
begin
  inherited Create;
  Language := 'RU';

  WalletPath := '';
  WalletPasswordEnc := '';

  ApiEnabled := False;
  ApiRunning := False;
  ApiPort := 8089;
  ApiAuthType := aatHeader;
  ApiKeyEnc := '';
  ApiBasicLoginEnc := '';
  ApiBasicPasswordEnc := '';

  AllowedHostsMode := ahmAll;
  AllowedIps := [];

  EnhancedApiEnabled := False;
  PdbName := '';
  AclAdminUser := '';
  AclAdminPasswordEnc := '';
  Tns := '';
end;

procedure TOwmSettings.Assign(const ASource: TOwmSettings);
begin
  if ASource = nil then
    Exit;

  Language := ASource.Language;

  WalletPath := ASource.WalletPath;
  WalletPasswordEnc := ASource.WalletPasswordEnc;

  ApiEnabled := ASource.ApiEnabled;
  ApiRunning := ASource.ApiRunning;
  ApiPort := ASource.ApiPort;
  ApiAuthType := ASource.ApiAuthType;
  ApiKeyEnc := ASource.ApiKeyEnc;
  ApiBasicLoginEnc := ASource.ApiBasicLoginEnc;
  ApiBasicPasswordEnc := ASource.ApiBasicPasswordEnc;

  AllowedHostsMode := ASource.AllowedHostsMode;
  AllowedIps := Copy(ASource.AllowedIps);

  EnhancedApiEnabled := ASource.EnhancedApiEnabled;
  PdbName := ASource.PdbName;
  AclAdminUser := ASource.AclAdminUser;
  AclAdminPasswordEnc := ASource.AclAdminPasswordEnc;
  Tns := ASource.Tns;
end;

{ TOwmSettingsService }

constructor TOwmSettingsService.Create(const ABaseDir: string);
begin
  inherited Create;
  FBaseDir := IncludeTrailingPathDelimiter(ABaseDir);
  FConfigDir := TPath.Combine(FBaseDir, 'config');
  FSettingsPath := TPath.Combine(FConfigDir, 'settings.json');
end;

procedure TOwmSettingsService.EnsureFolders;
begin
  if not TDirectory.Exists(FConfigDir) then
    TDirectory.CreateDirectory(FConfigDir);
end;

function TOwmSettingsService.CreateDefault: TOwmSettings;
begin
  Result := TOwmSettings.Create;
end;

function TOwmSettingsService.SettingsToJson(const ASettings: TOwmSettings): TJSONObject;
var
  LRoot: TJSONObject;
  LWallet: TJSONObject;
  LApi: TJSONObject;
  LEnhanced: TJSONObject;
begin
  LRoot := TJSONObject.Create;

  LRoot.AddPair('language', ASettings.Language);

  LWallet := TJSONObject.Create;
  LWallet.AddPair('path', ASettings.WalletPath);
  LWallet.AddPair('passwordEnc', ASettings.WalletPasswordEnc);
  LRoot.AddPair('wallet', LWallet);

  LApi := TJSONObject.Create;
  LApi.AddPair('enabled', TJSONBool.Create(ASettings.ApiEnabled));
  LApi.AddPair('running', TJSONBool.Create(ASettings.ApiRunning));
  LApi.AddPair('port', TJSONNumber.Create(ASettings.ApiPort));
  LApi.AddPair('authType', ApiAuthTypeToString(ASettings.ApiAuthType));
  LApi.AddPair('apiKeyEnc', ASettings.ApiKeyEnc);
  LApi.AddPair('basicLoginEnc', ASettings.ApiBasicLoginEnc);
  LApi.AddPair('basicPasswordEnc', ASettings.ApiBasicPasswordEnc);
  LApi.AddPair('allowedHostsMode', AllowedHostsModeToString(ASettings.AllowedHostsMode));
  LApi.AddPair('allowedIps', StringsToJsonArray(ASettings.AllowedIps));
  LRoot.AddPair('api', LApi);

  LEnhanced := TJSONObject.Create;
  LEnhanced.AddPair('enabled', TJSONBool.Create(ASettings.EnhancedApiEnabled));
  LEnhanced.AddPair('pdbName', ASettings.PdbName);
  LEnhanced.AddPair('aclAdminUser', ASettings.AclAdminUser);
  LEnhanced.AddPair('aclAdminPasswordEnc', ASettings.AclAdminPasswordEnc);
  LEnhanced.AddPair('tns', ASettings.Tns);
  LRoot.AddPair('enhancedApi', LEnhanced);

  Result := LRoot;
end;

function TOwmSettingsService.SettingsFromJson(AObj: TJSONObject): TOwmSettings;
var
  LWallet: TJSONObject;
  LApi: TJSONObject;
  LEnhanced: TJSONObject;
begin
  Result := CreateDefault;
  if AObj = nil then
    Exit;

  Result.Language := JsonString(AObj, 'language', Result.Language);

  LWallet := AObj.Values['wallet'] as TJSONObject;
  Result.WalletPath := JsonString(LWallet, 'path', Result.WalletPath);
  Result.WalletPasswordEnc := JsonString(LWallet, 'passwordEnc', Result.WalletPasswordEnc);

  LApi := AObj.Values['api'] as TJSONObject;
  Result.ApiEnabled := JsonBoolean(LApi, 'enabled', Result.ApiEnabled);
  Result.ApiRunning := JsonBoolean(LApi, 'running', Result.ApiRunning);
  Result.ApiPort := JsonInteger(LApi, 'port', Result.ApiPort);
  Result.ApiAuthType := StringToApiAuthType(JsonString(LApi, 'authType', ApiAuthTypeToString(Result.ApiAuthType)));
  Result.ApiKeyEnc := JsonString(LApi, 'apiKeyEnc', Result.ApiKeyEnc);
  Result.ApiBasicLoginEnc := JsonString(LApi, 'basicLoginEnc', Result.ApiBasicLoginEnc);
  Result.ApiBasicPasswordEnc := JsonString(LApi, 'basicPasswordEnc', Result.ApiBasicPasswordEnc);
  Result.AllowedHostsMode := StringToAllowedHostsMode(JsonString(LApi, 'allowedHostsMode',
    AllowedHostsModeToString(Result.AllowedHostsMode)));
  Result.AllowedIps := JsonArrayToStrings(LApi, 'allowedIps');

  LEnhanced := AObj.Values['enhancedApi'] as TJSONObject;
  Result.EnhancedApiEnabled := JsonBoolean(LEnhanced, 'enabled', Result.EnhancedApiEnabled);
  Result.PdbName := JsonString(LEnhanced, 'pdbName', Result.PdbName);
  Result.AclAdminUser := JsonString(LEnhanced, 'aclAdminUser', Result.AclAdminUser);
  Result.AclAdminPasswordEnc := JsonString(LEnhanced, 'aclAdminPasswordEnc', Result.AclAdminPasswordEnc);
  Result.Tns := JsonString(LEnhanced, 'tns', Result.Tns);

  if Result.ApiPort <= 0 then
    Result.ApiPort := 8089;
end;

function TOwmSettingsService.Load: TOwmSettings;
var
  LText: string;
  LJson: TJSONValue;
begin
  EnsureFolders;

  if not TFile.Exists(FSettingsPath) then
  begin
    Result := CreateDefault;
    Save(Result);
    Exit;
  end;

  LText := TFile.ReadAllText(FSettingsPath, TEncoding.UTF8);
  LJson := TJSONObject.ParseJSONValue(LText);
  try
    if not (LJson is TJSONObject) then
      Exit(CreateDefault);

    Result := SettingsFromJson(TJSONObject(LJson));
  finally
    LJson.Free;
  end;
end;

procedure TOwmSettingsService.Save(const ASettings: TOwmSettings);
var
  LJson: TJSONObject;
begin
  EnsureFolders;
  LJson := SettingsToJson(ASettings);
  try
    TFile.WriteAllText(FSettingsPath, LJson.ToJSON, TEncoding.UTF8);
  finally
    LJson.Free;
  end;
end;

end.

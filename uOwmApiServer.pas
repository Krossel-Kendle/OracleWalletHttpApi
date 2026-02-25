unit uOwmApiServer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.SyncObjs,
  IdContext,
  IdCustomHTTPServer,
  IdHTTPServer,
  uOwmSettings,
  uOwmToolsDetector,
  uOwmTypes,
  uOwmWalletService,
  uOwmEnhancedAclService,
  uOwmLogger;

type
  TOwmApiServer = class
  private
    FCritSec: TCriticalSection;
    FServer: TIdHTTPServer;
    FSettings: TOwmSettings;
    FTools: TOwmToolsInfo;
    FWalletService: TOwmWalletService;
    FEnhancedAclService: TOwmEnhancedAclService;
    FLogger: TOwmLogger;
    FOnStateChanged: TNotifyEvent;

    procedure HandleCommand(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);

    procedure SendJson(AResponseInfo: TIdHTTPResponseInfo; AStatus: Integer; AJson: TJSONValue);
    procedure SendJsonApi(AResponseInfo: TIdHTTPResponseInfo; AStatus: Integer;
      AData: TJSONValue; AMeta: TJSONObject = nil);
    procedure SendError(AResponseInfo: TIdHTTPResponseInfo; AStatus: Integer;
      const ACode, AMessage: string);
    function BuildJsonApiVersion: TJSONObject;
    function BuildResource(const AType, AId: string; AAttributes: TJSONObject): TJSONObject;
    function BuildCertId(const ACert: TCertInfo): string;
    function BuildCertAttributes(const ACert: TCertInfo; AIncludeDaysLeft: Boolean): TJSONObject;
    function RequestBodyAsText(ARequestInfo: TIdHTTPRequestInfo): string;
    function GetJsonString(AObj: TJSONObject; const AName: string): string;
    function GetJsonInteger(AObj: TJSONObject; const AName: string;
      ADefault: Integer): Integer;
    function GetJsonBoolean(AObj: TJSONObject; const AName: string;
      ADefault: Boolean): Boolean;
    function ExtractJsonApiAttributes(AObj: TJSONObject; const AExpectedType: string;
      out AAttributes: TJSONObject; out AErrorCode, AErrorMessage: string): Boolean;
    procedure AddCertJsonItem(AArray: TJSONArray; const ACert: TCertInfo;
      AIncludeDaysLeft: Boolean = False);

    function IsAuthorized(ARequestInfo: TIdHTTPRequestInfo): Boolean;
    function DecodeBasicAuth(const AHeader: string; out AUser, APassword: string): Boolean;
    function IsHostAllowed(AContext: TIdContext): Boolean;

    function BuildTempFilePath(const AExt: string): string;
    function DownloadToFile(const AUrl, AFileName: string; out AError: string): Boolean;
    function BuildOpenApiDocument: TJSONObject;

    procedure NotifyStateChanged;
  public
    constructor Create(AWalletService: TOwmWalletService; ALogger: TOwmLogger;
      const ATools: TOwmToolsInfo);
    destructor Destroy; override;

    procedure ApplySettings(const ASettings: TOwmSettings);
    function Start(out AError: string): Boolean;
    procedure Stop;
    function IsRunning: Boolean;

    property OnStateChanged: TNotifyEvent read FOnStateChanged write FOnStateChanged;
  end;

implementation

uses
  System.StrUtils,
  System.Math,
  System.DateUtils,
  System.NetEncoding,
  System.IOUtils,
  System.Net.URLClient,
  System.Net.HttpClient,
  IdURI,
  uOwmI18n,
  uOwmCrypto;

constructor TOwmApiServer.Create(AWalletService: TOwmWalletService; ALogger: TOwmLogger;
  const ATools: TOwmToolsInfo);
begin
  inherited Create;
  FCritSec := TCriticalSection.Create;
  FSettings := TOwmSettings.Create;
  FTools := ATools;
  FWalletService := AWalletService;
  FLogger := ALogger;
  FEnhancedAclService := TOwmEnhancedAclService.Create(ATools, ALogger);

  FServer := TIdHTTPServer.Create(nil);
  FServer.OnCommandGet := HandleCommand;
  FServer.OnCommandOther := HandleCommand;
  FServer.ParseParams := True;
end;

destructor TOwmApiServer.Destroy;
begin
  Stop;
  FServer.Free;
  FEnhancedAclService.Free;
  FSettings.Free;
  FCritSec.Free;
  inherited Destroy;
end;

procedure TOwmApiServer.ApplySettings(const ASettings: TOwmSettings);
begin
  FCritSec.Acquire;
  try
    FSettings.Assign(ASettings);
  finally
    FCritSec.Release;
  end;
  FEnhancedAclService.ApplySettings(ASettings);
end;

function TOwmApiServer.Start(out AError: string): Boolean;
var
  LPort: Integer;
begin
  Result := False;
  AError := '';

  FCritSec.Acquire;
  try
    if FServer.Active then
      Exit(True);

    LPort := FSettings.ApiPort;
    if (LPort <= 0) or (LPort > 65535) then
      LPort := 8089;

    try
      FServer.Bindings.Clear;
      with FServer.Bindings.Add do
      begin
        IP := '0.0.0.0';
        Port := LPort;
      end;

      FServer.DefaultPort := LPort;
      FServer.Active := True;
      if Assigned(FLogger) then
        FLogger.Info(OwmTextFmt('api.log.started', 'API server started on port %d', [LPort]));
      Result := True;
    except
      on E: Exception do
      begin
        AError := E.Message;
        if Assigned(FLogger) then
          FLogger.Error(OwmTextFmt('api.log.start_failed', 'API server start failed: %s', [E.Message]));
      end;
    end;
  finally
    FCritSec.Release;
  end;

  NotifyStateChanged;
end;

procedure TOwmApiServer.Stop;
begin
  FCritSec.Acquire;
  try
    if FServer.Active then
    begin
      FServer.Active := False;
      if Assigned(FLogger) then
        FLogger.Info(OwmText('api.log.stopped', 'API server stopped'));
    end;
  finally
    FCritSec.Release;
  end;

  NotifyStateChanged;
end;

function TOwmApiServer.IsRunning: Boolean;
begin
  FCritSec.Acquire;
  try
    Result := FServer.Active;
  finally
    FCritSec.Release;
  end;
end;

procedure TOwmApiServer.NotifyStateChanged;
begin
  if Assigned(FOnStateChanged) then
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnStateChanged) then
          FOnStateChanged(Self);
      end);
end;

procedure TOwmApiServer.SendJson(AResponseInfo: TIdHTTPResponseInfo; AStatus: Integer;
  AJson: TJSONValue);
begin
  try
    AResponseInfo.ResponseNo := AStatus;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := AJson.ToJSON;
  finally
    AJson.Free;
  end;
end;

function TOwmApiServer.BuildJsonApiVersion: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('version', '1.0');
end;

procedure TOwmApiServer.SendJsonApi(AResponseInfo: TIdHTTPResponseInfo; AStatus: Integer;
  AData: TJSONValue; AMeta: TJSONObject);
var
  LDoc: TJSONObject;
begin
  LDoc := TJSONObject.Create;
  try
    LDoc.AddPair('jsonapi', BuildJsonApiVersion);
    if Assigned(AData) then
      LDoc.AddPair('data', AData)
    else
      LDoc.AddPair('data', TJSONNull.Create);
    if Assigned(AMeta) then
      LDoc.AddPair('meta', AMeta);

    AResponseInfo.ResponseNo := AStatus;
    AResponseInfo.ContentType := 'application/vnd.api+json';
    AResponseInfo.ContentText := LDoc.ToJSON;
  finally
    LDoc.Free;
  end;
end;

procedure TOwmApiServer.SendError(AResponseInfo: TIdHTTPResponseInfo; AStatus: Integer;
  const ACode, AMessage: string);
var
  LDoc: TJSONObject;
  LErrors: TJSONArray;
  LErrorObj: TJSONObject;
begin
  LDoc := TJSONObject.Create;
  try
    LDoc.AddPair('jsonapi', BuildJsonApiVersion);
    LErrors := TJSONArray.Create;
    LErrorObj := TJSONObject.Create;
    LErrorObj.AddPair('status', IntToStr(AStatus));
    LErrorObj.AddPair('code', ACode);
    LErrorObj.AddPair('title', ACode);
    LErrorObj.AddPair('detail', AMessage);
    LErrors.AddElement(LErrorObj);
    LDoc.AddPair('errors', LErrors);

    AResponseInfo.ResponseNo := AStatus;
    AResponseInfo.ContentType := 'application/vnd.api+json';
    AResponseInfo.ContentText := LDoc.ToJSON;
  finally
    LDoc.Free;
  end;
end;

function TOwmApiServer.BuildResource(const AType, AId: string; AAttributes: TJSONObject): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('type', AType);
  if Trim(AId) <> '' then
    Result.AddPair('id', AId);
  if not Assigned(AAttributes) then
    AAttributes := TJSONObject.Create;
  Result.AddPair('attributes', AAttributes);
end;

function TOwmApiServer.RequestBodyAsText(ARequestInfo: TIdHTTPRequestInfo): string;
var
  LStream: TStringStream;
begin
  Result := '';

  if ARequestInfo.PostStream <> nil then
  begin
    LStream := TStringStream.Create('', TEncoding.UTF8);
    try
      ARequestInfo.PostStream.Position := 0;
      LStream.CopyFrom(ARequestInfo.PostStream, ARequestInfo.PostStream.Size);
      Result := LStream.DataString;
    finally
      LStream.Free;
    end;
    Exit;
  end;

  Result := ARequestInfo.UnparsedParams;
end;

function TOwmApiServer.GetJsonString(AObj: TJSONObject; const AName: string): string;
var
  LValue: TJSONValue;
begin
  Result := '';
  if AObj = nil then
    Exit;

  LValue := AObj.Values[AName];
  if LValue <> nil then
    Result := Trim(LValue.Value);
end;

function TOwmApiServer.GetJsonInteger(AObj: TJSONObject; const AName: string;
  ADefault: Integer): Integer;
var
  LValue: TJSONValue;
  LNumber: Integer;
begin
  Result := ADefault;
  if AObj = nil then
    Exit;

  LValue := AObj.Values[AName];
  if (LValue = nil) or (Trim(LValue.Value) = '') then
    Exit;

  if TryStrToInt(Trim(LValue.Value), LNumber) then
    Result := LNumber;
end;

function TOwmApiServer.GetJsonBoolean(AObj: TJSONObject; const AName: string;
  ADefault: Boolean): Boolean;
var
  LValue: TJSONValue;
  LText: string;
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

  LText := LowerCase(Trim(LValue.Value));
  if (LText = 'true') or (LText = '1') or (LText = 'yes') then
    Result := True
  else if (LText = 'false') or (LText = '0') or (LText = 'no') then
    Result := False;
end;

function TOwmApiServer.ExtractJsonApiAttributes(AObj: TJSONObject; const AExpectedType: string;
  out AAttributes: TJSONObject; out AErrorCode, AErrorMessage: string): Boolean;
var
  LDataObj: TJSONObject;
  LDataValue: TJSONValue;
  LAttrsValue: TJSONValue;
  LType: string;
begin
  Result := False;
  AAttributes := nil;
  AErrorCode := '';
  AErrorMessage := '';

  if AObj = nil then
  begin
    AErrorCode := 'InvalidBody';
    AErrorMessage := OwmText('api.err.invalid_json', 'JSON body required');
    Exit;
  end;

  LDataValue := AObj.Values['data'];
  if LDataValue = nil then
  begin
    AAttributes := AObj;
    Exit(True);
  end;

  if not (LDataValue is TJSONObject) then
  begin
    AErrorCode := 'InvalidBody';
    AErrorMessage := OwmText('api.err.jsonapi_data_object',
      'JSON:API request requires data object');
    Exit;
  end;

  LDataObj := TJSONObject(LDataValue);
  LType := GetJsonString(LDataObj, 'type');
  if LType = '' then
  begin
    AErrorCode := 'InvalidBody';
    AErrorMessage := OwmText('api.err.jsonapi_type_required',
      'JSON:API request requires data.type');
    Exit;
  end;

  if (AExpectedType <> '') and (not SameText(LType, AExpectedType)) then
  begin
    AErrorCode := 'InvalidBody';
    AErrorMessage := OwmTextFmt('api.err.jsonapi_type_mismatch',
      'JSON:API data.type must be %s', [AExpectedType]);
    Exit;
  end;

  LAttrsValue := LDataObj.Values['attributes'];
  if not (LAttrsValue is TJSONObject) then
  begin
    AErrorCode := 'InvalidBody';
    AErrorMessage := OwmText('api.err.jsonapi_attributes_required',
      'JSON:API request requires data.attributes object');
    Exit;
  end;

  AAttributes := TJSONObject(LAttrsValue);
  Result := True;
end;

function TOwmApiServer.BuildCertId(const ACert: TCertInfo): string;
begin
  Result := Trim(ACert.Thumbprint);
  if Result = '' then
    Result := Trim(CertDisplayName(ACert));
  if Result = '' then
    Result := Trim(ACert.Subject);
  if Result = '' then
    Result := 'unknown';
end;

function TOwmApiServer.BuildCertAttributes(const ACert: TCertInfo;
  AIncludeDaysLeft: Boolean): TJSONObject;
var
  LDaysLeft: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', CertDisplayName(ACert));
  Result.AddPair('subject', ACert.Subject);
  Result.AddPair('issuer', ACert.Issuer);
  Result.AddPair('notAfter', ACert.NotAfterText);
  Result.AddPair('thumbprint', ACert.Thumbprint);
  Result.AddPair('sourcePath', ACert.SourcePath);

  if AIncludeDaysLeft then
  begin
    if ACert.NotAfter > 0 then
      LDaysLeft := Trunc(ACert.NotAfter) - Trunc(Now)
    else
      LDaysLeft := -1;
    Result.AddPair('daysLeft', TJSONNumber.Create(LDaysLeft));
  end;
end;

procedure TOwmApiServer.AddCertJsonItem(AArray: TJSONArray; const ACert: TCertInfo;
  AIncludeDaysLeft: Boolean);
begin
  AArray.AddElement(BuildResource('certificates', BuildCertId(ACert),
    BuildCertAttributes(ACert, AIncludeDaysLeft)));
end;

function TOwmApiServer.DecodeBasicAuth(const AHeader: string; out AUser,
  APassword: string): Boolean;
var
  LRaw: string;
  LDecoded: string;
  LPos: Integer;
begin
  Result := False;
  AUser := '';
  APassword := '';

  if not StartsText('Basic ', AHeader) then
    Exit;

  LRaw := Trim(Copy(AHeader, 7, MaxInt));
  try
    LDecoded := TEncoding.UTF8.GetString(TNetEncoding.Base64.DecodeStringToBytes(LRaw));
    LPos := Pos(':', LDecoded);
    if LPos <= 0 then
      Exit;

    AUser := Copy(LDecoded, 1, LPos - 1);
    APassword := Copy(LDecoded, LPos + 1, MaxInt);
    Result := True;
  except
    on Exception do
      Result := False;
  end;
end;

function TOwmApiServer.IsAuthorized(ARequestInfo: TIdHTTPRequestInfo): Boolean;
var
  LAuthMode: TOwmApiAuthType;
  LHeaderKey: string;
  LConfiguredKey: string;
  LConfiguredLogin: string;
  LConfiguredPassword: string;
  LUser: string;
  LPass: string;
begin
  FCritSec.Acquire;
  try
    LAuthMode := FSettings.ApiAuthType;
    LConfiguredKey := Trim(DecryptString(FSettings.ApiKeyEnc));
    LConfiguredLogin := DecryptString(FSettings.ApiBasicLoginEnc);
    LConfiguredPassword := DecryptString(FSettings.ApiBasicPasswordEnc);
  finally
    FCritSec.Release;
  end;

  case LAuthMode of
    aatHeader:
      begin
        LHeaderKey := ARequestInfo.RawHeaders.Values['X-API-Key'];
        Result := (LConfiguredKey <> '') and SameStr(LHeaderKey, LConfiguredKey);
      end;
    aatBasic:
      begin
        Result := DecodeBasicAuth(ARequestInfo.RawHeaders.Values['Authorization'], LUser, LPass) and
          (LConfiguredLogin <> '') and (LConfiguredPassword <> '') and
          SameStr(LUser, LConfiguredLogin) and SameStr(LPass, LConfiguredPassword);
      end;
  else
    Result := False;
  end;
end;

function NormalizeIp(const AValue: string): string;
begin
  Result := Trim(AValue);
  if StartsText('::ffff:', LowerCase(Result)) then
    Result := Copy(Result, 8, MaxInt);
end;

function TOwmApiServer.IsHostAllowed(AContext: TIdContext): Boolean;
var
  LPeerIp: string;
  LIp: string;
begin
  FCritSec.Acquire;
  try
    LPeerIp := NormalizeIp(AContext.Binding.PeerIP);

    if FSettings.AllowedHostsMode = ahmAll then
      Exit(True);

    if SameText(LPeerIp, '127.0.0.1') or SameText(LPeerIp, '::1') then
      Exit(True);

    for LIp in FSettings.AllowedIps do
      if SameText(NormalizeIp(LIp), LPeerIp) then
        Exit(True);

    Result := False;
  finally
    FCritSec.Release;
  end;
end;

function TOwmApiServer.BuildTempFilePath(const AExt: string): string;
var
  LDir: string;
  LExt: string;
begin
  LDir := TPath.Combine(TPath.GetTempPath, 'KappsWalletManager');
  if not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);

  LExt := AExt;
  if not StartsText('.', LExt) then
    LExt := '.' + LExt;

  Result := TPath.Combine(LDir,
    FormatDateTime('yyyymmdd_hhnnss_zzz', Now) + '_' + IntToStr(Random(10000)) + LExt);
end;

function TOwmApiServer.DownloadToFile(const AUrl, AFileName: string;
  out AError: string): Boolean;
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LStream: TFileStream;
begin
  Result := False;
  AError := '';

  LClient := THTTPClient.Create;
  try
    try
      LClient.ConnectionTimeout := 15000;
      LClient.ResponseTimeout := 30000;
      LStream := TFileStream.Create(AFileName, fmCreate);
      try
        LResp := LClient.Get(AUrl, LStream);
        if not InRange(LResp.StatusCode, 200, 299) then
        begin
          AError := OwmTextFmt('api.err.download_failed_http', 'Download failed. HTTP %d', [LResp.StatusCode]);
          Exit;
        end;
        Result := True;
      finally
        LStream.Free;
      end;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    LClient.Free;
  end;
end;

function TOwmApiServer.BuildOpenApiDocument: TJSONObject;

  procedure AddResponse(AResponses: TJSONObject; const AStatus, ADescription: string);
  var
    LResponseObj: TJSONObject;
    LContentObj: TJSONObject;
    LMediaTypeObj: TJSONObject;
    LSchemaObj: TJSONObject;
  begin
    LResponseObj := TJSONObject.Create;
    LResponseObj.AddPair('description', ADescription);
    LContentObj := TJSONObject.Create;
    LMediaTypeObj := TJSONObject.Create;
    LSchemaObj := TJSONObject.Create;
    LSchemaObj.AddPair('type', 'object');
    LMediaTypeObj.AddPair('schema', LSchemaObj);
    LContentObj.AddPair('application/vnd.api+json', LMediaTypeObj);
    LResponseObj.AddPair('content', LContentObj);
    AResponses.AddPair(AStatus, LResponseObj);
  end;

  procedure AddSecurity(AOperationObj: TJSONObject);
  var
    LSecurityArr: TJSONArray;
    LApiKeyObj: TJSONObject;
    LBasicObj: TJSONObject;
  begin
    LSecurityArr := TJSONArray.Create;
    LApiKeyObj := TJSONObject.Create;
    LApiKeyObj.AddPair('ApiKeyAuth', TJSONArray.Create);
    LSecurityArr.AddElement(LApiKeyObj);

    LBasicObj := TJSONObject.Create;
    LBasicObj.AddPair('BasicAuth', TJSONArray.Create);
    LSecurityArr.AddElement(LBasicObj);

    AOperationObj.AddPair('security', LSecurityArr);
  end;

  procedure AddRequestBody(AOperationObj: TJSONObject);
  var
    LReqBodyObj: TJSONObject;
    LReqContentObj: TJSONObject;
    LReqMediaJsonApiObj: TJSONObject;
    LReqMediaJsonObj: TJSONObject;
    LReqSchemaObj: TJSONObject;
    LReqSchemaObj2: TJSONObject;
  begin
    LReqBodyObj := TJSONObject.Create;
    LReqBodyObj.AddPair('required', TJSONBool.Create(True));

    LReqContentObj := TJSONObject.Create;
    LReqMediaJsonApiObj := TJSONObject.Create;
    LReqMediaJsonObj := TJSONObject.Create;
    LReqSchemaObj := TJSONObject.Create;
    LReqSchemaObj.AddPair('type', 'object');
    LReqSchemaObj.AddPair('additionalProperties', TJSONBool.Create(True));
    LReqSchemaObj2 := TJSONObject.Create;
    LReqSchemaObj2.AddPair('type', 'object');
    LReqSchemaObj2.AddPair('additionalProperties', TJSONBool.Create(True));

    LReqMediaJsonApiObj.AddPair('schema', LReqSchemaObj);
    LReqMediaJsonObj.AddPair('schema', LReqSchemaObj2);
    LReqContentObj.AddPair('application/vnd.api+json', LReqMediaJsonApiObj);
    LReqContentObj.AddPair('application/json', LReqMediaJsonObj);
    LReqBodyObj.AddPair('content', LReqContentObj);
    AOperationObj.AddPair('requestBody', LReqBodyObj);
  end;

  procedure AddOperation(APathItem: TJSONObject; const AMethod, AOperationId, ASummary: string;
    const ASuccessCode: string; AHasRequestBody: Boolean);
  var
    LOpObj: TJSONObject;
    LResponsesObj: TJSONObject;
  begin
    LOpObj := TJSONObject.Create;
    LOpObj.AddPair('operationId', AOperationId);
    LOpObj.AddPair('summary', ASummary);

    LResponsesObj := TJSONObject.Create;
    AddResponse(LResponsesObj, ASuccessCode, 'Successful JSON:API response');
    AddResponse(LResponsesObj, '400', 'Invalid request');
    AddResponse(LResponsesObj, '401', 'Unauthorized');
    AddResponse(LResponsesObj, '403', 'Forbidden');
    AddResponse(LResponsesObj, '404', 'Not found');
    AddResponse(LResponsesObj, '409', 'Conflict');
    AddResponse(LResponsesObj, '500', 'Internal server error');
    AddResponse(LResponsesObj, '503', 'Service unavailable');
    LOpObj.AddPair('responses', LResponsesObj);

    if AHasRequestBody then
      AddRequestBody(LOpObj);

    AddSecurity(LOpObj);
    APathItem.AddPair(LowerCase(AMethod), LOpObj);
  end;

var
  LRoot: TJSONObject;
  LInfo: TJSONObject;
  LServers: TJSONArray;
  LServerObj: TJSONObject;
  LPaths: TJSONObject;
  LPathItem: TJSONObject;
  LComponents: TJSONObject;
  LSecuritySchemes: TJSONObject;
  LApiKeyScheme: TJSONObject;
  LBasicScheme: TJSONObject;
begin
  LRoot := TJSONObject.Create;
  LRoot.AddPair('openapi', '3.0.3');

  LInfo := TJSONObject.Create;
  LInfo.AddPair('title', 'Oracle Wallet HTTP API');
  LInfo.AddPair('version', '1.0.0');
  LInfo.AddPair('description', 'OpenAPI document for Oracle Wallet API. Runtime payloads are JSON:API 1.0.');
  LRoot.AddPair('info', LInfo);

  LServers := TJSONArray.Create;
  LServerObj := TJSONObject.Create;
  LServerObj.AddPair('url', '/api/v1');
  LServers.AddElement(LServerObj);
  LRoot.AddPair('servers', LServers);

  LPaths := TJSONObject.Create;

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'GET', 'getOpenApiDoc', 'Get OpenAPI document', '200', False);
  LPaths.AddPair('/openapi.json', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'GET', 'getHealth', 'Health check', '200', False);
  LPaths.AddPair('/health', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'POST', 'createWallet', 'Create wallet', '201', True);
  LPaths.AddPair('/wallets', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'GET', 'listCertificates', 'List wallet certificates', '200', False);
  AddOperation(LPathItem, 'POST', 'addCertificateByUrl', 'Download and add certificate by URL', '201', True);
  LPaths.AddPair('/certs', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'GET', 'listExpiringCertificates', 'List expiring certificates', '200', False);
  LPaths.AddPair('/certs/expiring', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'GET', 'getCertificateByName', 'Get certificate by thumbprint/name/subject', '200', False);
  AddOperation(LPathItem, 'DELETE', 'deleteCertificateByName', 'Delete certificate by thumbprint/name/subject', '200', False);
  LPaths.AddPair('/certs/{name}', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'POST', 'uploadCertificate', 'Upload certificate (base64 payload)', '201', True);
  LPaths.AddPair('/certs/upload', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'POST', 'removeAllCertificates', 'Remove all certificates from wallet', '200', True);
  LPaths.AddPair('/certs/remove-all', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'GET', 'getAclTypes', 'List supported ACL types', '200', False);
  LPaths.AddPair('/acl/types', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'GET', 'listAcl', 'List ACL grants', '200', False);
  LPaths.AddPair('/acl', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'POST', 'grantAcl', 'Grant ACL privilege', '200', True);
  LPaths.AddPair('/acl/grant', LPathItem);

  LPathItem := TJSONObject.Create;
  AddOperation(LPathItem, 'POST', 'revokeAcl', 'Revoke ACL privilege', '200', True);
  LPaths.AddPair('/acl/revoke', LPathItem);

  LRoot.AddPair('paths', LPaths);

  LComponents := TJSONObject.Create;
  LSecuritySchemes := TJSONObject.Create;

  LApiKeyScheme := TJSONObject.Create;
  LApiKeyScheme.AddPair('type', 'apiKey');
  LApiKeyScheme.AddPair('in', 'header');
  LApiKeyScheme.AddPair('name', 'X-API-Key');
  LSecuritySchemes.AddPair('ApiKeyAuth', LApiKeyScheme);

  LBasicScheme := TJSONObject.Create;
  LBasicScheme.AddPair('type', 'http');
  LBasicScheme.AddPair('scheme', 'basic');
  LSecuritySchemes.AddPair('BasicAuth', LBasicScheme);

  LComponents.AddPair('securitySchemes', LSecuritySchemes);
  LRoot.AddPair('components', LComponents);

  Result := LRoot;
end;

procedure TOwmApiServer.HandleCommand(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LMethod: string;
  LPath: string;
  LBodyText: string;
  LBody: TJSONValue;
  LBodyObj: TJSONObject;
  LMetaObj: TJSONObject;
  LCerts: TCertInfoArray;
  LUpcoming: TCertInfoArray;
  LCert: TCertInfo;
  LName: string;
  LError: string;
  LArray: TJSONArray;
  LWalletPath: string;
  LWalletPassword: string;
  LTempFile: string;
  LUrl: string;
  LFound: Boolean;
  LRemoved: Integer;
  LFailed: Integer;
  LDays: Integer;
  LLimit: Integer;
  I: Integer;
  J: Integer;
  LTmpCert: TCertInfo;
  LMaxDate: TDateTime;
  LUploadContent: string;
  LUploadFileName: string;
  LUploadExt: string;
  LUploadBytes: TBytes;
  LNewWalletPath: string;
  LNewWalletPassword: string;
  LAutoLogin: Boolean;
  LAutoLoginLocal: Boolean;
  LWalletCreateErrorCode: string;
  LSwitchToNew: Boolean;
  LUpdatedSettings: TOwmSettings;
  LEnhancedEnabled: Boolean;
  LApiEnabled: Boolean;
  LAclReq: TOwmAclRequest;
  LAclItems: TOwmAclEntryArray;
  LAclItem: TOwmAclEntry;
  LAclTypes: TArray<string>;
  LType: string;
  LJsonApiAttrs: TJSONObject;
  LExtractErrorCode: string;
  LExtractErrorMessage: string;
begin
  LMethod := UpperCase(ARequestInfo.Command);
  LPath := ARequestInfo.Document;

  if not StartsText('/api/v1', LPath) then
  begin
    SendError(AResponseInfo, 404, 'NotFound', OwmText('api.err.route_not_found', 'Route not found'));
    Exit;
  end;

  if not IsHostAllowed(AContext) then
  begin
    SendError(AResponseInfo, 403, 'Forbidden', OwmText('api.err.host_not_allowed', 'Host is not allowed'));
    Exit;
  end;

  if not IsAuthorized(ARequestInfo) then
  begin
    AResponseInfo.CustomHeaders.Values['WWW-Authenticate'] := 'Basic realm="OracleWallet"';
    SendError(AResponseInfo, 401, 'Unauthorized', OwmText('api.err.auth_failed', 'Authentication failed'));
    Exit;
  end;

  FCritSec.Acquire;
  try
    LWalletPath := FSettings.WalletPath;
    LWalletPassword := DecryptString(FSettings.WalletPasswordEnc);
    LEnhancedEnabled := FSettings.EnhancedApiEnabled;
    LApiEnabled := FSettings.ApiEnabled;
  finally
    FCritSec.Release;
  end;

  if (LMethod = 'GET') and SameText(LPath, '/api/v1/openapi.json') then
  begin
    SendJson(AResponseInfo, 200, BuildOpenApiDocument);
    Exit;
  end;

  if (LMethod = 'GET') and SameText(LPath, '/api/v1/health') then
  begin
    LBodyObj := TJSONObject.Create;
    LBodyObj.AddPair('time', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    LBodyObj.AddPair('serverRunning', TJSONBool.Create(IsRunning));
    LBodyObj.AddPair('apiEnabled', TJSONBool.Create(LApiEnabled));
    LBodyObj.AddPair('enhancedApiEnabled', TJSONBool.Create(LEnhancedEnabled));
    LBodyObj.AddPair('walletConfigured', TJSONBool.Create(Trim(LWalletPath) <> ''));
    LBodyObj.AddPair('orapkiAvailable', TJSONBool.Create(FTools.OrapkiAvailable));
    LBodyObj.AddPair('sqlplusAvailable', TJSONBool.Create(FTools.SqlPlusAvailable));
    SendJsonApi(AResponseInfo, 200, BuildResource('health', 'self', LBodyObj));
    Exit;
  end;

  if (LMethod = 'POST') and SameText(LPath, '/api/v1/wallets') then
  begin
    LBodyText := RequestBodyAsText(ARequestInfo);
    LBody := TJSONObject.ParseJSONValue(LBodyText);
    try
      if not (LBody is TJSONObject) then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody', OwmText('api.err.invalid_json', 'JSON body required'));
        Exit;
      end;

      if not ExtractJsonApiAttributes(TJSONObject(LBody), 'wallets', LJsonApiAttrs,
        LExtractErrorCode, LExtractErrorMessage) then
      begin
        SendError(AResponseInfo, 400, LExtractErrorCode, LExtractErrorMessage);
        Exit;
      end;

      LNewWalletPath := GetJsonString(LJsonApiAttrs, 'path');
      LNewWalletPassword := GetJsonString(LJsonApiAttrs, 'password');
      LAutoLogin := GetJsonBoolean(LJsonApiAttrs, 'autoLogin', True);
      LAutoLoginLocal := GetJsonBoolean(LJsonApiAttrs, 'autoLoginLocal', False);
      LSwitchToNew := GetJsonBoolean(LJsonApiAttrs, 'switchToNew', True);

      if LNewWalletPath = '' then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody',
          OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['path']));
        Exit;
      end;

      if LNewWalletPassword = '' then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody',
          OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['password']));
        Exit;
      end;

      if not FWalletService.CreateWallet(LNewWalletPath, LNewWalletPassword,
        LAutoLogin, LAutoLoginLocal, LError, LWalletCreateErrorCode) then
      begin
        if SameText(LWalletCreateErrorCode, 'InvalidPath') then
          SendError(AResponseInfo, 400, 'InvalidPath',
            OwmText('api.err.invalid_path', 'Invalid path'))
        else if SameText(LWalletCreateErrorCode, 'WalletExists') then
          SendError(AResponseInfo, 409, 'WalletExists',
            OwmText('api.err.wallet_exists', 'wallet is already exists'))
        else
          SendError(AResponseInfo, 500, 'WalletError', LError);
        Exit;
      end;

      try
        LNewWalletPath := ExcludeTrailingPathDelimiter(TPath.GetFullPath(Trim(LNewWalletPath)));
      except
        on Exception do
          LNewWalletPath := Trim(LNewWalletPath);
      end;

      if LSwitchToNew then
      begin
        LUpdatedSettings := TOwmSettings.Create;
        try
          FCritSec.Acquire;
          try
            FSettings.WalletPath := LNewWalletPath;
            FSettings.WalletPasswordEnc := EncryptString(LNewWalletPassword);
            LUpdatedSettings.Assign(FSettings);
          finally
            FCritSec.Release;
          end;
          FEnhancedAclService.ApplySettings(LUpdatedSettings);
        finally
          LUpdatedSettings.Free;
        end;
      end;

      LBodyObj := TJSONObject.Create;
      if LSwitchToNew then
        LBodyObj.AddPair('message', OwmTextFmt('api.msg.wallet_created_switched',
          'New wallet created and activated: %s', [LNewWalletPath]))
      else
        LBodyObj.AddPair('message', OwmTextFmt('api.msg.wallet_created',
          'New wallet created: %s', [LNewWalletPath]));
      LBodyObj.AddPair('walletPath', LNewWalletPath);
      LBodyObj.AddPair('switched', TJSONBool.Create(LSwitchToNew));
      SendJsonApi(AResponseInfo, 201, BuildResource('wallets', LNewWalletPath, LBodyObj));
    finally
      LBody.Free;
    end;
    Exit;
  end;

  if (LMethod = 'GET') and SameText(LPath, '/api/v1/certs') then
  begin
    if not FWalletService.ListCertificates(LWalletPath, LWalletPassword, LCerts, LError) then
    begin
      SendError(AResponseInfo, 500, 'WalletError', LError);
      Exit;
    end;

    LArray := TJSONArray.Create;
    for LCert in LCerts do
      AddCertJsonItem(LArray, LCert);
    SendJsonApi(AResponseInfo, 200, LArray);
    Exit;
  end;

  if (LMethod = 'GET') and SameText(LPath, '/api/v1/certs/expiring') then
  begin
    if not FWalletService.ListCertificates(LWalletPath, LWalletPassword, LCerts, LError) then
    begin
      SendError(AResponseInfo, 500, 'WalletError', LError);
      Exit;
    end;

    LDays := StrToIntDef(Trim(ARequestInfo.Params.Values['days']), 30);
    if not InRange(LDays, 1, 3650) then
      LDays := 30;

    LLimit := StrToIntDef(Trim(ARequestInfo.Params.Values['limit']), 20);
    if not InRange(LLimit, 1, 200) then
      LLimit := 20;

    SetLength(LUpcoming, 0);
    LMaxDate := IncDay(Now, LDays);
    for I := 0 to High(LCerts) do
      if (LCerts[I].NotAfter > 0) and (LCerts[I].NotAfter <= LMaxDate) then
      begin
        J := Length(LUpcoming);
        SetLength(LUpcoming, J + 1);
        LUpcoming[J] := LCerts[I];
      end;

    for I := 0 to High(LUpcoming) - 1 do
      for J := I + 1 to High(LUpcoming) do
        if LUpcoming[I].NotAfter > LUpcoming[J].NotAfter then
        begin
          LTmpCert := LUpcoming[I];
          LUpcoming[I] := LUpcoming[J];
          LUpcoming[J] := LTmpCert;
        end;

    LArray := TJSONArray.Create;
    for I := 0 to Min(High(LUpcoming), LLimit - 1) do
      AddCertJsonItem(LArray, LUpcoming[I], True);
    LMetaObj := TJSONObject.Create;
    LMetaObj.AddPair('days', TJSONNumber.Create(LDays));
    LMetaObj.AddPair('total', TJSONNumber.Create(Length(LUpcoming)));
    LMetaObj.AddPair('limit', TJSONNumber.Create(LLimit));
    SendJsonApi(AResponseInfo, 200, LArray, LMetaObj);
    Exit;
  end;

  if (LMethod = 'POST') and SameText(LPath, '/api/v1/certs/remove-all') then
  begin
    LBodyText := RequestBodyAsText(ARequestInfo);
    LBody := TJSONObject.ParseJSONValue(LBodyText);
    try
      if not (LBody is TJSONObject) then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody', OwmText('api.err.invalid_json', 'JSON body required'));
        Exit;
      end;

      if not ExtractJsonApiAttributes(TJSONObject(LBody), 'wallet-operations', LJsonApiAttrs,
        LExtractErrorCode, LExtractErrorMessage) then
      begin
        SendError(AResponseInfo, 400, LExtractErrorCode, LExtractErrorMessage);
        Exit;
      end;

      if not GetJsonBoolean(LJsonApiAttrs, 'confirm', False) then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody',
          OwmText('api.err.confirm_true_required', 'confirm=true is required'));
        Exit;
      end;

      if not FWalletService.ListCertificates(LWalletPath, LWalletPassword, LCerts, LError) then
      begin
        SendError(AResponseInfo, 500, 'WalletError', LError);
        Exit;
      end;

      FWalletService.RemoveAllCertificates(LWalletPath, LWalletPassword, LCerts, LRemoved, LFailed, LError);

      LBodyObj := TJSONObject.Create;
      LBodyObj.AddPair('success', TJSONBool.Create(LFailed = 0));
      LBodyObj.AddPair('removed', TJSONNumber.Create(LRemoved));
      LBodyObj.AddPair('failed', TJSONNumber.Create(LFailed));
      if LError <> '' then
        LBodyObj.AddPair('message', LError)
      else
        LBodyObj.AddPair('message', OwmText('api.msg.remove_all_done', 'Remove-all completed'));
      SendJsonApi(AResponseInfo, 200,
        BuildResource('wallet-operations', 'remove-all', LBodyObj));
    finally
      LBody.Free;
    end;
    Exit;
  end;

  if (LMethod = 'GET') and StartsText('/api/v1/certs/', LPath) then
  begin
    LName := TIdURI.URLDecode(Copy(LPath, Length('/api/v1/certs/') + 1, MaxInt));
    if not FWalletService.ListCertificates(LWalletPath, LWalletPassword, LCerts, LError) then
    begin
      SendError(AResponseInfo, 500, 'WalletError', LError);
      Exit;
    end;

    LFound := False;
    for LCert in LCerts do
      if SameText(LCert.Thumbprint, LName) or SameText(CertDisplayName(LCert), LName) or
         SameText(LCert.Subject, LName) then
      begin
        SendJsonApi(AResponseInfo, 200,
          BuildResource('certificates', BuildCertId(LCert), BuildCertAttributes(LCert, False)));
        LFound := True;
        Break;
      end;

    if not LFound then
      SendError(AResponseInfo, 404, 'NotFound', OwmText('api.err.cert_not_found', 'Certificate not found'));
    Exit;
  end;

  if (LMethod = 'DELETE') and StartsText('/api/v1/certs/', LPath) then
  begin
    LName := TIdURI.URLDecode(Copy(LPath, Length('/api/v1/certs/') + 1, MaxInt));
    if not FWalletService.ListCertificates(LWalletPath, LWalletPassword, LCerts, LError) then
    begin
      SendError(AResponseInfo, 500, 'WalletError', LError);
      Exit;
    end;

    LFound := False;
    for LCert in LCerts do
      if SameText(LCert.Thumbprint, LName) or SameText(CertDisplayName(LCert), LName) or
         SameText(LCert.Subject, LName) then
      begin
        LFound := True;
        if not FWalletService.RemoveCertificate(LWalletPath, LWalletPassword, LCert.Subject, LError) then
        begin
          SendError(AResponseInfo, 500, 'WalletError', LError);
          Exit;
        end;
        Break;
      end;

    if not LFound then
    begin
      SendError(AResponseInfo, 404, 'NotFound', OwmText('api.err.cert_not_found', 'Certificate not found'));
      Exit;
    end;

    LBodyObj := TJSONObject.Create;
    LBodyObj.AddPair('message', OwmText('api.msg.cert_removed', 'Certificate removed'));
    LBodyObj.AddPair('name', LName);
    SendJsonApi(AResponseInfo, 200,
      BuildResource('wallet-operations', 'remove-certificate', LBodyObj));
    Exit;
  end;

  if (LMethod = 'POST') and SameText(LPath, '/api/v1/certs') then
  begin
    LBodyText := RequestBodyAsText(ARequestInfo);
    LBody := TJSONObject.ParseJSONValue(LBodyText);
    try
      if not (LBody is TJSONObject) then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody', OwmText('api.err.invalid_json', 'JSON body required'));
        Exit;
      end;

      if not ExtractJsonApiAttributes(TJSONObject(LBody), 'certificate-imports', LJsonApiAttrs,
        LExtractErrorCode, LExtractErrorMessage) then
      begin
        SendError(AResponseInfo, 400, LExtractErrorCode, LExtractErrorMessage);
        Exit;
      end;

      LUrl := GetJsonString(LJsonApiAttrs, 'url');
      if LUrl = '' then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody', OwmText('api.err.url_required', 'url is required'));
        Exit;
      end;

      LTempFile := BuildTempFilePath('.cer');
      if not DownloadToFile(LUrl, LTempFile, LError) then
      begin
        SendError(AResponseInfo, 400, 'DownloadFailed', LError);
        Exit;
      end;

      if not FWalletService.AddCertificate(LWalletPath, LWalletPassword, LTempFile, LError) then
      begin
        SendError(AResponseInfo, 500, 'WalletError', LError);
        Exit;
      end;

      LBodyObj := TJSONObject.Create;
      LBodyObj.AddPair('message', OwmText('api.msg.cert_added', 'Certificate added'));
      LBodyObj.AddPair('url', LUrl);
      SendJsonApi(AResponseInfo, 201,
        BuildResource('certificate-imports', LUrl, LBodyObj));
    finally
      LBody.Free;
      if (LTempFile <> '') and FileExists(LTempFile) then
        TFile.Delete(LTempFile);
    end;
    Exit;
  end;

  if (LMethod = 'POST') and SameText(LPath, '/api/v1/certs/upload') then
  begin
    LBodyText := RequestBodyAsText(ARequestInfo);
    LBody := TJSONObject.ParseJSONValue(LBodyText);
    try
      if not (LBody is TJSONObject) then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody', OwmText('api.err.invalid_json', 'JSON body required'));
        Exit;
      end;

      if not ExtractJsonApiAttributes(TJSONObject(LBody), 'certificate-uploads', LJsonApiAttrs,
        LExtractErrorCode, LExtractErrorMessage) then
      begin
        SendError(AResponseInfo, 400, LExtractErrorCode, LExtractErrorMessage);
        Exit;
      end;

      LUploadContent := GetJsonString(LJsonApiAttrs, 'contentBase64');
      if LUploadContent = '' then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody',
          OwmText('api.err.upload_content_required', 'contentBase64 is required'));
        Exit;
      end;

      LUploadFileName := GetJsonString(LJsonApiAttrs, 'fileName');
      LUploadExt := LowerCase(ExtractFileExt(LUploadFileName));
      if (LUploadExt <> '.crt') and (LUploadExt <> '.cer') and
         (LUploadExt <> '.pem') and (LUploadExt <> '.der') then
        LUploadExt := '.cer';

      try
        LUploadBytes := TNetEncoding.Base64.DecodeStringToBytes(LUploadContent);
      except
        on Exception do
        begin
          SendError(AResponseInfo, 400, 'InvalidBody',
            OwmText('api.err.upload_base64_invalid', 'Invalid base64 payload'));
          Exit;
        end;
      end;

      if Length(LUploadBytes) = 0 then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody',
          OwmText('api.err.upload_base64_invalid', 'Invalid base64 payload'));
        Exit;
      end;

      LTempFile := BuildTempFilePath(LUploadExt);
      TFile.WriteAllBytes(LTempFile, LUploadBytes);

      if not FWalletService.AddCertificate(LWalletPath, LWalletPassword, LTempFile, LError) then
      begin
        SendError(AResponseInfo, 500, 'WalletError', LError);
        Exit;
      end;

      LBodyObj := TJSONObject.Create;
      LBodyObj.AddPair('message', OwmText('api.msg.cert_added', 'Certificate added'));
      if LUploadFileName <> '' then
        LBodyObj.AddPair('fileName', LUploadFileName);
      SendJsonApi(AResponseInfo, 201,
        BuildResource('certificate-uploads', FormatDateTime('yyyymmddhhnnsszzz', Now), LBodyObj));
    finally
      LBody.Free;
      if (LTempFile <> '') and FileExists(LTempFile) then
        TFile.Delete(LTempFile);
    end;
    Exit;
  end;

  if StartsText('/api/v1/acl', LPath) then
  begin
    if not LEnhancedEnabled then
    begin
      SendError(AResponseInfo, 403, 'Forbidden', OwmText('api.err.enhanced_disabled', 'Enhanced API is disabled'));
      Exit;
    end;

    if not FTools.SqlPlusAvailable then
    begin
      SendError(AResponseInfo, 503, 'ToolMissing', OwmText('api.err.sqlplus_missing', 'sqlplus.exe not found'));
      Exit;
    end;

    if (LMethod = 'GET') and SameText(LPath, '/api/v1/acl/types') then
    begin
      LArray := TJSONArray.Create;
      LAclTypes := FEnhancedAclService.SupportedAclTypes;
      for LType in LAclTypes do
      begin
        LBodyObj := TJSONObject.Create;
        LBodyObj.AddPair('name', LType);
        LArray.AddElement(BuildResource('acl-types', LType, LBodyObj));
      end;
      SendJsonApi(AResponseInfo, 200, LArray);
      Exit;
    end;

    if (LMethod = 'GET') and SameText(LPath, '/api/v1/acl') then
    begin
      LName := Trim(ARequestInfo.Params.Values['schema']);
      if LName = '' then
      begin
        SendError(AResponseInfo, 400, 'InvalidBody',
          OwmTextFmt('api.err.invalid_value', 'Invalid value for %s', ['schema']));
        Exit;
      end;

      if not FEnhancedAclService.ListAcl(LName, Trim(ARequestInfo.Params.Values['host']),
        LAclItems, LError) then
      begin
        SendError(AResponseInfo, 400, 'AclError', LError);
        Exit;
      end;

      LArray := TJSONArray.Create;
      for LAclItem in LAclItems do
      begin
        LBodyObj := TJSONObject.Create;
        LBodyObj.AddPair('host', LAclItem.Host);
        LBodyObj.AddPair('lowerPort', TJSONNumber.Create(LAclItem.LowerPort));
        LBodyObj.AddPair('upperPort', TJSONNumber.Create(LAclItem.UpperPort));
        LBodyObj.AddPair('principal', LAclItem.Principal);
        LBodyObj.AddPair('privilege', LAclItem.Privilege);
        LBodyObj.AddPair('isGrant', TJSONBool.Create(LAclItem.IsGrant));
        LArray.AddElement(BuildResource('acl-grants',
          Format('%s:%s:%d:%d:%s', [LAclItem.Principal, LAclItem.Host,
            LAclItem.LowerPort, LAclItem.UpperPort, LAclItem.Privilege]), LBodyObj));
      end;
      SendJsonApi(AResponseInfo, 200, LArray);
      Exit;
    end;

    if ((LMethod = 'POST') and SameText(LPath, '/api/v1/acl/grant')) or
       ((LMethod = 'POST') and SameText(LPath, '/api/v1/acl/revoke')) then
    begin
      LBodyText := RequestBodyAsText(ARequestInfo);
      LBody := TJSONObject.ParseJSONValue(LBodyText);
      try
        if not (LBody is TJSONObject) then
        begin
          SendError(AResponseInfo, 400, 'InvalidBody', OwmText('api.err.invalid_json', 'JSON body required'));
          Exit;
        end;

        if not ExtractJsonApiAttributes(TJSONObject(LBody), 'acl-requests', LJsonApiAttrs,
          LExtractErrorCode, LExtractErrorMessage) then
        begin
          SendError(AResponseInfo, 400, LExtractErrorCode, LExtractErrorMessage);
          Exit;
        end;

        LAclReq.SchemaName := GetJsonString(LJsonApiAttrs, 'schema');
        LAclReq.Host := GetJsonString(LJsonApiAttrs, 'host');
        LAclReq.Port := GetJsonInteger(LJsonApiAttrs, 'port', 0);
        LAclReq.AclType := GetJsonString(LJsonApiAttrs, 'aclType');

        if SameText(LPath, '/api/v1/acl/grant') then
          LFound := FEnhancedAclService.GrantAcl(LAclReq, LError)
        else
          LFound := FEnhancedAclService.RevokeAcl(LAclReq, LError);

        if not LFound then
        begin
          SendError(AResponseInfo, 400, 'AclError', LError);
          Exit;
        end;

        LBodyObj := TJSONObject.Create;
        if SameText(LPath, '/api/v1/acl/grant') then
          LBodyObj.AddPair('message', OwmTextFmt('api.msg.acl_granted',
            'ACL granted for %s (%s)', [LAclReq.SchemaName, LAclReq.Host]))
        else
          LBodyObj.AddPair('message', OwmTextFmt('api.msg.acl_revoked',
            'ACL revoked for %s (%s)', [LAclReq.SchemaName, LAclReq.Host]));
        LBodyObj.AddPair('schema', LAclReq.SchemaName);
        LBodyObj.AddPair('host', LAclReq.Host);
        LBodyObj.AddPair('port', TJSONNumber.Create(LAclReq.Port));
        LBodyObj.AddPair('aclType', LAclReq.AclType);
        if SameText(LPath, '/api/v1/acl/grant') then
          LBodyObj.AddPair('action', 'grant')
        else
          LBodyObj.AddPair('action', 'revoke');
        SendJsonApi(AResponseInfo, 200,
          BuildResource('acl-operations',
            Format('%s:%s:%d:%s', [LAclReq.SchemaName, LAclReq.Host, LAclReq.Port, LAclReq.AclType]),
            LBodyObj));
      finally
        LBody.Free;
      end;
      Exit;
    end;

    SendError(AResponseInfo, 404, 'NotFound', OwmText('api.err.route_not_found', 'Route not found'));
    Exit;
  end;

  SendError(AResponseInfo, 404, 'NotFound', OwmText('api.err.route_not_found', 'Route not found'));
end;

end.

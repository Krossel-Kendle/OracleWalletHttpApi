unit uOwmApiReferenceData;

interface

uses
  System.SysUtils;

type
  TOwmApiRefCategory = (arcOracleWallet, arcEnhanced);

  TOwmApiRefEndpoint = record
    Id: string;
    Category: TOwmApiRefCategory;
    NodeTextKey: string;
    NodeTextDefault: string;
    Method: string;
    Path: string;
    DescriptionKey: string;
    DescriptionDefault: string;
    RequestExample: string;
    ResponseExample: string;
  end;

  TOwmApiRefEndpointArray = TArray<TOwmApiRefEndpoint>;

function GetApiReferenceCategoryCaption(ACategory: TOwmApiRefCategory): string;
function GetApiReferenceEndpoints: TOwmApiRefEndpointArray;

implementation

uses
  uOwmI18n;

const
  CEndpoints: array[0..13] of TOwmApiRefEndpoint = (
    (
      Id: 'openapi_doc';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.openapi';
      NodeTextDefault: 'OpenAPI document';
      Method: 'GET';
      Path: '/api/v1/openapi.json';
      DescriptionKey: 'apiref.desc.openapi';
      DescriptionDefault: 'Returns OpenAPI 3.0 JSON document for all available API endpoints.';
      RequestExample: '{'#13#10'  "headers": {'#13#10'    "X-API-Key": "<your_api_key>"'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "openapi": "3.0.3",'#13#10'  "info": {'#13#10'    "title": "Oracle Wallet HTTP API",'#13#10'    "version": "1.0.0"'#13#10'  },'#13#10'  "paths": {'#13#10'    "/health": {'#13#10'      "get": {'#13#10'        "operationId": "getHealth"'#13#10'      }'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'wallet_health';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_health';
      NodeTextDefault: 'Health check';
      Method: 'GET';
      Path: '/api/v1/health';
      DescriptionKey: 'apiref.desc.wallet_health';
      DescriptionDefault: 'Returns server/runtime status: API flags, tools availability and wallet configuration.';
      RequestExample: '{'#13#10'  "headers": {'#13#10'    "X-API-Key": "<your_api_key>"'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "health",'#13#10'    "id": "self",'#13#10'    "attributes": {'#13#10'      "serverRunning": true,'#13#10'      "apiEnabled": true,'#13#10'      "enhancedApiEnabled": true,'#13#10'      "walletConfigured": true,'#13#10'      "orapkiAvailable": true,'#13#10'      "sqlplusAvailable": true'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'wallet_create';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_create';
      NodeTextDefault: 'Create wallet';
      Method: 'POST';
      Path: '/api/v1/wallets';
      DescriptionKey: 'apiref.desc.wallet_create';
      DescriptionDefault: 'Creates a new wallet and can switch active wallet to it. Errors: 400 Invalid path, 409 wallet is already exists.';
      RequestExample: '{'#13#10'  "data": {'#13#10'    "type": "wallets",'#13#10'    "attributes": {'#13#10'      "path": "C:\\app\\wallet_new",'#13#10'      "password": "<wallet_password>",'#13#10'      "autoLogin": true,'#13#10'      "autoLoginLocal": false,'#13#10'      "switchToNew": true'#13#10'    }'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "wallets",'#13#10'    "id": "C:\\app\\wallet_new",'#13#10'    "attributes": {'#13#10'      "message": "New wallet created and activated: C:\\app\\wallet_new",'#13#10'      "walletPath": "C:\\app\\wallet_new",'#13#10'      "switched": true'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'wallet_list';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_list';
      NodeTextDefault: 'List certificates';
      Method: 'GET';
      Path: '/api/v1/certs';
      DescriptionKey: 'apiref.desc.wallet_list';
      DescriptionDefault: 'Returns all certificates from wallet with basic metadata.';
      RequestExample: '{'#13#10'  "headers": {'#13#10'    "X-API-Key": "<your_api_key>"'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": ['#13#10'    {'#13#10'      "type": "certificates",'#13#10'      "id": "ABCD...",'#13#10'      "attributes": {'#13#10'        "name": "DigiCert Global Root G2",'#13#10'        "subject": "CN=DigiCert Global Root G2,...",'#13#10'        "issuer": "CN=DigiCert Global Root G2,...",'#13#10'        "notAfter": "2038-01-15T12:00:00"'#13#10'      }'#13#10'    }'#13#10'  ]'#13#10'}'
    ),
    (
      Id: 'wallet_expiring';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_expiring';
      NodeTextDefault: 'Expiring certificates';
      Method: 'GET';
      Path: '/api/v1/certs/expiring?days=30&limit=20';
      DescriptionKey: 'apiref.desc.wallet_expiring';
      DescriptionDefault: 'Returns certificates expiring in specified period, sorted by closest expiration.';
      RequestExample: '{'#13#10'  "path": "/api/v1/certs/expiring?days=30&limit=20"'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": ['#13#10'    {'#13#10'      "type": "certificates",'#13#10'      "id": "ABCD...",'#13#10'      "attributes": {'#13#10'        "name": "api.example.com",'#13#10'        "notAfter": "2026-03-11T09:00:00",'#13#10'        "daysLeft": 16'#13#10'      }'#13#10'    }'#13#10'  ],'#13#10'  "meta": {'#13#10'    "days": 30,'#13#10'    "total": 3,'#13#10'    "limit": 20'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'wallet_get_one';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_get_one';
      NodeTextDefault: 'Get certificate';
      Method: 'GET';
      Path: '/api/v1/certs/{name}';
      DescriptionKey: 'apiref.desc.wallet_get_one';
      DescriptionDefault: 'Returns one certificate by thumbprint/name/subject.';
      RequestExample: '{'#13#10'  "path": "/api/v1/certs/DigiCert%20Global%20Root%20G2",'#13#10'  "headers": {'#13#10'    "X-API-Key": "<your_api_key>"'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "certificates",'#13#10'    "id": "ABCD...",'#13#10'    "attributes": {'#13#10'      "name": "DigiCert Global Root G2",'#13#10'      "subject": "CN=DigiCert Global Root G2,...",'#13#10'      "issuer": "CN=DigiCert Global Root G2,...",'#13#10'      "notAfter": "2038-01-15T12:00:00"'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'wallet_add_by_url';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_add_by_url';
      NodeTextDefault: 'Add certificate by URL';
      Method: 'POST';
      Path: '/api/v1/certs';
      DescriptionKey: 'apiref.desc.wallet_add_by_url';
      DescriptionDefault: 'Downloads certificate by URL and adds it as trusted cert.';
      RequestExample: '{'#13#10'  "data": {'#13#10'    "type": "certificate-imports",'#13#10'    "attributes": {'#13#10'      "url": "https://example.com/cert.cer"'#13#10'    }'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "certificate-imports",'#13#10'    "id": "https://example.com/cert.cer",'#13#10'    "attributes": {'#13#10'      "message": "Certificate added",'#13#10'      "url": "https://example.com/cert.cer"'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'wallet_upload';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_upload';
      NodeTextDefault: 'Upload certificate';
      Method: 'POST';
      Path: '/api/v1/certs/upload';
      DescriptionKey: 'apiref.desc.wallet_upload';
      DescriptionDefault: 'Adds certificate from base64 payload.';
      RequestExample: '{'#13#10'  "data": {'#13#10'    "type": "certificate-uploads",'#13#10'    "attributes": {'#13#10'      "fileName": "root.cer",'#13#10'      "contentBase64": "MII..."'#13#10'    }'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "certificate-uploads",'#13#10'    "id": "20260225094500123",'#13#10'    "attributes": {'#13#10'      "message": "Certificate added",'#13#10'      "fileName": "root.cer"'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'wallet_remove_all';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_remove_all';
      NodeTextDefault: 'Remove all certificates';
      Method: 'POST';
      Path: '/api/v1/certs/remove-all';
      DescriptionKey: 'apiref.desc.wallet_remove_all';
      DescriptionDefault: 'Bulk-delete endpoint for wallet certificates. Requires confirm=true.';
      RequestExample: '{'#13#10'  "data": {'#13#10'    "type": "wallet-operations",'#13#10'    "attributes": {'#13#10'      "confirm": true'#13#10'    }'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "wallet-operations",'#13#10'    "id": "remove-all",'#13#10'    "attributes": {'#13#10'      "success": true,'#13#10'      "removed": 12,'#13#10'      "failed": 0,'#13#10'      "message": "Remove-all completed"'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'wallet_delete';
      Category: arcOracleWallet;
      NodeTextKey: 'apiref.node.wallet_delete';
      NodeTextDefault: 'Delete certificate';
      Method: 'DELETE';
      Path: '/api/v1/certs/{name}';
      DescriptionKey: 'apiref.desc.wallet_delete';
      DescriptionDefault: 'Deletes one certificate from wallet by thumbprint/name/subject.';
      RequestExample: '{'#13#10'  "path": "/api/v1/certs/ABCD...",'#13#10'  "headers": {'#13#10'    "X-API-Key": "<your_api_key>"'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "wallet-operations",'#13#10'    "id": "remove-certificate",'#13#10'    "attributes": {'#13#10'      "message": "Certificate removed",'#13#10'      "name": "ABCD..."'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'acl_types';
      Category: arcEnhanced;
      NodeTextKey: 'apiref.node.acl_types';
      NodeTextDefault: 'Supported ACL types';
      Method: 'GET';
      Path: '/api/v1/acl/types';
      DescriptionKey: 'apiref.desc.acl_types';
      DescriptionDefault: 'Returns ACL type values supported by Enhanced API.';
      RequestExample: '{'#13#10'  "path": "/api/v1/acl/types"'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": ['#13#10'    {'#13#10'      "type": "acl-types",'#13#10'      "id": "connect",'#13#10'      "attributes": { "name": "connect" }'#13#10'    },'#13#10'    {'#13#10'      "type": "acl-types",'#13#10'      "id": "resolve",'#13#10'      "attributes": { "name": "resolve" }'#13#10'    }'#13#10'  ]'#13#10'}'
    ),
    (
      Id: 'acl_grant';
      Category: arcEnhanced;
      NodeTextKey: 'apiref.node.acl_grant';
      NodeTextDefault: 'Grant ACL';
      Method: 'POST';
      Path: '/api/v1/acl/grant';
      DescriptionKey: 'apiref.desc.acl_grant';
      DescriptionDefault: 'Grants ACL privilege for schema/host/port/type (Enhanced API).';
      RequestExample: '{'#13#10'  "data": {'#13#10'    "type": "acl-requests",'#13#10'    "attributes": {'#13#10'      "schema": "APP_USER",'#13#10'      "host": "api.example.com",'#13#10'      "port": 443,'#13#10'      "aclType": "http"'#13#10'    }'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "acl-operations",'#13#10'    "id": "APP_USER:api.example.com:443:http",'#13#10'    "attributes": {'#13#10'      "message": "ACL granted for APP_USER (api.example.com)",'#13#10'      "action": "grant"'#13#10'    }'#13#10'  }'#13#10'}'
    ),
    (
      Id: 'acl_list';
      Category: arcEnhanced;
      NodeTextKey: 'apiref.node.acl_list';
      NodeTextDefault: 'List ACL';
      Method: 'GET';
      Path: '/api/v1/acl?schema=APP_USER';
      DescriptionKey: 'apiref.desc.acl_list';
      DescriptionDefault: 'Lists ACL grants for selected schema and optional host filter.';
      RequestExample: '{'#13#10'  "query": "schema=APP_USER&host=api.example.com"'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": ['#13#10'    {'#13#10'      "type": "acl-grants",'#13#10'      "id": "APP_USER:api.example.com:443:443:connect",'#13#10'      "attributes": {'#13#10'        "host": "api.example.com",'#13#10'        "lowerPort": 443,'#13#10'        "upperPort": 443,'#13#10'        "principal": "APP_USER",'#13#10'        "privilege": "connect",'#13#10'        "isGrant": true'#13#10'      }'#13#10'    }'#13#10'  ]'#13#10'}'
    ),
    (
      Id: 'acl_revoke';
      Category: arcEnhanced;
      NodeTextKey: 'apiref.node.acl_revoke';
      NodeTextDefault: 'Revoke ACL';
      Method: 'POST';
      Path: '/api/v1/acl/revoke';
      DescriptionKey: 'apiref.desc.acl_revoke';
      DescriptionDefault: 'Revokes previously granted ACL privilege.';
      RequestExample: '{'#13#10'  "data": {'#13#10'    "type": "acl-requests",'#13#10'    "attributes": {'#13#10'      "schema": "APP_USER",'#13#10'      "host": "api.example.com",'#13#10'      "port": 443,'#13#10'      "aclType": "http"'#13#10'    }'#13#10'  }'#13#10'}';
      ResponseExample: '{'#13#10'  "jsonapi": { "version": "1.0" },'#13#10'  "data": {'#13#10'    "type": "acl-operations",'#13#10'    "id": "APP_USER:api.example.com:443:http",'#13#10'    "attributes": {'#13#10'      "message": "ACL revoked for APP_USER (api.example.com)",'#13#10'      "action": "revoke"'#13#10'    }'#13#10'  }'#13#10'}'
    )
  );

function GetApiReferenceCategoryCaption(ACategory: TOwmApiRefCategory): string;
begin
  case ACategory of
    arcOracleWallet:
      Result := OwmText('apiref.root.wallet_api', 'Oracle Wallet API');
    arcEnhanced:
      Result := OwmText('apiref.root.enhanced_api', 'Enhanced API');
  else
    Result := '';
  end;
end;

function GetApiReferenceEndpoints: TOwmApiRefEndpointArray;
var
  I: Integer;
begin
  SetLength(Result, Length(CEndpoints));
  for I := 0 to High(CEndpoints) do
    Result[I] := CEndpoints[I];
end;

end.

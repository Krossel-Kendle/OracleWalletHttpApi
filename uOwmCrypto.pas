unit uOwmCrypto;

interface

uses
  System.SysUtils;

type
  TOwmEncryptionScope = (esCurrentUser, esLocalMachine);

function EncryptString(const APlainText: string; AScope: TOwmEncryptionScope = esCurrentUser): string;
function DecryptString(const ACipherText: string): string;
function IsEncryptedValue(const AValue: string): Boolean;

implementation

uses
  Winapi.Windows,
  System.NetEncoding,
  System.StrUtils,
  uOwmI18n;

const
  CEncryptPrefix = 'dpapi:';
  CRYPTPROTECT_UI_FORBIDDEN = $1;
  CRYPTPROTECT_LOCAL_MACHINE = $4;

function CryptProtectData(
  pDataIn: PDATA_BLOB;
  szDataDescr: LPCWSTR;
  pOptionalEntropy: PDATA_BLOB;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PDATA_BLOB
): BOOL; stdcall; external 'Crypt32.dll' name 'CryptProtectData';

function CryptUnprotectData(
  pDataIn: PDATA_BLOB;
  ppszDataDescr: PLPWSTR;
  pOptionalEntropy: PDATA_BLOB;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PDATA_BLOB
): BOOL; stdcall; external 'Crypt32.dll' name 'CryptUnprotectData';

function IsEncryptedValue(const AValue: string): Boolean;
begin
  Result := StartsText(CEncryptPrefix, Trim(AValue));
end;

function NormalizeBase64(const AValue: string): string;
begin
  Result := Trim(AValue);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '', [rfReplaceAll]);
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
end;

function EncryptString(const APlainText: string; AScope: TOwmEncryptionScope): string;
var
  LInBlob: DATA_BLOB;
  LOutBlob: DATA_BLOB;
  LInBytes: TBytes;
  LOutBytes: TBytes;
  LFlags: DWORD;
begin
  if APlainText = '' then
    Exit('');

  LFlags := CRYPTPROTECT_UI_FORBIDDEN;
  if AScope = esLocalMachine then
    LFlags := LFlags or CRYPTPROTECT_LOCAL_MACHINE;

  LInBytes := TEncoding.UTF8.GetBytes(APlainText);
  ZeroMemory(@LInBlob, SizeOf(LInBlob));
  ZeroMemory(@LOutBlob, SizeOf(LOutBlob));
  LInBlob.cbData := Length(LInBytes);
  if LInBlob.cbData > 0 then
    LInBlob.pbData := @LInBytes[0];

  if not CryptProtectData(@LInBlob, nil, nil, nil, nil, LFlags, @LOutBlob) then
    raise Exception.CreateFmt(OwmText('crypto.err.protect', 'CryptProtectData failed. code=%d'), [GetLastError]);

  try
    SetLength(LOutBytes, LOutBlob.cbData);
    if LOutBlob.cbData > 0 then
      Move(LOutBlob.pbData^, LOutBytes[0], LOutBlob.cbData);
  finally
    if Assigned(LOutBlob.pbData) then
      LocalFree(HLOCAL(LOutBlob.pbData));
  end;

  Result := CEncryptPrefix + NormalizeBase64(TNetEncoding.Base64.EncodeBytesToString(LOutBytes));
end;

function DecryptString(const ACipherText: string): string;
var
  LText: string;
  LBase64: string;
  LInBlob: DATA_BLOB;
  LOutBlob: DATA_BLOB;
  LInBytes: TBytes;
  LOutBytes: TBytes;
begin
  LText := Trim(ACipherText);
  if LText = '' then
    Exit('');

  if not IsEncryptedValue(LText) then
    Exit(LText);

  LBase64 := Copy(LText, Length(CEncryptPrefix) + 1, MaxInt);
  LInBytes := TNetEncoding.Base64.DecodeStringToBytes(NormalizeBase64(LBase64));

  ZeroMemory(@LInBlob, SizeOf(LInBlob));
  ZeroMemory(@LOutBlob, SizeOf(LOutBlob));
  LInBlob.cbData := Length(LInBytes);
  if LInBlob.cbData > 0 then
    LInBlob.pbData := @LInBytes[0];

  if not CryptUnprotectData(@LInBlob, nil, nil, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @LOutBlob) then
    raise Exception.CreateFmt(OwmText('crypto.err.unprotect', 'CryptUnprotectData failed. code=%d'), [GetLastError]);

  try
    SetLength(LOutBytes, LOutBlob.cbData);
    if LOutBlob.cbData > 0 then
      Move(LOutBlob.pbData^, LOutBytes[0], LOutBlob.cbData);
  finally
    if Assigned(LOutBlob.pbData) then
      LocalFree(HLOCAL(LOutBlob.pbData));
  end;

  Result := TEncoding.UTF8.GetString(LOutBytes);
end;

end.

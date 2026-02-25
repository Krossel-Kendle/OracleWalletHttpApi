unit uOwmTypes;

interface

uses
  System.SysUtils;

type
  TCertInfo = record
    DisplayName: string;
    Subject: string;
    Issuer: string;
    NotAfter: TDateTime;
    NotAfterText: string;
    Thumbprint: string;
    SourcePath: string;
  end;

  TCertInfoArray = TArray<TCertInfo>;

function CertDisplayName(const ACert: TCertInfo): string;

implementation

uses
  uOwmI18n;

function ExtractCn(const ASubject: string): string;
var
  LSubject: string;
  LPos: Integer;
  LRest: string;
  LEnd: Integer;
begin
  Result := '';
  LSubject := Trim(ASubject);
  if LSubject = '' then
    Exit;

  LPos := Pos('CN=', UpperCase(LSubject));
  if LPos <= 0 then
    Exit;

  LRest := Copy(LSubject, LPos + 3, MaxInt);
  LEnd := Pos(',', LRest);
  if LEnd > 0 then
    Result := Trim(Copy(LRest, 1, LEnd - 1))
  else
    Result := Trim(LRest);
end;

function CertDisplayName(const ACert: TCertInfo): string;
var
  LCn: string;
begin
  LCn := ExtractCn(ACert.Subject);
  if LCn <> '' then
    Exit(LCn);

  if Trim(ACert.DisplayName) <> '' then
    Exit(ACert.DisplayName);

  if Trim(ACert.Subject) <> '' then
    Exit(ACert.Subject);

  if Trim(ACert.Thumbprint) <> '' then
    Exit(ACert.Thumbprint);

  Result := OwmText('types.unknown', '(unknown)');
end;

end.

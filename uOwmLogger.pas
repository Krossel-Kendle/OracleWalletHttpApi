unit uOwmLogger;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  TOwmLogLevel = (llError, llWarning, llInfo, llDebug);

  TOwmLogger = class
  private
    FLock: TCriticalSection;
    FLines: TStringList;
    FLogsDir: string;
    FMaxLines: Integer;
    FOnLine: TNotifyEvent;
    procedure EnsureLogsDir;
    procedure TrimBuffer;
    procedure WriteFileLine(const ALine: string);
    procedure EmitUiEvent;
  public
    constructor Create(const ALogsDir: string; AMaxLines: Integer = 100);
    destructor Destroy; override;

    procedure Log(ALevel: TOwmLogLevel; const AMessage: string);
    procedure Info(const AMessage: string);
    procedure Warn(const AMessage: string);
    procedure &Error(const AMessage: string);
    procedure Debug(const AMessage: string);

    function Snapshot: TArray<string>;
    function LastLine: string;

    property OnLine: TNotifyEvent read FOnLine write FOnLine;
  end;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  Vcl.Forms;

{ TOwmLogger }

constructor TOwmLogger.Create(const ALogsDir: string; AMaxLines: Integer);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLines := TStringList.Create;
  FLogsDir := IncludeTrailingPathDelimiter(ALogsDir);
  if AMaxLines < 10 then
    FMaxLines := 10
  else
    FMaxLines := AMaxLines;
  EnsureLogsDir;
end;

destructor TOwmLogger.Destroy;
begin
  FLines.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TOwmLogger.EnsureLogsDir;
begin
  if not TDirectory.Exists(FLogsDir) then
    TDirectory.CreateDirectory(FLogsDir);
end;

procedure TOwmLogger.TrimBuffer;
begin
  while FLines.Count > FMaxLines do
    FLines.Delete(0);
end;

procedure TOwmLogger.WriteFileLine(const ALine: string);
var
  LPath: string;
begin
  EnsureLogsDir;
  LPath := TPath.Combine(FLogsDir, 'app_' + FormatDateTime('yyyymmdd', Date) + '.log');
  TFile.AppendAllText(LPath, ALine + sLineBreak, TEncoding.UTF8);
end;

procedure TOwmLogger.EmitUiEvent;
begin
  if not Assigned(FOnLine) then
    Exit;

  if Assigned(Application) then
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnLine) then
          FOnLine(Self);
      end)
  else
    FOnLine(Self);
end;

procedure TOwmLogger.Log(ALevel: TOwmLogLevel; const AMessage: string);
const
  CLevelTags: array[TOwmLogLevel] of string = ('ERROR', 'WARN', 'INFO', 'DEBUG');
var
  LLine: string;
begin
  LLine := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' [' + CLevelTags[ALevel] + '] ' + AMessage;

  FLock.Acquire;
  try
    FLines.Add(LLine);
    TrimBuffer;
    WriteFileLine(LLine);
  finally
    FLock.Release;
  end;

  EmitUiEvent;
end;

procedure TOwmLogger.Info(const AMessage: string);
begin
  Log(llInfo, AMessage);
end;

procedure TOwmLogger.Warn(const AMessage: string);
begin
  Log(llWarning, AMessage);
end;

procedure TOwmLogger.Error(const AMessage: string);
begin
  Log(llError, AMessage);
end;

procedure TOwmLogger.Debug(const AMessage: string);
begin
  Log(llDebug, AMessage);
end;

function TOwmLogger.Snapshot: TArray<string>;
var
  I: Integer;
begin
  FLock.Acquire;
  try
    SetLength(Result, FLines.Count);
    for I := 0 to FLines.Count - 1 do
      Result[I] := FLines[I];
  finally
    FLock.Release;
  end;
end;

function TOwmLogger.LastLine: string;
begin
  Result := '';
  FLock.Acquire;
  try
    if FLines.Count > 0 then
      Result := FLines[FLines.Count - 1];
  finally
    FLock.Release;
  end;
end;

end.

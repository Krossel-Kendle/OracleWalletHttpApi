unit uOwmProcessRunner;

interface

uses
  Winapi.Windows,
  System.SysUtils;

type
  TProcessRunResult = record
    ExitCode: Cardinal;
    OutputText: string;
    TimedOut: Boolean;
    ErrorMessage: string;
  end;

function RunProcessCapture(const AExePath, AArgsLine: string; ATimeoutMs: Cardinal;
  out AResult: TProcessRunResult): Boolean;

implementation

function BytesToString(const ABytes: TBytes): string;
begin
  if Length(ABytes) = 0 then
    Exit('');

  try
    Result := TEncoding.UTF8.GetString(ABytes);
  except
    Result := TEncoding.ANSI.GetString(ABytes);
  end;
end;

procedure AppendBytes(var ADest: TBytes; const ASrc: TBytes; ACount: Integer);
var
  LOldLen: Integer;
begin
  if ACount <= 0 then
    Exit;
  LOldLen := Length(ADest);
  SetLength(ADest, LOldLen + ACount);
  Move(ASrc[0], ADest[LOldLen], ACount);
end;

function ReadAvailablePipeBytes(APipeHandle: THandle; var ABuffer: TBytes): Boolean;
var
  LBytesAvail: DWORD;
  LBytesRead: DWORD;
  LChunk: TBytes;
begin
  Result := True;
  SetLength(LChunk, 8192);

  while True do
  begin
    if not PeekNamedPipe(APipeHandle, nil, 0, nil, @LBytesAvail, nil) then
      Exit(False);
    if LBytesAvail = 0 then
      Break;

    if not ReadFile(APipeHandle, LChunk[0], Length(LChunk), LBytesRead, nil) then
      Exit(False);

    AppendBytes(ABuffer, LChunk, LBytesRead);
  end;
end;

function RunProcessCapture(const AExePath, AArgsLine: string; ATimeoutMs: Cardinal;
  out AResult: TProcessRunResult): Boolean;
var
  LSecAttr: TSecurityAttributes;
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LReadPipe: THandle;
  LWritePipe: THandle;
  LCmdLine: string;
  LWaitCode: DWORD;
  LStartTick: UInt64;
  LOutputBytes: TBytes;
begin
  FillChar(AResult, SizeOf(AResult), 0);
  AResult.ExitCode := Cardinal(-1);
  AResult.TimedOut := False;
  AResult.ErrorMessage := '';

  LReadPipe := 0;
  LWritePipe := 0;

  FillChar(LSecAttr, SizeOf(LSecAttr), 0);
  LSecAttr.nLength := SizeOf(LSecAttr);
  LSecAttr.bInheritHandle := True;

  if not CreatePipe(LReadPipe, LWritePipe, @LSecAttr, 0) then
  begin
    AResult.ErrorMessage := SysErrorMessage(GetLastError);
    Exit(False);
  end;

  try
    if not SetHandleInformation(LReadPipe, HANDLE_FLAG_INHERIT, 0) then
    begin
      AResult.ErrorMessage := SysErrorMessage(GetLastError);
      Exit(False);
    end;

    FillChar(LStartupInfo, SizeOf(LStartupInfo), 0);
    LStartupInfo.cb := SizeOf(LStartupInfo);
    LStartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    LStartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    LStartupInfo.hStdOutput := LWritePipe;
    LStartupInfo.hStdError := LWritePipe;
    LStartupInfo.wShowWindow := SW_HIDE;
    FillChar(LProcessInfo, SizeOf(LProcessInfo), 0);

    LCmdLine := '"' + AExePath + '" ' + AArgsLine;
    if not CreateProcess(nil, PChar(LCmdLine), nil, nil, True, CREATE_NO_WINDOW, nil, nil,
      LStartupInfo, LProcessInfo) then
    begin
      AResult.ErrorMessage := SysErrorMessage(GetLastError);
      Exit(False);
    end;

    try
      CloseHandle(LWritePipe);
      LWritePipe := 0;
      LStartTick := GetTickCount64;
      SetLength(LOutputBytes, 0);

      while True do
      begin
        if not ReadAvailablePipeBytes(LReadPipe, LOutputBytes) then
          Break;

        LWaitCode := WaitForSingleObject(LProcessInfo.hProcess, 50);
        if LWaitCode = WAIT_OBJECT_0 then
          Break;

        if (ATimeoutMs > 0) and ((GetTickCount64 - LStartTick) >= ATimeoutMs) then
        begin
          AResult.TimedOut := True;
          TerminateProcess(LProcessInfo.hProcess, 1);
          Break;
        end;
      end;

      ReadAvailablePipeBytes(LReadPipe, LOutputBytes);
      WaitForSingleObject(LProcessInfo.hProcess, 5000);
      GetExitCodeProcess(LProcessInfo.hProcess, AResult.ExitCode);
      AResult.OutputText := BytesToString(LOutputBytes);
      Result := True;
    finally
      CloseHandle(LProcessInfo.hThread);
      CloseHandle(LProcessInfo.hProcess);
    end;
  finally
    if LReadPipe <> 0 then
      CloseHandle(LReadPipe);
    if LWritePipe <> 0 then
      CloseHandle(LWritePipe);
  end;
end;

end.

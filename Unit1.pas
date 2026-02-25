unit Unit1;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellAPI,
  System.SysUtils,
  System.UITypes,
  System.Variants,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.Math,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Menus,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  uOwmTypes,
  uOwmSettings,
  uOwmLogger,
  uOwmToolsDetector,
  uOwmWalletService,
  uOwmApiServer,
  uOwmI18n;

type
  TForm1 = class(TForm)
    mmMain: TMainMenu;
    miApp: TMenuItem;
    miSettings: TMenuItem;
    miAddWallet: TMenuItem;
    miApiReference: TMenuItem;
    miAbout: TMenuItem;
    miOptions: TMenuItem;
    miConfigure: TMenuItem;
    pnlClient: TPanel;
    pcMain: TPageControl;
    tsGeneral: TTabSheet;
    tsLog: TTabSheet;
    pnlGeneralClient: TPanel;
    pnlLeft: TPanel;
    splMain: TSplitter;
    pnlRight: TPanel;
    gbWallet: TGroupBox;
    lbCerts: TListBox;
    pnlButtons1: TPanel;
    btnView: TButton;
    btnAdd: TButton;
    btnRemove: TButton;
    pnlButtons2: TPanel;
    btnLoadFromFolder: TButton;
    btnRemoveAll: TButton;
    gbSummary: TGroupBox;
    lblTotalCertsCaption: TLabel;
    lblTotalCertsValue: TLabel;
    lblExpSoonCaption: TLabel;
    lblExp1: TLabel;
    lblExp2: TLabel;
    lblExp3: TLabel;
    lblExp4: TLabel;
    lblExp5: TLabel;
    gbDetails: TGroupBox;
    pnlDetailCn: TPanel;
    lblCn: TLabel;
    edtCN: TEdit;
    pnlDetailIssuer: TPanel;
    lblIssuer: TLabel;
    edtIssuer: TEdit;
    pnlDetailNotAfter: TPanel;
    lblNotAfter: TLabel;
    edtNotAfter: TEdit;
    pnlDetailThumb: TPanel;
    lblThumb: TLabel;
    edtThumbprint: TEdit;
    pnlDetailPath: TPanel;
    lblPath: TLabel;
    edtPath: TEdit;
    memoLog: TMemo;
    pnlStatus: TPanel;
    lblBrand: TLabel;
    lblSite: TLabel;
    lblToolsCaption: TLabel;
    lblWalletToolStatus: TLabel;
    lblSqlPlusStatus: TLabel;
    lblServerCaption: TLabel;
    lblServerStatus: TLabel;
    lblEnhancedCaption: TLabel;
    lblEnhancedStatus: TLabel;
    lblStatus: TLabel;
    dlgOpenCert: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure miSettingsClick(Sender: TObject);
    procedure miAddWalletClick(Sender: TObject);
    procedure miApiReferenceClick(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure miConfigureClick(Sender: TObject);
    procedure lbCertsClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnLoadFromFolderClick(Sender: TObject);
    procedure btnRemoveAllClick(Sender: TObject);
    procedure lblSiteClick(Sender: TObject);
    procedure lblSiteMouseEnter(Sender: TObject);
    procedure lblSiteMouseLeave(Sender: TObject);
  private
    FSettingsService: TOwmSettingsService;
    FSettings: TOwmSettings;
    FLogger: TOwmLogger;
    FTools: TOwmToolsInfo;
    FWalletService: TOwmWalletService;
    FApiServer: TOwmApiServer;
    FCerts: TCertInfoArray;

    procedure InitializeServices;
    procedure ApplyToolsState;
    procedure RefreshCertificates;
    procedure UpdateSummary;
    procedure UpdateDetails;
    procedure ApplyLanguage;
    procedure UpdateStatusBar;
    function WalletPassword: string;

    procedure ApplyApiSettings;
    procedure LoggerLine(Sender: TObject);
    procedure ApiStateChanged(Sender: TObject);

    procedure SetStatusText(const AText: string);
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.Generics.Collections,
  Vcl.FileCtrl,
  uOwmCrypto,
  uSettingsForm,
  uAboutForm,
  uWalletConfigForm,
  uApiReferenceForm,
  uAddWalletForm;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
  btnView.Visible := False;
  dlgOpenCert.Options := dlgOpenCert.Options + [ofFileMustExist];

  InitializeServices;
  ApplyLanguage;
  ApplyToolsState;

  if FTools.OrapkiAvailable and (Trim(FSettings.WalletPath) <> '') then
    RefreshCertificates;

  UpdateStatusBar;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(FSettings) and Assigned(FApiServer) then
  begin
    FSettings.ApiRunning := FApiServer.IsRunning;
    FSettingsService.Save(FSettings);
  end;

  FApiServer.Free;
  FWalletService.Free;
  FSettings.Free;
  FSettingsService.Free;
  if Assigned(FLogger) then
    FLogger.OnLine := nil;
  FLogger.Free;
end;

procedure TForm1.InitializeServices;
var
  LBaseDir: string;
  LError: string;
  LLine: string;
begin
  LBaseDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  FSettingsService := TOwmSettingsService.Create(LBaseDir);
  FSettings := FSettingsService.Load;
  OwmSetLanguage(FSettings.Language);

  FLogger := TOwmLogger.Create(TPath.Combine(LBaseDir, 'logs'), 100);
  FLogger.OnLine := LoggerLine;

  FTools := DetectOracleTools;
  if FTools.OrapkiAvailable then
    FLogger.Info(OwmTextFmt('log.orapki_found', 'orapki found: %s', [FTools.OrapkiPath]))
  else
    FLogger.Warn(OwmText('log.orapki_not_found', 'orapki not found'));

  if FTools.SqlPlusAvailable then
    FLogger.Info(OwmTextFmt('log.sqlplus_found', 'sqlplus found: %s', [FTools.SqlPlusPath]))
  else
    FLogger.Warn(OwmText('log.sqlplus_not_found', 'sqlplus not found'));

  FWalletService := TOwmWalletService.Create(FTools, FLogger);

  FApiServer := TOwmApiServer.Create(FWalletService, FLogger, FTools);
  FApiServer.OnStateChanged := ApiStateChanged;
  FApiServer.ApplySettings(FSettings);

  if FSettings.ApiEnabled then
  begin
    if not FApiServer.Start(LError) then
    begin
      MessageDlg(OwmTextFmt('msg.api_start_failed', 'API start failed: %s', [LError]), mtError, [mbOK], 0);
      FSettings.ApiEnabled := False;
      FSettings.ApiRunning := False;
      FSettingsService.Save(FSettings);
    end
    else
      FSettings.ApiRunning := True;
  end;

  for LLine in FLogger.Snapshot do
    memoLog.Lines.Add(LLine);
end;

procedure TForm1.ApplyToolsState;
var
  LEnabled: Boolean;
begin
  LEnabled := FTools.OrapkiAvailable;

  lbCerts.Enabled := LEnabled;
  btnAdd.Enabled := LEnabled;
  btnRemove.Enabled := LEnabled;
  btnLoadFromFolder.Enabled := LEnabled;
  btnRemoveAll.Enabled := LEnabled;
  miAddWallet.Enabled := LEnabled;

  if not LEnabled then
    SetStatusText(OwmText('msg.orapki_disabled', 'orapki.exe not found. Wallet actions are disabled.'));
end;

function TForm1.WalletPassword: string;
begin
  Result := DecryptString(FSettings.WalletPasswordEnc);
end;

procedure TForm1.RefreshCertificates;
var
  LError: string;
  LCert: TCertInfo;
begin
  if not FTools.OrapkiAvailable then
    Exit;

  if Trim(FSettings.WalletPath) = '' then
  begin
    SetLength(FCerts, 0);
    lbCerts.Items.Clear;
    UpdateSummary;
    UpdateDetails;
    SetStatusText(OwmText('msg.wallet_not_configured', 'Wallet path is not configured.'));
    Exit;
  end;

  if not FWalletService.ListCertificates(FSettings.WalletPath, WalletPassword, FCerts, LError) then
  begin
    SetStatusText(OwmTextFmt('msg.wallet_read_error', 'Wallet read error: %s', [LError]));
    FLogger.Error(OwmTextFmt('msg.wallet_read_error', 'Wallet read error: %s', [LError]));
    Exit;
  end;

  lbCerts.Items.BeginUpdate;
  try
    lbCerts.Items.Clear;
    for LCert in FCerts do
      lbCerts.Items.Add(CertDisplayName(LCert));
    if lbCerts.Items.Count > 0 then
      lbCerts.ItemIndex := 0;
  finally
    lbCerts.Items.EndUpdate;
  end;

  UpdateSummary;
  UpdateDetails;
  SetStatusText(OwmTextFmt('msg.loaded_certs', 'Loaded %d certificate(s).', [Length(FCerts)]));
end;

procedure TForm1.UpdateSummary;
var
  LUpcoming: TCertInfoArray;
  LCount: Integer;
  I: Integer;
  J: Integer;
  LTemp: TCertInfo;
  LLabels: array[0..4] of TLabel;
begin
  lblTotalCertsValue.Caption := IntToStr(Length(FCerts));

  SetLength(LUpcoming, 0);
  for I := 0 to High(FCerts) do
    if FCerts[I].NotAfter > 0 then
    begin
      LCount := Length(LUpcoming);
      SetLength(LUpcoming, LCount + 1);
      LUpcoming[LCount] := FCerts[I];
    end;

  for I := 0 to High(LUpcoming) - 1 do
    for J := I + 1 to High(LUpcoming) do
      if LUpcoming[I].NotAfter > LUpcoming[J].NotAfter then
      begin
        LTemp := LUpcoming[I];
        LUpcoming[I] := LUpcoming[J];
        LUpcoming[J] := LTemp;
      end;

  LLabels[0] := lblExp1;
  LLabels[1] := lblExp2;
  LLabels[2] := lblExp3;
  LLabels[3] := lblExp4;
  LLabels[4] := lblExp5;

  for I := 0 to 4 do
  begin
    if I <= High(LUpcoming) then
    begin
      LLabels[I].Visible := True;
      LLabels[I].Caption := Format('%s - %s', [FormatDateTime('yyyy-mm-dd', LUpcoming[I].NotAfter),
        CertDisplayName(LUpcoming[I])]);
    end
    else
      LLabels[I].Visible := False;
  end;
end;

procedure TForm1.UpdateDetails;
var
  LIndex: Integer;
  LCert: TCertInfo;
begin
  LIndex := lbCerts.ItemIndex;
  if (LIndex < 0) or (LIndex > High(FCerts)) then
  begin
    edtCN.Text := '';
    edtIssuer.Text := '';
    edtNotAfter.Text := '';
    edtThumbprint.Text := '';
    edtPath.Text := '';
    Exit;
  end;

  LCert := FCerts[LIndex];
  edtCN.Text := CertDisplayName(LCert);
  edtIssuer.Text := LCert.Issuer;
  if Trim(LCert.NotAfterText) <> '' then
    edtNotAfter.Text := LCert.NotAfterText
  else if LCert.NotAfter > 0 then
    edtNotAfter.Text := FormatDateTime('yyyy-mm-dd hh:nn:ss', LCert.NotAfter)
  else
    edtNotAfter.Text := '';
  edtThumbprint.Text := LCert.Thumbprint;
  edtPath.Text := LCert.SourcePath;
end;

procedure TForm1.ApplyApiSettings;
var
  LError: string;
begin
  FApiServer.ApplySettings(FSettings);

  if FApiServer.IsRunning then
    FApiServer.Stop;

  if FSettings.ApiEnabled then
  begin
    if not FApiServer.Start(LError) then
    begin
      FSettings.ApiEnabled := False;
      MessageDlg(OwmTextFmt('msg.api_start_failed', 'API start failed: %s', [LError]), mtError, [mbOK], 0);
    end;
  end
  else
    FApiServer.Stop;

  FSettings.ApiRunning := FApiServer.IsRunning;
  FSettingsService.Save(FSettings);

  UpdateStatusBar;
end;

procedure TForm1.ApiStateChanged(Sender: TObject);
begin
  FSettings.ApiRunning := FApiServer.IsRunning;
  UpdateStatusBar;
end;

procedure TForm1.LoggerLine(Sender: TObject);
var
  LLine: string;
begin
  if not Assigned(FLogger) then
    Exit;

  LLine := FLogger.LastLine;
  if LLine = '' then
    Exit;

  memoLog.Lines.Add(LLine);
  while memoLog.Lines.Count > 100 do
    memoLog.Lines.Delete(0);

  lblStatus.Caption := LLine;
end;

procedure TForm1.UpdateStatusBar;
begin
  lblWalletToolStatus.Font.Style := [fsBold];
  if FTools.OrapkiAvailable then
  begin
    lblWalletToolStatus.Caption := OwmText('status.wallet_tool_ok', 'wallet tool: OK');
    lblWalletToolStatus.Font.Color := clGreen;
    lblWalletToolStatus.Transparent := True;
    lblWalletToolStatus.Color := clBtnFace;
  end
  else
  begin
    lblWalletToolStatus.Caption := OwmText('status.wallet_tool_missing', 'wallet tool: MISSING');
    lblWalletToolStatus.Font.Color := clWhite;
    lblWalletToolStatus.Transparent := False;
    lblWalletToolStatus.Color := clRed;
  end;

  lblSqlPlusStatus.Font.Style := [fsBold];
  if FTools.SqlPlusAvailable then
  begin
    lblSqlPlusStatus.Caption := OwmText('status.sqlplus_ok', 'sqlplus: OK');
    lblSqlPlusStatus.Font.Color := clGreen;
    lblSqlPlusStatus.Transparent := True;
    lblSqlPlusStatus.Color := clBtnFace;
  end
  else
  begin
    lblSqlPlusStatus.Caption := OwmText('status.sqlplus_missing', 'sqlplus: MISSING');
    lblSqlPlusStatus.Font.Color := clBlack;
    lblSqlPlusStatus.Transparent := False;
    lblSqlPlusStatus.Color := clYellow;
  end;

  if Assigned(FApiServer) and FApiServer.IsRunning then
  begin
    lblServerStatus.Caption := OwmText('status.server_running', 'RUNNING');
    lblServerStatus.Font.Style := [fsBold];
    lblServerStatus.Font.Color := clGreen;
  end
  else
  begin
    lblServerStatus.Caption := OwmText('status.server_stopped', 'STOPPED');
    lblServerStatus.Font.Style := [fsBold];
    lblServerStatus.Font.Color := clRed;
  end;

  if Assigned(FSettings) and FSettings.EnhancedApiEnabled then
  begin
    lblEnhancedStatus.Caption := OwmText('status.on', 'on');
    lblEnhancedStatus.Font.Color := clGreen;
  end
  else
  begin
    lblEnhancedStatus.Caption := OwmText('status.off', 'off');
    lblEnhancedStatus.Font.Color := clRed;
  end;
end;

procedure TForm1.ApplyLanguage;
begin
  Caption := OwmText('main.caption', 'Oracle Wallet Certificate Manager');
  tsGeneral.Caption := OwmText('main.tab.general', 'General');
  tsLog.Caption := OwmText('main.tab.log', 'Log');

  gbWallet.Caption := OwmText('main.group.wallet', 'Wallet Certificates');
  gbSummary.Caption := OwmText('main.group.summary', 'Summary');
  gbDetails.Caption := OwmText('main.group.details', 'Selected Certificate');

  lblTotalCertsCaption.Caption := OwmText('main.label.total', 'Installed certificates:');
  lblExpSoonCaption.Caption := OwmText('main.label.expiring', 'Expiring soon:');
  lblCn.Caption := OwmText('main.label.cn', 'CN');
  lblIssuer.Caption := OwmText('main.label.issuer', 'Issuer');
  lblNotAfter.Caption := OwmText('main.label.not_after', 'NotAfter');
  lblThumb.Caption := OwmText('main.label.thumbprint', 'Thumbprint');
  lblPath.Caption := OwmText('main.label.path', 'Path');

  btnView.Caption := OwmText('btn.view', 'View');
  btnAdd.Caption := OwmText('btn.add', 'Add');
  btnRemove.Caption := OwmText('btn.remove', 'Remove');
  btnLoadFromFolder.Caption := OwmText('btn.load_folder', 'Load From Folder');
  btnRemoveAll.Caption := OwmText('btn.remove_all', 'Remove All');

  miApp.Caption := OwmText('menu.app', 'App');
  miSettings.Caption := OwmText('menu.settings', 'Settings');
  miAddWallet.Caption := OwmText('menu.add_wallet', 'Add New Wallet');
  miApiReference.Caption := OwmText('menu.api_reference', 'API Reference');
  miAbout.Caption := OwmText('menu.about', 'About');
  miOptions.Caption := OwmText('menu.options', 'Wallet Configuration');
  miConfigure.Caption := OwmText('menu.configure', 'Configure');

  lblToolsCaption.Caption := OwmText('status.tools', 'Tools:');
  lblServerCaption.Caption := OwmText('status.server', 'Server:');
  lblEnhancedCaption.Caption := OwmText('status.enhanced_api', 'Enhanced api:');

  if (lblStatus.Caption = '') or SameText(lblStatus.Caption, 'Ready') or
     SameText(lblStatus.Caption, 'Готово') or SameText(lblStatus.Caption, 'Siap') then
    lblStatus.Caption := OwmText('status.ready', 'Ready');

  dlgOpenCert.Filter := OwmText('filefilter.certificates', 'Certificates') +
    '|*.crt;*.cer;*.pem;*.der|' +
    OwmText('filefilter.all_files', 'All files') + '|*.*';

  UpdateStatusBar;
end;

procedure TForm1.miAddWalletClick(Sender: TObject);
var
  LOptions: TOwmNewWalletOptions;
  LError: string;
begin
  if not FTools.OrapkiAvailable then
  begin
    MessageDlg(OwmText('msg.orapki_disabled',
      'orapki.exe not found. Wallet actions are disabled.'), mtError, [mbOK], 0);
    Exit;
  end;

  if TAddWalletForm.Execute(LOptions) then
  begin
    if not FWalletService.CreateWallet(LOptions.WalletPath, LOptions.Password,
      LOptions.AutoLogin, LOptions.AutoLoginLocal, LError) then
    begin
      MessageDlg(OwmTextFmt('msg.wallet_create_failed', 'Failed to create wallet: %s',
        [LError]), mtError, [mbOK], 0);
    end
    else
    begin
      FSettings.WalletPath := LOptions.WalletPath;
      FSettings.WalletPasswordEnc := EncryptString(LOptions.Password);
      FSettingsService.Save(FSettings);
      FApiServer.ApplySettings(FSettings);
      RefreshCertificates;
      UpdateStatusBar;
      SetStatusText(OwmTextFmt('msg.wallet_created_switched',
        'New wallet created and activated: %s', [LOptions.WalletPath]));
    end;
  end;
end;

procedure TForm1.SetStatusText(const AText: string);
begin
  lblStatus.Caption := AText;
end;

procedure TForm1.miSettingsClick(Sender: TObject);
begin
  if TSettingsForm.Execute(FSettings) then
  begin
    OwmSetLanguage(FSettings.Language);
    ApplyLanguage;
    FSettingsService.Save(FSettings);
    ApplyApiSettings;
    RefreshCertificates;
    SetStatusText(OwmText('msg.settings_updated', 'Settings updated.'));
  end;
end;

procedure TForm1.miAboutClick(Sender: TObject);
begin
  TAboutForm.Execute(Self);
end;

procedure TForm1.miApiReferenceClick(Sender: TObject);
begin
  TApiReferenceForm.Execute(Self);
end;

procedure TForm1.miConfigureClick(Sender: TObject);
begin
  if TWalletConfigForm.Execute(FSettings, FTools.OrapkiAvailable) then
  begin
    FSettingsService.Save(FSettings);
    FApiServer.ApplySettings(FSettings);
    RefreshCertificates;
    UpdateStatusBar;
    SetStatusText(OwmText('msg.wallet_config_saved', 'Wallet configuration saved.'));
  end;
end;

procedure TForm1.lbCertsClick(Sender: TObject);
begin
  UpdateDetails;
end;

procedure TForm1.btnAddClick(Sender: TObject);
var
  LError: string;
begin
  if not dlgOpenCert.Execute then
    Exit;

  if not FWalletService.AddCertificate(FSettings.WalletPath, WalletPassword, dlgOpenCert.FileName, LError) then
  begin
    MessageDlg(OwmTextFmt('msg.add_failed', 'Failed to add certificate: %s', [LError]), mtError, [mbOK], 0);
    Exit;
  end;

  RefreshCertificates;
end;

procedure TForm1.btnRemoveClick(Sender: TObject);
var
  LIndex: Integer;
  LError: string;
  LSubject: string;
begin
  LIndex := lbCerts.ItemIndex;
  if (LIndex < 0) or (LIndex > High(FCerts)) then
    Exit;

  if MessageDlg(OwmText('msg.confirm_remove_selected', 'Remove selected certificate?'), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  LSubject := FCerts[LIndex].Subject;
  if not FWalletService.RemoveCertificate(FSettings.WalletPath, WalletPassword, LSubject, LError) then
  begin
    MessageDlg(OwmTextFmt('msg.remove_failed', 'Failed to remove certificate: %s', [LError]), mtError, [mbOK], 0);
    Exit;
  end;

  RefreshCertificates;
end;

procedure TForm1.btnLoadFromFolderClick(Sender: TObject);
var
  LFolder: string;
  LAdded: Integer;
  LSkipped: Integer;
  LFailed: Integer;
  LError: string;
begin
  LFolder := '';
  if not SelectDirectory(OwmText('msg.select_cert_folder', 'Select folder with certificates'), '', LFolder) then
    Exit;

  FWalletService.AddFromFolder(FSettings.WalletPath, WalletPassword, LFolder, LAdded, LSkipped, LFailed, LError);
  MessageDlg(OwmTextFmt('msg.folder_import_result', 'Added: %d, skipped: %d, failed: %d', [LAdded, LSkipped, LFailed]), mtInformation, [mbOK], 0);

  if (LError <> '') and (LFailed > 0) then
    FLogger.Warn(OwmTextFmt('log.folder_import_warn', 'Folder import warnings: %s', [LError]));

  RefreshCertificates;
end;

procedure TForm1.btnRemoveAllClick(Sender: TObject);
var
  LRemoved: Integer;
  LFailed: Integer;
  LError: string;
begin
  if Length(FCerts) = 0 then
    Exit;

  if MessageDlg(OwmText('msg.confirm_remove_all', 'Remove ALL certificates from wallet?'), mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  FWalletService.RemoveAllCertificates(FSettings.WalletPath, WalletPassword, FCerts, LRemoved, LFailed, LError);
  MessageDlg(OwmTextFmt('msg.remove_all_result', 'Removed: %d, errors: %d', [LRemoved, LFailed]), mtInformation, [mbOK], 0);

  if (LError <> '') and (LFailed > 0) then
    FLogger.Warn(OwmTextFmt('log.remove_all_warn', 'Remove all finished with warnings: %s', [LError]));

  RefreshCertificates;
end;

procedure TForm1.lblSiteClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar('https://kapps.at'), nil, nil, SW_SHOWNORMAL);
end;

procedure TForm1.lblSiteMouseEnter(Sender: TObject);
begin
  lblSite.Font.Color := clNavy;
end;

procedure TForm1.lblSiteMouseLeave(Sender: TObject);
begin
  lblSite.Font.Color := clBlue;
end;

end.

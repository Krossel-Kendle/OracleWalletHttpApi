unit uSettingsForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.NetEncoding,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  uOwmSettings;

type
  TSettingsForm = class(TForm)
    pnlClient: TPanel;
    gbLanguage: TGroupBox;
    pnlLanguageRow: TPanel;
    lblLanguage: TLabel;
    cbLanguage: TComboBox;
    gbApi: TGroupBox;
    sbApi: TScrollBox;
    pnlEnableApi: TPanel;
    chkEnableApi: TCheckBox;
    rgApiAuthType: TRadioGroup;
    pnlAuthHeader: TPanel;
    lblApiKey: TLabel;
    edtApiKey: TEdit;
    btnGenApiKey: TButton;
    pnlAuthBasic: TPanel;
    pnlBasicLogin: TPanel;
    lblBasicLogin: TLabel;
    edtApiLogin: TEdit;
    pnlBasicPassword: TPanel;
    lblBasicPassword: TLabel;
    edtApiPassword: TEdit;
    pnlApiPort: TPanel;
    lblApiPort: TLabel;
    edtApiPort: TEdit;
    rgAllowedHosts: TRadioGroup;
    pnlHostsList: TPanel;
    memAllowedIps: TMemo;
    pnlEnhancedSwitch: TPanel;
    chkEnhancedApi: TCheckBox;
    pnlEnhancedApi: TPanel;
    pnlPdbName: TPanel;
    lblPdbName: TLabel;
    cbPdbName: TComboBox;
    pnlAclUser: TPanel;
    lblAclAdminUser: TLabel;
    edtAclAdminUser: TEdit;
    pnlAclPassword: TPanel;
    lblAclAdminPassword: TLabel;
    edtAclAdminPassword: TEdit;
    pnlTns: TPanel;
    lblTns: TLabel;
    edtTns: TEdit;
    btnBrowseTns: TButton;
    pnlTnsHint: TPanel;
    lblTnsHint: TLabel;
    pnlBottom: TPanel;
    btnCancel: TButton;
    btnSave: TButton;
    dlgOpenTns: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure rgApiAuthTypeClick(Sender: TObject);
    procedure rgAllowedHostsClick(Sender: TObject);
    procedure chkEnhancedApiClick(Sender: TObject);
    procedure btnGenApiKeyClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cbLanguageChange(Sender: TObject);
    procedure btnBrowseTnsClick(Sender: TObject);
  private
    FSettings: TOwmSettings;
    procedure ApplyLanguage;
    procedure LoadFromSettings;
    procedure SaveToSettings;
    procedure UpdateUiState;
    function GenerateApiKey: string;
    procedure LoadPdbFromTns(const ATnsFileName, APreferredPdb: string);
    procedure ResolveTnsAndPdb;
  public
    class function Execute(var ASettings: TOwmSettings): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.Math,
  System.StrUtils,
  uOwmCrypto,
  uOwmI18n,
  uOwmTnsResolver;

class function TSettingsForm.Execute(var ASettings: TOwmSettings): Boolean;
var
  LForm: TSettingsForm;
  LPrevLanguage: string;
begin
  LPrevLanguage := OwmGetLanguage;
  LForm := TSettingsForm.Create(nil);
  try
    LForm.FSettings := TOwmSettings.Create;
    LForm.FSettings.Assign(ASettings);
    LForm.LoadFromSettings;
    OwmSetLanguage(LForm.FSettings.Language);
    LForm.ApplyLanguage;
    Result := LForm.ShowModal = mrOk;
    if Result then
    begin
      LForm.SaveToSettings;
      ASettings.Assign(LForm.FSettings);
      OwmSetLanguage(ASettings.Language);
    end
    else
    begin
      OwmSetLanguage(LPrevLanguage);
    end;
  finally
    LForm.FSettings.Free;
    LForm.Free;
  end;
end;

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  cbLanguage.OnChange := cbLanguageChange;

  cbLanguage.Items.Clear;
  cbLanguage.Items.Add('RU');
  cbLanguage.Items.Add('EN');
  cbLanguage.Items.Add('ID');

  dlgOpenTns.DefaultExt := 'ora';
  dlgOpenTns.Filter := 'tnsnames.ora|tnsnames.ora|Oracle files (*.ora)|*.ora|All files|*.*';
  dlgOpenTns.Options := dlgOpenTns.Options + [ofFileMustExist];

  OwmSetLanguage(OwmGetLanguage);
  ApplyLanguage;
  UpdateUiState;
end;

procedure TSettingsForm.ApplyLanguage;
var
  LAuthIndex: Integer;
  LHostsIndex: Integer;
begin
  Caption := OwmText('settings.caption', 'Settings');
  gbLanguage.Caption := OwmText('settings.group.language', 'Language');
  lblLanguage.Caption := OwmText('settings.label.ui_language', 'UI language');
  gbApi.Caption := OwmText('settings.group.api', 'API');
  chkEnableApi.Caption := OwmText('settings.enable_api', 'Enable API');
  rgApiAuthType.Caption := OwmText('settings.auth_type', 'Auth type');
  lblApiKey.Caption := OwmText('settings.api_key', 'X-API-Key');
  btnGenApiKey.Caption := OwmText('btn.generate', 'Generate');
  lblBasicLogin.Caption := OwmText('settings.basic_login', 'Basic login');
  lblBasicPassword.Caption := OwmText('settings.basic_password', 'Basic password');
  lblApiPort.Caption := OwmText('settings.api_port', 'API port');
  rgAllowedHosts.Caption := OwmText('settings.allowed_hosts', 'Allowed hosts');
  chkEnhancedApi.Caption := OwmText('settings.enhanced', 'Enhanced API (ACL via SQL*Plus)');
  lblPdbName.Caption := OwmText('settings.pdb_name', 'PDB name');
  lblAclAdminUser.Caption := OwmText('settings.acl_user', 'ACL admin user');
  lblAclAdminPassword.Caption := OwmText('settings.acl_password', 'ACL password');
  lblTns.Caption := OwmText('settings.tns', 'TNS file');
  btnBrowseTns.Caption := OwmText('btn.ellipsis', '...');
  lblTnsHint.Caption := OwmText('settings.tns_hint',
    'Path to tnsnames.ora. Use "..." to select file. PDB list is loaded from this file.');
  btnSave.Caption := OwmText('btn.save', 'Save');
  btnCancel.Caption := OwmText('btn.cancel', 'Cancel');
  dlgOpenTns.Title := OwmText('settings.tns_dialog_title', 'Select tnsnames.ora');
  dlgOpenTns.Filter := OwmText('filefilter.tnsnames', 'TNS names file') +
    '|tnsnames.ora|' + OwmText('filefilter.oracle_files', 'Oracle files') +
    '|*.ora|' + OwmText('filefilter.all_files', 'All files') + '|*.*';

  if (memAllowedIps.Lines.Count = 0) then
    memAllowedIps.Lines.Add(OwmText('settings.ips_hint', '# one IP per line'));

  LAuthIndex := rgApiAuthType.ItemIndex;
  if LAuthIndex < 0 then
    LAuthIndex := 0;
  rgApiAuthType.Items.Clear;
  rgApiAuthType.Items.Add(OwmText('settings.auth.header', 'Header'));
  rgApiAuthType.Items.Add(OwmText('settings.auth.basic', 'Basic'));
  rgApiAuthType.ItemIndex := LAuthIndex;

  LHostsIndex := rgAllowedHosts.ItemIndex;
  if LHostsIndex < 0 then
    LHostsIndex := 0;
  rgAllowedHosts.Items.Clear;
  rgAllowedHosts.Items.Add(OwmText('settings.hosts.all', 'All'));
  rgAllowedHosts.Items.Add(OwmText('settings.hosts.list', 'List'));
  rgAllowedHosts.ItemIndex := LHostsIndex;
end;

procedure TSettingsForm.LoadFromSettings;
var
  LIp: string;
begin
  cbLanguage.ItemIndex := cbLanguage.Items.IndexOf(FSettings.Language);
  if cbLanguage.ItemIndex < 0 then
    cbLanguage.ItemIndex := 0;

  chkEnableApi.Checked := FSettings.ApiEnabled;
  edtApiPort.Text := IntToStr(FSettings.ApiPort);

  if FSettings.ApiAuthType = aatBasic then
    rgApiAuthType.ItemIndex := 1
  else
    rgApiAuthType.ItemIndex := 0;

  edtApiKey.Text := DecryptString(FSettings.ApiKeyEnc);
  edtApiLogin.Text := DecryptString(FSettings.ApiBasicLoginEnc);
  edtApiPassword.Text := DecryptString(FSettings.ApiBasicPasswordEnc);

  if FSettings.AllowedHostsMode = ahmList then
    rgAllowedHosts.ItemIndex := 1
  else
    rgAllowedHosts.ItemIndex := 0;

  memAllowedIps.Clear;
  for LIp in FSettings.AllowedIps do
    memAllowedIps.Lines.Add(LIp);

  chkEnhancedApi.Checked := FSettings.EnhancedApiEnabled;
  edtAclAdminUser.Text := FSettings.AclAdminUser;
  edtAclAdminPassword.Text := DecryptString(FSettings.AclAdminPasswordEnc);
  ResolveTnsAndPdb;

  UpdateUiState;
end;

procedure TSettingsForm.LoadPdbFromTns(const ATnsFileName, APreferredPdb: string);
var
  LAliases: TArray<string>;
  LAlias: string;
  LPreferred: string;
  LIndex: Integer;
begin
  cbPdbName.Items.BeginUpdate;
  try
    cbPdbName.Items.Clear;

    if FileExists(ATnsFileName) then
      LAliases := ExtractTnsAliases(ATnsFileName)
    else
      SetLength(LAliases, 0);

    for LAlias in LAliases do
      cbPdbName.Items.Add(LAlias);

    LPreferred := Trim(APreferredPdb);
    if (LPreferred <> '') and (cbPdbName.Items.IndexOf(LPreferred) < 0) then
      cbPdbName.Items.Insert(0, LPreferred);

    if LPreferred <> '' then
      LIndex := cbPdbName.Items.IndexOf(LPreferred)
    else
      LIndex := -1;

    if (LIndex < 0) and (cbPdbName.Items.Count > 0) then
      LIndex := 0;

    cbPdbName.ItemIndex := LIndex;
  finally
    cbPdbName.Items.EndUpdate;
  end;
end;

procedure TSettingsForm.ResolveTnsAndPdb;
var
  LTnsFile: string;
begin
  LTnsFile := DetectTnsNamesFile(FSettings.Tns);
  edtTns.Text := LTnsFile;
  LoadPdbFromTns(LTnsFile, FSettings.PdbName);
end;

procedure TSettingsForm.SaveToSettings;
var
  LPort: Integer;
  LIpLines: TStringList;
  LLine: string;
  LCleanLine: string;
  I: Integer;
begin
  LPort := StrToIntDef(Trim(edtApiPort.Text), 0);
  if not InRange(LPort, 1, 65535) then
    raise Exception.Create(OwmText('settings.validation.port', 'API port must be in range 1..65535'));

  if chkEnableApi.Checked then
  begin
    if (rgApiAuthType.ItemIndex = 0) and (Trim(edtApiKey.Text) = '') then
      raise Exception.Create(OwmText('settings.validation.api_key', 'API key is required for Header auth'));

    if (rgApiAuthType.ItemIndex = 1) and
       ((Trim(edtApiLogin.Text) = '') or (edtApiPassword.Text = '')) then
      raise Exception.Create(OwmText('settings.validation.basic',
        'Basic login and password are required for Basic auth'));
  end;

  if chkEnhancedApi.Checked then
  begin
    if Trim(cbPdbName.Text) = '' then
      raise Exception.Create(OwmText('settings.validation.pdb',
        'PDB name is required when Enhanced API is enabled'));
    if Trim(edtAclAdminUser.Text) = '' then
      raise Exception.Create(OwmText('settings.validation.acl_user',
        'ACL admin user is required when Enhanced API is enabled'));
    if Trim(edtAclAdminPassword.Text) = '' then
      raise Exception.Create(OwmText('settings.validation.acl_password',
        'ACL admin password is required when Enhanced API is enabled'));
    if Trim(edtTns.Text) = '' then
      raise Exception.Create(OwmText('settings.validation.tns_file',
        'Path to tnsnames.ora is required when Enhanced API is enabled'));
    if not FileExists(Trim(edtTns.Text)) then
      raise Exception.Create(OwmTextFmt('settings.validation.tns_file_not_found',
        'TNS file was not found: %s', [Trim(edtTns.Text)]));
  end;

  FSettings.Language := cbLanguage.Text;

  FSettings.ApiEnabled := chkEnableApi.Checked;
  FSettings.ApiPort := LPort;
  if rgApiAuthType.ItemIndex = 1 then
    FSettings.ApiAuthType := aatBasic
  else
    FSettings.ApiAuthType := aatHeader;

  FSettings.ApiKeyEnc := EncryptString(Trim(edtApiKey.Text));
  FSettings.ApiBasicLoginEnc := EncryptString(Trim(edtApiLogin.Text));
  FSettings.ApiBasicPasswordEnc := EncryptString(edtApiPassword.Text);

  if rgAllowedHosts.ItemIndex = 1 then
    FSettings.AllowedHostsMode := ahmList
  else
    FSettings.AllowedHostsMode := ahmAll;

  LIpLines := TStringList.Create;
  try
    for LLine in memAllowedIps.Lines do
    begin
      LCleanLine := Trim(LLine);
      if (LCleanLine = '') or StartsText('#', LCleanLine) then
        Continue;
      LIpLines.Add(LCleanLine);
    end;
    SetLength(FSettings.AllowedIps, LIpLines.Count);
    for I := 0 to LIpLines.Count - 1 do
      FSettings.AllowedIps[I] := LIpLines[I];
  finally
    LIpLines.Free;
  end;

  FSettings.EnhancedApiEnabled := chkEnhancedApi.Checked;
  FSettings.PdbName := Trim(cbPdbName.Text);
  FSettings.AclAdminUser := Trim(edtAclAdminUser.Text);
  FSettings.AclAdminPasswordEnc := EncryptString(edtAclAdminPassword.Text);
  FSettings.Tns := Trim(edtTns.Text);
end;

procedure TSettingsForm.UpdateUiState;
begin
  pnlAuthHeader.Enabled := rgApiAuthType.ItemIndex = 0;
  pnlAuthBasic.Enabled := rgApiAuthType.ItemIndex = 1;
  pnlHostsList.Enabled := rgAllowedHosts.ItemIndex = 1;
  pnlEnhancedApi.Enabled := chkEnhancedApi.Checked;
end;

function TSettingsForm.GenerateApiKey: string;
var
  LBytes: TBytes;
  I: Integer;
begin
  SetLength(LBytes, 32);
  for I := 0 to High(LBytes) do
    LBytes[I] := Byte(Random(256));
  Result := TNetEncoding.Base64.EncodeBytesToString(LBytes);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

procedure TSettingsForm.rgApiAuthTypeClick(Sender: TObject);
begin
  UpdateUiState;
end;

procedure TSettingsForm.rgAllowedHostsClick(Sender: TObject);
begin
  UpdateUiState;
end;

procedure TSettingsForm.chkEnhancedApiClick(Sender: TObject);
begin
  UpdateUiState;
end;

procedure TSettingsForm.btnGenApiKeyClick(Sender: TObject);
begin
  edtApiKey.Text := GenerateApiKey;
end;

procedure TSettingsForm.btnBrowseTnsClick(Sender: TObject);
var
  LPreferredPdb: string;
begin
  if Trim(edtTns.Text) <> '' then
    dlgOpenTns.FileName := edtTns.Text;

  if not dlgOpenTns.Execute then
    Exit;

  edtTns.Text := dlgOpenTns.FileName;
  LPreferredPdb := cbPdbName.Text;
  LoadPdbFromTns(edtTns.Text, LPreferredPdb);
end;

procedure TSettingsForm.btnSaveClick(Sender: TObject);
begin
  try
    SaveToSettings;
    ModalResult := mrOk;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TSettingsForm.cbLanguageChange(Sender: TObject);
begin
  OwmSetLanguage(cbLanguage.Text);
  ApplyLanguage;
  UpdateUiState;
end;

end.

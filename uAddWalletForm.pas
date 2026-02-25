unit uAddWalletForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.UITypes,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls;

type
  TOwmNewWalletOptions = record
    WalletPath: string;
    Password: string;
    AutoLogin: Boolean;
    AutoLoginLocal: Boolean;
  end;

  TWalletPathState = (wpsEmpty, wpsOk, wpsInvalid, wpsWalletExists);

  TAddWalletForm = class(TForm)
    pnlClient: TPanel;
    gbWallet: TGroupBox;
    pnlPath: TPanel;
    lblPath: TLabel;
    edtWalletPath: TEdit;
    btnBrowsePath: TButton;
    pnlPassword: TPanel;
    lblPassword: TLabel;
    edtPassword: TEdit;
    pnlFlags: TPanel;
    chkAutoLogin: TCheckBox;
    chkAutoLoginLocal: TCheckBox;
    pnlPathStatus: TPanel;
    lblPathStatus: TLabel;
    pnlBottom: TPanel;
    btnCancel: TButton;
    btnCreate: TButton;
    procedure FormShow(Sender: TObject);
    procedure btnBrowsePathClick(Sender: TObject);
    procedure btnCreateClick(Sender: TObject);
    procedure chkAutoLoginClick(Sender: TObject);
    procedure chkAutoLoginLocalClick(Sender: TObject);
    procedure edtWalletPathChange(Sender: TObject);
    procedure edtPasswordChange(Sender: TObject);
  private
    FResult: TOwmNewWalletOptions;
    FPathState: TWalletPathState;
    procedure ApplyLanguage;
    procedure ValidateForm;
    function EvaluateWalletPath(const APath: string; out ANormalizedPath: string): TWalletPathState;
    procedure UpdatePathStatus;
    procedure UpdateCreateButtonState;
  public
    class function Execute(out AOptions: TOwmNewWalletOptions): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  System.StrUtils,
  Vcl.FileCtrl,
  uOwmI18n;

class function TAddWalletForm.Execute(out AOptions: TOwmNewWalletOptions): Boolean;
var
  LForm: TAddWalletForm;
begin
  FillChar(AOptions, SizeOf(AOptions), 0);
  LForm := TAddWalletForm.Create(nil);
  try
    LForm.ApplyLanguage;
    Result := LForm.ShowModal = mrOk;
    if Result then
      AOptions := LForm.FResult;
  finally
    LForm.Free;
  end;
end;

procedure TAddWalletForm.ApplyLanguage;
begin
  Caption := OwmText('addwallet.caption',
    'Create New Wallet (existing wallet: Wallet Configuration -> Configure)');
  gbWallet.Caption := OwmText('addwallet.group', 'Wallet Creation');
  lblPath.Caption := OwmText('addwallet.path', 'Wallet folder path');
  lblPassword.Caption := OwmText('addwallet.password', 'Wallet password');
  chkAutoLogin.Caption := OwmText('addwallet.autologin', 'Enable auto-login (cwallet.sso)');
  chkAutoLoginLocal.Caption := OwmText('addwallet.autologin_local',
    'Enable local auto-login only');
  btnBrowsePath.Caption := OwmText('btn.browse', 'Browse...');
  btnCreate.Caption := OwmText('addwallet.create', 'Create and Switch');
  btnCancel.Caption := OwmText('btn.cancel', 'Cancel');
end;

procedure TAddWalletForm.FormShow(Sender: TObject);
begin
  UpdatePathStatus;
  UpdateCreateButtonState;
end;

function TAddWalletForm.EvaluateWalletPath(const APath: string;
  out ANormalizedPath: string): TWalletPathState;
var
  LDrive: string;
  LEwalletPath: string;
  LCwalletPath: string;
begin
  Result := wpsEmpty;
  ANormalizedPath := '';

  if Trim(APath) = '' then
    Exit;

  try
    ANormalizedPath := ExcludeTrailingPathDelimiter(TPath.GetFullPath(Trim(APath)));
  except
    on Exception do
      Exit(wpsInvalid);
  end;

  if (ANormalizedPath = '') or SameText(ANormalizedPath, '\') then
    Exit(wpsInvalid);

  if TFile.Exists(ANormalizedPath) then
    Exit(wpsInvalid);

  if not StartsText('\\', ANormalizedPath) then
  begin
    LDrive := ExtractFileDrive(ANormalizedPath);
    if (LDrive <> '') and (not System.SysUtils.DirectoryExists(
      IncludeTrailingPathDelimiter(LDrive))) then
      Exit(wpsInvalid);
  end;

  LEwalletPath := TPath.Combine(ANormalizedPath, 'ewallet.p12');
  LCwalletPath := TPath.Combine(ANormalizedPath, 'cwallet.sso');
  if FileExists(LEwalletPath) or FileExists(LCwalletPath) then
    Exit(wpsWalletExists);

  Result := wpsOk;
end;

procedure TAddWalletForm.UpdatePathStatus;
var
  LPath: string;
begin
  FPathState := EvaluateWalletPath(edtWalletPath.Text, LPath);
  case FPathState of
    wpsInvalid:
      begin
        lblPathStatus.Caption := OwmText('addwallet.path_invalid', 'Invalid path!');
        lblPathStatus.Font.Color := clRed;
        lblPathStatus.Visible := True;
      end;
    wpsWalletExists:
      begin
        lblPathStatus.Caption := OwmText('addwallet.path_wallet_exists',
          'Wallet already exists in this folder. Cannot create another one here.');
        lblPathStatus.Font.Color := clYellow;
        lblPathStatus.Visible := True;
      end;
  else
    begin
      lblPathStatus.Caption := '';
      lblPathStatus.Visible := False;
    end;
  end;
end;

procedure TAddWalletForm.UpdateCreateButtonState;
begin
  btnCreate.Enabled := (FPathState = wpsOk) and (Trim(edtPassword.Text) <> '');
end;

procedure TAddWalletForm.ValidateForm;
begin
  UpdatePathStatus;
  if FPathState = wpsInvalid then
    raise Exception.Create(OwmText('addwallet.path_invalid', 'Invalid path!'));
  if FPathState = wpsWalletExists then
    raise Exception.Create(OwmText('addwallet.path_wallet_exists',
      'Wallet already exists in this folder. Cannot create another one here.'));
  if Trim(edtWalletPath.Text) = '' then
    raise Exception.Create(OwmText('addwallet.validation.path', 'Wallet path is required'));
  if Trim(edtPassword.Text) = '' then
    raise Exception.Create(OwmText('addwallet.validation.password', 'Wallet password is required'));
end;

procedure TAddWalletForm.btnBrowsePathClick(Sender: TObject);
var
  LDir: string;
begin
  LDir := Trim(edtWalletPath.Text);
  if LDir = '' then
    LDir := TPath.GetDirectoryName(ParamStr(0));

  if SelectDirectory(OwmText('addwallet.select_folder', 'Select wallet folder'), '', LDir) then
    edtWalletPath.Text := LDir;

  UpdatePathStatus;
  UpdateCreateButtonState;
end;

procedure TAddWalletForm.edtWalletPathChange(Sender: TObject);
begin
  UpdatePathStatus;
  UpdateCreateButtonState;
end;

procedure TAddWalletForm.edtPasswordChange(Sender: TObject);
begin
  UpdateCreateButtonState;
end;

procedure TAddWalletForm.chkAutoLoginClick(Sender: TObject);
begin
  if chkAutoLogin.Checked then
    chkAutoLoginLocal.Checked := False;
end;

procedure TAddWalletForm.chkAutoLoginLocalClick(Sender: TObject);
begin
  if chkAutoLoginLocal.Checked then
    chkAutoLogin.Checked := False;
end;

procedure TAddWalletForm.btnCreateClick(Sender: TObject);
begin
  try
    ValidateForm;

    FResult.WalletPath := ExcludeTrailingPathDelimiter(TPath.GetFullPath(Trim(edtWalletPath.Text)));
    FResult.Password := edtPassword.Text;
    FResult.AutoLogin := chkAutoLogin.Checked;
    FResult.AutoLoginLocal := chkAutoLoginLocal.Checked;

    ModalResult := mrOk;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

end.

unit uWalletConfigForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  uOwmSettings;

type
  TWalletConfigForm = class(TForm)
    pnlClient: TPanel;
    gbWallet: TGroupBox;
    pnlWalletPath: TPanel;
    lblWalletPath: TLabel;
    edtWalletPath: TEdit;
    btnBrowseWalletPath: TButton;
    pnlWalletPassword: TPanel;
    lblWalletPassword: TLabel;
    edtWalletPassword: TEdit;
    pnlWarning: TPanel;
    lblWarning: TLabel;
    pnlBottom: TPanel;
    btnCancel: TButton;
    btnSave: TButton;
    procedure btnBrowseWalletPathClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FSettings: TOwmSettings;
    FCanEdit: Boolean;
    procedure ApplyLanguage;
    procedure LoadFromSettings;
    procedure SaveToSettings;
    procedure ApplyCanEdit;
  public
    class function Execute(var ASettings: TOwmSettings; ACanEdit: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  Vcl.FileCtrl,
  uOwmCrypto,
  uOwmI18n;

class function TWalletConfigForm.Execute(var ASettings: TOwmSettings;
  ACanEdit: Boolean): Boolean;
var
  LForm: TWalletConfigForm;
begin
  LForm := TWalletConfigForm.Create(nil);
  try
    LForm.FSettings := TOwmSettings.Create;
    LForm.FSettings.Assign(ASettings);
    LForm.FCanEdit := ACanEdit;
    LForm.LoadFromSettings;
    LForm.ApplyLanguage;
    LForm.ApplyCanEdit;

    Result := LForm.ShowModal = mrOk;
    if Result then
    begin
      LForm.SaveToSettings;
      ASettings.Assign(LForm.FSettings);
    end;
  finally
    LForm.FSettings.Free;
    LForm.Free;
  end;
end;

procedure TWalletConfigForm.LoadFromSettings;
begin
  edtWalletPath.Text := FSettings.WalletPath;
  edtWalletPassword.Text := DecryptString(FSettings.WalletPasswordEnc);
end;

procedure TWalletConfigForm.ApplyLanguage;
begin
  Caption := OwmText('walletcfg.caption', 'Wallet Configuration');
  gbWallet.Caption := OwmText('walletcfg.group.access', 'Wallet Access');
  lblWalletPath.Caption := OwmText('walletcfg.wallet_path', 'Wallet folder path');
  lblWalletPassword.Caption := OwmText('walletcfg.wallet_password', 'Wallet password');
  btnBrowseWalletPath.Caption := OwmText('btn.browse', 'Browse...');
  btnSave.Caption := OwmText('btn.save', 'Save');
  btnCancel.Caption := OwmText('btn.cancel', 'Cancel');
end;

procedure TWalletConfigForm.SaveToSettings;
begin
  if Trim(edtWalletPath.Text) = '' then
    raise Exception.Create(OwmText('walletcfg.validation.path', 'Wallet path is required'));

  FSettings.WalletPath := Trim(edtWalletPath.Text);
  FSettings.WalletPasswordEnc := EncryptString(edtWalletPassword.Text);
end;

procedure TWalletConfigForm.ApplyCanEdit;
begin
  edtWalletPath.Enabled := FCanEdit;
  edtWalletPassword.Enabled := FCanEdit;
  btnBrowseWalletPath.Enabled := FCanEdit;
  btnSave.Enabled := FCanEdit;

  lblWarning.Visible := not FCanEdit;
  if not FCanEdit then
    lblWarning.Caption := OwmText('walletcfg.warning.orapki',
      'orapki.exe was not found. Wallet operations are disabled.');
end;

procedure TWalletConfigForm.btnBrowseWalletPathClick(Sender: TObject);
var
  LDir: string;
begin
  LDir := Trim(edtWalletPath.Text);
  if LDir = '' then
    LDir := TPath.GetDirectoryName(ParamStr(0));

  if SelectDirectory(OwmText('walletcfg.select_folder', 'Select wallet folder'), '', LDir) then
    edtWalletPath.Text := LDir;
end;

procedure TWalletConfigForm.btnSaveClick(Sender: TObject);
begin
  try
    SaveToSettings;
    ModalResult := mrOk;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

end.

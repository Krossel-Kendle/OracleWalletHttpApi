unit uAboutForm;

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
  Vcl.StdCtrls;

type
  TAboutForm = class(TForm)
    pnlClient: TPanel;
    gbInfo: TGroupBox;
    pnlBottom: TPanel;
    btnClose: TButton;
    lblAuthor: TLabel;
    lblWebsiteCaption: TLabel;
    lblWebsite: TLabel;
    lblDescription: TLabel;
    procedure lblWebsiteClick(Sender: TObject);
    procedure lblWebsiteMouseEnter(Sender: TObject);
    procedure lblWebsiteMouseLeave(Sender: TObject);
  private
    procedure ApplyLanguage;
  public
    class procedure Execute(AOwner: TComponent);
  end;

implementation

{$R *.dfm}

uses
  Winapi.ShellAPI,
  uOwmI18n;

class procedure TAboutForm.Execute(AOwner: TComponent);
var
  LForm: TAboutForm;
begin
  LForm := TAboutForm.Create(AOwner);
  try
    LForm.ApplyLanguage;
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

procedure TAboutForm.ApplyLanguage;
begin
  Caption := OwmText('about.caption', 'About');
  gbInfo.Caption := OwmText('about.group.caption', 'Oracle Wallet Certificate Manager');
  lblAuthor.Caption := OwmText('about.author', 'Author: Vladislav Filimonov, Krossel Apps');
  lblWebsiteCaption.Caption := OwmText('about.website_caption', 'Website:');
  lblDescription.Caption := OwmText('about.description',
    'VCL utility for Oracle Wallet certificate lifecycle: list, add, remove, folder import, summary of upcoming expirations, and optional local API for remote operations.');
  btnClose.Caption := OwmText('btn.close', 'Close');
end;

procedure TAboutForm.lblWebsiteClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar('https://kapps.at'), nil, nil, SW_SHOWNORMAL);
end;

procedure TAboutForm.lblWebsiteMouseEnter(Sender: TObject);
begin
  lblWebsite.Font.Color := clNavy;
end;

procedure TAboutForm.lblWebsiteMouseLeave(Sender: TObject);
begin
  lblWebsite.Font.Color := clBlue;
end;

end.

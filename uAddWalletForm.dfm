object AddWalletForm: TAddWalletForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Add Wallet'
  ClientHeight = 292
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 15
  object pnlClient: TPanel
    AlignWithMargins = True
    Left = 8
    Top = 8
    Width = 744
    Height = 246
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object gbWallet: TGroupBox
      Left = 0
      Top = 0
      Width = 744
      Height = 246
      Align = alClient
      Caption = 'New Wallet'
      TabOrder = 0
      object pnlFlags: TPanel
        Left = 2
        Top = 123
        Width = 740
        Height = 121
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 3
        object chkAutoLoginLocal: TCheckBox
          AlignWithMargins = True
          Left = 8
          Top = 36
          Width = 724
          Height = 20
          Margins.Left = 8
          Margins.Top = 10
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Caption = 'Enable local auto-login only'
          TabOrder = 1
          OnClick = chkAutoLoginLocalClick
        end
        object chkAutoLogin: TCheckBox
          AlignWithMargins = True
          Left = 8
          Top = 6
          Width = 724
          Height = 20
          Margins.Left = 8
          Margins.Top = 6
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Caption = 'Enable auto-login (cwallet.sso)'
          TabOrder = 0
          OnClick = chkAutoLoginClick
        end
      end
      object pnlPathStatus: TPanel
        Left = 2
        Top = 95
        Width = 740
        Height = 28
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 2
        object lblPathStatus: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 8
          Width = 724
          Height = 15
          Margins.Left = 8
          Margins.Top = 8
          Margins.Right = 8
          Margins.Bottom = 5
          Align = alClient
          Caption = 'Invalid path!'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Visible = False
          ExplicitWidth = 66
          ExplicitHeight = 15
        end
      end
      object pnlPassword: TPanel
        Left = 2
        Top = 57
        Width = 740
        Height = 38
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object lblPassword: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 11
          Width = 95
          Height = 18
          Margins.Left = 8
          Margins.Top = 11
          Margins.Right = 0
          Margins.Bottom = 9
          Align = alLeft
          Caption = 'Wallet password'
          ExplicitHeight = 15
        end
        object edtPassword: TEdit
          AlignWithMargins = True
          Left = 111
          Top = 8
          Width = 621
          Height = 21
          Margins.Left = 8
          Margins.Top = 8
          Margins.Right = 8
          Margins.Bottom = 9
          Align = alClient
          PasswordChar = '*'
          TabOrder = 0
          OnChange = edtPasswordChange
        end
      end
      object pnlPath: TPanel
        Left = 2
        Top = 17
        Width = 740
        Height = 40
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btnBrowsePath: TButton
          AlignWithMargins = True
          Left = 647
          Top = 6
          Width = 85
          Height = 28
          Margins.Left = 8
          Margins.Top = 6
          Margins.Right = 8
          Margins.Bottom = 6
          Align = alRight
          Caption = 'Browse...'
          TabOrder = 1
          OnClick = btnBrowsePathClick
        end
        object edtWalletPath: TEdit
          AlignWithMargins = True
          Left = 111
          Top = 9
          Width = 528
          Height = 21
          Margins.Left = 8
          Margins.Top = 9
          Margins.Right = 0
          Margins.Bottom = 10
          Align = alClient
          TabOrder = 0
          OnChange = edtWalletPathChange
        end
        object lblPath: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 12
          Width = 95
          Height = 18
          Margins.Left = 8
          Margins.Top = 12
          Margins.Right = 0
          Margins.Bottom = 10
          Align = alLeft
          Caption = 'Wallet folder path'
          ExplicitHeight = 15
        end
      end
    end
  end
  object pnlBottom: TPanel
    AlignWithMargins = True
    Left = 8
    Top = 262
    Width = 744
    Height = 22
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCancel: TButton
      AlignWithMargins = True
      Left = 656
      Top = 0
      Width = 85
      Height = 22
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 3
      Margins.Bottom = 0
      Align = alRight
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object btnCreate: TButton
      AlignWithMargins = True
      Left = 529
      Top = 0
      Width = 119
      Height = 22
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alRight
      Caption = 'Create and Switch'
      Default = True
      TabOrder = 0
      OnClick = btnCreateClick
    end
  end
end

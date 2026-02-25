object WalletConfigForm: TWalletConfigForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Wallet Configuration'
  ClientHeight = 220
  ClientWidth = 680
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object pnlClient: TPanel
    AlignWithMargins = True
    Left = 8
    Top = 8
    Width = 664
    Height = 170
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object gbWallet: TGroupBox
      Left = 0
      Top = 0
      Width = 664
      Height = 170
      Align = alClient
      Caption = 'Wallet Access'
      TabOrder = 0
      object pnlWarning: TPanel
        Left = 2
        Top = 136
        Width = 660
        Height = 32
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 2
        object lblWarning: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 8
          Width = 644
          Height = 15
          Margins.Left = 8
          Margins.Top = 8
          Margins.Right = 8
          Margins.Bottom = 8
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          WordWrap = True
          ExplicitWidth = 4
          ExplicitHeight = 15
        end
      end
      object pnlWalletPassword: TPanel
        Left = 2
        Top = 89
        Width = 660
        Height = 47
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblWalletPassword: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 16
          Width = 95
          Height = 15
          Margins.Left = 8
          Margins.Top = 16
          Margins.Right = 0
          Margins.Bottom = 16
          Align = alLeft
          Caption = 'Wallet password'
          ExplicitHeight = 15
        end
        object edtWalletPassword: TEdit
          AlignWithMargins = True
          Left = 111
          Top = 13
          Width = 541
          Height = 21
          Margins.Left = 8
          Margins.Top = 13
          Margins.Right = 8
          Margins.Bottom = 13
          Align = alClient
          PasswordChar = '*'
          TabOrder = 0
        end
      end
      object pnlWalletPath: TPanel
        Left = 2
        Top = 17
        Width = 660
        Height = 72
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btnBrowseWalletPath: TButton
          AlignWithMargins = True
          Left = 567
          Top = 25
          Width = 85
          Height = 28
          Margins.Left = 8
          Margins.Top = 25
          Margins.Right = 8
          Margins.Bottom = 19
          Align = alRight
          Caption = 'Browse...'
          TabOrder = 1
          OnClick = btnBrowseWalletPathClick
        end
        object edtWalletPath: TEdit
          AlignWithMargins = True
          Left = 111
          Top = 25
          Width = 448
          Height = 21
          Margins.Left = 8
          Margins.Top = 25
          Margins.Right = 0
          Margins.Bottom = 26
          Align = alClient
          TabOrder = 0
        end
        object lblWalletPath: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 28
          Width = 95
          Height = 15
          Margins.Left = 8
          Margins.Top = 28
          Margins.Right = 0
          Margins.Bottom = 29
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
    Top = 186
    Width = 664
    Height = 26
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCancel: TButton
      AlignWithMargins = True
      Left = 576
      Top = 0
      Width = 85
      Height = 26
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
    object btnSave: TButton
      AlignWithMargins = True
      Left = 483
      Top = 0
      Width = 85
      Height = 26
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alRight
      Caption = 'Save'
      Default = True
      TabOrder = 0
      OnClick = btnSaveClick
    end
  end
end

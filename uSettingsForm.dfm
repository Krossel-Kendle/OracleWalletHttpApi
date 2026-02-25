object SettingsForm: TSettingsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 655
  ClientWidth = 740
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlClient: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 734
    Height = 607
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitLeft = 8
    ExplicitTop = 8
    ExplicitWidth = 724
    ExplicitHeight = 595
    object gbApi: TGroupBox
      AlignWithMargins = True
      Left = 0
      Top = 70
      Width = 734
      Height = 537
      Margins.Left = 0
      Margins.Top = 6
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alClient
      Caption = 'API'
      TabOrder = 1
      ExplicitWidth = 724
      ExplicitHeight = 525
      object sbApi: TScrollBox
        Left = 2
        Top = 17
        Width = 730
        Height = 518
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        ExplicitWidth = 720
        ExplicitHeight = 506
        object pnlEnableApi: TPanel
          Left = 0
          Top = 0
          Width = 713
          Height = 34
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          ExplicitWidth = 720
          object chkEnableApi: TCheckBox
            AlignWithMargins = True
            Left = 8
            Top = 8
            Width = 704
            Height = 17
            Margins.Left = 8
            Margins.Top = 8
            Margins.Right = 8
            Margins.Bottom = 8
            Align = alClient
            Caption = 'Enable API'
            TabOrder = 0
          end
        end
        object rgApiAuthType: TRadioGroup
          AlignWithMargins = True
          Left = 8
          Top = 37
          Width = 697
          Height = 56
          Margins.Left = 8
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Caption = 'Auth type'
          Columns = 2
          TabOrder = 1
          OnClick = rgApiAuthTypeClick
          ExplicitWidth = 704
        end
        object pnlAuthHeader: TPanel
          Left = 0
          Top = 93
          Width = 713
          Height = 38
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 2
          ExplicitWidth = 720
          object lblApiKey: TLabel
            AlignWithMargins = True
            Left = 8
            Top = 11
            Width = 54
            Height = 15
            Margins.Left = 8
            Margins.Top = 11
            Margins.Right = 0
            Margins.Bottom = 8
            Align = alLeft
            Caption = 'X-API-Key'
          end
          object btnGenApiKey: TButton
            AlignWithMargins = True
            Left = 607
            Top = 8
            Width = 105
            Height = 22
            Margins.Left = 8
            Margins.Top = 8
            Margins.Right = 8
            Margins.Bottom = 8
            Align = alRight
            Caption = 'Generate'
            TabOrder = 0
            OnClick = btnGenApiKeyClick
          end
          object edtApiKey: TEdit
            AlignWithMargins = True
            Left = 125
            Top = 8
            Width = 474
            Height = 22
            Margins.Left = 8
            Margins.Top = 8
            Margins.Right = 0
            Margins.Bottom = 8
            Align = alClient
            ReadOnly = True
            TabOrder = 1
          end
        end
        object pnlAuthBasic: TPanel
          Left = 0
          Top = 131
          Width = 713
          Height = 69
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 3
          ExplicitWidth = 720
          object pnlBasicPassword: TPanel
            Left = 0
            Top = 34
            Width = 720
            Height = 35
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 1
            object lblBasicPassword: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 11
              Width = 80
              Height = 15
              Margins.Left = 8
              Margins.Top = 11
              Margins.Right = 0
              Margins.Bottom = 8
              Align = alLeft
              Caption = 'Basic password'
            end
            object edtApiPassword: TEdit
              AlignWithMargins = True
              Left = 125
              Top = 8
              Width = 587
              Height = 22
              Margins.Left = 8
              Margins.Top = 8
              Margins.Right = 8
              Margins.Bottom = 5
              Align = alClient
              PasswordChar = '*'
              TabOrder = 0
            end
          end
          object pnlBasicLogin: TPanel
            Left = 0
            Top = 0
            Width = 720
            Height = 34
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 0
            object lblBasicLogin: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 11
              Width = 57
              Height = 15
              Margins.Left = 8
              Margins.Top = 11
              Margins.Right = 0
              Margins.Bottom = 8
              Align = alLeft
              Caption = 'Basic login'
            end
            object edtApiLogin: TEdit
              AlignWithMargins = True
              Left = 125
              Top = 8
              Width = 587
              Height = 21
              Margins.Left = 8
              Margins.Top = 8
              Margins.Right = 8
              Margins.Bottom = 5
              Align = alClient
              TabOrder = 0
            end
          end
        end
        object pnlApiPort: TPanel
          Left = 0
          Top = 200
          Width = 713
          Height = 34
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 4
          ExplicitWidth = 720
          object lblApiPort: TLabel
            AlignWithMargins = True
            Left = 8
            Top = 11
            Width = 43
            Height = 15
            Margins.Left = 8
            Margins.Top = 11
            Margins.Right = 0
            Margins.Bottom = 8
            Align = alLeft
            Caption = 'API port'
          end
          object edtApiPort: TEdit
            AlignWithMargins = True
            Left = 125
            Top = 8
            Width = 587
            Height = 21
            Margins.Left = 8
            Margins.Top = 8
            Margins.Right = 8
            Margins.Bottom = 5
            Align = alClient
            NumbersOnly = True
            TabOrder = 0
            Text = '8089'
          end
        end
        object rgAllowedHosts: TRadioGroup
          AlignWithMargins = True
          Left = 8
          Top = 237
          Width = 697
          Height = 56
          Margins.Left = 8
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          Caption = 'Allowed hosts'
          Columns = 2
          TabOrder = 5
          OnClick = rgAllowedHostsClick
          ExplicitWidth = 704
        end
        object pnlHostsList: TPanel
          Left = 0
          Top = 293
          Width = 713
          Height = 96
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 6
          ExplicitWidth = 720
          object memAllowedIps: TMemo
            AlignWithMargins = True
            Left = 8
            Top = 0
            Width = 697
            Height = 96
            Margins.Left = 8
            Margins.Top = 0
            Margins.Right = 8
            Margins.Bottom = 0
            Align = alClient
            Lines.Strings = (
              '# one IP per line')
            ScrollBars = ssVertical
            TabOrder = 0
          end
        end
        object pnlEnhancedSwitch: TPanel
          Left = 0
          Top = 389
          Width = 713
          Height = 34
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 7
          ExplicitWidth = 720
          object chkEnhancedApi: TCheckBox
            AlignWithMargins = True
            Left = 8
            Top = 8
            Width = 704
            Height = 17
            Margins.Left = 8
            Margins.Top = 8
            Margins.Right = 8
            Margins.Bottom = 8
            Align = alClient
            Caption = 'Enhanced API (ACL via SQL*Plus)'
            TabOrder = 0
            OnClick = chkEnhancedApiClick
          end
        end
        object pnlEnhancedApi: TPanel
          Left = 0
          Top = 423
          Width = 713
          Height = 181
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 8
          ExplicitWidth = 720
          object pnlTnsHint: TPanel
            Left = 0
            Top = 140
            Width = 720
            Height = 32
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 4
            object lblTnsHint: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 6
              Width = 338
              Height = 15
              Margins.Left = 8
              Margins.Top = 6
              Margins.Right = 8
              Margins.Bottom = 6
              Align = alClient
              Caption = 'If TNS is empty, app will try to resolve tnsnames.ora on demand.'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGrayText
              Font.Height = -12
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
              WordWrap = True
            end
          end
          object pnlTns: TPanel
            Left = 0
            Top = 105
            Width = 720
            Height = 35
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 3
            object lblTns: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 11
              Width = 21
              Height = 15
              Margins.Left = 8
              Margins.Top = 11
              Margins.Right = 0
              Margins.Bottom = 8
              Align = alLeft
              Caption = 'TNS'
            end
            object btnBrowseTns: TButton
              AlignWithMargins = True
              Left = 672
              Top = 8
              Width = 40
              Height = 22
              Margins.Left = 8
              Margins.Top = 8
              Margins.Right = 8
              Margins.Bottom = 5
              Align = alRight
              Caption = '...'
              TabOrder = 0
              OnClick = btnBrowseTnsClick
            end
            object edtTns: TEdit
              AlignWithMargins = True
              Left = 125
              Top = 8
              Width = 547
              Height = 21
              Margins.Left = 8
              Margins.Top = 8
              Margins.Right = 0
              Margins.Bottom = 5
              Align = alClient
              ReadOnly = True
              TabOrder = 1
            end
          end
          object pnlAclPassword: TPanel
            Left = 0
            Top = 70
            Width = 720
            Height = 35
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 2
            object lblAclAdminPassword: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 11
              Width = 75
              Height = 15
              Margins.Left = 8
              Margins.Top = 11
              Margins.Right = 0
              Margins.Bottom = 8
              Align = alLeft
              Caption = 'ACL password'
            end
            object edtAclAdminPassword: TEdit
              AlignWithMargins = True
              Left = 125
              Top = 8
              Width = 587
              Height = 22
              Margins.Left = 8
              Margins.Top = 8
              Margins.Right = 8
              Margins.Bottom = 5
              Align = alClient
              PasswordChar = '*'
              TabOrder = 0
            end
          end
          object pnlAclUser: TPanel
            Left = 0
            Top = 35
            Width = 720
            Height = 35
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 1
            object lblAclAdminUser: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 11
              Width = 84
              Height = 15
              Margins.Left = 8
              Margins.Top = 11
              Margins.Right = 0
              Margins.Bottom = 8
              Align = alLeft
              Caption = 'ACL admin user'
            end
            object edtAclAdminUser: TEdit
              AlignWithMargins = True
              Left = 125
              Top = 8
              Width = 587
              Height = 21
              Margins.Left = 8
              Margins.Top = 8
              Margins.Right = 8
              Margins.Bottom = 5
              Align = alClient
              TabOrder = 0
            end
          end
          object pnlPdbName: TPanel
            Left = 0
            Top = 0
            Width = 720
            Height = 35
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 0
            object lblPdbName: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 11
              Width = 55
              Height = 15
              Margins.Left = 8
              Margins.Top = 11
              Margins.Right = 0
              Margins.Bottom = 8
              Align = alLeft
              Caption = 'PDB name'
            end
            object cbPdbName: TComboBox
              AlignWithMargins = True
              Left = 125
              Top = 8
              Width = 587
              Height = 23
              Margins.Left = 8
              Margins.Top = 8
              Margins.Right = 8
              Margins.Bottom = 5
              Align = alClient
              Style = csDropDownList
              TabOrder = 0
            end
          end
        end
      end
    end
    object gbLanguage: TGroupBox
      AlignWithMargins = True
      Left = 0
      Top = 0
      Width = 734
      Height = 64
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Language'
      TabOrder = 0
      ExplicitWidth = 724
      object pnlLanguageRow: TPanel
        Left = 2
        Top = 17
        Width = 720
        Height = 45
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        object lblLanguage: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 13
          Width = 63
          Height = 15
          Margins.Left = 8
          Margins.Top = 13
          Margins.Right = 0
          Margins.Bottom = 12
          Align = alLeft
          Caption = 'UI language'
        end
        object cbLanguage: TComboBox
          AlignWithMargins = True
          Left = 115
          Top = 10
          Width = 598
          Height = 23
          Margins.Left = 8
          Margins.Top = 10
          Margins.Right = 8
          Margins.Bottom = 12
          Align = alClient
          Style = csDropDownList
          TabOrder = 0
        end
      end
    end
  end
  object pnlBottom: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 616
    Width = 734
    Height = 36
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitLeft = 8
    ExplicitTop = 611
    ExplicitWidth = 724
    object btnCancel: TButton
      AlignWithMargins = True
      Left = 634
      Top = 3
      Width = 87
      Height = 30
      Align = alRight
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object btnSave: TButton
      AlignWithMargins = True
      Left = 541
      Top = 3
      Width = 87
      Height = 30
      Align = alRight
      Caption = 'Save'
      Default = True
      TabOrder = 0
      OnClick = btnSaveClick
    end
  end
  object dlgOpenTns: TOpenDialog
    Left = 504
    Top = 24
  end
end

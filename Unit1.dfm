object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Oracle Wallet HTTP API Manager'
  ClientHeight = 760
  ClientWidth = 1200
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = mmMain
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlClient: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 730
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pcMain: TPageControl
      Left = 0
      Top = 0
      Width = 1200
      Height = 730
      ActivePage = tsGeneral
      Align = alClient
      TabOrder = 0
      object tsGeneral: TTabSheet
        Caption = 'General'
        object pnlGeneralClient: TPanel
          Left = 0
          Top = 0
          Width = 1192
          Height = 700
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 0
          object splMain: TSplitter
            Left = 473
            Top = 0
            Width = 8
            Height = 700
            ResizeStyle = rsUpdate
            ExplicitLeft = 468
          end
          object pnlRight: TPanel
            Left = 481
            Top = 0
            Width = 711
            Height = 700
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object gbDetails: TGroupBox
              AlignWithMargins = True
              Left = 0
              Top = 243
              Width = 711
              Height = 457
              Margins.Left = 0
              Margins.Top = 6
              Margins.Right = 0
              Margins.Bottom = 0
              Align = alClient
              Caption = 'Selected Certificate'
              TabOrder = 1
              object pnlDetailPath: TPanel
                Left = 2
                Top = 169
                Width = 707
                Height = 286
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 4
                object lblPath: TLabel
                  AlignWithMargins = True
                  Left = 8
                  Top = 11
                  Width = 24
                  Height = 267
                  Margins.Left = 8
                  Margins.Top = 11
                  Margins.Right = 0
                  Margins.Bottom = 8
                  Align = alLeft
                  Caption = 'Path'
                  ExplicitHeight = 15
                end
                object edtPath: TEdit
                  AlignWithMargins = True
                  Left = 40
                  Top = 8
                  Width = 659
                  Height = 270
                  Margins.Left = 8
                  Margins.Top = 8
                  Margins.Right = 8
                  Margins.Bottom = 8
                  Align = alClient
                  ReadOnly = True
                  TabOrder = 0
                  ExplicitHeight = 23
                end
              end
              object pnlDetailThumb: TPanel
                Left = 2
                Top = 131
                Width = 707
                Height = 38
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 3
                object lblThumb: TLabel
                  AlignWithMargins = True
                  Left = 8
                  Top = 11
                  Width = 63
                  Height = 18
                  Margins.Left = 8
                  Margins.Top = 11
                  Margins.Right = 0
                  Margins.Bottom = 9
                  Align = alLeft
                  Caption = 'Thumbprint'
                  ExplicitHeight = 15
                end
                object edtThumbprint: TEdit
                  AlignWithMargins = True
                  Left = 79
                  Top = 8
                  Width = 620
                  Height = 21
                  Margins.Left = 8
                  Margins.Top = 8
                  Margins.Right = 8
                  Margins.Bottom = 9
                  Align = alClient
                  ReadOnly = True
                  TabOrder = 0
                  ExplicitHeight = 23
                end
              end
              object pnlDetailNotAfter: TPanel
                Left = 2
                Top = 93
                Width = 707
                Height = 38
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 2
                object lblNotAfter: TLabel
                  AlignWithMargins = True
                  Left = 8
                  Top = 11
                  Width = 46
                  Height = 18
                  Margins.Left = 8
                  Margins.Top = 11
                  Margins.Right = 0
                  Margins.Bottom = 9
                  Align = alLeft
                  Caption = 'NotAfter'
                  ExplicitHeight = 15
                end
                object edtNotAfter: TEdit
                  AlignWithMargins = True
                  Left = 62
                  Top = 8
                  Width = 637
                  Height = 21
                  Margins.Left = 8
                  Margins.Top = 8
                  Margins.Right = 8
                  Margins.Bottom = 9
                  Align = alClient
                  ReadOnly = True
                  TabOrder = 0
                  ExplicitHeight = 23
                end
              end
              object pnlDetailIssuer: TPanel
                Left = 2
                Top = 55
                Width = 707
                Height = 38
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 1
                object lblIssuer: TLabel
                  AlignWithMargins = True
                  Left = 8
                  Top = 11
                  Width = 30
                  Height = 18
                  Margins.Left = 8
                  Margins.Top = 11
                  Margins.Right = 0
                  Margins.Bottom = 9
                  Align = alLeft
                  Caption = 'Issuer'
                  ExplicitHeight = 15
                end
                object edtIssuer: TEdit
                  AlignWithMargins = True
                  Left = 46
                  Top = 8
                  Width = 653
                  Height = 21
                  Margins.Left = 8
                  Margins.Top = 8
                  Margins.Right = 8
                  Margins.Bottom = 9
                  Align = alClient
                  ReadOnly = True
                  TabOrder = 0
                  ExplicitHeight = 23
                end
              end
              object pnlDetailCn: TPanel
                Left = 2
                Top = 17
                Width = 707
                Height = 38
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object lblCn: TLabel
                  AlignWithMargins = True
                  Left = 8
                  Top = 11
                  Width = 17
                  Height = 18
                  Margins.Left = 8
                  Margins.Top = 11
                  Margins.Right = 0
                  Margins.Bottom = 9
                  Align = alLeft
                  Caption = 'CN'
                  ExplicitHeight = 15
                end
                object edtCN: TEdit
                  AlignWithMargins = True
                  Left = 33
                  Top = 8
                  Width = 666
                  Height = 21
                  Margins.Left = 8
                  Margins.Top = 8
                  Margins.Right = 8
                  Margins.Bottom = 9
                  Align = alClient
                  ReadOnly = True
                  TabOrder = 0
                  ExplicitHeight = 23
                end
              end
            end
            object gbSummary: TGroupBox
              Left = 0
              Top = 0
              Width = 711
              Height = 237
              Align = alTop
              Caption = 'Summary'
              TabOrder = 0
              object lblExp5: TLabel
                AlignWithMargins = True
                Left = 12
                Top = 142
                Width = 687
                Height = 15
                Margins.Left = 10
                Margins.Top = 0
                Margins.Right = 10
                Margins.Bottom = 0
                Align = alTop
                Caption = '-'
                ExplicitWidth = 5
              end
              object lblExp4: TLabel
                AlignWithMargins = True
                Left = 12
                Top = 127
                Width = 687
                Height = 15
                Margins.Left = 10
                Margins.Top = 0
                Margins.Right = 10
                Margins.Bottom = 0
                Align = alTop
                Caption = '-'
                ExplicitWidth = 5
              end
              object lblExp3: TLabel
                AlignWithMargins = True
                Left = 12
                Top = 112
                Width = 687
                Height = 15
                Margins.Left = 10
                Margins.Top = 0
                Margins.Right = 10
                Margins.Bottom = 0
                Align = alTop
                Caption = '-'
                ExplicitWidth = 5
              end
              object lblExp2: TLabel
                AlignWithMargins = True
                Left = 12
                Top = 97
                Width = 687
                Height = 15
                Margins.Left = 10
                Margins.Top = 0
                Margins.Right = 10
                Margins.Bottom = 0
                Align = alTop
                Caption = '-'
                ExplicitWidth = 5
              end
              object lblExp1: TLabel
                AlignWithMargins = True
                Left = 12
                Top = 82
                Width = 687
                Height = 15
                Margins.Left = 10
                Margins.Top = 0
                Margins.Right = 10
                Margins.Bottom = 0
                Align = alTop
                Caption = '-'
                ExplicitWidth = 5
              end
              object lblExpSoonCaption: TLabel
                AlignWithMargins = True
                Left = 12
                Top = 67
                Width = 687
                Height = 15
                Margins.Left = 10
                Margins.Top = 6
                Margins.Right = 10
                Margins.Bottom = 0
                Align = alTop
                Caption = 'Expiring soon:'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Height = -12
                Font.Name = 'Segoe UI'
                Font.Style = [fsBold]
                ParentFont = False
                ExplicitWidth = 77
              end
              object lblTotalCertsValue: TLabel
                AlignWithMargins = True
                Left = 12
                Top = 44
                Width = 687
                Height = 17
                Margins.Left = 10
                Margins.Top = 0
                Margins.Right = 10
                Margins.Bottom = 0
                Align = alTop
                Caption = '0'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Height = -13
                Font.Name = 'Segoe UI'
                Font.Style = [fsBold]
                ParentFont = False
                ExplicitWidth = 7
              end
              object lblTotalCertsCaption: TLabel
                AlignWithMargins = True
                Left = 12
                Top = 29
                Width = 687
                Height = 15
                Margins.Left = 10
                Margins.Top = 12
                Margins.Right = 10
                Margins.Bottom = 0
                Align = alTop
                Caption = 'Installed certificates:'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Height = -12
                Font.Name = 'Segoe UI'
                Font.Style = [fsBold]
                ParentFont = False
                ExplicitWidth = 116
              end
            end
          end
          object pnlLeft: TPanel
            Left = 0
            Top = 0
            Width = 473
            Height = 700
            Align = alLeft
            BevelOuter = bvNone
            TabOrder = 1
            object gbWallet: TGroupBox
              Left = 0
              Top = 0
              Width = 473
              Height = 700
              Align = alClient
              Caption = 'Wallet Certificates'
              TabOrder = 0
              object lbCerts: TListBox
                Left = 2
                Top = 17
                Width = 469
                Height = 601
                Align = alClient
                ItemHeight = 15
                TabOrder = 0
                OnClick = lbCertsClick
              end
              object pnlButtons2: TPanel
                Left = 2
                Top = 658
                Width = 469
                Height = 40
                Align = alBottom
                BevelOuter = bvNone
                TabOrder = 2
                object btnRemoveAll: TButton
                  AlignWithMargins = True
                  Left = 171
                  Top = 6
                  Width = 143
                  Height = 31
                  Margins.Left = 8
                  Margins.Top = 6
                  Margins.Right = 8
                  Align = alLeft
                  Caption = 'Remove All'
                  TabOrder = 1
                  OnClick = btnRemoveAllClick
                end
                object btnLoadFromFolder: TButton
                  AlignWithMargins = True
                  Left = 8
                  Top = 6
                  Width = 155
                  Height = 31
                  Margins.Left = 8
                  Margins.Top = 6
                  Margins.Right = 0
                  Align = alLeft
                  Caption = 'Load From Folder'
                  TabOrder = 0
                  OnClick = btnLoadFromFolderClick
                end
              end
              object pnlButtons1: TPanel
                Left = 2
                Top = 618
                Width = 469
                Height = 40
                Align = alBottom
                BevelOuter = bvNone
                TabOrder = 1
                object btnRemove: TButton
                  AlignWithMargins = True
                  Left = 171
                  Top = 6
                  Width = 143
                  Height = 31
                  Margins.Left = 8
                  Margins.Top = 6
                  Margins.Right = 8
                  Align = alLeft
                  Caption = 'Remove'
                  TabOrder = 2
                  OnClick = btnRemoveClick
                end
                object btnAdd: TButton
                  AlignWithMargins = True
                  Left = 8
                  Top = 6
                  Width = 155
                  Height = 31
                  Margins.Left = 8
                  Margins.Top = 6
                  Margins.Right = 0
                  Align = alLeft
                  Caption = 'Add'
                  TabOrder = 1
                  OnClick = btnAddClick
                end
                object btnView: TButton
                  AlignWithMargins = True
                  Left = 322
                  Top = 6
                  Width = 95
                  Height = 31
                  Margins.Left = 0
                  Margins.Top = 6
                  Margins.Right = 8
                  Align = alLeft
                  Caption = 'View'
                  TabOrder = 0
                end
              end
            end
          end
        end
      end
      object tsLog: TTabSheet
        Caption = 'Log'
        ImageIndex = 1
        object memoLog: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 700
          Align = alClient
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 730
    Width = 1200
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object lblStatus: TLabel
      AlignWithMargins = True
      Left = 633
      Top = 8
      Width = 559
      Height = 15
      Margins.Left = 10
      Margins.Top = 8
      Margins.Right = 8
      Margins.Bottom = 7
      Align = alClient
      AutoSize = False
      Caption = 'Ready'
      EllipsisPosition = epEndEllipsis
      ShowAccelChar = False
      ExplicitLeft = 614
      ExplicitWidth = 34
    end
    object lblEnhancedStatus: TLabel
      AlignWithMargins = True
      Left = 507
      Top = 8
      Width = 17
      Height = 15
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'off'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitLeft = 569
    end
    object lblEnhancedCaption: TLabel
      AlignWithMargins = True
      Left = 331
      Top = 8
      Width = 74
      Height = 15
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'Enhanced api:'
      ExplicitLeft = 481
    end
    object lblServerStatus: TLabel
      AlignWithMargins = True
      Left = 571
      Top = 8
      Width = 52
      Height = 15
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'STOPPED'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitLeft = 673
    end
    object lblServerCaption: TLabel
      AlignWithMargins = True
      Left = 532
      Top = 8
      Width = 35
      Height = 15
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'Server:'
      ExplicitLeft = 621
    end
    object lblSqlPlusStatus: TLabel
      AlignWithMargins = True
      Left = 409
      Top = 8
      Width = 94
      Height = 15
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'sqlplus: MISSING'
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitLeft = 513
    end
    object lblWalletToolStatus: TLabel
      AlignWithMargins = True
      Left = 207
      Top = 8
      Width = 116
      Height = 15
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'wallet tool: MISSING'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitLeft = 379
    end
    object lblToolsCaption: TLabel
      AlignWithMargins = True
      Left = 173
      Top = 8
      Width = 30
      Height = 15
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'Tools:'
      ExplicitLeft = 330
    end
    object lblSite: TLabel
      AlignWithMargins = True
      Left = 81
      Top = 8
      Width = 84
      Height = 15
      Cursor = crHandPoint
      Margins.Left = 6
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'https://kapps.at'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsUnderline]
      ParentFont = False
      OnClick = lblSiteClick
      OnMouseEnter = lblSiteMouseEnter
      OnMouseLeave = lblSiteMouseLeave
      ExplicitLeft = 98
    end
    object lblBrand: TLabel
      AlignWithMargins = True
      Left = 8
      Top = 8
      Width = 67
      Height = 15
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 7
      Align = alLeft
      Caption = 'KrosselApps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object mmMain: TMainMenu
    Left = 56
    Top = 88
    object miApp: TMenuItem
      Caption = 'App'
      object miSettings: TMenuItem
        Caption = 'Settings'
        OnClick = miSettingsClick
      end
      object miApiReference: TMenuItem
        Caption = 'API Reference'
        OnClick = miApiReferenceClick
      end
      object miAbout: TMenuItem
        Caption = 'About'
        OnClick = miAboutClick
      end
    end
    object miOptions: TMenuItem
      Caption = 'Options'
      object miConfigure: TMenuItem
        Caption = 'Configure'
        OnClick = miConfigureClick
      end
    end
    object miAddWallet: TMenuItem
      Caption = 'Add New Wallet'
      OnClick = miAddWalletClick
    end
  end
  object dlgOpenCert: TOpenDialog
    Left = 120
    Top = 88
  end
end

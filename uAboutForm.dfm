object AboutForm: TAboutForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'About'
  ClientHeight = 256
  ClientWidth = 520
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
    Width = 504
    Height = 198
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object gbInfo: TGroupBox
      Left = 0
      Top = 0
      Width = 504
      Height = 198
      Align = alClient
      Caption = 'Oracle Wallet Certificate Manager'
      TabOrder = 0
      object lblAuthor: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 31
        Width = 484
        Height = 15
        Margins.Left = 10
        Margins.Top = 12
        Margins.Right = 10
        Margins.Bottom = 6
        Align = alTop
        Caption = 'Author: Vladislav Filimonov, Krossel Apps'
        ExplicitWidth = 244
      end
      object lblWebsiteCaption: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 58
        Width = 484
        Height = 15
        Margins.Left = 10
        Margins.Top = 6
        Margins.Right = 10
        Margins.Bottom = 0
        Align = alTop
        Caption = 'Website:'
        ExplicitWidth = 44
      end
      object lblWebsite: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 76
        Width = 484
        Height = 15
        Cursor = crHandPoint
        Margins.Left = 10
        Margins.Top = 3
        Margins.Right = 10
        Margins.Bottom = 8
        Align = alTop
        Caption = 'https://kapps.at'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsUnderline]
        ParentFont = False
        OnClick = lblWebsiteClick
        OnMouseEnter = lblWebsiteMouseEnter
        OnMouseLeave = lblWebsiteMouseLeave
        ExplicitWidth = 90
      end
      object lblDescription: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 102
        Width = 484
        Height = 84
        Margins.Left = 10
        Margins.Top = 3
        Margins.Right = 10
        Margins.Bottom = 10
        Align = alClient
        AutoSize = False
        Caption =
          'VCL utility for Oracle Wallet certificate lifecycle: list, add, rem' +
          'ove, folder import, summary of upcoming expirations, and optional l' +
          'ocal API for remote operations.'
        WordWrap = True
      end
    end
  end
  object pnlBottom: TPanel
    AlignWithMargins = True
    Left = 8
    Top = 214
    Width = 504
    Height = 34
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      AlignWithMargins = True
      Left = 416
      Top = 3
      Width = 85
      Height = 28
      Align = alRight
      Caption = 'Close'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
  end
end

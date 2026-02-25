object ApiReferenceForm: TApiReferenceForm
  Left = 0
  Top = 0
  Caption = 'API Reference'
  ClientHeight = 720
  ClientWidth = 1140
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object pnlClient: TPanel
    Left = 0
    Top = 0
    Width = 1140
    Height = 720
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 285
      Height = 720
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object tvEndpoints: TTreeView
        Left = 0
        Top = 0
        Width = 285
        Height = 720
        Align = alClient
        HideSelection = False
        Indent = 19
        ReadOnly = True
        TabOrder = 0
        OnChange = tvEndpointsChange
      end
    end
    object splMain: TSplitter
      Left = 285
      Top = 0
      Width = 8
      Height = 720
      ResizeStyle = rsUpdate
      ExplicitLeft = 279
      ExplicitTop = -16
      ExplicitHeight = 744
    end
    object pnlRight: TPanel
      Left = 293
      Top = 0
      Width = 847
      Height = 720
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object gbResponse: TGroupBox
        Left = 0
        Top = 412
        Width = 847
        Height = 308
        Align = alClient
        Caption = 'Response example'
        TabOrder = 3
        object reResponse: TRichEdit
          Left = 2
          Top = 17
          Width = 843
          Height = 289
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
          WordWrap = False
        end
      end
      object splReqResp: TSplitter
        Left = 0
        Top = 404
        Width = 847
        Height = 8
        Cursor = crVSplit
        Align = alTop
        ResizeStyle = rsUpdate
        ExplicitTop = 362
      end
      object gbRequest: TGroupBox
        Left = 0
        Top = 176
        Width = 847
        Height = 228
        Align = alTop
        Caption = 'Request example'
        TabOrder = 2
        object reRequest: TRichEdit
          Left = 2
          Top = 17
          Width = 843
          Height = 209
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
          WordWrap = False
        end
      end
      object pnlHeader: TPanel
        Left = 0
        Top = 0
        Width = 847
        Height = 176
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblDescription: TLabel
          AlignWithMargins = True
          Left = 8
          Top = 58
          Width = 831
          Height = 110
          Margins.Left = 8
          Margins.Top = 6
          Margins.Right = 8
          Margins.Bottom = 8
          Align = alClient
          AutoSize = False
          Caption = 'Endpoint description and examples will be displayed here.'
          WordWrap = True
          ExplicitHeight = 15
        end
        object reEndpoint: TRichEdit
          AlignWithMargins = True
          Left = 8
          Top = 8
          Width = 831
          Height = 44
          Margins.Left = 8
          Margins.Top = 8
          Margins.Right = 8
          Margins.Bottom = 0
          Align = alTop
          BorderStyle = bsNone
          Color = clBtnFace
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          Lines.Strings = (
            'Select an endpoint in the tree.')
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
  end
end

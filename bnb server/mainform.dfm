object FormMain: TFormMain
  Left = 0
  Top = 0
  Anchors = [akLeft, akTop, akRight, akBottom]
  Caption = 'FormMain'
  ClientHeight = 558
  ClientWidth = 894
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object IPLabel: TLabel
    Left = 32
    Top = 21
    Width = 48
    Height = 13
    Caption = #32465#23450#22320#22336
  end
  object PortLabel: TLabel
    Left = 240
    Top = 21
    Width = 24
    Height = 13
    Caption = #31471#21475
  end
  object StartButton: TButton
    Left = 440
    Top = 16
    Width = 75
    Height = 25
    Caption = #21551#21160
    TabOrder = 0
    OnClick = StartButtonClick
  end
  object IPEdit: TEdit
    Left = 95
    Top = 18
    Width = 121
    Height = 21
    TabOrder = 1
    Text = '10.246.54.151'
  end
  object PortEdit: TEdit
    Left = 278
    Top = 18
    Width = 121
    Height = 21
    TabOrder = 2
    Text = '1234'
  end
  object PageControl1: TPageControl
    Left = 16
    Top = 80
    Width = 857
    Height = 457
    ActivePage = TabSheet1
    Align = alCustom
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
    object TabSheet1: TTabSheet
      Caption = #26085#24535
      object LogRichEdit: TRichEdit
        Left = 0
        Top = 0
        Width = 849
        Height = 429
        Align = alClient
        Color = clInfoText
        Font.Charset = GB2312_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Lines.Strings = (
          'LogRichEdit')
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        Zoom = 100
      end
    end
    object TabSheet2: TTabSheet
      Caption = #20107#20214
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 648
    Top = 16
  end
end

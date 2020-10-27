object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'FrmMain'
  ClientHeight = 485
  ClientWidth = 671
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  DesignSize = (
    671
    485)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 501
    Top = 15
    Width = 60
    Height = 13
    Anchors = [akLeft, akTop, akRight]
    Caption = #22312#32447#21015#34920#65306
  end
  object redtChat: TRichEdit
    Left = 15
    Top = 15
    Width = 475
    Height = 361
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clInfoBk
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object lbOnlines: TListBox
    Left = 501
    Top = 42
    Width = 157
    Height = 334
    Anchors = [akTop, akRight, akBottom]
    Color = clInfoBk
    ItemHeight = 13
    TabOrder = 1
  end
  object mmInput: TMemo
    Left = 15
    Top = 387
    Width = 554
    Height = 79
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 2
  end
  object bbtnSend: TBitBtn
    Left = 575
    Top = 387
    Width = 83
    Height = 79
    Anchors = [akRight, akBottom]
    Caption = #21457#36865
    TabOrder = 3
    OnClick = bbtnSendClick
  end
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 603
    Top = 21
  end
end

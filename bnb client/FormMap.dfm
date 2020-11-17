object FrmMap: TFrmMap
  Left = 0
  Top = 0
  Caption = 'FrmMap'
  ClientHeight = 808
  ClientWidth = 904
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object pntbx: TPaintBox32
    Left = 0
    Top = 0
    Width = 904
    Height = 808
    Align = alClient
    TabOrder = 0
    ExplicitLeft = -216
    ExplicitTop = -96
    ExplicitWidth = 649
    ExplicitHeight = 481
  end
  object pnl1: TPanel
    Left = 799
    Top = 0
    Width = 129
    Height = 97
    TabOrder = 1
    object lbl2: TLabel
      Left = 8
      Top = 32
      Width = 36
      Height = 26
      Caption = 'speed :'#13#10
    end
    object lbl3: TLabel
      Left = 66
      Top = 32
      Width = 16
      Height = 13
      Caption = 'lbl3'
    end
    object lbl4: TLabel
      Left = 8
      Top = 56
      Width = 38
      Height = 13
      Caption = 'faceto :'
    end
    object lbl5: TLabel
      Left = 61
      Top = 56
      Width = 16
      Height = 13
      Caption = 'lbl5'
    end
    object lbl6: TLabel
      Left = 0
      Top = 13
      Width = 47
      Height = 13
      Caption = 'PlayerId :'
    end
    object lbl7: TLabel
      Left = 66
      Top = 13
      Width = 16
      Height = 13
      Caption = 'lbl7'
    end
    object lbl1: TLabel
      Left = 8
      Top = 75
      Width = 47
      Height = 13
      Caption = 'MsgNum :'
    end
    object lbl8: TLabel
      Left = 61
      Top = 75
      Width = 6
      Height = 13
      Caption = '0'
    end
  end
end

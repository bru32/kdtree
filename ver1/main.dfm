object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Kd-Tree'
  ClientHeight = 510
  ClientWidth = 643
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = [fsBold]
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    643
    510)
  PixelsPerInch = 96
  TextHeight = 13
  object pbxDiagram: TPaintBox
    Left = 8
    Top = 48
    Width = 627
    Height = 454
    Anchors = [akLeft, akTop, akRight, akBottom]
    OnPaint = pbxDiagramPaint
  end
  object Label1: TLabel
    Left = 8
    Top = 11
    Width = 61
    Height = 13
    Caption = 'Dimention:'
  end
  object Label2: TLabel
    Left = 280
    Top = 11
    Width = 58
    Height = 13
    Caption = 'Find Point:'
  end
  object btnSearch: TButton
    Left = 495
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Search'
    TabOrder = 0
    OnClick = btnSearchClick
  end
  object btnCreateTree: TButton
    Left = 119
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Create Tree'
    TabOrder = 1
    OnClick = btnCreateTreeClick
  end
  object Edit1: TEdit
    Left = 344
    Top = 8
    Width = 145
    Height = 21
    TabOrder = 2
    Text = '0,0'
  end
  object edtDimention: TEdit
    Left = 71
    Top = 8
    Width = 33
    Height = 21
    TabOrder = 3
    Text = '2'
  end
end

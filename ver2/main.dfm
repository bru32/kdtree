object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 415
  ClientWidth = 437
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox1: TPaintBox
    Left = 21
    Top = 8
    Width = 400
    Height = 400
    OnMouseEnter = PaintBox1MouseEnter
    OnMouseLeave = PaintBox1MouseLeave
    OnMouseMove = PaintBox1MouseMove
    OnPaint = PaintBox1Paint
  end
end

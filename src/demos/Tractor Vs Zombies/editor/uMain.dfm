object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = '-'
  ClientHeight = 654
  ClientWidth = 1048
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    1048
    654)
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 47
    Width = 800
    Height = 600
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
  end
  object Button1: TButton
    Left = 851
    Top = 8
    Width = 137
    Height = 33
    Anchors = [akTop, akRight]
    Caption = #1048#1085#1080#1094#1080#1072#1083#1080#1079#1072#1094#1080#1103
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 851
    Top = 47
    Width = 137
    Height = 34
    Anchors = [akTop, akRight]
    Caption = #1044#1077#1080#1085#1080#1094#1080#1072#1083#1080#1079#1072#1094#1080#1103
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    OnClick = Button2Click
  end
  object gbEarthTools: TGroupBox
    Left = 814
    Top = 104
    Width = 226
    Height = 81
    Anchors = [akTop, akRight]
    Caption = #1047#1077#1084#1083#1103' :: '#1048#1085#1089#1090#1088#1091#1084#1077#1085#1090#1099
    TabOrder = 3
    object btnEarthPathCreate: TButton
      Left = 3
      Top = 46
      Width = 206
      Height = 25
      Caption = #1056#1077#1078#1080#1084' '#1085#1086#1074#1099#1093' '#1090#1086#1095#1077#1082
      TabOrder = 0
      OnClick = btnEarthPathCreateClick
    end
    object btnEarthPathSelect: TButton
      Left = 3
      Top = 15
      Width = 206
      Height = 25
      Caption = #1056#1077#1078#1080#1084' '#1074#1099#1073#1086#1088#1072' '#1090#1086#1095#1077#1082
      TabOrder = 1
      OnClick = btnEarthPathSelectClick
    end
  end
  object btnSelect: TButton
    Left = 8
    Top = 8
    Width = 131
    Height = 25
    Caption = #1056#1077#1078#1080#1084' '#1074#1099#1073#1086#1088#1072
    TabOrder = 4
    OnClick = btnSelectClick
  end
  object btnEarth: TButton
    Left = 145
    Top = 8
    Width = 75
    Height = 25
    Caption = #1047#1077#1084#1083#1103
    TabOrder = 5
    OnClick = btnEarthClick
  end
  object btnObjects: TButton
    Left = 226
    Top = 8
    Width = 75
    Height = 25
    Caption = #1054#1073#1098#1077#1082#1090#1099
    TabOrder = 6
    OnClick = btnObjectsClick
  end
  object gbEarthProperties: TGroupBox
    Left = 814
    Top = 191
    Width = 226
    Height = 81
    Anchors = [akTop, akRight]
    Caption = #1047#1077#1084#1083#1103' :: '#1057#1074#1086#1081#1089#1090#1074#1072
    TabOrder = 7
    object Label1: TLabel
      Left = 7
      Top = 55
      Width = 41
      Height = 13
      Caption = #1048#1085#1076#1077#1082#1089':'
    end
    object editEarthPosX: TLabeledEdit
      Left = 24
      Top = 24
      Width = 65
      Height = 21
      EditLabel.Width = 13
      EditLabel.Height = 13
      EditLabel.Caption = 'X: '
      LabelPosition = lpLeft
      NumbersOnly = True
      TabOrder = 0
    end
    object editEarthPosY: TLabeledEdit
      Left = 120
      Top = 24
      Width = 65
      Height = 21
      EditLabel.Width = 13
      EditLabel.Height = 13
      EditLabel.Caption = 'Y: '
      LabelPosition = lpLeft
      NumbersOnly = True
      TabOrder = 1
    end
    object editEarthIndex: TSpinEdit
      Left = 54
      Top = 51
      Width = 71
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 2
      Value = 0
    end
  end
  object gbObjectProperties: TGroupBox
    Left = 814
    Top = 287
    Width = 226
    Height = 138
    Caption = #1054#1073#1098#1077#1082#1090#1099' :: '#1057#1074#1086#1081#1089#1090#1074#1072
    TabOrder = 8
    object editObjectPosY: TLabeledEdit
      Left = 120
      Top = 24
      Width = 65
      Height = 21
      EditLabel.Width = 13
      EditLabel.Height = 13
      EditLabel.Caption = 'Y: '
      LabelPosition = lpLeft
      NumbersOnly = True
      TabOrder = 0
    end
    object editObjectPosX: TLabeledEdit
      Left = 24
      Top = 24
      Width = 65
      Height = 21
      EditLabel.Width = 13
      EditLabel.Height = 13
      EditLabel.Caption = 'X: '
      LabelPosition = lpLeft
      NumbersOnly = True
      TabOrder = 1
    end
    object editObjectSizeY: TLabeledEdit
      Left = 112
      Top = 80
      Width = 65
      Height = 21
      EditLabel.Width = 15
      EditLabel.Height = 13
      EditLabel.Caption = #1085#1072' '
      LabelPosition = lpLeft
      NumbersOnly = True
      TabOrder = 2
    end
    object editObjectSizeX: TLabeledEdit
      Left = 24
      Top = 80
      Width = 65
      Height = 21
      EditLabel.Width = 35
      EditLabel.Height = 13
      EditLabel.Caption = #1056#1072#1079#1084#1077#1088
      NumbersOnly = True
      TabOrder = 3
    end
    object editObjectRot: TLabeledEdit
      Left = 112
      Top = 107
      Width = 65
      Height = 21
      EditLabel.Width = 82
      EditLabel.Height = 13
      EditLabel.Caption = #1059#1075#1086#1083' '#1087#1086#1074#1086#1088#1086#1090#1072': '
      LabelPosition = lpLeft
      NumbersOnly = True
      TabOrder = 4
    end
  end
  object gbObjectTools: TGroupBox
    Left = 814
    Top = 431
    Width = 226
    Height = 105
    Caption = #1054#1073#1098#1077#1082#1090#1099' :: '#1048#1085#1089#1090#1088#1091#1084#1077#1085#1090#1099
    TabOrder = 9
  end
  object MainMenu1: TMainMenu
    Left = 1000
    Top = 32
    object N1: TMenuItem
      Caption = #1060#1072#1081#1083
      object menuNewLevel: TMenuItem
        Caption = #1053#1086#1074#1099#1081' '#1091#1088#1086#1074#1077#1085#1100
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object menuLoadLevel: TMenuItem
        Caption = #1047#1072#1075#1088#1091#1079#1080#1090#1100' '#1091#1088#1086#1074#1077#1085#1100
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object menuSaveLevel: TMenuItem
        Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1091#1088#1086#1074#1077#1085#1100
      end
      object menuSaveLevelAs: TMenuItem
        Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1091#1088#1086#1074#1077#1085#1100' '#1082#1072#1082'...'
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object menuExit: TMenuItem
        Caption = #1042#1099#1093#1086#1076
        OnClick = menuExitClick
      end
    end
  end
end

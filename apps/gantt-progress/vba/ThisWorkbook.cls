VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisWorkbook"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

' ============================================================
' ThisWorkbook.cls — Workbook_Open で UserInterfaceOnly 再設定
' ※ UserInterfaceOnly はブックを閉じると失われるため必須
' ============================================================

Private Sub Workbook_Open()
    On Error Resume Next
    Call ReProtect
    On Error GoTo 0
End Sub

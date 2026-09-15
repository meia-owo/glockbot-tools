VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SheetDateEvents"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

' ============================================================
' SheetDateEvents.cls — 日付シート用イベント スタブ
'
' 【組み立て手順】
' 各 YYYYMMDD シートの「シートモジュール」に以下をコピーする。
' （または GenerateSheets 直後に手動で貼り付け）
' クラスとしてインポートしてもシートに自動バインドされない点に注意。
'
' ボタン配置（フォームコントロール）:
'   「着工」         → ButtonRecordStart
'   「完了」         → ButtonRecordFinish
'   「記録取り消し」 → ButtonUndoLast
'   「階層1」        → ShowLevel1
'   「階層2」        → ShowLevel2
'   「階層3」        → ShowLevel3
' ============================================================

' --- 以下を各日付シートのコードに貼り付け ---
'
' Option Explicit
'
' Private Sub Worksheet_BeforeDoubleClick(ByVal Target As Range, Cancel As Boolean)
'     ' J列=着工(10), K列=完了(11)
'     If Target.CountLarge > 1 Then Exit Sub
'     If Target.Row <= 1 Then Exit Sub
'     If Target.Column = 10 Then
'         Cancel = True
'         Call RecordStart(Me, Target.Row)
'     ElseIf Target.Column = 11 Then
'         Cancel = True
'         Call RecordFinish(Me, Target.Row)
'     End If
' End Sub
'

' 開発時テスト用（このクラス単体ではシートに紐付かない）
Public Sub InstallHint()
    MsgBox "このコードを各 YYYYMMDD シートモジュールにコピーしてください。" & vbCrLf & _
           "詳細は README.md / SHEET_DESIGN.md を参照。", vbInformation
End Sub

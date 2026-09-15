Attribute VB_Name = "ImportVba"
Option Explicit

' ============================================================
' Excel 上で一度だけ実行するインポートヘルパー（手動でも可）
' 使い方:
'  1. GanttProgress_v3_TEMPLATE.xlsx を開く
'  2. VBA エディタで新規標準モジュールを作り、本ファイル内容を貼付
'  3. RunImport を実行（vba フォルダのパスを定数で指定）
'  4. この一時モジュールは削除して .xlsm 保存
' ============================================================

Private Const VBA_FOLDER As String = "C:\path\to\gantt-progress-v3\vba\"

Public Sub RunImport()
    Dim vbproj As Object
    Dim f As Variant
    Dim files As Variant

    files = Array("modUtil.bas", "modValidate.bas", "modGantt.bas", "modProgress.bas", "modMain.bas")
    Set vbproj = ThisWorkbook.VBProject

    For Each f In files
        vbproj.VBComponents.Import VBA_FOLDER & CStr(f)
    Next f

    MsgBox "標準モジュールのインポートが完了しました。" & vbCrLf & _
           "ThisWorkbook_Open と日付シートの BeforeDoubleClick は手動で貼ってください。", vbInformation
End Sub

' ============================================================
' 各日付シート（YYYYMMDD）のシートモジュールへ貼り付け用
' ============================================================
Option Explicit

Private Sub Worksheet_BeforeDoubleClick(ByVal Target As Range, Cancel As Boolean)
    ' J列=着工(10), K列=完了(11)
    If Target.CountLarge > 1 Then Exit Sub
    If Target.Row <= 1 Then Exit Sub
    Select Case Target.Column
        Case 10  ' 着工
            Cancel = True
            Call RecordStart(Me, Target.Row)
        Case 11  ' 完了
            Cancel = True
            Call RecordFinish(Me, Target.Row)
    End Select
End Sub

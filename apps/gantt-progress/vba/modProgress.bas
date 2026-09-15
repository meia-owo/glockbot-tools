Attribute VB_Name = "modProgress"
Option Explicit

' ============================================================
' modProgress.bas — 着工/完了タイムスタンプ・実績塗り・Undo・Log
' ============================================================

Private Const STATUS_TODO As String = "未着手"
Private Const STATUS_DOING As String = "着工中"
Private Const STATUS_DONE As String = "完了"

' 着工記録（行番号指定。ダブルクリック / ボタン共用）
Public Sub RecordStart(Optional ByVal ws As Worksheet = Nothing, Optional ByVal targetRow As Long = 0)
    Dim row As Long
    Dim taskName As String
    Dim ans As VbMsgBoxResult

    On Error GoTo EH
    If ws Is Nothing Then Set ws = ActiveSheet
    If Not IsDateSheetName(ws.Name) Then
        MsgBox "日付シート上で実行してください。", vbExclamation, "RecordStart"
        Exit Sub
    End If

    row = ResolveTaskRow(ws, targetRow)
    If row <= 1 Then Exit Sub

    If Len(Trim$(CStr(ws.Cells(row, COL_DATE_START).Value & ""))) > 0 Then
        MsgBox "既に着工時刻が記録されています。取り消してから再記録してください。", vbExclamation, "RecordStart"
        Exit Sub
    End If

    taskName = TaskLabel(ws, row)
    ans = MsgBox("タスク「" & taskName & "」を着工として記録します。" & vbCrLf & "よろしいですか？", _
                 vbOKCancel + vbQuestion, "着工記録")
    If ans <> vbOK Then Exit Sub

    SpeedOn
    ws.Unprotect Password:=""
    ws.Cells(row, COL_DATE_START).Value = Now
    ws.Cells(row, COL_DATE_START).NumberFormat = "yyyy/mm/dd hh:mm:ss"
    ws.Cells(row, COL_DATE_STATUS).Value = STATUS_DOING
    ' 着工時点: 計画線の開始セルから「現在相当」までは実績色を載せない（計画固定・論点C）
    ' 着工中はステータスのみ。完了時に着工〜完了範囲を実績塗り。
    ' 視認用に計画線先頭セルを黄で上書き（連続1セル or 開始列のみ）
    PaintActualPartial ws, row, ColorInProgress()
    AppendLog ws.Name, row, "着工", taskName
    Call ReProtectSingle(ws)
    SpeedOff
    Exit Sub
EH:
    SpeedForceRestore
    On Error Resume Next
    Call ReProtectSingle(ws)
    MsgBox "RecordStart エラー: " & Err.Description, vbCritical
End Sub

' 完了記録
Public Sub RecordFinish(Optional ByVal ws As Worksheet = Nothing, Optional ByVal targetRow As Long = 0)
    Dim row As Long
    Dim taskName As String
    Dim ans As VbMsgBoxResult
    Dim startTs As Variant

    On Error GoTo EH
    If ws Is Nothing Then Set ws = ActiveSheet
    If Not IsDateSheetName(ws.Name) Then
        MsgBox "日付シート上で実行してください。", vbExclamation, "RecordFinish"
        Exit Sub
    End If

    row = ResolveTaskRow(ws, targetRow)
    If row <= 1 Then Exit Sub

    startTs = ws.Cells(row, COL_DATE_START).Value
    If Not IsDate(startTs) Then
        MsgBox "着工時刻が未記録です。先に着工を記録してください。", vbExclamation, "RecordFinish"
        Exit Sub
    End If
    If Len(Trim$(CStr(ws.Cells(row, COL_DATE_FINISH).Value & ""))) > 0 Then
        MsgBox "既に完了時刻が記録されています。", vbExclamation, "RecordFinish"
        Exit Sub
    End If

    taskName = TaskLabel(ws, row)
    ans = MsgBox("タスク「" & taskName & "」を完了として記録します。" & vbCrLf & "よろしいですか？", _
                 vbOKCancel + vbQuestion, "完了記録")
    If ans <> vbOK Then Exit Sub

    SpeedOn
    ws.Unprotect Password:=""
    ws.Cells(row, COL_DATE_FINISH).Value = Now
    ws.Cells(row, COL_DATE_FINISH).NumberFormat = "yyyy/mm/dd hh:mm:ss"
    ws.Cells(row, COL_DATE_STATUS).Value = STATUS_DONE
    ' 着工〜完了の実績範囲を一括塗り（計画線は固定・上に実績色）
    PaintActualSpan ws, row, CDate(startTs), Now, ColorDone()
    AppendLog ws.Name, row, "完了", taskName
    Call ReProtectSingle(ws)
    SpeedOff
    Exit Sub
EH:
    SpeedForceRestore
    On Error Resume Next
    Call ReProtectSingle(ws)
    MsgBox "RecordFinish エラー: " & Err.Description, vbCritical
End Sub

' 直前タイムスタンプ取り消し（選択行）
Public Sub UndoLast(Optional ByVal ws As Worksheet = Nothing, Optional ByVal targetRow As Long = 0)
    Dim row As Long
    Dim taskName As String
    Dim ans As VbMsgBoxResult
    Dim hasFinish As Boolean, hasStart As Boolean

    On Error GoTo EH
    If ws Is Nothing Then Set ws = ActiveSheet
    If Not IsDateSheetName(ws.Name) Then
        MsgBox "日付シート上で実行してください。", vbExclamation, "UndoLast"
        Exit Sub
    End If

    row = ResolveTaskRow(ws, targetRow)
    If row <= 1 Then Exit Sub

    hasFinish = Len(Trim$(CStr(ws.Cells(row, COL_DATE_FINISH).Value & ""))) > 0
    hasStart = Len(Trim$(CStr(ws.Cells(row, COL_DATE_START).Value & ""))) > 0
    If Not hasFinish And Not hasStart Then
        MsgBox "取り消すタイムスタンプがありません。", vbInformation, "UndoLast"
        Exit Sub
    End If

    taskName = TaskLabel(ws, row)
    ans = MsgBox("タスク「" & taskName & "」の記録を取り消します。" & vbCrLf & _
                 "（完了があれば完了のみ、なければ着工をクリア）" & vbCrLf & "よろしいですか？", _
                 vbOKCancel + vbQuestion, "記録取り消し")
    If ans <> vbOK Then Exit Sub

    SpeedOn
    ws.Unprotect Password:=""
    If hasFinish Then
        ws.Cells(row, COL_DATE_FINISH).ClearContents
        ws.Cells(row, COL_DATE_STATUS).Value = STATUS_DOING
        ' 実績緑を戻すのは複雑（計画色復元）。簡易: ガント帯を計画色に戻し着工黄を再適用
        RestorePlanThenInProgress ws, row
        AppendLog ws.Name, row, "完了取消", taskName
    ElseIf hasStart Then
        ws.Cells(row, COL_DATE_START).ClearContents
        ws.Cells(row, COL_DATE_STATUS).Value = STATUS_TODO
        RestorePlanOnly ws, row
        AppendLog ws.Name, row, "着工取消", taskName
    End If
    Call ReProtectSingle(ws)
    SpeedOff
    Exit Sub
EH:
    SpeedForceRestore
    On Error Resume Next
    Call ReProtectSingle(ws)
    MsgBox "UndoLast エラー: " & Err.Description, vbCritical
End Sub

' ボタン用: 選択行の着工
Public Sub ButtonRecordStart()
    Dim ws As Worksheet
    Set ws = ActiveSheet
    If Selection.CountLarge > 1 Then
        MsgBox "複数セルが選択されています。単一タスク行を選択してください。", vbExclamation
        Exit Sub
    End If
    RecordStart ws, Selection.Row
End Sub

Public Sub ButtonRecordFinish()
    Dim ws As Worksheet
    Set ws = ActiveSheet
    If Selection.CountLarge > 1 Then
        MsgBox "複数セルが選択されています。単一タスク行を選択してください。", vbExclamation
        Exit Sub
    End If
    RecordFinish ws, Selection.Row
End Sub

Public Sub ButtonUndoLast()
    Dim ws As Worksheet
    Set ws = ActiveSheet
    If Selection.CountLarge > 1 Then
        MsgBox "複数セルが選択されています。単一タスク行を選択してください。", vbExclamation
        Exit Sub
    End If
    UndoLast ws, Selection.Row
End Sub

' 階層表示切替
Public Sub ShowLevel1()
    On Error Resume Next
    ActiveSheet.Outline.ShowLevels RowLevels:=1
End Sub
Public Sub ShowLevel2()
    On Error Resume Next
    ActiveSheet.Outline.ShowLevels RowLevels:=2
End Sub
Public Sub ShowLevel3()
    On Error Resume Next
    ActiveSheet.Outline.ShowLevels RowLevels:=3
End Sub

' --- helpers ---

Private Function ResolveTaskRow(ByVal ws As Worksheet, ByVal targetRow As Long) As Long
    Dim row As Long
    If targetRow > 1 Then
        row = targetRow
    Else
        If Selection.CountLarge > 1 Then
            MsgBox "複数セルが選択されています。単一タスク行を選択してください。", vbExclamation
            ResolveTaskRow = 0
            Exit Function
        End If
        row = Selection.Row
    End If
    If row <= 1 Then
        MsgBox "ヘッダ行は対象外です。", vbExclamation
        ResolveTaskRow = 0
        Exit Function
    End If
    If Len(Trim$(CStr(ws.Cells(row, COL_DATE_SMALL).Value & ""))) = 0 Then
        MsgBox "タスク行ではありません。", vbExclamation
        ResolveTaskRow = 0
        Exit Function
    End If
    ResolveTaskRow = row
End Function

Private Function TaskLabel(ByVal ws As Worksheet, ByVal row As Long) As String
    TaskLabel = CStr(ws.Cells(row, COL_DATE_LARGE).Value) & " / " & _
                CStr(ws.Cells(row, COL_DATE_MID).Value) & " / " & _
                CStr(ws.Cells(row, COL_DATE_SMALL).Value)
End Function

' 着工中: 計画グレー帯のうち先頭セルを黄に（簡易視認）
Private Sub PaintActualPartial(ByVal ws As Worksheet, ByVal row As Long, ByVal clr As Long)
    Dim c As Long, cFirst As Long, cLast As Long
    cFirst = 0
    For c = COL_DATE_TIME0 To COL_DATE_TIME0 + TIME_COL_COUNT - 1
        If ws.Cells(row, c).Interior.Color = ColorPlan() Then
            If cFirst = 0 Then cFirst = c
            cLast = c
        ElseIf cFirst > 0 Then
            Exit For
        End If
    Next c
    If cFirst > 0 Then
        ' 連続計画帯の先頭1セルのみ黄（範囲一括の最小単位）
        ws.Cells(row, cFirst).Interior.Color = clr
    End If
End Sub

' 着工〜完了の実時刻を5分セルにマップして一括塗り
Private Sub PaintActualSpan(ByVal ws As Worksheet, ByVal row As Long, _
                            ByVal tStart As Date, ByVal tFinish As Date, ByVal clr As Long)
    Dim sMin As Long, eMin As Long
    Dim c1 As Long, c2 As Long
    Dim maxCol As Long

    sMin = Hour(tStart) * 60 + Minute(tStart)
    eMin = Hour(tFinish) * 60 + Minute(tFinish)
    If eMin < sMin Then eMin = sMin
    ' 5分切り上げで終了セル
    c1 = COL_DATE_TIME0 + (sMin \ 5)
    c2 = COL_DATE_TIME0 + (Application.WorksheetFunction.Ceiling(eMin + 0.001, 5) \ 5) - 1
    If c2 < c1 Then c2 = c1
    maxCol = COL_DATE_TIME0 + TIME_COL_COUNT - 1
    If c1 < COL_DATE_TIME0 Then c1 = COL_DATE_TIME0
    If c2 > maxCol Then c2 = maxCol
    If c1 > maxCol Then Exit Sub
    ' ★ 1回の Range 一括塗り
    ws.Range(ws.Cells(row, c1), ws.Cells(row, c2)).Interior.Color = clr
End Sub

' 計画色復元（グレー連続帯を Input から再描画は重いので、既存グレー/黄/緑をグレーに戻す簡易版）
' 本格復元は GenerateSheets 再実行 or 将来の「計画再描画」ボタン（論点C）
Private Sub RestorePlanOnly(ByVal ws As Worksheet, ByVal row As Long)
    Dim c As Long
    Dim c1 As Long, c2 As Long
    Dim inBand As Boolean
    ' 黄/緑/グレーが連続する帯を検出してグレーに戻す（複数バンド対応は簡易1パス）
    c1 = 0
    For c = COL_DATE_TIME0 To COL_DATE_TIME0 + TIME_COL_COUNT - 1
        Select Case ws.Cells(row, c).Interior.Color
            Case ColorPlan(), ColorInProgress(), ColorDone()
                If c1 = 0 Then c1 = c
                c2 = c
            Case Else
                If c1 > 0 Then
                    ws.Range(ws.Cells(row, c1), ws.Cells(row, c2)).Interior.Color = ColorPlan()
                    c1 = 0
                End If
        End Select
    Next c
    If c1 > 0 Then
        ws.Range(ws.Cells(row, c1), ws.Cells(row, c2)).Interior.Color = ColorPlan()
    End If
End Sub

Private Sub RestorePlanThenInProgress(ByVal ws As Worksheet, ByVal row As Long)
    RestorePlanOnly ws, row
    PaintActualPartial ws, row, ColorInProgress()
End Sub

Private Sub AppendLog(ByVal sheetName As String, ByVal row As Long, _
                      ByVal op As String, ByVal taskName As String)
    Dim wsLog As Worksheet
    Dim lr As Long
    On Error Resume Next
    Set wsLog = ThisWorkbook.Worksheets("Log")
    If wsLog Is Nothing Then Exit Sub
    lr = wsLog.Cells(wsLog.Rows.Count, 1).End(xlUp).Row + 1
    If lr < 2 Then lr = 2
    wsLog.Cells(lr, 1).Value = Now
    wsLog.Cells(lr, 1).NumberFormat = "yyyy/mm/dd hh:mm:ss"
    wsLog.Cells(lr, 2).Value = sheetName
    wsLog.Cells(lr, 3).Value = row
    wsLog.Cells(lr, 4).Value = op
    wsLog.Cells(lr, 5).Value = taskName
    On Error GoTo 0
End Sub

Private Sub ReProtectSingle(ByVal ws As Worksheet)
    On Error Resume Next
    ws.Unprotect Password:=""
    ws.Cells.Locked = True
    ws.Range("D:H").Locked = False
    ws.Protect Password:="", UserInterfaceOnly:=True, _
        DrawingObjects:=False, Contents:=True, Scenarios:=True
    On Error GoTo 0
End Sub

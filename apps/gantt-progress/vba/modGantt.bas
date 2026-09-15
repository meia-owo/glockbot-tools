Attribute VB_Name = "modGantt"
Option Explicit

' ============================================================
' modGantt.bas — 計画線描画（アンカー＋チェーン / 大項目レーン）
' パフォーマンス必須:
'   - 1タスク = 1回の Range 一括塗り（セルループ禁止）
'   - Union 大量結合禁止
'   - 計画線は固定（論点C: 実績から引き直さない）
' ============================================================

' wsDate: 日付シート / tasks: その日のタスク配列（Input由来）
' tasks(i, 1..8) = Large, Mid, Small, Note1..5 は既に書き込み済み想定
' 本 Sub は行2以降の「開始時刻(元Input K)・総時間」をシートに保持していないため、
' GenerateSheets から lane 計算用の並列配列を渡すか、Hidden列を使う。
' → ここでは Input シートから対象日付の行を再走査して描画する方式。

Public Sub DrawPlanLines(ByVal wsDate As Worksheet, ByVal targetDate As Date, ByVal wsInput As Worksheet)
    Dim lastRow As Long
    Dim r As Long
    Dim d As Variant
    Dim large As String
    Dim startT As Variant
    Dim mins As Double
    Dim hasAnchor As Boolean
    Dim laneEnd As Object ' large -> endMin
    Dim startMin As Long
    Dim cellsNeeded As Long
    Dim endMin As Long
    Dim c1 As Long, c2 As Long
    Dim dateRow As Long
    Dim maxEndCol As Long

    Set laneEnd = CreateObject("Scripting.Dictionary")
    maxEndCol = COL_DATE_TIME0 + TIME_COL_COUNT - 1 ' 23:55 列

    ' 日付シートのタスク行は 2 行目〜（1行目=ヘッダ）
    ' Input と同じ順序で同一日付行を処理し、日付シート行と対応付ける
    dateRow = 1 ' ヘッダ直後からインクリメント
    lastRow = wsInput.Cells(wsInput.Rows.Count, COL_INPUT_DATE).End(xlUp).Row

    For r = 2 To lastRow
        d = wsInput.Cells(r, COL_INPUT_DATE).Value
        If Not IsDate(d) Then GoTo NextInput
        If CDate(d) <> CDate(targetDate) Then GoTo NextInput

        dateRow = dateRow + 1
        large = Trim$(CStr(wsInput.Cells(r, COL_INPUT_LARGE).Value & ""))
        mins = Val(wsInput.Cells(r, COL_INPUT_MINUTES).Value)
        startT = wsInput.Cells(r, COL_INPUT_STARTTIME).Value

        hasAnchor = False
        If Not IsEmpty(startT) And Len(Trim$(CStr(startT & ""))) > 0 Then
            If IsDate(startT) Or IsNumeric(startT) Then hasAnchor = True
        End If

        If hasAnchor Then
            startMin = Hour(CDate(startT)) * 60 + Minute(CDate(startT))
            ' 複数アンカー: チェーン起点をリセット
        Else
            If laneEnd.Exists(large) Then
                startMin = CLng(laneEnd(large))
            Else
                ' バリデーション済み想定だが防御
                GoTo NextInput
            End If
        End If

        cellsNeeded = MinutesToCells(mins)
        If cellsNeeded <= 0 Then GoTo NextInput

        endMin = startMin + cellsNeeded * 5
        ' 論点A: 23:55 クリップ（セル数も縮小）
        If endMin > 23 * 60 + 55 Then
            endMin = 23 * 60 + 55
            cellsNeeded = (endMin - startMin) \ 5
            If cellsNeeded <= 0 Then GoTo UpdateLane
        End If

        c1 = COL_DATE_TIME0 + (startMin \ 5)
        c2 = c1 + cellsNeeded - 1  ' 例: 9:00+45分 → 9セル (9:00〜9:40)
        If c1 < COL_DATE_TIME0 Then c1 = COL_DATE_TIME0
        If c2 > maxEndCol Then c2 = maxEndCol
        If c1 > maxEndCol Or c2 < c1 Then GoTo UpdateLane

        ' ★ パフォーマンス核心: 1タスク = 1 Range 一括塗り（セルループ・Union 禁止）
        wsDate.Range(wsDate.Cells(dateRow, c1), wsDate.Cells(dateRow, c2)).Interior.Color = ColorPlan()

UpdateLane:
        laneEnd(large) = endMin

NextInput:
    Next r
End Sub

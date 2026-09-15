Attribute VB_Name = "modMain"
Option Explicit

' ============================================================
' modMain.bas — シート生成全体制御 GenerateSheets
' 流れ: validate → unique dates → copy Template → write rows
'       → outline → DrawPlanLines → CleanNames
' ============================================================

Public Sub GenerateSheets()
    Dim wsInput As Worksheet
    Dim wsTemplate As Worksheet
    Dim dates As Object
    Dim dKey As Variant
    Dim ans As VbMsgBoxResult
    Dim wsDate As Worksheet
    Dim sheetName As String
    Dim targetDate As Date
    Dim i As Long
    Dim sortedDates() As Date
    Dim nDates As Long

    On Error GoTo EH
    Set wsInput = ThisWorkbook.Worksheets("Input")
    Set wsTemplate = ThisWorkbook.Worksheets("Template")

    SpeedOn
    Application.DisplayAlerts = False

    ' 1. バリデーション
    If Not ValidateInput(wsInput) Then
        GoTo CleanExit
    End If

    ' 2. ユニーク日付抽出（昇順）
    Set dates = CreateObject("Scripting.Dictionary")
    Dim lastRow As Long, r As Long, d As Variant
    lastRow = wsInput.Cells(wsInput.Rows.Count, COL_INPUT_DATE).End(xlUp).Row
    For r = 2 To lastRow
        d = wsInput.Cells(r, COL_INPUT_DATE).Value
        If IsDate(d) Then
            sheetName = Format$(CDate(d), "yyyymmdd")
            If Not dates.Exists(sheetName) Then
                dates.Add sheetName, CDate(d)
            End If
        End If
    Next r

    If dates.Count = 0 Then
        MsgBox "生成対象の日付がありません。", vbExclamation, "GenerateSheets"
        GoTo CleanExit
    End If

    ' ソート
    nDates = dates.Count
    ReDim sortedDates(1 To nDates)
    i = 0
    For Each dKey In dates.Keys
        i = i + 1
        sortedDates(i) = dates(dKey)
    Next dKey
    Call SortDates(sortedDates)

    ' No 自動採番
    Call RenumberInput(wsInput)

    ' 3〜5. 日付ごと生成
    For i = 1 To nDates
        targetDate = sortedDates(i)
        sheetName = Format$(targetDate, "yyyymmdd")

        On Error Resume Next
        Set wsDate = ThisWorkbook.Worksheets(sheetName)
        On Error GoTo EH

        If Not wsDate Is Nothing Then
            ans = MsgBox("シート「" & sheetName & "」は既に存在します。" & vbCrLf & _
                         "はい=上書き / いいえ=スキップ / キャンセル=中断", _
                         vbYesNoCancel + vbQuestion, "GenerateSheets")
            If ans = vbCancel Then GoTo CleanExit
            If ans = vbNo Then
                Set wsDate = Nothing
                GoTo NextDate
            End If
            ' 上書き: 削除して再Copy
            Application.DisplayAlerts = False
            wsDate.Delete
            Set wsDate = Nothing
            Application.DisplayAlerts = False
        End If

        ' Template Copy（名前定義は Template に持たせない）
        wsTemplate.Visible = xlSheetVisible
        wsTemplate.Copy After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count)
        Set wsDate = ActiveSheet
        wsDate.Name = sheetName
        wsTemplate.Visible = xlSheetHidden

        ' 備考見出し転記（Input F-J → 日付シート D-H の1行目）
        Call CopyNoteHeaders(wsInput, wsDate)

        ' タスク行書き込み＋アウトライン
        Call WriteDateRows(wsInput, wsDate, targetDate)

        ' 計画線描画
        Call DrawPlanLines(wsDate, targetDate, wsInput)

        ' 初期ステータス
        Call InitStatusColumn(wsDate)

        ' 保護
        Call ProtectDateSheet(wsDate)

        ' タブを日付昇順位置へ（簡易: 末尾のままでも可、並び替えは任意）
        Set wsDate = Nothing
NextDate:
    Next i

    ' タブ並び替え（Dashboard, Input, 日付昇順, Template, Log）
    Call OrderSheets

    ' 5. 不要名前定義削除
    Call CleanNames

    MsgBox "シート生成が完了しました（" & nDates & " 日分）。", vbInformation, "GenerateSheets"

CleanExit:
    Application.DisplayAlerts = True
    SpeedOff
    Exit Sub
EH:
    Application.DisplayAlerts = True
    SpeedForceRestore
    MsgBox "GenerateSheets エラー: " & Err.Description, vbCritical
End Sub

' Dashboard 更新ボタン用（数式中心のため軽量メモ）
Public Sub RefreshDashboard()
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets("Dashboard")
    If ws Is Nothing Then Exit Sub
    Call BuildDashboardLinks(ws)
    MsgBox "Dashboard の日別リンクを更新しました。", vbInformation, "RefreshDashboard"
End Sub

' --- private helpers ---

Private Sub RenumberInput(ByVal ws As Worksheet)
    Dim lastRow As Long, r As Long, n As Long
    lastRow = ws.Cells(ws.Rows.Count, COL_INPUT_DATE).End(xlUp).Row
    n = 0
    For r = 2 To lastRow
        If Len(Trim$(CStr(ws.Cells(r, COL_INPUT_DATE).Value & ""))) > 0 Then
            n = n + 1
            ws.Cells(r, COL_INPUT_NO).Value = n
        End If
    Next r
End Sub

Private Sub CopyNoteHeaders(ByVal wsInput As Worksheet, ByVal wsDate As Worksheet)
    Dim i As Long
    ' Input 1行目 F-J → Date 1行目 D-H
    For i = 0 To 4
        wsDate.Cells(1, COL_DATE_NOTE1 + i).Value = wsInput.Cells(1, COL_INPUT_NOTE1 + i).Value
    Next i
End Sub

Private Sub WriteDateRows(ByVal wsInput As Worksheet, ByVal wsDate As Worksheet, ByVal targetDate As Date)
    Dim lastRow As Long, r As Long, outRow As Long
    Dim d As Variant
    Dim prevLarge As String, prevMid As String
    Dim large As String, mid As String
    Dim grpStartLarge As Long, grpStartMid As Long
    Dim i As Long

    lastRow = wsInput.Cells(wsInput.Rows.Count, COL_INPUT_DATE).End(xlUp).Row
    outRow = 1
    prevLarge = vbNullString
    prevMid = vbNullString
    grpStartLarge = 0
    grpStartMid = 0

    ' アウトライン準備
    On Error Resume Next
    wsDate.Cells.ClearOutline
    On Error GoTo 0
    wsDate.Outline.AutomaticStyles = False
    wsDate.Outline.SummaryRow = xlAbove

    For r = 2 To lastRow
        d = wsInput.Cells(r, COL_INPUT_DATE).Value
        If Not IsDate(d) Then GoTo NextR
        If CDate(d) <> CDate(targetDate) Then GoTo NextR

        outRow = outRow + 1
        large = CStr(wsInput.Cells(r, COL_INPUT_LARGE).Value & "")
        mid = CStr(wsInput.Cells(r, COL_INPUT_MID).Value & "")

        wsDate.Cells(outRow, COL_DATE_LARGE).Value = large
        wsDate.Cells(outRow, COL_DATE_MID).Value = mid
        wsDate.Cells(outRow, COL_DATE_SMALL).Value = wsInput.Cells(r, COL_INPUT_SMALL).Value
        For i = 0 To 4
            wsDate.Cells(outRow, COL_DATE_NOTE1 + i).Value = wsInput.Cells(r, COL_INPUT_NOTE1 + i).Value
        Next i
        wsDate.Cells(outRow, COL_DATE_STATUS).Value = "未着手"

        ' 階層グループ: 同一大項目・中項目の連続行を後で Group
        ' 簡易実装: 行ごとに OutlineLevel を設定
        ' Level1=大項目境界, Level2=中項目, Level3=小項目(詳細)
        ' Excel Outline は Group でネスト。ここでは連続する同一 Large を Group、
        ' その中の同一 Mid を Group する2パス方式。

NextR:
    Next r

    ' Outline: 大項目・中項目の連続ブロックを Group
    Call ApplyOutlineGroups(wsDate, outRow)
End Sub

Private Sub ApplyOutlineGroups(ByVal ws As Worksheet, ByVal lastDataRow As Long)
    Dim r As Long
    Dim startR As Long
    Dim curLarge As String, curMid As String
    Dim nextLarge As String

    If lastDataRow < 3 Then Exit Sub

    On Error Resume Next
    ws.Outline.AutomaticStyles = False

    ' 中項目グループ（同一 Large+Mid の連続）
    startR = 2
    curLarge = CStr(ws.Cells(2, COL_DATE_LARGE).Value)
    curMid = CStr(ws.Cells(2, COL_DATE_MID).Value)
    For r = 3 To lastDataRow + 1
        If r <= lastDataRow Then
            nextLarge = CStr(ws.Cells(r, COL_DATE_LARGE).Value)
        Else
            nextLarge = vbNullString
        End If
        Dim nextMid As String
        If r <= lastDataRow Then
            nextMid = CStr(ws.Cells(r, COL_DATE_MID).Value)
        Else
            nextMid = vbNullString
        End If
        If nextLarge <> curLarge Or nextMid <> curMid Or r > lastDataRow Then
            If r - 1 > startR Then
                ws.Rows(startR & ":" & (r - 1)).Group
            End If
            If r <= lastDataRow Then
                startR = r
                curLarge = nextLarge
                curMid = nextMid
            End If
        End If
    Next r

    ' 大項目グループ
    startR = 2
    curLarge = CStr(ws.Cells(2, COL_DATE_LARGE).Value)
    For r = 3 To lastDataRow + 1
        If r <= lastDataRow Then
            nextLarge = CStr(ws.Cells(r, COL_DATE_LARGE).Value)
        Else
            nextLarge = vbNullString
        End If
        If nextLarge <> curLarge Or r > lastDataRow Then
            If r - 1 > startR Then
                ws.Rows(startR & ":" & (r - 1)).Group
            End If
            If r <= lastDataRow Then
                startR = r
                curLarge = nextLarge
            End If
        End If
    Next r
    On Error GoTo 0
End Sub

Private Sub InitStatusColumn(ByVal ws As Worksheet)
    Dim lastRow As Long, r As Long
    lastRow = ws.Cells(ws.Rows.Count, COL_DATE_SMALL).End(xlUp).Row
    For r = 2 To lastRow
        If Len(Trim$(CStr(ws.Cells(r, COL_DATE_STATUS).Value & ""))) = 0 Then
            ws.Cells(r, COL_DATE_STATUS).Value = "未着手"
        End If
    Next r
End Sub

Private Sub ProtectDateSheet(ByVal ws As Worksheet)
    On Error Resume Next
    ws.Unprotect Password:=""
    ws.Cells.Locked = True
    ws.Range("D:H").Locked = False
    ws.Protect Password:="", UserInterfaceOnly:=True, _
        DrawingObjects:=False, Contents:=True, Scenarios:=True
    On Error GoTo 0
End Sub

Private Sub SortDates(ByRef arr() As Date)
    Dim i As Long, j As Long
    Dim tmp As Date
    For i = LBound(arr) To UBound(arr) - 1
        For j = i + 1 To UBound(arr)
            If arr(j) < arr(i) Then
                tmp = arr(i)
                arr(i) = arr(j)
                arr(j) = tmp
            End If
        Next j
    Next i
End Sub

Private Sub OrderSheets()
    Dim ws As Worksheet
    Dim pos As Long
    On Error Resume Next
    ThisWorkbook.Worksheets("Dashboard").Move Before:=ThisWorkbook.Worksheets(1)
    ThisWorkbook.Worksheets("Input").Move After:=ThisWorkbook.Worksheets("Dashboard")
    ' 日付シートは名前順に並べる
    Dim names As Object
    Dim k As Variant
    Dim arr() As String
    Dim n As Long, i As Long, j As Long, tmp As String
    Set names = CreateObject("Scripting.Dictionary")
    For Each ws In ThisWorkbook.Worksheets
        If IsDateSheetName(ws.Name) Then names(ws.Name) = 1
    Next ws
    n = names.Count
    If n = 0 Then GoTo HideFixed
    ReDim arr(1 To n)
    i = 0
    For Each k In names.Keys
        i = i + 1
        arr(i) = CStr(k)
    Next k
    For i = 1 To n - 1
        For j = i + 1 To n
            If arr(j) < arr(i) Then
                tmp = arr(i): arr(i) = arr(j): arr(j) = tmp
            End If
        Next j
    Next i
    pos = 3 ' Dashboard=1, Input=2 の次
    For i = 1 To n
        ThisWorkbook.Worksheets(arr(i)).Move Before:=ThisWorkbook.Worksheets(pos)
        pos = pos + 1
    Next i
HideFixed:
    ThisWorkbook.Worksheets("Template").Visible = xlSheetHidden
    ThisWorkbook.Worksheets("Log").Visible = xlSheetHidden
    ThisWorkbook.Worksheets("Template").Move After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count)
    ThisWorkbook.Worksheets("Log").Move After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count)
    On Error GoTo 0
End Sub

Public Sub BuildDashboardLinks(ByVal wsDash As Worksheet)
    Dim ws As Worksheet
    Dim r As Long
    r = 12 ' 日別サマリ開始行（Dashboard レイアウトに合わせる）
    On Error Resume Next
    ' 既存リンク行をクリア（A12:D50）
    wsDash.Range("A12:D50").ClearContents
    For Each ws In ThisWorkbook.Worksheets
        If IsDateSheetName(ws.Name) Then
            wsDash.Hyperlinks.Add Anchor:=wsDash.Cells(r, 1), Address:="", SubAddress:="'" & ws.Name & "'!A1", TextToDisplay:=ws.Name
            wsDash.Cells(r, 2).Formula = "=IFERROR(COUNTIF('" & ws.Name & "'!I:I,""完了"")/COUNTA('" & ws.Name & "'!C:C)-1,"""")"
            ' 簡易: 完了率は生成後に数式調整。ここではシート名リンクのみ確実に
            r = r + 1
        End If
    Next ws
    On Error GoTo 0
End Sub

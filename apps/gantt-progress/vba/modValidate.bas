Attribute VB_Name = "modValidate"
Option Explicit

' ============================================================
' modValidate.bas — Input バリデーション
' 必須列 / レーン先頭アンカー / 時刻逆転 / 日付順
' 論点A: 23:55超 → 警告のみ（生成続行・描画側でクリップ）
' 論点D: 重なり → 警告のみ（生成続行）
' ============================================================

' 戻り値: True=生成続行可 / False=中断
Public Function ValidateInput(ByVal wsInput As Worksheet) As Boolean
    Dim lastRow As Long
    Dim r As Long
    Dim errMsg As String
    Dim warnMsg As String
    Dim d As Variant, large As String, startT As Variant, mins As Variant
    Dim prevDate As Date
    Dim hasPrevDate As Boolean
    Dim laneKey As String
    Dim laneFirstDone As Object
    Dim laneChainEnd As Object
    Dim lanePrevEnd As Long
    Dim startMin As Long
    Dim cellsNeeded As Long
    Dim endMin As Long
    Dim hasAnchor As Boolean

    ValidateInput = False
    errMsg = ""
    warnMsg = ""
    Set laneFirstDone = CreateObject("Scripting.Dictionary")
    Set laneChainEnd = CreateObject("Scripting.Dictionary")

    lastRow = wsInput.Cells(wsInput.Rows.Count, COL_INPUT_DATE).End(xlUp).Row
    If lastRow < 2 Then
        MsgBox "Inputシートにデータ行がありません。", vbExclamation, "ValidateInput"
        Exit Function
    End If

    hasPrevDate = False

    For r = 2 To lastRow
        If Len(Trim$(CStr(wsInput.Cells(r, COL_INPUT_DATE).Value & ""))) = 0 _
           And Len(Trim$(CStr(wsInput.Cells(r, COL_INPUT_LARGE).Value & ""))) = 0 Then
            GoTo NextRow
        End If

        d = wsInput.Cells(r, COL_INPUT_DATE).Value
        If Not IsDate(d) Then
            AppendLine errMsg, "行" & r & ": 日付が不正または空欄です。"
            GoTo NextRow
        End If
        large = Trim$(CStr(wsInput.Cells(r, COL_INPUT_LARGE).Value & ""))
        If Len(large) = 0 Then
            AppendLine errMsg, "行" & r & ": 大項目が空欄です。"
        End If
        If Len(Trim$(CStr(wsInput.Cells(r, COL_INPUT_MID).Value & ""))) = 0 Then
            AppendLine errMsg, "行" & r & ": 中項目が空欄です。"
        End If
        If Len(Trim$(CStr(wsInput.Cells(r, COL_INPUT_SMALL).Value & ""))) = 0 Then
            AppendLine errMsg, "行" & r & ": 小項目が空欄です。"
        End If

        mins = wsInput.Cells(r, COL_INPUT_MINUTES).Value
        If Not IsNumeric(mins) Or Val(mins) <= 0 Then
            AppendLine errMsg, "行" & r & ": 総時間(分)は正の数値が必須です。"
            mins = 0
        End If

        ' 日付昇順
        If hasPrevDate Then
            If CDate(d) < prevDate Then
                AppendLine errMsg, "行" & r & ": 日付が直前行より前です（日付昇順で記入してください）。"
            End If
        End If
        prevDate = CDate(d)
        hasPrevDate = True

        laneKey = Format$(CDate(d), "yyyymmdd") & "|" & large

        startT = wsInput.Cells(r, COL_INPUT_STARTTIME).Value
        hasAnchor = False
        If Not IsEmpty(startT) And Len(Trim$(CStr(startT & ""))) > 0 Then
            If IsDate(startT) Or IsNumeric(startT) Then
                hasAnchor = True
            Else
                AppendLine errMsg, "行" & r & ": 開始時刻の形式が不正です。"
            End If
        End If

        ' 各日付×大項目の先頭タスクに開始時刻必須 → エラー中断
        If Not laneFirstDone.Exists(laneKey) Then
            laneFirstDone(laneKey) = True
            If Not hasAnchor Then
                AppendLine errMsg, "行" & r & ": 日付×大項目「" & large & "」の先頭タスクに開始時刻(アンカー)が必要です。"
            End If
            If hasAnchor Then
                startMin = Hour(CDate(startT)) * 60 + Minute(CDate(startT))
            Else
                startMin = 0
            End If
        Else
            If hasAnchor Then
                startMin = Hour(CDate(startT)) * 60 + Minute(CDate(startT))
                ' 論点D: 重なり警告のみ・生成続行
                If laneChainEnd.Exists(laneKey) Then
                    lanePrevEnd = CLng(laneChainEnd(laneKey))
                    If startMin < lanePrevEnd Then
                        AppendLine warnMsg, "行" & r & ": アンカー開始が直前タスク計画終了より前です（計画重なり・警告のみ・生成続行）。"
                    End If
                End If
            Else
                If Not laneChainEnd.Exists(laneKey) Then
                    AppendLine errMsg, "行" & r & ": チェーン起点が不定です（先頭アンカー不足）。"
                    startMin = 0
                Else
                    startMin = CLng(laneChainEnd(laneKey))
                End If
            End If
        End If

        cellsNeeded = MinutesToCells(Val(mins))
        endMin = startMin + cellsNeeded * 5

        ' 論点A: 23:55超 → 警告のみ（描画は当日末までクリップ）
        If endMin > 23 * 60 + 55 Then
            AppendLine warnMsg, "行" & r & ": 計画終了が23:55を超えます（24時以内運用・警告のみ。描画は23:55まで）。"
            endMin = 23 * 60 + 55
        End If

        laneChainEnd(laneKey) = endMin

NextRow:
    Next r

    If Len(warnMsg) > 0 Then
        MsgBox "【警告】生成は続行します。" & vbCrLf & warnMsg, vbExclamation, "ValidateInput"
    End If
    If Len(errMsg) > 0 Then
        MsgBox "【エラー】生成を中断します。" & vbCrLf & errMsg, vbCritical, "ValidateInput"
        ValidateInput = False
        Exit Function
    End If

    ValidateInput = True
End Function

Private Sub AppendLine(ByRef buf As String, ByVal line As String)
    If Len(buf) = 0 Then
        buf = line
    Else
        buf = buf & vbCrLf & line
    End If
End Sub

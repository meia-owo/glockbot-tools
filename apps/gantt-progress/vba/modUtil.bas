Attribute VB_Name = "modUtil"
Option Explicit

' ============================================================
' modUtil.bas — 高速化制御 / 名前定義掃除 / 保護再設定
' UTF-8. VBA IDE へインポート時は文字コードに注意。
' ============================================================

Private mPrevScreenUpdating As Boolean
Private mPrevCalculation As XlCalculation
Private mPrevEnableEvents As Boolean
Private mSpeedDepth As Long

' 高速化三本柱 ON（ネスト対応）。呼び出し側は必ず On Error GoTo で SpeedOff を呼ぶこと。
Public Sub SpeedOn()
    If mSpeedDepth = 0 Then
        mPrevScreenUpdating = Application.ScreenUpdating
        mPrevCalculation = Application.Calculation
        mPrevEnableEvents = Application.EnableEvents
        Application.ScreenUpdating = False
        Application.Calculation = xlCalculationManual
        Application.EnableEvents = False
    End If
    mSpeedDepth = mSpeedDepth + 1
End Sub

' 高速化 OFF（ネスト解除時のみ実復帰）
Public Sub SpeedOff()
    If mSpeedDepth > 0 Then mSpeedDepth = mSpeedDepth - 1
    If mSpeedDepth = 0 Then
        Application.ScreenUpdating = mPrevScreenUpdating
        Application.Calculation = mPrevCalculation
        Application.EnableEvents = mPrevEnableEvents
    End If
End Sub

' エラー時強制復帰（深度を無視して元に戻す）
Public Sub SpeedForceRestore()
    On Error Resume Next
    mSpeedDepth = 0
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True
    On Error GoTo 0
End Sub

' Copy 後の不要名前定義削除（#REF! / 孤立）— ブック肥大化防止
Public Sub CleanNames()
    Dim nm As Name
    Dim i As Long
    On Error Resume Next
    For i = ThisWorkbook.Names.Count To 1 Step -1
        Set nm = ThisWorkbook.Names(i)
        If Not nm Is Nothing Then
            If InStr(1, nm.Value, "#REF!", vbTextCompare) > 0 Then
                nm.Delete
            ElseIf IsOrphanName(nm) Then
                nm.Delete
            End If
        End If
        Set nm = Nothing
    Next i
    On Error GoTo 0
End Sub

Private Function IsOrphanName(ByVal nm As Name) As Boolean
    ' 参照先シートが存在しない、または空参照の名前を孤立とみなす
    Dim ref As String
    On Error Resume Next
    ref = nm.RefersTo
    If Err.Number <> 0 Then
        IsOrphanName = True
        Err.Clear
        Exit Function
    End If
    If Len(ref) = 0 Or ref = "=" Then
        IsOrphanName = True
    End If
    On Error GoTo 0
End Function

' 全日付シート(YYYYMMDD)に UserInterfaceOnly 保護を再設定
' ※ UserInterfaceOnly はブックを閉じると失われるため Workbook_Open で必須
Public Sub ReProtect()
    Dim ws As Worksheet
    Dim nm As String
    On Error Resume Next
    For Each ws In ThisWorkbook.Worksheets
        nm = ws.Name
        If IsDateSheetName(nm) Then
            ws.Unprotect Password:=""
            ' 備考列 D-H はロック解除（現場追記許容）、他はロック
            ws.Cells.Locked = True
            ws.Range("D:H").Locked = False
            ws.Protect Password:="", UserInterfaceOnly:=True, _
                DrawingObjects:=False, Contents:=True, Scenarios:=True, _
                AllowFormattingCells:=False, AllowFormattingColumns:=True, _
                AllowFormattingRows:=True, AllowInsertingColumns:=False, _
                AllowInsertingRows:=False, AllowDeletingColumns:=False, _
                AllowDeletingRows:=False, AllowSorting:=False, _
                AllowFiltering:=False, AllowUsingPivotTables:=False
        End If
    Next ws
    On Error GoTo 0
End Sub

' YYYYMMDD (8桁数字) 判定
Public Function IsDateSheetName(ByVal sheetName As String) As Boolean
    Dim i As Long
    If Len(sheetName) <> 8 Then
        IsDateSheetName = False
        Exit Function
    End If
    For i = 1 To 8
        If Mid$(sheetName, i, 1) < "0" Or Mid$(sheetName, i, 1) > "9" Then
            IsDateSheetName = False
            Exit Function
        End If
    Next i
    IsDateSheetName = True
End Function

' 定数（列位置・色）— 他モジュールから参照
Public Const COL_INPUT_NO As Long = 1
Public Const COL_INPUT_DATE As Long = 2
Public Const COL_INPUT_LARGE As Long = 3
Public Const COL_INPUT_MID As Long = 4
Public Const COL_INPUT_SMALL As Long = 5
Public Const COL_INPUT_NOTE1 As Long = 6   ' F〜J = 備考1〜5（見出し文字列非依存）
Public Const COL_INPUT_NOTE5 As Long = 10
Public Const COL_INPUT_STARTTIME As Long = 11
Public Const COL_INPUT_MINUTES As Long = 12

Public Const COL_DATE_LARGE As Long = 1
Public Const COL_DATE_MID As Long = 2
Public Const COL_DATE_SMALL As Long = 3
Public Const COL_DATE_NOTE1 As Long = 4
Public Const COL_DATE_NOTE5 As Long = 8
Public Const COL_DATE_STATUS As Long = 9
Public Const COL_DATE_START As Long = 10   ' J 着工
Public Const COL_DATE_FINISH As Long = 11  ' K 完了
Public Const COL_DATE_TIME0 As Long = 12   ' L = 0:00
Public Const TIME_COL_COUNT As Long = 288  ' 0:00〜23:55 / 5分

' RGB 色（Interior.Color）
Public Function ColorPlan() As Long
    ColorPlan = RGB(200, 200, 200)       ' 計画線グレー
End Function

Public Function ColorInProgress() As Long
    ColorInProgress = RGB(255, 235, 59)  ' 着工中 黄
End Function

Public Function ColorDone() As Long
    ColorDone = RGB(129, 199, 132)       ' 完了 緑
End Function

' 時刻 → 列番号（L=0:00 起点）。5分刻み。範囲外は -1
Public Function TimeToCol(ByVal t As Date) As Long
    Dim totalMin As Long
    totalMin = Hour(t) * 60 + Minute(t)
    If totalMin < 0 Or totalMin > 23 * 60 + 55 Then
        TimeToCol = -1
        Exit Function
    End If
    TimeToCol = COL_DATE_TIME0 + (totalMin \ 5)
End Function

' 分 → 5分セル数（切り上げ）
Public Function MinutesToCells(ByVal minutes As Double) As Long
    Dim m As Long
    m = CLng(Application.WorksheetFunction.Ceiling(minutes, 5))
    If m < 5 And minutes > 0 Then m = 5
    MinutesToCells = m \ 5
End Function

' 列番号 → そのセル開始時刻（分）
Public Function ColToMinutes(ByVal col As Long) As Long
    ColToMinutes = (col - COL_DATE_TIME0) * 5
End Function

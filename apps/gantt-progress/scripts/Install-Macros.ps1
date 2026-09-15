<#
.SYNOPSIS
  GanttProgress_v3_TEMPLATE.xlsx に VBA モジュールをインポートし .xlsm として保存する。
.DESCRIPTION
  Windows + Excel (M365 推奨) で実行してください。
  1) このスクリプトと同じ階層の親にある vba\*.bas / ThisWorkbook コードを取り込み
  2) GanttProgress_v3.xlsm として保存
  注意: シートモジュールの BeforeDoubleClick は自動では各日付シートに付きません。
        生成後に vba\Worksheet_BeforeDoubleClick_snippet.bas を各日付シートへ貼ってください。
#>
[CmdletBinding()]
param(
    [string]$WorkbookPath = "",
    [string]$VbaDir = "",
    [string]$OutPath = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $WorkbookPath) { $WorkbookPath = Join-Path $Root "GanttProgress_v3_TEMPLATE.xlsx" }
if (-not $VbaDir) { $VbaDir = Join-Path $Root "vba" }
if (-not $OutPath) { $OutPath = Join-Path $Root "GanttProgress_v3.xlsm" }

if (-not (Test-Path $WorkbookPath)) { throw "Workbook not found: $WorkbookPath" }
if (-not (Test-Path $VbaDir)) { throw "VBA dir not found: $VbaDir" }

# Trust access to VBA project object model が必要
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $wb = $excel.Workbooks.Open((Resolve-Path $WorkbookPath).Path)
    $vbproj = $wb.VBProject

    $basFiles = @(
        "modUtil.bas",
        "modValidate.bas",
        "modGantt.bas",
        "modProgress.bas",
        "modMain.bas"
    )
    foreach ($f in $basFiles) {
        $path = Join-Path $VbaDir $f
        if (-not (Test-Path $path)) { throw "Missing $path" }
        Write-Host "Importing $f ..."
        $vbproj.VBComponents.Import((Resolve-Path $path).Path) | Out-Null
    }

    # ThisWorkbook code: replace existing ThisWorkbook module code
    $twPath = Join-Path $VbaDir "ThisWorkbook.cls"
    if (Test-Path $twPath) {
        Write-Host "Patching ThisWorkbook ..."
        $code = Get-Content -Path $twPath -Raw -Encoding UTF8
        # Strip CLASS header lines for CodeModule insert
        $lines = $code -split "`r?`n"
        $body = New-Object System.Collections.Generic.List[string]
        $skip = $true
        foreach ($line in $lines) {
            if ($line -match '^Option Explicit') { $skip = $false }
            if (-not $skip) { [void]$body.Add($line) }
        }
        $tw = $vbproj.VBComponents.Item("ThisWorkbook")
        $tw.CodeModule.DeleteLines(1, $tw.CodeModule.CountOfLines)
        $tw.CodeModule.AddFromString(($body -join "`r`n"))
    }

    # Save as xlsm (52 = xlOpenXMLWorkbookMacroEnabled)
    if (Test-Path $OutPath) { Remove-Item $OutPath -Force }
    $wb.SaveAs($OutPath, 52)
    $wb.Close($false)
    Write-Host "Saved: $OutPath"
    Write-Host ""
    Write-Host "次の手動手順:"
    Write-Host " 1. Input シートにフォームコントロールボタン『シート生成』→ GenerateSheets"
    Write-Host " 2. Dashboard に『更新』→ RefreshDashboard（任意）"
    Write-Host " 3. 日付シート生成後、各シートに Worksheet_BeforeDoubleClick_snippet.bas を貼付"
    Write-Host " 4. 日付シート上部に 着工/完了/記録取り消し/階層1-3 ボタンを配置"
}
finally {
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}

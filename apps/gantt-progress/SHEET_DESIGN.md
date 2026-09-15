# SHEET_DESIGN — ガント進捗 v3

版: GlockBOT 0.1.0

## 1. 列マップ

### Input（ヘッダ行 = 3、テーブル `InputTable`）

| 列 | 項目 | 必須 | VBA 参照 |
|----|------|------|----------|
| A | No | 自動 | `COL_INPUT_NO=1` |
| B | 日付 | ○ | `COL_INPUT_DATE=2` |
| C | 大項目（レーン） | ○ | `COL_INPUT_LARGE=3` |
| D | 中項目 | ○ | `COL_INPUT_MID=4` |
| E | 小項目 | ○ | `COL_INPUT_SMALL=5` |
| F–J | 備考1–5 | － | `COL_INPUT_NOTE1=6` … `NOTE5=10`（**見出し非依存・列位置固定**） |
| K | 開始時刻 | △ アンカー | `COL_INPUT_STARTTIME=11` |
| L | 総時間(分) | ○ | `COL_INPUT_MINUTES=12` |

注意書き: 行1。ボタン案内: 行2。

### Template / YYYYMMDD

| 列 | 項目 |
|----|------|
| A–C | 大項目・中項目・小項目 |
| D–H | 備考1–5（Input 見出しを転記。列グループ化可） |
| I | ステータス（未着手 / 着工中 / 完了） |
| J | 着工タイムスタンプ |
| K | 完了タイムスタンプ |
| L 以降 288 列 | 0:00–23:55（5 分刻み） |

- 行1: 時刻見出し（縦書き想定）
- 1 時間ごと（12 セル）に右太罫線
- ウィンドウ枠固定: `L2`（A–K + 見出し行）
- **名前定義なし**

### Log

| A | B | C | D | E |
|---|---|---|---|---|
| 日時 | シート名 | 行 | 操作種別 | タスク |

### Dashboard

- 全体進捗メモ、遅延タスク案内、日別サマリ（`RefreshDashboard` がハイパーリンクを A12 付近に再構築）

## 2. 色（Interior.Color / RGB）

| 用途 | RGB | 定数 |
|------|-----|------|
| 計画線 | (200, 200, 200) | `ColorPlan` |
| 着工中 | (255, 235, 59) | `ColorInProgress` |
| 完了 | (129, 199, 132) | `ColorDone` |

条件付き書式は使用しない。

## 3. バリデーション規則（`ValidateInput`）

| 規則 | 結果 |
|------|------|
| 日付・大中小・総時間(分)>0 | エラー → 生成中断 |
| 各 日付×大項目 の先頭に開始時刻 | エラー → 中断 |
| 日付の全体昇順 | エラー → 中断 |
| 開始時刻形式不正 | エラー → 中断 |
| アンカーが前タスク計画終了より前（重なり）論点 D | **警告のみ・続行** |
| 計画終了が 23:55 超 論点 A | **警告のみ・続行**（描画はクリップ） |

## 4. 計画線ロジック（`DrawPlanLines`）

- 大項目 = レーン。レーン内は記入順。
- 開始時刻あり → アンカー（チェーン起点リセット）
- 空欄 → 同一レーン直前タスクの計画終了から連結
- 総時間は 5 分切り上げセル数（例: 43 分 → 9 セル）
- **1 タスク = 1 回の `Range(...).Interior.Color`**（セルループ / Union 禁止）
- 論点 C: 実績記録後も計画線は引き直さない

## 5. モジュール・プロシージャ一覧

| モジュール | 主なプロシージャ |
|------------|------------------|
| `modUtil` | `SpeedOn`, `SpeedOff`, `SpeedForceRestore`, `CleanNames`, `ReProtect`, `IsDateSheetName`, `TimeToCol`, `MinutesToCells`, 色/列定数 |
| `modValidate` | `ValidateInput` |
| `modGantt` | `DrawPlanLines` |
| `modProgress` | `RecordStart`, `RecordFinish`, `UndoLast`, `ButtonRecordStart/Finish`, `ButtonUndoLast`, `ShowLevel1/2/3` |
| `modMain` | `GenerateSheets`, `RefreshDashboard`, `BuildDashboardLinks` |
| `ThisWorkbook` | `Workbook_Open` → `ReProtect` |
| 日付シート | `Worksheet_BeforeDoubleClick`（スニペット貼付） |

## 6. GenerateSheets 処理順

1. `ValidateInput`
2. ユニーク日付抽出・昇順
3. Input No 採番
4. 各日: 既存確認（上書き/スキップ/中断）→ Template Copy → 備考見出し転記 → 行書き込み → Outline（`AutomaticStyles=False`）→ `DrawPlanLines` → 保護
5. シート並び替え、Template/Log 再非表示
6. `CleanNames`

## 7. 保護

- 日付シート: `Protect UserInterfaceOnly:=True`
- ロック解除: 備考 D–H のみ
- `Workbook_Open` で全日付シートに再設定

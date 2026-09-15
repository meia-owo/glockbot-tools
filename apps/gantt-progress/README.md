# ガントチャート進捗管理ツール v3

版: GlockBOT 0.1.0

Input シートにタスクを時系列で記入し、「シート生成」で日付ごとの 5 分刻みガントシートを自動生成するマクロ有効ブック向け成果物です。

## .xlsm 直接生成の状態

| 項目 | 状態 |
|------|------|
| シート骨格 `.xlsx` | **生成済み** (`GanttProgress_v3_TEMPLATE.xlsx`) |
| VBA ソース一式 | **生成済み** (`vba/*.bas`, `vba/*.cls`) |
| マクロ入り `.xlsm` | **未生成（不可）** |

**理由:** 本環境は Linux で Microsoft Excel / `vbaProject.bin` 署名付き生成手段がありません。偽のマクロバイナリは作成していません。Windows 上の Excel でモジュールをインポートし `.xlsm` 保存してください。

## 成果物一覧

```
apps/gantt-progress-v3/
├── GanttProgress_v3_TEMPLATE.xlsx   # Dashboard / Input / Template / Log
├── README.md
├── SHEET_DESIGN.md
├── vba/
│   ├── modUtil.bas
│   ├── modValidate.bas
│   ├── modGantt.bas
│   ├── modProgress.bas
│   ├── modMain.bas
│   ├── ThisWorkbook.cls
│   ├── SheetDateEvents.cls          # 説明用スタブ
│   └── Worksheet_BeforeDoubleClick_snippet.bas
└── scripts/
    ├── build_workbook.py
    ├── Install-Macros.ps1           # Windows Excel で .xlsm 化
    ├── ImportVba.bas
    └── self_check.py
```

## シート構成

| シート | 役割 | 備考 |
|--------|------|------|
| Dashboard | 全体進捗・遅延・日別サマリ | 固定。数式中心 + `RefreshDashboard` |
| Input | タスク台帳（ListObject） | 固定。「シート生成」→ `GenerateSheets` |
| Template | 日付シート雛形（288 列） | **非表示・名前定義なし** |
| Log | 操作履歴 | 非表示 |
| YYYYMMDD | 日別ガント | Template を Copy して生成 |

## Windows Excel での組み立て手順

### 前提
- Microsoft 365 版 Excel 推奨（スピル / `CountLarge`）
- **開発** タブ → 「VBA プロジェクト オブジェクト モデルへのアクセスを信頼する」を有効化（PowerShell 自動インポート時）

### A. PowerShell 自動（推奨）

1. 本フォルダを Windows にコピー
2. PowerShell で:

```powershell
cd ...\gantt-progress-v3\scripts
.\Install-Macros.ps1
```

3. 生成された `GanttProgress_v3.xlsm` を開く

### B. 手動インポート

1. `GanttProgress_v3_TEMPLATE.xlsx` を開き、名前を付けて保存で `.xlsm` に変更
2. Alt+F11 → ファイル → ファイルのインポート  
   - `modUtil.bas` / `modValidate.bas` / `modGantt.bas` / `modProgress.bas` / `modMain.bas`
3. `ThisWorkbook` に `Workbook_Open`（`vba/ThisWorkbook.cls` の本体）を貼付
4. UTF-8 の文字化け時はメモ帳で ANSI/Shift_JIS 保存してから再インポート、または IDE 上で日本語を修正

### ボタン割り当て

| 場所 | ボタン表示 | 割り当てマクロ |
|------|------------|----------------|
| Input | シート生成 | `GenerateSheets` |
| Dashboard | 更新 | `RefreshDashboard` |
| 各日付シート | 着工 / 完了 / 記録取り消し | `ButtonRecordStart` / `ButtonRecordFinish` / `ButtonUndoLast` |
| 各日付シート | 階層1 / 2 / 3 | `ShowLevel1` / `ShowLevel2` / `ShowLevel3` |

フォームコントロール（推奨）または図形のマクロ登録で配置。

### 日付シートのダブルクリック

`GenerateSheets` はシート Copy のみ行い、**イベントコードは自動コピーされません**。  
各 `YYYYMMDD` シートのシートモジュールに  
`vba/Worksheet_BeforeDoubleClick_snippet.bas` の内容を貼り付けてください。

- J 列ダブルクリック → 着工（`Cancel = True`）
- K 列ダブルクリック → 完了

## Input の使い方

1. テーブル（`InputTable`）に追記。列位置は固定:
   - A No（自動） B 日付* C 大項目* D 中項目* E 小項目*  
   - F–J 備考1–5（見出しリネーム可） K 開始時刻（アンカー） L 総時間(分)*
2. **大項目（レーン）ごと**に時系列順。先頭タスクには必ず開始時刻。
3. 複数アンカー可（例: 昼休み後 13:00）。空欄行はチェーン（直前計画終了から連結）。
4. 「シート生成」実行。

## 進捗記録

- 主: J/K 列ダブルクリック → 確認ダイアログ → `Now` 記録・ステータス更新・実績色
- 副: 上部ボタン（選択行。`CountLarge > 1` は拒否）
- 取消: 「記録取り消し」→ Log に履歴

計画線は実績で引き直しません（論点 C）。

## 採用論点

| 論点 | 採用 |
|------|------|
| A 日またぎ | 警告のみ。描画は 23:55 までクリップ |
| C 実績で計画再描画 | しない（計画固定） |
| D 計画重なり | 警告のみ・生成続行 |

## 性能ルール（実装済み）

- `SpeedOn` / `SpeedOff`（ScreenUpdating / Calculation / EnableEvents）+ エラー時復帰
- 計画・実績色は **連続 Range 一括**（セルループ・Union 大量結合なし）
- 条件付き書式は使わない
- Copy 後 `CleanNames`
- `Workbook_Open` → `ReProtect`（`UserInterfaceOnly:=True`）

## 既知の制限

1. Linux 上ではマクロ入り `.xlsm` を本物として生成できない
2. 日付シートの `BeforeDoubleClick` は生成後の手貼りが必要
3. UndoLast の色復元は簡易（完全な計画再描画は将来機能）
4. Dashboard の遅延一覧はプレースホルダ（M365 数式で拡張想定）
5. 500 行 × 288 列 × 複数日の実測は未実施（Windows 側で検証）
6. VBA ソースは UTF-8。IDE インポートで日本語が化ける場合あり

## セルフチェック

```bash
./.venv/bin/python scripts/self_check.py
```

## 再ビルド（xlsx のみ）

```bash
./.venv/bin/python scripts/build_workbook.py
```

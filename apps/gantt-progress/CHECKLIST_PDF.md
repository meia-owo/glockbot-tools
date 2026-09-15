# PDF v3 要件チェックリスト

| # | 要件 | 状態 |
|---|------|------|
| 1 | Dashboard / Input / Template / Log / YYYYMMDD | xlsx 骨格 + VBA 生成ロジック |
| 2 | CSV 廃止・Input 直接記入 | 済（サンプル14行） |
| 3 | 備考1–5（F–J）、見出しリネーム可・列位置参照 | 済 |
| 4 | ListObject テーブル | 済 InputTable |
| 5 | シート生成ボタン → GenerateSheets | VBA 済・ボタンは手動配置 |
| 6 | バリデーション（必須・先頭アンカー・日付順） | 済 |
| 7 | 論点A 23:55超 警告 | 済（警告のみ・描画クリップ） |
| 8 | 論点C 計画固定 | 済（再描画なし） |
| 9 | 論点D 重なり警告のみ続行 | 済 |
| 10 | アンカー＋チェーン・大項目レーン・複数アンカー | 済 DrawPlanLines |
| 11 | 5分切り上げ・1タスク1 Range 塗り | 済 |
| 12 | Template 288列・枠固定・時間見出し・時間太罫 | 済 |
| 13 | Template 名前定義なし・Copy後 CleanNames | 済 |
| 14 | Outline AutomaticStyles=False | 済 |
| 15 | ダブルクリック J/K・Cancel=True | スニペット提供（手貼り） |
| 16 | RecordStart/Finish/UndoLast・確認・Log | 済 |
| 17 | CountLarge 複数選択ガード | 済 |
| 18 | UserInterfaceOnly + Workbook_Open ReProtect | 済 |
| 19 | SpeedOn/Off エラー復帰 | 済 |
| 20 | 条件付き書式不使用 | 済 |
| 21 | 実マクロ .xlsm | **未（Linux 制約）** — Install-Macros.ps1 で組み立て |

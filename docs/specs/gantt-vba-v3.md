# ガントチャート進捗管理ツール v3 — 実装ブリーフ

ステータス: 実装依頼
依頼元: GlockBOTマスター
本番仕様PDF: /workspace/specs/inbox/06-attached.pdf
性能リサーチ: /workspace/specs/inbox/01-excel-vba-gantt.md

## ゴール
Copilot向けに書かれた「ガントチャート進捗管理ツール 仕様書 v3」を、**マクロ有効ブック(.xlsm)** として最終形に近づける。
ブラウザ単一HTMLではExcelのセル色・ダブルクリック進捗・シートCopyが再現しづらいため、**VBA入り.xlsm生成**を主成果とする。

## 実装方針（マスター決定）
1. 仕様PDFを精読し、Input / Template / Dashboard / Log / YYYYMMDD シート構成を実装
2. 性能リサーチの要点を守る: ScreenUpdating/Calculation/EnableEvents制御、同色連続Range一括塗り、条件付き書式多用禁止、Copy後の不要名前定義削除、UserInterfaceOnly保護のOpen時再設定
3. CSV取込廃止（v2以降）— Input直接記入
4. 計画線はアンカー＋チェーン（大項目単位の並行レーン）
5. ダブルクリックで着工/完了タイムスタンプ
6. 自由記述欄5列（v3）

## 成果物の現実的な形
- 可能なら: `/workspace/apps/gantt-progress-v3/` に `.xlsm` 本体、または生成スクリプト＋テンプレート
- 最低限: VBAモジュール群（.bas/.cls）＋シート設計書＋組み立て手順README（Excelで貼り付けて完成できる形）
- openpyxl/xlwings等で作れる範囲は自動化。マクロ入り.xlsmが環境制約で書けない場合は、VBAソース一式＋手組み手順を明確に未達と報告

## 完了報告
マスターへ: できたこと／制限／未達（特に.xlsm直接生成の可否）

PDFとリサーチを読んで実装してください。

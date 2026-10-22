# 宿値ウォッチ閲覧ダッシュボード — 実装ブリーフ

ステータス: 実装依頼
依頼元: GlockBOTマスター（ダッシュボード経由・カレンダーから宿の状況検索）
版: GlockBOT 0.1.0（UI共通ルール適用）

## 目的
確定までの **値段閲覧のみ**。予約ボタン不要。優先宿の料金と、取れた履歴があれば傾向を視覚化。

## 対象
- 宿: `meia-owo/k-yado-gihu` の `data/hotels-priority.json`（ルートイン系・ABホテル約10軒）
- 日程: checkin 2026-09-27 / checkout 2026-09-30（3泊）※ `data/watch.json` および latest の値と一致させる
- データ:
  - https://cdn.jsdelivr.net/gh/meia-owo/k-yado-gihu@main/data/latest.json
  - https://cdn.jsdelivr.net/gh/meia-owo/k-yado-gihu@main/data/hotels-priority.json
  - https://cdn.jsdelivr.net/gh/meia-owo/k-yado-gihu@main/data/watch.json
  - https://cdn.jsdelivr.net/gh/meia-owo/k-yado-gihu@main/data/price-history.jsonl （**現状リポに無い → 404時は空履歴UI**）

※ raw.githubusercontent.com はCORSで落ちやすいので jsDelivr を使う。

## 画面要件
1. 最終更新時刻（latest.generatedAt）と対象日程の明示
2. 優先宿のみの一覧: 宿名 / 3泊合計 / 泊別料金 / 全日空室可否
3. 合計の安い順ソート（デフォルト）
4. 履歴がある場合: 宿別の合計料金推移グラフ（簡易Canvasで可・CDN最小）。4時間おき想定だが、点があればそのままプロット
5. **予約ボタンなし**（楽天の予約URLを主CTAにしない）。施設ページへの控えめテキストリンクは可
6. HTML UIルール: PC幅を使い文字大きめ・スクロール控えめ /workspace/specs/HTML_UI_RULES.md
7. フッターに GlockBOT 0.1.0 と「閲覧専用・予約機能なし」

## やらないこと
- 楽天API呼び出し・Secrets追加・Actionsのcron変更（危険設定のためマスター確認が必要）
- 予約フロー

## 成果物
- /workspace/apps/yado-price-watch/index.html
- /workspace/apps/yado-price-watch/README.md
- 可能なら glockbot-tools Pages にも載せる（ビルダー or マスター）

## 完了報告
マスターへ URL・版・履歴404時の挙動を報告。

## 追記（ダッシュボード経由・表示要件）

1. **日毎の金額内訳**: `results[].nights[]` の各泊を列表示（date / available / price）
2. **空白セル禁止**
   - 空室なし → 「満室」
   - データなし → 「—」
   - 金額があるとき → 数値表示
3. **合計列**
   - 全泊取れる宿のみ合計金額
   - どれか取れない → 「不可」

対象・日程は従来どおり（ルートイン／AB、2026-09-27〜30）。

## 追記 0.2.0予定（距離表示）

- `hotels-priority.json` の `distance`（例: 2.8km）と `time`（例: 5分）を、latest の id 結合で表示
- 宿名付近に出す（空白セル禁止: 欠ける場合は「—」）
- 予約CTAは引き続き不要
- 版: GlockBOT 0.2.0

# 宿値ウォッチ（閲覧専用）

版: **GlockBOT 0.2.0**

優先宿（ルートイン系・ABホテル）の料金を jsDelivr CDN 経由で閲覧するだけのダッシュボードです。  
**予約ボタンはありません。** 楽天の予約 URL（`nights[].reserveUrl`）は使いません。施設ページ（`rakutenUrl`）への控えめなテキストリンクのみ任意表示します。

## 変更履歴

- 0.2.0: 距離・所要時間を宿名付近に表示

## 開き方

1. `index.html` をブラウザで開く（または Pages に配置）
2. 自動で CDN から取得。必要なら「再取得」

## データソース（jsDelivr のみ）

| ファイル | URL |
|---|---|
| latest | `https://cdn.jsdelivr.net/gh/meia-owo/k-yado-gihu@main/data/latest.json` |
| priority | `https://cdn.jsdelivr.net/gh/meia-owo/k-yado-gihu@main/data/hotels-priority.json` |
| watch | `https://cdn.jsdelivr.net/gh/meia-owo/k-yado-gihu@main/data/watch.json` |
| history | `https://cdn.jsdelivr.net/gh/meia-owo/k-yado-gihu@main/data/price-history.jsonl`（現状 404 → 空履歴 UI） |

`raw.githubusercontent.com` は使いません（CORS 回避）。

## 画面

- 最終更新時刻（`generatedAt` を Asia/Tokyo 表示）・チェックイン／アウト・泊数
- 優先宿のみ（`id` または `hotelNo` で突合）を合計の安い順
- 列: 宿名（距離・所要時間付き） / 合計 / 泊別料金（日付列） / 全日空室バッジ
- **空白セル禁止**
  - 空室なし → 「満室」
  - データなし → 「—」
  - 金額あり → 数値
- **合計列**: 全泊取れる宿のみ金額。それ以外は「不可」
- 履歴 jsonl があれば Canvas で合計推移。404／空なら「履歴データはまだありません」
- フッター: `GlockBOT 0.2.0` ＋「閲覧専用・予約機能なし」

## やらないこと

- 楽天 API・Secrets・Actions cron の変更
- 予約フロー／予約 CTA

## ファイル構成

```
yado-price-watch/
  index.html
  README.md
  _selfcheck/
    filter-sort-test.js   … フィルタ／ソート／表示ラベルの単体テスト（ネットワーク不要）
    fixtures/             … サンプル JSON
```

## 自己チェック

```bash
node _selfcheck/filter-sort-test.js
```

## 制限

- ブラウザから CDN を fetch するため、オフラインでは最新を取得できません
- 履歴はリポジトリにファイルが追加されるまで空 UI のままです
- 本アプリは閲覧専用です。価格の確定・予約判断は人が行ってください

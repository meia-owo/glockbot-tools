# GlockBOT Tools（確認用）

こっこsan の GlockBOT 成果物を **GitHub Pages** で確認するための公開リポジトリです。


## Excelの取り方（チャットを遡らない）

1. **いちばん簡単**: [Releases（最新）](https://github.com/meia-owo/glockbot-tools/releases/latest) から xlsx をダウンロード
2. **Pages一覧の上部**「Excel・ダウンロード」からも同じ
3. リポ内パス: `apps/gantt-progress/GanttProgress_v3_TEMPLATE.xlsx`

## 見る場所

Pages 有効化後のトップ（例）:

`https://meia-owo.github.io/glockbot-tools/`

## 安全について（大事）

- **公開リポジトリ**です。誰でも中身を読めます
- パスワード・APIキー・社外秘データはリポジトリに入れません
- 各HTMLは基本的にブラウザ内だけで動きます（サーバに業務データを送らない設計）
- 「上司報告」の任意AIモードだけ、使うと自分の入力が Anthropic に送られます。社内ではオフラインモード推奨
- GitHub Actions・新しい外部連携・権限の広いトークンは、**こっこsanの確認なしでは追加しません**

## 中身

| パス | 内容 |
|------|------|
| `apps/yaskawa-diff-check/` | 安川差分チェック |
| `apps/quote-unitprice-db/` | 見積単価DB |
| `apps/teams-heat-ambiguity/` | Teams熱量・曖昧度 |
| `apps/boss-report-assistant/` | 上司報告攻略 |
| `apps/kawasaki-bxp-load-screen/` | 川崎BXP負荷スクリーニング |
| `apps/mail-task-explorer/` | メールタスクエクスプローラー |
| `apps/yado-price-watch/` | 宿値ウォッチ（閲覧専用） |
| `apps/gantt-progress/` | ガント（Excelパッケージ） |

版番号は各アプリの README / フッター（GlockBOT 0.1.0〜）。

# GlockBOT Tools（確認用）

こっこsan の GlockBOT 成果物を **GitHub Pages** で確認するための公開リポジトリです。

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
| `apps/gantt-progress/` | ガント（Excelパッケージ） |

版番号は各アプリの README / フッター（GlockBOT 0.1.0〜）。

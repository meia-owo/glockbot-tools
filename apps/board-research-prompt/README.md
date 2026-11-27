# 掲示板リサーチ用プロンプト作成ツール

**GlockBOT 0.1.1**

探したいこと・探す場所・キーワードなどを入力すると、会社の Copilot Chat や Gemini にそのまま貼れるリサーチ依頼文を組み立てます。

データはサーバへ送りません。外部 CDN なし（フォルダごと開けば `file://` でも動作）。

## 使い方

1. `index.html` をブラウザで開く（ネットワーク不要）
2. 探したいこと、場所、キーワード、期間、件数、持ち帰る項目を入れる
3. 下の「依頼文をコピー」を押して、Copilot Chat や Gemini に貼る
4. コピーに失敗したら、依頼文が選択されるので手動でコピーする

空欄の項目は依頼文から省きます。社名・品番・実際の数値は入れないでください。

## ファイル構成

```
board-research-prompt/
  index.html            … 画面
  build-prompt.js       … 依頼文の組み立て（純関数、ブラウザ/Node 共用）
  build-prompt.test.js  … Node の小テスト
  README.md
```

## 自己検査

```bash
node apps/board-research-prompt/build-prompt.test.js
```

## 版

GlockBOT 0.1.1

- 0.1.1: 期間・件数を text+inputmode=numeric に。IME確定の誤追加を防止。コピー表示タイマーを張り直し
- 0.1.0: 初回。依頼文の組み立てとコピー

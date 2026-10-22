# 上司報告攻略ツール — 実装ブリーフ（再設計）

ステータス: 実装依頼
依頼元: GlockBOTマスター
原ソース（React原型）: /workspace/specs/inbox/07-boss-report-assistant.txt

## 背景
Claude単体時代のReact原型。Anthropic APIをフロントから直呼びしており、社内・GitHub公開・ローカル利用には不向き。最終形として作り直す。

## ゴール
メモ／会議テキストから「報告の4要素チェック → 報告文 → パワポ構成＋台本」を整えるツールを、**単一HTML**で完成させる。

## 再設計方針（マスター決定）
1. **デフォルトはオフライン完結モード**
   - 4要素チェックリスト（人手で不足を埋めるフォーム）
   - テンプレート組み立てで報告文・スライド構成案を生成（プロンプト定義の構造をUIに焼き込む）
   - コピー用テキスト出力（報告文／スライド台本／撮影リスト）
2. **任意のAIモード**（あれば）
   - ユーザーが自分のAPIキーを入力して呼ぶ方式のみ（キーはlocalStorageに保存するか都度入力、コードにハードコード禁止）
   - 社内利用ではオフラインモードを推奨とREADME明記
3. Reactビルド不要。単一HTML+CSS+JS。CDN最小限。
4. 原ソースの CHECK_PROMPT / GENERATE_PROMPT / SLIDES_PROMPT の4要素・出力JSONスキーマを踏襲。

## 成果物
- /workspace/apps/boss-report-assistant/index.html
- /workspace/apps/boss-report-assistant/README.md

## 完了報告
マスターへ: できたこと／制限／未達

原ソース全文は inbox を参照。

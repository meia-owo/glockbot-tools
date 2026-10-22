# スマスロ天井メモ 0.3.5 — G直入ブランク＋示唆参考画像

ステータス: **0.3.5 完成**  
親: `/workspace/specs/smaslo-ceiling-memo-0.3-yabachiba-logs.md`  
版: GlockBOT **0.3.5**  
依頼: こっこsan（G直入の前数字消しが面倒／示唆演出が分かりづらい）

## 目的
1. **G直入**: フォーカス時にフィールドを空にして打ちやすくする（空適用で G=0 にしない）
2. **示唆早見／ピッカー**: 照合用の参考画像をカードに添える（個人用・非商用・公式ではない）

## Feature 1 — G直入 blank-on-focus
- focus: `#gInput` を空文字にし `gInputEditing=true`（`states[].g` はまだ変えない）
- `render()` は `gInputEditing` 中は `#gInput.value` を上書きしない
- blur / 反映 / Enter:
  - 空 or 非数 → 表示だけ現在 G に戻す（setG しない・undo しない）
  - 数あり → 既存 `setG` 経路。成功後 blur・表示は新 G
- 空を `clampInt` 経由で 0 にしない

## Feature 2 — 示唆参考画像
- hint に任意 `img` / `imgAlt`（＋既存 `visual` 模式図フォールバック）
- 画像は `assets/hints/*.webp`（相対パス・file:// / Pages 両対応）
- 示唆早見カード・ピッカーに表示
- 脚注: 「参考画像（個人用・照合用・公式ではない）」
- 南国SPECIALを優先（リールフラッシュ色・さざなみ・PUSH・SPECIAL LUCKY 等）。ヤバチバ／チバリヨ2はランプ系を可能な範囲で

## やらないこと
- CDN・fetch・外部依存の実行時読込
- 「設定○です」断定 UI
- LS キー／セットログ意味の変更

## 検証
```bash
node apps/smaslo-ceiling-memo/_selfcheck/run.js
```

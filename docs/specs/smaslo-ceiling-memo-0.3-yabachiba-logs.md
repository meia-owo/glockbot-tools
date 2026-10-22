# スマスロ天井メモ 0.3 — ヤバチバ セット／示唆ログ＋入力QoL

ステータス: **0.3.0 完成**  
親: `/workspace/specs/smaslo-ceiling-memo-0.2.1-hint-log.md`  
依頼元: GlockBOTマスター（こっこsan）／承認「実装よろ」  
版: GlockBOT **0.3.0**  
参照UI: `/workspace/specs/HTML_UI_RULES.md`

## 目的
南国SPECIALに入っている **初当たりセット／連チャン／スルー** と **示唆ログ**を、ヤバチバタブでも使えるようにする。  
あわせて G 直入の押しやすさ・カウンタ Undo・export／リセットの衛生を整える。

## スコープ
- ヤバチバ: セットログ＋示唆ログ（既存 `hints[]` を選択肢の正）
- 南国: 挙動維持（キー不変・回帰）
- チバリヨ2: セットUI出さない（`setLog.enabled` なし）
- G直入＋「反映」、全タブ「1つ戻す」、JSON に v2 sets を含める、リセット文言

## やらないこと
- 新ヒント意味・天井+α・設定3等の未検証解析データ
- 台番号単位の複数台記録
- チバリヨ2へのセット展開（無料で無害なら可だがデフォルト無効）
- 南国スルー定義の変更

## localStorage
```
smaslo-ceiling-memo:v1:<machineId>       # 天井カウンタ（壊さない）
smaslo-ceiling-memo:v1:activeTab
smaslo-ceiling-memo:v2:<machineId>:sets  # セット＋示唆
smaslo-ceiling-memo:v2:nangoku-sp:sets   # 0.2 からキー不変（既存データ継続）
smaslo-ceiling-memo:v2:yabachiba:sets    # 0.3 追加
```

データ形は 0.2.1 と同じ（`hintEvents` / `waitingHints` / `openSegment`）。  
`firstHitSuika` フィールドは任意の第2カウンタ値スナップショットとして両機種で共用（UIラベルは機種の c2 名）。

## 機種フラグ
```js
MACHINES[id].setLog = {
  enabled: true,
  endStyle: "hisho" | "simple",
  throughHelp: "短文ヘルプ"
}
```
- 南国: `endStyle: "hisho"`
- ヤバチバ: `endStyle: "simple"`

## ヤバチバのセット終了／スルー定義（決定）
飛翔概念はない。機械内部モードをアプリが断定しない。

| 操作 | 結果 |
|---|---|
| **セット終了** | セットを閉じる。`linkedHisho = (renchanCount === 1) ? false : true` |
| **やめた（判定保留）** | `linkedHisho = null` |
| ボーナス追加 | `[+ BIG] [+ REG]`（中立ラベル） |

**スルー（ヤバチバ）** = 終了セットのうち **連チャン数 === 1**（初当ボーナスのみで終わった記録）の件数。  
`linkedHisho === false` として集計（南国と同じ集計関数）。  
`linkedHisho === true` の表示ラベルは **「連あり」**（南国の「飛翔」と区別）。

これは「連が続かなかったセット数」の正直な記録であり、AT突入や内部状態の断定ではない。UIヘルプに明記。

## 示唆ログ
0.2.1 と同じ区間規則をヤバチバでも使用:
- 初当 → `after-start`（1連目中）
- ボーナス追加 → `between-n-(n+1)`
- セット終了 → `waitingHints`（post-set／通常待ち）
- 次初当で waiting を前セットへアーカイブ

選択肢はヤバチバ既存 `hints[]`（花笠／バックランプ／トップランプ／虹7）。新カタログ追加なし。  
「この行をログへ」を示唆早見に表示。

## 入力 QoL
- **G直入**: 大きめ number + `inputmode=numeric` + 「反映」（Enter可）。スライダー・±1/±10 維持
- **1つ戻す**: 機種別スタック最大10。対象は G と第2カウンタのみ（セット操作は対象外）

## Export / リセット
- JSON 書出: `{ version, activeTab, machines, sets: { "nangoku-sp":..., "yabachiba":... } }`
- JSON 読込: `sets` があれば機種別に正規化して v2 キーへ保存
- 当該機種リセット: カウンタをクリアすると明記。セット有効機種は続けてセット全クリアするか確認

## 成果物
- `apps/smaslo-ceiling-memo/index.html`（0.3.0）
- README / VERSION / selfcheck 拡張
- Pages 更新
- スクショ: `30-yabachiba-set-active.png` / `31-yabachiba-ended-detail.png` / `32-yabachiba-input-undo.png` / 任意 `33-nangoku-regression.png`

## 完了報告チェック
- 南国キー不変・スルー定義不変
- ヤバチバ: セット終了で連1→スルー／連2+→連あり
- 示唆区間がボーナスで切れる／セット後通常待ち可
- Undo・G反映・export sets・リセット確認
- selfcheck PASS・断定UIなし

# 軽井沢→荘川 旅ピンマップ（trip-pin-base）

版: **trip-pin-base 0.5.0**（GlockBOT）

岡崎発着・2泊3日（2026-10-30〜11-01）の確定宿＋立ち寄りを Leaflet 地図と時系列サマリーで閲覧する静的アプリ。

正の仕様: `/workspace/specs/takayama-hotel-map-0.4.0-day3-return.md`（Day1 は `takayama-hotel-map-0.3.1-day1-route.md`）  
Pages: https://meia-owo.github.io/glockbot-tools/apps/takayama-hotel-map/

## 開き方

1. `index.html` をブラウザで開く（Leaflet CDN 使用）
2. または GitHub Pages 上記 URL

## タブ

| タブ | 内容 |
|---|---|
| **地図** | 左リスト＋Leaflet 地図。ピン focus / Google Maps・楽天リンク |
| **時系列**（初期・0.4.1〜） | 旅程概要＋Day1〜Day3 の時刻順カード。予約番号・差引金額・夕食B・アメニティ。Day3 帰路（ちこり村→恵那川上屋 恵那峡店→瑞浪 瑞喜舎→岡崎）を区間所要つきで表示 |

時系列は**日別アコーディオン**（Day見出し＝日付・曜日・区間・宿、件数表示、複数同時に開ける、「すべて開く/閉じる」）。初期: 今日(JST)が旅行日ならその日、それ以外は Day1 を開く（`?day=1〜3` で指定可）。

初期表示は時系列タブ（タブ順も 時系列→地図）。`#map` 付きURLのみ地図タブで開く。localStorage での記憶なし。地図は初回表示時に invalidateSize＋全ピン fit。

「地図で見る」で地図タブへ切替＋当該ピン focus（setView + openPopup + リスト active）。

## Day1（0.3.1）

手書きルート反映: AM5岡崎出発 → 153号 → 香嵐渓 → 信州平谷道の駅 → 飯田IC→諏訪IC → 152号 → 白樺湖 → 長門牧場（ピザ） → 運転メモ → 旧軽井沢銀座散策 → ハルニレテラス → グリーンプラザ軽井沢 CI 17:30。

## Day3（0.4.0）

10:00 龍リゾートCO → 東海北陸道・東海環状・中央道（約145km・約2h）→ ちこり村（ランチ約60分）→ 恵那川上屋 恵那峡店（約45分）→ 瑞浪市薬師町1-1 恵那川上屋 瑞喜舎 瑞浪店（約30分）→ 中央道・東海環状・東名 → 岡崎 16:15〜16:30頃（渋滞なし推定）。

## 版履歴（要点）

| 版 | 内容 |
|---|---|
| 0.1.0 | 確定宿ピンベース |
| 0.2.0 | 行程立ち寄りピン追加 |
| 0.3.0 | 時系列サマリー別タブ |
| 0.3.1 | Day1 手書きルート反映（香嵐渓・平谷道の駅・白樺湖・ハルニレ追加／銀座置換） |
| 0.5.0 | 時系列を日別アコーディオン化・すべて開く/閉じる・タップ領域拡大・ワイド画面で幅/文字拡大・「地図で見る」初回フォーカス不具合修正 |
| 0.4.1 | 初期表示を時系列タブに変更（タブ順入替・`#map` ハッシュ対応・地図は初回表示時に fit） |
| 0.4.0 | Day3 帰路ルート＋立ち寄り3件・岡崎帰着ref・区間所要（実ルーティング推定） |

## スクショ

`screenshots/30-tab-map.png` / `screenshots/31-tab-timeline.png`（0.3.0）  
`screenshots/32-tab-map-day1.png` / `screenshots/33-tab-timeline-day1.png`（0.3.1）  
`screenshots/34-tab-map-day3.png` / `screenshots/35-tab-timeline-day3.png`（0.4.0）  
`screenshots/36-default-timeline.png` / `screenshots/37-switch-to-map.png`（0.4.1）  
`screenshots/38-live-timeline-accordion.png`（0.5.0・公開URL）

# 軽井沢→荘川 旅ピンマップ（trip-pin-base）

版: **trip-pin-base 0.3.0**（GlockBOT）

岡崎発着・2泊3日（2026-10-30〜11-01）の確定宿＋立ち寄りを Leaflet 地図と時系列サマリーで閲覧する静的アプリ。

正の仕様: `/workspace/specs/takayama-hotel-map-0.3-timeline-tab.md`  
Pages: https://meia-owo.github.io/glockbot-tools/apps/takayama-hotel-map/

## 開き方

1. `index.html` をブラウザで開く（Leaflet CDN 使用）
2. または GitHub Pages 上記 URL

## タブ

| タブ | 内容 |
|---|---|
| **地図**（初期） | 左リスト＋Leaflet 地図。ピン focus / Google Maps・楽天リンク |
| **時系列** | 旅程概要＋Day1〜Day3 の時刻順カード。予約番号・差引金額・夕食B・アメニティ。Day3 立ち寄りは空欄（未定）を明示 |

「地図で見る」で地図タブへ切替＋当該ピン focus（setView + openPopup + リスト active）。

## 版履歴（要点）

| 版 | 内容 |
|---|---|
| 0.1.0 | 確定宿ピンベース |
| 0.2.0 | 行程立ち寄りピン追加 |
| 0.3.0 | 時系列サマリー別タブ |

## スクショ

`screenshots/30-tab-map.png` / `screenshots/31-tab-timeline.png`

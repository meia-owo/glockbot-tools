// node apps/takayama-hotel-map/trip-status.test.js
const assert = require('assert');
const { parseTime, computeStatuses } = require('./trip-status.js');

assert.deepStrictEqual(parseTime('12:20頃〜13:20頃（約60分）'), { start: 740, end: 800, tentative: false });
assert.deepStrictEqual(parseTime('8:30頃（仮）CO → 移動'), { start: 510, end: null, tentative: true });
assert.deepStrictEqual(parseTime('AM 5時'), { start: 300, end: null, tentative: false });
assert.deepStrictEqual(parseTime('立ち寄り'), { start: null, end: null, tentative: false });

const dates = { 1: '2026-10-30', 2: '2026-10-31', 3: '2026-11-01' };
const stops = [
  { day: 1, start: null }, { day: 1, start: 1050 },                 // D1: 時刻なし, 17:30
  { day: 2, start: 510 }, { day: 2, start: 750 }, { day: 2, start: 840 }, // D2: 8:30, 12:30, 14:00
  { day: 3, start: 600 }
];
// Day2 13:00 → D1 済 / 8:30・12:30 済 / 14:00 次 / D3 これから
assert.deepStrictEqual(computeStatuses(stops, dates, '2026-10-31', 780),
  ['done', 'done', 'done', 'done', 'next', 'todo']);
// Day1 17:30 を過ぎたら時刻なしの前ピンも済、当日に次なし
assert.deepStrictEqual(computeStatuses(stops, dates, '2026-10-30', 1080).slice(0, 2), ['done', 'done']);
// Day1 朝: 時刻なしピンが次
assert.deepStrictEqual(computeStatuses(stops, dates, '2026-10-30', 500).slice(0, 2), ['next', 'todo']);
// 滞在中（開始〜終了の間）は「次」のまま
assert.deepStrictEqual(computeStatuses([{ day: 3, start: 740, end: 800 }], dates, '2026-11-01', 760), ['next']);
// 旅行日以外は全部これから
assert.ok(computeStatuses(stops, dates, '2026-11-02', 600).every(s => s === 'todo'));
console.log('trip-status tests: OK');

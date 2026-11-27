// node apps/board-research-prompt/build-prompt.test.js
const assert = require('assert');
const { buildPrompt, splitList, parseYear, parseLimit } = require('./build-prompt.js');

const full = buildPrompt({
  topic: '掲示板でよくあるログイン失敗の切り分け',
  places: ['Qiita', 'Zenn', '社内Wiki'],
  keywordsJa: ['ログイン失敗', '切り分け'],
  keywordsEn: ['login failure', 'troubleshooting'],
  sinceYear: 2022,
  limit: 5,
  fields: ['タイトル', 'URL', '概要1行'],
});

assert.ok(full.includes('【探してほしいこと】\n掲示板でよくあるログイン失敗の切り分け'));
assert.ok(full.includes('【探す場所】\nQiita、Zenn、社内Wiki'));
assert.ok(full.includes('【探す言葉】'));
assert.ok(full.includes('日本語: ログイン失敗、切り分け'));
assert.ok(full.includes('英語: login failure, troubleshooting'));
assert.ok(full.includes('同じ意味の言い換えや関連語にも広げて探してください。'));
assert.ok(full.includes('【持ち帰ってほしいもの】'));
assert.ok(full.includes('2022年以降'));
assert.ok(full.includes('5件'));
assert.ok(full.includes('各件について: タイトル、URL、概要1行'));
assert.ok(full.endsWith('見つからなければ正直に書く。作り話はしない。必ずURLを付ける。'));

const empty = buildPrompt({
  topic: '  ',
  places: [],
  keywordsJa: [],
  keywordsEn: [],
  sinceYear: null,
  limit: null,
  fields: [],
});
assert.strictEqual(empty, '見つからなければ正直に書く。作り話はしない。必ずURLを付ける。');
assert.ok(!empty.includes('【'));

assert.deepStrictEqual(splitList('Qiita、 Zenn\nReddit, teratail'), ['Qiita', 'Zenn', 'Reddit', 'teratail']);
assert.deepStrictEqual(parseYear(''), { ok: true, value: null });
assert.deepStrictEqual(parseYear('2020'), { ok: true, value: 2020 });
assert.strictEqual(parseYear('20').ok, false);
assert.strictEqual(parseYear('abc').ok, false);
assert.deepStrictEqual(parseLimit('10'), { ok: true, value: 10 });
assert.strictEqual(parseLimit('0').ok, false);
assert.strictEqual(parseLimit('3.5').ok, false);
assert.deepStrictEqual(parseYear('２０２２'), { ok: true, value: 2022 });
assert.deepStrictEqual(parseLimit('８'), { ok: true, value: 8 });

// type=text 経由を想定: 全角のまま value が渡っても正規化とチェックが効く
const zYear = parseYear('２０２２');
const zLimit = parseLimit('８');
assert.deepStrictEqual(zYear, { ok: true, value: 2022 });
assert.deepStrictEqual(zLimit, { ok: true, value: 8 });
const fromZenkaku = buildPrompt({
  topic: '切り分け',
  places: [],
  keywordsJa: [],
  keywordsEn: [],
  sinceYear: zYear.value,
  limit: zLimit.value,
  fields: [],
});
assert.ok(fromZenkaku.includes('2022年以降'));
assert.ok(fromZenkaku.includes('8件'));
assert.strictEqual(parseYear('あ').ok, false);
assert.strictEqual(parseLimit('１２３４５６').ok, false); // 123456 > 200

console.log('build-prompt tests: OK');

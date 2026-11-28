(function (root) {
  'use strict';

  function trim(s) {
    return String(s == null ? '' : s).trim();
  }

  function normalizeDigits(s) {
    return String(s).replace(/[０-９]/g, function (ch) {
      return String.fromCharCode(ch.charCodeAt(0) - 0xFEE0);
    });
  }

  // 改行・カンマ（半角/全角）で分割。空白では割らない（複合語を守る）
  function splitList(text) {
    return trim(text)
      .split(/[\n,、，]+/)
      .map(function (s) { return s.trim(); })
      .filter(Boolean);
  }

  function parseYear(raw) {
    var s = trim(normalizeDigits(raw));
    if (!s) return { ok: true, value: null };
    if (!/^\d{4}$/.test(s)) return { ok: false, error: '期間は西暦4桁で入力してください' };
    var n = Number(s);
    if (n < 1990 || n > 2100) return { ok: false, error: '期間は1990〜2100の西暦で入力してください' };
    return { ok: true, value: n };
  }

  function parseLimit(raw) {
    var s = trim(normalizeDigits(raw));
    if (!s) return { ok: true, value: null };
    if (!/^\d+$/.test(s)) return { ok: false, error: '件数は正の整数で入力してください' };
    var n = Number(s);
    if (n < 1 || n > 200) return { ok: false, error: '件数は1〜200の整数で入力してください' };
    return { ok: true, value: n };
  }

  function buildPrompt(input) {
    var parts = [];
    var topic = trim(input && input.topic);
    if (topic) parts.push('【探してほしいこと】\n' + topic);

    var places = ((input && input.places) || []).map(trim).filter(Boolean);
    if (places.length) parts.push('【探す場所】\n' + places.join('、'));

    var ja = ((input && input.keywordsJa) || []).map(trim).filter(Boolean);
    var en = ((input && input.keywordsEn) || []).map(trim).filter(Boolean);
    if (ja.length || en.length) {
      var kw = ['【探す言葉】'];
      if (ja.length) kw.push('日本語: ' + ja.join('、'));
      if (en.length) kw.push('英語: ' + en.join(', '));
      kw.push('同じ意味の言い換えや関連語にも広げて探してください。');
      parts.push(kw.join('\n'));
    }

    var take = [];
    if (input && input.sinceYear != null) take.push(input.sinceYear + '年以降');
    if (input && input.limit != null) take.push(input.limit + '件');
    var fields = ((input && input.fields) || []).map(trim).filter(Boolean);
    if (fields.length) take.push('各件について: ' + fields.join('、'));
    if (take.length) parts.push('【持ち帰ってほしいもの】\n' + take.join('\n'));

    parts.push('見つからなければ正直に書く。作り話はしない。必ずURLを付ける。');
    return parts.join('\n\n');
  }

  var api = { buildPrompt: buildPrompt, splitList: splitList, parseYear: parseYear, parseLimit: parseLimit };
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.BoardResearchPrompt = api;
})(this);

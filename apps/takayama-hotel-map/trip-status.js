/* trip-pin-base 0.6.0: 時刻パースと 済/次/これから 判定（ブラウザ・node 共用、依存なし） */
(function (root) {
  // 時系列タブの .tl-time 文字列 → { start, end, tentative }（分。時刻なしは null）
  function parseTime(text) {
    const s = String(text || '');
    const t = [];
    s.replace(/(\d{1,2}):(\d{2})/g, (_, h, m) => { t.push(+h * 60 + +m); return _; });
    if (!t.length) {
      const am = s.match(/AM\s*(\d{1,2})時/);
      if (am) t.push(+am[1] * 60);
    }
    return { start: t.length ? t[0] : null, end: t.length > 1 ? t[1] : null, tentative: /仮/.test(s) };
  }
  // stops: [{ day, start, end }]（日ごとに時系列順）
  // tripDates: { 1: 'YYYY-MM-DD', ... } / today: 'YYYY-MM-DD'(Asia/Tokyo) / nowMin: 0..1439
  // 戻り値: stops と同じ並びの 'done' | 'next' | 'todo'
  function computeStatuses(stops, tripDates, today, nowMin) {
    let todayDay = null;
    for (const k in tripDates) if (tripDates[k] === today) todayDay = Number(k);
    const st = stops.map(() => 'todo');
    if (todayDay === null) return st; // 旅行日以外は全部「これから」
    const idx = [];
    stops.forEach((p, i) => {
      if (p.day < todayDay) st[i] = 'done';
      else if (p.day === todayDay) idx.push(i);
    });
    // その日の停車: 終了(なければ開始)時刻を過ぎたら済。後ろが済なら前も済
    let lastDone = -1;
    idx.forEach((i, j) => {
      const p = stops[i];
      const t = p.end != null ? p.end : p.start;
      if (t != null && nowMin >= t) lastDone = j;
    });
    idx.forEach((i, j) => { if (j <= lastDone) st[i] = 'done'; });
    if (lastDone + 1 < idx.length) st[idx[lastDone + 1]] = 'next';
    return st;
  }
  const api = { parseTime, computeStatuses };
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.TripStatus = api;
})(this);

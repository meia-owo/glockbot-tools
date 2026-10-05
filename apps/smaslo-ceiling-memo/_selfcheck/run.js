#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const vm = require("vm");
const assert = require("assert");

const ROOT = path.resolve(__dirname, "..");
const HTML_PATH = path.join(ROOT, "index.html");
const README_PATH = path.join(ROOT, "README.md");

let failed = 0;
function ok(name) {
  console.log("  ✓ " + name);
}
function fail(name, err) {
  failed++;
  console.error("  ✗ " + name + ": " + (err && err.message ? err.message : err));
}

const html = fs.readFileSync(HTML_PATH, "utf8");
const readme = fs.readFileSync(README_PATH, "utf8");

console.log("== static checks ==");
try {
  assert.ok(html.includes("GlockBOT 0.3.5"), "HTML version");
  assert.ok(readme.includes("GlockBOT 0.3.5"), "README version");
  assert.ok(!html.includes("GlockBOT 0.2.1"), "no stale 0.2.1 in HTML");
  assert.ok(!html.includes("GlockBOT 0.2.0"), "no stale 0.2.0 in HTML");
  ok("version string GlockBOT 0.3.5");
} catch (e) {
  fail("version string", e);
}

try {
  const cdnScripts = html.match(/<script[^>]+src=["']https?:\/\//gi) || [];
  assert.strictEqual(cdnScripts.length, 0, "CDN script: " + cdnScripts.join(","));
  const linkCdn = html.match(/<link[^>]+href=["']https?:\/\//gi) || [];
  assert.strictEqual(linkCdn.length, 0, "CDN link: " + linkCdn.join(","));
  ok("no CDN script/link tags");
} catch (e) {
  fail("no CDN", e);
}

try {
  const scriptMatch = html.match(/<script>([\s\S]*?)<\/script>/);
  assert.ok(scriptMatch, "inline script");
  const code = scriptMatch[1];
  assert.ok(!/\bfetch\s*\(/.test(code), "fetch( found");
  assert.ok(!/\bXMLHttpRequest\b/.test(code), "XMLHttpRequest found");
  ok("no fetch(/XHR in script");
} catch (e) {
  fail("no network APIs", e);
}

try {
  assert.ok(html.includes("smaslo-ceiling-memo:v1:<machineId>"), "LS key pattern in comment");
  assert.ok(html.includes("smaslo-ceiling-memo:v1:activeTab"), "activeTab key in comment");
  assert.ok(html.includes("smaslo-ceiling-memo:v2:nangoku-sp:sets"), "v2 nangoku sets key");
  assert.ok(html.includes("smaslo-ceiling-memo:v2:yabachiba:sets"), "v2 yabachiba sets key");
  assert.ok(html.includes("smaslo-ceiling-memo:v2:<machineId>:sets"), "v2 generic sets key");
  ok("LS key scheme documented (v1 + v2 sets per machine)");
} catch (e) {
  fail("LS key comment", e);
}

try {
  assert.ok(html.includes('data-machine="yabachiba"'));
  assert.ok(html.includes('data-machine="chibariyo2"'));
  assert.ok(html.includes('data-machine="nangoku-sp"'));
  assert.ok(html.includes("示唆早見"));
  assert.ok(html.includes("濃厚") && html.includes("示唆") && html.includes("弱") && html.includes("調査中"));
  assert.ok(html.includes('id="setLogPanel"'), "set log panel");
  assert.ok(html.includes("初当たりを記録") || html.includes("初当たりセット"), "set log copy");
  assert.ok(html.includes("示唆を残す"), "hint log button");
  assert.ok(html.includes("この行をログへ") || html.includes("log-row-btn"), "hint card log affordance");
  assert.ok(html.includes("id=\"gApply\"") || html.includes("id='gApply'"), "G apply button");
  assert.ok(html.includes("id=\"undoBtn\"") || html.includes("1つ戻す"), "undo button");
  assert.ok(html.includes("セット終了"), "yabachiba simple end");
  ok("tabs + hints + set-log + G/undo UI markers");
} catch (e) {
  fail("tabs/hints markers", e);
}


try {
  assert.ok(html.includes("gInputEditing"), "gInputEditing flag");
  assert.ok(/gInputEditing\s*=\s*true/.test(html) || html.includes('gInputEditing = true'), "focus sets gInputEditing");
  assert.ok(html.includes('this.value = ""') || html.includes("this.value = ''"), "focus blanks gInput");
  assert.ok(html.includes("if (!gInputEditing)"), "render skips gInput while editing");
  ok("gInput blank-on-focus logic present");
} catch (e) {
  fail("gInput blank-on-focus", e);
}

try {
  assert.ok(html.includes("renderHintVisual"), "renderHintVisual");
  assert.ok(html.includes("参考画像（個人用・照合用・公式ではない）") || html.includes("hint-visual-footnote"), "hint visual footnote");
  assert.ok(html.includes("assets/hints/"), "hint image assets path");
  assert.ok(html.includes('img: "assets/hints/') || html.includes("img: 'assets/hints/"), "hint img fields");
  const assetsDir = path.join(ROOT, "assets", "hints");
  assert.ok(fs.existsSync(assetsDir), "assets/hints dir");
  const imgs = fs.readdirSync(assetsDir).filter(function (f) { return /\.(webp|jpg|jpeg|png)$/i.test(f); });
  assert.ok(imgs.length >= 8, "hint images count >= 8, got " + imgs.length);
  ok("hint visuals + assets (" + imgs.length + " files)");
} catch (e) {
  fail("hint visuals", e);
}

console.log("== API via vm ==");
let API;
try {
  const m = html.match(/<script>([\s\S]*?)<\/script>/);
  assert.ok(m, "script tag");
  const sandbox = {
    window: {},
    module: { exports: {} },
    console,
    Math,
    Number,
    parseInt,
    isNaN,
    JSON,
    String,
    Array,
    Object,
    Date,
    setTimeout: function () {},
    clearTimeout: function () {},
    document: undefined,
    localStorage: undefined,
  };
  vm.runInNewContext(m[1], sandbox, { timeout: 5000 });
  API = sandbox.window.SmasloCeilingMemo || sandbox.module.exports;
  assert.ok(API && typeof API.computeLead === "function", "API.computeLead");
  assert.strictEqual(API.VERSION, "GlockBOT 0.3.5");
  assert.strictEqual(API.LS_SETS_KEY, "smaslo-ceiling-memo:v2:nangoku-sp:sets");
  assert.strictEqual(API.setsLsKey("yabachiba"), "smaslo-ceiling-memo:v2:yabachiba:sets");
  assert.strictEqual(API.setsLsKey("nangoku-sp"), "smaslo-ceiling-memo:v2:nangoku-sp:sets");
  assert.strictEqual(API.LS_PREFIX, "smaslo-ceiling-memo:v1:");
  ok("API exported");
} catch (e) {
  fail("vm load", e);
  console.error("SELFCHECK FAILED");
  process.exit(1);
}

console.log("== machines + hints ==");
try {
  const ids = API.machineIds();
  assert.deepStrictEqual(ids.sort(), ["chibariyo2", "nangoku-sp", "yabachiba"].sort());
  ids.forEach(function (id) {
    const m = API.MACHINES[id];
    assert.ok(m, id);
    assert.ok(Array.isArray(m.hints) && m.hints.length > 0, id + " hints non-empty");
    m.hints.forEach(function (h) {
      assert.ok(h.when && h.means && h.strength, id + " hint fields");
      assert.ok(h.section === "mode" || h.section === "setting", id + " hint section");
      if (h.section === "mode" && h.group) {
        assert.ok(["終了時", "途中", "ボーナス中"].indexOf(h.group) >= 0, id + " hint group");
      }
      assert.ok(["濃厚", "示唆", "弱", "調査中"].indexOf(h.strength) >= 0, "strength " + h.strength);
    });
  });
  assert.ok(API.machineHasSetLog(API.MACHINES.yabachiba), "yabachiba setLog");
  assert.ok(API.machineHasSetLog(API.MACHINES["nangoku-sp"]), "nangoku setLog");
  assert.ok(!API.machineHasSetLog(API.MACHINES.chibariyo2), "chibariyo2 no setLog");
  assert.strictEqual(API.setLogEndStyle(API.MACHINES.yabachiba), "simple");
  assert.strictEqual(API.setLogEndStyle(API.MACHINES["nangoku-sp"]), "hisho");
  ok("3 machine ids with non-empty hints + setLog flags");
} catch (e) {
  fail("machines/hints", e);
}

console.log("== cap switches ==");
try {
  const y = API.MACHINES.yabachiba;
  assert.strictEqual(API.resolveGCap(y, "normal999"), 999);
  assert.strictEqual(API.resolveC2Cap(y, { settingChange: false }), 40);
  assert.strictEqual(API.resolveC2Cap(y, { settingChange: true }), 30);

  const c = API.MACHINES.chibariyo2;
  assert.strictEqual(API.resolveGCap(c, "normal999"), 999);
  assert.strictEqual(API.resolveGCap(c, "reset350"), 350);
  assert.strictEqual(API.resolveGCap(c, "reset600"), 600);
  assert.strictEqual(API.resolveC2Cap(c, { altCap: false }), 45);
  assert.strictEqual(API.resolveC2Cap(c, { altCap: true }), 40);

  const n = API.MACHINES["nangoku-sp"];
  assert.strictEqual(n.hints.length, 18, "nangoku hints count");
  const nModeGroups = n.hints.filter(function (h) { return h.section === "mode"; }).reduce(function (counts, h) {
    counts[h.group] = (counts[h.group] || 0) + 1;
    return counts;
  }, {});
  assert.deepStrictEqual(nModeGroups, { "終了時": 4, "途中": 4, "ボーナス中": 3 }, "nangoku mode groups");
  assert.strictEqual(n.hints.filter(function (h) { return h.section === "setting"; }).length, 7, "nangoku setting hints");
  assert.ok(!n.hints.some(function (h) { return h.when === "リプフラ発生率表"; }), "old vague リプフラ card removed");
  assert.strictEqual(API.resolveGCap(n, "normal799"), 799);
  assert.strictEqual(API.resolveGCap(n, "short500"), 500);
  assert.strictEqual(API.resolveC2Cap(n, {}), 9);
  assert.ok(n.deep.throughFromSets, "nangoku throughFromSets");
  assert.ok(Array.isArray(n.deep.optionalCounters) && n.deep.optionalCounters.length === 0, "nangoku no manual through counter");
  ok("setting-change / gCap mode switches change caps");
} catch (e) {
  fail("cap switches", e);
}

function expectLead(name, g, c2, gCap, c2Cap, c2Label, expectLabel) {
  try {
    const r = API.computeLead(g, c2, gCap, c2Cap, c2Label);
    assert.strictEqual(r.label, expectLabel, JSON.stringify(r));
    ok(name + " → " + expectLabel);
  } catch (e) {
    fail(name, e);
  }
}

console.log("== lead cases (yabachiba-scale) ==");
expectLead("both roomy", 0, 0, 999, 40, "チェリー", "どちらも余裕");
expectLead("G ahead", 900, 5, 999, 40, "チェリー", "G先");
expectLead("cherry ahead", 100, 35, 999, 40, "チェリー", "チェリー先");
expectLead("nearly tie", 950, 38, 999, 40, "チェリー", "ほぼ同時");

console.log("== lead cases (nangoku suika) ==");
expectLead("suika ahead", 100, 8, 799, 9, "スイカ", "スイカ先");
expectLead("G ahead nangoku", 700, 1, 799, 9, "スイカ", "G先");
expectLead("both roomy nangoku", 50, 0, 799, 9, "スイカ", "どちらも余裕");

console.log("== lead cases (chibariyo2 reset) ==");
expectLead("reset350 G ahead", 300, 2, 350, 45, "チェリー", "G先");
expectLead("cherry ahead c45", 50, 40, 999, 45, "チェリー", "チェリー先");

try {
  assert.strictEqual(API.remainingG(100, 999), 899);
  assert.strictEqual(API.remainingG(999, 999), 0);
  assert.strictEqual(API.remainingC2(8, 9), 1);
  assert.strictEqual(API.LS_PREFIX, "smaslo-ceiling-memo:v1:");
  ok("remaining helpers + LS_PREFIX");
} catch (e) {
  fail("helpers", e);
}

console.log("== set / through helpers (0.2 / 0.3) ==");
try {
  const now = new Date("2026-09-25T12:00:00+09:00");
  let store = API.emptySetsStore(now);
  assert.strictEqual(store.dayKey, "2026-09-25");
  assert.strictEqual(store.activeId, null);

  API.startSet(store, { firstHitG: 512, firstHitSuika: 4, firstBonus: "BIG" }, now);
  let active = API.getActiveSet(store);
  assert.ok(active, "active after start");
  assert.strictEqual(API.renchanCount(active), 1, "first bonus = 1連目");
  assert.strictEqual(active.firstHitG, 512);
  assert.strictEqual(active.firstHitSuika, 4);
  assert.strictEqual(API.bonusChain(active), "BIG");

  API.addBonus(store, "REG", new Date("2026-09-25T12:10:00+09:00"));
  API.addBonus(store, "BIG", new Date("2026-09-25T12:20:00+09:00"));
  active = API.getActiveSet(store);
  assert.strictEqual(API.renchanCount(active), 3, "renchanCount = bonuses.length");
  assert.strictEqual(API.bonusChain(active), "BIG→REG→BIG");

  API.endSet(store, false, "", new Date("2026-09-25T12:30:00+09:00"));
  assert.strictEqual(store.activeId, null);
  assert.strictEqual(API.todayThroughCount(store, new Date("2026-09-25T13:00:00+09:00")), 1, "スルー終了 → through+1");

  API.startSet(store, { firstHitG: 100, firstBonus: "REG" }, new Date("2026-09-25T14:00:00+09:00"));
  API.endSet(store, true, "", new Date("2026-09-25T14:30:00+09:00"));
  assert.strictEqual(API.todayThroughCount(store, new Date("2026-09-25T15:00:00+09:00")), 1, "飛翔終了 → through unchanged");

  API.startSet(store, { firstHitG: 200, firstBonus: "BIG" }, new Date("2026-09-25T16:00:00+09:00"));
  API.endSet(store, null, "", new Date("2026-09-25T16:30:00+09:00"));
  assert.strictEqual(API.todayThroughCount(store, new Date("2026-09-25T17:00:00+09:00")), 1, "保留終了 → through unchanged");

  assert.strictEqual(API.todaySetCount(store, new Date("2026-09-25T17:00:00+09:00")), 3);
  assert.strictEqual(API.todayMaxRen(store, new Date("2026-09-25T17:00:00+09:00")), 3);
  assert.strictEqual(API.linkedLabel(false), "スルー");
  assert.strictEqual(API.linkedLabel(true), "飛翔");
  assert.strictEqual(API.linkedLabel(true, "simple"), "連あり");
  assert.strictEqual(API.linkedLabel(null), "保留");

  // yabachiba simple end: renchan===1 → through
  const yStore = API.emptySetsStore(now);
  API.startSet(yStore, { firstHitG: 300, firstBonus: "BIG" }, now);
  assert.strictEqual(API.linkedForSimpleEnd(API.getActiveSet(yStore)), false, "1連 → スルー");
  API.endSet(yStore, API.linkedForSimpleEnd(API.getActiveSet(yStore)), "", new Date("2026-09-25T12:05:00+09:00"));
  assert.strictEqual(API.todayThroughCount(yStore, now), 1, "simple 1連 end → through");

  API.startSet(yStore, { firstHitG: 10, firstBonus: "REG" }, new Date("2026-09-25T13:00:00+09:00"));
  API.addBonus(yStore, "BIG", new Date("2026-09-25T13:10:00+09:00"));
  assert.strictEqual(API.linkedForSimpleEnd(API.getActiveSet(yStore)), true, "2連 → 連あり");
  API.endSet(yStore, API.linkedForSimpleEnd(API.getActiveSet(yStore)), "", new Date("2026-09-25T13:20:00+09:00"));
  assert.strictEqual(API.todayThroughCount(yStore, new Date("2026-09-25T14:00:00+09:00")), 1, "2連 end not through");

  // day roll
  const dayStore = API.emptySetsStore(new Date("2026-09-24T10:00:00+09:00"));
  API.startSet(dayStore, { firstHitG: 1, firstBonus: "BIG" }, new Date("2026-09-24T10:00:00+09:00"));
  API.endSet(dayStore, false, "", new Date("2026-09-24T11:00:00+09:00"));
  assert.strictEqual(API.todayThroughCount(dayStore, new Date("2026-09-25T12:00:00+09:00")), 0, "other day not in 今日");

  ok("start→add BIG/REG→スルー+1 / 飛翔 unchanged / simple end / renchan / day filter");
} catch (e) {
  fail("set/through helpers", e);
}

try {
  assert.ok(readme.includes("初当たりセット") || readme.includes("スルー"), "README set/through");
  assert.ok(readme.includes("smaslo-ceiling-memo:v2:nangoku-sp:sets"), "README v2 nangoku key");
  assert.ok(readme.includes("smaslo-ceiling-memo:v2:yabachiba:sets") || readme.includes("yabachiba:sets"), "README v2 yabachiba key");
  assert.ok(readme.includes("hintEvents") || readme.includes("示唆ログ"), "README hint log");
  assert.ok(readme.includes("1つ戻す") || readme.includes("Undo") || readme.includes("undo"), "README undo");
  ok("README documents set/through + v2 keys + undo");
} catch (e) {
  fail("README set docs", e);
}

console.log("== hint segment helpers (0.2.1) ==");
try {
  const now = new Date("2026-09-25T12:00:00+09:00");
  let store = API.emptySetsStore(now);
  assert.ok(store.waitingHints === null || store.waitingHints === undefined || store.waitingHints === null);
  assert.ok("waitingHints" in store || store.waitingHints === null, "empty store has waitingHints field");

  const legacy = {
    dayKey: "2026-09-25",
    activeId: null,
    sets: [{
      id: "set_old",
      startedAt: "2026-09-25T01:00:00.000Z",
      endedAt: "2026-09-25T01:30:00.000Z",
      firstHitG: 100,
      bonuses: [{ n: 1, type: "BIG", at: "2026-09-25T01:00:00.000Z" }],
      linkedHisho: false,
      note: ""
    }]
  };
  const migrated = API.normalizeSetsStore(legacy, now);
  assert.ok(Array.isArray(migrated.sets[0].hintEvents), "migration hintEvents array");
  assert.strictEqual(migrated.sets[0].hintEvents.length, 0, "migration empty hintEvents");
  assert.strictEqual(API.todayThroughCount(migrated, now), 1, "through intact after migrate");

  store = API.emptySetsStore(now);
  API.startSet(store, { firstHitG: 400, firstBonus: "BIG" }, now);
  let active = API.getActiveSet(store);
  assert.ok(Array.isArray(active.hintEvents) && active.hintEvents.length === 0, "start hintEvents []");
  assert.strictEqual(store.openSegment.segmentKey, "after-start", "open after-start");
  assert.strictEqual(store.openSegment.segmentLabel, "1連目中");

  const h1 = API.MACHINES["nangoku-sp"].hints.find(function (h) { return h.when.indexOf("さざなみ前兆 赤") >= 0; });
  assert.ok(h1, "sample hint");
  API.addHintEvent(store, h1, "memo1", new Date("2026-09-25T12:05:00+09:00"));
  active = API.getActiveSet(store);
  assert.strictEqual(active.hintEvents.length, 1);
  assert.strictEqual(active.hintEvents[0].segmentKey, "after-start");
  assert.strictEqual(active.hintEvents[0].note, "memo1");

  API.addBonus(store, "REG", new Date("2026-09-25T12:10:00+09:00"));
  assert.strictEqual(store.openSegment.segmentKey, "between-1-2", "segment after 2nd bonus");
  assert.strictEqual(store.openSegment.segmentLabel, "1→2連のあいだ");

  const h2 = API.MACHINES["nangoku-sp"].hints.find(function (h) { return h.group === "ボーナス中"; });
  API.addHintEvent(store, h2, "", new Date("2026-09-25T12:12:00+09:00"));
  active = API.getActiveSet(store);
  assert.strictEqual(active.hintEvents.length, 2);
  assert.strictEqual(active.hintEvents[1].segmentKey, "between-1-2");

  API.endSet(store, false, "", new Date("2026-09-25T12:30:00+09:00"));
  assert.strictEqual(store.activeId, null);
  assert.ok(store.waitingHints, "waiting after end");
  assert.strictEqual(store.openSegment.segmentKey, "post-set");
  assert.strictEqual(API.todayThroughCount(store, new Date("2026-09-25T12:31:00+09:00")), 1, "through still +1");

  const h3 = API.MACHINES["nangoku-sp"].hints.find(function (h) { return h.section === "setting"; });
  API.addHintEvent(store, h3, "wait-note", new Date("2026-09-25T12:40:00+09:00"));
  assert.strictEqual(store.waitingHints.events.length, 1, "waiting accepts hint");
  assert.strictEqual(store.waitingHints.events[0].segmentKey, "post-set");

  const endedId = store.waitingHints.endedSetId;
  API.startSet(store, { firstHitG: 50, firstBonus: "REG" }, new Date("2026-09-25T13:00:00+09:00"));
  assert.strictEqual(store.waitingHints, null, "waiting cleared on next first-hit");
  const prev = API.findSetById(store, endedId);
  assert.ok(prev, "prev set found");
  const post = prev.hintEvents.filter(function (e) { return e.segmentKey === "post-set"; });
  assert.strictEqual(post.length, 1, "waiting archived onto prev set post-set");
  assert.strictEqual(store.openSegment.segmentKey, "after-start", "new set after-start");

  // yabachiba hints can be logged the same way
  store = API.emptySetsStore(now);
  API.startSet(store, { firstHitG: 100, firstBonus: "BIG" }, now);
  const yh = API.MACHINES.yabachiba.hints[0];
  API.addHintEvent(store, yh, "yaba", now);
  assert.strictEqual(API.getActiveSet(store).hintEvents.length, 1, "yabachiba hint log");
  assert.strictEqual(API.getActiveSet(store).hintEvents[0].when, yh.when);

  store = API.emptySetsStore(now);
  API.addHintEvent(store, h1, "orphan", now);
  assert.ok(store.waitingHints, "create waiting on first hint");
  assert.strictEqual(store.waitingHints.events.length, 1);

  assert.ok(!html.includes("だから通常B"), "no assertion copy");

  ok("start→hint→bonus segment→hint→end through→waiting→next first-hit archive + yabachiba");
} catch (e) {
  fail("hint segment helpers", e);
}

try {
  const verPath = path.join(ROOT, "VERSION");
  assert.ok(fs.existsSync(verPath), "VERSION file");
  assert.ok(fs.readFileSync(verPath, "utf8").includes("GlockBOT 0.3.5"), "VERSION content");
  ok("VERSION file GlockBOT 0.3.5");
} catch (e) {
  fail("VERSION file", e);
}

console.log("");
if (failed) {
  console.error("SELFCHECK FAILED (" + failed + ")");
  process.exit(1);
}
console.log("SELFCHECK PASSED");
process.exit(0);

// Проверка модели редактора BR2 в node:  node editor/test/roundtrip.js
// 1. каждая пара .MAP/.HER архива (и из 4_MAP.ZIP): открыть -> сохранить -> побайтно то же (4353 + 496 байт; для старых 4096-байтных - карта и миникарта по алгоритму MAPPER)
// 2. миникарта и тип, построенные по алгоритму MAPPER (biterize), совпадают с записанными автором
// 3. проект JSON туда и обратно; задания .TSK/.TS2: расшифровать -> собрать -> те же байты
// 4. правки (здание, кисть, герой, патруль) и проверка
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const C = require('../js/core.js');
const ED = path.join(__dirname, '..'), ROOT = path.join(ED, '..');
const ctx = { window: {} };
vm.runInNewContext(fs.readFileSync(path.join(ED, 'data', 'br2data.js'), 'utf8'), ctx);
const D = ctx.window.BR2_DATA;
let fails = 0, checks = 0;
const ok = (c, m) => { checks++; if (!c) { fails++; console.log('ОШИБКА:', m); } };
const MAPD = path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'MAP'), TASKD = path.join(ROOT, 'archive', 'unz', 'BR2_DEMO', 'TASK');
const rd = p => new Uint8Array(fs.readFileSync(p));

let nFull = 0, nOld = 0;
for (const L of D.levels) {
  const mapB = C.b64dec(L.map), herB = C.b64dec(L.her);
  if (L.src === 'MAP') {                                   // встроенные данные совпадают с файлами архива
    ok(C.eq(mapB, rd(path.join(MAPD, L.name + '.MAP'))) && C.eq(herB, rd(path.join(MAPD, L.name + '.HER'))), L.name + ': встроенные данные = файлы архива');
  }
  const lv = C.levelFromFiles(mapB, herB, L.name);
  const outHer = C.levelToHer(lv), outMap = C.levelToMap(lv);
  ok(C.eq(outHer, herB), `${L.name}: .HER побайтно`);
  if (!lv.oldFormat) {
    nFull++;
    ok(C.eq(outMap, mapB), `${L.name}: .MAP побайтно (карта + миникарта + тип)`);
    ok(C.eq(outMap.subarray(4096, 4352), lv.mini) && outMap[4352] === lv.type, `${L.name}: миникарта и тип по алгоритму MAPPER = записанные автором (тип ${lv.type})`);
  } else {
    nOld++;
    ok(C.eq(outMap.subarray(0, 4096), mapB), `${L.name} (старый формат): первые 4096 байт`);
    console.log(`  ${L.name}: старый формат (4096 байт), миникарта построена: тип ${outMap[4352]}`);
  }
  const lv2 = C.levelFromProject(JSON.parse(JSON.stringify(C.levelToProject(lv))));
  ok(C.eq(C.levelToMap(lv2), outMap) && C.eq(C.levelToHer(lv2), outHer), `${L.name}: проект JSON`);
  const err = C.validate(lv).filter(r => r.level === 'error');
  console.log(`  ${L.name}: героев ${lv.heroes.length}, ландшафт ${lv.land + 1}, тип ${outMap[4352]}, ошибок проверки ${err.length}` + (err.length ? ' (' + [...new Set(err.map(e => e.msg.split(':')[0]))].join(', ') + ')' : ''));
}
console.log(`пар .MAP/.HER: новых ${nFull}, старых ${nOld}`);

for (const T of D.tasks) {
  for (const [k, ext, w, h] of [['tsk', 'TSK', 20, 4], ['ts2', 'TS2', 32, 24]]) {
    const raw = C.b64dec(T[k]);
    ok(C.eq(raw, rd(path.join(TASKD, T.name + '.' + ext))), `${T.name}.${ext}: встроено = файл архива`);
    const lines = C.taskDecode(raw, w, h);
    ok(C.eq(C.taskEncode(lines, w, h), raw), `${T.name}.${ext}: расшифровать -> собрать -> те же байты`);
    console.log(`  ${T.name}.${ext}: ` + JSON.stringify(lines.slice(0, 3)) + (lines.length > 3 ? '...' : ''));
  }
}

// правки
const L10 = D.levels.find(l => l.name === '4_10');
let lv = C.levelFromFiles(C.b64dec(L10.map), C.b64dec(L10.her), '4_10');
const m = lv.map;
let bx = -1, by = -1;
for (let y = 3; y < 60 && bx < 0; y++) for (let x = 3; x < 60 && bx < 0; x++) {
  let free = true; for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) if (m[(y + dy) * 64 + x + dx] !== 1) free = false;
  if (free && !lv.heroes.some(h => Math.abs(h.x - x) < 3 && Math.abs(h.y - y) < 3)) { bx = x; by = y; }
}
ok(bx > 0 && C.canPlaceBuilding(m, bx, by), 'здание можно поставить на пустое место (' + bx + ',' + by + ')');
const before = Array.from(m);
C.placeBuilding(m, 104, bx, by);
ok(m[by * 64 + bx] === 104 && C.DXY.every(([dx, dy], d) => m[(by + dy) * 64 + bx + dx] === 120 + d), 'здание: центр и хвосты 120..127 как в action()');
ok(!C.canPlaceBuilding(m, bx + 1, by) && !C.canPlaceBuilding(m, 1, 5) && !C.canPlaceBuilding(m, 62, 5), 'рядом со зданием и у края - нельзя');
ok(C.buildingAt(m, bx + 1, by + 1).x === bx && C.tileIndex(m, bx - 1, by) === (104 - 102) * 8 + 120, 'хвост -> здание, спрайт хвоста');
C.paintTile(m, bx + 1, by - 1, 7);
ok(C.eq(Array.from(m), before.map((v, i) => (i === (by - 1) * 64 + bx + 1 ? 7 : v))), 'кисть по хвосту сносит здание целиком (клетки = 1) и ставит тайл');
lv.heroes.push({ o: 0, t: 3, x: 5, y: 5, px: 7, py: 8 });
const h2 = C.herFromBytes(C.levelToHer(lv));
ok(h2.some(h => h.x === 5 && h.y === 5 && h.px === 7 && h.py === 8), 'патруль записывается 6-байтной записью');
ok(C.validate(lv).some(r => /патруль/.test(r.msg)), 'проверка предупреждает о патруле');
const f = C.fogMask([{ o: 1, x: 10, y: 10 }], 1);
ok(f[10 * 64 + 10] === 0 && f[8 * 64 + 8] === 0 && f[7 * 64 + 7] === 1 && f[0] === 0, 'туман: 5x5 открыто, остальное (1..62) закрыто');
ok(C.encodeLine('ёж {3}').glyphs.length === 4 && C.encodeLine('~').bad.length === 1, 'кодирование знаков шрифта');

console.log(`проверок: ${checks}, ошибок: ${fails}`);
process.exit(fails ? 1 : 0);

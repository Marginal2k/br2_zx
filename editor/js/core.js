/* Чёрный Ворон 2: модель уровня редактора (без DOM; работает в браузере и в node).
 *
 * Источник истины - авторский редактор карт MAPPER (archive/unz/BR2_DEMO/MAPPER/GAMELOOP.CPP: load_map/load_hero/save_map/save_hero/biterize/
 * div_map/draw_qu/action/Game_Help) и код игры src/game (LODlev, setMAP, LVSTART).
 *
 *   .MAP, 4353 байта: карта 64x64 [y][x] (4096; байт [0][0] = номер ландшафта 0..4 = файл 41SPR..45SPR) + миникарта деления на области
 *                     (256 = 32 строки x 8 байт, 2 бита на квадрат 2x2) + тип (1 байт = число областей - 1, "isDIV")
 *   .HER, 496 байт:   записи {чей, тип, X, Y} (4 байта) или {чей+0x80, тип, X, Y, X патруля, Y патруля} (6 байт); конец - #FF
 *                     чей: 0 люди, 1 кунги, 2 пленники, 4 предмет. Записи идут по клеткам: сверху вниз, слева направо (save_hero)
 * Старый формат (4_MAP.ZIP, 4096 байт, без миникарты) открывается; при сохранении миникарта и тип строятся, как в MAPPER.
 *
 * Модель: { name, land, map: Uint8Array(4096) (map[0] = 0, ландшафт отдельно), heroes: [{o,t,x,y,px,py}] (px=py=0 - нет патруля),
 *           mini, type (как прочитано; при записи пересчитываются), task: {tsk:[строки], ts2:[строки], rawTsk, rawTs2}, side: 0|1 (только для редактора) }
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.BR2Core = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  const MAP_N = 64, MAP_BYTES = 4096, MAP_FILE = 4353, HER_BYTES = 496;
  const MAY_MOVE = 41;                 // GAMELOOP.CPP: меньше (и не 0) - проходимо; в игре то же: go_Max EQU 41 (src/game/lib1a.asm, setMAP)
  const SHIFT = [1, 65, 64, 63, -1, -65, -64, -63];                       // GAMELOOP.CPP: shft[]; хвост 120+d: центр здания в клетке +SHIFT[d]
  const DXY = [[-1, 0], [-1, -1], [0, -1], [1, -1], [1, 0], [1, 1], [0, 1], [-1, 1]];   // где стоит хвост d относительно центра
  const OWN_OBJ = 4;
  const TSK_W = 20, TSK_H = 4, TS2_W = 32, TS2_H = 24, GLYPH_END = 127, GLYPH_SPACE = 10;
  // 4TSKTXT2.CPP: code[] - порядок знаков шрифта 4FONT.FNT (19 строк по 6 знаков)
  const CODE = '012345' + '6789 _' + 'АБВГДЕ' + 'ЖЗИЙКЛ' + 'МНОПРС' + 'ТУФХЦЧ' + 'ШЩЬЫЭЮ' + 'Я:?.,!' + 'абвгде' + 'жзийкл' + 'мнопрс' +
    'туфхцч' + 'шщьыъэ' + 'юяёNRS' + 'IFY()%' + '/-^^^^' + "^*'abc" + 'Ddefgh' + '<>GJLU';

  function b64dec(s) {
    if (typeof atob === 'function') { const t = atob(s), u = new Uint8Array(t.length); for (let i = 0; i < t.length; i++) u[i] = t.charCodeAt(i); return u; }
    return new Uint8Array(Buffer.from(s, 'base64'));
  }
  function b64enc(u) {
    if (typeof btoa === 'function') { let s = ''; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); }
    return Buffer.from(u).toString('base64');
  }
  const eq = (a, b) => { if (a.length !== b.length) return false; for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false; return true; };
  const utf8 = s => new TextEncoder().encode(s);
  class FormatError extends Error {}
  const fmt = (s, v) => v ? s.replace(/\{(\w+)\}/g, (m, k) => (k in v ? v[k] : m)) : s;
  let tr = fmt;
  function setTranslator(f) { tr = f || fmt; }

  // ------------------------------------------------------------------ герои (.HER)
  /** байты .HER -> записи. load_hero: while(hero[i]!=255 && i<=490) */
  function herFromBytes(d) {
    if (d.length !== HER_BYTES) throw new FormatError(tr('.HER: {n} байт вместо {m}', { n: d.length, m: HER_BYTES }));
    const heroes = []; let i = 0;
    while (d[i] !== 255 && i <= 490) {
      const pat = d[i] >= 0x80, o = d[i] & 0x7F;
      heroes.push({ o, t: d[i + 1], x: d[i + 2], y: d[i + 3], px: pat ? d[i + 4] : 0, py: pat ? d[i + 5] : 0 });
      i += pat ? 6 : 4;
    }
    return heroes;
  }
  /** save_hero: перебор клеток y, x; запись только для чей = 0,1 (с патрулём), 2, 4 */
  function herToBytes(heroes) {
    const h = new Uint8Array(HER_BYTES).fill(255);
    const cell = new Map();
    for (const r of heroes) cell.set(r.y * 64 + r.x, r);        // как map2[y][x]: одна запись на клетку, последняя побеждает
    let k = 0;
    for (const key of [...cell.keys()].sort((a, b) => a - b)) {
      const r = cell.get(key);
      let n = 0;
      if (r.o === 0 || r.o === 1) {
        h[k] = r.o; n = 4;
        if (r.px > 0) { h[k] += 0x80; h[k + 4] = r.px; h[k + 5] = r.py; n = 6; }
      } else if (r.o === 2 || r.o === OWN_OBJ) { h[k] = r.o; n = 4; }
      if (n) {
        h[k + 1] = r.t; h[k + 2] = r.x; h[k + 3] = r.y; k += n;
        if (k > 490) break;
      }
    }
    return h;
  }

  // ------------------------------------------------------------------ здания (3x3): центр 102..119, хвосты 120..127
  const isCenter = v => v >= 102 && v <= 119;
  /** номер спрайта ландшафта для клетки (draw_qu): хвост рисуется спрайтом (центр-102)*8+120+d; брошенный хвост = тайл 1 */
  function tileIndex(m, x, y) {
    const v = m[y * 64 + x] & 0x7F;
    if (v < 120) return v;
    const p = y * 64 + x + SHIFT[v - 120];
    const at = p >= 0 && p < 4096 ? m[p] & 0x7F : 0;
    if (at < 102 || at > 119) return 1;
    return (at - 102) * 8 + 120 + (v - 120);
  }
  /** здание, к которому относится клетка: {x,y,center} (центр) или null */
  function buildingAt(m, x, y) {
    const v = m[y * 64 + x];
    if (isCenter(v)) return { x, y, center: v };
    if (v >= 120 && v <= 127) {
      const d = v - 120, cx = x - DXY[d][0], cy = y - DXY[d][1];     // хвост стоит в центр+DXY[d], значит центр = клетка - DXY[d]
      if (cx >= 0 && cy >= 0 && cx < 64 && cy < 64 && isCenter(m[cy * 64 + cx])) return { x: cx, y: cy, center: m[cy * 64 + cx] };
    }
    return null;
  }
  /** action(): здание ставится, если центр в 2..61 и в 8 соседних клетках нет значений >= 102 (своё здание, которое заменяем, не считается) */
  function canPlaceBuilding(m, cx, cy) {
    if (cx < 2 || cy < 2 || cx > 61 || cy > 61) return false;
    const old = buildingAt(m, cx, cy);
    for (const [dx, dy] of DXY) {
      const v = m[(cy + dy) * 64 + cx + dx];
      if (v >= 102 && !(old && old.x === cx && old.y === cy)) return false;
    }
    return true;
  }
  function eraseBuilding(m, b) {
    m[b.y * 64 + b.x] = 1;
    for (const [dx, dy] of DXY) m[(b.y + dy) * 64 + b.x + dx] = 1;
  }
  function placeBuilding(m, center, cx, cy) {
    const old = buildingAt(m, cx, cy);
    if (old) eraseBuilding(m, old);
    m[cy * 64 + cx] = center;
    DXY.forEach(([dx, dy], d) => { m[(cy + dy) * 64 + cx + dx] = 120 + d; });
  }
  /** кисть: обычный тайл (1..101); здание под кистью сносится целиком (в MAPPER на хвосте кисть не действует, на центре - сносит) */
  function paintTile(m, x, y, v) {
    if (x < 0 || y < 0 || x > 63 || y > 63) return;
    const b = buildingAt(m, x, y);
    if (b) eraseBuilding(m, b);
    m[y * 64 + x] = v;
  }

  // ------------------------------------------------------------------ области и миникарта (GAMELOOP.CPP: div_map, b4x4, biterize)
  /** части: Uint8Array(4096): 0 - препятствие, 1..N - номер области */
  function divMap(map, heroes) {
    const m2 = new Map();
    for (const r of heroes) m2.set(r.y * 64 + r.x, r.o * 50 + r.t);
    const part = new Uint8Array(4096);
    for (let i = 0; i < 64; i++) for (let j = 0; j < 64; j++) {
      const k = i * 64 + j, v = (k === 0 ? 0 : map[k]) & 0x7F;
      if (v < MAY_MOVE && v !== 0) {
        const h = m2.has(k) ? m2.get(k) : 255;
        if (h === 204) { /* забор А: клетка закрыта */ } else if (h === 205) { if (i > 0) part[k - 64] = 0; } else part[k] = 255;
      } else if (v > 100) part[k] = 255;
    }
    let n = 1;
    for (;;) {
      let st = -1;
      for (let k = 0; k < 4096; k++) if (part[k] === 255) { st = k; break; }
      if (st < 0) return { part, count: n - 1, isDIV: n - 2 };
      let pts = [st]; part[st] = n;
      while (pts.length) {
        const nx = [];
        for (const k of pts) {
          const i = k >> 6, j = k & 63;
          for (let di = -1; di <= 1; di++) for (let dj = -1; dj <= 1; dj++) {
            const ii = i + di, jj = j + dj;
            if ((di || dj) && ii >= 0 && jj >= 0 && ii < 64 && jj < 64 && part[ii * 64 + jj] === 255) { part[ii * 64 + jj] = n; nx.push(ii * 64 + jj); }
          }
        }
        pts = nx;
      }
      n++;
    }
  }
  function b4x4(part, i, j) {
    let np = 0;
    for (const [a, b] of [[i, j], [i, j + 1], [i + 1, j], [i + 1, j + 1]]) if (a < 64 && b < 64 && part[a * 64 + b] > 0) np = part[a * 64 + b];
    return np > 3 ? 0 : np;
  }
  /** biterize(): {mini(256), type, part} - миникарта деления на области и байт типа (число областей - 1) */
  function biterize(map, heroes) {
    const { part, isDIV } = divMap(map, heroes), mini = new Uint8Array(256);
    if (isDIV === 0) mini.fill(0xAA);
    else for (let i = 0; i < 64; i += 2) for (let j = 0; j < 64; j += 8)
      mini[(i >> 1) * 8 + (j >> 3)] = b4x4(part, i, j) + (b4x4(part, i, j + 2) << 2) + (b4x4(part, i, j + 4) << 4) + (b4x4(part, i, j + 6) << 6);
    return { mini, type: isDIV & 255, part };
  }
  /** туман в начале игры (map.asm FOGALL + lik1.asm onsee): клетки 1..62 закрыты, вокруг своих героев (сторона o) открыто 5x5 */
  function fogMask(heroes, owner) {
    const f = new Uint8Array(4096);
    for (let y = 1; y < 63; y++) for (let x = 1; x < 63; x++) f[y * 64 + x] = 1;
    for (const r of heroes) if (r.o === owner) for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) {
      const x = r.x + dx, y = r.y + dy; if (x >= 0 && y >= 0 && x < 64 && y < 64) f[y * 64 + x] = 0;
    }
    return f;
  }

  // ------------------------------------------------------------------ .MAP + .HER <-> уровень
  const heroSig = heroes => JSON.stringify(heroes.map(h => [h.o, h.t, h.x, h.y, h.px, h.py]));
  function levelFromFiles(mapB, herB, name) {
    if (mapB.length !== MAP_FILE && mapB.length !== MAP_BYTES) throw new FormatError(tr('.MAP: {n} байт, нужно {a} (или {b} - старый формат)', { n: mapB.length, a: MAP_FILE, b: MAP_BYTES }));
    const map = Uint8Array.from(mapB.subarray(0, MAP_BYTES)), land = map[0]; map[0] = 0;
    const heroes = herFromBytes(herB), full = mapB.length === MAP_FILE;
    return {
      name, land, map, heroes, oldFormat: !full, side: land === 3 ? 1 : 0,
      mini: full ? Uint8Array.from(mapB.subarray(4096, 4352)) : null, type: full ? mapB[4352] : null,
      herRaw: Uint8Array.from(herB), herSig: heroSig(heroes), task: null
    };
  }
  /** save_map: [0][0] = ландшафт; затем миникарта и тип, построенные по карте и героям */
  function levelToMap(lv) {
    const out = new Uint8Array(MAP_FILE);
    out.set(lv.map, 0); out[0] = lv.land;
    const b = biterize(lv.map, lv.heroes);
    out.set(b.mini, 4096); out[4352] = b.type;
    return out;
  }
  function levelToHer(lv) { return herToBytes(lv.heroes); }
  function cloneLevel(lv) {
    return Object.assign({}, lv, { map: Uint8Array.from(lv.map), heroes: lv.heroes.map(h => Object.assign({}, h)), task: lv.task ? JSON.parse(JSON.stringify(lv.task)) : null });
  }
  function newLevel(name, land, side) {
    const map = new Uint8Array(4096).fill(1);
    for (let i = 0; i < 64; i++) map[i] = map[63 * 64 + i] = map[i * 64] = map[i * 64 + 63] = 0;       // load_map: новая карта - рамка 0, фон 1
    return { name, land, map, heroes: [], side, oldFormat: false, mini: null, type: null, herRaw: null, herSig: '[]', task: null };
  }

  // ------------------------------------------------------------------ задание: .TSK (4x20) и .TS2 (24x32), знаки шрифта 4FONT.FNT
  const ENC = {};
  for (let i = 0; i < CODE.length; i++) ENC[CODE[i]] = i;      // как conv_tab(): при повторах (знак ^) побеждает последний
  const glyphChar = i => (i < CODE.length && ENC[CODE[i]] === i) ? CODE[i] : '{' + i + '}';
  /** строка -> {glyphs, bad[]}: {N} - знак по номеру */
  function encodeLine(s) {
    const glyphs = [], bad = []; let k = 0;
    while (k < s.length) {
      const m = /^\{(\d{1,3})\}/.exec(s.slice(k));
      if (m && +m[1] < CODE.length) { glyphs.push(+m[1]); k += m[0].length; continue; }
      const c = s[k];
      if (c in ENC) glyphs.push(ENC[c]); else bad.push({ ch: c, at: k });
      k++;
    }
    return { glyphs, bad };
  }
  const order = (h, j) => h === 4 ? j : (j % 2 === 0 ? j / 2 : 23 - (j - 1) / 2);   // 4TSKTXT2.CPP: порядок строк в файле
  /** файл -> строки текста (пустые строки сверху и снизу отброшены; пробелы по краям обрезаны) */
  function taskDecode(b, w, h) {
    const rows = new Array(h).fill(null);
    for (let j = 0; j < h; j++) {
      const r = []; for (let x = 0; x < w; x++) r.push(b[j * (w + 1) + x]);
      rows[order(h, j)] = r;
    }
    const txt = rows.map(r => r.map(g => g === GLYPH_SPACE ? ' ' : glyphChar(g)).join('').replace(/^ +| +$/g, ''));
    let a = 0, z = txt.length;
    while (a < z && txt[a] === '') a++;
    while (z > a && txt[z - 1] === '') z--;
    return txt.slice(a, z);
  }
  /** строки -> файл: как conv_one_task (строка по центру, блок строк по центру по вертикали, после каждой строки #7F) */
  function taskEncode(lines, w, h) {
    const rows = lines.map(s => encodeLine(s).glyphs);
    const y1 = (h - rows.length) >> 1, out = [], ps = new Array(h).fill(null);
    rows.forEach((g, y) => {
      if (y1 + y >= h) return;
      const r = new Array(w).fill(GLYPH_SPACE), x1 = Math.max(0, (w - g.length) >> 1);
      g.slice(0, w).forEach((v, i) => { r[x1 + i] = v; }); ps[y1 + y] = r;
    });
    for (let j = 0; j < h; j++) { const i = order(h, j); out.push(...(ps[i] || new Array(w).fill(GLYPH_SPACE)), GLYPH_END); }
    return Uint8Array.from(out);
  }
  function taskFromBytes(tsk, ts2) {
    const t = { tsk: tsk ? taskDecode(tsk, TSK_W, TSK_H) : [], ts2: ts2 ? taskDecode(ts2, TS2_W, TS2_H) : [], rawTsk: tsk || null, rawTs2: ts2 || null };
    t.sigTsk = JSON.stringify(t.tsk); t.sigTs2 = JSON.stringify(t.ts2);
    return t;
  }
  function taskCheck(lines, w, h) {
    const res = lines.map(s => encodeLine(s));
    return { lines: res, tooLong: res.some(r => r.glyphs.length + r.bad.length > w), tooMany: lines.length > h };
  }
  /** байты .TSK / .TS2 (если текст не менялся - исходные байты, иначе пересобираются) */
  function taskToBytes(t, which) {
    const lines = which === 'tsk' ? t.tsk : t.ts2, raw = which === 'tsk' ? t.rawTsk : t.rawTs2, sig = which === 'tsk' ? t.sigTsk : t.sigTs2;
    if (raw && sig === JSON.stringify(lines)) return raw;
    return which === 'tsk' ? taskEncode(lines, TSK_W, TSK_H) : taskEncode(lines, TS2_W, TS2_H);
  }

  // ------------------------------------------------------------------ PNG и ZIP (из редактора BR1)
  let CRC_T = null;
  function crc32(u, crc) {
    if (!CRC_T) { CRC_T = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; CRC_T[n] = c >>> 0; } }
    crc = (crc === undefined ? 0 : crc) ^ 0xFFFFFFFF;
    for (let i = 0; i < u.length; i++) crc = CRC_T[(crc ^ u[i]) & 255] ^ (crc >>> 8);
    return (crc ^ 0xFFFFFFFF) >>> 0;
  }
  function concat(parts) { const n = parts.reduce((a, p) => a + p.length, 0), o = new Uint8Array(n); let k = 0; for (const p of parts) { o.set(p, k); k += p.length; } return o; }
  const be32 = v => Uint8Array.of(v >>> 24, (v >>> 16) & 255, (v >>> 8) & 255, v & 255);
  function pngChunk(type, data) { const t = utf8(type); return concat([be32(data.length), t, data, be32(crc32(concat([t, data])))]); }
  /** индексированное изображение -> PNG. deflate(Uint8Array) -> Uint8Array|Promise */
  async function encodePng(w, h, idx, palette, deflate) {
    const raw = new Uint8Array((w + 1) * h);
    for (let y = 0; y < h; y++) raw.set(idx.subarray(y * w, y * w + w), y * (w + 1) + 1);
    const ihdr = concat([be32(w), be32(h), Uint8Array.of(8, 3, 0, 0, 0)]);
    const pal = new Uint8Array(palette.length * 3); palette.forEach((c, i) => pal.set(c, i * 3));
    const z = await deflate(raw);
    return concat([Uint8Array.of(137, 80, 78, 71, 13, 10, 26, 10), pngChunk('IHDR', ihdr), pngChunk('PLTE', pal), pngChunk('IDAT', z), pngChunk('IEND', new Uint8Array(0))]);
  }
  function zipStore(files) {
    const parts = [], central = [];
    let off = 0;
    const le16 = v => Uint8Array.of(v & 255, v >> 8), le32 = v => Uint8Array.of(v & 255, (v >>> 8) & 255, (v >>> 16) & 255, v >>> 24);
    for (const [name, data] of Object.entries(files)) {
      const nb = utf8(name), crc = crc32(data);
      const local = concat([le32(0x04034b50), le16(20), le16(0x800), le16(0), le16(0), le16(0x21), le32(crc), le32(data.length), le32(data.length), le16(nb.length), le16(0), nb]);
      parts.push(local, data);
      central.push(concat([le32(0x02014b50), le16(20), le16(20), le16(0x800), le16(0), le16(0), le16(0x21), le32(crc), le32(data.length), le32(data.length),
        le16(nb.length), le16(0), le16(0), le16(0), le16(0), le32(0), le32(off), nb]));
      off += local.length + data.length;
    }
    const cd = concat(central);
    return concat(parts.concat([cd, concat([le32(0x06054b50), le16(0), le16(0), le16(central.length), le16(central.length), le32(cd.length), le32(off), le16(0)])]));
  }


  // ------------------------------------------------------------------ проект JSON
  function levelToProject(lv) {
    const rows = [];
    for (let y = 0; y < 64; y++) rows.push(Array.from(lv.map.slice(y * 64, y * 64 + 64)).join(','));
    return {
      format: 'br2-level-editor', version: 1, name: lv.name, land: lv.land, side: lv.side, map: rows,
      heroes: lv.heroes.map(h => [h.o, h.t, h.x, h.y, h.px, h.py]), task: lv.task ? { tsk: lv.task.tsk, ts2: lv.task.ts2 } : null
    };
  }
  function levelFromProject(o) {
    if (!o || o.format !== 'br2-level-editor') throw new FormatError(tr('это не проект редактора BR2'));
    const map = new Uint8Array(4096);
    o.map.forEach((r, y) => r.split(',').forEach((v, x) => { map[y * 64 + x] = +v; }));
    const heroes = o.heroes.map(a => ({ o: a[0], t: a[1], x: a[2], y: a[3], px: a[4] || 0, py: a[5] || 0 }));
    const lv = { name: o.name, land: o.land, map, heroes, side: o.side, oldFormat: false, mini: null, type: null, herRaw: null, herSig: heroSig(heroes), task: null };
    if (o.task) { lv.task = taskFromBytes(null, null); lv.task.tsk = o.task.tsk; lv.task.ts2 = o.task.ts2; }
    return lv;
  }

  // ------------------------------------------------------------------ проверка (Game_Help: ERR1..ERR7 + замечания редактора)
  function validate(lv) {
    const R = [], err = (msg, x, y) => R.push({ level: 'error', msg, x, y }), warn = (msg, x, y) => R.push({ level: 'warn', msg, x, y });
    const m = lv.map, cnt = { 0: 0, 1: 0, 2: 0, 4: 0 };
    for (const h of lv.heroes) {
      if (h.x > 63 || h.y > 63) { err(tr('герой вне карты'), h.x & 63, h.y & 63); continue; }
      if (!(h.o in cnt)) { err(tr('чей = {o}: в MAPPER такого нет (0, 1, 2, 4)', { o: h.o }), h.x, h.y); continue; }
      cnt[h.o]++;
      const v = m[h.y * 64 + h.x];
      if (v === 0 || v >= 40) err(tr('ERR2: герой на непроходимой клетке (тайл {v})', { v }), h.x, h.y);       // chk_hero: map==0 || map>=40
      if (h.o === 4 && h.t > 6) err(tr('предмет: тип {t} (бывают 0..6)', { t: h.t }), h.x, h.y);
      if (h.o !== 4 && h.t > 23) err(tr('герой: тип {t} (бывают 0..23)', { t: h.t }), h.x, h.y);
      if (h.px > 0 && h.o > 1) warn(tr('патруль у этой стороны MAPPER не сохраняет'), h.x, h.y);
      else if (h.px > 0) warn(tr('патруль: LVSTART игры v0.04 читает записи по 4 байта и 6-байтных не знает - с патрулём расстановка героев в игре сломается'), h.x, h.y);
    }
    const seen = new Set();
    for (const h of lv.heroes) { const k = h.y * 64 + h.x; if (seen.has(k)) err(tr('две записи в одной клетке: MAPPER хранит одну на клетку, остальные теряются'), h.x, h.y); seen.add(k); }
    if (cnt[0] > 48 || cnt[1] > 48 || cnt[2] > 5) err(tr('ERR1: слишком много героев за одну из сторон (людей {a}, кунгов {b}, пленников {c}; не больше 48 / 48 / 5)', { a: cnt[0], b: cnt[1], c: cnt[2] }));
    if (cnt[0] + cnt[1] + cnt[2] + cnt[4] > 123) err(tr('ERR3: героев и предметов вместе более 123'));
    if (cnt[4] > 44) err(tr('ERR7: предметов более 44'));
    const saved = herFromBytes(herToBytes(lv.heroes)).length;
    if (saved < new Set(lv.heroes.map(h => h.y * 64 + h.x)).size) err(tr('в .HER (496 байт) помещается только {n} записей', { n: saved }));
    let mine = 0, hb = 0, kb = 0;
    for (let y = 0; y < 64; y++) for (let x = 0; x < 64; x++) {
      const v = m[y * 64 + x];
      if (v === 103) mine++; else if (v >= 104 && v <= 111) hb++; else if (v >= 112 && v <= 119) kb++;
      if (isCenter(v)) {
        if (x < 2 || y < 2 || x > 61 || y > 61) err(tr('здание слишком близко к краю'), x, y);
        else DXY.forEach(([dx, dy], d) => { if (m[(y + dy) * 64 + x + dx] !== 120 + d) err(tr('у здания не хватает части {d}', { d }), x, y); });
      } else if (v >= 120) { if (v > 127 || !buildingAt(m, x, y)) err(tr('хвост здания ({v}) без центра', { v }), x, y); }
      else if (v === 101) warn(tr('тайл 101 (буфер невидимого поля) в карте не нужен'), x, y);
      if ((x === 0 || y === 0 || x === 63 || y === 63) && v !== 0) warn(tr('граница карты должна быть тайлом 0'), x, y);
    }
    if (hb > 32 || kb > 32) err(tr('ERR5: слишком много построек за одну из сторон (людей {a}, кунгов {b}; не более 32)', { a: hb, b: kb }));
    if (mine > 8) err(tr('ERR6: шахт больше 8 ({n})', { n: mine }));
    if (lv.land !== 3) for (let y = 1; y < 63; y++) for (let x = 1; x < 63; x++) {     // chk_wood
      const v = m[y * 64 + x], ok = a => a === 0 || a === 50 || a === 51, okU = a => a === 0 || a === 50 || a === 49, up = m[(y - 1) * 64 + x], dn = m[(y + 1) * 64 + x];
      if ((v === 49 && !ok(dn)) || (v === 50 && (!ok(dn) || !okU(up))) || (v === 51 && !okU(up))) err(tr('ERR4: неверный спрайт леса'), x, y);
    }
    if (lv.land > 4) err(tr('ландшафт {n}: файлов 41SPR..45SPR только пять', { n: lv.land + 1 }));
    else if (lv.land !== 3 && lv.land !== 4) warn(tr('в игре v0.04 есть только ландшафты 44SPR (кунги) и 45SPR (люди): этот в игре не загрузится'));
    return R;
  }

  // ------------------------------------------------------------------ карта в игре (src/game/map.asm: MP_OUT, MP_SPA, MP_IMG)
  /** значки 3x3: по 3 строки, биты 7..5 (младшие байты DEFW из MP_IMG), индекс = смещение / 6 */
  const MP_IMG = [[0xE0, 0x80, 0x80], [0xE0, 0x80, 0xA0], [0xE0, 0xC0, 0xA0], [0xE0, 0xE0, 0xE0], [0xE0, 0xA0, 0xE0], [0x00, 0x00, 0xE0],
    [0x40, 0xA0, 0x40], [0xC0, 0x80, 0x00], [0xE0, 0xA0, 0x40], [0xA0, 0x40, 0xA0], [0x00, 0x40, 0x00], [0x80, 0x40, 0x40], [0x40, 0x20, 0x40],
    [0x00, 0x60, 0x00], [0xA0, 0xA0, 0xA0], [0xE0, 0x80, 0xA0], [0xE0, 0x00, 0xE0], [0xE0, 0x00, 0xC0], [0xC0, 0xC0, 0xC0], [0xC0, 0xC0, 0x00],
    [0xE0, 0xE0, 0x00], [0xA0, 0xA0, 0x80]];
  /** gameMap(map, heroes, mps): 192x192 точек (1 = чернила), как режим «карта» в игре: клетка -> MPsign -> значок;
   *  клетка с героем: люди / кунги / пленник (MP_IMG+0/+6/+12), предметы остаются клеткой карты. Анимация воды и мигание не рисуются. */
  function gameMap(map, heroes, mps) {
    const W = MAP_N * 3, px = new Uint8Array(W * W), who = new Map();
    for (const r of heroes) if (r.o <= 2 && r.x < MAP_N && r.y < MAP_N) who.set(r.y * MAP_N + r.x, r.o);
    for (let y = 0; y < MAP_N; y++) for (let x = 0; x < MAP_N; x++) {
      const k = y * MAP_N + x, o = who.get(k);
      const cell = (x || y) ? map[k] & 0x7F : 0;                     // [0][0] в файле = номер ландшафта, в игре это клетка рамки
      const g = MP_IMG[o !== undefined ? o : Math.floor(mps[cell] / 6)] || MP_IMG[3];
      for (let r = 0; r < 3; r++) for (let b = 0; b < 3; b++) if (g[r] & (0x80 >> b)) px[(y * 3 + r) * W + x * 3 + b] = 1;
    }
    return px;
  }

  return {
    gameMap,
    MAP_N, MAP_BYTES, MAP_FILE, HER_BYTES, MAY_MOVE, SHIFT, DXY, CODE, TSK_W, TSK_H, TS2_W, TS2_H, FormatError, setTranslator, fmt, b64dec, b64enc, eq, utf8, crc32, concat,
    herFromBytes, herToBytes, isCenter, tileIndex, buildingAt, canPlaceBuilding, eraseBuilding, placeBuilding, paintTile, divMap, biterize, fogMask,
    levelFromFiles, levelToMap, levelToHer, cloneLevel, newLevel, glyphChar, encodeLine, taskDecode, taskEncode, taskFromBytes, taskCheck, taskToBytes,
    encodePng, zipStore, levelToProject, levelFromProject, validate, heroSig
  };
});

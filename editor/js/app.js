/* Чёрный Ворон 2: интерфейс редактора уровней. Модель и форматы - js/core.js, данные игры - data/br2data.js.
 * Каркас (вид, масштаб, сдвиг, отмена, кисть, герои, язык, файлы) - из редактора «Чёрного Ворона» 1. */
(function () {
  'use strict';
  const C = window.BR2Core, D = window.BR2_DATA, I18N = window.BRI18N, t = I18N.t;
  C.setTranslator(t);
  const $ = id => document.getElementById(id);

  // ------------------------------------------------------------------ справочники
  // GAMELOOP.CPP: styp[] - названия типов героев 0..23 (одни и те же для людей, кунгов и пленников) и objtyp[] - предметы
  const HNAME = ['робот', 'робот1', 'робот2', 'десантник', 'огнемётчик', 'волкер', 'зенитка', 'капеллан', 'князь', 'танк', 'штурмовик', 'транспорт',
    'пеон', 'пеон1', 'пеон2', 'кунг', 'кракотун', 'демон', 'ланголетта', 'варлок', 'зерг', 'тень', 'ворон', 'гнездолёт'];
  const ONAME = ['металлит-концентрат', 'циклофрен-концентрат', 'телепорт', 'выключатель', 'забор А', 'забор Б', 'мина'];
  const OWNER_NAME = { 0: 'люди', 1: 'кунги', 2: 'пленники', 4: 'предметы' };
  const OWNER_RGB = { 0: [30, 80, 255], 1: [225, 25, 25], 2: [20, 160, 20], 4: [190, 0, 190] };
  // комментарий в конце GAMELOOP.CPP (тип 1): группы тайлов
  const TILE_GROUPS = [[0, 0, 'пусто (граница)'], [1, 3, 'трава'], [4, 5, 'проходы: подъём/спуск'], [6, 14, 'пожарище'], [15, 18, 'фазы мазута'], [19, 27, 'тропы, грязь'],
    [28, 31, 'углы берега'], [32, 34, 'мост 1'], [35, 37, 'мост 2'], [38, 40, 'элементы оформления'], [41, 48, 'элементы оформления (непроходимые)'], [49, 51, 'лес'],
    [52, 55, 'прямой берег'], [56, 67, 'горы-подъём'], [68, 93, 'горы'], [94, 100, 'анимированные элементы (вода)'], [101, 101, 'стройка 50-99% / буфер'],
    [102, 102, 'стройка 0-49%'], [103, 103, 'штольня (шахта)'], [104, 111, 'здания людей'], [112, 119, 'здания кунгов']];
  const groupOf = v => (TILE_GROUPS.find(g => v >= g[0] && v <= g[1]) || [0, 0, ''])[2];
  const ZXRGB = [[0, 0, 0], [0, 0, 215], [215, 0, 0], [215, 0, 215], [0, 215, 0], [0, 215, 215], [215, 215, 0], [215, 215, 215]];
  const SIDE_COLOR = [0x28, 0x30];          // COLOR уровня: людей #28 (бумага голубая), кунгов #30 (бумага жёлтая) - docs/NOTES.md, build.py
  const SIDE_NAME = ['людей', 'кунгов'];
  const LAND = {}; D.levels && Object.keys(D.land).forEach(k => { LAND[k] = C.b64dec(D.land[k]); });
  const FONT = C.b64dec(D.font);
  const HSPR = D.heroes.map(h => ({ mask: C.b64dec(h.mask), img: C.b64dec(h.img) })), OSPR = D.objects.map(h => ({ mask: C.b64dec(h.mask), img: C.b64dec(h.img) }));

  // ------------------------------------------------------------------ состояние
  let lv = null, undo = [], redo = [], dirty = false;
  let tool = 'brush', mapTool = 'brush', curTile = 1, curBuild = 104, heroOwner = 0, heroType = 3, selHero = -1;
  let view = { z: 1, ox: 0, oy: 0 }, hover = null, drag = null, spaceDown = false, issues = [], flash = null, partCache = null;
  const opt = { grid: false, heroes: true, pass: false, parts: false, fog: false, issues: true, mono: false };

  // ------------------------------------------------------------------ графика
  const atlasCache = new Map();
  function colors() {
    if (opt.mono) return [[0, 0, 0], [255, 255, 255]];
    const a = SIDE_COLOR[lv ? lv.side : 0], br = (a >> 6) & 1, ink = ZXRGB[a & 7], paper = ZXRGB[(a >> 3) & 7];
    return br ? [ink, paper.map(v => v ? 255 : 0)] : [ink, paper];
  }
  const landKey = () => String(Math.min(5, (lv ? lv.land : 0) + 1));
  /** атлас 412 тайлов 16x16 (32 в ряд): файл 4NSPR.DAT, тайл = 2 столбца по 16 байт, бит 1 - чернила (как в игре) */
  function atlas() {
    const [ink, paper] = colors(), key = landKey() + ':' + ink + ':' + paper;
    if (atlasCache.has(key)) return atlasCache.get(key);
    const land = LAND[landKey()], cv = document.createElement('canvas');
    cv.width = 512; cv.height = 13 * 16;
    const g = cv.getContext('2d'), im = g.createImageData(512, 208), d = im.data;
    for (let tl = 0; tl < 412; tl++) {
      const tx = (tl % 32) * 16, ty = (tl >> 5) * 16;
      for (let k = 0; k < 2; k++) for (let l = 0; l < 16; l++) {
        const b = land[tl * 32 + k * 16 + l];
        for (let bit = 0; bit < 8; bit++) {
          const c = (b >> (7 - bit)) & 1 ? ink : paper, o = ((ty + l) * 512 + tx + k * 8 + bit) * 4;
          d[o] = c[0]; d[o + 1] = c[1]; d[o + 2] = c[2]; d[o + 3] = 255;
        }
      }
    }
    g.putImageData(im, 0, 0);
    atlasCache.set(key, cv);
    return cv;
  }
  function drawTileTo(g, tl, x, y, size) {
    size = size || 16;
    if (tl < 0 || tl >= 412) { g.fillStyle = '#f0f'; g.fillRect(x, y, size, size); return; }
    g.drawImage(atlas(), (tl % 32) * 16, (tl >> 5) * 16, 16, 16, x, y, size, size);
  }
  const heroCache = new Map();
  /** герой: маска - силуэт цветом бумаги, рисунок - чернилами (как sprites игры), рамка цвета стороны */
  function heroSprite(o, ty) {
    const key = o + ':' + ty + ':' + colors(), isObj = o === 4;
    if (heroCache.has(key)) return heroCache.get(key);
    const cv = document.createElement('canvas'); cv.width = cv.height = 16;
    const g = cv.getContext('2d'), im = g.createImageData(16, 16), d = im.data, [ink, paper] = colors();
    const sp = (isObj ? OSPR : HSPR)[ty];
    if (sp) for (let col = 0; col < 2; col++) for (let row = 0; row < 16; row++) {
      const m = sp.mask[col * 16 + row], p = sp.img[col * 16 + row];
      for (let bit = 0; bit < 8; bit++) if ((m >> (7 - bit)) & 1) {
        const c = (p >> (7 - bit)) & 1 ? ink : paper, q = (row * 16 + col * 8 + bit) * 4;
        d[q] = c[0]; d[q + 1] = c[1]; d[q + 2] = c[2]; d[q + 3] = 255;
      }
    }
    g.putImageData(im, 0, 0);
    g.strokeStyle = 'rgb(' + (OWNER_RGB[o] || [128, 128, 128]) + ')'; g.lineWidth = 1; g.strokeRect(.5, .5, 15, 15);
    heroCache.set(key, cv);
    return cv;
  }
  function buildingCanvas(center, scale) {
    const cv = document.createElement('canvas'); cv.width = cv.height = 48 * scale;
    const g = cv.getContext('2d'); g.imageSmoothingEnabled = false;
    drawTileTo(g, center, 16 * scale, 16 * scale, 16 * scale);
    C.DXY.forEach(([dx, dy], d) => drawTileTo(g, (center - 102) * 8 + 120 + d, (1 + dx) * 16 * scale, (1 + dy) * 16 * scale, 16 * scale));
    return cv;
  }
  function glyphCanvas(i, fg, bg) {
    const cv = document.createElement('canvas'); cv.width = cv.height = 8;
    const g = cv.getContext('2d'), im = g.createImageData(8, 8), d = im.data;
    for (let r = 0; r < 8; r++) { const b = FONT[i * 8 + r]; for (let k = 0; k < 8; k++) { const c = (b >> (7 - k)) & 1 ? fg : bg, q = (r * 8 + k) * 4; d[q] = c[0]; d[q + 1] = c[1]; d[q + 2] = c[2]; d[q + 3] = 255; } }
    g.putImageData(im, 0, 0);
    return cv;
  }

  // ------------------------------------------------------------------ карта (offscreen 1024x1024)
  const mapCv = document.createElement('canvas'); mapCv.width = mapCv.height = 1024;
  const mg = mapCv.getContext('2d');
  let fog = null;
  function redrawMap(x0, y0, x1, y1) {
    if (!lv) { mg.fillStyle = '#222'; mg.fillRect(0, 0, 1024, 1024); return; }
    x0 = Math.max(0, x0 === undefined ? 0 : x0); y0 = Math.max(0, y0 === undefined ? 0 : y0);
    x1 = Math.min(63, x1 === undefined ? 63 : x1); y1 = Math.min(63, y1 === undefined ? 63 : y1);
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) drawTileTo(mg, fog && fog[y * 64 + x] ? 411 : C.tileIndex(lv.map, x, y), x * 16, y * 16);
  }
  function updateFog() { fog = opt.fog && lv ? C.fogMask(lv.heroes, lv.side) : null; }
  function parts() { if (!partCache) partCache = C.divMap(lv.map, lv.heroes); return partCache; }

  // ------------------------------------------------------------------ вид
  const cv = $('cv'), g = cv.getContext('2d');
  let drawPending = false;
  function scheduleDraw() { if (!drawPending) { drawPending = true; requestAnimationFrame(draw); } }
  function resize() { const r = cv.getBoundingClientRect(); cv.width = Math.round(r.width * devicePixelRatio); cv.height = Math.round(r.height * devicePixelRatio); scheduleDraw(); }
  function fit() {
    const w = cv.width / devicePixelRatio, h = cv.height / devicePixelRatio, z = Math.max(0.25, Math.min(w, h) / 1024 * 0.96);
    view.z = z; view.ox = (w - 1024 * z) / 2; view.oy = (h - 1024 * z) / 2; scheduleDraw();
  }
  function zoomAt(f, mx, my) {
    const nz = Math.max(0.25, Math.min(8, view.z * f));
    view.ox = mx - (mx - view.ox) * nz / view.z; view.oy = my - (my - view.oy) * nz / view.z; view.z = nz; scheduleDraw();
  }
  function cellAt(e) {
    const r = cv.getBoundingClientRect(), mx = e.clientX - r.left, my = e.clientY - r.top;
    const x = Math.floor((mx - view.ox) / (16 * view.z)), y = Math.floor((my - view.oy) / (16 * view.z));
    return { x, y, mx, my, in: x >= 0 && y >= 0 && x < 64 && y < 64 };
  }
  const PART_RGB = ['', '0,200,0', '40,120,255', '255,150,0', '255,60,200'];
  function draw() {
    drawPending = false;
    const dpr = devicePixelRatio;
    g.setTransform(1, 0, 0, 1, 0, 0);
    g.fillStyle = '#111'; g.fillRect(0, 0, cv.width, cv.height);
    g.setTransform(dpr * view.z, 0, 0, dpr * view.z, dpr * view.ox, dpr * view.oy);
    g.imageSmoothingEnabled = false;
    g.drawImage(mapCv, 0, 0);
    if (!lv) { g.fillStyle = '#ccc'; g.font = '28px sans-serif'; g.fillText(t('Откройте уровень'), 380, 512); return; }
    const lw = 1 / view.z;
    if (opt.pass) {
      g.fillStyle = 'rgba(255,40,40,.35)';
      for (let i = 0; i < 4096; i++) { const v = i === 0 ? 0 : lv.map[i]; if (!(v >= 1 && v < C.MAY_MOVE)) g.fillRect((i & 63) * 16, (i >> 6) * 16, 16, 16); }
    }
    if (opt.parts) {
      const p = parts().part;
      for (let i = 0; i < 4096; i++) if (p[i]) { g.fillStyle = 'rgba(' + PART_RGB[Math.min(p[i], 4)] + ',.38)'; g.fillRect((i & 63) * 16, (i >> 6) * 16, 16, 16); }
    }
    if (opt.grid) {
      g.strokeStyle = 'rgba(128,128,128,.45)'; g.lineWidth = lw; g.beginPath();
      for (let i = 0; i <= 64; i++) { g.moveTo(i * 16, 0); g.lineTo(i * 16, 1024); g.moveTo(0, i * 16); g.lineTo(1024, i * 16); }
      g.stroke();
    }
    if (opt.heroes) {
      lv.heroes.forEach((h, k) => {
        if (h.x > 63 || h.y > 63) return;
        if (h.px > 0) {
          g.strokeStyle = 'rgba(250,124,104,.9)'; g.lineWidth = 2 * lw + .5; g.setLineDash([4 * lw, 3 * lw]);
          g.beginPath(); g.moveTo(h.x * 16 + 8, h.y * 16 + 8); g.lineTo(h.px * 16 + 8, h.py * 16 + 8); g.stroke(); g.setLineDash([]);
        }
        g.drawImage(heroSprite(h.o, h.t), h.x * 16, h.y * 16);
        if (k === selHero) { g.strokeStyle = '#ffd23a'; g.lineWidth = 2.5 * lw + 1; g.strokeRect(h.x * 16 - 2, h.y * 16 - 2, 20, 20); }
      });
    }
    if (opt.issues) for (const r of issues) if (r.x !== undefined) {
      g.strokeStyle = r.level === 'error' ? '#ff3030' : '#ffc400'; g.lineWidth = 2 * lw + .5; g.strokeRect(r.x * 16 + 1, r.y * 16 + 1, 14, 14);
    }
    if (hover && hover.in) {
      if (tool === 'building') {
        const ok = C.canPlaceBuilding(lv.map, hover.x, hover.y);
        g.globalAlpha = 0.7; g.drawImage(buildingCanvas(curBuild, 1), (hover.x - 1) * 16, (hover.y - 1) * 16); g.globalAlpha = 1;
        g.strokeStyle = ok ? '#ffd23a' : '#ff3030'; g.lineWidth = 2 * lw; g.strokeRect((hover.x - 1) * 16, (hover.y - 1) * 16, 48, 48);
      } else if (tool === 'brush') {
        g.globalAlpha = 0.6; drawTileTo(g, curTile, hover.x * 16, hover.y * 16); g.globalAlpha = 1;
        g.strokeStyle = '#ffd23a'; g.lineWidth = 2 * lw; g.strokeRect(hover.x * 16, hover.y * 16, 16, 16);
      } else if (tool === 'hero' && !heroAt(hover.x, hover.y)) {
        g.globalAlpha = 0.6; g.drawImage(heroSprite(heroOwner, heroType), hover.x * 16, hover.y * 16); g.globalAlpha = 1;
        g.strokeStyle = '#ffd23a'; g.lineWidth = 2 * lw; g.strokeRect(hover.x * 16, hover.y * 16, 16, 16);
      } else if (tool === 'erase') {
        const b = C.buildingAt(lv.map, hover.x, hover.y);
        g.strokeStyle = '#ff3030'; g.lineWidth = 2 * lw;
        if (b) g.strokeRect((b.x - 1) * 16, (b.y - 1) * 16, 48, 48); else g.strokeRect(hover.x * 16, hover.y * 16, 16, 16);
      } else { g.strokeStyle = '#ffd23a'; g.lineWidth = 2 * lw; g.strokeRect(hover.x * 16, hover.y * 16, 16, 16); }
    }
    if (drag && drag.kind === 'rect') {
      const [x0, y0, x1, y1] = rectOf(drag);
      g.fillStyle = 'rgba(255,210,58,.25)'; g.fillRect(x0 * 16, y0 * 16, (x1 - x0 + 1) * 16, (y1 - y0 + 1) * 16);
      g.strokeStyle = '#ffd23a'; g.lineWidth = 2 * lw; g.strokeRect(x0 * 16, y0 * 16, (x1 - x0 + 1) * 16, (y1 - y0 + 1) * 16);
    }
    if (flash) { g.strokeStyle = '#00e5ff'; g.lineWidth = 3 * lw + 1; g.strokeRect(flash.x * 16 - 6, flash.y * 16 - 6, 28, 28); }
    $('zVal').textContent = Math.round(view.z * 100) + '%';
  }
  const rectOf = d => [Math.min(d.x0, d.x1), Math.min(d.y0, d.y1), Math.max(d.x0, d.x1), Math.max(d.y0, d.y1)];
  function heroAt(x, y) { if (!lv) return null; for (let k = lv.heroes.length - 1; k >= 0; k--) if (lv.heroes[k].x === x && lv.heroes[k].y === y) return k + 1; return null; }

  // ------------------------------------------------------------------ правки, отмена
  function snapshot() { undo.push(C.cloneLevel(lv)); if (undo.length > 200) undo.shift(); redo = []; setDirty(true); }
  function setDirty(v) { dirty = v; $('dirty').textContent = v ? '● ' + t('есть несохранённые правки') : ''; }
  function doUndo() { if (!undo.length) return; redo.push(C.cloneLevel(lv)); lv = undo.pop(); setDirty(true); refreshAll(); }
  function doRedo() { if (!redo.length) return; undo.push(C.cloneLevel(lv)); lv = redo.pop(); setDirty(true); refreshAll(); }
  const editable = () => !!lv;
  function paintAt(x, y) {
    if (!(x >= 0 && y >= 0 && x < 64 && y < 64)) return;
    if (lv.map[y * 64 + x] === curTile) return;
    C.paintTile(lv.map, x, y, curTile);
    redrawMap(x - 2, y - 2, x + 2, y + 2);
  }
  function lineCells(x0, y0, x1, y1, f) {
    const dx = Math.abs(x1 - x0), dy = -Math.abs(y1 - y0), sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    let e = dx + dy;
    for (;;) { f(x0, y0); if (x0 === x1 && y0 === y1) break; const e2 = 2 * e; if (e2 >= dy) { e += dy; x0 += sx; } if (e2 <= dx) { e += dx; y0 += sy; } }
  }
  const passable = (x, y) => { const v = lv.map[y * 64 + x]; return v !== 0 && v < C.MAY_MOVE; };      // action(): hN==0 || (map<MAY_MOVE && map!=0)

  // ------------------------------------------------------------------ мышь
  cv.addEventListener('contextmenu', e => e.preventDefault());
  cv.addEventListener('wheel', e => { e.preventDefault(); const c = cellAt(e); zoomAt(e.deltaY < 0 ? 1.2 : 1 / 1.2, c.mx, c.my); }, { passive: false });
  function pickAt(x, y) {
    const b = C.buildingAt(lv.map, x, y);
    if (b) { curBuild = b.center; setTool('building'); }
    else { const v = lv.map[y * 64 + x]; curTile = v; setTool(tool === 'pick' ? 'brush' : (tool === 'rect' ? 'rect' : 'brush')); }
    refreshPalettes();
  }
  cv.addEventListener('mousedown', e => {
    const c = cellAt(e);
    if (e.button === 1 || tool === 'hand' || spaceDown || !editable()) { drag = { kind: 'pan', mx: c.mx, my: c.my, ox: view.ox, oy: view.oy }; e.preventDefault(); return; }
    if (!c.in) return;
    if (e.button === 2) {
      if (tool === 'hero') { const k = heroAt(c.x, c.y); if (k) { snapshot(); lv.heroes.splice(k - 1, 1); selHero = -1; changed('heroes'); } return; }
      pickAt(c.x, c.y); return;
    }
    if (e.button !== 0) return;
    if (tool === 'pick') pickAt(c.x, c.y);
    else if (tool === 'brush') { snapshot(); drag = { kind: 'paint', x: c.x, y: c.y }; paintAt(c.x, c.y); changed('map', true); }
    else if (tool === 'rect') { drag = { kind: 'rect', x0: c.x, y0: c.y, x1: c.x, y1: c.y }; scheduleDraw(); }
    else if (tool === 'building') {
      if (!C.canPlaceBuilding(lv.map, c.x, c.y)) { status(t('Здание сюда не помещается: рядом другое здание или край карты (центр в клетках 2..61)')); return; }
      snapshot(); C.placeBuilding(lv.map, curBuild, c.x, c.y); redrawMap(c.x - 3, c.y - 3, c.x + 3, c.y + 3); changed('map');
    } else if (tool === 'erase') {
      const b = C.buildingAt(lv.map, c.x, c.y);
      if (b) { snapshot(); C.eraseBuilding(lv.map, b); redrawMap(b.x - 3, b.y - 3, b.x + 3, b.y + 3); changed('map'); }
    } else if (tool === 'hero') {
      const k = heroAt(c.x, c.y);
      if (k) { selHero = k - 1; drag = { kind: 'hero', k: k - 1, moved: false }; refreshHeroes(); scheduleDraw(); }
      else {
        if (!passable(c.x, c.y)) { status(t('Героя можно ставить только на проходимую клетку (тайл 1..40)')); return; }
        snapshot(); lv.heroes.push({ o: heroOwner, t: heroType, x: c.x, y: c.y, px: 0, py: 0 }); selHero = lv.heroes.length - 1; changed('heroes');
      }
    }
  });
  window.addEventListener('mousemove', e => {
    const c = cellAt(e);
    if (drag && drag.kind === 'pan') { view.ox = drag.ox + c.mx - drag.mx; view.oy = drag.oy + c.my - drag.my; scheduleDraw(); return; }
    if (e.target === cv || drag) {
      const nh = c.in ? c : null;
      if (!hover || !nh || hover.x !== nh.x || hover.y !== nh.y) { hover = nh; showHover(); scheduleDraw(); }
    }
    if (!drag || !c.in) return;
    if (drag.kind === 'paint' && (c.x !== drag.x || c.y !== drag.y)) { lineCells(drag.x, drag.y, c.x, c.y, paintAt); drag.x = c.x; drag.y = c.y; changed('map', true); }
    else if (drag.kind === 'rect') { drag.x1 = c.x; drag.y1 = c.y; scheduleDraw(); }
    else if (drag.kind === 'hero') {
      const h = lv.heroes[drag.k];
      if ((h.x !== c.x || h.y !== c.y) && !heroAt(c.x, c.y) && passable(c.x, c.y)) { if (!drag.moved) { snapshot(); drag.moved = true; } h.x = c.x; h.y = c.y; changed('heroes', true); }
    }
  });
  window.addEventListener('mouseup', () => {
    if (!drag) return;
    const d = drag; drag = null;
    if (d.kind === 'rect') {
      const [x0, y0, x1, y1] = rectOf(d);
      snapshot();
      for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) C.paintTile(lv.map, x, y, curTile);
      redrawMap(x0 - 2, y0 - 2, x1 + 2, y1 + 2); changed('map');
    } else if (d.kind === 'paint' || (d.kind === 'hero' && d.moved)) changed(d.kind === 'paint' ? 'map' : 'heroes');
    scheduleDraw();
  });
  cv.addEventListener('mouseleave', () => { if (!drag) { hover = null; scheduleDraw(); } });

  function showHover() {
    if (!hover || !editable()) { status(''); return; }
    const { x, y } = hover, v = lv.map[y * 64 + x], ti = C.tileIndex(lv.map, x, y);
    const mayBld = lv.land === 2 || lv.land === 3 ? 5 : 14;
    let s = `<b>${x},${y}</b> · ${t('тайл')} <b>${v}</b>` + (ti !== v ? ` (${t('спрайт')} ${ti})` : '') + ' · ' + t(groupOf(Math.min(v, 119))) + ' · ' +
      (v === 0 ? t('граница') : v < C.MAY_MOVE ? t('проходимо') : t('непроходимо')) + (v >= 1 && v <= mayBld ? ' · ' + t('строить можно') : '');
    const b = C.buildingAt(lv.map, x, y);
    if (b) s += ' · ' + t('здание {c}, центр {x},{y}', { c: b.center, x: b.x, y: b.y });
    const k = heroAt(x, y);
    if (k) { const h = lv.heroes[k - 1]; s += ' · ' + t('герой №{k}', { k }) + ': ' + heroTitle(h); }
    status(s);
  }
  function status(html) { $('status').innerHTML = html; }
  const heroName = h => h.o === 4 ? ONAME[h.t] : HNAME[h.t];
  const heroTitle = h => `${heroName(h) !== undefined ? t(heroName(h)) : t('тип') + ' ' + h.t} (${h.t}), ${OWNER_NAME[h.o] ? t(OWNER_NAME[h.o]) : h.o}`;

  // ------------------------------------------------------------------ клавиатура
  window.addEventListener('keydown', e => {
    const inField = /^(INPUT|SELECT|TEXTAREA)$/.test(document.activeElement.tagName);
    if ((e.ctrlKey || e.metaKey) && !inField) {
      if (e.key === 'z' || e.key === 'я') { e.preventDefault(); e.shiftKey ? doRedo() : doUndo(); return; }
      if (e.key === 'y' || e.key === 'н') { e.preventDefault(); doRedo(); return; }
    }
    if (inField || e.ctrlKey || e.metaKey || e.altKey) return;
    if (e.code === 'Space') { spaceDown = true; e.preventDefault(); return; }
    if ((e.key === 'Delete' || e.key === 'Backspace') && selHero >= 0 && editable()) { snapshot(); lv.heroes.splice(selHero, 1); selHero = -1; changed('heroes'); return; }
    const k = { KeyB: 'brush', KeyR: 'rect', KeyI: 'pick', KeyU: 'building', KeyE: 'erase', KeyH: 'hand' }[e.code];
    if (k) { setTool(k); return; }
    if (e.key === '+' || e.key === '=') zoomAt(1.25, cv.clientWidth / 2, cv.clientHeight / 2);
    if (e.key === '-') zoomAt(0.8, cv.clientWidth / 2, cv.clientHeight / 2);
    if (e.key === '0') fit();
  });
  window.addEventListener('keyup', e => { if (e.code === 'Space') spaceDown = false; });

  // ------------------------------------------------------------------ вкладки и инструменты
  function setTab(n) {
    document.querySelectorAll('#tabs button').forEach(b => b.classList.toggle('on', b.dataset.tab === n));
    document.querySelectorAll('.tab').forEach(s => s.classList.toggle('on', s.id === 'tab-' + n));
    if (n === 'heroes') setTool('hero'); else if (n === 'map' && tool === 'hero') setTool(mapTool);
    if (n === 'level') refreshLevel();
    if (n === 'task') refreshTask();
  }
  document.querySelectorAll('#tabs button').forEach(b => b.addEventListener('click', () => setTab(b.dataset.tab)));
  function setTool(n) {
    tool = n; if (n !== 'hero') mapTool = n;
    document.querySelectorAll('[data-tool]').forEach(b => b.classList.toggle('on', b.dataset.tool === n));
    cv.style.cursor = n === 'hand' ? 'grab' : 'crosshair';
    refreshPalettes(); scheduleDraw();
  }
  document.querySelectorAll('[data-tool]').forEach(b => b.addEventListener('click', () => setTool(b.dataset.tool)));
  for (const k of Object.keys(opt)) {
    const el = $('opt' + k[0].toUpperCase() + k.slice(1));
    el.checked = opt[k];
    el.addEventListener('change', () => {
      opt[k] = el.checked;
      if (k === 'mono') { heroCache.clear(); redrawMap(); refreshPalettes(true); }
      if (k === 'fog') { updateFog(); redrawMap(); }
      scheduleDraw();
    });
  }
  $('zIn').onclick = () => zoomAt(1.25, cv.clientWidth / 2, cv.clientHeight / 2);
  $('zOut').onclick = () => zoomAt(0.8, cv.clientWidth / 2, cv.clientHeight / 2);
  $('zFit').onclick = fit;

  // ------------------------------------------------------------------ палитры
  let palKey = '';
  function canvasOf(f, size) { const c = document.createElement('canvas'); c.width = c.height = size; const cg = c.getContext('2d'); cg.imageSmoothingEnabled = false; f(cg); return c; }
  function refreshPalettes(force) {
    const key = landKey() + ':' + colors() + ':' + heroOwner;
    if (force || key !== palKey) {
      palKey = key;
      const pt = $('palTiles'); pt.innerHTML = '';
      for (let ti = 0; ti <= 101; ti++) {
        const c = canvasOf(cg => drawTileTo(cg, ti, 0, 0, 32), 32);
        c.title = `${t('тайл')} ${ti} - ${t(groupOf(ti))} (${ti >= 1 && ti < C.MAY_MOVE ? t('проходимо') : t('непроходимо')})`;
        c.dataset.t = ti; c.onclick = () => { curTile = ti; setTool(tool === 'rect' ? 'rect' : 'brush'); };
        pt.appendChild(c);
      }
      const pb = $('palBuild'); pb.innerHTML = '';
      for (let b = 102; b <= 119; b++) {
        const c = buildingCanvas(b, 1); c.title = t('здание, центр {c}', { c: b }) + ' - ' + t(groupOf(b));
        c.dataset.b = b; c.onclick = () => { curBuild = b; setTool('building'); };
        pb.appendChild(c);
      }
      const ph = $('palHeroes'); ph.innerHTML = '';
      const n = heroOwner === 4 ? 7 : 24;
      for (let ht = 0; ht < n; ht++) {
        const d = document.createElement('div'); d.className = 'h'; d.dataset.t = ht; d.title = `${t('тип')} ${ht}`;
        const c = canvasOf(cg => { cg.fillStyle = colors()[1].length ? 'rgb(' + colors()[1] + ')' : '#ddd'; cg.fillRect(0, 0, 32, 32); cg.drawImage(heroSprite(heroOwner, ht), 0, 0, 32, 32); }, 32);
        d.append(c, document.createTextNode(ht + ' ' + t(heroOwner === 4 ? ONAME[ht] : HNAME[ht])));
        d.onclick = () => { heroType = ht; if (selHero >= 0 && editable()) { snapshot(); lv.heroes[selHero].t = ht; changed('heroes'); } setTool('hero'); refreshPalettes(true); };
        ph.appendChild(d);
      }
    }
    document.querySelectorAll('#palTiles canvas').forEach(c => c.classList.toggle('on', +c.dataset.t === curTile && (tool === 'brush' || tool === 'rect')));
    document.querySelectorAll('#palBuild canvas').forEach(c => c.classList.toggle('on', +c.dataset.b === curBuild && tool === 'building'));
    document.querySelectorAll('#palHeroes .h').forEach(c => c.classList.toggle('on', +c.dataset.t === heroType));
    const cur = $('curTile'); cur.innerHTML = '';
    if (tool === 'building') cur.append(buildingCanvas(curBuild, 1), document.createTextNode(`${t('здание')} ${curBuild}`));
    else cur.append(canvasOf(cg => drawTileTo(cg, curTile, 0, 0, 32), 32), document.createTextNode(`${t('тайл')} ${curTile}`));
  }
  $('hSide').onchange = () => {
    heroOwner = +$('hSide').value; heroType = Math.min(heroType, heroOwner === 4 ? 6 : 23);
    if (selHero >= 0 && editable()) { snapshot(); lv.heroes[selHero].o = heroOwner; lv.heroes[selHero].t = heroType; changed('heroes'); }
    refreshPalettes(true);
  };

  // ------------------------------------------------------------------ герои: список и правка
  function refreshHeroes() {
    if (!editable()) { $('heroList').tBodies[0].innerHTML = ''; $('heroEdit').innerHTML = ''; return; }
    const tb = $('heroList').tBodies[0]; tb.innerHTML = '';
    lv.heroes.forEach((h, k) => {
      const tr = document.createElement('tr'); if (k === selHero) tr.className = 'on';
      tr.innerHTML = `<td>${k + 1}</td><td class="s${h.o}">${h.o}</td><td>${h.t} ${heroName(h) !== undefined ? t(heroName(h)) : ''}</td><td>${h.x}</td><td>${h.y}</td><td>${h.px > 0 ? h.px + ',' + h.py : ''}</td>`;
      tr.onclick = () => { selHero = k; goto(h.x, h.y, false); refreshHeroes(); };
      tb.appendChild(tr);
    });
    const per = { 0: 0, 1: 0, 2: 0, 4: 0 }; lv.heroes.forEach(h => { if (h.o in per) per[h.o]++; });
    $('heroCount').textContent = t('Записей: {n} · людей {a}, кунгов {b}, пленников {c}, предметов {d} (не больше 48 / 48 / 5 / 44, всего 123; в .HER помещается около 120)', { n: lv.heroes.length, a: per[0], b: per[1], c: per[2], d: per[4] });
    const he = $('heroEdit');
    if (selHero < 0 || selHero >= lv.heroes.length) { he.innerHTML = '<span class="hint">' + t('Герой не выбран') + '</span>'; return; }
    const h = lv.heroes[selHero], names = h.o === 4 ? ONAME : HNAME;
    he.innerHTML = `<b>${t('Герой №{k}', { k: selHero + 1 })}</b>
      <div class="row">${t('чей')} <select id="heS">${[0, 1, 2, 4].map(s => `<option value="${s}"${s === h.o ? ' selected' : ''}>${s} - ${t(OWNER_NAME[s])}</option>`).join('')}</select>
      ${t('тип')} <select id="heT">${names.map((n, k) => `<option value="${k}"${k === h.t ? ' selected' : ''}>${k} ${t(n)}</option>`).join('')}</select></div>
      <div class="row">x <input id="heX" type="number" min="0" max="63" value="${h.x}"> y <input id="heY" type="number" min="0" max="63" value="${h.y}"> <button id="heDel">${t('Удалить')}</button></div>
      <div class="row">${t('патруль')} x <input id="hePX" type="number" min="0" max="63" value="${h.px}"> y <input id="hePY" type="number" min="0" max="63" value="${h.py}" title="${t('0 в x - без патруля. Патруль только у людей и кунгов')}"></div>`;
    const upd = (f, v) => { snapshot(); h[f] = v; changed('heroes'); };
    const num = e => Math.max(0, Math.min(63, +e.target.value | 0));
    $('heS').onchange = e => { snapshot(); h.o = +e.target.value; if (h.o === 4) h.t = Math.min(h.t, 6); changed('heroes'); };
    $('heT').onchange = e => upd('t', +e.target.value);
    $('heX').onchange = e => upd('x', num(e)); $('heY').onchange = e => upd('y', num(e));
    $('hePX').onchange = e => upd('px', num(e)); $('hePY').onchange = e => upd('py', num(e));
    $('heDel').onclick = () => { snapshot(); lv.heroes.splice(selHero, 1); selHero = -1; changed('heroes'); };
  }

  // ------------------------------------------------------------------ вкладка «Уровень»
  const LANDS = ['41SPR', '42SPR', '43SPR', '44SPR (кунги в игре v0.04)', '45SPR (люди в игре v0.04)'];
  const mpsCache = {};
  function drawGameMini() {                                   // режим «карта» в игре: экран атрибута %00101001 - бумага 5, чернила 1
    const n = String(Math.min(lv.land, 4) + 1);
    const mps = mpsCache[n] || (mpsCache[n] = C.b64dec(window.BR2_DATA.mps[n]));
    const px = C.gameMap(lv.map, lv.heroes, mps), mc = $('gameMini'), g = mc.getContext('2d'), im = g.createImageData(192, 192);
    const ink = ZXRGB[1], paper = ZXRGB[5];
    for (let i = 0; i < px.length; i++) { const c = px[i] ? ink : paper; im.data.set(c, i * 4); im.data[i * 4 + 3] = 255; }
    g.putImageData(im, 0, 0);
  }
  $('gameMini').onclick = e => {
    if (!lv) return;
    const r = e.currentTarget.getBoundingClientRect();
    const x = Math.floor((e.clientX - r.left) / r.width * 64), y = Math.floor((e.clientY - r.top) / r.height * 64);
    goto(Math.max(0, Math.min(63, x)), Math.max(0, Math.min(63, y)), false);
  };
  function refreshLevel() {
    const f = $('levelForm');
    if (!editable()) { f.innerHTML = ''; return; }
    f.innerHTML = `<div class="f"><span>${t('Ландшафт')} <small>${t('байт [0][0] файла .MAP')}</small></span><select id="lfLand">${LANDS.map((n, i) => `<option value="${i}"${i === lv.land ? ' selected' : ''}>${i + 1} - ${t(n)}</option>`).join('')}${lv.land > 4 ? `<option selected value="${lv.land}">${lv.land + 1} (?)</option>` : ''}</select></div>
      <div class="f"><span>${t('Цвет поля и туман для стороны')} <small>${t('только вид в редакторе: в .MAP не записывается; игра берёт COLOR и MASTER из своих данных')}</small></span><select id="lfSide"><option value="0"${lv.side === 0 ? ' selected' : ''}>${t('люди (COLOR #28, тумана нет)')}</option><option value="1"${lv.side === 1 ? ' selected' : ''}>${t('кунги (COLOR #30, туман)')}</option></select></div>`;
    $('lfLand').onchange = e => { snapshot(); lv.land = +e.target.value; changed('land'); };
    $('lfSide').onchange = e => { snapshot(); lv.side = +e.target.value; changed('land'); };
    drawGameMini();
    const b = C.biterize(lv.map, lv.heroes), mc = $('miniView'), mgx = mc.getContext('2d'), im = mgx.createImageData(32, 32);
    const pc = [[40, 40, 40], [220, 60, 60], [60, 200, 60], [60, 120, 240]];
    for (let i = 0; i < 32; i++) for (let j = 0; j < 8; j++) for (let q = 0; q < 4; q++) {
      const v = (b.mini[i * 8 + j] >> (q * 2)) & 3, c = pc[v], o = (i * 32 + j * 4 + q) * 4;
      im.data[o] = c[0]; im.data[o + 1] = c[1]; im.data[o + 2] = c[2]; im.data[o + 3] = 255;
    }
    mgx.putImageData(im, 0, 0);
    $('miniInfo').textContent = t('Тип уровня (число областей - 1): {n}. Значение квадрата: 0 - препятствие, 1..3 - номер области (у единой карты все 2, байт #AA).', { n: b.type });
  }

  // ------------------------------------------------------------------ задание
  let lastTaskInput = null;
  function taskLines(el) { const a = el.value.split('\n'); while (a.length && a[a.length - 1] === '') a.pop(); return a; }
  function buildTask() {
    for (const [id, key] of [['taskTsk', 'tsk'], ['taskTs2', 'ts2']]) {
      const el = $(id); let snap = false;
      el.addEventListener('focus', () => { lastTaskInput = el; snap = false; });
      el.addEventListener('input', () => {
        if (!editable()) return;
        if (!snap) { snapshot(); snap = true; }
        ensureTask(); lv.task[key] = taskLines(el); changed('task', true);
      });
    }
    const gl = $('glyphs');
    for (let i = 0; i < C.CODE.length; i++) {
      const c = glyphCanvas(i, [255, 255, 255], [0, 0, 0]); c.style.width = c.style.height = '20px';
      const ch = C.glyphChar(i); c.title = `${i}: ${ch}`;
      c.onclick = () => {
        const inp = lastTaskInput || $('taskTsk'), s = inp.selectionStart ?? inp.value.length, e = inp.selectionEnd ?? s;
        inp.value = inp.value.slice(0, s) + ch + inp.value.slice(e); inp.focus(); inp.setSelectionRange(s + ch.length, s + ch.length);
        inp.dispatchEvent(new Event('input'));
      };
      gl.appendChild(c);
    }
  }
  $('taskSample').innerHTML = D.tasks.map((x, i) => `<option value="${i}">${x.name}</option>`).join('');
  $('bTaskSample').onclick = () => {
    if (!editable()) return;
    const tk = D.tasks[+$('taskSample').value]; snapshot();
    lv.task = C.taskFromBytes(C.b64dec(tk.tsk), C.b64dec(tk.ts2)); changed('task'); refreshTask();
  };
  function ensureTask() { if (!lv.task) lv.task = C.taskFromBytes(null, null); }
  function drawTaskPreview(cvEl, lines, w, h) {
    const pg = cvEl.getContext('2d'), tmp = C.taskDecode(C.taskEncode(lines, w, h), w, h); void tmp;
    pg.fillStyle = '#000'; pg.fillRect(0, 0, cvEl.width, cvEl.height);
    const y1 = (h - lines.length) >> 1;
    lines.forEach((s, y) => {
      const gl = C.encodeLine(s).glyphs, x1 = Math.max(0, (w - gl.length) >> 1);
      gl.slice(0, w).forEach((gi, x) => { if (gi * 8 + 8 <= FONT.length) pg.drawImage(glyphCanvas(gi, [255, 255, 0], [0, 0, 0]), (x1 + x) * 8, (y1 + y) * 8); });
    });
  }
  function refreshTask() {
    if (!editable()) return;
    const tk = lv.task || { tsk: [], ts2: [] };
    for (const [id, key, w, h, info, pv] of [['taskTsk', 'tsk', 20, 4, 'tskInfo', 'tskPreview'], ['taskTs2', 'ts2', 32, 24, 'ts2Info', 'ts2Preview']]) {
      const el = $(id);
      if (document.activeElement !== el) el.value = tk[key].join('\n');
      const lines = tk[key], chk = C.taskCheck(lines, w, h);
      const bad = [...new Set(chk.lines.flatMap(r => r.bad.map(b => '«' + b.ch + '»')))];
      $(info).textContent = t('строк {n} из {h}', { n: lines.length, h }) + (chk.tooLong ? ' · ' + t('есть строки длиннее {w} знаков', { w }) : '') + (bad.length ? ' · ' + t('нет в шрифте:') + ' ' + bad.join(' ') : '');
      $(info).style.color = chk.tooLong || chk.tooMany || bad.length ? 'var(--err)' : '';
      el.classList.toggle('bad', chk.tooLong || chk.tooMany || bad.length > 0);
      drawTaskPreview($(pv), lines, w, h);
    }
  }

  // ------------------------------------------------------------------ проверка
  function refreshIssues() {
    issues = lv ? C.validate(lv) : [];
    const ul = $('issues'); ul.innerHTML = '';
    if (!issues.length) ul.innerHTML = '<li class="okk">✔ ' + t('Ошибок и предупреждений нет') + '</li>';
    for (const r of issues.slice(0, 300)) {
      const li = document.createElement('li'); li.className = r.level;
      li.textContent = r.msg + (r.x !== undefined ? `  [${r.x},${r.y}]` : '');
      if (r.x !== undefined) li.onclick = () => goto(r.x, r.y, true);
      ul.appendChild(li);
    }
    const ne = issues.filter(r => r.level === 'error').length, nw = issues.length - ne, b = $('chkBadge');
    b.textContent = ne ? `✖${ne}` : nw ? `▲${nw}` : '';
    b.className = ne ? 'err' : nw ? 'warn' : '';
    scheduleDraw();
  }
  function goto(x, y, zoom) {
    const w = cv.clientWidth, h = cv.clientHeight;
    if (zoom && view.z < 2) view.z = 2;
    view.ox = w / 2 - (x * 16 + 8) * view.z; view.oy = h / 2 - (y * 16 + 8) * view.z;
    flash = { x, y }; scheduleDraw();
    setTimeout(() => { flash = null; scheduleDraw(); }, 1200);
  }

  // ------------------------------------------------------------------ общее обновление
  let issueTimer = null;
  function changed(what, light) {
    setDirty(true); partCache = null;
    if (what === 'land') { heroCache.clear(); updateFog(); redrawMap(); refreshPalettes(); }
    if (what === 'heroes') { updateFog(); if (fog) redrawMap(); refreshHeroes(); }
    if (what === 'task') refreshTask();
    if (document.querySelector('#tab-level.on')) refreshLevel();
    clearTimeout(issueTimer);
    issueTimer = setTimeout(refreshIssues, light ? 250 : 0);
    scheduleDraw();
  }
  const baseName = () => /^\d+$/.test(lv.name) ? '4_' + lv.name : lv.name;
  function refreshAll() {
    $('lvName').value = lv ? lv.name : '';
    updateFog(); redrawMap(); refreshPalettes(true); refreshHeroes(); refreshLevel(); refreshTask(); refreshIssues(); scheduleDraw();
    document.title = (lv ? lv.name + ' - ' : '') + t('Редактор уровней Black Raven 2');
  }
  function setLevel(l, msg) {
    lv = l; undo = []; redo = []; selHero = -1; partCache = null; setDirty(false);
    atlasCache.clear(); heroCache.clear(); refreshAll(); fit();
    status(msg || '');
  }
  /** подставить сгенерированный уровень; прежний возвращается Ctrl+Z */
  function replaceLevel(l, msg) {
    snapshot(); lv = l; selHero = -1; partCache = null; atlasCache.clear(); heroCache.clear(); refreshAll(); fit(); status(msg || '');
  }
  $('lvName').addEventListener('change', () => {
    const v = $('lvName').value.trim().replace(/[^\w.-]+/g, '_');
    if (!lv || !v) return; lv.name = v; $('lvName').value = v; setDirty(true);
  });

  // ------------------------------------------------------------------ файлы
  async function streamThrough(u, ts) { const s = new Blob([u]).stream().pipeThrough(ts); return new Uint8Array(await new Response(s).arrayBuffer()); }
  function download(name, data, type) {
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([data], { type: type || 'application/octet-stream' })); a.download = name;
    document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 2000);
  }
  const confirmDiscard = () => !dirty || confirm(t('Есть несохранённые правки. Продолжить без сохранения?'));
  $('fMap').onchange = async e => {
    const files = Array.from(e.target.files); e.target.value = '';
    if (!files.length || !confirmDiscard()) return;
    try {
      const by = {}; for (const f of files) by[f.name.replace(/^.*\./, '').toLowerCase()] = f;
      if (!by.map) throw new Error(t('Нужен файл .MAP (и желательно .HER рядом)'));
      const base = by.map.name.replace(/\.map$/i, ''), rdf = async f => new Uint8Array(await f.arrayBuffer());
      const herB = by.her ? await rdf(by.her) : new Uint8Array(496).fill(255);
      const l = C.levelFromFiles(await rdf(by.map), herB, base);
      if (by.tsk || by.ts2) l.task = C.taskFromBytes(by.tsk ? await rdf(by.tsk) : null, by.ts2 ? await rdf(by.ts2) : null);
      setLevel(l, t('Открыто: {f}', { f: files.map(f => f.name).join(', ') }) + (l.oldFormat ? ' - ' + t('старый формат .MAP (4096 байт), миникарта будет построена при сохранении') : ''));
    } catch (err) { alert(err.message); }
  };
  $('fPrj').onchange = async e => {
    const f = e.target.files[0]; e.target.value = '';
    if (!f || !confirmDiscard()) return;
    try { setLevel(C.levelFromProject(JSON.parse(await f.text())), t('Открыт проект {f}', { f: f.name })); } catch (err) { alert(err.message); }
  };
  $('bSavePrj').onclick = () => {
    if (!lv) return;
    download(baseName() + '.br2level.json', JSON.stringify(C.levelToProject(lv), null, 1), 'application/json'); setDirty(false);
  };
  function preExport() {
    if (!lv) return false;
    refreshIssues();
    const errs = issues.filter(r => r.level === 'error');
    if (errs.length && !confirm(t('Проверка нашла ошибки ({n}):', { n: errs.length }) + '\n\n' + errs.slice(0, 12).map(r => '• ' + r.msg).join('\n') + '\n\n' + t('Всё равно экспортировать? (игра может работать неправильно)'))) { setTab('check'); return false; }
    return true;
  }
  function levelFiles() {
    const n = baseName(), f = { [n + '.MAP']: C.levelToMap(lv), [n + '.HER']: C.levelToHer(lv) };
    if (lv.task) {
      const tn = /^4_\d+$/.test(n) ? '4_' + n.slice(2).padStart(3, '0') : n;
      if (lv.task.tsk.length || lv.task.rawTsk) f[tn + '.TSK'] = C.taskToBytes(lv.task, 'tsk');
      if (lv.task.ts2.length || lv.task.rawTs2) f[tn + '.TS2'] = C.taskToBytes(lv.task, 'ts2');
    }
    return f;
  }
  $('bExpMap').onclick = () => {
    if (!preExport()) return;
    const f = levelFiles(), n = baseName();
    download(n + '.MAP', f[n + '.MAP']);
    setTimeout(() => download(n + '.HER', f[n + '.HER']), 300);
    status(t('Записаны {a} (4353 байта) и {b} (496 байт)', { a: n + '.MAP', b: n + '.HER' })); setDirty(false);
  };
  $('bExpDir').onclick = async () => {
    if (!preExport()) return;
    const files = levelFiles();
    if (window.showDirectoryPicker) {
      try {
        const dir = await window.showDirectoryPicker({ id: 'br2-levels', mode: 'readwrite' });
        for (const [n, u] of Object.entries(files)) { const fh = await dir.getFileHandle(n, { create: true }); const w = await fh.createWritable(); await w.write(u); await w.close(); }
        status(t('Записан каталог {d} ({f})', { d: dir.name, f: Object.keys(files).join(', ') })); setDirty(false); return;
      } catch (err) { if (err.name === 'AbortError') return; console.warn(err); }
    }
    download(baseName() + '.zip', C.zipStore(files), 'application/zip');
    status(t('Записан {f}', { f: baseName() + '.zip' })); setDirty(false);
  };
  $('bNew').onclick = async () => {
    if (!confirmDiscard()) return;
    const r = await ask(t('Новый уровень'), `<p>${t('Номер уровня (файлы 4_N.MAP и 4_N.HER):')} <input id="dlgName" value="200" size="8"></p>
      <p>${t('Ландшафт')}: <select id="dlgLand">${LANDS.map((n, i) => `<option value="${i}"${i === 4 ? ' selected' : ''}>${i + 1} - ${t(n)}</option>`).join('')}</select></p>
      <p class="hint">${t('Карта - фон 1 с границей 0, героев нет (как новая карта в MAPPER).')}</p>`, () => [$('dlgName').value.trim() || '200', +$('dlgLand').value]);
    if (!r) return;
    setLevel(C.newLevel(r[0].replace(/[^\w.-]+/g, '_'), r[1], r[1] === 3 ? 1 : 0), t('Новый уровень')); setDirty(true);
  };
  $('bUndo').onclick = doUndo; $('bRedo').onclick = doRedo;
  window.addEventListener('beforeunload', e => { if (dirty) { e.preventDefault(); e.returnValue = ''; } });
  function ask(title, html, get) {
    return new Promise(res => {
      const d = $('dlg'); $('dlgBody').innerHTML = `<h3>${title}</h3>` + html; d.returnValue = '';
      d.onclose = () => res(d.returnValue === 'ok' ? get() : null); d.showModal();
    });
  }

  // ------------------------------------------------------------------ встроенные уровни игры
  const SAMPLES = D.levels;
  const SAMPLE_NOTE = { '4_10': 'уровень людей в игре v0.04', '4_4': 'уровень кунгов в игре v0.04', '4_100': 'вшит в образ демо' };
  function openSample(s, msg) {
    const l = C.levelFromFiles(C.b64dec(s.map), C.b64dec(s.her), s.name);
    const tk = D.tasks.find(x => x.name === s.name.replace(/^4_(\d+)$/, (m, d) => '4_' + d.padStart(3, '0')));
    if (tk) l.task = C.taskFromBytes(C.b64dec(tk.tsk), C.b64dec(tk.ts2));
    setLevel(l, msg || t('Открыт уровень игры {name}', { name: s.name }));
  }
  $('bSamples').onclick = async () => {
    if (!confirmDiscard()) return;
    const i = await ask(t('Уровни игры'), `<p class="hint">${t('Карты автора из архива демо (br2/archive/.../MAP): откройте любой, чтобы посмотреть, как он устроен, или взять за основу своего.')}</p>
      <select id="dlgSmp" size="12" style="width:100%">${SAMPLES.map((s, k) => `<option value="${k}"${k ? '' : ' selected'}>${s.name}${SAMPLE_NOTE[s.name] ? ' - ' + t(SAMPLE_NOTE[s.name]) : ''}</option>`).join('')}</select>`, () => $('dlgSmp').value);
    if (i !== null && i !== '') openSample(SAMPLES[+i]);
  };

  // ------------------------------------------------------------------ язык, старт
  const langSel = $('lang');
  langSel.value = I18N.lang;
  langSel.onchange = () => { I18N.setLang(langSel.value); I18N.applyDom(document.body); refreshAll(); status(''); };
  I18N.applyDom(document.body);
  buildTask();
  new ResizeObserver(resize).observe(cv);
  resize();
  const q = new URLSearchParams(location.search);       // для снимков и отладки: ?open=4_10&tab=heroes&opts=parts,fog&sel=3&zoom=3&at=20,30
  openSample(SAMPLES.find(s => s.name === (q.get('open') || '4_10')) || SAMPLES[0]);
  if (q.get('proj')) fetch(q.get('proj')).then(r => r.json()).then(o => { setLevel(C.levelFromProject(o), t('Открыт проект {f}', { f: q.get('proj') })); afterOpen(); }).catch(e => status(String(e)));
  else afterOpen();
  function afterOpen() {
  (q.get('opts') || '').split(',').filter(Boolean).forEach(k => { if (k in opt) { opt[k] = true; $('opt' + k[0].toUpperCase() + k.slice(1)).checked = true; } });
  if (q.get('side')) { lv.side = +q.get('side'); refreshAll(); }
  if (q.get('opts')) { updateFog(); redrawMap(); }
  if (q.get('tab')) setTab(q.get('tab'));
  if (q.get('sel')) { selHero = +q.get('sel'); refreshHeroes(); }
  if (q.get('at')) { const [x, y] = q.get('at').split(',').map(Number); view.z = +(q.get('zoom') || 3); goto(x, y, false); }
  if (q.get('tasksample')) { $('taskSample').value = q.get('tasksample'); $('bTaskSample').click(); }
  if (q.get('dlg') === 'samples') $('bSamples').click();
  }
  window.BR2App = { get level() { return lv; }, setLevel, replaceLevel, confirmDiscard: () => confirmDiscard(), goto, setTab, setTool };
})();

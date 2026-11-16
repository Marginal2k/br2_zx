// snapshot now; replay up to FR frames; if the game crashes (I=#3F after #BE), replay again with watchWrites on the flpSEL address and report the writers
const FR = +q.get('fr') || 60;
zx.pause();
const snap = zx.saveSnapshot('szx');
async function trial(watch) {
  await zx.loadFile(snap, 'x.szx'); zx.pause();
  if (watch) zx.watchWrites(watch[0], watch[1]);
  let seen = false, crashAt = -1, pcs = [];
  for (let f = 0; f < FR; f++) { F(1); const g = zx.captureRegisters(); if (g.i === 0xBE) seen = true; if (seen && g.i === 0x3F) { crashAt = f; break; } }
  return { crashAt, w: watch ? zx.stopWrites() : null };
}
const t = await trial(null);
if (t.crashAt < 0) return 'nocrash';
const lo = +(q.get('lo') || 0xDD3D), hi = +(q.get('hi') || 0xDD3F);
const t2 = await trial([lo, hi]);
const b0 = Array.from(zx.peekBank(0).slice(0x1D3D, 0x1D45));
return { crashAt: t.crashAt, crashAt2: t2.crashAt, writers: t2.w.map(h => ({ pc: h.pc.toString(16), n: h.count, callers: (h.callers || []).slice(0, 4) })), b0 };

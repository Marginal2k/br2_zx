// determinism check: snapshot now, then N times: restore, run FR frames, report whether the game crashed to ROM (I=#3F after I=#BE)
const N = +q.get('n') || 8, FR = +q.get('fr') || 60;
zx.pause();
const snap = zx.saveSnapshot('szx');
const out = [];
for (let k = 0; k < N; k++) {
  await zx.loadFile(snap, 'x.szx'); zx.pause();
  let seen = false, crashAt = -1;
  for (let f = 0; f < FR; f++) { F(1); const g = zx.captureRegisters(); if (g.i === 0xBE) seen = true; if (seen && g.i === 0x3F) { crashAt = f; break; } }
  const g = zx.captureRegisters();
  out.push(crashAt < 0 ? 'ok' : 'CRASH@' + crashAt);
}
return out.join(' ');

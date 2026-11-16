// single-step N instructions (q.n, default 300000) and return the last 100 non-sequential transitions (deduplicated runs), plus final regs
zx.pause();
const N = +q.get('n') || 300000; const ring = []; let prev = -100, last = '', rep = 0;
for (let i = 0; i < N; i++) {
  const g = zx.captureRegisters();
  if (Math.abs(g.pc - prev) > 4 || g.pc < prev) {
    const key = prev.toString(16) + '->' + g.pc.toString(16);
    if (key === last) rep++; else { if (rep) ring[ring.length - 1] += ' x' + (rep + 1); rep = 0; last = key; ring.push(key + ':' + [g.sp, g.hl, g.de, g.bc, g.a].map(v => v.toString(16)).join('/')); if (ring.length > 100) ring.shift(); }
  }
  prev = g.pc; zx.step(1);
}
return ring.join(' ');

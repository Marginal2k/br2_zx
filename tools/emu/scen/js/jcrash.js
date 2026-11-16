// single-step until PC reaches q.stop (hex, default e114) or n instructions; return the last 60 non-sequential transitions
zx.pause();
const N = +q.get('n') || 1000000; const stop = parseInt(q.get('stop') || 'e114', 16); const ring = []; let prev = -100;
let i = 0;
for (; i < N; i++) {
  const g = zx.captureRegisters();
  if (g.pc === stop || (stop === 0x1 && g.pc < 0x4000)) break;
  if (Math.abs(g.pc - prev) > 4 || g.pc < prev) { ring.push(prev.toString(16) + '->' + g.pc.toString(16) + ':' + [g.sp, g.hl, g.de, g.bc, g.a].map(v => v.toString(16)).join('/')); if (ring.length > 60) ring.shift(); }
  prev = g.pc; zx.step(1);
}
return 'steps=' + i + ' ' + ring.join(' ');

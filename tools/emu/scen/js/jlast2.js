zx.pause();
const N = +q.get('n') || 1000000; const ring = [];
let i = 0, prevpc = 0;
for (; i < N; i++) {
  const g = zx.captureRegisters();
  if (g.pc < 0x4000 && g.pc !== 0x38) break;
  prevpc = g.pc; ring.push(g.pc.toString(16)); if (ring.length > 6) ring.shift();
  zx.step(1);
}
const out = [];
for (let k = 0; k < 14; k++) { const g = zx.captureRegisters(); out.push(g.pc.toString(16) + ':' + g.sp.toString(16) + ':i' + g.i + ':im' + g.im + ':if' + (g.iff1 ? 1 : 0)); zx.step(1); }
return 'prev=' + ring.join(',') + ' then ' + out.join(' ');

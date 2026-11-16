// single-step until PC reaches #0000 (reset: the game jumped to 0) or #0008/#0038 outside the interrupt, return the last 40 PCs with SP/HL/A
zx.pause();
const N = +q.get('n') || 4000000; const ring = [];
let i = 0, hit = '';
for (; i < N; i++) {
  const g = zx.captureRegisters();
  if (g.pc === 0 || g.pc === 8 || (g.pc >= 0x1000 && g.pc < 0x4000 && g.i === 0x3F && g.im !== 2 && i > 1000)) { hit = 'ROM pc=' + g.pc.toString(16); break; }
  ring.push(g.pc.toString(16) + ':' + g.sp.toString(16) + ':' + g.hl.toString(16) + ':' + g.a.toString(16)); if (ring.length > 60) ring.shift();
  zx.step(1);
}
const gg = zx.captureRegisters();
return 'steps=' + i + ' ' + hit + ' pc=' + gg.pc.toString(16) + ' sp=' + gg.sp.toString(16) + ' | ' + ring.slice(-40).join(' ');

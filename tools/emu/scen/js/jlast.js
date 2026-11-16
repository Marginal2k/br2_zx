// single-step until PC < 0x4000 (outside the interrupt entry) and return the last 40 PCs with SP/HL
zx.pause();
const N = +q.get('n') || 1000000; const ring = [];
let i = 0;
for (; i < N; i++) {
  const g = zx.captureRegisters();
  if (g.pc < 0x4000 && g.pc !== 0x38) break;
  ring.push(g.pc.toString(16) + ':' + g.sp.toString(16) + ':' + g.hl.toString(16)); if (ring.length > 40) ring.shift();
  zx.step(1);
}
const gg = zx.captureRegisters(); return 'steps=' + i + ' END pc=' + gg.pc.toString(16) + ' sp=' + gg.sp.toString(16) + ' ' + ring.slice(-14).join(' ');

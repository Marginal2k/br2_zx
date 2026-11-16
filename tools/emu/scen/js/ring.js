// run instruction by instruction until PC enters ROM (<4000) after 2000 steps; keep last 60 states
zx.pause(); const ring = []; let n = 0;
while (n < 3000000) {
  const g = zx.captureRegisters();
  ring.push([g.pc, g.sp, g.hl, g.de, g.bc].map(v => v.toString(16)).join('/'));
  if (ring.length > 70) ring.shift();
  if (g.pc < 0x0100 && n > 10) break;
  zx.step(1); n++;
}
return { n, ring: ring.join(' ') };

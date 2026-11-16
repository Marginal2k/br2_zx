// watch writes into page-0 window range DD00..DDFF while running up to N frames; stop when I returns to 3F (crash)
zx.watchWrites(0xDD00, 0xDDFF);
let seen = false, fr = 0, crashed = false;
for (; fr < (+q.get('maxfr') || 80); fr++) {
  sp.runFrameHeadless();
  const g = zx.captureRegisters();
  if (g.i === 0xBE) seen = true;
  if (seen && g.i === 0x3F) { crashed = true; break; }
}
const w = zx.stopWrites();
const b0 = zx.peekBank(0);
return { crashed, fr, hits: w.slice(0, 30), b0_dd3d: Array.from(b0.slice(0x1D3D, 0x1D45)) };

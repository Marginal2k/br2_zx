// run frames until the game "crashes" (I register becomes #3F = ROM reset), keeping a rolling z80/szx snapshot every K frames;
// then restore the snapshot taken ~K frames earlier and single-step with a ring buffer to find the instruction that went wrong.
const K = 5, maxFr = +q.get('maxfr') || 1500;
let snaps = [], fr = 0, crashed = false, seen = false;
for (; fr < maxFr; fr++) {
  if (fr % K === 0) { snaps.push({ fr, d: zx.saveSnapshot('szx') }); if (snaps.length > 3) snaps.shift(); }
  sp.runFrameHeadless();
  const g = zx.captureRegisters();
  if (g.i === 0xBE) seen = true;
  if (seen && g.i === 0x3F) { crashed = true; break; }
}
if (!crashed) return { crashed: false, frames: fr };
zx.pause();
const s0 = snaps[0];
res.disks['crash_szx'] = btoa(String.fromCharCode(...s0.d));
res.crashb0 = Array.from(zx.peekBank(0).slice(0x1D3D, 0x1D3D + 8));

const pg = new Uint8Array(await (await fetch('/media/one/game/page0.bin?' + Date.now(), { cache: 'no-store' })).arrayBuffer());
const b0 = zx.peekBank(0); const diffs = []; let st = -1;
for (let i = 0; i <= 16384; i++) { const d = i < 16384 && b0[i] !== pg[i]; if (d && st < 0) st = i; if (!d && st >= 0) { diffs.push(st.toString(16) + '-' + (i - 1).toString(16)); st = -1; } }
res.bank0diff = diffs.slice(0, 40);

await zx.loadFile(s0.d, 'x.szx'); zx.pause();
const ring = []; let n = 0, from = s0.fr, prev = -100;
for (let k = from; k < fr + 1; k++) {
  // single-step one frame worth of instructions (approx) watching for PC < 0x100 (outside RAM code) after being in RAM
  for (let st = 0; st < 20000; st++) {
    const g = zx.captureRegisters();
    if (Math.abs(g.pc - prev) > 4 || g.pc < prev) { ring.push(prev.toString(16) + '->' + [g.pc, g.sp, g.hl, g.de, g.bc, g.a].map(v => v.toString(16)).join('/')); if (ring.length > 40) ring.shift(); }
    prev = g.pc;
    if (g.pc === 0 || g.i === 0x3F) { return { crashed: true, fr, from, ring: ring.join(' ') }; }
    zx.step(1);
  }
}
return { crashed: true, fr, from, note: 'not reproduced', ring: ring.slice(-10).join(' ') };

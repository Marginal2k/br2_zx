// d2 held; single-step ~N instructions; log first hit of watched addresses and the instruction index; stop when PC leaves RAM >=0x6000 into ROM (<0x4000) after bGAME start
zx.pause(); zx.keyDown('2');
const W = {0x6507: 'PRESS->bGAME', 0x6266: 'bGAME', 0x626F: 'after LOADF0', 0x6277: 'DELPZ0', 0x627A: 'call DELPZ0', 0x627D: 'LDPG1', 0x6316: 'call FE00'};
let out0 = null; const hit = {}; const trail = []; let n = 0; let last = null; const cpu = sp.cpu;
const lim = +q.get('lim') || 4000000;
while (n < lim) {
  const pc = cpu.pc;
  if (W[pc] && !(pc in hit)) { hit[pc] = n; }
  if (pc < 0x0100 && (0x6266 in hit)) { out0 = [n, pc]; break; }
  if (0x6266 in hit) { trail.push(pc); if (trail.length > 40) trail.shift(); }
  zx.step(1); n++;
  if (n % 70000 === 0) sp.runFrameHeadless(); zx.pause();   // let time pass (interrupts) roughly
}
const out = {}; for (const k in hit) out[(+k).toString(16) + ' ' + W[k]] = hit[k];
return { out0, trail: trail.map(v => v.toString(16)).join(' '), n, pc: cpu.pc.toString(16), out };

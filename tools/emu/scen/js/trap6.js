// ловушки JR $ в банках ОЗУ на бывших CALL #0000: q.sites = "bank:addr,bank:addr", q.n кадров; возвращает какие сработали
const sites = (q.get('sites') || '6:C3F4,6:C403,6:C47C,0:ED55').split(',').map(s => { const [b, a] = s.split(':'); return { b: +b, a: parseInt(a, 16), orig: null, hit: -1 }; });
const N = +q.get('n') || 3000;
for (const s of sites) { const bank = sp.memory.ram[s.b]; s.orig = [bank[s.a - 0xC000], bank[s.a - 0xC000 + 1]]; bank[s.a - 0xC000] = 0x18; bank[s.a - 0xC000 + 1] = 0xFE; }
let f = 0;
for (; f < N; f++) {
  sp.runFrameHeadless();
  const pc = zx.captureRegisters().pc;
  for (const s of sites) if (s.hit < 0 && pc === s.a) { sp.runFrameHeadless(); if (zx.captureRegisters().pc === s.a) s.hit = f; }
  if (sites.some(s => s.hit >= 0)) break;
}
return 'frames=' + f + ' ' + sites.map(s => s.b + ':' + s.a.toString(16) + '=' + s.hit).join(' ') + ' check ' + sp.memory.ram[6][0x3F4];

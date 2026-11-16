// start the game's SAVgam directly (A = slot) by hand: push a return address (trap), run frames, sample the PC
const slot = 7;
const SAV = parseInt(q.get('sav') || '4895', 16);
zx.pause();
const sum = (a, n) => { const d = zx.peekBlock(a, n); let s = 0; for (let i = 0; i < n; i++) s = (s * 31 + d[i]) >>> 0; return s.toString(16); };
const out = { before: { gdata: sum(0x7700, 0x4900), table: sum(0xBE00, 257) } };
// return address #4010 (inside the vars area? use #4020): poke JR $ there
const TRAP = 0x4040; zx.pokeBlock(TRAP, [0x18, 0xFE]);
zx.pokeBlock(0x4030, [TRAP & 255, TRAP >> 8]);
sp.cpu.iff1 = false; sp.cpu.iff2 = false; sp.cpu.halted = false; zx.setRegisters({ pc: SAV, sp: 0x4030, a: slot });
const pcs = [];
for (let f = 0; f < (+q.get('fr') || 400); f++) { F(1); const g = zx.captureRegisters(); if (f % 20 === 0) pcs.push(g.pc.toString(16)); if (g.pc === TRAP) { out.returnedAt = f; break; } }
out.pcs = pcs.join(' ');
out.after = { gdata: sum(0x7700, 0x4900), savsig: Array.from(zx.peekBlock(0xBFFA, 2)).map(v => v.toString(16)).join('') };
return out;

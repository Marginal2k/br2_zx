// SAVgam(slot) called on the game's own stack, return trap in free area #40BD
const slot = +(q.get('slot') || 0);
const SAV = parseInt(q.get('sav'), 16);
zx.pause();
const TRAP = 0x40BD; zx.pokeBlock(TRAP, [0x18, 0xFE]);
const nsp = 0x4030;
zx.pokeBlock(nsp, [TRAP & 255, TRAP >> 8]);
sp.cpu.iff1 = false; sp.cpu.iff2 = false; sp.cpu.halted = false; zx.setRegisters({ pc: SAV, sp: nsp, a: slot });
let ret = -1;
for (let f = 0; f < 600; f++) { F(1); const g = zx.captureRegisters(); if (g.pc === TRAP) { ret = f; break; } }
return { returnedAt: ret, savsig: Array.from(zx.peekBlock(0xBFFA, 2)).map(v => v.toString(16)).join('') };

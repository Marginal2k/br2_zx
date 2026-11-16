// game D_READ (#4734) on assorted tracks, run as real frames (TR-DOS ROM paging needs the normal run loop): does the data arrive?
zx.pause();
const img = new Uint8Array(await (await fetch('/media/br_1mb.trd?' + Date.now(), { cache: 'no-store' })).arrayBuffer());
zx.pause();
const out = []; const TRAP = 0x4040;
const saved = Array.from(zx.peekBlock(TRAP, 2)); const stk = Array.from(zx.peekBlock(0x4030, 2));
for (const [t, s] of [[1, 2], [0, 1], [2, 1], [3, 2], [5, 3], [14, 10], [17, 1], [62, 7], [127, 3], [200, 5]]) {
  zx.pokeBlock(0x9000, new Array(256).fill(0xEE));
  zx.pokeBlock(TRAP, [0x18, 0xFE]); zx.pokeBlock(0x4030, [TRAP & 255, TRAP >> 8]);
  zx.setRegisters({ pc: 0x4734, sp: 0x4030, bc: 0x0100, de: (t << 8) | s, hl: 0x9000 });
  let n = 0; for (; n < 60; n++) { F(1); if (zx.captureRegisters().pc === TRAP) break; }
  const g = zx.captureRegisters();
  const got = zx.peekBlock(0x9000, 256); const o = (t * 16 + s - 1) * 256;
  let same = true; for (let i = 0; i < 256; i++) if (got[i] !== img[o + i]) { same = false; break; }
  out.push(`${t}/${s}:${g.pc === TRAP ? (g.f & 1 ? 'ERR' : 'ok') : 'NORET'}${same ? '=data' : got[0] === 0xEE ? ' NOTHING' : ' WRONG'}(${n}fr)`);
}
zx.pokeBlock(TRAP, saved); zx.pokeBlock(0x4030, stk);
return out.join(' ');

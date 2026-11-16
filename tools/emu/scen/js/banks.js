const o = {};
for (let b = 0; b < 8; b++) { const k = zx.peekBank(b); o['b' + b] = Array.from(k.slice(0, 6)).join(',') + ' nz=' + k.reduce((a, v) => a + (v ? 1 : 0), 0); }
const m = sp.memory;
o.ramlen = m.ram ? m.ram.length : 'noram'; o.same01 = m.getRamBank(0) === m.getRamBank(1);
const pg = new Uint8Array(await (await fetch('/media/one/game/page0.bin', { cache: 'no-store' })).arrayBuffer());
o.pg0 = Array.from(pg.slice(0, 6)).join(',') + ' len=' + pg.length;
return o;

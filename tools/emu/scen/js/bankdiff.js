// count bytes differing from build/one/game/pageN.bin per RAM bank (bank2<->page5, bank5<->page2 swapped back)
const out = {};
for (let b = 0; b < 8; b++) {
  const pgn = b === 2 ? 5 : b === 5 ? 2 : b; // after #FE00 the swap is undone: bank5 = page5 code, bank2 = page2 data -> compare bank b to page b
  const pg = new Uint8Array(await (await fetch(`/media/one/game/page${b}.bin?` + Date.now(), { cache: 'no-store' })).arrayBuffer());
  const bk = zx.peekBank(b); let n = 0, first = -1, last = -1;
  for (let i = 0; i < 16384; i++) if (bk[i] !== pg[i]) { n++; if (first < 0) first = i; last = i; }
  out['bank' + b] = `${n} diff, ${first < 0 ? '-' : first.toString(16) + '..' + last.toString(16)}`;
}
return out;

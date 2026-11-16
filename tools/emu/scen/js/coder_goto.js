// move the game cursor (MX #7401, MY #7402) to the next target of q.path = "x/y,x/y,..." using only the QAOP keys; returns the final position
const tg = (q.get('path') || '').split(',').filter(Boolean);
res.__gi = res.__gi || 0; const t = tg[res.__gi++];
if (!t) return 'no target';
const [tx, ty] = t.split('/').map(Number);
const pos = () => { const b = zx.peekBlock(parseInt(q.get('mx') || '7401', 16), 2); return [b[0], b[1]]; };
const keys = { l: 'o', r: 'p', u: 'q', d: 'a' };
let it = 0;
const axis = (idx, neg, pos_) => {
  // coarse: hold key frame by frame while far
  for (let n = 0; n < 200; n++) {
    const d = (idx ? ty : tx) - pos()[idx]; if (Math.abs(d) <= 4) break;
    const k = d > 0 ? pos_ : neg; zx.keyDown(k); F(1); zx.keyUp(k); it++;
  }
  F(8);
  // fine: short taps
  for (let n = 0; n < 40; n++) {
    const d = (idx ? ty : tx) - pos()[idx]; if (Math.abs(d) <= 1) break;
    const k = d > 0 ? pos_ : neg; zx.keyDown(k); F(2); zx.keyUp(k); F(4); it++;
  }
};
axis(0, 'o', 'p'); axis(1, 'q', 'a');
const [x, y] = pos(); return `goto ${tx},${ty} -> ${x},${y} in ${it} it`;

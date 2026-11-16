const pos = () => { const b = zx.peekBlock(0x7401, 2); return b[0]+','+b[1]; };
const o=[pos()];
for (const k of ['q','q','a','o','p']) { zx.keyDown(k); for(let i=0;i<4;i++){F(1);o.push(k+':'+pos());} zx.keyUp(k); F(3); o.push('up:'+pos()); }
return o.join(' ');

// AY writes during 600 frames: count frames where any volume reg 8-10 is nonzero, tone changes
const ay = sp.ay; const regs=()=>Array.from(ay.registers);
let act=0, vmax=0, ch=0, last='';
for (let i = 0; i < 600; i++) { F(1); const r = regs(); const v=Math.max(r[8],r[9],r[10]); vmax=Math.max(vmax,v); if (v&15) act++; const s=r.join(','); if(s!==last){ch++;last=s;} }
return {framesWithVolume:act, vmax, regChanges:ch, last};

// AY activity over 250 frames: max of volume regs 8-10, number of distinct tone-period values, writes
const ay = sp.ay; const regs=()=>Array.from(ay.regs || ay.registers || []);
let vmax=0, tones=new Set(), mix=new Set(), snaps=0;
for (let i = 0; i < 250; i++) { F(1); const r = regs(); vmax=Math.max(vmax,r[8],r[9],r[10]); tones.add(r[0]+','+r[1]+','+r[2]+','+r[3]); mix.add(r[7]); }
return { vmax, toneVariants: tones.size, mixers:[...mix].join('/'), last: regs().join(',') };

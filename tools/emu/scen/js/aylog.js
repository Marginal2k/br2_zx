// log AY registers per frame for n frames (arg n, default 200): returns distinct tone/volume stats and the first frames
const ay = sp.ay; const n = +q.get('n') || 200; const rows = [];
for (let i = 0; i < n; i++) { F(1); rows.push(Array.from(ay.regs || ay.registers || [])); }
const per = [];
for (let r = 0; r < 14; r++) { const v = rows.map(x => x[r]); per.push('R' + r + ':min' + Math.min(...v) + ' max' + Math.max(...v) + ' chg' + v.filter((x, i) => i && x !== v[i - 1]).length); }
return { frames: n, enabled: sp.ayEnabled, stats: per.join(' | '), first: rows.slice(0, 6).map(x => x.slice(0, 14).join(',')).join(' ; '), mid: rows.slice(100, 103).map(x => x.slice(0, 14).join(',')).join(' ; ') };

// AY activity: registers now + whether tone/volume registers change over 50 frames; beeper edges
const ay = sp.ay; const r0 = Array.from(ay.regs || ay.registers || []);
const seen = new Set();
for (let i = 0; i < 50; i++) { F(1); const r = Array.from(ay.regs || ay.registers || []); seen.add(r.join(',')); }
return { regs: r0.join(','), distinctRegSnapshotsIn50Frames: seen.size, ayEnabled: sp.ayEnabled };

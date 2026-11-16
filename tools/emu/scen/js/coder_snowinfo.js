const u = sp.ula; const o = {};
o.en = u.snowEnabled; o.bytes = u.snowBytes; o.dbl = u.snowDoubles;
try { o.isSnowing = u.isSnowing(); } catch (e) { o.err = '' + e; }
try { o.possible = u._snowPossible(); } catch (e) { o.err2 = '' + e; }
o.i = zx.captureRegisters().i; o.mach = zx.machineId || zx.machine;
return JSON.stringify(o);

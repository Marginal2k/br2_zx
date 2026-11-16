// snow counters over 100 frames (u.snowBytes / u.snowDoubles are cumulative: reset first) plus I
const u = sp.ula; u.snowBytes = 0; u.snowDoubles = 0; const is = new Set();
for (let i = 0; i < 100; i++) { F(1); is.add(zx.captureRegisters().i.toString(16)); }
return `snowBytes=${u.snowBytes} doubles=${u.snowDoubles} I=${[...is].join('/')}`;

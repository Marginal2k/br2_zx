const m = sp.memory; const o = [];
for (let b = 0; b < 8; b++) { const r = m.ram[b]; o.push(`ram${b}: ${r.constructor.name} off=${r.byteOffset} len=${r.length} bufLen=${r.buffer.byteLength}`); }
o.push('getRamBank(2)===ram[2]: ' + (m.getRamBank(2) === m.ram[2]));
o.push(m.getRamBank.toString().slice(0, 300));
return o;

// Generic scripted run: boot a TRD (TR-DOS autoboot), then a sequence of steps.
// Query params: trd=/media/br_1mb.trd [drive2=/media/br2.trd] [machine=pentagon|128k|+2|...] [snow=1] [beta=1]
//               steps=a,b,c   or  steps=@scenario  (tools/emu/scen/scenario.txt; commas or newlines; '#' comments)
//               noboot=1 (do not boot TR-DOS; just load the disks)
// Steps (frames: 1 frame = 1/50 s of emulated time):
//   wN            run N frames           KX  hold key X 70 frames (menus poll slowly)   kX  tap key (8 frames down, 8 up)
//   hX:N[:G]     hold key X exactly N frames then G idle frames (for auto-repeating keys)
//   dX / uX       key down / up          t:TEXT type text      (key names of ZX-M8XXX: 'Enter', ' ', '1', 'a', 'CAPS', 'SYM')
//   s:name        screenshot of the shown screen RAM (build/emu/<run>_<name>.png)
//   c:name        screenshot of the emulator canvas (border + snow effect; needs snow=1 for snow)
//   r:name        log registers (pc sp i im ...)
//   m:name:ADDR:LEN   dump memory (hex ADDR, dec LEN) as seen by the CPU into result.mem[name]; B:name:BANK:ADDR:LEN from a RAM bank
//   pADDR:VAL     poke (hex, hex)       jADDR  set PC       XX:name:REG=VAL  set register (hex)
//   rt:ADDR:MAXFR   run until PC==ADDR (or MAXFR frames); logs reached
//   ri:name       run to next interrupt, log PC/I (IM2 vector check: PC should be BFBF)
//   chk:name:ADDR:LEN:HEX   assert memory equals HEX bytes (HEX repeated to LEN)
//   wi:name:ADDR:MAXFR      wait until byte at ADDR (hex) changes; logs frames waited
//   idle:name:N   run N frames sampling PC+I every 25 frames -> log (hang detector)
//   tr:name:N:S   N frames, log pc/sp/i every S frames
//   fastboot:one|two[:drive]  WORKAROUND while the disk loader is broken: inject the 8 pages as the loader would, jump to #FE00 (use after w200 of a normal boot)
//   ins:N:file    insert another disk image into drive N (swapping test)
//   boot          (re)boot TR-DOS: full machine reset, disks stay in drives
//   disk:name:N   store drive N image (base64) into result.disks[name]
//   js:name:file  run tools/emu/scen/js/<file>.js (async fn body; args zx sp L F res hex q)
//   ev:name:JS    eval JS expression (zx, sp available)
export async function run(zx, q, win) {
  const machine = q.get('machine') || 'pentagon';
  await zx.ready({ machine });
  await zx.start({ machine });
  zx.pause();   // no real-time frames between start and the scripted run: keeps runs repeatable
  const sp = zx.spectrum;
  // frame stepping: default = full runFrame. fast=1 -> runFrameHeadless.
  // hunt=1: crash hunter - rolling snapshots + key log; when the game falls back to ROM (I=#3F after I=#BE) the remaining steps are skipped and
  //         a post-mortem replays the last frames with single-stepping and logs the last jumps (res.hunt).
  const hunt = q.get('hunt') === '1';
  const H = { gf: 0, snaps: [], ev: [], held: new Set(), seenBE: false, crash: -1 };
  const runOne = q.get('fast') === '1' ? (() => sp.runFrameHeadless()) : (() => sp.runFrame());
  const Fr = n => {
    for (let i = 0; i < n; i++) {
      if (hunt) {
        if (H.crash >= 0) return;
        if (H.gf % 5 === 0) { H.snaps.push({ gf: H.gf, d: zx.saveSnapshot('szx'), held: [...H.held] }); if (H.snaps.length > 3) H.snaps.shift(); }
      }
      runOne();
      if (hunt) { H.gf++; const g = zx.captureRegisters(); if (g.i !== H.lastI) { (H.ichg = H.ichg || []).push(`fr${H.gf}: I=${g.i.toString(16)} pc=${g.pc.toString(16)} sp=${g.sp.toString(16)} im=${g.im}`); H.lastI = g.i; } if (g.i === 0xBE || g.i === 0xBA) H.seenBE = true; if (H.seenBE && g.i === 0x3F) H.crash = H.gf; }
    }
  };
  const F = Fr;
  if (hunt) {
    const kd = zx.keyDown.bind(zx), ku = zx.keyUp.bind(zx); H.kd0 = kd; H.ku0 = ku;
    zx.keyDown = k => { H.held.add(k); H.ev.push([H.gf, 1, k]); return kd(k); };
    zx.keyUp = k => { H.held.delete(k); H.ev.push([H.gf, 0, k]); return ku(k); };
  }
  if (q.get('snow') === '1') sp.ula.setSnowEffect(true);
  if (q.get('beta') === '1') { sp.betaDiskEnabled = true; }
  const trd = q.get('trd');
  if (trd) await zx.loadUrl(trd + '?' + Date.now(), { name: trd.split('/').pop() });
  const loadDrive = async (url, idx) => {
    const buf = new Uint8Array(await (await fetch(url + '?' + Date.now(), { cache: 'no-store' })).arrayBuffer());
    sp.betaDisk.loadDisk(buf, 'trd', idx);
  };
  if (q.get('drive2')) await loadDrive(q.get('drive2'), 1);
  if (q.get('drive3')) await loadDrive(q.get('drive3'), 2);
  // disk registry: images keep their modifications when swapped out and back in
  const reg0 = {}; const nm = u => u.split('/').pop();
  if (trd) reg0[nm(trd)] = sp.betaDisk.drives[0].diskData;
  if (q.get('drive2')) reg0[nm(q.get('drive2'))] = sp.betaDisk.drives[1].diskData;
  const res = { shots: {}, canvas: {}, mem: {}, disks: {}, log: [] };
  const L = s => res.log.push(s);
  const hex = (n, w = 4) => n.toString(16).toUpperCase().padStart(w, '0');
  const reg = () => zx.captureRegisters();
  const doBoot = () => { zx.pause(); if (!sp.bootTrdos()) L('!! bootTrdos failed'); };
  if (q.get('noboot') !== '1') doBoot();
  const shown = () => {
    const bank = sp.memory.screenBank || 5;
    return Array.from(zx.peekBank(bank).slice(0, 6912));
  };
  const hexOf = a => Array.from(a).map(b => hex(b, 2)).join('');
  let src = q.get('steps') || 'w600,s:boot';
  if (src[0] === '@') src = await (await fetch('/h/scen/' + src.slice(1) + '.txt?' + Date.now())).text();
  const steps = src.split('\n').map(l => l.replace(/#.*/, '')).join(',').split(',').map(s => s.trim()).filter(Boolean);
  // prefetch everything the steps need: an await inside the step loop lets the emulator's real-time loop run and disturb the machine
  const jsCache = {};
  for (const st of steps) {
    const a = st.split(':');
    if (a[0] === 'js' && !jsCache[a[2]]) jsCache[a[2]] = await (await fetch('/h/scen/js/' + a[2] + '.js?' + Date.now())).text();
    if (a[0] === 'ins') { const f = a[2]; const url = f.startsWith('ref/') ? '/ref/' + f.slice(4) : '/media/' + f; if (!reg0[nm(f)]) reg0[nm(f)] = new Uint8Array(await (await fetch(url + '?' + Date.now(), { cache: 'no-store' })).arrayBuffer()); }
  }
  zx.pause();
  for (const st of steps) {
    const a = st.split(':');
    try {
      if (/^w\d+$/.test(st)) F(+st.slice(1));
      else if (/^W\d+$/.test(st)) Fr(+st.slice(1));   // W: run with full rendering (runFrame) instead of headless
      else if (st === 'boot') doBoot();
      else if (a[0] === 't') { zx.typeText(a.slice(1).join(':').replace(/\\n/g, '\n')); }
      else if (a[0] === 'rt') {   // rt:ADDR:MAXFR - run (with interrupts) until PC==ADDR: a JR $ trap is poked at ADDR (RAM only), removed afterwards
        const mx = +a[2] || 500, ad = parseInt(a[1], 16);
        if (reg().pc === ad) zx.step(1);
        const orig = Array.from(zx.peekBlock(ad, 2));
        zx.pokeBlock(ad, [0x18, 0xFE]);
        let n = 0;
        for (; n < mx; n++) { sp.runFrameHeadless(); const g = reg(); if (g.pc === ad) break; }
        const hit = reg().pc === ad;
        zx.pokeBlock(ad, orig);
        L(`rt ${a[1]} ${hit ? 'hit after ' + n + ' fr' : 'NOT hit in ' + mx + ' fr'} pc=${hex(reg().pc)}`);
      }
      else if (a[0] === 'ri') { const r = zx.runToInterrupt(200000); const g = reg(); L(`ri ${a[1] || ''} reached=${r.reached} pc=${hex(g.pc)} sp=${hex(g.sp)} i=${hex(g.i, 2)} im=${g.im}`); }
      else if (a[0] === 'r') { const g = reg(); L(`reg ${a[1]} pc=${hex(g.pc)} sp=${hex(g.sp)} i=${hex(g.i, 2)} im=${g.im} a=${hex(g.a, 2)} bc=${hex(g.bc)} de=${hex(g.de)} hl=${hex(g.hl)} ix=${hex(g.ix)} iy=${hex(g.iy)} frames=${sp.totalFrames}`); }
      else if (a[0] === 'fastboot') {   // fastboot:one|two - WORKAROUND for the broken disk loader: put the 8 pages (build/<v>/game/pageN.bin) where the loader would leave them
        const v = a[1] || 'one';        // (bank2 <- page5.bin, bank5 <- page2.bin, as the loader does), then enter #FE00 with A=drive 0
        const pgs = [];
        for (let b = 0; b < 8; b++) {   // fetch everything first: no awaits while memory is being written
          const src = b === 2 ? 5 : b === 5 ? 2 : b;
          pgs[b] = new Uint8Array(await (await fetch(`/media/${v}/game/page${src}.bin?` + Date.now(), { cache: 'no-store' })).arrayBuffer());
        }
        zx.pause();
        for (let b = 0; b < 8; b++) sp.memory.getRamBank(b).set(pgs[b]);
        sp.memory.writePaging(0x16);   // bank 6 at #C000, ROM1, screen 5
        zx.setRegisters({ pc: 0xFE00, sp: 0x63F8, a: +(a[2] || 0) });
        sp.cpu.iff1 = false; sp.cpu.iff2 = false; sp.cpu.halted = false;
        L('fastboot ' + v + ' -> pc=FE00');
      }
      else if (a[0] === 'rr') { const g = reg(); L(`rr ${a[1]} pc=${hex(g.pc)} sp=${hex(g.sp)} hl=${hex(g.hl)} de=${hex(g.de)} bc=${hex(g.bc)} a=${hex(g.a, 2)} [hl]=${hexOf(zx.peekBlock(g.hl, 10))} 7ffd=${hex(sp.memory.pagingRegister || 0, 2)}`); }
      else if (a[0] === 's') { res.shots[a[1]] = shown(); const g = reg(); L(`shot ${a[1]} pc=${hex(g.pc)} i=${hex(g.i, 2)}`); }
      else if (a[0] === 'c') { Fr(1); const cv = win.document.querySelector('canvas'); res.canvas[a[1]] = cv.toDataURL('image/png'); const g = reg(); L(`canvas ${a[1]} ${cv.width}x${cv.height} pc=${hex(g.pc)} i=${hex(g.i, 2)}`); }
      else if (a[0] === 'm') { res.mem[a[1]] = hexOf(zx.peekBlock(parseInt(a[2], 16), +a[3])); }
      else if (a[0] === 'B') { res.mem[a[1]] = hexOf(zx.peekBank(+a[2]).slice(parseInt(a[3], 16), parseInt(a[3], 16) + +a[4])); }
      else if (a[0] === 'chk') {
        const addr = parseInt(a[2], 16), len = +a[3];
        const got = hexOf(zx.peekBlock(addr, len)); let exp = a[4].toUpperCase();
        if (exp.length < len * 2) exp = exp.repeat(Math.ceil(len * 2 / exp.length)).slice(0, len * 2);
        L(`${got === exp ? 'PASS' : 'FAIL'} chk ${a[1]} @${a[2]}+${len}${got === exp ? '' : ' got ' + got.slice(0, 80)}`);
      }
      else if (a[0] === 'wi') {
        const addr = parseInt(a[2], 16), mx = +a[3] || 1000, v0 = zx.peek(addr); let n = 0;
        for (; n < mx && zx.peek(addr) === v0; n++) F(1);
        L(`wi ${a[1]} ${hex(addr)}: ${hex(v0, 2)} -> ${hex(zx.peek(addr), 2)} after ${n} fr`);
      }
      else if (a[0] === 'idle') {
        const n = +a[2], seen = {}; let i0 = null;
        for (let k = 0; k < n; k += 25) { F(Math.min(25, n - k)); const g = reg(); seen[hex(g.pc)] = (seen[hex(g.pc)] || 0) + 1; if (g.i !== i0) { L(`  i=${hex(g.i, 2)} at fr ${k}`); i0 = g.i; } }
        L(`idle ${a[1]} ${n} fr: distinct PCs=${Object.keys(seen).length} ${Object.keys(seen).slice(0, 12).join(' ')}`);
      }
      else if (a[0] === 'tr') {   // tr:name:N:S - every S frames log pc/sp/i/page
        const n = +a[2], stp = +a[3] || 10, o = [];
        for (let k = 0; k < n; k += stp) { F(stp); const g = reg(); o.push(`${hex(g.pc)}/${hex(g.sp)}/${hex(g.i, 2)}`); }
        L(`tr ${a[1]}: ${o.join(' ')}`);
      }
      else if (a[0] === 'disk') {
        const d = sp.betaDisk.drives[+a[2] || 0].diskData; let s = ''; for (let i = 0; i < d.length; i += 8192) s += String.fromCharCode(...d.subarray(i, i + 8192));
        res.disks[a[1]] = btoa(s); L(`disk ${a[1]} ${d.length} bytes`);
      }
      else if (a[0] === 'ev') { L('ev ' + a[1] + ' = ' + JSON.stringify(await (new Function('zx', 'sp', 'return (async()=>(' + a.slice(2).join(':') + '))()'))(zx, sp))); }
      else if (a[0] === 'ins') {   // ins:DRIVE:file  insert /media/<file> (or ref/..) into drive 0..3; a disk keeps its writes when re-inserted
        const f = a[2]; const url = f.startsWith('ref/') ? '/ref/' + f.slice(4) : '/media/' + f;
        if (!reg0[nm(f)]) reg0[nm(f)] = new Uint8Array(await (await fetch(url + '?' + Date.now(), { cache: 'no-store' })).arrayBuffer());
        const dr = sp.betaDisk.drives[+a[1]]; sp.betaDisk.loadDisk(reg0[nm(f)], 'trd', +a[1]); dr.headTrack = 0;
        L('inserted ' + f + ' in drive ' + a[1]);
      }
      else if (a[0] === 'js') {   // js:name:file - run tools/emu/scen/js/<file>.js as an async function body (zx, sp, L, F, res, hex)
        const code = jsCache[a[2]];
        const r = await (new Function('zx', 'sp', 'L', 'F', 'res', 'hex', 'q', 'return (async()=>{' + code + '})()'))(zx, sp, L, F, res, hex, q);
        if (r !== undefined) L('js ' + a[1] + ' = ' + JSON.stringify(r));
      }
      else if (a[0] === 'XX') { const o = {}; const [k, v] = a[2].split('='); o[k] = parseInt(v, 16); zx.setRegisters(o); }
      else if (a[0].length === 2 && a[0][0] === 'h') { zx.keyDown(a[0][1]); F(+a[1] || 2); zx.keyUp(a[0][1]); F(+a[2] || 6); }   // hX:N[:gap] hold key X for N frames, then gap frames
      else if (st[0] === 'K') { const k = st.slice(1); zx.keyDown(k); F(70); zx.keyUp(k); F(8); }
      else if (st[0] === 'k') { const k = st.slice(1); zx.keyDown(k); F(8); zx.keyUp(k); F(8); }
      else if (st[0] === 'd') zx.keyDown(st.slice(1));
      else if (st[0] === 'u') zx.keyUp(st.slice(1));
      else if (st[0] === 'p') { const [ad, v] = st.slice(1).split(':'); zx.pokeBlock(parseInt(ad, 16), [parseInt(v, 16)]); }
      else if (st[0] === 'j') { zx.setRegisters({ pc: parseInt(st.slice(1), 16) }); }
      else L('?? unknown step ' + st);
    } catch (e) { L(`!! step ${st}: ${e && e.message || e}`); }
  }
  if (hunt) {
    L('I changes: ' + (H.ichg || []).join(' | '));
    L(`hunt: ${H.crash >= 0 ? 'CRASH detected at frame ' + H.crash : 'no crash in ' + H.gf + ' frames'}`);
    if (H.crash >= 0) {
      const s0 = H.snaps[0];
      zx.keyDown = H.kd0; zx.keyUp = H.ku0;
      await zx.loadFile(s0.d, 'x.szx'); zx.pause();
      for (const k of 'qaopP '.split('')) { try { zx.keyUp(k); } catch (e) { } }
      for (const k of s0.held) zx.keyDown(k);
      let gf = s0.gf, ei = H.ev.findIndex(e => e[0] >= s0.gf); if (ei < 0) ei = H.ev.length;
      const apply = () => { while (ei < H.ev.length && H.ev[ei][0] <= gf) { const e = H.ev[ei++]; if (e[1]) zx.keyDown(e[2]); else zx.keyUp(e[2]); } };
      while (gf < H.crash - (+q.get('stepback') || 2)) { apply(); sp.runFrame(); gf++; }
      const ring = []; let prev = -100, found = null, lastKey = '', rep = 0;
      for (let f = 0; f < 20 && !found; f++) {
        apply(); gf++;
        for (let st = 0; st < 40000 && !found; st++) {
          const g = zx.captureRegisters();
          if (Math.abs(g.pc - prev) > 4 || g.pc < prev) {
            const key = prev.toString(16) + '->' + g.pc.toString(16);
            if (key === lastKey) rep++;
            else { if (rep) ring[ring.length - 1] += ' x' + (rep + 1); rep = 0; lastKey = key; ring.push(key + ':' + [g.sp, g.hl, g.de, g.bc, g.a].map(v => v.toString(16)).join('/')); if (ring.length > 120) ring.shift(); }
          }
          prev = g.pc;
          if (q.get('hstop') && g.pc === parseInt(q.get('hstop'), 16) && g.hl < 0x4000) { found = true; const stk = Array.from({ length: 8 }, (_, i) => hex(zx.peekWord((g.sp + 2 * i) & 0xFFFF))).join(' '); ring.push(`HSTOP pc=${hex(g.pc)} hl=${hex(g.hl)} de=${hex(g.de)} bc=${hex(g.bc)} sp=${hex(g.sp)} stack: ${stk}`); break; }
          if ((g.pc < 0x4000 && !sp.memory.trdosActive) || (g.pc >= 0xBE00 && g.pc < 0xBFB8 && g.pc !== 0xBF00)) { found = true; ring.push('STOP pc=' + g.pc.toString(16) + ' sp=' + g.sp.toString(16)); break; }
          zx.step(1);
        }
      }
      { const t = zx.peekBlock(0xBE00, 257); let bad = []; for (let i = 0; i < 257; i++) if (t[i] !== 0xBF) bad.push(hex(0xBE00 + i) + '=' + hex(t[i], 2)); const g = zx.captureRegisters();
        L(`post-mortem: I=${hex(g.i, 2)} im=${g.im} table #BE00..#BF00 bad bytes: ${bad.length} ${bad.slice(0, 12).join(' ')}; #BFBF=${hexOf(zx.peekBlock(0xBFBF, 3))}; 7ffd-ish ram bank at C000: ${sp.memory.currentRamBank}`); }
      res.hunt = { crashFrame: H.crash, from: s0.gf, found: !!found, ring: ring.join(' ') };
      L('hunt ring (prev->pc/sp/hl/de/bc/a): ' + ring.join(' '));
    }
  }
  res.regs = reg();
  await zx.report(res, 'result', q.get('name') || 'play');
  return { log: res.log.length };
}

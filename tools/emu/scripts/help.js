export async function run(zx, q) {
  await zx.ready({ machine: 'pentagon' });
  const h = zx.help();
  await zx.report({ help: h }, 'result', q.get('name') || 'help');
  return { n: h.length };
}

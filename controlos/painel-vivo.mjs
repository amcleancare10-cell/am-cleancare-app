// Testa o painel REAL (os ficheiros que estão publicados em amcleancare.ch) num browser simulado, como gerente e como admin :
// abre todas as páginas, os botões principais e os formulários, com dados fictícios (nunca toca em dados reais).
// Apanha : erros de código, páginas em branco, menus sem página, ficheiro do painel corrompido.
import fs from 'node:fs';
import vm from 'node:vm';
import cp from 'node:child_process';

const SITE = 'https://amcleancare.ch/wp-content/plugins/am-cleancare-apps/gerencia/';
const DIR = 'live-web';
const rows = [];
const add = (nome, estado, detalhe = '') => { rows.push({ grupo: 'Painel (gerente e admin)', nome, estado, detalhe }); console.log(`${estado === 'ok' ? '✅' : '❌'} ${nome} ${detalhe}`); };
fs.mkdirSync(DIR + '/js', { recursive: true });
const files = ['index.html', 'candidat.html', 'config.js', 'js/panel.bundle.js', 'js/candidat.js'];
let baixou = true;
for (const f of files) {
  try { const r = await fetch(SITE + f + '?x=' + Date.now()); if (!r.ok) throw new Error('HTTP ' + r.status); fs.writeFileSync(`${DIR}/${f}`, Buffer.from(await r.arrayBuffer())); }
  catch (e) { baixou = false; add('descarregar ' + f, 'falha', String(e.message || e)); }
}
if (baixou) {
  add('ficheiros do painel descarregados', 'ok', files.length + ' ficheiros');
  for (const f of ['config.js', 'js/panel.bundle.js', 'js/candidat.js']) { try { new vm.Script(fs.readFileSync(`${DIR}/${f}`, 'utf8'), { filename: f }); } catch (e) { add('ficheiro ' + f + ' sem erros de sintaxe', 'falha', String(e.message).slice(0, 140)); baixou = false; } }
  if (baixou) add('ficheiros JavaScript do painel sem erros de sintaxe', 'ok');
}
if (baixou) {
  const run = (script, env) => { const r = cp.spawnSync('node', [script], { env: { ...process.env, ...env }, encoding: 'utf8', timeout: 240000, maxBuffer: 1 << 26 }); return { code: r.status, out: (r.stdout || '') + (r.stderr || '') }; };
  const s = run('painel/smoke.js', { WEB_DIR: DIR, BUNDLE: '1' });
  const resumo = s.out.split('\n').filter((l) => /^== |✗|erro global|interações/.test(l.trim()) || /^== /.test(l)).join(' | ').slice(0, 600);
  add('painel: todas as páginas e botões (gerente e admin)', s.code === 0 ? 'ok' : 'falha', s.code === 0 ? resumo.replace(/\s+/g, ' ').slice(0, 160) : resumo || s.out.slice(-300));
  const c = run('painel/candidat.js', { WEB_DIR: DIR });
  add('formulário público de candidatura', c.code === 0 ? 'ok' : 'falha', c.code === 0 ? '' : c.out.slice(-300));
}
fs.writeFileSync('rows-painel.json', JSON.stringify(rows));
process.exit(rows.some((r) => r.estado === 'falha') ? 1 : 0);

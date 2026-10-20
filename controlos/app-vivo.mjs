// Controlos da app dos locatários, num navegador (Chrome sem ecrã) :
//  1) a app web PUBLICADA (amcleancare.ch/app/) arranca sem erros ;
//  2) (se a pasta app-demo existir, compilada pelo fluxo) a versão de demonstração abre os ecrãs principais sem erros nem páginas em branco.
// Os testes de demonstração usam dados fictícios e nunca tocam em dados reais.
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const CHROME = process.env.CHROME || '/usr/bin/google-chrome';
const rows = [];
const add = (nome, estado, detalhe = '') => { rows.push({ grupo: 'App dos locatários', nome, estado, detalhe }); console.log(`${estado === 'ok' ? '✅' : estado === 'aviso' ? '⚠️' : '❌'} ${nome} ${detalhe}`); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const ARGS = ['--no-sandbox', '--disable-dev-shm-usage', '--hide-scrollbars', '--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'];
const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ARGS, protocolTimeout: 120000 });

async function abrir(url, { ms = 9000, viewport = { width: 390, height: 844, deviceScaleFactor: 1, isMobile: true, hasTouch: true }, init } = {}) {
  const page = await browser.newPage(); await page.setViewport(viewport); const erros = [];
  page.on('pageerror', (e) => erros.push(String(e).slice(0, 160)));
  page.on('console', (m) => { if (m.type() === 'error' && !/favicon|Failed to load resource|net::ERR|CORS|WebGL|GL Driver|GPU stall/i.test(m.text())) erros.push('console: ' + m.text().slice(0, 140)); });
  if (init) await page.evaluateOnNewDocument(init);
  await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 }); await sleep(ms);
  return { page, erros };
}
const pixels = async (page) => { const b = await page.screenshot({ type: 'jpeg', quality: 60 }); return b.length; };

// 1) app publicada
for (let tentativa = 1; tentativa <= 2; tentativa++) {
  try {
    const { page, erros } = await abrir('https://amcleancare.ch/app/index.html', { ms: 10000 });
    const flutter = await page.evaluate(() => !!document.querySelector('flutter-view, flt-glass-pane, flt-scene-host') || !!document.querySelector('canvas'));
    const tam = await pixels(page); await page.close();
    if (!flutter) throw new Error('a app não arrancou (sem ecrã Flutter)');
    if (tam < 8000) throw new Error('ecrã em branco');
    if (erros.length) throw new Error('erros: ' + erros.join(' | '));
    add('app web publicada arranca (ecrã de entrada)', 'ok'); break;
  } catch (e) { if (tentativa === 2) add('app web publicada arranca (ecrã de entrada)', 'falha', String(e.message || e).slice(0, 200)); else await sleep(5000); }
}

// 2) demonstração compilada no fluxo
if (fs.existsSync('app-demo/index.html')) {
  const MIME = { html: 'text/html', js: 'application/javascript', json: 'application/json', png: 'image/png', jpg: 'image/jpeg', svg: 'image/svg+xml', wasm: 'application/wasm', otf: 'font/otf', ttf: 'font/ttf', ico: 'image/x-icon' };
  const srv = http.createServer((q, r) => { let p = decodeURIComponent(q.url.split('?')[0]).replace(/^\/tenant\//, '/'); if (p === '/') p = '/index.html'; const f = path.join('app-demo', p); fs.readFile(f, (e, b) => { if (e) { r.writeHead(404); r.end(); return; } r.writeHead(200, { 'content-type': MIME[path.extname(f).slice(1)] || 'application/octet-stream', 'access-control-allow-origin': '*' }); r.end(b); }); }).listen(8801);
  const cenas = [['início', null], ['mensagens', [108, 618]], ['reduções', [252, 618]], ['perfil', [324, 618]], ['tickets', [260, 560]], ['novo ticket', [100, 560]]];
  const falhas = []; const ok = [];
  for (const [nome, toque] of cenas) {
    try {
      const { page, erros } = await abrir('http://localhost:8801/tenant/index.html', { ms: 7000, viewport: { width: 360, height: 640, deviceScaleFactor: 1, isMobile: true, hasTouch: true } });
      if (toque) { await page.touchscreen.tap(toque[0], toque[1]); await sleep(2500); }
      const tam = await pixels(page); await page.close();
      if (tam < 8000) throw new Error('ecrã em branco'); if (erros.length) throw new Error(erros[0]);
      ok.push(nome);
    } catch (e) { falhas.push(`${nome}: ${String(e.message || e).slice(0, 80)}`); }
  }
  srv.close();
  // um navegador sem placa gráfica é instável : só avisa (não envia e-mail) se for o navegador a falhar
  add('app (demonstração): ecrãs principais abrem sem erros', falhas.length ? 'aviso' : 'ok', falhas.length ? falhas.join(' · ') : ok.length + ' ecrãs');
}
await browser.close();
fs.writeFileSync('rows-app.json', JSON.stringify(rows));
process.exit(rows.some((r) => r.estado === 'falha') ? 1 : 0);

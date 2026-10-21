// Controlos automáticos da AM Clean Care (correm no GitHub Actions, sem o computador do utilizador).
// SÓ LEITURA : nada é criado, alterado ou apagado. Usa apenas endereços públicos e a chave "anon" (pública, a mesma da app).
// Saída : resumo em Markdown (summary.md) e código de saída 1 se algum controlo FALHAR (os AVISOS não falham).
import fs from 'node:fs';
import tls from 'node:tls';

const SITE = 'https://amcleancare.ch';
const SB = 'https://uxxjvwvqhaeepmmdkior.supabase.co';
const rows = []; // {grupo, nome, estado: 'ok'|'aviso'|'falha', detalhe}
const add = (grupo, nome, estado, detalhe = '') => { rows.push({ grupo, nome, estado, detalhe }); console.log(`${estado === 'ok' ? '✅' : estado === 'aviso' ? '⚠️' : '❌'} [${grupo}] ${nome} ${detalhe}`); };
const t0 = Date.now();
const get = async (url, opt = {}) => { const c = new AbortController(); const to = setTimeout(() => c.abort(), opt.timeout || 25000); try { return await fetch(url, { redirect: 'follow', ...opt, signal: c.signal }); } finally { clearTimeout(to); } };
const check = async (grupo, nome, fn) => { try { const r = await fn(); if (r === true || r === undefined) add(grupo, nome, 'ok'); else if (typeof r === 'string') add(grupo, nome, 'ok', r); else add(grupo, nome, r.estado || 'ok', r.detalhe || ''); } catch (e) { add(grupo, nome, 'falha', String(e && e.message || e).slice(0, 160)); } };
const need = (cond, msg) => { if (!cond) throw new Error(msg); };

// chave anon real (pública) : lida de config.js do painel, para nunca ficar desatualizada
let anon = '';
await check('Painel', 'config.js do painel abre', async () => { const r = await get(`${SITE}/wp-content/plugins/am-cleancare-apps/gerencia/config.js`); need(r.ok, 'HTTP ' + r.status); const t = await r.text(); const m = /SUPABASE_ANON_KEY:\s*'([^']+)'/.exec(t); need(m, 'sem chave anon'); anon = m[1]; });
const H = { apikey: anon, Authorization: 'Bearer ' + anon };

// ---------- site e painel ----------
await check('Painel', 'https://amcleancare.ch/gerance/ abre (painel)', async () => { const r = await get(`${SITE}/gerance/`); need(r.ok, 'HTTP ' + r.status); const t = await r.text(); need(/panel\.bundle|AM Clean|Espace/i.test(t), 'conteúdo inesperado'); return `${r.status}`; });
await check('Painel', 'endereço antigo /gerencia/ redireciona', async () => { const r = await get(`${SITE}/gerencia/`, { redirect: 'manual' }); need([301, 302, 308].includes(r.status), 'HTTP ' + r.status); });
await check('Painel', 'ficheiro principal do painel (bundle) existe e é grande', async () => { const r = await get(`${SITE}/wp-content/plugins/am-cleancare-apps/gerencia/js/panel.bundle.js`); need(r.ok, 'HTTP ' + r.status); const n = (await r.text()).length; need(n > 300000, 'pequeno demais: ' + n); return Math.round(n / 1024) + ' KB'; });
await check('Painel', 'portal das empresas (devis.html) abre', async () => { const r = await get(`${SITE}/gerance/devis.html`); need(r.ok, 'HTTP ' + r.status); });
await check('Painel', 'formulário de candidatura (candidat.html) abre', async () => { const r = await get(`${SITE}/gerance/candidat.html`); need(r.ok, 'HTTP ' + r.status); });
await check('Painel', 'État des lieux (etat-des-lieux.html) abre', async () => { const r = await get(`${SITE}/gerance/etat-des-lieux.html`); need(r.ok, 'HTTP ' + r.status); });
await check('Site', 'app web dos locatários (/app/) abre', async () => { const r = await get(`${SITE}/app/`); need(r.ok, 'HTTP ' + r.status); });
await check('Site', 'política de privacidade abre', async () => { const r = await get(`${SITE}/confidentialite`); need(r.ok, 'HTTP ' + r.status); });
await check('Site', 'página de instalação (/installer) abre', async () => { const r = await get(`${SITE}/installer`); need(r.ok, 'HTTP ' + r.status); });
await check('Site', 'certificado HTTPS válido por mais de 14 dias', async () => {
  const exp = await new Promise((res, rej) => { const s = tls.connect(443, 'amcleancare.ch', { servername: 'amcleancare.ch' }, () => { const c = s.getPeerCertificate(); s.end(); res(new Date(c.valid_to)); }); s.on('error', rej); s.setTimeout(15000, () => { s.destroy(); rej(new Error('timeout')); }); });
  const dias = Math.floor((exp - Date.now()) / 864e5); if (dias < 7) throw new Error('expira em ' + dias + ' dias'); return dias < 15 ? { estado: 'aviso', detalhe: 'expira em ' + dias + ' dias' } : { detalhe: 'expira em ' + dias + ' dias' };
});

// ---------- app Android e tutoriais ----------
await check('App', 'o instalador (/installer) leva às lojas (Google Play e App Store) e /apk encaminha para ele', async () => { const a = await get(`${SITE}/apk`, { method: 'HEAD', redirect: 'manual' }); need([301, 302, 307, 308].includes(a.status) && /\/installer/.test(a.headers.get('location') || ''), '/apk deveria encaminhar para /installer (HTTP ' + a.status + ')'); const r = await get(`${SITE}/installer`); need(r.ok, 'HTTP ' + r.status); const t = await r.text(); need(/apps\.apple\.com/.test(t) && /play\.google\.com/.test(t), 'faltam os endereços das lojas'); return 'ok'; });
let build = 0;
// ---------- lojas de aplicações ----------
await check('Lojas', 'App Store : a app aparece na loja suíça', async () => { const r = await get('https://itunes.apple.com/lookup?id=6756571666&country=ch'); need(r.ok, 'HTTP ' + r.status); const j = await r.json(); need(j.resultCount === 1, 'a app não aparece na App Store suíça'); return 'versão ' + j.results[0].version; });
await check('Lojas', 'App Store : países com a app disponível (Suíça, França, Portugal)', async () => { const falta = []; for (const c of ['ch', 'fr', 'pt']) { const r = await get(`https://itunes.apple.com/lookup?id=6756571666&country=${c}`); const j = r.ok ? await r.json() : { resultCount: 0 }; if (j.resultCount !== 1) falta.push(c.toUpperCase()); } return falta.length ? { estado: 'aviso', detalhe: 'a app não está disponível em : ' + falta.join(', ') } : 'disponível nos 3'; });
await check('Lojas', 'Google Play : a ficha da app abre', async () => { const r = await get('https://play.google.com/store/apps/details?id=com.amcleancare.propertyissues&hl=fr'); need(r.ok, 'HTTP ' + r.status); const t = await r.text(); need(/AM CleanCare|AM Clean Care/i.test(t), 'a ficha não parece a nossa'); });
await check('Site', 'página do QR code (/qr-code-app) abre', async () => { const r = await get(`${SITE}/qr-code-app`); need(r.ok, 'HTTP ' + r.status); const t = await r.text(); need(/qrcode/i.test(t), 'conteúdo inesperado'); });
await check('Site', 'página inicial do site abre', async () => { const r = await get(`${SITE}/`); need(r.ok, 'HTTP ' + r.status); });
await check('App', 'aviso de nova versão (version.json) válido', async () => { const r = await get(`${SITE}/wp-content/plugins/am-cleancare-apps/apk/version.json`); need(r.ok, 'HTTP ' + r.status); const j = await r.json(); build = +j.build; need(build >= 100, 'conteúdo inesperado'); return 'build ' + build; });
await check('App', 'vídeos de tutorial (16) abrem', async () => { const falhas = []; for (let i = 1; i <= 16; i++) { const n = String(i).padStart(2, '0'); const r = await get(`${SB}/storage/v1/object/public/batimentimg/tutoriels/${n}.mp4`, { headers: { Range: 'bytes=0-99' } }); if (![200, 206].includes(r.status)) falhas.push(n + ':' + r.status); } need(!falhas.length, 'falharam ' + falhas.join(', ')); });

// ---------- Supabase ----------
await check('Supabase', 'API da base de dados responde', async () => { const r = await get(`${SB}/rest/v1/annonces_immo?select=id&limit=1`, { headers: H }); need(r.ok, 'HTTP ' + r.status); });
await check('Supabase', 'serviço de contas (auth) saudável', async () => { const r = await get(`${SB}/auth/v1/health`, { headers: { apikey: anon } }); need(r.ok, 'HTTP ' + r.status); });
for (const f of ['ai-chat', 'send-email', 'send-push', 'create-user', 'devis-notify', 'candidature-notify', 'zefix-sync', 'ticket-rappels', 'controle-semanal']) {
  await check('Serviços', `função ${f} publicada`, async () => { const r = await get(`${SB}/functions/v1/${f}`, { method: 'OPTIONS', headers: { Origin: 'https://amcleancare.ch', 'Access-Control-Request-Method': 'POST' } }); need(r.status < 400, 'HTTP ' + r.status); });
}
await check('Serviços', 'concierge virtual exige sessão (segurança)', async () => { const r = await get(`${SB}/functions/v1/ai-chat`, { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: '{}' }); need(r.status === 401, 'devia ser 401, é ' + r.status); });
await check('Serviços', 'envio de e-mails exige sessão (segurança)', async () => { const r = await get(`${SB}/functions/v1/send-email`, { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: '{}' }); need(r.status === 401, 'devia ser 401, é ' + r.status); });

// ---------- segurança (só leituras anónimas) ----------
for (const t of ['tenants', 'managers', 'tickets', 'factures', 'coffre_acces', 'coffre_cles', 'devis_offres']) {
  await check('Segurança', `anónimo não lê "${t}"`, async () => { const r = await get(`${SB}/rest/v1/${t}?select=*&limit=1`, { headers: H }); if (r.status === 404) return 'tabela não existe'; if (r.status === 401 || r.status === 403) return; need(r.ok, 'HTTP ' + r.status); const j = await r.json(); need(Array.isArray(j) && j.length === 0, 'anónimo conseguiu ler dados!'); });
}
await check('Segurança', 'documentos privados não são listáveis por anónimos', async () => { const r = await get(`${SB}/storage/v1/object/list/docsprives`, { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: JSON.stringify({ prefix: '', limit: 5 }) }); if (!r.ok) return; const j = await r.json(); need(Array.isArray(j) && j.length === 0, 'anónimo lista ficheiros privados!'); });
await check('Segurança', 'anónimo não lista ficheiros da pasta de imagens', async () => { const r = await get(`${SB}/storage/v1/object/list/batimentimg`, { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: JSON.stringify({ prefix: '', limit: 5 }) }); if (!r.ok) return; const j = await r.json(); need(Array.isArray(j) && j.length === 0, 'anónimo lista ficheiros!'); });

// ---------- agente interno (só leitura: "dry" não envia e-mails) ----------
await check('Agente', 'controlo interno da base de dados (sem erros)', async () => {
  const r = await get(`${SB}/functions/v1/controle-semanal`, { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: JSON.stringify({ dry: true }), timeout: 90000 }); need(r.ok, 'HTTP ' + r.status); const j = await r.json(); need(j.ok !== false, 'agente falhou');
  if (j.problemas > 0) { const lista = (j.issues || []).map((x) => `${x.nivel || ''} ${x.titulo || ''}`.trim()).join(' · ').slice(0, 300); return { estado: j.urgentes > 0 ? 'falha' : 'aviso', detalhe: `${j.problemas} problema(s): ${lista}` }; }
  const anonT = j.metrics?.db?.anon_tables; if (Array.isArray(anonT)) { const ext = anonT.filter((t) => !['annonces_immo', 'candidate_information'].includes(t)); if (ext.length) return { estado: 'falha', detalhe: 'tabelas expostas a anónimos: ' + ext.join(', ') }; }
  const semRls = j.metrics?.db?.tables_sans_rls; if (Array.isArray(semRls) && semRls.length) return { estado: 'falha', detalhe: 'tabelas sem proteção (RLS): ' + semRls.join(', ') };
  const m = j.metrics?.db; if (m) { const p = []; if (m.db_mb > 400) p.push('base de dados ' + m.db_mb + ' MB'); if (m.storage_mb > 800) p.push('ficheiros ' + m.storage_mb + ' MB'); if (p.length) return { estado: 'aviso', detalhe: p.join(', ') }; return `base de dados ${m.db_mb} MB · ficheiros ${m.storage_mb} MB`; }
});
await check('Agente', 'tarefas agendadas a correr (lembretes diários)', async () => {
  const r = await get(`${SB}/functions/v1/controle-semanal`, { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: JSON.stringify({ dry: true }), timeout: 90000 }); const j = await r.json(); const cr = j.metrics?.db?.cron || []; need(cr.length >= 2, 'tarefas agendadas em falta');
  const mau = cr.filter((c) => !c.actif || c.echecs_8j > 0); need(!mau.length, 'com problema: ' + mau.map((c) => c.nom).join(', '));
  const rap = cr.find((c) => c.nom === 'ticket-rappels-quotidien'); if (rap?.derniere && Date.now() - new Date(rap.derniere) > 3 * 864e5) throw new Error('lembretes diários não correm há mais de 3 dias');
});

// ---------- e-mail (DNS) ----------
const doh = async (name, type) => { const r = await get(`https://dns.google/resolve?name=${name}&type=${type}`, { headers: { accept: 'application/dns-json' } }); const j = await r.json(); return j.Answer || []; };
await check('E-mail', 'domínio autenticado no Brevo (código e DKIM)', async () => { const txt = (await doh('amcleancare.ch', 'TXT')).map((a) => a.data).join(' '); need(/brevo-code/.test(txt), 'falta o registo brevo-code'); for (const s of ['brevo1', 'brevo2']) { const a = await doh(`${s}._domainkey.amcleancare.ch`, 'CNAME'); need(a.length > 0, `falta ${s}._domainkey`); } });
await check('E-mail', 'registo SPF existe', async () => { const txt = (await doh('amcleancare.ch', 'TXT')).map((a) => a.data).join(' '); need(/v=spf1/.test(txt), 'sem SPF'); });

// ---------- resumo ----------
const falhas = rows.filter((r) => r.estado === 'falha'), avisos = rows.filter((r) => r.estado === 'aviso');
const ic = { ok: '✅', aviso: '⚠️', falha: '❌' };
let md = `# Controlo automático AM Clean Care\n\n`;
md += falhas.length ? `**❌ ${falhas.length} controlo(s) a falhar**` : avisos.length ? `**⚠️ Tudo a funcionar, com ${avisos.length} aviso(s)**` : `**✅ Tudo a funcionar (${rows.length} controlos)**`;
md += ` · ${new Date().toISOString().replace('T', ' ').slice(0, 16)} UTC · ${Math.round((Date.now() - t0) / 1000)} s\n\n`;
if (falhas.length) md += '## O que falhou\n' + falhas.map((r) => `- ❌ **${r.nome}** (${r.grupo}) — ${r.detalhe}`).join('\n') + '\n\n';
if (avisos.length) md += '## Avisos\n' + avisos.map((r) => `- ⚠️ **${r.nome}** (${r.grupo}) — ${r.detalhe}`).join('\n') + '\n\n';
md += '## Todos os controlos\n\n| | Grupo | Controlo | Detalhe |\n|---|---|---|---|\n' + rows.map((r) => `| ${ic[r.estado]} | ${r.grupo} | ${r.nome} | ${r.detalhe} |`).join('\n') + '\n';
fs.writeFileSync('summary.md', md); fs.writeFileSync('rows.json', JSON.stringify(rows));
fs.writeFileSync('estado.txt', falhas.length ? 'falha' : avisos.length ? 'aviso' : 'ok');
console.log(`\nResumo: ${rows.length - falhas.length - avisos.length} ok · ${avisos.length} avisos · ${falhas.length} falhas`);
process.exit(falhas.length ? 1 : 0);

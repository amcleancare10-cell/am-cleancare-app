// Junta os resultados de todos os controlos (rows-*.json) num único relatório (summary.md) e decide o estado.
// Saída : summary.md, estado.txt (ok | aviso | falha) e código 0/1. Os AVISOS não geram e-mail; só as FALHAS.
import fs from 'node:fs';
import path from 'node:path';

const dir = process.argv[2] || 'resultados';
let rows = [];
const lerTodos = (d) => { for (const f of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, f.name); if (f.isDirectory()) lerTodos(p); else if (/^rows.*\.json$/.test(f.name)) { try { rows.push(...JSON.parse(fs.readFileSync(p, 'utf8'))); } catch (_) { rows.push({ grupo: 'Controlos', nome: 'ler ' + f.name, estado: 'falha', detalhe: 'ficheiro de resultados ilegível' }); } } } };
if (fs.existsSync(dir)) lerTodos(dir);
const esperados = ['Painel', 'Site', 'App', 'Supabase', 'Serviços', 'Segurança', 'Agente', 'E-mail', 'Painel (gerente e admin)', 'App dos locatários', 'Código da app'];
for (const g of ['Painel', 'Painel (gerente e admin)', 'App dos locatários']) if (!rows.some((r) => r.grupo === g)) rows.push({ grupo: g, nome: 'o controlo "' + g + '" não devolveu resultados', estado: 'falha', detalhe: 'a tarefa falhou antes de terminar (ver o relatório no GitHub)' });
const falhas = rows.filter((r) => r.estado === 'falha'), avisos = rows.filter((r) => r.estado === 'aviso');
const ic = { ok: '✅', aviso: '⚠️', falha: '❌' };
let md = `# Controlo automático AM Clean Care\n\n`;
md += falhas.length ? `**❌ ${falhas.length} controlo(s) a falhar**` : avisos.length ? `**⚠️ Tudo a funcionar, com ${avisos.length} aviso(s)**` : `**✅ Tudo a funcionar (${rows.length} controlos)**`;
md += ` · ${new Date().toISOString().replace('T', ' ').slice(0, 16)} UTC\n\n`;
if (falhas.length) md += '## O que falhou\n' + falhas.map((r) => `- ❌ **${r.nome}** (${r.grupo}) — ${String(r.detalhe || '').replace(/\n/g, ' ')}`).join('\n') + '\n\n';
if (avisos.length) md += '## Avisos (não precisam de ação urgente)\n' + avisos.map((r) => `- ⚠️ **${r.nome}** (${r.grupo}) — ${String(r.detalhe || '').replace(/\n/g, ' ')}`).join('\n') + '\n\n';
md += '## Todos os controlos\n\n| | Grupo | Controlo | Detalhe |\n|---|---|---|---|\n' + rows.map((r) => `| ${ic[r.estado]} | ${r.grupo} | ${r.nome} | ${String(r.detalhe || '').replace(/\|/g, '/').replace(/\n/g, ' ')} |`).join('\n') + '\n';
fs.writeFileSync('summary.md', md);
fs.writeFileSync('estado.txt', falhas.length ? 'falha' : avisos.length ? 'aviso' : 'ok');
console.log(`Resumo: ${rows.length - falhas.length - avisos.length} ok · ${avisos.length} avisos · ${falhas.length} falhas`);
process.exit(falhas.length ? 1 : 0);

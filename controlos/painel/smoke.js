// Teste de fumo do painel: carrega o código real num browser simulado (jsdom) com um Supabase falso
// e abre todas as páginas, como gerente e como admin, para apanhar erros de execução.
const fs = require('fs');
const { JSDOM } = require('jsdom');
const WEB = (process.env.WEB_DIR ? require('path').resolve(process.env.WEB_DIR) : require('path').resolve(__dirname, '../../web')) + '/';

const FIX = {
  login_view: [{ user_id: 'U1', role: 'manager', name: 'Gerente Teste', email: 't@x.ch' }],
  batiment: [{ id: 37, address: 'Rue de Test 1', description: 'Edificio', floors: 4, entry_code: '1234', manager_id: 'U1', imgBatiment: '', adress_jardin: 'Jardin', total_surface_jardin: 120, frequence_jardin: 'Mensuelle', contact_immo_jardin: 'x' }],
  ticket_apartment_manager_view: [
    { ticket_id: 1, title: 'Fuite', description: 'Eau', photos: ['http://x/y.jpg'], status: 'En Attente', ticket_created_at: '2026-01-01T10:00:00Z', apartment_id: 37, address: 'Rue de Test 1', apartment_number: '3B', tenant_name: 'Ana', tenant_email: 'a@x.ch', tenant_phone: '079', tenant_floor: 3, manager_id: 'U1', agency_name: 'G', manager_name: 'M', manager_email: 'm@x.ch', apartment_description: 'Edificio' },
    { ticket_id: 2, title: 'Lumière', description: '', photos: [], status: 'Fermé', ticket_created_at: '2026-01-02T10:00:00Z', apartment_id: 37, address: 'Rue de Test 1', apartment_number: '4A', tenant_name: 'Rui', tenant_email: 'r@x.ch', manager_id: 'U1' },
  ],
  tenants: [{ user_id: 'T1', full_name: 'Ana', email: 'a@x.ch', phone: '079', apartment_id: 37, apartNum: '3B', statusAproved: 'En Attente', created_at: '2026-01-01T10:00:00Z' }],
  ticket_chats: [{ id: 1, ticket_id: 1, author_id: 'T1', author_name: 'Ana', message: 'Bonjour', sent_at: '2026-01-01T10:05:00Z' }],
  ticket_report_view: [{ annee: 2026, mois: 1, apartment_id: 37, type_de_probleme: 'Plomberie', nb_tickets: 3 }],
  avg_response_time_view: [{ annee: 2026, mois: 1, apartment_id: 37, temps_reponse_moyen_seconds: 5400 }],
  announcements: [{ id: 1, description: 'Vélo', photo: ['http://x/a.jpg'], price: 50, free: false, contact: '079', created_at: '2026-01-01T10:00:00Z', apartamentID: 37, tenantID: 'T1' }],
  CodeInscription: [{ id: 1, apartID: 37, title: 'Appart 3B', uuidRandom: 'abc' }],
  batiment_codes: [{ id: 1, apartment_id: 37, code: '4321', location: 'Boîte' }],
  Entreprise: [{ id: 5, name: 'Plombier SA', TypeEntreprise: 'Plomberie', typeID: 1, email: 'p@x.ch', phone: '021', managerID: 'U1' }],
  entreprise_types: [{ id: 1, name: 'Plomberie', description: '', is_active: true }],
  problem_types: [{ id: 1, name: 'Fuite', color: '#f00', locationID: 1 }],
  locations: [{ id: 1, description: 'Cuisine' }],
  codesReduction: [{ id: 1, title: 'Promo', code: 'X10', description: 'd', img: '' }],
  managers: [{ user_id: 'U1', manager_name: 'M', agency_name: 'G', email: 'm@x.ch', phone: '1', agency_address: 'a', agency_img: '', username: 'g', created_at: '2026-01-01T10:00:00Z' }],
  infoCamera: [{ id: 1, building: 'B', floor: 1, area_room: 'Hall', camera_name: 'Cam1', ip_address: '10.0.0.1', port: 554, username: 'u', password: 'p', rtsp_url: 'rtsp://x' }],
  annonces_immo: [{ id: 'A1', batimentID: 37, offer_type: 'Location', address: 'Rue de Test 1', city: 'Lausanne', apartment_number: '3B', pieces: '3', living_space: 70, rent: 1800, photos: ['http://x/p.jpg'], created_at: '2026-01-01T10:00:00Z', receive_email: true }],
  candidate_information: [{ id: 'C1', annonces_id: 'A1', apartID: '37', full_name: 'Paul', email: 'p@x.ch', annual_income: 90000, employer_name: 'ACME', created_at: '2026-01-02T10:00:00Z', piece_identite: ['http://x/id.pdf'] }],
  admin_chats: [{ id: 1, author_id: 'T1', user_id: 'U1', message: 'Bonjour, une clé ?', sent_at: '2026-01-03T10:00:00Z' }],
  ticket_event: [{ id: 1, ticket_id: 1, step: 'analyse', note: null, planned_at: null, created_at: '2026-01-02T10:00:00Z' }],
  buanderie: [{ id: 1, batiment_id: 37, nom: 'Buanderie A', machines: ['Lave-linge', 'Séchoir'], jours: [1, 2, 3, 4, 5], heure_debut: 7, heure_fin: 22, duree_creneau: 5, regles: '', batiments_acces: [], actif: true, ordre: 0 }],
  buanderie_planning: [{ id: 1, buanderie_id: 1, jour: 2, debut: 12, machine: 'Lave-linge', apartment_num: '3B' }],
  batiment_presence: [{ id: 1, batiment_id: 37, jour: 1, debut: '08:00', fin: '12:00' }],
  calendrier_tonte: [{ id: 1, batiment_id: 37, month: 'Mars', description: 'Tonte' }],
  'Notification New': [{ id: 1, userid: 'U1', Tittle: 'Nouveau ticket #1', Description: 'Fuite', Read: 'Unread', created_at: '2026-01-01T10:00:00Z' }], user_profiles: [{ user_id: 'U1', role: 'manager' }], pdf_responses: [],
};

function makeSb(fix) {
  class Q {
    constructor(t) { this.t = t; this.op = 'select'; }
    select() { return this; } eq() { return this; } gte() { return this; } lte() { return this; } or() { return this; } in() { return this; } order() { return this; } limit() { return this; }
    insert() { this.op = 'w'; return this; } update() { this.op = 'w'; return this; } delete() { this.op = 'w'; return this; }
    maybeSingle() { this.single = true; return this; }
    then(res, rej) { const d = fix[this.t] || []; return Promise.resolve({ data: this.op === 'w' ? null : (this.single ? d[0] || null : d), error: null }).then(res, rej); }
  }
  return {
    from: (t) => new Q(t),
    rpc: async () => ({ data: { ticket: 1 }, error: null }),
    auth: { getSession: async () => ({ data: { session: null } }), signOut: async () => ({}), signInWithPassword: async () => ({ data: { user: { id: 'U1', email: 't@x.ch' } }, error: null }), resetPasswordForEmail: async () => ({}), updateUser: async () => ({}) },
    storage: { from: () => ({ upload: async () => ({ error: null }), getPublicUrl: () => ({ data: { publicUrl: 'http://x/f' } }) }) },
    functions: { invoke: async () => ({ data: {}, error: { message: 'not deployed' } }) },
  };
}

async function run(role) {
  const html = fs.readFileSync(WEB + 'index.html', 'utf8').replace(/<script[^>]*><\/script>/g, '');
  const dom = new JSDOM(html, { runScripts: 'outside-only', url: 'https://amcleancare.ch/gerance/index.html' });
  const w = dom.window;
  w.supabase = { createClient: () => makeSb(JSON.parse(JSON.stringify(FIX))) };
  w.crypto.randomUUID = () => '00000000-0000-4000-8000-000000000000';
  const errors = [];
  w.addEventListener('error', (e) => errors.push(e.message));
  for (const f of (process.env.BUNDLE ? ['config.js', 'js/panel.bundle.js'] : ['config.js', 'js/core.js', 'js/services.js', 'js/pages-main.js', 'js/pages-res.js', 'js/pages-extra.js', 'js/home-ff.js', 'js/accounts.js', 'js/registre.js', 'js/jardin.js', 'js/codes-auto.js', 'js/locataires-import.js', 'js/app-qr.js', 'js/batiment-photo.js', 'js/faq.js', 'js/tutoriels-data.js', 'js/tutoriels.js', 'js/manager-home.js', 'js/sql-update.js', 'js/sql-clean.js', 'js/maintenance.js', 'js/comptes.js', 'js/rapports.js', 'js/demandes.js', 'js/buanderie.js', 'js/admin-home.js'])) {
    try { w.eval(fs.readFileSync(WEB + f, 'utf8')); } catch (e) { errors.push(f + ': ' + e.message); }
  }
  const AM = w.AM;
  AM.state = { authUid: 'U1', uid: 'U1', role, name: 'Gerente Teste', email: 't@x.ch', isAdmin: role === 'admin', buildingIds: role === 'admin' ? null : [37] };
  w.document.getElementById('shell').hidden = false;
  AM.buildShell();
  const results = [];
  for (const [name, def] of Object.entries(AM.routes)) {
    const el = w.document.getElementById('main'); el.innerHTML = '';
    try { await def.render(el, name === 'ticket' ? '1' : ''); const len = el.innerHTML.length; results.push([name, len > 80 ? 'ok' : 'VAZIO(' + len + ')']); }
    catch (e) { results.push([name, 'ERRO: ' + e.message]); }
  }
  // ---- interações ----
  const inter = [];
  const tick = () => new Promise((r) => setTimeout(r, 30));
  const doc = w.document;
  const step = async (label, fn) => { try { const ok = await Promise.race([fn(), new Promise((_, rej) => setTimeout(() => rej(new Error('tempo esgotado (10 s)')), 10000))]); inter.push([label, ok ? 'ok' : 'FALHOU']); } catch (e) { inter.push([label, 'ERRO: ' + e.message]); } };
  for (const r of [...(role === 'admin' ? ['batiments'] : []), 'codes-inscription', ...(role === 'admin' ? ['codes-boite'] : []), 'entreprises', 'annonces-immo', ...(role === 'admin' ? ['gerances', 'types-entreprise', 'lieux', 'codes-reduction', 'cameras'] : [])]) {
    await step('adicionar em ' + r, async () => {
      const el = doc.getElementById('main'); await AM.routes[r].render(el, ''); const add = doc.getElementById('add') || doc.getElementById('g_new'); if (!add) return false;
      add.click(); await tick(); const ok = !!doc.querySelector('#modal .mbox form') || !!doc.querySelector('#modal #a_e'); AM.closeModal(); return ok;
    });
  }
  if (role === 'admin') await step('buanderie: nova buanderie + planning', async () => { const el = doc.getElementById('main'); await AM.routes.buanderie.render(el, ''); doc.getElementById('bn_new').click(); await tick(); const ok = !!doc.querySelector('#modal #f_mach') && !!doc.getElementById('pl_add'); AM.closeModal(); return ok; });
  if (role === 'admin') await step('presença: adicionar', async () => { const el = doc.getElementById('main'); await AM.routes.presence.render(el, ''); return !!doc.getElementById('pr_add') && /08:00|matin|après-midi/i.test(el.innerHTML); });
  await step('ticket: abrir bon de commande', async () => { const el = doc.getElementById('main'); await AM.routes.ticket.render(el, '1'); doc.getElementById('bc').click(); await new Promise((r) => setTimeout(r, 80)); const ok = !!doc.querySelector('#modal #be'); AM.closeModal(); return ok; });
  await step('ticket: linha do tempo', async () => { const el = doc.getElementById('main'); await AM.routes.ticket.render(el, '1'); return /Suivi/.test(el.innerHTML) && /Bons de commande envoy/.test(el.innerHTML) && !el.querySelector('[data-step]'); });
  await step('ticket: guardar estado', async () => { const el = doc.getElementById('main'); await AM.routes.ticket.render(el, '1'); doc.getElementById('st').value = 'En Cours'; w.location.hash = '#/ticket/1'; doc.getElementById('sv').click(); await new Promise((r) => setTimeout(r, 600)); const sb = doc.getElementById('sb'); return !!sb; });
  await step('ticket: enviar mensagem', async () => { const el = doc.getElementById('main'); await AM.routes.ticket.render(el, '1'); doc.getElementById('mg').value = 'Olá'; doc.getElementById('sd').click(); await new Promise((r) => setTimeout(r, 80)); return true; });
  await step('locatários: aceitar', async () => { const el = doc.getElementById('main'); await AM.routes.locataires.render(el, ''); const b = doc.querySelector('#tb button[data-s="Accepté"]'); if (!b) return false; b.click(); await new Promise((r) => setTimeout(r, 80)); return true; });
  await step('candidaturas: abrir ficha', async () => { const el = doc.getElementById('main'); await AM.routes.candidatures.render(el, ''); const tg = doc.querySelector('[data-tg]'); if (!tg) return false; tg.click(); await tick(); const tr = doc.querySelector('tr[data-id]'); if (!tr) return false; tr.click(); await tick(); const ok = doc.querySelector('#modal')?.textContent.includes('Paul'); AM.closeModal(); return !!ok; });
  await step('notificações: enviar', async () => { const el = doc.getElementById('main'); await AM.routes.notifications.render(el, ''); doc.getElementById('all').click(); await new Promise((r) => setTimeout(r, 30)); const rows = doc.querySelectorAll('#tb tr').length; doc.getElementById('nt').value = 'T'; doc.getElementById('nm').value = 'M'; return rows >= 1 && !!doc.getElementById('ch_p') && !!doc.getElementById('ch_e') && !!doc.getElementById('ns'); });
  await step('comunidade: grupos WhatsApp por prédio', async () => { const el = doc.getElementById('main'); await AM.routes.communaute.render(el, ''); return /Locataire Connect/.test(el.innerHTML) && /WhatsApp|groupe/i.test(el.innerHTML); });
  await step('locataires: duas partes (lista + importar/cartas)', async () => { const el = doc.getElementById('main'); await AM.routes.locataires.render(el, ''); const t = el.querySelectorAll('.tabs a[data-mode]'); return t.length === 2 && !!el.querySelector('#li_f') && !!el.querySelector('#lt_pdf') && !!el.querySelector('#lt_zip'); });
  await step('importar CSV: leitura flexível', async () => { const r = AM.parseCsv('Mieter;Wohnung;Stock;Email\nDupont Marie;12;3;a@b.ch'); const g = AM.guessColumns(r); const o = AM.applyColumns(r, g.header, g.map); return o.length === 1 && o[0].nom === 'Dupont Marie' && o[0].apt === '12' && o[0].etage === '3'; });
  await step('FAQ do concierge: página abre', async () => { const el = doc.getElementById('main'); await AM.routes.faq.render(el, ''); return /Questions fréquentes/.test(el.innerHTML); });
  await step('sugestão IA no ticket: sempre há proposta', async () => { const s = AM.localSuggest({ title: 'Fuite', description: 'Eau dans la salle de bain', tenant_name: 'Ana' }, [{ id: 1, name: 'Plomberie' }]); return s.secteur === 'Plomberie' && !!s.action && !!s.message_locataire; });
  await step('inbox: marcar como lida', async () => { const el = doc.getElementById('main'); await AM.routes.inbox.render(el, ''); const d = doc.querySelector('[data-id]'); if (!d) return false; d.click(); await new Promise((r) => setTimeout(r, 60)); return true; });
  await step('demandas: formulário interativo', async () => { const el = doc.getElementById('main'); await AM.routes.demandes.render(el, 'images'); const ok1 = !!doc.getElementById('dm_send') && el.querySelectorAll('.dm-type').length === 2; doc.querySelector('[data-t="nettoyage"]').click(); const ok2 = !!doc.querySelector('[data-s]') && /Récapitulatif/.test(el.innerHTML); return ok1 && ok2; });
  console.log('  interações: ' + inter.filter((i) => i[1] === 'ok').length + '/' + inter.length + ' ok');
  inter.filter((i) => i[1] !== 'ok').forEach((i) => console.log('  ✗', i[0], i[1]));
  results.push(...inter.filter((i) => i[1] !== 'ok'));
  const navRoutes = [...w.document.querySelectorAll('#nav a')].map((a) => a.dataset.r);
  const missing = navRoutes.filter((r) => !AM.routes[r.split('/')[0]]);
  console.log(`\n== ${role}: ${results.filter((r) => r[1] === 'ok').length}/${results.length} páginas ok; menu: ${navRoutes.length} entradas${missing.length ? '; SEM ROTA: ' + missing : ''}`);
  results.filter((r) => r[1] !== 'ok').forEach((r) => console.log('  ✗', r[0], r[1]));
  errors.forEach((e) => console.log('  erro global:', e));
  return results.every((r) => r[1] === 'ok') && !missing.length && !errors.length;
}

(async () => {
  const a = await run('manager'); const b = await run('admin');
  console.log(a && b ? '\nTUDO OK' : '\nHÁ PROBLEMAS');
  process.exit(a && b ? 0 : 1);
})();

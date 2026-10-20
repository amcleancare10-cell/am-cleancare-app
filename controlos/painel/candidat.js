const fs = require('fs');
const { JSDOM } = require('jsdom');
const WEB = (process.env.WEB_DIR ? require('path').resolve(process.env.WEB_DIR) : require('path').resolve(__dirname, '../../web')) + '/';
(async () => {
  const html = fs.readFileSync(WEB + 'candidat.html', 'utf8').replace(/<script[^>]*><\/script>/g, '');
  const dom = new JSDOM(html, { runScripts: 'outside-only', url: 'https://amcleancare.ch/gerance/candidat.html?annonce=A1' });
  const w = dom.window; const inserted = [];
  const ad = { id: 'A1', batimentID: 37, offer_type: 'Location', address: 'Rue de Test 1', city: 'Lausanne', pieces: '3', living_space: 70, rent: 1800, photos: [], receive_email: true };
  w.supabase = { createClient: () => ({
    from: (t) => ({ select: () => ({ eq: () => ({ maybeSingle: async () => ({ data: t === 'annonces_immo' ? ad : null, error: null }) }) }), insert: async (row) => { inserted.push([t, row]); return { error: null }; } }),
    storage: { from: () => ({ upload: async () => ({ error: null }), getPublicUrl: () => ({ data: { publicUrl: 'http://x/doc.pdf' } }) }) },
    functions: { invoke: async () => ({ data: {}, error: null }) } }) };
  w.crypto.randomUUID = () => '11111111-1111-4111-8111-111111111111';
  w.eval(fs.readFileSync(WEB + 'config.js', 'utf8')); w.eval(fs.readFileSync(WEB + 'js/candidat.js', 'utf8'));
  await new Promise((r) => setTimeout(r, 100));
  const d = w.document;
  console.log('formulário visível:', !d.getElementById('form').hidden, '| campos:', d.querySelectorAll('#form input, #form select, #form textarea').length, '| anúncio mostrado:', d.getElementById('ad').textContent.includes('Rue de Test 1'));
  d.getElementById('f_full_name').value = 'Paul Martin'; d.getElementById('f_email').value = 'p@x.ch'; d.getElementById('f_personal_phone').value = '079'; d.getElementById('f_date_of_birth').value = '1990-05-04'; d.getElementById('f_annual_income').value = '90000';
  d.getElementById('f_etat_civil').value = 'Marié(e)'; d.getElementById('f_searche_recently').checked = true; d.getElementById('consent').checked = true;
  d.getElementById('form').dispatchEvent(new w.Event('submit', { cancelable: true }));
  await new Promise((r) => setTimeout(r, 150));
  const row = inserted[0]?.[1];
  console.log('inserido em:', inserted[0]?.[0], '| apartID:', row?.apartID, '| annonces_id:', row?.annonces_id, '| nome:', row?.full_name, '| renda:', row?.annual_income, '| estado civil:', row?.etat_civil, '| bool:', row?.searche_recently);
  console.log('ecrã de agradecimento:', !d.getElementById('done').hidden);
  process.exit(row && !d.getElementById('done').hidden ? 0 : 1);
})();

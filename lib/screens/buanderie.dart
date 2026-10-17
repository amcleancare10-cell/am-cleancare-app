import 'package:flutter/material.dart' hide Text;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n.dart';
import '../api.dart';
import '../config.dart';
import '../ui.dart';
import 'requests.dart';

/// Buanderie: planning semanal FIXO do edifício. Só a gérance (admin, no painel) o altera; o locatário consulta
/// e vê o seu dia a destacado. Os dias avançam sozinhos: mostra sempre os próximos dias de abertura a partir de hoje.
class BuanderieScreen extends StatefulWidget {
  const BuanderieScreen({super.key, required this.me});
  final Me me;
  @override
  State<BuanderieScreen> createState() => _BuanderieScreenState();
}

const _dayNames = {
  'fr': ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
  'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  'de': ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
  'pt': ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
  'sq': ['Hën', 'Mar', 'Mër', 'Enj', 'Pre', 'Sht', 'Die'],
};
const _dayLong = {
  'fr': ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'],
  'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  'de': ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
  'pt': ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'],
  'sq': ['e hënë', 'e martë', 'e mërkurë', 'e enjte', 'e premte', 'e shtunë', 'e diel'],
};
String dayName(int weekday) => (_dayNames[L.lang.value] ?? _dayNames['fr']!)[weekday - 1];
String dayLong(int weekday) => (_dayLong[L.lang.value] ?? _dayLong['fr']!)[weekday - 1];
String hh(int h) => '${h.toString().padLeft(2, '0')}h';
String ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool isDry(String m) {
  final l = m.toLowerCase();
  return l.contains('sé') || l.contains('seche') || l.contains('dry') || l.contains('trock') || l.contains('seca');
}
List<int> intList(dynamic v) => v is List ? v.map((e) => int.tryParse('$e') ?? 0).toList() : <int>[];
String normApt(dynamic v) => '$v'.trim().toLowerCase();

class _BuanderieScreenState extends State<BuanderieScreen> {
  bool loading = true, missing = false;
  List<Json> laundries = [];
  Json? cur;
  List<Json> planning = [], reservations = [], myRes = [];
  bool resMissing = false;
  late DateTime today, sel;

  @override
  void initState() {
    super.initState();
    today = dayOnly(DateTime.now());
    sel = today;
    load();
  }

  int get bid => widget.me.buildingId ?? -1;

  Future<void> load() async {
    try {
      final rows = List<Json>.from(await sb.from('buanderie').select().or('batiment_id.eq.$bid,batiments_acces.cs.{$bid}').eq('actif', true).order('ordre').order('id'));
      // só as lavandarias deste edifício (nunca de outros)
      laundries = rows.where((r) => r['actif'] != false && (r['batiment_id'] == bid || intList(r['batiments_acces']).contains(bid))).toList();
      if (laundries.isNotEmpty) {
        final keep = cur == null ? null : laundries.where((l) => l['id'] == cur!['id']).firstOrNull;
        cur = keep ?? laundries.first;
        await loadPlanning();
      } else {
        cur = null;
      }
      missing = false;
    } on PostgrestException catch (e) {
      debugPrint('buanderie: ${e.message}'); // tabela ainda não criada (SQL 07 por correr) ou sem acesso
      missing = true;
      laundries = [];
    } catch (e) {
      debugPrint('buanderie: $e');
      missing = true;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> loadPlanning() async {
    final id = cur!['id'];
    final rows = List<Json>.from(await sb.from('buanderie_planning').select().eq('buanderie_id', id));
    planning = rows.where((r) => r['buanderie_id'] == id).toList();
    await loadReservations();
    final days = shownDays;
    if (days.isNotEmpty && !days.any((d) => ymd(d) == ymd(sel))) sel = days.first;
  }

  /// Inscrições em horários livres (dias extra): as de toda a buanderie nos próximos dias e as minhas.
  /// O locatário já não se inscreve sozinho: só o admin atribui os horários (as inscrições antigas não se usam).
  Future<void> loadReservations() async {
    reservations = [];
    myRes = [];
    resMissing = false;
  }

  // ------------------------------------------------------------ utilidades
  List<String> get machines => (cur?['machines'] is List ? (cur!['machines'] as List).map((e) => '$e').toList() : <String>[]);
  int get hStart => (cur?['heure_debut'] as num?)?.toInt() ?? 7;
  int get hEnd => (cur?['heure_fin'] as num?)?.toInt() ?? 22;
  int get dur => ((cur?['duree_creneau'] as num?)?.toInt() ?? 5).clamp(1, 12);
  List<int> get openDays => intList(cur?['jours']).isEmpty ? [1, 2, 3, 4, 5] : intList(cur?['jours']);
  List<int> get starts => [for (var h = hStart; h + dur <= hEnd; h += dur) h];
  DateTime startOf(DateTime day, int h) => DateTime(day.year, day.month, day.day, h);

  /// Próximos dias de abertura (14 dias a partir de hoje, sem fins de semana se a buanderie não abre): muda sozinho todos os dias.
  List<DateTime> get shownDays => [for (var i = 0; i < 14; i++) today.add(Duration(days: i))].where((d) => openDays.contains(d.weekday)).toList();

  Json? cellAt(int weekday, int h, String machine) => planning.where((r) => (r['jour'] as num).toInt() == weekday && (r['debut'] as num).toInt() == h && r['machine'] == machine).firstOrNull;
  Json? resAt(DateTime d, int h, String m) => reservations.where((r) => '${r['jour']}'.startsWith(ymd(d)) && (r['debut'] as num).toInt() == h && r['machine'] == m).firstOrNull;
  bool myResMine(Json r) => r['tenant_id'] == widget.me.uid;
  DateTime resStart(Json r) {
    final d = DateTime.parse('${r['jour']}'.substring(0, 10));
    return startOf(d, (r['debut'] as num).toInt());
  }
  /// Já tenho um horário nesse dia? (fixo ou inscrição) — só se pode ter um por dia
  bool hasSlotOn(DateTime d) => myCells.any((c) => (c['jour'] as num).toInt() == d.weekday) || myRes.any((r) => '${r['jour']}'.startsWith(ymd(d)));
  bool isMine(Json r) => normApt(r['apartment_num']) == normApt(widget.me.apartNum) && widget.me.apartNum.trim().isNotEmpty;
  List<Json> get myCells => planning.where(isMine).toList()
    ..sort((a, b) => ((a['jour'] as num).toInt() * 100 + (a['debut'] as num).toInt()).compareTo((b['jour'] as num).toInt() * 100 + (b['debut'] as num).toInt()));

  /// Próxima data do meu horário (hoje se ainda não terminou).
  ({DateTime start, Json cell})? get next {
    final now = DateTime.now();
    ({DateTime start, Json cell})? best;
    for (final c in myCells) {
      for (var i = 0; i < 8; i++) {
        final d = today.add(Duration(days: i));
        if (d.weekday != (c['jour'] as num).toInt()) continue;
        final end = startOf(d, (c['debut'] as num).toInt() + dur);
        if (end.isAfter(now)) {
          final s = startOf(d, (c['debut'] as num).toInt());
          if (best == null || s.isBefore(best.start)) best = (start: s, cell: c);
          break;
        }
      }
    }
    for (final r in myRes) {
      final st = resStart(r);
      if (st.add(Duration(hours: dur)).isAfter(now) && (best == null || st.isBefore(best.start))) best = (start: st, cell: r);
    }
    return best;
  }

  String nameOfLaundry(dynamic id) => '${laundries.where((l) => l['id'] == id).firstOrNull?['nom'] ?? ''}';

  final Set<String> requested = {};
  Future<void> cancelRes(Json r) async {}   // (inscrições diretas já não existem)

  /// Locatário novo (sem horário fixo): pede um dia e uma hora; o pedido vai por e-mail à AM Clean Care e só o admin o coloca no planning.
  Future<void> requestSlot(DateTime day, int h, String machine) async {
    final label = '$machine · ${dayLong(day.weekday)} ${day.day}.${day.month.toString().padLeft(2, '0')} · ${hh(h)}–${hh(h + dur)}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Demander ce créneau ?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text("L'administrateur vous attribuera ce créneau dans le planning et vous serez prévenu(e)."),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => Navigator.pop(context, true), child: const Text('Envoyer la demande')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final me = widget.me;
      final m = await Api.managerOf(me);
      final when = '${dayLong(day.weekday)} ${day.day}.${day.month.toString().padLeft(2, '0')}.${day.year}';
      await Api.email('laundry_slot_request', AppConfig.supportEmail, AppConfig.appName, {
        'ref': 'BUA-${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(2, 12)}',
        'deviceType': '${cur?['nom'] ?? 'Buanderie'} · $machine',
        'details': 'Jour demandé : $when\nCréneau : ${hh(h)}–${hh(h + dur)}\nMachine : $machine\nBuanderie : ${cur?['nom'] ?? ''}\n(Locataire sans créneau fixe : à attribuer dans le planning.)',
        'nomeLocatario': me.name, 'building': me.buildingName, 'address': '${me.building?['address'] ?? ''}', 'floor': '${me.floor ?? ''}', 'num': me.apartNum,
        'email': me.email, 'tenantPhone': me.phone, 'managerName': '${m?['manager_name'] ?? ''}', 'agencyName': '${m?['agency_name'] ?? ''}',
        'landlordEmail': '${m?['email'] ?? ''}', 'landlordPhone': '${m?['phone'] ?? ''}',
      });
      requested.add('${ymd(day)}-$h-$machine');
      if (mounted) { setState(() {}); toast(context, 'Demande envoyée. Vous serez prévenu(e) quand le créneau sera attribué.'); }
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    }
  }

  void report() => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestScreen(me: widget.me, kind: RequestKind.laundry)));

  // ------------------------------------------------------------ visual
  Widget reportButton() => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), foregroundColor: kAmber, side: BorderSide(color: kAmber.withValues(alpha: .6), width: 1.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: report,
          icon: const Icon(Icons.report_problem_outlined),
          label: const Text('Signaler un problème', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      );

  Widget slotCell(DateTime day, int h, String machine) {
    final r = cellAt(day.weekday, h, machine);
    final dark = isDark(context);
    final past = startOf(day, h + dur).isBefore(DateTime.now());
    Widget box({required Widget child, Color? bg, Gradient? grad, Border? border, List<BoxShadow>? shadow, VoidCallback? onTap}) => Padding(
          padding: const EdgeInsets.all(3),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onTap,
            child: Ink(
              height: 52,
              decoration: BoxDecoration(color: bg, gradient: grad, borderRadius: BorderRadius.circular(13), border: border, boxShadow: shadow),
              child: Center(child: child),
            ),
          ),
        );
    if (r != null && isMine(r)) {
      return box(
        grad: const LinearGradient(colors: [kPrimary, kViolet]),
        shadow: [BoxShadow(color: kPrimary.withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 4))],
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Moi · ${widget.me.apartNum}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
          Text('${hh(h)}–${hh(h + dur)}', style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    if (r != null) {
      return box(bg: dark ? const Color(0xFF1B2038) : const Color(0xFFEEF0F6), child: Opacity(opacity: past ? .55 : 1, child: Text('App. ${r['apartment_num'] ?? ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mutedOf(context)))));
    }
    final rv = resAt(day, h, machine);
    if (rv != null && myResMine(rv)) {
      return box(
        grad: const LinearGradient(colors: [kPrimary, kViolet]),
        shadow: [BoxShadow(color: kPrimary.withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 4))],
        onTap: past ? null : () => cancelRes(rv),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Moi · ${widget.me.apartNum}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
          Text('${hh(h)}–${hh(h + dur)}', style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    if (rv != null) {
      return box(bg: dark ? const Color(0xFF1B2038) : const Color(0xFFEEF0F6), child: Opacity(opacity: past ? .55 : 1, child: Text('App. ${rv['apartment_num'] ?? ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mutedOf(context)))));
    }
    final isNew = myCells.isEmpty && widget.me.apartNum.trim().isNotEmpty;       // novo locatário: ainda sem horário no planning
    final asked = requested.contains('${ymd(day)}-$h-$machine');
    if (asked) {
      return box(bg: kAmber.withValues(alpha: .14), border: Border.all(color: kAmber.withValues(alpha: .5)), child: const Text('Demandé', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kAmber)));
    }
    if (isNew && !past) {
      return box(
        bg: kPrimary.withValues(alpha: dark ? .16 : .07),
        border: Border.all(color: kPrimary.withValues(alpha: .35)),
        onTap: () => requestSlot(day, h, machine),
        child: Icon(Icons.add_rounded, color: dark ? const Color(0xFFA9A3FF) : kPrimary),
      );
    }
    return box(bg: Colors.transparent, border: Border.all(color: lineOf(context)), child: Text('Libre', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: mutedOf(context).withValues(alpha: .6))));
  }

  Widget dayChip(DateTime d) {
    final on = ymd(d) == ymd(sel);
    final isToday = ymd(d) == ymd(today);
    final has = myCells.any((c) => (c['jour'] as num).toInt() == d.weekday);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => setState(() => sel = d),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? kPrimary : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: on ? kPrimary : (isToday ? kPrimary.withValues(alpha: .6) : lineOf(context)), width: isToday && !on ? 1.6 : 1),
            boxShadow: on ? [BoxShadow(color: kPrimary.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))] : null,
          ),
          child: Column(children: [
            Text(dayName(d.weekday), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: on ? Colors.white70 : mutedOf(context))),
            const SizedBox(height: 2),
            Text('${d.day}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: on ? Colors.white : null)),
            const SizedBox(height: 3),
            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: has ? (on ? Colors.white : kGreen) : Colors.transparent)),
          ]),
        ),
      ),
    );
  }

  Widget legendItem(Widget swatch, String t) => Row(mainAxisSize: MainAxisSize.min, children: [swatch, const SizedBox(width: 6), Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedOf(context)))]);

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 3));
    } else if (missing || laundries.isEmpty) {
      body = ListView(padding: const EdgeInsets.all(18), children: [
        const SizedBox(height: 30),
        EmptyState(missing ? "Le planning de la buanderie n'est pas encore activé." : "Aucune buanderie n'est configurée pour votre immeuble. Contactez votre gérance.", icon: Icons.local_laundry_service_outlined),
        reportButton(),
      ]);
    } else {
      final days = shownDays;
      final nx = next;
      final dark = isDark(context);
      final regles = '${cur?['regles'] ?? ''}'.trim();
      final mine = myCells;
      body = RefreshIndicator(
        onRefresh: () async { await load(); },
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
          if (laundries.length > 1) ...[
            const SectionTitle('Choisissez votre buanderie'),
            SizedBox(
              height: 46,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final l in laundries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(Icons.local_laundry_service_rounded, size: 18, color: l['id'] == cur!['id'] ? Colors.white : kPrimary),
                      label: Text('${l['nom']}', style: TextStyle(fontWeight: FontWeight.w800, color: l['id'] == cur!['id'] ? Colors.white : null)),
                      selected: l['id'] == cur!['id'],
                      selectedColor: kPrimary,
                      showCheckmark: false,
                      onSelected: (_) async { setState(() { cur = l; loading = true; }); try { await loadPlanning(); } catch (_) {} if (mounted) setState(() => loading = false); },
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          // ---- o meu próximo horário
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: kHeroGradient, borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 28)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nx == null ? '${cur!['nom']}' : 'Votre prochain créneau', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 3),
                Text(nx == null ? "Aucun jour n'est attribué à votre appartement. Contactez la gérance." : '${dayLong(nx.start.weekday)} ${nx.start.day}.${nx.start.month.toString().padLeft(2, '0')} · ${hh(nx.start.hour)}–${hh(nx.start.hour + dur)} · ${nx.cell['machine']}', style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3)),
              ])),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 94, child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, padding: const EdgeInsets.only(top: 2, bottom: 12), children: [for (final d in days) dayChip(d)])),
          const SizedBox(height: 6),
          // ---- planning do dia escolhido
          SoftCard(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: days.isEmpty || machines.isEmpty
                ? Padding(padding: const EdgeInsets.symmetric(vertical: 26), child: Center(child: Text(machines.isEmpty ? "Aucune machine n'est configurée." : 'La buanderie est fermée.', style: TextStyle(color: mutedOf(context), fontWeight: FontWeight.w600))))
                : Column(children: [
                    Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text('${dayLong(sel.weekday)[0].toUpperCase()}${dayLong(sel.weekday).substring(1)} ${sel.day}.${sel.month.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)))),
                    Row(children: [
                      const SizedBox(width: 44),
                      for (final m in machines)
                        Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(isDry(m) ? Icons.dry_rounded : Icons.local_laundry_service_outlined, size: 16, color: kPrimary),
                          const SizedBox(width: 4),
                          Flexible(child: Text(m, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: mutedOf(context)))),
                        ]))),
                    ]),
                    for (final h in starts)
                      Row(children: [
                        SizedBox(width: 44, child: Text(hh(h), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: mutedOf(context)))),
                        for (final m in machines) Expanded(child: slotCell(sel, h, m)),
                      ]),
                  ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: Wrap(spacing: 14, runSpacing: 6, children: [
              legendItem(Container(width: 12, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: lineOf(context), width: 1.4))), 'Libre'),
              legendItem(Container(width: 12, height: 12, decoration: BoxDecoration(color: dark ? const Color(0xFF3A4163) : const Color(0xFFCFD3E2), borderRadius: BorderRadius.circular(4))), 'Occupé'),
              legendItem(Container(width: 12, height: 12, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(4))), 'Mon créneau'),
              if (myCells.isEmpty) legendItem(Icon(Icons.add_rounded, size: 14, color: kPrimary), 'Demander'),
            ]),
          ),
          // ---- o meu horário fixo
          const SectionTitle('Mon horaire fixe'),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: mine.isEmpty
                ? Padding(padding: const EdgeInsets.all(14), child: Text("Aucun jour n'est attribué à votre appartement pour le moment.", style: TextStyle(color: mutedOf(context))))
                : Column(children: [
                    for (final c in mine)
                      ListTile(
                        leading: IconBadge(isDry('${c['machine']}') ? Icons.dry_rounded : Icons.local_laundry_service_outlined, color: kPrimary, size: 42),
                        title: Text('${tr('Chaque')} ${dayLong((c['jour'] as num).toInt())} · ${hh((c['debut'] as num).toInt())}–${hh((c['debut'] as num).toInt() + dur)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        subtitle: Text('${c['machine']}${laundries.length > 1 ? ' · ${nameOfLaundry(c['buanderie_id'])}' : ''}'),
                      ),
                  ]),
          ),
          if (myRes.where((r) => resStart(r).add(Duration(hours: dur)).isAfter(DateTime.now())).isNotEmpty) ...[
            const SectionTitle('Mes réservations'),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Column(children: [
                for (final r in myRes.where((r) => resStart(r).add(Duration(hours: dur)).isAfter(DateTime.now())))
                  ListTile(
                    leading: IconBadge(isDry('${r['machine']}') ? Icons.dry_rounded : Icons.local_laundry_service_outlined, color: kGreen, size: 42),
                    title: Text('${dayLong(resStart(r).weekday)} ${resStart(r).day}.${resStart(r).month.toString().padLeft(2, '0')} · ${hh(resStart(r).hour)}–${hh(resStart(r).hour + dur)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                    subtitle: Text('${r['machine']}${laundries.length > 1 ? ' · ${nameOfLaundry(r['buanderie_id'])}' : ''}'),
                    trailing: TextButton(onPressed: () => cancelRes(r), child: const Text('Annuler', style: TextStyle(color: kRed, fontWeight: FontWeight.w800))),
                  ),
              ]),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kAmber.withValues(alpha: dark ? .14 : .09), borderRadius: BorderRadius.circular(16), border: Border.all(color: kAmber.withValues(alpha: .35))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, size: 19, color: kAmber),
                const SizedBox(width: 10),
                Expanded(child: Text(myCells.isEmpty
                    ? "Vous n'avez pas encore de créneau : touchez le + sur un créneau libre pour le demander. L'administrateur l'attribuera dans le planning et vous préviendra. ${tr('Un créneau libre du planning peut être utilisé ; un créneau occupé par un autre locataire ne peut pas l\'être. Le non-respect du planning peut entraîner votre retrait du système.')}"
                    : tr("Un créneau libre du planning peut être utilisé ; un créneau occupé par un autre locataire ne peut pas l'être. Le non-respect du planning peut entraîner votre retrait du système."), style: const TextStyle(fontSize: 12.5, height: 1.4))),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 17, color: mutedOf(context)),
              const SizedBox(width: 8),
              Expanded(child: Text(regles.isNotEmpty ? regles : 'Le planning fixe est géré par la gérance. Pour changer votre jour fixe, contactez-la.', style: TextStyle(fontSize: 12.5, height: 1.35, color: mutedOf(context)))),
            ]),
          ),
          reportButton(),
        ]),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(cur == null ? 'Buanderie' : '${tr('Buanderie')}${laundries.length > 1 ? '' : ' · ${cur!['nom']}'}')),
      body: body,
    );
  }
}

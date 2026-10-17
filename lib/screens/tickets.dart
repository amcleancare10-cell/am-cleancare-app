import 'dart:typed_data';
import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import 'package:image_picker/image_picker.dart';
import '../api.dart';
import '../config.dart';
import '../ui.dart';

/// Gestionnaire de tickets: En cours / En attente / Fermé.
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.me});
  final Me me;
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  String filter = '';
  int _k = 0;

  Future<List<Json>> load() async {
    var q = sb.from('tickets').select().eq('tenant_id', widget.me.uid);
    if (filter.isNotEmpty) q = q.eq('status', filter);
    return List<Json>.from(await q.order('created_at', ascending: false).limit(200));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Gestionnaire de tickets')),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kPrimary, foregroundColor: Colors.white,
          onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => NewTicketScreen(me: widget.me))); setState(() => _k++); },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouveau ticket', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: Column(children: [
          SizedBox(
            height: 52,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), children: [
              for (final s in const ['', 'En Cours', 'En Attente', 'Fermé'])
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(s.isEmpty ? 'Tous' : (s == 'En Cours' ? 'En cours' : s == 'En Attente' ? 'En attente' : s)), selected: filter == s, selectedColor: kPrimary.withValues(alpha: .15), onSelected: (_) => setState(() { filter = s; _k++; }))),
            ]),
          ),
          Expanded(
            child: Load<List<Json>>(
              key: ValueKey(_k),
              future: load(),
              builder: (c, rows) => rows.isEmpty
                  ? EmptyState('Aucun ticket ici.\nSignalez un problème en quelques secondes.', icon: Icons.confirmation_number_outlined, action: 'Ouvrir un ticket', onAction: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => NewTicketScreen(me: widget.me))); setState(() => _k++); })
                  : RefreshIndicator(
                      onRefresh: () async => setState(() => _k++),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (c, i) {
                          final t = rows[i];
                          return FadeIn(
                            delay: i * 40,
                            child: SoftCard(
                              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetail(me: widget.me, ticket: t))); setState(() => _k++); },
                              child: Row(children: [
                                IconBadge(Icons.confirmation_number_outlined, color: statusColor('${t['status']}')),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('#${t['id']}  ${t['title'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(fmtDate(t['created_at']), style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
                                ])),
                                StatusChip(t['status']?.toString()),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ]),
      );
}

/// Discussion du problème: informações do residente + conversa.
class TicketDetail extends StatefulWidget {
  const TicketDetail({super.key, required this.me, required this.ticket});
  final Me me;
  final Json ticket;
  @override
  State<TicketDetail> createState() => _TicketDetailState();
}

class _TicketDetailState extends State<TicketDetail> {
  final msg = TextEditingController();
  final scroll = ScrollController();
  int _k = 0;

  Future<List<Json>> chat() async => List<Json>.from(await sb.from('ticket_chats').select().eq('ticket_id', widget.ticket['id']).order('sent_at'));

  Future<void> send() async {
    final txt = msg.text.trim();
    if (txt.isEmpty) return;
    msg.clear();
    try {
      await sb.from('ticket_chats').insert({'ticket_id': widget.ticket['id'], 'author_id': widget.me.uid, 'author_name': widget.me.name, 'message': txt, 'isVisualized': false});
      final m = await Api.managerOf(widget.me);
      Api.notify([widget.me.managerId], 'Ticket #${widget.ticket['id']}', 'Nouveau message de ${widget.me.name} : $txt');
      Api.email('chat_notification', m?['email']?.toString(), m?['manager_name']?.toString(), {'ticketNumber': '${widget.ticket['id']}', 'ticketTitle': '${widget.ticket['title']}', 'message': txt});
      setState(() => _k++);
      await Future.delayed(const Duration(milliseconds: 250));
      if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket, me = widget.me;
    final photos = (t['photos'] is List) ? List<String>.from((t['photos'] as List).map((e) => e.toString())) : <String>[];
    return Scaffold(
      appBar: AppBar(title: Text('Ticket #${t['id']}')),
      body: Column(children: [
        Expanded(
          child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), children: [
            SoftCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text('${t['title'] ?? ''}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), StatusChip(t['status']?.toString())]),
                const SizedBox(height: 4),
                Text(fmtDateTime(t['created_at']), style: TextStyle(color: mutedOf(context), fontSize: 12.5)),
                if ((t['description'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 12), Text('${t['description']}', style: const TextStyle(height: 1.4))],
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(height: 92, child: ListView(scrollDirection: Axis.horizontal, children: [for (final u in photos) Padding(padding: const EdgeInsets.only(right: 10), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(u, width: 92, height: 92, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(width: 92, color: Colors.black12, child: const Icon(Icons.broken_image_outlined)))))])),
                ],
              ]),
            ),
            TicketTimeline(key: ValueKey('tl$_k'), ticket: t),
            const SectionTitle('Informations du résident'),
            SoftCard(
              child: Column(children: [
                _info(context, Icons.person_outline_rounded, 'Résident', me.name),
                _info(context, Icons.apartment_rounded, 'Bâtiment', me.buildingName),
                _info(context, Icons.door_front_door_outlined, 'Appartement', '${me.apartNum}${me.floor != null ? ' · étage ${me.floor}' : ''}'),
                if (me.phone.isNotEmpty) _info(context, Icons.phone_outlined, 'Téléphone', me.phone),
              ]),
            ),
            const SectionTitle('Conversation'),
            Load<List<Json>>(
              key: ValueKey(_k),
              future: chat(),
              builder: (c, rows) => rows.isEmpty
                  ? Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('Aucun message pour le moment.', style: TextStyle(color: mutedOf(context)))))
                  : Column(children: [for (final m in rows) Bubble(text: '${m['message'] ?? ''}', mine: m['author_id'] == me.uid, meta: '${m['author_name'] ?? ''} · ${fmtDateTime(m['sent_at'])}')]),
            ),
          ]),
        ),
        ChatInput(controller: msg, onSend: send),
      ]),
    );
  }

  Widget _info(BuildContext c, IconData i, String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Icon(i, size: 20, color: mutedOf(c)), const SizedBox(width: 12), Text(l, style: TextStyle(color: mutedOf(c))), const Spacer(), Flexible(child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)))]));
}

/// Nouveau ticket.
class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key, required this.me});
  final Me me;
  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final title = TextEditingController(), desc = TextEditingController();
  List<Json> locations = [], types = [];
  int? locationId, typeId;
  String cat = 'appartement';   // 'appartement' | 'immeuble' (parties communes)
  String catOf(Json l) => '${l['categorie'] ?? 'appartement'}'.toLowerCase() == 'immeuble' ? 'immeuble' : 'appartement';
  final List<XFile> photos = [];
  final List<Uint8List> previews = [];
  bool busy = false, ready = false;

  @override
  void initState() {
    super.initState();
    () async {
      try {
        locations = List<Json>.from(await sb.from('locations').select().order('description'));
        types = List<Json>.from(await sb.from('problem_types').select().order('name'));
      } catch (_) {}
      if (mounted) setState(() => ready = true);
    }();
  }

  Future<void> pick() async {
    final r = await ImagePicker().pickMultiImage(imageQuality: 80, limit: 6);
    for (final x in r) {
      photos.add(x);
      previews.add(await x.readAsBytes());
    }
    if (mounted) setState(() {});
  }

  Future<void> submit() async {
    if (title.text.trim().isEmpty || typeId == null) { toast(context, 'Indiquez un titre et un type de problème.', error: true); return; }
    final me = widget.me;
    if (me.buildingId == null) { toast(context, 'Aucun bâtiment associé à votre compte.', error: true); return; }
    setState(() => busy = true);
    try {
      final urls = await Api.uploadImages(AppConfig.bucketTickets, photos);
      final ticket = await sb.from('tickets').insert({'tenant_id': me.uid, 'apartment_id': me.buildingId, 'title': title.text.trim(), 'description': desc.text.trim(), 'location_id': locationId, 'problem_type_id': typeId, 'status': 'En Attente', 'photos': urls}).select().single();
      if (desc.text.trim().isNotEmpty) {
        await sb.from('ticket_chats').insert({'ticket_id': ticket['id'], 'author_id': me.uid, 'author_name': me.name, 'message': desc.text.trim(), 'isVisualized': false});
      }
      final m = await Api.managerOf(me);
      await Api.notify([me.managerId], 'Nouveau ticket #${ticket['id']}', '${title.text.trim()} · ${me.name}');
      final now = DateTime.now();
      Api.email('ticket_created', m?['email']?.toString(), m?['manager_name']?.toString(), {
        'ticketNumber': '${ticket['id']}', 'ticketTitle': title.text.trim(), 'creatorName': me.name, 'apartmentName': me.buildingName, 'floor': '${me.floor ?? ''}', 'apartamentNumber': me.apartNum,
        'problemDescription': desc.text.trim(), 'location': '${locations.where((l) => l['id'] == locationId).firstOrNull?['description'] ?? ''}', 'problemType': '${types.where((x) => x['id'] == typeId).firstOrNull?['name'] ?? ''}',
        'photoUrls': urls.take(4).join(','), 'tenantPhone': me.phone, 'tenantEmail': me.email, 'address': '${me.building?['address'] ?? ''}', 'date': fmtDate(now.toIso8601String()), 'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}', 'landLordEmail': '${m?['email'] ?? ''}',
      });
      if (mounted) {
        toast(context, 'Ticket créé. La gérance a été prévenue.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // só aparecem os tipos do lugar escolhido, sem repetidos, com "Autre" no fim
    final seen = <String>{};
    final filtered = locationId == null
        ? <Json>[]
        : (types.where((t) => t['locationID'] == locationId && seen.add('${t['name']}'.trim().toLowerCase())).toList()
          ..sort((a, b) {
            int w(Json x) => '${x['name']}'.toLowerCase().startsWith('autre') ? 1 : 0;
            final c = w(a).compareTo(w(b));
            return c != 0 ? c : '${a['name']}'.compareTo('${b['name']}');
          }));
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau ticket')),
      body: !ready
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : ListView(padding: EdgeInsets.fromLTRB(18, 0, 18, 30 + safeBottom(context)), children: [
              const _Step(1, 'Où est le problème ?'),
              if (locations.any((l) => catOf(l) == 'immeuble')) ...[
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'appartement', icon: const Icon(Icons.home_outlined, size: 18), label: Text(tr('Mon appartement'))),
                    ButtonSegment(value: 'immeuble', icon: const Icon(Icons.apartment_rounded, size: 18), label: Text(tr('Immeuble'))),
                  ],
                  selected: {cat},
                  onSelectionChanged: (s) => setState(() { cat = s.first; locationId = null; typeId = null; }),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final l in locations.where((l) => catOf(l) == cat)) ChoiceChip(label: Text('${l['description']}'), selected: locationId == l['id'], selectedColor: kPrimary.withValues(alpha: .15), onSelected: (_) => setState(() { locationId = l['id'] as int; typeId = null; })),
              ]),
              _Step(2, 'Type de problème', active: locationId != null),
              if (locationId == null) Text('Choisissez un lieu pour voir les types.', style: TextStyle(color: mutedOf(context))),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in filtered) ChoiceChip(label: Text('${t['name']}'), selected: typeId == t['id'], selectedColor: kPrimary.withValues(alpha: .15), onSelected: (_) => setState(() => typeId = t['id'] as int)),
              ]),
              const _Step(3, 'Détails du problème'),
              TextField(controller: title, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Titre du problème *'))),
              const SizedBox(height: 12),
              TextField(controller: desc, minLines: 4, maxLines: 8, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Description détaillée'), alignLabelWithHint: true)),
              const FormLabel('Photos'),
              SizedBox(
                height: 92,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  InkWell(onTap: pick, borderRadius: BorderRadius.circular(18), child: Container(width: 92, decoration: BoxDecoration(color: kPrimary.withValues(alpha: .08), borderRadius: BorderRadius.circular(18), border: Border.all(color: kPrimary.withValues(alpha: .35))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: kPrimary), SizedBox(height: 4), Text('Ajouter', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12))]))),
                  for (var i = 0; i < previews.length; i++)
                    Padding(padding: const EdgeInsets.only(left: 10), child: Stack(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(previews[i], width: 92, height: 92, fit: BoxFit.cover)),
                      Positioned(right: 4, top: 4, child: InkWell(onTap: () => setState(() { photos.removeAt(i); previews.removeAt(i); }), child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 15, color: Colors.white)))),
                    ])),
                ]),
              ),
              const SizedBox(height: 28),
              FilledButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Envoyer le ticket')),
            ]),
    );
  }
}


/// Título de passo numerado (1, 2, 3) do novo ticket.
class _Step extends StatelessWidget {
  const _Step(this.n, this.label, {this.active = true});
  final int n;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
        child: Row(children: [
          Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? kPrimary : mutedOf(context).withValues(alpha: .35)), child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
        ]),
      );
}


/// Linha do tempo do pedido: recebido, em análise, técnico planificado, resolvido (a gérance regista cada passo no painel
/// e o locatário recebe um push). Se a tabela ainda não existir, deduz o que pode do estado do ticket.
class TicketTimeline extends StatelessWidget {
  const TicketTimeline({super.key, required this.ticket});
  final Json ticket;

  Future<List<Json>?> load() async {
    try {
      return List<Json>.from(await sb.from('ticket_event').select().eq('ticket_id', ticket['id']).order('created_at'));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Json>?>(
        future: load(),
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) return const SizedBox.shrink();
          final events = (s.data ?? <Json>[]).where((e) => e['ticket_id'] == ticket['id']).toList();
          final known = s.data != null;
          final status = '${ticket['status']}';
          Json? ev(String k) => events.where((e) => e['step'] == k).lastOrNull;
          bool reached(String k) => k == 'recu' || ev(k) != null || (k == 'resolu' && status == 'Fermé') || (!known && k == 'analyse' && status != 'En Attente');
          final steps = [
            ('recu', 'Reçu', Icons.inbox_rounded, ticket['created_at']),
            ('analyse', 'En analyse', Icons.search_rounded, ev('analyse')?['created_at']),
            ('planifie', 'Technicien planifié', Icons.event_available_rounded, ev('planifie')?['created_at']),
          ];
          final lastDone = steps.lastIndexWhere((e) => reached(e.$1));
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Suivi de votre demande', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                for (var i = 0; i < steps.length; i++)
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      SizedBox(
                        width: 34,
                        child: Column(children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: reached(steps[i].$1) ? (i == lastDone ? kPrimary : kGreen) : lineOf(context)),
                            child: Icon(reached(steps[i].$1) ? (i == lastDone ? steps[i].$3 : Icons.check_rounded) : steps[i].$3, size: 17, color: reached(steps[i].$1) ? Colors.white : mutedOf(context)),
                          ),
                          if (i < steps.length - 1) Expanded(child: Container(width: 2, color: reached(steps[i + 1].$1) ? kGreen : lineOf(context))),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(steps[i].$2, style: TextStyle(fontWeight: reached(steps[i].$1) ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: reached(steps[i].$1) ? null : mutedOf(context))),
                            if (reached(steps[i].$1) && steps[i].$4 != null) Text(fmtDateTime(steps[i].$4), style: TextStyle(fontSize: 12, color: mutedOf(context))),
                            if (steps[i].$1 == 'planifie' && ev('planifie')?['planned_at'] != null)
                              Padding(padding: const EdgeInsets.only(top: 3), child: Text('${tr('Passage prévu le')} ${fmtDateTime(ev('planifie')!['planned_at'])}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kPrimary))),
                            if ((ev(steps[i].$1)?['note'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text('${ev(steps[i].$1)!['note']}', style: TextStyle(fontSize: 12.5, color: mutedOf(context)))),
                          ]),
                        ),
                      ),
                    ]),
                  ),
              ]),
            ),
          );
        },
      );
}

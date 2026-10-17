import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import '../api.dart';
import '../ui.dart';
import '../config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tickets.dart';

/// Separador "Messages": conversas recentes dos tickets + acesso à conciergerie.
class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key, required this.me});
  final Me me;
  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  int _k = 0;

  Future<List<Json>> load() async {
    final rows = List<Json>.from(await sb.from('last_ticket_message_view').select().eq('ticket_creator_id', widget.me.uid).order('sent_at', ascending: false).limit(100));
    return rows;
  }

  Future<void> openTicket(Json r) async {
    try {
      final t = await sb.from('tickets').select().eq('id', r['ticket_id']).single();
      if (mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetail(me: widget.me, ticket: t)));
      if (mounted) setState(() => _k++);
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: RefreshIndicator(
          onRefresh: () async => setState(() => _k++),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
            // WhatsApp do serviço de conciergerie (mensagem já pronta com os dados do locatário)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SoftCard(
                onTap: () {
                  final me = widget.me;
                  final msg = "Bonjour, je suis ${me.name}${me.buildingName.isNotEmpty ? ' (${me.buildingName}${me.apartNum.isNotEmpty ? ', app. ${me.apartNum}' : ''})' : ''}. Je souhaiterais faire appel au service de conciergerie.";
                  launchUrl(Uri.parse('${AppConfig.whatsappUrl.split('?').first}?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication);
                },
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: .15), shape: BoxShape.circle), child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('WhatsApp conciergerie', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    const SizedBox(height: 2),
                    Text('Parler au service de conciergerie', style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
                  ])),
                  Icon(Icons.arrow_forward_ios_rounded, size: 15, color: mutedOf(context)),
                ]),
              ),
            ),
            const SectionTitle('Messages récents'),
            Load<List<Json>>(
              key: ValueKey(_k),
              future: load(),
              builder: (c, rows) => rows.isEmpty
                  ? const Padding(padding: EdgeInsets.only(top: 40), child: EmptyState('Aucune conversation pour le moment.\nLes échanges de vos tickets apparaissent ici.', icon: Icons.chat_bubble_outline_rounded))
                  : Column(children: [
                      for (var i = 0; i < rows.length; i++)
                        FadeIn(
                          delay: i * 35,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SoftCard(
                              onTap: () => openTicket(rows[i]),
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                CircleAvatar(radius: 24, backgroundColor: kPrimary.withValues(alpha: .13), child: Text(('${rows[i]['author_name'] ?? '?'}').trim().isEmpty ? '?' : ('${rows[i]['author_name']}').trim()[0].toUpperCase(), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 18))),
                                const SizedBox(width: 13),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [Expanded(child: Text('Ticket #${rows[i]['ticket_id']}', style: const TextStyle(fontWeight: FontWeight.w800))), Text(ago(rows[i]['sent_at']), style: TextStyle(fontSize: 12, color: mutedOf(context)))]),
                                  const SizedBox(height: 3),
                                  Text('${rows[i]['author_name'] ?? ''}: ${rows[i]['message'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: mutedOf(context), fontSize: 13.5, height: 1.3)),
                                  const SizedBox(height: 7),
                                  StatusChip(rows[i]['status']?.toString()),
                                ])),
                              ]),
                            ),
                          ),
                        ),
                    ]),
            ),
          ]),
        ),
      );
}

/// Message au gestionnaire (conversa com o gestor do edifício).
class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({super.key, required this.me});
  final Me me;
  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> {
  final msg = TextEditingController();
  final scroll = ScrollController();
  Json? manager;
  bool loaded = false;
  int _k = 0;

  @override
  void initState() {
    super.initState();
    Api.managerOf(widget.me).then((m) { if (mounted) setState(() { manager = m; loaded = true; }); });
  }

  String get mid => '${manager?['user_id'] ?? widget.me.managerId}';

  Future<List<Json>> load() async {
    final me = widget.me.uid;
    return List<Json>.from(await sb.from('admin_chats').select().or('and(author_id.eq.$me,user_id.eq.$mid),and(author_id.eq.$mid,user_id.eq.$me)').order('sent_at'));
  }

  Future<void> send() async {
    final txt = msg.text.trim();
    if (txt.isEmpty) return;
    msg.clear();
    try {
      await sb.from('admin_chats').insert({'author_id': widget.me.uid, 'user_id': mid, 'message': txt});
      Api.notify([mid], 'Message de ${widget.me.name}', txt);
      Api.email('chat_notification', manager?['email']?.toString(), manager?['manager_name']?.toString(), {'ticketTitle': 'Message de ${widget.me.name}', 'message': txt});
      setState(() => _k++);
      await Future.delayed(const Duration(milliseconds: 250));
      if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return Scaffold(appBar: AppBar(title: const Text('Conciergerie')), body: const Center(child: CircularProgressIndicator(strokeWidth: 3)));
    if (mid.isEmpty || mid == 'null') return Scaffold(appBar: AppBar(title: const Text('Conciergerie')), body: const EmptyState("Aucun gestionnaire n'est associé à votre bâtiment.", icon: Icons.support_agent_rounded));
    final name = '${manager?['manager_name'] ?? 'Gestionnaire'}';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(radius: 19, backgroundColor: kPrimary.withValues(alpha: .13), child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), Text('${manager?['agency_name'] ?? 'Gérance'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mutedOf(context)))])),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: Load<List<Json>>(
            key: ValueKey(_k),
            future: load(),
            builder: (c, rows) => rows.isEmpty
                ? const EmptyState('Écrivez à votre gestionnaire.\nVous recevrez sa réponse ici.', icon: Icons.forum_outlined)
                : ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), children: [for (final m in rows) Bubble(text: '${m['message'] ?? ''}', mine: m['author_id'] == widget.me.uid, meta: fmtDateTime(m['sent_at']))]),
          ),
        ),
        ChatInput(controller: msg, onSend: send, hint: tr('Votre message')),
      ]),
    );
  }
}

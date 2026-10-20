import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../config.dart';
import '../ui.dart';
import 'tickets.dart';
import 'community.dart';
import 'messages.dart';
import 'requests.dart';
import 'buanderie.dart';
import 'assistant.dart';
import 'profile.dart';
import 'discounts.dart';
import '../push.dart';
import '../update.dart';

Future<void> callNumber(String n) => launchUrl(Uri.parse('tel:${n.replaceAll(' ', '')}'));

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.me, required this.onRefresh});
  final Me me;
  final Future<void> Function() onRefresh;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  bool pushOff = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () { if (mounted) AppUpdate.check(context); });
    // depois de o Android mostrar o pedido de permissão, verifica se as notificações ficaram ligadas
    Future.delayed(const Duration(seconds: 6), () async {
      final ok = await Push.granted();
      if (mounted) setState(() => pushOff = !ok);
    });
  }

  void go(int i) {
    // Locataire Connect: abre diretamente o grupo de WhatsApp do edifício (se o gerente o tiver indicado)
    if (i == 2) {
      final g = '${widget.me.building?['whatsapp_group'] ?? ''}'.trim();
      if (g.isNotEmpty) {
        launchUrl(Uri.parse(g), mode: LaunchMode.externalApplication);
        return;
      }
    }
    setState(() => tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(me: widget.me, goTab: go),
      MessagesTab(me: widget.me),
      CommunityTab(me: widget.me),
      const DiscountsTab(),
      ProfileTab(me: widget.me, onRefresh: widget.onRefresh),
    ];
    return Scaffold(
      body: Column(children: [
        if (pushOff)
          Material(
            color: kAmber.withValues(alpha: .15),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: Row(children: [
                  const Icon(Icons.notifications_off_outlined, size: 20, color: kAmber),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Les notifications sont désactivées : vous ne recevrez pas les alertes sur votre téléphone.', style: TextStyle(fontSize: 12.5, height: 1.3))),
                  TextButton(onPressed: () async { await Push.askAgain(); await Future.delayed(const Duration(seconds: 2)); final ok = await Push.granted(); if (mounted) setState(() => pushOff = !ok); }, child: const Text('Activer', style: TextStyle(fontWeight: FontWeight.w800))),
                ]),
              ),
            ),
          ),
        Expanded(child: IndexedStack(index: tab, children: pages)),
      ]),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: go, destinations: [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: tr('Accueil')),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: tr('Messages')),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: tr('Annonces')),
        NavigationDestination(icon: Icon(Icons.local_offer_outlined), selectedIcon: Icon(Icons.local_offer_rounded), label: tr('Réductions')),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: tr('Profil')),
      ]),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.me, required this.goTab});
  final Me me;
  final void Function(int) goTab;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _k = 0;

  Future<Map<String, dynamic>> load() async {
    final me = widget.me;
    final notifs = List<Json>.from(await sb.from('Notification New').select().eq('userid', me.uid).order('created_at', ascending: false).limit(30)).where((n) => n['Tittle'] != 'DIAG-PUSH').toList();
    final tickets = List<Json>.from(await sb.from('tickets').select('id,status').eq('tenant_id', me.uid));
    final manager = await Api.managerOf(me);
    var posts = <Json>[];
    if (me.buildingId != null) {
      posts = List<Json>.from(await sb.from('announcements').select().eq('apartamentID', me.buildingId!).order('created_at', ascending: false).limit(3));
    }
    // dias e horas em que a equipa está no edifício (definidos no painel); se a tabela ainda não existir, não mostra nada
    var presence = <Json>[];
    if (me.buildingId != null) {
      try {
        final rows = List<Json>.from(await sb.from('batiment_presence').select().eq('batiment_id', me.buildingId!).order('jour').order('debut'));
        presence = rows.where((r) => r['batiment_id'] == me.buildingId).toList();
      } catch (_) {}
    }
    return {'notifs': notifs, 'tickets': tickets, 'manager': manager, 'posts': posts, 'presence': presence};
  }

  void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w)).then((_) => setState(() => _k++));

  Widget tile(IconData i, Color c, String t, String s, VoidCallback f, {String? badge}) {
    Widget badgeW() => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)), child: Text(badge!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)));
    if (kDesign == 'b') {
      // Esmeralda: linhas largas, uma por atalho
      return SoftCard(
        onTap: f,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          IconBadge(i, color: c, size: 50),
          const SizedBox(width: 14),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            const SizedBox(height: 2),
            Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
          ])),
          if (badge != null) ...[badgeW(), const SizedBox(width: 8)],
          Icon(Icons.chevron_right_rounded, color: mutedOf(context)),
        ]),
      );
    }
    if (kDesign == 'c') {
      // Marinho & ouro: filete dourado em cima, ícone em círculo contornado
      return SoftCard(
        onTap: f,
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 3, decoration: BoxDecoration(color: kViolet, borderRadius: BorderRadius.vertical(top: Radius.circular(kCard)))),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kViolet, width: 1.4)), child: Icon(i, color: kPrimary, size: 22)),
                const Spacer(),
                if (badge != null) badgeW(),
              ]),
              const Spacer(),
              Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.2)),
              const SizedBox(height: 3),
              Text(s, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.25, color: mutedOf(context))),
            ]),
          )),
        ]),
      );
    }
    return SoftCard(
      onTap: f,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [IconBadge(i, color: c), const Spacer(), if (badge != null) badgeW()]),
        const Spacer(),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.2)),
        const SizedBox(height: 3),
        Text(s, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.25, color: mutedOf(context))),
      ]),
    );
  }

  Widget emergency(String label, String number, Color color, IconData icon) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => callNumber(number),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(18)),
            child: Column(children: [Icon(icon, color: color), const SizedBox(height: 6), Text(number, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)), Text(label, style: TextStyle(fontSize: 12, color: mutedOf(context)))]),
          ),
        ),
      );

  /// Dias e horas em que a equipa AM Clean Care está no edifício (definidos no painel pelo admin), por baixo do concierge virtual.
  Widget presenceCard(List<Json> rows, Json? manager) {
    if (rows.isEmpty) return const SizedBox.shrink();
    // contacto da equipa definido pela gérance (admin); se vazio usa o da AM Clean Care
    final tp = '${manager?['team_phone'] ?? ''}'.trim(), tw = '${manager?['team_whatsapp'] ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = tp.isNotEmpty ? tp : AppConfig.phoneConcierge;
    final waUrl = tw.isNotEmpty ? 'https://wa.me/$tw' : AppConfig.whatsappUrl;
    // dias por período (a gérance escolhe « matin » ou « après-midi » para cada dia) : "Lun · Mer · après-midi"
    final am = <int>{}, pm = <int>{};
    for (final r in rows) {
      final h = int.tryParse('${r['debut']}'.substring(0, 2)) ?? 14;
      ((h < 12) ? am : pm).add((r['jour'] as num).toInt());
    }
    String line(Set<int> d, String per) => '${(d.toList()..sort()).map(dayName).join(' · ')} — ${tr(per)}';
    final lines = [if (am.isNotEmpty) line(am, 'matin'), if (pm.isNotEmpty) line(pm, 'après-midi')];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(color: kTeal.withValues(alpha: isDark(context) ? .14 : .08), borderRadius: BorderRadius.circular(16), border: Border.all(color: kTeal.withValues(alpha: .3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Icon(Icons.cleaning_services_rounded, size: 20, color: kTeal),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Nous sommes présents dans l'immeuble", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            const SizedBox(height: 3),
            for (final l in lines) Text(l, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ])),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => callNumber(phone),
            icon: const Icon(Icons.call_rounded, color: kGreen),
            tooltip: 'Appeler',
          ),
          if (waUrl.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              tooltip: 'WhatsApp',
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final first = me.name.trim().isEmpty ? '' : me.name.trim().split(' ').first;
    final buildingPhoto = '${me.building?['imgBatiment'] ?? ''}'.trim();
    return Load<Map<String, dynamic>>(
      key: ValueKey(_k),
      future: load(),
      builder: (c, d) {
        final notifs = d['notifs'] as List<Json>, tickets = d['tickets'] as List<Json>, posts = d['posts'] as List<Json>;
        final manager = d['manager'] as Json?;
        final unread = notifs.where((n) => n['Read'] == 'Unread').length;
        final nOpen = tickets.where((t) => t['status'] == 'En Cours').length, nWait = tickets.where((t) => t['status'] == 'En Attente').length;
        final gerancePhone = AppConfig.phoneGerance.isNotEmpty ? AppConfig.phoneGerance : '${manager?['phone'] ?? ''}';
        return RefreshIndicator(
          onRefresh: () async => setState(() => _k++),
          child: ListView(padding: EdgeInsets.zero, children: [
            // ---- cabeçalho com gradiente ----
            Stack(clipBehavior: Clip.none, children: [
              Padding(padding: const EdgeInsets.only(bottom: 62), child: Container(
                padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 14, 22, 92),
                decoration: BoxDecoration(image: buildingPhoto.isEmpty ? null : DecorationImage(image: NetworkImage(buildingPhoto), fit: BoxFit.cover, opacity: .2), gradient: kDesign == 'b' ? const LinearGradient(colors: [Color(0xFFD9F3EA), Color(0xFFBDE8DA)], begin: Alignment.topLeft, end: Alignment.bottomRight) : kHeroGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(kDesign == 'c' ? 26 : 40)), border: kDesign == 'c' ? Border(bottom: BorderSide(color: kViolet, width: 3)) : null),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LangButton(light: kDesign != 'b'),
                const SizedBox(height: 12),
                Row(children: [
                  Brand(size: 46, light: kDesign != 'b', logoUrl: ((d['manager'] as Json?)?['agency_img'] ?? '').toString()),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(first.isEmpty ? '${tr('Bonjour')} 👋' : '${tr('Bonjour')}, $first 👋', style: TextStyle(color: kDesign == 'b' ? const Color(0xFF0B3D33) : Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(me.buildingName.isEmpty ? AppConfig.appName : '${me.buildingName} · app. ${me.apartNum}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: (kDesign == 'b' ? const Color(0xFF0B3D33) : Colors.white).withValues(alpha: .85), fontSize: 13)),
                  ])),
                  Stack(clipBehavior: Clip.none, children: [
                    IconButton.filled(style: IconButton.styleFrom(backgroundColor: (kDesign == 'b' ? const Color(0xFF0E9F7E) : Colors.white).withValues(alpha: .2)), onPressed: () => open(NotificationsScreen(me: me)), icon: Icon(Icons.notifications_none_rounded, color: kDesign == 'b' ? const Color(0xFF0B3D33) : Colors.white)),
                    if (unread > 0) Positioned(right: 2, top: 2, child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle), child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
                  ]),
                ]),
                ]),
              )),
              // ---- cartão do concierge virtual ----
              Positioned(
                left: 18, right: 18, bottom: 0,
                child: SoftCard(
                  onTap: () => open(AssistantScreen(me: me)),
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Stack(children: [
                      Container(width: 54, height: 54, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: Padding(padding: const EdgeInsets.all(4), child: Image.asset('assets/logo_empresa.png', fit: BoxFit.contain))),
                      Positioned(right: 0, bottom: 0, child: Container(width: 15, height: 15, decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardTheme.color!, width: 2.5)))),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Flexible(child: Text('Concierge virtuel', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), const SizedBox(width: 8), Text('En ligne', style: TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 12))]),
                      const SizedBox(height: 3),
                      Text('Posez votre question, je parle votre langue.', style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ]),
                ),
              ),
            ]),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: presenceCard(d['presence'] as List<Json>, d['manager'] as Json?)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Que souhaitez-vous faire ?'),
                FadeIn(
                  child: GridView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: kDesign == 'b' ? 1 : 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: kDesign == 'b' ? 78 : 160), children: [
                    tile(Icons.add_circle_outline_rounded, kPrimary, 'Ouvrir un ticket', 'Vous avez des problèmes ?', () async { await openNewTicket(context, me); if (mounted) setState(() => _k++); }),
                    tile(Icons.confirmation_number_outlined, kBlue, 'Tickets ouverts', nOpen + nWait == 0 ? 'Aucun ticket en cours' : '$nOpen ${tr('en cours')} · $nWait ${tr('en attente')}', () => open(TicketsScreen(me: me)), badge: nOpen + nWait > 0 ? '${nOpen + nWait}' : null),
                    tile(Icons.support_agent_rounded, kTeal, 'Conciergerie', 'Parler avec le Service de Conciergerie', () {
                      // abre o WhatsApp da conciergerie, com uma mensagem já pronta com os dados do locatário
                      final msg = "Bonjour, je suis ${me.name}${me.buildingName.isNotEmpty ? ' (${me.buildingName}${me.apartNum.isNotEmpty ? ', app. ${me.apartNum}' : ''})' : ''}. Je souhaiterais faire appel au service de conciergerie.";
                      launchUrl(Uri.parse('${AppConfig.whatsappUrl.split('?').first}?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication);
                    }),
                    tile(Icons.local_laundry_service_outlined, kAmber, 'Buanderie', 'Planning de la buanderie ou signaler un problème', () => open(BuanderieScreen(me: me))),
                    tile(Icons.inventory_2_outlined, kRed, 'Colis volé ?', 'Nous sommes là pour vous aider', () => open(RequestScreen(me: me, kind: RequestKind.camera))),
                    tile(Icons.spa_outlined, kGreen, 'Règles de bien-être', "Vivre ensemble dans l'immeuble", () => open(const RulesScreen())),
                  ]),
                ),
                SectionTitle('Notifications récentes', action: notifs.isEmpty ? null : 'Tout voir', onAction: () => open(NotificationsScreen(me: me))),
                if (notifs.isEmpty)
                  SoftCard(child: Row(children: [const IconBadge(Icons.notifications_none_rounded, size: 40), const SizedBox(width: 14), Expanded(child: Text('Aucune notification pour le moment.', style: TextStyle(color: mutedOf(context))))]))
                else
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(children: [
                      for (var i = 0; i < notifs.take(3).length; i++) ...[
                        if (i > 0) const Divider(indent: 70),
                        ListTile(
                          leading: IconBadge(notifs[i]['Read'] == 'Unread' ? Icons.mark_email_unread_outlined : Icons.notifications_none_rounded, color: notifs[i]['Read'] == 'Unread' ? kPrimary : kBlue, size: 42),
                          title: Text('${notifs[i]['Tittle'] ?? ''}', style: TextStyle(fontWeight: notifs[i]['Read'] == 'Unread' ? FontWeight.w800 : FontWeight.w600, fontSize: 14.5)),
                          subtitle: Text('${notifs[i]['Description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Text(ago(notifs[i]['created_at']), style: TextStyle(fontSize: 12, color: mutedOf(context))),
                          onTap: () => open(NotificationsScreen(me: me)),
                        ),
                      ],
                    ]),
                  ),
                const SectionTitle("Numéros d'urgence"),
                SoftCard(
                  child: Column(children: [
                    Row(children: [
                      emergency('Police', '117', kBlue, Icons.local_police_outlined), const SizedBox(width: 10),
                      emergency('Ambulance', '144', kRed, Icons.medical_services_outlined), const SizedBox(width: 10),
                      emergency('Pompiers', '118', kAmber, Icons.local_fire_department_outlined),
                    ]),
                    const SizedBox(height: 12),
                    ListTile(contentPadding: EdgeInsets.zero, leading: const IconBadge(Icons.support_agent_rounded, color: kTeal, size: 42), title: const Text('Concierge', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(AppConfig.phoneConcierge), trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(onPressed: () => callNumber(AppConfig.phoneConcierge), icon: const Icon(Icons.call_rounded, color: kGreen)),
                      if (AppConfig.whatsappUrl.isNotEmpty) IconButton(onPressed: () => launchUrl(Uri.parse(AppConfig.whatsappUrl), mode: LaunchMode.externalApplication), icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366))),
                    ])),
                    if (gerancePhone.isNotEmpty) ListTile(contentPadding: EdgeInsets.zero, leading: const IconBadge(Icons.business_rounded, color: kPrimary, size: 42), title: const Text('Gérance', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(gerancePhone), trailing: IconButton(onPressed: () => callNumber(gerancePhone), icon: const Icon(Icons.call_rounded, color: kGreen))),
                  ]),
                ),
                SectionTitle('Quoi de neuf dans le bâtiment ?', action: 'Voir', onAction: () => widget.goTab(2)),
                if (posts.isEmpty)
                  SoftCard(onTap: () => widget.goTab(2), child: Row(children: [const IconBadge(Icons.groups_outlined, color: kGreen, size: 40), const SizedBox(width: 14), Expanded(child: Text('Soyez le premier à publier une annonce.', style: TextStyle(color: mutedOf(context))))]))
                else
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(children: [
                      for (var i = 0; i < posts.length; i++) ...[
                        if (i > 0) const Divider(indent: 70),
                        ListTile(onTap: () => widget.goTab(2), leading: IconBadge(posts[i]['free'] == true ? Icons.card_giftcard_rounded : Icons.sell_outlined, color: posts[i]['free'] == true ? kGreen : kPrimary, size: 42), title: Text('${posts[i]['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), subtitle: Text(posts[i]['free'] == true ? 'Gratuit' : 'CHF ${posts[i]['price'] ?? ''}')),
                      ],
                    ]),
                  ),
                const SizedBox(height: 30),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

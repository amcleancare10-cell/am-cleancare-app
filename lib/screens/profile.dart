import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../config.dart';
import '../rules.dart';
import '../push.dart';
import '../ui.dart';

/// Profil: informations personnelles, paramètres du compte, règles, notifications.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.me, required this.onRefresh});
  final Me me;
  final Future<void> Function() onRefresh;
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _k = 0;

  Future<Json?> loadTenant() async => await sb.from('tenants').select('created_at').eq('user_id', widget.me.uid).maybeSingle();

  Future<void> deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const IconBadge(Icons.warning_amber_rounded, color: kRed, size: 62),
        title: const Text('Supprimer mon compte'),
        content: const Text('Vous êtes sur le point de supprimer votre compte, êtes-vous sûr de votre choix ?\n\nLa suppression de votre compte est irréversible. Toutes vos données seront définitivement perdues.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(style: FilledButton.styleFrom(backgroundColor: kRed, minimumSize: const Size(0, 46)), onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer'))],
      ),
    );
    if (ok != true) return;
    try {
      await sb.rpc('delete_user_all_data_by_user_id', params: {'p_user_id': widget.me.uid});
      await sb.auth.signOut();
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    }
  }

  Widget row(IconData i, String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [Icon(i, size: 21, color: mutedOf(context)), const SizedBox(width: 14), Text(l, style: TextStyle(color: mutedOf(context))), const SizedBox(width: 12), Expanded(child: Text(v.isEmpty ? '—' : v, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)))]));

  Widget action(IconData i, String t, VoidCallback f, {Color? color, String? subtitle}) => ListTile(
        leading: IconBadge(i, color: color ?? kPrimary, size: 42),
        title: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: f,
      );

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final initial = me.name.trim().isEmpty ? '?' : me.name.trim()[0].toUpperCase();
    final last = sb.auth.currentUser?.lastSignInAt;
    return Load<Json?>(
      key: ValueKey(_k),
      future: loadTenant(),
      builder: (c, tenant) => ListView(padding: EdgeInsets.zero, children: [
        Container(
          padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 22, 22, 28),
          decoration: const BoxDecoration(gradient: kHeroGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(40))),
          child: Column(children: [
            CircleAvatar(radius: 42, backgroundColor: Colors.white.withValues(alpha: .22), child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800))),
            const SizedBox(height: 14),
            Text(me.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(me.email, style: TextStyle(color: Colors.white.withValues(alpha: .85))),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(99)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF6CE9A6), shape: BoxShape.circle)), const SizedBox(width: 8), Text(me.approved ? 'Compte actif' : 'En attente', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('Informations personnelles'),
            SoftCard(child: Column(children: [
              row(Icons.person_outline_rounded, 'Nom complet', me.name),
              row(Icons.mail_outline_rounded, 'Email', me.email),
              row(Icons.phone_outlined, 'Téléphone', me.phone),
              row(Icons.location_on_outlined, 'Adresse', '${me.building?['address'] ?? ''}${me.apartNum.isNotEmpty ? ' · app. ${me.apartNum}' : ''}'),
            ])),
            const SectionTitle('Paramètres du compte'),
            SoftCard(child: Column(children: [
              row(Icons.event_available_outlined, 'Membre depuis', tenant?['created_at'] == null ? '' : fmtDate(tenant!['created_at'])),
              row(Icons.login_rounded, 'Dernière connexion', last == null ? '' : fmtDateTime(last)),
              row(Icons.verified_user_outlined, 'Statut du compte', me.approved ? 'Actif' : me.status),
            ])),
            const SizedBox(height: 14),
            OutlinedButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(me: me))); await widget.onRefresh(); if (mounted) setState(() => _k++); }, icon: const Icon(Icons.edit_outlined), label: const Text('Modifier mes informations')),
            const SectionTitle('Plus'),
            SoftCard(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: [
              action(Icons.notifications_none_rounded, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(me: me)))),
              action(Icons.notifications_active_outlined, 'Tester les notifications du téléphone', () async {
                await Push.login(me.uid);
                await Future.delayed(const Duration(seconds: 3));
                final st = await Push.status(me.uid);
                if (context.mounted) showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Notifications du téléphone'), content: SelectableText(st), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fermer'))]));
              }),
              const Divider(indent: 70),
              action(Icons.spa_outlined, 'Règles de bien-être', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesScreen())), color: kTeal),
              const Divider(indent: 70),
              action(Icons.lock_reset_rounded, 'Changer le mot de passe', () async { try { await sb.auth.resetPasswordForEmail(me.email); if (context.mounted) toast(context, 'E-mail de réinitialisation envoyé.'); } catch (e) { if (context.mounted) toast(context, Api.fmtErr(e), error: true); } }, color: kBlue),
            ])),
            const SizedBox(height: 16),
            FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF344054), foregroundColor: Colors.white), onPressed: () => sb.auth.signOut(), icon: const Icon(Icons.logout_rounded), label: const Text('Se déconnecter')),
            const SizedBox(height: 6),
            Center(child: TextButton.icon(onPressed: deleteAccount, style: TextButton.styleFrom(foregroundColor: kRed), icon: const Icon(Icons.delete_forever_outlined), label: const Text('Supprimer mon compte'))),
            Center(child: Text(AppConfig.appName, style: TextStyle(color: mutedOf(context), fontSize: 12))),
          ]),
        ),
      ]),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.me});
  final Me me;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final name = TextEditingController(text: widget.me.name), phone = TextEditingController(text: widget.me.phone), apart = TextEditingController(text: widget.me.apartNum), floor = TextEditingController(text: '${widget.me.floor ?? ''}');
  bool busy = false;

  Future<void> save() async {
    if (name.text.trim().isEmpty) { toast(context, 'Le nom est obligatoire.', error: true); return; }
    setState(() => busy = true);
    try {
      await sb.from('tenants').update({'full_name': name.text.trim(), 'phone': phone.text.trim(), 'apartNum': apart.text.trim(), 'floor': int.tryParse(floor.text.trim())}).eq('user_id', widget.me.uid);
      if (mounted) { toast(context, 'Informations mises à jour.'); Navigator.pop(context); }
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Modifier mes informations')),
        body: ListView(padding: EdgeInsets.fromLTRB(18, 8, 18, 30 + safeBottom(context)), children: [
          TextField(controller: name, decoration: InputDecoration(labelText: tr('Nom complet'), prefixIcon: Icon(Icons.person_outline_rounded))),
          const SizedBox(height: 14),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: tr('Téléphone'), prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: TextField(controller: apart, decoration: InputDecoration(labelText: tr("N° d'appartement")))), const SizedBox(width: 12), Expanded(child: TextField(controller: floor, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('Étage'))))]),
          const SizedBox(height: 28),
          FilledButton(onPressed: busy ? null : save, child: busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Enregistrer')),
        ]),
      );
}

/* ----------------------------- Notifications ----------------------------- */
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.me});
  final Me me;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _k = 0;
  Future<List<Json>> load() async => List<Json>.from(await sb.from('Notification New').select().eq('userid', widget.me.uid).order('created_at', ascending: false).limit(100));

  Future<void> markAll(List<Json> rows) async {
    final ids = rows.where((n) => n['Read'] == 'Unread').map((n) => n['id']).toList();
    if (ids.isEmpty) return;
    await sb.from('Notification New').update({'Read': 'Read'}).inFilter('id', ids);
    if (mounted) setState(() => _k++);
  }

  @override
  Widget build(BuildContext context) => Load<List<Json>>(
        key: ValueKey(_k),
        future: load(),
        builder: (c, rows) => Scaffold(
          appBar: AppBar(title: const Text('Notifications'), actions: [if (rows.any((n) => n['Read'] == 'Unread')) TextButton(onPressed: () => markAll(rows), child: const Text('Tout lire'))]),
          body: rows.isEmpty
              ? const EmptyState('Aucune notification.', icon: Icons.notifications_none_rounded)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (c, i) {
                    final n = rows[i];
                    final unread = n['Read'] == 'Unread';
                    return FadeIn(
                      delay: i * 30,
                      child: SoftCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () async { if (unread) { await sb.from('Notification New').update({'Read': 'Read'}).eq('id', n['id']); if (mounted) setState(() => _k++); } },
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          IconBadge(unread ? Icons.mark_email_unread_outlined : Icons.drafts_outlined, color: unread ? kPrimary : kBlue, size: 44),
                          const SizedBox(width: 13),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [Expanded(child: Text('${n['Tittle'] ?? ''}', style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600))), Text(ago(n['created_at']), style: TextStyle(fontSize: 12, color: mutedOf(context)))]),
                            const SizedBox(height: 3),
                            Text('${n['Description'] ?? ''}', style: TextStyle(color: mutedOf(context), height: 1.35)),
                          ])),
                          if (unread) Container(margin: const EdgeInsets.only(left: 8, top: 6), width: 10, height: 10, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      );
}

/* ----------------------------- Règles de bien-être ----------------------------- */
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  Widget phone(BuildContext c, String label, String number, IconData i, Color col) => number.isEmpty
      ? const SizedBox.shrink()
      : ListTile(leading: IconBadge(i, color: col, size: 40), title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(number), trailing: const Icon(Icons.call_rounded, color: kGreen), onTap: () => launchUrl(Uri.parse('tel:${number.replaceAll(' ', '')}')));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Règles de bien-être')),
        body: ListView(padding: EdgeInsets.fromLTRB(16, 0, 16, 30 + safeBottom(context)), children: [
          SoftCard(gradient: kHeroGradient, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bienvenue dans notre immeuble', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(wellbeingIntro, style: TextStyle(color: Colors.white.withValues(alpha: .9), height: 1.4)),
          ])),
          const SizedBox(height: 14),
          for (final s in wellbeingSections)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  shape: const Border(), collapsedShape: const Border(),
                  title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final it in s.items) Padding(padding: const EdgeInsets.only(bottom: 11), child: Text(it, style: const TextStyle(height: 1.45)))],
                ),
              ),
            ),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: [
              const ListTile(title: Text('Contacts importants', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              phone(context, 'Concierge', AppConfig.phoneConcierge, Icons.support_agent_rounded, kTeal),
              phone(context, 'Gérance', AppConfig.phoneGerance, Icons.business_rounded, kPrimary),
              phone(context, 'Urgences', '112', Icons.emergency_rounded, kRed),
              phone(context, 'Police', '117', Icons.local_police_outlined, kBlue),
              phone(context, 'Pompiers', '118', Icons.local_fire_department_outlined, kAmber),
              phone(context, 'Ambulance', '144', Icons.medical_services_outlined, kRed),
            ]),
          ),
          const SizedBox(height: 12),
          Text(wellbeingOutro, style: TextStyle(color: mutedOf(context), height: 1.45)),
        ]),
      );
}

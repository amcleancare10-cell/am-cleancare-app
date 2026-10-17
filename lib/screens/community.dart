import 'dart:typed_data';
import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../config.dart';
import '../ui.dart';

/// Locataire Connect: "Quoi de neuf dans le bâtiment ?"
class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key, required this.me});
  final Me me;
  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  bool onlyMine = false;
  int _k = 0;

  Future<Map<String, dynamic>> load() async {
    final me = widget.me;
    if (me.buildingId == null) return {'posts': <Json>[], 'likes': <Json>[], 'comments': <Json>[]};
    var q = sb.from('announcements').select().eq('apartamentID', me.buildingId!);
    if (onlyMine) q = q.eq('tenantID', me.uid);
    final posts = List<Json>.from(await q.order('created_at', ascending: false).limit(100));
    final ids = posts.map((p) => p['id']).toList();
    var likes = <Json>[], comments = <Json>[];
    if (ids.isNotEmpty) {
      likes = List<Json>.from(await sb.from('announcements_likes').select('announcementsID,user_ID').inFilter('announcementsID', ids));
      comments = List<Json>.from(await sb.from('announcements_chat').select('announcementsID').inFilter('announcementsID', ids));
    }
    return {'posts': posts, 'likes': likes, 'comments': comments};
  }

  Future<void> like(Json p) async {
    try {
      await sb.rpc('toggle_announcement_like', params: {'p_announcement_id': p['id'], 'p_user_id': widget.me.uid});
      setState(() => _k++);
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    }
  }

  Future<void> remove(Json p) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Supprimer la publication'), content: const Text('Êtes-vous sûr de vouloir supprimer cette publication ?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(style: FilledButton.styleFrom(backgroundColor: kRed, minimumSize: const Size(0, 44)), onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer'))]));
    if (ok != true) return;
    try {
      await sb.rpc('delete_announcement', params: {'p_announcement_id': p['id']});
    } catch (_) {
      await sb.from('announcements').delete().eq('id', p['id']);
    }
    if (mounted) setState(() => _k++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Locataire Connect')),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kPrimary, foregroundColor: Colors.white,
          onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => NewPostScreen(me: widget.me))); setState(() => _k++); },
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Publier', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: Column(children: [
          if ('${widget.me.building?['whatsapp_group'] ?? ''}'.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: SoftCard(
                onTap: () => launchUrl(Uri.parse('${widget.me.building!['whatsapp_group']}'.trim()), mode: LaunchMode.externalApplication),
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const IconBadge(Icons.chat_rounded, color: Color(0xFF1FAF54), size: 46),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Groupe WhatsApp de l'immeuble", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    const SizedBox(height: 2),
                    Text('Discutez avec vos voisins', style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
                  ])),
                  FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FAF54), minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 16)), onPressed: () => launchUrl(Uri.parse('${widget.me.building!['whatsapp_group']}'.trim()), mode: LaunchMode.externalApplication), child: const Text('Rejoindre')),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
            child: Row(children: [
              Expanded(child: Text('Quoi de neuf dans le bâtiment ?', style: TextStyle(color: mutedOf(context), fontWeight: FontWeight.w600))),
              ChoiceChip(label: const Text('Mes publications'), selected: onlyMine, selectedColor: kPrimary.withValues(alpha: .15), onSelected: (v) => setState(() { onlyMine = v; _k++; })),
            ]),
          ),
          Expanded(
            child: Load<Map<String, dynamic>>(
              key: ValueKey(_k),
              future: load(),
              builder: (c, d) {
                final posts = d['posts'] as List<Json>, likes = d['likes'] as List<Json>, comments = d['comments'] as List<Json>;
                if (posts.isEmpty) return EmptyState(onlyMine ? "Vous n'avez encore rien publié." : "Aucune annonce pour l'instant.\nPubliez la première !", icon: Icons.groups_outlined, action: 'Créer une annonce', onAction: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => NewPostScreen(me: widget.me))); setState(() => _k++); });
                return RefreshIndicator(
                  onRefresh: () async => setState(() => _k++),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (c, i) {
                      final p = posts[i];
                      final nl = likes.where((l) => l['announcementsID'] == p['id']).toList();
                      final liked = nl.any((l) => l['user_ID'] == widget.me.uid);
                      final nc = comments.where((x) => x['announcementsID'] == p['id']).length;
                      final photos = (p['photo'] is List) ? List<String>.from((p['photo'] as List).map((e) => e.toString())) : (p['photo'] is String && (p['photo'] as String).isNotEmpty ? [p['photo'] as String] : <String>[]);
                      final free = p['free'] == true;
                      return FadeIn(
                        delay: i * 40,
                        child: SoftCard(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (photos.isNotEmpty)
                                Stack(children: [
                                  Image.network(photos.first, height: 210, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(height: 120, color: Colors.black12, child: const Center(child: Icon(Icons.image_not_supported_outlined)))),
                                  Positioned(left: 12, top: 12, child: _price(free, p['price'])),
                                ]),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [if (photos.isEmpty) _price(free, p['price']), const Spacer(), Text(ago(p['created_at']), style: TextStyle(fontSize: 12, color: mutedOf(context)))]),
                                  const SizedBox(height: 10),
                                  Text('${p['description'] ?? ''}', style: const TextStyle(height: 1.4, fontSize: 15)),
                                  if ((p['contact'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: _ContactButton(post: p)),
                                ]),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                child: Row(children: [
                                  TextButton.icon(onPressed: () => like(p), icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? kRed : null), label: Text('${nl.length}')),
                                  TextButton.icon(onPressed: () async { await Navigator.push(c, MaterialPageRoute(builder: (_) => CommentsScreen(me: widget.me, post: p))); setState(() => _k++); }, icon: const Icon(Icons.chat_bubble_outline_rounded), label: Text('$nc')),
                                  TextButton.icon(onPressed: () => SharePlus.instance.share(ShareParams(text: '${p['description'] ?? ''}${free ? '' : ' · CHF ${p['price']}'}\n— ${AppConfig.appName}')), icon: const Icon(Icons.ios_share_rounded), label: const Text('Partager')),
                                  const Spacer(),
                                  if (p['tenantID'] == widget.me.uid) IconButton(tooltip: 'Supprimer', icon: const Icon(Icons.delete_outline_rounded), onPressed: () => remove(p)),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      );

  Widget _price(bool free, dynamic price) {
    final c = free ? kGreen : kPrimary;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: free ? kGreen : kPrimary, borderRadius: BorderRadius.circular(99)), child: Text(free ? 'Gratuit' : 'CHF $price', style: TextStyle(color: c == kGreen || c == kPrimary ? Colors.white : null, fontWeight: FontWeight.w800, fontSize: 13)));
  }
}

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key, required this.me});
  final Me me;
  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final desc = TextEditingController(), price = TextEditingController(), contact = TextEditingController();
  bool free = false, busy = false;
  final List<XFile> photos = [];
  final List<Uint8List> previews = [];

  @override
  void initState() {
    super.initState();
    contact.text = widget.me.phone.isNotEmpty ? widget.me.phone : widget.me.email;
  }

  Future<void> submit() async {
    if (desc.text.trim().isEmpty) { toast(context, 'Décrivez votre annonce.', error: true); return; }
    if (!free && double.tryParse(price.text.replaceAll(',', '.')) == null) { toast(context, 'Indiquez un prix ou cochez « Gratuit ».', error: true); return; }
    setState(() => busy = true);
    try {
      final urls = await Api.uploadImages(AppConfig.bucketAnnonce, photos);
      await sb.from('announcements').insert({'apartamentID': widget.me.buildingId, 'tenantID': widget.me.uid, 'description': desc.text.trim(), 'free': free, 'price': free ? 0 : double.parse(price.text.replaceAll(',', '.')), 'contact': contact.text.trim(), 'photo': urls});
      // Avisa os vizinhos aceites do mesmo edifício (como na app original)
      try {
        List<String> ids;
        try {
          ids = List<String>.from(await sb.rpc('my_neighbors') as List);
        } catch (_) {
          final ts = List<Json>.from(await sb.from('tenants').select('user_id').eq('apartment_id', widget.me.buildingId!).eq('statusAproved', 'Accepté'));
          ids = ts.map((t) => '${t['user_id']}').toList();
        }
        final txt = desc.text.trim();
        await Api.notify(ids.where((u) => u != widget.me.uid), 'Nouvelle publication', txt.length > 80 ? '${txt.substring(0, 80)}…' : txt, type: 'All');
      } catch (_) {}
      if (mounted) { toast(context, 'Annonce publiée.'); Navigator.pop(context); }
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Créer une annonce')),
        body: ListView(padding: EdgeInsets.fromLTRB(18, 0, 18, 30 + safeBottom(context)), children: [
          const FormLabel('Informations de base'),
          TextField(controller: desc, minLines: 4, maxLines: 8, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Description *'), alignLabelWithHint: true)),
          const FormLabel('Photos'),
          SizedBox(
            height: 92,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async { final r = await ImagePicker().pickMultiImage(imageQuality: 80, limit: 5); for (final x in r) { photos.add(x); previews.add(await x.readAsBytes()); } if (mounted) setState(() {}); },
                child: Container(width: 92, decoration: BoxDecoration(color: kPrimary.withValues(alpha: .08), borderRadius: BorderRadius.circular(18), border: Border.all(color: kPrimary.withValues(alpha: .35))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: kPrimary), SizedBox(height: 4), Text('Ajouter', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12))])),
              ),
              for (var i = 0; i < previews.length; i++)
                Padding(padding: const EdgeInsets.only(left: 10), child: Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(previews[i], width: 92, height: 92, fit: BoxFit.cover)),
                  Positioned(right: 4, top: 4, child: InkWell(onTap: () => setState(() { photos.removeAt(i); previews.removeAt(i); }), child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 15, color: Colors.white)))),
                ])),
            ]),
          ),
          const FormLabel('Prix'),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(children: [
              SwitchListTile(contentPadding: EdgeInsets.zero, value: free, onChanged: (v) => setState(() => free = v), title: const Text('Gratuit', style: TextStyle(fontWeight: FontWeight.w700))),
              if (!free) TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr('Prix (CHF)'), prefixIcon: Icon(Icons.sell_outlined))),
            ]),
          ),
          const FormLabel('Contact'),
          TextField(controller: contact, decoration: InputDecoration(labelText: tr('Téléphone ou e-mail'), prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 28),
          FilledButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text("Publier l'annonce")),
        ]),
      );
}

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.me, required this.post});
  final Me me;
  final Json post;
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final msg = TextEditingController();
  int _k = 0;

  Future<List<Json>> load() async => List<Json>.from(await sb.from('announcements_chat').select().eq('announcementsID', widget.post['id']).order('sent_at'));

  Future<void> send() async {
    final t = msg.text.trim();
    if (t.isEmpty) return;
    msg.clear();
    try {
      await sb.from('announcements_chat').insert({'announcementsID': widget.post['id'], 'author_ID': widget.me.uid, 'author_name': widget.me.name, 'message': t});
      setState(() => _k++);
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Commentaires')),
        body: Column(children: [
          Expanded(
            child: Load<List<Json>>(
              key: ValueKey(_k),
              future: load(),
              builder: (c, rows) => rows.isEmpty
                  ? const EmptyState('Aucun commentaire. Soyez le premier !', icon: Icons.chat_bubble_outline_rounded)
                  : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 10), children: [for (final r in rows) Bubble(text: '${r['message'] ?? ''}', mine: r['author_ID'] == widget.me.uid, meta: '${r['author_name'] ?? ''} · ${ago(r['sent_at'])}')]),
            ),
          ),
          ChatInput(controller: msg, onSend: send, hint: tr('Votre commentaire')),
        ]),
      );
}


/// Contacto do anúncio: se for um telemóvel abre direto o WhatsApp com uma mensagem pronta; se for e-mail abre o correio.
class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.post});
  final Json post;

  static String? whatsappNumber(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.contains('@') || d.replaceAll('+', '').length < 8) return null;
    if (d.startsWith('+')) {
      d = d.substring(1);
    } else if (d.startsWith('00')) {
      d = d.substring(2);
    } else if (d.startsWith('0')) {
      d = '41${d.substring(1)}'; // número suíço sem indicativo
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final raw = '${post['contact']}'.trim();
    final wa = whatsappNumber(raw);
    final desc = '${post['description'] ?? ''}';
    final snippet = desc.length > 80 ? '${desc.substring(0, 80)}…' : desc;
    final isMail = raw.contains('@');
    final color = isMail ? kPrimary : const Color(0xFF1FAF54);
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color.withValues(alpha: .12), foregroundColor: color, elevation: 0, minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 16)),
        onPressed: () {
          final msg = Uri.encodeComponent('Bonjour, je suis intéressé(e) par votre annonce : $snippet');
          final uri = isMail ? Uri.parse('mailto:$raw?subject=${Uri.encodeComponent('Annonce')}&body=$msg') : wa != null ? Uri.parse('https://wa.me/$wa?text=$msg') : Uri.parse('tel:$raw');
          launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        icon: Icon(isMail ? Icons.mail_outline_rounded : Icons.chat_rounded, size: 18),
        label: Text(isMail ? raw : 'Contacter par WhatsApp'),
      ),
    );
  }
}

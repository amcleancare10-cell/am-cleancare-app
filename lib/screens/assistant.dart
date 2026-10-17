import 'dart:convert';
import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../config.dart';
import '../ui.dart';
import 'requests.dart';
import 'tickets.dart';

const welcome = "Bonjour, je suis votre concierge virtuel 👋\nJe suis là pour vous aider à trouver la solution à votre problème.\nJe parle votre langue ainsi que plusieurs autres.\n\nComment puis-je vous aider ?";

// Mesmas palavras-chave da app original para propor ações depois da resposta.
bool _has(String t, List<String> keys) {
  final l = t.toLowerCase();
  return keys.any(l.contains);
}

bool needsWhatsapp(String t) => _has(t, ['whatsapp', 'contactez-nous sur whatsapp', 'contact us on whatsapp']);
bool needsFootage(String t) => _has(t, ['security footage', 'footage', 'security video', 'watch footage', 'watch video footage', 'surveillance camera', 'sécurité vidéo', 'view the footage', 'visionner les images', 'see the recording', 'enregistrement vidéo']);
bool needsTicket(String t) => _has(t, ['open a ticket', 'create a ticket', 'ticket', 'ouvrir un dossier', 'déposer un ticket', 'contacter', 'contacting management', 'management contact', 'am cleancare', 'agency', 'contact management']);

/// Concierge virtuel: assistente de IA com memória da conversa.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.me});
  final Me me;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final msg = TextEditingController();
  final scroll = ScrollController();
  final List<Map<String, dynamic>> history = [];
  XFile? pendingImage;
  bool busy = false, loaded = false;
  String get _key => 'assistant_${widget.me.uid}';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final raw = p.getString(_key);
      if (raw != null) {
        try { history.addAll(List<Map<String, dynamic>>.from((jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)))); } catch (_) {}
      }
      if (mounted) setState(() => loaded = true);
      _down();
    });
  }

  Future<void> _save() async => (await SharedPreferences.getInstance()).setString(_key, jsonEncode(history.length > 40 ? history.sublist(history.length - 40) : history));

  void _down() => WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent + 300, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      });

  Future<void> send([String? preset]) async {
    final t = (preset ?? msg.text).trim();
    if ((t.isEmpty && pendingImage == null) || busy) return;
    msg.clear();
    final img = pendingImage;
    pendingImage = null;
    setState(() { busy = true; });
    String? imageUrl;
    try {
      if (img != null) imageUrl = (await Api.uploadImages(AppConfig.bucketTickets, [img])).first;
    } catch (_) {}
    history.add({'role': 'user', 'content': t.isEmpty ? '(photo)' : t, 'image_url': ?imageUrl, 't': DateTime.now().toIso8601String()});
    setState(() {});
    _down();
    final r = await Api.edge('ai-chat', {'lang': L.lang.value, 'context': {'name': widget.me.name.split(' ').first, 'building': widget.me.buildingName, 'apartment': widget.me.apartNum, 'whatsappGroup': '${widget.me.building?['whatsapp_group'] ?? ''}'.trim().isNotEmpty}, 'messages': history.map((m) => {'role': m['role'], 'content': m['content'], 'image_url': ?m['image_url']}).toList()});
    final reply = r?['reply']?.toString();
    history.add({'role': 'assistant', 'content': (reply == null || reply.isEmpty) ? "Je ne suis pas disponible pour le moment. Vous pouvez contacter la conciergerie sur WhatsApp ou ouvrir un Ticket pour que l'équipe vous aide." : reply, 't': DateTime.now().toIso8601String()});
    await _save();
    if (mounted) setState(() => busy = false);
    _down();
  }

  Future<void> reset() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Nouvelle conversation ?'), content: const Text('La conversation actuelle sera effacée.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => Navigator.pop(context, true), child: const Text('Effacer'))]));
    if (ok != true) return;
    history.clear();
    await _save();
    if (mounted) setState(() {});
  }

  Widget actions(String text) {
    final chips = <Widget>[];
    Widget chip(IconData i, String l, Color c, VoidCallback f) => ActionChip(avatar: Icon(i, size: 18, color: c), label: Text(l, style: TextStyle(fontWeight: FontWeight.w700, color: c)), side: BorderSide(color: c.withValues(alpha: .5)), backgroundColor: c.withValues(alpha: .08), onPressed: f);
    if (needsWhatsapp(text) && AppConfig.whatsappUrl.isNotEmpty) chips.add(chip(Icons.chat_rounded, 'WhatsApp', const Color(0xFF1FAF54), () => launchUrl(Uri.parse(AppConfig.whatsappUrl), mode: LaunchMode.externalApplication)));
    if (needsFootage(text)) chips.add(chip(Icons.videocam_outlined, 'Demander les images', kAmber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestScreen(me: widget.me, kind: RequestKind.camera)))));
    if (needsTicket(text)) chips.add(chip(Icons.confirmation_number_outlined, 'Ouvrir un ticket', kPrimary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewTicketScreen(me: widget.me)))));
    chips.add(chip(Icons.copy_rounded, 'Copier', const Color(0xFF667085), () { Clipboard.setData(ClipboardData(text: text)); toast(context, 'Réponse copiée.'); }));
    return Padding(padding: const EdgeInsets.only(top: 4, bottom: 6), child: Wrap(spacing: 8, runSpacing: 6, children: chips));
  }

  static const _suggestions = ["J'ai une fuite d'eau", 'Problème de chauffage', 'Bruit des voisins', "L'ascenseur est en panne", "J'ai perdu mon colis"];

  Widget _suggestionBar() => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _suggestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (c, i) => ActionChip(
            label: Text(_suggestions[i], style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimary)),
            backgroundColor: kPrimary.withValues(alpha: .09),
            side: BorderSide(color: kPrimary.withValues(alpha: .25)),
            shape: const StadiumBorder(),
            onPressed: busy ? null : () => send(tr(_suggestions[i])),
          ),
        ),
      );

  Widget _intro() => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 18),
        child: Column(children: [
          const _Avatar(size: 76),
          const SizedBox(height: 12),
          const Text('Concierge virtuel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 2),
          Text('Répond en quelques secondes', style: TextStyle(fontSize: 13, color: mutedOf(context))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final lastIdx = history.lastIndexWhere((m) => m['role'] == 'assistant');
    final dark = isDark(context);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0E1224) : const Color(0xFFF3F4FA),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          const _Avatar(size: 40, dot: true),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Concierge virtuel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text('En ligne', style: TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w700))])),
        ]),
        actions: [IconButton(tooltip: tr('Nouvelle conversation'), onPressed: reset, icon: const Icon(Icons.edit_note_rounded, size: 28))],
      ),
      body: Column(children: [
        Expanded(
          child: !loaded
              ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
              : ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), children: [
                  _intro(),
                  const _Row(mine: false, showAvatar: true, text: welcome),
                  for (var i = 0; i < history.length; i++) ...[
                    _Row(
                      mine: history[i]['role'] == 'user',
                      showAvatar: history[i]['role'] != 'user' && (i == history.length - 1 || history[i + 1]['role'] == 'user'),
                      text: '${history[i]['content']}',
                      time: history[i]['t'] != null ? fmtTime(history[i]['t']) : null,
                      imageUrl: history[i]['image_url']?.toString(),
                    ),
                    if (i == lastIdx && !busy) Padding(padding: const EdgeInsets.only(left: 38), child: actions('${history[i]['content']}')),
                  ],
                  if (busy) const _Row.typing(),
                ]),
        ),
        if (pendingImage != null)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: lineOf(context))),
            child: Row(children: [const Icon(Icons.image_outlined, size: 20, color: kPrimary), const SizedBox(width: 8), Expanded(child: Text(pendingImage!.name, overflow: TextOverflow.ellipsis)), IconButton(onPressed: () => setState(() => pendingImage = null), icon: const Icon(Icons.close_rounded, size: 20))]),
          ),
        if (history.isEmpty && !busy) Padding(padding: const EdgeInsets.only(bottom: 8), child: _suggestionBar()),
        _Composer(
          controller: msg,
          busy: busy,
          onSend: send,
          onAttach: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
            if (x != null) setState(() => pendingImage = x);
          },
        ),
      ]),
    );
  }
}

String fmtTime(dynamic d) {
  try {
    final t = DateTime.parse(d.toString()).toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

/// Avatar do concierge virtual.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, this.dot = false});
  final double size;
  final bool dot;
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Container(width: size, height: size, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kPrimary, kViolet], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Padding(padding: EdgeInsets.all(size * .16), child: Image.asset('assets/logo_branco.png', fit: BoxFit.contain))),
        if (dot) Positioned(right: -1, bottom: -1, child: Container(width: size * .32, height: size * .32, decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)))),
      ]);
}

/// Uma linha de conversa estilo Messenger: avatar à esquerda nas mensagens do concierge, balão à direita nas minhas.
class _Row extends StatelessWidget {
  const _Row({required this.mine, required this.text, this.showAvatar = false, this.time, this.imageUrl}) : typing = false;
  const _Row.typing() : mine = false, text = '', showAvatar = true, time = null, imageUrl = null, typing = true;
  final bool mine, showAvatar, typing;
  final String text;
  final String? time, imageUrl;

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final bg = mine ? null : (dark ? const Color(0xFF1F2440) : Colors.white);
    final radius = BorderRadius.only(topLeft: const Radius.circular(22), topRight: const Radius.circular(22), bottomLeft: Radius.circular(mine ? 22 : (showAvatar ? 6 : 22)), bottomRight: Radius.circular(mine ? 6 : 22));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) SizedBox(width: 32, child: showAvatar ? const _Avatar(size: 28) : null),
          if (!mine) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .74),
                  padding: typing ? const EdgeInsets.symmetric(horizontal: 18, vertical: 15) : const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: mine ? const LinearGradient(colors: [kPrimary, kViolet], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    color: bg,
                    borderRadius: radius,
                    boxShadow: mine ? null : [BoxShadow(color: Colors.black.withValues(alpha: dark ? .2 : .05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: typing
                      ? const _Dots()
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          if (imageUrl != null) Padding(padding: EdgeInsets.only(bottom: text == '(photo)' ? 0 : 8), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(imageUrl!, width: 210, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()))),
                          if (text.isNotEmpty && text != '(photo)') Text(text, style: TextStyle(color: mine ? Colors.white : null, height: 1.4, fontSize: 15)),
                        ]),
                ),
                if (time != null && time!.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(6, 3, 6, 0), child: Text(time!, style: TextStyle(fontSize: 11, color: mutedOf(context)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de escrita em forma de pílula, como no Messenger.
class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.busy, required this.onSend, required this.onAttach});
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend, onAttach;
  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: dark ? const Color(0xFF1B2038) : Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: lineOf(context))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                IconButton(onPressed: onAttach, icon: const Icon(Icons.add_photo_alternate_outlined, color: kPrimary)),
                Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 5, textInputAction: TextInputAction.send, onSubmitted: (_) => onSend(), decoration: InputDecoration(hintText: tr('Écrivez votre message'), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, contentPadding: const EdgeInsets.symmetric(vertical: 13)))),
                const SizedBox(width: 8),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kPrimary, kViolet])),
            child: IconButton(onPressed: busy ? null : onSend, icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22)),
          ),
        ]),
      ),
    );
  }
}

/// Três pontos animados (a escrever…).
class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() { c.dispose(); super.dispose(); }

  double _lift(int i) {
    final p = (c.value * 3 - i) % 3;
    return p < 1 ? (p < .5 ? p * 2 : 2 - p * 2) : 0;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, _) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: EdgeInsets.only(right: i == 2 ? 0 : 5, bottom: 5 * _lift(i)),
              width: 9,
              height: 9,
              decoration: BoxDecoration(shape: BoxShape.circle, color: mutedOf(context).withValues(alpha: .7)),
            ),
        ]),
      );
}

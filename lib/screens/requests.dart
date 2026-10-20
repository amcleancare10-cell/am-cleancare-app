import 'dart:typed_data';
import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../config.dart';
import '../ui.dart';
import '../laundry_help.dart';

enum RequestKind { camera, code, laundry }

/// Pedidos ao gestor: buanderie, "Colis volé ?" (câmaras) e código.
class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key, required this.me, required this.kind});
  final Me me;
  final RequestKind kind;
  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final details = TextEditingController(), subject = TextEditingController(), contact = TextEditingController();
  String? device;
  final Set<String> problems = {};
  final List<XFile> photos = [];
  final List<Uint8List> previews = [];
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  String? codeChoice;
  bool busy = false;
  Json? laundry;

  RequestKind get kind => widget.kind;
  bool get needsPhoto => kind != RequestKind.code;

  @override
  void initState() {
    super.initState();
    contact.text = widget.me.phone.isNotEmpty ? '${widget.me.email} · ${widget.me.phone}' : widget.me.email;
    if (widget.kind == RequestKind.laundry) loadMyLaundry(widget.me).then((l) { if (mounted) setState(() => laundry = l); });
  }

  String get title => switch (kind) { RequestKind.camera => "Demande d'information", RequestKind.code => 'Demande de code', RequestKind.laundry => 'Gestion des problèmes' };

  Future<void> pick() async {
    final r = await ImagePicker().pickMultiImage(imageQuality: 80, limit: 4);
    for (final x in r) {
      photos.add(x);
      previews.add(await x.readAsBytes());
    }
    if (mounted) setState(() {});
  }

  Future<void> submit() async {
    if (kind == RequestKind.laundry && device == null) { toast(context, "Sélectionnez le type d'appareil concerné.", error: true); return; }
    if (kind == RequestKind.laundry && problems.isEmpty) { toast(context, 'Sélectionnez le problème rencontré.', error: true); return; }
    if (kind == RequestKind.camera && subject.text.trim().isEmpty) { toast(context, "Indiquez l'objet de votre demande.", error: true); return; }
    if (kind == RequestKind.code && codeChoice == null) { toast(context, 'Choisissez le code demandé.', error: true); return; }
    if (needsPhoto && photos.isEmpty) { toast(context, 'Vous devez charger une image.', error: true); return; }
    final when = '${fmtDate(date.toIso8601String())} ${time.format(context)}';
    setState(() => busy = true);
    try {
      final me = widget.me;
      final urls = await Api.uploadImages(AppConfig.bucketTickets, photos);
      final m = await Api.managerOf(me);
      final p = {
        'deviceType': switch (kind) { RequestKind.laundry => device ?? '', RequestKind.camera => subject.text.trim(), RequestKind.code => codeChoice ?? '' },
        'problemsList': problems.join(', '),
        'details': kind == RequestKind.camera ? 'Date et heure : $when\n${details.text.trim()}' : details.text.trim(),
        'photoUrl': urls.isEmpty ? '' : urls.first,
        'nomeLocatario': me.name, 'building': me.buildingName, 'floor': '${me.floor ?? ''}', 'num': me.apartNum, 'email': me.email, 'contact': contact.text.trim(),
        'landlordEmail': '${m?['email'] ?? ''}', 'landlordPhone': '${m?['phone'] ?? ''}',
        'tenantPhone': me.phone, 'address': '${me.building?['address'] ?? ''}', 'managerName': '${m?['manager_name'] ?? ''}', 'agencyName': '${m?['agency_name'] ?? ''}',
        'ref': 'DEM-${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(2, 12)}',
      };
      final template = switch (kind) { RequestKind.laundry => 'laundry_report', RequestKind.code => 'code_request', RequestKind.camera => 'camera_request' };
      // como na app original: os pedidos vão para a caixa da empresa (info@ambox.ch), com os dados do gerente no corpo
      await Api.email(template, AppConfig.supportEmail, AppConfig.appName, p);
      if (kind == RequestKind.laundry) {
        await _laundryTicket(me, m, urls, p);   // o signalamento vira um ticket real (lugar « Buanderie ») : a gérance acompanha-o no painel
      } else {
        await Api.notify([me.managerId], title, '${me.name} · ${p['deviceType']}');
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const IconBadge(Icons.check_circle_outline_rounded, color: kGreen, size: 64),
          title: Text(kind == RequestKind.code ? 'Succès' : 'Demande envoyée'),
          content: Text(switch (kind) {
            RequestKind.code => "Un e-mail contenant votre demande a été envoyé à votre gérance. Veuillez patienter jusqu'à ce que vous receviez une réponse.",
            RequestKind.laundry => 'Votre signalement sera traité dans les plus brefs délais.',
            RequestKind.camera => 'Votre demande a été transmise à la gérance. Vous serez contacté rapidement.',
          }),
          actions: [FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(110, 46)), onPressed: () => Navigator.pop(context), child: const Text('Ok'))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Cria o ticket « Buanderie » (lugar 32 / tipo conforme a máquina) ; se falhar, o e-mail já foi enviado e a gérance é avisada na mesma.
  Future<void> _laundryTicket(Me me, Json? m, List<String> urls, Map<String, String> p) async {
    try {
      if (me.buildingId == null) throw 'sem edifício';
      final loc = await sb.from('locations').select('id').ilike('description', 'buanderie').limit(1).maybeSingle();
      final locId = loc?['id'];
      final probs = problems.toList();
      final leak = probs.contains("Fuite d'eau");
      final typeName = leak ? "Fuite d eau" : (device == 'Sèche-linge' ? 'Séchoir en panne' : 'Machine à laver en panne');
      int? typeId;
      if (locId != null) { final t = await sb.from('problem_types').select('id').eq('locationID', locId).ilike('name', typeName).limit(1).maybeSingle(); typeId = (t?['id'] as num?)?.toInt(); }
      final titleT = 'Buanderie · ${device ?? ''} · ${probs.join(', ')}';
      final descT = [if (probs.isNotEmpty) 'Problèmes : ${probs.join(', ')}', if (details.text.trim().isNotEmpty) details.text.trim(), 'Signalé depuis la section Buanderie de l\'application.'].join('\n');
      final ticket = await sb.from('tickets').insert({'tenant_id': me.uid, 'apartment_id': me.buildingId, 'title': titleT, 'description': descT, 'location_id': locId, 'problem_type_id': typeId, 'status': 'En Attente', 'photos': urls}).select().single();
      await sb.from('ticket_chats').insert({'ticket_id': ticket['id'], 'author_id': me.uid, 'author_name': me.name, 'message': descT, 'isVisualized': false});
      await Api.notify([me.managerId], 'Nouveau ticket #${ticket['id']} · Buanderie', '$titleT · ${me.name}');
      final now = DateTime.now();
      Api.email('ticket_created', m?['email']?.toString(), m?['manager_name']?.toString(), {
        'ticketNumber': '${ticket['id']}', 'ticketTitle': titleT, 'creatorName': me.name, 'apartmentName': me.buildingName, 'floor': '${me.floor ?? ''}', 'apartamentNumber': me.apartNum,
        'problemDescription': descT, 'location': 'Buanderie', 'problemType': typeName, 'photoUrls': urls.take(4).join(','), 'tenantPhone': me.phone, 'tenantEmail': me.email,
        'address': '${me.building?['address'] ?? ''}', 'date': fmtDate(now.toIso8601String()), 'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}', 'landLordEmail': '${m?['email'] ?? ''}',
      });
    } catch (e) {
      debugPrint('laundry ticket: $e');
      await Api.notify([me.managerId], title, '${me.name} · ${p['deviceType']}');
    }
  }

  Widget photoPicker(String hint, {bool required = true}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(hint, style: TextStyle(color: mutedOf(context), fontSize: 13.5, height: 1.35)),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            InkWell(
              onTap: pick,
              borderRadius: BorderRadius.circular(18),
              child: Container(width: 96, decoration: BoxDecoration(color: kPrimary.withValues(alpha: .08), borderRadius: BorderRadius.circular(18), border: Border.all(color: kPrimary.withValues(alpha: .35))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, color: kPrimary, size: 28), SizedBox(height: 4), Text('Ajouter', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12))])),
            ),
            for (var i = 0; i < previews.length; i++)
              Padding(padding: const EdgeInsets.only(left: 10), child: Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(previews[i], width: 96, height: 96, fit: BoxFit.cover)),
                Positioned(right: 4, top: 4, child: InkWell(onTap: () => setState(() { photos.removeAt(i); previews.removeAt(i); }), child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 15, color: Colors.white)))),
              ])),
          ]),
        ),
        if (required && photos.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('* Vous devez télécharger une image.', style: TextStyle(color: kRed, fontSize: 12.5))),
      ]);

  Widget deviceTile(String label, IconData icon) {
    final sel = device == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => device = label),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: sel ? kPrimary.withValues(alpha: .12) : Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? kPrimary : lineOf(context), width: sel ? 2 : 1)),
          child: Column(children: [Icon(icon, size: 36, color: sel ? kPrimary : mutedOf(context)), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: sel ? kPrimary : null))]),
        ),
      ),
    );
  }

  Widget helpTile(IconData i, String t, String url) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: IconBadge(i, size: 40),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: EdgeInsets.fromLTRB(18, 0, 18, 30 + safeBottom(context)), children: [
          if (kind == RequestKind.laundry) ...[
            const FormLabel('Signaler un problème'),
            Text("Sélectionnez le type d'appareil concerné", style: TextStyle(color: mutedOf(context))),
            const SizedBox(height: 12),
            Row(children: [deviceTile('Machine à laver', Icons.local_laundry_service_outlined), const SizedBox(width: 12), deviceTile('Sèche-linge', Icons.dry_cleaning_outlined)]),
            const FormLabel('Sélectionnez le problème rencontré'),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final p in const ['Ne démarre pas', "Fuite d'eau", 'Bruit anormal', 'Cycle incomplet', "Erreur sur l'écran", 'Porte bloquée']) FilterChip(label: Text(p), selected: problems.contains(p), selectedColor: kPrimary.withValues(alpha: .15), onSelected: (v) => setState(() => v ? problems.add(p) : problems.remove(p)))]),
            LaundryHelpCard(laundry: laundry, problems: problems),
            const FormLabel('Ajouter une photo du problème'),
            photoPicker('Une photo nous aide à intervenir plus vite.'),
            const FormLabel('Détails (facultatif)'),
            TextField(controller: details, minLines: 3, maxLines: 6, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Décrivez le problème'), alignLabelWithHint: true)),
            const FormLabel('Aide'),
            SoftCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Column(children: [
              helpTile(Icons.menu_book_outlined, 'Guide', AppConfig.helpGuideUrl), const Divider(),
              helpTile(Icons.description_outlined, 'Manuel', '${laundry?['lien_manuel'] ?? ''}'.trim().isNotEmpty ? '${laundry!['lien_manuel']}'.trim() : AppConfig.helpManualUrl), const Divider(),
              helpTile(Icons.play_circle_outline_rounded, 'Vidéos', AppConfig.helpVideosUrl),
            ])),
          ],
          if (kind == RequestKind.camera) ...[
            SoftCard(gradient: kHeroGradient, child: const Row(children: [Icon(Icons.inventory_2_outlined, color: Colors.white, size: 30), SizedBox(width: 14), Expanded(child: Text('Colis volé ?\nNous sommes là pour vous aider.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.3)))])),
            const FormLabel('Détails de la demande'),
            TextField(controller: subject, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Objet *'), prefixIcon: Icon(Icons.title_rounded))),
            const SizedBox(height: 12),
            TextField(controller: details, minLines: 4, maxLines: 8, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Description (lieu, objet, circonstances)'), alignLabelWithHint: true)),
            const FormLabel('Preuve de livraison'),
            photoPicker("Veuillez ajouter des captures d'écran de votre preuve de livraison."),
            const FormLabel('Date et heure'),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now()); if (d != null) setState(() => date = d); }, icon: const Icon(Icons.calendar_today_outlined, size: 18), label: Text(fmtDate(date.toIso8601String())))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () async { final t = await showTimePicker(context: context, initialTime: time); if (t != null) setState(() => time = t); }, icon: const Icon(Icons.schedule_rounded, size: 18), label: Text(time.format(context)))),
            ]),
            const FormLabel('Contact'),
            TextField(controller: contact, decoration: InputDecoration(labelText: tr('E-mail ou téléphone'), prefixIcon: Icon(Icons.alternate_email_rounded))),
          ],
          if (kind == RequestKind.code) ...[
            const FormLabel('Infos'),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final c in const ['Boîte aux lettres', "Porte d'entrée", 'Garage', 'Local vélos', 'Autre']) ChoiceChip(label: Text(c), selected: codeChoice == c, selectedColor: kPrimary.withValues(alpha: .15), onSelected: (_) => setState(() => codeChoice = c))]),
            const SizedBox(height: 14),
            TextField(controller: details, minLines: 3, maxLines: 6, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: tr('Précisions (facultatif)'), alignLabelWithHint: true)),
            const FormLabel('Contact'),
            TextField(controller: contact, decoration: InputDecoration(labelText: tr('E-mail ou téléphone'), prefixIcon: Icon(Icons.alternate_email_rounded))),
          ],
          const SizedBox(height: 28),
          FilledButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(switch (kind) { RequestKind.laundry => 'Envoyer le signalement', _ => 'Envoyer la demande' })),
        ]),
      );
}

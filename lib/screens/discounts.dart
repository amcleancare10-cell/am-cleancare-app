import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Codes de réduction (bons plans para os moradores).
class DiscountsTab extends StatefulWidget {
  const DiscountsTab({super.key});
  @override
  State<DiscountsTab> createState() => _DiscountsTabState();
}

class _DiscountsTabState extends State<DiscountsTab> {
  int _k = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Codes de réduction')),
        body: Load<List<Json>>(
          key: ValueKey(_k),
          future: sb.from('codesReduction').select().order('created_at', ascending: false).then((v) => List<Json>.from(v)),
          builder: (c, rows) => rows.isEmpty
              ? const EmptyState('Aucun code de réduction pour le moment.\nRevenez bientôt !', icon: Icons.local_offer_outlined)
              : RefreshIndicator(
                  onRefresh: () async => setState(() => _k++),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (c, i) {
                      final d = rows[i];
                      final img = '${d['img'] ?? ''}';
                      final code = '${d['code'] ?? ''}'.trim();
                      final isUrl = code.startsWith('http');
                      final desc = '${d['description'] ?? ''}'.trim();
                      return FadeIn(
                        delay: i * 45,
                        child: SoftCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: lineOf(context))),
                                padding: const EdgeInsets.all(6),
                                child: img.isEmpty ? const Icon(Icons.local_offer_rounded, color: kPrimary) : Image.network(img, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.local_offer_rounded, color: kPrimary)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${d['title'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                if (desc.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: mutedOf(context), fontSize: 13))),
                              ])),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: isUrl
                                  ? FilledButton.icon(
                                      style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                                      onPressed: () => launchUrl(Uri.parse(code), mode: LaunchMode.externalApplication),
                                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                                      label: const Text("Ouvrir l'offre"),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(color: kPrimary.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
                                      child: Text(code, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16, color: kPrimary)),
                                    )),
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                tooltip: 'Copier',
                                onPressed: () { Clipboard.setData(ClipboardData(text: code)); toast(c, isUrl ? 'Lien copié' : 'Code copié'); },
                                icon: const Icon(Icons.copy_rounded, size: 18),
                              ),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
        ),
      );
}

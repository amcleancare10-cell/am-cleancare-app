import 'package:flutter/material.dart' hide Text;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'l10n.dart';
import 'ui.dart';

/// Buanderie du locataire (la première active de son immeuble) : instructions des machines écrites par la gérance.
Future<Json?> loadMyLaundry(Me me) async {
  final bid = me.buildingId;
  if (bid == null) return null;
  try {
    final rows = List<Json>.from(await sb.from('buanderie').select().or('batiment_id.eq.$bid,batiments_acces.cs.{$bid}').eq('actif', true).order('ordre').order('id'));
    return rows.firstOrNull;
  } on PostgrestException catch (_) {
    return null;
  } catch (_) {
    return null;
  }
}

/// Conseils rapides, par problème (texte de base en français, traduit par l10n). Jamais d'invention : gestes de sécurité usuels.
const laundryTips = <String, String>{
  'Porte bloquée': "Attendez 3 minutes après la fin du cycle (verrou de sécurité) et ne forcez jamais la porte. Si elle reste bloquée, signalez-le.",
  'Ne démarre pas': "Vérifiez que la porte est bien fermée et que le programme est choisi. Si rien ne s'affiche, signalez-le.",
  "Fuite d'eau": "Arrêtez la machine et ne touchez pas au branchement électrique avec les mains mouillées. Prenez une photo et signalez-le tout de suite.",
  'Bruit anormal': "Vérifiez que le linge est bien réparti et que la machine n'est pas surchargée. Si le bruit continue, signalez-le.",
  'Cycle incomplet': "Éteignez la machine 1 minute, puis relancez le programme (essorage). Si cela se répète, signalez-le.",
  "Erreur sur l'écran": "Notez le code affiché et prenez-le en photo. Éteignez la machine 1 minute, puis rallumez-la.",
};

/// Cartão « Instructions des machines » (texto da gérance + manual), com os conselhos dos problemas escolhidos.
class LaundryHelpCard extends StatelessWidget {
  const LaundryHelpCard({super.key, required this.laundry, this.problems = const {}, this.title = 'Instructions des machines'});
  final Json? laundry;
  final Set<String> problems;
  final String title;

  @override
  Widget build(BuildContext context) {
    final consignes = '${laundry?['consignes'] ?? ''}'.trim();
    final lien = '${laundry?['lien_manuel'] ?? ''}'.trim();
    final tips = [for (final p in problems) if (laundryTips[p] != null) MapEntry(p, laundryTips[p]!)];
    if (consignes.isEmpty && lien.isEmpty && tips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const IconBadge(Icons.menu_book_outlined, size: 40), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)))]),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Essayez d\'abord', style: TextStyle(fontWeight: FontWeight.w800, color: mutedOf(context), fontSize: 12.5)),
            for (final t in tips) Padding(padding: const EdgeInsets.only(top: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline_rounded, size: 18, color: kGreen), const SizedBox(width: 8), Expanded(child: Text(t.value, style: const TextStyle(height: 1.35)))])),
          ],
          if (consignes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(consignes, style: const TextStyle(height: 1.4, fontSize: 14.5)),
          ],
          if (lien.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(onPressed: () => launchUrl(Uri.parse(lien), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new_rounded, size: 18), label: Text('Manuel / vidéo des machines')),
          ],
        ]),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart' hide Text;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'config.dart';
import 'l10n.dart';

/// Aviso de « nova versão disponível ». A atualização faz-se SEMPRE pela loja (Google Play / App Store), nunca por ficheiro da internet.
/// A app consulta amcleancare.ch/apk/version.json (« build » = última versão já publicada nas lojas) e, se for mais recente, abre a loja.
class AppUpdate {
  static bool _shown = false;

  static Future<void> check(BuildContext context) async {
    if (kIsWeb || _shown) return;
    try {
      final r = await http.get(Uri.parse(AppConfig.updateInfoUrl)).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final build = (j['build'] as num?)?.toInt() ?? 0;
      if (build <= AppConfig.buildNumber) return;
      _shown = true;
      if (!context.mounted) return;
      final force = j['force'] == true;
      final notes = '${j['notes'] ?? ''}'.trim();
      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      final store = ios ? AppConfig.appStoreUrl : AppConfig.playStoreUrl;
      await showDialog<void>(
        context: context,
        barrierDismissible: !force,
        builder: (c) => AlertDialog(
          title: const Text('Nouvelle version disponible'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Version ${j['version'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
            if (notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(notes)),
            const Padding(padding: EdgeInsets.only(top: 10), child: Text("Appuyez sur « Mettre à jour », ouvrez le fichier téléchargé et confirmez l'installation.", style: TextStyle(fontSize: 12.5))),
          ]),
          actions: [
            if (!force) TextButton(onPressed: () => Navigator.pop(c), child: const Text('Plus tard')),
            FilledButton(onPressed: () { launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication); if (!force) Navigator.pop(c); }, child: const Text('Mettre à jour')),
          ],
        ),
      );
    } catch (_) {/* sem ligação ou sem ficheiro: ignora */}
  }
}

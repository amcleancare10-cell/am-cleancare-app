import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Text;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'config.dart';
import 'l10n.dart';

/// Aviso de « nova versão disponível » (só no Android instalado por APK). A app consulta
/// amcleancare.ch/apk/version.json e, se houver uma versão mais recente, propõe descarregá-la.
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
      final url = '${j['apk'] ?? AppConfig.updateApkUrl}';
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
            FilledButton(onPressed: () { launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); if (!force) Navigator.pop(c); }, child: const Text('Mettre à jour')),
          ],
        ),
      );
    } catch (_) {/* sem ligação ou sem ficheiro: ignora */}
  }
}

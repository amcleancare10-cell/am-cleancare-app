import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'api.dart';

/// Notificações push no telemóvel (OneSignal). O utilizador é identificado pelo seu user_id,
/// o mesmo que a função send-push usa como destino (external_id).
class Push {
  static const appId = 'd1f5fcd0-c1ca-47e9-a59a-1295359db97c';
  static bool _ready = false;
  static String _obsToken = '', _obsId = '', _obsLog = '';

  static void init() {
    if (kIsWeb || _ready) return;
    try {
      OneSignal.initialize(appId);
      OneSignal.User.pushSubscription.addObserver((st) {
        _obsToken = st.current.token ?? '';
        _obsId = st.current.id ?? '';
        _obsLog = 'optedIn=${st.current.optedIn} · token=${_obsToken.isEmpty ? 'vide' : 'reçu'} · id=${_obsId.isEmpty ? 'vide' : 'ok'}';
      });
      _ready = true;
    } catch (_) {}
  }

  /// Liga este telemóvel ao utilizador, pede a permissão e garante que está subscrito.
  static Future<void> login(String uid) async {
    if (kIsWeb) return;
    init();
    if (!_ready) return;
    try {
      await OneSignal.login(uid);
      await OneSignal.Notifications.requestPermission(true);
      await OneSignal.User.pushSubscription.optIn();
    } catch (_) {}
  }

  /// As notificações do telemóvel estão permitidas? (na web não se aplica: devolve true)
  static Future<bool> granted() async {
    if (kIsWeb || !_ready) return true;
    try {
      return OneSignal.Notifications.permission;
    } catch (_) {
      return true;
    }
  }

  /// Volta a pedir a permissão (se o Android já não deixar pedir, abre as definições da app).
  static Future<void> askAgain() async {
    if (kIsWeb || !_ready) return;
    try {
      await OneSignal.Notifications.requestPermission(true);
      await OneSignal.User.pushSubscription.optIn();
    } catch (_) {}
  }

  /// Estado do registo neste telemóvel (para diagnosticar quando o push não chega).
  static Future<String> status(String uid) async {
    if (kIsWeb) return 'Notifications du téléphone : disponibles uniquement dans l’application Android.';
    init();
    final sb = StringBuffer();
    try {
      final sub = OneSignal.User.pushSubscription;
      final oid = await OneSignal.User.getOnesignalId();
      final ext = await OneSignal.User.getExternalId();
      sb.writeln('Autorisation Android : ${OneSignal.Notifications.permission ? 'oui' : 'NON'}');
      sb.writeln('Abonné (optedIn) : ${sub.optedIn}');
      sb.writeln('Jeton FCM : ${((sub.token ?? '').isEmpty && _obsToken.isEmpty) ? 'AUCUN' : 'reçu'}');
      sb.writeln('Dernier changement : ${_obsLog.isEmpty ? 'aucun' : _obsLog}');
      sb.writeln('ID abonnement : ${sub.id ?? 'AUCUN'}');
      sb.writeln('OneSignal ID : ${oid ?? 'AUCUN'}');
      sb.writeln('External ID : ${ext ?? 'AUCUN'}');
      sb.writeln('Compte : $uid');
    } catch (e) {
      sb.writeln('Erreur : $e');
    }
    return sb.toString();
  }

  static Future<void> logout() async {
    if (kIsWeb || !_ready) return;
    try {
      await OneSignal.logout();
    } catch (_) {}
  }
}

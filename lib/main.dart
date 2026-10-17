import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import 'l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api.dart';
import 'push.dart';
import 'config.dart';
import 'ui.dart';
import 'screens/auth.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.configured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.anonKey);
  }
  await L.load();
  Push.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppConfig.appName,
        scaffoldMessengerKey: L.messengerKey,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        builder: (context, child) => ValueListenableBuilder<String>(valueListenable: L.lang, builder: (_, code, _) => KeyedSubtree(key: ValueKey(code), child: child!)),
        home: AppConfig.configured ? const Gate() : const ConfigMissing(),
      );
}

/// Decide o que mostrar: login, espera de aprovação ou a app.
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  Me? me;
  bool loading = true;
  StreamSubscription<AuthState>? sub;

  @override
  void initState() {
    super.initState();
    sub = sb.auth.onAuthStateChange.listen((_) => refresh());
    refresh();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final m = await Api.loadMe();
      if (m == null) { Push.logout(); } else if (m.role != 'manager' && m.role != 'admin') { Push.login(m.uid); }
      if (mounted) setState(() { me = m; loading = false; });
    } catch (e, st) {
      debugPrint('Chargement du profil impossible: $e\n$st');
      if (mounted) setState(() { me = null; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final m = me;
    if (m == null) return const LoginScreen();
    if (m.role == 'manager' || m.role == 'admin') return RoleNotice(me: m);
    if (!m.approved) return PendingScreen(me: m, onRefresh: refresh);
    return HomeShell(me: m, onRefresh: refresh);
  }
}

class ConfigMissing extends StatelessWidget {
  const ConfigMissing({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text("Configuration manquante.\n\nRenseignez la clé publique (anon) du projet dans lib/config.dart ou compilez avec --dart-define=SUPABASE_ANON_KEY=...", textAlign: TextAlign.center),
          ),
        ),
      );
}

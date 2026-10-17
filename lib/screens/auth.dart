import 'package:flutter/material.dart' hide Text;
import '../l10n.dart';
import '../api.dart';
import '../config.dart';
import '../ui.dart';

/// Fundo com gradiente e formas suaves, partilhado pelo login e pelo registo.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child, this.height = 300});
  final Widget child;
  final double height;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Container(height: height, decoration: const BoxDecoration(gradient: kHeroGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(44)))),
        Positioned(top: -50, right: -40, child: Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)))),
        Positioned(top: 90, left: -60, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)))),
        child,
      ]);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(), pass = TextEditingController();
  bool busy = false, hide = true;

  Future<void> login() async {
    if (email.text.trim().isEmpty || pass.text.isEmpty) { toast(context, 'Saisissez votre e-mail et votre mot de passe.', error: true); return; }
    setState(() => busy = true);
    try {
      await sb.auth.signInWithPassword(email: email.text.trim(), password: pass.text);
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e) == 'Invalid login credentials' ? 'E-mail ou mot de passe incorrect.' : Api.fmtErr(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> forgot() async {
    if (email.text.trim().isEmpty) { toast(context, "Saisissez d'abord votre e-mail.", error: true); return; }
    try {
      await sb.auth.resetPasswordForEmail(email.text.trim());
      if (mounted) toast(context, 'E-mail de réinitialisation envoyé.');
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: safeBottom(context)),
          child: Stack(children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 330, child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(gradient: kHeroGradient),
                child: Stack(children: [
                  Positioned(top: MediaQuery.of(context).padding.top + 12, left: 16, child: const LangButton(light: true)),
                  Positioned(top: -50, right: -40, child: Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)))),
                  Positioned(bottom: 10, left: -60, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)))),
                  Padding(
                    padding: EdgeInsets.fromLTRB(28, MediaQuery.of(context).padding.top + 44, 28, 84),
                    child: FadeIn(child: Column(children: [
                      const Brand(size: 78, light: true),
                      const SizedBox(height: 18),
                      Text('Bienvenue', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Votre partenaire de confiance en gestion immobilière', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .88), height: 1.4)),
                    ])),
                  ),
                ]),
              ),
            )),
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 330 - 46),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(children: [
                    FadeIn(
                      delay: 120,
                      child: SoftCard(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          TextField(controller: email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.username], decoration: InputDecoration(labelText: tr('E-mail'), prefixIcon: Icon(Icons.mail_outline_rounded))),
                          const SizedBox(height: 14),
                          TextField(controller: pass, obscureText: hide, autofillHints: const [AutofillHints.password], onSubmitted: (_) => login(), decoration: InputDecoration(labelText: tr('Mot de passe'), prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => hide = !hide)))),
                          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: forgot, child: const Text('Mot de passe oublié ? Cliquez ici'))),
                          const SizedBox(height: 4),
                          FilledButton(onPressed: busy ? null : login, child: busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Se connecter')),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeIn(delay: 220, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Nouveau sur ${AppConfig.appName} ?', style: TextStyle(color: mutedOf(context))),
                      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.w800))),
                    ])),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final code = TextEditingController(), name = TextEditingController(), email = TextEditingController(), phone = TextEditingController(), pass = TextEditingController(), pass2 = TextEditingController(), apart = TextEditingController(), floor = TextEditingController();
  int step = 0;
  int? buildingId;
  Json? building;
  bool busy = false, terms = false, hide = true;

  Future<void> checkCode() async {
    if (code.text.trim().isEmpty) { toast(context, 'Saisissez le code.', error: true); return; }
    setState(() => busy = true);
    try {
      final b = await Api.validateCode(code.text);
      if (b == null) throw Exception("Code d'inscription invalide.");
      // código pessoal da carta (« Nom | app. 12, étage 3 »): o nome, o apartamento e o andar já vêm preenchidos
      final ct = '${b['codeTitle'] ?? ''}';
      if (ct.contains(' | ')) {
        final parts = ct.split(' | ');
        if (name.text.trim().isEmpty) name.text = parts.first.trim();
        final det = parts.sublist(1).join(' | ');
        final am = RegExp(r'app\.\s*([^,]+)').firstMatch(det), fm = RegExp(r'[ée]tage\s*(\d+)').firstMatch(det);
        if (am != null && apart.text.trim().isEmpty) apart.text = am.group(1)!.trim();
        if (fm != null && floor.text.trim().isEmpty) floor.text = fm.group(1)!;
      }
      setState(() { buildingId = (b['apartID'] as num).toInt(); building = b; step = 1; });
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void toPassword() {
    if ([name, email, apart].any((c) => c.text.trim().isEmpty)) { toast(context, 'Remplissez les champs obligatoires.', error: true); return; }
    if (!email.text.contains('@')) { toast(context, 'E-mail invalide.', error: true); return; }
    setState(() => step = 2);
  }

  Future<void> submit() async {
    if (pass.text.length < 6) { toast(context, 'Mot de passe : 6 caractères minimum.', error: true); return; }
    if (pass.text != pass2.text) { toast(context, 'Les mots de passe ne correspondent pas.', error: true); return; }
    if (!terms) { toast(context, "Veuillez accepter les conditions d'utilisation.", error: true); return; }
    setState(() => busy = true);
    try {
      final res = await sb.auth.signUp(email: email.text.trim(), password: pass.text);
      final uid = res.user?.id;
      if (uid == null) throw Exception('Création du compte impossible.');
      await sb.from('tenants').insert({'user_id': uid, 'apartment_id': buildingId, 'full_name': name.text.trim(), 'email': email.text.trim(), 'phone': phone.text.trim(), 'apartNum': apart.text.trim(), 'floor': int.tryParse(floor.text.trim()), 'isAcceptTerm': true, 'statusAproved': 'En Attente'});
      await sb.from('user_profiles').insert({'user_id': uid, 'role': 'tenant'});
      if (mounted) {
        toast(context, 'Compte créé. Votre inscription doit être validée par la gérance.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) toast(context, Api.fmtErr(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(String l, TextEditingController c, {TextInputType? t, IconData? i}) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextField(controller: c, keyboardType: t, decoration: InputDecoration(labelText: tr(l), prefixIcon: i == null ? null : Icon(i))));

  Widget stepper() => Row(children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 5, decoration: BoxDecoration(color: i <= step ? Colors.white : Colors.white.withValues(alpha: .3), borderRadius: BorderRadius.circular(9)))),
          if (i < 2) const SizedBox(width: 6),
        ],
      ]);

  @override
  Widget build(BuildContext context) {
    final titles = ['Entrez le code', 'Vos informations', 'Créer un mot de passe'];
    return Scaffold(
      body: AuthBackdrop(
        height: 230,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 22, 0),
              child: Row(children: [
                IconButton(onPressed: () => step == 0 ? Navigator.pop(context) : setState(() => step--), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
                Expanded(child: Text('Inscription', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
              ]),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 10), child: stepper()),
            Padding(padding: const EdgeInsets.fromLTRB(24, 6, 24, 0), child: Align(alignment: Alignment.centerLeft, child: Text('${tr('Étape')} ${step + 1} ${tr('sur')} 3 · ${tr(titles[step])}', style: TextStyle(color: Colors.white.withValues(alpha: .9), fontWeight: FontWeight.w600)))),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 24 + safeBottom(context)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: SoftCard(
                      key: ValueKey(step),
                      padding: const EdgeInsets.all(22),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (step == 0) ...[
                          const IconBadge(Icons.vpn_key_outlined, size: 56),
                          const SizedBox(height: 14),
                          Text("Veuillez saisir le code de sécurité fourni par l'administrateur.", style: TextStyle(color: mutedOf(context), height: 1.4)),
                          const SizedBox(height: 18),
                          TextField(controller: code, textCapitalization: TextCapitalization.characters, textInputAction: TextInputAction.done, onSubmitted: (_) => checkCode(), decoration: InputDecoration(labelText: tr('Code'), prefixIcon: Icon(Icons.key_rounded))),
                          const SizedBox(height: 20),
                          FilledButton(onPressed: busy ? null : checkCode, child: busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Continuer')),
                        ] else if (step == 1) ...[
                          if (building != null) Container(
                            padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(color: kPrimary.withValues(alpha: .09), borderRadius: BorderRadius.circular(16)),
                            child: Row(children: [const IconBadge(Icons.apartment_rounded), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${building!['description'] ?? 'Votre bâtiment'}', style: const TextStyle(fontWeight: FontWeight.w800)), Text('${building!['address'] ?? ''}', style: TextStyle(color: mutedOf(context), fontSize: 13))]))]),
                          ),
                          field('Nom complet *', name, i: Icons.person_outline_rounded),
                          field('E-mail *', email, t: TextInputType.emailAddress, i: Icons.mail_outline_rounded),
                          field('Téléphone', phone, t: TextInputType.phone, i: Icons.phone_outlined),
                          Row(children: [Expanded(child: field("N° d'appartement *", apart)), const SizedBox(width: 12), Expanded(child: field('Étage', floor, t: TextInputType.number))]),
                          const SizedBox(height: 6),
                          FilledButton(onPressed: toPassword, child: const Text('Continuer')),
                        ] else ...[
                          TextField(controller: pass, obscureText: hide, decoration: InputDecoration(labelText: tr('Mot de passe'), prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => hide = !hide)))),
                          const SizedBox(height: 14),
                          TextField(controller: pass2, obscureText: hide, decoration: InputDecoration(labelText: tr('Confirmer le mot de passe'), prefixIcon: Icon(Icons.lock_reset_rounded))),
                          const SizedBox(height: 10),
                          CheckboxListTile(contentPadding: EdgeInsets.zero, value: terms, onChanged: (v) => setState(() => terms = v ?? false), title: const Text("J'accepte les conditions d'utilisation et la politique de confidentialité."), controlAffinity: ListTileControlAffinity.leading),
                          const SizedBox(height: 10),
                          FilledButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text("S'inscrire")),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Locatário ainda não aprovado pela gerência.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key, required this.me, required this.onRefresh});
  final Me me;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) {
    final refused = me.status == 'Refusé';
    return Scaffold(
      body: AuthBackdrop(
        height: 280,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FadeIn(
                child: SoftCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    IconBadge(refused ? Icons.block_rounded : Icons.hourglass_top_rounded, color: refused ? kRed : kAmber, size: 78),
                    const SizedBox(height: 18),
                    Text(refused ? 'Inscription refusée' : 'Inscription en attente', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(refused ? 'Contactez votre gérance pour plus d\'informations.' : 'La gérance doit valider votre compte. Vous pourrez ensuite utiliser toute l\'application.', textAlign: TextAlign.center, style: TextStyle(color: mutedOf(context), height: 1.4)),
                    const SizedBox(height: 24),
                    FilledButton(onPressed: onRefresh, child: const Text('Actualiser')),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => sb.auth.signOut(), child: const Text('Se déconnecter')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gerentes e admins usam o painel web.
class RoleNotice extends StatelessWidget {
  const RoleNotice({super.key, required this.me});
  final Me me;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: AuthBackdrop(
          height: 280,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SoftCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Brand(size: 68),
                    const SizedBox(height: 18),
                    Text("Votre espace ${me.role == 'admin' ? 'administrateur' : 'gérance'} est disponible sur le site web.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text('Connectez-vous depuis un navigateur : ${AppConfig.webPanelUrl}', textAlign: TextAlign.center, style: TextStyle(color: mutedOf(context), height: 1.4)),
                    const SizedBox(height: 22),
                    TextButton(onPressed: () => sb.auth.signOut(), child: const Text('Se déconnecter')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

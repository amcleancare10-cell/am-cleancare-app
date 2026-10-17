import 'package:flutter/material.dart' hide Text;
import 'l10n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'config.dart';

/* ------------------------------ Identidade visual ------------------------------ */
/// Variante de design (compilar com --dart-define=DESIGN=a|b|c). a = Indigo moderno, b = Esmeralda suíço, c = Marinho & ouro.
const String kDesign = String.fromEnvironment('DESIGN', defaultValue: 'a');
const kPrimary = kDesign == 'b' ? Color(0xFF0E9F7E) : kDesign == 'c' ? Color(0xFF1E2A5A) : Color(0xFF4F46E5);
const kViolet = kDesign == 'b' ? Color(0xFF2CC9A8) : kDesign == 'c' ? Color(0xFFC9A24B) : Color(0xFF7A5AF8);
/// Raio dos cartões e botões de cada variante.
const double kCard = kDesign == 'b' ? 28 : kDesign == 'c' ? 14 : 22;
const double kBtn = kDesign == 'b' ? 30 : kDesign == 'c' ? 10 : 16;
const kGreen = Color(0xFF12B76A);
const kAmber = Color(0xFFF79009);
const kRed = Color(0xFFF04438);
const kBlue = Color(0xFF2E90FA);
const kTeal = Color(0xFF0BA5A4);

const kHeroGradient = LinearGradient(
    colors: kDesign == 'b' ? [Color(0xFF087A63), Color(0xFF0E9F7E), Color(0xFF2CC9A8)] : kDesign == 'c' ? [Color(0xFF0F1838), Color(0xFF1E2A5A), Color(0xFF3B4A8C)] : [Color(0xFF3B32C9), Color(0xFF6D4EF0), kViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);
const kScaffoldLight = kDesign == 'b' ? Color(0xFFF1F9F6) : kDesign == 'c' ? Color(0xFFF8F5EF) : Color(0xFFF4F5FB);

/// Espaço da barra de navegação do telemóvel (botões/gestos), para o conteúdo não ficar por baixo dela.
double safeBottom(BuildContext c) => MediaQuery.of(c).viewPadding.bottom;

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color mutedOf(BuildContext c) => Theme.of(c).colorScheme.onSurface.withValues(alpha: .58);
Color lineOf(BuildContext c) => isDark(c) ? const Color(0xFF262B44) : const Color(0xFFE7E9F3);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final cs = ColorScheme.fromSeed(seedColor: kPrimary, brightness: b).copyWith(primary: dark ? const Color(0xFF8E86FF) : kPrimary, surface: dark ? const Color(0xFF171B2E) : Colors.white);
  final base = ThemeData(brightness: b, colorScheme: cs, useMaterial3: true);
  final fontBase = kDesign == 'b' ? GoogleFonts.manropeTextTheme(base.textTheme) : kDesign == 'c' ? GoogleFonts.dmSansTextTheme(base.textTheme) : GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
  var text = fontBase.apply(bodyColor: dark ? const Color(0xFFEEF0FA) : const Color(0xFF161A2B), displayColor: dark ? const Color(0xFFEEF0FA) : const Color(0xFF161A2B));
  if (kDesign == 'c') {
    text = text.copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(textStyle: text.headlineLarge, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.playfairDisplay(textStyle: text.headlineMedium, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.playfairDisplay(textStyle: text.titleLarge, fontWeight: FontWeight.w700),
    );
  }
  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: dark ? const Color(0xFF0E1120) : kScaffoldLight,
    appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: false, titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 21)),
    cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, color: dark ? const Color(0xFF171B2E) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCard), side: BorderSide(color: dark ? const Color(0xFF262B44) : const Color(0xFFE9EBF4)))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: dark ? const Color(0xFF171B2E) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kBtn), borderSide: BorderSide(color: dark ? const Color(0xFF262B44) : const Color(0xFFE0E3F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBtn), borderSide: BorderSide(color: dark ? const Color(0xFF262B44) : const Color(0xFFE0E3F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBtn), borderSide: const BorderSide(color: kPrimary, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBtn)), textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBtn)), side: BorderSide(color: dark ? const Color(0xFF30365A) : const Color(0xFFD9DCEB)), textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: BorderSide(color: dark ? const Color(0xFF30365A) : const Color(0xFFE0E3F0)), labelStyle: text.labelLarge, showCheckmark: false),
    navigationBarTheme: NavigationBarThemeData(height: 68, backgroundColor: dark ? const Color(0xFF171B2E) : Colors.white, indicatorColor: kPrimary.withValues(alpha: .14), labelTextStyle: WidgetStatePropertyAll(text.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10.5))),
    dividerTheme: DividerThemeData(color: dark ? const Color(0xFF262B44) : const Color(0xFFE9EBF4), space: 1),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
  );
}

String fmtDate(dynamic d) => d == null ? '' : DateFormat('dd.MM.yyyy').format(DateTime.parse(d.toString()).toLocal());
String fmtDateTime(dynamic d) => d == null ? '' : DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(d.toString()).toLocal());
String ago(dynamic d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(DateTime.parse(d.toString()).toLocal());
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} j';
  return fmtDate(d);
}

void toast(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? kRed : null));
}

Color statusColor(String? s) => s == 'Fermé' ? kGreen : s == 'En Cours' ? kPrimary : kAmber;

/* ------------------------------ Componentes ------------------------------ */
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String? status;
  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5), decoration: BoxDecoration(color: c.withValues(alpha: .13), borderRadius: BorderRadius.circular(99)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 6), Text(status ?? '—', style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12))]));
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.size = 56, this.light = false, this.logoUrl});
  final double size;
  final bool light;
  final String? logoUrl; // logo da gérance do locatário
  @override
  Widget build(BuildContext context) => (logoUrl != null && logoUrl!.trim().isNotEmpty)
      ? Container(width: size, height: size, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * .32)), padding: EdgeInsets.all(size * .08), child: ClipRRect(borderRadius: BorderRadius.circular(size * .24), child: Image.network(logoUrl!.trim(), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox())))
      : AppConfig.logoAsset.isNotEmpty
      ? Image.asset(AppConfig.logoAsset, height: size)
      : Container(width: size, height: size, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * .32), boxShadow: light ? null : [BoxShadow(color: Colors.black.withValues(alpha: .10), blurRadius: 8)]), padding: EdgeInsets.all(size * .05), child: Image.asset('assets/logo_empresa.png', fit: BoxFit.contain));
}

/// Cartão suave, com toque opcional.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(18), this.gradient, this.margin});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kCard);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient, color: gradient == null ? Theme.of(context).cardTheme.color : null, borderRadius: radius,
        border: gradient == null ? Border.all(color: lineOf(context)) : null,
        boxShadow: [BoxShadow(color: (isDark(context) ? Colors.black : const Color(0xFF3B32C9)).withValues(alpha: isDark(context) ? .25 : .06), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: Material(color: Colors.transparent, borderRadius: radius, child: InkWell(borderRadius: radius, onTap: onTap, child: Padding(padding: padding, child: child))),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color = kPrimary, this.size = 46});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(size * .34)), child: Icon(icon, color: color, size: size * .5));
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
}

/// Aparece suavemente (usado nas listas e nos blocos do início).
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + delay),
        curve: Curves.easeOutCubic,
        builder: (c, v, w) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: w)),
        child: child,
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key, this.icon = Icons.inbox_outlined, this.action, this.onAction});
  final String text;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            IconBadge(icon, size: 74),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: mutedOf(context), height: 1.4)),
            if (action != null) ...[const SizedBox(height: 16), FilledButton(onPressed: onAction, style: FilledButton.styleFrom(minimumSize: const Size(0, 46)), child: Text(action!))],
          ]),
        ),
      );
}

/// Carrega dados assíncronos com estado de carregamento e erro.
class Load<T> extends StatelessWidget {
  const Load({super.key, required this.future, required this.builder});
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          if (s.hasError) return EmptyState('Une erreur est survenue.\n${s.error}', icon: Icons.cloud_off_outlined);
          return builder(c, s.data as T);
        },
      );
}

/// Bolha de mensagem de chat.
class Bubble extends StatelessWidget {
  const Bubble({super.key, required this.text, required this.mine, this.meta, this.child});
  final String text;
  final bool mine;
  final String? meta;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final bg = mine ? null : (isDark(context) ? const Color(0xFF1F2440) : Colors.white);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        decoration: BoxDecoration(
          gradient: mine ? const LinearGradient(colors: [kPrimary, kViolet]) : null, color: bg,
          border: mine ? null : Border.all(color: lineOf(context)),
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(mine ? 20 : 6), bottomRight: Radius.circular(mine ? 6 : 20)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (meta != null) Text(meta!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mine ? Colors.white70 : mutedOf(context))),
          if (meta != null) const SizedBox(height: 3),
          if (text.isNotEmpty) Text(text, style: TextStyle(color: mine ? Colors.white : null, height: 1.38)),
          ?child,
        ]),
      ),
    );
  }
}

/// Barra de escrita de chat.
class ChatInput extends StatelessWidget {
  const ChatInput({super.key, required this.controller, required this.onSend, this.hint = 'Écrire un message', this.leading, this.busy = false});
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;
  final Widget? leading;
  final bool busy;
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, border: Border(top: BorderSide(color: lineOf(context)))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            ?leading,
            Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 5, textInputAction: TextInputAction.send, onSubmitted: (_) => onSend(), decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), fillColor: isDark(context) ? const Color(0xFF1F2440) : const Color(0xFFF1F2F9)))),
            const SizedBox(width: 8),
            Container(decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kPrimary, kViolet])), child: IconButton(onPressed: busy ? null : onSend, icon: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_upward_rounded, color: Colors.white))),
          ]),
        ),
      );
}

/// Título de formulário com estilo único.
class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(2, 18, 2, 8), child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)));
}

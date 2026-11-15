import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models.dart';

/// Quest Friend palette (from the provided color palette screenshot).
class QF {
  static const background = Color(0xFFFFF0F0);
  static const surface = Color(0xFFF2DDC1);
  static const border = Color(0xFFEBD4D4);
  static const primary = Color(0xFF835858);
  static const text = Color(0xFF463333);
  static const textSecondary = Color(0xFF835858);
  static const secondary = Color(0xFF99A799);
  static const tint = Color(0xFFD3E4CD);
  static const highlight = Color(0xFFE2C2B9);

  // Deeper shades sampled from the logo's night-sky circles.
  static const skyMid = Color(0xFF714D4D);
  static const skyDeep = Color(0xFF634545);
}

final TextStyle kDisplay = TextStyle(
  fontFamily: GoogleFonts.fredoka().fontFamily,
  fontWeight: FontWeight.w600,
  color: QF.text,
  height: 1.15,
);

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: QF.primary,
    onPrimary: QF.background,
    secondary: QF.secondary,
    onSecondary: QF.text,
    secondaryContainer: QF.tint,
    onSecondaryContainer: QF.text,
    surface: QF.background,
    onSurface: QF.text,
    outline: QF.border,
    outlineVariant: QF.border,
    error: Color(0xFF9B3B30),
    onError: QF.background,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: GoogleFonts.fredoka().fontFamily,
  );
  return base.copyWith(
    scaffoldBackgroundColor: QF.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: QF.background,
      foregroundColor: QF.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: QF.background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: QF.highlight,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? QF.primary : QF.textSecondary.withAlpha(170),
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? QF.primary : QF.textSecondary,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: QF.primary,
        foregroundColor: QF.background,
        disabledBackgroundColor: QF.border,
        disabledForegroundColor: QF.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: QF.primary,
        side: const BorderSide(color: QF.primary),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: QF.primary),
    ),
    dividerColor: QF.border,
  );
}

InputDecoration qfInput(String hint, {Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: QF.textSecondary),
      filled: true,
      fillColor: QF.surface,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: QF.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: QF.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: QF.primary, width: 1.5),
      ),
    );

// ---------------------------------------------------------------------------
// Visual motif: the guiding star, night-sky dots and rolling hills from the logo
// ---------------------------------------------------------------------------

class StarPainter extends CustomPainter {
  final Color color;
  final Color? core;
  const StarPainter({required this.color, this.core});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;
    final k = r * 0.14;
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    if (core != null) {
      canvas.drawCircle(c, r * 0.16, Paint()..color = core!);
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter old) => old.color != color || old.core != core;
}

class GuidingStar extends StatelessWidget {
  final double size;
  final Color color;
  final Color? core;
  const GuidingStar({super.key, this.size = 24, this.color = QF.surface, this.core = QF.background});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: StarPainter(color: color, core: core),
      );
}

/// Loading indicator: a slowly pulsing guiding star.
class StarLoader extends StatefulWidget {
  final double size;
  final String? label;
  const StarLoader({super.key, this.size = 36, this.label});

  @override
  State<StarLoader> createState() => _StarLoaderState();
}

class _StarLoaderState extends State<StarLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.rotate(
          angle: _c.value * 0.7,
          child: Opacity(
            opacity: 0.5 + 0.5 * _c.value,
            child: GuidingStar(size: widget.size, color: QF.primary, core: QF.background),
          ),
        ),
      ),
      if (widget.label != null) ...[
        const SizedBox(height: 10),
        Text(widget.label!, style: const TextStyle(color: QF.textSecondary)),
      ],
    ]);
  }
}

class SkyDotsPainter extends CustomPainter {
  const SkyDotsPainter();
  static const _dots = [
    [0.12, 0.22, 4.0],
    [0.22, 0.52, 2.5],
    [0.86, 0.18, 2.5],
    [0.92, 0.50, 4.0],
    [0.40, 0.12, 2.0],
    [0.70, 0.08, 2.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = QF.highlight.withAlpha(190);
    for (final d in _dots) {
      canvas.drawCircle(Offset(size.width * d[0], size.height * d[1]), d[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant SkyDotsPainter old) => false;
}

class HillsPainter extends CustomPainter {
  final Color back;
  final Color front;
  const HillsPainter({this.back = QF.secondary, this.front = QF.tint});

  @override
  void paint(Canvas canvas, Size s) {
    final b = Path()
      ..moveTo(0, s.height * 0.55)
      ..cubicTo(s.width * 0.25, s.height * 0.2, s.width * 0.55, s.height * 0.85, s.width, s.height * 0.4)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(b, Paint()..color = back);
    final f = Path()
      ..moveTo(0, s.height * 0.8)
      ..cubicTo(s.width * 0.3, s.height * 0.62, s.width * 0.7, s.height * 0.62, s.width, s.height * 0.84)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(f, Paint()..color = front);
  }

  @override
  bool shouldRepaint(covariant HillsPainter old) => old.back != back || old.front != front;
}

/// The "night sky over rolling hills" scene used on the splash and home hero.
class NightScene extends StatelessWidget {
  final Widget child;
  final double hillHeight;
  final bool showStar;
  const NightScene({super.key, required this.child, this.hillHeight = 70, this.showStar = true});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(child: CustomPaint(painter: SkyDotsPainter())),
      if (showStar)
        Positioned(
          right: -34,
          top: -34,
          child: Container(
            width: 170,
            height: 170,
            decoration: const BoxDecoration(color: QF.skyMid, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(color: QF.skyDeep, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const GuidingStar(size: 72),
            ),
          ),
        ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: hillHeight,
        child: const CustomPaint(painter: HillsPainter()),
      ),
      child,
    ]);
  }
}

class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset('assets/logo.png', width: size, height: size, fit: BoxFit.cover),
      );
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class QCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  const QCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        color: color ?? QF.surface,
        borderRadius: r,
        border: Border.all(color: QF.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text, style: kDisplay.copyWith(fontSize: 20)),
      );
}

class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorCard(this.message, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) => QCard(
        color: QF.highlight,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: QF.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      );
}

class LangPicker extends StatelessWidget {
  final Lang? value;
  final ValueChanged<Lang?> onChanged;
  final bool allowAuto;
  const LangPicker({super.key, required this.value, required this.onChanged, this.allowAuto = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: QF.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QF.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Lang?>(
          value: value,
          isExpanded: true,
          hint: const Text('Detect language'),
          dropdownColor: QF.background,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.expand_more, color: QF.primary),
          items: [
            if (allowAuto) const DropdownMenuItem<Lang?>(value: null, child: Text('Detect language')),
            for (final l in kLanguages)
              DropdownMenuItem<Lang?>(value: l, child: Text(l.name, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Small markdown renderer (headings, bullets, **bold**, *italic*) so the app
/// needs no extra markdown package.
class MarkdownLite extends StatelessWidget {
  final String data;
  final TextStyle? style;
  const MarkdownLite(this.data, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = (style ?? Theme.of(context).textTheme.bodyMedium!).copyWith(height: 1.4, color: style?.color ?? QF.text);
    final blocks = <Widget>[];
    for (final raw in data.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        blocks.add(const SizedBox(height: 6));
        continue;
      }
      final h = RegExp(r'^\s*#{1,4}\s+(.*)$').firstMatch(line);
      if (h != null) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text.rich(_inline(h.group(1)!, base.copyWith(fontWeight: FontWeight.w700, fontSize: (base.fontSize ?? 14) + 2))),
        ));
        continue;
      }
      final b = RegExp(r'^\s*[-*\u2022]\s+(.*)$').firstMatch(line);
      if (b != null) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 2, left: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\u2022  ', style: base),
            Expanded(child: Text.rich(_inline(b.group(1)!, base))),
          ]),
        ));
        continue;
      }
      final n = RegExp(r'^\s*(\d+)[.)]\s+(.*)$').firstMatch(line);
      if (n != null) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 2, left: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${n.group(1)}.  ', style: base),
            Expanded(child: Text.rich(_inline(n.group(2)!, base))),
          ]),
        ));
        continue;
      }
      blocks.add(Text.rich(_inline(line, base)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  TextSpan _inline(String s, TextStyle base) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    var last = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > last) spans.add(TextSpan(text: s.substring(last, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        spans.add(TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      last = m.end;
    }
    if (last < s.length) spans.add(TextSpan(text: s.substring(last)));
    return TextSpan(style: base, children: spans);
  }
}

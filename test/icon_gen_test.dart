import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the brand art as PNGs through the golden pipeline, so the launcher
/// icon and splash logo are generated from code with no external tools.
///
/// Run: flutter test --update-goldens test/icon_gen_test.dart
/// then move test/*.png to assets/icon/ and run
/// `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
///
/// Four files come out:
///  * app_icon.png    – full-bleed 1024² icon (iOS, legacy Android, web).
///  * app_icon_bg.png – adaptive-icon background layer: the cork alone.
///  * app_icon_fg.png – adaptive-icon foreground: the notes, kept inside the
///                      66 % safe zone so every launcher mask leaves them whole.
///  * splash_logo.png – the notes on transparency for the splash screen.
void main() {
  testWidgets('app_icon', skip: true, (tester) async {
    await _paint(tester,
        const _BrandPainter(background: true, notes: true, scale: 1.1),
        'app_icon.png');
  });
  testWidgets('app_icon_bg', skip: true, (tester) async {
    await _paint(tester, const _BrandPainter(background: true, notes: false),
        'app_icon_bg.png');
  });
  testWidgets('app_icon_fg', skip: true, (tester) async {
    await _paint(tester,
        const _BrandPainter(background: false, notes: true, scale: 0.7),
        'app_icon_fg.png');
  });
  testWidgets('splash_logo', skip: true, (tester) async {
    await _paint(tester,
        const _BrandPainter(background: false, notes: true, scale: 0.8),
        'splash_logo.png');
  });
}

Future<void> _paint(
    WidgetTester tester, CustomPainter painter, String file) async {
  // The test surface defaults to 800×600, which would crop the art.
  tester.view.physicalSize = const Size(1024, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      child: SizedBox(
        width: 1024,
        height: 1024,
        child: CustomPaint(painter: painter),
      ),
    ),
  );
  await expectLater(find.byType(CustomPaint), matchesGoldenFile(file));
}

/// Two sticky notes pinned to a cork board — the app in one picture.
///
/// [background] paints the cork; [notes] paints the papers and pin; [scale]
/// shrinks the note composition about the centre (1.0 fills the canvas).
class _BrandPainter extends CustomPainter {
  const _BrandPainter({
    required this.background,
    required this.notes,
    this.scale = 1.0,
  });

  final bool background;
  final bool notes;
  final double scale;

  static const _ink = Color(0xFF3B372F);

  @override
  void paint(Canvas canvas, Size size) {
    if (background) _paintCork(canvas, size);
    if (!notes) return;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    // A mint note peeks out from behind, tilted the other way, so the icon
    // reads as a *wall* of notes rather than a single memo.
    _paintNote(
      canvas,
      center: const Offset(-62, 44),
      side: 500,
      angle: 0.17,
      colors: const [Color(0xFFCDEDE8), Color(0xFFA9D9D1)],
      shadowAlpha: 0.32,
    );
    // The front note: sunny yellow, corner curling up, a few lines written.
    const frontCenter = Offset(26, -10);
    const frontAngle = -0.07;
    _paintNote(
      canvas,
      center: frontCenter,
      side: 540,
      angle: frontAngle,
      colors: const [Color(0xFFFFF59D), Color(0xFFFFD54F)],
      shadowAlpha: 0.46,
      curl: true,
      writing: true,
    );
    // The pin goes through the front note's top edge.
    final topEdge = _rotate(const Offset(0, -270), frontAngle) + frontCenter;
    _paintPin(canvas, topEdge);

    canvas.restore();
  }

  /// Warm cork with a fine speckled grain and a soft vignette.
  void _paintCork(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C7A57), Color(0xFF6E5238)],
        ).createShader(rect),
    );
    // Deterministic grain: two sizes of dark flecks and a few light ones.
    var seed = 0x2545F491;
    double next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    final dark = Paint()..color = const Color(0x2A2A1A0E);
    final light = Paint()..color = const Color(0x22FFE9C8);
    for (var i = 0; i < 1400; i++) {
      final p = Offset(next() * size.width, next() * size.height);
      final r = 1.2 + next() * 3.2;
      canvas.drawCircle(p, r, i % 5 == 0 ? light : dark);
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.78,
          colors: const [Color(0x00000000), Color(0x40000000)],
        ).createShader(rect),
    );
  }

  /// One sheet of paper centred on [center], rotated by [angle].
  void _paintNote(
    Canvas canvas, {
    required Offset center,
    required double side,
    required double angle,
    required List<Color> colors,
    required double shadowAlpha,
    bool curl = false,
    bool writing = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final rect = Rect.fromCenter(center: Offset.zero, width: side, height: side);
    const radius = Radius.circular(16);
    const fold = 96.0;

    var sheet = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
    if (curl) {
      final cut = Path()
        ..moveTo(rect.right, rect.bottom - fold)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right - fold, rect.bottom)
        ..close();
      sheet = Path.combine(PathOperation.difference, sheet, cut);
    }

    // Drop shadow, offset down-right as if lit from the top-left.
    canvas.drawPath(
      sheet.shift(const Offset(10, 22)),
      Paint()
        ..color = Colors.black.withValues(alpha: shadowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawPath(
      sheet,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    if (writing) {
      // Three hand-drawn lines of "text", each a gentle curve.
      final pen = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;
      const lines = [(-150.0, 150.0, -78.0), (-150.0, 90.0, 6.0), (-150.0, 24.0, 90.0)];
      for (final (x0, x1, y) in lines) {
        final path = Path()
          ..moveTo(x0, y + 4)
          ..quadraticBezierTo((x0 + x1) / 2, y - 10, x1, y + 2);
        canvas.drawPath(path, pen);
      }
    }

    if (curl) {
      // The corner folded back over the sheet, with its own small shadow.
      final flap = Path()
        ..moveTo(rect.right, rect.bottom - fold)
        ..lineTo(rect.right - fold, rect.bottom)
        ..lineTo(rect.right - fold, rect.bottom - fold)
        ..close();
      canvas.drawPath(
        flap.shift(const Offset(-6, -8)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawPath(
        flap,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              Color.lerp(colors.last, _ink, 0.30)!,
              Color.lerp(colors.first, _ink, 0.08)!,
            ],
          ).createShader(Rect.fromLTWH(rect.right - fold,
              rect.bottom - fold, fold, fold)),
      );
    }

    canvas.restore();
  }

  /// A glossy red push-pin head.
  void _paintPin(Canvas canvas, Offset c) {
    const r = 50.0;
    canvas.drawCircle(
      c.translate(8, 16),
      r,
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [Color(0xFFFF8A80), Color(0xFFE53935), Color(0xFFB71C1C)],
          stops: [0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Specular highlight.
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(-16, -18), width: 26, height: 18),
      Paint()..color = const Color(0xBBFFFFFF),
    );
  }

  static Offset _rotate(Offset p, double angle) => Offset(
        p.dx * math.cos(angle) - p.dy * math.sin(angle),
        p.dx * math.sin(angle) + p.dy * math.cos(angle),
      );

  @override
  bool shouldRepaint(_BrandPainter old) =>
      old.background != background || old.notes != notes || old.scale != scale;
}

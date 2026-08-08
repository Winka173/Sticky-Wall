import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the launcher icon and splash logo as PNGs via the golden pipeline,
/// so the app's brand art is generated from code with no external tools.
/// Run: flutter test --update-goldens test/icon_gen_test.dart
void main() {
  testWidgets('app_icon', skip: true, (tester) async {
    await _paint(tester, const _IconPainter(background: true), 'app_icon.png');
  });
  testWidgets('splash_logo', skip: true, (tester) async {
    await _paint(tester, const _IconPainter(background: false), 'splash_logo.png');
  });
}

Future<void> _paint(WidgetTester tester, CustomPainter painter, String file) async {
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

class _IconPainter extends CustomPainter {
  const _IconPainter({required this.background});

  final bool background;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (background) {
      // Warm cork-board backdrop.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8A6B4A), Color(0xFF5C4632)],
          ).createShader(rect),
      );
      // A few speckles for cork texture.
      final speck = Paint()..color = const Color(0x22000000);
      for (var i = 0; i < 260; i++) {
        final a = (i * 97) % 1024, b = (i * 173) % 1024;
        canvas.drawCircle(
            Offset(a.toDouble(), b.toDouble()), (i % 3) + 1.0, speck);
      }
    }

    // A yellow sticky note, slightly tilted.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 30);
    canvas.rotate(-0.09);

    const noteSize = 560.0;
    final noteRect = Rect.fromCenter(
      center: Offset.zero,
      width: noteSize,
      height: noteSize,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          noteRect.shift(const Offset(14, 26)), const Radius.circular(24)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(noteRect, const Radius.circular(20)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF176), Color(0xFFFFE04A)],
        ).createShader(noteRect),
    );

    // "Handwriting": a few ink strokes.
    final ink = Paint()
      ..color = const Color(0xFF4A4030)
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = -70.0 + i * 90;
      final wobble = math.sin(i * 1.3) * 14;
      canvas.drawLine(
        Offset(-170, y + wobble),
        Offset(150 - i * 46, y - wobble),
        ink,
      );
    }

    canvas.restore();

    // Red push-pin near the top of the note.
    final pinCenter = Offset(size.width / 2 - 150, size.height / 2 - 214);
    canvas.drawCircle(
      pinCenter.translate(6, 10),
      42,
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      pinCenter,
      40,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFFF8A80), Color(0xFFD32F2F)],
        ).createShader(Rect.fromCircle(center: pinCenter, radius: 40)),
    );
    canvas.drawCircle(pinCenter.translate(-12, -12), 10,
        Paint()..color = const Color(0x88FFFFFF));
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) => false;
}

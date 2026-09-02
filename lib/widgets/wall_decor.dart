import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Procedural grime layer: water rings, drips, paint splatters, smudges and
/// scuffs painted over the wall (under the notes). Deterministic per wall,
/// and kept at very low opacity so writing and notes stay legible.
class WallDecor extends StatelessWidget {
  const WallDecor({super.key, required this.wall});

  final WallStyle wall;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WallDecorPainter(wall),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WallDecorPainter extends CustomPainter {
  _WallDecorPainter(this.wall);

  final WallStyle wall;

  /// Grime reads as chalky dust on dark walls, damp/dirt on light walls.
  Color get _dirt => wall.dark ? Colors.white : const Color(0xFF5D4A33);

  static const _paints = [
    Color(0xFF8C3B3B), // muted red
    Color(0xFF3B5E8C), // muted blue
    Color(0xFFC9A227), // ochre
    Color(0xFF4E7A55), // moss green
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(stableHash(wall.id));
    final count =
        (size.width * size.height / (180 * 180)).round().clamp(10, 70);

    for (var i = 0; i < count; i++) {
      final at = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      switch (rng.nextInt(5)) {
        case 0:
          _waterRing(canvas, rng, at);
        case 1:
          _drip(canvas, rng, at, size);
        case 2:
          _splatter(canvas, rng, at);
        case 3:
          _smudge(canvas, rng, at);
        default:
          _scuff(canvas, rng, at);
      }
    }
  }

  double _alpha(math.Random rng, double min, double max) =>
      min + rng.nextDouble() * (max - min);

  /// Irregular ellipse outline, like a dried water/coffee ring.
  void _waterRing(Canvas canvas, math.Random rng, Offset c) {
    final r = 18.0 + rng.nextDouble() * 30;
    final squash = 0.75 + rng.nextDouble() * 0.25;
    final phase = rng.nextDouble() * math.pi * 2;
    final wobble = 0.05 + rng.nextDouble() * 0.06;

    final path = Path();
    const steps = 28;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * math.pi * 2;
      final radius = r * (1 + wobble * math.sin(3 * t + phase));
      final p = Offset(
        c.dx + radius * math.cos(t),
        c.dy + radius * squash * math.sin(t),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + rng.nextDouble() * 1.8
        ..color = _dirt.withValues(alpha: _alpha(rng, 0.08, 0.14)),
    );
  }

  /// A run of liquid: a wobbly tapering line downward ending in a droplet.
  void _drip(Canvas canvas, math.Random rng, Offset from, Size size) {
    final length = math.min(
      40.0 + rng.nextDouble() * 100,
      size.height - from.dy - 4,
    );
    if (length < 20) return;

    final color = _dirt.withValues(alpha: _alpha(rng, 0.09, 0.15));
    final wobble = 2.0 + rng.nextDouble() * 3;
    final segments = 3;
    var width = 2.2 + rng.nextDouble() * 1.6;
    var start = from;

    for (var i = 0; i < segments; i++) {
      final end = Offset(
        from.dx + math.sin(i * 2.1 + rng.nextDouble()) * wobble,
        from.dy + length * (i + 1) / segments,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      start = end;
      width *= 0.7;
    }

    canvas.drawCircle(start, width * 1.6, Paint()..color = color);
  }

  /// A paint splatter: central blob plus satellite droplets.
  void _splatter(Canvas canvas, math.Random rng, Offset c) {
    // Half the splatters are colored paint, half plain grime.
    final base =
        rng.nextBool() ? _paints[rng.nextInt(_paints.length)] : _dirt;
    final color = base.withValues(alpha: _alpha(rng, 0.14, 0.22));

    canvas.drawCircle(c, 3 + rng.nextDouble() * 4, Paint()..color = color);

    final dots = 8 + rng.nextInt(10);
    for (var i = 0; i < dots; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = 6 + rng.nextDouble() * 34;
      final p = Offset(
        c.dx + math.cos(angle) * dist,
        c.dy + math.sin(angle) * dist,
      );
      canvas.drawCircle(
        p,
        (0.8 + rng.nextDouble() * 2.4) * (1 - dist / 60),
        Paint()..color = color,
      );
    }
  }

  /// A soft dirty patch.
  void _smudge(Canvas canvas, math.Random rng, Offset c) {
    final paint = Paint()
      ..color = _dirt.withValues(alpha: _alpha(rng, 0.05, 0.09))
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        6 + rng.nextDouble() * 8,
      );

    final patches = 3 + rng.nextInt(3);
    for (var i = 0; i < patches; i++) {
      final offset = Offset(
        c.dx + (rng.nextDouble() - 0.5) * 40,
        c.dy + (rng.nextDouble() - 0.5) * 24,
      );
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(rng.nextDouble() * math.pi);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 30 + rng.nextDouble() * 60,
          height: 14 + rng.nextDouble() * 26,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  /// A cluster of short scratch marks.
  void _scuff(Canvas canvas, math.Random rng, Offset c) {
    final color = _dirt.withValues(alpha: _alpha(rng, 0.10, 0.16));
    final strokes = 3 + rng.nextInt(4);
    final baseAngle = rng.nextDouble() * math.pi;

    for (var i = 0; i < strokes; i++) {
      final angle = baseAngle + (rng.nextDouble() - 0.5) * 0.5;
      final len = 10 + rng.nextDouble() * 22;
      final start = Offset(
        c.dx + (rng.nextDouble() - 0.5) * 26,
        c.dy + (rng.nextDouble() - 0.5) * 26,
      );
      canvas.drawLine(
        start,
        start + Offset(math.cos(angle) * len, math.sin(angle) * len),
        Paint()
          ..strokeWidth = 0.8 + rng.nextDouble()
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_WallDecorPainter oldDelegate) =>
      oldDelegate.wall.id != wall.id;
}

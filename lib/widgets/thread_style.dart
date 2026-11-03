import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/note.dart';

/// Draws a thread along [path] in [color] as the given [style]: round yarn
/// with a sheen, twisted twine, a flat ribbon, a dashed cord or a string of
/// beads. The wall's thread painter draws the shadow and knots around it;
/// the thread sheet uses it for its samples.
void paintThreadLine(
  Canvas canvas,
  Path path,
  Color color,
  ThreadStyle style, {
  double alpha = 1,
}) {
  final shade = color.withValues(alpha: color.a * alpha);
  final round = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = shade;
  switch (style) {
    case ThreadStyle.yarn:
      canvas.drawPath(path, round..strokeWidth = 2.2);
      _sheen(canvas, path, 0.7, 0.4 * alpha);
    case ThreadStyle.twine:
      canvas.drawPath(path, round..strokeWidth = 3.4);
      // The twist: short darker strokes slanted across the cord.
      final twist = Paint()
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(shade, const Color(0xFF000000), 0.35)!;
      _along(path, 4.5, (p, u) {
        final n = Offset(-u.dy, u.dx);
        final skew = u * 1.3;
        canvas.drawLine(p - n * 1.5 - skew, p + n * 1.5 + skew, twist);
      });
    case ThreadStyle.ribbon:
      canvas.drawPath(
        path,
        round
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.butt,
      );
      // Darker selvedges and a light fold down the middle.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Color.lerp(shade, const Color(0xFF000000), 0.25)!
          ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 1.2),
      );
      _sheen(canvas, path, 1.2, 0.45 * alpha);
    case ThreadStyle.dashed:
      final dash = round..strokeWidth = 2.4;
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 11) {
          canvas.drawPath(
            metric.extractPath(d, math.min(d + 6.5, metric.length)),
            dash,
          );
        }
      }
    case ThreadStyle.beads:
      // A fine string with round beads strung along it.
      canvas.drawPath(path, Paint.from(round)..strokeWidth = 0.9);
      final bead = Paint()..color = shade;
      final shine = Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.55 * alpha);
      _along(path, 8, (p, _) {
        canvas
          ..drawCircle(p, 3, bead)
          ..drawCircle(p - const Offset(0.9, 0.9), 1, shine);
      });
  }
}

/// The light catching the top of a round cord.
void _sheen(Canvas canvas, Path path, double width, double opacity) {
  canvas
    ..save()
    ..translate(0, -0.6)
    ..drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    )
    ..restore();
}

/// Calls [each] every [step] pixels along [path] with the point and the
/// unit direction of travel there.
void _along(Path path, double step, void Function(Offset, Offset) each) {
  for (final metric in path.computeMetrics()) {
    for (var d = step / 2; d < metric.length; d += step) {
      final t = metric.getTangentForOffset(d);
      if (t != null) each(t.position, t.vector);
    }
  }
}

/// A short length of thread in [style], for picking one in the thread
/// sheet.
class ThreadSample extends StatelessWidget {
  const ThreadSample({super.key, required this.style, required this.color});

  final ThreadStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(56, 22),
      painter: _SamplePainter(style, color),
    );
  }
}

class _SamplePainter extends CustomPainter {
  const _SamplePainter(this.style, this.color);

  final ThreadStyle style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(4, size.height * 0.35)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.95,
        size.width - 4,
        size.height * 0.35,
      );
    paintThreadLine(canvas, path, color, style);
  }

  @override
  bool shouldRepaint(_SamplePainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.color != color;
}

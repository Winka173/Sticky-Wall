import 'package:flutter/material.dart';

/// A pencil eraser, drawn: a tilted block with a band, so the tool reads as
/// "rub out" at a glance (Material has no eraser icon).
class EraserIcon extends StatelessWidget {
  const EraserIcon({super.key, required this.color, this.filled = false});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 22,
    child: CustomPaint(painter: _EraserPainter(color, filled)),
  );
}

class _EraserPainter extends CustomPainter {
  _EraserPainter(this.color, this.filled);

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas
      ..save()
      ..translate(s / 2, s / 2)
      ..rotate(-0.7);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 0.9, height: s * 0.46),
      Radius.circular(s * 0.1),
    );
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    if (filled) {
      canvas.drawRRect(body, Paint()..color = color.withValues(alpha: 0.35));
    }
    canvas
      ..drawRRect(body, line)
      // The band between the rubber and the sleeve.
      ..drawLine(
        Offset(-s * 0.05, -s * 0.23),
        Offset(-s * 0.05, s * 0.23),
        line,
      )
      ..restore()
      // The line it rubs out, under it.
      ..drawLine(
        Offset(s * 0.12, s * 0.95),
        Offset(s * 0.88, s * 0.95),
        line..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_EraserPainter old) =>
      old.color != color || old.filled != filled;
}

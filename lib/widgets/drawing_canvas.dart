import 'package:flutter/material.dart';

import '../models/draw_stroke.dart';
import '../theme.dart';

/// Paints normalized strokes (0..1) scaled to the given canvas size. Shared by
/// the editor and the small thumbnails on note cards.
class StrokePainter extends CustomPainter {
  StrokePainter(this.strokes);

  final List<DrawStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final first = stroke.points.first;
      path.moveTo(first.dx * size.width, first.dy * size.height);
      if (stroke.points.length == 1) {
        // A dot.
        canvas.drawCircle(
          Offset(first.dx * size.width, first.dy * size.height),
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  // Strokes are mutated in place (points appended to strokes.last), so the
  // list identity/length can be unchanged mid-stroke; always repaint.
  bool shouldRepaint(StrokePainter oldDelegate) => true;
}

const _penColors = [
  0xFF3B372F, // ink
  0xFFC62828, // red
  0xFF1565C0, // blue
  0xFF2E7D32, // green
  0xFFF9A825, // amber
  0xFFFFFFFF, // white (for dark paper)
];

/// A freehand drawing surface with a color/size toolbar. Mutates [strokes] in
/// place and calls [onChanged] so the host can persist.
class DrawingEditor extends StatefulWidget {
  const DrawingEditor({
    super.key,
    required this.strokes,
    required this.onChanged,
    this.height = 240,
  });

  final List<DrawStroke> strokes;
  final VoidCallback onChanged;
  final double height;

  @override
  State<DrawingEditor> createState() => _DrawingEditorState();
}

class _DrawingEditorState extends State<DrawingEditor> {
  int _color = _penColors.first;
  double _width = 4;
  Size _size = Size.zero;

  Offset _norm(Offset local) => Size(_size.width, _size.height) == Size.zero
      ? Offset.zero
      : Offset(
          (local.dx / _size.width).clamp(0.0, 1.0),
          (local.dy / _size.height).clamp(0.0, 1.0),
        );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: widget.height,
            width: double.infinity,
            color: const Color(0xFFFFFDF5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _size = constraints.biggest;
                return GestureDetector(
                  onPanStart: (d) {
                    widget.strokes.add(DrawStroke(
                      color: _color,
                      width: _width,
                      points: [_norm(d.localPosition)],
                    ));
                    widget.onChanged();
                    setState(() {});
                  },
                  onPanUpdate: (d) {
                    if (widget.strokes.isEmpty) return;
                    widget.strokes.last.points.add(_norm(d.localPosition));
                    widget.onChanged();
                    setState(() {});
                  },
                  child: CustomPaint(
                    painter: StrokePainter(widget.strokes),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final c in _penColors)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color == c ? AppColors.ink : Colors.black26,
                      width: _color == c ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            IconButton(
              tooltip: 'Undo',
              icon: const Icon(Icons.undo),
              onPressed: widget.strokes.isEmpty
                  ? null
                  : () {
                      widget.strokes.removeLast();
                      widget.onChanged();
                      setState(() {});
                    },
            ),
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_sweep),
              onPressed: widget.strokes.isEmpty
                  ? null
                  : () {
                      widget.strokes.clear();
                      widget.onChanged();
                      setState(() {});
                    },
            ),
          ],
        ),
        Slider(
          value: _width,
          min: 2,
          max: 16,
          onChanged: (v) => setState(() => _width = v),
        ),
      ],
    );
  }
}

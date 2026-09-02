import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/draw_stroke.dart';
import '../theme.dart';

/// Width : height of every drawing surface. Strokes are stored normalized, so
/// the editor and the card thumbnails must share one aspect ratio or a sketch
/// would be squashed when it lands on the wall.
const kDrawingAspect = 1.5;

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
  0xFF6A1B9A, // violet
];

const _penWidths = [2.5, 5.0, 10.0];

/// A freehand drawing surface with a color/size toolbar. Mutates [strokes] in
/// place and calls [onChanged] so the host can persist.
class DrawingEditor extends StatefulWidget {
  const DrawingEditor({
    super.key,
    required this.strokes,
    required this.onChanged,
  });

  final List<DrawStroke> strokes;
  final VoidCallback onChanged;

  @override
  State<DrawingEditor> createState() => _DrawingEditorState();
}

class _DrawingEditorState extends State<DrawingEditor> {
  int _color = _penColors.first;
  double _width = _penWidths[1];
  Size _size = Size.zero;

  // The finger currently drawing; a second finger is ignored so a stray
  // touch doesn't scribble across the stroke in progress.
  int? _pointer;

  Offset _norm(Offset local) => _size == Size.zero
      ? Offset.zero
      : Offset(
          (local.dx / _size.width).clamp(0.0, 1.0),
          (local.dy / _size.height).clamp(0.0, 1.0),
        );

  void _mutate(VoidCallback change) {
    change();
    widget.onChanged();
    setState(() {});
  }

  void _begin(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _mutate(() {
      widget.strokes.add(DrawStroke(
        color: _color,
        width: _width,
        points: [_norm(e.localPosition)],
      ));
    });
  }

  void _extend(PointerMoveEvent e) {
    if (e.pointer != _pointer || widget.strokes.isEmpty) return;
    _mutate(() => widget.strokes.last.points.add(_norm(e.localPosition)));
  }

  void _finish(PointerEvent e) {
    if (e.pointer == _pointer) _pointer = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasStrokes = widget.strokes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.control),
          child: AspectRatio(
            aspectRatio: kDrawingAspect,
            child: Container(
              color: const Color(0xFFFFFDF5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _size = constraints.biggest;
                  // Raw pointer events, not a pan gesture: the ink starts the
                  // instant the finger lands (a pan waits for ~18 px of slop,
                  // which used to swallow the start of every stroke and turn
                  // taps into nothing). The eager recogniser claims the touch
                  // so the enclosing scroll view can't hijack vertical
                  // strokes as a scroll.
                  return RawGestureDetector(
                    gestures: <Type, GestureRecognizerFactory>{
                      EagerGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              EagerGestureRecognizer>(
                        EagerGestureRecognizer.new,
                        (_) {},
                      ),
                    },
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _begin,
                      onPointerMove: _extend,
                      onPointerUp: _finish,
                      onPointerCancel: _finish,
                      child: CustomPaint(
                        painter: StrokePainter(widget.strokes),
                        size: Size.infinite,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // A Wrap, not a Row: on a 320 dp phone the tools don't fit one line.
        Wrap(
          spacing: 2,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final c in _penColors)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: _color == c ? 28 : 22,
                      height: _color == c ? 28 : 22,
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
                ),
              ),
            const SizedBox(width: 10),
            // Three pen sizes, drawn at their real thickness.
            for (final w in _penWidths)
              Tooltip(
                message: l10n.penSize,
                child: InkResponse(
                  radius: 16,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _width = w);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _width == w
                          ? AppColors.ink.withValues(alpha: 0.14)
                          : null,
                    ),
                    child: Container(
                      width: w + 3,
                      height: w + 3,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: l10n.undo,
              visualDensity: VisualDensity.compact,
              color: AppColors.ink,
              icon: const Icon(Icons.undo, size: 21),
              onPressed:
                  hasStrokes ? () => _mutate(widget.strokes.removeLast) : null,
            ),
            IconButton(
              tooltip: l10n.clear,
              visualDensity: VisualDensity.compact,
              color: AppColors.ink,
              icon: const Icon(Icons.delete_sweep_outlined, size: 21),
              onPressed:
                  hasStrokes ? () => _mutate(widget.strokes.clear) : null,
            ),
          ],
        ),
      ],
    );
  }
}

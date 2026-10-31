import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/draw_stroke.dart';
import '../theme.dart';
import 'keyboard_tappable.dart';

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

/// Paints the guide pattern of a [DrawCanvas] — ruled lines, a grid or dots.
/// The spacing is a fraction of the width, so a card thumbnail shows the same
/// paper as the editor, only smaller.
class CanvasPatternPainter extends CustomPainter {
  const CanvasPatternPainter(this.canvas);

  final DrawCanvas canvas;

  /// Guide cells across the canvas.
  static const _columns = 12;

  @override
  void paint(Canvas c, Size size) {
    if (canvas.pattern == CanvasPattern.plain) return;
    final step = size.width / _columns;
    final guide = Paint()
      ..color = canvas.isDark
          ? const Color(0x33FFFFFF)
          : AppColors.ink.withValues(alpha: 0.13)
      ..strokeWidth = 1;

    switch (canvas.pattern) {
      case CanvasPattern.ruled:
        for (var y = step; y < size.height; y += step) {
          c.drawLine(Offset(0, y), Offset(size.width, y), guide);
        }
      case CanvasPattern.grid:
        for (var y = step; y < size.height; y += step) {
          c.drawLine(Offset(0, y), Offset(size.width, y), guide);
        }
        for (var x = step; x < size.width; x += step) {
          c.drawLine(Offset(x, 0), Offset(x, size.height), guide);
        }
      case CanvasPattern.dots:
        // Dots need a little more weight than lines to stay visible.
        final dot = Paint()
          ..color = guide.color.withValues(alpha: guide.color.a * 1.6);
        final r = (size.width / 260).clamp(0.8, 2.0);
        for (var y = step; y < size.height; y += step) {
          for (var x = step; x < size.width; x += step) {
            c.drawCircle(Offset(x, y), r, dot);
          }
        }
      case CanvasPattern.plain:
        break;
    }
  }

  @override
  bool shouldRepaint(CanvasPatternPainter oldDelegate) =>
      oldDelegate.canvas != canvas;
}

/// A drawing as it should look anywhere: its paper tone, the guide pattern and
/// the strokes on top. Used by the editor (with the pointer [child] inside)
/// and by the card thumbnails.
class DrawingSurface extends StatelessWidget {
  const DrawingSurface({
    super.key,
    required this.strokes,
    required this.canvas,
    this.child,
  });

  final List<DrawStroke> strokes;
  final DrawCanvas canvas;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(canvas.color),
      child: CustomPaint(
        painter: CanvasPatternPainter(canvas),
        foregroundPainter: StrokePainter(strokes),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

/// Pen colors. Chalk comes second so it is at hand once the canvas is dark.
const _penColors = [
  0xFF3B372F, // ink
  0xFFFDFBF3, // chalk
  0xFFC62828, // red
  0xFFEF6C00, // orange
  0xFFF9A825, // amber
  0xFF2E7D32, // green
  0xFF1565C0, // blue
  0xFF6A1B9A, // violet
  0xFFD81B60, // pink
];

/// Spoken names for [_penColors], in the same order.
List<String> _penColorNames(AppLocalizations l10n) => [
  l10n.colorInk,
  l10n.colorChalk,
  l10n.colorRed,
  l10n.colorOrange,
  l10n.colorAmber,
  l10n.colorGreen,
  l10n.colorBlue,
  l10n.colorViolet,
  l10n.colorPink,
];

/// Spoken names for [DrawCanvas.tones], in the same order.
List<String> _toneNames(AppLocalizations l10n) => [
  l10n.toneWhite,
  l10n.toneCream,
  l10n.toneBlush,
  l10n.toneSky,
  l10n.toneMint,
  l10n.toneKraft,
  l10n.toneChalkboard,
];

const _penWidths = [2.5, 5.0, 10.0];

/// Height of every tap target in the editor's controls (Material's 48 dp).
/// Rows share their width out evenly, so a row of swatches is one unbroken
/// strip of targets with no dead gaps between them.
const _target = 48.0;

/// The most a row stretches each target, so a wide screen keeps the
/// swatches together instead of spreading them edge to edge.
Widget _evenRow(List<Widget> children) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: children.length * _target),
  child: Row(children: [for (final c in children) Expanded(child: c)]),
);

/// How far (logical px) from the finger a stroke counts as touched by the
/// eraser.
const _eraserReach = 16.0;

/// Undo depth. Snapshots are shallow (stroke references), so this is cheap.
const _historyLimit = 60;

/// What a touch on the canvas does.
enum _Tool { pen, eraser }

/// A freehand drawing surface with pen, eraser, undo / redo, and a panel to
/// pick the canvas paper (tone + guide pattern). Mutates [strokes] in place
/// and calls [onChanged] so the host can persist; canvas changes go through
/// [onCanvasChanged] because [DrawCanvas] is immutable.
class DrawingEditor extends StatefulWidget {
  const DrawingEditor({
    super.key,
    required this.strokes,
    required this.canvas,
    required this.onChanged,
    required this.onCanvasChanged,
  });

  final List<DrawStroke> strokes;
  final DrawCanvas canvas;
  final VoidCallback onChanged;
  final ValueChanged<DrawCanvas> onCanvasChanged;

  @override
  State<DrawingEditor> createState() => _DrawingEditorState();
}

class _DrawingEditorState extends State<DrawingEditor> {
  late int _color = widget.canvas.isDark ? _penColors[1] : _penColors[0];
  double _width = _penWidths[1];
  _Tool _tool = _Tool.pen;
  bool _canvasPanel = false;
  Size _size = Size.zero;

  // Undo / redo as snapshots of the stroke list before each action.
  final _past = <List<DrawStroke>>[];
  final _future = <List<DrawStroke>>[];

  // The finger currently drawing; a second finger is ignored so a stray
  // touch doesn't scribble across the stroke in progress.
  int? _pointer;

  // Whether the erase gesture in progress has removed anything yet; a miss
  // must not leave an empty undo step behind.
  bool _erased = false;

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

  void _snapshot() {
    _past.add(List.of(widget.strokes));
    if (_past.length > _historyLimit) _past.removeAt(0);
    _future.clear();
  }

  void _restore(List<DrawStroke> strokes) => widget.strokes
    ..clear()
    ..addAll(strokes);

  void _undo() {
    if (_past.isEmpty) return;
    _future.add(List.of(widget.strokes));
    _mutate(() => _restore(_past.removeLast()));
  }

  void _redo() {
    if (_future.isEmpty) return;
    _past.add(List.of(widget.strokes));
    _mutate(() => _restore(_future.removeLast()));
  }

  void _clear() {
    _snapshot();
    _mutate(widget.strokes.clear);
  }

  /// Removes every stroke that passes within [_eraserReach] of [local].
  void _eraseAt(Offset local) {
    if (_size == Size.zero) return;
    final before = widget.strokes.length;
    widget.strokes.removeWhere((s) {
      final reach = _eraserReach + s.width / 2;
      for (final p in s.points) {
        final dx = p.dx * _size.width - local.dx;
        final dy = p.dy * _size.height - local.dy;
        if (dx * dx + dy * dy <= reach * reach) return true;
      }
      return false;
    });
    if (widget.strokes.length != before) {
      _erased = true;
      widget.onChanged();
      setState(() {});
    }
  }

  void _begin(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _snapshot();
    switch (_tool) {
      case _Tool.pen:
        _mutate(() {
          widget.strokes.add(
            DrawStroke(
              color: _color,
              width: _width,
              points: [_norm(e.localPosition)],
            ),
          );
        });
      case _Tool.eraser:
        _erased = false;
        _eraseAt(e.localPosition);
    }
  }

  void _extend(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    switch (_tool) {
      case _Tool.pen:
        if (widget.strokes.isEmpty) return;
        _mutate(() => widget.strokes.last.points.add(_norm(e.localPosition)));
      case _Tool.eraser:
        _eraseAt(e.localPosition);
    }
  }

  void _finish(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (_tool == _Tool.eraser && !_erased && _past.isNotEmpty) {
      _past.removeLast();
    }
  }

  void _setCanvas(DrawCanvas canvas) {
    // Ink on a chalkboard (or chalk on paper) would vanish; follow the paper.
    if (canvas.isDark != widget.canvas.isDark) {
      if (canvas.isDark && _color == _penColors[0]) _color = _penColors[1];
      if (!canvas.isDark && _color == _penColors[1]) _color = _penColors[0];
    }
    widget.onCanvasChanged(canvas);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _surface(),
        const SizedBox(height: 8),
        _colorRow(l10n),
        _toolRow(l10n),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _canvasPanel
              ? _CanvasPanel(
                  canvas: widget.canvas,
                  l10n: l10n,
                  onChanged: _setCanvas,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _surface() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.control - 1),
        child: AspectRatio(
          aspectRatio: kDrawingAspect,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _size = constraints.biggest;
              return DrawingSurface(
                strokes: widget.strokes,
                canvas: widget.canvas,
                // Raw pointer events, not a pan gesture: the ink starts the
                // instant the finger lands (a pan waits for ~18 px of slop,
                // which used to swallow the start of every stroke and turn
                // taps into nothing). The eager recogniser claims the touch
                // so the enclosing scroll view can't hijack vertical
                // strokes as a scroll.
                child: RawGestureDetector(
                  gestures: <Type, GestureRecognizerFactory>{
                    EagerGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          EagerGestureRecognizer
                        >(EagerGestureRecognizer.new, (_) {}),
                  },
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _begin,
                    onPointerMove: _extend,
                    onPointerUp: _finish,
                    onPointerCancel: _finish,
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Pen colors; picking one also switches back to the pen.
  Widget _colorRow(AppLocalizations l10n) {
    final names = _penColorNames(l10n);
    return _evenRow([
      for (var i = 0; i < _penColors.length; i++)
        _Swatch(
          color: Color(_penColors[i]),
          label: names[i],
          selected: _tool == _Tool.pen && _color == _penColors[i],
          onTap: () => setState(() {
            _color = _penColors[i];
            _tool = _Tool.pen;
          }),
        ),
    ]);
  }

  /// Pen sizes, eraser, history and the canvas panel toggle.
  Widget _toolRow(AppLocalizations l10n) {
    final hasStrokes = widget.strokes.isNotEmpty;
    final sizeNames = [l10n.penThin, l10n.penMedium, l10n.penThick];
    return _evenRow([
      // Three pen sizes, drawn at their real thickness.
      for (var i = 0; i < _penWidths.length; i++)
        _PenSize(
          width: _penWidths[i],
          label: sizeNames[i],
          selected: _tool == _Tool.pen && _width == _penWidths[i],
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _width = _penWidths[i];
              _tool = _Tool.pen;
            });
          },
        ),
      _ToolButton(
        tooltip: l10n.eraser,
        icon: Icons.auto_fix_normal_outlined,
        activeIcon: Icons.auto_fix_normal,
        active: _tool == _Tool.eraser,
        onPressed: () => setState(
          () => _tool = _tool == _Tool.eraser ? _Tool.pen : _Tool.eraser,
        ),
      ),
      _ToolButton(
        tooltip: l10n.undo,
        icon: Icons.undo,
        onPressed: _past.isNotEmpty ? _undo : null,
      ),
      _ToolButton(
        tooltip: l10n.redo,
        icon: Icons.redo,
        onPressed: _future.isNotEmpty ? _redo : null,
      ),
      _ToolButton(
        tooltip: l10n.clear,
        icon: Icons.delete_sweep_outlined,
        onPressed: hasStrokes ? _clear : null,
      ),
      _ToolButton(
        tooltip: l10n.canvasSection,
        icon: Icons.texture_outlined,
        activeIcon: Icons.texture,
        active: _canvasPanel,
        onPressed: () => setState(() => _canvasPanel = !_canvasPanel),
      ),
    ]);
  }
}

/// One pen size: a dot at the stroke's real thickness, ringed when chosen.
class _PenSize extends StatelessWidget {
  const _PenSize({
    required this.width,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkResponse(
          radius: 22,
          onTap: onTap,
          child: SizedBox(
            height: _target,
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                // Chosen: a tint and an ink ring, so it shows without colour.
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.ink.withValues(alpha: 0.14)
                      : null,
                  border: selected
                      ? Border.all(color: AppColors.ink, width: 1.5)
                      : null,
                ),
                child: Container(
                  width: width + 3,
                  height: width + 3,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paper tone and guide pattern for the canvas, each option previewed as a
/// tiny sheet of that paper.
class _CanvasPanel extends StatelessWidget {
  const _CanvasPanel({
    required this.canvas,
    required this.l10n,
    required this.onChanged,
  });

  final DrawCanvas canvas;
  final AppLocalizations l10n;
  final ValueChanged<DrawCanvas> onChanged;

  String _patternLabel(CanvasPattern p) => switch (p) {
    CanvasPattern.plain => l10n.patternPlain,
    CanvasPattern.ruled => l10n.patternRuled,
    CanvasPattern.grid => l10n.patternGrid,
    CanvasPattern.dots => l10n.patternDots,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.canvasSection,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 4),
          // Guide patterns on one line, paper tones on the next, so neither
          // set breaks mid-row on a narrow sheet.
          Wrap(
            children: [
              for (final p in CanvasPattern.values)
                Tooltip(
                  message: _patternLabel(p),
                  excludeFromSemantics: true,
                  child: Semantics(
                    button: true,
                    selected: canvas.pattern == p,
                    label: _patternLabel(p),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(canvas.copyWith(pattern: p)),
                      // The 40 px sheet sits in a 48 px target.
                      child: SizedBox.square(
                        dimension: _target,
                        child: Center(child: _patternTile(p)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _evenRow([
            for (var i = 0; i < DrawCanvas.tones.length; i++)
              _Swatch(
                color: Color(DrawCanvas.tones[i]),
                label: _toneNames(l10n)[i],
                selected: canvas.color == DrawCanvas.tones[i],
                square: true,
                onTap: () =>
                    onChanged(canvas.copyWith(color: DrawCanvas.tones[i])),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _patternTile(CanvasPattern p) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: canvas.pattern == p ? AppColors.ink : Colors.black26,
          width: canvas.pattern == p ? 2.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: DrawingSurface(
          strokes: const [],
          canvas: canvas.copyWith(pattern: p),
        ),
      ),
    );
  }
}

/// A colour chip: a pen colour (round) or a paper tone (square). The chip
/// keeps its size; the tap target around it is the full [_target] height and
/// whatever width its row gives it.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.square = false,
  });

  final Color color;
  final String label;
  final bool selected;
  final bool square;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KeyboardTappable(
      onActivate: onTap,
      circle: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: _target,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: selected ? 28 : 22,
                height: selected ? 28 : 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: square ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: square ? BorderRadius.circular(5) : null,
                  border: Border.all(
                    color: selected ? AppColors.ink : Colors.black26,
                    width: selected ? 2.5 : 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An icon button for the drawing toolbar. [active] swaps in the filled
/// glyph and a tint, so the state shows by shape as well as by colour; a
/// disabled one stays at 3.5:1 on the paper so it can still be read.
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.activeIcon,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final IconData? activeIcon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      isSelected: active,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.ink,
        disabledForegroundColor: AppColors.ink.withValues(alpha: 0.6),
        backgroundColor: active ? AppColors.ink.withValues(alpha: 0.14) : null,
        minimumSize: const Size(36, _target),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(active ? activeIcon ?? icon : icon, size: 21),
      onPressed: onPressed,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';
import 'note_views.dart';

/// The free-form "wall": notes sit at absolute positions, can be dragged and
/// resized, and the whole board can be pinched to zoom / panned. Tapping empty
/// space creates a note there; double-tapping empty space resets the zoom.
class WallView extends StatefulWidget {
  const WallView({
    super.key,
    required this.notes,
    required this.callbacksFor,
    required this.onMove,
    required this.onResize,
    required this.onBringToFront,
    required this.onCreateAt,
    this.captureKeys,
    this.emptyHint,
    this.resetZoomTooltip = 'Reset zoom',
  });

  final List<Note> notes;
  final NoteCallbacks Function(Note) callbacksFor;
  final void Function(Note note, double x, double y) onMove;
  final void Function(Note note, double scale) onResize;
  final void Function(Note note) onBringToFront;
  final void Function(double x, double y) onCreateAt;
  final Map<String, GlobalKey>? captureKeys;

  /// Shown centered (non-interactive) when there are no notes, so tapping the
  /// wall to create still works.
  final Widget? emptyHint;
  final String resetZoomTooltip;

  @override
  State<WallView> createState() => _WallViewState();
}

class _WallViewState extends State<WallView> {
  static const double _cardWidth = 168;
  static const double _minScale = 0.7;
  static const double _maxScale = 2.4;

  final _tc = TransformationController();

  String? _draggingGuid;
  Offset _dragTopLeft = Offset.zero;

  // Live resize state.
  String? _resizingGuid;
  double _resizeScale = 1;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _tc,
              minScale: 0.6,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(320),
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (d) {
                          // Same basis as display/move (see _positioned).
                          final mw = (w - _cardWidth).clamp(1.0, w);
                          final mh = (h - 80).clamp(1.0, h);
                          final x = (d.localPosition.dx - _cardWidth / 2) / mw;
                          final y = (d.localPosition.dy - 30) / mh;
                          widget.onCreateAt(
                              x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
                        },
                      ),
                    ),
                    if (widget.notes.isEmpty && widget.emptyHint != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(child: widget.emptyHint),
                        ),
                      ),
                    for (final note in widget.notes) _positioned(note, w, h),
                  ],
                ),
              ),
            ),
            // Fixed (un-zoomed) reset-zoom button.
            Positioned(
              top: 4,
              right: 8,
              child: Material(
                color: const Color(0xCC33322C),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: widget.resetZoomTooltip,
                  iconSize: 20,
                  color: Colors.white,
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: () => _tc.value = Matrix4.identity(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _positioned(Note note, double w, double h) {
    final dragging = _draggingGuid == note.guid;
    final scale = _resizingGuid == note.guid ? _resizeScale : note.scale;
    final maxLeft = (w - _cardWidth * scale).clamp(0.0, w);
    final maxTop = (h - 80).clamp(1.0, h);

    final left = dragging ? _dragTopLeft.dx : note.x * maxLeft;
    final top = dragging ? _dragTopLeft.dy : note.y * maxTop;

    return Positioned(
      // Keyed so an in-flight drag follows its note across the bring-to-front
      // reorder instead of rebinding to whatever note lands at this index.
      key: ValueKey(note.guid),
      left: left.clamp(0.0, w),
      top: top.clamp(0.0, (h - 40).clamp(0.0, h)),
      width: _cardWidth * scale,
      child: GestureDetector(
        onPanStart: (_) {
          HapticFeedback.mediumImpact();
          widget.onBringToFront(note);
          setState(() {
            _draggingGuid = note.guid;
            _dragTopLeft = Offset(note.x * maxLeft, note.y * maxTop);
          });
        },
        onPanUpdate: (d) => setState(() => _dragTopLeft += d.delta),
        onPanEnd: (_) {
          final ml = (w - _cardWidth * scale).clamp(1.0, w);
          widget.onMove(note, _dragTopLeft.dx / ml, _dragTopLeft.dy / maxTop);
          setState(() => _draggingGuid = null);
        },
        child: AnimatedScale(
          scale: dragging ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              StickyNoteCard(
                note: note,
                cb: widget.callbacksFor(note),
                raised: dragging,
                maxContentLines: 6,
                captureKey: widget.captureKeys?[note.guid],
                showDelete: false,
              ),
              Positioned(
                right: -6,
                bottom: -6,
                child: _ResizeHandle(
                  onStart: () => setState(() {
                    _resizingGuid = note.guid;
                    _resizeScale = note.scale;
                  }),
                  onDelta: (dx) => setState(() {
                    _resizeScale = (_resizeScale + dx / _cardWidth)
                        .clamp(_minScale, _maxScale);
                  }),
                  onEnd: () {
                    widget.onResize(note, _resizeScale);
                    setState(() => _resizingGuid = null);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onStart,
    required this.onDelta,
    required this.onEnd,
  });

  final VoidCallback onStart;
  final void Function(double dx) onDelta;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onStart(),
      onPanUpdate: (d) => onDelta((d.delta.dx + d.delta.dy) / 2),
      onPanEnd: (_) => onEnd(),
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xCC33322C),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: const Icon(Icons.open_in_full, size: 15, color: Colors.white),
      ),
    );
  }
}

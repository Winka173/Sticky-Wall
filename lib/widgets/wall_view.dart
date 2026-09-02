import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';
import '../theme.dart';
import 'note_views.dart';

/// The free-form "wall": notes sit at absolute positions, can be dragged and
/// resized, and the whole board can be pinched to zoom / panned.
///
/// Gestures on empty wall: long-press sticks a new note right there, a tap
/// deselects the active note, a double-tap resets the zoom.
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
    this.isDimmed,
    this.resetZoomTooltip = 'Reset zoom',
  });

  final List<Note> notes;
  final NoteCallbacks Function(Note) callbacksFor;
  final void Function(Note note, double x, double y) onMove;
  final void Function(Note note, double scale) onResize;
  final void Function(Note note) onBringToFront;
  final void Function(double x, double y) onCreateAt;
  final Map<String, GlobalKey>? captureKeys;

  /// Shown centered when there are no notes. It receives taps itself; the
  /// wall around it still takes the long-press gesture.
  final Widget? emptyHint;

  /// Notes for which this returns true are faded out and not interactive —
  /// how search and the type filter "spotlight" matches on the wall.
  final bool Function(Note note)? isDimmed;

  final String resetZoomTooltip;

  @override
  State<WallView> createState() => _WallViewState();
}

class _WallViewState extends State<WallView>
    with SingleTickerProviderStateMixin {
  static const double _cardWidth = 168;
  static const double _minScale = 0.7;
  static const double _maxScale = 2.4;

  /// Room kept clear at the bottom of the wall so notes never hide under the
  /// floating action button.
  static const double _bottomInset = 80;

  final _tc = TransformationController();
  late final AnimationController _zoomReset = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  Animation<Matrix4>? _zoomAnim;

  String? _draggingGuid;
  Offset _dragTopLeft = Offset.zero;

  // Live resize state.
  String? _resizingGuid;
  double _resizeScale = 1;

  // The note showing its resize handle (last touched); null hides all.
  String? _activeGuid;

  @override
  void initState() {
    super.initState();
    _zoomReset.addListener(() {
      final anim = _zoomAnim;
      if (anim != null) _tc.value = anim.value;
    });
  }

  @override
  void dispose() {
    _zoomReset.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _zoomAnim = Matrix4Tween(begin: _tc.value, end: Matrix4.identity())
        .animate(CurvedAnimation(parent: _zoomReset, curve: Curves.easeOutCubic));
    _zoomReset.forward(from: 0);
  }

  void _setActive(String? guid) {
    if (_activeGuid == guid) return;
    setState(() => _activeGuid = guid);
  }

  // Travel ranges for a note's fractional x/y. Floored at 1 so the maths (and
  // `clamp`, which throws on an inverted range) survive a collapsed wall —
  // e.g. landscape with the keyboard up leaves almost no height.
  static double _rangeX(double w, double scale) =>
      math.max(1.0, w - _cardWidth * scale);
  static double _rangeY(double h) => math.max(1.0, h - _bottomInset);

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
                        onTap: () => _setActive(null),
                        onDoubleTap: _resetZoom,
                        onLongPressStart: (d) {
                          HapticFeedback.mediumImpact();
                          // Same basis as display/move (see _positioned), so
                          // the note lands centered under the finger.
                          final x = (d.localPosition.dx - _cardWidth / 2) /
                              _rangeX(w, 1);
                          final y = (d.localPosition.dy - 40) / _rangeY(h);
                          widget.onCreateAt(
                              x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
                        },
                      ),
                    ),
                    if (widget.notes.isEmpty && widget.emptyHint != null)
                      Positioned.fill(child: Center(child: widget.emptyHint)),
                    for (final (i, note) in widget.notes.indexed)
                      _positioned(note, i, w, h),
                  ],
                ),
              ),
            ),
            // Fixed (un-zoomed) reset button, only while actually zoomed/panned.
            Positioned(
              top: 4,
              right: 8,
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: _tc,
                builder: (context, m, child) {
                  final show = !m.isIdentity();
                  return AnimatedOpacity(
                    opacity: show ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(ignoring: !show, child: child),
                  );
                },
                child: Material(
                  color: AppColors.overlayDark,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: widget.resetZoomTooltip,
                    iconSize: 20,
                    color: Colors.white,
                    icon: const Icon(Icons.center_focus_strong),
                    onPressed: _resetZoom,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _positioned(Note note, int index, double w, double h) {
    final dragging = _draggingGuid == note.guid;
    final resizing = _resizingGuid == note.guid;
    final active = _activeGuid == note.guid;
    final dimmed = widget.isDimmed?.call(note) ?? false;
    final scale = resizing ? _resizeScale : note.scale;
    final maxLeft = _rangeX(w, scale);
    final maxTop = _rangeY(h);

    final left = dragging ? _dragTopLeft.dx : note.x * maxLeft;
    final top = dragging ? _dragTopLeft.dy : note.y * maxTop;

    final base = widget.callbacksFor(note);
    final cb = NoteCallbacks(
      onEdit: () {
        _setActive(note.guid);
        base.onEdit();
      },
      onTogglePin: base.onTogglePin,
      onToggleItem: base.onToggleItem,
      onLongPress: () {
        _setActive(note.guid);
        base.onLongPress();
      },
    );

    return AnimatedPositioned(
      // Keyed so an in-flight drag follows its note across the bring-to-front
      // reorder instead of rebinding to whatever note lands at this index.
      key: ValueKey(note.guid),
      // Instant while the finger is down; on release the note settles into
      // its clamped spot instead of jumping there.
      duration: dragging || resizing
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: left.clamp(0.0, math.max(0.0, w)),
      top: top.clamp(0.0, math.max(0.0, h - 40)),
      width: _cardWidth * scale,
      child: IgnorePointer(
        ignoring: dimmed,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.22 : 1,
          duration: const Duration(milliseconds: 200),
          child: NoteAppear(
            delay: Duration(milliseconds: 25 * math.min(index, 12)),
            child: GestureDetector(
              onPanStart: (_) {
                HapticFeedback.mediumImpact();
                widget.onBringToFront(note);
                setState(() {
                  _draggingGuid = note.guid;
                  _activeGuid = note.guid;
                  _dragTopLeft = Offset(note.x * maxLeft, note.y * maxTop);
                });
              },
              onPanUpdate: (d) => setState(() => _dragTopLeft += d.delta),
              onPanEnd: (_) {
                widget.onMove(note, _dragTopLeft.dx / maxLeft,
                    _dragTopLeft.dy / maxTop);
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
                      cb: cb,
                      raised: dragging,
                      maxContentLines: 6,
                      captureKey: widget.captureKeys?[note.guid],
                    ),
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: _ResizeHandle(
                        visible: active,
                        resizing: resizing,
                        onStart: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _resizingGuid = note.guid;
                            _resizeScale = note.scale;
                          });
                        },
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
          ),
        ),
      ),
    );
  }
}

/// The corner grip for resizing. Hidden until its note is the active one, so
/// the wall reads as paper on texture rather than a field of dark buttons.
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.visible,
    required this.resizing,
    required this.onStart,
    required this.onDelta,
    required this.onEnd,
  });

  final bool visible;
  final bool resizing;
  final VoidCallback onStart;
  final void Function(double dx) onDelta;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final size = resizing ? 30.0 : 26.0;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: GestureDetector(
          onPanStart: (_) => onStart(),
          onPanUpdate: (d) => onDelta((d.delta.dx + d.delta.dy) / 2),
          onPanEnd: (_) => onEnd(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: resizing ? AppColors.ink : AppColors.overlayDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.chalk, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.open_in_full, size: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

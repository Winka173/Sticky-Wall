import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';
import '../theme.dart';
import 'note_views.dart';

/// Where a note should go after "tidy up": fractional position plus size.
typedef Placement = (Note note, double x, double y, double scale);

/// Lets the screen above ask the wall to do things that need its layout
/// (tidying notes into rows) without reaching into its state.
class WallHandle {
  _WallViewState? _state;

  /// Arranges the current board's notes into neat rows, animated. With
  /// [byColor] notes of the same paper color are grouped together; otherwise
  /// they keep their reading order (pinned first, then top-to-bottom).
  void tidy({bool byColor = false}) => _state?._tidy(byColor: byColor);
}

/// The wall's pan/zoom, shared between [WallView] (which drives it) and the
/// full-screen background behind it, so the texture travels with the notes
/// instead of the paper sliding over a wall that stands still.
///
/// [matrix] maps wall coordinates to the wall viewport; [origin] is where
/// that viewport's top-left corner sits on screen, so anything drawn in
/// screen space can apply the same transform about the same point.
class WallCamera extends ChangeNotifier {
  WallCamera() {
    controller.addListener(notifyListeners);
  }

  final controller = TransformationController();
  Offset _origin = Offset.zero;

  Matrix4 get matrix => controller.value;
  Offset get origin => _origin;

  /// True while the wall is zoomed or panned away from its resting place.
  bool get moved => !controller.value.isIdentity();

  void _setOrigin(Offset o) {
    if (o == _origin) return;
    _origin = o;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// The free-form "wall": notes sit at absolute positions, can be dragged and
/// resized, and the whole board can be pinched to zoom / panned. Red threads
/// can be tied between pins by dragging from one pin to another note.
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
    this.links = const [],
    this.onConnect,
    this.onCutLink,
    this.onArrange,
    this.handle,
    this.camera,
    this.selected = const {},
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

  /// Threads to draw (both ends must be in [notes]; others are skipped).
  final List<NoteLink> links;

  /// A thread was dragged from note [a]'s pin onto note [b]. When null, pins
  /// can't be dragged at all.
  final void Function(String a, String b)? onConnect;

  /// A thread was tapped (or a thread was dragged onto a note it already
  /// connects to).
  final void Function(NoteLink link)? onCutLink;

  /// Receives the result of [WallHandle.tidy].
  final void Function(List<Placement> placements)? onArrange;
  final WallHandle? handle;

  /// Pan/zoom state to drive, when the background wants to follow it. Without
  /// one the wall keeps a private controller.
  final WallCamera? camera;

  /// Guids drawn as selected (multi-select mode).
  final Set<String> selected;
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

  /// Height reserved above the paper for the pin (see note_views.dart).
  static const double _pinInset = 14;

  /// Room kept clear at the bottom of the wall so notes never hide under the
  /// floating action button.
  static const double _bottomInset = 80;

  final _wallKey = GlobalKey();

  // The shared camera's controller when we have one, else our own.
  TransformationController? _ownTc;
  TransformationController get _tc =>
      widget.camera?.controller ?? (_ownTc ??= TransformationController());

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

  // A thread being pulled out of a pin: its source and the finger, in wall
  // coordinates.
  String? _threadFrom;
  Offset? _threadTo;
  String? _threadOver;

  // True while notes fly to their tidied spots (slower, smoother move).
  bool _settling = false;

  // A tidy in progress: the (scale, columns) layouts being tried, each
  // rendered offstage for one frame so the cards can be measured at that
  // width (see _tidy). Empty when idle.
  List<(double scale, int cols)> _probes = const [];
  bool _probeByColor = false;
  final _probeKeys = <(double, String), GlobalKey>{};

  // Last layout size, so tidy can do its maths outside build.
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.handle?._state = this;
    _zoomReset.addListener(() {
      final anim = _zoomAnim;
      if (anim != null) _tc.value = anim.value;
    });
    // A shared camera outlives the wall it was zoomed on; a wall that has
    // just appeared (another board) glides back to its resting view. Deferred
    // because the background listens too, and it may already be built.
    if (widget.camera?.moved ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetZoom();
      });
    }
  }

  @override
  void didUpdateWidget(WallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      if (oldWidget.handle?._state == this) oldWidget.handle?._state = null;
      widget.handle?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.handle?._state == this) widget.handle?._state = null;
    _zoomReset.dispose();
    _ownTc?.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _zoomAnim = Matrix4Tween(begin: _tc.value, end: Matrix4.identity())
        .animate(CurvedAnimation(parent: _zoomReset, curve: Curves.easeOutCubic));
    _zoomReset.forward(from: 0);
  }

  /// Tells the camera where the wall viewport sits on screen, so the
  /// background can pivot its copy of the transform about the same point.
  void _reportOrigin() {
    final camera = widget.camera;
    if (camera == null || !mounted) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) {
      camera._setOrigin(box.localToGlobal(Offset.zero));
    }
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

  Offset _topLeftOf(Note note, double w, double h) {
    if (_draggingGuid == note.guid) return _dragTopLeft;
    final scale = _resizingGuid == note.guid ? _resizeScale : note.scale;
    return Offset(note.x * _rangeX(w, scale), note.y * _rangeY(h));
  }

  /// Where a note's pin sits, in wall coordinates.
  Offset _pinOf(Note note, double w, double h) {
    final scale = _resizingGuid == note.guid ? _resizeScale : note.scale;
    final tl = _topLeftOf(note, w, h);
    return tl + Offset(_cardWidth * scale / 2, _pinInset);
  }

  RenderBox? get _wallBox {
    final ro = _wallKey.currentContext?.findRenderObject();
    return ro is RenderBox && ro.hasSize ? ro : null;
  }

  /// Converts a screen position into wall coordinates, seeing through the
  /// InteractiveViewer's zoom and pan.
  Offset _toWall(Offset global) => _wallBox?.globalToLocal(global) ?? global;

  /// The paper's rendered box, when the screen above gave us capture keys.
  RenderBox? _paperBox(Note note) {
    final ro = widget.captureKeys?[note.guid]?.currentContext?.findRenderObject();
    return ro is RenderBox && ro.hasSize && ro.attached ? ro : null;
  }

  /// The top-most note under a screen position, other than [except].
  Note? _noteAt(Offset global, {String? except}) {
    final local = _toWall(global);
    for (final note in widget.notes.reversed) {
      if (note.guid == except) continue;
      if (widget.isDimmed?.call(note) ?? false) continue;
      final box = _paperBox(note);
      if (box != null) {
        final p = box.globalToLocal(global);
        // Generous on top so dropping onto the pin itself counts too.
        if (p.dx >= 0 && p.dx <= box.size.width &&
            p.dy >= -_pinInset * 2 && p.dy <= box.size.height) {
          return note;
        }
        continue;
      }
      final tl = _topLeftOf(note, _size.width, _size.height);
      final rect = Rect.fromLTWH(tl.dx, tl.dy, _cardWidth * note.scale,
          _cardWidth * note.scale * 0.9 + _pinInset);
      if (rect.contains(local)) return note;
    }
    return null;
  }

  // --- Threads -------------------------------------------------------------

  void _threadStart(Note note, Offset global) {
    HapticFeedback.selectionClick();
    setState(() {
      _threadFrom = note.guid;
      _threadTo = _toWall(global);
      _threadOver = null;
      _activeGuid = note.guid;
    });
  }

  void _threadUpdate(Offset global) {
    if (_threadFrom == null) return;
    final over = _noteAt(global, except: _threadFrom)?.guid;
    if (over != _threadOver && over != null) HapticFeedback.selectionClick();
    setState(() {
      _threadTo = _toWall(global);
      _threadOver = over;
    });
  }

  void _threadEnd(Offset global) {
    final from = _threadFrom;
    if (from == null) return;
    final target = global == Offset.zero ? null : _noteAt(global, except: from);
    setState(() {
      _threadFrom = null;
      _threadTo = null;
      _threadOver = null;
    });
    if (target == null) return;
    final existing = widget.links
        .where((l) => l.same(from, target.guid))
        .cast<NoteLink?>()
        .firstOrNull;
    if (existing != null) {
      widget.onCutLink?.call(existing);
    } else {
      HapticFeedback.mediumImpact();
      widget.onConnect?.call(from, target.guid);
    }
  }

  List<_Thread> _threads(double w, double h) {
    final byGuid = {for (final n in widget.notes) n.guid: n};
    final out = <_Thread>[];
    for (final link in widget.links) {
      final a = byGuid[link.a];
      final b = byGuid[link.b];
      if (a == null || b == null) continue;
      final dimmed = (widget.isDimmed?.call(a) ?? false) ||
          (widget.isDimmed?.call(b) ?? false);
      out.add(_Thread(_pinOf(a, w, h), _pinOf(b, w, h), link: link, faded: dimmed));
    }
    final from = _threadFrom == null ? null : byGuid[_threadFrom];
    final to = _threadTo;
    if (from != null && to != null) {
      out.add(_Thread(_pinOf(from, w, h), to, live: true));
    }
    return out;
  }

  void _cutAt(Offset local, double w, double h) {
    _Thread? best;
    var bestD = 14.0;
    for (final t in _threads(w, h)) {
      if (t.link == null) continue;
      final d = t.distanceTo(local);
      if (d < bestD) {
        bestD = d;
        best = t;
      }
    }
    if (best?.link != null) {
      HapticFeedback.lightImpact();
      widget.onCutLink?.call(best!.link!);
    }
  }

  // --- Tidy ----------------------------------------------------------------

  // Air between tidied cards: side by side, between rows (on top of the pin
  // overhang, which is already part of a card's height), and to the wall edge.
  static const double _tidyGap = 12;
  static const double _tidyRowGap = 14;
  static const double _tidyMargin = 8;

  /// Tidying happens in two frames. The text on a card does not scale with
  /// its width, it reflows — a narrower card gets taller, up to the line cap —
  /// so no estimate from the current sizes places rows reliably: guess low and
  /// rows overlap, guess high and they drift apart. Instead every candidate
  /// layout is rendered offstage for one frame and measured, then the rows are
  /// packed with the exact heights in [_finishTidy].
  void _tidy({required bool byColor}) {
    if (widget.notes.isEmpty || widget.onArrange == null) return;
    if (_probes.isNotEmpty) return; // one at a time
    final w = _size.width;
    if (w <= 0 || _size.height <= 0) return;

    // One candidate per column count the wall can hold: the largest scale
    // (never above 1) at which that many cards still fit across. A row that
    // is a hair too wide at the minimum scale is still allowed — rows are
    // centered, so it only eats into the margins.
    final probes = <(double, int)>[];
    for (var cols = 1; cols <= 64; cols++) {
      final fit = (w - 2 * _tidyMargin - (cols - 1) * _tidyGap) /
          (cols * _cardWidth);
      if (fit < _minScale - 0.02) break;
      final s = fit.clamp(_minScale, 1.0);
      // Same scale, more columns: strictly better.
      if (probes.isNotEmpty && probes.last.$1 == s) probes.removeLast();
      probes.add((s, cols));
    }
    if (probes.isEmpty) probes.add((_minScale, 1));

    setState(() {
      _probes = probes;
      _probeByColor = byColor;
      _probeKeys.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishTidy());
  }

  /// Second half of [_tidy]: reads the measured card heights, picks the
  /// largest layout whose rows fit the wall (else the smallest), and hands the
  /// placements up.
  void _finishTidy() {
    final probes = _probes;
    if (!mounted || probes.isEmpty) return;
    final notes = List<Note>.of(widget.notes);
    final w = _size.width;
    final h = _size.height;

    // Reading order first; then, if asked, grouped by paper color.
    notes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final dy = a.y - b.y;
      if (dy.abs() > 0.08) return dy.sign.toInt();
      return a.x.compareTo(b.x);
    });
    if (_probeByColor) {
      int shade(Note n) =>
          AppColors.notePapers.indexOf(noteColor(n.colorIndex, n.guid));
      notes.sort((a, b) => shade(a).compareTo(shade(b)));
    }

    // Measured paper height at a candidate scale, plus the pin overhang and
    // the few px the hand-stuck tilt adds to the bounding box.
    double heightAt(Note n, double s) {
      final ro = _probeKeys[(s, n.guid)]?.currentContext?.findRenderObject();
      final paper = ro is RenderBox && ro.hasSize
          ? ro.size.height
          : _cardWidth * s * 0.9;
      return paper + _pinInset + 6;
    }

    (List<Placement>, double height) layout((double, int) probe) {
      final (s, cols) = probe;
      final cw = _cardWidth * s;
      final left0 = math.max(0.0, (w - cols * cw - (cols - 1) * _tidyGap) / 2);
      final out = <Placement>[];
      var top = 4.0;
      for (var i = 0; i < notes.length; i += cols) {
        final row = notes.sublist(i, math.min(i + cols, notes.length));
        var rowH = 0.0;
        for (final (c, n) in row.indexed) {
          final left = left0 + c * (cw + _tidyGap);
          out.add((n, left / _rangeX(w, s), top / _rangeY(h), s));
          rowH = math.max(rowH, heightAt(n, s));
        }
        top += rowH + _tidyRowGap;
      }
      return (out, top - _tidyRowGap);
    }

    // Candidates run from the largest cards down; take the first that fits.
    final maxH = h - _bottomInset;
    List<Placement>? best;
    for (final probe in probes) {
      final (placements, height) = layout(probe);
      best = placements;
      if (height <= maxH) break;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _probes = const [];
      _probeKeys.clear();
      _settling = true;
      _activeGuid = null;
    });
    widget.onArrange!(best!);
  }

  /// The offstage cards a tidy measures: every note at every candidate scale.
  /// Laid out but never painted or hit; gone again after one frame.
  Widget _tidyProbes() {
    return Offstage(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (s, _) in _probes)
              for (final note in widget.notes)
                SizedBox(
                  width: _cardWidth * s,
                  child: StickyNoteCard(
                    note: note,
                    cb: _noCallbacks,
                    maxContentLines: 6,
                    captureKey:
                        _probeKeys.putIfAbsent((s, note.guid), GlobalKey.new),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
  static const _noCallbacks = NoteCallbacks(
    onEdit: _noop,
    onTogglePin: _noop,
    onToggleItem: _noopIndex,
    onLongPress: _noop,
  );
  static void _noopIndex(int _) {}

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        _size = Size(w, h);
        final threads = _threads(w, h);
        // Our screen position is only known once laid out.
        if (widget.camera != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _reportOrigin());
        }

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _tc,
              minScale: 0.6,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(320),
              // Re-measure right before a gesture, when it matters most.
              onInteractionStart: (_) => _reportOrigin(),
              child: SizedBox(
                key: _wallKey,
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
                        onLongPressStart: (d) =>
                            _createAt(d.localPosition, w, h),
                      ),
                    ),
                    if (widget.notes.isEmpty && widget.emptyHint != null)
                      Positioned.fill(
                        child: GestureDetector(
                          // Claims only the hint itself; the bare wall around
                          // it still reaches the detector above. A Stack stops
                          // at the first child hit, so without this a long
                          // press on the hint text would go nowhere.
                          behavior: HitTestBehavior.deferToChild,
                          onLongPressStart: (d) =>
                              _createAt(d.localPosition, w, h),
                          child: Center(child: widget.emptyHint),
                        ),
                      ),
                    for (final (i, note) in widget.notes.indexed)
                      _positioned(note, i, w, h),
                    // Threads lie over the paper, like real yarn over pins.
                    // The painter only claims taps landing on a thread, so
                    // the notes beneath stay fully interactive.
                    if (threads.isNotEmpty)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTapUp: widget.onCutLink == null
                              ? null
                              : (d) => _cutAt(d.localPosition, w, h),
                          child: CustomPaint(
                            painter: _ThreadPainter(threads,
                                highlight: _threadOver != null),
                          ),
                        ),
                      ),
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
            if (_probes.isNotEmpty) _tidyProbes(),
          ],
        );
      },
    );
  }

  /// Long press on bare wall (wall-local [p]): asks for a new note there.
  void _createAt(Offset p, double w, double h) {
    HapticFeedback.mediumImpact();
    // Same basis as display/move (see _positioned), so the note lands
    // centered under the finger.
    final x = (p.dx - _cardWidth / 2) / _rangeX(w, 1);
    final y = (p.dy - 40) / _rangeY(h);
    widget.onCreateAt(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  Widget _positioned(Note note, int index, double w, double h) {
    final dragging = _draggingGuid == note.guid;
    final resizing = _resizingGuid == note.guid;
    final active = _activeGuid == note.guid;
    final dimmed = widget.isDimmed?.call(note) ?? false;
    final scale = resizing ? _resizeScale : note.scale;
    final maxLeft = _rangeX(w, scale);
    final maxTop = _rangeY(h);
    final threading = _threadFrom != null;
    final over = _threadOver == note.guid;

    final left = dragging ? _dragTopLeft.dx : note.x * maxLeft;
    final top = dragging ? _dragTopLeft.dy : note.y * maxTop;

    final base = widget.callbacksFor(note);
    final canThread = widget.onConnect != null && !dimmed;
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
      onPinDragStart: canThread ? (g) => _threadStart(note, g) : null,
      onPinDragUpdate: canThread ? _threadUpdate : null,
      onPinDragEnd: canThread ? _threadEnd : null,
    );

    return AnimatedPositioned(
      // Keyed so an in-flight drag follows its note across the bring-to-front
      // reorder instead of rebinding to whatever note lands at this index.
      key: ValueKey(note.guid),
      // Instant while the finger is down; on release the note settles into
      // its clamped spot instead of jumping there. Tidying flies slower.
      duration: dragging || resizing
          ? Duration.zero
          : Duration(milliseconds: _settling ? 560 : 200),
      curve: _settling ? Curves.easeInOutCubic : Curves.easeOutCubic,
      onEnd: _settling ? () => setState(() => _settling = false) : null,
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
                // Lifts while dragged; also swells a touch when a thread is
                // hovering over it, to say "drop here".
                scale: dragging ? 1.05 : (over ? 1.04 : 1.0),
                duration: const Duration(milliseconds: 120),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    StickyNoteCard(
                      note: note,
                      cb: cb,
                      raised: dragging || over,
                      selected: widget.selected.contains(note.guid),
                      maxContentLines: 6,
                      captureKey: widget.captureKeys?[note.guid],
                    ),
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: _ResizeHandle(
                        visible: active && !threading,
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

/// One piece of yarn between two points on the wall.
class _Thread {
  const _Thread(this.a, this.b, {this.link, this.live = false, this.faded = false});

  final Offset a;
  final Offset b;
  final NoteLink? link;

  /// Being dragged right now (end follows the finger).
  final bool live;

  /// One end is a dimmed (filtered-out) note.
  final bool faded;

  /// Yarn sags a little between the pins, more the longer it is.
  Offset get control {
    final mid = (a + b) / 2;
    final sag = math.min(30.0, (a - b).distance * 0.12);
    return mid + Offset(0, sag);
  }

  Path get path => Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);

  /// Distance from [p] to the curve, sampled — plenty for a fingertip.
  double distanceTo(Offset p) {
    var best = double.infinity;
    final c = control;
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final q = a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);
      best = math.min(best, (q - p).distance);
    }
    return best;
  }
}

/// Draws the red threads tied between pins, sagging slightly like real
/// string, plus the one currently being dragged out.
class _ThreadPainter extends CustomPainter {
  const _ThreadPainter(this.threads, {this.highlight = false});

  final List<_Thread> threads;
  final bool highlight;

  static const _yarn = Color(0xFFC62828);

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final yarn = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final sheen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x66FFFFFF);

    for (final t in threads) {
      final path = t.path;
      final alpha = t.faded ? 0.3 : (t.live && !highlight ? 0.75 : 1.0);
      canvas.save();
      canvas.translate(1.5, 2.5);
      canvas.drawPath(path, shadow..color = Color.fromRGBO(0, 0, 0, 0.33 * alpha));
      canvas.restore();
      canvas.drawPath(path, yarn..color = _yarn.withValues(alpha: alpha));
      canvas.save();
      canvas.translate(0, -0.6);
      canvas.drawPath(path, sheen..color = Color.fromRGBO(255, 255, 255, 0.4 * alpha));
      canvas.restore();
      // Little knot where the yarn is wound round each pin.
      final knot = Paint()..color = _yarn.withValues(alpha: alpha);
      canvas.drawCircle(t.a, 3.2, knot);
      if (!t.live) canvas.drawCircle(t.b, 3.2, knot);
    }
  }

  @override
  bool hitTest(Offset position) {
    for (final t in threads) {
      if (t.link != null && t.distanceTo(position) <= 14) return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(_ThreadPainter old) =>
      old.highlight != highlight ||
      old.threads.length != threads.length ||
      !_sameEnds(old.threads, threads);

  static bool _sameEnds(List<_Thread> x, List<_Thread> y) {
    for (var i = 0; i < x.length; i++) {
      if (x[i].a != y[i].a || x[i].b != y[i].b || x[i].faded != y[i].faded) {
        return false;
      }
    }
    return true;
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

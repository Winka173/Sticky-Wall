import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';
import '../theme.dart';
import '../util/angles.dart';
import 'note_views.dart';

/// Where a note should go after "tidy up": fractional position plus size.
typedef Placement = (Note note, double x, double y, double scale);

/// Lets the screen above ask the wall to do things that need its layout
/// (tidying notes into rows) without reaching into its state.
class WallHandle {
  _WallViewState? _state;

  /// The wall's most recent layout size, kept after the wall itself is gone
  /// (another layout is showing) so a board export can lay notes out over
  /// the same range. Zero until the wall has been laid out once.
  Size lastSize = Size.zero;

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

/// The free-form "wall": notes sit at absolute positions, can be dragged,
/// resized and turned, and the whole board can be pinched to zoom / panned.
/// Red threads can be tied between pins by dragging from one pin to another
/// note.
///
/// Gestures on a note: one finger drags it; two fingers twist it round and
/// pinch it larger or smaller. Gestures on empty wall: long-press sticks a
/// new note right there, a tap deselects the active note, a double-tap resets
/// the zoom.
class WallView extends StatefulWidget {
  const WallView({
    super.key,
    required this.notes,
    required this.callbacksFor,
    required this.onMove,
    this.onMoveMany,
    required this.onResize,
    this.onRotate,
    required this.onBringToFront,
    required this.onCreateAt,
    this.onTrash,
    this.onLasso,
    this.onDragOver,
    this.onDrop,
    this.lasso = false,
    this.trashLabel = 'Delete',
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
    this.rotateTooltip = 'Rotate',
    this.still = false,
  });

  final List<Note> notes;
  final NoteCallbacks Function(Note) callbacksFor;
  final void Function(Note note, double x, double y) onMove;

  /// A dragged selection landed: every note with its new position, to be
  /// applied as one change. Falls back to [onMove] per note when null.
  final void Function(List<(Note note, double x, double y)> moves)? onMoveMany;
  final void Function(Note note, double scale) onResize;

  /// The note was turned with its rotate handle to [angle] radians (clockwise,
  /// 0 = upright). When null, notes can't be rotated and the handle is hidden.
  final void Function(Note note, double angle)? onRotate;
  final void Function(Note note) onBringToFront;
  final void Function(double x, double y) onCreateAt;

  /// Notes dropped on the trash tray at the bottom of the wall. When null
  /// there is no tray.
  final void Function(List<Note> notes)? onTrash;

  /// In select mode ([lasso]), the notes a loop drawn on empty wall enclosed.
  final void Function(List<Note> notes)? onLasso;

  /// A note is being dragged: the finger's screen position, so the screen
  /// above can light up drop targets outside the wall (board tabs). Null
  /// once the drag is over.
  final void Function(Note note, Offset? global)? onDragOver;

  /// A dragged note (or selection) was let go at [global]. Return true to
  /// take it — it was dropped on a tab — and the wall leaves its position
  /// alone (the note is on another board now).
  final bool Function(List<Note> notes, Offset global)? onDrop;

  /// Select mode: a finger drawn round notes on empty wall selects them
  /// (see [onLasso]), and dragging a selected note takes the selection along.
  final bool lasso;

  /// Label on the trash tray.
  final String trashLabel;

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
  final String rotateTooltip;

  /// A still render of the board (the export): complete on its first frame
  /// with no entrance animation, no grips, and cards turned near the edge
  /// left to overhang rather than clipped.
  final bool still;

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
  // The finger's own idea of the top-left, before snapping to a guide, and
  // where the card was when the drag began (the selection follows by the
  // same distance).
  Offset _dragRaw = Offset.zero;
  Offset _dragStart = Offset.zero;
  // Last finger position on screen, for the tray and the tabs above.
  Offset? _dragGlobal;
  bool _overTray = false;
  final _trayKey = GlobalKey();

  // Alignment guides the dragged card has snapped to, in wall coordinates.
  double? _guideX;
  double? _guideY;
  static const double _snapReach = 6;

  // The rest of a dragged selection (guids), moving by _groupDelta.
  Set<String> _groupGuids = const {};
  Offset _groupDelta = Offset.zero;

  // The loop being drawn in select mode, in wall coordinates.
  List<Offset>? _lasso;

  // The note the camera was last pointed at by a double tap.
  String? _focusedGuid;
  // Where the finger last was, in wall coordinates. Drag distance is measured
  // there rather than from the gesture's local delta, because the detector
  // sits inside the note's rotation and would otherwise report it turned.
  Offset _dragFinger = Offset.zero;

  // Live resize state.
  String? _resizingGuid;
  double _resizeScale = 1;

  // Live rotate state: the note being turned, its current angle, its pivot in
  // wall coordinates, the finger's bearing from that pivot when the grip was
  // taken and the note's angle at that moment. The note follows the finger
  // around its centre; near a quarter turn it clicks into place.
  String? _rotatingGuid;
  double _rotateAngle = 0;
  Offset _rotateCenter = Offset.zero;
  double _rotateGrip = 0;
  double _rotateBase = 0;
  bool _rotateSnapped = false;

  // Two fingers on a note: its turn follows the twist and its size the pinch
  // (see _noteUpdate). A twist only takes hold past a few degrees so a plain
  // pinch does not wobble the card, and a pinch only counts past a few
  // percent so a twist does not creep in size. [_pinchGuid] is the note the
  // two fingers are on; [_pinchRatio] its paper's height over its width, so
  // it can grow about its centre rather than from its corner.
  static const double _twistSlop = 0.04;
  static const double _pinchSlop = 0.04;
  String? _pinchGuid;
  bool _twisting = false;
  double _pinchBase = 1;
  double _pinchRatio = 0.9;

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
    _focusedGuid = null;
    _animateCamera(Matrix4.identity());
  }

  void _animateCamera(Matrix4 to) {
    _zoomAnim = Matrix4Tween(
      begin: _tc.value,
      end: to,
    ).animate(CurvedAnimation(parent: _zoomReset, curve: Curves.easeOutCubic));
    _zoomReset.forward(from: 0);
  }

  /// Double tap on a note: glides the camera in to frame it; a second double
  /// tap on the same note (or the reset button) glides back out.
  void _focusOn(Note note) {
    if (_focusedGuid == note.guid && !_tc.value.isIdentity()) {
      _resetZoom();
      return;
    }
    final w = _size.width;
    final h = _size.height;
    if (w <= 0 || h <= 0) return;
    final box = _boxOf(note, w, h);
    final zoom = math
        .min(w / (box.width + 48), h / (box.height + 48))
        .clamp(1.2, 2.4);
    final c = box.center;
    final to = Matrix4.identity()
      ..translateByDouble(w / 2 - zoom * c.dx, h / 2 - zoom * c.dy, 0, 1)
      ..scaleByDouble(zoom, zoom, 1, 1);
    HapticFeedback.selectionClick();
    _focusedGuid = note.guid;
    _setActive(note.guid);
    _animateCamera(to);
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
    final base = Offset(note.x * _rangeX(w, scale), note.y * _rangeY(h));
    return _groupGuids.contains(note.guid) ? base + _groupDelta : base;
  }

  /// The card's footprint on the wall (paper plus pin inset), upright.
  Rect _boxOf(Note note, double w, double h) {
    final scale = _resizingGuid == note.guid ? _resizeScale : note.scale;
    final width = _cardWidth * scale;
    final tl = _topLeftOf(note, w, h);
    return Rect.fromLTWH(
      tl.dx,
      tl.dy,
      width,
      _paperHeight(note, width) + _pinInset,
    );
  }

  /// The angle a note is drawn at right now, in radians.
  double _angleOf(Note note) =>
      _rotatingGuid == note.guid ? _rotateAngle : noteAngle(note);

  /// The paper's height, from its rendered box when we have one, else the
  /// usual proportion of a sheet.
  double _paperHeight(Note note, double width) =>
      _paperBox(note)?.size.height ?? width * 0.9;

  /// The point a note turns about, in wall coordinates: the centre of the
  /// card including the pin's inset (what `NoteTurn` rotates).
  Offset _centerOf(Note note, double w, double h) {
    final scale = _resizingGuid == note.guid ? _resizeScale : note.scale;
    final width = _cardWidth * scale;
    return _topLeftOf(note, w, h) +
        Offset(width / 2, (_paperHeight(note, width) + _pinInset) / 2);
  }

  /// Where a note's pin sits, in wall coordinates — turned about the card's
  /// centre along with the paper, so threads stay tied to the pin.
  Offset _pinOf(Note note, double w, double h) {
    final scale = _resizingGuid == note.guid ? _resizeScale : note.scale;
    final tl = _topLeftOf(note, w, h);
    final width = _cardWidth * scale;
    final angle = _angleOf(note);
    if (angle == 0) return tl + Offset(width / 2, _pinInset);
    final center = _centerOf(note, w, h);
    final reach = (_paperHeight(note, width) - _pinInset) / 2;
    return center + Offset(reach * math.sin(angle), -reach * math.cos(angle));
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
    final ro = widget.captureKeys?[note.guid]?.currentContext
        ?.findRenderObject();
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
        if (p.dx >= 0 &&
            p.dx <= box.size.width &&
            p.dy >= -_pinInset * 2 &&
            p.dy <= box.size.height) {
          return note;
        }
        continue;
      }
      final tl = _topLeftOf(note, _size.width, _size.height);
      final rect = Rect.fromLTWH(
        tl.dx,
        tl.dy,
        _cardWidth * note.scale,
        _cardWidth * note.scale * 0.9 + _pinInset,
      );
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
      final dimmed =
          (widget.isDimmed?.call(a) ?? false) ||
          (widget.isDimmed?.call(b) ?? false);
      out.add(
        _Thread(_pinOf(a, w, h), _pinOf(b, w, h), link: link, faded: dimmed),
      );
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
      final fit =
          (w - 2 * _tidyMargin - (cols - 1) * _tidyGap) / (cols * _cardWidth);
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
                    captureKey: _probeKeys.putIfAbsent((
                      s,
                      note.guid,
                    ), GlobalKey.new),
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
        widget.handle?.lastSize = _size;
        final threads = _threads(w, h);
        // Our screen position is only known once laid out.
        if (widget.camera != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _reportOrigin());
        }

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _tc,
              clipBehavior: widget.still ? Clip.none : Clip.hardEdge,
              minScale: 0.6,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(320),
              // Re-measure right before a gesture, when it matters most.
              onInteractionStart: (_) {
                _focusedGuid = null;
                _reportOrigin();
              },
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
                        // In select mode a finger on bare wall draws a lasso
                        // (the wall itself pans with two fingers meanwhile).
                        onPanStart: widget.lasso
                            ? (d) => setState(() => _lasso = [d.localPosition])
                            : null,
                        onPanUpdate: widget.lasso
                            ? (d) =>
                                  setState(() => _lasso?.add(d.localPosition))
                            : null,
                        onPanEnd: widget.lasso ? (_) => _finishLasso() : null,
                        onPanCancel: widget.lasso
                            ? () => setState(() => _lasso = null)
                            : null,
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
                    if (_guideX != null || _guideY != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _GuidePainter(x: _guideX, y: _guideY),
                          ),
                        ),
                      ),
                    if (_lasso != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _LassoPainter(_lasso!)),
                        ),
                      ),
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
                            painter: _ThreadPainter(
                              threads,
                              highlight: _threadOver != null,
                            ),
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
            // Drop a dragged note here to delete it. Slides up while a drag
            // is under way; leaves room for the add button on the right.
            if (widget.onTrash != null && !widget.still)
              Positioned(
                left: 16,
                right: 92,
                bottom: 12,
                child: _DropTray(
                  key: _trayKey,
                  shown: _draggingGuid != null && _pinchGuid == null,
                  armed: _overTray,
                  label: widget.trashLabel,
                ),
              ),
            if (_probes.isNotEmpty) _tidyProbes(),
          ],
        );
      },
    );
  }

  // --- Lasso -----------------------------------------------------------

  void _finishLasso() {
    final loop = _lasso;
    setState(() => _lasso = null);
    if (loop == null || loop.length < 3) return;
    final w = _size.width;
    final h = _size.height;
    final caught = [
      for (final note in widget.notes)
        if (!(widget.isDimmed?.call(note) ?? false) &&
            _inside(loop, _boxOf(note, w, h).center))
          note,
    ];
    if (caught.isEmpty) return;
    HapticFeedback.selectionClick();
    widget.onLasso?.call(caught);
  }

  /// Whether [p] lies inside the polygon [loop] (even-odd rule).
  static bool _inside(List<Offset> loop, Offset p) {
    var inside = false;
    for (var i = 0, j = loop.length - 1; i < loop.length; j = i++) {
      final a = loop[i];
      final b = loop[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  // --- Snapping ---------------------------------------------------------

  /// Nudges a dragged card onto the nearest alignment within reach — an
  /// edge or centre line of a neighbour, or the wall's centre line — and
  /// records the guide(s) to draw. Returns the snapped top-left.
  Offset _snap(Note note, Offset raw) {
    final w = _size.width;
    final h = _size.height;
    final scale = _resizingGuid == note.guid ? _resizeScale : note.scale;
    final width = _cardWidth * scale;
    final height = _paperHeight(note, width) + _pinInset;
    final xs = [raw.dx, raw.dx + width / 2, raw.dx + width];
    final ys = [raw.dy, raw.dy + height / 2, raw.dy + height];
    double? dx;
    double? dy;
    double? gx;
    double? gy;
    void tryX(double target) {
      for (final x in xs) {
        final d = target - x;
        if (d.abs() <= _snapReach && (dx == null || d.abs() < dx!.abs())) {
          dx = d;
          gx = target;
        }
      }
    }

    void tryY(double target) {
      for (final y in ys) {
        final d = target - y;
        if (d.abs() <= _snapReach && (dy == null || d.abs() < dy!.abs())) {
          dy = d;
          gy = target;
        }
      }
    }

    tryX(w / 2);
    for (final other in widget.notes) {
      if (other.guid == note.guid || _groupGuids.contains(other.guid)) continue;
      if (widget.isDimmed?.call(other) ?? false) continue;
      final box = _boxOf(other, w, h);
      tryX(box.left);
      tryX(box.center.dx);
      tryX(box.right);
      tryY(box.top);
      tryY(box.center.dy);
      tryY(box.bottom);
    }
    if ((gx != null && gx != _guideX) || (gy != null && gy != _guideY)) {
      HapticFeedback.selectionClick();
    }
    _guideX = gx;
    _guideY = gy;
    return raw + Offset(dx ?? 0, dy ?? 0);
  }

  bool _hitTray(Offset global) {
    final ro = _trayKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return false;
    final p = ro.globalToLocal(global);
    return p.dx >= 0 &&
        p.dy >= 0 &&
        p.dx <= ro.size.width &&
        p.dy <= ro.size.height;
  }

  // --- One or two fingers on a note ------------------------------------

  /// The finger(s) landed, or their number changed (the recognizer ends and
  /// restarts the gesture then, see _noteEnd). One finger begins a drag; a
  /// second one starts a twist / pinch from the note's current turn and size.
  void _noteStart(Note note, ScaleStartDetails d) {
    if (d.pointerCount == 1) HapticFeedback.mediumImpact();
    widget.onBringToFront(note);
    final scale = note.scale;
    final w = _size.width;
    final h = _size.height;
    setState(() {
      _draggingGuid = note.guid;
      _activeGuid = note.guid;
      _dragStart = Offset(note.x * _rangeX(w, scale), note.y * _rangeY(h));
      _dragTopLeft = _dragRaw = _dragStart;
      _dragFinger = _toWall(d.focalPoint);
      _dragGlobal = d.focalPoint;
      _guideX = _guideY = null;
      _overTray = false;
      // In select mode a selected note takes the rest of the selection along.
      _groupGuids = widget.lasso && widget.selected.contains(note.guid)
          ? {
              for (final n in widget.notes)
                if (n.guid != note.guid && widget.selected.contains(n.guid))
                  n.guid,
            }
          : const {};
      _groupDelta = Offset.zero;
      if (d.pointerCount < 2) return;
      final width = _cardWidth * scale;
      _pinchGuid = note.guid;
      _pinchBase = scale;
      _pinchRatio = _paperHeight(note, width) / width;
      _twisting = false;
      _resizingGuid = note.guid;
      _resizeScale = scale;
      if (widget.onRotate != null) {
        _rotatingGuid = note.guid;
        _rotateBase = noteAngle(note);
        _rotateAngle = _rotateBase;
        _rotateSnapped = false;
      }
    });
  }

  void _noteUpdate(Note note, ScaleUpdateDetails d) {
    if (_draggingGuid != note.guid) return;
    final finger = _toWall(d.focalPoint);
    setState(() {
      _dragRaw += finger - _dragFinger;
      _dragFinger = finger;
      _dragGlobal = d.focalPoint;
      if (d.pointerCount < 2 || _pinchGuid != note.guid) {
        // One finger: the card snaps to its neighbours, the selection comes
        // along, and the tray / tabs learn where the finger is.
        _dragTopLeft = _snap(note, _dragRaw);
        _groupDelta = _dragTopLeft - _dragStart;
        final over = widget.onTrash != null && _hitTray(d.focalPoint);
        if (over != _overTray) HapticFeedback.selectionClick();
        _overTray = over;
        widget.onDragOver?.call(note, d.focalPoint);
        return;
      }
      _guideX = _guideY = null;
      _overTray = false;

      if (_rotatingGuid == note.guid) {
        if (!_twisting && d.rotation.abs() > _twistSlop) _twisting = true;
        if (_twisting) {
          final free = normalizeAngle(_rotateBase + d.rotation);
          final angle = snapQuarterTurns(free);
          final snapped = angle != free;
          if (snapped && !_rotateSnapped) HapticFeedback.selectionClick();
          _rotateAngle = angle;
          _rotateSnapped = snapped;
        }
      }

      // Past the dead band the size follows the pinch continuously (no jump
      // as it takes hold).
      final s = d.scale;
      final factor = s > 1 + _pinchSlop
          ? s / (1 + _pinchSlop)
          : s < 1 - _pinchSlop
          ? s / (1 - _pinchSlop)
          : 1.0;
      final next = (_pinchBase * factor).clamp(_minScale, _maxScale);
      // Grow about the centre, so the card swells under the fingers rather
      // than away from its top-left corner.
      final grow = (next - _resizeScale) * _cardWidth;
      _dragRaw -= Offset(grow / 2, grow * _pinchRatio / 2);
      _dragTopLeft = _dragRaw;
      _resizeScale = next;
    });
  }

  /// Commits whatever the fingers changed. Also called when a finger is
  /// added or lifted mid-gesture ([d] still counts pointers then); the
  /// restart that follows picks the note up again from these committed
  /// values, so nothing jumps. Only a real release can drop the note on the
  /// tray or a tab.
  void _noteEnd(Note note, ScaleEndDetails d) {
    if (_draggingGuid != note.guid) return;
    final pinching = _pinchGuid == note.guid;
    final scale = pinching ? _resizeScale : note.scale;
    final w = _size.width;
    final h = _size.height;
    final byGuid = {for (final n in widget.notes) n.guid: n};
    final group = [
      note,
      for (final g in _groupGuids)
        if (byGuid[g] != null) byGuid[g]!,
    ];
    final released = d.pointerCount == 0;
    final global = _dragGlobal;

    var taken = false;
    if (released && !pinching && global != null) {
      if (_overTray && widget.onTrash != null) {
        HapticFeedback.mediumImpact();
        widget.onTrash!(group);
        taken = true;
      } else if (widget.onDrop?.call(group, global) ?? false) {
        taken = true;
      }
    }
    if (!taken) {
      final moves = [
        for (final n in group)
          (
            n,
            _topLeftOf(n, w, h).dx / _rangeX(w, n == note ? scale : n.scale),
            _topLeftOf(n, w, h).dy / _rangeY(h),
          ),
      ];
      if (moves.length > 1 && widget.onMoveMany != null) {
        widget.onMoveMany!(moves);
      } else {
        for (final (n, x, y) in moves) {
          widget.onMove(n, x, y);
        }
      }
      if (pinching && _twisting) widget.onRotate?.call(note, _rotateAngle);
      if (pinching && scale != note.scale) widget.onResize(note, scale);
    }
    if (released) widget.onDragOver?.call(note, null);
    setState(() {
      _draggingGuid = null;
      _groupGuids = const {};
      _groupDelta = Offset.zero;
      _guideX = _guideY = null;
      _overTray = false;
      _dragGlobal = null;
      if (pinching) {
        _pinchGuid = null;
        _twisting = false;
        _resizingGuid = null;
        _rotatingGuid = null;
      }
    });
  }

  /// The staggered entrance, unless this wall is a still render.
  Widget _appear(int index, Widget child) => widget.still
      ? child
      : NoteAppear(
          delay: Duration(milliseconds: 25 * math.min(index, 12)),
          child: child,
        );

  // --- The rotate grip --------------------------------------------------

  double _bearing(Offset finger) =>
      math.atan2(finger.dy - _rotateCenter.dy, finger.dx - _rotateCenter.dx);

  void _rotateStart(Note note, Offset global, double w, double h) {
    HapticFeedback.selectionClick();
    final center = _centerOf(note, w, h);
    setState(() {
      _rotatingGuid = note.guid;
      _activeGuid = note.guid;
      _rotateCenter = center;
      _rotateBase = noteAngle(note);
      _rotateAngle = _rotateBase;
      _rotateGrip = _bearing(_toWall(global));
      _rotateSnapped = false;
    });
  }

  void _rotateUpdate(Offset global) {
    if (_rotatingGuid == null) return;
    final turned = _bearing(_toWall(global)) - _rotateGrip;
    final free = normalizeAngle(_rotateBase + turned);
    final angle = snapQuarterTurns(free);
    final snapped = angle != free;
    if (snapped && !_rotateSnapped) HapticFeedback.selectionClick();
    setState(() {
      _rotateAngle = angle;
      _rotateSnapped = snapped;
    });
  }

  void _rotateEnd(Note note) {
    if (_rotatingGuid != note.guid) return;
    widget.onRotate?.call(note, _rotateAngle);
    setState(() => _rotatingGuid = null);
  }

  /// A tap on the rotate handle squares the note up.
  void _straighten(Note note) {
    HapticFeedback.selectionClick();
    widget.onRotate?.call(note, 0);
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
    final rotating = _rotatingGuid == note.guid;
    final active = _activeGuid == note.guid;
    final dimmed = widget.isDimmed?.call(note) ?? false;
    final scale = resizing ? _resizeScale : note.scale;
    final threading = _threadFrom != null;
    final over = _threadOver == note.guid;

    final grouped = _groupGuids.contains(note.guid);
    final tl = _topLeftOf(note, w, h);
    final left = tl.dx;
    final top = tl.dy;

    final base = widget.callbacksFor(note);
    final canThread = widget.onConnect != null && !dimmed;
    final grips = active && !threading && !widget.still;
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
      // Not in select mode: there a tap must toggle at once, not wait to
      // see whether a second one follows.
      onDoubleTap: widget.still || widget.lasso ? null : () => _focusOn(note),
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
      duration: dragging || resizing || grouped
          ? Duration.zero
          : Duration(milliseconds: _settling ? 560 : 200),
      curve: _settling ? Curves.easeInOutCubic : Curves.easeOutCubic,
      onEnd: _settling ? () => setState(() => _settling = false) : null,
      left: left.clamp(0.0, math.max(0.0, w)),
      top: top.clamp(0.0, math.max(0.0, h - 40)),
      width: _cardWidth * scale,
      // The turn is outermost so a card lying at an angle is hit-testable
      // wherever it is painted, not only inside its upright footprint; the
      // gestures below therefore measure in wall coordinates, not local ones.
      child: NoteTurn(
        angle: _angleOf(note),
        live: rotating,
        child: IgnorePointer(
          ignoring: dimmed,
          child: AnimatedOpacity(
            opacity: dimmed ? 0.22 : 1,
            duration: const Duration(milliseconds: 200),
            child: _appear(
              index,
              RawGestureDetector(
                gestures: {
                  _NoteGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        _NoteGestureRecognizer
                      >(_NoteGestureRecognizer.new, (r) {
                        // RawGestureDetector leaves the device's slop to
                        // us; without it the wall's pan (which has it) wins.
                        r.gestureSettings = MediaQuery.maybeGestureSettingsOf(
                          context,
                        );
                        r.onStart = (d) => _noteStart(note, d);
                        r.onUpdate = (d) => _noteUpdate(note, d);
                        r.onEnd = (d) => _noteEnd(note, d);
                      }),
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
                        rotated: false,
                      ),
                      if (!widget.still)
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: _Grip(
                            visible: grips,
                            engaged: resizing,
                            icon: Icons.open_in_full,
                            onPanStart: (_) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _resizingGuid = note.guid;
                                _resizeScale = note.scale;
                              });
                            },
                            // The grip's local delta is in the card's own
                            // frame, so "away from the centre" grows the note
                            // whichever way it is turned.
                            onPanUpdate: (d) => setState(() {
                              final dx = (d.delta.dx + d.delta.dy) / 2;
                              _resizeScale = (_resizeScale + dx / _cardWidth)
                                  .clamp(_minScale, _maxScale);
                            }),
                            onPanEnd: () {
                              widget.onResize(note, _resizeScale);
                              setState(() => _resizingGuid = null);
                            },
                          ),
                        ),
                      if (!widget.still && widget.onRotate != null)
                        Positioned(
                          left: -8,
                          bottom: -8,
                          child: _Grip(
                            visible: grips,
                            engaged: rotating,
                            icon: Icons.rotate_right,
                            tooltip: widget.rotateTooltip,
                            onPanStart: (d) =>
                                _rotateStart(note, d.globalPosition, w, h),
                            onPanUpdate: (d) => _rotateUpdate(d.globalPosition),
                            onPanEnd: () => _rotateEnd(note),
                            onTap: () => _straighten(note),
                          ),
                        ),
                    ],
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

/// Faint dashed lines where a dragged card has snapped into line with a
/// neighbour (or the wall's centre).
class _GuidePainter extends CustomPainter {
  const _GuidePainter({this.x, this.y});

  final double? x;
  final double? y;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    void dashed(Offset a, Offset b) {
      final length = (b - a).distance;
      final dir = (b - a) / length;
      for (var d = 0.0; d < length; d += 14) {
        final p = a + dir * d;
        final q = a + dir * math.min(d + 8, length);
        canvas.drawLine(p, q, shadow);
        canvas.drawLine(p, q, line);
      }
    }

    if (x != null) dashed(Offset(x!, 0), Offset(x!, size.height));
    if (y != null) dashed(Offset(0, y!), Offset(size.width, y!));
  }

  @override
  bool shouldRepaint(_GuidePainter old) => old.x != x || old.y != y;
}

/// The loop drawn round notes in select mode.
class _LassoPainter extends CustomPainter {
  const _LassoPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path..close(),
      Paint()..color = AppColors.accent.withValues(alpha: 0.14),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke..color = const Color(0x66000000));
    canvas.drawPath(
      path,
      stroke
        ..color = AppColors.accent
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_LassoPainter old) =>
      old.points.length != points.length ||
      (points.isNotEmpty && old.points.last != points.last);
}

/// The tray a dragged note can be dropped into to delete it. Slides in from
/// below the wall while a drag is under way and turns red under the finger.
class _DropTray extends StatelessWidget {
  const _DropTray({
    super.key,
    required this.shown,
    required this.armed,
    required this.label,
  });

  final bool shown;
  final bool armed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, 1.4),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: AnimatedScale(
            scale: armed ? 1.04 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 60,
              decoration: BoxDecoration(
                color: armed ? AppColors.deleteIcon : AppColors.overlayDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.chalk.withValues(alpha: armed ? 0.9 : 0.4),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    armed ? Icons.delete : Icons.delete_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
  const _Thread(
    this.a,
    this.b, {
    this.link,
    this.live = false,
    this.faded = false,
  });

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
      canvas.drawPath(
        path,
        shadow..color = Color.fromRGBO(0, 0, 0, 0.33 * alpha),
      );
      canvas.restore();
      canvas.drawPath(path, yarn..color = _yarn.withValues(alpha: alpha));
      canvas.save();
      canvas.translate(0, -0.6);
      canvas.drawPath(
        path,
        sheen..color = Color.fromRGBO(255, 255, 255, 0.4 * alpha),
      );
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

/// The gesture on a note: one finger drags it, two turn and resize it. A
/// stock [ScaleGestureRecognizer] only claims the gesture once the fingers
/// have moved apart or their midpoint has travelled the pan slop — a clean
/// twist does neither, so it would never begin. Two fingers on one card can
/// mean nothing else, so this claims them the moment the second one lands
/// (a lone finger still waits for the slop, leaving taps and long-presses
/// to the card).
class _NoteGestureRecognizer extends ScaleGestureRecognizer {
  Offset? _down;
  bool _claimed = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _down ??= event.position;
  }

  @override
  void handleEvent(PointerEvent event) {
    // Claim a one-finger drag a little before the wall's own pan would: the
    // InteractiveViewer behind the note competes for the same finger, and
    // whichever recognizer crosses its slop first takes the gesture. A
    // finger that moves on a card means "drag the card".
    final down = _down;
    if (!_claimed &&
        event is PointerMoveEvent &&
        down != null &&
        pointerCount == 1 &&
        (event.position - down).distance >
            0.8 * computePanSlop(event.kind, gestureSettings)) {
      _claimed = true;
      resolve(GestureDisposition.accepted);
    }
    super.handleEvent(event);
    if (event is PointerDownEvent && pointerCount >= 2) {
      _claimed = true;
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _down = null;
    _claimed = false;
    super.didStopTrackingLastPointer(pointer);
  }
}

/// The drag of a corner grip. A plain pan waits for the finger to travel the
/// pan slop (36px) before it counts, and a grip that far behind the finger
/// feels stuck — this one takes the gesture after a few pixels, since there is
/// nothing else a drag on a grip could mean. Positions are measured from
/// where the finger landed, so a turn loses none of its first degrees.
class _GripDragRecognizer extends PanGestureRecognizer {
  _GripDragRecognizer() {
    dragStartBehavior = DragStartBehavior.down;
  }

  static const double _slop = 6;

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) => globalDistanceMoved.abs() > _slop;
}

/// A corner grip — the resize handle at bottom-right, the rotate handle at
/// bottom-left. Hidden until its note is the active one, so the wall reads as
/// paper on texture rather than a field of dark buttons.
class _Grip extends StatelessWidget {
  const _Grip({
    required this.visible,
    required this.engaged,
    required this.icon,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onTap,
    this.tooltip,
  });

  final bool visible;

  /// Being dragged right now: drawn bigger and darker.
  final bool engaged;
  final IconData icon;
  final void Function(DragStartDetails details) onPanStart;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final size = engaged ? 30.0 : 26.0;
    Widget grip = RawGestureDetector(
      gestures: {
        if (onTap != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r.onTap = onTap,
              ),
        _GripDragRecognizer:
            GestureRecognizerFactoryWithHandlers<_GripDragRecognizer>(
              _GripDragRecognizer.new,
              (r) {
                r.gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
                r.onStart = onPanStart;
                r.onUpdate = onPanUpdate;
                r.onEnd = (_) => onPanEnd();
                r.onCancel = onPanEnd;
              },
            ),
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: engaged ? AppColors.ink : AppColors.overlayDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.chalk, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 13, color: Colors.white),
      ),
    );
    if (tooltip != null) grip = Tooltip(message: tooltip, child: grip);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: grip,
      ),
    );
  }
}

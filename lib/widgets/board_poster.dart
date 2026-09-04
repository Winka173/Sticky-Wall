import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/app_localizations.dart';
import '../models/draw_stroke.dart';
import '../models/note.dart';
import '../services/image_service.dart';
import '../theme.dart';
import 'note_views.dart';
import 'wall_background.dart';
import 'wall_view.dart';

/// The board as a picture: the wall, its notes and threads laid out as they
/// are on screen, with no header, toolbar, grips or button — a plan you can
/// share or save to the gallery. Shown full screen for a look first; the
/// picture is rendered from that very preview, so what you see is what
/// leaves the app.
class BoardPosterPage extends StatefulWidget {
  const BoardPosterPage({
    super.key,
    required this.wall,
    required this.decor,
    required this.notes,
    required this.links,
    this.strokes = const [],
    required this.wallSize,
    required this.imageService,
    this.viewport,
    this.selected = const {},
    this.onShowOnWidget,
  });

  final WallStyle wall;

  /// Whether the wall's stains and marks are drawn (the user's setting).
  final bool decor;
  final List<Note> notes;
  final List<NoteLink> links;

  /// Marker strokes drawn on this wall.
  final List<DrawStroke> strokes;

  /// The live wall's layout size. Notes sit at fractions of that range, so
  /// the poster reproduces it to put every card where it is on screen. Zero
  /// when the wall has not been laid out this session; a portrait sheet the
  /// width of the screen is used instead.
  final Size wallSize;
  final ImageService imageService;

  /// The part of the wall on screen right now (wall coordinates), when the
  /// user has zoomed or panned — offered as an alternative to the whole wall.
  final Rect? viewport;

  /// Guids of the notes currently selected; when any, the export can be
  /// narrowed to just those.
  final Set<String> selected;

  /// Puts the rendered picture on the home-screen widget; null where there
  /// is no widget (iOS, web, desktop).
  final Future<bool> Function(Uint8List png)? onShowOnWidget;

  @override
  State<BoardPosterPage> createState() => _BoardPosterPageState();
}

class _BoardPosterPageState extends State<BoardPosterPage> {
  /// Room around the wall so a card turned or resized near an edge is not
  /// cut off; the texture continues underneath.
  static const double _margin = 24;

  static void _noop() {}
  static void _noopIndex(int _) {}
  static const _still = NoteCallbacks(
    onEdit: _noop,
    onTogglePin: _noop,
    onToggleItem: _noopIndex,
    onLongPress: _noop,
  );

  final _boundary = GlobalKey();
  final _wallBox = GlobalKey();
  late final _paperKeys = {for (final n in widget.notes) n.guid: GlobalKey()};

  // Where the cards actually ended up, measured after layout (home
  // coordinates): the estimate in _wholeWall does not know a card's height
  // or its turn, so a print parked in the margin could poke out of the
  // picture. Null until the first frame has been measured.
  Rect? _measured;
  bool _busy = false;

  // The options: what part of the wall, which notes, how many pixels per
  // logical pixel.
  bool _visibleOnly = false;
  late bool _selectedOnly = widget.selected.isNotEmpty;
  double _pixelRatio = 3;

  // Trimming: the part of the picture that is kept, as fractions of it, and
  // whether the handles are out.
  Rect _crop = const Rect.fromLTWH(0, 0, 1, 1);
  bool _cropping = false;

  bool get _trimmed => _crop != const Rect.fromLTWH(0, 0, 1, 1);

  Size _wallSize(BuildContext context) {
    final size = widget.wallSize;
    if (size.width > 0 && size.height > 0) return size;
    final screen = MediaQuery.sizeOf(context);
    return Size(screen.width, screen.width * 1.4);
  }

  List<Note> get _notes => _selectedOnly
      ? [
          for (final n in widget.notes)
            if (widget.selected.contains(n.guid)) n,
        ]
      : widget.notes;

  /// Rasterizes the preview (trimmed to the crop when one is set). Waits for
  /// the frame in flight first so a photo that has only just decoded is in
  /// the picture.
  Future<Uint8List?> _render() async {
    await WidgetsBinding.instance.endOfFrame;
    final ro = _boundary.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return null;
    final whole = await ImageService.capture(ro, pixelRatio: _pixelRatio);
    if (whole == null || !_trimmed) return whole;
    return ImageService.cropPng(whole, _crop);
  }

  Future<void> _run(
    Future<void> Function(Uint8List bytes) action, {
    String? failure,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _render();
      if (bytes != null) await action(bytes);
    } catch (_) {
      if (failure != null && mounted) _toast(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _share(AppLocalizations l10n) => _run(
    (bytes) => widget.imageService.sharePng(bytes, subject: l10n.appTitle),
  );

  Future<void> _save(AppLocalizations l10n) => _run((bytes) async {
    await widget.imageService.saveToGallery(bytes);
    if (!mounted) return;
    _toast(l10n.imageSaved);
    // Saved is the end of the job: leave the page rather than sit in the
    // trim handles with the picture already in the gallery.
    await Navigator.of(context).maybePop();
  }, failure: l10n.imageSaveFailed);

  Future<void> _sharePdf(AppLocalizations l10n) => _run((bytes) async {
    final pdf = await ImageService.pdfFromPng(bytes);
    await widget.imageService.sharePdf(pdf, subject: l10n.appTitle);
  });

  Future<void> _toWidget(AppLocalizations l10n) => _run((bytes) async {
    final ok = await widget.onShowOnWidget!(bytes);
    if (mounted) {
      _toast(ok ? l10n.widgetUpdated : l10n.widgetUpdateFailed);
    }
  }, failure: l10n.widgetUpdateFailed);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wall = _wallSize(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    // What ends up in the picture: the whole wall — grown to take in any
    // note parked out in the margin — or just the part in view.
    final crop = _visibleOnly && widget.viewport != null
        ? widget.viewport!
        : _wholeWall(wall);
    final box = Size(crop.width + 2 * _margin, crop.height + 2 * _margin);
    final faded = AppColors.chalk.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.chalk,
        elevation: 0,
        title: Text(l10n.exportBoard),
        actions: [
          IconButton(
            tooltip: l10n.cropImage,
            icon: Icon(
              Icons.crop,
              color: _cropping || _trimmed ? AppColors.accent : null,
            ),
            onPressed: _busy
                ? null
                : () => setState(() => _cropping = !_cropping),
          ),
          IconButton(
            tooltip: l10n.shareAsImage,
            icon: const Icon(Icons.ios_share),
            onPressed: _busy ? null : () => _share(l10n),
          ),
          IconButton(
            tooltip: l10n.saveImage,
            icon: const Icon(Icons.save_alt),
            onPressed: _busy ? null : () => _save(l10n),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.moreActions,
            enabled: !_busy,
            onSelected: (v) {
              if (v == 'pdf') _sharePdf(l10n);
              if (v == 'widget') _toWidget(l10n);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 10),
                    Text(l10n.sharePdf),
                  ],
                ),
              ),
              if (widget.onShowOnWidget != null)
                PopupMenuItem(
                  value: 'widget',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.widgets_outlined,
                        size: 18,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.putOnHomeScreen),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Center(
                // The preview keeps the picture's proportions and shrinks to
                // fit the screen; the crop handles lie over it at screen
                // scale. The render below ignores all that and draws the
                // boundary at its own size.
                child: AspectRatio(
                  aspectRatio: box.width / box.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FittedBox(
                        child: RepaintBoundary(
                          key: _boundary,
                          child: SizedBox(
                            width: box.width,
                            height: box.height,
                            // The wall paints notes parked in its margin
                            // outside its own box; only the picture's frame
                            // should show.
                            child: ClipRect(
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  Positioned.fill(
                                    child: WallBackground(
                                      wall: widget.wall,
                                      decor: widget.decor,
                                    ),
                                  ),
                                  // The whole wall, laid out at its live size
                                  // and shifted so the chosen part sits in the
                                  // frame.
                                  Positioned(
                                    left: _margin - crop.left,
                                    top: _margin - crop.top,
                                    width: wall.width,
                                    height: wall.height,
                                    child: IgnorePointer(
                                      key: _wallBox,
                                      child: WallView(
                                        notes: _notes,
                                        callbacksFor: (_) => _still,
                                        onMove: (_, _, _) {},
                                        onResize: (_, _) {},
                                        onBringToFront: (_) {},
                                        onCreateAt: (_, _) {},
                                        links: widget.links,
                                        strokes: widget.strokes,
                                        captureKeys: _paperKeys,
                                        still: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_cropping || _trimmed)
                        CropFrame(
                          crop: _crop,
                          editable: _cropping,
                          onChanged: (r) => setState(() => _crop = r),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _options(l10n),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Text(
              _cropping ? l10n.cropHint : l10n.exportHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.35, color: faded),
            ),
          ),
        ],
      ),
    );
  }

  /// The home area plus whatever hangs outside it: a note dragged out into
  /// the wall's margin still makes the picture.
  Rect _wholeWall(Size wall) {
    var rect = Offset.zero & wall;
    final measured = _measured;
    if (measured != null) return rect.expandToInclude(measured);
    for (final n in _notes) {
      final width = 168 * n.scale;
      final left = n.x * (wall.width - width);
      final top = n.y * (wall.height - 80);
      // A card's height is not known until it is laid out; allow a tall one
      // (a portrait print with its caption) plus a little air.
      final height = width * (n.type == NoteType.photo ? 1.4 : 1.0) + 14;
      rect = rect.expandToInclude(
        Rect.fromLTWH(left - 8, top - 8, width + 16, height + 16),
      );
    }
    return rect;
  }

  /// Reads the cards' rendered corners (turned cards included) and the
  /// marker strokes, relative to the wall's box, and grows the picture to
  /// take them in. Runs after every frame in whole-wall mode; measurements
  /// are relative to the wall box, so a bigger frame does not move them and
  /// the size settles after one extra frame.
  void _measure() {
    if (!mounted || (_visibleOnly && widget.viewport != null)) return;
    final wallRo = _wallBox.currentContext?.findRenderObject();
    if (wallRo is! RenderBox || !wallRo.hasSize) return;
    final wall = wallRo.size;
    Rect? all;
    void take(Offset p) {
      final dot = Rect.fromCenter(center: p, width: 0, height: 0);
      all = all == null ? dot : all!.expandToInclude(dot);
    }

    for (final key in _paperKeys.values) {
      final ro = key.currentContext?.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
      final size = ro.size;
      for (final c in [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ]) {
        take(ro.localToGlobal(c, ancestor: wallRo));
      }
    }
    for (final stroke in widget.strokes) {
      for (final p in stroke.points) {
        take(Offset(p.dx * wall.width, p.dy * wall.height));
      }
    }
    final bounds = all;
    if (bounds == null) return;
    // Air all round, and the pin's head above the paper.
    final next = Rect.fromLTRB(
      bounds.left - 10,
      bounds.top - 24,
      bounds.right + 10,
      bounds.bottom + 10,
    );
    final old = _measured;
    if (old != null &&
        (old.left - next.left).abs() < 0.5 &&
        (old.top - next.top).abs() < 0.5 &&
        (old.right - next.right).abs() < 0.5 &&
        (old.bottom - next.bottom).abs() < 0.5) {
      return;
    }
    setState(() => _measured = next);
  }

  /// Which part, which notes, how sharp — only the choices that apply.
  Widget _options(AppLocalizations l10n) {
    final style = SegmentedButton.styleFrom(
      foregroundColor: AppColors.chalk,
      selectedForegroundColor: AppColors.ink,
      selectedBackgroundColor: AppColors.accent,
      side: BorderSide(color: AppColors.chalk.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
      // The app's own face, a size down.
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.viewport != null)
            SegmentedButton<bool>(
              style: style,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.exportWholeWall)),
                ButtonSegment(value: true, label: Text(l10n.exportVisible)),
              ],
              selected: {_visibleOnly},
              onSelectionChanged: (s) =>
                  setState(() => _visibleOnly = s.single),
            ),
          if (widget.selected.isNotEmpty)
            SegmentedButton<bool>(
              style: style,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.exportAllNotes)),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.exportSelectedNotes(widget.selected.length)),
                ),
              ],
              selected: {_selectedOnly},
              onSelectionChanged: (s) =>
                  setState(() => _selectedOnly = s.single),
            ),
          SegmentedButton<double>(
            style: style,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 2, label: Text('2×')),
              ButtonSegment(value: 3, label: Text('3×')),
              ButtonSegment(value: 4, label: Text('4×')),
            ],
            selected: {_pixelRatio},
            onSelectionChanged: (s) => setState(() => _pixelRatio = s.single),
          ),
          if (_trimmed)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              icon: const Icon(Icons.crop_free, size: 18),
              label: Text(l10n.cropReset),
              onPressed: () => setState(() {
                _crop = const Rect.fromLTWH(0, 0, 1, 1);
              }),
            ),
        ],
      ),
    );
  }
}

/// The trimming frame over the export preview: the kept part stays bright,
/// the rest is dimmed, and while [editable] the corners and edges can be
/// dragged (or the whole frame moved). [crop] is in fractions of the
/// picture, so it maps straight onto the rendered PNG whatever the zoom.
class CropFrame extends StatefulWidget {
  const CropFrame({
    super.key,
    required this.crop,
    required this.editable,
    required this.onChanged,
  });

  final Rect crop;
  final bool editable;
  final ValueChanged<Rect> onChanged;

  /// Smallest side the frame may shrink to, as a fraction of the picture.
  static const double minSide = 0.1;

  @override
  State<CropFrame> createState() => _CropFrameState();
}

enum _Grab {
  move,
  left,
  top,
  right,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _CropFrameState extends State<CropFrame> {
  _Grab? _grab;
  Rect _start = Rect.zero;
  Offset _origin = Offset.zero;

  static const double _reach = 22;

  /// What the finger took hold of: a corner within reach, else an edge, else
  /// the frame itself (or nothing, outside it).
  _Grab? _hit(Offset p, Rect frame) {
    bool near(double a, double b) => (a - b).abs() <= _reach;
    final l = near(p.dx, frame.left);
    final r = near(p.dx, frame.right);
    final t = near(p.dy, frame.top);
    final b = near(p.dy, frame.bottom);
    final insideX = p.dx >= frame.left - _reach && p.dx <= frame.right + _reach;
    final insideY = p.dy >= frame.top - _reach && p.dy <= frame.bottom + _reach;
    if (l && t) return _Grab.topLeft;
    if (r && t) return _Grab.topRight;
    if (l && b) return _Grab.bottomLeft;
    if (r && b) return _Grab.bottomRight;
    if (l && insideY) return _Grab.left;
    if (r && insideY) return _Grab.right;
    if (t && insideX) return _Grab.top;
    if (b && insideX) return _Grab.bottom;
    if (frame.contains(p)) return _Grab.move;
    return null;
  }

  Rect _apply(_Grab grab, Offset delta, Size size) {
    final dx = delta.dx / size.width;
    final dy = delta.dy / size.height;
    var l = _start.left;
    var t = _start.top;
    var r = _start.right;
    var b = _start.bottom;
    const min = CropFrame.minSide;
    switch (grab) {
      case _Grab.move:
        final w = _start.width;
        final h = _start.height;
        l = (l + dx).clamp(0.0, 1 - w);
        t = (t + dy).clamp(0.0, 1 - h);
        return Rect.fromLTWH(l, t, w, h);
      case _Grab.left:
      case _Grab.topLeft:
      case _Grab.bottomLeft:
        l = (l + dx).clamp(0.0, r - min);
      case _Grab.right:
      case _Grab.topRight:
      case _Grab.bottomRight:
        r = (r + dx).clamp(l + min, 1.0);
      case _Grab.top:
      case _Grab.bottom:
        break;
    }
    switch (grab) {
      case _Grab.top:
      case _Grab.topLeft:
      case _Grab.topRight:
        t = (t + dy).clamp(0.0, b - min);
      case _Grab.bottom:
      case _Grab.bottomLeft:
      case _Grab.bottomRight:
        b = (b + dy).clamp(t + min, 1.0);
      default:
        break;
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        Rect frame() => Rect.fromLTRB(
          widget.crop.left * size.width,
          widget.crop.top * size.height,
          widget.crop.right * size.width,
          widget.crop.bottom * size.height,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: !widget.editable
              ? null
              : (d) {
                  _grab = _hit(d.localPosition, frame());
                  _start = widget.crop;
                  _origin = d.localPosition;
                },
          onPanUpdate: !widget.editable
              ? null
              : (d) {
                  final grab = _grab;
                  if (grab == null) return;
                  widget.onChanged(
                    _apply(grab, d.localPosition - _origin, size),
                  );
                },
          onPanEnd: (_) => _grab = null,
          onPanCancel: () => _grab = null,
          child: CustomPaint(
            painter: _CropPainter(frame(), handles: widget.editable),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter(this.frame, {required this.handles});

  final Rect frame;
  final bool handles;

  @override
  void paint(Canvas canvas, Size size) {
    // Dim what is trimmed away.
    final outside = Path()
      ..addRect(Offset.zero & size)
      ..addRect(frame)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outside, Paint()..color = const Color(0x99000000));
    canvas.drawRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.chalk,
    );
    if (!handles) return;
    // Thirds, as a camera would show them.
    final thirds = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = AppColors.chalk.withValues(alpha: 0.35);
    for (var i = 1; i < 3; i++) {
      final x = frame.left + frame.width * i / 3;
      final y = frame.top + frame.height * i / 3;
      canvas.drawLine(Offset(x, frame.top), Offset(x, frame.bottom), thirds);
      canvas.drawLine(Offset(frame.left, y), Offset(frame.right, y), thirds);
    }
    // Corner brackets in the accent, thick enough for a thumb.
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;
    const arm = 18.0;
    void bracket(Offset c, double sx, double sy) {
      canvas.drawLine(c, c + Offset(arm * sx, 0), corner);
      canvas.drawLine(c, c + Offset(0, arm * sy), corner);
    }

    bracket(frame.topLeft, 1, 1);
    bracket(frame.topRight, -1, 1);
    bracket(frame.bottomLeft, 1, -1);
    bracket(frame.bottomRight, -1, -1);
    // A short bar on each edge, so edges read as grabbable too.
    final edge = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;
    const half = 12.0;
    final cx = frame.center.dx;
    final cy = frame.center.dy;
    canvas.drawLine(
      Offset(cx - half, frame.top),
      Offset(cx + half, frame.top),
      edge,
    );
    canvas.drawLine(
      Offset(cx - half, frame.bottom),
      Offset(cx + half, frame.bottom),
      edge,
    );
    canvas.drawLine(
      Offset(frame.left, cy - half),
      Offset(frame.left, cy + half),
      edge,
    );
    canvas.drawLine(
      Offset(frame.right, cy - half),
      Offset(frame.right, cy + half),
      edge,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.frame != frame || old.handles != handles;
}

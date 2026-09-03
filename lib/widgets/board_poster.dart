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
  late final _paperKeys = {for (final n in widget.notes) n.guid: GlobalKey()};
  bool _busy = false;

  // The options: what part of the wall, which notes, how many pixels per
  // logical pixel.
  bool _visibleOnly = false;
  late bool _selectedOnly = widget.selected.isNotEmpty;
  double _pixelRatio = 3;

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

  /// Rasterizes the preview. Waits for the frame in flight first so a photo
  /// that has only just decoded is in the picture.
  Future<Uint8List?> _render() async {
    await WidgetsBinding.instance.endOfFrame;
    final ro = _boundary.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return null;
    return ImageService.capture(ro, pixelRatio: _pixelRatio);
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
    if (mounted) _toast(l10n.imageSaved);
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
    // What ends up in the picture: the whole wall, or just the part in view.
    final crop = _visibleOnly && widget.viewport != null
        ? widget.viewport!
        : Offset.zero & wall;
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
                    const Icon(Icons.picture_as_pdf_outlined, size: 18),
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
                      const Icon(Icons.widgets_outlined, size: 18),
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
                // The preview shrinks to fit the screen; the render below
                // ignores that and draws the boundary at its own size.
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _boundary,
                    child: SizedBox(
                      width: crop.width + 2 * _margin,
                      height: crop.height + 2 * _margin,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(
                            child: WallBackground(
                              wall: widget.wall,
                              decor: widget.decor,
                            ),
                          ),
                          // The whole wall, laid out at its live size and
                          // shifted so the chosen part sits in the frame.
                          Positioned(
                            left: _margin - crop.left,
                            top: _margin - crop.top,
                            width: wall.width,
                            height: wall.height,
                            child: IgnorePointer(
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
            ),
          ),
          _options(l10n),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Text(
              l10n.exportHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.35, color: faded),
            ),
          ),
        ],
      ),
    );
  }

  /// Which part, which notes, how sharp — only the choices that apply.
  Widget _options(AppLocalizations l10n) {
    final style = SegmentedButton.styleFrom(
      foregroundColor: AppColors.chalk,
      selectedForegroundColor: AppColors.ink,
      selectedBackgroundColor: AppColors.accent,
      side: BorderSide(color: AppColors.chalk.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(fontSize: 13),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
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
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/app_localizations.dart';
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
    required this.wallSize,
    required this.imageService,
  });

  final WallStyle wall;

  /// Whether the wall's stains and marks are drawn (the user's setting).
  final bool decor;
  final List<Note> notes;
  final List<NoteLink> links;

  /// The live wall's layout size. Notes sit at fractions of that range, so
  /// the poster reproduces it to put every card where it is on screen. Zero
  /// when the wall has not been laid out this session; a portrait sheet the
  /// width of the screen is used instead.
  final Size wallSize;
  final ImageService imageService;

  @override
  State<BoardPosterPage> createState() => _BoardPosterPageState();
}

class _BoardPosterPageState extends State<BoardPosterPage> {
  /// Room around the wall so a card turned or resized near an edge is not
  /// cut off; the texture continues underneath.
  static const double _margin = 24;

  /// Pixels per logical pixel in the exported PNG.
  static const double _pixelRatio = 3;

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

  Size _wallSize(BuildContext context) {
    final size = widget.wallSize;
    if (size.width > 0 && size.height > 0) return size;
    final screen = MediaQuery.sizeOf(context);
    return Size(screen.width, screen.width * 1.4);
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = _wallSize(context);
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
                      width: size.width + 2 * _margin,
                      height: size.height + 2 * _margin,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: WallBackground(
                              wall: widget.wall,
                              decor: widget.decor,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(_margin),
                            child: IgnorePointer(
                              child: WallView(
                                notes: widget.notes,
                                callbacksFor: (_) => _still,
                                onMove: (_, _, _) {},
                                onResize: (_, _) {},
                                onBringToFront: (_) {},
                                onCreateAt: (_, _) {},
                                links: widget.links,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
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
}

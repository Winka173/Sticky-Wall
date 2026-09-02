import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../models/note.dart';
import '../models/view_mode.dart';
import '../services/image_service.dart';
import '../services/notes_controller.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/board_bar.dart';
import '../widgets/note_dialog.dart';
import '../widgets/note_views.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/wall_decor.dart';
import '../widgets/wall_view.dart';

const _kToast = Duration(seconds: 3);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.notes, required this.settings});

  final NotesController notes;
  final SettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _imageService = ImageService();
  bool _searching = false;

  // Per-note RepaintBoundary keys so a note can be rasterized to an image.
  // Keyed by view mode *and* guid: while the content AnimatedSwitcher
  // crossfades two layouts, the same note is in the tree twice, and a
  // GlobalKey shared between the two copies would crash the framework.
  final _captureKeys = <String, GlobalKey>{};

  // Direction of the last board change, for the content slide: +1 moved to a
  // board further right, -1 further left, 0 = only the layout changed.
  int _slideDir = 0;
  late int _lastBoardIndex = _notes.currentBoardIndex;
  late ViewMode _lastViewMode = _notes.viewMode;

  NotesController get _notes => widget.notes;
  WallStyle get _wall => walls[_notes.currentBoard.wallIndex % walls.length];
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  String _captureId(Note note) => '${_notes.viewMode.name}/${note.guid}';

  GlobalKey _keyFor(Note note) =>
      _captureKeys.putIfAbsent(_captureId(note), GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _notes.search = _searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: _kToast),
    );
  }

  String _boardName(Board board) =>
      board.name.isEmpty ? _l10n.defaultBoardName : board.name;

  void _setSearching(bool on) {
    if (!on) _searchController.clear();
    setState(() => _searching = on);
  }

  // --- Note actions --------------------------------------------------------

  NoteCallbacks _callbacks(Note note) => NoteCallbacks(
        onEdit: () => _openEditor(note, isNew: false),
        onTogglePin: () {
          HapticFeedback.selectionClick();
          _notes.togglePin(note);
        },
        onToggleItem: (i) => _notes.toggleChecklistItem(note, i),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showNoteActions(note);
        },
      );

  Future<void> _showNoteActions(Note note) async {
    final l10n = _l10n;
    final canMove = _notes.boards.length > 1;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.edit),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(
                  note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.pinned ? l10n.unpin : l10n.pin),
              onTap: () => Navigator.pop(context, 'pin'),
            ),
            if (canMove)
              ListTile(
                leading: const Icon(Icons.drive_file_move_outlined),
                title: Text(l10n.moveToBoard),
                onTap: () => Navigator.pop(context, 'move'),
              ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(l10n.shareAsImage),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(l10n.saveImage),
              onTap: () => Navigator.pop(context, 'save'),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.deleteIcon),
              title: Text(l10n.delete,
                  style: const TextStyle(color: AppColors.deleteIcon)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _openEditor(note, isNew: false);
      case 'pin':
        HapticFeedback.selectionClick();
        _notes.togglePin(note);
      case 'move':
        await _moveToBoard(note);
      case 'share':
        await _captureAndShare(note);
      case 'save':
        await _captureAndSave(note);
      case 'delete':
        _delete(note);
    }
  }

  Future<void> _moveToBoard(Note note) async {
    final l10n = _l10n;
    final targets =
        _notes.boards.where((b) => b.id != note.boardId).toList();
    final target = await showModalBottomSheet<Board>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(l10n.moveToBoard,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            for (final board in targets)
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: Text(_boardName(board)),
                onTap: () => Navigator.pop(context, board),
              ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    _notes.moveToBoard(note, target.id);
    _toast(l10n.movedToBoard(_boardName(target)));
  }

  RenderRepaintBoundary? _boundaryFor(Note note) {
    final ctx = _captureKeys[_captureId(note)]?.currentContext;
    return ctx?.findRenderObject() as RenderRepaintBoundary?;
  }

  Future<void> _captureAndShare(Note note) async {
    final boundary = _boundaryFor(note);
    if (boundary == null) return;
    try {
      final bytes = await ImageService.capture(boundary);
      if (bytes != null) {
        await _imageService.sharePng(bytes, subject: _l10n.appTitle);
      }
    } catch (_) {/* user cancelled / platform unavailable */}
  }

  Future<void> _captureAndSave(Note note) async {
    final boundary = _boundaryFor(note);
    if (boundary == null) return;
    try {
      final bytes = await ImageService.capture(boundary);
      if (bytes == null || !mounted) return;
      await _imageService.saveToGallery(bytes);
      _toast(_l10n.imageSaved);
    } catch (_) {
      if (mounted) _toast(_l10n.imageSaveFailed);
    }
  }

  Future<void> _openEditor(Note note, {required bool isNew}) async {
    final oldPhoto = note.imagePath;
    final result = await showNoteDialog(
      context,
      note: note,
      isNew: isNew,
      existing: _notes.boardNotes,
    );
    if (result == null || !mounted) return;
    if (isNew) {
      _notes.add(result);
    } else {
      _notes.update(result);
    }
    // The photo was swapped or removed: drop the old file unless another
    // note still shows it.
    if (oldPhoto != result.imagePath && !_notes.photoInUse(oldPhoto)) {
      ImageService.deleteFile(oldPhoto);
    }
  }

  void _delete(Note note) {
    _notes.delete(note);
    _captureKeys.removeWhere((k, _) => k.endsWith('/${note.guid}'));
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger
        .showSnackBar(
          SnackBar(
            content: Text(_l10n.noteDeleted),
            duration: _kToast,
            action: SnackBarAction(
              label: _l10n.undo,
              onPressed: _notes.undoDelete,
            ),
          ),
        )
        .closed
        .then((reason) {
      if (reason == SnackBarClosedReason.action) return;
      // Undo is off the table now; the note's photo can go too.
      final orphan = _notes.purgeDeleted(note);
      if (orphan != null) ImageService.deleteFile(orphan);
    });
  }

  // --- Layout --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.notes, widget.settings]),
      builder: (context, _) {
        final wall = _wall;
        // Only a board or layout change may retarget the slide; unrelated
        // rebuilds (typing in search) must not yank a running transition.
        final boardIndex = _notes.currentBoardIndex;
        if (boardIndex != _lastBoardIndex) {
          _slideDir = boardIndex > _lastBoardIndex ? 1 : -1;
          _lastBoardIndex = boardIndex;
        } else if (_notes.viewMode != _lastViewMode) {
          _slideDir = 0;
        }
        _lastViewMode = _notes.viewMode;
        final showFabLabel =
            _notes.boardNotes.isEmpty || _notes.viewMode != ViewMode.wall;

        return Stack(
          children: [
            // Background layers live outside the Scaffold so switching walls
            // crossfades the texture without rebuilding the app content.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: _WallBackground(
                  key: ValueKey('${wall.id}-${widget.settings.wallDecor}'),
                  wall: wall,
                  decor: widget.settings.wallDecor,
                ),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              // The editor is a dialog above this screen; letting the keyboard
              // squash the wall underneath would make every note slide about
              // behind the barrier while you type.
              resizeToAvoidBottomInset: false,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openEditor(_notes.draft(), isNew: true),
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.ink,
                // Shrinks to a plain "+" once a free wall has notes on it, so
                // it covers less of them.
                isExtended: showFabLabel,
                icon: const Icon(Icons.add),
                label:
                    Text(_l10n.addNote, style: const TextStyle(fontSize: 17)),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    _buildTitleRow(wall),
                    _buildToolRow(wall),
                    const SizedBox(height: 6),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: _contentTransition,
                        child: KeyedSubtree(
                          key: ValueKey(
                              '${_notes.currentBoardId}:${_notes.viewMode.name}'),
                          child: _buildContent(wall),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Board changes slide the content sideways in the direction of travel;
  /// layout changes simply crossfade.
  Widget _contentTransition(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = animation.value;
        // The outgoing tree's animation runs in reverse; it leaves the
        // opposite way the new one arrives.
        final leaving = animation.status == AnimationStatus.reverse ||
            animation.status == AnimationStatus.dismissed;
        final dir = leaving ? -_slideDir : _slideDir;
        return FractionalTranslation(
          translation: Offset((1 - v) * 0.10 * dir, 0),
          child: Opacity(opacity: v, child: child),
        );
      },
    );
  }

  BoxDecoration _frosted(WallStyle wall) => BoxDecoration(
        color: wall.dark ? const Color(0x26FFFFFF) : const Color(0x14000000),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: wall.wallTextFaded.withValues(alpha: 0.25)),
      );

  Widget _buildTitleRow(WallStyle wall) {
    final text = wall.wallText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
      child: SizedBox(
        height: 48,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _searching
              ? _searchField(wall)
              : Row(
                  key: const ValueKey('title'),
                  children: [
                    Expanded(
                      child: Text(
                        _l10n.appTitle,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 28,
                          color: text,
                          shadows: wall.wallTextShadows,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _l10n.search,
                      icon: Icon(Icons.search, color: text),
                      onPressed: () => _setSearching(true),
                    ),
                    IconButton(
                      tooltip: _l10n.customize,
                      icon: Icon(Icons.palette_outlined, color: text),
                      onPressed: () => showSettingsSheet(
                        context,
                        settings: widget.settings,
                        notes: _notes,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _searchField(WallStyle wall) {
    final text = wall.wallText;
    final faded = wall.wallTextFaded;
    return Padding(
      key: const ValueKey('search'),
      padding: const EdgeInsets.fromLTRB(0, 3, 8, 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: _frosted(wall),
        child: Row(
          children: [
            IconButton(
              tooltip: _l10n.cancel,
              iconSize: 20,
              icon: Icon(Icons.arrow_back, color: text),
              onPressed: () => _setSearching(false),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                cursorColor: text,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: text, fontSize: 17),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: _l10n.search,
                  hintStyle: TextStyle(color: faded, fontSize: 17),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox(width: 12)
                  : IconButton(
                      tooltip: _l10n.clear,
                      iconSize: 18,
                      icon: Icon(Icons.close, color: faded),
                      onPressed: _searchController.clear,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolRow(WallStyle wall) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
      child: Row(
        children: [
          Expanded(child: BoardBar(notes: _notes, textColor: wall.wallText)),
          _filterButton(wall),
          if (_notes.viewMode != ViewMode.wall) _sortButton(wall),
          _layoutButton(wall),
        ],
      ),
    );
  }

  PopupMenuItem<T> _menuItem<T>(
    T value,
    String label, {
    IconData? icon,
    bool selected = false,
  }) {
    return PopupMenuItem<T>(
      value: value,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: selected ? FontWeight.bold : null,
              ),
            ),
          ),
          if (selected)
            const Icon(Icons.check, size: 18, color: AppColors.ink),
        ],
      ),
    );
  }

  Widget _filterButton(WallStyle wall) {
    final l10n = _l10n;
    final active = _notes.typeFilter != -1;
    final options = [
      (-1, l10n.typeAll, Icons.all_inclusive),
      (0, l10n.typeNormal, Icons.notes),
      (1, l10n.typeLink, Icons.link),
      (2, l10n.typeChecklist, Icons.checklist),
      (3, l10n.typeDrawing, Icons.brush_outlined),
    ];
    return PopupMenuButton<int>(
      tooltip: l10n.type,
      icon: Badge(
        isLabelVisible: active,
        smallSize: 8,
        backgroundColor: AppColors.accent,
        child: Icon(active ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: wall.wallText),
      ),
      onSelected: (v) => _notes.typeFilter = v,
      itemBuilder: (context) => [
        for (final (key, label, icon) in options)
          _menuItem(key, label,
              icon: icon, selected: _notes.typeFilter == key),
      ],
    );
  }

  Widget _sortButton(WallStyle wall) {
    final l10n = _l10n;
    // (label, icon, byCreated, ascending)
    final options = [
      (l10n.sortNewest, Icons.schedule, true, false),
      (l10n.sortOldest, Icons.history, true, true),
      (l10n.sortAZ, Icons.sort_by_alpha, false, true),
      (l10n.sortZA, Icons.sort_by_alpha, false, false),
    ];
    return PopupMenuButton<int>(
      tooltip: l10n.sortTooltip,
      icon: Icon(Icons.swap_vert, color: wall.wallText),
      onSelected: (i) =>
          _notes.setSort(byCreated: options[i].$3, ascending: options[i].$4),
      itemBuilder: (context) => [
        for (final (i, o) in options.indexed)
          _menuItem(i, o.$1,
              icon: o.$2,
              selected: _notes.sortByCreated == o.$3 &&
                  _notes.sortAscending == o.$4),
      ],
    );
  }

  static IconData _layoutIcon(ViewMode mode) => switch (mode) {
        ViewMode.wall => Icons.dashboard_customize_outlined,
        ViewMode.grid => Icons.grid_view_rounded,
        ViewMode.list => Icons.view_agenda_outlined,
      };

  String _layoutLabel(ViewMode mode) => switch (mode) {
        ViewMode.wall => _l10n.viewWall,
        ViewMode.grid => _l10n.viewGrid,
        ViewMode.list => _l10n.viewList,
      };

  Widget _layoutButton(WallStyle wall) {
    // Shows the *current* layout and opens a menu, instead of the old cycling
    // button whose icon meant "what you'll get next".
    return PopupMenuButton<ViewMode>(
      tooltip: _l10n.layout,
      icon: Icon(_layoutIcon(_notes.viewMode), color: wall.wallText),
      onSelected: (m) => _notes.viewMode = m,
      itemBuilder: (context) => [
        for (final mode in ViewMode.values)
          _menuItem(mode, _layoutLabel(mode),
              icon: _layoutIcon(mode), selected: _notes.viewMode == mode),
      ],
    );
  }

  Widget _buildContent(WallStyle wall) {
    // Wall mode: free-drag canvas with every note on the board. Search and
    // the type filter dim non-matches instead of removing them, so nothing
    // jumps around. Rendered even when empty so the wall still takes taps.
    if (_notes.viewMode == ViewMode.wall) {
      final notes = _notes.boardNotes;
      return WallView(
        notes: notes,
        callbacksFor: _callbacks,
        onMove: _notes.moveNote,
        onResize: _notes.resizeNote,
        onBringToFront: _notes.bringToFront,
        onCreateAt: (x, y) => _openEditor(_notes.draftAt(x, y), isNew: true),
        captureKeys: {for (final n in notes) n.guid: _keyFor(n)},
        isDimmed: (n) => _notes.isFiltering && !_notes.matches(n),
        resetZoomTooltip: _l10n.resetZoom,
        emptyHint: _emptyState(wall, tip: _l10n.wallCreateHint),
      );
    }

    final notes = _notes.visibleNotes;
    if (notes.isEmpty) {
      return _notes.boardNotes.isNotEmpty && _notes.isFiltering
          ? _noMatches(wall)
          : _emptyState(wall);
    }

    // Grid/list: swipe horizontally to move between boards.
    final content =
        _notes.viewMode == ViewMode.grid ? _grid(notes) : _list(notes);
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -250) {
          _notes.selectBoardAt(_notes.currentBoardIndex + 1);
        } else if (v > 250) {
          _notes.selectBoardAt(_notes.currentBoardIndex - 1);
        }
      },
      child: content,
    );
  }

  Duration _staggerFor(int index) =>
      Duration(milliseconds: 25 * math.min(index, 12));

  Widget _grid(List<Note> notes) {
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      crossAxisCount: 2,
      // The pin already pokes 14 px above each card, so keep rows tight.
      mainAxisSpacing: 10,
      crossAxisSpacing: 14,
      itemCount: notes.length,
      itemBuilder: (context, i) => NoteAppear(
        key: ValueKey(notes[i].guid),
        delay: _staggerFor(i),
        child: StickyNoteCard(
          note: notes[i],
          cb: _callbacks(notes[i]),
          maxContentLines: 8,
          captureKey: _keyFor(notes[i]),
        ),
      ),
    );
  }

  Widget _list(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final note = notes[i];
        return Dismissible(
          key: ValueKey('dismiss-${note.guid}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _delete(note),
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.only(right: 22),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: AppColors.deleteIcon,
              borderRadius: BorderRadius.circular(AppRadii.paper),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: NoteAppear(
            delay: _staggerFor(i),
            child: NoteListTile(
              note: note,
              cb: _callbacks(note),
              captureKey: _keyFor(note),
            ),
          ),
        );
      },
    );
  }

  Widget _noMatches(WallStyle wall) {
    final faded = wall.wallTextFaded;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: faded),
          const SizedBox(height: 10),
          Text(
            _l10n.noMatches,
            style: TextStyle(
                fontSize: 20, color: faded, shadows: wall.wallTextShadows),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(WallStyle wall, {String? tip}) {
    final faded = wall.wallTextFaded;
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _openEditor(_notes.draft(), isNew: true),
        child: Transform.rotate(
          angle: -0.03,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A dashed "ghost note" inviting the first pin.
                SizedBox(
                  width: 150,
                  height: 112,
                  child: CustomPaint(
                    painter: _GhostNotePainter(faded),
                    child: Icon(Icons.add, size: 36, color: faded),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _l10n.emptyState,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.4,
                    color: faded,
                    shadows: wall.wallTextShadows,
                  ),
                ),
                if (tip != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    tip,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: faded.withValues(alpha: 0.75),
                      shadows: wall.wallTextShadows,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The wall texture + scrim + stains + vignette, kept outside the Scaffold so
/// wall switches can crossfade without touching app content.
class _WallBackground extends StatelessWidget {
  const _WallBackground({
    super.key,
    required this.wall,
    required this.decor,
  });

  final WallStyle wall;
  final bool decor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B5849),
        image: DecorationImage(
          image: AssetImage(wall.asset),
          repeat: ImageRepeat.repeat,
          scale: 2.2,
        ),
      ),
      child: Container(
        color: wall.overlay,
        child: Stack(
          children: [
            if (decor) Positioned.fill(child: WallDecor(wall: wall)),
            // Soft vignette adds depth so the wall recedes at the edges.
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.15,
                      colors: [Colors.transparent, Color(0x33000000)],
                      stops: [0.62, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed outline in the shape of a sticky note.
class _GhostNotePainter extends CustomPainter {
  _GhostNotePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1.5),
        const Radius.circular(8),
      ));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 8, metric.length)),
          paint,
        );
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_GhostNotePainter oldDelegate) =>
      oldDelegate.color != color;
}

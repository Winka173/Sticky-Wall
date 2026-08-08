import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../l10n/app_localizations.dart';
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

  // Per-note RepaintBoundary keys, so a note can be rasterized to an image.
  final _captureKeys = <String, GlobalKey>{};

  NotesController get _notes => widget.notes;
  WallStyle get _wall => walls[_notes.currentBoard.wallIndex % walls.length];
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  GlobalKey _keyFor(Note note) =>
      _captureKeys.putIfAbsent(note.guid, () => GlobalKey());

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

  NoteCallbacks _callbacks(Note note) => NoteCallbacks(
        onEdit: () => _openEditor(note, isNew: false),
        onDelete: () => _delete(note),
        onTogglePin: () => _notes.togglePin(note),
        onToggleItem: (i) => _notes.toggleChecklistItem(note, i),
        onLongPress: () => _showNoteActions(note),
      );

  Future<void> _showNoteActions(Note note) async {
    final l10n = _l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(l10n.pin),
              onTap: () => Navigator.pop(context, 'pin'),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(l10n.shareAsImage),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(l10n.saveImage),
              onTap: () => Navigator.pop(context, 'save'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.deleteIcon),
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
      case 'pin':
        _notes.togglePin(note);
      case 'share':
        await _captureAndShare(note);
      case 'save':
        await _captureAndSave(note);
      case 'delete':
        _delete(note);
    }
  }

  RenderRepaintBoundary? _boundaryFor(Note note) {
    final ctx = _captureKeys[note.guid]?.currentContext;
    return ctx?.findRenderObject() as RenderRepaintBoundary?;
  }

  Future<void> _captureAndShare(Note note) async {
    final boundary = _boundaryFor(note);
    if (boundary == null) return;
    try {
      final bytes = await ImageService.capture(boundary);
      if (bytes != null) await _imageService.sharePng(bytes);
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
    final result = await showNoteDialog(
      context,
      note: note,
      isNew: isNew,
      existing: _notes.boardNotes,
    );
    if (result == null || !mounted) return;
    if (isNew) {
      _notes.add(result);
      _toast(_l10n.addSuccess);
    } else {
      _notes.update(result);
      _toast(_l10n.updateSuccess);
    }
  }

  void _delete(Note note) {
    _notes.delete(note);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_l10n.noteDeleted),
          duration: _kToast,
          action: SnackBarAction(
            label: _l10n.undo,
            onPressed: _notes.undoDelete,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.notes, widget.settings]),
      builder: (context, _) {
        final wall = _wall;
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
                if (widget.settings.wallDecor)
                  Positioned.fill(child: WallDecor(wall: wall)),
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
                Scaffold(
                  backgroundColor: Colors.transparent,
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: () => _openEditor(_notes.draft(), isNew: true),
                    backgroundColor: const Color(0xFFFFCA28),
                    foregroundColor: AppColors.ink,
                    icon: const Icon(Icons.push_pin),
                    label: Text(_l10n.addNote,
                        style: const TextStyle(fontSize: 17)),
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(wall),
                        BoardBar(notes: _notes, textColor: wall.wallText),
                        const SizedBox(height: 8),
                        _buildToolbar(wall),
                        const SizedBox(height: 8),
                        Expanded(child: _buildContent(wall)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(WallStyle wall) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Row(
        children: [
          Text(
            'Sticky Wall',
            style: TextStyle(
              fontFamily: 'Pacifico',
              fontSize: 30,
              color: wall.wallText,
              shadows: wall.wallTextShadows,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: _l10n.customize,
            icon: Icon(Icons.palette_outlined, color: wall.wallText),
            onPressed: () => showSettingsSheet(
              context,
              settings: widget.settings,
              notes: _notes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(WallStyle wall) {
    final l10n = _l10n;
    final text = wall.wallText;

    final typeOptions = [
      (key: -1, label: l10n.typeAll),
      (key: 0, label: l10n.typeNormal),
      (key: 1, label: l10n.typeLink),
      (key: 2, label: l10n.typeChecklist),
    ];

    return Theme(
      data: wallControlsTheme(context, wall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 116,
              child: DropdownButtonFormField<int>(
                initialValue: _notes.typeFilter,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.type),
                dropdownColor: wall.dropdownSurface,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 16, color: text),
                iconEnabledColor: text,
                items: [
                  for (final o in typeOptions)
                    DropdownMenuItem(value: o.key, child: Text(o.label)),
                ],
                onChanged: (v) {
                  if (v != null) _notes.typeFilter = v;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(labelText: l10n.search),
                style: TextStyle(color: text, fontSize: 16),
              ),
            ),
            IconButton(
              tooltip: l10n.sortTooltip,
              icon: Icon(
                _notes.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: text,
              ),
              onPressed: _notes.toggleSortDirection,
            ),
            _viewModeButton(wall),
          ],
        ),
      ),
    );
  }

  Widget _viewModeButton(WallStyle wall) {
    final l10n = _l10n;
    final (icon, next, tip) = switch (_notes.viewMode) {
      ViewMode.wall => (Icons.dashboard_customize, ViewMode.grid, l10n.viewGrid),
      ViewMode.grid => (Icons.grid_view, ViewMode.list, l10n.viewList),
      ViewMode.list => (Icons.view_agenda, ViewMode.wall, l10n.viewWall),
    };
    return IconButton(
      tooltip: tip,
      icon: Icon(icon, color: wall.wallText),
      onPressed: () => _notes.viewMode = next,
    );
  }

  Widget _buildContent(WallStyle wall) {
    // Wall mode: free-drag canvas (all board notes, unfiltered by layout).
    // Rendered even when empty so tapping the wall still creates a note.
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
        resetZoomTooltip: _l10n.resetZoom,
        emptyHint: _emptyState(wall),
      );
    }

    final notes = _notes.visibleNotes;
    if (notes.isEmpty) return _emptyState(wall);

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

  Widget _grid(List<Note> notes) {
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 16,
      itemCount: notes.length,
      itemBuilder: (context, i) => _Appear(
        key: ValueKey(notes[i].guid),
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
      itemBuilder: (context, i) => _Appear(
        key: ValueKey(notes[i].guid),
        child: NoteListTile(
          note: notes[i],
          cb: _callbacks(notes[i]),
          captureKey: _keyFor(notes[i]),
        ),
      ),
    );
  }

  Widget _emptyState(WallStyle wall) {
    return Center(
      child: Transform.rotate(
        angle: -0.03,
        child: Text(
          _l10n.emptyState,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            height: 1.4,
            color: wall.wallTextFaded,
            shadows: wall.wallTextShadows,
          ),
        ),
      ),
    );
  }
}

/// Plays a small "stick onto the wall" entrance: fade + settle + tiny rotate.
class _Appear extends StatefulWidget {
  const _Appear({super.key, required this.child});

  final Widget child;

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return FadeTransition(
      opacity: _c,
      child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(curve),
          child: widget.child),
    );
  }
}

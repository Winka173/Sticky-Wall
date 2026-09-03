import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../models/draw_stroke.dart';
import '../models/note.dart';
import '../models/view_mode.dart';
import '../services/image_service.dart';
import '../services/notes_controller.dart';
import '../services/settings_controller.dart';
import '../services/share_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import '../widgets/action_sheet.dart';
import '../widgets/add_note_button.dart';
import '../widgets/board_bar.dart';
import '../widgets/board_poster.dart';
import '../widgets/note_dialog.dart';
import '../widgets/note_views.dart';
import '../widgets/peel_away.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/wall_background.dart';
import '../widgets/wall_view.dart';
import 'trash_screen.dart';

const _kToast = Duration(seconds: 3);

/// The main screen: title row, board tabs and tools, then the notes in the
/// current layout (free wall, grid or list) over the wall texture. Also hosts
/// the editor, selection mode, search, share/save and incoming shared content.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.notes,
    required this.settings,
    this.shareReceiver,
  });

  final NotesController notes;
  final SettingsController settings;

  /// Delivers content shared from other apps; null (tests, desktop) means the
  /// screen never listens for it.
  final ShareReceiver? shareReceiver;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _imageService = ImageService();
  final _wallHandle = WallHandle();
  // Pan/zoom of the wall, shared with the background so the texture moves
  // with the notes.
  final _camera = WallCamera();
  bool _searching = false;

  // A note dragged up from the wall can land on a board tab: the chips are
  // found through these keys, and the hovered one is lit through this.
  final _chipKeys = <String, GlobalKey>{};
  final _dropTarget = ValueNotifier<String?>(null);

  // The wall's Undo pill: shown for a few seconds after each remembered
  // wall edit (see NotesController.wallEdits), and after each undo while
  // more remain.
  int _seenWallEdits = 0;
  bool _undoShown = false;
  Timer? _undoTimer;

  // Marker mode: drawing on the wall with the current pen, and the stroke
  // lists as they were before each change, for Undo.
  bool _marking = false;
  WallMarker _marker = const WallMarker();
  final _inkPast = <List<DrawStroke>>[];

  // Multi-select: on while the selection bar is up; guids of chosen notes.
  bool _selecting = false;
  final _selected = <String>{};

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
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  String _captureId(Note note) => '${_notes.viewMode.name}/${note.guid}';

  GlobalKey _keyFor(Note note) =>
      _captureKeys.putIfAbsent(_captureId(note), GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _notes.search = _searchController.text);
    widget.shareReceiver?.listen(_onShared);
  }

  @override
  void dispose() {
    widget.shareReceiver?.dispose();
    _searchController.dispose();
    _camera.dispose();
    _dropTarget.dispose();
    _undoTimer?.cancel();
    super.dispose();
  }

  // --- Undo (wall) ---------------------------------------------------------

  /// Shows the Undo pill and arms the timer that hides it again. Called
  /// from build when a new edit is noticed, so it must not set state itself.
  void _armUndo() {
    _undoShown = true;
    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _undoShown = false);
    });
  }

  void _undoWall() {
    HapticFeedback.lightImpact();
    _notes.undoWall();
    // undoWall notified: the rebuild sees wallEdits unchanged, so re-arm
    // here while more steps remain.
    setState(() {
      if (_notes.canUndoWall) {
        _armUndo();
      } else {
        _undoTimer?.cancel();
        _undoShown = false;
      }
    });
  }

  Widget _undoPill() {
    final show = _undoShown && _notes.canUndoWall;
    return IgnorePointer(
      ignoring: !show,
      child: AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0, -0.8),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: AppColors.overlayDark,
            borderRadius: BorderRadius.circular(20),
            elevation: 3,
            child: InkWell(
              onTap: _undoWall,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.undo, size: 18, color: AppColors.chalk),
                    const SizedBox(width: 8),
                    Text(
                      _l10n.undo,
                      style: const TextStyle(
                        color: AppColors.chalk,
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
      ),
    );
  }

  // --- Drops on the board tabs ---------------------------------------------

  /// The board whose tab is under [global], other than the current one.
  String? _boardAt(Offset global) {
    for (final board in _notes.boards) {
      if (board.id == _notes.currentBoardId) continue;
      final ro = _chipKeys[board.id]?.currentContext?.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
      final p = ro.globalToLocal(global);
      // A little slack all round: the finger is under a card, not a cursor.
      if (Rect.fromLTWH(
        -6,
        -14,
        ro.size.width + 12,
        ro.size.height + 28,
      ).contains(p)) {
        return board.id;
      }
    }
    return null;
  }

  void _dragOver(Note note, Offset? global) {
    final id = global == null ? null : _boardAt(global);
    if (id == _dropTarget.value) return;
    if (id != null) HapticFeedback.selectionClick();
    _dropTarget.value = id;
  }

  /// A note (or selection) let go somewhere on screen: moves it to the board
  /// whose tab it landed on. Returns whether it did.
  bool _dropOnTab(List<Note> notes, Offset global) {
    _dropTarget.value = null;
    final id = _boardAt(global);
    if (id == null) return false;
    final board = _notes.boards.firstWhere((b) => b.id == id);
    _notes.moveAllToBoard(notes, id);
    _exitSelecting();
    _toast(_l10n.movedToBoard(_boardName(board)));
    return true;
  }

  // --- Marker mode ---------------------------------------------------------

  void _startMarking(WallStyle wall) {
    _exitSelecting();
    setState(() {
      _marking = true;
      _inkPast.clear();
      // Ink on a light wall, chalk on a dark one.
      _marker = WallMarker(
        color: wall.dark ? AppColors.markers.last : AppColors.markers.first,
      );
    });
  }

  void _stopMarking() => setState(() {
    _marking = false;
    _inkPast.clear();
  });

  List<DrawStroke> get _wallStrokes => _notes.currentBoard.strokes;

  void _inkBegin() {
    _inkPast.add(List.of(_wallStrokes));
    if (_inkPast.length > 40) _inkPast.removeAt(0);
  }

  void _undoInk() {
    if (_inkPast.isEmpty) return;
    HapticFeedback.lightImpact();
    _wallStrokes
      ..clear()
      ..addAll(_inkPast.removeLast());
    _notes.saveWallStrokes();
  }

  void _clearInk() {
    if (_wallStrokes.isEmpty) return;
    HapticFeedback.lightImpact();
    _inkBegin();
    _wallStrokes.clear();
    _notes.saveWallStrokes();
  }

  /// Pen, colours, eraser, undo, clear and done, docked at the bottom while
  /// drawing on the wall. Compact enough for a 360dp phone in one row.
  Widget _markerBar(WallStyle wall) {
    final l10n = _l10n;
    final text = wall.wallText;
    const widths = [3.0, 6.0, 11.0];
    final nextWidth =
        widths[(widths.indexOf(_marker.width) + 1) % widths.length];
    Widget tool({
      required String tooltip,
      required Widget icon,
      VoidCallback? onTap,
      Color? color,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: icon,
      iconSize: 21,
      color: color ?? text,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
        child: Container(
          decoration: _frosted(wall, radius: 16),
          padding: const EdgeInsets.fromLTRB(4, 6, 5, 6),
          child: Row(
            children: [
              for (final c in AppColors.markers)
                _InkDot(
                  color: Color(c),
                  selected: !_marker.eraser && _marker.color == c,
                  onTap: () => setState(
                    () => _marker = _marker.copyWith(color: c, eraser: false),
                  ),
                ),
              const Spacer(),
              tool(
                tooltip: l10n.penSize,
                // The icon's weight hints at the current width.
                icon: Icon(Icons.line_weight, size: 14 + _marker.width),
                onTap: () => setState(
                  () => _marker = _marker.copyWith(width: nextWidth),
                ),
              ),
              tool(
                tooltip: l10n.eraser,
                icon: Icon(
                  _marker.eraser
                      ? Icons.auto_fix_normal
                      : Icons.auto_fix_normal_outlined,
                ),
                color: _marker.eraser ? AppColors.accent : text,
                onTap: () => setState(
                  () => _marker = _marker.copyWith(eraser: !_marker.eraser),
                ),
              ),
              tool(
                tooltip: l10n.undo,
                icon: const Icon(Icons.undo),
                onTap: _inkPast.isEmpty ? null : _undoInk,
              ),
              tool(
                tooltip: l10n.clear,
                icon: const Icon(Icons.delete_sweep_outlined),
                onTap: _wallStrokes.isEmpty ? null : _clearInk,
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: l10n.done,
                child: Material(
                  color: AppColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _stopMarking,
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.check, size: 20, color: AppColors.ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Threads ---------------------------------------------------------------

  /// A tap on a thread: pick its yarn colour, write on it, give it an
  /// arrowhead, or cut it.
  Future<void> _editThread(NoteLink link) async {
    final l10n = _l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ThreadSheet(
        link: link,
        notes: _notes,
        onCut: (cut) {
          Navigator.pop(context);
          unawaited(HapticFeedback.lightImpact());
          _notes.disconnect(cut);
          _undoToast(l10n.threadCut, () => _notes.restoreLink(cut));
        },
      ),
    );
  }

  /// Long press on the add button: pick the note type straight away.
  Future<void> _quickAdd() async {
    final l10n = _l10n;
    unawaited(HapticFeedback.mediumImpact());
    final type = await showActionSheet<NoteType>(
      context,
      title: l10n.addNote,
      children: [
        for (final (t, icon, label) in [
          (NoteType.normal, Icons.notes, l10n.typeNormal),
          (NoteType.link, Icons.link, l10n.typeLink),
          (NoteType.checklist, Icons.checklist, l10n.typeChecklist),
          (NoteType.drawing, Icons.brush_outlined, l10n.typeDrawing),
          (NoteType.photo, Icons.photo_outlined, l10n.typePhoto),
          (NoteType.label, Icons.label_outline, l10n.typeLabel),
        ])
          ListTile(
            leading: Icon(icon),
            title: Text(label),
            onTap: () => Navigator.pop(context, t),
          ),
      ],
    );
    if (type == null || !mounted) return;
    await _openEditor(_notes.draft()..type = type, isNew: true);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: _kToast));
  }

  void _undoToast(String message, VoidCallback undo) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: _kToast,
          action: SnackBarAction(label: _l10n.undo, onPressed: undo),
        ),
      );
  }

  String _boardName(Board board) =>
      board.name.isEmpty ? _l10n.defaultBoardName : board.name;

  void _setSearching(bool on) {
    if (!on) _searchController.clear();
    setState(() => _searching = on);
  }

  // --- Sharing in ----------------------------------------------------------

  /// Something arrived through the system share sheet: open the editor with
  /// it filled in, so the user can still pick a board, color or emote.
  Future<void> _onShared(SharedContent content) async {
    final draft = _notes.draft();
    if (content.imagePath.isNotEmpty) {
      final stored = await _imageService.importSharedImage(content.imagePath);
      if (stored != null) draft.imagePath = stored;
    }
    if (!mounted) return;
    if (content.url.isNotEmpty) {
      draft.type = NoteType.link;
      draft.url = content.url;
    } else if (draft.hasPhoto && content.text.isEmpty) {
      // A bare picture becomes a print on the wall, not a note about one.
      draft.type = NoteType.photo;
    }
    draft.content = content.text;
    // Whatever was open (another editor, a sheet) gives way to the new note.
    Navigator.of(context).popUntil((route) => route.isFirst);
    await _openEditor(draft, isNew: true);
  }

  // --- Note actions --------------------------------------------------------

  NoteCallbacks _callbacks(Note note) => NoteCallbacks(
    onEdit: () {
      if (_selecting) {
        _toggleSelected(note);
      } else {
        _openEditor(note, isNew: false);
      }
    },
    onTogglePin: () {
      HapticFeedback.selectionClick();
      _notes.togglePin(note);
    },
    onToggleItem: (i) => _notes.toggleChecklistItem(note, i),
    onLongPress: () {
      HapticFeedback.mediumImpact();
      if (_selecting) {
        _toggleSelected(note);
      } else {
        _showNoteActions(note);
      }
    },
  );

  Future<void> _showNoteActions(Note note) async {
    final l10n = _l10n;
    final canMove = _notes.boards.length > 1;
    final action = await showActionSheet<String>(
      context,
      children: [
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.edit),
          onTap: () => Navigator.pop(context, 'edit'),
        ),
        if (note.hasPhoto)
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: Text(l10n.viewPhoto),
            onTap: () => Navigator.pop(context, 'photo'),
          ),
        ListTile(
          leading: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
          title: Text(note.pinned ? l10n.unpin : l10n.pin),
          onTap: () => Navigator.pop(context, 'pin'),
        ),
        ListTile(
          leading: Icon(note.locked ? Icons.lock_open : Icons.lock_outline),
          title: Text(note.locked ? l10n.unlock : l10n.lockInPlace),
          onTap: () => Navigator.pop(context, 'lock'),
        ),
        ListTile(
          leading: const Icon(Icons.checklist_rtl),
          title: Text(l10n.select),
          onTap: () => Navigator.pop(context, 'select'),
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
          leading: const Icon(
            Icons.delete_outline,
            color: AppColors.deleteIcon,
          ),
          title: Text(
            l10n.delete,
            style: const TextStyle(color: AppColors.deleteIcon),
          ),
          onTap: () => Navigator.pop(context, 'delete'),
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _openEditor(note, isNew: false);
      case 'photo':
        await showPhotoViewer(context, note.imagePath);
      case 'pin':
        unawaited(HapticFeedback.selectionClick());
        _notes.togglePin(note);
      case 'lock':
        unawaited(HapticFeedback.selectionClick());
        _notes.toggleLock(note);
      case 'select':
        _startSelecting(note);
      case 'move':
        await _moveToBoard([note]);
      case 'share':
        await _captureAndShare(note);
      case 'save':
        await _captureAndSave(note);
      case 'delete':
        await _delete(note);
    }
  }

  Future<void> _moveToBoard(List<Note> notes) async {
    if (notes.isEmpty) return;
    final l10n = _l10n;
    final current = _notes.currentBoardId;
    final targets = _notes.boards.where((b) => b.id != current).toList();
    final target = await showActionSheet<Board>(
      context,
      title: l10n.moveToBoard,
      children: [
        for (final board in targets)
          ListTile(
            leading: board.icon.isEmpty
                ? const Icon(Icons.dashboard_outlined)
                : Text(board.icon, style: const TextStyle(fontSize: 22)),
            title: Text(
              _boardName(board),
              style: board.decorate(const TextStyle()),
            ),
            onTap: () => Navigator.pop(context, board),
          ),
      ],
    );
    if (target == null || !mounted) return;
    _notes.moveAllToBoard(notes, target.id);
    _exitSelecting();
    _toast(l10n.movedToBoard(_boardName(target)));
  }

  RenderRepaintBoundary? _boundaryFor(Note note) {
    final ctx = _captureKeys[_captureId(note)]?.currentContext;
    return ctx?.findRenderObject() as RenderRepaintBoundary?;
  }

  /// The part of the wall on screen, in wall coordinates — or null when the
  /// camera is at rest and the whole wall is in view anyway.
  Rect? get _visibleWallRect {
    final size = _wallHandle.lastSize;
    if (!_camera.moved || size.isEmpty) return null;
    return MatrixUtils.inverseTransformRect(_camera.matrix, Offset.zero & size);
  }

  /// Shows the board as a picture — wall, notes and threads, nothing else —
  /// to share or save. Always the wall layout, whichever view is showing.
  Future<void> _exportBoard() {
    final wall = wallFor(_notes.currentBoard, night: isNight(context));
    final hasWidget = !kIsWeb && Platform.isAndroid;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BoardPosterPage(
          wall: wall,
          decor: widget.settings.wallDecor,
          notes: _notes.boardNotes,
          links: _notes.linksOn(_notes.currentBoardId),
          strokes: _notes.currentBoard.strokes,
          wallSize: _wallHandle.lastSize,
          imageService: _imageService,
          viewport: _notes.viewMode == ViewMode.wall ? _visibleWallRect : null,
          selected: _selecting ? Set.of(_selected) : const {},
          onShowOnWidget: hasWidget ? WidgetService.showWallImage : null,
        ),
      ),
    );
  }

  Future<void> _captureAndShare(Note note) async {
    final boundary = _boundaryFor(note);
    if (boundary == null) return;
    try {
      final bytes = await ImageService.capture(boundary);
      if (bytes != null) {
        await _imageService.sharePng(bytes, subject: _l10n.appTitle);
      }
    } catch (_) {
      /* user cancelled / platform unavailable */
    }
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
    // A photo taken off (or swapped out of) the note: drop its file unless
    // another note still shows it.
    if (oldPhoto.isNotEmpty &&
        result.imagePath != oldPhoto &&
        !_notes.photoInUse(oldPhoto)) {
      unawaited(ImageService.deleteFile(oldPhoto));
    }
  }

  /// Picks photos (several from the gallery, or one from the camera) and pins
  /// each as its own print — at [x],[y] when the user long-pressed a spot.
  Future<void> _pinPhotos({double? x, double? y}) async {
    final l10n = _l10n;
    final source = await showActionSheet<ImageSource>(
      context,
      title: l10n.pinPhotos,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(l10n.fromGallery),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text(l10n.takePhoto),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
      ],
    );
    if (source == null || !mounted) return;
    List<String> stored;
    try {
      stored = source == ImageSource.gallery
          ? await _imageService.pickImages()
          : [?await _imageService.pickImage(source)];
    } catch (_) {
      return; // Permission denied, camera error — nothing to pin.
    }
    if (stored.isEmpty || !mounted) return;
    final created = _notes.addPhotos(stored, x: x, y: y);
    _toast(_l10n.photosPinned(created.length));
  }

  /// Long-press on an empty spot of the wall: a note or photos, right there.
  Future<void> _createAt(double x, double y) async {
    final l10n = _l10n;
    final choice = await showActionSheet<String>(
      context,
      children: [
        ListTile(
          leading: const Icon(Icons.sticky_note_2_outlined),
          title: Text(l10n.noteHere),
          onTap: () => Navigator.pop(context, 'note'),
        ),
        ListTile(
          leading: const Icon(Icons.add_photo_alternate_outlined),
          title: Text(l10n.photosHere),
          onTap: () => Navigator.pop(context, 'photos'),
        ),
      ],
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'note':
        await _openEditor(_notes.draftAt(x, y), isNew: true);
      case 'photos':
        await _pinPhotos(x: x, y: y);
    }
  }

  /// Peels the note off the wall (unless it already animated itself away,
  /// e.g. a swipe-to-dismiss) and drops it in the trash, with Undo.
  Future<void> _delete(Note note, {bool peel = true}) async {
    if (peel) {
      final key = _captureKeys[_captureId(note)];
      if (key != null) await PeelAway.play(context, key);
      if (!mounted) return;
    }
    _notes.delete(note);
    _forgetKeys([note]);
    _undoToast(_l10n.noteDeleted, _notes.undoDelete);
  }

  Future<void> _deleteMany(List<Note> notes, {bool peel = true}) async {
    if (notes.isEmpty) return;
    if (peel) {
      // Peel a handful for the effect; a huge selection just vanishes.
      final keys = [
        for (final n in notes.take(8)) _captureKeys[_captureId(n)],
      ].nonNulls;
      await Future.wait(keys.map((k) => PeelAway.play(context, k)));
      if (!mounted) return;
    }
    _notes.trashAll(notes);
    _forgetKeys(notes);
    _exitSelecting();
    _undoToast(_l10n.notesDeleted(notes.length), _notes.undoDelete);
  }

  void _forgetKeys(Iterable<Note> notes) {
    final guids = {for (final n in notes) n.guid};
    _captureKeys.removeWhere((k, _) => guids.contains(k.split('/').last));
  }

  // --- Multi-select --------------------------------------------------------

  List<Note> get _selectedNotes =>
      _notes.boardNotes.where((n) => _selected.contains(n.guid)).toList();

  void _startSelecting(Note note) {
    HapticFeedback.selectionClick();
    setState(() {
      _selecting = true;
      _selected
        ..clear()
        ..add(note.guid);
    });
  }

  void _toggleSelected(Note note) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(note.guid)) _selected.add(note.guid);
    });
  }

  void _selectAll() {
    final pool = _notes.isFiltering ? _notes.visibleNotes : _notes.boardNotes;
    setState(() => _selected.addAll(pool.map((n) => n.guid)));
  }

  void _exitSelecting() {
    if (!_selecting && _selected.isEmpty) return;
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  Future<void> _recolorSelected() async {
    final notes = _selectedNotes;
    if (notes.isEmpty) return;
    final l10n = _l10n;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.color,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // -1 stands for "auto" (derive from each note's guid).
                  _Swatch(
                    color: AppColors.paper,
                    auto: true,
                    onTap: () => Navigator.pop(context, -1),
                  ),
                  for (final (i, c) in AppColors.notePapers.indexed)
                    _Swatch(color: c, onTap: () => Navigator.pop(context, i)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _notes.recolor(notes, picked < 0 ? null : picked);
  }

  void _pinSelected() {
    final notes = _selectedNotes;
    if (notes.isEmpty) return;
    HapticFeedback.selectionClick();
    _notes.pinAll(notes, !notes.every((n) => n.pinned));
  }

  // --- Layout --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.notes, widget.settings]),
      builder: (context, _) {
        final night = isNight(context);
        final wall = wallFor(_notes.currentBoard, night: night);
        // Only a board or layout change may retarget the slide; unrelated
        // rebuilds (typing in search) must not yank a running transition.
        final boardIndex = _notes.currentBoardIndex;
        if (boardIndex != _lastBoardIndex) {
          _slideDir = boardIndex > _lastBoardIndex ? 1 : -1;
          _lastBoardIndex = boardIndex;
          // A selection belongs to one board.
          _selected.clear();
          _selecting = false;
        } else if (_notes.viewMode != _lastViewMode) {
          _slideDir = 0;
        }
        _lastViewMode = _notes.viewMode;
        final showFabLabel =
            _notes.boardNotes.isEmpty || _notes.viewMode != ViewMode.wall;
        if (_notes.wallEdits != _seenWallEdits) {
          _seenWallEdits = _notes.wallEdits;
          _armUndo();
        }
        // Marker mode belongs to the wall; leaving it ends the session.
        if (_notes.viewMode != ViewMode.wall) _marking = false;

        return Stack(
          children: [
            // Background layers live outside the Scaffold so switching walls
            // crossfades the texture without rebuilding the app content.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: WallBackground(
                  key: ValueKey(
                    '${wall.id}-${wall.imageFile}-${widget.settings.wallDecor}',
                  ),
                  wall: wall,
                  decor: widget.settings.wallDecor,
                  // Only the wall pans; grid and list scroll over a still
                  // background.
                  camera: _notes.viewMode == ViewMode.wall ? _camera : null,
                ),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              // The editor is a dialog above this screen; letting the keyboard
              // squash the wall underneath would make every note slide about
              // behind the barrier while you type.
              resizeToAvoidBottomInset: false,
              floatingActionButton: _selecting || _marking
                  ? null
                  : AddNoteButton(
                      label: _l10n.addNote,
                      onPressed: () => _openEditor(_notes.draft(), isNew: true),
                      onLongPress: _quickAdd,
                      // Shrinks to just the pencil once a free wall has notes
                      // on it, so it covers less of them.
                      extended: showFabLabel,
                    ),
              bottomNavigationBar: _selecting
                  ? _selectionBar(wall)
                  : _marking
                  ? _markerBar(wall)
                  : null,
              body: SafeArea(
                // While the keyboard is up the system reports no bottom
                // padding (the keyboard covers the navigation bar), which
                // would let the wall grow by that strip and every note below
                // the top row slide down with it. Keep the bar's height.
                maintainBottomViewPadding: true,
                child: Column(
                  children: [
                    _buildTitleRow(wall),
                    _buildToolRow(wall),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Stack(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: _contentTransition,
                            child: KeyedSubtree(
                              key: ValueKey(
                                '${_notes.currentBoardId}:${_notes.viewMode.name}',
                              ),
                              child: _buildContent(wall),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 0,
                            right: 0,
                            child: Center(child: _undoPill()),
                          ),
                        ],
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
        final leaving =
            animation.status == AnimationStatus.reverse ||
            animation.status == AnimationStatus.dismissed;
        final dir = leaving ? -_slideDir : _slideDir;
        return FractionalTranslation(
          translation: Offset((1 - v) * 0.10 * dir, 0),
          child: Opacity(opacity: v, child: child),
        );
      },
    );
  }

  BoxDecoration _frosted(WallStyle wall, {double radius = 21}) => BoxDecoration(
    color: wall.dark ? const Color(0x26FFFFFF) : const Color(0x14000000),
    borderRadius: BorderRadius.circular(radius),
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
          child: _selecting
              ? _selectionTitle(wall)
              : _searching
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

  Widget _selectionTitle(WallStyle wall) {
    final text = wall.wallText;
    return Padding(
      key: const ValueKey('select'),
      padding: const EdgeInsets.fromLTRB(0, 3, 8, 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: _frosted(wall),
        child: Row(
          children: [
            IconButton(
              tooltip: _l10n.cancel,
              iconSize: 20,
              icon: Icon(Icons.close, color: text),
              onPressed: _exitSelecting,
            ),
            Expanded(
              child: Text(
                _l10n.selectedCount(_selected.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: _l10n.selectAll,
              iconSize: 22,
              icon: Icon(Icons.select_all, color: text),
              onPressed: _selectAll,
            ),
          ],
        ),
      ),
    );
  }

  /// Bulk actions for the current selection, docked at the bottom.
  Widget _selectionBar(WallStyle wall) {
    final notes = _selectedNotes;
    final any = notes.isNotEmpty;
    final allPinned = any && notes.every((n) => n.pinned);
    final l10n = _l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          decoration: _frosted(wall, radius: 16),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _BarAction(
                icon: allPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: allPinned ? l10n.unpin : l10n.pin,
                color: wall.wallText,
                onTap: any ? _pinSelected : null,
              ),
              _BarAction(
                icon: Icons.palette_outlined,
                label: l10n.color,
                color: wall.wallText,
                onTap: any ? _recolorSelected : null,
              ),
              if (_notes.boards.length > 1)
                _BarAction(
                  icon: Icons.drive_file_move_outlined,
                  label: l10n.move,
                  color: wall.wallText,
                  onTap: any ? () => _moveToBoard(notes) : null,
                ),
              _BarAction(
                icon: Icons.delete_outline,
                label: l10n.delete,
                color: wall.dark
                    ? const Color(0xFFFF8A80)
                    : AppColors.deleteIcon,
                onTap: any ? () => _deleteMany(notes) : null,
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
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Live hit count, so you know when to stop typing.
                        Text(
                          _l10n.resultCount(_notes.visibleNotes.length),
                          style: TextStyle(color: faded, fontSize: 13),
                        ),
                        IconButton(
                          tooltip: _l10n.clear,
                          iconSize: 18,
                          icon: Icon(Icons.close, color: faded),
                          onPressed: _searchController.clear,
                        ),
                      ],
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
          Expanded(
            child: BoardBar(
              notes: _notes,
              textColor: wall.wallText,
              chipKeys: {
                for (final b in _notes.boards)
                  b.id: _chipKeys.putIfAbsent(b.id, GlobalKey.new),
              },
              dropTarget: _dropTarget,
            ),
          ),
          _filterButton(wall),
          if (_notes.viewMode != ViewMode.wall) _sortButton(wall),
          _layoutButton(wall),
          _moreButton(wall),
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
          if (selected) const Icon(Icons.check, size: 18, color: AppColors.ink),
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
      (4, l10n.typePhoto, Icons.photo_outlined),
      (5, l10n.typeLabel, Icons.label_outline),
    ];
    return PopupMenuButton<int>(
      tooltip: l10n.type,
      icon: Badge(
        isLabelVisible: active,
        smallSize: 8,
        backgroundColor: AppColors.accent,
        child: Icon(
          active ? Icons.filter_alt : Icons.filter_alt_outlined,
          color: wall.wallText,
        ),
      ),
      onSelected: (v) => _notes.typeFilter = v,
      itemBuilder: (context) => [
        for (final (key, label, icon) in options)
          _menuItem(key, label, icon: icon, selected: _notes.typeFilter == key),
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
          _menuItem(
            i,
            o.$1,
            icon: o.$2,
            selected:
                _notes.sortByCreated == o.$3 && _notes.sortAscending == o.$4,
          ),
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
          _menuItem(
            mode,
            _layoutLabel(mode),
            icon: _layoutIcon(mode),
            selected: _notes.viewMode == mode,
          ),
      ],
    );
  }

  /// Everything that didn't earn its own button: photos, select, tidy, trash,
  /// lights.
  Widget _moreButton(WallStyle wall) {
    final l10n = _l10n;
    final onWall = _notes.viewMode == ViewMode.wall;
    final canTidy = onWall && _notes.boardNotes.length > 1;
    final night = isNight(context);
    final trashCount = _notes.trashCount;
    return PopupMenuButton<String>(
      tooltip: l10n.moreActions,
      icon: Icon(Icons.more_vert, color: wall.wallText),
      onSelected: (v) {
        switch (v) {
          case 'photos':
            _pinPhotos();
          case 'select':
            if (_notes.boardNotes.isNotEmpty) {
              setState(() {
                _selecting = true;
                _selected.clear();
              });
            }
          case 'tidy':
            HapticFeedback.lightImpact();
            _wallHandle.tidy();
          case 'tidyColor':
            HapticFeedback.lightImpact();
            _wallHandle.tidy(byColor: true);
          case 'export':
            _exportBoard();
          case 'draw':
            _startMarking(wall);
          case 'trash':
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TrashScreen(notes: _notes),
              ),
            );
          case 'lights':
            widget.settings.setNightMode(night ? NightMode.off : NightMode.on);
        }
      },
      itemBuilder: (context) => [
        _menuItem(
          'photos',
          l10n.pinPhotos,
          icon: Icons.add_photo_alternate_outlined,
        ),
        if (_notes.boardNotes.isNotEmpty)
          _menuItem('select', l10n.select, icon: Icons.checklist_rtl),
        if (canTidy) ...[
          _menuItem(
            'tidy',
            l10n.tidy,
            icon: Icons.auto_awesome_mosaic_outlined,
          ),
          _menuItem(
            'tidyColor',
            l10n.tidyByColor,
            icon: Icons.palette_outlined,
          ),
        ],
        if (onWall) _menuItem('draw', l10n.drawOnWall, icon: Icons.gesture),
        if (_notes.boardNotes.isNotEmpty)
          _menuItem('export', l10n.exportBoard, icon: Icons.image_outlined),
        _menuItem(
          'trash',
          trashCount > 0 ? '${l10n.trash} ($trashCount)' : l10n.trash,
          icon: Icons.delete_outline,
        ),
        _menuItem(
          'lights',
          night ? l10n.lightsOn : l10n.lightsOff,
          icon: night ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        ),
      ],
    );
  }

  Widget _buildContent(WallStyle wall) {
    // Wall mode: free-drag canvas with every note on the board. Search and
    // the type filter dim non-matches instead of removing them, so nothing
    // jumps around. Rendered even when empty so the wall still takes taps.
    if (_notes.viewMode == ViewMode.wall) {
      final notes = _notes.boardNotes;
      final boardId = _notes.currentBoardId;
      return WallView(
        notes: notes,
        callbacksFor: _callbacks,
        onMove: _notes.moveNote,
        onMoveMany: _notes.moveNotes,
        onResize: _notes.resizeNote,
        onRotate: _notes.rotateNote,
        onBringToFront: _notes.bringToFront,
        onCreateAt: _createAt,
        onTrash: (dropped) => dropped.length == 1
            ? _delete(dropped.single, peel: false)
            : _deleteMany(dropped, peel: false),
        onLasso: (caught) => setState(() {
          _selected.addAll(caught.map((n) => n.guid));
        }),
        onDragOver: _dragOver,
        onDrop: _dropOnTab,
        lasso: _selecting,
        trashLabel: _l10n.dropToDelete,
        onThreadTap: _editThread,
        strokes: _notes.currentBoard.strokes,
        marking: _marking,
        marker: _marker,
        onInkBegin: _inkBegin,
        onInkChanged: _notes.saveWallStrokes,
        links: _notes.linksOn(boardId),
        onConnect: (a, b) {
          if (_notes.connect(a, b)) {
            HapticFeedback.lightImpact();
            _toast(_l10n.threadTied);
          }
        },
        onCutLink: (link) {
          HapticFeedback.lightImpact();
          _notes.disconnect(link);
          _undoToast(_l10n.threadCut, () => _notes.connect(link.a, link.b));
        },
        onArrange: _notes.arrange,
        handle: _wallHandle,
        camera: _camera,
        selected: _selecting ? _selected : const {},
        captureKeys: {for (final n in notes) n.guid: _keyFor(n)},
        isDimmed: (n) => _notes.isFiltering && !_notes.matches(n),
        resetZoomTooltip: _l10n.resetZoom,
        rotateTooltip: _l10n.rotate,
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
    final content = _notes.viewMode == ViewMode.grid
        ? _grid(notes)
        : _list(notes);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // ~200 px per column: two on a phone, up to six on a wide tablet or
        // desktop window.
        final cols = (constraints.maxWidth / 200).floor().clamp(2, 6);
        return MasonryGridView.count(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          crossAxisCount: cols,
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
              selected: _selecting && _selected.contains(notes[i].guid),
              maxContentLines: 8,
              captureKey: _keyFor(notes[i]),
            ),
          ),
        );
      },
    );
  }

  Widget _list(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final note = notes[i];
        final tile = NoteAppear(
          delay: _staggerFor(i),
          child: NoteListTile(
            note: note,
            cb: _callbacks(note),
            selected: _selecting && _selected.contains(note.guid),
            captureKey: _keyFor(note),
          ),
        );
        // No swipe-to-delete while selecting: swipes would fight with taps
        // that toggle selection.
        if (_selecting) return tile;
        return Dismissible(
          key: ValueKey('dismiss-${note.guid}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _delete(note, peel: false),
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
          child: tile,
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
              fontSize: 20,
              color: faded,
              shadows: wall.wallTextShadows,
            ),
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

/// One icon-over-label button in the selection bar.
class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = onTap == null ? color.withValues(alpha: 0.35) : color;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A colour choice in a sheet (paper colours, yarn colours).
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.onTap,
    this.auto = false,
    this.selected = false,
  });

  final Color color;
  final VoidCallback onTap;
  final bool auto;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: AppColors.ink, width: 3)
              : Border.all(color: Colors.black26),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 3,
              offset: Offset(0, 1.5),
            ),
          ],
        ),
        child: auto
            ? const Icon(Icons.auto_awesome, size: 20, color: AppColors.ink)
            : null,
      ),
    );
  }
}

/// The sheet a tapped thread opens: yarn colour, a label to hang on it, an
/// arrowhead, and the scissors. Changes apply as they are made.
class _ThreadSheet extends StatefulWidget {
  const _ThreadSheet({
    required this.link,
    required this.notes,
    required this.onCut,
  });

  final NoteLink link;
  final NotesController notes;
  final void Function(NoteLink link) onCut;

  @override
  State<_ThreadSheet> createState() => _ThreadSheetState();
}

class _ThreadSheetState extends State<_ThreadSheet> {
  late NoteLink _link = widget.link;
  late final _label = TextEditingController(text: widget.link.label);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _apply(NoteLink next) {
    setState(() => _link = next);
    widget.notes.updateLink(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.thread,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.yarnColor,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in AppColors.yarns)
                  _Swatch(
                    color: Color(c),
                    selected: (_link.color ?? AppColors.yarns.first) == c,
                    onTap: () => _apply(_link.copyWith(color: c)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              maxLength: 24,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.threadLabelHint,
                prefixIcon: const Icon(Icons.sell_outlined),
                counterText: '',
                isDense: true,
              ),
              onChanged: (v) => _apply(_link.copyWith(label: v.trim())),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.arrow_right_alt),
              title: Text(l10n.threadArrow),
              value: _link.arrow,
              onChanged: (v) => _apply(_link.copyWith(arrow: v)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(
                  Icons.content_cut,
                  color: AppColors.deleteIcon,
                ),
                label: Text(
                  l10n.cutThread,
                  style: const TextStyle(color: AppColors.deleteIcon),
                ),
                onPressed: () => widget.onCut(_link),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One marker colour in the drawing bar.
class _InkDot extends StatelessWidget {
  const _InkDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: selected ? 28 : 22,
          height: selected ? 28 : 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.accent : Colors.black26,
              width: selected ? 3 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(0, 1.5),
              ),
            ],
          ),
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
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1.5),
          const Radius.circular(8),
        ),
      );
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

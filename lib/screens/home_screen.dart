import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show FlutterView;

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
import '../services/audio_service.dart';
import '../services/image_service.dart';
import '../services/memory_wall.dart';
import '../services/notes_controller.dart';
import '../services/pro_controller.dart';
import '../services/reminder_service.dart';
import '../services/settings_controller.dart';
import '../services/share_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import '../util/rich_note.dart';
import '../widgets/action_sheet.dart';
import '../widgets/add_note_button.dart';
import '../widgets/board_bar.dart';
import '../widgets/board_poster.dart';
import '../widgets/gesture_tips.dart';
import '../widgets/keyboard_tappable.dart';
import '../widgets/note_dialog.dart';
import '../widgets/note_views.dart';
import '../widgets/peel_away.dart';
import '../widgets/photo_frames.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/pro_sheet.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/stickers.dart';
import '../widgets/thread_style.dart';
import '../widgets/wall_background.dart';
import '../widgets/wall_view.dart';
import 'gallery_screen.dart';
import 'memory_wall_sheet.dart';
import 'trash_screen.dart';

part 'home_screen_actions.dart';
part 'home_screen_chrome.dart';
part 'home_screen_widgets.dart';

const _kToast = Duration(seconds: 3);

/// The main screen: title row, board tabs and tools, then the notes in the
/// current layout (free wall, grid or list) over the wall texture. Also hosts
/// the editor, selection mode, search, share/save and incoming shared content.
class HomeScreen extends StatefulWidget {
  /// Height of the title row, the tool row and the gap under them. On the
  /// wall the notes run underneath this band (the wall fills the body and the
  /// rows float over it), so the wall is told to keep its resting view clear
  /// of it; grid and list simply start below it.
  static const double wallHeaderHeight = 54 + 52 + 6;

  /// Height the floating tool pill (and its margin) takes at the bottom of
  /// the wall: the resting view and the drop tray stay above it.
  static const double wallFooterHeight = 64;

  /// The wall's usable size in logical pixels for [view] — the same
  /// arithmetic the layout does, but available before the first frame, so the
  /// sample notes can be placed in real distances rather than in fractions of
  /// a screen whose size is not known yet. Null when the view has no size.
  static Size? wallSizeFor(FlutterView view) {
    final dpr = view.devicePixelRatio;
    if (dpr <= 0 || view.physicalSize.isEmpty) return null;
    final width = view.physicalSize.width / dpr;
    // The body starts below the status bar; the wall keeps its resting view
    // clear of the two header rows, the tool pill and the system bar.
    final height =
        (view.physicalSize.height - view.padding.top - view.padding.bottom) /
            dpr -
        wallHeaderHeight -
        wallFooterHeight;
    if (width <= 0 || height <= 0) return null;
    return Size(width, height);
  }

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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

  // The gesture tips are offered once, the first time the wall shows.
  bool _tipsOffered = false;

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

  String _captureId(Note note, [ViewMode? mode]) =>
      '${(mode ?? _notes.viewMode).name}/${note.guid}';

  /// The capture key for [note] in the layout being built. A layout takes
  /// its [mode] at build time: while two layouts crossfade, the outgoing one
  /// may still create items lazily, and must not borrow the new mode's keys.
  GlobalKey _keyFor(Note note, [ViewMode? mode]) =>
      _captureKeys.putIfAbsent(_captureId(note, mode), GlobalKey.new);

  /// When the app last left the screen; null while it is in front.
  DateTime? _awayAt;

  /// Private boards shut again once the app has been away a minute, as the
  /// app lock does: a photo picker or share sheet is not a trip away. Coming
  /// back to a shut board closes whatever of it was still open.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _awayAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final away = _awayAt;
        _awayAt = null;
        if (away == null ||
            DateTime.now().difference(away) < const Duration(minutes: 1)) {
          return;
        }
        final wasOpen = _notes.currentBoard.isPrivate;
        _notes.shutPrivateBoards();
        if (wasOpen && _notes.currentBoardShut) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          setState(() {
            _selecting = false;
            _selected.clear();
            _marking = false;
          });
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() => _notes.search = _searchController.text);
    widget.shareReceiver?.listen(_onShared);
    _reminderTaps = ReminderService.opened.listen(_openFromReminder);
    final launched = ReminderService.takeLaunchNote();
    if (launched != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openFromReminder(launched),
      );
    }
  }

  StreamSubscription<String>? _reminderTaps;

  /// A tapped reminder opens its note, on its own board.
  Future<void> _openFromReminder(String guid) async {
    final note = _notes.allNotes
        .where((n) => n.guid == guid && !n.isTrashed)
        .firstOrNull;
    if (note == null || !mounted) return;
    if (!await _makeWayForIncoming() || !mounted) return;
    if (note.boardId != _notes.currentBoardId) _notes.selectBoard(note.boardId);
    // A note on a shut private board opens only after the phone's lock.
    if (_notes.currentBoardShut) {
      final open = await unlockPrivateBoard(
        context,
        _notes,
        _notes.currentBoard,
      );
      if (!open || !mounted) return;
    }
    await _openEditor(note, isNew: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.shareReceiver?.dispose();
    unawaited(_reminderTaps?.cancel());
    _searchController.dispose();
    _camera.dispose();
    _dropTarget.dispose();
    _undoTimer?.cancel();
    super.dispose();
  }

  /// [setState] for the parts of this State built from extensions (the
  /// header, tool pill and marker bar in home_screen_chrome.dart).
  void _update(VoidCallback change) => setState(change);

  static IconData _layoutIcon(ViewMode mode) => switch (mode) {
    // No "+" in it: on the toolbar that read as "add".
    ViewMode.wall => Icons.dashboard_outlined,
    ViewMode.grid => Icons.grid_view_rounded,
    ViewMode.list => Icons.view_agenda_outlined,
  };

  // --- Undo (wall) ---------------------------------------------------------

  /// Shows the Undo pill and arms the timer that hides it again. Called
  /// from build when a new edit is noticed, so it must not set state itself.
  void _armUndo() {
    _undoShown = true;
    _undoTimer?.cancel();
    // Six seconds is too short to find the pill with a screen reader.
    if (MediaQuery.accessibleNavigationOf(context)) return;
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
                padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.undo, size: 18, color: AppColors.chalk),
                    const SizedBox(width: 8),
                    Text(
                      switch (_notes.nextWallUndo) {
                        WallEditKind.move => _l10n.undoMove,
                        WallEditKind.resize => _l10n.undoResize,
                        WallEditKind.rotate => _l10n.undoRotate,
                        WallEditKind.tidy => _l10n.undoTidy,
                        WallEditKind.moveBoard => _l10n.undoMoveBoard,
                        null => _l10n.undo,
                      },
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

  // --- Marker mode (methods in home_screen_chrome.dart) ----------------
  List<DrawStroke> get _wallStrokes => _notes.currentBoard.strokes;

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

  /// A fresh install opens on the sample wall with three ways to start: keep
  /// exploring it, clear it, or pick a template. One sheet, never again.
  Future<void> _welcome() async {
    final l10n = _l10n;
    widget.settings.markWelcomeSeen();
    ListTile choice(String value, IconData icon, String title, String hint) =>
        ListTile(
          leading: Icon(icon, size: 28),
          title: Text(title, style: const TextStyle(fontSize: 18)),
          subtitle: Text(hint),
          onTap: () => Navigator.pop(context, value),
        );
    final picked = await showActionSheet<String>(
      context,
      title: l10n.welcomeTitle,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(l10n.welcomeBody, style: const TextStyle(fontSize: 15)),
        ),
        choice(
          'template',
          Icons.dashboard_customize_outlined,
          l10n.welcomeTemplate,
          l10n.welcomeTemplateHint,
        ),
        choice(
          'blank',
          Icons.crop_square,
          l10n.welcomeBlank,
          l10n.welcomeBlankHint,
        ),
        choice(
          'explore',
          Icons.travel_explore_outlined,
          l10n.welcomeExplore,
          l10n.welcomeExploreHint,
        ),
      ],
    );
    if (!mounted) return;
    switch (picked) {
      case 'blank':
        _notes.discardSamples(_notes.currentBoardId);
      case 'template':
        final board = _notes.currentBoardId;
        final firstRun = {for (final n in _notes.sampleNotes(board)) n.guid};
        final result = await GalleryScreen.open(
          context,
          notes: _notes,
          into: board,
        );
        if (!mounted) return;
        // The template takes the samples' place; backing out keeps them.
        if (result is TemplateUsed) {
          _notes.discardSamples(board, only: firstRun);
        }
        showGalleryResult(context, result);
    }
  }

  Future<void> _showTips() async {
    await showGestureTips(context);
    widget.settings.markTipsSeen();
  }

  /// Every kind of note, from the "Other kinds" pill or a long press on the
  /// add button. The everyday kinds come first; the voice note, which needs
  /// the microphone, sits last under its own line.
  Future<void> _quickAdd() async {
    final l10n = _l10n;
    unawaited(HapticFeedback.mediumImpact());
    ListTile tile(NoteType t, IconData icon, String label) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.pop(context, t),
    );
    var memory = false;
    final type = await showActionSheet<NoteType>(
      context,
      title: l10n.addNote,
      children: [
        tile(NoteType.normal, Icons.notes, l10n.typeNormal),
        tile(NoteType.checklist, Icons.checklist, l10n.typeChecklist),
        tile(NoteType.photo, Icons.photo_outlined, l10n.typePhoto),
        tile(NoteType.link, Icons.link, l10n.typeLink),
        tile(NoteType.drawing, Icons.brush_outlined, l10n.typeDrawing),
        tile(NoteType.label, Icons.label_outline, l10n.typeLabel),
        tile(NoteType.sticker, Icons.emoji_emotions_outlined, l10n.typeSticker),
        ListTile(
          leading: const Icon(Icons.photo_album_outlined),
          title: Text(l10n.memoryWall),
          subtitle: Text(l10n.memoryWallHint),
          onTap: () {
            memory = true;
            Navigator.pop(context);
          },
        ),
        const Divider(height: 1),
        tile(NoteType.audio, Icons.voicemail, l10n.typeAudio),
      ],
    );
    if (memory && mounted) {
      await _newMemoryWall();
      return;
    }
    if (type == null || !mounted) return;
    if (type == NoteType.sticker) {
      await _addSticker();
      return;
    }
    await _openEditor(_notes.draft()..type = type, isNew: true);
  }

  /// A memory wall: several photos from the gallery, then a layout and a
  /// look, and a new board of editable prints.
  Future<void> _newMemoryWall({List<String>? photos}) async {
    final l10n = _l10n;
    List<String> stored;
    if (photos != null) {
      stored = photos;
    } else {
      try {
        stored = await _imageService.pickImages();
      } catch (_) {
        if (mounted) _toast(l10n.photoPickFailed);
        return;
      }
    }
    if (stored.isEmpty || !mounted) return;
    final choice = await showMemoryWallSheet(context, count: stored.length);
    if (!mounted) return;
    if (choice == null) {
      // Copied in for nothing: nothing refers to them.
      for (final f in stored) {
        unawaited(ImageService.deleteFile(f));
      }
      return;
    }
    final used = stored.take(memoryWallMax).toList();
    for (final f in stored.skip(memoryWallMax)) {
      unawaited(ImageService.deleteFile(f));
    }
    _notes.addMemoryWall(
      l10n.memoryTitle,
      used,
      choice.layout,
      pack: choice.look,
      frame: choice.frame,
      caption: choice.caption,
      date: MaterialLocalizations.of(context).formatMediumDate(DateTime.now()),
    );
    _toast(l10n.memoryMade(used.length));
  }

  /// Picks a sticker and sticks it on the wall, at [x],[y] when the user
  /// long-pressed a spot.
  Future<void> _addSticker({double? x, double? y}) async {
    final id = await showStickerPicker(context);
    if (id == null || !mounted) return;
    if (_notes.viewMode != ViewMode.wall) _notes.viewMode = ViewMode.wall;
    _notes.addSticker(id, x: x, y: y);
    _maybeOfferPro();
  }

  /// A tap on a sticker swaps it for another one.
  Future<void> _changeSticker(Note note) async {
    final id = await showStickerPicker(context, current: note.sticker);
    if (id == null || id == note.sticker || !mounted) return;
    _notes.update(note.clone()..sticker = id);
  }

  /// Once, for someone who has used the app for a week and filled a wall,
  /// a quiet line about Pro — never a popup, never at start-up.
  void _maybeOfferPro() {
    final pro = ProScope.maybeOf(context);
    if (pro == null || pro.unlocked) return;
    final settings = widget.settings;
    if (!settings.shouldOfferPro(
      noteCount: _notes.allNotes.where((n) => !n.isTrashed).length,
    )) {
      return;
    }
    settings.markProOffered();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_l10n.proNudge),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: _l10n.proNudgeAction,
            onPressed: () => showProSheet(context),
          ),
        ),
      );
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
  /// Text, a link or a picture shared from another app: which board it
  /// goes on (when there is a choice), then straight onto that wall, with
  /// Open and Undo, rather than an editor to fill in first.
  Future<void> _onShared(SharedContent content) async {
    // The same payload delivered twice (a resume, a replayed intent) is
    // handled once.
    if (!_handledShares.add(content.signature)) return;
    // Whatever was open gives way — an editor only once its user has saved
    // or let go of their edits.
    if (!await _makeWayForIncoming() || !mounted) return;
    if (content.imagePaths.length > 1) {
      await _onSharedPhotos(content.imagePaths);
      return;
    }
    final board = await _pickShareBoard();
    if (board == null || !mounted) return;
    await _sharedNote(content, board);
  }

  final _handledShares = <String>{};

  /// Several photos from another app: pinned as prints on a board, or made
  /// into a memory wall. Every one is copied in first (the sender's access
  /// can lapse); any that could not be used are counted aloud.
  Future<void> _onSharedPhotos(List<String> paths) async {
    final l10n = _l10n;
    final (stored, skipped) = await _imageService.importSharedImages(paths);
    if (!mounted) return;
    if (skipped > 0) _toast(l10n.sharedSkipped(skipped));
    if (stored.isEmpty) return;
    final choice = stored.length < 2
        ? 'pin'
        : await showActionSheet<String>(
            context,
            title: l10n.sharedPhotos(stored.length),
            children: [
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: Text(l10n.sharePinPhotos),
                subtitle: Text(l10n.sharePinPhotosHint),
                onTap: () => Navigator.pop(context, 'pin'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_album_outlined),
                title: Text(l10n.memoryWall),
                subtitle: Text(l10n.memoryWallHint),
                onTap: () => Navigator.pop(context, 'memory'),
              ),
            ],
          );
    if (!mounted) return;
    void forget() {
      // Copied in for nothing: nothing refers to them.
      for (final f in stored) {
        unawaited(ImageService.deleteFile(f));
      }
    }

    if (choice == 'memory') {
      await _newMemoryWall(photos: stored);
      return;
    }
    if (choice != 'pin') return forget();
    final board = await _pickShareBoard();
    if (board == null || !mounted) return forget();
    if (_notes.viewMode != ViewMode.wall) _notes.viewMode = ViewMode.wall;
    final created = _notes.addPhotos(stored);
    if (skipped == 0) _toast(l10n.photosPinned(created.length));
  }

  /// Which board something shared goes on (asked only when there is a
  /// choice), opened and unlocked; null when the user backed out.
  Future<Board?> _pickShareBoard() async {
    final l10n = _l10n;
    var board = _notes.currentBoard;
    if (_notes.boards.length > 1) {
      final current = _notes.currentBoard;
      final picked = await showActionSheet<Board>(
        context,
        title: l10n.shareWhere,
        children: [
          for (final b in [
            current,
            ..._notes.boards.where((b) => b.id != current.id),
          ])
            ListTile(
              leading: b.isPrivate
                  ? const Icon(Icons.lock_outline)
                  : b.icon.isEmpty
                  ? const Icon(Icons.dashboard_outlined)
                  : Text(b.icon, style: const TextStyle(fontSize: 22)),
              title: Text(b.name.isEmpty ? l10n.defaultBoardName : b.name),
              trailing: b.id == current.id ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, b),
            ),
        ],
      );
      if (picked == null || !mounted) return null;
      board = picked;
    }
    // A shut private board opens first, so nothing lands where it cannot be
    // seen.
    if (!_notes.isOpen(board)) {
      final open = await unlockPrivateBoard(context, _notes, board);
      if (!open || !mounted) return null;
    }
    _notes.selectBoard(board.id);
    return board;
  }

  /// One shared text, link or photo as a note on [board].
  Future<void> _sharedNote(SharedContent content, Board board) async {
    final l10n = _l10n;
    final note = _notes.draft();
    if (content.imagePath.isNotEmpty) {
      final stored = await _imageService.importSharedImage(content.imagePath);
      if (!mounted) return;
      if (stored != null) {
        note.imagePath = stored;
      } else {
        _toast(l10n.photoPickFailed);
        if (content.text.isEmpty && content.url.isEmpty) return;
      }
    }
    note.content = content.text;
    if (content.url.isNotEmpty) {
      note
        ..type = NoteType.link
        ..url = content.url;
      // An untitled link shows its address on the card.
      if (note.content.isEmpty) note.content = content.url;
      final key = content.url.toLowerCase().replaceFirst(
        RegExp(r'^https?://(www\.)?'),
        '',
      );
      final same = _notes.boardNotes.where(
        (n) =>
            n.type == NoteType.link &&
            n.url.toLowerCase().replaceFirst(
                  RegExp(r'^https?://(www\.)?'),
                  '',
                ) ==
                key,
      );
      if (same.isNotEmpty) {
        _toast(l10n.duplicateExists);
        return;
      }
    } else if (note.hasPhoto && content.text.isEmpty) {
      // A bare picture becomes a print on the wall, not a note about one.
      note.type = NoteType.photo;
    }
    _notes.add(note);
    final name = board.name.isEmpty ? l10n.defaultBoardName : board.name;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text(l10n.sharedSaved(name))),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  final saved = _notes.allNotes
                      .where((n) => n.guid == note.guid && !n.isTrashed)
                      .firstOrNull;
                  if (saved != null) _openEditor(saved, isNew: false);
                },
                child: Text(l10n.openNote),
              ),
            ],
          ),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () {
              _notes.delete(note);
              _forgetKeys([note]);
            },
          ),
        ),
      );
  }

  /// Completes when the open editor closes; null while none is open.
  Completer<void>? _editorClosed;

  /// Before a share or a tapped reminder opens the editor: an editor that is
  /// already open closes the way its user decides — Save, or Discard when
  /// asked — rather than being popped with its edits. Sheets and menus just
  /// give way. False when the user chose to keep editing.
  Future<bool> _makeWayForIncoming() async {
    final open = _editorClosed;
    if (open != null) {
      unawaited(Navigator.of(context).maybePop());
      await open.future;
      if (!mounted || _editorClosed != null) return false;
    }
    if (!mounted) return false;
    Navigator.of(context).popUntil((route) => route.isFirst);
    return true;
  }

  Future<void> _openEditor(Note note, {required bool isNew}) async {
    // A sticker has nothing to write on: "editing" it picks another one.
    if (note.type == NoteType.sticker && !isNew) {
      await _changeSticker(note);
      return;
    }
    final oldPhoto = note.imagePath;
    final oldAudio = note.audioPath;
    final closed = _editorClosed = Completer<void>();
    final Note? result;
    try {
      result = await showNoteDialog(
        context,
        note: note,
        isNew: isNew,
        existing: _notes.boardNotes,
        onDelete: isNew ? null : () => _delete(note),
        readable: widget.settings.readableEditor,
        onReadable: widget.settings.setReadableEditor,
      );
    } finally {
      _editorClosed = null;
      closed.complete();
    }
    if (result == null || !mounted) return;
    if (isNew) {
      _notes.add(result);
      _maybeOfferPro();
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
    // Likewise a recording deleted or recorded over in the editor.
    if (oldAudio.isNotEmpty &&
        result.audioPath != oldAudio &&
        !_notes.audioInUse(oldAudio)) {
      unawaited(AudioService.deleteFile(oldAudio));
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
      // Permission denied, camera error — nothing to pin, but say so.
      if (mounted) _toast(_l10n.photoPickFailed);
      return;
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
        ListTile(
          leading: const Icon(Icons.emoji_emotions_outlined),
          title: Text(l10n.stickerHere),
          onTap: () => Navigator.pop(context, 'sticker'),
        ),
      ],
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'note':
        await _openEditor(_notes.draftAt(x, y), isNew: true);
      case 'photos':
        await _pinPhotos(x: x, y: y);
      case 'sticker':
        await _addSticker(x: x, y: y);
    }
  }

  /// Peels the note off the wall (unless it already animated itself away,
  /// e.g. a swipe-to-dismiss) and drops it in the trash, with Undo.
  Future<void> _delete(Note note, {bool peel = true}) async {
    if (peel && !MediaQuery.disableAnimationsOf(context)) {
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
    if (peel && !MediaQuery.disableAnimationsOf(context)) {
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
    final pro = ProScope.unlockedOf(context);
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
                    name: paperName(_l10n, null),
                    color: AppColors.paper,
                    auto: true,
                    onTap: () => Navigator.pop(context, -1),
                  ),
                  for (final (i, c) in AppColors.notePapers.indexed)
                    _Swatch(
                      name: paperName(_l10n, i),
                      color: c,
                      locked: !pro && i >= AppColors.freePapers,
                      // A Pro paper without Pro: -2 opens the Pro sheet.
                      onTap: () => Navigator.pop(
                        context,
                        !pro && i >= AppColors.freePapers ? -2 : i,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked == -2) {
      await showProSheet(context);
      return;
    }
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
    // Back leaves a mode before it leaves the app: marker, then selection,
    // then search.
    return PopScope(
      canPop: !(_marking || _selecting || _searching),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_marking) {
          _stopMarking();
        } else if (_selecting) {
          _exitSelecting();
        } else if (_searching) {
          _setSearching(false);
        }
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.notes, widget.settings]),
        builder: (context, _) {
          final night = isNight(context);
          final wall = wallFor(
            _notes.currentBoard,
            night: night,
            tryWall: widget.settings.tryWall,
          );
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
          final onWall = _notes.viewMode == ViewMode.wall;
          // The tool pill sits bottom-left; on narrow phones an extended FAB
          // next to it would not fit, so the label only shows on wide screens.
          final wide = MediaQuery.sizeOf(context).width >= 420;
          final showFabLabel = (_notes.boardNotes.isEmpty || !onWall) && wide;
          if (_notes.wallEdits != _seenWallEdits) {
            _seenWallEdits = _notes.wallEdits;
            _armUndo();
          }
          // Marker mode belongs to the wall; leaving it ends the session.
          if (_notes.viewMode != ViewMode.wall) _marking = false;
          if (onWall && !_tipsOffered && widget.settings.welcomePending) {
            _tipsOffered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _welcome();
            });
          } else if (onWall && !_tipsOffered && widget.settings.tipsPending) {
            _tipsOffered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showTips();
            });
          }

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
                    soften: widget.settings.wallSoften,
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
                floatingActionButton:
                    _selecting || _marking || _notes.currentBoardShut
                    ? null
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _moreKindsButton(wall),
                          const SizedBox(height: 12),
                          AddNoteButton(
                            label: _l10n.addNote,
                            onPressed: () =>
                                _openEditor(_notes.draft(), isNew: true),
                            onLongPress: _quickAdd,
                            // Shrinks to just the pencil once a free wall has
                            // notes on it, so it covers less of them.
                            extended: showFabLabel,
                          ),
                        ],
                      ),
                body: SafeArea(
                  // On the wall the body runs under the system bar too (the
                  // wall keeps its resting view clear of it); grid and list
                  // stop above it.
                  bottom: !onWall,
                  // While the keyboard is up the system reports no bottom
                  // padding (the keyboard covers the navigation bar), which
                  // would let the wall grow by that strip and every note below
                  // the top row slide down with it. Keep the bar's height.
                  maintainBottomViewPadding: true,
                  child: Stack(
                    children: [
                      // The content fills the body; each layout keeps its own
                      // place under the header (see _buildContent).
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 260),
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
                      ),
                      // A breath of shade behind the rows, so they stay legible
                      // over a note passing underneath.
                      if (onWall)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: HomeScreen.wallHeaderHeight + 16,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (wall.dark ? Colors.black : Colors.white)
                                        .withValues(alpha: 0.32),
                                    (wall.dark ? Colors.black : Colors.white)
                                        .withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Positioned like everything else here, so the Stack
                      // fills the body rather than shrinking to the rows.
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        // The rows have fixed heights the wall is laid out
                        // under; large system text grows them only so far.
                        // Notes and sheets scale freely.
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTitleRow(wall),
                              _buildToolRow(wall),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: HomeScreen.wallHeaderHeight + 6,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _filterPill(),
                            ),
                            if (_searching) _otherBoardsPill(),
                            _undoPill(),
                          ],
                        ),
                      ),
                      // The same breath of shade along the bottom, behind the
                      // tool pill and the add button.
                      if (onWall)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height:
                              HomeScreen.wallFooterHeight +
                              MediaQuery.viewPaddingOf(context).bottom +
                              28,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    (wall.dark ? Colors.black : Colors.white)
                                        .withValues(alpha: 0.32),
                                    (wall.dark ? Colors.black : Colors.white)
                                        .withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // The selection and marker bars float over the body too
                      // (not docked): docking would shrink the body, and with
                      // it the wall, nudging every note up the moment either
                      // bar appears. Each bar carries its own SafeArea.
                      if (_selecting || _marking)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _selecting
                              ? _selectionBar(wall)
                              : _markerBar(wall),
                        ),
                      // Tools live in a pill at the bottom, thumb-side, so the
                      // top row is all board tabs. The selection and marker
                      // bars take its place (the selection bar carries the ⋮
                      // menu, which exports the selection).
                      if (!_selecting && !_marking && !_notes.currentBoardShut)
                        Positioned(
                          // The same 16dp margin as the board tabs above.
                          left: 16,
                          bottom:
                              12 +
                              (onWall
                                  ? MediaQuery.viewPaddingOf(context).bottom
                                  : 0),
                          child: _toolPill(wall),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
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

  Widget _buildContent(WallStyle wall) {
    // A private board stays behind its cover until the phone's lock is given.
    if (_notes.currentBoardShut) {
      return _PrivateBoardCover(
        wall: wall,
        onUnlock: () =>
            unlockPrivateBoard(context, _notes, _notes.currentBoard),
      );
    }
    // Wall mode: free-drag canvas with every note on the board. Search and
    // the type filter dim non-matches instead of removing them, so nothing
    // jumps around. Rendered even when empty so the wall still takes taps.
    if (_notes.viewMode == ViewMode.wall) {
      // Each stack shows as its top card.
      final notes = _notes.wallNotes;
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
        onLasso: (caught) => setState(() {
          _selected.addAll(caught.map((n) => n.guid));
        }),
        onDragOver: _dragOver,
        onDrop: _dropOnTab,
        lasso: _selecting,
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
          _undoToast(_l10n.threadCut, () => _notes.restoreLink(link));
        },
        onArrange: _notes.arrange,
        handle: _wallHandle,
        camera: _camera,
        selected: _selecting ? _selected : const {},
        captureKeys: {for (final n in notes) n.guid: _keyFor(n, ViewMode.wall)},
        isDimmed: (n) => _notes.isFiltering && !_notes.matches(n),
        resetZoomTooltip: _l10n.resetZoom,
        fitAllTooltip: _l10n.fitAll,
        rotateTooltip: _l10n.rotate,
        resizeTooltip: _l10n.resize,
        stackSizeOf: (n) => _notes.stackOf(n).length,
        emptyHint: _emptyState(wall, tip: _l10n.wallCreateHint),
        // The wall fills the body: notes pan under the header rows and the
        // system bar, while its resting view stays between them.
        topInset: HomeScreen.wallHeaderHeight,
        bottomInset:
            MediaQuery.viewPaddingOf(context).bottom +
            HomeScreen.wallFooterHeight,
      );
    }

    // Grid and list sit below the header rows (the body starts above them).
    const below = EdgeInsets.only(top: HomeScreen.wallHeaderHeight);
    final notes = _notes.visibleNotes;
    if (notes.isEmpty) {
      return Padding(
        padding: below,
        child: _notes.boardNotes.isNotEmpty && _notes.isFiltering
            ? _noMatches(wall)
            : _emptyState(wall),
      );
    }

    // Grid: swipe horizontally to move between boards. Not in the list,
    // where a sideways swipe on a row already means delete.
    if (_notes.viewMode == ViewMode.list) {
      return Padding(padding: below, child: _list(notes));
    }
    final content = _grid(notes);
    return Padding(
      padding: below,
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -250) {
            _notes.selectBoardAt(_notes.currentBoardIndex + 1);
          } else if (v > 250) {
            _notes.selectBoardAt(_notes.currentBoardIndex - 1);
          }
        },
        child: content,
      ),
    );
  }

  Duration _staggerFor(int index) =>
      Duration(milliseconds: 25 * math.min(index, 12));

  Widget _grid(List<Note> notes) {
    const mode = ViewMode.grid;
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
              captureKey: _keyFor(notes[i], mode),
            ),
          ),
        );
      },
    );
  }

  Widget _list(List<Note> notes) {
    const mode = ViewMode.list;
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
            captureKey: _keyFor(note, mode),
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

  void _clearFilters() {
    _notes.typeFilter = -1;
    if (_searching) _setSearching(false);
  }

  String _typeName(int filter) => switch (filter) {
    0 => _l10n.typeNormal,
    1 => _l10n.typeLink,
    2 => _l10n.typeChecklist,
    3 => _l10n.typeDrawing,
    4 => _l10n.typePhoto,
    5 => _l10n.typeLabel,
    6 => _l10n.typeAudio,
    _ => _l10n.typeAll,
  };

  /// On the wall a filter only dims cards, so say that one is on — and how
  /// to turn it off — instead of leaving a wall of faded notes unexplained.
  /// It is remembered across launches, which makes this matter more.
  Widget _filterPill() {
    final filtering = _notes.typeFilter != -1;
    final none =
        _notes.isFiltering &&
        _notes.boardNotes.isNotEmpty &&
        !_notes.boardNotes.any(_notes.matches);
    if (_notes.viewMode != ViewMode.wall || _selecting || _marking) {
      return const SizedBox.shrink();
    }
    if (!filtering && !none) return const SizedBox.shrink();
    final label = [
      if (filtering) _l10n.filterShowing(_typeName(_notes.typeFilter)),
      if (none) _l10n.noMatches,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.overlayDark,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_alt, size: 16, color: AppColors.chalk),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.chalk, fontSize: 14),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                onPressed: _clearFilters,
                child: Text(_l10n.clearFilter),
              ),
            ],
          ),
        ),
      ),
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
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: wall.wallText),
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: Text(_l10n.clearFilter),
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
                      color: faded,
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

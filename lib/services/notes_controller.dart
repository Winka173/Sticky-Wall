import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/board.dart';
import '../models/note.dart';
import '../models/view_mode.dart';
import '../util/text_fold.dart';
import 'note_storage.dart';
import 'reminder_service.dart';

/// Removes a stored file that no note or board refers to any more.
typedef FileRemover = void Function(String stored);

/// Owns the boards, notes, threads and list/view state, persists every change
/// through [NoteStorage], and notifies the UI to rebuild.
///
/// Deleted notes are not removed straight away: they sit in the trash (with
/// [Note.deletedAt] set) for [trashRetention] and can be restored, then are
/// purged for good on the next launch.
class NotesController extends ChangeNotifier {
  NotesController(
    this._storage,
    this._reminders, {
    FileRemover? deletePhoto,
    FileRemover? deleteWallImage,
  })  : _deletePhoto = deletePhoto ?? _noop,
        _deleteWallImage = deleteWallImage ?? _noop {
    _load();
  }

  static void _noop(String _) {}

  /// How long a note stays in the trash before it is purged.
  static const trashRetention = Duration(days: 30);

  final NoteStorage _storage;
  final ReminderService _reminders;
  final FileRemover _deletePhoto;
  final FileRemover _deleteWallImage;
  final _uuid = const Uuid();

  final List<Board> _boards = [];
  final List<Note> _notes = [];
  final List<NoteLink> _links = [];
  late String _currentBoardId;

  late ViewMode _viewMode;
  late int _typeFilter;
  late bool _sortByCreated;
  late bool _sortAscending;
  String _search = '';

  // The most recently trashed note(s), kept so a Snackbar can undo it.
  List<Note> _lastDeleted = const [];

  void _load() {
    _boards
      ..clear()
      ..addAll(_storage.loadBoards());
    _notes
      ..clear()
      ..addAll(_storage.loadNotes());
    _links
      ..clear()
      ..addAll(_storage.loadLinks());

    // First run (or upgrade from the single-list version): create a default
    // board and adopt any existing notes into it.
    if (_boards.isEmpty) {
      final board = Board(id: 'default', name: '', wallIndex: 0);
      _boards.add(board);
      for (final note in _notes) {
        note.boardId = board.id;
      }
      _storage.saveBoards(_boards);
      _storage.saveNotes(_notes);
    }

    _currentBoardId = _storage.currentBoardId ?? _boards.first.id;
    if (_boards.every((b) => b.id != _currentBoardId)) {
      _currentBoardId = _boards.first.id;
    }

    _viewMode = _storage.viewMode;
    _typeFilter = _storage.typeFilter;
    _sortByCreated = _storage.sortByCreated;
    _sortAscending = _storage.sortAscending;

    // Housekeeping that only needs to happen once per launch.
    final now = DateTime.now();
    final expired = _notes
        .where((n) =>
            n.deletedAt != null &&
            now.difference(n.deletedAt!) > trashRetention)
        .toList();
    var changed = false;
    for (final note in expired) {
      _purge(note);
      changed = true;
    }
    if (_storage.autoTrashDone) {
      changed |= _sweepCompleted(const Duration(days: 1), now);
    }
    if (changed) _persistNotes();
  }

  // --- Boards --------------------------------------------------------------

  List<Board> get boards => List.unmodifiable(_boards);
  String get currentBoardId => _currentBoardId;

  Board get currentBoard =>
      _boards.firstWhere((b) => b.id == _currentBoardId,
          orElse: () => _boards.first);

  int get currentBoardIndex =>
      _boards.indexWhere((b) => b.id == _currentBoardId).clamp(0, _boards.length - 1);

  void selectBoard(String id) {
    if (id == _currentBoardId) return;
    _currentBoardId = id;
    _storage.setCurrentBoardId(id);
    notifyListeners();
  }

  void selectBoardAt(int index) {
    if (index < 0 || index >= _boards.length) return;
    selectBoard(_boards[index].id);
  }

  /// Creates a board with the given tab appearance and switches to it.
  Board addBoard(
    String name, {
    String icon = '',
    bool bold = false,
    bool italic = false,
    bool underline = false,
  }) {
    final board = Board(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      bold: bold,
      italic: italic,
      underline: underline,
    );
    _boards.add(board);
    _storage.saveBoards(_boards);
    selectBoard(board.id);
    return board;
  }

  /// Changes how a board's tab reads; anything left null keeps its value.
  void updateBoard(
    String id, {
    String? name,
    String? icon,
    bool? bold,
    bool? italic,
    bool? underline,
  }) {
    final board = _boards.firstWhere((b) => b.id == id);
    if (name != null) board.name = name;
    if (icon != null) board.icon = icon;
    if (bold != null) board.bold = bold;
    if (italic != null) board.italic = italic;
    if (underline != null) board.underline = underline;
    _storage.saveBoards(_boards);
    notifyListeners();
  }

  /// Moves the board tab at [oldIndex] so it ends up at [newIndex] (the final
  /// position, as `ReorderableListView.onReorderItem` reports it).
  void reorderBoards(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _boards.length) return;
    newIndex = newIndex.clamp(0, _boards.length - 1);
    if (oldIndex == newIndex) return;
    _boards.insert(newIndex, _boards.removeAt(oldIndex));
    _storage.saveBoards(_boards);
    notifyListeners();
  }

  /// Removes a board and all its notes (trashed ones included) for good.
  /// Keeps at least one board.
  void deleteBoard(String id) {
    if (_boards.length <= 1) return;
    final board = _boards.firstWhere((b) => b.id == id);
    _boards.remove(board);
    for (final note in _notes.where((n) => n.boardId == id).toList()) {
      _purge(note);
    }
    if (board.hasWallImage) _deleteWallImage(board.wallImage);
    // Undo would resurrect a note onto a board that no longer exists.
    _lastDeleted = _lastDeleted.where((n) => n.boardId != id).toList();
    if (_currentBoardId == id) _currentBoardId = _boards.first.id;
    _storage
      ..saveBoards(_boards)
      ..setCurrentBoardId(_currentBoardId);
    _persistNotes();
    notifyListeners();
  }

  /// Switches the current board to one of the built-in textures, dropping
  /// any photo it had.
  void setCurrentBoardWall(int wallIndex) {
    final board = currentBoard;
    if (board.hasWallImage) _deleteWallImage(board.wallImage);
    board
      ..wallIndex = wallIndex
      ..wallImage = ''
      ..wallImageDark = false;
    _storage.saveBoards(_boards);
    notifyListeners();
  }

  /// Uses the user's own photo (already copied by `ImageService`) as the
  /// current board's wall. [dark] picks the scrim that keeps text readable.
  void setCurrentBoardWallImage(String stored, {required bool dark}) {
    final board = currentBoard;
    if (board.hasWallImage && board.wallImage != stored) {
      _deleteWallImage(board.wallImage);
    }
    board
      ..wallImage = stored
      ..wallImageDark = dark;
    _storage.saveBoards(_boards);
    notifyListeners();
  }

  // --- View state ----------------------------------------------------------

  ViewMode get viewMode => _viewMode;
  set viewMode(ViewMode mode) {
    _viewMode = mode;
    _storage.setViewMode(mode);
    notifyListeners();
  }

  int get typeFilter => _typeFilter;
  set typeFilter(int value) {
    _typeFilter = value;
    _storage.setTypeFilter(value);
    notifyListeners();
  }

  bool get sortByCreated => _sortByCreated;
  bool get sortAscending => _sortAscending;

  void setSort({required bool byCreated, required bool ascending}) {
    if (_sortByCreated == byCreated && _sortAscending == ascending) return;
    _sortByCreated = byCreated;
    _sortAscending = ascending;
    _storage
      ..setSortByCreated(byCreated)
      ..setSortAscending(ascending);
    notifyListeners();
  }

  String get search => _search;
  set search(String value) {
    _search = value;
    notifyListeners();
  }

  // --- Note queries --------------------------------------------------------

  /// Live (not trashed) notes on the current board, unsorted — the free wall
  /// view draws them in this order, so later means on top.
  List<Note> get boardNotes => _notes
      .where((n) => n.boardId == _currentBoardId && !n.isTrashed)
      .toList();

  /// True when a search or type filter is narrowing the notes shown.
  bool get isFiltering => _search.trim().isNotEmpty || _typeFilter != -1;

  /// Whether [note] passes the current type filter and search. Search is
  /// case- and diacritic-insensitive ("tuoi" finds "Tưới").
  bool matches(Note note) {
    final matchesType = switch (_typeFilter) {
      0 => note.type == NoteType.normal,
      1 => note.type == NoteType.link,
      2 => note.type == NoteType.checklist,
      3 => note.type == NoteType.drawing,
      _ => true,
    };
    if (!matchesType) return false;
    final search = foldText(_search.trim());
    if (search.isEmpty) return true;
    final haystack = foldText([
      note.content,
      note.url,
      ...note.checklist.map((i) => i.text),
    ].join(' '));
    return haystack.contains(search);
  }

  /// Notes on the current board, filtered by type/search and sorted, for the
  /// grid and list views. Pinned notes come first.
  List<Note> get visibleNotes {
    final filtered = boardNotes.where(matches).toList();

    filtered.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final int cmp;
      if (_sortByCreated) {
        cmp = a.createdAt.compareTo(b.createdAt);
      } else {
        cmp = a.content.toLowerCase().compareTo(b.content.toLowerCase());
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  // --- Note mutations ------------------------------------------------------

  Note _newNoteAt(double x, double y) => Note(
        guid: _uuid.v4(),
        content: '',
        createdAt: DateTime.now(),
        boardId: _currentBoardId,
        x: x,
        y: y,
      );

  /// Builds a blank note positioned near the wall center with a small random
  /// offset, so several new notes don't stack exactly.
  Note draft() {
    final rng = math.Random();
    return _newNoteAt(0.30 + rng.nextDouble() * 0.30,
        0.28 + rng.nextDouble() * 0.30);
  }

  Note draftAt(double x, double y) => _newNoteAt(x, y);

  void add(Note note) {
    _refreshCompleted(note);
    _notes.add(note);
    _persistNotes();
    _reminders.sync(note);
    notifyListeners();
  }

  /// Replaces the stored note that has the same guid (the dialog edits a
  /// clone), preserving its position in the list.
  void update(Note note) {
    _refreshCompleted(note);
    final i = _notes.indexWhere((n) => n.guid == note.guid);
    if (i == -1) {
      _notes.add(note);
    } else {
      _notes[i] = note;
    }
    _persistNotes();
    _reminders.sync(note);
    notifyListeners();
  }

  /// Sticks pre-made notes (and threads) on the wall — used for the sample
  /// notes on a fresh install.
  void seed(List<Note> notes, {List<NoteLink> links = const []}) {
    _notes.addAll(notes);
    _links.addAll(links);
    _persistNotes();
    _storage.saveLinks(_links);
    notifyListeners();
  }

  /// Moves a note to the trash. It disappears from every view but keeps its
  /// place, photo and threads so [undoDelete] / [restore] can bring it back.
  void delete(Note note) => trashAll([note]);

  void trashAll(List<Note> notes) {
    if (notes.isEmpty) return;
    final now = DateTime.now();
    for (final note in notes) {
      note.deletedAt = now;
      _reminders.cancel(note);
    }
    _lastDeleted = List.of(notes);
    _persistNotes();
    notifyListeners();
  }

  bool get canUndo => _lastDeleted.isNotEmpty;

  void undoDelete() {
    if (_lastDeleted.isEmpty) return;
    restoreAll(_lastDeleted);
  }

  /// Takes a note out of the trash, back onto its board (or the first board
  /// if that one is gone).
  void restore(Note note) => restoreAll([note]);

  void restoreAll(List<Note> notes) {
    for (final note in notes) {
      if (!_notes.contains(note)) continue;
      note.deletedAt = null;
      if (_boards.every((b) => b.id != note.boardId)) {
        note.boardId = _boards.first.id;
      }
      _reminders.sync(note);
    }
    _lastDeleted = const [];
    _persistNotes();
    notifyListeners();
  }

  /// Notes in the trash, most recently deleted first.
  List<Note> get trashed => _notes.where((n) => n.isTrashed).toList()
    ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));

  int get trashCount => _notes.where((n) => n.isTrashed).length;

  /// Days before [note] is purged from the trash, rounded up so a note binned
  /// a minute ago still reads "30 days"; 0 means it goes on the next launch.
  int daysLeft(Note note, [DateTime? now]) {
    final at = note.deletedAt;
    if (at == null) return trashRetention.inDays;
    final left = trashRetention - (now ?? DateTime.now()).difference(at);
    if (left.isNegative) return 0;
    return (left.inMinutes / Duration.minutesPerDay).ceil();
  }

  /// Deletes a note for good, along with its threads and — when no other
  /// note shows it — its photo file.
  void purge(Note note) {
    _purge(note);
    _persistNotes();
    notifyListeners();
  }

  void emptyTrash() {
    for (final note in trashed) {
      _purge(note);
    }
    _persistNotes();
    notifyListeners();
  }

  void _purge(Note note) {
    _notes.removeWhere((n) => n.guid == note.guid);
    _lastDeleted = _lastDeleted.where((n) => n.guid != note.guid).toList();
    _reminders.cancel(note);
    if (_links.any((l) => l.connects(note.guid))) {
      _links.removeWhere((l) => l.connects(note.guid));
      _storage.saveLinks(_links);
    }
    final path = note.imagePath;
    if (path.isNotEmpty && !photoInUse(path)) _deletePhoto(path);
  }

  /// Whether some note (live or trashed) still shows the photo at [path].
  bool photoInUse(String path) =>
      path.isNotEmpty && _notes.any((n) => n.imagePath == path);

  /// Moves a note onto another board, dropping it near the center there.
  void moveToBoard(Note note, String boardId) => moveAllToBoard([note], boardId);

  void moveAllToBoard(List<Note> notes, String boardId) {
    if (_boards.every((b) => b.id != boardId)) return;
    final rng = math.Random();
    var changed = false;
    for (final note in notes) {
      if (note.boardId == boardId) continue;
      note
        ..boardId = boardId
        ..x = 0.25 + rng.nextDouble() * 0.3
        ..y = 0.2 + rng.nextDouble() * 0.3;
      changed = true;
    }
    if (!changed) return;
    _persistNotes();
    notifyListeners();
  }

  void togglePin(Note note) => pinAll([note], !note.pinned);

  void pinAll(List<Note> notes, bool pinned) {
    for (final note in notes) {
      note.pinned = pinned;
    }
    _persistNotes();
    notifyListeners();
  }

  /// Sets the paper color of several notes at once (null = auto from id).
  void recolor(List<Note> notes, int? colorIndex) {
    for (final note in notes) {
      note.colorIndex = colorIndex;
    }
    _persistNotes();
    notifyListeners();
  }

  void toggleChecklistItem(Note note, int index) {
    note.checklist[index].done = !note.checklist[index].done;
    _refreshCompleted(note);
    _persistNotes();
    notifyListeners();
  }

  /// Keeps [Note.completedAt] in step with the checklist: stamped the moment
  /// the last item is ticked, cleared as soon as one is unticked.
  void _refreshCompleted(Note note) {
    if (note.type == NoteType.checklist && note.checklistDone) {
      note.completedAt ??= DateTime.now();
    } else {
      note.completedAt = null;
    }
  }

  /// Trashes checklists that have been fully ticked for longer than [after].
  /// Returns whether anything moved.
  bool _sweepCompleted(Duration after, DateTime now) {
    final done = _notes
        .where((n) =>
            !n.isTrashed &&
            n.completedAt != null &&
            now.difference(n.completedAt!) > after)
        .toList();
    for (final note in done) {
      note.deletedAt = now;
      _reminders.cancel(note);
    }
    return done.isNotEmpty;
  }

  /// Public entry for the settings toggle / app resume.
  void sweepCompleted({Duration after = const Duration(days: 1)}) {
    if (_sweepCompleted(after, DateTime.now())) {
      _persistNotes();
      notifyListeners();
    }
  }

  /// Updates a note's fractional wall position and brings it to the front.
  void moveNote(Note note, double x, double y) {
    note.x = x.clamp(0.0, 1.0);
    note.y = y.clamp(0.0, 1.0);
    _bringToFront(note);
    _persistNotes();
    notifyListeners();
  }

  /// Places (and sizes) many notes at once — the "tidy up" animation.
  void arrange(List<(Note, double x, double y, double scale)> placements) {
    for (final (note, x, y, scale) in placements) {
      note
        ..x = x.clamp(0.0, 1.0)
        ..y = y.clamp(0.0, 1.0)
        ..scale = scale.clamp(0.5, 3.0);
    }
    _persistNotes();
    notifyListeners();
  }

  void bringToFront(Note note) {
    _bringToFront(note);
    notifyListeners();
  }

  void resizeNote(Note note, double scale) {
    note.scale = scale.clamp(0.5, 3.0);
    _persistNotes();
    notifyListeners();
  }

  void _bringToFront(Note note) {
    if (_notes.remove(note)) _notes.add(note);
  }

  void _persistNotes() => _storage.saveNotes(_notes);

  // --- Threads -------------------------------------------------------------

  List<NoteLink> get links => List.unmodifiable(_links);

  /// Threads whose both ends are live notes on [boardId].
  List<NoteLink> linksOn(String boardId) {
    final here = {
      for (final n in _notes)
        if (n.boardId == boardId && !n.isTrashed) n.guid,
    };
    return _links
        .where((l) => here.contains(l.a) && here.contains(l.b))
        .toList();
  }

  bool isLinked(String a, String b) => _links.any((l) => l.same(a, b));

  /// Ties a thread between two notes, or returns false without change if
  /// they are the same note, already tied, or not on the wall at all.
  bool connect(String a, String b) {
    if (a == b || isLinked(a, b)) return false;
    var found = 0;
    for (final n in _notes) {
      if (n.guid == a || n.guid == b) found++;
    }
    if (found < 2) return false;
    _links.add(NoteLink(a, b));
    _storage.saveLinks(_links);
    notifyListeners();
    return true;
  }

  void disconnect(NoteLink link) {
    _links.removeWhere((l) => l.same(link.a, link.b));
    _storage.saveLinks(_links);
    notifyListeners();
  }

  // --- Backup --------------------------------------------------------------

  /// Every note, trashed ones included, so a backup round-trips the trash.
  List<Note> get allNotes => List.unmodifiable(_notes);

  /// Replaces all boards and notes with imported data.
  void replaceAll(List<Board> boards, List<Note> notes) {
    if (boards.isEmpty) return;
    // Old reminders would otherwise keep firing for notes that no longer exist.
    for (final note in _notes) {
      _reminders.cancel(note);
    }
    _lastDeleted = const [];
    _boards
      ..clear()
      ..addAll(boards);
    _notes
      ..clear()
      ..addAll(notes);
    final guids = {for (final n in _notes) n.guid};
    _links.removeWhere((l) => !guids.contains(l.a) || !guids.contains(l.b));
    _currentBoardId = _boards.first.id;
    _storage
      ..saveBoards(_boards)
      ..saveNotes(_notes)
      ..saveLinks(_links)
      ..setCurrentBoardId(_currentBoardId);
    for (final note in _notes) {
      if (!note.isTrashed) _reminders.sync(note);
    }
    notifyListeners();
  }
}

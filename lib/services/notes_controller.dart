import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/board.dart';
import '../models/draw_stroke.dart';
import '../models/note.dart';
import '../models/view_mode.dart';
import '../theme.dart';
import '../util/angles.dart';
import '../util/rich_note.dart';
import '../util/text_fold.dart';
import 'memory_wall.dart';
import 'note_storage.dart';
import 'reminder_service.dart';
import 'template_library.dart';
import 'theme_packs.dart';

/// Removes a stored file that no note or board refers to any more.
typedef FileRemover = void Function(String stored);

/// What a wall Undo step puts back — named so the UI can say what it undoes.
enum WallEditKind { move, resize, rotate, tidy, moveBoard }

/// Where a note sat before a wall edit, so Undo can put it back.
class _Placement {
  _Placement(this.note)
    : x = note.x,
      y = note.y,
      scale = note.scale,
      rotation = note.rotation,
      boardId = note.boardId;

  final Note note;
  final double x;
  final double y;
  final double scale;
  final double? rotation;
  final String boardId;

  /// Puts the note back — onto its old board too, unless that is gone.
  void restore(List<Board> boards) {
    note
      ..x = x
      ..y = y
      ..scale = scale
      ..rotation = rotation;
    if (boards.any((b) => b.id == boardId)) note.boardId = boardId;
  }
}

class _WallEdit {
  _WallEdit(this.kind, this.before, this.at);

  WallEditKind kind;
  final List<_Placement> before;
  DateTime at;
}

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
    FileRemover? deleteAudio,
  }) : _deletePhoto = deletePhoto ?? _noop,
       _deleteWallImage = deleteWallImage ?? _noop,
       _deleteAudio = deleteAudio ?? _noop {
    _load();
  }

  static void _noop(String _) {}

  /// How long a note stays in the trash before it is purged.
  static const trashRetention = Duration(days: 30);

  final NoteStorage _storage;
  final ReminderService _reminders;
  final FileRemover _deletePhoto;
  final FileRemover _deleteWallImage;
  final FileRemover _deleteAudio;
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

  // Wall edits that can be undone, oldest first (see _rememberWall).
  final _wallUndo = <_WallEdit>[];
  int _wallEdits = 0;

  /// The clock wall edits are stamped with; tests swap in a fixed one.
  DateTime Function() clock = DateTime.now;

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
        .where(
          (n) =>
              n.deletedAt != null &&
              now.difference(n.deletedAt!) > trashRetention,
        )
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

  Board get currentBoard => _boards.firstWhere(
    (b) => b.id == _currentBoardId,
    orElse: () => _boards.first,
  );

  int get currentBoardIndex => _boards
      .indexWhere((b) => b.id == _currentBoardId)
      .clamp(0, _boards.length - 1);

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

  /// Creates a board with the given name and icon and switches to it.
  Board addBoard(String name, {String icon = ''}) {
    final board = Board(id: _uuid.v4(), name: name, icon: icon);
    _boards.add(board);
    _storage.saveBoards(_boards);
    selectBoard(board.id);
    return board;
  }

  // --- Private boards -----------------------------------------------------

  /// Private boards opened with the phone's lock since the app last went to
  /// the background.
  final _openPrivate = <String>{};

  /// Whether [board]'s notes may be shown: not private, or opened.
  bool isOpen(Board board) =>
      !board.isPrivate || _openPrivate.contains(board.id);

  /// The open board is private and still shut.
  bool get currentBoardShut => !isOpen(currentBoard);

  bool _shut(String boardId) {
    final board = _boards.where((b) => b.id == boardId).firstOrNull;
    return board != null && !isOpen(board);
  }

  bool _onPrivateBoard(Note note) =>
      _boards.where((b) => b.id == note.boardId).firstOrNull?.isPrivate ??
      false;

  void _syncReminder(Note note) =>
      _reminders.sync(note, hidden: _onPrivateBoard(note));

  /// The phone's lock was given for [boardId].
  void openPrivateBoard(String boardId) {
    if (_openPrivate.add(boardId)) notifyListeners();
  }

  /// Shuts every private board again (the app went to the background).
  void shutPrivateBoards() {
    if (_openPrivate.isEmpty) return;
    _openPrivate.clear();
    notifyListeners();
  }

  /// Makes a board private or not; its notes' reminders are scheduled again
  /// so their texts are hidden or shown to match.
  void setBoardPrivate(String id, bool value) {
    final board = _boards.firstWhere((b) => b.id == id);
    board.isPrivate = value;
    // Whoever just made it private is looking at it.
    if (value) _openPrivate.add(id);
    _storage.saveBoards(_boards);
    for (final note in _notes) {
      if (note.boardId == id && !note.isTrashed) _syncReminder(note);
    }
    notifyListeners();
  }

  /// Renames a board or changes its icon; anything left null keeps its value.
  void updateBoard(String id, {String? name, String? icon}) {
    final board = _boards.firstWhere((b) => b.id == id);
    if (name != null) board.name = name;
    if (icon != null) board.icon = icon;
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
    for (final photo in {board.wallImage, board.savedWallImage}) {
      if (photo.isNotEmpty) _deleteWallImage(photo);
    }
    // Undo would resurrect a note onto a board that no longer exists.
    _lastDeleted = _lastDeleted.where((n) => n.boardId != id).toList();
    if (_currentBoardId == id) _currentBoardId = _boards.first.id;
    _storage
      ..saveBoards(_boards)
      ..setCurrentBoardId(_currentBoardId);
    _persistNotes();
    notifyListeners();
  }

  /// A copy of board [id] named [name], right after it, with copies of its
  /// notes, threads, stacks and marker strokes, and switches to it. Its own
  /// wall photo is not shared (deleting either board would take the file);
  /// the copy shows the texture instead.
  Board duplicateBoard(String id, String name) {
    final source = _boards.firstWhere((b) => b.id == id);
    final copy = Board(
      id: _uuid.v4(),
      name: name,
      wallIndex: source.wallIndex,
      icon: source.icon,
      themeId: source.themeId,
      fontId: source.fontId,
      pinStyle: source.pinStyle,
      isPrivate: source.isPrivate,
      strokes: [
        for (final s in source.strokes) DrawStroke.fromJson(s.toJson()),
      ],
    );
    final guids = <String, String>{};
    final stacks = <String, String>{};
    final copies = <Note>[];
    for (final n in _notes) {
      if (n.boardId != id || n.isTrashed) continue;
      final json = n.toJson();
      final guid = _uuid.v4();
      guids[n.guid] = guid;
      json['guid'] = guid;
      json['boardId'] = copy.id;
      final stack = n.stack;
      if (stack != null) json['stack'] = stacks[stack] ??= _uuid.v4();
      final made = Note.fromJson(json)
        ..reminderAt = null
        ..repeat = ReminderRepeat.none;
      copies.add(made);
    }
    final links = [
      for (final l in linksOn(id))
        if (guids[l.a] case final a?)
          if (guids[l.b] case final b?)
            NoteLink(
              a,
              b,
              color: l.color,
              label: l.label,
              arrow: l.arrow,
              style: l.style,
            ),
    ];
    _boards.insert(_boards.indexOf(source) + 1, copy);
    // A copy of a private board is open while its original is.
    if (copy.isPrivate && isOpen(source)) _openPrivate.add(copy.id);
    _storage.saveBoards(_boards);
    seed(copies, links: links);
    selectBoard(copy.id);
    return copy;
  }

  /// Switches the current board to one of the built-in textures. The board's
  /// own photo is kept (see [Board.savedWallImage]) so trying textures never
  /// costs it; [forgetPhoto] is the explicit "remove photo", which deletes it.
  void setCurrentBoardWall(int wallIndex, {bool forgetPhoto = false}) {
    final board = currentBoard;
    if (forgetPhoto) {
      if (board.hasSavedWallImage) _deleteWallImage(board.savedWallImage);
      if (board.hasWallImage && board.wallImage != board.savedWallImage) {
        _deleteWallImage(board.wallImage);
      }
      board
        ..savedWallImage = ''
        ..savedWallImageDark = false;
    }
    board
      ..wallIndex = wallIndex
      ..wallImage = ''
      ..wallImageDark = false;
    _storage.saveBoards(_boards);
    notifyListeners();
  }

  /// Uses the user's own photo (already copied by `ImageService`) as the
  /// current board's wall — a new one, or the kept one picked again. [dark]
  /// picks the scrim that keeps text readable. A new photo replaces the kept
  /// one, whose file goes then.
  void setCurrentBoardWallImage(String stored, {required bool dark}) {
    final board = currentBoard;
    for (final old in {board.wallImage, board.savedWallImage}) {
      if (old.isNotEmpty && old != stored) _deleteWallImage(old);
    }
    board
      ..wallImage = stored
      ..wallImageDark = dark
      ..savedWallImage = stored
      ..savedWallImageDark = dark;
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
  /// The open board's notes — none while it is a shut private board.
  List<Note> get boardNotes => currentBoardShut
      ? const []
      : _notes
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
      4 => note.type == NoteType.photo,
      5 => note.type == NoteType.label,
      6 => note.type == NoteType.audio,
      _ => true,
    };
    if (!matchesType) return false;
    final search = foldText(_search.trim());
    if (search.isEmpty) return true;
    final haystack = foldText(
      [
        plainNoteText(note.content),
        note.url,
        ...note.checklist.map((i) => i.text),
      ].join(' '),
    );
    return haystack.contains(search);
  }

  /// Live notes on the *other* boards that the search finds — so a search
  /// can say "3 more on other walls" instead of a note seeming lost. Empty
  /// while nothing is typed: a type filter alone stays on this board.
  List<Note> get otherBoardMatches {
    if (_search.trim().isEmpty) return const [];
    return [
      for (final n in _notes)
        if (!n.isTrashed &&
            n.boardId != _currentBoardId &&
            !_shut(n.boardId) &&
            matches(n))
          n,
    ];
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
    return _newNoteAt(
      0.30 + rng.nextDouble() * 0.30,
      0.28 + rng.nextDouble() * 0.30,
    );
  }

  Note draftAt(double x, double y) => _newNoteAt(x, y);

  /// Sticks sticker [id] on the current board, at [x],[y] or near the
  /// middle of the wall. Returns the new sticker note.
  Note addSticker(String id, {double? x, double? y}) {
    final note = (x != null && y != null ? _newNoteAt(x, y) : draft())
      ..type = NoteType.sticker
      ..sticker = id;
    add(note);
    return note;
  }

  void add(Note note) {
    _refreshCompleted(note);
    _notes.add(note);
    _persistNotes();
    _syncReminder(note);
    notifyListeners();
  }

  /// Pins photos (already copied by `ImageService`) straight onto the current
  /// board, one photo print per file, fanned out from ([x], [y]) so a batch
  /// lands as a loose stack rather than one on top of the other. Defaults to
  /// the middle of the wall. Returns the notes created.
  List<Note> addPhotos(List<String> stored, {double? x, double? y}) {
    if (stored.isEmpty) return const [];
    final rng = math.Random();
    final baseX = x ?? 0.30 + rng.nextDouble() * 0.30;
    final baseY = y ?? 0.25 + rng.nextDouble() * 0.30;
    final created = <Note>[];
    for (final (i, file) in stored.indexed) {
      // Each print sits a little right and below the previous one; a long
      // batch wraps back so nothing ends up off the wall.
      final step = i % 6;
      final note =
          _newNoteAt(
              (baseX + step * 0.06).clamp(0.0, 1.0),
              (baseY + step * 0.05).clamp(0.0, 1.0),
            )
            ..type = NoteType.photo
            ..imagePath = file;
      _notes.add(note);
      created.add(note);
    }
    _persistNotes();
    notifyListeners();
    return created;
  }

  /// Replaces the stored note that has the same guid (the dialog edits a
  /// clone), preserving its position in the list.
  void update(Note note) {
    // Written on, a template's example is the user's own note now.
    note
      ..sample = false
      ..editedAt = DateTime.now();
    _refreshCompleted(note);
    final i = _notes.indexWhere((n) => n.guid == note.guid);
    if (i == -1) {
      _notes.add(note);
    } else {
      _notes[i] = note;
    }
    _persistNotes();
    _syncReminder(note);
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

  /// A new board started from [template], written in [languageCode] and
  /// dressed in [pack] (its wall, papers, ruling, handwriting, pin and
  /// thread) when one is given. Switches to it. With [into], that board is
  /// used instead (renamed to the template), as on a fresh install.
  Board addBoardFromTemplate(
    BoardTemplateDef template,
    String languageCode, {
    ThemePack? pack,
    String? into,
  }) {
    final Board board;
    if (into != null) {
      board = _boards.firstWhere((b) => b.id == into)
        ..name = template.name.of(languageCode);
      _storage.saveBoards(_boards);
      selectBoard(board.id);
    } else {
      board = addBoard(template.name.of(languageCode));
    }
    if (pack != null) {
      board
        ..wallIndex = pack.wallIndex
        ..themeId = pack.id
        ..fontId = pack.font
        ..pinStyle = pack.pin == PinStyle.classic ? '' : pack.pin.name;
      _storage.saveBoards(_boards);
    }
    final made = template.build(board.id, languageCode, pack: pack);
    seed(made.notes, links: made.links);
    return board;
  }

  /// A new board of [photos] (stored file names, as picked) laid out by
  /// [layout] in [pack]'s look, under a [title] strip. Switches to it.
  Board addMemoryWall(
    String title,
    List<String> photos,
    MemoryLayout layout, {
    ThemePack? pack,
    PhotoFrame frame = PhotoFrame.print,
    CaptionPreset caption = CaptionPreset.none,
    String date = '',
  }) {
    final board = addBoard(title);
    if (pack != null) {
      board
        ..wallIndex = pack.wallIndex
        ..themeId = pack.id
        ..fontId = pack.font
        ..pinStyle = pack.pin == PinStyle.classic ? '' : pack.pin.name;
      _storage.saveBoards(_boards);
    }
    final made = memoryWallNotes(
      photos,
      board.id,
      layout,
      pack: pack,
      title: title,
      frame: frame,
      caption: caption,
      date: date,
    );
    viewMode = ViewMode.wall;
    seed(made.notes, links: made.links);
    return board;
  }

  /// When something on board [boardId] was last made or edited, if ever.
  DateTime? lastEdited(String boardId) {
    DateTime? last;
    for (final n in _notes) {
      if (n.boardId != boardId || n.isTrashed) continue;
      final t = n.touchedAt;
      if (last == null || t.isAfter(last)) last = t;
    }
    return last;
  }

  /// Pins board [boardId] to the top of *All boards*, or takes it off.
  void toggleFavorite(String boardId) {
    final board = _boards.firstWhere((b) => b.id == boardId);
    board.favorite = !board.favorite;
    _storage.saveBoards(_boards);
    notifyListeners();
  }

  /// The live photo prints on board [boardId], in the order they were added.
  List<Note> printsOn(String boardId) => [
    for (final n in _notes)
      if (n.boardId == boardId && !n.isTrashed && n.type == NoteType.photo) n,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Lays the prints of board [boardId] out again: a fresh collage for
  /// [seed] (the same seed gives the same wall), or [layout]. Only their
  /// places, sizes and turns change: photos, captions, frames and threads
  /// stay. With [hero], that print goes first, large in the middle. Returns
  /// what puts them back (for Undo).
  VoidCallback rearrangePrints(
    String boardId, {
    MemoryLayout layout = MemoryLayout.collage,
    String seed = '',
    String? hero,
  }) {
    final prints = printsOn(boardId);
    if (hero != null) {
      final first = prints.where((n) => n.guid == hero).firstOrNull;
      if (first != null) {
        prints
          ..remove(first)
          ..insert(0, first);
      }
    } else if (seed.isNotEmpty) {
      prints.shuffle(math.Random(stableHash(seed)));
    }
    final before = {
      for (final n in prints) n.guid: (n.x, n.y, n.scale, n.rotation),
    };
    // Leave room for a title strip when the board has one at the top.
    final titled = _notes.any(
      (n) =>
          n.boardId == boardId &&
          !n.isTrashed &&
          n.type == NoteType.label &&
          n.y < 0.05,
    );
    final spots = memoryPositions(
      prints.length,
      hero != null ? MemoryLayout.hero : layout,
      top: titled ? 0.14 : 0.04,
      seed: '$boardId$seed',
    );
    for (final (i, n) in prints.indexed) {
      n
        ..x = spots[i].x
        ..y = spots[i].y
        ..scale = spots[i].scale
        ..rotation = spots[i].rotation;
    }
    _persistNotes();
    notifyListeners();
    return () {
      for (final n in _notes) {
        final b = before[n.guid];
        if (b == null) continue;
        n
          ..x = b.$1
          ..y = b.$2
          ..scale = b.$3
          ..rotation = b.$4;
      }
      _persistNotes();
      notifyListeners();
    };
  }

  /// Puts [frame] on [prints] (every print on the board, or one). Returns
  /// what puts the old frames back (for Undo).
  VoidCallback setFrames(List<Note> prints, PhotoFrame frame) {
    final before = {for (final n in prints) n.guid: n.frame};
    for (final n in prints) {
      n.frame = frame;
    }
    _persistNotes();
    notifyListeners();
    return () {
      for (final n in _notes) {
        if (before[n.guid] case final f?) n.frame = f;
      }
      _persistNotes();
      notifyListeners();
    };
  }

  /// Removes the first-run examples from board [boardId] for good (they
  /// never were the user's) with the threads tied to them.
  /// With [only], just those of them.
  void discardSamples(String boardId, {Set<String>? only}) {
    final ids = {
      for (final n in sampleNotes(boardId))
        if (only == null || only.contains(n.guid)) n.guid,
    };
    if (ids.isEmpty) return;
    _notes.removeWhere((n) => ids.contains(n.guid));
    _links.removeWhere((l) => ids.contains(l.a) || ids.contains(l.b));
    _persistNotes();
    _storage.saveLinks(_links);
    notifyListeners();
  }

  /// Takes a template's examples off board [boardId] (to the trash, with
  /// Undo through [undoDelete]) and leaves its headings, stickers and wall.
  int clearSamples(String boardId) {
    final samples = sampleNotes(boardId);
    trashAll(samples);
    return samples.length;
  }

  /// The example notes a template put on board [boardId] that are still as
  /// it left them.
  List<Note> sampleNotes(String boardId) => [
    for (final n in _notes)
      if (n.boardId == boardId && n.sample && !n.isTrashed) n,
  ];

  /// Puts a theme pack on board [boardId]: its wall, its papers on the notes
  /// in reading order, its ruling on the sheets that can take it, its
  /// thread on every tie, and its handwriting and pin for the board. What
  /// the notes say, where they sit, their links and dates stay as they are.
  /// Returns a function that puts everything back (for Undo).
  VoidCallback applyTheme(String boardId, ThemePack pack) {
    final board = _boards.firstWhere((b) => b.id == boardId);
    final before = (
      wallIndex: board.wallIndex,
      wallImage: board.wallImage,
      wallImageDark: board.wallImageDark,
      themeId: board.themeId,
      fontId: board.fontId,
      pinStyle: board.pinStyle,
    );
    final notes = [
      for (final n in _notes)
        if (n.boardId == boardId && !n.isTrashed) n,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final looks = {for (final n in notes) n.guid: (n.colorIndex, n.paper)};
    final links = List<NoteLink>.of(_links);

    board
      ..wallIndex = pack.wallIndex
      // A photo of the user's own stays saved, one tap away in Customize.
      ..wallImage = ''
      ..wallImageDark = false
      ..themeId = pack.id
      ..fontId = pack.font
      ..pinStyle = pack.pin == PinStyle.classic ? '' : pack.pin.name;
    var i = 0;
    for (final n in notes) {
      switch (n.type) {
        case NoteType.photo || NoteType.sticker:
          continue;
        case _:
          n.colorIndex = pack.paperAt(i++);
          if (pack.paper.suits(n.type)) n.paper = pack.paper;
      }
    }
    final ids = {for (final n in notes) n.guid};
    for (var k = 0; k < _links.length; k++) {
      final l = _links[k];
      if (ids.contains(l.a) || ids.contains(l.b)) {
        _links[k] = l.copyWith(style: pack.thread, color: pack.yarn);
      }
    }
    _storage
      ..saveBoards(_boards)
      ..saveLinks(_links);
    _persistNotes();
    notifyListeners();

    return () {
      board
        ..wallIndex = before.wallIndex
        ..wallImage = before.wallImage
        ..wallImageDark = before.wallImageDark
        ..themeId = before.themeId
        ..fontId = before.fontId
        ..pinStyle = before.pinStyle;
      for (final n in _notes) {
        final look = looks[n.guid];
        if (look == null) continue;
        n
          ..colorIndex = look.$1
          ..paper = look.$2;
      }
      _links
        ..clear()
        ..addAll(links);
      _storage
        ..saveBoards(_boards)
        ..saveLinks(_links);
      _persistNotes();
      notifyListeners();
    };
  }

  /// Drops the board's own handwriting and pin, so the ones chosen in
  /// Customize show on it again.
  void clearBoardStyle(String boardId) {
    final board = _boards.firstWhere((b) => b.id == boardId);
    if (board.fontId.isEmpty && board.pinStyle.isEmpty) return;
    board
      ..fontId = ''
      ..pinStyle = '';
    _storage.saveBoards(_boards);
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
      _syncReminder(note);
    }
    _lastDeleted = const [];
    _persistNotes();
    notifyListeners();
  }

  /// Notes in the trash, most recently deleted first.
  /// The trash, newest first — without notes from a shut private board,
  /// which wait there unseen until it is opened.
  List<Note> get trashed =>
      _notes.where((n) => n.isTrashed && !_shut(n.boardId)).toList()
        ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));

  int get trashCount =>
      _notes.where((n) => n.isTrashed && !_shut(n.boardId)).length;

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
    if (!photoInUse(note.imagePath)) _deletePhoto(note.imagePath);
    if (!audioInUse(note.audioPath)) _deleteAudio(note.audioPath);
  }

  /// Whether some note (live or trashed) still shows the photo at [path].
  bool photoInUse(String path) =>
      path.isNotEmpty && _notes.any((n) => n.imagePath == path);

  /// Whether some note (live or trashed) still plays the recording [path].
  bool audioInUse(String path) =>
      path.isNotEmpty && _notes.any((n) => n.audioPath == path);

  /// A copy of [note] beside it — a touch down and to the right, on top —
  /// with its own id, unpinned and unlocked so it can be taken where it is
  /// wanted. Shares the photo file (the file goes when the last note showing
  /// it does).
  Note duplicate(Note note) {
    final copy = _copyOf(
      note,
      boardId: note.boardId,
      x: (note.x + 0.04).clamp(-wallSpill, 1 + wallSpill),
      y: (note.y + 0.04).clamp(-wallSpill, 1 + wallSpill),
    );
    _notes.add(copy);
    _persistNotes();
    _syncReminder(copy);
    notifyListeners();
    return copy;
  }

  /// Copies notes onto another board, near its middle; the originals stay.
  /// Returns the copies (empty when the board does not exist).
  List<Note> copyToBoard(List<Note> notes, String boardId) {
    if (_boards.every((b) => b.id != boardId)) return const [];
    final rng = math.Random();
    final copies = [
      for (final note in notes)
        _copyOf(
          note,
          boardId: boardId,
          x: 0.25 + rng.nextDouble() * 0.3,
          y: 0.2 + rng.nextDouble() * 0.3,
        ),
    ];
    _notes.addAll(copies);
    _persistNotes();
    for (final copy in copies) {
      _syncReminder(copy);
    }
    notifyListeners();
    return copies;
  }

  Note _copyOf(
    Note note, {
    required String boardId,
    required double x,
    required double y,
  }) {
    final json = note.toJson()
      ..['guid'] = _uuid.v4()
      ..['boardId'] = boardId
      ..['x'] = x
      ..['y'] = y
      ..['createdAt'] = DateTime.now().toIso8601String()
      ..['pinned'] = false
      ..['locked'] = false
      // Two copies of one reminder would ring twice for the same thing.
      ..remove('reminderAt')
      ..remove('repeat')
      // A copy lies on its own, not in the original's pile.
      ..remove('stack')
      ..remove('deletedAt')
      ..remove('completedAt');
    final copy = Note.fromJson(json);
    _refreshCompleted(copy);
    return copy;
  }

  /// Moves a note onto another board, dropping it near the center there.
  void moveToBoard(Note note, String boardId) =>
      moveAllToBoard([note], boardId);

  void moveAllToBoard(List<Note> notes, String boardId) {
    if (_boards.every((b) => b.id != boardId)) return;
    final moving = notes.where((n) => n.boardId != boardId).toList();
    if (moving.isEmpty) return;
    _rememberWall(WallEditKind.moveBoard, moving);
    final rng = math.Random();
    for (final note in moving) {
      note
        ..boardId = boardId
        ..x = 0.25 + rng.nextDouble() * 0.3
        ..y = 0.2 + rng.nextDouble() * 0.3;
      _syncReminder(note);
    }
    _persistNotes();
    notifyListeners();
  }

  void togglePin(Note note) => pinAll([note], !note.pinned);

  /// Holds a note in place on the wall (or lets it go again).
  void toggleLock(Note note) => lockAll([note], !note.locked);

  void lockAll(List<Note> notes, bool locked) {
    for (final note in notes) {
      note.locked = locked;
    }
    _persistNotes();
    notifyListeners();
  }

  // --- Marker strokes on the wall -----------------------------------------

  /// The wall view draws into the current board's stroke list in place; this
  /// writes the result down and tells everyone.
  void saveWallStrokes() {
    _storage.saveBoards(_boards);
    notifyListeners();
  }

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
        .where(
          (n) =>
              !n.isTrashed &&
              n.completedAt != null &&
              now.difference(n.completedAt!) > after,
        )
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

  /// How far outside the home area (0..1) a note may sit, in fractions of
  /// it: the wall has a margin all round the screen (see `WallView.pad`).
  static const double wallSpill = 4.0;

  static double _onWall(double v) => v.clamp(-wallSpill, 1 + wallSpill);

  /// Updates a note's fractional wall position and brings it to the front.
  void moveNote(Note note, double x, double y) {
    final nx = _onWall(x);
    final ny = _onWall(y);
    // A stack moves as one pile.
    final pile = [note, ..._stackMates(note)];
    if (nx != note.x || ny != note.y) {
      _rememberWall(WallEditKind.move, pile);
      for (final n in pile) {
        n
          ..x = nx
          ..y = ny;
      }
    }
    _bringToFront(note);
    _persistNotes();
    notifyListeners();
  }

  /// Moves several notes at once — a dragged selection — as one Undo step.
  void moveNotes(List<(Note note, double x, double y)> moves) {
    moves = [
      for (final (note, x, y) in moves) ...[
        (note, x, y),
        for (final mate in _stackMates(note)) (mate, x, y),
      ],
    ];
    final changed = [
      for (final (note, x, y) in moves)
        if (_onWall(x) != note.x || _onWall(y) != note.y) note,
    ];
    if (changed.isEmpty) return;
    _rememberWall(WallEditKind.move, changed);
    for (final (note, x, y) in moves) {
      note
        ..x = _onWall(x)
        ..y = _onWall(y);
    }
    _persistNotes();
    notifyListeners();
  }

  /// Places (and sizes) many notes at once — the "tidy up" animation. A
  /// tidied note also loses any turn the user gave it: neat rows want the
  /// cards straight (their slight hand-stuck tilt comes back on its own).
  void arrange(List<(Note, double x, double y, double scale)> placements) {
    // The wall tidies the top card of a stack; the pile goes with it.
    placements = [
      for (final (note, x, y, scale) in placements) ...[
        (note, x, y, scale),
        for (final mate in _stackMates(note)) (mate, x, y, scale),
      ],
    ];
    _rememberWall(WallEditKind.tidy, [
      for (final (note, _, _, _) in placements) note,
    ]);
    for (final (note, x, y, scale) in placements) {
      note
        ..x = x.clamp(0.0, 1.0)
        ..y = y.clamp(0.0, 1.0)
        ..scale = scale.clamp(0.5, 3.0)
        ..rotation = null;
    }
    _persistNotes();
    notifyListeners();
  }

  void bringToFront(Note note) {
    _bringToFront(note);
    notifyListeners();
  }

  void resizeNote(Note note, double scale) {
    final s = scale.clamp(0.5, 3.0);
    if (s == note.scale) return;
    _rememberWall(WallEditKind.resize, [note]);
    note.scale = s;
    _persistNotes();
    notifyListeners();
  }

  /// Turns a note on the wall to [angle] radians, or back to its natural
  /// tilt with null. Stored in (-π, π] so a card spun round and round does
  /// not accumulate turns.
  void rotateNote(Note note, double? angle) {
    final r = angle == null ? null : normalizeAngle(angle);
    if (r == note.rotation) return;
    _rememberWall(WallEditKind.rotate, [note]);
    note.rotation = r;
    _persistNotes();
    notifyListeners();
  }

  // --- Undo (wall) ---------------------------------------------------------

  /// How many wall edits are kept for Undo. Deleting has its own Undo on the
  /// snackbar (see [undoDelete]); this covers moving, turning, resizing,
  /// tidying and dragging notes onto another board.
  static const wallUndoLimit = 40;

  /// Nudges of one note in quick succession — a drag committed in phases as
  /// fingers came and went, a turn followed by a resize — fold into a single
  /// step, so Undo takes the note back to where the hand first took it.
  static const wallUndoMergeWindow = Duration(milliseconds: 1500);

  /// Bumps every time a wall edit is remembered, so the UI can show its Undo
  /// affordance for a moment after each change.
  int get wallEdits => _wallEdits;

  bool get canUndoWall => _wallUndo.isNotEmpty;

  /// What [undoWall] would revert next, or null when there is nothing.
  WallEditKind? get nextWallUndo => _wallUndo.lastOrNull?.kind;

  void _rememberWall(WallEditKind kind, List<Note> notes) {
    if (notes.isEmpty) return;
    final now = clock();
    final last = _wallUndo.lastOrNull;
    const solo = {WallEditKind.move, WallEditKind.resize, WallEditKind.rotate};
    if (last != null &&
        notes.length == 1 &&
        last.before.length == 1 &&
        last.before.single.note == notes.single &&
        solo.contains(kind) &&
        solo.contains(last.kind) &&
        now.difference(last.at) < wallUndoMergeWindow) {
      // The older snapshot already holds where the note started.
      last
        ..kind = kind
        ..at = now;
    } else {
      _wallUndo.add(
        _WallEdit(kind, [for (final n in notes) _Placement(n)], now),
      );
      if (_wallUndo.length > wallUndoLimit) _wallUndo.removeAt(0);
    }
    _wallEdits++;
  }

  /// Reverts the latest wall edit and returns what it was, or null when
  /// there is nothing to undo. Notes purged since are left alone.
  WallEditKind? undoWall() {
    if (_wallUndo.isEmpty) return null;
    final edit = _wallUndo.removeLast();
    for (final placement in edit.before) {
      if (!_notes.contains(placement.note)) continue;
      final from = placement.note.boardId;
      placement.restore(_boards);
      if (placement.note.boardId != from) _syncReminder(placement.note);
    }
    _persistNotes();
    notifyListeners();
    return edit.kind;
  }

  void _bringToFront(Note note) {
    if (_notes.remove(note)) _notes.add(note);
  }

  // --- Stacks ----------------------------------------------------------------

  /// The other live notes in [note]'s stack (empty for a lone note).
  List<Note> _stackMates(Note note) {
    final id = note.stack;
    if (id == null) return const [];
    return [
      for (final n in _notes)
        if (n.stack == id && n != note && !n.isTrashed) n,
    ];
  }

  /// [note]'s whole stack, bottom to top (the last one shows), or just the
  /// note when it lies alone.
  List<Note> stackOf(Note note) => note.stack == null
      ? [note]
      : [
          for (final n in _notes)
            if (n.stack == note.stack && !n.isTrashed) n,
        ];

  /// What the wall shows: the current board's notes with each stack folded
  /// to its top card.
  List<Note> get wallNotes {
    final tops = <String, Note>{
      // Later in the list = higher on the pile, so the last one wins.
      for (final n in boardNotes)
        if (n.stack != null) n.stack!: n,
    };
    // Keep the wall's paint order: a stack sits where its top card does.
    return [
      for (final n in boardNotes)
        if (n.stack == null || tops[n.stack!] == n) n,
    ];
  }

  /// Piles [notes] onto the last of them, which stays on top. A note that
  /// was in another stack brings that whole stack along.
  void stackNotes(List<Note> notes) {
    if (notes.length < 2) return;
    final pile = <Note>{for (final n in notes) ...stackOf(n)}.toList();
    final top = notes.last;
    final id = top.stack ?? _uuid.v4();
    _rememberWall(WallEditKind.move, pile);
    for (final n in pile) {
      n
        ..stack = id
        ..x = top.x
        ..y = top.y;
    }
    for (final n in pile) {
      if (n != top) _bringToFront(n);
    }
    _bringToFront(top);
    _persistNotes();
    notifyListeners();
  }

  /// Spreads a stack back out into single notes, fanned to the right and
  /// down from where it lay, so each can be seen again.
  void unstack(Note note) {
    final pile = stackOf(note);
    if (pile.length < 2) {
      note.stack = null;
      _persistNotes();
      notifyListeners();
      return;
    }
    _rememberWall(WallEditKind.move, pile);
    for (final (i, n) in pile.reversed.indexed) {
      n
        ..stack = null
        ..x = _onWall(note.x + i * 0.07)
        ..y = _onWall(note.y + i * 0.05);
    }
    _persistNotes();
    notifyListeners();
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

  /// Restyles a thread — colour, label, arrowhead — matched by its two ends.
  void updateLink(NoteLink link) {
    final i = _links.indexWhere((l) => l.same(link.a, link.b));
    if (i == -1) return;
    _links[i] = link;
    _storage.saveLinks(_links);
    notifyListeners();
  }

  /// Ties a cut thread back exactly as it was (Undo), unless the pair has
  /// been tied again meanwhile.
  void restoreLink(NoteLink link) {
    if (isLinked(link.a, link.b)) return;
    _links.add(link);
    _storage.saveLinks(_links);
    notifyListeners();
  }

  // --- Backup --------------------------------------------------------------

  /// Every note, trashed ones included, so a backup round-trips the trash.
  List<Note> get allNotes => List.unmodifiable(_notes);

  /// How many of [boards] and [notes] (from a backup) are already here, by
  /// id: what a merge will not copy twice.
  ({int boards, int notes}) backupOverlap(
    List<Board> boards,
    List<Note> notes,
  ) {
    final boardIds = {for (final b in _boards) b.id};
    final guids = {for (final n in _notes) n.guid};
    return (
      boards: boards.where((b) => boardIds.contains(b.id)).length,
      notes: notes.where((n) => guids.contains(n.guid)).length,
    );
  }

  /// Adds a backup to what is here instead of replacing it. Everything here
  /// stays. A board already here (same id) takes the backup's notes for it;
  /// a note already here (same id) is left as it is here, so loading the
  /// same backup twice adds nothing the second time. Threads come along
  /// where both their ends exist. Nothing is renamed or recoloured.
  void mergeAll(List<Board> boards, List<Note> notes, {List<NoteLink>? links}) {
    final boardIds = {for (final b in _boards) b.id};
    for (final b in boards) {
      if (boardIds.add(b.id)) _boards.add(b);
    }
    final guids = {for (final n in _notes) n.guid};
    final added = <Note>[];
    for (final n in notes) {
      if (!guids.add(n.guid)) continue;
      // A note of a board that the backup lacks lands on the open one.
      if (!boardIds.contains(n.boardId)) n.boardId = _currentBoardId;
      _notes.add(n);
      added.add(n);
    }
    for (final l in links ?? const <NoteLink>[]) {
      if (!guids.contains(l.a) || !guids.contains(l.b)) continue;
      if (_links.any((x) => x.same(l.a, l.b))) continue;
      _links.add(l);
    }
    _storage
      ..saveBoards(_boards)
      ..saveNotes(_notes)
      ..saveLinks(_links);
    for (final note in added) {
      if (!note.isTrashed) _syncReminder(note);
    }
    notifyListeners();
  }

  /// Replaces all boards and notes with imported data, and the threads with
  /// [links] when the backup carried any.
  void replaceAll(
    List<Board> boards,
    List<Note> notes, {
    List<NoteLink>? links,
  }) {
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
    // An empty list replaces too: Undo of a load puts back "no threads".
    if (links != null) {
      _links
        ..clear()
        ..addAll(links);
    }
    final guids = {for (final n in _notes) n.guid};
    _links.removeWhere((l) => !guids.contains(l.a) || !guids.contains(l.b));
    _currentBoardId = _boards.first.id;
    _storage
      ..saveBoards(_boards)
      ..saveNotes(_notes)
      ..saveLinks(_links)
      ..setCurrentBoardId(_currentBoardId);
    for (final note in _notes) {
      if (!note.isTrashed) _syncReminder(note);
    }
    notifyListeners();
  }
}

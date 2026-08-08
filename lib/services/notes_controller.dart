import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/board.dart';
import '../models/note.dart';
import '../models/view_mode.dart';
import 'note_storage.dart';
import 'reminder_service.dart';

/// Owns the boards, notes and list/view state, persists every change through
/// [NoteStorage], and notifies the UI to rebuild.
class NotesController extends ChangeNotifier {
  NotesController(this._storage, this._reminders) {
    _load();
  }

  final NoteStorage _storage;
  final ReminderService _reminders;
  final _uuid = const Uuid();

  final List<Board> _boards = [];
  final List<Note> _notes = [];
  late String _currentBoardId;

  late ViewMode _viewMode;
  late int _typeFilter;
  late bool _sortByCreated;
  late bool _sortAscending;
  String _search = '';

  // The most recently deleted note, kept so a Snackbar can undo it.
  Note? _lastDeleted;

  void _load() {
    _boards
      ..clear()
      ..addAll(_storage.loadBoards());
    _notes
      ..clear()
      ..addAll(_storage.loadNotes());

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

  Board addBoard(String name) {
    final board = Board(id: _uuid.v4(), name: name, wallIndex: 0);
    _boards.add(board);
    _storage.saveBoards(_boards);
    selectBoard(board.id);
    return board;
  }

  void renameBoard(String id, String name) {
    _boards.firstWhere((b) => b.id == id).name = name;
    _storage.saveBoards(_boards);
    notifyListeners();
  }

  /// Removes a board and all its notes. Keeps at least one board.
  void deleteBoard(String id) {
    if (_boards.length <= 1) return;
    _boards.removeWhere((b) => b.id == id);
    _notes.removeWhere((n) => n.boardId == id);
    if (_currentBoardId == id) _currentBoardId = _boards.first.id;
    _storage
      ..saveBoards(_boards)
      ..saveNotes(_notes)
      ..setCurrentBoardId(_currentBoardId);
    notifyListeners();
  }

  void setCurrentBoardWall(int wallIndex) {
    currentBoard.wallIndex = wallIndex;
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
  set sortByCreated(bool value) {
    _sortByCreated = value;
    _storage.setSortByCreated(value);
    notifyListeners();
  }

  bool get sortAscending => _sortAscending;
  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
    _storage.setSortAscending(_sortAscending);
    notifyListeners();
  }

  String get search => _search;
  set search(String value) {
    _search = value;
    notifyListeners();
  }

  // --- Note queries --------------------------------------------------------

  /// All notes on the current board, unsorted (used by the free wall view).
  List<Note> get boardNotes =>
      _notes.where((n) => n.boardId == _currentBoardId).toList();

  /// Notes on the current board, filtered by type/search and sorted, for the
  /// grid and list views. Pinned notes come first.
  List<Note> get visibleNotes {
    final search = _search.toLowerCase().trim();

    final filtered = boardNotes.where((note) {
      final matchesType = switch (_typeFilter) {
        0 => note.type == NoteType.normal,
        1 => note.type == NoteType.link,
        2 => note.type == NoteType.checklist,
        _ => true,
      };
      final haystack = [
        note.content,
        note.url,
        ...note.checklist.map((i) => i.text),
      ].join(' ').toLowerCase();
      return matchesType && haystack.contains(search);
    }).toList();

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
    _notes.add(note);
    _persistNotes();
    _reminders.sync(note);
    notifyListeners();
  }

  /// Replaces the stored note that has the same guid (the dialog edits a
  /// clone), preserving its position in the list.
  void update(Note note) {
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

  void delete(Note note) {
    _lastDeleted = note;
    _notes.removeWhere((n) => n.guid == note.guid);
    _reminders.cancel(note);
    _persistNotes();
    notifyListeners();
  }

  bool get canUndo => _lastDeleted != null;

  void undoDelete() {
    final note = _lastDeleted;
    if (note == null) return;
    _notes.add(note);
    _lastDeleted = null;
    _reminders.sync(note);
    _persistNotes();
    notifyListeners();
  }

  void togglePin(Note note) {
    note.pinned = !note.pinned;
    _persistNotes();
    notifyListeners();
  }

  void toggleChecklistItem(Note note, int index) {
    note.checklist[index].done = !note.checklist[index].done;
    _persistNotes();
    notifyListeners();
  }

  /// Updates a note's fractional wall position and brings it to the front.
  void moveNote(Note note, double x, double y) {
    note.x = x.clamp(0.0, 1.0);
    note.y = y.clamp(0.0, 1.0);
    _bringToFront(note);
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

  // --- Backup --------------------------------------------------------------

  List<Note> get allNotes => List.unmodifiable(_notes);

  /// Replaces all boards and notes with imported data.
  void replaceAll(List<Board> boards, List<Note> notes) {
    if (boards.isEmpty) return;
    _boards
      ..clear()
      ..addAll(boards);
    _notes
      ..clear()
      ..addAll(notes);
    _currentBoardId = _boards.first.id;
    _storage
      ..saveBoards(_boards)
      ..saveNotes(_notes)
      ..setCurrentBoardId(_currentBoardId);
    for (final note in _notes) {
      _reminders.sync(note);
    }
    notifyListeners();
  }
}

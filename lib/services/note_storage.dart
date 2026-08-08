import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/board.dart';
import '../models/note.dart';
import '../models/view_mode.dart';

/// Persists notes, boards and preferences locally as JSON.
class NoteStorage {
  NoteStorage(this._prefs);

  static const _notesKey = 'notes';
  static const _boardsKey = 'boards';
  static const _currentBoardKey = 'currentBoard';
  static const _sortAscKey = 'sort';
  static const _sortByCreatedKey = 'sortByCreated';
  static const _viewModeKey = 'viewMode';
  static const _filterKey = 'filter';
  static const _fontKey = 'font';
  static const _languageKey = 'language';
  static const _decorKey = 'decor';

  final SharedPreferences _prefs;

  static Future<NoteStorage> create() async {
    return NoteStorage(await SharedPreferences.getInstance());
  }

  // --- Notes ---------------------------------------------------------------

  List<Note> loadNotes() {
    final raw = _prefs.getString(_notesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) {
    return _prefs.setString(
      _notesKey,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  // --- Boards --------------------------------------------------------------

  List<Board> loadBoards() {
    final raw = _prefs.getString(_boardsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Board.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBoards(List<Board> boards) {
    return _prefs.setString(
      _boardsKey,
      jsonEncode(boards.map((b) => b.toJson()).toList()),
    );
  }

  String? get currentBoardId => _prefs.getString(_currentBoardKey);
  Future<void> setCurrentBoardId(String id) =>
      _prefs.setString(_currentBoardKey, id);

  // --- View preferences ----------------------------------------------------

  bool get sortAscending => _prefs.getBool(_sortAscKey) ?? false;
  Future<void> setSortAscending(bool value) =>
      _prefs.setBool(_sortAscKey, value);

  bool get sortByCreated => _prefs.getBool(_sortByCreatedKey) ?? true;
  Future<void> setSortByCreated(bool value) =>
      _prefs.setBool(_sortByCreatedKey, value);

  ViewMode get viewMode {
    final name = _prefs.getString(_viewModeKey);
    return ViewMode.values
            .where((m) => m.name == name)
            .cast<ViewMode?>()
            .firstOrNull ??
        ViewMode.grid;
  }

  Future<void> setViewMode(ViewMode mode) =>
      _prefs.setString(_viewModeKey, mode.name);

  /// -1 = All, 0 = Normal, 1 = Link, 2 = Checklist.
  int get typeFilter => _prefs.getInt(_filterKey) ?? -1;
  Future<void> setTypeFilter(int value) => _prefs.setInt(_filterKey, value);

  String get fontId => _prefs.getString(_fontKey) ?? 'patrick';
  Future<void> setFontId(String value) => _prefs.setString(_fontKey, value);

  /// 'system', or a locale code ('en', 'vi').
  String get languageCode => _prefs.getString(_languageKey) ?? 'system';
  Future<void> setLanguageCode(String value) =>
      _prefs.setString(_languageKey, value);

  bool get wallDecor => _prefs.getBool(_decorKey) ?? true;
  Future<void> setWallDecor(bool value) => _prefs.setBool(_decorKey, value);
}

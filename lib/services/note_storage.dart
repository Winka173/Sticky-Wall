import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/board.dart';
import '../models/note.dart';
import '../models/view_mode.dart';

/// When the wall goes dark: never, always, with the system theme, or between
/// two hours of the day.
enum NightMode { off, on, system, schedule }

/// Persists notes, boards and preferences locally as JSON.
class NoteStorage {
  NoteStorage(this._prefs);

  static const _notesKey = 'notes';
  static const _boardsKey = 'boards';
  static const _linksKey = 'links';
  static const _currentBoardKey = 'currentBoard';
  static const _sortAscKey = 'sort';
  static const _sortByCreatedKey = 'sortByCreated';
  static const _viewModeKey = 'viewMode';
  static const _filterKey = 'filter';
  static const _fontKey = 'font';
  static const _languageKey = 'language';
  static const _decorKey = 'decor';
  static const _nightKey = 'night';
  static const _nightStartKey = 'nightStart';
  static const _nightEndKey = 'nightEnd';
  static const _autoTrashDoneKey = 'autoTrashDone';
  static const _tipsPendingKey = 'tipsPending';

  final SharedPreferences _prefs;

  static Future<NoteStorage> create() async {
    return NoteStorage(await SharedPreferences.getInstance());
  }

  /// True until anything has ever been saved — used to stick the sample notes
  /// on a brand-new install (and never again, even once they're deleted).
  bool get isFirstRun =>
      !_prefs.containsKey(_notesKey) && !_prefs.containsKey(_boardsKey);

  /// Decodes a stored JSON list record by record. One malformed entry (a
  /// hand-edited backup, a field from a newer version) is skipped rather
  /// than taking every other note down with it.
  List<T> _loadList<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (e) {
      debugPrint('Could not decode "$key": $e');
      return [];
    }
    final out = <T>[];
    for (final entry in decoded) {
      try {
        out.add(parse(entry as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Skipping malformed "$key" record: $e');
      }
    }
    return out;
  }

  // --- Notes ---------------------------------------------------------------

  List<Note> loadNotes() => _loadList(_notesKey, Note.fromJson);

  Future<void> saveNotes(List<Note> notes) {
    return _prefs.setString(
      _notesKey,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  // --- Boards --------------------------------------------------------------

  List<Board> loadBoards() => _loadList(_boardsKey, Board.fromJson);

  Future<void> saveBoards(List<Board> boards) {
    return _prefs.setString(
      _boardsKey,
      jsonEncode(boards.map((b) => b.toJson()).toList()),
    );
  }

  String? get currentBoardId => _prefs.getString(_currentBoardKey);
  Future<void> setCurrentBoardId(String id) =>
      _prefs.setString(_currentBoardKey, id);

  // --- Threads between notes ----------------------------------------------

  List<NoteLink> loadLinks() => _loadList(_linksKey, NoteLink.fromJson);

  Future<void> saveLinks(List<NoteLink> links) {
    return _prefs.setString(
      _linksKey,
      jsonEncode(links.map((l) => l.toJson()).toList()),
    );
  }

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

  /// -1 = All, 0 = Normal, 1 = Link, 2 = Checklist, 3 = Drawing, 4 = Photo,
  /// 5 = Label.
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

  // --- Lights --------------------------------------------------------------

  NightMode get nightMode {
    final name = _prefs.getString(_nightKey);
    return NightMode.values
            .where((m) => m.name == name)
            .cast<NightMode?>()
            .firstOrNull ??
        NightMode.off;
  }

  Future<void> setNightMode(NightMode mode) =>
      _prefs.setString(_nightKey, mode.name);

  /// Hour of day (0–23) the scheduled night starts / ends.
  int get nightStart => _prefs.getInt(_nightStartKey) ?? 21;
  Future<void> setNightStart(int hour) => _prefs.setInt(_nightStartKey, hour);

  int get nightEnd => _prefs.getInt(_nightEndKey) ?? 6;
  Future<void> setNightEnd(int hour) => _prefs.setInt(_nightEndKey, hour);

  // --- Housekeeping --------------------------------------------------------

  bool get autoTrashDone => _prefs.getBool(_autoTrashDoneKey) ?? false;
  Future<void> setAutoTrashDone(bool value) =>
      _prefs.setBool(_autoTrashDoneKey, value);

  /// Whether the gesture tips are still owed: set on a fresh install, cleared
  /// once the sheet has been shown.
  bool get tipsPending => _prefs.getBool(_tipsPendingKey) ?? false;
  Future<void> setTipsPending(bool value) =>
      _prefs.setBool(_tipsPendingKey, value);
}

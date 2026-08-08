import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

/// Persists notes and view settings locally, mirroring the key/value JSON
/// store the original desktop app kept in its user-data folder.
class NoteStorage {
  NoteStorage(this._prefs);

  static const _notesKey = 'notes';
  static const _sortKey = 'sort';
  static const _gridKey = 'grid';
  static const _filterKey = 'filter';
  static const _wallKey = 'wall';
  static const _fontKey = 'font';
  static const _languageKey = 'language';
  static const _decorKey = 'decor';

  final SharedPreferences _prefs;

  static Future<NoteStorage> create() async {
    return NoteStorage(await SharedPreferences.getInstance());
  }

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

  bool get sortAscending => _prefs.getBool(_sortKey) ?? false;
  Future<void> setSortAscending(bool value) => _prefs.setBool(_sortKey, value);

  bool get gridView => _prefs.getBool(_gridKey) ?? false;
  Future<void> setGridView(bool value) => _prefs.setBool(_gridKey, value);

  /// -1 = All, 0 = Normal, 1 = Link (same convention as the original app).
  int get typeFilter => _prefs.getInt(_filterKey) ?? -1;
  Future<void> setTypeFilter(int value) => _prefs.setInt(_filterKey, value);

  /// Index into the [walls] list in theme.dart.
  int get wallIndex => _prefs.getInt(_wallKey) ?? 0;
  Future<void> setWallIndex(int value) => _prefs.setInt(_wallKey, value);

  /// Id of a [FontChoice] in theme.dart.
  String get fontId => _prefs.getString(_fontKey) ?? 'patrick';
  Future<void> setFontId(String value) => _prefs.setString(_fontKey, value);

  /// 'system', or a locale code ('en', 'vi').
  String get languageCode => _prefs.getString(_languageKey) ?? 'system';
  Future<void> setLanguageCode(String value) =>
      _prefs.setString(_languageKey, value);

  /// Whether the procedural wall stains layer is shown.
  bool get wallDecor => _prefs.getBool(_decorKey) ?? true;
  Future<void> setWallDecor(bool value) => _prefs.setBool(_decorKey, value);
}

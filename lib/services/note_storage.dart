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
}

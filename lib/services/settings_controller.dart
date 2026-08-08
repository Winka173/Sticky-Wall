import 'package:flutter/material.dart';

import '../theme.dart';
import 'note_storage.dart';

/// App-level appearance and language settings. Persists through
/// [NoteStorage] and notifies listeners so the app rebuilds live.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage)
      : _wallIndex = _storage.wallIndex % walls.length,
        _fontId = _storage.fontId,
        _languageCode = _storage.languageCode,
        _wallDecor = _storage.wallDecor;

  final NoteStorage _storage;

  int _wallIndex;
  String _fontId;
  String _languageCode;
  bool _wallDecor;

  WallStyle get wall => walls[_wallIndex];
  int get wallIndex => _wallIndex;

  FontChoice get font => fontChoiceById(_fontId);

  String get languageCode => _languageCode;

  /// null → follow the system locale.
  Locale? get localeOverride =>
      _languageCode == 'system' ? null : Locale(_languageCode);

  void setWallIndex(int index) {
    _wallIndex = index % walls.length;
    _storage.setWallIndex(_wallIndex);
    notifyListeners();
  }

  void setFontId(String id) {
    _fontId = id;
    _storage.setFontId(id);
    notifyListeners();
  }

  void setLanguageCode(String code) {
    _languageCode = code;
    _storage.setLanguageCode(code);
    notifyListeners();
  }

  bool get wallDecor => _wallDecor;

  void setWallDecor(bool value) {
    _wallDecor = value;
    _storage.setWallDecor(value);
    notifyListeners();
  }
}

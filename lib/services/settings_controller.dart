import 'package:flutter/material.dart';

import '../theme.dart';
import 'note_storage.dart';

/// App-wide appearance and language settings (things that are not per-board).
/// Persists through [NoteStorage] and notifies listeners so the app rebuilds.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage)
      : _fontId = _storage.fontId,
        _languageCode = _storage.languageCode,
        _wallDecor = _storage.wallDecor;

  final NoteStorage _storage;

  String _fontId;
  String _languageCode;
  bool _wallDecor;

  FontChoice get font => fontChoiceById(_fontId);

  String get languageCode => _languageCode;

  /// null → follow the system locale.
  Locale? get localeOverride =>
      _languageCode == 'system' ? null : Locale(_languageCode);

  bool get wallDecor => _wallDecor;

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

  void setWallDecor(bool value) {
    _wallDecor = value;
    _storage.setWallDecor(value);
    notifyListeners();
  }
}

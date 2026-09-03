import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'note_storage.dart';

export 'note_storage.dart' show NightMode;

/// App-wide appearance and language settings (things that are not per-board).
/// Persists through [NoteStorage] and notifies listeners so the app rebuilds.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage)
    : _fontId = _storage.fontId,
      _languageCode = _storage.languageCode,
      _wallDecor = _storage.wallDecor,
      _nightMode = _storage.nightMode,
      _nightStart = _storage.nightStart,
      _nightEnd = _storage.nightEnd,
      _autoTrashDone = _storage.autoTrashDone {
    _watchClock();
  }

  final NoteStorage _storage;

  String _fontId;
  String _languageCode;
  bool _wallDecor;
  NightMode _nightMode;
  int _nightStart;
  int _nightEnd;
  bool _autoTrashDone;

  Timer? _clock;
  bool? _lastScheduledNight;

  FontChoice get font => fontChoiceById(_fontId);

  String get languageCode => _languageCode;

  /// null → follow the system locale.
  Locale? get localeOverride =>
      _languageCode == 'system' ? null : Locale(_languageCode);

  bool get wallDecor => _wallDecor;

  NightMode get nightMode => _nightMode;
  int get nightStart => _nightStart;
  int get nightEnd => _nightEnd;
  bool get autoTrashDone => _autoTrashDone;

  /// The gesture tips have not been shown yet (fresh install).
  bool get tipsPending => _storage.tipsPending;

  /// The tips were shown; they stay reachable from the more menu.
  void markTipsSeen() => _storage.setTipsPending(false);

  /// Whether the scheduled window covers [now]; the window may wrap past
  /// midnight (21 → 6). Equal start and end means "never".
  bool scheduledNightAt(DateTime now) {
    final h = now.hour;
    if (_nightStart == _nightEnd) return false;
    return _nightStart < _nightEnd
        ? h >= _nightStart && h < _nightEnd
        : h >= _nightStart || h < _nightEnd;
  }

  /// What `MaterialApp.themeMode` should be for the current setting.
  ThemeMode get themeMode => switch (_nightMode) {
    NightMode.off => ThemeMode.light,
    NightMode.on => ThemeMode.dark,
    NightMode.system => ThemeMode.system,
    NightMode.schedule =>
      scheduledNightAt(DateTime.now()) ? ThemeMode.dark : ThemeMode.light,
  };

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

  void setNightMode(NightMode mode) {
    _nightMode = mode;
    _storage.setNightMode(mode);
    _watchClock();
    notifyListeners();
  }

  void setNightHours({required int start, required int end}) {
    _nightStart = start.clamp(0, 23);
    _nightEnd = end.clamp(0, 23);
    _storage
      ..setNightStart(_nightStart)
      ..setNightEnd(_nightEnd);
    _lastScheduledNight = null;
    notifyListeners();
  }

  void setAutoTrashDone(bool value) {
    _autoTrashDone = value;
    _storage.setAutoTrashDone(value);
    notifyListeners();
  }

  /// In schedule mode, checks once a minute whether the lights should have
  /// flipped and rebuilds only when they did.
  void _watchClock() {
    _clock?.cancel();
    _clock = null;
    _lastScheduledNight = null;
    if (_nightMode != NightMode.schedule) return;
    _lastScheduledNight = scheduledNightAt(DateTime.now());
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      final night = scheduledNightAt(DateTime.now());
      if (night != _lastScheduledNight) {
        _lastScheduledNight = night;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}

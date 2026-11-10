import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'note_storage.dart';

export 'note_storage.dart'
    show NightMode, WidgetContent, WidgetLook, WidgetTextSize;

/// App-wide appearance and language settings (things that are not per-board).
/// Persists through [NoteStorage] and notifies listeners so the app rebuilds.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage)
    : _fontId = _storage.fontId,
      _languageCode = _storage.languageCode,
      _wallDecor = _storage.wallDecor,
      _boardPanel = _storage.boardPanel,
      _nightMode = _storage.nightMode,
      _nightStart = _storage.nightStart,
      _nightEnd = _storage.nightEnd,
      _autoBackup = _storage.autoBackup,
      _lastAutoBackup = _storage.lastAutoBackup,
      _pinStyle = pinStyleById(_storage.pinStyle),
      _appLock = _storage.appLock,
      _widgetBoard = _storage.widgetBoard,
      _widgetContent = _storage.widgetContent,
      _widgetLook = _storage.widgetLook,
      _widgetTextSize = _storage.widgetTextSize,
      _widgetPicture = _storage.widgetPicture,
      _installedAt = _storage.installedAt ?? DateTime.now() {
    if (_storage.installedAt == null) {
      unawaited(_storage.setInstalledAt(_installedAt));
    }
    _watchClock();
  }

  final NoteStorage _storage;

  String _fontId;
  String _languageCode;
  bool _wallDecor;
  bool _boardPanel;
  NightMode _nightMode;
  int _nightStart;
  int _nightEnd;
  bool _autoBackup;
  DateTime? _lastAutoBackup;
  PinStyle _pinStyle;
  bool _appLock;
  String _widgetBoard;
  WidgetContent _widgetContent;
  WidgetLook _widgetLook;
  WidgetTextSize _widgetTextSize;
  bool _widgetPicture;
  final DateTime _installedAt;

  // Trying on a Pro wall, font or pin from Customize before buying: shown,
  // never saved, and gone when the sheet closes.
  int? _tryWall;
  String? _tryFont;
  PinStyle? _tryPin;

  Timer? _clock;
  bool? _lastScheduledNight;

  /// The chosen font, as picked — it may be a Pro one (see [fontFor]).
  FontChoice get font => fontChoiceById(_fontId);

  /// The font to draw with: one being tried on, else the chosen one — a Pro
  /// font only while Pro is unlocked.
  FontChoice fontFor({required bool pro}) {
    final tried = _tryFont;
    if (tried != null) return fontChoiceById(tried);
    return font.pro && !pro ? fontChoices.first : font;
  }

  /// The chosen pin style, as picked (see [pinStyleFor]).
  PinStyle get pinStyle => _pinStyle;

  /// The pin style to draw: one being tried on, else the chosen one — a Pro
  /// one only while Pro is unlocked.
  PinStyle pinStyleFor({required bool pro}) =>
      _tryPin ?? (_pinStyle.pro && !pro ? PinStyle.classic : _pinStyle);

  /// The bundled wall being tried on, if any (an index into `walls`).
  int? get tryWall => _tryWall;
  String? get tryFont => _tryFont;
  PinStyle? get tryPin => _tryPin;

  /// Whether a Pro wall, font or pin is on show without being bought.
  bool get tryingOn => _tryWall != null || _tryFont != null || _tryPin != null;

  /// Null stops trying a wall on.
  void setTryWall(int? index) {
    _tryWall = index;
    notifyListeners();
  }

  void setTryFont(String? id) {
    _tryFont = id;
    notifyListeners();
  }

  void setTryPin(PinStyle? style) {
    _tryPin = style;
    notifyListeners();
  }

  /// Puts back what was chosen before trying on.
  void endTryOn() {
    if (!tryingOn) return;
    _tryWall = null;
    _tryFont = null;
    _tryPin = null;
    notifyListeners();
  }

  /// Keeps the font and pin tried on (once Pro is bought); the wall belongs
  /// to the board, so the caller keeps that. Ends the try-on.
  void keepTryOn() {
    final font = _tryFont;
    final pin = _tryPin;
    if (font != null) setFontId(font);
    if (pin != null) setPinStyle(pin);
    endTryOn();
  }

  /// Whether to say a word about Pro now: once, to someone who has used
  /// the app for a week and has a good few notes up.
  bool shouldOfferPro({required int noteCount, DateTime? now}) =>
      !_storage.proOffered &&
      noteCount >= 20 &&
      (now ?? DateTime.now()).difference(_installedAt).inDays >= 7;

  void markProOffered() => unawaited(_storage.setProOffered(true));

  /// Whether opening the app asks for the phone's lock (off by default).
  bool get appLock => _appLock;

  /// The board the home-screen widget shows; empty = the open one.
  String get widgetBoard => _widgetBoard;
  WidgetContent get widgetContent => _widgetContent;
  WidgetLook get widgetLook => _widgetLook;
  WidgetTextSize get widgetTextSize => _widgetTextSize;

  /// A board picture has been sent to the widget and can be shown again.
  bool get widgetPicture => _widgetPicture;

  /// The board that picture shows.
  String get widgetPictureBoard => _storage.widgetPictureBoard;

  /// A picture of board [boardId] was just sent to the widget: show it.
  void showWidgetPicture(String boardId) {
    unawaited(_storage.setWidgetPictureBoard(boardId));
    setWidgetContent(WidgetContent.picture);
  }

  String get languageCode => _languageCode;

  /// null → follow the system locale.
  Locale? get localeOverride =>
      _languageCode == 'system' ? null : Locale(_languageCode);

  bool get wallDecor => _wallDecor;

  /// The board list floats open over the wall (wide windows only; see
  /// BoardSidebar). Closed until the user opens it.
  bool get boardPanel => _boardPanel;

  NightMode get nightMode => _nightMode;
  int get nightStart => _nightStart;
  int get nightEnd => _nightEnd;

  /// Weekly backup into the app's own folder (see `AutoBackup`).
  bool get autoBackup => _autoBackup;

  /// When the last automatic backup was written; null before the first.
  DateTime? get lastAutoBackup => _lastAutoBackup;

  /// The gesture tips have not been shown yet (fresh install).
  bool get tipsPending => _storage.tipsPending;

  /// The tips were shown; they stay reachable from the more menu.
  void markTipsSeen() => _storage.setTipsPending(false);

  bool get welcomePending => _storage.welcomePending;

  bool get readableEditor => _storage.readableEditor;

  /// How much the wall is calmed behind the notes (0..1).
  double get wallSoften => _storage.wallSoften;
  void setWallSoften(double value) {
    _storage.setWallSoften(value.clamp(0.0, 1.0));
    notifyListeners();
  }

  void setReadableEditor(bool value) => _storage.setReadableEditor(value);
  void markWelcomeSeen() => _storage.setWelcomePending(false);

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

  void setPinStyle(PinStyle style) {
    _pinStyle = style;
    _storage.setPinStyle(style.name);
    notifyListeners();
  }

  void setAppLock(bool value) {
    _appLock = value;
    _storage.setAppLock(value);
    notifyListeners();
  }

  void setWidgetBoard(String boardId) {
    _widgetBoard = boardId;
    _storage.setWidgetBoard(boardId);
    notifyListeners();
  }

  void setWidgetContent(WidgetContent value) {
    _widgetContent = value;
    _storage.setWidgetContent(value);
    if (value == WidgetContent.picture) {
      _widgetPicture = true;
      _storage.setWidgetPicture(true);
    }
    notifyListeners();
  }

  void setWidgetLook(WidgetLook value) {
    _widgetLook = value;
    _storage.setWidgetLook(value);
    notifyListeners();
  }

  void setWidgetTextSize(WidgetTextSize value) {
    _widgetTextSize = value;
    _storage.setWidgetTextSize(value);
    notifyListeners();
  }

  void setLanguageCode(String code) {
    _languageCode = code;
    _storage.setLanguageCode(code);
    notifyListeners();
  }

  void setBoardPanel(bool value) {
    if (value == _boardPanel) return;
    _boardPanel = value;
    _storage.setBoardPanel(value);
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

  void setAutoBackup(bool value) {
    _autoBackup = value;
    _storage.setAutoBackup(value);
    notifyListeners();
  }

  /// Records that an automatic backup was just written at [at].
  Future<void> markAutoBackup(DateTime at) async {
    _lastAutoBackup = at;
    notifyListeners();
    await _storage.setLastAutoBackup(at);
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

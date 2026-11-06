import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'models/view_mode.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/auto_backup.dart';
import 'services/image_service.dart';
import 'services/note_storage.dart';
import 'services/notes_controller.dart';
import 'services/pro_controller.dart';
import 'services/recents_privacy.dart';
import 'services/reminder_service.dart';
import 'services/sample_notes.dart';
import 'services/settings_controller.dart';
import 'services/share_service.dart';
import 'services/sync/drive_backend.dart';
import 'services/sync/sync_service.dart';
import 'services/widget_service.dart';
import 'theme.dart';
import 'widgets/lock_gate.dart';

/// Boots storage, reminders and the image cache, seeds the sample notes on a
/// first run, wires the home-screen widget, then starts the app.
/// Whether this build offers sync (see main).
const _syncBuild = bool.fromEnvironment('STICKY_SYNC');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await NoteStorage.create();
  final reminders = ReminderService();
  await Future.wait([reminders.init(), ImageService.init()]);

  // Decided before the controller writes its default board.
  final firstRun = storage.isFirstRun;
  final notes = NotesController(
    storage,
    reminders,
    deletePhoto: ImageService.deleteFile,
    deleteWallImage: ImageService.deleteWallFile,
    deleteAudio: AudioService.deleteFile,
  );
  final settings = SettingsController(storage);
  final pro = ProController(
    storage,
    store: kIsWeb ? null : InAppPurchase.instance,
  );
  // The price and an earlier purchase arrive in the background; until then
  // Pro is whatever it was last time.
  unawaited(pro.init());
  // What Android's notification settings call the channel, in the app's
  // language rather than always in English.
  final words = _localizationsFor(settings.localeOverride);
  ReminderService.labels = (
    channel: words.remindersChannel,
    description: words.remindersChannelDescription,
    fallback: words.appTitle,
    hidden: words.reminderPrivate,
  );

  if (firstRun) {
    final views = PlatformDispatcher.instance.views;
    final sample = SampleNotes.build(
      _localizationsFor(settings.localeOverride),
      notes.currentBoardId,
      // Laid out for this screen: on a tablet the samples keep the distances
      // they have on a phone instead of being stretched to the corners.
      wall: views.isEmpty ? null : HomeScreen.wallSizeFor(views.first),
    );
    // Marked as examples: "Start with a blank wall" takes them away again.
    for (final n in sample.notes) {
      n.sample = true;
    }
    notes.seed(sample.notes, links: sample.links);
    // The samples teach wall gestures (and one is tied to another by a
    // thread), so a fresh install opens on the wall rather than the grid,
    // under the welcome that offers a blank wall or a template instead.
    notes.viewMode = ViewMode.wall;
    await storage.setWelcomePending(true);
  }

  // Sync across devices (Google Drive's app folder), off unless switched
  // on. Offered on Android, and only in builds made with
  // --dart-define=STICKY_SYNC=true: a release without the Google OAuth
  // clients set up would show a switch that cannot connect.
  if (!kIsWeb && Platform.isAndroid && _syncBuild) {
    final sync = SyncService(
      prefs: await SharedPreferences.getInstance(),
      notes: notes,
    );
    SyncService.instance = sync;
    if (sync.enabled) sync.attach(DriveSyncBackend());
    Timer? pending;
    // A change syncs half a minute after the last edit, not on every one.
    notes.addListener(() {
      if (!sync.enabled || sync.applying) return;
      pending?.cancel();
      pending = Timer(const Duration(seconds: 30), sync.syncNow);
    });
    AppLifecycleListener(
      onResume: () => unawaited(sync.syncNow()),
      onPause: () {
        if (pending?.isActive ?? false) {
          pending!.cancel();
          unawaited(sync.syncNow());
        }
      },
    );
    if (sync.enabled) unawaited(sync.syncNow());
  }

  // While the app lock is on or a private board is open, the recent-apps
  // screen shows no notes.
  void syncRecents() => RecentsPrivacy.hide(
    settings.appLock || notes.boards.any((b) => b.isPrivate && notes.isOpen(b)),
  );
  settings.addListener(syncRecents);
  notes.addListener(syncRecents);
  syncRecents();

  // Keep the home-screen widget in sync with the board and notes it shows
  // (and with the language, so untitled notes get the right placeholder).
  final widgetService = WidgetService();
  await WidgetService.init();
  void syncWidget() {
    final l10n = _localizationsFor(settings.localeOverride);
    final board =
        notes.boards.where((b) => b.id == settings.widgetBoard).firstOrNull ??
        notes.currentBoard;
    var content = settings.widgetContent;
    // A picture of a board that has since been made private is not shown.
    final pictured = notes.boards
        .where((b) => b.id == settings.widgetPictureBoard)
        .firstOrNull;
    if (content == WidgetContent.picture &&
        (board.isPrivate || (pictured?.isPrivate ?? false))) {
      content = WidgetContent.pinned;
    }
    // The home screen is in plain view: a private board never lists its
    // notes there, open or not.
    widgetService.update(
      title: board.name.isEmpty ? l10n.defaultBoardName : board.name,
      notes: board.isPrivate
          ? const []
          : WidgetService.notesFor(notes.allNotes, board.id, content),
      empty: board.isPrivate
          ? l10n.widgetPrivate
          : content == WidgetContent.newest
          ? l10n.widgetEmptyNewest
          : l10n.widgetEmptyPinned,
      checklistLabel: l10n.typeChecklist,
      drawingLabel: l10n.typeDrawing,
      photoLabel: l10n.typePhoto,
      audioLabel: l10n.typeAudio,
      content: content,
      look: settings.widgetLook,
      textSize: settings.widgetTextSize,
    );
  }

  notes.addListener(syncWidget);
  settings.addListener(syncWidget);
  syncWidget();

  // The weekly safety copy, once the first frames are out of the way. Fire
  // and forget: it logs its own failures and never holds up the start.
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 3),
      () => AutoBackup.runIfDue(settings, notes),
    ),
  );

  runApp(
    StickyWallApp(
      settings: settings,
      notes: notes,
      pro: pro,
      shareReceiver: ShareReceiver(),
    ),
  );
}

/// Resolves strings outside the widget tree (for the home-screen widget):
/// the chosen language, else the device language if we support it, else EN.
AppLocalizations _localizationsFor(Locale? override) {
  final device = PlatformDispatcher.instance.locale;
  final candidate = override ?? Locale(device.languageCode);
  final supported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == candidate.languageCode,
  );
  return lookupAppLocalizations(
    supported ? Locale(candidate.languageCode) : const Locale('en'),
  );
}

/// Root widget: builds the paper theme from the chosen font and night mode,
/// installs localization, and shows the [HomeScreen].
class StickyWallApp extends StatelessWidget {
  const StickyWallApp({
    super.key,
    required this.settings,
    required this.notes,
    this.pro,
    this.shareReceiver,
  });

  final SettingsController settings;
  final NotesController notes;

  /// Sticky Wall Pro; null in tests that don't need it (Pro then counts as
  /// not bought).
  final ProController? pro;
  final ShareReceiver? shareReceiver;

  /// One per notes controller: tells the app when the open board's own
  /// handwriting or pin changes, and not on every note moved.
  static final _boardStyles = Expando<_BoardStyle>();

  @override
  Widget build(BuildContext context) {
    final pro = this.pro;
    final boardStyle = _boardStyles[notes] ??= _BoardStyle(notes);
    final app = ListenableBuilder(
      listenable: Listenable.merge([settings, boardStyle, ?pro]),
      builder: (context, _) {
        final unlocked = pro?.unlocked ?? false;
        final board = notes.currentBoard;
        // A theme pack's handwriting and pin belong to its board; one being
        // tried on in Customize shows over it.
        final font = settings.tryFont == null && board.fontId.isNotEmpty
            ? fontChoiceById(board.fontId)
            : settings.fontFor(pro: unlocked);
        final pin = settings.tryPin == null && board.pinStyle.isNotEmpty
            ? pinStyleById(board.pinStyle)
            : settings.pinStyleFor(pro: unlocked);
        return _app(font, pin);
      },
    );
    return pro == null ? app : ProScope(controller: pro, child: app);
  }

  Widget _app(FontChoice font, PinStyle pin) => MaterialApp(
    title: 'Sticky Wall',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(font, pin: pin),
    // "Lights off": the same warm theme, dimmed — never a grey dark mode.
    darkTheme: buildAppTheme(font, night: true, pin: pin),
    themeMode: settings.themeMode,
    locale: settings.localeOverride,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // Notes carry their own depth; the platform's injected scrollbar
    // (desktop/web) clutters the wall, so hide it globally.
    scrollBehavior: const _NoScrollbarBehavior(),
    // Above the navigator, so a lock covers open dialogs and sheets too.
    builder: (context, child) =>
        LockGate(enabled: settings.appLock, child: child!),
    home: HomeScreen(
      notes: notes,
      settings: settings,
      shareReceiver: shareReceiver,
    ),
  );
}

/// Notifies when the open board's own font or pin changes.
class _BoardStyle extends ChangeNotifier {
  _BoardStyle(this._notes) {
    _key = _keyNow();
    _notes.addListener(_check);
  }

  final NotesController _notes;
  late String _key;

  String _keyNow() {
    final b = _notes.currentBoard;
    return '${b.id}|${b.fontId}|${b.pinStyle}';
  }

  void _check() {
    final key = _keyNow();
    if (key == _key) return;
    _key = key;
    notifyListeners();
  }
}

/// Material scroll physics without the platform scrollbar.
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

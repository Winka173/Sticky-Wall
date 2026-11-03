import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'l10n/app_localizations.dart';
import 'models/view_mode.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/auto_backup.dart';
import 'services/image_service.dart';
import 'services/note_storage.dart';
import 'services/notes_controller.dart';
import 'services/pro_controller.dart';
import 'services/reminder_service.dart';
import 'services/sample_notes.dart';
import 'services/settings_controller.dart';
import 'services/share_service.dart';
import 'services/widget_service.dart';
import 'theme.dart';
import 'widgets/lock_gate.dart';

/// Boots storage, reminders and the image cache, seeds the sample notes on a
/// first run, wires the home-screen widget, then starts the app.
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
    notes.seed(sample.notes, links: sample.links);
    // The samples teach wall gestures (and one is tied to another by a
    // thread), so a fresh install opens on the wall rather than the grid —
    // where the gesture tips are offered once.
    notes.viewMode = ViewMode.wall;
    await storage.setTipsPending(true);
  }

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

  @override
  Widget build(BuildContext context) {
    final pro = this.pro;
    final app = ListenableBuilder(
      listenable: Listenable.merge([settings, ?pro]),
      builder: (context, _) {
        final unlocked = pro?.unlocked ?? false;
        final font = settings.fontFor(pro: unlocked);
        final pin = settings.pinStyleFor(pro: unlocked);
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

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'models/view_mode.dart';
import 'screens/home_screen.dart';
import 'services/image_service.dart';
import 'services/note_storage.dart';
import 'services/notes_controller.dart';
import 'services/reminder_service.dart';
import 'services/sample_notes.dart';
import 'services/settings_controller.dart';
import 'services/share_service.dart';
import 'services/widget_service.dart';
import 'theme.dart';

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
  );
  final settings = SettingsController(storage);

  if (firstRun) {
    final sample = SampleNotes.build(
        _localizationsFor(settings.localeOverride), notes.currentBoardId);
    notes.seed(sample.notes, links: sample.links);
    // The samples teach wall gestures (and one is tied to another by a
    // thread), so a fresh install opens on the wall rather than the grid.
    notes.viewMode = ViewMode.wall;
  }

  // Keep the home-screen widget in sync with the current board's pinned notes
  // (and with the language, so untitled notes get the right placeholder).
  final widgetService = WidgetService();
  void syncWidget() {
    final l10n = _localizationsFor(settings.localeOverride);
    final board = notes.currentBoard;
    widgetService.update(
      title: board.name.isEmpty ? l10n.defaultBoardName : board.name,
      pinned: notes.boardNotes.where((n) => n.pinned).toList(growable: false),
      checklistLabel: l10n.typeChecklist,
      drawingLabel: l10n.typeDrawing,
      photoLabel: l10n.typePhoto,
    );
  }

  notes.addListener(syncWidget);
  settings.addListener(syncWidget);
  syncWidget();

  runApp(StickyWallApp(
    settings: settings,
    notes: notes,
    shareReceiver: ShareReceiver(),
  ));
}

/// Resolves strings outside the widget tree (for the home-screen widget):
/// the chosen language, else the device language if we support it, else EN.
AppLocalizations _localizationsFor(Locale? override) {
  final device = PlatformDispatcher.instance.locale;
  final candidate = override ?? Locale(device.languageCode);
  final supported = AppLocalizations.supportedLocales
      .any((l) => l.languageCode == candidate.languageCode);
  return lookupAppLocalizations(
      supported ? Locale(candidate.languageCode) : const Locale('en'));
}

/// Root widget: builds the paper theme from the chosen font and night mode,
/// installs localization, and shows the [HomeScreen].
class StickyWallApp extends StatelessWidget {
  const StickyWallApp({
    super.key,
    required this.settings,
    required this.notes,
    this.shareReceiver,
  });

  final SettingsController settings;
  final NotesController notes;
  final ShareReceiver? shareReceiver;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Sticky Wall',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(settings.font),
        // "Lights off": the same warm theme, dimmed — never a grey dark mode.
        darkTheme: buildAppTheme(settings.font, night: true),
        themeMode: settings.themeMode,
        locale: settings.localeOverride,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Notes carry their own depth; the platform's injected scrollbar
        // (desktop/web) clutters the wall, so hide it globally.
        scrollBehavior: const _NoScrollbarBehavior(),
        home: HomeScreen(
          notes: notes,
          settings: settings,
          shareReceiver: shareReceiver,
        ),
      ),
    );
  }
}

/// Material scroll physics without the platform scrollbar.
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/image_service.dart';
import 'services/note_storage.dart';
import 'services/notes_controller.dart';
import 'services/reminder_service.dart';
import 'services/settings_controller.dart';
import 'services/widget_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await NoteStorage.create();
  final reminders = ReminderService();
  await Future.wait([reminders.init(), ImageService.init()]);

  final notes = NotesController(storage, reminders);
  final settings = SettingsController(storage);

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
    );
  }

  notes.addListener(syncWidget);
  settings.addListener(syncWidget);
  syncWidget();

  runApp(StickyWallApp(settings: settings, notes: notes));
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

class StickyWallApp extends StatelessWidget {
  const StickyWallApp({
    super.key,
    required this.settings,
    required this.notes,
  });

  final SettingsController settings;
  final NotesController notes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Sticky Wall',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(settings.font),
        locale: settings.localeOverride,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Notes carry their own depth; the platform's injected scrollbar
        // (desktop/web) clutters the wall, so hide it globally.
        scrollBehavior: const _NoScrollbarBehavior(),
        home: HomeScreen(notes: notes, settings: settings),
      ),
    );
  }
}

class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

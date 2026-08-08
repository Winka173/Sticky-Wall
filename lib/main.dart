import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/note_storage.dart';
import 'services/notes_controller.dart';
import 'services/reminder_service.dart';
import 'services/settings_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await NoteStorage.create();
  final reminders = ReminderService();
  await reminders.init();
  runApp(
    StickyWallApp(
      settings: SettingsController(storage),
      notes: NotesController(storage, reminders),
    ),
  );
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

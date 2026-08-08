import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/note_storage.dart';
import 'services/settings_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await NoteStorage.create();
  runApp(
    StickyWallApp(storage: storage, settings: SettingsController(storage)),
  );
}

class StickyWallApp extends StatelessWidget {
  const StickyWallApp({
    super.key,
    required this.storage,
    required this.settings,
  });

  final NoteStorage storage;
  final SettingsController settings;

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
        home: HomeScreen(storage: storage, settings: settings),
      ),
    );
  }
}

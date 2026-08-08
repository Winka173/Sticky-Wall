import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/note_storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await NoteStorage.create();
  runApp(StickyWallApp(storage: storage));
}

class StickyWallApp extends StatelessWidget {
  const StickyWallApp({super.key, required this.storage});

  final NoteStorage storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticky Wall',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: HomeScreen(storage: storage),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';

/// Pumps the app and counts how often it asks the system to close it.
Future<(SettingsController, List<int>)> _app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([Board(id: 'b', name: 'Home', wallIndex: 0)]);
  await storage.saveNotes([]);
  await storage.setViewMode(ViewMode.wall);
  await storage.setLanguageCode('en');
  final settings = SettingsController(storage);
  final closes = <int>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') closes.add(1);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  await tester.pumpWidget(
    StickyWallApp(
      settings: settings,
      notes: NotesController(storage, ReminderService()),
    ),
  );
  await tester.pumpAndSettle();
  return (settings, closes);
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

void main() {
  testWidgets('one Back asks, a second one within two seconds leaves', (
    tester,
  ) async {
    final (_, closes) = await _app(tester);
    await _back(tester);
    expect(find.text('Press Back again to leave'), findsOneWidget);
    expect(closes, isEmpty);
    await _back(tester);
    expect(closes, hasLength(1));
  });

  testWidgets('after two seconds a Back asks again', (tester) async {
    final (_, closes) = await _app(tester);
    await _back(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await _back(tester);
    expect(closes, isEmpty);
    expect(find.text('Press Back again to leave'), findsOneWidget);
  });

  testWidgets('turned off, one Back leaves', (tester) async {
    final (settings, closes) = await _app(tester);
    settings.setBackTwiceToExit(false);
    await tester.pumpAndSettle();
    await _back(tester);
    expect(closes, hasLength(1));
    expect(settings.backTwiceToExit, isFalse);
  });
}

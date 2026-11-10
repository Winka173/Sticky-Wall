import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';

Future<NotesController> _app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(2560, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes([
    for (final (i, text) in ['Milk', 'Call Mom'].indexed)
      Note(
        guid: 'n$i',
        content: text,
        createdAt: DateTime(2026),
        boardId: 'default',
      ),
  ]);
  await storage.setViewMode(ViewMode.grid);
  await storage.setLanguageCode('en');
  final notes = NotesController(storage, ReminderService());
  await tester.pumpWidget(
    StickyWallApp(settings: SettingsController(storage), notes: notes),
  );
  await tester.pumpAndSettle();
  return notes;
}

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Ctrl+F searches and Esc leaves the search', (tester) async {
    await _app(tester);
    expect(find.byType(TextField), findsNothing);
    await _ctrl(tester, LogicalKeyboardKey.keyF);
    expect(find.byType(TextField), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Ctrl+A selects every note and Delete trashes them', (
    tester,
  ) async {
    final notes = await _app(tester);
    await _ctrl(tester, LogicalKeyboardKey.keyA);
    expect(find.text('2 selected'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(notes.boardNotes, isEmpty);
  });

  testWidgets('Esc leaves a selection', (tester) async {
    await _app(tester);
    await _ctrl(tester, LogicalKeyboardKey.keyA);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsNothing);
  });

  testWidgets('Ctrl+N opens a new note', (tester) async {
    await _app(tester);
    await _ctrl(tester, LogicalKeyboardKey.keyN);
    // The editor's save button.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('a right click on a note opens its menu', (tester) async {
    await _app(tester);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(
      find.text('Milk'),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    // The same sheet a long press opens.
    expect(find.byType(BottomSheet), findsOneWidget);
  });
}

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

const _url = 'https://a.vn/menu';

Note _note({List<String>? plain}) => Note(
  guid: 'n1',
  content: 'Menu for Saturday $_url ok',
  createdAt: DateTime(2026),
  boardId: 'default',
  plainLinks: plain,
);

/// The app on the grid with one text note; returns the controller and the
/// addresses the browser was asked to open.
Future<(NotesController, List<String>)> _pump(
  WidgetTester tester, {
  List<String>? plain,
  ViewMode view = ViewMode.grid,
}) async {
  final opened = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/url_launcher'),
    (call) async {
      final args = call.arguments as Map<Object?, Object?>?;
      if (call.method == 'launch') opened.add(args!['url']! as String);
      return true;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    ),
  );
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes([_note(plain: plain)]);
  await storage.setViewMode(view);
  final notes = NotesController(storage, ReminderService());
  await tester.pumpWidget(
    StickyWallApp(settings: SettingsController(storage), notes: notes),
  );
  await tester.pumpAndSettle();
  return (notes, opened);
}

Future<void> _saveEditor(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.check));
  await tester.pumpAndSettle();
}

void main() {
  test('plain addresses travel with the note, and old notes have none', () {
    final note = _note(plain: [_url]);
    expect(Note.fromJson(note.toJson()).plainLinks, [_url]);
    expect(_note().toJson().containsKey('plainLinks'), isFalse);
    final old = _note().toJson()..remove('plainLinks');
    expect(Note.fromJson(old).plainLinks, isEmpty);
  });

  testWidgets('a tap on an address opens it; elsewhere opens the note', (
    tester,
  ) async {
    final (_, opened) = await _pump(tester);
    await tester.tapOnText(find.textRange.ofSubstring(_url));
    await tester.pumpAndSettle();
    expect(opened, [_url]);
    expect(find.text('Links in this note'), findsNothing);

    await tester.tapOnText(find.textRange.ofSubstring('Saturday'));
    await tester.pumpAndSettle();
    expect(find.text('Links in this note'), findsOneWidget);
    expect(opened, [_url]);
  });

  testWidgets('an address turned back into words is no link, and back', (
    tester,
  ) async {
    final (notes, opened) = await _pump(tester);
    await tester.tapOnText(find.textRange.ofSubstring('Saturday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove link'));
    await tester.pump();
    expect(find.text('Make it a link'), findsOneWidget);
    await _saveEditor(tester);
    expect(notes.allNotes.single.plainLinks, [_url]);

    // Now a tap on the address opens the note like any other word.
    await tester.tapOnText(find.textRange.ofSubstring(_url));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    await tester.tap(find.text('Make it a link'));
    await tester.pump();
    await _saveEditor(tester);
    expect(notes.allNotes.single.plainLinks, isEmpty);

    await tester.tapOnText(find.textRange.ofSubstring(_url));
    await tester.pumpAndSettle();
    expect(opened, [_url]);
  });

  testWidgets('an address deleted from the words is forgotten', (tester) async {
    final (notes, _) = await _pump(tester, plain: [_url]);
    await tester.tapOnText(find.textRange.ofSubstring('Saturday'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Menu for Saturday');
    await tester.pump();
    expect(find.text('Links in this note'), findsNothing);
    await _saveEditor(tester);
    expect(notes.allNotes.single.plainLinks, isEmpty);
  });

  testWidgets('on the wall too, an address opens and a word opens the note', (
    tester,
  ) async {
    final (_, opened) = await _pump(tester, view: ViewMode.wall);
    await tester.tapOnText(find.textRange.ofSubstring(_url));
    await tester.pumpAndSettle();
    expect(opened, [_url]);
    await tester.tapOnText(find.textRange.ofSubstring('Saturday'));
    await tester.pumpAndSettle();
    expect(find.text('Links in this note'), findsOneWidget);
  });
}

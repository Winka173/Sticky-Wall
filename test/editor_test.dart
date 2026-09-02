import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/add_note_button.dart';

Future<NotesController> _pumpApp(WidgetTester tester,
    {List<Note> notes = const [], ViewMode? viewMode}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes(notes);
  if (viewMode != null) await storage.setViewMode(viewMode);
  final controller = NotesController(storage, ReminderService());
  await tester.pumpWidget(StickyWallApp(
    settings: SettingsController(storage),
    notes: controller,
  ));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(AddNoteButton));
  await tester.pumpAndSettle();
}

Finder get _saveButton => find.byIcon(Icons.check);

void main() {
  testWidgets('saving an empty note shows an inline error and stays open',
      (tester) async {
    final notes = await _pumpApp(tester);
    await _openEditor(tester);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Write something first'), findsOneWidget);
    expect(_saveButton, findsOneWidget); // dialog still open
    expect(notes.boardNotes, isEmpty);

    // Typing clears the error.
    await tester.enterText(find.byType(TextField).first, 'Buy bread');
    await tester.pumpAndSettle();
    expect(find.text('Write something first'), findsNothing);
  });

  testWidgets('typing and saving sticks the note on the wall', (tester) async {
    final notes = await _pumpApp(tester);
    await _openEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'Buy bread');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(notes.boardNotes.single.content, 'Buy bread');
    expect(find.text('Buy bread'), findsOneWidget);
    expect(_saveButton, findsNothing);
  });

  testWidgets('a link already on the wall is rejected, www/scheme ignored',
      (tester) async {
    final notes = await _pumpApp(tester, notes: [
      Note(
        guid: 'x',
        content: 'Docs',
        url: 'https://www.docs.flutter.dev/',
        createdAt: DateTime(2026),
        boardId: 'default',
      ),
    ]);
    await _openEditor(tester);

    await tester.tap(find.byTooltip('Link'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'docs.flutter.dev');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('This link is already on the wall'), findsOneWidget);
    expect(notes.boardNotes.length, 1);

    // A different link with no title saves and shows its address.
    await tester.enterText(fields.at(1), 'https://dart.dev');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(notes.boardNotes.length, 2);
    expect(
        notes.boardNotes.any((n) => n.content == 'https://dart.dev'), true);
  });

  testWidgets('checklist keeps a typed-but-unsubmitted item on save',
      (tester) async {
    final notes = await _pumpApp(tester);
    await _openEditor(tester);

    await tester.tap(find.byTooltip('To-do list'));
    await tester.pumpAndSettle();

    // Title field, then the "add item" field.
    await tester.enterText(find.byType(TextField).at(1), 'milk');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'milk'), findsOneWidget);

    // Second item typed without pressing enter.
    await tester.enterText(find.byType(TextField).last, 'eggs');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    final note = notes.boardNotes.single;
    expect(note.type, NoteType.checklist);
    expect(note.checklist.map((i) => i.text), ['milk', 'eggs']);
  });

  testWidgets('a photo print needs at least one photo', (tester) async {
    final notes = await _pumpApp(tester);
    await _openEditor(tester);

    await tester.tap(find.byTooltip('Photo'));
    await tester.pumpAndSettle();
    // The strip shows the invitation, the caption hint replaces the title.
    expect(find.text('Add photos'), findsOneWidget);
    expect(find.text('Caption'), findsOneWidget);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Add at least one photo'), findsOneWidget);
    expect(notes.boardNotes, isEmpty);
  });

  testWidgets('a print pinned on the wall shows its caption and actions',
      (tester) async {
    final notes = await _pumpApp(tester, notes: [
      Note(
        guid: 'p',
        content: 'Beach day',
        type: NoteType.photo,
        images: ['missing.jpg'],
        createdAt: DateTime(2026),
        boardId: 'default',
      ),
    ]);
    expect(notes.boardNotes.single.type, NoteType.photo);
    expect(find.text('Beach day'), findsOneWidget);

    // Long-press opens the action sheet — every row visible, "View photos"
    // included, nothing overflowing on a small screen.
    await tester.longPress(find.text('Beach day'));
    await tester.pumpAndSettle();
    expect(find.text('View photos'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long-pressing empty wall offers a note or photos there',
      (tester) async {
    // The free-drag wall is where long-press-to-create lives; the default
    // grid layout has no such spot.
    final notes = await _pumpApp(tester, viewMode: ViewMode.wall);
    await tester.longPressAt(const Offset(200, 400));
    await tester.pumpAndSettle();
    expect(find.text('Sticky note here'), findsOneWidget);
    expect(find.text('Photos here'), findsOneWidget);

    await tester.tap(find.text('Sticky note here'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Right here');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(notes.boardNotes.single.content, 'Right here');
  });
}

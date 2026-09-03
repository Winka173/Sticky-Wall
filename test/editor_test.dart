import 'dart:math' as math;

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
import 'package:sticky_wall/widgets/board_poster.dart';
import 'package:sticky_wall/widgets/note_views.dart';

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

  testWidgets('a photo print needs its photo', (tester) async {
    final notes = await _pumpApp(tester);
    await _openEditor(tester);

    await tester.tap(find.byTooltip('Photo'));
    await tester.pumpAndSettle();
    // The invitation tile shows, the caption hint replaces the title.
    expect(find.text('Add photo'), findsOneWidget);
    expect(find.text('Caption'), findsOneWidget);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Add a photo'), findsOneWidget);
    expect(notes.boardNotes, isEmpty);
  });

  testWidgets('a print pinned on the wall shows its caption and actions',
      (tester) async {
    final notes = await _pumpApp(tester, notes: [
      Note(
        guid: 'p',
        content: 'Beach day',
        type: NoteType.photo,
        imagePath: 'missing.jpg',
        createdAt: DateTime(2026),
        boardId: 'default',
      ),
    ]);
    expect(notes.boardNotes.single.type, NoteType.photo);
    expect(find.text('Beach day'), findsOneWidget);

    // Long-press opens the action sheet — every row visible, "View photo"
    // included, nothing overflowing on a small screen.
    await tester.longPress(find.text('Beach day'));
    await tester.pumpAndSettle();
    expect(find.text('View photo'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a note with a photo can swap or drop it in the editor',
      (tester) async {
    final notes = await _pumpApp(tester, notes: [
      Note(
        guid: 'n',
        content: 'One snap',
        imagePath: 'a.jpg',
        createdAt: DateTime(2026),
        boardId: 'default',
      ),
    ]);
    await tester.tap(find.text('One snap'));
    await tester.pumpAndSettle();

    // With a photo attached the tool button offers to replace it, and the
    // photo tile carries its own remove button.
    expect(find.byTooltip('Replace photo'), findsOneWidget);
    expect(find.byTooltip('Add photo'), findsNothing);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add photo'), findsOneWidget);
    expect(find.byTooltip('Replace photo'), findsNothing);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(notes.boardNotes.single.imagePath, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rotate grip turns a wall note; a tap squares it up',
      (tester) async {
    final notes = await _pumpApp(tester, viewMode: ViewMode.wall, notes: [
      Note(
        guid: 't',
        content: 'Turn me',
        createdAt: DateTime(2026),
        boardId: 'default',
        x: 0.5,
        y: 0.3,
      ),
    ]);
    final note = notes.boardNotes.single;
    expect(find.byIcon(Icons.rotate_right), findsOneWidget);
    // The grips only show up on the note last touched: nudge it (further
    // than the pan slop, or the drag never starts).
    await tester.drag(find.text('Turn me'), const Offset(0, 60));
    await tester.pumpAndSettle();

    // Swing the grip an eighth of a turn round the card's centre.
    final grip = find.byIcon(Icons.rotate_right);
    final pivot = tester.getCenter(find.byType(NoteTurn));
    final start = tester.getCenter(grip);
    final radius = (start - pivot).distance;
    final from = math.atan2(start.dy - pivot.dy, start.dx - pivot.dx);
    final gesture = await tester.startGesture(start);
    for (var i = 1; i <= 8; i++) {
      final a = from + (math.pi / 4) * i / 8;
      await gesture.moveTo(
          pivot + Offset(radius * math.cos(a), radius * math.sin(a)));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(note.rotation, isNotNull);
    expect(note.rotation!, closeTo(noteTilt(note) + math.pi / 4, 0.02));

    // A tap on the same grip straightens the note.
    await tester.tap(find.byIcon(Icons.rotate_right));
    await tester.pumpAndSettle();
    expect(note.rotation, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a turn near a quarter turn clicks into place', (tester) async {
    final notes = await _pumpApp(tester, viewMode: ViewMode.wall, notes: [
      Note(
        guid: 't',
        content: 'Snap me',
        createdAt: DateTime(2026),
        boardId: 'default',
        x: 0.5,
        y: 0.3,
        rotation: 0.5,
      ),
    ]);
    final note = notes.boardNotes.single;
    await tester.drag(find.text('Snap me'), const Offset(0, 60));
    await tester.pumpAndSettle();

    // Aim 2° past upright: within the snap band, so it lands exactly on 0.
    final grip = find.byIcon(Icons.rotate_right);
    final pivot = tester.getCenter(find.byType(NoteTurn));
    final start = tester.getCenter(grip);
    final radius = (start - pivot).distance;
    final from = math.atan2(start.dy - pivot.dy, start.dx - pivot.dx);
    final gesture = await tester.startGesture(start);
    final a = from - 0.5 - 0.035;
    await gesture.moveTo(
        pivot + Offset(radius * math.cos(a), radius * math.sin(a)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(note.rotation, 0);
  });

  testWidgets('two fingers on a wall note twist it round', (tester) async {
    final notes = await _pumpApp(tester, viewMode: ViewMode.wall, notes: [
      Note(
        guid: 't',
        content: 'Twist me',
        createdAt: DateTime(2026),
        boardId: 'default',
        x: 0.5,
        y: 0.3,
      ),
    ]);
    final note = notes.boardNotes.single;
    final c = tester.getCenter(find.text('Twist me'));
    const r = 30.0;
    Offset at(double a) => c + Offset(r * math.cos(a), r * math.sin(a));

    // Two fingers either side of the centre, turned together through 0.6
    // rad while keeping their distance: a pure twist, no pinch.
    final g1 = await tester.startGesture(at(0));
    final g2 = await tester.startGesture(at(math.pi));
    await tester.pump();
    for (var i = 1; i <= 6; i++) {
      final a = 0.6 * i / 6;
      await g1.moveTo(at(a));
      await g2.moveTo(at(math.pi + a));
      await tester.pump();
    }
    await g1.up();
    await g2.up();
    await tester.pumpAndSettle();
    expect(note.rotation, isNotNull);
    expect(note.rotation!, closeTo(noteTilt(note) + 0.6, 0.02));
    expect(note.scale, 1.0, reason: 'the fingers kept their distance');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pinch on a wall note resizes it', (tester) async {
    final notes = await _pumpApp(tester, viewMode: ViewMode.wall, notes: [
      Note(
        guid: 't',
        content: 'Pinch me',
        createdAt: DateTime(2026),
        boardId: 'default',
        x: 0.5,
        y: 0.3,
      ),
    ]);
    final note = notes.boardNotes.single;
    final c = tester.getCenter(find.text('Pinch me'));
    final g1 = await tester.startGesture(c + const Offset(-20, 0));
    final g2 = await tester.startGesture(c + const Offset(20, 0));
    await tester.pump();
    await g1.moveTo(c + const Offset(-40, 0));
    await g2.moveTo(c + const Offset(40, 0));
    await tester.pump();
    await g1.up();
    await g2.up();
    await tester.pumpAndSettle();
    // Fingers twice as far apart: double the size, less the 4% dead band.
    expect(note.scale, closeTo(2 / 1.04, 0.02));
    expect(note.rotation, isNull, reason: 'no twist, no turn');
  });

  testWidgets('export shows the board alone, ready to share', (tester) async {
    await _pumpApp(tester, viewMode: ViewMode.wall, notes: [
      Note(
        guid: 'a',
        content: 'Plan A',
        createdAt: DateTime(2026),
        boardId: 'default',
      ),
    ]);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export board as image'));
    await tester.pumpAndSettle();

    expect(find.byType(BoardPosterPage), findsOneWidget);
    // The note is on the poster (the home wall behind is offstage); none of
    // the app's own controls are.
    expect(find.text('Plan A'), findsOneWidget);
    expect(find.byType(AddNoteButton), findsNothing);
    expect(find.byIcon(Icons.rotate_right), findsNothing);
    expect(find.byIcon(Icons.open_in_full), findsNothing);
    expect(find.byTooltip('Share as image'), findsOneWidget);
    expect(find.byTooltip('Save image'), findsOneWidget);
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

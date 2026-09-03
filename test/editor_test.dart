import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/screens/home_screen.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/add_note_button.dart';
import 'package:sticky_wall/widgets/board_bar.dart';
import 'package:sticky_wall/widgets/board_poster.dart';
import 'package:sticky_wall/widgets/drawing_canvas.dart';
import 'package:sticky_wall/widgets/note_views.dart';
import 'package:sticky_wall/widgets/wall_background.dart';
import 'package:sticky_wall/widgets/wall_view.dart';

Future<NotesController> _pumpApp(
  WidgetTester tester, {
  List<Note> notes = const [],
  ViewMode? viewMode,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes(notes);
  if (viewMode != null) await storage.setViewMode(viewMode);
  final controller = NotesController(storage, ReminderService());
  await tester.pumpWidget(
    StickyWallApp(settings: SettingsController(storage), notes: controller),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(AddNoteButton));
  await tester.pumpAndSettle();
}

Finder get _saveButton => find.byIcon(Icons.check);

/// Drags a wall note by exactly [by], in one move past the pan slop. The
/// note claims the gesture from where the finger landed, so the whole move
/// counts (unlike `tester.drag`, whose slop-sized first step is swallowed by
/// the competing wall pan).
Future<void> _dragNote(WidgetTester tester, Finder note, Offset by) async {
  final g = await tester.startGesture(tester.getCenter(note));
  await g.moveBy(by);
  await tester.pump();
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saving an empty note shows an inline error and stays open', (
    tester,
  ) async {
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

  testWidgets('a link already on the wall is rejected, www/scheme ignored', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      notes: [
        Note(
          guid: 'x',
          content: 'Docs',
          url: 'https://www.docs.flutter.dev/',
          createdAt: DateTime(2026),
          boardId: 'default',
        ),
      ],
    );
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
    expect(notes.boardNotes.any((n) => n.content == 'https://dart.dev'), true);
  });

  testWidgets('checklist keeps a typed-but-unsubmitted item on save', (
    tester,
  ) async {
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

  testWidgets('a print pinned on the wall shows its caption and actions', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      notes: [
        Note(
          guid: 'p',
          content: 'Beach day',
          type: NoteType.photo,
          imagePath: 'missing.jpg',
          createdAt: DateTime(2026),
          boardId: 'default',
        ),
      ],
    );
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

  testWidgets('a note with a photo can swap or drop it in the editor', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      notes: [
        Note(
          guid: 'n',
          content: 'One snap',
          imagePath: 'a.jpg',
          createdAt: DateTime(2026),
          boardId: 'default',
        ),
      ],
    );
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

  testWidgets('the rotate grip turns a wall note; a tap squares it up', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 't',
          content: 'Turn me',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.3,
        ),
      ],
    );
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
        pivot + Offset(radius * math.cos(a), radius * math.sin(a)),
      );
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
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 't',
          content: 'Snap me',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.3,
          rotation: 0.5,
        ),
      ],
    );
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
      pivot + Offset(radius * math.cos(a), radius * math.sin(a)),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(note.rotation, 0);
  });

  testWidgets('two fingers on a wall note twist it round', (tester) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 't',
          content: 'Twist me',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.3,
        ),
      ],
    );
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
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 't',
          content: 'Pinch me',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.3,
        ),
      ],
    );
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
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Plan A',
          createdAt: DateTime(2026),
          boardId: 'default',
        ),
      ],
    );
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

  testWidgets('a note can be parked out in the margin, but not off the wall', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Edge',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.5,
        ),
      ],
    );
    final a = notes.boardNotes.single;
    final wall = tester.getRect(find.byType(InteractiveViewer));
    final rangeX = wall.width - 168;

    // Past the right edge of the screen: the note goes out into the margin
    // (a fraction above 1) and stays there on release.
    await _dragNote(tester, find.text('Edge'), const Offset(380, 0));
    expect(a.x, closeTo(0.5 + 380 / rangeX, 1e-6));
    expect(a.x, greaterThan(1.0));
    // Back a little: it follows at once.
    await _dragNote(tester, find.text('Edge'), const Offset(-60, 0));
    expect(a.x, closeTo(0.5 + 320 / rangeX, 1e-6));

    // The margin has an end: a huge drag stops at the wall's outer edge.
    await _dragNote(tester, find.text('Edge'), const Offset(3000, 0));
    expect(a.x, closeTo(1 + WallView.pad / rangeX, 1e-6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('notes pan under the header and stay in view', (tester) async {
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Under',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.0,
        ),
      ],
    );
    final wall = tester.getRect(find.byType(InteractiveViewer));
    // The wall's box starts at the very top of the body, under the rows.
    expect(wall.top, lessThan(tester.getRect(find.text('Sticky Wall')).top));
    final before = tester.getRect(find.text('Under'));
    // Pan the wall up by most of the header: the note slides under the rows
    // and is still painted there.
    await tester.dragFrom(
      wall.center + const Offset(0, 120),
      const Offset(0, -(HomeScreen.wallHeaderHeight - 20)),
    );
    await tester.pumpAndSettle();
    final after = tester.getRect(find.text('Under'));
    expect(after.top, lessThan(before.top - 60));
    expect(after.top, lessThan(wall.top + HomeScreen.wallHeaderHeight));
    expect(find.text('Under').hitTestable(), findsOneWidget);
  });

  testWidgets('the toolbar has a pen on the wall that starts marker mode', (
    tester,
  ) async {
    await _pumpApp(tester, viewMode: ViewMode.wall);
    await tester.tap(find.byTooltip('Draw on the wall'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Done'), findsOneWidget);
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Done'), findsNothing);
  });

  testWidgets('the whole-wall export grows to cover notes out in the margin', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Home',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.2,
          y: 0.2,
        ),
        // A big print parked well outside the home area, and turned.
        Note(
          guid: 'b',
          content: 'Far',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 1.5,
          y: 1.3,
          scale: 2.2,
          rotation: 0.6,
        ),
      ],
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export board as image'));
    await tester.pumpAndSettle();
    final poster = find.byType(BoardPosterPage);
    final wallRect = tester.getRect(
      find.descendant(of: poster, matching: find.byType(WallBackground)),
    );
    for (final text in ['Home', 'Far']) {
      final card = tester.getRect(
        find.ancestor(
          of: find.descendant(of: poster, matching: find.text(text)),
          matching: find.byType(NoteTurn),
        ),
      );
      expect(wallRect.contains(card.topLeft), true, reason: '$text top-left');
      expect(
        wallRect.contains(card.bottomRight),
        true,
        reason: '$text bottom-right',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the export can be trimmed with the crop frame', (tester) async {
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.1,
          y: 0.1,
        ),
      ],
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export board as image'));
    await tester.pumpAndSettle();
    expect(find.byType(CropFrame), findsNothing);
    await tester.tap(find.byTooltip('Trim'));
    await tester.pumpAndSettle();
    final frame = find.byType(CropFrame);
    expect(frame, findsOneWidget);
    expect(
      find.text('Whole picture'),
      findsNothing,
      reason: 'nothing trimmed yet',
    );

    // Drag the bottom-right corner inwards by a quarter of the picture.
    final box = tester.getRect(frame);
    final g = await tester.startGesture(box.bottomRight - const Offset(2, 2));
    await g.moveBy(Offset(-box.width / 4, -box.height / 4));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    final crop = tester.widget<CropFrame>(frame).crop;
    expect(crop.right, closeTo(0.75, 0.02));
    expect(crop.bottom, closeTo(0.75, 0.02));
    expect(crop.left, 0);
    expect(find.text('Whole picture'), findsOneWidget);

    // Dragging inside moves the frame; the reset puts everything back.
    final g2 = await tester.startGesture(box.center - const Offset(60, 60));
    await g2.moveBy(Offset(box.width / 8, 0));
    await tester.pump();
    await g2.up();
    await tester.pumpAndSettle();
    expect(tester.widget<CropFrame>(frame).crop.left, closeTo(0.125, 0.02));
    await tester.tap(find.text('Whole picture'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CropFrame>(frame).crop,
      const Rect.fromLTWH(0, 0, 1, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawing on the wall can start from the grid', (tester) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.grid,
      notes: [
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
        ),
      ],
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draw on the wall'));
    await tester.pumpAndSettle();
    expect(notes.viewMode, ViewMode.wall);
    expect(find.byTooltip('Done'), findsOneWidget);
  });

  testWidgets('double-tapping a note zooms the wall onto it and back', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Focus me',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.3,
          y: 0.3,
        ),
      ],
    );
    final reset = find.byTooltip('Reset zoom');
    expect(reset, findsNothing, reason: 'camera at rest: no reset button');

    await tester.tap(find.text('Focus me'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('Focus me'));
    await tester.pumpAndSettle();
    expect(reset, findsOneWidget, reason: 'zoomed in');
    expect(find.byType(TextField), findsNothing, reason: 'no editor opened');

    await tester.tap(find.text('Focus me'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('Focus me'));
    await tester.pumpAndSettle();
    expect(reset, findsNothing, reason: 'back out');
  });

  testWidgets('a lasso drawn round notes in select mode picks them up', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.1,
          y: 0.1,
        ),
        Note(
          guid: 'b',
          content: 'Bb',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.6,
          y: 0.45,
        ),
      ],
    );
    await tester.longPress(find.text('Aa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select notes'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    // A loop just outside B's card, starting on bare wall.
    final box = tester
        .getRect(
          find.ancestor(of: find.text('Bb'), matching: find.byType(NoteTurn)),
        )
        .inflate(24);
    final g = await tester.startGesture(box.topLeft);
    for (final p in [
      box.topRight,
      box.bottomRight,
      box.bottomLeft,
      box.topLeft,
    ]) {
      await g.moveTo(p);
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging a selected note takes the whole selection along', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.1,
          y: 0.1,
        ),
        Note(
          guid: 'b',
          content: 'Bb',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.6,
          y: 0.6,
        ),
      ],
    );
    final a = notes.boardNotes[0];
    final b = notes.boardNotes[1];
    await tester.longPress(find.text('Aa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bb')); // adds B to the selection
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    final wall = tester.getRect(find.byType(InteractiveViewer));
    final rangeY =
        wall.height -
        HomeScreen.wallHeaderHeight -
        HomeScreen.wallFooterHeight -
        80;
    await _dragNote(tester, find.text('Aa'), const Offset(0, 50));
    expect(a.y, closeTo(0.1 + 50 / rangeY, 1e-6));
    expect(b.y, closeTo(0.6 + 50 / rangeY, 1e-6), reason: 'came along');
    expect(a.x, closeTo(0.1, 1e-9));
    expect(b.x, closeTo(0.6, 1e-9));
    // One Undo step puts both back.
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(a.y, 0.1);
    expect(b.y, 0.6);
  });

  testWidgets('dropping a dragged note on the tray deletes it', (tester) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Bin me',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.3,
        ),
      ],
    );
    final g = await tester.startGesture(tester.getCenter(find.text('Bin me')));
    await g.moveBy(const Offset(0, 40));
    await tester.pumpAndSettle(); // the tray slides in
    expect(find.text('Drop here to delete'), findsOneWidget);
    final tray = tester.getRect(find.text('Drop here to delete'));
    await g.moveTo(tray.center);
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(notes.boardNotes, isEmpty);
    expect(notes.trashCount, 1);
    expect(find.text('Moved to trash'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropping a dragged note on a board tab moves it there', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Tab me',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.3,
        ),
      ],
    );
    final work = notes.addBoard('Work');
    notes.selectBoard('default');
    await tester.pumpAndSettle();
    final note = notes.boardNotes.single;

    final g = await tester.startGesture(tester.getCenter(find.text('Tab me')));
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await g.moveTo(tester.getCenter(find.text('Work')));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(note.boardId, work.id);
    expect(notes.boardNotes, isEmpty);
    expect(find.textContaining('Moved to'), findsOneWidget);
    // Undo (the pill, not the snackbar's) brings it back to this board.
    await tester.tap(find.text('Undo').last);
    await tester.pumpAndSettle();
    expect(note.boardId, 'default');
  });

  testWidgets('long-pressing the add button offers the note types', (
    tester,
  ) async {
    await _pumpApp(tester, viewMode: ViewMode.wall);
    await tester.longPress(find.byType(AddNoteButton));
    await tester.pumpAndSettle();
    for (final label in ['Text', 'Link', 'To-do list', 'Drawing', 'Photo']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Drawing'));
    await tester.pumpAndSettle();
    expect(find.byType(DrawingEditor), findsOneWidget);
  });

  testWidgets('the Undo pill puts a moved note back', (tester) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Oops',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.3,
        ),
      ],
    );
    final note = notes.boardNotes.single;
    double pillOpacity() => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.text('Undo'),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;
    expect(pillOpacity(), 0, reason: 'nothing to undo yet');
    await _dragNote(tester, find.text('Oops'), const Offset(0, 100));
    expect(note.y, isNot(0.3));
    expect(pillOpacity(), 1);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(note.y, 0.3);
    expect(pillOpacity(), 0, reason: 'nothing left to undo: the pill is gone');
    // Left alone, the pill also times out.
    await _dragNote(tester, find.text('Oops'), const Offset(0, 100));
    expect(pillOpacity(), 1);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(pillOpacity(), 0);
  });

  testWidgets('a locked note stays put, and a tidy flows the rest beneath it', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'h',
          content: 'This week',
          type: NoteType.label,
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.05,
          y: 0.02,
          locked: true,
        ),
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.5,
          y: 0.5,
        ),
        Note(
          guid: 'b',
          content: 'Bb',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.7,
          y: 0.8,
        ),
      ],
    );
    final head = notes.boardNotes[0];
    await _dragNote(tester, find.text('This week'), const Offset(60, 120));
    expect(head.x, 0.05, reason: 'locked: the drag does nothing');
    expect(head.y, 0.02);
    expect(find.byIcon(Icons.lock), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidy up'));
    await tester.pumpAndSettle();
    expect(head.x, 0.05, reason: 'tidy leaves it where it is');
    expect(head.y, 0.02);
    final wall = tester.getRect(find.byType(InteractiveViewer));
    final rangeY =
        wall.height -
        HomeScreen.wallHeaderHeight -
        HomeScreen.wallFooterHeight -
        80;
    final headBottom =
        tester
            .getRect(
              find.ancestor(
                of: find.text('This week'),
                matching: find.byType(NoteTurn),
              ),
            )
            .bottom -
        wall.top;
    for (final n in notes.boardNotes.skip(1)) {
      expect(
        n.y * rangeY + HomeScreen.wallHeaderHeight,
        greaterThan(headBottom - 1),
        reason: 'rows start under the heading',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap on a thread opens its sheet: arrow, label, cut, undo', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.1,
          y: 0.1,
        ),
        Note(
          guid: 'b',
          content: 'Bb',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.7,
          y: 0.7,
        ),
      ],
    );
    notes.connect('a', 'b');
    await tester.pumpAndSettle();

    Rect card(String text) => tester.getRect(
      find.ancestor(of: find.text(text), matching: find.byType(NoteTurn)),
    );
    // Pins sit 14px under the top edge, centred; the yarn sags between them.
    final pa = card('Aa').topCenter + const Offset(0, 14);
    final pb = card('Bb').topCenter + const Offset(0, 14);
    final sag = math.min(30.0, (pa - pb).distance * 0.12);
    await tester.tapAt((pa + pb) / 2 + Offset(0, sag / 2));
    await tester.pumpAndSettle();
    expect(find.text('Thread'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(notes.links.single.arrow, true);
    await tester.enterText(find.byType(TextField), 'blocks');
    await tester.pumpAndSettle();
    expect(notes.links.single.label, 'blocks');

    await tester.tap(find.text('Cut thread'));
    await tester.pumpAndSettle();
    expect(notes.links, isEmpty);
    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await tester.pumpAndSettle();
    expect(notes.links.single.label, 'blocks', reason: 'tied back as it was');
    expect(tester.takeException(), isNull);
  });

  testWidgets('marker mode draws on the wall; undo, clear and done work', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.1,
          y: 0.1,
        ),
      ],
    );
    final note = notes.boardNotes.single;
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draw on the wall'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Done'), findsOneWidget);
    expect(find.byType(AddNoteButton), findsNothing);

    // A line across bare wall.
    final g = await tester.startGesture(const Offset(300, 400));
    await g.moveBy(const Offset(120, 40));
    await tester.pump();
    await g.moveBy(const Offset(80, -30));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(notes.currentBoard.strokes.length, 1);
    expect(notes.currentBoard.strokes.single.points.length, 3);

    // A line over a note draws too — the note is left alone.
    final g2 = await tester.startGesture(tester.getCenter(find.text('Aa')));
    await g2.moveBy(const Offset(90, 0));
    await tester.pump();
    await g2.up();
    await tester.pumpAndSettle();
    expect(notes.currentBoard.strokes.length, 2);
    expect(note.x, 0.1);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(notes.currentBoard.strokes.length, 1);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(notes.currentBoard.strokes, isEmpty);
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(notes.currentBoard.strokes.length, 1, reason: 'clear undone');

    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Done'), findsNothing);
    expect(find.byType(AddNoteButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the marker bar fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await _pumpApp(tester, viewMode: ViewMode.wall);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draw on the wall'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Done'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow');
  });

  testWidgets('a label is written on tape and locked from the sheet', (
    tester,
  ) async {
    final notes = await _pumpApp(tester, viewMode: ViewMode.wall);
    await tester.longPress(find.byType(AddNoteButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Label'));
    await tester.pumpAndSettle();
    expect(find.text('Column or section name…'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Backlog');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    final label = notes.boardNotes.single;
    expect(label.type, NoteType.label);
    expect(find.text('Backlog'), findsOneWidget);

    await tester.longPress(find.text('Backlog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lock in place'));
    await tester.pumpAndSettle();
    expect(label.locked, true);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('the format buttons mark the text and the card renders it', (
    tester,
  ) async {
    final notes = await _pumpApp(tester);
    await _openEditor(tester);
    await tester.enterText(find.byType(TextField).first, 'milk');
    final field = tester.widget<TextField>(find.byType(TextField).first);
    field.controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 4,
    );
    await tester.tap(find.byTooltip('Bold'));
    await tester.pump();
    expect(field.controller!.text, '**milk**');
    // Bullets go on every line the selection touches; again takes them off.
    field.controller!.value = const TextEditingValue(
      text: 'one\ntwo',
      selection: TextSelection(baseOffset: 0, extentOffset: 7),
    );
    await tester.tap(find.byTooltip('Bullet list'));
    await tester.pump();
    expect(field.controller!.text, '- one\n- two');
    await tester.tap(find.byTooltip('Bullet list'));
    await tester.pump();
    expect(field.controller!.text, 'one\ntwo');

    field.controller!.text = 'Buy **milk**';
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(notes.boardNotes.single.content, 'Buy **milk**');
    final rich = tester
        .widgetList<Text>(find.byType(Text))
        .firstWhere((t) => t.textSpan?.toPlainText() == 'Buy milk');
    final bold = (rich.textSpan as TextSpan).children!
        .cast<TextSpan>()
        .firstWhere((s) => s.text == 'milk');
    expect(bold.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('the export offers the part in view, the selection and a size', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.1,
          y: 0.1,
        ),
        Note(
          guid: 'b',
          content: 'Bb',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.6,
          y: 0.5,
        ),
      ],
    );
    // Zoom in on A (so there is a "part in view") and select A.
    await tester.tap(find.text('Aa'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('Aa'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Aa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select notes'));
    await tester.pumpAndSettle();
    expect(notes.boardNotes.length, 2);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export board as image'));
    await tester.pumpAndSettle();
    expect(find.byType(BoardPosterPage), findsOneWidget);
    expect(find.text('Part in view'), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('3×'), findsOneWidget);
    // The selection is preselected: only A is on the poster.
    expect(find.text('Aa'), findsOneWidget);
    expect(find.text('Bb'), findsNothing);
    await tester.tap(find.text('All notes'));
    await tester.pumpAndSettle();
    expect(find.text('Bb'), findsOneWidget);
    await tester.tap(find.text('Part in view'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4×'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('Share as PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a note can be duplicated or copied to another board from its sheet',
    (tester) async {
      final notes = await _pumpApp(
        tester,
        viewMode: ViewMode.wall,
        notes: [
          Note(
            guid: 'a',
            content: 'Twin',
            createdAt: DateTime(2026),
            boardId: 'default',
            x: 0.2,
            y: 0.2,
          ),
        ],
      );
      final work = notes.addBoard('Work');
      notes.selectBoard('default');
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Twin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(notes.boardNotes.length, 2);
      expect(find.text('Twin'), findsNWidgets(2));

      // The copy sits on top of the original, a touch down and to the right.
      await tester.longPress(find.text('Twin').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to another board'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(ListTile), matching: find.text('Work')),
      );
      await tester.pumpAndSettle();
      expect(notes.boardNotes.length, 2, reason: 'still both here');
      expect(find.textContaining('Copied 1 note'), findsOneWidget);
      notes.selectBoard(work.id);
      await tester.pumpAndSettle();
      expect(notes.boardNotes.single.content, 'Twin');
    },
  );

  testWidgets('notes hold still when the marker or selection bar appears', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Still',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.3,
          y: 0.6,
        ),
        Note(
          guid: 'b',
          content: 'Other',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.7,
          y: 0.2,
        ),
      ],
    );
    final before = tester.getRect(find.text('Still'));
    final otherBefore = tester.getRect(find.text('Other'));

    await tester.tap(find.byTooltip('Draw on the wall'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Done'), findsOneWidget);
    expect(tester.getRect(find.text('Still')), before, reason: 'marker bar');
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Still'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select notes'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    // The selected card lifts a touch on purpose; its neighbour must not move.
    expect(
      tester.getRect(find.text('Other')),
      otherBefore,
      reason: 'select bar',
    );
  });

  testWidgets('board tabs own the top row; tools sit in a pill at the bottom', (
    tester,
  ) async {
    final notes = await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Aa',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.2,
          y: 0.2,
        ),
      ],
    );
    notes.addBoard('Work');
    notes.addBoard('Home');
    notes.selectBoard('default');
    await tester.pumpAndSettle();

    final screen = tester.getRect(find.byType(Scaffold));
    final tabs = tester.getRect(find.byType(BoardBar));
    expect(tabs.right, greaterThan(screen.right - 16), reason: 'full width');
    expect(tabs.top, lessThan(HomeScreen.wallHeaderHeight));

    final more = tester.getRect(find.byIcon(Icons.more_vert));
    final pen = tester.getRect(find.byIcon(Icons.gesture));
    expect(more.bottom, greaterThan(screen.bottom - 80), reason: 'at bottom');
    expect(pen.center.dy, closeTo(more.center.dy, 1), reason: 'same pill');
    expect(more.top, greaterThan(tabs.bottom), reason: 'not in the header');

    // Grid and list keep the pill too, with sort in place of the pen.
    notes.viewMode = ViewMode.grid;
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.gesture), findsNothing);
    expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    expect(
      tester.getRect(find.byIcon(Icons.more_vert)).bottom,
      greaterThan(screen.bottom - 80),
    );
  });

  testWidgets('the camera button hides at rest, offers fit, then reset', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Near',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.2,
          y: 0.2,
        ),
      ],
    );
    // Everything in view, camera at rest: nothing to offer.
    expect(find.byTooltip('Show everything'), findsNothing);
    expect(find.byTooltip('Reset zoom'), findsNothing);

    // Pan the wall until the note leaves the screen: "show everything".
    final wall = tester.getRect(find.byType(InteractiveViewer));
    final g = await tester.startGesture(wall.center + const Offset(0, 200));
    await g.moveBy(const Offset(-300, 0));
    await tester.pump();
    await g.moveBy(const Offset(-300, 0));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show everything'), findsOneWidget);
    expect(find.byTooltip('Reset zoom'), findsNothing);

    // Fit: the only note sits inside the home area, so "everything" is the
    // resting view itself — the camera glides home and the button goes.
    await tester.tap(find.byTooltip('Show everything'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Reset zoom'), findsNothing);
    expect(find.byTooltip('Show everything'), findsNothing);
  });

  testWidgets('the show-everything button frames notes out in the margin', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      viewMode: ViewMode.wall,
      notes: [
        Note(
          guid: 'a',
          content: 'Near',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 0.2,
          y: 0.2,
        ),
        Note(
          guid: 'b',
          content: 'Far',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: 1.6,
          y: 0.5,
        ),
      ],
    );
    final wall = tester.getRect(find.byType(InteractiveViewer));
    // Off to the right, past the screen.
    expect(tester.getRect(find.text('Far')).left, greaterThan(wall.right));
    await tester.tap(find.byTooltip('Show everything'));
    await tester.pumpAndSettle();
    final far = tester.getRect(find.text('Far'));
    final near = tester.getRect(find.text('Near'));
    expect(far.right, lessThan(wall.right));
    expect(near.left, greaterThan(wall.left));
    expect(find.byTooltip('Reset zoom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the gesture tips are offered once and stay in the menu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.setViewMode(ViewMode.wall);
    await storage.setTipsPending(true);
    final settings = SettingsController(storage);
    await tester.pumpWidget(
      StickyWallApp(
        settings: settings,
        notes: NotesController(storage, ReminderService()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gesture tips'), findsOneWidget);
    expect(find.text('Pins and threads'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Pins and threads'), findsNothing);
    expect(storage.tipsPending, false);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gesture tips'));
    await tester.pumpAndSettle();
    expect(find.text('Pins and threads'), findsOneWidget);
  });

  testWidgets('long-pressing empty wall offers a note or photos there', (
    tester,
  ) async {
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

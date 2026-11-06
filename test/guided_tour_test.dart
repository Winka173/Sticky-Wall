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
import 'package:sticky_wall/widgets/guided_tour.dart';

/// The interactive guide runs on the real wall, moves on when the gesture
/// is done (or with Next), and never changes anything by itself.
/// More → Settings → Help → Interactive guide.
Future<void> openGuide(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Interactive guide'), 200);
  await tester.tap(find.text('Interactive guide'));
  await tester.pumpAndSettle();
}

void main() {
  Future<NotesController> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveNotes([
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
    ]);
    await storage.setViewMode(ViewMode.wall);
    final notes = NotesController(storage, ReminderService());
    await tester.pumpWidget(
      StickyWallApp(settings: SettingsController(storage), notes: notes),
    );
    await tester.pumpAndSettle();
    return notes;
  }

  testWidgets('replayed from the menu: tap, drag, thread, then a first '
      'note', (tester) async {
    final notes = await pump(tester);
    final before = notes.allNotes.map((n) => n.toJson().toString()).toList();

    await openGuide(tester);
    expect(find.byType(GuidedTourCard), findsOneWidget);
    expect(find.text('Tap a note to write on it'), findsOneWidget);
    expect(
      notes.allNotes.map((n) => n.toJson().toString()).toList(),
      before,
      reason: 'starting the guide changes nothing',
    );

    // Doing it moves the guide on: opening a note.
    await tester.tap(find.text('Aa'));
    // A single tap waits out the double-tap window first.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Drag a note to move it'), findsOneWidget);

    // Dragging one.
    final g = await tester.startGesture(tester.getCenter(find.text('Bb')));
    await g.moveBy(const Offset(-60, 40));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(find.text('Tie two notes together'), findsOneWidget);

    // Next is always there instead of the gesture.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text("That's the wall"), findsOneWidget);
    expect(notes.links, isEmpty);

    await tester.tap(find.text('Write my first note'));
    await tester.pumpAndSettle();
    expect(find.byType(GuidedTourCard), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget, reason: 'editor open');
  });

  testWidgets('Skip ends the guide at once', (tester) async {
    await pump(tester);
    await openGuide(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(GuidedTourCard), findsNothing);
  });
}

// The wall must not budge while a dialog opens above it. Android reports no
// bottom padding while the keyboard is up (it covers the navigation bar), so
// a naive SafeArea grows by the bar's height and every note below the top
// row slides down with the fractional coordinates.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/add_note_button.dart';
import 'package:sticky_wall/widgets/board_bar.dart';
import 'package:sticky_wall/widgets/wall_view.dart';

DateTime _t(int d) => DateTime(2026, 8, d, 9);

Future<StickyWallApp> _app() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([Board(id: 'default', name: '', wallIndex: 0)]);
  // Two rows: the second one is where a height change would show.
  await storage.saveNotes([
    Note(guid: 'a', content: 'one', boardId: 'default', createdAt: _t(1)),
    Note(guid: 'b', content: 'two', boardId: 'default', createdAt: _t(2), x: 0.5),
    Note(guid: 'c', content: 'three', boardId: 'default', createdAt: _t(3), y: 0.5),
    Note(guid: 'd', content: 'four', boardId: 'default', createdAt: _t(4), x: 0.5, y: 0.5),
  ]);
  await storage.setViewMode(ViewMode.wall);
  await storage.setLanguageCode('vi');
  return StickyWallApp(
    settings: SettingsController(storage),
    notes: NotesController(storage, ReminderService()),
  );
}

/// A phone with a 48 dp gesture bar at the bottom.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 2.75;
  tester.view.padding = const FakeViewPadding(top: 66, bottom: 132);
  tester.view.viewPadding = const FakeViewPadding(top: 66, bottom: 132);
  addTearDown(tester.view.reset);
}

/// What Android reports once the keyboard slides over the gesture bar.
Future<void> _showKeyboard(WidgetTester tester) async {
  tester.view.viewInsets = const FakeViewPadding(bottom: 800);
  tester.view.padding = const FakeViewPadding(top: 66, bottom: 0);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wall holds still while the note editor and keyboard open',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    final wall0 = tester.getRect(find.byType(WallView));
    final card0 = tester.getRect(find.text('three'));

    await tester.tap(find.byType(AddNoteButton));
    await tester.pumpAndSettle();
    await _showKeyboard(tester);

    expect(tester.getRect(find.byType(WallView)), wall0);
    expect(tester.getRect(find.text('three')), card0);
  });

  testWidgets('wall holds still while the new-board dialog and keyboard open',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    final wall0 = tester.getRect(find.byType(WallView));
    final card0 = tester.getRect(find.text('three'));

    await tester.tap(find.descendant(
        of: find.byType(BoardBar), matching: find.byIcon(Icons.add)));
    await tester.pumpAndSettle();
    expect(find.text('Tường mới'), findsOneWidget);
    await _showKeyboard(tester);

    expect(tester.getRect(find.byType(WallView)), wall0);
    expect(tester.getRect(find.text('three')), card0);
  });
}

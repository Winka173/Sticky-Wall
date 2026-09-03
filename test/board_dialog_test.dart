import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/board_bar.dart';

Future<(StickyWallApp, NotesController)> _app() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([Board(id: 'default', name: '', wallIndex: 0)]);
  await storage.saveNotes([]);
  await storage.setViewMode(ViewMode.grid);
  await storage.setLanguageCode('vi');
  final notes = NotesController(storage, ReminderService());
  return (
    StickyWallApp(settings: SettingsController(storage), notes: notes),
    notes,
  );
}

/// The style the board bar draws [label] with.
TextStyle _chipStyle(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

/// The "+" at the end of the board strip (the empty wall has one too).
final _addBoard = find.descendant(
  of: find.byType(BoardBar),
  matching: find.byIcon(Icons.add),
);

Future<void> _openNewBoard(WidgetTester tester) async {
  await tester.tap(_addBoard);
  await tester.pumpAndSettle();
}

/// Scrolls a board tab into the strip, then taps it.
Future<void> _tapTab(WidgetTester tester, String label) async {
  final tab = find.text(label, skipOffstage: false);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  test('board formatting survives a JSON round trip', () {
    final board = Board(
      id: 'b',
      name: 'Work',
      icon: '💼',
      bold: true,
      italic: false,
      underline: true,
    );
    final copy = Board.fromJson(board.toJson());
    expect(copy.icon, '💼');
    expect(copy.bold, isTrue);
    expect(copy.italic, isFalse);
    expect(copy.underline, isTrue);

    // Older saves without the flags load as plain text.
    final legacy = Board.fromJson({'id': 'x', 'name': 'Old'});
    expect(legacy.bold || legacy.italic || legacy.underline, isFalse);
    final style = copy.decorate(const TextStyle(fontSize: 16));
    expect(style.fontWeight, FontWeight.bold);
    expect(style.fontStyle, isNull);
    expect(style.decoration, TextDecoration.underline);
    expect(style.fontSize, 16);
  });

  testWidgets('new board dialog takes a name, icon and formatting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final (app, notes) = await _app();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await _openNewBoard(tester);
    expect(find.text('Tường mới'), findsOneWidget);

    // Nothing to save yet.
    final save = find.widgetWithText(FilledButton, 'Lưu');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField), ' Công việc ');
    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.tap(find.byIcon(Icons.format_italic));
    await tester.pump();
    // The field previews the formatting as it is toggled.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.fontWeight, FontWeight.bold);
    expect(field.style?.fontStyle, FontStyle.italic);

    await tester.tap(find.text('💼'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final board = notes.boards.last;
    expect(board.name, 'Công việc');
    expect(board.icon, '💼');
    expect(board.bold, isTrue);
    expect(board.italic, isTrue);
    expect(board.underline, isFalse);
    expect(notes.currentBoardId, board.id);

    // The tab is drawn in that formatting.
    await tester.ensureVisible(find.text('Công việc', skipOffstage: false));
    await tester.pumpAndSettle();
    final style = _chipStyle(tester, 'Công việc');
    expect(style.fontWeight, FontWeight.bold);
    expect(style.fontStyle, FontStyle.italic);
    expect(style.decoration, isNull);
  });

  testWidgets('the selected tab is scrolled into view, and stays there', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final (app, notes) = await _app();
    // Short names: the test font is wide, and a chip has to be narrower than
    // the strip before it can be fully in view at all.
    for (final name in ['Việc', 'Học', 'Nhà', 'Đi']) {
      notes.addBoard(name);
    }
    notes
      ..selectBoard('default')
      ..viewMode = ViewMode.wall;
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // The strip is wider than the screen; the last tab is off the end.
    Rect strip() => tester.getRect(find.byType(ReorderableListView));
    bool inStrip(String label) {
      final tab = find.text(label);
      if (tab.evaluate().isEmpty) return false;
      final rect = tester.getRect(tab);
      return rect.left >= strip().left && rect.right <= strip().right;
    }

    expect(inStrip('Đi'), isFalse);

    // Selecting it brings it fully into view without scrolling by hand…
    notes.selectBoard(notes.boards.last.id);
    await tester.pumpAndSettle();
    expect(inStrip('Đi'), isTrue);

    // …and it stays in view when the toolbar grows a sort button (grid)
    // and narrows the strip.
    notes.viewMode = ViewMode.grid;
    await tester.pumpAndSettle();
    expect(inStrip('Đi'), isTrue);
  });

  testWidgets('editing a board pre-fills the dialog and keeps changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final (app, notes) = await _app();
    notes.addBoard('Học', icon: '📚', bold: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Tapping the selected tab opens the manage sheet.
    await _tapTab(tester, 'Học');
    await tester.tap(find.text('Chỉnh sửa tường'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa tường'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Học',
    );
    // Bold came in switched on; add underline, drop the icon.
    await tester.tap(find.byIcon(Icons.format_underlined));
    await tester.tap(find.text('Không có'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    final board = notes.boards.last;
    expect(board.name, 'Học');
    expect(board.icon, '');
    expect(board.bold, isTrue);
    expect(board.underline, isTrue);
    await tester.ensureVisible(find.text('Học', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(_chipStyle(tester, 'Học').decoration, TextDecoration.underline);
  });
}

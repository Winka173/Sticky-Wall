import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/board_bar.dart';
import 'package:sticky_wall/widgets/board_sidebar.dart';
import 'package:sticky_wall/widgets/wall_view.dart';

Future<(StickyWallApp, NotesController, SettingsController)> _app(
  int boards,
) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([
    for (var i = 0; i < boards; i++)
      Board(id: 'b$i', name: 'Room ${i + 1}', wallIndex: 0),
  ]);
  await storage.saveNotes([]);
  await storage.setViewMode(ViewMode.wall);
  await storage.setLanguageCode('en');
  final notes = NotesController(storage, ReminderService());
  final settings = SettingsController(storage);
  return (StickyWallApp(settings: settings, notes: notes), notes, settings);
}

void _window(WidgetTester tester, Size dp) {
  tester.view.physicalSize = dp * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

final _panel = find.byKey(const Key('board-panel'));
final _toggle = find.byKey(const Key('board-panel-toggle'));

void main() {
  testWidgets('a wide window keeps the strip; the list opens on demand', (
    tester,
  ) async {
    _window(tester, const Size(1280, 800));
    final (app, _, settings) = await _app(3);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Closed at first: the strip, with the list's button leading it.
    expect(find.byType(BoardBar), findsOneWidget);
    expect(_panel, findsNothing);
    expect(_toggle, findsOneWidget);

    final wallBefore = tester.getRect(find.byType(WallView));
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(_panel, findsOneWidget);
    expect(settings.boardPanel, isTrue);
    expect(find.text('Boards'), findsOneWidget);
    // It floats: the wall keeps its size and place.
    expect(tester.getRect(find.byType(WallView)), wallBefore);
    // As tall as its three boards, not the whole height of the window.
    expect(tester.getSize(_panel).height, lessThan(320));

    // Its ✕ closes it; so would the strip's button.
    await tester.tap(find.byTooltip('Hide board list').last);
    await tester.pumpAndSettle();
    expect(_panel, findsNothing);
    expect(settings.boardPanel, isFalse);
  });

  testWidgets('the list switches boards and opens the same sheets', (
    tester,
  ) async {
    _window(tester, const Size(1280, 800));
    final (app, notes, settings) = await _app(3);
    settings.setBoardPanel(true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    final inPanel = find.descendant(of: _panel, matching: find.text('Room 2'));

    await tester.tap(inPanel);
    await tester.pumpAndSettle();
    expect(notes.currentBoardId, 'b1');
    expect(_panel, findsOneWidget, reason: 'stays open while switching');

    // The open board's row opens its manage sheet.
    await tester.tap(inPanel);
    await tester.pumpAndSettle();
    expect(find.text('Edit board'), findsOneWidget);
    await tester.tapAt(const Offset(1100, 40));
    await tester.pumpAndSettle();

    // "New board" offers a blank board or a template.
    await tester.tap(
      find.descendant(of: _panel, matching: find.text('New board')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Blank board'), findsOneWidget);
    await tester.tapAt(const Offset(1100, 40));
    await tester.pumpAndSettle();

    // The grid button is the picker with a picture of each board.
    await tester.tap(
      find.descendant(of: _panel, matching: find.byTooltip('All boards')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Key('board-pin-${notes.boards.first.id}')), findsOne);
  });

  testWidgets('a phone has no list button', (tester) async {
    _window(tester, const Size(400, 860));
    final (app, _, settings) = await _app(3);
    // Opened on a tablet earlier: a phone still shows just the strip.
    settings.setBoardPanel(true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(_toggle, findsNothing);
    expect(_panel, findsNothing);
  });

  testWidgets('every row but the open one can be measured for a drop', (
    tester,
  ) async {
    _window(tester, const Size(1280, 800));
    final (_, notes, _) = await _app(4);
    final keys = {for (final b in notes.boards) b.id: GlobalKey()};
    final hover = ValueNotifier<String?>(null);
    addTearDown(hover.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: BoardSidebar(
              notes: notes,
              dark: false,
              onClose: () {},
              chipKeys: keys,
              dropTarget: hover,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final b in notes.boards) {
      final box = keys[b.id]!.currentContext!.findRenderObject()! as RenderBox;
      expect(box.hasSize, isTrue, reason: b.name);
    }

    // A note hovering over a row lights it up in the gold of a drop target.
    hover.value = 'b2';
    await tester.pumpAndSettle();
    final row = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Room 3'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect((row.decoration! as BoxDecoration).color, const Color(0xFFFFCA28));
  });

  testWidgets('with the list open, its rows are the drop targets', (
    tester,
  ) async {
    _window(tester, const Size(1280, 800));
    final (app, notes, settings) = await _app(6);
    settings.setBoardPanel(true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    // No duplicate keys between tabs and rows (that would have thrown), and
    // a board missing from the collapsed strip is still in the list.
    expect(tester.takeException(), isNull);
    for (final b in notes.boards) {
      expect(
        find.descendant(of: _panel, matching: find.text(b.name)),
        findsOneWidget,
      );
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/widgets/board_bar.dart';

Future<NotesController> _notes(int boards, {Set<int> pinned = const {}}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([
    for (var i = 0; i < boards; i++)
      Board(
        id: 'b$i',
        name: 'B${i + 1}',
        wallIndex: 0,
        favorite: pinned.contains(i),
      ),
  ]);
  await storage.saveNotes([]);
  return NotesController(storage, ReminderService());
}

Future<void> _pump(
  WidgetTester tester,
  NotesController notes, {
  ValueNotifier<bool>? dragging,
  Map<String, GlobalKey>? chipKeys,
  bool highContrast = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(392, 808),
        highContrast: highContrast,
      ),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 48,
                child: BoardBar(
                  notes: notes,
                  dragging: dragging,
                  chipKeys: chipKeys,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _inStrip = find.byType(BoardBar);

void main() {
  testWidgets('a few boards are all tabs, with the picker button', (
    tester,
  ) async {
    final notes = await _notes(4);
    await _pump(tester, notes);
    for (var i = 1; i <= 4; i++) {
      expect(find.text('B$i'), findsOneWidget);
    }
    expect(find.byIcon(Icons.apps), findsOneWidget);
    expect(find.text('All 4'), findsNothing);
  });

  testWidgets(
    'from five boards the strip keeps the open one and the most used',
    (tester) async {
      // Board 5 is pinned, board 4 open; the rest have never been edited.
      final notes = await _notes(6, pinned: {4});
      notes.selectBoard('b3');
      await _pump(tester, notes);
      // The open board, the pinned one and one more, in the boards' own order.
      final tabs = [
        for (var i = 1; i <= 6; i++)
          if (find.text('B$i').evaluate().isNotEmpty) i,
      ];
      expect(tabs.length, BoardBar.collapsedTabs);
      expect(tabs, containsAll([4, 5]));
      expect(tabs, orderedEquals([...tabs]..sort()));
      // One "All 6" tab opens the picker; the separate button is gone.
      expect(find.text('All 6'), findsOneWidget);
      expect(find.byIcon(Icons.apps), findsOneWidget);
      await tester.tap(find.text('All 6'));
      await tester.pumpAndSettle();
      expect(find.text('All boards'), findsOneWidget);
    },
  );

  testWidgets('picking another board from the strip moves the open tab', (
    tester,
  ) async {
    final notes = await _notes(6);
    await _pump(tester, notes);
    expect(notes.currentBoardId, 'b0');
    final other = [
      for (var i = 2; i <= 6; i++)
        if (find.text('B$i').evaluate().isNotEmpty) i,
    ].first;
    await tester.tap(find.text('B$other'));
    await tester.pumpAndSettle();
    expect(notes.currentBoardId, 'b${other - 1}');
  });

  testWidgets('dragging a note opens a tray holding every other board', (
    tester,
  ) async {
    final notes = await _notes(7);
    final keys = {for (final b in notes.boards) b.id: GlobalKey()};
    final dragging = ValueNotifier<bool>(false);
    addTearDown(dragging.dispose);
    await _pump(tester, notes, dragging: dragging, chipKeys: keys);
    expect(find.byKey(const Key('board-drop-tray')), findsNothing);

    dragging.value = true;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('board-drop-tray')), findsOneWidget);
    // Each board but the open one has exactly one measurable chip, so a drop
    // can find it.
    for (final b in notes.boards) {
      final attached = keys[b.id]!.currentContext != null;
      expect(attached, b.id != notes.currentBoardId, reason: b.name);
    }

    dragging.value = false;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('board-drop-tray')), findsNothing);
  });

  testWidgets('with few boards a drag opens no tray', (tester) async {
    final notes = await _notes(3);
    final dragging = ValueNotifier<bool>(true);
    addTearDown(dragging.dispose);
    await _pump(tester, notes, dragging: dragging);
    expect(find.byKey(const Key('board-drop-tray')), findsNothing);
  });

  testWidgets('the open tab is solid chalk, the others a scrim', (
    tester,
  ) async {
    final notes = await _notes(3);
    await _pump(tester, notes);
    Color? fillOf(String label) {
      final box = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (box.decoration! as BoxDecoration).color;
    }

    expect(fillOf('B1'), const Color(0xFFFDFBF3));
    expect(fillOf('B2'), const Color(0x991E160E));
    expect(_inStrip, findsOneWidget);
  });

  testWidgets('high contrast makes the scrim solid', (tester) async {
    final notes = await _notes(3);
    await _pump(tester, notes, highContrast: true);
    final box = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('B2'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect((box.decoration! as BoxDecoration).color!.a, 1.0);
  });
}

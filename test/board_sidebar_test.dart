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

Future<(StickyWallApp, NotesController)> _app(int boards) async {
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
  return (
    StickyWallApp(settings: SettingsController(storage), notes: notes),
    notes,
  );
}

void _window(WidgetTester tester, Size dp) {
  tester.view.physicalSize = dp * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a wide window lists the boards down the left, no strip', (
    tester,
  ) async {
    _window(tester, const Size(1280, 800));
    final (app, notes) = await _app(3);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byType(BoardSidebar), findsOneWidget);
    expect(find.byType(BoardBar), findsNothing);
    for (var i = 1; i <= 3; i++) {
      expect(find.text('Room $i'), findsOneWidget);
    }
    expect(find.text('Boards'), findsOneWidget);

    await tester.tap(find.text('Room 2'));
    await tester.pumpAndSettle();
    expect(notes.currentBoardId, 'b1');
  });

  testWidgets('the list opens the same sheets as the strip', (tester) async {
    _window(tester, const Size(1280, 800));
    final (app, notes) = await _app(3);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // The open board's row opens its manage sheet.
    await tester.tap(find.text('Room 1'));
    await tester.pumpAndSettle();
    expect(find.text('Edit board'), findsOneWidget);
    await tester.tapAt(const Offset(1100, 40));
    await tester.pumpAndSettle();

    // "New board" offers a blank board or a template.
    await tester.tap(find.text('New board'));
    await tester.pumpAndSettle();
    expect(find.text('Blank board'), findsOneWidget);
    await tester.tapAt(const Offset(1100, 40));
    await tester.pumpAndSettle();

    // "All boards" is the picker with a picture of each.
    await tester.tap(find.text('All boards'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('board-pin-${notes.boards.first.id}')),
      findsOneWidget,
    );
  });

  testWidgets('a phone-sized window keeps the strip', (tester) async {
    _window(tester, const Size(400, 860));
    final (app, _) = await _app(3);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.byType(BoardSidebar), findsNothing);
    expect(find.byType(BoardBar), findsOneWidget);
  });

  testWidgets('a mid-sized window (960 dp) keeps the strip too', (
    tester,
  ) async {
    _window(tester, const Size(960, 600));
    final (app, _) = await _app(3);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.byType(BoardSidebar), findsNothing);
    expect(find.byType(BoardBar), findsOneWidget);
  });

  testWidgets('every row but the open one can be measured for a drop', (
    tester,
  ) async {
    _window(tester, const Size(1280, 800));
    final (_, notes) = await _app(4);
    final keys = {for (final b in notes.boards) b.id: GlobalKey()};
    final hover = ValueNotifier<String?>(null);
    addTearDown(hover.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Row(
            children: [
              BoardSidebar(
                notes: notes,
                dark: false,
                chipKeys: keys,
                dropTarget: hover,
              ),
            ],
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
}

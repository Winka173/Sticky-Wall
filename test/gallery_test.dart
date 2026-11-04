import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/screens/gallery_screen.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/pro_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/share_service.dart';
import 'package:sticky_wall/services/template_library.dart';
import 'package:sticky_wall/widgets/board_bar.dart';

/// Hands shares to the test instead of the platform.
class _FakeShares extends ShareReceiver {
  void Function(SharedContent content)? deliver;

  @override
  void listen(void Function(SharedContent content) onShared) =>
      deliver = onShared;

  @override
  void dispose() {}
}

Future<NotesController> _pumpApp(
  WidgetTester tester, {
  bool pro = false,
  bool welcome = false,
  ShareReceiver? shares,
}) async {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([Board(id: 'default', name: '')]);
  await storage.saveNotes([
    Note(
      guid: 'mine',
      content: 'My own words',
      createdAt: DateTime(2026),
      boardId: 'default',
      colorIndex: 2,
      x: 0.3,
      y: 0.4,
      // On a fresh install the wall holds the first-run examples.
      sample: welcome,
    ),
  ]);
  await storage.setViewMode(ViewMode.wall);
  if (welcome) await storage.setWelcomePending(true);
  final notes = NotesController(storage, ReminderService());
  final proC = ProController(storage);
  if (pro) proC.unlockForTesting();
  // The library is read once, outside the fake clock.
  await tester.runAsync(TemplateLibrary.load);
  await tester.pumpWidget(
    StickyWallApp(
      settings: SettingsController(storage),
      notes: notes,
      pro: proC,
      shareReceiver: shares,
    ),
  );
  await tester.pumpAndSettle();
  return notes;
}

void main() {
  testWidgets('a board starts from a template, from the "+" tab', (
    tester,
  ) async {
    final notes = await _pumpApp(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(BoardBar),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('From a template'));
    await tester.pumpAndSettle();
    expect(find.byType(GalleryScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kanban');
    await tester.pumpAndSettle();
    expect(find.text('Kanban Lite'), findsOneWidget);
    await tester.tap(find.text('Kanban Lite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this template'));
    await tester.pumpAndSettle();

    expect(find.byType(GalleryScreen), findsNothing);
    expect(notes.currentBoard.name, 'Kanban Lite');
    expect(notes.boardNotes.map((n) => n.content), contains('Doing'));
    expect(find.textContaining('is ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a free theme goes on the board and comes off with Undo', (
    tester,
  ) async {
    final notes = await _pumpApp(tester);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Templates & themes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Themes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Free'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark Chalk'));
    await tester.pumpAndSettle();
    expect(find.textContaining('What you wrote'), findsOneWidget);
    await tester.tap(find.text('Apply to “My Wall”'));
    await tester.pumpAndSettle();

    final mine = notes.boardNotes.single;
    expect(notes.currentBoard.themeId, 'dark_chalk');
    expect(notes.currentBoard.fontId, 'amatic');
    expect(mine.content, 'My own words');
    expect((mine.x, mine.y), (0.3, 0.4));
    expect(find.text('“Dark Chalk” applied'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await tester.pumpAndSettle();
    expect(notes.currentBoard.themeId, '');
    expect(mine.colorIndex, 2);
  });

  testWidgets('a Pro theme without Pro offers Pro instead', (tester) async {
    final notes = await _pumpApp(tester);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Templates & themes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Themes'));
    await tester.pumpAndSettle();
    // The shelf chips scroll sideways; Seasonal is past the edge.
    final strip = find.byWidget(
      tester.widget<ListView>(
        find.ancestor(of: find.text('Free'), matching: find.byType(ListView)),
      ),
    );
    await tester.dragUntilVisible(
      find.text('Seasonal'),
      strip,
      const Offset(-120, 0),
    );
    await tester.ensureVisible(find.text('Seasonal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seasonal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunar New Year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock with Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Sticky Wall Pro'), findsWidgets);
    expect(notes.currentBoard.themeId, '');
  });

  testWidgets('a fresh install can start blank', (tester) async {
    final notes = await _pumpApp(tester, welcome: true);
    expect(find.text('Welcome to Sticky Wall'), findsOneWidget);
    await tester.tap(find.text('Start with a blank wall'));
    await tester.pumpAndSettle();
    expect(notes.boardNotes, isEmpty);
    expect(notes.trashed, isEmpty, reason: 'examples never were theirs');
  });

  testWidgets('a fresh install can start from a template', (tester) async {
    final notes = await _pumpApp(tester, welcome: true);
    await tester.tap(find.text('Pick a template'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this template'));
    await tester.pumpAndSettle();
    expect(notes.boards.length, 1, reason: 'filled in, not added');
    expect(notes.currentBoard.name, 'Daily Notes');
    expect(notes.boardNotes.any((n) => n.content == 'My own words'), isFalse);
    expect(notes.boardNotes.any((n) => n.content == 'Morning'), isTrue);
  });

  testWidgets('the sample wall stays when explored', (tester) async {
    final notes = await _pumpApp(tester, welcome: true);
    await tester.tap(find.text('Explore the sample wall'));
    await tester.pumpAndSettle();
    expect(notes.boardNotes.single.content, 'My own words');
  });

  testWidgets('all boards: pictures, switch, duplicate with Undo', (
    tester,
  ) async {
    final notes = await _pumpApp(tester);
    final work = notes.addBoard('Work');
    notes
      ..seed(
        [
          Note(
            guid: 'w1',
            content: 'Ship it',
            createdAt: DateTime(2026),
            boardId: work.id,
            stack: 's',
          ),
          Note(
            guid: 'w2',
            content: 'Test it',
            createdAt: DateTime(2026),
            boardId: work.id,
            stack: 's',
          ),
        ],
        links: const [NoteLink('w1', 'w2')],
      )
      ..selectBoard('default');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('All boards'));
    await tester.pumpAndSettle();
    expect(find.text('2 notes'), findsOneWidget);
    expect(find.text('1 note'), findsOneWidget);
    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();
    expect(notes.currentBoardId, work.id);

    await tester.tap(find.byTooltip('All boards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate board'));
    await tester.pumpAndSettle();
    final copy = notes.currentBoard;
    expect(copy.name, 'Work (copy)');
    expect(notes.boards.indexOf(copy), notes.boards.indexOf(work) + 1);
    final copied = notes.boardNotes;
    expect(copied.map((n) => n.content).toSet(), {'Ship it', 'Test it'});
    expect(copied.every((n) => !{'w1', 'w2'}.contains(n.guid)), isTrue);
    expect(copied.first.stack, isNot('s'), reason: 'its own stack');
    expect(copied.first.stack, copied.last.stack);
    expect(notes.linksOn(copy.id), hasLength(1));
    expect(notes.linksOn(work.id), hasLength(1), reason: 'original kept');

    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await tester.pumpAndSettle();
    expect(notes.boards.any((b) => b.id == copy.id), isFalse);
  });

  testWidgets('a shared link goes straight onto the chosen board', (
    tester,
  ) async {
    final shares = _FakeShares();
    final notes = await _pumpApp(tester, shares: shares);
    final work = notes.addBoard('Work');
    notes.selectBoard('default');
    await tester.pumpAndSettle();

    shares.deliver!(
      const SharedContent(text: 'Read later', url: 'https://example.com/a'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save to which board?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Work'));
    await tester.pumpAndSettle();

    expect(notes.currentBoardId, work.id);
    final saved = notes.boardNotes.single;
    expect(saved.type, NoteType.link);
    expect(saved.url, 'https://example.com/a');
    expect(saved.content, 'Read later');
    expect(find.text('Saved to “Work”'), findsOneWidget);

    // The same link again is not stuck up twice.
    shares.deliver!(const SharedContent(url: 'http://www.example.com/a'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Work'));
    await tester.pumpAndSettle();
    expect(notes.boardNotes, hasLength(1));

    shares.deliver!(const SharedContent(text: 'Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Work'));
    await tester.pumpAndSettle();
    expect(notes.boardNotes, hasLength(2));
    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await tester.pumpAndSettle();
    expect(notes.boardNotes, hasLength(1));
  });
}

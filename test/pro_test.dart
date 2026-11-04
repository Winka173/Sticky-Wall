import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/app_lock.dart';
import 'package:sticky_wall/services/backup_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/pro_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/widget_service.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/add_note_button.dart';
import 'package:sticky_wall/widgets/lock_gate.dart';
import 'package:sticky_wall/widgets/note_views.dart';
import 'package:sticky_wall/widgets/stickers.dart';
import 'package:sticky_wall/widgets/wall_view.dart';

final _epoch = DateTime(2026);

Note _note(
  String guid, {
  bool pinned = false,
  NoteType type = NoteType.normal,
  int minutes = 0,
  String boardId = 'default',
}) => Note(
  guid: guid,
  content: guid,
  type: type,
  pinned: pinned,
  boardId: boardId,
  createdAt: _epoch.add(Duration(minutes: minutes)),
  x: 0.1,
  y: 0.1,
);

/// The app with a store-less [ProController] (Pro locked unless [pro]).
Future<(NotesController, SettingsController, ProController)> _pumpApp(
  WidgetTester tester, {
  bool pro = false,
  List<Note> notes = const [],
  List<NoteLink> links = const [],
  List<Board>? boards,
  ViewMode viewMode = ViewMode.grid,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes(notes);
  await storage.saveLinks(links);
  if (boards != null) await storage.saveBoards(boards);
  await storage.setViewMode(viewMode);
  final controller = NotesController(storage, ReminderService());
  final settings = SettingsController(storage);
  final proController = ProController(storage);
  if (pro) proController.unlockForTesting();
  await tester.pumpWidget(
    StickyWallApp(settings: settings, notes: controller, pro: proController),
  );
  await tester.pumpAndSettle();
  return (controller, settings, proController);
}

Future<void> _openCustomize(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.palette_outlined));
  await tester.pumpAndSettle();
}

/// Scrolls the Customize sheet down to the row holding [first], then along
/// that row until [target] is built.
Future<void> _scrollToTile(
  WidgetTester tester,
  String first,
  String target,
) async {
  await tester.scrollUntilVisible(
    find.text(first),
    150,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last,
  );
  // Driven through its position: the tile it was found by scrolls out of
  // the row and is dropped, so a finder on it would not last.
  final row = tester.state<ScrollableState>(
    find
        .ancestor(of: find.text(first), matching: find.byType(Scrollable))
        .first,
  );
  while (find.text(target).evaluate().isEmpty &&
      row.position.pixels < row.position.maxScrollExtent) {
    row.position.jumpTo(row.position.pixels + 200);
    await tester.pump();
  }
  await tester.ensureVisible(find.text(target));
  await tester.pumpAndSettle();
}

/// An [AppLock] that answers [results] in turn (the last one repeats).
class _FakeLock extends AppLock {
  _FakeLock(this.results);

  final List<UnlockResult> results;
  int asked = 0;

  @override
  Future<UnlockResult> authenticate(String reason) async {
    final result = results[asked.clamp(0, results.length - 1)];
    asked++;
    return result;
  }
}

Widget _gated(AppLock lock, {Duration awayLimit = Duration.zero}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => LockGate(
        enabled: true,
        lock: lock,
        awayLimit: awayLimit,
        child: child!,
      ),
      home: const Scaffold(body: Text('my notes')),
    );

void main() {
  group('Pro things', () {
    test('a note without a colour never lands on a Pro paper', () {
      for (var i = 0; i < 500; i++) {
        final color = noteColor(null, 'note-$i');
        final index = AppColors.notePapers.indexOf(color);
        expect(index, lessThan(AppColors.freePapers));
      }
    });

    test('Pro fonts and pins are drawn only while Pro is unlocked', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsController(await NoteStorage.create());
      final proFont = fontChoices.firstWhere((f) => f.pro);
      settings
        ..setFontId(proFont.id)
        ..setPinStyle(PinStyle.washi);
      expect(settings.fontFor(pro: true).id, proFont.id);
      expect(settings.fontFor(pro: false).id, fontChoices.first.id);
      expect(settings.pinStyleFor(pro: true), PinStyle.washi);
      expect(settings.pinStyleFor(pro: false), PinStyle.classic);
      expect(pinStyleById('nonsense'), PinStyle.classic);
    });

    test('without a store Pro stays as cached and says so', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      final pro = ProController(storage);
      await pro.init();
      expect(pro.unlocked, isFalse);
      expect(pro.status, ProStatus.unavailable);
      expect(pro.canBuy, isFalse);

      pro.unlockForTesting();
      expect(ProController(storage).unlocked, isTrue);
    });

    test('a refunded order stops unlocking Pro; no answer keeps it', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      ProController(storage).unlockForTesting();

      // Offline, or Play missing: the cached unlock stands.
      final offline = ProController(storage, ownership: () async => null);
      await offline.init();
      expect(offline.unlocked, isTrue);

      // Still owned.
      final owned = ProController(storage, ownership: () async => true);
      await owned.init();
      expect(owned.unlocked, isTrue);

      // Play answers that the account no longer owns it (refund, revoke).
      final refunded = ProController(storage, ownership: () async => false);
      await refunded.init();
      expect(refunded.unlocked, isFalse);
      expect(ProController(storage).unlocked, isFalse, reason: 'remembered');
    });

    testWidgets('a Pro wall tapped again without Pro opens the Pro sheet', (
      tester,
    ) async {
      final (notes, _, _) = await _pumpApp(tester);
      await _openCustomize(tester);
      await _scrollToTile(tester, 'Cork board', 'Navy chalkboard');
      // The first tap tries it on; the second offers Pro.
      await tester.tap(find.text('Navy chalkboard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Navy chalkboard'));
      await tester.pumpAndSettle();

      expect(find.text('Sticky Wall Pro'), findsWidgets);
      expect(find.textContaining("Purchases aren't available"), findsOneWidget);
      expect(notes.currentBoard.wallIndex, 0);
    });

    testWidgets('with Pro the same wall is simply chosen', (tester) async {
      final (notes, _, _) = await _pumpApp(tester, pro: true);
      await _openCustomize(tester);
      expect(find.text('Unlocked. Thank you!'), findsOneWidget);
      await _scrollToTile(tester, 'Cork board', 'Navy chalkboard');
      await tester.tap(find.text('Navy chalkboard'));
      await tester.pumpAndSettle();
      expect(walls[notes.currentBoard.wallIndex].id, 'chalk_navy');
    });

    testWidgets('a pin style is picked in Customize', (tester) async {
      final (_, settings, _) = await _pumpApp(tester, pro: true);
      await _openCustomize(tester);
      await _scrollToTile(tester, 'Red pin', 'Paper clip');
      await tester.tap(find.text('Paper clip'));
      await tester.pumpAndSettle();
      expect(settings.pinStyle, PinStyle.clip);
    });

    for (final style in PinStyle.values) {
      testWidgets('cards draw with the ${style.name} pin', (tester) async {
        final (_, settings, _) = await _pumpApp(
          tester,
          pro: true,
          viewMode: ViewMode.wall,
          notes: [_note('a'), _note('b', pinned: true)],
        );
        settings.setPinStyle(style);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Two cards, plus the decorative pin on the add button.
        expect(find.byType(NotePin), findsNWidgets(3));
      });
    }
  });

  group('App lock', () {
    testWidgets('is off by default', (tester) async {
      await _pumpApp(tester);
      expect(find.text('Sticky Wall is locked'), findsNothing);
    });

    testWidgets('opens once the phone lock is given', (tester) async {
      final lock = _FakeLock([UnlockResult.unlocked]);
      await tester.pumpWidget(_gated(lock));
      await tester.pumpAndSettle();
      expect(lock.asked, 1);
      expect(find.text('Sticky Wall is locked'), findsNothing);
      expect(find.text('my notes').hitTestable(), findsOneWidget);
    });

    testWidgets('stays shut when cancelled, and Unlock asks again', (
      tester,
    ) async {
      final lock = _FakeLock([UnlockResult.failed, UnlockResult.unlocked]);
      await tester.pumpWidget(_gated(lock));
      await tester.pumpAndSettle();
      expect(find.text('Sticky Wall is locked'), findsOneWidget);
      expect(find.text('my notes').hitTestable(), findsNothing);

      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(lock.asked, 2);
      expect(find.text('Sticky Wall is locked'), findsNothing);
    });

    testWidgets('locks again after time in the background', (tester) async {
      final lock = _FakeLock([UnlockResult.unlocked, UnlockResult.failed]);
      await tester.pumpWidget(_gated(lock));
      await tester.pumpAndSettle();
      expect(find.text('Sticky Wall is locked'), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Sticky Wall is locked'), findsOneWidget);
    });

    testWidgets('a short trip away does not ask again', (tester) async {
      final lock = _FakeLock([UnlockResult.unlocked]);
      await tester.pumpWidget(
        _gated(lock, awayLimit: const Duration(minutes: 1)),
      );
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(lock.asked, 1);
      expect(find.text('Sticky Wall is locked'), findsNothing);
    });

    testWidgets('a phone whose lock was removed is not locked out', (
      tester,
    ) async {
      await tester.pumpWidget(_gated(_FakeLock([UnlockResult.noLock])));
      await tester.pumpAndSettle();
      expect(find.text('Sticky Wall is locked'), findsNothing);
    });
  });

  group('Home-screen widget', () {
    final all = [
      _note('old', minutes: 1),
      _note('pinned', pinned: true, minutes: 2),
      _note('label', type: NoteType.label, minutes: 9),
      _note('new', minutes: 5),
      _note('elsewhere', pinned: true, minutes: 8, boardId: 'other'),
      _note('gone', minutes: 7)..deletedAt = _epoch,
    ];

    test('lists the pinned notes of the chosen board', () {
      final shown = WidgetService.notesFor(
        all,
        'default',
        WidgetContent.pinned,
      );
      expect(shown.map((n) => n.guid), ['pinned']);
    });

    test('lists the newest notes first, without labels or the trash', () {
      final shown = WidgetService.notesFor(
        all,
        'default',
        WidgetContent.newest,
      );
      expect(shown.map((n) => n.guid), ['new', 'pinned', 'old']);
    });

    test('settings start as before: pinned notes on the wall brown', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsController(await NoteStorage.create());
      expect(settings.widgetBoard, '');
      expect(settings.widgetContent, WidgetContent.pinned);
      expect(settings.widgetLook, WidgetLook.wall);
      expect(settings.widgetTextSize, WidgetTextSize.normal);
      expect(settings.appLock, isFalse);
    });
  });

  group('More Pro things', () {
    test('paper, sticker and thread style survive JSON, and old data '
        'reads as before', () {
      final note = _note('a')
        ..paper = PaperStyle.notebook
        ..type = NoteType.sticker
        ..sticker = 'urgent';
      final back = Note.fromJson(note.toJson());
      expect(back.paper, PaperStyle.notebook);
      expect(back.sticker, 'urgent');
      expect(back.type, NoteType.sticker);

      final old = Note.fromJson(_note('b').toJson()..remove('paper'));
      expect(old.paper, PaperStyle.plain);
      expect(old.toJson().containsKey('paper'), isFalse);

      const link = NoteLink('a', 'b', style: ThreadStyle.ribbon);
      expect(NoteLink.fromJson(link.toJson()).style, ThreadStyle.ribbon);
      expect(
        NoteLink.fromJson(const NoteLink('a', 'b').toJson()).style,
        ThreadStyle.yarn,
      );
    });

    test('the highlighter draws broad and see-through', () {
      const pen = WallMarker(color: 0xFFD32F2F, width: 3);
      expect(pen.strokeColor, 0xFFD32F2F);
      expect(pen.strokeWidth, 3);
      final marker = pen.copyWith(highlighter: true);
      expect(marker.strokeColor >>> 24, AppColors.highlighterAlpha);
      expect(marker.strokeColor & 0xFFFFFF, 0xD32F2F);
      expect(marker.strokeWidth, greaterThan(10));
    });

    test('Pro is offered once, after a week and twenty notes', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      final settings = SettingsController(storage);
      final now = DateTime.now();
      expect(settings.shouldOfferPro(noteCount: 30, now: now), isFalse);
      final later = now.add(const Duration(days: 8));
      expect(settings.shouldOfferPro(noteCount: 10, now: later), isFalse);
      expect(settings.shouldOfferPro(noteCount: 20, now: later), isTrue);
      settings.markProOffered();
      await Future<void>.delayed(Duration.zero);
      expect(settings.shouldOfferPro(noteCount: 20, now: later), isFalse);
      // The install date is kept, not reset at every start.
      await storage.setProOffered(false);
      expect(
        SettingsController(storage).shouldOfferPro(noteCount: 20, now: now),
        isFalse,
      );
    });

    testWidgets('every sticker and paper style draws, stickers without a '
        'pin', (tester) async {
      final notes = [
        for (final (i, s) in stickers.indexed)
          _note('s$i', type: NoteType.sticker)
            ..content = ''
            ..sticker = s.id,
        for (final style in PaperStyle.values)
          _note('p${style.name}')..paper = style,
      ];
      await _pumpApp(tester, pro: true, notes: notes);
      expect(tester.takeException(), isNull);
      expect(find.byType(StickerArt), findsWidgets);
      for (final note in notes.where((n) => n.type == NoteType.sticker)) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey(note.guid)),
            matching: find.byType(NotePin),
          ),
          findsNothing,
        );
      }
    });

    for (final style in ThreadStyle.values) {
      testWidgets('a ${style.name} thread draws on the wall', (tester) async {
        await _pumpApp(
          tester,
          pro: true,
          viewMode: ViewMode.wall,
          notes: [
            _note('a'),
            _note('b')
              ..x = 0.7
              ..y = 0.6,
          ],
          links: [NoteLink('a', 'b', style: style, arrow: true)],
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a free sticker is stuck on the wall from the add menu', (
      tester,
    ) async {
      final (notes, _, _) = await _pumpApp(tester, viewMode: ViewMode.wall);
      await tester.longPress(find.byType(AddNoteButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sticker'));
      await tester.pumpAndSettle();
      expect(find.text('Pick a sticker'), findsOneWidget);

      // A Pro stamp offers Pro instead.
      await tester.tap(find.bySemanticsLabel('Urgent, Pro'));
      await tester.pumpAndSettle();
      expect(find.textContaining("Purchases aren't available"), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('⭐'));
      await tester.pumpAndSettle();
      final stuck = notes.boardNotes.single;
      expect(stuck.type, NoteType.sticker);
      expect(stuck.sticker, 'star');
    });

    testWidgets('a Pro wall is tried on, then put back', (tester) async {
      final (notes, settings, _) = await _pumpApp(tester);
      await _openCustomize(tester);
      await _scrollToTile(tester, 'Cork board', 'Navy chalkboard');
      await tester.tap(find.text('Navy chalkboard'));
      await tester.pumpAndSettle();
      expect(settings.tryWall, walls.indexWhere((w) => w.id == 'chalk_navy'));
      expect(notes.currentBoard.wallIndex, 0, reason: 'not saved');
      expect(find.text('Put back'), findsOneWidget);

      await tester.tap(find.text('Put back'));
      await tester.pumpAndSettle();
      expect(settings.tryingOn, isFalse);

      // Tried again and the sheet closed: put back as well.
      await tester.tap(find.text('Navy chalkboard'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(settings.tryingOn, isFalse);
      expect(notes.currentBoard.wallIndex, 0);
    });

    testWidgets('bought while trying on, the wall and font are kept', (
      tester,
    ) async {
      final (notes, settings, pro) = await _pumpApp(tester);
      await _openCustomize(tester);
      final font = fontChoices.firstWhere((f) => f.pro);
      settings
        ..setTryWall(walls.indexWhere((w) => w.id == 'sage'))
        ..setTryFont(font.id);
      await tester.pumpAndSettle();
      pro.unlockForTesting();
      await tester.pumpAndSettle();
      expect(settings.tryingOn, isFalse);
      expect(walls[notes.currentBoard.wallIndex].id, 'sage');
      expect(settings.font.id, font.id);
    });
  });

  group('Seasons, private boards, own colours', () {
    test('a mixed paper colour is stored in colorIndex and read back', () {
      const mint = Color(0xFFCDEFE0);
      final stored = customPaper(mint);
      expect(isCustomPaper(stored), isTrue);
      expect(noteColor(stored, 'x'), mint);
      // Palette indices and "auto" are untouched.
      expect(isCustomPaper(3), isFalse);
      expect(isCustomPaper(null), isFalse);
      expect(noteColor(3, 'x'), AppColors.notePapers[3]);
      final note = _note('a')..colorIndex = stored;
      expect(Note.fromJson(note.toJson()).colorIndex, stored);
    });

    test('every seasonal sticker has a pack and the packs are Pro', () {
      for (final pack in StickerPack.values.skip(1)) {
        final inPack = stickers.where((s) => s.pack == pack);
        expect(inPack, isNotEmpty, reason: pack.name);
        expect(inPack.every((s) => s.pro), isTrue);
      }
      expect(stickers.map((s) => s.id).toSet().length, stickers.length);
      for (final id in ['tet', 'tet_dao', 'xmas', 'moon', 'love']) {
        expect(walls.where((w) => w.id == id).single.pro, isTrue);
      }
    });

    test('a shut private board keeps its notes out of search and the '
        'trash list', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveBoards([
        Board(id: 'default', name: ''),
        Board(id: 'secret', name: 'Diary', isPrivate: true),
      ]);
      await storage.saveNotes([
        _note('open')..content = 'milk',
        _note('hidden', boardId: 'secret')..content = 'milk diary',
        _note('binned', boardId: 'secret')
          ..content = 'milk'
          ..deletedAt = DateTime.now(),
      ]);
      final notes = NotesController(storage, ReminderService());
      final secret = notes.boards.firstWhere((b) => b.id == 'secret');
      expect(notes.isOpen(secret), isFalse);
      notes.search = 'milk';
      expect(notes.otherBoardMatches, isEmpty);
      expect(notes.trashed, isEmpty);

      notes.openPrivateBoard('secret');
      expect(notes.otherBoardMatches.map((n) => n.guid), ['hidden']);
      expect(notes.trashed.map((n) => n.guid), ['binned']);

      notes.shutPrivateBoards();
      expect(notes.isOpen(secret), isFalse);
      expect(Board.fromJson(secret.toJson()).isPrivate, isTrue);
    });

    testWidgets('a shut private board shows its cover, not its notes', (
      tester,
    ) async {
      final (notes, _, _) = await _pumpApp(
        tester,
        pro: true,
        boards: [Board(id: 'default', name: '', isPrivate: true)],
        notes: [_note('a')..content = 'my secret'],
      );
      expect(find.text('Private board'), findsOneWidget);
      expect(find.text('my secret'), findsNothing);
      expect(find.byType(AddNoteButton), findsNothing);

      // No lock plugin in tests: like a phone without a screen lock, it opens.
      await tester.tap(find.text('Unlock'));
      // The lock plugin answers on a real platform channel turn.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('my secret'), findsOneWidget);

      // A quick trip out (a photo picker, a share sheet) keeps it open.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('my secret'), findsOneWidget);

      // Shut again (after a minute away), nothing of it is listed.
      notes.shutPrivateBoards();
      await tester.pumpAndSettle();
      expect(find.text('my secret'), findsNothing);
      expect(notes.currentBoardShut, isTrue);
      expect(notes.boardNotes, isEmpty);
      expect(notes.visibleNotes, isEmpty);
    });
  });

  group('Seasons', () {
    tearDown(() => seasonClock = DateTime.now);

    test('each pack opens only around its occasion', () {
      bool open(Season s, int y, int m, int d) =>
          seasonOpen(s, now: DateTime(y, m, d));
      // Tết 2027 is on 6 February.
      expect(open(Season.tet, 2027, 1, 11), isFalse);
      expect(open(Season.tet, 2027, 1, 12), isTrue);
      expect(open(Season.tet, 2027, 2, 21), isTrue);
      expect(open(Season.tet, 2027, 2, 22), isFalse);
      // Christmas runs over New Year.
      expect(open(Season.christmas, 2026, 11, 30), isFalse);
      expect(open(Season.christmas, 2026, 12, 24), isTrue);
      expect(open(Season.christmas, 2027, 1, 6), isTrue);
      expect(open(Season.christmas, 2027, 1, 7), isFalse);
      // Mid-Autumn 2027 is on 15 September.
      expect(open(Season.midAutumn, 2027, 8, 24), isFalse);
      expect(open(Season.midAutumn, 2027, 9, 1), isTrue);
      expect(open(Season.midAutumn, 2027, 9, 19), isFalse);
      expect(open(Season.valentine, 2027, 2, 14), isTrue);
      expect(open(Season.valentine, 2027, 3, 1), isFalse);
      // Past the known calendar a pack stays open rather than locked away.
      expect(open(Season.tet, 2040, 7, 1), isTrue);
    });

    test('the next window is the coming one', () {
      final next = currentOrNextSeason(Season.tet, now: DateTime(2026, 11, 3))!;
      expect(next.start, DateTime(2027, 1, 12));
      expect(next.end, DateTime(2027, 2, 21));
    });

    testWidgets('out of season a pack can still be picked', (tester) async {
      seasonClock = () => DateTime(2026, 7, 3);
      await _pumpApp(tester, pro: true, viewMode: ViewMode.wall);
      await tester.longPress(find.byType(AddNoteButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sticker'));
      await tester.pumpAndSettle();
      final mai = find.bySemanticsLabel('Apricot blossom');
      await tester.scrollUntilVisible(
        mai,
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(mai);
      await tester.pumpAndSettle();
      expect(find.textContaining('back '), findsNothing);
    });

    testWidgets('in season its stickers can be picked', (tester) async {
      seasonClock = () => DateTime(2027, 2, 1);
      await _pumpApp(tester, pro: true, viewMode: ViewMode.wall);
      await tester.longPress(find.byType(AddNoteButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sticker'));
      await tester.pumpAndSettle();
      final mai = find.bySemanticsLabel('Apricot blossom');
      await tester.scrollUntilVisible(
        mai,
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(mai, findsOneWidget);
      expect(find.textContaining('until Feb 21'), findsOneWidget);
    });

    test('a seasonal wall is featured around its occasion', () {
      final tet = walls.firstWhere((w) => w.id == 'tet');
      seasonClock = () => DateTime(2026, 11, 3);
      expect(tet.inSeason, isFalse);
      seasonClock = () => DateTime(2027, 1, 20);
      expect(tet.inSeason, isTrue);
      expect(walls.firstWhere((w) => w.id == 'cork').inSeason, isTrue);
    });
  });

  test('a backup keeps paper styles, stickers, own colours, private boards '
      'and thread styles', () {
    final notes = [
      _note('a')
        ..paper = PaperStyle.notebook
        ..colorIndex = customPaper(const Color(0xFFDDEEFF)),
      _note('s', type: NoteType.sticker)..sticker = 'mai',
    ];
    final boards = [Board(id: 'default', name: 'Diary', isPrivate: true)];
    const links = [NoteLink('a', 's', style: ThreadStyle.beads)];
    final back = BackupService().decode(
      BackupService().encode(boards, notes, links),
    );
    expect(back.boards.single.isPrivate, isTrue);
    final a = back.notes.firstWhere((n) => n.guid == 'a');
    expect(a.paper, PaperStyle.notebook);
    expect(noteColor(a.colorIndex, 'a'), const Color(0xFFDDEEFF));
    expect(back.notes.firstWhere((n) => n.guid == 's').sticker, 'mai');
    expect(back.links!.single.style, ThreadStyle.beads);
  });
}

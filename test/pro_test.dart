import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/app_lock.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/pro_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/widget_service.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/lock_gate.dart';
import 'package:sticky_wall/widgets/note_views.dart';

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
  ViewMode viewMode = ViewMode.grid,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes(notes);
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

    testWidgets('a Pro wall without Pro opens the Pro sheet instead', (
      tester,
    ) async {
      final (notes, _, _) = await _pumpApp(tester);
      await _openCustomize(tester);
      await _scrollToTile(tester, 'Cork board', 'Navy chalkboard');
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
}

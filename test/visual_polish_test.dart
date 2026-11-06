import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/screens/gallery_screen.dart';
import 'package:sticky_wall/screens/memory_wall_sheet.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/pro_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/template_library.dart';
import 'package:sticky_wall/services/theme_packs.dart';
import 'package:sticky_wall/widgets/add_note_button.dart';
import 'package:sticky_wall/widgets/add_to_wall_sheet.dart';
import 'package:sticky_wall/widgets/photo_frames.dart';

Future<(NotesController, NoteStorage)> _pump(
  WidgetTester tester, {
  bool pro = false,
  String lang = 'en',
  bool locked = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([
    Board(id: 'default', name: 'My board', isPrivate: locked),
  ]);
  await storage.saveNotes([
    Note(
      guid: 'my-note',
      content: 'My own idea',
      boardId: 'default',
      createdAt: DateTime(2026),
      colorIndex: 0,
      rotation: .13,
      x: .05,
      y: .1,
    ),
  ]);
  await storage.setLanguageCode(lang);
  await storage.setViewMode(ViewMode.wall);
  final notes = NotesController(storage, ReminderService());
  final billing = ProController(storage);
  if (pro) billing.unlockForTesting();
  await tester.pumpWidget(
    StickyWallApp(
      notes: notes,
      settings: SettingsController(storage),
      pro: billing,
    ),
  );
  await tester.pumpAndSettle();
  return (notes, storage);
}

void main() {
  test('catalog entitlement split and billing identity remain unchanged', () {
    expect(themePacks.length, 37);
    expect(themePacks.where((p) => !p.pro).length, 17);
    expect(PhotoFrame.values.where((f) => !f.pro).length, 3);
    expect(ProController.productId, 'sticky_wall_pro');
  });
  for (final lang in ['en', 'vi']) {
    for (final size in [const Size(320, 700), const Size(900, 700)]) {
      testWidgets('Add picker readable at 200% $lang $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pump(tester, lang: lang);
        await tester.tap(find.byType(AddNoteButton));
        await tester.pumpAndSettle();
        expect(find.byType(AddToWallSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final type in [
          NoteType.normal,
          NoteType.checklist,
          NoteType.photo,
          NoteType.link,
          NoteType.audio,
          NoteType.drawing,
        ]) {
          final tile = find.byKey(ValueKey('add-${type.name}'));
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          final rect = tester.getRect(tile);
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final type in [NoteType.normal, NoteType.checklist, NoteType.photo]) {
    testWidgets('primary Add opens ${type.name} editor without losing board', (
      tester,
    ) async {
      final (notes, _) = await _pump(tester);
      await tester.tap(find.byType(AddNoteButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('add-${type.name}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('editor-type')), findsOneWidget);
      if (type == NoteType.photo) {
        expect(find.text('Add photo'), findsOneWidget);
        await tester.tap(find.byTooltip('Add'));
        await tester.pumpAndSettle();
        final words = AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        )!;
        expect(find.text(words.photoRequired), findsOneWidget);
      } else {
        await tester.enterText(find.byType(TextField).first, 'New from picker');
        await tester.tap(find.byTooltip('Add'));
        await tester.pumpAndSettle();
        expect(notes.boardNotes.last.type, type);
        expect(notes.boardNotes.last.content, 'New from picker');
      }
      expect(notes.currentBoardId, 'default');
      expect(tester.takeException(), isNull);
    });
  }

  for (final owned in [false, true]) {
    testWidgets(
      'theme trial uses own notes; cancel never writes (Pro=$owned)',
      (tester) async {
        await tester.runAsync(TemplateLibrary.load);
        final (notes, storage) = await _pump(tester, pro: owned);
        final before = jsonEncode(
          storage.loadNotes().map((n) => n.toJson()).toList(),
        );
        final context = tester.element(find.byType(Scaffold).first);
        unawaited(GalleryScreen.open(context, notes: notes, themes: true));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Free'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dark Chalk'));
        await tester.pumpAndSettle();
        expect(find.byType(ThemeBoardPreview), findsOneWidget);
        final preview = tester.widget<BoardPreview>(
          find.descendant(
            of: find.byType(ThemeBoardPreview),
            matching: find.byType(BoardPreview),
          ),
        );
        expect(preview.notes.single.content, 'My own idea');
        expect(preview.notes.single.rotation, .13);
        expect(
          identical(preview.notes.single, notes.boardNotes.single),
          isFalse,
        );
        expect(
          jsonEncode(storage.loadNotes().map((n) => n.toJson()).toList()),
          before,
        );
        Navigator.of(tester.element(find.byType(ThemeBoardPreview))).pop();
        await tester.pumpAndSettle();
        expect(
          jsonEncode(storage.loadNotes().map((n) => n.toJson()).toList()),
          before,
        );
        expect(notes.currentBoard.themeId, '');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Memory Pro frame is previewable; Create still requires Pro', (
    tester,
  ) async {
    await _pump(tester);
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(showMemoryWallSheet(context, count: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Film strip · Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Sticky Wall Pro'), findsNothing);
    final unlock = find.text('Unlock with Pro');
    await tester.ensureVisible(unlock);
    await tester.tap(unlock);
    await tester.pumpAndSettle();
    expect(find.text('Sticky Wall Pro'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a locked board never exposes notes in theme trials', (
    tester,
  ) async {
    await tester.runAsync(TemplateLibrary.load);
    final (notes, _) = await _pump(tester, locked: true);
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(GalleryScreen.open(context, notes: notes, themes: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Free'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark Chalk'));
    await tester.pumpAndSettle();
    expect(find.byType(ThemeBoardPreview), findsNothing);
    expect(find.text('My own idea'), findsNothing);
    await tester.tap(find.text('Apply to this board'));
    await tester.pumpAndSettle();
    expect(notes.currentBoard.themeId, '');
  });

  testWidgets('compact memory preview keeps all print corners in frame', (
    tester,
  ) async {
    await _pump(tester);
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(
      showMemoryWallSheet(
        context,
        count: 20,
        photos: [for (var i = 0; i < 20; i++) 'missing-fixture-$i.jpg'],
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('memory-live-preview'));
    final bounds = tester.getRect(preview).inflate(1);
    final prints = find.descendant(
      of: preview,
      matching: find.byType(FramedPrint),
    );
    expect(prints, findsNWidgets(20));
    for (final element in prints.evaluate()) {
      final box = element.renderObject! as RenderBox;
      for (final corner in [
        Offset.zero,
        Offset(box.size.width, 0),
        Offset(0, box.size.height),
        Offset(box.size.width, box.size.height),
      ]) {
        expect(bounds.contains(box.localToGlobal(corner)), isTrue);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('owned Pro applies the exact trial look without moving words', (
    tester,
  ) async {
    await tester.runAsync(TemplateLibrary.load);
    final (notes, _) = await _pump(tester, pro: true);
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(GalleryScreen.open(context, notes: notes, themes: true));
    await tester.pumpAndSettle();
    final chipScroll = tester.state<ScrollableState>(
      find
          .ancestor(
            of: find.byTooltip('Free'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    chipScroll.position.jumpTo(chipScroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Seasonal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunar New Year'));
    await tester.pumpAndSettle();
    final preview = tester.widget<BoardPreview>(
      find.descendant(
        of: find.byType(ThemeBoardPreview),
        matching: find.byType(BoardPreview),
      ),
    );
    final color = preview.notes.single.colorIndex;
    final pack = preview.pack!;
    await tester.tap(find.text('Apply to this board'));
    await tester.pumpAndSettle();
    expect(notes.currentBoard.themeId, pack.id);
    expect(notes.boardNotes.single.colorIndex, color);
    expect(notes.boardNotes.single.content, 'My own idea');
    expect(notes.boardNotes.single.rotation, .13);
    expect(notes.boardNotes.single.x, .05);
    expect(notes.boardNotes.single.y, .1);
    expect(tester.takeException(), isNull);
  });
}

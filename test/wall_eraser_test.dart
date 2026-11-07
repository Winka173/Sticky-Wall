import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/draw_stroke.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/note_views.dart';
import 'package:sticky_wall/widgets/wall_view.dart';

void main() {
  Future<(NotesController, NoteStorage)> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveNotes([]);
    await storage.setViewMode(ViewMode.wall);
    final notes = NotesController(storage, ReminderService());
    await tester.pumpWidget(
      StickyWallApp(notes: notes, settings: SettingsController(storage)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pen'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Done'), findsOneWidget);
    await tester.pumpAndSettle();
    return (notes, storage);
  }

  for (final width in [320.0, 430.0, 600.0]) {
    testWidgets(
      'tool pill remains tappable on an empty ${width.toInt()}dp wall',
      (tester) async {
        await pump(tester);
        await tester.tap(find.byTooltip('Done'));
        await tester.pumpAndSettle();
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pen'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Done'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'fast eraser sweep cuts only touched ink, saves fragments and undoes once',
    (tester) async {
      final (notes, storage) = await pump(tester);
      final pen = await tester.startGesture(const Offset(60, 420));
      await pen.moveTo(const Offset(350, 420));
      await pen.up();
      await tester.pumpAndSettle();
      final original = notes.currentBoard.strokes.single.toJson();
      await tester.tap(find.byTooltip('Eraser'));
      await tester.pump();
      final eraser = await tester.startGesture(const Offset(200, 360));
      await tester.pump();
      expect(find.byKey(const ValueKey('wall-eraser-cursor')), findsOneWidget);
      await eraser.moveTo(const Offset(200, 480));
      await tester.pump();
      expect(
        notes.currentBoard.strokes,
        hasLength(2),
        reason: 'Cut even when both pointer samples miss the ink',
      );
      await eraser.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wall-eraser-cursor')), findsNothing);
      final persisted = storage.loadBoards().firstWhere(
        (b) => b.id == notes.currentBoardId,
      );
      expect(
        persisted.strokes.map((s) => s.toJson()).toList(),
        notes.currentBoard.strokes.map((s) => s.toJson()).toList(),
      );
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(notes.currentBoard.strokes.single.toJson(), original);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(
        notes.currentBoard.strokes,
        isEmpty,
        reason:
            'The next undo removes the original draw, not another piece of the erase',
      );
    },
  );

  testWidgets('rubbing empty wall does not add an Undo step', (tester) async {
    final (notes, _) = await pump(tester);
    await tester.dragFrom(const Offset(60, 420), const Offset(290, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Eraser'));
    await tester.pump();
    await tester.dragFrom(const Offset(60, 600), const Offset(290, 0));
    await tester.pumpAndSettle();
    expect(notes.currentBoard.strokes, hasLength(1));
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(notes.currentBoard.strokes, isEmpty);
  });

  testWidgets('a marker drag repaints ink without rebuilding every note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var cardBuilds = 0;
    // Use the actual wall, counting its card construction callback.
    final note = Note(
      guid: 'a',
      content: 'Keep still',
      createdAt: DateTime(2026),
      boardId: 'default',
    );
    final strokes = <DrawStroke>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WallView(
            notes: [note],
            callbacksFor: (_) {
              cardBuilds++;
              return const NoteCallbacks(
                onEdit: _noop,
                onTogglePin: _noop,
                onToggleItem: _noopIndex,
                onLongPress: _noop,
              );
            },
            onMove: (_, _, _) {},
            onResize: (_, _) {},
            onBringToFront: (_) {},
            onCreateAt: (_, _) {},
            strokes: strokes,
            marking: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = cardBuilds;
    final gesture = await tester.startGesture(const Offset(80, 430));
    for (var i = 1; i <= 20; i++) {
      await gesture.moveTo(Offset(80 + i * 10, 430));
      await tester.pump();
    }
    expect(
      cardBuilds,
      before,
      reason: 'Pointer movement must not reconstruct the note layer',
    );
    expect(strokes.single.points, hasLength(21));
    await gesture.up();
    await tester.pumpAndSettle();
  });
}

void _noop() {}
void _noopIndex(int _) {}

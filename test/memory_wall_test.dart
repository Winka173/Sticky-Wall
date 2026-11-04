import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/screens/memory_wall_sheet.dart';
import 'package:sticky_wall/services/memory_wall.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/theme_packs.dart';
import 'package:sticky_wall/theme.dart';

List<String> _photos(int n) => [for (var i = 0; i < n; i++) 'p$i.jpg'];

void main() {
  group('Memory wall layout', () {
    for (final layout in MemoryLayout.values) {
      for (final n in [1, 2, 5, 12, 20, 26]) {
        test('${layout.name} with $n photos stays on the wall', () {
          final made = memoryWallNotes(
            _photos(n),
            'b',
            layout,
            title: 'Trip',
            now: DateTime(2026),
          );
          final prints = made.notes.where((x) => x.type == NoteType.photo);
          expect(prints.length, n.clamp(0, memoryWallMax));
          for (final p in made.notes) {
            expect(p.x, inInclusiveRange(0, 1));
            expect(p.y, inInclusiveRange(0, 1));
            expect(p.boardId, 'b');
          }
          // Prints keep the order they were picked in.
          final order = prints.toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          expect(order.first.imagePath, 'p0.jpg');
          // The title sits on top, held still.
          final title = made.notes.firstWhere((x) => x.type == NoteType.label);
          expect(title.content, 'Trip');
          expect(title.locked, isTrue);
          // A timeline ties each print to the next.
          expect(
            made.links.length,
            layout == MemoryLayout.timeline ? prints.length - 1 : 0,
          );
        });
      }
    }

    test('prints in a row do not run into each other', () {
      final made = memoryWallNotes(_photos(12), 'b', MemoryLayout.prints);
      const wall = 360.0;
      final rows = <double, List<Note>>{};
      for (final p in made.notes) {
        rows.putIfAbsent(p.y, () => []).add(p);
      }
      for (final row in rows.values) {
        row.sort((a, b) => a.x.compareTo(b.x));
        for (var i = 0; i + 1 < row.length; i++) {
          final w = 168 * row[i].scale;
          final leftA = row[i].x * (wall - w);
          final leftB = row[i + 1].x * (wall - w);
          expect(leftB - leftA, greaterThanOrEqualTo(w - 1));
        }
      }
    });
  });

  test('a memory wall is a board of its own, in the chosen look', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveBoards([Board(id: 'default', name: '')]);
    await storage.saveNotes([]);
    final c = NotesController(storage, ReminderService())
      ..viewMode = ViewMode.grid;
    final pack = themePackById('polaroid_studio')!;
    final board = c.addMemoryWall(
      'Memories',
      _photos(6),
      MemoryLayout.timeline,
      pack: pack,
    );
    expect(c.currentBoardId, board.id);
    expect(c.viewMode, ViewMode.wall);
    expect(board.themeId, 'polaroid_studio');
    expect(board.pinStyle, 'washi');
    expect(c.boardNotes.where((n) => n.type == NoteType.photo).length, 6);
    expect(c.linksOn(board.id).length, 5);
    expect(c.linksOn(board.id).first.style, pack.thread);
  });

  testWidgets('the sheet picks a layout and a free look', (tester) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    (MemoryLayout, ThemePack)? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(fontChoices.first),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async =>
                    picked = await showMemoryWallSheet(context, count: 24),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('first 20'), findsOneWidget);
    await tester.tap(find.text('Timeline'));
    await tester.pump();
    await tester.tap(find.text('Make the wall'));
    await tester.pumpAndSettle();
    expect(picked?.$1, MemoryLayout.timeline);
    // Without Pro the look falls back to a free one.
    expect(picked?.$2.pro, isFalse);
  });
}

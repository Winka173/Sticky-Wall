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
    MemoryWallChoice? picked;
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
    await tester.ensureVisible(find.text('Make the wall'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make the wall'));
    await tester.pumpAndSettle();
    expect(picked?.layout, MemoryLayout.timeline);
    expect(picked?.frame, PhotoFrame.polaroid);
    // Without Pro the look falls back to a free one.
    expect(picked?.look.pro, isFalse);
  });

  test('shuffle, hero and frames move only the prints, and undo', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveBoards([Board(id: 'default', name: '')]);
    await storage.saveNotes([]);
    final c = NotesController(storage, ReminderService());
    final board = c.addMemoryWall(
      'Trip',
      _photos(6),
      MemoryLayout.prints,
      frame: PhotoFrame.film,
      caption: CaptionPreset.numbers,
    );
    final prints = c.printsOn(board.id);
    expect(prints.map((n) => n.content), ['1', '2', '3', '4', '5', '6']);
    expect(prints.every((n) => n.frame == PhotoFrame.film), isTrue);
    final title = c.boardNotes.firstWhere((n) => n.type == NoteType.label);
    final before = [for (final n in prints) (n.x, n.y)];

    // The same seed lays the same wall out.
    final undo = c.rearrangePrints(board.id, seed: 'a');
    final first = [for (final n in c.printsOn(board.id)) (n.x, n.y)];
    undo();
    expect([for (final n in prints) (n.x, n.y)], before);
    c.rearrangePrints(board.id, seed: 'a');
    expect([for (final n in c.printsOn(board.id)) (n.x, n.y)], first);
    expect((title.x, title.y), (0.5, 0.0), reason: 'the title stays');
    expect(prints.map((n) => n.content).toSet(), {
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
    });
    for (final n in prints) {
      expect(n.x, inInclusiveRange(0, 1));
      expect(n.y, inInclusiveRange(0, 1));
    }

    final hero = prints[3];
    c.rearrangePrints(board.id, hero: hero.guid);
    expect(hero.scale, greaterThan(prints[0].scale));
    expect(hero.x, 0.5);

    final undoFrames = c.setFrames(prints, PhotoFrame.torn);
    expect(prints.every((n) => n.frame == PhotoFrame.torn), isTrue);
    undoFrames();
    expect(prints.every((n) => n.frame == PhotoFrame.film), isTrue);

    // Frames survive a save and a load.
    final reloaded = Note.fromJson(prints.first.toJson());
    expect(reloaded.frame, PhotoFrame.film);
    expect(
      Note.fromJson({...prints.first.toJson(), 'frame': 'hologram'}).frame,
      PhotoFrame.print,
    );
  });
}

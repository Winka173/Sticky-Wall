// Rough timings for big walls in the test environment (not a device: no GPU,
// no real frame clock). They catch work that grows badly with the number
// of notes; the device numbers come from a profile build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';

List<Note> _notes(int n) => [
  for (var i = 0; i < n; i++)
    Note(
      guid: 'n$i',
      content: i.isEven ? 'Note number $i' : 'Ghi chú số $i, có dấu',
      type: i % 7 == 0 ? NoteType.checklist : NoteType.normal,
      checklist: i % 7 == 0
          ? [ChecklistItem(text: 'a'), ChecklistItem(text: 'b', done: true)]
          : null,
      createdAt: DateTime(2026).add(Duration(minutes: i)),
      boardId: 'default',
      colorIndex: i % 6,
      x: (i * 37 % 100) / 100,
      y: (i * 53 % 100) / 100,
    ),
];

void main() {
  for (final n in [50, 200, 500]) {
    testWidgets('a wall of $n notes opens, drags and searches', (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveBoards([Board(id: 'default', name: '')]);
      await storage.saveNotes(_notes(n));
      await storage.setViewMode(ViewMode.wall);
      final notes = NotesController(storage, ReminderService());

      final open = Stopwatch()..start();
      await tester.pumpWidget(
        StickyWallApp(settings: SettingsController(storage), notes: notes),
      );
      await tester.pump();
      open.stop();

      final drag = Stopwatch()..start();
      final g = await tester.startGesture(const Offset(200, 900));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(4, 3));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump();
      drag.stop();

      final search = Stopwatch()..start();
      notes.search = 'co dau';
      await tester.pump();
      search.stop();
      expect(notes.visibleNotes, isNotEmpty);

      final grid = Stopwatch()..start();
      notes
        ..search = ''
        ..viewMode = ViewMode.grid;
      await tester.pump();
      grid.stop();

      debugPrint(
        'PERF n=$n open=${open.elapsedMilliseconds}ms '
        'drag10=${drag.elapsedMilliseconds}ms '
        'search=${search.elapsedMilliseconds}ms '
        'grid=${grid.elapsedMilliseconds}ms',
      );
      // Generous: this only fails when something grows out of hand.
      expect(open.elapsedMilliseconds, lessThan(20000));
      expect(drag.elapsedMilliseconds, lessThan(20000));
      await tester.pumpWidget(const SizedBox());
    });
  }
}

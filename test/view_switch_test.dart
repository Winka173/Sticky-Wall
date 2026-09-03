import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

Future<(StickyWallApp, NotesController)> _app(ViewMode mode) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes([
    Note(guid: 'a', content: 'one', createdAt: _epoch, boardId: 'default'),
    Note(guid: 'b', content: 'two', createdAt: _epoch, boardId: 'default'),
  ]);
  await storage.setViewMode(mode);
  final notes = NotesController(storage, ReminderService());
  return (
    StickyWallApp(settings: SettingsController(storage), notes: notes),
    notes,
  );
}

void main() {
  for (final (from, to) in [
    (ViewMode.grid, ViewMode.list),
    (ViewMode.list, ViewMode.wall),
    (ViewMode.wall, ViewMode.grid),
  ]) {
    testWidgets('switching $from -> $to mid-transition does not throw', (
      tester,
    ) async {
      final (app, notes) = await _app(from);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      notes.viewMode = to;
      // Mid-transition frames: old and new content coexist.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('one'), findsOneWidget);
    });
  }
}

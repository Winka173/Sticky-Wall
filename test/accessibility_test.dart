import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/add_note_button.dart';

/// Flutter's own accessibility guidelines on the main screens: tap targets
/// big enough for a thumb, and every tappable thing named for a screen
/// reader. (A real TalkBack session is still needed on a device.)
void main() {
  Future<void> pump(WidgetTester tester, ViewMode mode) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveNotes([
      for (var i = 0; i < 4; i++)
        Note(
          guid: '$i',
          content: 'Note $i',
          createdAt: DateTime(2026),
          boardId: 'default',
          x: (i % 2) * 0.6,
          y: (i ~/ 2) * 0.5,
        ),
    ]);
    await storage.setViewMode(mode);
    await tester.pumpWidget(
      StickyWallApp(
        settings: SettingsController(storage),
        notes: NotesController(storage, ReminderService()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode in ViewMode.values) {
    testWidgets('home ($mode): tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, mode);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('the editor: tap targets and labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, ViewMode.grid);
    await tester.tap(find.byType(AddNoteButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-normal')));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}

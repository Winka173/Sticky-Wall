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

void main() {
  Future<NotesController> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.setViewMode(ViewMode.wall);
    await storage.setWelcomePending(false);
    await storage.saveNotes([
      Note(
        guid: 'open',
        content: 'Open immediately',
        createdAt: DateTime(2026),
        boardId: 'default',
        x: .1,
        y: .15,
      ),
      Note(
        guid: 'check',
        type: NoteType.checklist,
        content: 'List',
        checklist: [ChecklistItem(text: 'Check immediately')],
        createdAt: DateTime(2026),
        boardId: 'default',
        x: .7,
        y: .5,
      ),
    ]);
    final notes = NotesController(storage, ReminderService());
    await tester.pumpWidget(
      StickyWallApp(notes: notes, settings: SettingsController(storage)),
    );
    await tester.pumpAndSettle();
    return notes;
  }

  testWidgets('note tap latency', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Open immediately'));
    var ms = 0;
    await tester.pump();
    while (find.byType(TextField).evaluate().isEmpty && ms < 500) {
      await tester.pump(const Duration(milliseconds: 16));
      ms += 16;
    }
    debugPrint('NOTE_TAP_CALLBACK_MS=$ms');
    expect(
      ms,
      0,
      reason: 'Open on the first frame; do not wait for a double tap',
    );
    expect(find.byType(TextField), findsWidgets);
    await tester.pumpAndSettle();
  });

  testWidgets('checkbox tap latency', (tester) async {
    final notes = await pump(tester);
    final item = notes.allNotes
        .firstWhere((n) => n.guid == 'check')
        .checklist
        .first;
    await tester.tap(find.text('Check immediately'));
    var ms = 0;
    await tester.pump();
    while (!item.done && ms < 500) {
      await tester.pump(const Duration(milliseconds: 16));
      ms += 16;
    }
    debugPrint('CHECKBOX_TAP_CALLBACK_MS=$ms');
    expect(ms, 0, reason: 'Checklist must change on the first frame after tap');
    expect(item.done, isTrue);
    await tester.pumpAndSettle();
  });
}

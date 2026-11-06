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

/// A message with Undo shows once and closes by itself (newer Flutter keeps
/// a snackbar with an action open until tapped unless told otherwise).
void main() {
  testWidgets('an Undo message closes by itself', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveBoards([
      Board(id: 'default', name: ''),
      Board(id: 'work', name: 'Work'),
    ]);
    await storage.saveNotes([
      Note(
        guid: '1',
        content: 'Bin me',
        createdAt: DateTime(2026),
        boardId: 'default',
      ),
    ]);
    await storage.setViewMode(ViewMode.grid);
    final notes = NotesController(storage, ReminderService());
    await tester.pumpWidget(
      StickyWallApp(settings: SettingsController(storage), notes: notes),
    );
    await tester.pumpAndSettle();

    // Delete a note from its sheet: "moved to the trash" with Undo.
    await tester.longPress(find.text('Bin me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SnackBarAction, 'Undo'), findsNothing);
  });
}

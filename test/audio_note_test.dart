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
import 'package:sticky_wall/widgets/audio_note.dart';
import 'package:sticky_wall/widgets/note_views.dart';

Note _voice({String title = 'Grocery ideas'}) => Note(
  guid: 'v',
  content: title,
  createdAt: DateTime(2026),
  boardId: 'default',
  type: NoteType.audio,
  audioPath: 'voice_1.m4a',
  audioMs: 42000,
  x: 0.2,
  y: 0.2,
);

Future<void> _pumpApp(
  WidgetTester tester,
  ViewMode mode, {
  List<Note>? notes,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes(notes ?? [_voice()]);
  await storage.setViewMode(mode);
  await tester.pumpWidget(
    StickyWallApp(
      settings: SettingsController(storage),
      notes: NotesController(storage, ReminderService()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final mode in [ViewMode.wall, ViewMode.grid]) {
    testWidgets('a voice note is a cassette with its title and play ($mode)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpApp(tester, mode);
      final card = find.byType(StickyNoteCard);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('Grocery ideas')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('0:42')),
        findsOneWidget,
      );
      final play = find.descendant(
        of: card,
        matching: find.byType(VoicePlayButton),
      );
      expect(play, findsOneWidget);
      expect(find.bySemanticsLabel('Play voice note'), findsOneWidget);
      // A finger-sized target.
      final size = tester.getSize(play);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('an untitled one is named by its type; lists get a play too', (
    tester,
  ) async {
    await _pumpApp(tester, ViewMode.list, notes: [_voice(title: '')]);
    expect(find.byType(NoteListTile), findsOneWidget);
    expect(find.text('Voice note · 0:42'), findsOneWidget);
    expect(find.byType(VoicePlayButton), findsOneWidget);
  });

  testWidgets('the editor offers play, record again and delete', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester, ViewMode.grid);
    await tester.tap(find.text('Grocery ideas'));
    await tester.pumpAndSettle();
    expect(find.byType(VoiceRecorderPanel), findsOneWidget);
    expect(find.text('Record again'), findsOneWidget);
    expect(find.text('Delete recording'), findsOneWidget);

    // Deleting leaves the microphone, and Save then asks for a recording.
    await tester.tap(find.text('Delete recording'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Start recording'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('Record something first'), findsOneWidget);
    semantics.dispose();
  });
}

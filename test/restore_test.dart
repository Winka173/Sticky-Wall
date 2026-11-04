import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/backup_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/restore_preview.dart';

Note _note(String id, String board, {String text = '', DateTime? deleted}) =>
    Note(
      guid: id,
      content: text.isEmpty ? id : text,
      createdAt: DateTime(2026),
      boardId: board,
      deletedAt: deleted,
    );

Future<NotesController> _here() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([Board(id: 'default', name: 'Home')]);
  await storage.saveNotes([_note('a', 'default', text: 'Mine')]);
  return NotesController(storage, ReminderService());
}

String _backupJson() => BackupService().encode(
  [
    Board(id: 'default', name: 'Home'),
    Board(id: 'trip', name: 'Trip', isPrivate: true),
  ],
  [
    _note('a', 'default', text: 'Older copy of mine'),
    _note('b', 'default'),
    _note('c', 'trip'),
    _note('d', 'trip', deleted: DateTime(2026, 2)),
    Note(
      guid: 's',
      content: '',
      type: NoteType.sticker,
      sticker: 'star',
      createdAt: DateTime(2026),
      boardId: 'trip',
    ),
  ],
  const [NoteLink('b', 'c'), NoteLink('a', 'b')],
);

void main() {
  test('a decoded backup says when, how big and which version', () {
    final source = _backupJson();
    final backup = BackupService().decode(source);
    expect(backup.version, 2);
    expect(backup.exportedAt, isNotNull);
    expect(backup.sizeBytes, source.length);
  });

  test('merging keeps what is here and adds the rest, once', () async {
    final c = await _here();
    final backup = BackupService().decode(_backupJson());
    final overlap = c.backupOverlap(backup.boards, backup.notes);
    expect(overlap, (boards: 1, notes: 1));

    c.mergeAll(backup.boards, backup.notes, links: backup.links);
    expect(c.boards.map((b) => b.id), ['default', 'trip']);
    expect(
      c.allNotes.firstWhere((n) => n.guid == 'a').content,
      'Mine',
      reason: 'a note already here is not overwritten',
    );
    expect(c.allNotes.map((n) => n.guid).toSet(), {'a', 'b', 'c', 'd', 's'});
    expect(c.links.length, 2);

    // The same backup again adds nothing.
    final again = BackupService().decode(_backupJson());
    c.mergeAll(again.boards, again.notes, links: again.links);
    expect(c.allNotes.length, 5);
    expect(c.boards.length, 2);
    expect(c.links.length, 2);
  });

  testWidgets('the preview counts what the backup holds before anything '
      'changes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final c = await _here();
    final backup = BackupService().decode(_backupJson());
    RestoreMode? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(fontChoices.first),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await showRestorePreview(
                context,
                backup: backup,
                notes: c,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Restore a backup'), findsOneWidget);
    expect(find.text('4 · 1 in the trash'), findsOneWidget);
    expect(
      find.textContaining('1 boards and 1 notes in it are already'),
      findsOneWidget,
    );
    expect(c.allNotes.length, 1, reason: 'nothing changes in the preview');
    await tester.tap(find.text('Add to what is here'));
    await tester.pumpAndSettle();
    expect(picked, RestoreMode.merge);
  });
}

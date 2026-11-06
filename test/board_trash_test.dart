import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/draw_stroke.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/backup_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';

/// A whole board goes to the Trash with everything on it and comes back
/// intact; files are only ever deleted when nothing (live, in the note
/// Trash or on a board in the Trash) still uses them.
void main() {
  late NoteStorage storage;
  late List<String> deletedPhotos;
  late List<String> deletedAudio;
  late List<String> deletedWalls;

  NotesController open() => NotesController(
    storage,
    ReminderService(),
    deletePhoto: deletedPhotos.add,
    deleteAudio: deletedAudio.add,
    deleteWallImage: deletedWalls.add,
  );

  Note note(
    String guid,
    String board, {
    NoteType type = NoteType.normal,
    String image = '',
    String audio = '',
    String content = '',
    DateTime? deletedAt,
  }) => Note(
    guid: guid,
    content: content.isEmpty ? guid : content,
    type: type,
    imagePath: image,
    audioPath: audio,
    createdAt: DateTime(2026),
    boardId: board,
    deletedAt: deletedAt,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await NoteStorage.create();
    deletedPhotos = [];
    deletedAudio = [];
    deletedWalls = [];
    await storage.saveBoards([
      Board(id: 'home', name: 'Home'),
      Board(
        id: 'trip',
        name: 'Trip',
        icon: '🏖️',
        wallIndex: 3,
        wallImage: 'beach.jpg',
        themeId: 'seaside',
        isPrivate: false,
        strokes: [
          DrawStroke(
            color: 0xFF000000,
            width: 3,
            points: const [Offset(0.1, 0.1), Offset(0.2, 0.2)],
          ),
        ],
      ),
      Board(id: 'work', name: 'Work'),
    ]);
    await storage.saveNotes([
      note('h1', 'home', content: 'stays home'),
      note('t1', 'trip', content: 'pack sunscreen'),
      note('t2', 'trip', type: NoteType.photo, image: 'sea.jpg'),
      note('t3', 'trip', type: NoteType.audio, audio: 'waves.m4a'),
      note('t4', 'trip', type: NoteType.checklist),
      // Already in the note Trash before the board went.
      note('t5', 'trip', content: 'old idea', deletedAt: DateTime.now()),
      // The same photo pinned on another board too.
      note('w1', 'work', type: NoteType.photo, image: 'sea.jpg'),
    ]);
    await storage.saveLinks(const [NoteLink('t1', 't2', label: 'then')]);
  });

  test('deleting a board hides it with everything on it and deletes no '
      'file', () {
    final c = open()..selectBoard('trip');
    final undo = c.deleteBoard('trip');
    expect(undo, isNotNull);
    expect(c.boards.map((b) => b.id), ['home', 'work']);
    expect(c.currentBoardId, 'home', reason: 'the tab before it opens');
    expect(c.deletedBoards.single.id, 'trip');
    expect(c.noteCountOn('trip'), 5);
    expect(deletedPhotos, isEmpty);
    expect(deletedAudio, isEmpty);
    expect(deletedWalls, isEmpty);

    // Out of sight everywhere: search across boards and the note Trash.
    c.search = 'sunscreen';
    expect(c.otherBoardMatches, isEmpty);
    c.search = '';
    expect(c.trashed.map((n) => n.guid), isNot(contains('t5')));

    // Undo puts it straight back.
    undo!();
    expect(c.boards.map((b) => b.id), ['home', 'trip', 'work']);
    expect(c.deletedBoards, isEmpty);
  });

  test('a board in the Trash survives a restart and comes back whole', () {
    open().deleteBoard('trip');

    final c = open();
    expect(c.deletedBoards.single.name, 'Trip');
    c.restoreBoard('trip');

    expect(c.boards.map((b) => b.id), ['home', 'trip', 'work']);
    expect(c.currentBoardId, 'trip');
    final board = c.currentBoard;
    expect(board.icon, '🏖️');
    expect(board.wallIndex, 3);
    expect(board.wallImage, 'beach.jpg');
    expect(board.themeId, 'seaside');
    expect(board.strokes.single.points.length, 2);
    expect(board.deletedAt, isNull);
    expect(c.boardNotes.map((n) => n.guid).toSet(), {'t1', 't2', 't3', 't4'});
    expect(c.trashed.map((n) => n.guid), contains('t5'));
    expect(c.links.single.label, 'then');

    // And it is still all there after another restart.
    final again = open()..selectBoard('trip');
    expect(again.deletedBoards, isEmpty);
    expect(again.boardNotes.length, 4);
  });

  test('after 30 days the board goes for good, taking only the files '
      'nothing else uses', () async {
    open().deleteBoard('trip');
    final stored = storage.loadDeletedBoards()
      ..single.deletedAt = DateTime.now().subtract(const Duration(days: 31));
    await storage.saveDeletedBoards(stored);

    final c = open();
    expect(c.deletedBoards, isEmpty);
    expect(c.allNotes.map((n) => n.guid).toSet(), {'h1', 'w1'});
    expect(c.links, isEmpty);
    expect(deletedAudio, ['waves.m4a']);
    expect(deletedWalls, ['beach.jpg']);
    expect(
      deletedPhotos,
      isNot(contains('sea.jpg')),
      reason: 'the Work board still shows that photo',
    );
  });

  test('a clock set back never shortens the 30 days', () async {
    open().deleteBoard('trip');
    final stored = storage.loadDeletedBoards()
      ..single.deletedAt = DateTime.now().add(const Duration(days: 400));
    await storage.saveDeletedBoards(stored);

    final c = open();
    expect(c.deletedBoards.single.id, 'trip');
    expect(c.boardDaysLeft(c.deletedBoards.single), greaterThan(0));
  });

  test('Empty Trash and Delete forever take boards too', () {
    final c = open()
      ..deleteBoard('trip')
      ..deleteBoard('work');
    c.deleteBoardForever('work');
    expect(c.deletedBoards.single.id, 'trip');
    expect(deletedPhotos, isEmpty, reason: 'sea.jpg is still on Trip');
    c.emptyTrash();
    expect(c.deletedBoards, isEmpty);
    expect(c.allNotes.map((n) => n.guid), ['h1']);
    expect(deletedPhotos, ['sea.jpg']);
  });

  test('the last board in use cannot be deleted', () {
    final c = open()
      ..deleteBoard('trip')
      ..deleteBoard('work');
    expect(c.deleteBoard('home'), isNull);
    expect(c.boards.single.id, 'home');
  });

  test('an import with the same board id never takes over a board in the '
      'Trash', () {
    final c = open()..deleteBoard('trip');
    // An import brings a different board that happens to use the same id.
    c.mergeAll([Board(id: 'trip', name: 'Imported')], [note('i1', 'trip')]);
    expect(c.boards.where((b) => b.id == 'trip').single.name, 'Imported');
    expect(c.noteCountOn('trip'), 1, reason: 'only the imported note');
    final inTrash = c.deletedBoards.single;
    expect(inTrash.id, isNot('trip'));
    expect(c.noteCountOn(inTrash.id), 5);

    c.restoreBoard(inTrash.id);
    expect(c.boards.map((b) => b.name), ['Home', 'Trip', 'Work', 'Imported']);
    expect(c.noteCountOn(inTrash.id), 5);
  });

  test('a board that was never deleted cannot be restored twice', () {
    final c = open();
    c.restoreBoard('trip');
    expect(c.boards.length, 3);
    final undo = c.deleteBoard('trip')!;
    undo();
    undo();
    expect(c.boards.where((b) => b.id == 'trip'), hasLength(1));
  });

  test('a backup carries the boards in the Trash and Replace brings them '
      'back', () {
    final c = open()..deleteBoard('trip');
    final doc = BackupService().encode(
      c.boards,
      c.allNotes,
      c.links,
      const {},
      const {},
      const {},
      c.deletedBoards,
    );
    final backup = BackupService().decode(doc);
    expect(backup.deletedBoards.single.id, 'trip');

    c.replaceAll(
      [Board(id: 'x', name: 'Fresh')],
      [],
      links: const [],
    );
    expect(c.deletedBoards, isEmpty);
    c.replaceAll(
      backup.boards,
      backup.notes,
      links: backup.links,
      deletedBoards: backup.deletedBoards,
    );
    expect(c.deletedBoards.single.name, 'Trip');
    c.restoreBoard('trip');
    expect(c.noteCountOn('trip'), 5);
  });

  test('a damaged or oversized file in a backup is counted, not hidden', () {
    final doc = BackupService().decode(
      '{"version":2,"boards":[{"id":"a","name":""}],"notes":[],'
      '"photos":{"good.jpg":"AQID","bad.jpg":"%%% not base64"}}',
    );
    expect(doc.photos.keys, ['good.jpg']);
    expect(doc.omittedFiles, 1);
  });

  test('a backup with absurd record counts is refused up front', () {
    final notes = List.filled(BackupService.maxNotes + 1, '{}').join(',');
    expect(
      () => BackupService().decode(
        '{"version":2,"boards":[{"id":"a","name":""}],"notes":[$notes]}',
      ),
      throwsA(
        isA<BackupFormatException>().having(
          (e) => e.problem,
          'problem',
          BackupProblem.tooLarge,
        ),
      ),
    );
  });
}

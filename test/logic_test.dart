import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/util/stable_hash.dart';
import 'package:sticky_wall/util/text_fold.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

Note _note(
  String guid,
  String content, {
  String url = '',
  String board = 'default',
  String image = '',
  NoteType? type,
  DateTime? createdAt,
}) =>
    Note(
      guid: guid,
      content: content,
      url: url,
      type: type,
      imagePath: image,
      createdAt: createdAt ?? _epoch,
      boardId: board,
    );

Future<NotesController> _controller({List<Note> notes = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes(notes);
  return NotesController(storage, ReminderService());
}

void main() {
  group('foldText / search', () {
    test('strips Vietnamese diacritics and case', () {
      expect(foldText('Tưới Cây Đúng giờ'), 'tuoi cay dung gio');
    });

    test('matches ignores accents on either side', () async {
      final c = await _controller(notes: [
        _note('1', 'Tưới cây'),
        _note('2', 'Đi chợ', type: NoteType.checklist),
      ]);
      c.search = 'tuoi';
      expect(c.visibleNotes.map((n) => n.guid), ['1']);
      c.search = 'ĐI';
      expect(c.visibleNotes.map((n) => n.guid), ['2']);
      c.search = '';
      c.typeFilter = 2;
      expect(c.visibleNotes.map((n) => n.guid), ['2']);
      expect(c.isFiltering, true);
    });
  });

  group('NotesController', () {
    test('setSort orders by date or title in both directions', () async {
      final c = await _controller(notes: [
        _note('a', 'banana', createdAt: DateTime(2026, 1, 2)),
        _note('b', 'apple', createdAt: DateTime(2026, 1, 3)),
        _note('c', 'cherry', createdAt: DateTime(2026, 1, 1)),
      ]);
      c.setSort(byCreated: true, ascending: false);
      expect(c.visibleNotes.map((n) => n.guid), ['b', 'a', 'c']);
      c.setSort(byCreated: true, ascending: true);
      expect(c.visibleNotes.map((n) => n.guid), ['c', 'a', 'b']);
      c.setSort(byCreated: false, ascending: true);
      expect(c.visibleNotes.map((n) => n.guid), ['b', 'a', 'c']);
      c.setSort(byCreated: false, ascending: false);
      expect(c.visibleNotes.map((n) => n.guid), ['c', 'a', 'b']);
    });

    test('pinned notes always sort first', () async {
      final c = await _controller(notes: [
        _note('a', 'a', createdAt: DateTime(2026, 1, 3)),
        _note('b', 'b', createdAt: DateTime(2026, 1, 1)),
      ]);
      c.setSort(byCreated: true, ascending: false);
      c.togglePin(c.boardNotes.firstWhere((n) => n.guid == 'b'));
      expect(c.visibleNotes.first.guid, 'b');
    });

    test('moveToBoard changes board and recenters the note', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      final other = c.addBoard('Work');
      c.selectBoard('default');
      final note = c.boardNotes.single;
      c.moveToBoard(note, other.id);
      expect(c.boardNotes, isEmpty);
      c.selectBoard(other.id);
      expect(c.boardNotes.single.guid, '1');
      expect(c.boardNotes.single.x, closeTo(0.35, 1e-9));
    });

    test('moveToBoard ignores unknown boards', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      c.moveToBoard(c.boardNotes.single, 'nope');
      expect(c.boardNotes.single.boardId, 'default');
    });

    test('purgeDeleted returns the orphaned photo once undo has lapsed',
        () async {
      final c = await _controller(notes: [
        _note('1', 'x', image: 'p1.jpg'),
        _note('2', 'y', image: 'shared.jpg'),
        _note('3', 'z', image: 'shared.jpg'),
      ]);
      final n1 = c.boardNotes[0];
      final n2 = c.boardNotes[1];

      c.delete(n1);
      c.delete(n2); // a second delete must not lose the first orphan
      expect(c.purgeDeleted(n1), 'p1.jpg');
      // Still shown by note 3 — must not be removed from disk.
      expect(c.purgeDeleted(n2), isNull);
      expect(c.canUndo, false);
    });

    test('purgeDeleted returns null when the note was restored', () async {
      final c = await _controller(notes: [_note('1', 'x', image: 'p1.jpg')]);
      final n1 = c.boardNotes.single;
      c.delete(n1);
      c.undoDelete();
      expect(c.purgeDeleted(n1), isNull);
      expect(c.photoInUse('p1.jpg'), true);
    });

    test('deleteBoard removes its notes and keeps one board', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      final work = c.addBoard('Work');
      c.add(c.draft()..content = 'on work');
      expect(c.boardNotes.length, 1);
      c.deleteBoard(work.id);
      expect(c.boards.length, 1);
      expect(c.currentBoardId, 'default');
      expect(c.allNotes.length, 1);
      c.deleteBoard('default');
      expect(c.boards.length, 1);
    });
  });

  group('NoteStorage', () {
    test('skips a malformed record instead of dropping every note', () async {
      SharedPreferences.setMockInitialValues({
        'notes': jsonEncode([
          {'guid': 'ok', 'content': 'fine'},
          {'content': 'no guid'},
          {'guid': 'ok2', 'content': 'also fine', 'x': 'not a number'},
        ]),
      });
      final storage = await NoteStorage.create();
      expect(storage.loadNotes().map((n) => n.guid), ['ok']);
    });

    test('returns nothing for unparseable JSON', () async {
      SharedPreferences.setMockInitialValues({'notes': '{not json'});
      final storage = await NoteStorage.create();
      expect(storage.loadNotes(), isEmpty);
    });
  });

  group('ImageService.resolve', () {
    tearDown(() => ImageService.docsDirForTest = null);

    test('rebuilds the path from a bare name or a stale absolute path', () {
      ImageService.docsDirForTest = '/docs';
      expect(ImageService.resolve('a.jpg'), '/docs/note_images/a.jpg');
      expect(ImageService.resolve('/old/container/note_images/a.jpg'),
          '/docs/note_images/a.jpg');
      expect(ImageService.resolve(r'C:\old\note_images\a.jpg'),
          '/docs/note_images/a.jpg');
      expect(ImageService.resolve(''), '');
    });

    test('passes the reference through when no directory is known', () {
      expect(ImageService.resolve('a.jpg'), 'a.jpg');
    });
  });

  group('ReminderService.titleFor', () {
    test('uses content, then checklist items, then the app name', () {
      expect(ReminderService.titleFor(_note('1', '  Call mum  ')), 'Call mum');
      final list = _note('2', '', type: NoteType.checklist)
        ..checklist = [ChecklistItem(text: 'milk'), ChecklistItem(text: 'eggs')];
      expect(ReminderService.titleFor(list), 'milk, eggs');
      expect(ReminderService.titleFor(_note('3', '')), 'Sticky Wall');
      expect(ReminderService.titleFor(_note('4', 'Gym')..emoji = '💪'),
          '💪 Gym');
    });
  });

  test('stableHash is deterministic and non-negative', () {
    expect(stableHash('abc'), stableHash('abc'));
    expect(stableHash('abc'), isNot(stableHash('abd')));
    expect(stableHash('Ghi chú dài ' * 50), greaterThanOrEqualTo(0));
  });
}

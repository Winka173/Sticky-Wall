import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/share_service.dart';
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

Future<NotesController> _controller({
  List<Note> notes = const [],
  FileRemover? deletePhoto,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes(notes);
  return NotesController(storage, ReminderService(), deletePhoto: deletePhoto);
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
      // Dropped somewhere near the middle, not on top of the last one moved.
      expect(c.boardNotes.single.x, inInclusiveRange(0.25, 0.55));
      expect(c.boardNotes.single.y, inInclusiveRange(0.2, 0.5));
    });

    test('moveToBoard ignores unknown boards', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      c.moveToBoard(c.boardNotes.single, 'nope');
      expect(c.boardNotes.single.boardId, 'default');
    });

    test('delete moves to the trash; undo and restore bring it back',
        () async {
      final c = await _controller(notes: [_note('1', 'x'), _note('2', 'y')]);
      final n1 = c.boardNotes[0];
      final n2 = c.boardNotes[1];

      c.delete(n1);
      expect(c.boardNotes.map((n) => n.guid), ['2']);
      expect(c.trashed.map((n) => n.guid), ['1']);
      expect(c.trashCount, 1);
      expect(c.daysLeft(n1), NotesController.trashRetention.inDays);
      expect(c.canUndo, true);

      c.undoDelete();
      expect(c.trashed, isEmpty);
      expect(c.canUndo, false);
      expect(c.boardNotes.length, 2);

      c.trashAll([n1, n2]);
      expect(c.boardNotes, isEmpty);
      c.restore(n2);
      expect(c.boardNotes.map((n) => n.guid), ['2']);
      expect(c.trashed.map((n) => n.guid), ['1']);
    });

    test('purge removes the note and its orphaned photo only', () async {
      final removed = <String>[];
      final c = await _controller(
        notes: [
          _note('1', 'x', image: 'p1.jpg'),
          _note('2', 'y', image: 'shared.jpg'),
          _note('3', 'z', image: 'shared.jpg'),
        ],
        deletePhoto: removed.add,
      );
      final n1 = c.boardNotes[0];
      final n2 = c.boardNotes[1];

      c.trashAll([n1, n2]);
      c.purge(n1);
      expect(removed, ['p1.jpg']);
      c.emptyTrash();
      // shared.jpg is still shown by note 3 — must stay on disk.
      expect(removed, ['p1.jpg']);
      expect(c.allNotes.map((n) => n.guid), ['3']);
      expect(c.canUndo, false);
    });

    test('notes older than the retention are purged on load', () async {
      final removed = <String>[];
      final old = _note('old', 'x', image: 'old.jpg')
        ..deletedAt = DateTime.now().subtract(const Duration(days: 31));
      final fresh = _note('fresh', 'y')
        ..deletedAt = DateTime.now().subtract(const Duration(days: 2));
      final c = await _controller(
          notes: [old, fresh, _note('live', 'z')], deletePhoto: removed.add);
      expect(c.allNotes.map((n) => n.guid), ['fresh', 'live']);
      expect(c.trashed.single.guid, 'fresh');
      expect(c.daysLeft(c.trashed.single), 28);
      expect(removed, ['old.jpg']);
    });

    test('deleteBoard purges its trashed notes too', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      final work = c.addBoard('Work');
      final note = c.allNotes.single;
      c.moveToBoard(note, work.id);
      c.delete(note);
      expect(c.trashed.single.guid, '1');
      c.deleteBoard(work.id);
      expect(c.allNotes, isEmpty);
      expect(c.canUndo, false);
    });

    test('restore falls back to the first board when its board is gone',
        () async {
      final c = await _controller(
          notes: [_note('1', 'x', board: 'gone')..deletedAt = DateTime.now()]);
      final note = c.trashed.single;
      c.restore(note);
      expect(note.boardId, 'default');
      expect(c.boardNotes.single.guid, '1');
    });

    test('bulk actions: pinAll, recolor, moveAllToBoard', () async {
      final c = await _controller(
          notes: [_note('1', 'x'), _note('2', 'y'), _note('3', 'z')]);
      final all = c.boardNotes;
      c.pinAll(all, true);
      expect(all.every((n) => n.pinned), true);
      c.recolor(all, 4);
      expect(all.every((n) => n.colorIndex == 4), true);
      c.recolor(all, null);
      expect(all.every((n) => n.colorIndex == null), true);
      final work = c.addBoard('Work');
      c.selectBoard('default');
      c.moveAllToBoard(all.take(2).toList(), work.id);
      expect(c.boardNotes.map((n) => n.guid), ['3']);
      c.selectBoard(work.id);
      expect(c.boardNotes.map((n) => n.guid), ['1', '2']);
    });

    test('reorderBoards moves a tab to its final index', () async {
      final c = await _controller();
      c.addBoard('B');
      c.addBoard('C');
      c.reorderBoards(0, 2);
      expect(c.boards.map((b) => b.name), ['B', 'C', '']);
      c.reorderBoards(2, 0);
      expect(c.boards.map((b) => b.name), ['', 'B', 'C']);
      c.reorderBoards(5, 0); // out of range: ignored
      expect(c.boards.map((b) => b.name), ['', 'B', 'C']);
    });

    test('arrange clamps positions and scale', () async {
      final c = await _controller(notes: [_note('1', 'x'), _note('2', 'y')]);
      final notes = c.boardNotes;
      c.arrange([(notes[0], -0.2, 0.3, 0.1), (notes[1], 0.4, 1.7, 9)]);
      expect(notes[0].x, 0);
      expect(notes[0].scale, 0.5);
      expect(notes[1].y, 1);
      expect(notes[1].scale, 3);
    });

    test('a finished checklist is stamped and swept after a day', () async {
      final c = await _controller(notes: [
        _note('1', 'list', type: NoteType.checklist)
          ..checklist = [ChecklistItem(text: 'a'), ChecklistItem(text: 'b')],
      ]);
      final note = c.boardNotes.single;
      c.toggleChecklistItem(note, 0);
      expect(note.completedAt, isNull);
      c.toggleChecklistItem(note, 1);
      expect(note.completedAt, isNotNull);
      c.toggleChecklistItem(note, 1);
      expect(note.completedAt, isNull);

      c.toggleChecklistItem(note, 1);
      c.sweepCompleted();
      expect(c.trashed, isEmpty, reason: 'only just finished');
      note.completedAt = DateTime.now().subtract(const Duration(days: 2));
      c.sweepCompleted();
      expect(c.trashed.single.guid, '1');
    });
  });

  group('threads', () {
    test('connect / disconnect / linksOn', () async {
      final c = await _controller(
          notes: [_note('1', 'x'), _note('2', 'y'), _note('3', 'z')]);
      expect(c.connect('1', '2'), true);
      expect(c.connect('2', '1'), false, reason: 'already tied');
      expect(c.connect('1', '1'), false, reason: 'no self-loops');
      expect(c.connect('1', 'ghost'), false, reason: 'unknown note');
      expect(c.isLinked('2', '1'), true);
      expect(c.linksOn('default').length, 1);

      // A thread only shows on a board that has both ends.
      final work = c.addBoard('Work');
      c.moveToBoard(c.allNotes.firstWhere((n) => n.guid == '2'), work.id);
      expect(c.linksOn('default'), isEmpty);
      expect(c.linksOn(work.id), isEmpty);
      expect(c.links.length, 1, reason: 'the tie itself survives the move');

      c.disconnect(c.links.single);
      expect(c.links, isEmpty);
    });

    test('purging a note cuts its threads; trashing keeps them', () async {
      final c = await _controller(
          notes: [_note('1', 'x'), _note('2', 'y'), _note('3', 'z')]);
      c.connect('1', '2');
      c.connect('2', '3');
      final n2 = c.boardNotes[1];
      c.delete(n2);
      expect(c.links.length, 2);
      expect(c.linksOn('default'), isEmpty, reason: 'trashed end is hidden');
      c.undoDelete();
      expect(c.linksOn('default').length, 2);
      c.delete(n2);
      c.purge(n2);
      expect(c.links, isEmpty);
    });

    test('links survive a reload and replaceAll drops dangling ones',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveNotes([_note('1', 'x'), _note('2', 'y')]);
      NotesController(storage, ReminderService()).connect('1', '2');

      final again = NotesController(storage, ReminderService());
      expect(again.links.single.same('1', '2'), true);

      again.replaceAll(again.boards, [_note('1', 'x')]);
      expect(again.links, isEmpty);
    });
  });

  group('first run', () {
    test('isFirstRun is only true before anything was saved', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      expect(storage.isFirstRun, true);
      NotesController(storage, ReminderService());
      expect(storage.isFirstRun, false, reason: 'the default board was saved');
    });

    test('seed places notes and threads on the current board', () async {
      final c = await _controller();
      c.seed([_note('a', 'A'), _note('b', 'B')], links: [NoteLink('a', 'b')]);
      expect(c.boardNotes.length, 2);
      expect(c.linksOn('default').length, 1);
    });
  });

  group('Note.nextReminder', () {
    final first = DateTime(2026, 1, 15, 9, 30);

    test('one-off reminders are returned as they are', () {
      final n = _note('1', 'x')..reminderAt = first;
      expect(n.nextReminder(DateTime(2027)), first);
    });

    test('daily / weekly advance to the first occurrence after now', () {
      final daily = _note('1', 'x')
        ..reminderAt = first
        ..repeat = ReminderRepeat.daily;
      expect(daily.nextReminder(DateTime(2026, 1, 20, 12)),
          DateTime(2026, 1, 21, 9, 30));
      expect(daily.nextReminder(DateTime(2026, 1, 20, 8)),
          DateTime(2026, 1, 20, 9, 30));

      final weekly = _note('2', 'x')
        ..reminderAt = first // a Thursday
        ..repeat = ReminderRepeat.weekly;
      final next = weekly.nextReminder(DateTime(2026, 2, 1))!;
      expect(next.weekday, first.weekday);
      expect(next, DateTime(2026, 2, 5, 9, 30));
    });

    test('monthly keeps the day of month and the time', () {
      final monthly = _note('1', 'x')
        ..reminderAt = DateTime(2026, 1, 31, 8)
        ..repeat = ReminderRepeat.monthly;
      // February has no 31st: Dart rolls over, so the reminder lands early
      // March rather than being lost.
      final next = monthly.nextReminder(DateTime(2026, 2, 1))!;
      expect(next.isAfter(DateTime(2026, 2, 1)), true);
      expect(next.hour, 8);
      expect(monthly.nextReminder(DateTime(2026, 4, 1)),
          DateTime(2026, 5, 1, 8)); // Apr 31 → May 1
    });

    test('round-trips repeat / deletedAt / completedAt through JSON', () {
      final n = _note('1', 'x')
        ..reminderAt = first
        ..repeat = ReminderRepeat.weekly
        ..deletedAt = DateTime(2026, 3, 1)
        ..completedAt = DateTime(2026, 2, 1);
      final back = Note.fromJson(
          jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>);
      expect(back.repeat, ReminderRepeat.weekly);
      expect(back.deletedAt, DateTime(2026, 3, 1));
      expect(back.completedAt, DateTime(2026, 2, 1));
      expect(back.isTrashed, true);
    });
  });

  group('SharedContent.fromText', () {
    test('splits the first link from the surrounding text', () {
      final c = SharedContent.fromText(
          'Check this out https://example.com/a?b=1. Great read');
      expect(c.url, 'https://example.com/a?b=1');
      expect(c.text, 'Check this out Great read');
    });

    test('plain text has no url; blank text is empty', () {
      expect(SharedContent.fromText('  hello  ').text, 'hello');
      expect(SharedContent.fromText('hello').url, '');
      expect(SharedContent.fromText('   ').isEmpty, true);
    });
  });

  group('SettingsController night schedule', () {
    test('wraps past midnight and treats start == end as never', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsController(await NoteStorage.create());
      s.setNightMode(NightMode.schedule);
      s.setNightHours(start: 21, end: 6);
      expect(s.scheduledNightAt(DateTime(2026, 1, 1, 23)), true);
      expect(s.scheduledNightAt(DateTime(2026, 1, 1, 3)), true);
      expect(s.scheduledNightAt(DateTime(2026, 1, 1, 12)), false);
      s.setNightHours(start: 8, end: 8);
      expect(s.scheduledNightAt(DateTime(2026, 1, 1, 8)), false);
      s.setNightMode(NightMode.on);
      expect(s.themeMode, ThemeMode.dark);
      s.setNightMode(NightMode.off);
      expect(s.themeMode, ThemeMode.light);
      s.setNightMode(NightMode.system);
      expect(s.themeMode, ThemeMode.system);
      s.dispose();
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

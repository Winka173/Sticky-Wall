import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/draw_stroke.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/share_service.dart';
import 'package:sticky_wall/theme.dart';
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
}) => Note(
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
      final c = await _controller(
        notes: [
          _note('1', '**Tưới** cây'),
          _note('2', 'Đi chợ', type: NoteType.checklist),
        ],
      );
      c.search = 'tuoi cay';
      expect(
        c.visibleNotes.map((n) => n.guid),
        ['1'],
        reason: 'the bold markers do not split the words',
      );
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
      final c = await _controller(
        notes: [
          _note('a', 'banana', createdAt: DateTime(2026, 1, 2)),
          _note('b', 'apple', createdAt: DateTime(2026, 1, 3)),
          _note('c', 'cherry', createdAt: DateTime(2026, 1, 1)),
        ],
      );
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
      final c = await _controller(
        notes: [
          _note('a', 'a', createdAt: DateTime(2026, 1, 3)),
          _note('b', 'b', createdAt: DateTime(2026, 1, 1)),
        ],
      );
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

    test('delete moves to the trash; undo and restore bring it back', () async {
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
        notes: [old, fresh, _note('live', 'z')],
        deletePhoto: removed.add,
      );
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

    test(
      'restore falls back to the first board when its board is gone',
      () async {
        final c = await _controller(
          notes: [_note('1', 'x', board: 'gone')..deletedAt = DateTime.now()],
        );
        final note = c.trashed.single;
        c.restore(note);
        expect(note.boardId, 'default');
        expect(c.boardNotes.single.guid, '1');
      },
    );

    test('bulk actions: pinAll, recolor, moveAllToBoard', () async {
      final c = await _controller(
        notes: [_note('1', 'x'), _note('2', 'y'), _note('3', 'z')],
      );
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

    test('a move may leave the home area, within the wall margin', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      final note = c.boardNotes.single;
      c.moveNote(note, 1.4, -0.3);
      expect(note.x, 1.4);
      expect(note.y, -0.3);
      c.moveNote(note, 5, -5);
      expect(note.x, 1 + NotesController.wallSpill);
      expect(note.y, -NotesController.wallSpill);
      c.moveNotes([(note, -9, 9)]);
      expect(note.x, -NotesController.wallSpill);
      expect(note.y, 1 + NotesController.wallSpill);
    });

    test('arrange clamps positions and scale, and squares notes up', () async {
      final c = await _controller(notes: [_note('1', 'x'), _note('2', 'y')]);
      final notes = c.boardNotes;
      c.rotateNote(notes[0], 1.2);
      c.arrange([(notes[0], -0.2, 0.3, 0.1), (notes[1], 0.4, 1.7, 9)]);
      expect(notes[0].x, 0);
      expect(notes[0].scale, 0.5);
      expect(notes[0].rotation, isNull, reason: 'tidy straightens');
      expect(notes[1].y, 1);
      expect(notes[1].scale, 3);
    });

    test(
      'rotateNote stores the turn in (-π, π] and null restores the tilt',
      () async {
        final c = await _controller(notes: [_note('1', 'x')]);
        final note = c.boardNotes.single;
        c.rotateNote(note, 0.4);
        expect(note.rotation, closeTo(0.4, 1e-9));
        c.rotateNote(note, 3 * math.pi + 0.5);
        expect(note.rotation, closeTo(-math.pi + 0.5, 1e-9));
        c.rotateNote(note, -math.pi);
        expect(
          note.rotation,
          closeTo(math.pi, 1e-9),
          reason: 'half turn is +π',
        );
        c.rotateNote(note, null);
        expect(note.rotation, isNull);
      },
    );

    test('a finished checklist is stamped and swept after a day', () async {
      final c = await _controller(
        notes: [
          _note('1', 'list', type: NoteType.checklist)
            ..checklist = [ChecklistItem(text: 'a'), ChecklistItem(text: 'b')],
        ],
      );
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

  group('wall undo', () {
    test('moving, resizing and turning can be undone, newest first', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      final note = c.boardNotes.single;
      var t = DateTime(2026, 9, 3, 12);
      c.clock = () => t;
      expect(c.canUndoWall, false);
      expect(c.undoWall(), isNull);

      c.moveNote(note, 0.7, 0.2);
      t = t.add(const Duration(seconds: 5));
      c.resizeNote(note, 1.5);
      t = t.add(const Duration(seconds: 5));
      c.rotateNote(note, 0.4);
      expect(c.wallEdits, 3);
      expect(c.nextWallUndo, WallEditKind.rotate);

      expect(c.undoWall(), WallEditKind.rotate);
      expect(note.rotation, isNull);
      expect(c.undoWall(), WallEditKind.resize);
      expect(note.scale, 1.0);
      expect(c.undoWall(), WallEditKind.move);
      expect(note.x, 0.5);
      expect(note.y, 0.5);
      expect(c.canUndoWall, false);
    });

    test('quick nudges of one note fold into a single step', () async {
      final c = await _controller(notes: [_note('1', 'x'), _note('2', 'y')]);
      final a = c.boardNotes[0];
      final b = c.boardNotes[1];
      var t = DateTime(2026, 9, 3, 12);
      c.clock = () => t;
      // A drag committed in phases: one finger, then two, then a turn.
      c.moveNote(a, 0.6, 0.5);
      t = t.add(const Duration(milliseconds: 400));
      c.moveNote(a, 0.7, 0.5);
      t = t.add(const Duration(milliseconds: 400));
      c.rotateNote(a, 0.3);
      expect(c.wallEdits, 3, reason: 'each change still shows the pill');
      // Another note, then the same note again after a pause: new steps.
      c.moveNote(b, 0.1, 0.1);
      t = t.add(const Duration(seconds: 3));
      c.moveNote(a, 0.9, 0.9);
      expect(c.undoWall(), WallEditKind.move);
      expect(a.x, 0.7);
      expect(c.undoWall(), WallEditKind.move);
      expect(b.x, 0.5);
      expect(c.undoWall(), WallEditKind.rotate);
      expect(a.x, 0.5, reason: 'all three phases undone together');
      expect(a.rotation, isNull);
      expect(c.canUndoWall, false);
    });

    test('a tidy and a move to another board undo as a whole', () async {
      final c = await _controller(notes: [_note('1', 'x'), _note('2', 'y')]);
      final notes = c.boardNotes;
      c.rotateNote(notes[0], 1.0);
      c.arrange([(notes[0], 0.1, 0.1, 0.8), (notes[1], 0.6, 0.1, 0.8)]);
      expect(notes[0].rotation, isNull);
      expect(c.undoWall(), WallEditKind.tidy);
      expect(notes[0].rotation, closeTo(1.0, 1e-9));
      expect(notes[0].x, 0.5);
      expect(notes[1].scale, 1.0);

      final work = c.addBoard('Work');
      c.selectBoard('default');
      c.moveAllToBoard([notes[0], notes[1]], work.id);
      expect(c.boardNotes, isEmpty);
      expect(c.undoWall(), WallEditKind.moveBoard);
      expect(c.boardNotes.length, 2);
      expect(notes[0].x, 0.5, reason: 'back where it was, too');
    });

    test('unchanged values and purged notes leave no trace', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      final note = c.boardNotes.single;
      c.moveNote(note, 0.5, 0.5);
      c.resizeNote(note, 1.0);
      c.rotateNote(note, null);
      c.moveNotes([(note, 0.5, 0.5)]);
      expect(c.canUndoWall, false);

      c.moveNote(note, 0.2, 0.2);
      c.delete(note);
      c.purge(note);
      expect(c.undoWall(), WallEditKind.move, reason: 'the step is spent');
      expect(c.allNotes, isEmpty);
    });

    test('the stack is capped', () async {
      final c = await _controller(notes: [_note('1', 'x')]);
      final note = c.boardNotes.single;
      var t = DateTime(2026);
      c.clock = () => t;
      for (var i = 1; i <= NotesController.wallUndoLimit + 10; i++) {
        t = t.add(const Duration(seconds: 10));
        c.moveNote(note, (i % 10) / 10, 0.1);
      }
      var steps = 0;
      while (c.undoWall() != null) {
        steps++;
      }
      expect(steps, NotesController.wallUndoLimit);
    });
  });

  group('labels, locks, yarn and marker strokes', () {
    test('a label and its lock round-trip; filter 5 keeps labels', () async {
      final c = await _controller(
        notes: [
          _note('1', 'To do', type: NoteType.label)..locked = true,
          _note('2', 'a task'),
        ],
      );
      final label = c.boardNotes.first;
      final json =
          jsonDecode(jsonEncode(label.toJson())) as Map<String, dynamic>;
      final back = Note.fromJson(json);
      expect(back.type, NoteType.label);
      expect(back.locked, true);
      expect(Note.fromJson(json..remove('locked')).locked, false);

      c.typeFilter = 5;
      expect(c.visibleNotes.single.guid, '1');
      c.typeFilter = -1;

      c.toggleLock(label);
      expect(label.locked, false);
      c.lockAll(c.boardNotes, true);
      expect(c.boardNotes.every((n) => n.locked), true);
    });

    test('a thread keeps its yarn colour, label and arrowhead', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveNotes([_note('1', 'x'), _note('2', 'y')]);
      final c = NotesController(storage, ReminderService());
      expect(c.connect('1', '2'), true);
      final plain = c.links.single;
      expect(plain.color, isNull);
      expect(plain.toJson().keys, ['a', 'b'], reason: 'defaults stay out');

      c.updateLink(
        plain.copyWith(color: AppColors.yarns[4], label: 'blocks', arrow: true),
      );
      final styled = NotesController(storage, ReminderService()).links.single;
      expect(styled.color, AppColors.yarns[4]);
      expect(styled.label, 'blocks');
      expect(styled.arrow, true);
      expect(styled.copyWith(clearColor: true).color, isNull);

      // Cut, then tied back exactly as it was; never twice.
      c.disconnect(styled);
      expect(c.links, isEmpty);
      c.restoreLink(styled);
      c.restoreLink(styled);
      expect(c.links.single.label, 'blocks');
      // Restyling a thread that is gone is a no-op.
      c.updateLink(const NoteLink('1', 'ghost', label: 'nope'));
      expect(c.links.length, 1);
    });

    test('marker strokes are saved with their board', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      final c = NotesController(storage, ReminderService());
      expect(c.currentBoard.toJson().containsKey('strokes'), false);
      c.currentBoard.strokes.add(
        DrawStroke(
          color: 0xFF3B372F,
          width: 4,
          points: const [Offset(0.1, 0.2), Offset(0.3, 0.4)],
        ),
      );
      c.saveWallStrokes();
      final again = NotesController(storage, ReminderService());
      final stroke = again.currentBoard.strokes.single;
      expect(stroke.points.length, 2);
      expect(stroke.points.last.dy, closeTo(0.4, 1e-9));
      expect(Board.fromJson(again.currentBoard.toJson()).strokes.length, 1);
    });
  });

  group('duplicate and copy', () {
    test('a duplicate sits beside the original with its own id', () async {
      final c = await _controller(
        notes: [
          _note('1', 'Plan', image: 'p.jpg', type: NoteType.checklist)
            ..checklist = [ChecklistItem(text: 'a', done: true)]
            ..pinned = true
            ..locked = true
            ..rotation = 0.4,
        ],
      );
      final original = c.boardNotes.single;
      final copy = c.duplicate(original);
      expect(c.boardNotes.length, 2);
      expect(copy.guid, isNot(original.guid));
      expect(copy.content, 'Plan');
      expect(copy.imagePath, 'p.jpg');
      expect(copy.checklist.single.done, true);
      expect(copy.rotation, closeTo(0.4, 1e-9));
      expect(copy.x, closeTo(0.54, 1e-9));
      expect(copy.pinned, false, reason: 'a copy is free to move');
      expect(copy.locked, false);
      // Ticking the copy leaves the original alone: a deep copy.
      c.toggleChecklistItem(copy, 0);
      expect(original.checklist.single.done, true);
      // The shared photo file lives while either note shows it.
      c.delete(original);
      c.purge(original);
      expect(c.photoInUse('p.jpg'), true);
    });

    test('copies land on the other board; the originals stay', () async {
      final c = await _controller(notes: [_note('1', 'x'), _note('2', 'y')]);
      final work = c.addBoard('Work');
      c.selectBoard('default');
      final copies = c.copyToBoard(c.boardNotes, work.id);
      expect(copies.length, 2);
      expect(c.boardNotes.length, 2, reason: 'originals untouched');
      c.selectBoard(work.id);
      expect(c.boardNotes.map((n) => n.content), containsAll(['x', 'y']));
      expect(c.copyToBoard(copies, 'ghost'), isEmpty);
    });
  });

  group('threads', () {
    test('connect / disconnect / linksOn', () async {
      final c = await _controller(
        notes: [_note('1', 'x'), _note('2', 'y'), _note('3', 'z')],
      );
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
        notes: [_note('1', 'x'), _note('2', 'y'), _note('3', 'z')],
      );
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

    test('links survive a reload and replaceAll drops dangling ones', () async {
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

  group('photos', () {
    test('the photo and the turn round-trip through JSON', () {
      final n = _note('1', 'x', image: 'a.jpg')..rotation = 0.7;
      final json = jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>;
      final back = Note.fromJson(json);
      expect(back.imagePath, 'a.jpg');
      expect(back.rotation, closeTo(0.7, 1e-9));
      expect(n.clone().rotation, closeTo(0.7, 1e-9));
      // No turn is stored as null, not 0: the card keeps its natural tilt.
      expect(Note.fromJson(json..remove('rotation')).rotation, isNull);
      expect(_note('2', 'y').toJson()['rotation'], isNull);
    });

    test('data from the multi-photo builds keeps its first photo', () {
      final json = _note('1', 'x').toJson()
        ..remove('imagePath')
        ..['images'] = ['', 'first.jpg', 'second.jpg'];
      expect(Note.fromJson(json).imagePath, 'first.jpg');
      expect(Note.fromJson(json..['images'] = <String>[]).imagePath, '');
      // A present imagePath wins over the old list.
      expect(
        Note.fromJson(
          json
            ..['imagePath'] = 'mine.jpg'
            ..['images'] = ['other.jpg'],
        ).imagePath,
        'mine.jpg',
      );
    });

    test(
      'addPhotos pins one print per file, cascading from the spot',
      () async {
        final c = await _controller();
        final created = c.addPhotos(
          ['a.jpg', 'b.jpg', 'c.jpg'],
          x: 0.2,
          y: 0.3,
        );
        expect(created.length, 3);
        expect(c.boardNotes.length, 3);
        for (final (i, n) in created.indexed) {
          expect(n.type, NoteType.photo);
          expect(n.imagePath, '${'abc'[i]}.jpg');
          expect(n.boardId, 'default');
        }
        expect(created[0].x, closeTo(0.2, 1e-9));
        expect(created[1].x, greaterThan(created[0].x));
        expect(created[1].y, greaterThan(created[0].y));
        expect(c.addPhotos([]), isEmpty);
        expect(c.boardNotes.length, 3);
      },
    );

    test('a print can be tied to a note with a thread', () async {
      final c = await _controller(notes: [_note('n', 'text')]);
      final print = c.addPhotos(['a.jpg']).single;
      expect(c.connect(print.guid, 'n'), true);
      expect(c.linksOn('default').single.same('n', print.guid), true);
    });

    test('type filter 4 keeps only prints', () async {
      final c = await _controller(notes: [_note('n', 'text')]);
      c.addPhotos(['a.jpg']);
      c.typeFilter = 4;
      expect(c.visibleNotes.single.type, NoteType.photo);
      c.typeFilter = 0;
      expect(c.visibleNotes.single.guid, 'n');
    });

    test(
      'purging a note deletes its photo unless another note shows it',
      () async {
        final removed = <String>[];
        final c = await _controller(
          notes: [
            _note('1', 'x', image: 'shared.jpg'),
            _note('2', 'y', image: 'shared.jpg'),
            _note('3', 'z', image: 'own.jpg'),
          ],
          deletePhoto: removed.add,
        );
        final n1 = c.boardNotes[0];
        final n3 = c.boardNotes[2];
        c.delete(n1);
        c.purge(n1);
        expect(removed, isEmpty, reason: 'note 2 still shows shared.jpg');
        expect(c.photoInUse('shared.jpg'), true);
        c.delete(n3);
        c.purge(n3);
        expect(removed, ['own.jpg']);
        expect(c.photoInUse('own.jpg'), false);
        expect(c.photoInUse(''), false);
      },
    );
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
      expect(
        daily.nextReminder(DateTime(2026, 1, 20, 12)),
        DateTime(2026, 1, 21, 9, 30),
      );
      expect(
        daily.nextReminder(DateTime(2026, 1, 20, 8)),
        DateTime(2026, 1, 20, 9, 30),
      );

      final weekly = _note('2', 'x')
        ..reminderAt =
            first // a Thursday
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
      expect(
        monthly.nextReminder(DateTime(2026, 4, 1)),
        DateTime(2026, 5, 1, 8),
      ); // Apr 31 → May 1
    });

    test('round-trips repeat / deletedAt / completedAt through JSON', () {
      final n = _note('1', 'x')
        ..reminderAt = first
        ..repeat = ReminderRepeat.weekly
        ..deletedAt = DateTime(2026, 3, 1)
        ..completedAt = DateTime(2026, 2, 1);
      final back = Note.fromJson(
        jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>,
      );
      expect(back.repeat, ReminderRepeat.weekly);
      expect(back.deletedAt, DateTime(2026, 3, 1));
      expect(back.completedAt, DateTime(2026, 2, 1));
      expect(back.isTrashed, true);
    });
  });

  group('SharedContent.fromText', () {
    test('splits the first link from the surrounding text', () {
      final c = SharedContent.fromText(
        'Check this out https://example.com/a?b=1. Great read',
      );
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
      expect(
        ImageService.resolve('/old/container/note_images/a.jpg'),
        '/docs/note_images/a.jpg',
      );
      expect(
        ImageService.resolve(r'C:\old\note_images\a.jpg'),
        '/docs/note_images/a.jpg',
      );
      expect(ImageService.resolve(''), '');
    });

    test('passes the reference through when no directory is known', () {
      expect(ImageService.resolve('a.jpg'), 'a.jpg');
    });
  });

  group('ReminderService.titleFor', () {
    test('uses content, then checklist items, then the app name', () {
      expect(ReminderService.titleFor(_note('1', '  Call mum  ')), 'Call mum');
      final list = _note(
        '2',
        '',
        type: NoteType.checklist,
      )..checklist = [ChecklistItem(text: 'milk'), ChecklistItem(text: 'eggs')];
      expect(ReminderService.titleFor(list), 'milk, eggs');
      expect(ReminderService.titleFor(_note('3', '')), 'Sticky Wall');
      expect(
        ReminderService.titleFor(_note('4', 'Gym')..emoji = '💪'),
        '💪 Gym',
      );
    });
  });

  test('stableHash is deterministic and non-negative', () {
    expect(stableHash('abc'), stableHash('abc'));
    expect(stableHash('abc'), isNot(stableHash('abd')));
    expect(stableHash('Ghi chú dài ' * 50), greaterThanOrEqualTo(0));
  });
}

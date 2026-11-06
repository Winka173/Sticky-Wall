import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/sync/sync_backend.dart';
import 'package:sticky_wall/services/sync/sync_engine.dart';
import 'package:sticky_wall/services/sync/sync_service.dart';

/// Separate preferences per simulated device (the real ones are a
/// process-wide singleton).
class _Prefs implements SharedPreferences {
  final _m = <String, Object>{};

  @override
  bool containsKey(String key) => _m.containsKey(key);
  @override
  Object? get(String key) => _m[key];
  @override
  String? getString(String key) => _m[key] as String?;
  @override
  bool? getBool(String key) => _m[key] as bool?;
  @override
  int? getInt(String key) => _m[key] as int?;
  @override
  double? getDouble(String key) => _m[key] as double?;
  @override
  List<String>? getStringList(String key) => _m[key] as List<String>?;
  @override
  Set<String> getKeys() => _m.keys.toSet();
  @override
  Future<bool> setString(String key, String value) async => _set(key, value);
  @override
  Future<bool> setBool(String key, bool value) async => _set(key, value);
  @override
  Future<bool> setInt(String key, int value) async => _set(key, value);
  @override
  Future<bool> setDouble(String key, double value) async => _set(key, value);
  @override
  Future<bool> setStringList(String key, List<String> value) async =>
      _set(key, value);
  @override
  Future<bool> remove(String key) async => _m.remove(key) != null || true;

  bool _set(String key, Object value) {
    _m[key] = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Media implements SyncMediaStore {
  final files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String kind, String name) async =>
      files['$kind/$name'];

  @override
  Future<void> write(String kind, String name, Uint8List bytes) async =>
      files['$kind/$name'] = bytes;
}

class _Device {
  _Device(this.cloud, {List<Board>? boards, List<Note> notes = const []}) {
    storage = NoteStorage(prefs);
    storage
      ..saveBoards(boards ?? [Board(id: 'default', name: '')])
      ..saveNotes(notes);
    this.notes = NotesController(storage, ReminderService());
    sync = SyncService(prefs: prefs, notes: this.notes, media: media)
      ..attach(cloud);
  }

  final MemorySyncBackend cloud;
  final prefs = _Prefs();
  final media = _Media();
  late final NoteStorage storage;
  late final NotesController notes;
  late final SyncService sync;

  Future<void> syncNow() async {
    await prefs.setBool('sync.enabled', true);
    sync.attach(cloud);
    await sync.syncNow();
  }

  Note note(String guid) =>
      notes.allNotes.firstWhere((n) => n.guid == guid);
}

Note _n(String guid, String text, {String board = 'default'}) => Note(
  guid: guid,
  content: text,
  createdAt: DateTime(2026),
  boardId: board,
);

void main() {
  late MemorySyncBackend cloud;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cloud = MemorySyncBackend();
  });

  test('two devices editing different notes end up with both', () async {
    final a = _Device(cloud, notes: [_n('1', 'from A')]);
    final b = _Device(cloud, notes: [_n('2', 'from B')]);
    await a.syncNow();
    await b.syncNow();
    await a.syncNow();
    expect(a.notes.allNotes.map((n) => n.content).toSet(), {
      'from A',
      'from B',
    });
    expect(b.notes.allNotes.map((n) => n.content).toSet(), {
      'from A',
      'from B',
    });
    expect(a.sync.state, SyncState.idle);
  });

  test('an edit made on one device reaches the other; an unchanged stale '
      'copy never undoes it', () async {
    final a = _Device(cloud, notes: [_n('1', 'v1')]);
    final b = _Device(cloud);
    await a.syncNow();
    await b.syncNow();
    a.notes.update(a.note('1').clone()..content = 'v2');
    await a.syncNow();
    // B syncs again with its old, untouched copy.
    await b.syncNow();
    expect(b.note('1').content, 'v2');
    await a.syncNow();
    expect(a.note('1').content, 'v2');
  });

  test('the same note edited on both before syncing: one wins, the other is '
      'kept as a copy', () async {
    final a = _Device(cloud, notes: [_n('1', 'start')]);
    final b = _Device(cloud);
    await a.syncNow();
    await b.syncNow();
    a.notes.update(a.note('1').clone()..content = 'A wrote this');
    b.notes.update(b.note('1').clone()..content = 'B wrote this');
    await a.syncNow();
    await b.syncNow();
    await a.syncNow();
    final onA = a.notes.allNotes.map((n) => n.content).toSet();
    final onB = b.notes.allNotes.map((n) => n.content).toSet();
    expect(onA, {'A wrote this', 'B wrote this'});
    expect(onB, onA);
    expect(b.sync.lastConflicts, 1);
  });

  test('a delete on one device is not undone by the other device\'s old '
      'copy', () async {
    final a = _Device(cloud, notes: [_n('1', 'x'), _n('2', 'y')]);
    final b = _Device(cloud);
    await a.syncNow();
    await b.syncNow();
    a.notes.purge(a.note('1'));
    await a.syncNow();
    await b.syncNow();
    expect(b.notes.allNotes.map((n) => n.guid), ['2']);
    await a.syncNow();
    expect(a.notes.allNotes.map((n) => n.guid), ['2']);
  });

  test('an edit made while the other device deleted the note is kept',
      () async {
    final a = _Device(cloud, notes: [_n('1', 'x')]);
    final b = _Device(cloud);
    await a.syncNow();
    await b.syncNow();
    a.notes.purge(a.note('1'));
    b.notes.update(b.note('1').clone()..content = 'still needed');
    await a.syncNow();
    await b.syncNow();
    await a.syncNow();
    expect(a.note('1').content, 'still needed');
    expect(b.note('1').content, 'still needed');
  });

  test('a board deleted on one device goes to the Trash on the other, whole, '
      'and can come back on either', () async {
    final a = _Device(
      cloud,
      boards: [
        Board(id: 'default', name: ''),
        Board(id: 'trip', name: 'Trip'),
      ],
      notes: [_n('1', 'home'), _n('2', 'beach', board: 'trip')],
    );
    final b = _Device(cloud);
    await a.syncNow();
    await b.syncNow();
    expect(b.notes.boards.map((x) => x.id), ['default', 'trip']);

    a.notes.deleteBoard('trip');
    await a.syncNow();
    await b.syncNow();
    expect(b.notes.boards.map((x) => x.id), ['default']);
    expect(b.notes.deletedBoards.single.id, 'trip');
    expect(b.notes.noteCountOn('trip'), 1);

    b.notes.restoreBoard('trip');
    await b.syncNow();
    await a.syncNow();
    expect(a.notes.boards.map((x) => x.id), ['default', 'trip']);
    expect(a.notes.deletedBoards, isEmpty);
  });

  test('threads only arrive with both of their notes', () async {
    final a = _Device(cloud, notes: [_n('1', 'a'), _n('2', 'b')]);
    a.notes.connect('1', '2');
    await a.syncNow();
    final b = _Device(cloud);
    await b.syncNow();
    expect(b.notes.links.single.connects('1'), isTrue);
  });

  test('photos travel by content hash and are checked on arrival', () async {
    final bytes = Uint8List.fromList(List.generate(64, (i) => i));
    final a = _Device(
      cloud,
      notes: [
        _n('1', '')
          ..type = NoteType.photo
          ..imagePath = 'p1.jpg',
      ],
    );
    a.media.files['photo/p1.jpg'] = bytes;
    await a.syncNow();
    final sha = sha256.convert(bytes).toString();
    expect(cloud.blobs.keys, [sha]);

    final b = _Device(cloud);
    await b.syncNow();
    expect(b.media.files['photo/p1.jpg'], bytes);
    expect(b.sync.missingMedia, 0);

    // A damaged blob is refused, and the local file is never touched.
    cloud.blobs[sha] = Uint8List.fromList([1, 2, 3]);
    final c = _Device(cloud);
    await c.syncNow();
    expect(c.media.files.containsKey('photo/p1.jpg'), isFalse);
    expect(c.sync.missingMedia, 1);
  });

  test('locked boards stay on the device unless chosen', () async {
    final a = _Device(
      cloud,
      boards: [
        Board(id: 'default', name: ''),
        Board(id: 'diary', name: 'Diary', isPrivate: true),
      ],
      notes: [_n('1', 'public'), _n('2', 'secret', board: 'diary')],
    );
    await a.syncNow();
    expect(cloud.devices.values.single, isNot(contains('secret')));
    expect(cloud.devices.values.single, isNot(contains('Diary')));
    final b = _Device(cloud);
    await b.syncNow();
    expect(b.notes.allNotes.map((n) => n.content), ['public']);
    // A's locked board is untouched by the sync.
    expect(a.notes.allNotes.map((n) => n.content).toSet(), {
      'public',
      'secret',
    });

    await a.sync.setIncludeLocked(true);
    await a.syncNow();
    await b.syncNow();
    expect(b.notes.allNotes.map((n) => n.content).toSet(), {
      'public',
      'secret',
    });
  });

  test('offline: nothing changes, the state says so, the next sync '
      'catches up', () async {
    final a = _Device(cloud, notes: [_n('1', 'x')]);
    cloud.failWith = SyncFailure.offline;
    await a.syncNow();
    expect(a.sync.state, SyncState.offline);
    expect(a.notes.allNotes.single.content, 'x');
    cloud.failWith = null;
    await a.syncNow();
    expect(a.sync.state, SyncState.idle);
    expect(cloud.devices, hasLength(1));
  });

  test('a file from a newer schema stops the sync instead of being '
      'misread', () async {
    cloud.devices['other'] = jsonEncode({'schema': 99, 'records': <String, Object>{}});
    await cloud.writeDevice('other', cloud.devices['other']!);
    final a = _Device(cloud, notes: [_n('1', 'x')]);
    await a.syncNow();
    expect(a.sync.state, SyncState.failed);
    expect(a.notes.allNotes.single.content, 'x');
  });

  test('the engine is deterministic: same inputs, same winner, on any '
      'device', () {
    final r1 = {'n:1': const SyncRecord(rev: 5, by: 'a', data: {'c': 1})};
    final r2 = {'n:1': const SyncRecord(rev: 5, by: 'b', data: {'c': 2})};
    final x = const SyncEngine().merge(
      device: 'z',
      local: const {},
      meta: const {},
      clock: 0,
      remote: [r1, r2],
      now: DateTime(2026),
    );
    final y = const SyncEngine().merge(
      device: 'y',
      local: const {},
      meta: const {},
      clock: 0,
      remote: [r2, r1],
      now: DateTime(2026),
    );
    expect(x.records['n:1']!.data, {'c': 2});
    expect(y.records['n:1']!.data, {'c': 2});
  });
}

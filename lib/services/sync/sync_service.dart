import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/board.dart';
import '../../models/note.dart';
import '../audio_service.dart';
import '../image_service.dart';
import '../notes_controller.dart';
import 'sync_backend.dart';
import 'sync_engine.dart';

/// Where the photo and recording files live, so the sync can read what it
/// uploads and write what it downloads. Tests use a map.
abstract class SyncMediaStore {
  Future<Uint8List?> read(String kind, String name);
  Future<void> write(String kind, String name, Uint8List bytes);
}

/// The app's real folders (see [ImageService], [AudioService]).
class AppMediaStore implements SyncMediaStore {
  const AppMediaStore();

  @override
  Future<Uint8List?> read(String kind, String name) => switch (kind) {
    'wall' => ImageService.readStored(name, wall: true),
    'audio' => AudioService.readStored(name),
    _ => ImageService.readStored(name),
  };

  @override
  Future<void> write(String kind, String name, Uint8List bytes) =>
      switch (kind) {
        'wall' => ImageService.writeStored(name, bytes, wall: true),
        'audio' => AudioService.writeStored(name, bytes),
        _ => ImageService.writeStored(name, bytes),
      };
}

enum SyncState { off, idle, syncing, offline, authNeeded, quota, failed }

/// Two-way sync of boards, notes, threads, the Trash and their files with
/// the other devices signed in to the same provider. Off unless switched
/// on; the app never needs it to open or edit anything.
///
/// Locked boards stay on this device unless [includeLocked] is on: they are
/// locked in the app, not encrypted, and the provider would hold them as
/// plain data.
class SyncService extends ChangeNotifier {
  SyncService({
    required this._prefs,
    required this._notes,
    this._media = const AppMediaStore(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final NotesController _notes;
  final SyncMediaStore _media;
  final DateTime Function() _clock;
  SyncBackend? _backend;

  static const schema = 1;
  static const _enabledKey = 'sync.enabled';
  static const _deviceKey = 'sync.device';
  static const _clockKey = 'sync.clock';
  static const _metaKey = 'sync.meta';
  static const _shaKey = 'sync.sha';
  static const _lastKey = 'sync.last';
  static const _lockedKey = 'sync.includeLocked';
  static const _providerKey = 'sync.provider';

  /// The app instance (set at start-up when a provider exists on this
  /// platform); null where sync is not offered.
  static SyncService? instance;

  /// True while merged data is being put into the app, so the app's own
  /// change listener does not schedule another sync for it.
  bool applying = false;

  SyncState _state = SyncState.off;
  SyncState get state => _state;

  /// Files referenced by synced notes that no device has uploaded yet, or
  /// whose download failed its checksum. The local copies are never touched.
  int _missingMedia = 0;
  int get missingMedia => _missingMedia;

  int _lastConflicts = 0;

  /// Notes edited on two devices at once in the last sync; each loser was
  /// kept as a copy.
  int get lastConflicts => _lastConflicts;

  bool get enabled => _prefs.getBool(_enabledKey) ?? false;
  bool get includeLocked => _prefs.getBool(_lockedKey) ?? false;
  String? get provider => _prefs.getString(_providerKey);

  DateTime? get lastSync => DateTime.tryParse(_prefs.getString(_lastKey) ?? '');

  String get deviceId {
    var id = _prefs.getString(_deviceKey);
    if (id == null) {
      id = const Uuid().v4();
      _prefs.setString(_deviceKey, id);
    }
    return id;
  }

  /// Switches sync on with [backend] (already authorized) and syncs once.
  Future<void> enable(SyncBackend backend) async {
    _backend = backend;
    await _prefs.setBool(_enabledKey, true);
    await _prefs.setString(_providerKey, backend.name);
    _state = SyncState.idle;
    notifyListeners();
    await syncNow();
  }

  /// Attaches the backend on launch when sync was left on.
  void attach(SyncBackend backend) {
    _backend = backend;
    if (enabled && _state == SyncState.off) {
      _state = SyncState.idle;
      notifyListeners();
    }
  }

  /// Switches sync off. Nothing on this device is deleted, and the copy
  /// with the provider stays for the other devices.
  Future<void> disable() async {
    await _prefs.setBool(_enabledKey, false);
    _backend = null;
    _state = SyncState.off;
    notifyListeners();
  }

  Future<void> setIncludeLocked(bool value) async {
    await _prefs.setBool(_lockedKey, value);
    notifyListeners();
  }

  Future<void>? _running;

  /// One full sync. Concurrent calls share the run in progress.
  Future<void> syncNow() {
    if (!enabled || _backend == null) return Future.value();
    return _running ??= _sync().whenComplete(() => _running = null);
  }

  Future<void> _sync() async {
    final backend = _backend!;
    _state = SyncState.syncing;
    notifyListeners();
    try {
      // Copies kept from a conflict are new notes: a second pass sends them
      // straight away instead of at the next sync.
      final copies = await _syncWith(backend);
      if (copies > 0) await _syncWith(backend);
      _lastConflicts = copies;
      _state = SyncState.idle;
      await _prefs.setString(_lastKey, _clock().toIso8601String());
    } on SyncException catch (e) {
      debugPrint('Sync stopped: $e');
      _state = switch (e.failure) {
        SyncFailure.offline => SyncState.offline,
        SyncFailure.authNeeded => SyncState.authNeeded,
        SyncFailure.quota => SyncState.quota,
        SyncFailure.newerVersion || SyncFailure.other => SyncState.failed,
      };
    } catch (e) {
      debugPrint('Sync failed: $e');
      _state = SyncState.failed;
    }
    notifyListeners();
  }

  // --- One sync ------------------------------------------------------------

  /// Returns how many conflict copies were made.
  Future<int> _syncWith(SyncBackend backend) async {
    final me = deviceId;
    final now = _clock();
    final excluded = <String>{};
    final local = await _collect(excluded);

    // Everyone else's latest file (and this device's own, which carries
    // what it learned from devices that may since have gone quiet).
    final remote = <Map<String, SyncRecord>>[];
    final versions = await backend.listDevices();
    for (final id in versions.keys) {
      final doc = await backend.readDevice(id);
      if (doc == null) continue;
      remote.add(_parse(doc));
    }

    final result = const SyncEngine().merge(
      device: me,
      local: local,
      meta: _loadMeta(),
      clock: _prefs.getInt(_clockKey) ?? 0,
      remote: remote,
      now: now,
      excluded: excluded,
    );

    // Files first: a record must never point at a blob that is not there.
    final blobs = await backend.listBlobs();
    final uploaded = <String>{};
    for (final e in result.records.entries) {
      if (!e.key.startsWith('m:') || e.value.data == null) continue;
      final sha = e.value.data!['sha'] as String?;
      if (sha == null || blobs.contains(sha) || uploaded.contains(sha)) {
        continue;
      }
      final (kind, name) = _mediaKey(e.key);
      final bytes = await _media.read(kind, name);
      if (bytes == null || sha256.convert(bytes).toString() != sha) continue;
      await backend.putBlob(sha, bytes);
      uploaded.add(sha);
    }
    blobs.addAll(uploaded);
    final records = Map.of(result.records)
      ..removeWhere(
        (k, r) =>
            k.startsWith('m:') &&
            r.data != null &&
            !blobs.contains(r.data!['sha']),
      );

    await backend.writeDevice(
      me,
      jsonEncode({
        'schema': schema,
        'device': me,
        'written': now.toIso8601String(),
        'records': {for (final e in records.entries) e.key: e.value.toJson()},
      }),
    );
    await _prefs.setString(
      _metaKey,
      jsonEncode({
        for (final e in result.meta.entries) e.key: e.value.toJson(),
      }),
    );
    await _prefs.setInt(_clockKey, result.clock);

    // Then the files this device lacks, each checked against its hash.
    var missing = 0;
    for (final e in records.entries) {
      if (!e.key.startsWith('m:') || e.value.data == null) continue;
      final (kind, name) = _mediaKey(e.key);
      if (await _media.read(kind, name) != null) continue;
      final sha = e.value.data!['sha'] as String;
      final bytes = await backend.getBlob(sha);
      if (bytes == null || sha256.convert(bytes).toString() != sha) {
        missing++;
        continue;
      }
      await _media.write(kind, name, bytes);
      _rememberSha(name, sha);
    }
    _missingMedia = missing;

    _apply(records, result.conflicts, excluded);
    return result.conflicts.length;
  }

  /// This device's data as records. Locked boards, their notes and threads
  /// touching them are left out (and listed in [excluded]) unless the user
  /// chose to sync them.
  Future<Map<String, Map<String, dynamic>>> _collect(
    Set<String> excluded,
  ) async {
    final out = <String, Map<String, dynamic>>{};
    final hidden = <String>{};
    final boards = _notes.boards;
    for (var i = 0; i < boards.length; i++) {
      final b = boards[i];
      if (b.isPrivate && !includeLocked) {
        hidden.add(b.id);
        excluded.add('b:${b.id}');
        continue;
      }
      out['b:${b.id}'] = {...b.toJson(), 'pos': i};
    }
    for (final b in _notes.deletedBoards) {
      if (b.isPrivate && !includeLocked) {
        hidden.add(b.id);
        excluded.add('b:${b.id}');
        continue;
      }
      out['b:${b.id}'] = b.toJson();
    }
    final hiddenNotes = <String>{};
    for (final n in _notes.allNotes) {
      if (hidden.contains(n.boardId)) {
        hiddenNotes.add(n.guid);
        excluded.add('n:${n.guid}');
        continue;
      }
      out['n:${n.guid}'] = n.toJson();
    }
    for (final l in _notes.links) {
      final key = 'l:${_linkKey(l)}';
      if (hiddenNotes.contains(l.a) || hiddenNotes.contains(l.b)) {
        excluded.add(key);
        continue;
      }
      out[key] = l.toJson();
    }

    // The files they use, by content hash.
    Future<void> media(String kind, String name) async {
      if (name.isEmpty) return;
      final key = 'm:$kind:$name';
      if (out.containsKey(key)) return;
      var sha = _knownSha(name);
      if (sha == null) {
        final bytes = await _media.read(kind, name);
        if (bytes == null) return;
        sha = sha256.convert(bytes).toString();
        _rememberSha(name, sha);
      }
      out[key] = {'sha': sha};
    }

    for (final e in out.entries.toList()) {
      final d = e.value;
      if (e.key.startsWith('n:')) {
        await media('photo', d['imagePath'] as String? ?? '');
        await media('audio', d['audioPath'] as String? ?? '');
      } else if (e.key.startsWith('b:')) {
        await media('wall', d['wallImage'] as String? ?? '');
        await media('wall', d['savedWallImage'] as String? ?? '');
      }
    }
    return out;
  }

  /// Puts the merged records into the app. What was left out of the sync
  /// (locked boards) stays exactly as it is.
  void _apply(
    Map<String, SyncRecord> records,
    List<SyncConflict> conflicts,
    Set<String> excluded,
  ) {
    final active = <(int, Board)>[];
    final deleted = <Board>[];
    final notes = <Note>[];
    final links = <NoteLink>[];
    for (final e in records.entries) {
      final d = e.value.data;
      if (d == null) continue;
      try {
        switch (e.key[0]) {
          case 'b':
            final b = Board.fromJson(d);
            if (b.deletedAt == null) {
              active.add((d['pos'] as int? ?? 1 << 20, b));
            } else {
              deleted.add(b);
            }
          case 'n':
            notes.add(Note.fromJson(d));
          case 'l':
            links.add(NoteLink.fromJson(d));
        }
      } catch (err) {
        // A record this version cannot read is left in the file, untouched.
        debugPrint('Skipped sync record ${e.key}: $err');
      }
    }
    // Locked boards that were not synced keep their place and content.
    final keptBoards = [
      for (final b in _notes.boards)
        if (excluded.contains('b:${b.id}')) b,
    ];
    final keptDeleted = [
      for (final b in _notes.deletedBoards)
        if (excluded.contains('b:${b.id}')) b,
    ];
    final keptNotes = [
      for (final n in _notes.allNotes)
        if (excluded.contains('n:${n.guid}')) n,
    ];
    final keptLinks = [
      for (final l in _notes.links)
        if (excluded.contains('l:${_linkKey(l)}')) l,
    ];
    active.sort((a, b) => a.$1.compareTo(b.$1));
    final copies = [for (final c in conflicts) ?_copyOf(c.losing)];
    applying = true;
    try {
      _notes.applySync(
        boards: [...active.map((e) => e.$2), ...keptBoards],
        deletedBoards: [...deleted, ...keptDeleted],
        notes: [...notes, ...keptNotes, ...copies],
        links: [...links, ...keptLinks],
      );
    } finally {
      applying = false;
    }
  }

  /// The losing side of a conflict, as a new note beside the winner.
  Note? _copyOf(Map<String, dynamic> data) {
    try {
      final copy = Note.fromJson({...data, 'guid': const Uuid().v4()});
      copy
        ..x = (copy.x + 0.04).clamp(
          -NotesController.wallSpill,
          1 + NotesController.wallSpill,
        )
        ..y = (copy.y + 0.04).clamp(
          -NotesController.wallSpill,
          1 + NotesController.wallSpill,
        );
      return copy;
    } catch (_) {
      return null;
    }
  }

  // --- Helpers -------------------------------------------------------------

  Map<String, SyncRecord> _parse(String doc) {
    final Object? json;
    try {
      json = jsonDecode(doc);
    } catch (_) {
      return const {};
    }
    if (json is! Map<String, dynamic>) return const {};
    final version = json['schema'];
    if (version is int && version > schema) {
      throw const SyncException(SyncFailure.newerVersion);
    }
    final records = json['records'];
    if (records is! Map<String, dynamic>) return const {};
    return {
      for (final e in records.entries) e.key: ?SyncRecord.fromJson(e.value),
    };
  }

  Map<String, SyncMeta> _loadMeta() {
    try {
      final raw = jsonDecode(_prefs.getString(_metaKey) ?? '{}');
      if (raw is! Map<String, dynamic>) return {};
      return {for (final e in raw.entries) e.key: ?SyncMeta.fromJson(e.value)};
    } catch (_) {
      return {};
    }
  }

  Map<String, String>? _shaCache;

  Map<String, String> get _shas => _shaCache ??= () {
    try {
      final raw = jsonDecode(_prefs.getString(_shaKey) ?? '{}');
      return raw is Map<String, dynamic>
          ? {for (final e in raw.entries) e.key: '${e.value}'}
          : <String, String>{};
    } catch (_) {
      return <String, String>{};
    }
  }();

  /// Stored file names never change content (a new photo gets a new name),
  /// so a name's hash is computed once.
  String? _knownSha(String name) => _shas[name];

  void _rememberSha(String name, String sha) {
    _shas[name] = sha;
    _prefs.setString(_shaKey, jsonEncode(_shas));
  }

  static (String, String) _mediaKey(String key) {
    final rest = key.substring(2);
    final i = rest.indexOf(':');
    return (rest.substring(0, i), rest.substring(i + 1));
  }

  static String _linkKey(NoteLink l) {
    final ends = [l.a, l.b]..sort();
    return ends.join('|');
  }
}

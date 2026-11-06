import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One synced record as a device file stores it: a revision, the device
/// that made it, and the data, or none for a deletion (a tombstone).
///
/// Revisions are a Lamport clock, not wall time: a device's next revision
/// is one more than the highest it has seen, so a phone with its clock set
/// wrong can neither win nor lose an edit by it. Ties go to the larger
/// device id, the same on every device.
class SyncRecord {
  const SyncRecord({
    required this.rev,
    required this.by,
    this.data,
    this.deadSince,
  });

  final int rev;
  final String by;

  /// The record's JSON, or null for a tombstone.
  final Map<String, dynamic>? data;

  /// When this device first saw the tombstone; tombstones are kept for
  /// [SyncEngine.tombstoneLife] after it, so a device that was offline that
  /// long still learns of the deletion before it is forgotten.
  final DateTime? deadSince;

  bool get isTombstone => data == null;

  /// Whether this record beats [other] (same key).
  bool beats(SyncRecord other) =>
      rev != other.rev ? rev > other.rev : by.compareTo(other.by) > 0;

  Map<String, dynamic> toJson() => {
    'r': rev,
    'b': by,
    if (data != null) 'd': data,
    if (deadSince != null) 't': deadSince!.toIso8601String(),
  };

  static SyncRecord? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final rev = json['r'];
    final by = json['b'];
    if (rev is! int || by is! String) return null;
    final data = json['d'];
    return SyncRecord(
      rev: rev,
      by: by,
      data: data is Map<String, dynamic> ? data : null,
      deadSince: DateTime.tryParse(json['t'] as String? ?? ''),
    );
  }
}

/// What this device knew of a record at its last sync: the revision it had
/// and a hash of the data, so a local edit since is noticed.
class SyncMeta {
  const SyncMeta(this.rev, this.by, this.hash, [this.deadSince]);

  final int rev;
  final String by;

  /// [SyncEngine.hashOf] the data, or [SyncEngine.tombstoneHash].
  final String hash;
  final DateTime? deadSince;

  Map<String, dynamic> toJson() => {
    'r': rev,
    'b': by,
    'h': hash,
    if (deadSince != null) 't': deadSince!.toIso8601String(),
  };

  static SyncMeta? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final rev = json['r'];
    final by = json['b'];
    final hash = json['h'];
    if (rev is! int || by is! String || hash is! String) return null;
    return SyncMeta(
      rev,
      by,
      hash,
      DateTime.tryParse(json['t'] as String? ?? ''),
    );
  }
}

/// A note edited on two devices before either synced: the loser's version,
/// kept as a copy beside the winner instead of being lost.
class SyncConflict {
  const SyncConflict(this.key, this.losing);

  final String key;
  final Map<String, dynamic> losing;
}

/// The outcome of one merge.
class SyncResult {
  const SyncResult({
    required this.records,
    required this.meta,
    required this.clock,
    required this.conflicts,
    required this.changedLocally,
  });

  /// Every record after the merge, tombstones included: what this device
  /// writes to its own file, and what the app's data should now be.
  final Map<String, SyncRecord> records;

  /// What to remember for the next sync.
  final Map<String, SyncMeta> meta;
  final int clock;

  /// Notes edited on both sides; the app keeps each loser as a copy.
  final List<SyncConflict> conflicts;

  /// Keys this device changed since its last sync.
  final Set<String> changedLocally;
}

/// Merges this device's records with every other device's file.
///
/// Keys name the record kind: `b:` board (a board in the Trash carries its
/// `deletedAt`), `n:` note, `l:` thread, `m:` media file. Deleting is a
/// tombstone with a newer revision, so a device holding an old copy cannot
/// bring the thing back. An edit made while another device deleted the
/// same thing is kept: losing work is worse than an unwanted note.
class SyncEngine {
  const SyncEngine();

  static const tombstoneHash = '-';

  /// How long a deletion is remembered.
  static const tombstoneLife = Duration(days: 120);

  static String hashOf(Map<String, dynamic> data) =>
      sha1.convert(utf8.encode(jsonEncode(_canonical(data)))).toString();

  static Object? _canonical(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _canonical(v[k])};
    }
    if (v is List) return [for (final e in v) _canonical(e)];
    return v;
  }

  SyncResult merge({
    required String device,
    required Map<String, Map<String, dynamic>> local,
    required Map<String, SyncMeta> meta,
    required int clock,
    required List<Map<String, SyncRecord>> remote,
    required DateTime now,
    Set<String> excluded = const {},
  }) {
    var lamport = clock;
    for (final m in meta.values) {
      if (m.rev > lamport) lamport = m.rev;
    }

    // 1. This device's records, with a new revision for anything changed.
    final mine = <String, SyncRecord>{};
    final changed = <String>{};
    final base = <String, SyncMeta>{};
    for (final key in {...local.keys, ...meta.keys}) {
      if (excluded.contains(key)) continue;
      final data = local[key];
      final m = meta[key];
      final hash = data == null ? tombstoneHash : hashOf(data);
      if (m == null) {
        if (data == null) continue;
        mine[key] = SyncRecord(rev: ++lamport, by: device, data: data);
        changed.add(key);
      } else if (m.hash != hash) {
        base[key] = m;
        mine[key] = SyncRecord(
          rev: ++lamport,
          by: device,
          data: data,
          deadSince: data == null ? now : null,
        );
        changed.add(key);
      } else {
        mine[key] = SyncRecord(
          rev: m.rev,
          by: m.by,
          data: data,
          deadSince: m.deadSince,
        );
      }
    }

    // 2. The best version of each record among the other devices.
    final theirs = <String, SyncRecord>{};
    for (final file in remote) {
      file.forEach((key, r) {
        if (excluded.contains(key)) return;
        final best = theirs[key];
        if (best == null || r.beats(best)) theirs[key] = r;
        if (r.rev > lamport) lamport = r.rev;
      });
    }

    // 3. Winner per key.
    final out = <String, SyncRecord>{};
    final conflicts = <SyncConflict>[];
    for (final key in {...mine.keys, ...theirs.keys}) {
      final l = mine[key];
      final r = theirs[key];
      if (l == null) {
        out[key] = r!;
        continue;
      }
      if (r == null || r.rev == l.rev && r.by == l.by) {
        out[key] = l;
        continue;
      }
      final b = base[key];
      final concurrent =
          changed.contains(key) &&
          (b == null ? meta[key] == null : (r.rev != b.rev || r.by != b.by));
      if (!concurrent) {
        out[key] = l.beats(r) ? l : r;
        continue;
      }
      // Both sides changed it since this device last synced.
      if (l.isTombstone != r.isTombstone) {
        // Edit against delete: the edit stays, as a newer revision.
        final kept = l.isTombstone ? r : l;
        out[key] = SyncRecord(rev: ++lamport, by: device, data: kept.data);
        continue;
      }
      final winner = l.beats(r) ? l : r;
      final loser = identical(winner, l) ? r : l;
      out[key] = winner;
      if (key.startsWith('n:') &&
          loser.data != null &&
          winner.data != null &&
          hashOf(loser.data!) != hashOf(winner.data!)) {
        conflicts.add(SyncConflict(key, loser.data!));
      }
    }

    // 4. Forget tombstones old enough that every device has seen them.
    out.removeWhere(
      (_, r) =>
          r.isTombstone &&
          r.deadSince != null &&
          now.difference(r.deadSince!) > tombstoneLife,
    );
    for (final e in out.entries.toList()) {
      if (e.value.isTombstone && e.value.deadSince == null) {
        out[e.key] = SyncRecord(
          rev: e.value.rev,
          by: e.value.by,
          deadSince: now,
        );
      }
    }

    final newMeta = {
      for (final e in out.entries)
        e.key: SyncMeta(
          e.value.rev,
          e.value.by,
          e.value.data == null ? tombstoneHash : hashOf(e.value.data!),
          e.value.deadSince,
        ),
    };
    return SyncResult(
      records: out,
      meta: newMeta,
      clock: lamport,
      conflicts: conflicts,
      changedLocally: changed,
    );
  }
}

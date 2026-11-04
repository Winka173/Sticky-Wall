import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/board.dart';
import '../models/note.dart';
import 'audio_service.dart';
import 'image_service.dart';

/// A parsed backup: boards, notes and the threads between them, plus the
/// photo and voice-note files they use (stored name → bytes).
class Backup {
  Backup({
    required this.boards,
    required this.notes,
    this.links,
    this.photos = const {},
    this.wallPhotos = const {},
    this.audios = const {},
    this.version,
    this.exportedAt,
    this.sizeBytes = 0,
  });

  /// The format version written in the file, if any.
  final int? version;

  /// When the backup was made, if the file says.
  final DateTime? exportedAt;

  /// How big the document was, for the restore preview.
  final int sizeBytes;

  final List<Board> boards;
  final List<Note> notes;

  /// Null for a backup from before threads were saved: the threads on the
  /// wall then stay where both ends still exist.
  final List<NoteLink>? links;
  final Map<String, Uint8List> photos;
  final Map<String, Uint8List> wallPhotos;

  /// Voice-note recordings; empty for a backup from before voice notes.
  final Map<String, Uint8List> audios;
}

/// Why a document could not be read as a backup, so the import dialog can
/// say which.
enum BackupProblem { notJson, notBackup, newerVersion }

/// A [FormatException] that knows its [problem].
class BackupFormatException extends FormatException {
  const BackupFormatException(this.problem, String message) : super(message);

  final BackupProblem problem;
}

/// Exports/imports the whole wall as a single JSON document, so a user can
/// move their notes to a new device or keep a safety copy.
///
/// Version 2 adds the photo files (base64 under `photos` / `wallPhotos`, by
/// stored name) and the voice-note recordings (`audios`, likewise — an
/// optional section, so older version 2 documents simply have none);
/// version 1 documents have no files and still load.
class BackupService {
  static const _version = 2;

  String encode(
    List<Board> boards,
    List<Note> notes, [
    List<NoteLink> links = const [],
    Map<String, Uint8List> photos = const {},
    Map<String, Uint8List> wallPhotos = const {},
    Map<String, Uint8List> audios = const {},
  ]) {
    return const JsonEncoder.withIndent('  ').convert({
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'boards': boards.map((b) => b.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'links': links.map((l) => l.toJson()).toList(),
      if (photos.isNotEmpty)
        'photos': photos.map((k, v) => MapEntry(k, base64Encode(v))),
      if (wallPhotos.isNotEmpty)
        'wallPhotos': wallPhotos.map((k, v) => MapEntry(k, base64Encode(v))),
      if (audios.isNotEmpty)
        'audios': audios.map((k, v) => MapEntry(k, base64Encode(v))),
    });
  }

  /// [encode] with the bytes of every photo and recording the notes and
  /// walls refer to (trashed notes included, since the trash round-trips). A
  /// file that has gone missing is skipped rather than failing the backup.
  Future<String> encodeWithPhotos(
    List<Board> boards,
    List<Note> notes,
    List<NoteLink> links,
  ) async {
    final photos = <String, Uint8List>{};
    for (final name in {for (final n in notes) n.imagePath}) {
      final bytes = await ImageService.readStored(name);
      if (bytes != null) photos[name] = bytes;
    }
    final wallPhotos = <String, Uint8List>{};
    for (final name in {
      for (final b in boards) ...[b.wallImage, b.savedWallImage],
    }) {
      final bytes = await ImageService.readStored(name, wall: true);
      if (bytes != null) wallPhotos[name] = bytes;
    }
    final audios = <String, Uint8List>{};
    for (final name in {for (final n in notes) n.audioPath}) {
      final bytes = await AudioService.readStored(name);
      if (bytes != null) audios[name] = bytes;
    }
    return encode(boards, notes, links, photos, wallPhotos, audios);
  }

  /// Parses a backup document. Throws [BackupFormatException] (a
  /// [FormatException]) on anything that is not a backup this app can read.
  Backup decode(String source) {
    final Object? data;
    try {
      data = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException(BackupProblem.notJson, 'Not JSON');
    }
    if (data is! Map<String, dynamic>) {
      throw const BackupFormatException(
        BackupProblem.notBackup,
        'Not a Sticky Wall backup',
      );
    }
    // A newer app may store things this one would silently drop.
    final version = data['version'];
    if (version is int && version > _version) {
      throw const BackupFormatException(
        BackupProblem.newerVersion,
        'Backup made by a newer version',
      );
    }
    try {
      final boards = (data['boards'] as List<dynamic>? ?? [])
          .map((e) => Board.fromJson(e as Map<String, dynamic>))
          .toList();
      final notes = (data['notes'] as List<dynamic>? ?? [])
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList();
      // Older backups have no threads; they leave the wall's threads be.
      final links = (data['links'] as List<dynamic>?)
          ?.map((e) => NoteLink.fromJson(e as Map<String, dynamic>))
          .toList();
      if (boards.isEmpty) throw const FormatException('No boards');
      return Backup(
        boards: boards,
        notes: notes,
        links: links,
        photos: _files(data['photos']),
        wallPhotos: _files(data['wallPhotos']),
        audios: _files(data['audios']),
        version: version is int ? version : null,
        exportedAt: DateTime.tryParse(data['exportedAt'] as String? ?? ''),
        sizeBytes: source.length,
      );
    } catch (_) {
      // Valid JSON in some other shape (or a backup with no boards).
      throw const BackupFormatException(
        BackupProblem.notBackup,
        'Not a Sticky Wall backup',
      );
    }
  }

  static Map<String, Uint8List> _files(Object? raw) {
    if (raw is! Map<String, dynamic>) return const {};
    return {
      for (final e in raw.entries)
        if (e.value is String) e.key: base64Decode(e.value as String),
    };
  }

  /// Puts the backup's photo and recording files back in the app's folders,
  /// before the notes that use them are restored.
  Future<void> restorePhotos(Backup backup) async {
    for (final e in backup.photos.entries) {
      await ImageService.writeStored(e.key, e.value);
    }
    for (final e in backup.wallPhotos.entries) {
      await ImageService.writeStored(e.key, e.value, wall: true);
    }
    for (final e in backup.audios.entries) {
      await AudioService.writeStored(e.key, e.value);
    }
  }

  /// Writes the same document as [encodeWithPhotos] straight into [file],
  /// one file at a time: a wall with hundreds of photos and recordings never
  /// holds them all — and their base64 copies — in memory at once.
  Future<void> writeTo(
    File file,
    List<Board> boards,
    List<Note> notes,
    List<NoteLink> links,
  ) async {
    final sink = file.openWrite();
    try {
      String key(String k) => jsonEncode(k);
      sink
        ..write('{"version":$_version,')
        ..write('"exportedAt":${jsonEncode(DateTime.now().toIso8601String())},')
        ..write(
          '"boards":${jsonEncode(boards.map((b) => b.toJson()).toList())},',
        )
        ..write('"notes":${jsonEncode(notes.map((n) => n.toJson()).toList())},')
        ..write('"links":${jsonEncode(links.map((l) => l.toJson()).toList())}');
      Future<void> section(
        String name,
        Iterable<String> files,
        Future<Uint8List?> Function(String stored) read,
      ) async {
        var first = true;
        for (final stored in files) {
          final bytes = await read(stored);
          if (bytes == null) continue;
          sink
            ..write(first ? ',${key(name)}:{' : ',')
            ..write('${key(stored)}:"${base64Encode(bytes)}"');
          first = false;
          // Let the sink drain before reading the next file.
          await sink.flush();
        }
        if (!first) sink.write('}');
      }

      await section('photos', {
        for (final n in notes)
          if (n.imagePath.isNotEmpty) n.imagePath,
      }, ImageService.readStored);
      await section('wallPhotos', {
        for (final b in boards)
          for (final w in [b.wallImage, b.savedWallImage])
            if (w.isNotEmpty) w,
      }, (stored) => ImageService.readStored(stored, wall: true));
      await section('audios', {
        for (final n in notes)
          if (n.audioPath.isNotEmpty) n.audioPath,
      }, AudioService.readStored);
      sink.write('}');
    } finally {
      await sink.close();
    }
  }

  /// Writes the backup to a temp file and opens the system share sheet.
  /// [subject] is the localized title the share target may show.
  Future<void> share(
    List<Board> boards,
    List<Note> notes,
    List<NoteLink> links, {
    required String subject,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sticky-wall-backup.json');
    await writeTo(file, boards, notes, links);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: subject,
      ),
    );
  }
}

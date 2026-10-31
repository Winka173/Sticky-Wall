import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/board.dart';
import '../models/note.dart';
import 'image_service.dart';

/// A parsed backup: boards, notes and the threads between them, plus the
/// photo files they show (stored name → bytes).
class Backup {
  Backup({
    required this.boards,
    required this.notes,
    this.links = const [],
    this.photos = const {},
    this.wallPhotos = const {},
  });

  final List<Board> boards;
  final List<Note> notes;
  final List<NoteLink> links;
  final Map<String, Uint8List> photos;
  final Map<String, Uint8List> wallPhotos;
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
/// stored name); version 1 documents have none and still load.
class BackupService {
  static const _version = 2;

  String encode(
    List<Board> boards,
    List<Note> notes, [
    List<NoteLink> links = const [],
    Map<String, Uint8List> photos = const {},
    Map<String, Uint8List> wallPhotos = const {},
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
    });
  }

  /// [encode] with the bytes of every photo the notes and walls refer to
  /// (trashed notes included, since the trash round-trips). A file that has
  /// gone missing is skipped rather than failing the whole backup.
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
    return encode(boards, notes, links, photos, wallPhotos);
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
      // Older backups have no threads; they restore without any.
      final links = (data['links'] as List<dynamic>? ?? [])
          .map((e) => NoteLink.fromJson(e as Map<String, dynamic>))
          .toList();
      if (boards.isEmpty) throw const FormatException('No boards');
      return Backup(
        boards: boards,
        notes: notes,
        links: links,
        photos: _files(data['photos']),
        wallPhotos: _files(data['wallPhotos']),
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

  /// Puts the backup's photo files back in the app's folders, before the
  /// notes that show them are restored.
  Future<void> restorePhotos(Backup backup) async {
    for (final e in backup.photos.entries) {
      await ImageService.writeStored(e.key, e.value);
    }
    for (final e in backup.wallPhotos.entries) {
      await ImageService.writeStored(e.key, e.value, wall: true);
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
    await file.writeAsString(await encodeWithPhotos(boards, notes, links));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: subject,
      ),
    );
  }
}

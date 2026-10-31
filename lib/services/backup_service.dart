import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/board.dart';
import '../models/note.dart';

/// A parsed backup: boards, notes and the threads between them.
class Backup {
  Backup({required this.boards, required this.notes, this.links = const []});

  final List<Board> boards;
  final List<Note> notes;
  final List<NoteLink> links;
}

/// Exports/imports the whole wall as a single JSON document, so a user can
/// move their notes to a new device or keep a safety copy.
class BackupService {
  static const _version = 1;

  String encode(
    List<Board> boards,
    List<Note> notes, [
    List<NoteLink> links = const [],
  ]) {
    return const JsonEncoder.withIndent('  ').convert({
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'boards': boards.map((b) => b.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'links': links.map((l) => l.toJson()).toList(),
    });
  }

  /// Parses a backup document. Throws [FormatException] on malformed input.
  Backup decode(String source) {
    final data = jsonDecode(source);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Not a Sticky Wall backup');
    }
    // A newer app may store things this one would silently drop.
    final version = data['version'];
    if (version is int && version > _version) {
      throw const FormatException('Backup made by a newer version');
    }
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
    if (boards.isEmpty) {
      throw const FormatException('Backup contains no boards');
    }
    return Backup(boards: boards, notes: notes, links: links);
  }

  /// Writes the backup to a temp file and opens the system share sheet.
  Future<void> share(
    List<Board> boards,
    List<Note> notes,
    List<NoteLink> links,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sticky-wall-backup.json');
    await file.writeAsString(encode(boards, notes, links));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Sticky Wall backup',
      ),
    );
  }
}

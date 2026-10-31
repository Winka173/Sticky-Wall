import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_service.dart';
import 'image_service.dart';
import 'notes_controller.dart';
import 'settings_controller.dart';

/// The weekly safety copy: on app start, when it is switched on and the last
/// one is a week old (or there is none), the whole wall is written with
/// [BackupService.writeTo] into `<documents>/backups/`, named by date, and
/// only the newest [keep] are kept.
///
/// Nothing here may hold up or break the app: [runIfDue] swallows every
/// error (with a debug print) and is called without being awaited.
class AutoBackup {
  AutoBackup._();

  static const interval = Duration(days: 7);
  static const keep = 4;
  static const _folder = 'backups';
  static final _name = RegExp(r'^sticky-wall-(\d{4}-\d{2}-\d{2})\.json$');

  /// Whether a backup is owed at [now], the last one having been at [last].
  /// A stamp in the future (the clock was turned back) counts as owed, or
  /// no backup would be made until the clock caught up.
  static bool isDue(DateTime? last, DateTime now) =>
      last == null || last.isAfter(now) || now.difference(last) >= interval;

  /// The file name for a backup made on [at]'s day: sortable by name.
  static String fileName(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'sticky-wall-${at.year}-${two(at.month)}-${two(at.day)}.json';
  }

  static Future<Directory> _dir() async {
    final docs = await ImageService.documentsPath();
    return Directory('$docs/$_folder');
  }

  /// The day an automatic backup was made, read from its name.
  static DateTime? dateOf(File file) {
    final m = _name.firstMatch(file.uri.pathSegments.last);
    return m == null ? null : DateTime.tryParse(m.group(1)!);
  }

  /// The automatic backups on this device, newest first.
  static Future<List<File>> list() async {
    final dir = await _dir();
    if (!dir.existsSync()) return const [];
    final files = <File>[];
    await for (final e in dir.list()) {
      if (e is File && _name.hasMatch(e.uri.pathSegments.last)) files.add(e);
    }
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// The newest automatic backup, or null when there is none.
  static Future<File?> latest() async {
    final all = await list();
    return all.isEmpty ? null : all.first;
  }

  /// Writes a backup now (today's file is replaced if there is one) and
  /// deletes all but the newest [keep]. Written to a side file first and
  /// renamed, so a crash half way never leaves a broken "latest" behind.
  static Future<File> write(NotesController notes, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final dir = await _dir();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final target = File('${dir.path}/${fileName(at)}');
    final part = File('${target.path}.part');
    await BackupService().writeTo(
      part,
      notes.boards,
      notes.allNotes,
      notes.links,
    );
    if (target.existsSync()) target.deleteSync();
    final done = await part.rename(target.path);
    await prune();
    return done;
  }

  /// Deletes every automatic backup but the newest [keep].
  static Future<void> prune() async {
    final all = await list();
    for (final old in all.skip(keep)) {
      try {
        await old.delete();
      } catch (e) {
        debugPrint('Could not delete old backup ${old.path}: $e');
      }
    }
  }

  /// The start-up check: writes a backup when one is due and switched on.
  /// Returns the file written, or null when none was (not due, switched off,
  /// or something failed — which is only logged).
  static Future<File?> runIfDue(
    SettingsController settings,
    NotesController notes, {
    DateTime? now,
  }) async {
    try {
      final at = now ?? DateTime.now();
      if (!settings.autoBackup || !isDue(settings.lastAutoBackup, at)) {
        return null;
      }
      final file = await write(notes, now: at);
      await settings.markAutoBackup(at);
      return file;
    } catch (e) {
      debugPrint('Automatic backup skipped: $e');
      return null;
    }
  }

  /// Opens the share sheet with [file] (an automatic backup).
  static Future<void> share(File file, {required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: subject,
      ),
    );
  }
}

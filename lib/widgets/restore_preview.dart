import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/backup_service.dart';
import '../services/notes_controller.dart';
import '../theme.dart';

/// How a backup is to be loaded.
enum RestoreMode { merge, replace }

/// What a backup holds and what loading it would do, before anything
/// changes: when it was made, how big it is, how many boards, notes,
/// photos, voice notes, threads, stickers and locked boards, and how much of
/// it is already here. Returns the chosen way to load it, or null.
Future<RestoreMode?> showRestorePreview(
  BuildContext context, {
  required Backup backup,
  required NotesController notes,
}) {
  return showModalBottomSheet<RestoreMode>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RestorePreview(backup: backup, notes: notes),
  );
}

class _RestorePreview extends StatelessWidget {
  const _RestorePreview({required this.backup, required this.notes});

  final Backup backup;
  final NotesController notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final made = backup.exportedAt?.toLocal();
    final live = backup.notes.where((n) => !n.isTrashed).toList();
    final trashed = backup.notes.length - live.length;
    final overlap = notes.backupOverlap(backup.boards, backup.notes);
    final mb = (backup.sizeBytes / (1024 * 1024)).toStringAsFixed(
      backup.sizeBytes < 1024 * 1024 ? 2 : 1,
    );
    final rows = [
      (Icons.dashboard_outlined, l10n.restoreBoards, '${backup.boards.length}'),
      (
        Icons.sticky_note_2_outlined,
        l10n.restoreNotes,
        trashed == 0
            ? '${live.length}'
            : '${live.length} · ${l10n.restoreInTrash(trashed)}',
      ),
      (Icons.photo_outlined, l10n.restorePhotos, '${backup.photos.length}'),
      (Icons.voicemail, l10n.restoreRecordings, '${backup.audios.length}'),
      (Icons.timeline, l10n.restoreThreads, '${backup.links?.length ?? 0}'),
      (
        Icons.emoji_emotions_outlined,
        l10n.restoreStickers,
        '${live.where((n) => n.type == NoteType.sticker).length}',
      ),
      (
        Icons.lock_outline,
        l10n.restoreLocked,
        '${backup.boards.where((b) => b.isPrivate).length}',
      ),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.restoreTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (made != null)
                  l10n.restoreMade(
                    '${dates.formatMediumDate(made)} '
                    '${dates.formatTimeOfDay(TimeOfDay.fromDateTime(made))}',
                  )
                else
                  l10n.restoreUnknownDate,
                l10n.restoreSize(mb),
                if (backup.version != null) 'v${backup.version}',
              ].join(' · '),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 12),
            for (final (icon, label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.inkSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label, style: const TextStyle(fontSize: 16)),
                    ),
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (overlap.boards + overlap.notes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.restoreConflicts(overlap.boards, overlap.notes),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.warnText,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _Choice(
              icon: Icons.call_merge,
              title: l10n.restoreMerge,
              hint: l10n.restoreMergeHint,
              onTap: () => Navigator.pop(context, RestoreMode.merge),
            ),
            const SizedBox(height: 10),
            _Choice(
              icon: Icons.swap_horiz,
              title: l10n.restoreReplace,
              hint: l10n.restoreReplaceHint,
              onTap: () => Navigator.pop(context, RestoreMode.replace),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        alignment: Alignment.centerLeft,
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                ),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

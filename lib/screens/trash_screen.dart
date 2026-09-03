import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/notes_controller.dart';
import '../theme.dart';
import '../widgets/note_views.dart';
import '../widgets/wall_background.dart';

/// Notes that were deleted in the last 30 days: restore them, throw them out
/// for good, or empty the whole bin.
class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key, required this.notes});

  final NotesController notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: notes,
      builder: (context, _) {
        final wall = wallFor(notes.currentBoard, night: isNight(context));
        final trashed = notes.trashed;
        final text = wall.wallText;
        return Stack(
          children: [
            Positioned.fill(child: WallBackground(wall: wall, decor: false)),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: text,
                elevation: 0,
                title: Text(
                  l10n.trash,
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 26,
                    color: text,
                    shadows: wall.wallTextShadows,
                  ),
                ),
                actions: [
                  if (trashed.isNotEmpty)
                    IconButton(
                      tooltip: l10n.emptyTrash,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: () => _confirmEmpty(context, l10n),
                    ),
                ],
              ),
              body: trashed.isEmpty
                  ? _Empty(wall: wall, l10n: l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: trashed.length,
                      itemBuilder: (context, i) => _TrashTile(
                        key: ValueKey(trashed[i].guid),
                        note: trashed[i],
                        daysLeft: notes.daysLeft(trashed[i]),
                        onRestore: () {
                          notes.restore(trashed[i]);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(l10n.restored)),
                            );
                        },
                        onPurge: () => notes.purge(trashed[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmEmpty(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.emptyTrashConfirm(notes.trashCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
    if (ok == true) notes.emptyTrash();
  }
}

/// One deleted note: a preview, when it was deleted and how long it has
/// left, plus restore / delete-forever buttons.
class _TrashTile extends StatelessWidget {
  const _TrashTile({
    super.key,
    required this.note,
    required this.daysLeft,
    required this.onRestore,
    required this.onPurge,
  });

  final Note note;
  final int daysLeft;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  String _preview(AppLocalizations l10n) {
    if (note.type == NoteType.checklist) {
      final head = note.content.trim();
      final items = note.checklist.map((i) => i.text).join(' · ');
      return [head, items].where((s) => s.isNotEmpty).join('\n');
    }
    if (note.content.trim().isNotEmpty) return note.content;
    return switch (note.type) {
      NoteType.link => note.url,
      NoteType.drawing => '✏️',
      NoteType.photo => '📷 ${l10n.typePhoto}',
      _ => note.content,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final deleted = note.deletedAt!;
    final when =
        '${ml.formatShortMonthDay(deleted)} '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(deleted))}';
    final scale = Theme.of(context).extension<NoteTextScale>()?.scale ?? 1;
    final expiring = daysLeft <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: paperDecoration(context, note),
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.emoji.isEmpty
                        ? _preview(l10n)
                        : '${note.emoji} ${_preview(l10n)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16 * scale,
                      height: 1.3,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.deletedOn(when)} · ${l10n.daysLeft(daysLeft)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: expiring
                          ? AppColors.deleteIcon
                          : AppColors.inkSoft,
                      fontWeight: expiring ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: l10n.restore,
                  icon: const Icon(
                    Icons.restore_from_trash_outlined,
                    color: AppColors.ink,
                  ),
                  onPressed: onRestore,
                ),
                IconButton(
                  tooltip: l10n.deleteForever,
                  icon: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.deleteIcon,
                  ),
                  onPressed: onPurge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown when nothing is in the trash.
class _Empty extends StatelessWidget {
  const _Empty({required this.wall, required this.l10n});

  final WallStyle wall;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final faded = wall.wallTextFaded;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 44, color: faded),
            const SizedBox(height: 12),
            Text(
              l10n.trashEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: faded,
                shadows: wall.wallTextShadows,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trashHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: faded.withValues(alpha: 0.75),
                shadows: wall.wallTextShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../models/note.dart';
import '../services/notes_controller.dart';
import '../theme.dart';
import '../util/rich_note.dart';
import '../widgets/note_views.dart';
import '../widgets/wall_background.dart';

/// Boards and notes deleted in the last 30 days: restore them, throw them
/// out for good, or empty the whole bin. A board comes back whole, with its
/// notes, threads, drawing and theme.
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
        final boards = notes.deletedBoards;
        final empty = trashed.isEmpty && boards.isEmpty;
        final text = wall.wallText;
        Widget heading(String label) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
          child: Semantics(
            header: true,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: text,
                shadows: wall.wallTextShadows,
              ),
            ),
          ),
        );
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
                  if (!empty)
                    IconButton(
                      tooltip: l10n.emptyTrash,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: () => _confirmEmpty(context, l10n),
                    ),
                ],
              ),
              body: empty
                  ? _Empty(wall: wall, l10n: l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount:
                          trashed.length +
                          (boards.isEmpty ? 0 : boards.length + 1) +
                          (boards.isNotEmpty && trashed.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (boards.isNotEmpty) {
                          if (i == 0) return heading(l10n.trashBoards);
                          if (i <= boards.length) {
                            final board = boards[i - 1];
                            return _BoardTile(
                              key: ValueKey('board-${board.id}'),
                              board: board,
                              name: _nameOf(l10n, board),
                              notes: notes.noteCountOn(board.id),
                              daysLeft: notes.boardDaysLeft(board),
                              onRestore: () {
                                notes.restoreBoard(board.id);
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.boardRestored(
                                          _nameOf(l10n, board),
                                        ),
                                      ),
                                    ),
                                  );
                              },
                              onPurge: () =>
                                  _confirmPurgeBoard(context, l10n, board),
                            );
                          }
                          if (i == boards.length + 1) {
                            return heading(l10n.trashNotes);
                          }
                          i -= boards.length + 2;
                        }
                        final note = trashed[i];
                        return _TrashTile(
                          key: ValueKey(note.guid),
                          note: note,
                          boardName: _boardName(l10n, note.boardId),
                          daysLeft: notes.daysLeft(note),
                          onRestore: () {
                            notes.restore(note);
                            // Restore falls back to the first board when the
                            // note's own is gone; say where it really went.
                            final where = _boardName(l10n, note.boardId);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    where == null
                                        ? l10n.restored
                                        : l10n.restoredTo(where),
                                  ),
                                ),
                              );
                          },
                          onPurge: () => _confirmPurge(context, l10n, note),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _nameOf(AppLocalizations l10n, Board b) {
    final name = b.name.isEmpty ? l10n.defaultBoardName : b.name;
    return b.icon.isEmpty ? name : '${b.icon} $name';
  }

  Future<void> _confirmPurgeBoard(
    BuildContext context,
    AppLocalizations l10n,
    Board board,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteBoardForeverConfirm(_nameOf(l10n, board))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteIcon),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
    if (ok == true) notes.deleteBoardForever(board.id);
  }

  /// The name of the board with [id] as its tab shows it, or null when that
  /// board has been deleted.
  String? _boardName(AppLocalizations l10n, String id) {
    for (final b in notes.boards) {
      if (b.id != id) continue;
      final name = b.name.isEmpty ? l10n.defaultBoardName : b.name;
      return b.icon.isEmpty ? name : '${b.icon} $name';
    }
    return null;
  }

  /// Delete forever sits right beside Restore: one stray tap must not cost
  /// the note.
  Future<void> _confirmPurge(
    BuildContext context,
    AppLocalizations l10n,
    Note note,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteForeverConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteIcon),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
    if (ok == true) notes.purge(note);
  }

  Future<void> _confirmEmpty(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          l10n.emptyTrashConfirm(notes.trashCount + notes.deletedBoards.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteIcon),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
    if (ok == true) notes.emptyTrash();
  }
}

/// One deleted note: a preview, where it came from, when it was deleted and
/// how long it has left, then labelled restore / delete-forever buttons.
class _TrashTile extends StatelessWidget {
  const _TrashTile({
    super.key,
    required this.note,
    required this.boardName,
    required this.daysLeft,
    required this.onRestore,
    required this.onPurge,
  });

  final Note note;

  /// The board the note was on; null when that board no longer exists.
  final String? boardName;
  final int daysLeft;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  String _preview(AppLocalizations l10n) {
    if (note.type == NoteType.checklist) {
      final head = note.content.trim();
      final items = note.checklist.map((i) => i.text).join(' · ');
      return [head, items].where((s) => s.isNotEmpty).join('\n');
    }
    if (note.content.trim().isNotEmpty) return plainNoteText(note.content);
    return switch (note.type) {
      NoteType.link => note.url,
      NoteType.drawing => '✏️',
      NoteType.photo => '📷 ${l10n.typePhoto}',
      NoteType.audio => '🎙️ ${l10n.typeAudio}',
      NoteType.sticker => l10n.typeSticker,
      _ => plainNoteText(note.content),
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
    final board = boardName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: paperDecoration(context, note),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
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
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  if (board != null) TextSpan(text: '$board · '),
                  TextSpan(text: '${l10n.deletedOn(when)} · '),
                  TextSpan(
                    text: l10n.daysLeft(daysLeft),
                    style: expiring
                        ? const TextStyle(
                            color: AppColors.warnText,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
            // Labelled actions along the bottom: icon-only buttons stacked
            // at the side read as decoration and left the card half empty.
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                  icon: const Icon(Icons.restore_from_trash_outlined),
                  label: Text(l10n.restore),
                  onPressed: onRestore,
                ),
                // Quiet on every card, so the red stays for the notes about
                // to expire; the confirmation is where it turns red.
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.inkSoft,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l10n.deleteForever),
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

/// A whole board in the Trash: its name, how much it holds, when it goes,
/// and Restore / Delete forever. Its notes are not listed, so a locked board
/// shows nothing of what is on it.
class _BoardTile extends StatelessWidget {
  const _BoardTile({
    super.key,
    required this.board,
    required this.name,
    required this.notes,
    required this.daysLeft,
    required this.onRestore,
    required this.onPurge,
  });

  final Board board;
  final String name;
  final int notes;
  final int daysLeft;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final deleted = board.deletedAt ?? DateTime.now();
    final expiring = daysLeft <= 3;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadii.control),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  board.isPrivate
                      ? Icons.lock_outline
                      : Icons.dashboard_outlined,
                  size: 20,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${l10n.boardInTrash(notes)} · '),
                  TextSpan(
                    text:
                        '${l10n.deletedOn(ml.formatShortMonthDay(deleted))} · ',
                  ),
                  TextSpan(
                    text: l10n.daysLeft(daysLeft),
                    style: expiring
                        ? const TextStyle(
                            color: AppColors.warnText,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                  icon: const Icon(Icons.restore_from_trash_outlined),
                  label: Text(l10n.restore),
                  onPressed: onRestore,
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.inkSoft,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l10n.deleteForever),
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
                color: faded,
                shadows: wall.wallTextShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

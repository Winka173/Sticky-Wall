import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../screens/gallery_screen.dart';
import '../services/notes_controller.dart';
import '../services/theme_packs.dart';
import '../theme.dart';
import 'wall_background.dart';

/// Every board as a card: a picture of its wall drawn from its notes, its
/// name and how many notes it holds. Tap to open one; its ⋮ duplicates or
/// deletes it. A shut private board shows only its lock.
Future<void> showBoardPicker(
  BuildContext context, {
  required NotesController notes,
  required Future<void> Function(Board board) onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: notes,
      builder: (context, _) => _BoardPicker(notes: notes, onDelete: onDelete),
    ),
  );
}

class _BoardPicker extends StatelessWidget {
  const _BoardPicker({required this.notes, required this.onDelete});

  final NotesController notes;
  final Future<void> Function(Board board) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.sizeOf(context).height;
    // Pinned boards first, then the most recently edited.
    final ordered = List.of(notes.boards)
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        final ta = notes.lastEdited(a.id);
        final tb = notes.lastEdited(b.id);
        // Boards with nothing on them go last.
        if (ta == null || tb == null) {
          return (tb == null ? 0 : 1) - (ta == null ? 0 : 1);
        }
        return tb.compareTo(ta);
      });
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.allBoards,
              style: const TextStyle(fontSize: 20, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                itemCount: ordered.length,
                itemBuilder: (context, i) => _BoardCard(
                  board: ordered[i],
                  notes: notes,
                  onDelete: onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.board,
    required this.notes,
    required this.onDelete,
  });

  final Board board;
  final NotesController notes;
  final Future<void> Function(Board board) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = board.id == notes.currentBoardId;
    final shut = !notes.isOpen(board);
    final onBoard = [
      for (final n in notes.allNotes)
        if (n.boardId == board.id && !n.isTrashed) n,
    ];
    final name = board.name.isEmpty ? l10n.defaultBoardName : board.name;
    final wall = wallFor(board, night: isNight(context));
    return Semantics(
      button: true,
      selected: selected,
      label: '$name, ${l10n.boardNoteCount(shut ? 0 : onBoard.length)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.control),
        onTap: () {
          notes.selectBoard(board.id);
          Navigator.pop(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  border: Border.all(
                    color: selected ? AppColors.ink : AppColors.inkHint,
                    width: selected ? 3 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: shut
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            WallBackground(wall: wall, decor: false),
                            Center(
                              child: Icon(
                                Icons.lock_outline,
                                size: 36,
                                color: wall.wallText,
                              ),
                            ),
                          ],
                        )
                      : BoardPreview(
                          wall: wall,
                          notes: onBoard,
                          links: notes.linksOn(board.id),
                          pack: themePackById(board.themeId),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (board.icon.isNotEmpty) ...[
                  Text(board.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                ],
                if (board.favorite) ...[
                  const Icon(Icons.push_pin, size: 15),
                  const SizedBox(width: 2),
                ],
                if (board.isPrivate) ...[
                  const Icon(Icons.lock_outline, size: 15),
                  const SizedBox(width: 2),
                ],
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.moreActions,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) async {
                    if (v == 'duplicate') {
                      final copy = notes.duplicateBoard(
                        board.id,
                        l10n.boardCopyName(name),
                      );
                      // The copy is open now; the sheet steps aside so its
                      // Undo can be reached.
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(l10n.boardDuplicated),
                            action: SnackBarAction(
                              label: l10n.undo,
                              // Takes the copy back out entirely: it was
                              // never meant to wait in the Trash.
                              onPressed: () => notes
                                ..deleteBoard(copy.id)
                                ..deleteBoardForever(copy.id),
                            ),
                          ),
                        );
                    } else if (v == 'favorite') {
                      notes.toggleFavorite(board.id);
                    } else if (v == 'delete') {
                      await onDelete(board);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'favorite',
                      child: Text(
                        board.favorite ? l10n.unpinBoard : l10n.pinBoard,
                      ),
                    ),
                    if (!shut)
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(l10n.duplicateBoard),
                      ),
                    if (notes.boards.length > 1)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.deleteBoard,
                          style: const TextStyle(color: AppColors.deleteIcon),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Text(
              shut
                  ? l10n.boardPrivate
                  : [
                      l10n.boardNoteCount(onBoard.length),
                      if (notes.lastEdited(board.id) case final t?)
                        _edited(context, l10n, t),
                    ].join(' · '),
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Edited today", "Edited yesterday" or "Edited 3 Nov".
String _edited(BuildContext context, AppLocalizations l10n, DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(when.year, when.month, when.day);
  final ago = today.difference(day).inDays;
  if (ago <= 0) return l10n.editedToday;
  if (ago == 1) return l10n.editedYesterday;
  return l10n.editedOn(
    MaterialLocalizations.of(context).formatShortMonthDay(when),
  );
}

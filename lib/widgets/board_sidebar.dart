import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../services/notes_controller.dart';
import '../theme.dart';
import 'board_actions.dart';
import 'keyboard_tappable.dart';

/// Every board as a list down the left of a wide window (a tablet, a desktop
/// window) in place of the tab strip. Tap a board to open it, tap the open one
/// to edit, move or delete it, long-press and drag a row to reorder. A note
/// dragged from the wall can be dropped on any row: the screen finds the rows
/// through [chipKeys] and names the hovered one in [dropTarget].
class BoardSidebar extends StatelessWidget {
  const BoardSidebar({
    super.key,
    required this.notes,
    required this.dark,
    this.chipKeys,
    this.dropTarget,
    this.onMemoryWall,
  });

  /// Windows at least this wide (dp) get the list instead of the strip. Below
  /// it the wall would be left too narrow for the sample notes and for
  /// working in a row of cards (a 960 dp window has room for five across; with
  /// the list only three).
  static const minWindowWidth = 1000.0;

  /// Width of the list, margins included.
  static const width = 244.0;

  /// Whether a window [context] lives in is wide enough for the list.
  static bool fits(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= minWindowWidth;

  final NotesController notes;

  /// The wall is dark: the panel is dark with chalk words, as its tool pill.
  final bool dark;

  /// A key per board id, placed on that board's row.
  final Map<String, GlobalKey>? chipKeys;

  /// The board id a dragged note is hovering over, if any.
  final ValueListenable<String?>? dropTarget;

  /// Offered on the "+": a new board of photos.
  final VoidCallback? onMemoryWall;

  static final _noTarget = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = BoardActions(notes, onMemoryWall: onMemoryWall);
    final ink = dark ? AppColors.chalk : AppColors.ink;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 0, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Near-opaque like the tool pill: no blur over a moving wall.
            color: dark ? const Color(0xE62A2520) : const Color(0xEBFDFBF3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ink.withValues(alpha: 0.25)),
          ),
          child: ListenableBuilder(
            listenable: notes,
            builder: (context, _) {
              final boards = notes.boards;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.boardsTitle,
                        style: TextStyle(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      buildDefaultDragHandles: false,
                      onReorderItem: notes.reorderBoards,
                      itemCount: boards.length,
                      itemBuilder: (context, index) {
                        final board = boards[index];
                        final selected = board.id == notes.currentBoardId;
                        return Padding(
                          key: ValueKey('board-row-${board.id}'),
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ReorderableDelayedDragStartListener(
                            index: index,
                            child: ValueListenableBuilder<String?>(
                              valueListenable: dropTarget ?? _noTarget,
                              builder: (context, hovered, _) => _BoardRow(
                                key: chipKeys?[board.id],
                                board: board,
                                label: actions.displayName(l10n, board),
                                count: notes.isOpen(board)
                                    ? notes.allNotes
                                          .where(
                                            (n) =>
                                                n.boardId == board.id &&
                                                !n.isTrashed,
                                          )
                                          .length
                                    : null,
                                selected: selected,
                                highlighted: hovered == board.id,
                                dark: dark,
                                onTap: () => selected
                                    ? actions.manage(context, l10n, board)
                                    : notes.selectBoard(board.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(height: 1, color: ink.withValues(alpha: 0.2)),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _FooterButton(
                          icon: Icons.add,
                          label: l10n.newBoard,
                          ink: ink,
                          onTap: () => actions.newBoard(context),
                        ),
                        if (boards.length > 1)
                          _FooterButton(
                            icon: Icons.apps,
                            label: l10n.allBoards,
                            ink: ink,
                            onTap: () => actions.pick(context),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    super.key,
    required this.board,
    required this.label,
    required this.count,
    required this.selected,
    required this.highlighted,
    required this.dark,
    required this.onTap,
  });

  final Board board;
  final String label;

  /// Notes on the board; null for a shut private board (it shows a lock).
  final int? count;
  final bool selected;

  /// A dragged note is hovering over the row: drawn as a drop target.
  final bool highlighted;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final solid = MediaQuery.highContrastOf(context);
    final panelInk = dark ? AppColors.chalk : AppColors.ink;
    // The open board is the panel's ink turned over; a drop target is gold.
    final Color fill;
    final Color ink;
    if (highlighted) {
      fill = AppColors.accent;
      ink = AppColors.ink;
    } else if (selected) {
      fill = panelInk;
      ink = dark ? AppColors.ink : AppColors.chalk;
    } else {
      fill = Colors.transparent;
      ink = panelInk;
    }
    return KeyboardTappable(
      onActivate: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Semantics(
        button: true,
        selected: selected,
        hint: selected ? l10n.editBoard : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: highlighted
                  ? Border.all(color: AppColors.accent, width: 2)
                  : solid && !selected
                  ? Border.all(color: panelInk.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: board.icon.isEmpty
                      ? Icon(Icons.dashboard_outlined, size: 20, color: ink)
                      : Text(board.icon, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (count == null)
                  Icon(
                    Icons.lock_outline,
                    size: 17,
                    color: ink,
                    semanticLabel: l10n.boardPrivate,
                  )
                else
                  Text(
                    '$count',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                if (board.isPrivate && count != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.lock_outline,
                    size: 15,
                    color: ink,
                    semanticLabel: l10n.boardPrivate,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.ink,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KeyboardTappable(
      onActivate: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: ink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

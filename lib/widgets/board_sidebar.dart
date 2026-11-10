import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../services/notes_controller.dart';
import '../theme.dart';
import 'board_actions.dart';
import 'keyboard_tappable.dart';

/// The board list a wide window (a tablet, a desktop window) can open beside
/// the tab strip: every board with its note count, New board and All boards.
/// It floats over the wall, the way a canvas app's panels do, so opening or
/// closing it never moves a note; the tab strip stays where it was. Tap a
/// board to open it, tap the open one to edit, move or delete it, long-press
/// and drag a row to reorder. A note dragged from the wall can be dropped on
/// any row: the screen finds the rows through [chipKeys] and names the
/// hovered one in [dropTarget].
class BoardSidebar extends StatelessWidget {
  const BoardSidebar({
    super.key,
    required this.notes,
    required this.dark,
    required this.onClose,
    this.chipKeys,
    this.dropTarget,
    this.onMemoryWall,
  });

  /// Windows at least this wide (dp) offer the list; a phone has the strip
  /// and its drop tray.
  static const minWindowWidth = 600.0;

  /// Width of the panel.
  static const width = 260.0;

  /// Whether a window [context] lives in is wide enough to offer the list.
  static bool fits(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= minWindowWidth;

  final NotesController notes;

  /// The wall is dark: the panel is dark with chalk words, as its tool pill.
  final bool dark;

  /// Closes the panel (its own ✕).
  final VoidCallback onClose;

  /// A key per board id, placed on that board's row.
  final Map<String, GlobalKey>? chipKeys;

  /// The board id a dragged note is hovering over, if any.
  final ValueListenable<String?>? dropTarget;

  /// Offered on "New board": a new board of photos.
  final VoidCallback? onMemoryWall;

  static final _noTarget = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = BoardActions(notes, onMemoryWall: onMemoryWall);
    final ink = dark ? AppColors.chalk : AppColors.ink;
    return Material(
      key: const Key('board-panel'),
      type: MaterialType.transparency,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          // Solid: notes and their words passing underneath must not show
          // through a list you read (and no blur over a moving wall).
          color: dark ? const Color(0xFF2A2520) : AppColors.chalk,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ink.withValues(alpha: 0.2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40302318),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ListenableBuilder(
          listenable: notes,
          builder: (context, _) {
            final boards = notes.boards;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 4, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.boardsTitle,
                            style: TextStyle(
                              color: ink,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.boardPanelHide,
                        icon: Icon(Icons.close, color: ink, size: 20),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                // As tall as its boards, scrolling only past the space left.
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                    buildDefaultDragHandles: false,
                    onReorderItem: notes.reorderBoards,
                    proxyDecorator: (child, _, _) =>
                        Material(type: MaterialType.transparency, child: child),
                    itemCount: boards.length,
                    itemBuilder: (context, index) {
                      final board = boards[index];
                      final selected = board.id == notes.currentBoardId;
                      return Padding(
                        key: ValueKey('board-row-${board.id}'),
                        padding: const EdgeInsets.only(bottom: 2),
                        child: ReorderableDelayedDragStartListener(
                          index: index,
                          child: ValueListenableBuilder<String?>(
                            valueListenable: dropTarget ?? _noTarget,
                            builder: (context, hovered, _) => _BoardRow(
                              key: chipKeys?[board.id],
                              board: board,
                              label: actions.displayName(l10n, board),
                              count: notes.isOpen(board)
                                  ? _count(notes, board.id)
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
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: ink.withValues(alpha: 0.15),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FooterButton(
                          icon: Icons.add,
                          label: l10n.newBoard,
                          ink: ink,
                          onTap: () => actions.newBoard(context),
                        ),
                      ),
                      if (boards.length > 1)
                        IconButton(
                          tooltip: l10n.allBoards,
                          icon: Icon(Icons.apps, color: ink, size: 20),
                          onPressed: () => actions.pick(context),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static int _count(NotesController notes, String boardId) =>
      notes.allNotes.where((n) => n.boardId == boardId && !n.isTrashed).length;
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
    final panelInk = dark ? AppColors.chalk : AppColors.ink;
    // The open board is a soft tint of the panel's ink with a bar at its
    // start, not a slab of solid colour; a drop target is gold.
    final Color fill;
    final ink = highlighted ? AppColors.ink : panelInk;
    if (highlighted) {
      fill = AppColors.accent;
    } else if (selected) {
      fill = panelInk.withValues(alpha: dark ? 0.16 : 0.09);
    } else {
      fill = Colors.transparent;
    }
    return KeyboardTappable(
      onActivate: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        button: true,
        selected: selected,
        hint: selected ? l10n.editBoard : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 48,
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // The open board's marker: a short bar in the panel's ink.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 4,
                  height: selected && !highlighted ? 22 : 0,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: panelInk,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                if (board.isPrivate)
                  Padding(
                    padding: EdgeInsets.only(right: count == null ? 0 : 6),
                    child: Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: ink,
                      semanticLabel: l10n.boardPrivate,
                    ),
                  ),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
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
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 48,
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

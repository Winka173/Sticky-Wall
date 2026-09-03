import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../services/notes_controller.dart';
import '../theme.dart';
import 'action_sheet.dart';
import 'board_dialog.dart';

/// Horizontal strip of board "tabs" with add / edit / delete.
///
/// Tapping a chip switches boards; tapping the *selected* chip opens the
/// manage sheet — the little chevron on it is the hint that it does more.
/// Long-press and drag a chip to reorder boards. A note dragged up from the
/// wall can be dropped on a chip to move it to that board: the screen above
/// finds the chips through [chipKeys] and names the hovered one in
/// [dropTarget], which lights up.
class BoardBar extends StatefulWidget {
  const BoardBar({
    super.key,
    required this.notes,
    required this.textColor,
    this.chipKeys,
    this.dropTarget,
  });

  final NotesController notes;
  final Color textColor;

  /// A key per board id, placed on that board's chip.
  final Map<String, GlobalKey>? chipKeys;

  /// The board id a dragged note is hovering over, if any.
  final ValueListenable<String?>? dropTarget;

  static final _noTarget = ValueNotifier<String?>(null);

  @override
  State<BoardBar> createState() => _BoardBarState();
}

class _BoardBarState extends State<BoardBar> {
  final _scroll = ScrollController();

  /// On the selected chip, so it can be scrolled into view.
  final _selectedKey = GlobalKey();

  // What the strip last revealed the selected tab for; see [_revealSelected].
  String? _revealedBoard;
  double _revealedWidth = -1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _displayName(AppLocalizations l10n, Board board) =>
      board.name.isEmpty ? l10n.defaultBoardName : board.name;

  /// Scrolls the strip just far enough that the selected tab is fully
  /// visible — once when the board changes and once when the strip is
  /// resized (grid / list add a sort button to the toolbar, which narrows the
  /// strip and would otherwise leave the active tab half hidden behind the
  /// "+"). Not on every rebuild: the user may have scrolled the strip to
  /// look at the other boards.
  void _revealSelected(double width) {
    final id = widget.notes.currentBoardId;
    if (id == _revealedBoard && width == _revealedWidth) return;
    _revealedBoard = id;
    _revealedWidth = width;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSelected(approach: true),
    );
  }

  void _scrollToSelected({required bool approach}) {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    final chip = _selectedKey.currentContext?.findRenderObject();
    final viewport = RenderAbstractViewport.maybeOf(chip);
    if (chip == null || viewport == null) {
      // Too far off the end to have been built yet: jump roughly there —
      // proportionally along the strip — and finish once it exists.
      if (!approach) return;
      final boards = widget.notes.boards;
      final index = boards.indexWhere(
        (b) => b.id == widget.notes.currentBoardId,
      );
      if (index < 0 || boards.length < 2) return;
      position.jumpTo(position.maxScrollExtent * index / (boards.length - 1));
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToSelected(approach: false),
      );
      return;
    }
    const gap = 8.0;
    final start = viewport.getOffsetToReveal(chip, 0).offset - gap;
    final end = viewport.getOffsetToReveal(chip, 1).offset + gap;
    final double target;
    if (position.pixels > start || end < start) {
      // Cut off at the front — or wider than the strip, in which case its
      // beginning is the part worth showing.
      target = start;
    } else if (position.pixels < end) {
      target = end;
    } else {
      return;
    }
    position.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notes = widget.notes;
    final textColor = widget.textColor;
    final boards = notes.boards;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          // Shrink-wrapped so the "+" follows the last tab directly while
          // they fit, and only becomes a fixed trailing button once the
          // strip has to scroll.
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _revealSelected(constraints.maxWidth);
                return ReorderableListView.builder(
                  scrollController: _scroll,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(left: 16),
                  buildDefaultDragHandles: false,
                  onReorderItem: notes.reorderBoards,
                  proxyDecorator: (child, _, animation) => AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (context, child) => Transform.scale(
                      scale:
                          1 +
                          0.08 * Curves.easeInOut.transform(animation.value),
                      child: Material(color: Colors.transparent, child: child),
                    ),
                  ),
                  itemCount: boards.length,
                  itemBuilder: (context, index) {
                    final board = boards[index];
                    final selected = board.id == notes.currentBoardId;
                    return Padding(
                      key: ValueKey('board-${board.id}'),
                      padding: const EdgeInsets.only(right: 8),
                      child: ReorderableDelayedDragStartListener(
                        key: selected ? _selectedKey : null,
                        index: index,
                        child: ValueListenableBuilder<String?>(
                          valueListenable:
                              widget.dropTarget ?? BoardBar._noTarget,
                          builder: (context, hovered, _) => _BoardChip(
                            key: widget.chipKeys?[board.id],
                            board: board,
                            label: _displayName(l10n, board),
                            selected: selected,
                            highlighted: hovered == board.id,
                            textColor: textColor,
                            onTap: () => selected
                                ? _manage(context, l10n, board)
                                : notes.selectBoard(board.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Outside the scrolling strip, so it never hides behind the tabs
          // when their names are long or there are many of them.
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _AddChip(
              tooltip: l10n.newBoard,
              textColor: textColor,
              onTap: () => _create(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final draft = await showBoardDialog(context);
    if (draft == null || draft.name.isEmpty) return;
    widget.notes.addBoard(
      draft.name,
      icon: draft.icon,
      bold: draft.bold,
      italic: draft.italic,
      underline: draft.underline,
    );
  }

  Future<void> _manage(
    BuildContext context,
    AppLocalizations l10n,
    Board board,
  ) async {
    final action = await showActionSheet<String>(
      context,
      title: board.icon.isEmpty
          ? _displayName(l10n, board)
          : '${board.icon} ${_displayName(l10n, board)}',
      titleStyle: board.decorate(
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: [
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.editBoard),
          onTap: () => Navigator.pop(context, 'edit'),
        ),
        if (widget.notes.boards.length > 1)
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: AppColors.deleteIcon,
            ),
            title: Text(
              l10n.deleteBoard,
              style: const TextStyle(color: AppColors.deleteIcon),
            ),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
      ],
    );
    if (action == null || !context.mounted) return;

    if (action == 'edit') {
      final draft = await showBoardDialog(context, board: board);
      if (draft == null) return;
      widget.notes.updateBoard(
        board.id,
        name: draft.name,
        icon: draft.icon,
        bold: draft.bold,
        italic: draft.italic,
        underline: draft.underline,
      );
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l10n.deleteBoardConfirm(_displayName(l10n, board))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      if (ok == true) widget.notes.deleteBoard(board.id);
    }
  }
}

/// A board tab: icon + name in the board's own formatting, filled when it is
/// the current board. Tap to switch, long-press to edit / delete.
class _BoardChip extends StatelessWidget {
  const _BoardChip({
    super.key,
    required this.board,
    required this.label,
    required this.selected,
    required this.textColor,
    required this.onTap,
    this.highlighted = false,
  });

  final Board board;
  final String label;
  final bool selected;

  /// A dragged note is hovering over the chip: drawn as a drop target.
  final bool highlighted;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = board.icon;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: highlighted ? 1.08 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(
            icon.isEmpty ? 16 : 12,
            6,
            selected ? 10 : 16,
            6,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.accent.withValues(alpha: 0.45)
                : selected
                ? textColor.withValues(alpha: 0.18)
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted
                  ? AppColors.accent
                  : textColor.withValues(alpha: selected ? 0.9 : 0.35),
              width: highlighted || selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(icon, style: const TextStyle(fontSize: 16)),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: board.decorate(
                    TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      // The underline is drawn in the text color by default; on
                      // a dark wall that is the chalk, which is what we want.
                      decorationColor: textColor,
                    ),
                  ),
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(Icons.expand_more, size: 18, color: textColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trailing "+" tab that creates a new board.
class _AddChip extends StatelessWidget {
  const _AddChip({
    required this.tooltip,
    required this.textColor,
    required this.onTap,
  });

  final String tooltip;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: textColor.withValues(alpha: 0.35)),
          ),
          child: Icon(Icons.add, color: textColor, size: 20),
        ),
      ),
    );
  }
}

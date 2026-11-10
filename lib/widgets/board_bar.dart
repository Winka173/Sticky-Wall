import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../services/notes_controller.dart';
import '../theme.dart';
import 'board_actions.dart';
import 'board_picker.dart';
import 'keyboard_tappable.dart';

export 'board_actions.dart' show BoardActions, unlockPrivateBoard;

/// Horizontal strip of board "tabs" with add / edit / delete.
///
/// Up to four boards sit in the strip as tabs. From [collapseFrom] boards on
/// it keeps only the open board and the ones used most (pinned first, then
/// latest edited, as in the picker) with an "All 12" tab that opens the
/// picker; reordering is then done from the manage sheet or the picker. While
/// a note is dragged ([dragging]) a tray under the strip lists every board
/// as a drop target.
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
    this.chipKeys,
    this.dropTarget,
    this.dragging,
    this.onMemoryWall,
    this.onTogglePanel,
    this.panelOpen = false,
  });

  /// The most boards shown as plain tabs; one more and the strip collapses.
  static const collapseFrom = 5;

  /// Tabs kept when collapsed, the open board included.
  static const collapsedTabs = 3;

  final NotesController notes;

  /// A key per board id, placed on that board's chip.
  final Map<String, GlobalKey>? chipKeys;

  /// The board id a dragged note is hovering over, if any.
  final ValueListenable<String?>? dropTarget;

  /// Whether a note is being dragged: a collapsed strip then opens its tray.
  final ValueListenable<bool>? dragging;

  /// Offered on the "+" tab: a new board of photos.
  final VoidCallback? onMemoryWall;

  /// On a wide window, opens or closes the board list (BoardSidebar); its
  /// button then leads the strip in place of the picker's.
  final VoidCallback? onTogglePanel;

  /// The board list is open: its rows are the drop targets, so the tabs give
  /// up their keys and a drag opens no tray.
  final bool panelOpen;

  static final _noTarget = ValueNotifier<String?>(null);
  static final _notDragging = ValueNotifier<bool>(false);

  @override
  State<BoardBar> createState() => _BoardBarState();
}

class _BoardBarState extends State<BoardBar> {
  /// Width over which a tab fades out at either end of the strip; inside
  /// the strip's own 16 dp start padding, so a tab at rest is never dimmed.
  static const _edgeFade = 12.0;

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

  late final _actions = BoardActions(
    widget.notes,
    onMemoryWall: widget.onMemoryWall,
  );

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

  /// The boards that get a tab: all of them while there are few, otherwise
  /// the open board and the most used, kept in the boards' own order so the
  /// tabs do not shuffle when one is picked.
  List<Board> _tabBoards() {
    final boards = widget.notes.boards;
    if (boards.length < BoardBar.collapseFrom) return boards;
    final keep = <String>{widget.notes.currentBoardId};
    for (final b in boardsByUse(widget.notes)) {
      if (keep.length >= BoardBar.collapsedTabs) break;
      keep.add(b.id);
    }
    return [
      for (final b in boards)
        if (keep.contains(b.id)) b,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notes = widget.notes;
    final collapsed = notes.boards.length >= BoardBar.collapseFrom;
    final tabs = _tabBoards();

    return ValueListenableBuilder<bool>(
      valueListenable: widget.dragging ?? BoardBar._notDragging,
      builder: (context, dragging, _) {
        // While the tray lists every board, its chips carry the drop keys;
        // with the board list open, its rows do.
        final trayOpen = collapsed && dragging && !widget.panelOpen;
        final tabKeys = trayOpen || widget.panelOpen ? null : widget.chipKeys;
        // Passthrough: the strip keeps the parent's tight height, as the bare
        // row did.
        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  if (widget.onTogglePanel case final toggle?)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _CircleButton(
                        key: const Key('board-panel-toggle'),
                        icon: widget.panelOpen
                            ? Icons.view_sidebar
                            : Icons.view_sidebar_outlined,
                        label: widget.panelOpen
                            ? l10n.boardPanelHide
                            : l10n.boardPanelShow,
                        selected: widget.panelOpen,
                        mirror: true,
                        onTap: toggle,
                      ),
                    )
                  // Every board at once, with a picture of each, once there
                  // are a few: the tab strip alone means scrolling sideways
                  // to find one. A collapsed strip has its own "All" tab.
                  else if (notes.boards.length > 1 && !collapsed)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _CircleButton(
                        icon: Icons.apps,
                        label: l10n.allBoards,
                        onTap: () => _actions.pick(context),
                      ),
                    ),
                  // Shrink-wrapped so the "+" follows the last tab directly
                  // while they fit, and only becomes a fixed trailing button
                  // once the strip has to scroll.
                  Flexible(
                    // A tab scrolled half out of the strip fades away at the
                    // edge instead of being cut off hard against a button.
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) {
                        final fade = bounds.width <= 0
                            ? 0.0
                            : (_edgeFade / bounds.width).clamp(0.0, 0.5);
                        return LinearGradient(
                          colors: const [
                            Color(0x00000000),
                            Color(0xFF000000),
                            Color(0xFF000000),
                            Color(0x00000000),
                          ],
                          stops: [0, fade, 1 - fade, 1],
                        ).createShader(bounds);
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          _revealSelected(constraints.maxWidth);
                          Widget tab(Board board) {
                            final selected = board.id == notes.currentBoardId;
                            return ValueListenableBuilder<String?>(
                              valueListenable:
                                  widget.dropTarget ?? BoardBar._noTarget,
                              builder: (context, hovered, _) => _BoardChip(
                                key: tabKeys?[board.id],
                                board: board,
                                label: _actions.displayName(l10n, board),
                                selected: selected,
                                highlighted: hovered == board.id,
                                onTap: () => selected
                                    ? _actions.manage(context, l10n, board)
                                    : notes.selectBoard(board.id),
                              ),
                            );
                          }

                          if (collapsed) {
                            // Not reorderable: only some boards are in it.
                            return ListView.builder(
                              controller: _scroll,
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 4,
                              ),
                              itemCount: tabs.length,
                              itemBuilder: (context, index) {
                                final board = tabs[index];
                                final selected =
                                    board.id == notes.currentBoardId;
                                return Padding(
                                  key: ValueKey('board-${board.id}'),
                                  padding: const EdgeInsets.only(right: 8),
                                  child: KeyedSubtree(
                                    key: selected ? _selectedKey : null,
                                    child: Center(child: tab(board)),
                                  ),
                                );
                              },
                            );
                          }
                          return ReorderableListView.builder(
                            scrollController: _scroll,
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(left: 16, right: 4),
                            buildDefaultDragHandles: false,
                            onReorderItem: notes.reorderBoards,
                            proxyDecorator: (child, _, animation) =>
                                AnimatedBuilder(
                                  animation: animation,
                                  child: child,
                                  builder: (context, child) => Transform.scale(
                                    scale:
                                        1 +
                                        0.08 *
                                            Curves.easeInOut.transform(
                                              animation.value,
                                            ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: child,
                                    ),
                                  ),
                                ),
                            itemCount: tabs.length,
                            itemBuilder: (context, index) {
                              final board = tabs[index];
                              final selected = board.id == notes.currentBoardId;
                              return Padding(
                                key: ValueKey('board-${board.id}'),
                                padding: const EdgeInsets.only(right: 8),
                                child: ReorderableDelayedDragStartListener(
                                  key: selected ? _selectedKey : null,
                                  index: index,
                                  child: Center(child: tab(board)),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  if (collapsed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _AllChip(
                        label: l10n.allBoardsCount(notes.boards.length),
                        onTap: () => _actions.pick(context),
                      ),
                    ),
                  // Outside the scrolling strip, so it never hides behind the
                  // tabs when their names are long or there are many of them.
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _AddChip(
                      tooltip: l10n.newBoard,
                      onTap: () => _actions.newBoard(context),
                    ),
                  ),
                ],
              ),
            ),
            if (trayOpen)
              Positioned(
                top: 48,
                left: 12,
                right: 4,
                child: _DropTray(
                  boards: [
                    for (final b in notes.boards)
                      if (b.id != notes.currentBoardId) b,
                  ],
                  labelOf: (b) => _actions.displayName(l10n, b),
                  chipKeys: widget.chipKeys,
                  dropTarget: widget.dropTarget ?? BoardBar._noTarget,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// How the strip's controls look on any wall: the open board is solid chalk
/// with ink words, the others a dark, mostly opaque scrim with chalk words and
/// a pale rim. Words keep 4.5:1 on bright, dark and patterned walls alike,
/// which a bare outline on the wall itself did not. No blur: a backdrop
/// filter over the moving wall costs a repaint every frame. With the system's
/// high-contrast setting the scrim is fully solid.
class _ChipFace extends StatelessWidget {
  const _ChipFace({
    required this.child,
    this.selected = false,
    this.highlighted = false,
    this.padding = EdgeInsets.zero,
  }) : size = null;

  /// A round control, [size] across (the grid and "+" buttons).
  const _ChipFace.circle({
    required this.child,
    required double this.size,
    this.selected = false,
  }) : highlighted = false,
       padding = EdgeInsets.zero;

  final Widget child;
  final bool selected;

  /// A dragged note is hovering over it: drawn as a drop target.
  final bool highlighted;
  final EdgeInsetsGeometry padding;
  final double? size;

  /// Height of a tab; round buttons are [size] across.
  static const height = 40.0;

  /// Words on the chip: ink on chalk when open, chalk on the scrim otherwise.
  static Color ink({required bool selected, bool highlighted = false}) =>
      selected || highlighted ? AppColors.ink : AppColors.chalk;

  @override
  Widget build(BuildContext context) {
    final solid = MediaQuery.highContrastOf(context);
    final Color fill;
    final Color rim;
    if (highlighted) {
      fill = AppColors.accent;
      rim = AppColors.accent;
    } else if (selected) {
      fill = AppColors.chalk;
      rim = AppColors.chalk;
    } else {
      fill = solid ? AppColors.ink : const Color(0x991E160E);
      rim = AppColors.chalk.withValues(alpha: solid ? 1 : 0.3);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      // Every tab the same height, whatever its row offers it.
      height: size ?? height,
      padding: padding,
      // Only a fixed-size circle centres its child: an aligned container
      // would otherwise grow to the widest width it is offered (a tray row).
      alignment: size == null ? null : Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: size == null ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: size == null ? BorderRadius.circular(20) : null,
        border: Border.all(
          color: rim,
          width: highlighted || selected ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}

/// A board tab: icon + name, solid when it is the current board. Tap to
/// switch; tap the current one to edit, move or delete it; long-press and drag
/// to reorder.
class _BoardChip extends StatelessWidget {
  const _BoardChip({
    super.key,
    required this.board,
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlighted = false,
  });

  final Board board;
  final String label;
  final bool selected;

  /// A dragged note is hovering over the chip: drawn as a drop target.
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = board.icon;
    final ink = _ChipFace.ink(selected: selected, highlighted: highlighted);
    return KeyboardTappable(
      onActivate: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Semantics(
        button: true,
        selected: selected,
        // Tapping the current board opens its sheet (edit, move, delete).
        hint: selected ? AppLocalizations.of(context)?.editBoard : null,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: highlighted ? 1.08 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutBack,
            child: _ChipFace(
              selected: selected,
              highlighted: highlighted,
              padding: EdgeInsets.fromLTRB(
                icon.isEmpty ? 16 : 12,
                6,
                selected ? 10 : 16,
                6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (board.isPrivate)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.lock_outline,
                        size: 15,
                        color: ink,
                        semanticLabel: AppLocalizations.of(
                          context,
                        )?.boardPrivate,
                      ),
                    ),
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
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(Icons.expand_more, size: 18, color: ink),
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

/// "All 12": the last tab of a collapsed strip, opening the board picker.
class _AllChip extends StatelessWidget {
  const _AllChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KeyboardTappable(
      onActivate: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: _ChipFace(
            padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apps, size: 17, color: AppColors.chalk),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(color: AppColors.chalk, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Every other board as a drop target, hanging under a collapsed strip while
/// a note is dragged. The screen above finds the chips by [chipKeys] (it only
/// measures them), so the tray takes no touches itself.
class _DropTray extends StatelessWidget {
  const _DropTray({
    required this.boards,
    required this.labelOf,
    required this.chipKeys,
    required this.dropTarget,
  });

  final List<Board> boards;
  final String Function(Board board) labelOf;
  final Map<String, GlobalKey>? chipKeys;
  final ValueListenable<String?> dropTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Container(
          key: const Key('board-drop-tray'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xE61E160E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.chalk.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.dropOnBoardHint,
                  style: const TextStyle(color: AppColors.chalk, fontSize: 14),
                ),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: dropTarget,
                builder: (context, hovered, _) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in boards)
                      _BoardChip(
                        key: chipKeys?[b.id],
                        board: b,
                        label: labelOf(b),
                        selected: false,
                        highlighted: hovered == b.id,
                        onTap: () {},
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round control at the start of the strip: the board picker, or on a wide
/// window the board list's show / hide (solid while the list is open).
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.mirror = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  /// Draws [icon] mirrored left to right.
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: KeyboardTappable(
        onActivate: onTap,
        circle: true,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            // A 40 dp circle inside a 48 dp target.
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: _ChipFace.circle(
                  size: _ChipFace.height,
                  selected: selected,
                  child: Transform.flip(
                    // The list opens on the left; Material draws this
                    // icon's panel on the right.
                    flipX: mirror,
                    child: Icon(
                      icon,
                      size: 20,
                      color: _ChipFace.ink(selected: selected),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The trailing "+" tab that creates a new board.
class _AddChip extends StatelessWidget {
  const _AddChip({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KeyboardTappable(
      onActivate: onTap,
      circle: true,
      child: Tooltip(
        message: tooltip,
        // A 44 dp circle inside a 48 dp wide target.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 48,
            child: Center(
              child: _ChipFace.circle(
                size: _ChipFace.height,
                child: const Icon(Icons.add, color: AppColors.chalk, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

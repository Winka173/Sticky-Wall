import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../screens/gallery_screen.dart';
import '../services/app_lock.dart';
import '../services/image_service.dart';
import '../services/memory_wall.dart';
import '../services/notes_controller.dart';
import '../services/pro_controller.dart';
import '../theme.dart';
import 'action_sheet.dart';
import 'board_dialog.dart';
import 'board_picker.dart';
import 'photo_frames.dart';
import 'pro_sheet.dart';

/// What the board strip and the wide-screen board list both do with a board:
/// make a new one, open the picker of every board, and the manage sheet of
/// the open one (edit, privacy, theme, order, delete).
class BoardActions {
  const BoardActions(this.notes, {this.onMemoryWall});

  final NotesController notes;

  /// Offered on the "+": a new board of photos.
  final VoidCallback? onMemoryWall;

  String displayName(AppLocalizations l10n, Board board) =>
      board.name.isEmpty ? l10n.defaultBoardName : board.name;

  /// Asks for the phone's lock, then makes [board] private or public. A
  /// phone without a screen lock cannot keep a board private.
  Future<void> _togglePrivate(
    BuildContext context,
    AppLocalizations l10n,
    Board board,
  ) async {
    final result = await const AppLock().authenticate(l10n.confirmItsYou);
    if (!context.mounted) return;
    switch (result) {
      case UnlockResult.unlocked:
        notes.setBoardPrivate(board.id, !board.isPrivate);
      case UnlockResult.noLock:
        if (board.isPrivate) {
          // Its lock was removed: let it go public rather than stay stuck.
          notes.setBoardPrivate(board.id, false);
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10n.appLockNoLock),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.gotIt),
              ),
            ],
          ),
        );
      case UnlockResult.failed:
        break;
    }
  }

  Future<void> _create(BuildContext context) async {
    final draft = await showBoardDialog(context);
    if (draft == null || draft.name.isEmpty || !context.mounted) return;
    notes.addBoard(draft.name, icon: draft.icon);
  }

  Future<void> pick(BuildContext context) => showBoardPicker(
    context,
    notes: notes,
    onDelete: (board) =>
        _confirmDelete(context, AppLocalizations.of(context)!, board),
  );

  /// Deletes [board] once the user agrees, saying how many notes go with it.
  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    Board board,
  ) async {
    // The board goes to the Trash with every note on it, trashed ones too.
    final count = notes.allNotes.where((n) => n.boardId == board.id).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBoardConfirm(displayName(l10n, board))),
        content: count == 0 ? null : Text(l10n.deleteBoardWithNotes(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteIcon),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final undo = notes.deleteBoard(board.id);
    if (undo != null) {
      _undoSnack(context, l10n.boardTrashed(displayName(l10n, board)), undo);
    }
  }

  void _undoSnack(BuildContext context, String message, VoidCallback undo) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Closes by itself, Undo or not.
          persist: false,
          content: Text(message),
          action: SnackBarAction(label: l10n.undo, onPressed: undo),
        ),
      );
  }

  /// The "+": a blank board, or one of the templates.
  Future<void> newBoard(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showActionSheet<String>(
      context,
      title: l10n.newBoard,
      children: [
        ListTile(
          leading: const Icon(Icons.crop_square),
          title: Text(l10n.newBoardBlank),
          onTap: () => Navigator.pop(context, 'blank'),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard_customize_outlined),
          title: Text(l10n.newBoardFromTemplate),
          subtitle: Text(l10n.newBoardFromTemplateHint),
          onTap: () => Navigator.pop(context, 'template'),
        ),
        if (onMemoryWall != null)
          ListTile(
            leading: const Icon(Icons.photo_album_outlined),
            title: Text(l10n.memoryWall),
            subtitle: Text(l10n.memoryWallHint),
            onTap: () => Navigator.pop(context, 'memory'),
          ),
      ],
    );
    if (!context.mounted) return;
    if (choice == 'blank') {
      await _create(context);
    } else if (choice == 'memory') {
      onMemoryWall?.call();
    } else if (choice == 'template') {
      final result = await GalleryScreen.open(context, notes: notes);
      if (context.mounted) showGalleryResult(context, result);
    }
  }

  Future<void> manage(
    BuildContext context,
    AppLocalizations l10n,
    Board board,
  ) async {
    // A shut private board is managed only once it has been opened.
    if (!notes.isOpen(board)) {
      if (!await unlockPrivateBoard(context, notes, board)) return;
      if (!context.mounted) return;
    }
    final pro = ProScope.unlockedOf(context);
    final index = notes.boards.indexWhere((b) => b.id == board.id);
    final action = await showActionSheet<String>(
      context,
      title: board.icon.isEmpty
          ? displayName(l10n, board)
          : '${board.icon} ${displayName(l10n, board)}',
      children: [
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.editBoard),
          onTap: () => Navigator.pop(context, 'edit'),
        ),
        // Making a board private is Pro; making it public again never is.
        ListTile(
          leading: Icon(
            board.isPrivate ? Icons.lock_open_outlined : Icons.lock_outline,
          ),
          title: Text(
            board.isPrivate ? l10n.boardMakePublic : l10n.boardMakePrivate,
          ),
          subtitle: board.isPrivate ? null : Text(l10n.boardPrivateHint),
          trailing: board.isPrivate || pro ? null : const ProMark(),
          onTap: () => Navigator.pop(
            context,
            board.isPrivate || pro ? 'private' : 'pro',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(l10n.changeTheme),
          onTap: () => Navigator.pop(context, 'theme'),
        ),
        if (notes.printsOn(board.id).isNotEmpty)
          ListTile(
            leading: const Icon(Icons.add_photo_alternate_outlined),
            title: Text(l10n.memoryAddPhotos),
            onTap: () => Navigator.pop(context, 'addPhotos'),
          ),
        if (notes.printsOn(board.id).length > 1) ...[
          ListTile(
            leading: const Icon(Icons.shuffle),
            title: Text(l10n.shufflePhotos),
            onTap: () => Navigator.pop(context, 'shuffle'),
          ),
          ListTile(
            leading: const Icon(Icons.filter_frames_outlined),
            title: Text(l10n.framesAll),
            onTap: () => Navigator.pop(context, 'frames'),
          ),
        ],
        if (notes.sampleNotes(board.id).isNotEmpty)
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l10n.clearSamples),
            subtitle: Text(l10n.clearSamplesHint),
            onTap: () => Navigator.pop(context, 'samples'),
          ),
        // Reordering is otherwise a long-press drag of the tab.
        if (index > 0)
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: Text(l10n.moveBoardLeft),
            onTap: () => Navigator.pop(context, 'left'),
          ),
        if (index < notes.boards.length - 1)
          ListTile(
            leading: const Icon(Icons.arrow_forward),
            title: Text(l10n.moveBoardRight),
            onTap: () => Navigator.pop(context, 'right'),
          ),
        if (notes.boards.length > 1)
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

    if (action == 'pro') {
      await showProSheet(context, focus: ProPerk.privateBoards);
      return;
    }
    if (action == 'theme') {
      final result = await GalleryScreen.open(
        context,
        notes: notes,
        themes: true,
      );
      if (context.mounted) showGalleryResult(context, result);
      return;
    }
    if (action == 'addPhotos') {
      // More photos for a memory wall made earlier, in its frame; Shuffle
      // then lays them all out together, and any print can be deleted from
      // its own menu.
      final List<String> stored;
      try {
        stored = await ImageService().pickImages(limit: memoryWallMax);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.photoPickFailed)));
        return;
      }
      if (stored.isEmpty || !context.mounted) return;
      final undo = notes.addPrintsTo(board.id, stored);
      _undoSnack(context, l10n.photosPinned(stored.length), undo);
      return;
    }
    if (action == 'shuffle') {
      final undo = notes.rearrangePrints(
        board.id,
        seed: DateTime.now().microsecondsSinceEpoch.toString(),
      );
      _undoSnack(context, l10n.photosShuffled, undo);
      return;
    }
    if (action == 'frames') {
      final frame = await showFramePicker(context, title: l10n.framesAll);
      if (frame == null || !context.mounted) return;
      if (frame.pro && !pro) {
        await showProSheet(context, focus: ProPerk.frames);
        return;
      }
      final undo = notes.setFrames(notes.printsOn(board.id), frame);
      _undoSnack(context, l10n.framesApplied, undo);
      return;
    }
    if (action == 'samples') {
      notes.clearSamples(board.id);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            // Closes by itself, Undo or not.
            persist: false,
            content: Text(l10n.samplesCleared),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: notes.undoDelete,
            ),
          ),
        );
      return;
    }
    if (action == 'private') {
      await _togglePrivate(context, l10n, board);
      return;
    }
    if (action == 'left' || action == 'right') {
      notes.reorderBoards(index, index + (action == 'left' ? -1 : 1));
      return;
    }
    if (action == 'edit') {
      final draft = await showBoardDialog(context, board: board);
      if (draft == null) return;
      notes.updateBoard(board.id, name: draft.name, icon: draft.icon);
    } else if (action == 'delete') {
      await _confirmDelete(context, l10n, board);
    }
  }
}

/// Asks for the phone's lock to open private [board] until the app next goes
/// to the background. True when it may be shown. A phone whose screen lock
/// was removed since is let in, as with the app lock.
Future<bool> unlockPrivateBoard(
  BuildContext context,
  NotesController notes,
  Board board,
) async {
  if (notes.isOpen(board)) return true;
  final reason = AppLocalizations.of(context)!.boardUnlockReason;
  final result = await const AppLock().authenticate(reason);
  if (result == UnlockResult.failed) return false;
  notes.openPrivateBoard(board.id);
  return true;
}

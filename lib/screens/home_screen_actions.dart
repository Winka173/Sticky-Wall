part of 'home_screen.dart';

/// What can be done to a note from its long-press sheet — and from the
/// keyboard menu and the selection bar that reuse it: edit, pin, lock, size
/// and turn, threads, duplicate, move or copy to a board, share and save as
/// an image. Kept apart from the screen's layout; none of it holds state of
/// its own.
extension _NoteActions on _HomeScreenState {
  // --- Note actions --------------------------------------------------------

  NoteCallbacks _callbacks(Note note) => NoteCallbacks(
    onEdit: () {
      if (_selecting) {
        _toggleSelected(note);
      } else {
        _openEditor(note, isNew: false);
      }
    },
    onTogglePin: () {
      HapticFeedback.selectionClick();
      _notes.togglePin(note);
    },
    onToggleItem: (i) => _notes.toggleChecklistItem(note, i),
    onLongPress: () {
      HapticFeedback.mediumImpact();
      if (_selecting) {
        _toggleSelected(note);
      } else {
        _showNoteActions(note);
      }
    },
  );

  Future<void> _showNoteActions(Note note) async {
    final l10n = _l10n;
    final canMove = _notes.boards.length > 1;
    final onWall = _notes.viewMode == ViewMode.wall;
    final threads = [
      for (final l in _notes.linksOn(_notes.currentBoardId))
        if (l.connects(note.guid)) l,
    ];
    final action = await showActionSheet<String>(
      context,
      children: [
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.edit),
          onTap: () => Navigator.pop(context, 'edit'),
        ),
        if (note.hasPhoto)
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: Text(l10n.viewPhoto),
            onTap: () => Navigator.pop(context, 'photo'),
          ),
        ListTile(
          leading: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
          title: Text(note.pinned ? l10n.unpin : l10n.pin),
          onTap: () => Navigator.pop(context, 'pin'),
        ),
        ListTile(
          leading: Icon(note.locked ? Icons.lock_open : Icons.lock_outline),
          title: Text(note.locked ? l10n.unlock : l10n.lockInPlace),
          onTap: () => Navigator.pop(context, 'lock'),
        ),
        // Menu paths for what the wall otherwise only does by dragging.
        if (onWall && !note.locked)
          ListTile(
            leading: const Icon(Icons.open_in_full),
            title: Text(l10n.sizeAndTurn),
            onTap: () => Navigator.pop(context, 'size'),
          ),
        if (onWall)
          ListTile(
            leading: const Icon(Icons.timeline),
            title: Text(l10n.tieThreadTo),
            onTap: () => Navigator.pop(context, 'tie'),
          ),
        if (onWall && threads.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.gesture),
            title: Text(l10n.threadsOfNote),
            onTap: () => Navigator.pop(context, 'threads'),
          ),
        ListTile(
          leading: const Icon(Icons.checklist_rtl),
          title: Text(l10n.select),
          onTap: () => Navigator.pop(context, 'select'),
        ),
        ListTile(
          leading: const Icon(Icons.content_copy_outlined),
          title: Text(l10n.duplicate),
          onTap: () => Navigator.pop(context, 'duplicate'),
        ),
        if (canMove)
          ListTile(
            leading: const Icon(Icons.drive_file_move_outlined),
            title: Text(l10n.moveToBoard),
            onTap: () => Navigator.pop(context, 'move'),
          ),
        if (canMove)
          ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: Text(l10n.copyToBoard),
            onTap: () => Navigator.pop(context, 'copy'),
          ),
        ListTile(
          leading: const Icon(Icons.ios_share),
          title: Text(l10n.shareAsImage),
          onTap: () => Navigator.pop(context, 'share'),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l10n.saveImage),
          onTap: () => Navigator.pop(context, 'save'),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(
            Icons.delete_outline,
            color: AppColors.deleteIcon,
          ),
          title: Text(
            l10n.delete,
            style: const TextStyle(color: AppColors.deleteIcon),
          ),
          onTap: () => Navigator.pop(context, 'delete'),
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _openEditor(note, isNew: false);
      case 'photo':
        await showPhotoViewer(context, note.imagePath);
      case 'pin':
        unawaited(HapticFeedback.selectionClick());
        _notes.togglePin(note);
      case 'lock':
        unawaited(HapticFeedback.selectionClick());
        _notes.toggleLock(note);
      case 'size':
        await _sizeAndTurn(note);
      case 'tie':
        await _tieThreadFrom(note);
      case 'threads':
        await _threadsOf(note, threads);
      case 'select':
        _startSelecting(note);
      case 'duplicate':
        unawaited(HapticFeedback.selectionClick());
        _notes.duplicate(note);
      case 'move':
        await _moveToBoard([note]);
      case 'copy':
        await _copyToBoard([note]);
      case 'share':
        await _captureAndShare(note);
      case 'save':
        await _captureAndSave(note);
      case 'delete':
        await _delete(note);
    }
  }

  /// Resize and turn from buttons, for anyone who cannot pinch, twist or
  /// drag the grips. Each press is one step of the wall's Undo.
  Future<void> _sizeAndTurn(Note note) async {
    final l10n = _l10n;
    const step = math.pi / 12; // 15°
    await showActionSheet<void>(
      context,
      title: l10n.sizeAndTurn,
      children: [
        StatefulBuilder(
          builder: (context, setSheet) {
            void apply(void Function() change) {
              HapticFeedback.selectionClick();
              change();
              setSheet(() {});
            }

            Widget button(String label, IconData icon, VoidCallback onTap) =>
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: OutlinedButton.icon(
                      onPressed: () => apply(onTap),
                      icon: Icon(icon),
                      label: Text(label, textAlign: TextAlign.center),
                    ),
                  ),
                );
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      button(
                        l10n.smaller,
                        Icons.zoom_out,
                        () => _notes.resizeNote(note, note.scale - 0.1),
                      ),
                      button(
                        l10n.larger,
                        Icons.zoom_in,
                        () => _notes.resizeNote(note, note.scale + 0.1),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      button(
                        l10n.turnLeft,
                        Icons.rotate_left,
                        () => _notes.rotateNote(note, noteAngle(note) - step),
                      ),
                      button(
                        l10n.straighten,
                        Icons.crop_portrait,
                        () => _notes.rotateNote(note, 0),
                      ),
                      button(
                        l10n.turnRight,
                        Icons.rotate_right,
                        () => _notes.rotateNote(note, noteAngle(note) + step),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Ties a thread from [note] to another note picked from a list — the
  /// pin-to-pin drag, without dragging.
  Future<void> _tieThreadFrom(Note note) async {
    final l10n = _l10n;
    final others = [
      for (final n in _notes.boardNotes)
        if (n.guid != note.guid && !_notes.isLinked(n.guid, note.guid)) n,
    ];
    if (others.isEmpty) {
      _toast(l10n.noOtherNotes);
      return;
    }
    final target = await showActionSheet<Note>(
      context,
      title: l10n.tieThreadTo,
      children: [
        for (final n in others)
          ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text(
              _noteTitle(n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.pop(context, n),
          ),
      ],
    );
    if (target == null || !mounted) return;
    if (_notes.connect(note.guid, target.guid)) {
      unawaited(HapticFeedback.lightImpact());
      _toast(l10n.threadTied);
    }
  }

  /// The threads on [note], each opening the same sheet a tap on the yarn
  /// opens.
  Future<void> _threadsOf(Note note, List<NoteLink> threads) async {
    final l10n = _l10n;
    final link = await showActionSheet<NoteLink>(
      context,
      title: l10n.threadsOfNote,
      children: [
        for (final l in threads)
          ListTile(
            leading: Icon(
              Icons.circle,
              color: Color(l.color ?? AppColors.yarns.first),
              size: 18,
            ),
            title: Text(
              _noteTitle(
                _notes.boardNotes.firstWhere(
                  (n) => n.guid == (l.a == note.guid ? l.b : l.a),
                  orElse: () => note,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: l.label.isEmpty ? null : Text(l.label),
            onTap: () => Navigator.pop(context, l),
          ),
      ],
    );
    if (link != null && mounted) await _editThread(link);
  }

  /// One line naming a note in a list: its words, else its first item,
  /// else its type.
  String _noteTitle(Note note) {
    final text = plainNoteText(note.content).trim();
    if (text.isNotEmpty) return text.split('\n').first;
    final item = note.checklist.where((i) => i.text.trim().isNotEmpty);
    if (item.isNotEmpty) return item.first.text;
    if (note.type == NoteType.photo) return _l10n.typePhoto;
    if (note.type == NoteType.drawing) return _l10n.typeDrawing;
    return _l10n.untitledNote;
  }

  /// Lets the user pick one of the other boards.
  Future<Board?> _pickBoard(String title) {
    final current = _notes.currentBoardId;
    final targets = _notes.boards.where((b) => b.id != current).toList();
    return showActionSheet<Board>(
      context,
      title: title,
      children: [
        for (final board in targets)
          ListTile(
            leading: board.icon.isEmpty
                ? const Icon(Icons.dashboard_outlined)
                : Text(board.icon, style: const TextStyle(fontSize: 22)),
            title: Text(
              _boardName(board),
              style: board.decorate(const TextStyle()),
            ),
            onTap: () => Navigator.pop(context, board),
          ),
      ],
    );
  }

  Future<void> _moveToBoard(List<Note> notes) async {
    if (notes.isEmpty) return;
    final l10n = _l10n;
    final target = await _pickBoard(l10n.moveToBoard);
    if (target == null || !mounted) return;
    _notes.moveAllToBoard(notes, target.id);
    _exitSelecting();
    _toast(l10n.movedToBoard(_boardName(target)));
  }

  /// Copies the notes onto another board; the originals stay here.
  Future<void> _copyToBoard(List<Note> notes) async {
    if (notes.isEmpty) return;
    final l10n = _l10n;
    final target = await _pickBoard(l10n.copyToBoard);
    if (target == null || !mounted) return;
    final copies = _notes.copyToBoard(notes, target.id);
    _exitSelecting();
    _toast(l10n.copiedToBoard(copies.length, _boardName(target)));
  }

  RenderRepaintBoundary? _boundaryFor(Note note) {
    final ctx = _captureKeys[_captureId(note)]?.currentContext;
    return ctx?.findRenderObject() as RenderRepaintBoundary?;
  }

  /// The part of the wall on screen, in wall coordinates — or null when the
  /// camera is at rest and the whole wall is in view anyway.
  Rect? get _visibleWallRect {
    final size = _wallHandle.lastSize;
    if (!_camera.moved || size.isEmpty) return null;
    return MatrixUtils.inverseTransformRect(_camera.matrix, Offset.zero & size);
  }

  /// Shows the board as a picture — wall, notes and threads, nothing else —
  /// to share or save. Always the wall layout, whichever view is showing.
  Future<void> _exportBoard() {
    final wall = wallFor(_notes.currentBoard, night: isNight(context));
    final hasWidget = !kIsWeb && Platform.isAndroid;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BoardPosterPage(
          wall: wall,
          decor: widget.settings.wallDecor,
          notes: _notes.boardNotes,
          links: _notes.linksOn(_notes.currentBoardId),
          strokes: _notes.currentBoard.strokes,
          wallSize: _wallHandle.lastSize,
          imageService: _imageService,
          viewport: _notes.viewMode == ViewMode.wall ? _visibleWallRect : null,
          selected: _selecting ? Set.of(_selected) : const {},
          onShowOnWidget: hasWidget ? WidgetService.showWallImage : null,
        ),
      ),
    );
  }

  Future<void> _captureAndShare(Note note) async {
    final boundary = _boundaryFor(note);
    try {
      final bytes = boundary == null
          ? null
          : await ImageService.capture(boundary);
      if (bytes == null) {
        if (mounted) _toast(_l10n.shareFailed);
        return;
      }
      await _imageService.sharePng(bytes, subject: _l10n.appTitle);
    } catch (_) {
      if (mounted) _toast(_l10n.shareFailed);
    }
  }

  Future<void> _captureAndSave(Note note) async {
    final boundary = _boundaryFor(note);
    if (boundary == null) return;
    try {
      final bytes = await ImageService.capture(boundary);
      if (bytes == null || !mounted) return;
      await _imageService.saveToGallery(bytes);
      _toast(_l10n.imageSaved);
    } catch (_) {
      if (mounted) _toast(_l10n.imageSaveFailed);
    }
  }
}

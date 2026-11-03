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
    onOpenStack: note.stack == null ? null : () => _openStack(note),
  );

  /// A stack's cards, top first: tap one to edit it, or spread them out.
  Future<void> _openStack(Note note) async {
    final l10n = _l10n;
    final pile = _notes.stackOf(note).reversed.toList();
    final choice = await showActionSheet<Object>(
      context,
      title: l10n.stackCount(pile.length),
      children: [
        for (final n in pile)
          ListTile(
            leading: Icon(
              Icons.sticky_note_2,
              color: paperColorOf(context, n.colorIndex, n.guid),
            ),
            title: Text(
              _noteTitle(n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.pop(context, n),
          ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.call_split),
          title: Text(l10n.unstack),
          onTap: () => Navigator.pop(context, 'unstack'),
        ),
      ],
    );
    if (!mounted) return;
    if (choice == 'unstack') {
      unawaited(HapticFeedback.lightImpact());
      _notes.unstack(note);
    } else if (choice is Note) {
      await _openEditor(choice, isNew: false);
    }
  }

  /// Piles [note] onto another note picked from a list; [note] lands on top.
  Future<void> _stackWith(Note note) async {
    final l10n = _l10n;
    final others = [
      for (final n in _notes.wallNotes)
        if (n != note && (n.stack == null || n.stack != note.stack)) n,
    ];
    if (others.isEmpty) {
      _toast(l10n.noOtherNotes);
      return;
    }
    final target = await showActionSheet<Note>(
      context,
      title: l10n.stackNotes,
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
    unawaited(HapticFeedback.lightImpact());
    _notes.stackNotes([target, note]);
  }

  Future<void> _showNoteActions(Note note) async {
    final l10n = _l10n;
    final canMove = _notes.boards.length > 1;
    final onWall = _notes.viewMode == ViewMode.wall;
    final threads = [
      for (final l in _notes.linksOn(_notes.currentBoardId))
        if (l.connects(note.guid)) l,
    ];
    final pro = ProScope.unlockedOf(context);
    // Prints and stickers have no paper to colour.
    final colorable =
        note.type != NoteType.photo && note.type != NoteType.sticker;
    // The everyday actions sit on top, one tap away; the rest are listed
    // under them.
    final action = await showActionSheet<String>(
      context,
      children: [
        if (colorable)
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                _Swatch(
                  name: paperName(l10n, null),
                  color: AppColors.paper,
                  auto: true,
                  selected: note.colorIndex == null,
                  onTap: () => Navigator.pop(context, 'color:-1'),
                ),
                for (final (i, c) in AppColors.notePapers.indexed)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _Swatch(
                      name: paperName(l10n, i),
                      color: c,
                      selected: note.colorIndex == i,
                      locked: !pro && i >= AppColors.freePapers,
                      onTap: () => Navigator.pop(
                        context,
                        !pro && i >= AppColors.freePapers ? 'pro' : 'color:$i',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _BarAction(
                icon: note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: note.pinned ? l10n.unpin : l10n.pinShort,
                color: AppColors.ink,
                onTap: () => Navigator.pop(context, 'pin'),
              ),
              if (canMove)
                _BarAction(
                  icon: Icons.drive_file_move_outlined,
                  label: l10n.move,
                  color: AppColors.ink,
                  onTap: () => Navigator.pop(context, 'move'),
                )
              else
                _BarAction(
                  icon: Icons.content_copy_outlined,
                  label: l10n.duplicate,
                  color: AppColors.ink,
                  onTap: () => Navigator.pop(context, 'duplicate'),
                ),
              _BarAction(
                icon: Icons.ios_share,
                label: l10n.share,
                color: AppColors.ink,
                onTap: () => Navigator.pop(context, 'share'),
              ),
              _BarAction(
                icon: Icons.delete_outline,
                label: l10n.delete,
                color: AppColors.deleteIcon,
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
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
        if (onWall)
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: Text(l10n.stackNotes),
            onTap: () => Navigator.pop(context, 'stack'),
          ),
        if (onWall && note.stack != null)
          ListTile(
            leading: const Icon(Icons.call_split),
            title: Text(l10n.unstack),
            onTap: () => Navigator.pop(context, 'unstack'),
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
        if (canMove)
          ListTile(
            leading: const Icon(Icons.content_copy_outlined),
            title: Text(l10n.duplicate),
            onTap: () => Navigator.pop(context, 'duplicate'),
          ),
        if (canMove)
          ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: Text(l10n.copyToBoard),
            onTap: () => Navigator.pop(context, 'copy'),
          ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l10n.saveImage),
          onTap: () => Navigator.pop(context, 'save'),
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action.startsWith('color:')) {
      unawaited(HapticFeedback.selectionClick());
      final i = int.parse(action.substring(6));
      _notes.recolor([note], i < 0 ? null : i);
      return;
    }
    switch (action) {
      case 'pro':
        await showProSheet(context);
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
      case 'stack':
        await _stackWith(note);
      case 'unstack':
        _notes.unstack(note);
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
    if (note.type == NoteType.audio) return _l10n.typeAudio;
    if (note.type == NoteType.sticker) return _l10n.typeSticker;
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
          // A private board's notes never go on the home screen.
          onShowOnWidget: hasWidget && !_notes.currentBoard.isPrivate
              ? _showOnWidget
              : null,
        ),
      ),
    );
  }

  /// Sends the board picture to the home-screen widget and switches the
  /// widget to showing it.
  Future<bool> _showOnWidget(Uint8List png) async {
    final ok = await WidgetService.showWallImage(png);
    if (ok) widget.settings.showWidgetPicture(_notes.currentBoardId);
    return ok;
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

  /// Under the search box: how many notes the search finds on the other
  /// walls, opening a list of them — a note is never lost to the wrong tab.
  Widget _otherBoardsPill() {
    final elsewhere = _notes.otherBoardMatches;
    if (elsewhere.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.overlayDark,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showOtherBoardMatches(elsewhere),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.travel_explore,
                    size: 16,
                    color: AppColors.chalk,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _l10n.otherBoardsMatches(elsewhere.length),
                    style: const TextStyle(
                      color: AppColors.chalk,
                      fontSize: 14,
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

  /// The matches on other walls, each with its wall's name; picking one goes
  /// to that wall (the search stays, so it is found there too) and opens it.
  Future<void> _showOtherBoardMatches(List<Note> notes) async {
    final boards = {for (final b in _notes.boards) b.id: b};
    final picked = await showActionSheet<Note>(
      context,
      title: _l10n.onOtherBoards,
      children: [
        for (final n in notes)
          ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text(
              _noteTitle(n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: boards[n.boardId] == null
                ? null
                : Text(_boardName(boards[n.boardId]!)),
            onTap: () => Navigator.pop(context, n),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    _notes.selectBoard(picked.boardId);
    await _openEditor(picked, isNew: false);
  }
}

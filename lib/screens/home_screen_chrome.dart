part of 'home_screen.dart';

/// The screen's chrome: the title and board rows, search, the selection
/// title and bar, the tool pill with its menus, and drawing on the wall
/// (marker mode and its bar).
extension _Chrome on _HomeScreenState {
  // --- Marker mode ---------------------------------------------------------

  void _startMarking(WallStyle wall) {
    _exitSelecting();
    // Drawing happens on the wall; from the grid or list, go there first.
    if (_notes.viewMode != ViewMode.wall) _notes.viewMode = ViewMode.wall;
    _update(() {
      _marking = true;
      _inkPast.clear();
      // Ink on a light wall, chalk on a dark one.
      _marker = WallMarker(
        color: wall.dark ? AppColors.markerChalk : AppColors.markers.first,
      );
    });
  }

  void _stopMarking() => _update(() {
    _marking = false;
    _inkPast.clear();
  });

  void _inkBegin() {
    _inkPast.add(List.of(_wallStrokes));
    if (_inkPast.length > 40) _inkPast.removeAt(0);
  }

  void _undoInk() {
    if (_inkPast.isEmpty) return;
    HapticFeedback.lightImpact();
    _wallStrokes
      ..clear()
      ..addAll(_inkPast.removeLast());
    _notes.saveWallStrokes();
  }

  Future<void> _clearInk() async {
    if (_wallStrokes.isEmpty) return;
    // Done empties the undo history, so a cleared wall could not come back.
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(_l10n.clearInkConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteIcon),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_l10n.clear),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    unawaited(HapticFeedback.lightImpact());
    _inkBegin();
    _update(_wallStrokes.clear);
    _notes.saveWallStrokes();
  }

  /// Pen, colours, eraser, undo, clear and done, docked at the bottom while
  /// drawing on the wall. Compact enough for a 360dp phone in one row.
  Widget _markerBar(WallStyle wall) {
    final l10n = _l10n;
    final pro = ProScope.unlockedOf(context);
    final text = wall.wallText;
    // The pen button steps thin → medium → thick, then (with Pro) to the
    // highlighter, then back to thin.
    const widths = [3.0, 6.0, 11.0];
    WallMarker nextPen() {
      if (_marker.highlighter) {
        return _marker.copyWith(highlighter: false, width: widths.first);
      }
      final i = widths.indexOf(_marker.width);
      if (i == widths.length - 1 && pro) {
        return _marker.copyWith(highlighter: true, eraser: false);
      }
      return _marker.copyWith(width: widths[(i + 1) % widths.length]);
    }

    Widget tool({
      required String tooltip,
      required Widget icon,
      VoidCallback? onTap,
      Color? color,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: icon,
      iconSize: 21,
      color: color ?? text,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
        child: _Glass(
          decoration: _frosted(wall, radius: 16, strong: true),
          padding: const EdgeInsets.fromLTRB(4, 6, 5, 6),
          child: Row(
            children: [
              // The colours take what the tools leave; on a phone too narrow
              // for all five at full size they scroll rather than overflow.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (i, c) in AppColors.markers.indexed)
                        _InkDot(
                          name: _markerName(l10n, i),
                          color: Color(c),
                          selected: !_marker.eraser && _marker.color == c,
                          locked: !pro && i >= AppColors.freeMarkers,
                          onTap: !pro && i >= AppColors.freeMarkers
                              ? () => showProSheet(context)
                              : () => _update(
                                  () => _marker = _marker.copyWith(
                                    color: c,
                                    eraser: false,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              tool(
                tooltip: _marker.highlighter ? l10n.highlighter : l10n.penSize,
                // The icon's weight hints at the current width.
                icon: _marker.highlighter
                    ? const Icon(Icons.border_color)
                    : Icon(Icons.line_weight, size: 14 + _marker.width),
                color: _marker.highlighter ? AppColors.accent : text,
                onTap: () => _update(() => _marker = nextPen()),
              ),
              tool(
                tooltip: l10n.eraser,
                icon: Icon(
                  _marker.eraser
                      ? Icons.auto_fix_normal
                      : Icons.auto_fix_normal_outlined,
                ),
                color: _marker.eraser ? AppColors.accent : text,
                onTap: () => _update(
                  () => _marker = _marker.copyWith(eraser: !_marker.eraser),
                ),
              ),
              tool(
                tooltip: l10n.undo,
                icon: const Icon(Icons.undo),
                onTap: _inkPast.isEmpty ? null : _undoInk,
              ),
              tool(
                tooltip: l10n.clear,
                icon: const Icon(Icons.delete_sweep_outlined),
                onTap: _wallStrokes.isEmpty ? null : _clearInk,
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: l10n.done,
                child: Material(
                  color: AppColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _stopMarking,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.check, size: 20, color: AppColors.ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The translucent chip look. [strong] is for controls that float over the
  /// notes themselves (the tool pill): enough fill that icons stay readable
  /// with a busy photo passing underneath.
  BoxDecoration _frosted(
    WallStyle wall, {
    double radius = 21,
    bool strong = false,
  }) => BoxDecoration(
    // Floating controls are near-opaque: a blur behind them cost a repaint
    // of the moving wall every frame and read as glass, not as the wall's
    // own warm chrome.
    color: strong
        ? (wall.dark ? const Color(0xE62A2520) : const Color(0xEBFDFBF3))
        : (wall.dark ? const Color(0x26FFFFFF) : const Color(0x14000000)),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: wall.wallTextFaded.withValues(alpha: 0.25)),
  );

  Widget _buildTitleRow(WallStyle wall) {
    final text = wall.wallText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
      child: SizedBox(
        height: 48,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selecting
              ? _selectionTitle(wall)
              : _searching
              ? _searchField(wall)
              : Row(
                  key: const ValueKey('title'),
                  children: [
                    Expanded(
                      child: Text(
                        _l10n.appTitle,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 28,
                          color: text,
                          shadows: wall.wallTextShadows,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _l10n.search,
                      icon: Icon(Icons.search, color: text),
                      onPressed: () => _setSearching(true),
                    ),
                    IconButton(
                      tooltip: _l10n.customize,
                      icon: Icon(Icons.palette_outlined, color: text),
                      onPressed: () => showSettingsSheet(
                        context,
                        settings: widget.settings,
                        notes: _notes,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _selectionTitle(WallStyle wall) {
    final text = wall.wallText;
    return Padding(
      key: const ValueKey('select'),
      padding: const EdgeInsets.fromLTRB(0, 3, 8, 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: _frosted(wall),
        child: Row(
          children: [
            IconButton(
              tooltip: _l10n.cancel,
              iconSize: 20,
              icon: Icon(Icons.close, color: text),
              onPressed: _exitSelecting,
            ),
            Expanded(
              child: Text(
                _selected.isEmpty
                    ? _l10n.selectHint
                    : _l10n.selectedCount(_selected.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: _l10n.selectAll,
              iconSize: 22,
              icon: Icon(Icons.select_all, color: text),
              onPressed: _selectAll,
            ),
          ],
        ),
      ),
    );
  }

  /// Bulk actions for the current selection, docked at the bottom.
  Widget _selectionBar(WallStyle wall) {
    final notes = _selectedNotes;
    final any = notes.isNotEmpty;
    final allPinned = any && notes.every((n) => n.pinned);
    final l10n = _l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: _Glass(
          decoration: _frosted(wall, radius: 16, strong: true),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _BarAction(
                icon: allPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: allPinned ? l10n.unpin : l10n.pinShort,
                color: wall.wallText,
                onTap: any ? _pinSelected : null,
              ),
              _BarAction(
                icon: Icons.palette_outlined,
                label: l10n.colorShort,
                color: wall.wallText,
                onTap: any ? _recolorSelected : null,
              ),
              // Piling is a wall thing: grid and list show every card.
              if (_notes.viewMode == ViewMode.wall)
                _BarAction(
                  icon: Icons.layers_outlined,
                  label: l10n.stackSelected,
                  color: wall.wallText,
                  onTap: notes.length > 1
                      ? () {
                          HapticFeedback.lightImpact();
                          _notes.stackNotes(notes);
                          _exitSelecting();
                        }
                      : null,
                ),
              if (_notes.boards.length > 1) ...[
                _BarAction(
                  icon: Icons.drive_file_move_outlined,
                  label: l10n.move,
                  color: wall.wallText,
                  onTap: any ? () => _moveToBoard(notes) : null,
                ),
                _BarAction(
                  icon: Icons.copy_all_outlined,
                  label: l10n.copy,
                  color: wall.wallText,
                  onTap: any ? () => _copyToBoard(notes) : null,
                ),
              ],
              _BarAction(
                icon: Icons.delete_outline,
                label: l10n.delete,
                color: wall.dark
                    ? const Color(0xFFFF8A80)
                    : AppColors.deleteIcon,
                onTap: any ? () => _deleteMany(notes) : null,
              ),
              Expanded(
                child: _moreButton(
                  wall,
                  child: _BarAction.face(
                    icon: Icons.more_vert,
                    label: l10n.moreActions,
                    color: wall.wallText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(WallStyle wall) {
    final text = wall.wallText;
    final faded = wall.wallTextFaded;
    return Padding(
      key: const ValueKey('search'),
      padding: const EdgeInsets.fromLTRB(0, 3, 8, 3),
      // A tap anywhere else on the screen means "done searching" — the same
      // way tapping away dismisses a text field.
      child: TapRegion(
        // On the wall, results are dimmed in place, so leaving is safe; in
        // grid and list the results *are* the screen — a tap there to open
        // one, or a scroll, only puts the keyboard away.
        onTapOutside: (_) {
          if (_notes.viewMode == ViewMode.wall ||
              _searchController.text.trim().isEmpty) {
            _setSearching(false);
          } else {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: _frosted(wall),
          child: Row(
            children: [
              IconButton(
                tooltip: _l10n.cancel,
                iconSize: 20,
                icon: Icon(Icons.arrow_back, color: text),
                onPressed: () => _setSearching(false),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  cursorColor: text,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: text, fontSize: 17),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: _l10n.search,
                    hintStyle: TextStyle(color: faded, fontSize: 17),
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox(width: 12)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Live hit count, so you know when to stop typing.
                          Text(
                            _l10n.resultCount(_notes.visibleNotes.length),
                            style: TextStyle(color: faded, fontSize: 13),
                          ),
                          IconButton(
                            tooltip: _l10n.clear,
                            iconSize: 18,
                            icon: Icon(Icons.close, color: faded),
                            onPressed: _searchController.clear,
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

  /// The second header row is the board strip alone, full width; the tools
  /// are in [_toolPill] at the bottom.
  Widget _buildToolRow(WallStyle wall) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
      child: SizedBox(
        height: 48,
        child: BoardBar(
          notes: _notes,
          textColor: wall.wallText,
          chipKeys: {
            for (final b in _notes.boards)
              b.id: _chipKeys.putIfAbsent(b.id, GlobalKey.new),
          },
          dropTarget: _dropTarget,
          onMemoryWall: _newMemoryWall,
        ),
      ),
    );
  }

  /// Filter, pen (wall) or sort (grid/list), layout and the more menu, in a
  /// frosted pill bottom-left, opposite the add button. Each tool is named
  /// under its icon: a row of bare icons was hard to read.
  Widget _toolPill(WallStyle wall) {
    return _Glass(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: _frosted(wall, radius: 28, strong: true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterButton(wall),
          if (_notes.viewMode == ViewMode.wall)
            Tooltip(
              message: _l10n.drawOnWall,
              child: Semantics(
                button: true,
                excludeSemantics: true,
                label: _l10n.drawOnWall,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _marking ? null : () => _startMarking(wall),
                  child: _toolFace(
                    Icon(Icons.gesture, color: wall.wallText),
                    _l10n.toolPen,
                    wall.wallText,
                  ),
                ),
              ),
            )
          else
            _sortButton(wall),
          _layoutButton(wall),
          _moreButton(
            wall,
            child: _toolFace(
              Icon(Icons.more_vert, color: wall.wallText),
              _l10n.toolMore,
              wall.wallText,
            ),
          ),
        ],
      ),
    );
  }

  /// One tool in the pill: its icon with a short name under it.
  Widget _toolFace(Widget icon, String label, Color color) {
    return SizedBox(
      width: 54,
      height: 52,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme.merge(data: const IconThemeData(size: 22), child: icon),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11, height: 1.1),
          ),
        ],
      ),
    );
  }

  /// The way to every kind of note besides the plain one the yellow button
  /// makes: a small labelled pill above it (its long-press does the same).
  Widget _moreKindsButton(WallStyle wall) {
    return Tooltip(
      message: _l10n.addOtherKinds,
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: _l10n.addOtherKinds,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: _quickAdd,
            child: _Glass(
              decoration: _frosted(wall, radius: 20, strong: true),
              padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: wall.wallText),
                  const SizedBox(width: 4),
                  Text(
                    _l10n.addOtherKindsShort,
                    style: TextStyle(color: wall.wallText, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<T> _menuItem<T>(
    T value,
    String label, {
    IconData? icon,
    bool selected = false,
  }) {
    return PopupMenuItem<T>(
      value: value,
      child: Semantics(
        selected: selected,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.ink),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: AppColors.ink),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(WallStyle wall) {
    final l10n = _l10n;
    final active = _notes.typeFilter != -1;
    final options = [
      (-1, l10n.typeAll, Icons.all_inclusive),
      (0, l10n.typeNormal, Icons.notes),
      (1, l10n.typeLink, Icons.link),
      (2, l10n.typeChecklist, Icons.checklist),
      (3, l10n.typeDrawing, Icons.brush_outlined),
      (4, l10n.typePhoto, Icons.photo_outlined),
      (5, l10n.typeLabel, Icons.label_outline),
      (6, l10n.typeAudio, Icons.voicemail),
    ];
    return PopupMenuButton<int>(
      tooltip: l10n.type,
      child: _toolFace(
        Badge(
          isLabelVisible: active,
          smallSize: 8,
          backgroundColor: AppColors.accent,
          child: Icon(
            active ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: wall.wallText,
          ),
        ),
        l10n.toolFilter,
        wall.wallText,
      ),
      onSelected: (v) => _notes.typeFilter = v,
      itemBuilder: (context) => [
        for (final (key, label, icon) in options)
          _menuItem(key, label, icon: icon, selected: _notes.typeFilter == key),
      ],
    );
  }

  Widget _sortButton(WallStyle wall) {
    final l10n = _l10n;
    // (label, icon, byCreated, ascending)
    final options = [
      (l10n.sortNewest, Icons.schedule, true, false),
      (l10n.sortOldest, Icons.history, true, true),
      (l10n.sortAZ, Icons.sort_by_alpha, false, true),
      (l10n.sortZA, Icons.sort_by_alpha, false, false),
    ];
    return PopupMenuButton<int>(
      tooltip: l10n.sortTooltip,
      child: _toolFace(
        Icon(Icons.swap_vert, color: wall.wallText),
        l10n.toolSort,
        wall.wallText,
      ),
      onSelected: (i) =>
          _notes.setSort(byCreated: options[i].$3, ascending: options[i].$4),
      itemBuilder: (context) => [
        for (final (i, o) in options.indexed)
          _menuItem(
            i,
            o.$1,
            icon: o.$2,
            selected:
                _notes.sortByCreated == o.$3 && _notes.sortAscending == o.$4,
          ),
      ],
    );
  }

  String _layoutLabel(ViewMode mode) => switch (mode) {
    ViewMode.wall => _l10n.viewWall,
    ViewMode.grid => _l10n.viewGrid,
    ViewMode.list => _l10n.viewList,
  };

  Widget _layoutButton(WallStyle wall) {
    // Shows the *current* layout and opens a menu, instead of the old cycling
    // button whose icon meant "what you'll get next".
    return PopupMenuButton<ViewMode>(
      tooltip: _l10n.layout,
      child: _toolFace(
        Icon(
          _HomeScreenState._layoutIcon(_notes.viewMode),
          color: wall.wallText,
        ),
        _layoutLabel(_notes.viewMode),
        wall.wallText,
      ),
      onSelected: (m) => _notes.viewMode = m,
      itemBuilder: (context) => [
        for (final mode in ViewMode.values)
          _menuItem(
            mode,
            _layoutLabel(mode),
            icon: _HomeScreenState._layoutIcon(mode),
            selected: _notes.viewMode == mode,
          ),
      ],
    );
  }

  /// Everything that didn't earn its own button: photos, select, tidy, trash,
  /// lights.
  /// The ⋮ menu. With [child] it wears that instead of the bare icon (the
  /// selection bar gives it an icon-and-label face like its neighbours).
  Widget _moreButton(WallStyle wall, {Widget? child}) {
    final l10n = _l10n;
    final onWall = _notes.viewMode == ViewMode.wall;
    final canTidy = onWall && _notes.boardNotes.length > 1;
    final night = isNight(context);
    final trashCount = _notes.trashCount;
    return PopupMenuButton<String>(
      tooltip: l10n.moreActions,
      icon: child == null ? Icon(Icons.more_vert, color: wall.wallText) : null,
      child: child,
      onSelected: (v) {
        switch (v) {
          case 'photos':
            _pinPhotos();
          case 'select':
            if (_notes.boardNotes.isNotEmpty) {
              _update(() {
                _selecting = true;
                _selected.clear();
              });
            }
          case 'tidy':
            HapticFeedback.lightImpact();
            _wallHandle.tidy();
          case 'tidyColor':
            HapticFeedback.lightImpact();
            _wallHandle.tidy(byColor: true);
          case 'export':
            _exportBoard();
          case 'draw':
            _startMarking(wall);
          case 'fit':
            _wallHandle.fitAll();
          case 'tips':
            _showTips();
          case 'gallery':
            GalleryScreen.open(
              context,
              notes: _notes,
            ).then((r) => mounted ? showGalleryResult(context, r) : null);
          case 'trash':
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TrashScreen(notes: _notes),
              ),
            );
          case 'lights':
            widget.settings.setNightMode(night ? NightMode.off : NightMode.on);
        }
      },
      // Grouped: add to the wall, arrange it, take it away, the app.
      itemBuilder: (context) => [
        _menuItem(
          'gallery',
          l10n.galleryTitle,
          icon: Icons.dashboard_customize_outlined,
        ),
        _menuItem(
          'photos',
          l10n.pinPhotos,
          icon: Icons.add_photo_alternate_outlined,
        ),
        // On the wall the pen has its own button in the pill.
        if (!onWall) _menuItem('draw', l10n.drawOnWall, icon: Icons.gesture),
        if (_notes.boardNotes.isNotEmpty) ...[
          const PopupMenuDivider(),
          _menuItem('select', l10n.select, icon: Icons.checklist_rtl),
          if (canTidy) ...[
            _menuItem(
              'tidy',
              l10n.tidy,
              icon: Icons.auto_awesome_mosaic_outlined,
            ),
            _menuItem(
              'tidyColor',
              l10n.tidyByColor,
              icon: Icons.palette_outlined,
            ),
          ],
          if (onWall)
            _menuItem('fit', l10n.fitAll, icon: Icons.fit_screen_outlined),
          _menuItem('export', l10n.exportBoard, icon: Icons.image_outlined),
        ],
        const PopupMenuDivider(),
        _menuItem(
          'trash',
          trashCount > 0 ? '${l10n.trash} ($trashCount)' : l10n.trash,
          icon: Icons.delete_outline,
        ),
        _menuItem(
          'lights',
          night ? l10n.lightsOn : l10n.lightsOff,
          icon: night ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        ),
        _menuItem('tips', l10n.gestureTips, icon: Icons.lightbulb_outline),
      ],
    );
  }
}

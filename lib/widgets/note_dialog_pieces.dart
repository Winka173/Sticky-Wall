part of 'note_dialog.dart';

/// The editor's parts below and around the paper's words: the adhesive
/// strip, photo tile, writing area and formatting, error line, link field,
/// checklist, reminder line, tool rows, emotes and paper colours.
extension _EditorPieces on _NoteDialogState {
  // --- pieces ---------------------------------------------------------------

  /// The adhesive strip along the top carries Cancel and Save, so saving is
  /// always one tap away and never hidden under the keyboard.
  Widget _topStrip(AppLocalizations l10n) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0x2EFFFFFF),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.paper),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.cancel,
            color: _NoteDialogState._ink,
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: widget.isNew ? l10n.add : l10n.save,
              child: Material(
                color: _NoteDialogState._ink,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _save,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.check, size: 22, color: AppColors.chalk),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The attached photo, full width at its own aspect ratio, with a remove
  /// button in its corner; tapping it opens it full screen. A photo note with
  /// nothing attached yet shows a stretched "add photo" tile as an invitation.
  Widget _photoTile(AppLocalizations l10n) {
    const faint = AppColors.inkSoft;
    if (!_n.hasPhoto) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: _NoteDialogState._ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _photoMenu(l10n),
            child: SizedBox(
              width: double.infinity,
              height: 96,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 26,
                    color: faint,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.addPhoto,
                    style: TextStyle(fontSize: 13, color: faint),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          KeyboardTappable(
            onActivate: () => showPhotoViewer(context, _n.imagePath),
            borderRadius: BorderRadius.circular(6),
            child: GestureDetector(
              onTap: () => showPhotoViewer(context, _n.imagePath),
              child: NotePhoto(path: _n.imagePath, maxHeight: 220, radius: 6),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: l10n.removePhoto,
              onPressed: _removePhoto,
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 14,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The writing surface: the same handwriting style the card uses, over
  /// faint ruled lines that sit exactly under each baseline — so typing here
  /// reads as writing on the paper, and what you see is what gets stuck up.
  Widget _writingArea(AppLocalizations l10n) {
    final isNormal = _n.type == NoteType.normal;
    final isPhoto = _n.type == NoteType.photo;
    final isLabel = _n.type == NoteType.label;
    final isAudio = _n.type == NoteType.audio;
    final style = noteBodyStyle(context);
    final lineHeight = style.fontSize! * style.height!;
    final strut = StrutStyle(
      fontSize: style.fontSize,
      height: style.height,
      forceStrutHeight: true,
    );

    final field = TextField(
      controller: _content,
      // A new photo note starts by picking photos, a voice note by
      // speaking — not by typing.
      autofocus: widget.isNew && !isPhoto && !isAudio,
      cursorColor: _NoteDialogState._ink,
      style: style,
      strutStyle: strut,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: isNormal ? TextInputType.multiline : TextInputType.text,
      textInputAction: isNormal
          ? TextInputAction.newline
          : _n.type == NoteType.drawing || isPhoto || isLabel || isAudio
          ? TextInputAction.done
          : TextInputAction.next,
      onSubmitted: isNormal
          ? null
          : (_) => switch (_n.type) {
              NoteType.link => _urlFocus.requestFocus(),
              NoteType.checklist =>
                (_items.isEmpty ? _newItemFocus : _items.first.focus)
                    .requestFocus(),
              _ => null,
            },
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: isNormal
            ? l10n.contentHint
            : isPhoto
            ? l10n.caption
            : isLabel
            ? l10n.labelHint
            : l10n.title,
        hintStyle: style.copyWith(color: AppColors.inkHint),
      ),
      maxLines: isNormal
          ? null
          : isPhoto || isLabel
          ? 2
          : 1,
      minLines: isNormal ? 5 : 1,
    );

    if (!isNormal) return field;

    // Where the first baseline falls inside a strut-sized line box.
    final probe = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      strutStyle: strut,
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = probe.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    probe.dispose();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Positioned.fill(
              // Plain and lined paper write on faint rules; the other papers
              // show their own squares, dots or card lines while writing.
              child: CustomPaint(
                painter:
                    _n.paper == PaperStyle.plain || _n.paper == PaperStyle.lined
                    ? _RulesPainter(
                        firstLine: baseline + 2,
                        lineHeight: lineHeight,
                        color: _NoteDialogState._ink.withValues(alpha: 0.12),
                      )
                    : PaperPatternPainter(
                        _n.paper,
                        line: lineHeight,
                        first: baseline + 2,
                        margin: false,
                      ),
              ),
            ),
            field,
          ],
        ),
        _formatRow(l10n),
      ],
    );
  }

  // --- formatting -------------------------------------------------------------

  /// Bold, italic and bullets for the text of a normal note. The markers are
  /// typed into the text (`**bold**`, `*italic*`, `- item`) and the card
  /// renders them — what you see here is the recipe, the wall the dish.
  Widget _formatRow(AppLocalizations l10n) {
    Widget button(String tooltip, IconData icon, VoidCallback onTap) =>
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: 20),
          color: _NoteDialogState._ink,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          alignment: Alignment.centerLeft,
          onPressed: onTap,
        );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          button(l10n.bold, Icons.format_bold, () => _wrapSelection('**')),
          button(l10n.italic, Icons.format_italic, () => _wrapSelection('*')),
          button(l10n.bullets, Icons.format_list_bulleted, _toggleBullets),
        ],
      ),
    );
  }

  /// Puts [marker] round the selected text — or, with nothing selected, a
  /// pair of markers at the cursor, ready to be typed into.
  void _wrapSelection(String marker) {
    final value = _content.value;
    final text = value.text;
    var sel = value.selection;
    if (!sel.isValid) sel = TextSelection.collapsed(offset: text.length);
    final start = sel.start;
    final end = sel.end;
    final wrapped = '$marker${text.substring(start, end)}$marker';
    _content.value = TextEditingValue(
      text: text.replaceRange(start, end, wrapped),
      selection: start == end
          ? TextSelection.collapsed(offset: start + marker.length)
          : TextSelection(
              baseOffset: start + marker.length,
              extentOffset: end + marker.length,
            ),
    );
  }

  /// Puts "- " in front of every line the selection touches, or takes it off
  /// again when they all have it.
  void _toggleBullets() {
    final value = _content.value;
    final text = value.text;
    var sel = value.selection;
    if (!sel.isValid) sel = TextSelection.collapsed(offset: text.length);
    final lineStart = sel.start == 0
        ? 0
        : text.lastIndexOf('\n', sel.start - 1) + 1;
    var lineEnd = text.indexOf('\n', sel.end);
    if (lineEnd == -1) lineEnd = text.length;
    final lines = text.substring(lineStart, lineEnd).split('\n');
    final bullet = RegExp(r'^(\s*)- ');
    final all = lines.every(bullet.hasMatch);
    final next = [
      for (final l in lines)
        all
            ? l.replaceFirstMapped(bullet, (m) => m.group(1)!)
            : bullet.hasMatch(l)
            ? l
            : '- $l',
    ].join('\n');
    _content.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineEnd, next),
      // Keep the lines selected, so pressing again takes the bullets off.
      selection: sel.isCollapsed
          ? TextSelection.collapsed(offset: lineStart + next.length)
          : TextSelection(
              baseOffset: lineStart,
              extentOffset: lineStart + next.length,
            ),
    );
  }

  Widget _errorLine() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.topLeft,
      child: _error == null
          ? const SizedBox(width: double.infinity)
          // Announced as it appears: the shake alone says nothing to a
          // screen reader.
          : Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.warnText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.warnText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _urlField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              Icons.link,
              size: 18,
              color: _NoteDialogState._ink.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _url,
              focusNode: _urlFocus,
              cursorColor: _NoteDialogState._ink,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: const TextStyle(fontSize: 16, color: AppColors.link),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                hintText: l10n.link,
                hintStyle: TextStyle(fontSize: 16, color: AppColors.inkHint),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistEditor(AppLocalizations l10n) {
    final itemStyle = TextStyle(
      fontSize: 17 * noteFontScale(context),
      color: _NoteDialogState._ink,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _items.length; i++)
          Row(
            children: [
              Checkbox(
                semanticLabel: _items[i].controller.text,
                value: _n.checklist[i].done,
                activeColor: _NoteDialogState._ink,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: _NoteDialogState._ink.withValues(alpha: 0.6),
                ),
                onChanged: (v) =>
                    _update(() => _n.checklist[i].done = v ?? false),
              ),
              Expanded(
                // Items are editable in place rather than delete-and-retype.
                child: TextField(
                  controller: _items[i].controller,
                  focusNode: _items[i].focus,
                  cursorColor: _NoteDialogState._ink,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) {
                    _n.checklist[i].text = v;
                    _clearError();
                  },
                  onSubmitted: (_) =>
                      (i + 1 < _items.length
                              ? _items[i + 1].focus
                              : _newItemFocus)
                          .requestFocus(),
                  style: itemStyle.copyWith(
                    decoration: _n.checklist[i].done
                        ? TextDecoration.lineThrough
                        : null,
                    color: _n.checklist[i].done
                        ? AppColors.inkSoft
                        : _NoteDialogState._ink,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.delete,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                color: _NoteDialogState._ink.withValues(alpha: 0.5),
                icon: const Icon(Icons.close),
                onPressed: () => _removeItem(i),
              ),
            ],
          ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.add,
                size: 20,
                color: _NoteDialogState._ink.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _newItem,
                focusNode: _newItemFocus,
                cursorColor: _NoteDialogState._ink,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                // Adds the item and keeps the keyboard up for the next one
                // (a bare onSubmitted would let the field lose focus).
                onEditingComplete: _addItem,
                style: itemStyle,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: l10n.addItem,
                  hintStyle: itemStyle.copyWith(color: AppColors.inkHint),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reminderLine(AppLocalizations l10n) {
    final ml = MaterialLocalizations.of(context);
    final repeats = _n.repeat != ReminderRepeat.none;
    // For a repeating reminder show when it rings *next*, not when it began.
    final at = _n.nextReminder()!;
    final overdue = !repeats && at.isBefore(DateTime.now());
    final color = overdue ? AppColors.warnText : AppColors.inkSoft;
    final label =
        '${ml.formatMediumDate(at)} ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(repeats ? Icons.repeat : Icons.alarm, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: _pickReminder,
              child: Text(label, style: TextStyle(fontSize: 14, color: color)),
            ),
          ),
          // "Once / Daily / Weekly / Monthly" — a small pill that opens a menu.
          PopupMenuButton<ReminderRepeat>(
            tooltip: l10n.repeat,
            initialValue: _n.repeat,
            onSelected: (r) => _update(() => _n.repeat = r),
            itemBuilder: (_) => [
              for (final r in ReminderRepeat.values)
                PopupMenuItem(
                  value: r,
                  child: Text(_NoteDialogState.repeatLabel(l10n, r)),
                ),
            ],
            // The pill stays small; the padding around it is the target.
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _NoteDialogState._ink.withValues(
                    alpha: repeats ? 0.14 : 0.07,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _NoteDialogState.repeatLabel(l10n, _n.repeat),
                  style: const TextStyle(
                    fontSize: 13,
                    color: _NoteDialogState._ink,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.removeReminder,
            color: _NoteDialogState._ink,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _update(() {
              _n.reminderAt = null;
              _n.repeat = ReminderRepeat.none;
              _notificationsOff = false;
            }),
          ),
        ],
      ),
    );
  }

  Widget _notificationsOffLine(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 16,
            color: AppColors.warnText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.notificationsOff,
              style: const TextStyle(fontSize: 13, color: AppColors.warnText),
            ),
          ),
        ],
      ),
    );
  }

  /// The note type on one row, then what can be added to it — photo,
  /// reminder, emote, paper colour — on the next, so nothing sits scrolled
  /// out of sight past the paper's edge.
  Widget _toolRow(AppLocalizations l10n) {
    final types = [
      (NoteType.normal, Icons.notes, l10n.typeNormal),
      (NoteType.link, Icons.link, l10n.typeLink),
      (NoteType.checklist, Icons.checklist, l10n.typeChecklist),
      (NoteType.drawing, Icons.brush_outlined, l10n.typeDrawing),
      (NoteType.photo, Icons.photo_outlined, l10n.typePhoto),
      (NoteType.label, Icons.label_outline, l10n.typeLabel),
      (NoteType.audio, Icons.voicemail, l10n.typeAudio),
    ];
    final isPhoto = _n.type == NoteType.photo;
    final isAudio = _n.type == NoteType.audio;
    final isLabel = _n.type == NoteType.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _NoteDialogState._ink.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              for (final (t, icon, label) in types)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: _n.type == t,
                    child: Tooltip(
                      message: label,
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => _setType(t),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 40,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17),
                                color: _n.type == t
                                    ? _NoteDialogState._ink
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                icon,
                                size: 19,
                                color: _n.type == t
                                    ? AppColors.chalk
                                    : _NoteDialogState._ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Filled icons mark what the note already has; outlined, what it
        // could have — never a faded icon that is hard to see on the paper.
        // Pulled out by an icon button's inner padding, so the icons line
        // up with the type pill and the text above.
        Transform.translate(
          offset: const Offset(-12, 0),
          child: Row(
            children: [
              // A photo note already has its add tile above; a cassette has
              // no room for a picture.
              if (!isPhoto && !isAudio)
                IconButton(
                  tooltip: _n.hasPhoto ? l10n.replacePhoto : l10n.addPhoto,
                  onPressed: () => _photoMenu(l10n),
                  color: _NoteDialogState._ink,
                  icon: Icon(
                    _n.hasPhoto
                        ? Icons.photo_camera_back
                        : Icons.photo_camera_back_outlined,
                    size: 22,
                  ),
                ),
              // A label is a heading, not something to be reminded of.
              if (!isLabel)
                IconButton(
                  tooltip: l10n.reminder,
                  onPressed: _pickReminder,
                  color: _NoteDialogState._ink,
                  icon: Icon(
                    _n.reminderAt == null ? Icons.alarm_add : Icons.alarm_on,
                    size: 22,
                  ),
                ),
              IconButton(
                tooltip: l10n.emote,
                isSelected: _showEmoji,
                onPressed: () => _update(() {
                  _showEmoji = !_showEmoji;
                  _showColors = false;
                }),
                color: _NoteDialogState._ink,
                icon: _n.emoji.isEmpty
                    ? const Icon(Icons.add_reaction_outlined, size: 22)
                    : Text(_n.emoji, style: const TextStyle(fontSize: 20)),
              ),
              // Prints are always white — no paper colour to choose.
              if (!isPhoto)
                IconButton(
                  tooltip: '${l10n.color}: ${paperName(l10n, _n.colorIndex)}',
                  isSelected: _showColors,
                  onPressed: () => _update(() {
                    _showColors = !_showColors;
                    _showEmoji = false;
                  }),
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: paperColorOf(context, _n.colorIndex, _n.guid),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _NoteDialogState._ink,
                        width: _showColors ? 2.2 : 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _photoMenu(AppLocalizations l10n) async {
    final source = await showActionSheet<ImageSource>(
      context,
      title: _n.hasPhoto ? l10n.replacePhoto : l10n.addPhoto,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(l10n.fromGallery),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text(l10n.takePhoto),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
      ],
    );
    if (source != null && mounted) await _attachPhoto(source);
  }

  Widget _emojiStrip() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final emoji in _emojiChoices)
              Semantics(
                selected: _n.emoji == emoji,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _update(() {
                    _n.emoji = _n.emoji == emoji ? '' : emoji;
                    _showEmoji = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _n.emoji == emoji
                          ? _NoteDialogState._ink.withValues(alpha: 0.16)
                          : null,
                    ),
                    constraints: const BoxConstraints(minWidth: 44),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _colorRow(AppLocalizations l10n) {
    final pro = ProScope.unlockedOf(context);
    // Ruling only goes on sheets of paper, not on prints, tape or tapes.
    final ruled = switch (_n.type) {
      NoteType.normal || NoteType.link || NoteType.checklist => true,
      _ => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_paperColors(l10n, pro), if (ruled) _paperStyles(l10n, pro)],
    );
  }

  /// The ruling on the paper: plain, or (with Pro) lined, grid, dots, an
  /// index card or a notebook page — each shown on a scrap of the note's
  /// own colour.
  Widget _paperStyles(AppLocalizations l10n, bool pro) {
    final paper = noteColor(_n.colorIndex, _n.guid);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final style in PaperStyle.values.where(
              (s) => s.suits(_n.type),
            ))
              _paperStyleTile(
                l10n,
                style: style,
                paper: paper,
                selected: _n.paper == style,
                locked: style.pro && !pro,
              ),
          ],
        ),
      ),
    );
  }

  Widget _paperStyleTile(
    AppLocalizations l10n, {
    required PaperStyle style,
    required Color paper,
    required bool selected,
    required bool locked,
  }) {
    final name = paperStyleLabel(l10n, style);
    void pick() {
      if (locked) {
        showProSheet(context);
        return;
      }
      HapticFeedback.selectionClick();
      _update(() => _n.paper = style);
    }

    return Semantics(
      button: true,
      selected: selected,
      label: locked ? l10n.proLocked(name) : name,
      excludeSemantics: true,
      child: Tooltip(
        message: name,
        child: InkWell(
          onTap: pick,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: paper,
                    border: Border.all(
                      color: selected ? _NoteDialogState._ink : Colors.black26,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: CustomPaint(
                    painter: PaperPatternPainter(style, line: 14, top: 2),
                  ),
                ),
                if (locked)
                  const Positioned(right: -6, bottom: -4, child: ProMark()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paperColors(AppLocalizations l10n, bool pro) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        children: [
          _swatch(
            name: paperName(l10n, null),
            color: noteColor(null, _n.guid),
            selected: _n.colorIndex == null,
            auto: true,
            onTap: () => _pickColor(null),
          ),
          for (var i = 0; i < AppColors.notePapers.length; i++)
            if (!pro && i >= AppColors.freePapers)
              _swatch(
                name: l10n.proLocked(paperName(l10n, i)),
                color: AppColors.notePapers[i],
                // Kept when it came from a backup or a Pro phone.
                selected: _n.colorIndex == i,
                locked: true,
                onTap: () => showProSheet(context),
              )
            else
              _swatch(
                name: paperName(l10n, i),
                color: AppColors.notePapers[i],
                selected: _n.colorIndex == i,
                onTap: () => _pickColor(i),
              ),
          // A colour of one's own: the rainbow until one is mixed, then it.
          _swatch(
            name: pro ? l10n.paperCustom : l10n.proLocked(l10n.paperCustom),
            color: isCustomPaper(_n.colorIndex)
                ? noteColor(_n.colorIndex, _n.guid)
                : AppColors.paper,
            selected: isCustomPaper(_n.colorIndex),
            rainbow: !isCustomPaper(_n.colorIndex),
            locked: !pro,
            onTap: pro ? _mixColor : () => showProSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _mixColor() async {
    final mixed = await showPaperColorDialog(
      context,
      initial: isCustomPaper(_n.colorIndex)
          ? noteColor(_n.colorIndex, _n.guid)
          : null,
    );
    if (mixed != null) _pickColor(mixed);
  }

  void _pickColor(int? index) {
    HapticFeedback.selectionClick();
    _update(() {
      _n.colorIndex = index;
      _showColors = false;
    });
  }

  Widget _swatch({
    required String name,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    bool auto = false,
    bool locked = false,
    bool rainbow = false,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: selected ? 32 : 26,
              height: selected ? 32 : 26,
              decoration: BoxDecoration(
                color: color,
                gradient: rainbow
                    ? const SweepGradient(
                        colors: [
                          Color(0xFFF8BBD0),
                          Color(0xFFFFF59D),
                          Color(0xFFB2DFDB),
                          Color(0xFFB3E5FC),
                          Color(0xFFE1BEE7),
                          Color(0xFFF8BBD0),
                        ],
                      )
                    : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _NoteDialogState._ink : Colors.black26,
                  width: selected ? 2 : 1,
                ),
              ),
              child: auto
                  ? Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: _NoteDialogState._ink.withValues(alpha: 0.7),
                    )
                  : locked
                  ? Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: _NoteDialogState._ink.withValues(alpha: 0.6),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint horizontal ruled lines, one just under each text baseline, so the
/// writing sits on them like real note paper.
class _RulesPainter extends CustomPainter {
  _RulesPainter({
    required this.firstLine,
    required this.lineHeight,
    required this.color,
  });

  final double firstLine;
  final double lineHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (lineHeight <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = firstLine; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RulesPainter oldDelegate) =>
      oldDelegate.firstLine != firstLine ||
      oldDelegate.lineHeight != lineHeight ||
      oldDelegate.color != color;
}

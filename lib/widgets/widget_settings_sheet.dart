part of 'settings_sheet.dart';

/// The home-screen widget's colours, as the Android and iOS widgets draw
/// them (keep in step with StickyWidgetProvider.kt and StickyWidget.swift).
({Color background, Color text, Color faded}) widgetColors(WidgetLook look) =>
    switch (look) {
      WidgetLook.wall => (
        background: const Color(0xFF6B5849),
        text: AppColors.chalk,
        faded: const Color(0xCCFDFBF3),
      ),
      WidgetLook.paper => (
        background: AppColors.paper,
        text: AppColors.ink,
        faded: const Color(0xCC3B372F),
      ),
      WidgetLook.ink => (
        background: const Color(0xFF2B2A25),
        text: AppColors.chalk,
        faded: const Color(0xCCFDFBF3),
      ),
    };

/// Title and line sizes of the widget, in sp.
(double, double) widgetTextSizes(WidgetTextSize size) => switch (size) {
  WidgetTextSize.small => (14, 12),
  WidgetTextSize.normal => (16, 14),
  WidgetTextSize.large => (19, 17),
};

/// Opens the widget's settings: which wall, what it lists, its colours and
/// text size, over a live preview.
Future<void> showWidgetSettingsSheet(
  BuildContext context, {
  required SettingsController settings,
  required NotesController notes,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([settings, notes]),
        builder: (context, _) =>
            _WidgetSettings(settings: settings, notes: notes),
      ),
    ),
  );
}

class _WidgetSettings extends StatelessWidget {
  const _WidgetSettings({required this.settings, required this.notes});

  final SettingsController settings;
  final NotesController notes;

  String _boardName(AppLocalizations l10n, Board board) {
    final name = board.name.isEmpty ? l10n.defaultBoardName : board.name;
    return board.icon.isEmpty ? name : '${board.icon} $name';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final boards = notes.boards;
    // A wall that was deleted falls back to the open one, as on the widget.
    final chosen = boards.any((b) => b.id == settings.widgetBoard)
        ? settings.widgetBoard
        : '';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                l10n.widgetSection,
                style: const TextStyle(fontSize: 22, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 16),
            _WidgetPreview(settings: settings, notes: notes),
            const SizedBox(height: 8),
            _SectionTitle(l10n.widgetBoardLabel),
            InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: chosen,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l10n.widgetBoardCurrent),
                    ),
                    for (final board in boards)
                      DropdownMenuItem(
                        value: board.id,
                        child: Text(
                          _boardName(l10n, board),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    if (id != null) settings.setWidgetBoard(id);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SectionTitle(l10n.widgetContentLabel),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (content, label, icon) in [
                  (
                    WidgetContent.pinned,
                    l10n.widgetContentPinned,
                    Icons.push_pin_outlined,
                  ),
                  (
                    WidgetContent.newest,
                    l10n.widgetContentNewest,
                    Icons.schedule_outlined,
                  ),
                  // Offered once a picture has been sent from the board
                  // export; it stays on the widget until replaced.
                  if (settings.widgetPicture)
                    (
                      WidgetContent.picture,
                      l10n.widgetContentPicture,
                      Icons.image_outlined,
                    ),
                ])
                  _choiceChip(
                    icon: icon,
                    label: label,
                    selected: settings.widgetContent == content,
                    onSelected: () => settings.setWidgetContent(content),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SectionTitle(l10n.widgetLookLabel),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (look, label) in [
                  (WidgetLook.wall, l10n.widgetLookWall),
                  (WidgetLook.paper, l10n.widgetLookPaper),
                  (WidgetLook.ink, l10n.widgetLookInk),
                ])
                  _choiceChip(
                    label: label,
                    selected: settings.widgetLook == look,
                    onSelected: () => settings.setWidgetLook(look),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SectionTitle(l10n.widgetTextSizeLabel),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (size, label) in [
                  (WidgetTextSize.small, l10n.widgetTextSmall),
                  (WidgetTextSize.normal, l10n.widgetTextNormal),
                  (WidgetTextSize.large, l10n.widgetTextLarge),
                ])
                  _choiceChip(
                    label: label,
                    selected: settings.widgetTextSize == size,
                    onSelected: () => settings.setWidgetTextSize(size),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.widgetAddHint,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

/// The widget as it will look with these settings and these notes.
class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({required this.settings, required this.notes});

  final SettingsController settings;
  final NotesController notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = widgetColors(settings.widgetLook);
    final (titleSize, lineSize) = widgetTextSizes(settings.widgetTextSize);
    final board =
        notes.boards.where((b) => b.id == settings.widgetBoard).firstOrNull ??
        notes.currentBoard;
    final content = settings.widgetContent;
    final shown = WidgetService.notesFor(notes.allNotes, board.id, content);
    // The widget draws in the system font; so does the preview.
    const system = 'Roboto';
    final lines = [
      for (final note in shown.take(WidgetService.maxLines))
        WidgetService.lineFor(
          note,
          l10n.typeChecklist,
          l10n.typeDrawing,
          l10n.typePhoto,
          l10n.typeAudio,
        ),
    ];

    return ExcludeSemantics(
      child: Container(
        height: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(20),
          border: settings.widgetLook == WidgetLook.paper
              ? Border.all(color: AppColors.inkHint)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: content == WidgetContent.picture
            ? Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 40,
                  color: colors.faded,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    board.name.isEmpty ? l10n.defaultBoardName : board.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: system,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (lines.isEmpty)
                    Text(
                      content == WidgetContent.newest
                          ? l10n.widgetEmptyNewest
                          : l10n.widgetEmptyPinned,
                      style: TextStyle(
                        fontFamily: system,
                        fontSize: lineSize,
                        color: colors.faded,
                      ),
                    ),
                  // As many lines as fit, like the real widget.
                  Expanded(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxHeight: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final line in lines)
                              Text(
                                '• $line',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: system,
                                  fontSize: lineSize,
                                  height: 1.35,
                                  color: colors.text,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

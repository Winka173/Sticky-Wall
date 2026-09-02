import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../screens/trash_screen.dart';
import '../services/backup_service.dart';
import '../services/image_service.dart';
import '../services/notes_controller.dart';
import '../services/settings_controller.dart';
import '../theme.dart';

String wallLabel(AppLocalizations l10n, String id) => switch (id) {
      'cork' => l10n.wallCork,
      'chalk_green' => l10n.wallChalkGreen,
      'chalk_black' => l10n.wallChalkBlack,
      'plaster' => l10n.wallPlaster,
      'brick' => l10n.wallBrick,
      'wood' => l10n.wallWood,
      _ => id,
    };

String nightModeLabel(AppLocalizations l10n, NightMode mode) => switch (mode) {
      NightMode.off => l10n.nightModeOff,
      NightMode.on => l10n.nightModeOn,
      NightMode.system => l10n.nightModeSystem,
      NightMode.schedule => l10n.nightModeSchedule,
    };

String hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

Future<void> showSettingsSheet(
  BuildContext context, {
  required SettingsController settings,
  required NotesController notes,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: Listenable.merge([settings, notes]),
      builder: (context, _) =>
          _SettingsSheet(settings: settings, notes: notes),
    ),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.settings, required this.notes});

  final SettingsController settings;
  final NotesController notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final board = notes.currentBoard;

    return DraggableScrollableSheet(
      expand: false,
      // Opens just past the wall picker; drag up for lights, fonts and data.
      initialChildSize: 0.58,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Center(
            child: Text(l10n.customize,
                style: const TextStyle(fontSize: 24, color: AppColors.ink)),
          ),
          const SizedBox(height: 12),
          _SectionTitle(l10n.wallSection),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: walls.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == walls.length) {
                  return _PhotoWallTile(
                    board: board,
                    l10n: l10n,
                    onTap: () => _photoWallFlow(context, l10n),
                  );
                }
                final wall = walls[index];
                final selected =
                    !board.hasWallImage && index == board.wallIndex;
                return _WallTile(
                  label: wallLabel(l10n, wall.id),
                  selected: selected,
                  onTap: () => notes.setCurrentBoardWall(index),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(wall.asset, fit: BoxFit.cover),
                      ColoredBox(color: wall.overlay),
                    ],
                  ),
                );
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.wallDecor,
                style: const TextStyle(fontSize: 16, color: AppColors.ink)),
            secondary: const Icon(Icons.water_drop_outlined,
                color: AppColors.ink),
            value: settings.wallDecor,
            onChanged: settings.setWallDecor,
          ),
          const SizedBox(height: 8),
          _SectionTitle(l10n.nightSection),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final mode in NightMode.values)
                ChoiceChip(
                  avatar: Icon(
                    switch (mode) {
                      NightMode.off => Icons.light_mode_outlined,
                      NightMode.on => Icons.dark_mode_outlined,
                      NightMode.system => Icons.phone_android_outlined,
                      NightMode.schedule => Icons.schedule_outlined,
                    },
                    size: 18,
                  ),
                  label: Text(nightModeLabel(l10n, mode)),
                  selected: settings.nightMode == mode,
                  onSelected: (_) => settings.setNightMode(mode),
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: settings.nightMode == NightMode.schedule
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _HourField(
                            label: l10n.nightStart,
                            value: settings.nightStart,
                            onChanged: (h) => settings.setNightHours(
                                start: h, end: settings.nightEnd),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HourField(
                            label: l10n.nightEnd,
                            value: settings.nightEnd,
                            onChanged: (h) => settings.setNightHours(
                                start: settings.nightStart, end: h),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 8),
          _SectionTitle(l10n.fontSection),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fontChoices.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final font = fontChoices[index];
                return _FontPaper(
                  font: font,
                  preview: l10n.fontPreview,
                  selected: settings.font.id == font.id,
                  tilt: (index.isEven ? -1 : 1) * 0.03,
                  onTap: () => settings.setFontId(font.id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _SectionTitle(l10n.languageSection),
          Wrap(
            spacing: 8,
            children: [
              for (final (code, label) in [
                ('system', l10n.langSystem),
                ('vi', 'Tiếng Việt'),
                ('en', 'English'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: settings.languageCode == code,
                  onSelected: (_) => settings.setLanguageCode(code),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.dataSection),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline, color: AppColors.ink),
            title: Text(l10n.trash,
                style: const TextStyle(fontSize: 16, color: AppColors.ink)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (notes.trashCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${notes.trashCount}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.ink)),
                  ),
                const Icon(Icons.chevron_right, color: AppColors.inkSoft),
              ],
            ),
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(MaterialPageRoute<void>(
                builder: (_) => TrashScreen(notes: notes),
              ));
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.autoTrashDone,
                style: const TextStyle(fontSize: 16, color: AppColors.ink)),
            subtitle: Text(l10n.autoTrashDoneHint,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            secondary:
                const Icon(Icons.task_alt_outlined, color: AppColors.ink),
            value: settings.autoTrashDone,
            onChanged: (on) {
              settings.setAutoTrashDone(on);
              if (on) notes.sweepCompleted();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => BackupService()
                      .share(notes.boards, notes.allNotes),
                  icon: const Icon(Icons.ios_share),
                  label: Text(l10n.exportData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _importFlow(context, l10n),
                  icon: const Icon(Icons.download),
                  label: Text(l10n.importData),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _photoWallFlow(
      BuildContext context, AppLocalizations l10n) async {
    final board = notes.currentBoard;
    if (board.hasWallImage) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.changePhoto),
                onTap: () => Navigator.pop(context, 'change'),
              ),
              ListTile(
                leading: const Icon(Icons.hide_image_outlined),
                title: Text(l10n.removePhoto),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ],
          ),
        ),
      );
      if (action == null) return;
      if (action == 'remove') {
        notes.setCurrentBoardWall(board.wallIndex);
        return;
      }
    }
    final picked = await ImageService().pickWallImage();
    if (picked == null) return;
    final (stored, dark) = picked;
    notes.setCurrentBoardWallImage(stored, dark: dark);
  }

  Future<void> _importFlow(BuildContext context, AppLocalizations l10n) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _ImportDialog(l10n: l10n),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final backup = BackupService().decode(text);
      notes.replaceAll(backup.boards, backup.notes);
      messenger.showSnackBar(SnackBar(content: Text(l10n.importSuccess)));
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed)));
    }
  }
}

class _WallTile extends StatelessWidget {
  const _WallTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.ink : Colors.black26,
                width: selected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  if (selected)
                    const Center(
                      child: Icon(Icons.check_circle,
                          color: Colors.white, size: 26),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ink,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

/// The last wall tile: the board's own photo when it has one, otherwise an
/// invitation to pick one.
class _PhotoWallTile extends StatelessWidget {
  const _PhotoWallTile({
    required this.board,
    required this.l10n,
    required this.onTap,
  });

  final Board board;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WallTile(
      label: l10n.customWall,
      selected: board.hasWallImage,
      onTap: onTap,
      child: board.hasWallImage
          ? Image.file(
              File(ImageService.resolveWall(board.wallImage)),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
            )
          : const _PhotoPlaceholder(),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.ink.withValues(alpha: 0.10),
            AppColors.ink.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.add_photo_alternate_outlined,
            color: AppColors.ink, size: 30),
      ),
    );
  }
}

class _HourField extends StatelessWidget {
  const _HourField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            for (var h = 0; h < 24; h++)
              DropdownMenuItem(value: h, child: Text(hourLabel(h))),
          ],
          onChanged: (h) {
            if (h != null) onChanged(h);
          },
        ),
      ),
    );
  }
}

/// A font choice rendered the way it will actually look: on a small sticky
/// note, slightly askew, with the preview line as handwriting.
class _FontPaper extends StatelessWidget {
  const _FontPaper({
    required this.font,
    required this.preview,
    required this.selected,
    required this.tilt,
    required this.onTap,
  });

  final FontChoice font;
  final String preview;
  final bool selected;
  final double tilt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paper = paperColorOf(context, null, font.id);
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: selected ? 0 : tilt,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 150,
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
          decoration: BoxDecoration(
            color: paper,
            border: selected
                ? Border.all(color: AppColors.ink, width: 2.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.28 : 0.18),
                blurRadius: selected ? 10 : 6,
                offset: Offset(0, selected ? 5 : 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(font.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: font.family,
                          fontSize: 18 * font.scale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: font.family,
                          fontSize: 15 * font.scale,
                          height: 1.25,
                          color: AppColors.inkSoft)),
                ],
              ),
              // A little pin so it reads as a note, not a card.
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.pin : Colors.black38,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black38,
                            blurRadius: 3,
                            offset: Offset(0, 1.5)),
                      ],
                    ),
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.check_circle,
                      color: AppColors.ink, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns its controller so it is disposed with the dialog, not while the
/// field is still animating off screen.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.importData),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.importReplaceWarning,
              style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 6,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.importHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.importData),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 16,
              color: AppColors.ink,
              fontWeight: FontWeight.bold)),
    );
  }
}

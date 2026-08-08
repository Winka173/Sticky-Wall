import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/backup_service.dart';
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

Future<void> showSettingsSheet(
  BuildContext context, {
  required SettingsController settings,
  required NotesController notes,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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
    final primary = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
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
              itemCount: walls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final wall = walls[index];
                final selected = index == notes.currentBoard.wallIndex;
                return GestureDetector(
                  onTap: () => notes.setCurrentBoardWall(index),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? primary : Colors.black26,
                            width: selected ? 3 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(wall.asset, fit: BoxFit.cover),
                              ColoredBox(color: wall.overlay),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(wallLabel(l10n, wall.id),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.ink)),
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
          _SectionTitle(l10n.fontSection),
          RadioGroup<String>(
            groupValue: settings.font.id,
            onChanged: (id) {
              if (id != null) settings.setFontId(id);
            },
            child: Column(
              children: [
                for (final font in fontChoices)
                  RadioListTile<String>(
                    value: font.id,
                    contentPadding: EdgeInsets.zero,
                    title: Text(font.label,
                        style: TextStyle(
                            fontFamily: font.family,
                            fontSize: 18 * font.scale,
                            color: AppColors.ink)),
                    subtitle: Text(l10n.fontPreview,
                        style: TextStyle(
                            fontFamily: font.family,
                            fontSize: 15 * font.scale,
                            color: const Color(0x993B372F))),
                  ),
              ],
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

  Future<void> _importFlow(BuildContext context, AppLocalizations l10n) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importData),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.importReplaceWarning,
                style: const TextStyle(fontSize: 14, color: Color(0x99000000))),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
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
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.importData),
          ),
        ],
      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold)),
    );
  }
}

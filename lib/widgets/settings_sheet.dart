import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
  BuildContext context,
  SettingsController settings,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: settings,
      builder: (context, _) => _SettingsSheet(settings: settings),
    ),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                l10n.customize,
                style: const TextStyle(fontSize: 22, color: AppColors.ink),
              ),
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
                  final selected = index == settings.wallIndex;
                  return GestureDetector(
                    onTap: () => settings.setWallIndex(index),
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? primary : Colors.black26,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
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
                        Text(
                          wallLabel(l10n, wall.id),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
                      title: Text(
                        font.label,
                        style: TextStyle(
                          fontFamily: font.family,
                          fontSize: 18 * font.scale,
                          color: AppColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        l10n.fontPreview,
                        style: TextStyle(
                          fontFamily: font.family,
                          fontSize: 15 * font.scale,
                          color: const Color(0x993B372F),
                        ),
                      ),
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
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// A short tour of what fingers can do on the wall, as a bottom sheet:
/// offered once on a fresh install (the first time the wall is shown) and
/// always available from the more menu.
Future<void> showGestureTips(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _GestureTipsSheet(),
  );
}

class _GestureTipsSheet extends StatelessWidget {
  const _GestureTipsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tips = [
      (Icons.open_with, l10n.tipDragTitle, l10n.tipDragBody),
      (Icons.push_pin_outlined, l10n.tipPinTitle, l10n.tipPinBody),
      (Icons.zoom_out_map, l10n.tipWallTitle, l10n.tipWallBody),
      (Icons.move_to_inbox_outlined, l10n.tipDropTitle, l10n.tipDropBody),
      (Icons.checklist_rtl, l10n.tipSelectTitle, l10n.tipSelectBody),
      (Icons.gesture, l10n.tipDrawTitle, l10n.tipDrawBody),
      (Icons.undo, l10n.tipUndoTitle, l10n.tipUndoBody),
    ];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
              child: Text(
                l10n.gestureTips,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                itemCount: tips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final (icon, title, body) = tips[i];
                  return _TipRow(icon: icon, title: title, body: body);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.chalk,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.gotIt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.fromLTRB(4, 4, 14, 0),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppColors.ink),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

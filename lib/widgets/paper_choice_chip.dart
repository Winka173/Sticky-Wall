import 'package:flutter/material.dart';

import '../theme.dart';

/// Icon and text choices on bare paper, with a quiet outline when selected.
class PaperChoiceChip extends StatelessWidget {
  const PaperChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.inkSoft;
    final text = Text(
      label,
      style: TextStyle(
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
    final style = TextButton.styleFrom(
      foregroundColor: color,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: selected
            ? AppColors.ink.withValues(alpha: .65)
            : Colors.transparent,
        width: 1.4,
      ),
      minimumSize: const Size(48, AppMetrics.target),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
    return Semantics(
      selected: selected,
      child: Tooltip(
        message: label,
        child: icon == null
            ? TextButton(onPressed: onSelected, style: style, child: text)
            : TextButton.icon(
                onPressed: onSelected,
                style: style,
                icon: Icon(icon, size: 23, color: color),
                label: text,
              ),
      ),
    );
  }
}

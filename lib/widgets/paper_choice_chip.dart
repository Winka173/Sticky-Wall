import 'package:flutter/material.dart';

import '../theme.dart';

/// Icon and text choices without a persistent background or border.
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
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        decoration: selected ? TextDecoration.underline : null,
      ),
    );
    final style = TextButton.styleFrom(
      foregroundColor: color,
      backgroundColor: Colors.transparent,
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

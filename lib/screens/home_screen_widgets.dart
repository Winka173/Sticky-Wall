part of 'home_screen.dart';

/// One icon-over-label button in the selection bar.
class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  /// The icon-over-label look, for other controls that sit in the bar.
  static Widget face({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = onTap == null ? color.withValues(alpha: 0.35) : color;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: face(icon: icon, label: label, color: c),
      ),
    );
  }
}

/// The spoken name of yarn colour [i] (see [AppColors.yarns]).
String _yarnName(AppLocalizations l10n, int i) => switch (i) {
  0 => l10n.swatchRed,
  1 => l10n.swatchOrange,
  2 => l10n.swatchGold,
  3 => l10n.swatchGreen,
  4 => l10n.swatchBlue,
  5 => l10n.swatchPurple,
  _ => l10n.swatchInk,
};

/// The spoken name of marker colour [i] (see [AppColors.markers]).
String _markerName(AppLocalizations l10n, int i) => switch (i) {
  0 => l10n.swatchInk,
  1 => l10n.swatchRed,
  2 => l10n.swatchBlue,
  3 => l10n.swatchGreen,
  _ => l10n.swatchChalk,
};

/// A colour choice in a sheet (paper colours, yarn colours).
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.color,
    required this.onTap,
    this.auto = false,
    this.selected = false,
  });

  final String name;
  final Color color;
  final VoidCallback onTap;
  final bool auto;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return KeyboardTappable(
      onActivate: onTap,
      circle: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: name,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: AppColors.ink, width: 3)
                  : Border.all(color: Colors.black26),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
            child: auto
                ? const Icon(Icons.auto_awesome, size: 20, color: AppColors.ink)
                : null,
          ),
        ),
      ),
    );
  }
}

/// The sheet a tapped thread opens: yarn colour, a label to hang on it, an
/// arrowhead, and the scissors. Changes apply as they are made.
class _ThreadSheet extends StatefulWidget {
  const _ThreadSheet({
    required this.link,
    required this.notes,
    required this.onCut,
  });

  final NoteLink link;
  final NotesController notes;
  final void Function(NoteLink link) onCut;

  @override
  State<_ThreadSheet> createState() => _ThreadSheetState();
}

class _ThreadSheetState extends State<_ThreadSheet> {
  late NoteLink _link = widget.link;
  late final _label = TextEditingController(text: widget.link.label);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _apply(NoteLink next) {
    setState(() => _link = next);
    widget.notes.updateLink(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.thread,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.yarnColor,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, c) in AppColors.yarns.indexed)
                  _Swatch(
                    name: _yarnName(AppLocalizations.of(context)!, i),
                    color: Color(c),
                    selected: (_link.color ?? AppColors.yarns.first) == c,
                    onTap: () => _apply(_link.copyWith(color: c)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              maxLength: 24,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.threadLabelHint,
                prefixIcon: const Icon(Icons.sell_outlined),
                counterText: '',
                isDense: true,
              ),
              onChanged: (v) => _apply(_link.copyWith(label: v.trim())),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.arrow_right_alt),
              title: Text(l10n.threadArrow),
              value: _link.arrow,
              onChanged: (v) => _apply(_link.copyWith(arrow: v)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(
                  Icons.content_cut,
                  color: AppColors.deleteIcon,
                ),
                label: Text(
                  l10n.cutThread,
                  style: const TextStyle(color: AppColors.deleteIcon),
                ),
                onPressed: () => widget.onCut(_link),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One marker colour in the drawing bar.
class _InkDot extends StatelessWidget {
  const _InkDot({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The dot stays small; the transparent box around it is the target.
    return KeyboardTappable(
      onActivate: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: name,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 30,
            height: 44,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: selected ? 28 : 22,
              height: selected ? 28 : 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : Colors.black26,
                  width: selected ? 3 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed outline in the shape of a sticky note.
class _GhostNotePainter extends CustomPainter {
  _GhostNotePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1.5),
          const Radius.circular(8),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 8, metric.length)),
          paint,
        );
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_GhostNotePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The surface of controls that float over the notes — the tool pill, the
/// marker and selection bars: a near-opaque chip, clipped to its shape.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.decoration,
    required this.child,
    this.padding,
    this.height,
  });

  final BoxDecoration decoration;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: decoration.borderRadius ?? BorderRadius.zero,
      child: Container(
        height: height,
        padding: padding,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

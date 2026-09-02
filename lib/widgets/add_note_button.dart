import 'package:flutter/material.dart';

import '../theme.dart';
import 'note_views.dart';

/// The "new note" action: a small blank sticky note, pinned and slightly
/// askew like the ones on the wall, with a pencil on it. Replaces the stock
/// round "+" so the primary action reads as part of the board rather than
/// a foreign Material control.
///
/// [extended] shows the label next to the pencil (used on an empty wall and
/// in grid/list modes); collapsed it is a compact square that covers less of
/// the notes behind it.
class AddNoteButton extends StatelessWidget {
  const AddNoteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.extended = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool extended;

  /// Same slight tilt the wall gives its notes.
  static const _tilt = -0.045;

  @override
  Widget build(BuildContext context) {
    // A brighter yellow than the note papers so it stands out as the one
    // action; at night it dims along with everything else on the wall.
    final paper = isNight(context)
        ? Color.lerp(AppColors.accent, const Color(0xFF7A6A4A), 0.22)!
        : AppColors.accent;

    final note = Transform.rotate(
      angle: _tilt,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(
            painter: _PaperPainter(color: paper),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onPressed,
                splashColor: AppColors.ink.withValues(alpha: 0.12),
                highlightColor: AppColors.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadii.paper),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      extended ? 18 : 16,
                      14,
                      extended ? 20 : 16,
                      14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined,
                            size: 26, color: AppColors.ink),
                        if (extended) ...[
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 17 * noteFontScale(context),
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Pinned through the top edge, like every note on the wall.
          const Positioned(
            top: -6,
            child: IgnorePointer(child: NotePin(pinned: false)),
          ),
        ],
      ),
    );
    // The visible label already names the button when extended; collapsed,
    // the tooltip supplies it (and a long-press reveals it).
    return extended ? note : Tooltip(message: label, child: note);
  }
}

/// A sheet of sticky-note paper with a soft drop shadow and a folded
/// bottom-right corner.
class _PaperPainter extends CustomPainter {
  const _PaperPainter({required this.color});

  final Color color;

  static const _fold = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // The sheet, minus the corner that curls up.
    final sheet = Path()
      ..addRRect(RRect.fromRectAndRadius(
          rect, const Radius.circular(AppRadii.paper)));
    final cut = Path()
      ..moveTo(w, h - _fold)
      ..lineTo(w, h)
      ..lineTo(w - _fold, h)
      ..close();
    final shape = Path.combine(PathOperation.difference, sheet, cut);

    canvas.drawPath(
      shape.shift(const Offset(2, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.10)!,
            color,
          ],
        ).createShader(rect),
    );

    // The curled corner: a darker triangle folded back over the sheet.
    final fold = Path()
      ..moveTo(w, h - _fold)
      ..lineTo(w - _fold, h)
      ..lineTo(w - _fold, h - _fold)
      ..close();
    canvas.drawPath(
      fold.shift(const Offset(-1, -1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(
      fold,
      Paint()..color = Color.lerp(color, AppColors.ink, 0.22)!,
    );
  }

  @override
  bool shouldRepaint(_PaperPainter old) => old.color != color;
}

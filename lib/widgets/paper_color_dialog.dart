import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Mixes a paper colour of one's own (Sticky Wall Pro): a hue, how strong
/// it is, and how light. Lightness never drops below what keeps ink easy to
/// read, so any mix still makes a usable sticky note. Returns the colour as
/// a note stores it (see [customPaper]), or null when cancelled.
Future<int?> showPaperColorDialog(BuildContext context, {Color? initial}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _PaperColorDialog(initial: initial),
  );
}

/// Mixes a pen colour for drawing on the wall (Sticky Wall Pro): any hue,
/// strength and lightness, previewed as a line on [wall]. Returns the ARGB
/// value, or null when cancelled.
Future<int?> showInkColorDialog(
  BuildContext context, {
  required Color wall,
  Color? initial,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _PaperColorDialog(initial: initial, inkOn: wall),
  );
}

class _PaperColorDialog extends StatefulWidget {
  const _PaperColorDialog({this.initial, this.inkOn});

  final Color? initial;

  /// Mixing a pen colour, shown on this wall colour; null for paper.
  final Color? inkOn;

  @override
  State<_PaperColorDialog> createState() => _PaperColorDialogState();
}

class _PaperColorDialogState extends State<_PaperColorDialog> {
  late HSLColor _hsl = _start();

  bool get _ink => widget.inkOn != null;

  // Paper stays light enough for ink to read on it; a pen may be anything.
  double get _minSat => _ink ? 0 : 0.15;
  double get _maxSat => _ink ? 1 : 0.9;
  double get _minLight => _ink ? 0.05 : 0.72;
  double get _maxLight => _ink ? 0.95 : 0.94;

  HSLColor _start() {
    final initial = widget.initial;
    if (initial == null) {
      return _ink
          ? const HSLColor.fromAHSL(1, 200, 0.8, 0.45)
          : const HSLColor.fromAHSL(1, 160, 0.55, 0.84);
    }
    final hsl = HSLColor.fromColor(initial);
    return hsl
        .withSaturation(hsl.saturation.clamp(_minSat, _maxSat))
        .withLightness(hsl.lightness.clamp(_minLight, _maxLight));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _hsl.toColor();
    return AlertDialog(
      title: Text(_ink ? l10n.inkCustomTitle : l10n.paperCustomTitle),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_ink)
              // A line in the colour, on the wall it will be drawn on.
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: widget.inkOn,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: CustomPaint(painter: _InkSample(color)),
              )
            else
              // A sheet in the colour, with a line of writing on it.
              Container(
                height: 96,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isNight(context) ? nightPaper(color) : color,
                  borderRadius: BorderRadius.circular(AppRadii.paper),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(1, 3),
                    ),
                  ],
                ),
                child: Text(l10n.fontPreview, style: noteBodyStyle(context)),
              ),
            const SizedBox(height: 12),
            _slider(
              label: l10n.paperCustomHue,
              value: _hsl.hue,
              max: 359,
              track: [
                for (var h = 0; h <= 360; h += 60)
                  HSLColor.fromAHSL(1, h.toDouble(), 0.7, 0.75).toColor(),
              ],
              onChanged: (v) => setState(() => _hsl = _hsl.withHue(v)),
            ),
            _slider(
              label: l10n.paperCustomStrength,
              value: _hsl.saturation,
              min: _minSat,
              max: _maxSat,
              onChanged: (v) => setState(() => _hsl = _hsl.withSaturation(v)),
            ),
            _slider(
              label: l10n.paperCustomLightness,
              value: _hsl.lightness,
              min: _minLight,
              max: _maxLight,
              onChanged: (v) => setState(() => _hsl = _hsl.withLightness(v)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ink ? color.toARGB32() : customPaper(color),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0,
    required double max,
    List<Color>? track,
  }) {
    final slider = Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      label: label,
      onChanged: onChanged,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
        ),
        if (track == null)
          slider
        else
          // The hue slider runs over the rainbow it picks from.
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 24,
                right: 24,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: track),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                ),
                child: slider,
              ),
            ],
          ),
      ],
    );
  }
}

/// A loose hand-drawn wave, to show a pen colour.
class _InkSample extends CustomPainter {
  _InkSample(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(size.width * 0.12, size.height * 0.6);
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.95,
      size.width * 0.88,
      size.height * 0.35,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_InkSample old) => old.color != color;
}

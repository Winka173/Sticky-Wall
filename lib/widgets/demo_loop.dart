import 'package:flutter/material.dart';

import '../theme.dart';

/// Plays a drawing that runs on `t` from 0 to 1, like a short silent clip:
/// [times] plays, each followed by a [hold] on the last frame, then it rests
/// on that frame with a replay button. With reduced motion only the last
/// frame shows, so t = 1 must explain the thing by itself.
class DemoLoop extends StatefulWidget {
  const DemoLoop({
    super.key,
    required this.label,
    required this.replayLabel,
    required this.builder,
    this.period = const Duration(milliseconds: 3600),
    this.hold = const Duration(milliseconds: 1100),
    this.times = 2,
  });

  /// Read aloud in place of the drawing.
  final String label;

  /// The replay button's tooltip.
  final String replayLabel;
  final Widget Function(BuildContext context, double t) builder;
  final Duration period, hold;
  final int times;

  /// The drawing's t at [elapsed] into the plays (pure, for tests).
  static double at(Duration elapsed, Duration period, Duration hold) {
    final whole = period + hold;
    final e = elapsed.inMicroseconds % whole.inMicroseconds;
    return (e / period.inMicroseconds).clamp(0.0, 1.0);
  }

  @override
  State<DemoLoop> createState() => _DemoLoopState();
}

class _DemoLoopState extends State<DemoLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _done = false;

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _c.stop();
    } else if (!_c.isAnimating && !_done) {
      _play();
    }
  }

  void _play() {
    _c.duration = (widget.period + widget.hold) * widget.times;
    setState(() => _done = false);
    _c.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && _c.value == 1) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = _still;
    return Semantics(
      image: true,
      label: widget.label,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => widget.builder(
                  context,
                  still || _done || _c.duration == null
                      ? 1
                      : DemoLoop.at(
                          _c.duration! * _c.value,
                          widget.period,
                          widget.hold,
                        ),
                ),
              ),
            ),
          ),
          if (_done && !still)
            PositionedDirectional(
              end: 6,
              bottom: 6,
              child: IconButton.filledTonal(
                key: const Key('demo-replay'),
                tooltip: widget.replayLabel,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.paper.withValues(alpha: .92),
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.replay, size: 20),
                onPressed: _play,
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Peels a rendered note off the wall: a snapshot of it lifts by one corner,
/// curls, and drifts down out of view. The real widget can be removed as soon
/// as [play] returns (the overlay stays until the animation ends).
///
/// Best-effort: if the boundary can't be rasterized (already gone, tests)
/// nothing is shown and the future completes at once.
abstract final class PeelAway {
  static const duration = Duration(milliseconds: 460);

  static Future<void> play(BuildContext context, GlobalKey key) async {
    final box = key.currentContext?.findRenderObject();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (box is! RenderRepaintBoundary || !box.attached || overlay == null) {
      return;
    }
    final ui.Image image;
    try {
      image = await box.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } catch (_) {
      return;
    }
    if (!box.attached || !overlay.mounted) {
      image.dispose();
      return;
    }
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PeelSnapshot(
        image: image,
        rect: rect,
        onDone: () {
          entry.remove();
          image.dispose();
        },
      ),
    );
    overlay.insert(entry);
  }
}

/// Plays the peel animation on a captured image of the note in an overlay,
/// then removes itself.
class _PeelSnapshot extends StatefulWidget {
  const _PeelSnapshot({
    required this.image,
    required this.rect,
    required this.onDone,
  });

  final ui.Image image;
  final Rect rect;
  final VoidCallback onDone;

  @override
  State<_PeelSnapshot> createState() => _PeelSnapshotState();
}

class _PeelSnapshotState extends State<_PeelSnapshot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: PeelAway.duration)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rect = widget.rect;
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInCubic.transform(_c.value);
            final lift = Curves.easeOut.transform(_c.value);
            // Lift from the bottom-right corner first, then let the whole
            // sheet tumble down and away.
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..translateByDouble(24 * t, rect.height * 0.9 * t, 0, 1)
              ..rotateX(-0.9 * lift)
              ..rotateZ(0.35 * t);
            return Opacity(
              opacity: (1 - math.pow(t, 1.6)).clamp(0.0, 1.0).toDouble(),
              child: Transform(
                transform: m,
                alignment: Alignment.topLeft,
                child: RawImage(
                  image: widget.image,
                  width: rect.width,
                  height: rect.height,
                  fit: BoxFit.fill,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

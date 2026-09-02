import 'dart:io';

import 'package:flutter/material.dart';

import '../models/board.dart';
import '../services/image_service.dart';
import '../theme.dart';
import 'wall_decor.dart';
import 'wall_view.dart' show WallCamera;

/// The wall a board shows right now: its bundled texture or its own photo,
/// switched to chalk-on-dark when the lights are off.
WallStyle wallFor(Board board, {required bool night}) {
  final wall = board.hasWallImage
      ? WallStyle.photo(ImageService.resolveWall(board.wallImage),
          dark: board.wallImageDark)
      : walls[board.wallIndex % walls.length];
  return night ? wall.atNight : wall;
}

/// The wall texture (or photo) + scrim + stains + vignette. Kept outside the
/// Scaffold so wall switches can crossfade without touching app content.
///
/// Given a [camera], the texture and stains follow the wall's pan and zoom
/// (the notes are pinned to the wall, so the wall has to move with them),
/// while the scrim, vignette and lamp light stay put like a real room's. The
/// widget is assumed to fill the screen from its top-left corner, which is
/// the coordinate space the camera reports its origin in.
///
/// With the lights off a dark veil drops over everything and a single warm
/// lamp glows from the top, so the wall recedes and the paper stands out.
class WallBackground extends StatelessWidget {
  const WallBackground({
    super.key,
    required this.wall,
    required this.decor,
    this.camera,
  });

  final WallStyle wall;
  final bool decor;
  final WallCamera? camera;

  /// How far the movable layer extends past every screen edge: the wall's
  /// pan boundary (320) at its smallest zoom (0.6), plus the header above the
  /// wall viewport at that zoom, rounded up generously. Off-screen paint is
  /// clipped away, so the extra costs nothing.
  static const double _bleed = 900;

  static const _fallbackTexture = 3; // plaster

  @override
  Widget build(BuildContext context) {
    final night = isNight(context);
    final camera = this.camera;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        Widget surface = _Surface(wall: wall, decor: decor, screen: size);
        if (camera != null) {
          surface = ClipRect(
            child: ListenableBuilder(
              listenable: camera,
              builder: (context, child) => Transform(
                transform: camera.matrix,
                origin: camera.origin,
                child: child,
              ),
              child: OverflowBox(
                minWidth: size.width + 2 * _bleed,
                maxWidth: size.width + 2 * _bleed,
                minHeight: size.height + 2 * _bleed,
                maxHeight: size.height + 2 * _bleed,
                child: surface,
              ),
            ),
          );
        }
        return ColoredBox(
          color: const Color(0xFF6B5849),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(child: surface),
              ColoredBox(color: wall.overlay),
              // Soft vignette adds depth so the wall recedes at the edges.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.15,
                      colors: [Colors.transparent, Color(0x33000000)],
                      stops: [0.62, 1.0],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: night ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -1.1),
                        radius: 1.5,
                        colors: [
                          Color(0x66201810),
                          Color(0xA6120E0A),
                          Color(0xCC0A0806),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The physical wall itself: texture or photo, plus stains. Sized by its
/// parent — the whole screen, or a much larger sheet when it has to be
/// dragged around behind the notes.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.wall,
    required this.decor,
    required this.screen,
  });

  final WallStyle wall;
  final bool decor;

  /// The screen's size; a photo wall keeps covering exactly this much in the
  /// middle of the sheet, whatever size the sheet is.
  final Size screen;

  @override
  Widget build(BuildContext context) {
    final file = wall.imageFile;
    if (file == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(wall.asset),
            repeat: ImageRepeat.repeat,
            scale: 2.2,
          ),
        ),
        // Stains belong to a wall, not to somebody's holiday photo.
        child: decor ? WallDecor(wall: wall) : null,
      );
    }
    final photo = File(file);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Past the photo's edges the wall carries on as a dim, blown-up echo
        // of it, so panning never runs into a hard border.
        Image.file(
          photo,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          color: const Color(0xA6000000),
          colorBlendMode: BlendMode.darken,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        Center(
          child: SizedBox.fromSize(
            size: screen,
            child: Image.file(
              photo,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // A missing file (restored backup on another device) falls
              // back to plain plaster rather than an error box.
              errorBuilder: (_, _, _) => Image.asset(
                walls[WallBackground._fallbackTexture].asset,
                repeat: ImageRepeat.repeat,
                scale: 2.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

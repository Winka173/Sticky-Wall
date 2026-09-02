import 'dart:io';

import 'package:flutter/material.dart';

import '../models/board.dart';
import '../services/image_service.dart';
import '../theme.dart';
import 'wall_decor.dart';

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
/// With the lights off a dark veil drops over everything and a single warm
/// lamp glows from the top, so the wall recedes and the paper stands out.
class WallBackground extends StatelessWidget {
  const WallBackground({
    super.key,
    required this.wall,
    required this.decor,
  });

  final WallStyle wall;
  final bool decor;

  @override
  Widget build(BuildContext context) {
    final night = isNight(context);
    final file = wall.imageFile;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B5849),
        image: file == null
            ? DecorationImage(
                image: AssetImage(wall.asset),
                repeat: ImageRepeat.repeat,
                scale: 2.2,
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (file != null)
            Image.file(
              File(file),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // A missing file (restored backup on another device) falls
              // back to plain plaster rather than an error box.
              errorBuilder: (_, _, _) => Image.asset(
                walls[3].asset,
                repeat: ImageRepeat.repeat,
                scale: 2.2,
              ),
            ),
          ColoredBox(color: wall.overlay),
          // Stains belong to a wall, not to somebody's holiday photo.
          if (decor && file == null) WallDecor(wall: wall),
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
  }
}

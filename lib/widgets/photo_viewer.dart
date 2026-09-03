import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/image_service.dart';

/// Opens a note's photo full screen: pinch to zoom, double-tap to toggle,
/// tap to close. [path] is a stored reference (see `ImageService.resolve`).
Future<void> showPhotoViewer(BuildContext context, String path) {
  if (path.isEmpty) return Future.value();
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => PhotoViewer(path: path),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  ));
}

/// The full-screen viewer itself; see [showPhotoViewer].
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.path});

  final String path;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  final _tc = TransformationController();

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _toggleZoom(TapDownDetails d) {
    if (_tc.value.getMaxScaleOnAxis() > 1.02) {
      _tc.value = Matrix4.identity();
      return;
    }
    // Zoom 2.5× around the tapped point.
    const s = 2.5;
    final p = d.localPosition;
    _tc.value = Matrix4.identity()
      ..translateByDouble(p.dx * (1 - s), p.dy * (1 - s), 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            // A tap on the photo (not a pinch or drag) closes the viewer.
            onTap: () => Navigator.of(context).maybePop(),
            onDoubleTapDown: _toggleZoom,
            // Needed so onDoubleTapDown fires (the recognizer wants a handler).
            onDoubleTap: () {},
            child: InteractiveViewer(
              transformationController: _tc,
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.file(
                  File(ImageService.resolve(widget.path)),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image,
                      size: 64, color: Colors.white54),
                ),
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              tooltip: l10n.cancel,
              color: Colors.white,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

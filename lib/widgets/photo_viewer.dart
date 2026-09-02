import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/image_service.dart';

/// Opens a note's photos full screen: swipe between them, pinch to zoom.
/// [images] are stored references (see `ImageService.resolve`).
Future<void> showPhotoViewer(
  BuildContext context,
  List<String> images, {
  int initial = 0,
}) {
  if (images.isEmpty) return Future.value();
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => PhotoViewer(
      images: images,
      initial: initial.clamp(0, images.length - 1),
    ),
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

/// The full-screen pager itself; see [showPhotoViewer].
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.images, this.initial = 0});

  final List<String> images;
  final int initial;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  // While a photo is zoomed in, horizontal drags pan it instead of flipping
  // to the next one.
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final many = widget.images.length > 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.images.length,
            itemBuilder: (context, i) => _ZoomablePhoto(
              path: widget.images[i],
              onZoomChanged: (z) {
                if (z != _zoomed) setState(() => _zoomed = z);
              },
              // A tap on the photo (not a pinch or drag) closes the viewer.
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          // Close button and "2 / 5" counter over the top edge.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.cancel,
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (many)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.images.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One page of the viewer: the photo, pinch-zoomable, double-tap to toggle.
class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    required this.path,
    required this.onZoomChanged,
    required this.onTap,
  });

  final String path;
  final ValueChanged<bool> onZoomChanged;
  final VoidCallback onTap;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _tc = TransformationController();

  @override
  void initState() {
    super.initState();
    _tc.addListener(_report);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _report() =>
      widget.onZoomChanged(_tc.value.getMaxScaleOnAxis() > 1.02);

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
    return GestureDetector(
      onTap: widget.onTap,
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
    );
  }
}

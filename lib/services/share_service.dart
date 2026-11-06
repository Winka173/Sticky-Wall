import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Something another app handed to us through the system share sheet, boiled
/// down to what a note can hold.
class SharedContent {
  const SharedContent({
    this.text = '',
    this.url = '',
    this.imagePaths = const [],
  });

  /// Plain text (or the text that came along with a link).
  final String text;

  /// The first http(s) link found in the shared text, if any.
  final String url;

  /// Absolute paths of every shared image file, in the order sent, without
  /// repeats.
  final List<String> imagePaths;

  /// The first shared image, or empty.
  String get imagePath => imagePaths.isEmpty ? '' : imagePaths.first;

  bool get isEmpty => text.isEmpty && url.isEmpty && imagePaths.isEmpty;

  /// Identifies a payload, so the same share delivered twice (a resume, a
  /// replayed intent) is only handled once.
  String get signature => [text, url, ...imagePaths].join('\u0000');

  static final _urlPattern = RegExp(
    r'https?://[^\s<>"]+',
    caseSensitive: false,
  );

  /// Splits shared text into the first link and everything else, so
  /// "Check this out https://…" becomes a link note titled "Check this out".
  factory SharedContent.fromText(String raw) {
    final text = raw.trim();
    final match = _urlPattern.firstMatch(text);
    if (match == null) return SharedContent(text: text);
    final url = match.group(0)!.replaceAll(RegExp(r'[.,;:!?)]+$'), '');
    final rest = text.replaceFirst(match.group(0)!, ' ');
    return SharedContent(
      url: url,
      text: rest.replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
  }

  /// Builds the content of a share payload: every image (in order, no
  /// repeats), and the text and links merged.
  static SharedContent fromFiles(List<SharedMediaFile> files) {
    final images = <String>[];
    final texts = <String>[];
    for (final f in files) {
      switch (f.type) {
        case SharedMediaType.image:
          if (f.path.isNotEmpty && !images.contains(f.path)) images.add(f.path);
        case SharedMediaType.text:
        case SharedMediaType.url:
          texts.add(f.path);
        case SharedMediaType.video:
        case SharedMediaType.file:
          break;
      }
      final msg = f.message?.trim();
      if (msg != null && msg.isNotEmpty && !texts.contains(msg)) texts.add(msg);
    }
    final fromText = SharedContent.fromText(texts.join('\n'));
    return SharedContent(
      text: fromText.text,
      url: fromText.url,
      imagePaths: images,
    );
  }
}

/// Listens for content shared into the app — both the share that launched it
/// and shares that arrive while it is running — and reports each as a
/// [SharedContent]. Every platform call is guarded so a platform without the
/// plugin (tests, desktop) just never delivers anything.
class ShareReceiver {
  StreamSubscription<List<SharedMediaFile>>? _sub;

  void listen(void Function(SharedContent content) onShared) {
    if (kIsWeb) return;
    void deliver(List<SharedMediaFile> files) {
      if (files.isEmpty) return;
      final content = SharedContent.fromFiles(files);
      if (!content.isEmpty) onShared(content);
    }

    try {
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((files) {
            deliver(files);
            // Otherwise the same payload would come back after a hot restart.
            ReceiveSharingIntent.instance.reset();
          })
          .catchError((Object e) {
            debugPrint('Share intent unavailable: $e');
          });
      _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
        deliver,
        onError: (Object e) => debugPrint('Share stream error: $e'),
      );
    } catch (e) {
      debugPrint('Share intent unavailable: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

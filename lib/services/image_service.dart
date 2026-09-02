import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Photo attachments, capturing a note to a PNG, and sharing / saving it.
///
/// Photos are copied into `<documents>/note_images/` and a note stores only
/// the file *name*. The documents directory itself is not stable — iOS moves
/// the app container on every update — so absolute paths would rot; [resolve]
/// rebuilds the full path at display time instead.
class ImageService {
  final _picker = ImagePicker();

  static const _folder = 'note_images';
  static String? _docsDir;

  /// Looks up the documents directory once so [resolve] can be synchronous.
  /// Safe to call where path_provider is unavailable (tests, web).
  static Future<void> init() async {
    try {
      _docsDir = (await getApplicationDocumentsDirectory()).path;
    } catch (_) {}
  }

  @visibleForTesting
  static set docsDirForTest(String? dir) => _docsDir = dir;

  /// Absolute path for a stored photo reference. Accepts both the bare file
  /// name written by current versions and the absolute paths older versions
  /// stored (only the name is used, so those heal automatically).
  static String resolve(String stored) {
    if (stored.isEmpty) return stored;
    final dir = _docsDir;
    if (dir == null) return stored;
    final name = stored.split(RegExp(r'[\\/]')).last;
    return '$dir/$_folder/$name';
  }

  /// Picks a photo and copies it into the app's documents directory so it
  /// survives even if the original is removed. Returns the stored reference
  /// (see [resolve]), or null when the user cancelled.
  Future<String?> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1600);
    if (picked == null) return null;
    _docsDir ??= (await getApplicationDocumentsDirectory()).path;
    final images = Directory('$_docsDir/$_folder');
    if (!images.existsSync()) images.createSync(recursive: true);
    final ext = picked.path.split('.').last;
    final name = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(picked.path).copy('${images.path}/$name');
    return name;
  }

  /// Removes a photo previously copied by [pickImage]. Missing files and I/O
  /// errors are ignored — this is best-effort housekeeping.
  static Future<void> deleteFile(String stored) async {
    if (stored.isEmpty) return;
    try {
      final file = File(resolve(stored));
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Rasterizes a RepaintBoundary (a rendered note) to PNG bytes.
  static Future<Uint8List?> capture(RenderRepaintBoundary boundary,
      {double pixelRatio = 3.0}) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> sharePng(Uint8List bytes, {required String subject}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sticky-note.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: subject,
      ),
    );
  }

  /// Saves PNG bytes to the device photo gallery (handles permission).
  Future<void> saveToGallery(Uint8List bytes) async {
    await Gal.putImageBytes(bytes, album: 'Sticky Wall');
  }
}

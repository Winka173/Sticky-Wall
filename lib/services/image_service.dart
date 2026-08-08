import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Photo attachments, capturing a note to a PNG, and sharing / saving it.
class ImageService {
  final _picker = ImagePicker();

  /// Picks a photo and copies it into the app's documents directory so it
  /// survives even if the original is removed. Returns the saved path, or null.
  Future<String?> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1600);
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final images = Directory('${dir.path}/note_images');
    if (!images.existsSync()) images.createSync(recursive: true);
    final ext = picked.path.split('.').last;
    final dest = '${images.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(picked.path).copy(dest);
    return dest;
  }

  /// Rasterizes a RepaintBoundary (a rendered note) to PNG bytes.
  static Future<Uint8List?> capture(RenderRepaintBoundary boundary,
      {double pixelRatio = 3.0}) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> sharePng(Uint8List bytes, {String subject = 'Sticky note'}) async {
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

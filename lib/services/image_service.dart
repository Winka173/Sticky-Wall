import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Photo attachments, wall photos, capturing a note to a PNG, and sharing /
/// saving it.
///
/// Photos are copied into `<documents>/note_images/` (wall photos into
/// `<documents>/wall_images/`) and a note or board stores only the file
/// *name*. The documents directory itself is not stable — iOS moves the app
/// container on every update — so absolute paths would rot; [resolve] rebuilds
/// the full path at display time instead.
class ImageService {
  final _picker = ImagePicker();

  static const _folder = 'note_images';
  static const _wallFolder = 'wall_images';
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

  static String _resolveIn(String folder, String stored) {
    if (stored.isEmpty) return stored;
    final dir = _docsDir;
    if (dir == null) return stored;
    final name = stored.split(RegExp(r'[\\/]')).last;
    return '$dir/$folder/$name';
  }

  /// Absolute path for a stored photo reference. Accepts both the bare file
  /// name written by current versions and the absolute paths older versions
  /// stored (only the name is used, so those heal automatically).
  static String resolve(String stored) => _resolveIn(_folder, stored);

  /// Absolute path for a board's wall photo.
  static String resolveWall(String stored) => _resolveIn(_wallFolder, stored);

  /// Largest edge a note photo is stored at; plenty for a card and a
  /// full-screen look, without keeping 12-megapixel originals around.
  static const _maxPhotoEdge = 1600.0;

  // Makes names unique even when a batch of photos is imported within the
  // same microsecond tick.
  static int _importSeq = 0;

  /// Copies [source] into the app's own folder under a fresh name and returns
  /// that name (see [resolve]), so the file survives even if the original is
  /// removed.
  Future<String> _import(String source, {String folder = _folder}) async {
    _docsDir ??= (await getApplicationDocumentsDirectory()).path;
    final dir = Directory('$_docsDir/$folder');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final ext = source.contains('.') ? source.split('.').last : 'jpg';
    final seq = (_importSeq++ % 1000).toString().padLeft(3, '0');
    final name = '${DateTime.now().microsecondsSinceEpoch}$seq.$ext';
    await File(source).copy('${dir.path}/$name');
    return name;
  }

  /// Picks one photo for a note. Returns the stored reference, or null when
  /// the user cancelled.
  Future<String?> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: _maxPhotoEdge,
    );
    if (picked == null) return null;
    return _import(picked.path);
  }

  /// Picks any number of photos from the gallery and stores each. Returns
  /// their references in the order chosen; empty when the user cancelled.
  Future<List<String>> pickImages() async {
    final picked = await _picker.pickMultiImage(maxWidth: _maxPhotoEdge);
    return [for (final file in picked) await _import(file.path)];
  }

  /// Stores an image handed to us by another app (share sheet) as a note
  /// photo. Returns null if the file can't be read.
  Future<String?> importSharedImage(String path) async {
    try {
      if (!await File(path).exists()) return null;
      return await _import(path);
    } catch (e) {
      debugPrint('Could not import shared image: $e');
      return null;
    }
  }

  /// Picks a photo from the gallery to use as a wall. Returns its stored
  /// reference and whether it is dark overall (so the right scrim and text
  /// color can be chosen), or null when cancelled.
  Future<(String, bool)?> pickWallImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (picked == null) return null;
    final dark = await isDarkImage(await picked.readAsBytes());
    final name = await _import(picked.path, folder: _wallFolder);
    return (name, dark);
  }

  /// Average luminance test on a tiny decode of the image — enough to tell a
  /// night sky from a beach. Assumes light when the image can't be decoded.
  static Future<bool> isDarkImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 32,
        targetHeight: 32,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData();
      frame.image.dispose();
      codec.dispose();
      if (data == null) return false;
      var sum = 0.0;
      final px = data.buffer.asUint8List();
      for (var i = 0; i + 3 < px.length; i += 4) {
        sum += 0.2126 * px[i] + 0.7152 * px[i + 1] + 0.0722 * px[i + 2];
      }
      return sum / (px.length / 4) < 128;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Removes a note photo previously copied by [pickImage] / [pickImages].
  /// Missing files and I/O errors are ignored — this is best-effort
  /// housekeeping.
  static Future<void> deleteFile(String stored) async {
    if (stored.isEmpty) return;
    await _delete(resolve(stored));
  }

  /// [deleteFile] for several photos at once.
  static Future<void> deleteFiles(Iterable<String> stored) =>
      Future.wait(stored.map(deleteFile));

  /// Removes a wall photo previously copied by [pickWallImage].
  static Future<void> deleteWallFile(String stored) async {
    if (stored.isEmpty) return;
    await _delete(resolveWall(stored));
  }

  /// Rasterizes a RepaintBoundary (a rendered note) to PNG bytes.
  static Future<Uint8List?> capture(
    RenderRepaintBoundary boundary, {
    double pixelRatio = 3.0,
  }) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  /// Wraps a PNG in a one-page PDF the size of the picture (three pixels to
  /// the point, so a 3× export prints at its logical size).
  static Future<Uint8List> pdfFromPng(
    Uint8List png, {
    bool compress = true,
  }) async {
    final decoded = await decodeImageFromList(png);
    final width = decoded.width / 3;
    final height = decoded.height / 3;
    decoded.dispose();
    final doc = pw.Document(title: 'Sticky Wall', compress: compress);
    final image = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height),
        build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
    return doc.save();
  }

  Future<void> sharePdf(Uint8List bytes, {required String subject}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sticky-wall.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: subject,
      ),
    );
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

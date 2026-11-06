import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/services/share_service.dart';

/// Several photos shared in from another app: every one is kept (not just
/// the first), within stated limits, and the rest are counted.
void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('share_photos_test');
    ImageService.docsDirForTest = '${temp.path}/docs';
  });

  tearDown(() {
    ImageService.docsDirForTest = null;
    temp.deleteSync(recursive: true);
  });

  File photo(String name, int bytes) =>
      File('${temp.path}/$name')..writeAsBytesSync(List.filled(bytes, 7));

  test('a payload keeps every image, in order, once, plus its text', () {
    final content = SharedContent.fromFiles([
      SharedMediaFile(path: '/a.jpg', type: SharedMediaType.image),
      SharedMediaFile(path: '/b.jpg', type: SharedMediaType.image),
      SharedMediaFile(path: '/a.jpg', type: SharedMediaType.image),
      SharedMediaFile(
        path: 'Holiday https://example.com/trip',
        type: SharedMediaType.text,
      ),
    ]);
    expect(content.imagePaths, ['/a.jpg', '/b.jpg']);
    expect(content.imagePath, '/a.jpg');
    expect(content.url, 'https://example.com/trip');
    expect(content.text, 'Holiday');
    expect(
      content.signature,
      SharedContent.fromFiles([
        SharedMediaFile(path: '/a.jpg', type: SharedMediaType.image),
        SharedMediaFile(path: '/b.jpg', type: SharedMediaType.image),
        SharedMediaFile(
          path: 'Holiday https://example.com/trip',
          type: SharedMediaType.text,
        ),
      ]).signature,
    );
  });

  test('every readable photo is copied in; missing, empty and oversized ones '
      'are counted', () async {
    final paths = [
      photo('1.jpg', 10).path,
      '${temp.path}/gone.jpg',
      photo('2.jpg', 0).path,
      photo('3.jpg', 20).path,
      photo('big.jpg', ImageService.maxSharedImageBytes + 1).path,
      photo('4.jpg', 30).path,
    ];
    final (stored, skipped) = await ImageService().importSharedImages(paths);
    expect(stored, hasLength(3));
    expect(skipped, 3);
    final docs = Directory('${temp.path}/docs');
    final copies = docs
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.lengthSync())
        .toList();
    expect(copies..sort(), [10, 20, 30]);
  });

  test('a share brings at most 20 photos; the rest are counted', () async {
    final paths = [for (var i = 0; i < 23; i++) photo('$i.jpg', 5).path];
    final (stored, skipped) = await ImageService().importSharedImages(paths);
    expect(stored, hasLength(ImageService.maxSharedImages));
    expect(skipped, 3);
  });
}

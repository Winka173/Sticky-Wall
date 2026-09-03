import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/services/image_service.dart';

void main() {
  testWidgets('a PNG becomes a one-page PDF the size of the picture', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 60, 30),
        ui.Paint()..color = const ui.Color(0xFFCC3333),
      );
      final image = await recorder.endRecording().toImage(60, 30);
      final Uint8List png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      final pdf = await ImageService.pdfFromPng(png, compress: false);
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      // 60×30 px at three pixels to the point: a 20×10 pt page.
      final box = RegExp(
        r'/MediaBox\s*\[([^\]]*)\]',
      ).firstMatch(latin1.decode(pdf, allowInvalid: true));
      expect(box, isNotNull, reason: 'page box in the file');
      final numbers = box!
          .group(1)!
          .trim()
          .split(RegExp(r'\s+'))
          .map(double.parse)
          .toList();
      expect(numbers, [0, 0, 20, 10]);
    });
  });
}

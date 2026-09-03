import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/services/image_service.dart';

void main() {
  testWidgets('cropPng keeps just the asked-for part', (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 40, 20),
        ui.Paint()..color = const ui.Color(0xFF2222CC),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(40, 0, 40, 20),
        ui.Paint()..color = const ui.Color(0xFFCC2222),
      );
      final image = await recorder.endRecording().toImage(80, 20);
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      // The right half only: 40×20, all red.
      final cropped = await ImageService.cropPng(
        png,
        const ui.Rect.fromLTWH(0.5, 0, 0.5, 1),
      );
      final out = await decodeImageFromList(cropped);
      expect(out.width, 40);
      expect(out.height, 20);
      final pixels = (await out.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      expect(
        pixels.getUint8(0),
        0xCC,
        reason: 'red channel of the first pixel',
      );
      expect(pixels.getUint8(2), 0x22, reason: 'blue channel');
    });
  });

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

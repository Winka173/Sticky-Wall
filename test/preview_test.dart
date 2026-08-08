import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/theme.dart';

Future<void> _loadRealFonts() async {
  final patrick = FontLoader('PatrickHand')
    ..addFont(rootBundle.load('assets/fonts/PatrickHand-Regular.ttf'));
  await patrick.load();
  final pacifico = FontLoader('Pacifico')
    ..addFont(rootBundle.load('assets/fonts/Pacifico-Regular.ttf'));
  await pacifico.load();
}

final _sampleNotes = [
  Note(guid: 'a1', content: 'Mua sữa và trứng gà cho bữa sáng'),
  Note(guid: 'b2', content: 'Tài liệu Flutter', url: 'https://docs.flutter.dev'),
  Note(guid: 'c3', content: 'Học tiếng Anh 30 phút mỗi ngày'),
  Note(guid: 'd4', content: 'Nhớ gọi điện hỏi thăm mẹ'),
  Note(guid: 'e5', content: 'Bảng màu Material', url: 'https://m3.material.io'),
  Note(guid: 'f6', content: 'Đặt lịch khám răng thứ Năm tuần sau'),
];

void main() {
  for (var i = 0; i < walls.length; i++) {
    testWidgets('preview wall ${walls[i].id}',
        // Screenshot generator, not a regression test: golden rendering
        // differs between platforms. Run on demand with:
        //   flutter test --update-goldens test/preview_test.dart
        // then copy the PNGs from test/ into screenshots/.
        skip: true, (tester) async {
      await _loadRealFonts();
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveNotes(_sampleNotes);
      await storage.setGridView(true);
      await storage.setWallIndex(i);

      tester.view.physicalSize = const Size(1170, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(StickyWallApp(storage: storage));

      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold));
        for (final wall in walls) {
          await precacheImage(AssetImage(wall.asset), context);
        }
      });
      await tester.pump();

      await expectLater(
        find.byType(StickyWallApp),
        matchesGoldenFile('preview_${walls[i].id}.png'),
      );
    });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/pro_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/eraser_icon.dart';

/// Drawing on the wall: an eraser that looks like one, and (with Pro) any
/// pen colour at all, mixed.
void main() {
  Future<void> pump(WidgetTester tester, {required bool pro}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveNotes([]);
    await storage.setViewMode(ViewMode.wall);
    final proC = ProController(storage);
    if (pro) proC.unlockForTesting();
    await tester.pumpWidget(
      StickyWallApp(
        settings: SettingsController(storage),
        notes: NotesController(storage, ReminderService()),
        pro: proC,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pen'));
    await tester.pumpAndSettle();
  }

  testWidgets('the eraser is drawn as an eraser and toggles', (tester) async {
    await pump(tester, pro: false);
    expect(find.byType(EraserIcon), findsOneWidget);
    await tester.tap(find.byTooltip('Eraser'));
    await tester.pump();
    expect(tester.widget<EraserIcon>(find.byType(EraserIcon)).filled, isTrue);
  });

  testWidgets('without Pro the mixed colour is locked and offers Pro', (
    tester,
  ) async {
    await pump(tester, pro: false);
    final dot = find.bySemanticsLabel(RegExp('Any color'));
    expect(dot, findsOneWidget);
    await tester.ensureVisible(dot);
    await tester.tap(dot);
    await tester.pumpAndSettle();
    expect(find.text('Mix a pen color'), findsNothing);
    expect(find.text('Sticky Wall Pro'), findsWidgets);
  });

  testWidgets('with Pro any colour can be mixed for the pen', (tester) async {
    await pump(tester, pro: true);
    final dot = find.bySemanticsLabel('Any color');
    await tester.ensureVisible(dot);
    await tester.tap(dot);
    await tester.pumpAndSettle();
    expect(find.text('Mix a pen color'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Mix a pen color'), findsNothing);
  });
}

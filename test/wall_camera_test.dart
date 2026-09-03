import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/screens/home_screen.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/wall_background.dart';
import 'package:sticky_wall/widgets/wall_view.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

Future<(StickyWallApp, NotesController)> _app(ViewMode mode) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveNotes([
    Note(guid: 'a', content: 'one', createdAt: _epoch, boardId: 'default'),
  ]);
  await storage.setViewMode(mode);
  final notes = NotesController(storage, ReminderService());
  return (
    StickyWallApp(settings: SettingsController(storage), notes: notes),
    notes,
  );
}

/// The transform the background applies to the wall texture, if any.
Transform? _backgroundTransform(WidgetTester tester) {
  final found = find.descendant(
    of: find.byType(WallBackground),
    matching: find.byType(Transform),
  );
  return found.evaluate().isEmpty ? null : tester.widget<Transform>(found);
}

void main() {
  testWidgets('panning the wall moves the background with it', (tester) async {
    final (app, _) = await _app(ViewMode.wall);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // At rest the texture sits where it always did.
    final before = _backgroundTransform(tester);
    expect(before, isNotNull);
    expect(before!.transform.isIdentity(), isTrue);

    // The camera knows where the wall viewport starts (the wall fills the
    // body; the header floats over its top band).
    final wallBox = tester.renderObject<RenderBox>(find.byType(WallView));
    final wallOrigin = wallBox.localToGlobal(Offset.zero);
    expect(before.origin, wallOrigin);

    // Drag empty wall (a corner, away from the note): the InteractiveViewer
    // pans.
    final wallRect = tester.getRect(find.byType(InteractiveViewer));
    await tester.dragFrom(
      wallRect.bottomLeft + const Offset(40, -60),
      const Offset(-60, -40),
    );
    await tester.pumpAndSettle();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    // The controller holds the content's shift as well (the pad, less the
    // header band); the background gets the camera relative to the resting
    // view.
    final wallMatrix = viewer.transformationController!.value.multiplied(
      Matrix4.translationValues(
        WallView.pad,
        WallView.pad - HomeScreen.wallHeaderHeight,
        0,
      ),
    );
    expect(wallMatrix.isIdentity(), isFalse);
    expect(_backgroundTransform(tester)!.transform, wallMatrix);
  });

  testWidgets('grid and list leave the background still', (tester) async {
    final (app, notes) = await _app(ViewMode.wall);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final wallRect = tester.getRect(find.byType(InteractiveViewer));
    await tester.dragFrom(
      wallRect.bottomLeft + const Offset(40, -60),
      const Offset(-60, -40),
    );
    await tester.pumpAndSettle();
    expect(_backgroundTransform(tester)!.transform.isIdentity(), isFalse);

    notes.viewMode = ViewMode.grid;
    await tester.pumpAndSettle();
    expect(_backgroundTransform(tester), isNull);

    // Back on the wall the leftover zoom glides away rather than sticking.
    notes.viewMode = ViewMode.wall;
    await tester.pumpAndSettle();
    expect(_backgroundTransform(tester)!.transform.isIdentity(), isTrue);
    expect(tester.takeException(), isNull);
  });
}

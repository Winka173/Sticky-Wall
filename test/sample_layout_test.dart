import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/screens/home_screen.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/sample_notes.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/note_views.dart';

/// A fresh install is the first thing anyone sees, so the samples have to
/// look arranged on every screen — not stretched to the corners of a tablet
/// with a hole in the middle, and never stacked on top of each other. They
/// are placed in real distances for that reason; these are the sizes where
/// the whole arrangement fits and so must not overlap.
final _sizes = <String, (Size, double)>{
  'phone': (const Size(1080, 2220), 2.75),
  'tablet portrait': (const Size(1600, 2560), 2),
  'tablet landscape': (const Size(2560, 1600), 2),
};

void main() {
  for (final MapEntry(key: name, value: (size, dpr)) in _sizes.entries) {
    testWidgets('the sample notes sit apart and in view on a $name', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      final notes = NotesController(storage, ReminderService());
      final sample = SampleNotes.build(
        await AppLocalizations.delegate.load(const Locale('en')),
        notes.currentBoardId,
        wall: HomeScreen.wallSizeFor(tester.view),
      );
      notes.seed(sample.notes, links: sample.links);
      notes.viewMode = ViewMode.wall;
      await tester.pumpWidget(
        StickyWallApp(settings: SettingsController(storage), notes: notes),
      );
      await tester.pumpAndSettle();

      final cards = find.byType(NoteTurn);
      expect(cards, findsNWidgets(sample.notes.length));
      final rects = [
        for (var i = 0; i < sample.notes.length; i++)
          tester.getRect(cards.at(i)),
      ];
      final screen = Offset.zero & tester.view.physicalSize / dpr;

      for (var i = 0; i < rects.length; i++) {
        final r = rects[i];
        expect(r.left, greaterThan(-1), reason: 'card $i off the left');
        expect(
          r.right,
          lessThan(screen.right + 1),
          reason: 'card $i too far right',
        );
        expect(
          r.top,
          greaterThan(HomeScreen.wallHeaderHeight - 1),
          reason: 'card $i under the header',
        );
        expect(
          r.bottom,
          lessThan(screen.bottom),
          reason: 'card $i off the foot',
        );
        for (var j = i + 1; j < rects.length; j++) {
          // Deflated a hair: cards may just touch, they may not pile up.
          expect(
            r.deflate(2).overlaps(rects[j].deflate(2)),
            isFalse,
            reason: 'cards $i and $j overlap',
          );
        }
      }
    });
  }

  test('the layout stays on the wall even on a tiny one', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final wall in [
      null,
      const Size(320, 200), // a phone on its side, header and pill taken off
      const Size(4000, 3000), // a desktop window
      Size.zero,
    ]) {
      final sample = SampleNotes.build(l10n, 'default', wall: wall);
      for (final note in sample.notes) {
        expect(note.x, inInclusiveRange(0, 1), reason: 'x on wall $wall');
        expect(note.y, inInclusiveRange(0, 1), reason: 'y on wall $wall');
      }
      // Distinct spots, whatever the wall: nothing collapses into a pile.
      final spots = {for (final n in sample.notes) '${n.x},${n.y}'};
      expect(spots.length, sample.notes.length, reason: 'wall $wall');
    }
  });
}

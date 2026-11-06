import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/screens/gallery_screen.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/template_library.dart';
import 'package:sticky_wall/welcome/guide_motion.dart';
import 'package:sticky_wall/welcome/how_to_use.dart';
import 'package:sticky_wall/welcome/welcome_guide.dart';

/// The first-run guide: shown once on a fresh install (never to someone
/// who already has a wall), Skip and finish remembered, three stages with
/// Back, a practice that saves nothing, and the three ways to start. Also
/// Settings → Help → How to use: the guide again and the manual's topics.

class _App {
  _App(this.storage, this.notes);
  final NoteStorage storage;
  final NotesController notes;
}

Future<_App> _pump(
  WidgetTester tester, {
  bool firstRun = true,
  Size size = const Size(390, 844),
  double text = 1,
  String? language,
  bool seed = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (text != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  if (seed) {
    SharedPreferences.setMockInitialValues({});
  }
  final storage = await NoteStorage.create();
  if (seed) {
    // On a fresh install the wall holds the first-run examples.
    await storage.saveNotes([
      Note(
        guid: 'a',
        content: 'Sample one',
        createdAt: DateTime(2026),
        boardId: 'default',
        sample: firstRun,
        x: .1,
        y: .1,
      ),
      Note(
        guid: 'b',
        content: 'Sample two',
        createdAt: DateTime(2026),
        boardId: 'default',
        sample: firstRun,
        x: .6,
        y: .5,
      ),
    ]);
    await storage.saveLinks([const NoteLink('a', 'b')]);
    await storage.setViewMode(ViewMode.wall);
    if (language != null) await storage.setLanguageCode(language);
    if (firstRun) {
      await storage.setWelcomePending(true);
      await storage.setTipsPending(true);
    }
  }
  final notes = NotesController(storage, ReminderService());
  await tester.pumpWidget(
    StickyWallApp(settings: SettingsController(storage), notes: notes),
  );
  await tester.pumpAndSettle();
  return _App(storage, notes);
}

/// Everything the guide must leave alone, as text.
String _snapshot(NotesController notes) => [
  for (final n in notes.allNotes) n.toJson().toString(),
  for (final l in notes.links) '${l.a}-${l.b}',
  notes.boards.length,
].join('|');

/// A title, by the label it gives a screen reader.
Finder _label(String text) =>
    find.byWidgetPredicate((w) => w is Semantics && w.properties.label == text);

Future<void> _primary(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('guide-primary')));
  await tester.tap(find.byKey(const Key('guide-primary')));
  await tester.pumpAndSettle();
}

/// Story beats → practice, with its Next fallback → the last stage.
Future<void> _toChoices(WidgetTester tester) async {
  await _primary(tester);
  await _primary(tester);
  for (var i = 0; i < 3; i++) {
    await tester.tap(find.byKey(const Key('guide-practice-next')));
    await tester.pumpAndSettle();
  }
  await _primary(tester);
}

/// Scrolls the page on top until [target] is built and on screen.
Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .descendant(
          of: find.byType(Scaffold).last,
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

/// More → Settings → How to use, in the app's [language].
Future<void> _openHowToUse(
  WidgetTester tester, {
  String language = 'en',
}) async {
  final l10n = lookupAppLocalizations(Locale(language));
  await tester.tap(find.byTooltip(l10n.moreActions));
  await tester.pumpAndSettle();
  // With large text the menu scrolls.
  await tester.ensureVisible(find.text(l10n.settingsTitle));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.settingsTitle));
  await tester.pumpAndSettle();
  await _reveal(tester, find.text(l10n.howToUse));
  await tester.tap(find.text(l10n.howToUse));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a first run opens the guide; Skip is remembered and keeps '
      'the sample wall', (tester) async {
    final app = await _pump(tester);
    final before = _snapshot(app.notes);
    expect(find.byType(WelcomeGuide), findsOneWidget);
    expect(_label('Step 1 of 3'), findsOneWidget);
    expect(_label('Notes everywhere. Found nowhere.'), findsOneWidget);
    expect(find.byKey(const Key('guide-back')), findsNothing);

    await tester.tap(find.byKey(const Key('guide-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeGuide), findsNothing);
    expect(app.storage.welcomePending, isFalse);
    expect(app.storage.tipsPending, isFalse, reason: 'the guide covers them');
    expect(_snapshot(app.notes), before, reason: 'Skip keeps the samples');

    // The next start does not show it again.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, seed: false);
    expect(find.byType(WelcomeGuide), findsNothing);
  });

  testWidgets('someone who already has a wall never sees it', (tester) async {
    await _pump(tester, firstRun: false);
    expect(find.byType(WelcomeGuide), findsNothing);
    expect(find.text('Sample one'), findsOneWidget);
  });

  testWidgets('three stages with Back; the practice saves nothing; '
      'Explore keeps the samples', (tester) async {
    final app = await _pump(tester);
    final before = _snapshot(app.notes);

    // 1a → 1b: the same stage.
    await _primary(tester);
    expect(_label('One wall for all of it.'), findsOneWidget);
    expect(_label('Step 1 of 3'), findsOneWidget);

    // 2: the practice, gesture by gesture.
    await _primary(tester);
    expect(_label('Step 2 of 3'), findsOneWidget);
    expect(find.text('Tap the yellow paper'), findsOneWidget);
    expect(find.text('Water the plants'), findsNothing);
    await tester.tap(find.byKey(const Key('guide-practice-add')));
    await tester.pumpAndSettle();
    expect(find.text('Water the plants'), findsOneWidget);
    expect(find.text('Drag the note onto the dashed spot'), findsOneWidget);

    final note = find.byKey(const Key('guide-practice-note'));
    final from = tester.getCenter(note);
    final to = tester.getCenter(find.text('Here'));
    final drag = await tester.startGesture(from);
    // Past the slop first, then the rest of the way.
    for (var i = 1; i <= 4; i++) {
      await drag.moveTo(Offset.lerp(from, to, i / 4)!);
      await tester.pump();
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('Pull its red pin onto “Saturday”'), findsOneWidget);

    final pin =
        tester.getTopLeft(note) + Offset(tester.getSize(note).width / 2, 12);
    final pull = await tester.startGesture(pin);
    await pull.moveBy(const Offset(0, -12));
    await tester.pump();
    await pull.moveTo(tester.getCenter(find.text('Saturday')));
    await tester.pump();
    await pull.up();
    await tester.pumpAndSettle();
    expect(find.byType(GuideCheck), findsOneWidget);
    expect(_label('That’s the wall.'), findsOneWidget);
    expect(find.textContaining('nothing was saved'), findsOneWidget);
    expect(_snapshot(app.notes), before, reason: 'practice only');

    // Back: practice (afresh) → the wall beat → the scattered beat.
    await tester.tap(find.byKey(const Key('guide-back')));
    await tester.pumpAndSettle();
    expect(_label('One wall for all of it.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guide-back')));
    await tester.pumpAndSettle();
    expect(_label('Notes everywhere. Found nowhere.'), findsOneWidget);

    await _toChoices(tester);
    expect(_label('Step 3 of 3'), findsOneWidget);
    expect(_label('Make it yours.'), findsOneWidget);
    for (final c in GuideStart.values) {
      expect(find.byKey(Key('guide-choice-${c.name}')), findsOneWidget);
    }
    // Back from the last stage returns to a fresh practice.
    await tester.tap(find.byKey(const Key('guide-back')));
    await tester.pumpAndSettle();
    expect(find.text('Tap the yellow paper'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('guide-practice-next')));
      await tester.pumpAndSettle();
    }
    await _primary(tester);

    // Explore (chosen to begin with) keeps the samples.
    await _primary(tester);
    expect(find.byType(WelcomeGuide), findsNothing);
    expect(_snapshot(app.notes), before);
    expect(app.storage.welcomePending, isFalse);
  });

  testWidgets('Android back steps back, and leaves from the first beat', (
    tester,
  ) async {
    await _pump(tester);
    await _primary(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_label('Notes everywhere. Found nowhere.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeGuide), findsNothing);
  });

  testWidgets('Blank wall removes the samples', (tester) async {
    final app = await _pump(tester);
    await _toChoices(tester);
    await tester.tap(find.byKey(const Key('guide-choice-blank')));
    await tester.pumpAndSettle();
    await _primary(tester);
    expect(find.byType(WelcomeGuide), findsNothing);
    expect(app.notes.boardNotes, isEmpty);
    expect(app.notes.links, isEmpty);
    expect(app.notes.trashed, isEmpty, reason: 'examples never were theirs');
  });

  testWidgets('Pick a template opens the gallery', (tester) async {
    // The library is read once, outside the fake clock.
    await tester.runAsync(TemplateLibrary.load);
    final app = await _pump(tester);
    final before = _snapshot(app.notes);
    await _toChoices(tester);
    await tester.tap(find.byKey(const Key('guide-choice-template')));
    await tester.pumpAndSettle();
    await _primary(tester);
    expect(find.byType(GalleryScreen), findsOneWidget);
    // Backing out of the gallery keeps the samples.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_snapshot(app.notes), before);
  });

  testWidgets('moving to a new phone is taught in How to use', (tester) async {
    await _pump(tester, firstRun: false);
    await _openHowToUse(tester);
    await _reveal(tester, find.byKey(const Key('manual-topic-10')));
    await tester.tap(find.byKey(const Key('manual-topic-10')));
    await tester.pumpAndSettle();
    expect(find.text('Keeping it safe'), findsOneWidget);
    expect(
      find.textContaining('New phone: back up on the old one'),
      findsOneWidget,
    );
  });

  testWidgets('How to use: replay changes nothing, and its last stage '
      'just closes', (tester) async {
    final app = await _pump(tester, firstRun: false);
    final before = _snapshot(app.notes);
    await _openHowToUse(tester);
    expect(find.byType(HowToUsePage), findsOneWidget);

    await tester.tap(find.byKey(const Key('manual-replay')));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeGuide), findsOneWidget);
    await _toChoices(tester);
    expect(_label('Make it yours.'), findsOneWidget);
    expect(find.byKey(const Key('guide-choice-blank')), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    await _primary(tester);
    expect(find.byType(WelcomeGuide), findsNothing);
    expect(find.byType(HowToUsePage), findsOneWidget);

    // Skip from a replay closes too.
    await tester.tap(find.byKey(const Key('manual-replay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guide-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(HowToUsePage), findsOneWidget);
    expect(_snapshot(app.notes), before);
    expect(app.storage.welcomePending, isFalse);
  });

  testWidgets('How to use: a topic opens; Previous and Next walk them all', (
    tester,
  ) async {
    final app = await _pump(tester, firstRun: false);
    final before = _snapshot(app.notes);
    await _openHowToUse(tester);
    await tester.tap(find.byKey(const Key('manual-topic-1')));
    await tester.pumpAndSettle();
    expect(find.byType(ManualTopicPage), findsOneWidget);
    expect(find.text('Topic 2 of 12'), findsOneWidget);
    expect(find.text('Moving and arranging'), findsOneWidget);

    await tester.tap(find.byKey(const Key('manual-previous')));
    await tester.pumpAndSettle();
    expect(find.text('Topic 1 of 12'), findsOneWidget);
    expect(find.byKey(const Key('manual-previous')), findsNothing);

    for (var i = 2; i <= 12; i++) {
      await tester.tap(find.byKey(const Key('manual-next')));
      await tester.pumpAndSettle();
      expect(find.text('Topic $i of 12'), findsOneWidget);
    }
    expect(find.text('Make it yours'), findsOneWidget);
    await tester.tap(find.byKey(const Key('manual-next')));
    await tester.pumpAndSettle();
    expect(find.byType(ManualTopicPage), findsNothing);
    expect(find.byType(HowToUsePage), findsOneWidget);
    expect(_snapshot(app.notes), before);
  });

  group('fits', () {
    const sizes = [
      (Size(320, 640), 2.0),
      (Size(390, 844), 1.0),
      (Size(1280, 800), 1.0),
    ];
    for (final language in ['en', 'vi']) {
      for (final (size, text) in sizes) {
        final name =
            '${size.width.toInt()}x${size.height.toInt()} '
            '@${(text * 100).toInt()}% $language';
        testWidgets('every guide stage at $name', (tester) async {
          await _pump(tester, size: size, text: text, language: language);
          await _primary(tester);
          await _primary(tester);
          await tester.tap(find.byKey(const Key('guide-practice-add')));
          await tester.pumpAndSettle();
          for (var i = 0; i < 2; i++) {
            await tester.tap(find.byKey(const Key('guide-practice-next')));
            await tester.pumpAndSettle();
          }
          expect(find.byType(GuideCheck), findsOneWidget);
          await _primary(tester);
          expect(find.byKey(const Key('guide-choice-explore')), findsOneWidget);
          await tester.ensureVisible(
            find.byKey(const Key('guide-choice-template')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('guide-choice-template')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });

        if (size.width > 400) continue;
        testWidgets('every manual topic at $name', (tester) async {
          await _pump(
            tester,
            firstRun: false,
            size: size,
            text: text,
            language: language,
          );
          await _openHowToUse(tester, language: language);
          expect(tester.takeException(), isNull);
          await _reveal(tester, find.byKey(const Key('manual-topic-0')));
          await tester.tap(find.byKey(const Key('manual-topic-0')));
          await tester.pumpAndSettle();
          for (var i = 1; i < 12; i++) {
            await tester.tap(find.byKey(const Key('manual-next')));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

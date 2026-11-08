import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/demo_loop.dart';
import 'package:sticky_wall/widgets/pro_demos.dart';
import 'package:sticky_wall/widgets/pro_sheet.dart';

/// A bare app with a button that opens the Pro sheet on [focus].
Future<void> _open(
  WidgetTester tester, {
  ProPerk? focus,
  String lang = 'en',
  bool still = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAppTheme(fontChoices.first),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showProSheet(context, focus: focus),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

String _stageTitle(WidgetTester tester) => tester
    .widgetList<Text>(find.byKey(const Key('pro-stage-title')))
    .map((t) => t.data)
    .join(' | ');

void main() {
  test('a film plays, holds its last frame, then plays again', () {
    const period = Duration(seconds: 2), hold = Duration(seconds: 1);
    expect(DemoLoop.at(Duration.zero, period, hold), 0);
    expect(DemoLoop.at(const Duration(seconds: 1), period, hold), .5);
    expect(DemoLoop.at(const Duration(milliseconds: 2500), period, hold), 1);
    expect(DemoLoop.at(const Duration(seconds: 4), period, hold), .5);
  });

  testWidgets('opened from a Pro thing, it plays that part first', (
    tester,
  ) async {
    await _open(tester, focus: ProPerk.fonts);
    expect(find.text('Sticky Wall Pro'), findsOneWidget);
    expect(_stageTitle(tester), '5 more handwriting fonts');
    // The pitch is for people who came to look at Pro, not for a tap.
    expect(find.textContaining('One payment'), findsNothing);
  });

  testWidgets('a part in the list plays on the stage', (tester) async {
    await _open(tester);
    expect(find.textContaining('One payment'), findsOneWidget);
    expect(_stageTitle(tester), '23 more theme packs');
    final row = find.byKey(const Key('pro-part-privateBoards'));
    await tester.scrollUntilVisible(row, 200);
    await tester.tap(row);
    await tester.pump(const Duration(milliseconds: 600));
    // The words cross-fade from the frame after the tap.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(_stageTitle(tester), 'Private boards');
    // The stage came back into view.
    expect(
      tester.getTopLeft(find.byKey(const Key('pro-stage'))).dy,
      lessThan(400),
    );
  });

  testWidgets('after two plays the film rests with a replay button', (
    tester,
  ) async {
    await _open(tester, focus: ProPerk.pins);
    expect(find.byKey(const Key('demo-replay')), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(const Key('demo-replay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('demo-replay')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('demo-replay')), findsNothing);
  });

  testWidgets('with less motion only the last frame shows', (tester) async {
    await _open(tester, focus: ProPerk.walls, still: true);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(const Key('demo-replay')), findsNothing);
    // The stage still names the part for a screen reader.
    expect(
      find.descendant(
        of: find.byKey(const Key('pro-stage')),
        matching: find.bySemanticsLabel(RegExp('^5 more walls')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Free and Pro are counted from the catalogues', (tester) async {
    await _open(tester);
    final table = find.byKey(const Key('pro-compare'));
    await tester.scrollUntilVisible(table, 300);
    for (final text in [
      '21, and your own photo',
      '+ 5, and 5 for the holidays',
      '+ 6, and any color you mix',
      'Yarn in 7 colors',
      '+ 4 styles, 4 colors',
      '+ Private boards',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('every film draws at every moment, in both languages', (
    tester,
  ) async {
    for (final lang in ['en', 'vi']) {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(fontChoices.first),
          home: Scaffold(
            // Not a ListView: every film is built, not only those in view.
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (final perk in ProPerk.values)
                    for (final t in [0.0, .37, .73, 1.0])
                      SizedBox(
                        width: 320,
                        height: 180,
                        child: Builder(
                          builder: (context) => proDemo(context, perk, t),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: lang);
    }
  });
}

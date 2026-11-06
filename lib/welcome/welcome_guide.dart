import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/keyboard_tappable.dart';
import 'guide_motion.dart';
import 'practice_wall.dart';
import 'story_scene.dart';

/// How a first run chose to start, from the guide's last stage.
enum GuideStart {
  /// The sample notes go: an empty wall.
  blank,

  /// The template gallery opens; a template used takes the samples' place.
  template,

  /// The sample wall stays as it is.
  explore,
}

/// The guide's three stages: the story (one stage, two beats), the practice
/// on a pretend wall, and how to start.
enum _Stage { story, practice, choose }

/// The first-run guide, a full page in three short stages:
///
/// 1. the story: notes scattered on scraps of paper, then the same scraps
///    pinned to one wall, as sticky notes tied by a thread;
/// 2. a practice wall, at real size on a phone: add a note, move it, tie it
///    to another one. Its notes are made on the spot and never saved;
/// 3. how to start: a blank wall, a template, or the sample wall.
///
/// Back and Skip are on every stage, and Android back steps back. It asks
/// for no permission, purchase, sign-in or sync. With [replay] (from
/// Settings) the last stage offers no choices and the guide changes
/// nothing at all. Closes with the [GuideStart] picked, or null (skipped).
class WelcomeGuide extends StatefulWidget {
  const WelcomeGuide({super.key, this.replay = false});

  final bool replay;

  /// Opens the guide over everything, with a fade.
  static Future<GuideStart?> open(BuildContext context, {bool replay = false}) {
    final time = guideMoves(context)
        ? const Duration(milliseconds: 320)
        : Duration.zero;
    return Navigator.of(context).push<GuideStart>(
      PageRouteBuilder<GuideStart>(
        transitionDuration: time,
        reverseTransitionDuration: time,
        pageBuilder: (_, _, _) => WelcomeGuide(replay: replay),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<WelcomeGuide> createState() => _WelcomeGuideState();
}

class _WelcomeGuideState extends State<WelcomeGuide>
    with SingleTickerProviderStateMixin {
  int _at = 0;

  /// The story's second beat: the scraps are on the wall.
  bool _gathered = false;

  /// The practice is done (the check has popped).
  bool _practiced = false;

  /// Bumped to start the practice afresh when it is entered again.
  int _practiceRun = 0;
  GuideStart _choice = GuideStart.explore;
  bool _leaving = false;
  final _focus = FocusNode(debugLabel: 'welcome guide');

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  _Stage get _stage => _Stage.values[_at];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_clock.value == 0 && !_clock.isAnimating) _play();
  }

  /// Plays the stage's entrance from the start (at rest without motion).
  void _play() {
    guideMoves(context) ? _clock.forward(from: 0) : _clock.value = 1;
  }

  @override
  void dispose() {
    _clock.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _go(int next) {
    setState(() {
      // Back into the story lands on its second beat.
      _gathered = next < _at || _gathered;
      _at = next;
      if (_stage == _Stage.practice) {
        _practiced = false;
        _practiceRun++;
      }
    });
    _play();
  }

  void _gather() {
    setState(() => _gathered = true);
    _play();
  }

  void _leave(GuideStart? start) {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pop(start);
  }

  void _back() {
    if (_stage == _Stage.story && _gathered) {
      setState(() => _gathered = false);
      _play();
    } else if (_at == 0) {
      _leave(null);
    } else {
      _go(_at - 1);
    }
  }

  void _practiceStep(PracticeStep step) {
    if (step != PracticeStep.done) return;
    setState(() => _practiced = true);
    _play();
  }

  @override
  Widget build(BuildContext context) {
    final page = _page(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        // Esc steps back; Enter presses the stage's button, unless another
        // control has the focus (then Enter is that control's).
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _back();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              node.hasPrimaryFocus &&
              page.primary != null) {
            page.onPrimary();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GuideBeat(
          clock: _clock,
          child: Scaffold(
            backgroundColor: guideGround(context),
            body: LayoutBuilder(
              builder: (context, box) {
                if (box.maxWidth >= 700) return SafeArea(child: _wide(page));
                return switch (_stage) {
                  _Stage.practice => _full(page),
                  _Stage.choose when !widget.replay => SafeArea(
                    child: _chooseNarrow(page),
                  ),
                  _ => SafeArea(child: _narrow(page)),
                };
              },
            ),
          ),
        ),
      ),
    );
  }

  _Page _page(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_stage) {
      _Stage.story when !_gathered => _Page(
        before: '${l10n.guideScatterTop}\n',
        words: l10n.guideScatterKey,
        body: l10n.guideScatterBody,
        primary: l10n.guideScatterAction,
        onPrimary: _gather,
      ),
      _Stage.story => _Page(
        before: l10n.guideWallBefore,
        words: l10n.guideWallKey,
        after: '.',
        body: l10n.guideWallBody,
        primary: l10n.guideWallAction,
        onPrimary: () => _go(1),
      ),
      _Stage.practice when _practiced => _Page(
        before: l10n.guidePracticeDoneBefore,
        words: l10n.guidePracticeDoneKey,
        after: '.',
        body: l10n.guidePracticeDoneBody,
        primary: l10n.guideNext,
        onPrimary: () => _go(2),
        check: true,
      ),
      _Stage.practice => _Page(
        before: l10n.guidePracticeBefore,
        words: l10n.guidePracticeKey,
        after: '.',
        body: l10n.guidePracticeBody,
        primary: null,
        onPrimary: () {},
      ),
      _Stage.choose => _Page(
        before: l10n.guideChooseBefore,
        words: l10n.guideChooseKey,
        after: '.',
        body: widget.replay ? l10n.guideChooseReplayBody : l10n.guideChooseBody,
        primary: widget.replay ? l10n.guideDone : l10n.guideStart,
        onPrimary: () => _leave(widget.replay ? null : _choice),
      ),
    };
  }

  /// The stage's picture. [top] and [bottom]: room to leave on a phone's
  /// full-screen practice for the bar and the system's own.
  Widget _scene({double top = 16, double bottom = 0}) => switch (_stage) {
    _Stage.practice => PracticeWall(
      key: ValueKey('practice-$_practiceRun'),
      top: top,
      bottom: bottom,
      onStep: _practiceStep,
    ),
    _ => StoryScene(
      key: const ValueKey('story'),
      gathered: _gathered || _stage == _Stage.choose,
    ),
  };

  Widget _bar({bool light = false}) {
    final l10n = AppLocalizations.of(context)!;
    final ink = light ? AppColors.chalk : AppColors.ink;
    final total = _Stage.values.length;
    final first = _at == 0 && !_gathered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          SizedBox(
            width: AppMetrics.target,
            child: first
                ? null
                : IconButton(
                    key: const Key('guide-back'),
                    tooltip: l10n.guideBack,
                    color: ink,
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back),
                  ),
          ),
          Expanded(
            child: Semantics(
              container: true,
              label: l10n.guideStepOf(_at + 1, total),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: AnimatedContainer(
                          duration: AppMetrics.motion(
                            context,
                            milliseconds: 360,
                          ),
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= _at
                                ? AppColors.accent
                                : light
                                ? const Color(0x59FDFBF3)
                                : AppColors.outline,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: const Key('guide-skip'),
            style: TextButton.styleFrom(
              foregroundColor: ink,
              textStyle: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => _leave(null),
            child: Text(l10n.guideSkip),
          ),
        ],
      ),
    );
  }

  /// The stage's title and its one line; on the finished practice, the
  /// check pops above them.
  Widget _words(_Page p, {required bool wide, bool center = false}) {
    final l10n = AppLocalizations.of(context)!;
    final align = center ? TextAlign.center : TextAlign.start;
    final title = TextStyle(
      fontSize: guideTitleSize(context, wide: wide),
      height: 1.1,
      color: AppColors.ink,
    );
    return AnimatedSwitcher(
      duration: AppMetrics.motion(context, milliseconds: 240),
      child: Column(
        key: ValueKey('words-$_at-$_gathered-$_practiced'),
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p.check) ...[
            GuideCheck(label: l10n.guideNothingSaved),
            const SizedBox(height: 4),
          ],
          GuideReveal(
            to: .35,
            // Titles are large already: they grow with the reader's text
            // size up to 150 %, the words under them all the way.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.5,
              child: GuideTitle(
                before: p.before,
                words: p.words,
                after: p.after,
                style: title,
                textAlign: align,
              ),
            ),
          ),
          SizedBox(height: wide ? 16 : 10),
          GuideReveal(
            from: .12,
            to: .5,
            child: Text(
              p.body,
              textAlign: align,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: wide ? 18 : 16,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primary(_Page p, {required bool wide}) {
    final label = p.primary;
    if (label == null) return const SizedBox.shrink();
    return GuideReveal(
      from: .6,
      to: .95,
      rise: 10,
      scale: .96,
      child: FilledButton(
        key: const Key('guide-primary'),
        style: FilledButton.styleFrom(
          minimumSize: Size(wide ? 260 : double.infinity, 56),
          textStyle: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control * 1.5),
          ),
        ),
        onPressed: p.onPrimary,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  /// The three ways to start, as large choices.
  Widget _choices() {
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      (
        GuideStart.blank,
        Icons.crop_square,
        AppColors.notePapers[11],
        l10n.welcomeBlank,
        l10n.welcomeBlankHint,
      ),
      (
        GuideStart.template,
        Icons.dashboard_customize_outlined,
        AppColors.notePapers[2],
        l10n.welcomeTemplate,
        l10n.welcomeTemplateHint,
      ),
      (
        GuideStart.explore,
        Icons.travel_explore_outlined,
        AppColors.notePapers[0],
        l10n.welcomeExplore,
        l10n.welcomeExploreHint,
      ),
    ];
    return GuideReveal(
      from: .2,
      to: .6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (start, icon, paper, title, hint) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Choice(
                key: Key('guide-choice-${start.name}'),
                icon: icon,
                paper: paper,
                title: title,
                hint: hint,
                selected: _choice == start,
                onTap: () => setState(() => _choice = start),
              ),
            ),
        ],
      ),
    );
  }

  /// On a phone, the practice: the wall fills the screen at real size,
  /// the bar floats on top, and once it is done the words come up in a
  /// panel from below.
  Widget _full(_Page p) {
    final pad = MediaQuery.paddingOf(context);
    const barHeight = 56.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: const Color(0xFF6B5849),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Text in the practice keeps to a size its wall can hold.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.5,
              child: _scene(top: pad.top + barHeight, bottom: pad.bottom),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pad.top + barHeight + 24,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: pad.top,
              left: pad.left,
              right: pad.right,
              child: _bar(light: true),
            ),
            if (_practiced)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GuideReveal(
                  to: .3,
                  rise: 80,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .62,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: guideGround(context),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 30,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20 + pad.left,
                          16,
                          20 + pad.right,
                          16 + pad.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _words(p, wide: false, center: true),
                            const SizedBox(height: 18),
                            _primary(p, wide: false),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// On a phone, the story's two beats (and the replay's last stage): a
  /// short title and one line at the top, the picture as large as the
  /// screen allows, the button at the foot. With little height or large
  /// text the words and the picture scroll between the bar and the button.
  Widget _narrow(_Page p) => LayoutBuilder(
    builder: (context, box) {
      final words = Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: _words(p, wide: false, center: true),
      );
      Widget scene(double? height) => SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: _scene(),
        ),
      );
      final actions = Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: _primary(p, wide: false),
      );
      final roomy =
          box.maxHeight >= 600 &&
          MediaQuery.textScalerOf(context).scale(16) <= 16 * 1.3;
      if (roomy) {
        return Column(
          children: [
            _bar(),
            words,
            Expanded(child: scene(null)),
            actions,
          ],
        );
      }
      // The bar and the button stay put; the words and the picture scroll.
      return Column(
        children: [
          _bar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  words,
                  scene((box.maxHeight * .52).clamp(220.0, 560.0)),
                ],
              ),
            ),
          ),
          actions,
        ],
      );
    },
  );

  /// On a phone, the last stage of a first run: the words, the three
  /// choices (scrolling if need be) and Start at the foot.
  Widget _chooseNarrow(_Page p) => Column(
    children: [
      _bar(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _words(p, wide: false, center: true),
              const SizedBox(height: 20),
              _choices(),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: _primary(p, wide: false),
      ),
    ],
  );

  /// Tablets and wide windows: words and button on the left, the picture
  /// (or the practice wall, or the choices) on the right.
  Widget _wide(_Page p) {
    final right = switch (_stage) {
      _Stage.practice => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: _scene(),
        ),
      ),
      _Stage.choose when !widget.replay => Center(
        child: SingleChildScrollView(child: _choices()),
      ),
      _ => _scene(),
    };
    return Column(
      children: [
        _bar(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _words(p, wide: true),
                              const SizedBox(height: 32),
                              _primary(p, wide: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(flex: 6, child: right),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Page {
  const _Page({
    required this.before,
    required this.words,
    this.after = '',
    required this.body,
    required this.primary,
    required this.onPrimary,
    this.check = false,
  });

  final String before;
  final String words;
  final String after;
  final String body;

  /// The button's words; null while the stage has no button yet (the
  /// practice, until it is done).
  final String? primary;
  final VoidCallback onPrimary;

  /// The finished practice: a check pops above the title.
  final bool check;
}

/// One way to start: a large card with a paper-coloured icon, a title and
/// a line, outlined in ink and ticked while chosen.
class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.icon,
    required this.paper,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color paper;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final night = isNight(context);
    final card = night ? nightPaper(AppColors.chalk) : AppColors.chalk;
    // With very large text the words need the whole width.
    final roomy = MediaQuery.textScalerOf(context).scale(10) <= 15;
    final radius = BorderRadius.circular(AppRadii.control * 1.5);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title. $hint',
      excludeSemantics: true,
      child: KeyboardTappable(
        onActivate: onTap,
        borderRadius: radius,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMetrics.motion(context),
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppColors.ink : AppColors.outline,
                width: selected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(
                    alpha: selected ? .18 : .08,
                  ),
                  blurRadius: selected ? 14 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (roomy) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: night ? nightPaper(paper) : paper,
                      borderRadius: BorderRadius.circular(AppRadii.paper),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Icon(icon, size: 26, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 21 * noteFontScale(context),
                          height: 1.15,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: AppMetrics.motion(context),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    key: ValueKey(selected),
                    size: 26,
                    color: selected ? AppColors.ink : AppColors.inkHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

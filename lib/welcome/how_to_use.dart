import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'guide_motion.dart';
import 'manual_screens.dart';
import 'welcome_guide.dart';

/// One short topic of the manual: a title, a line saying what it is about,
/// and two to four steps, each shown on a little phone (where to tap, what
/// opens).
class ManualTopic {
  const ManualTopic({
    required this.icon,
    required this.title,
    required this.summary,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final String summary;
  final List<(String words, ManualShow show)> steps;
}

/// Built with Google Drive sync (`--dart-define=STICKY_SYNC=true`).
const _syncBuild = bool.fromEnvironment('STICKY_SYNC');

typedef _B = ManualBeat;
typedef _L = ManualLayer;
typedef _T = ManualTarget;
typedef _S = ManualSpot;

// The places a finger goes most.
const _add = _S(_T.add);
const _more = _S(_T.more);
const _noteB = _S(_T.noteB);
const _noteA = _S(_T.noteA);

// More → Settings → a line of Settings.
const _toSettings = [
  _B.tap(_more, then: _L.more),
  _B.tap(_S.item(8), then: _L.settings),
];

/// The manual's topics, in reading order.
List<ManualTopic> manualTopics(AppLocalizations l10n) => [
  ManualTopic(
    icon: Icons.note_add_outlined,
    title: l10n.manualFirstTitle,
    summary: l10n.manualFirstSummary,
    steps: [
      (l10n.manualFirstStep1, const ManualShow([_B.tap(_add, then: _L.add)])),
      (
        l10n.manualFirstStep2,
        const ManualShow([
          _B.tap(_add, then: _L.add),
          _B.tap(_S.row(1), then: _L.editor),
        ]),
      ),
      (
        l10n.manualFirstStep3,
        const ManualShow([
          _B.tap(_S(_T.editorSave), then: _L.home),
          _B.tap(_noteB, then: _L.editor),
          _B.tap(_S(_T.editorSave), then: _L.home),
          _B.hold(_noteB, then: _L.note),
        ], start: _L.editor),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.open_with,
    title: l10n.manualMoveTitle,
    summary: l10n.manualMoveSummary,
    steps: [
      (
        l10n.manualMoveStep1,
        const ManualShow([_B.drag(_noteB, _S(_T.wallLow))]),
      ),
      (
        l10n.manualMoveStep2,
        const ManualShow([
          _B.tap(_noteB),
          _B.drag(_S(_T.gripB), _S(_T.wallLow), carry: ManualCarry.resize),
        ]),
      ),
      (
        l10n.manualMoveStep3,
        const ManualShow([
          _B.pinch(_S(_T.wall)),
          _B.tap(_more, then: _L.more),
          _B.tap(_S.item(3), then: _L.home),
        ]),
      ),
      (
        l10n.manualMoveStep4,
        const ManualShow([
          _B.drag(_noteB, _S(_T.wallLow), then: _L.undo),
          _B.tap(_S(_T.undo), then: _L.home),
        ]),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.timeline,
    title: l10n.manualThreadTitle,
    summary: l10n.manualThreadSummary,
    steps: [
      (
        l10n.manualThreadStep1,
        const ManualShow([
          _B.drag(_S(_T.pinB), _noteA, carry: ManualCarry.yarn),
        ]),
      ),
      (
        l10n.manualThreadStep2,
        const ManualShow([
          _B.tap(_S(_T.threadMid), then: _L.thread),
        ], tied: true),
      ),
      (
        l10n.manualThreadStep3,
        const ManualShow([_B.tap(_S(_T.pinB))], tied: true),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.checklist,
    title: l10n.manualKindsTitle,
    summary: l10n.manualKindsSummary,
    steps: [
      (
        l10n.manualKindsStep1,
        const ManualShow([_B.tap(_add, then: _L.add), _B.tap(_S.item(1))]),
      ),
      (
        l10n.manualKindsStep2,
        const ManualShow([
          _B.tap(_add, then: _L.add),
          _B.tap(_S.row(4), then: _L.voice),
          _B.hold(_S(_T.mic)),
        ]),
      ),
      (
        l10n.manualKindsStep3,
        const ManualShow([
          _B.tap(_noteB, then: _L.editor),
          _B.tap(_S.row(1), then: _L.reminder),
          _B.tap(_S.item(2), then: _L.editor),
        ]),
      ),
      (
        l10n.manualKindsStep4,
        const ManualShow([
          _B.hold(_noteB, then: _L.note),
          _B.tap(_S.item(2), then: _L.home),
        ]),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.gesture,
    title: l10n.manualDrawTitle,
    summary: l10n.manualDrawSummary,
    steps: [
      (
        l10n.manualDrawStep1,
        const ManualShow([_B.tap(_S(_T.pen), then: _L.pen)]),
      ),
      (
        l10n.manualDrawStep2,
        const ManualShow([
          _B.drag(_S(_T.wall), _S(_T.wallLow), carry: ManualCarry.stroke),
        ], start: _L.pen),
      ),
      (
        l10n.manualDrawStep3,
        const ManualShow(
          [
            _B.tap(_S.row(2)),
            _B.tap(_S.row(3)),
            _B.tap(_S.row(4), then: _L.home),
          ],
          start: _L.pen,
          stroke: true,
        ),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.dashboard_outlined,
    title: l10n.manualBoardsTitle,
    summary: l10n.manualBoardsSummary,
    steps: [
      (
        l10n.manualBoardsStep1,
        const ManualShow([
          _B.tap(_S(_T.tabPlus), then: _L.newBoard),
          _B.tap(_S.item(1)),
        ]),
      ),
      (
        l10n.manualBoardsStep2,
        const ManualShow([_B.drag(_noteB, _S(_T.tabWork))]),
      ),
      (
        l10n.manualBoardsStep3,
        const ManualShow([_B.tap(_more, then: _L.more), _B.tap(_S.item(6))]),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.dashboard_customize_outlined,
    title: l10n.manualLooksTitle,
    summary: l10n.manualLooksSummary,
    steps: [
      (
        l10n.manualLooksStep1,
        const ManualShow([_B.tap(_more, then: _L.more), _B.tap(_S.item(0))]),
      ),
      (
        l10n.manualLooksStep2,
        const ManualShow([
          _B.tap(_S(_T.tabOpen), then: _L.board),
          _B.tap(_S.item(3)),
        ]),
      ),
      (
        l10n.manualLooksStep3,
        const ManualShow([
          _B.tap(_S(_T.tabOpen), then: _L.board),
          _B.tap(_S.item(2)),
        ]),
      ),
      (
        l10n.manualLooksStep4,
        const ManualShow([
          _B.tap(_S(_T.tabOpen), then: _L.board),
          _B.tap(_S.item(4)),
        ]),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.photo_library_outlined,
    title: l10n.manualPhotosTitle,
    summary: l10n.manualPhotosSummary,
    steps: [
      (
        l10n.manualPhotosStep1,
        const ManualShow([
          _B.hold(_S(_T.wall), then: _L.wallHere),
          _B.tap(_S.item(1)),
        ]),
      ),
      (
        l10n.manualPhotosStep2,
        const ManualShow([_B.tap(_more, then: _L.more), _B.tap(_S.item(1))]),
      ),
      (
        l10n.manualPhotosStep3,
        const ManualShow([_B.tap(_add, then: _L.add), _B.tap(_S.item(2))]),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.search,
    title: l10n.manualFindTitle,
    summary: l10n.manualFindSummary,
    steps: [
      (
        l10n.manualFindStep1,
        const ManualShow([_B.tap(_S(_T.search), then: _L.search)]),
      ),
      (
        l10n.manualFindStep2,
        const ManualShow([
          _B.tap(_S(_T.layout), then: _L.views),
          _B.tap(_S.item(1)),
        ]),
      ),
      (
        l10n.manualFindStep3,
        const ManualShow([
          _B.hold(_noteB, then: _L.note),
          _B.tap(_S.item(5), then: _L.home),
          _B.drag(_S(_T.wall), _S(_T.wallLow), carry: ManualCarry.lasso),
        ]),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.ios_share,
    title: l10n.manualShareTitle,
    summary: l10n.manualShareSummary,
    steps: [
      (
        l10n.manualShareStep1,
        const ManualShow([
          _B.hold(_noteB, then: _L.note),
          _B.tap(_S.row(2)),
          _B.tap(_S.row(3)),
        ]),
      ),
      (
        l10n.manualShareStep2,
        const ManualShow([
          _B.tap(_S(_T.share), then: _L.export),
          _B.tap(_S.row(1)),
        ]),
      ),
      (
        l10n.manualShareStep3,
        const ManualShow([
          _B.tap(_S.row(2), then: _L.boardPick),
          _B.tap(_S.item(0), then: _L.home),
        ], start: _L.systemShare),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.shield_outlined,
    title: l10n.manualSafeTitle,
    summary: l10n.manualSafeSummary,
    steps: [
      (
        l10n.manualSafeStep1,
        const ManualShow([..._toSettings, _B.tap(_S.item(5))]),
      ),
      (
        l10n.manualSafeStep2,
        const ManualShow([..._toSettings, _B.tap(_S.item(6))]),
      ),
      if (_syncBuild)
        (
          l10n.manualSafeSync,
          const ManualShow([..._toSettings, _B.tap(_S.item(3))]),
        ),
      (
        l10n.manualSafeStep3,
        const ManualShow([..._toSettings, _B.tap(_S.item(2))]),
      ),
    ],
  ),
  ManualTopic(
    icon: Icons.palette_outlined,
    title: l10n.manualYoursTitle,
    summary: l10n.manualYoursSummary,
    steps: [
      (
        l10n.manualYoursStep1,
        const ManualShow([
          _B.tap(_S(_T.palette), then: _L.customize),
          _B.tap(_S.item(0)),
        ]),
      ),
      (
        l10n.manualYoursStep2,
        const ManualShow([_B.tap(_more, then: _L.more), _B.tap(_S.item(7))]),
      ),
      (
        l10n.manualYoursStep3,
        const ManualShow([..._toSettings, _B.tap(_S.item(1))]),
      ),
      (
        l10n.manualYoursStep4,
        const ManualShow([..._toSettings, _B.tap(_S.item(0))]),
      ),
    ],
  ),
];

/// Settings → Help → How to use: the guide again, step by step, and the
/// manual as short topics. Reading it changes nothing.
class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HowToUsePage()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topics = manualTopics(l10n);
    final ground = guideGround(context);
    return Scaffold(
      backgroundColor: ground,
      appBar: AppBar(
        backgroundColor: ground,
        foregroundColor: AppColors.ink,
        title: Text(l10n.howToUse),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _ReplayCard(
                  onTap: () => WelcomeGuide.open(context, replay: true),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      l10n.howToUseTopics,
                      style: AppType.heading(context),
                    ),
                  ),
                ),
                for (final (i, topic) in topics.indexed)
                  ListTile(
                    key: Key('manual-topic-$i'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    minVerticalPadding: 10,
                    leading: _TopicBadge(icon: topic.icon, index: i),
                    title: Text(
                      topic.title,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      topic.summary,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.inkSoft,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ManualTopicPage(start: i),
                      ),
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

/// The topic's icon on a little square of note paper.
class _TopicBadge extends StatelessWidget {
  const _TopicBadge({required this.icon, required this.index});

  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    final paper = AppColors.notePapers[index % AppColors.freePapers];
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isNight(context) ? nightPaper(paper) : paper,
        borderRadius: BorderRadius.circular(AppRadii.paper),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26302318),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.ink, size: 24),
    );
  }
}

/// "Replay the guide", the first way in: a large sunny card.
class _ReplayCard extends StatelessWidget {
  const _ReplayCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sun = isNight(context)
        ? nightPaper(AppColors.accent)
        : AppColors.accent;
    return Material(
      color: sun,
      borderRadius: BorderRadius.circular(AppRadii.control * 1.5),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        key: const Key('manual-replay'),
        borderRadius: BorderRadius.circular(AppRadii.control * 1.5),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                size: 36,
                color: AppColors.ink,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.guideReplay,
                      style: TextStyle(
                        fontSize: 22 * noteFontScale(context),
                        height: 1.15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.guideReplayHint,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One topic on a page of its own, with Previous and Next to walk through
/// them all in order. Its picture is still and does nothing.
class ManualTopicPage extends StatefulWidget {
  const ManualTopicPage({super.key, required this.start});

  final int start;

  @override
  State<ManualTopicPage> createState() => _ManualTopicPageState();
}

class _ManualTopicPageState extends State<ManualTopicPage> {
  late int _at = widget.start;

  /// The step playing on the little phone.
  int _step = 0;

  /// The phone on each topic's page (two pages show while they swap).
  final _phones = <int, GlobalKey>{};
  GlobalKey get _phone => _phones.putIfAbsent(_at, GlobalKey.new);

  /// Plays step [i], bringing the phone into view if it was scrolled away.
  void _play(int i) {
    setState(() => _step = i);
    final phone = _phone.currentContext;
    if (phone != null) {
      Scrollable.ensureVisible(
        phone,
        duration: AppMetrics.motion(context, milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  void _goTo(int topic) => setState(() {
    _at = topic;
    _step = 0;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topics = manualTopics(l10n);
    final topic = topics[_at];
    final last = _at == topics.length - 1;
    final ground = guideGround(context);
    final buttonText = const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    return Scaffold(
      backgroundColor: ground,
      appBar: AppBar(
        backgroundColor: ground,
        foregroundColor: AppColors.ink,
        title: Text(l10n.howToUse),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMetrics.motion(context, milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey('topic-$_at'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _body(context, topic, topics.length),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Row(
                  children: [
                    Expanded(
                      child: _at == 0
                          ? const SizedBox.shrink()
                          : OutlinedButton.icon(
                              key: const Key('manual-previous'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                textStyle: buttonText,
                              ),
                              onPressed: () => _goTo(_at - 1),
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: Text(
                                l10n.howToUsePrevious,
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('manual-next'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          textStyle: buttonText,
                        ),
                        onPressed: last
                            ? () => Navigator.of(context).pop()
                            : () => _goTo(_at + 1),
                        child: Text(
                          last ? l10n.guideDone : l10n.guideNext,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ManualTopic topic, int total) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howToUseTopicOf(_at + 1, total),
          style: AppType.caption(context),
        ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            topic.title,
            style: TextStyle(
              fontSize: 32 * noteFontScale(context),
              height: 1.1,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          topic.summary,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            height: 1.45,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          key: _phone,
          child: ManualPlayer(
            key: ValueKey('show-$_at-$_step'),
            show: topic.steps[_step].$2,
          ),
        ),
        const SizedBox(height: 16),
        for (final (i, (words, _)) in topic.steps.indexed)
          _StepRow(
            key: Key('manual-step-$i'),
            number: i + 1,
            words: words,
            playing: i == _step,
            onTap: () => _play(i),
          ),
      ],
    );
  }
}

/// A step of a topic: its number and words. Tapped, it plays on the little
/// phone above; the one playing is lit.
class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.number,
    required this.words,
    required this.playing,
    required this.onTap,
  });

  final int number;
  final String words;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isNight(context)
        ? nightPaper(AppColors.accent)
        : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: playing,
        child: Material(
          color: playing ? accent.withValues(alpha: .22) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.control * 1.5),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.control * 1.5),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: playing ? accent : null,
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Text(
                        '$number',
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      words,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 16,
                        height: 1.45,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ExcludeSemantics(
                    child: Icon(
                      playing ? Icons.play_circle : Icons.play_circle_outline,
                      size: 22,
                      color: playing ? AppColors.ink : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

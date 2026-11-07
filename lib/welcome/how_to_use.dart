import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'guide_motion.dart';
import 'manual_illustration.dart';
import 'welcome_guide.dart';

/// A topic contains short instructions with one real-UI picture per step.
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
  final List<String> steps;
}

const _syncBuild = bool.fromEnvironment('STICKY_SYNC');

String manualAssetName(int topic, int step) {
  if (topic == 10 && _syncBuild) {
    if (step == 2) return '11_sync';
    if (step == 3) return '11_3';
  }
  return '${topic + 1}_${step + 1}';
}

List<ManualTopic> manualTopics(AppLocalizations l10n) => [
  ManualTopic(
    icon: Icons.note_add_outlined,
    title: l10n.manualFirstTitle,
    summary: l10n.manualFirstSummary,
    steps: [
      l10n.manualFirstStep1,
      l10n.manualFirstStep2,
      l10n.manualFirstStep3,
    ],
  ),
  ManualTopic(
    icon: Icons.open_with,
    title: l10n.manualMoveTitle,
    summary: l10n.manualMoveSummary,
    steps: [
      l10n.manualMoveStep1,
      l10n.manualMoveStep2,
      l10n.manualMoveStep3,
      l10n.manualMoveStep4,
    ],
  ),
  ManualTopic(
    icon: Icons.timeline,
    title: l10n.manualThreadTitle,
    summary: l10n.manualThreadSummary,
    steps: [
      l10n.manualThreadStep1,
      l10n.manualThreadStep2,
      l10n.manualThreadStep3,
    ],
  ),
  ManualTopic(
    icon: Icons.checklist,
    title: l10n.manualKindsTitle,
    summary: l10n.manualKindsSummary,
    steps: [
      l10n.manualKindsStep1,
      l10n.manualKindsStep2,
      l10n.manualKindsStep3,
      l10n.manualKindsStep4,
    ],
  ),
  ManualTopic(
    icon: Icons.gesture,
    title: l10n.manualDrawTitle,
    summary: l10n.manualDrawSummary,
    steps: [l10n.manualDrawStep1, l10n.manualDrawStep2, l10n.manualDrawStep3],
  ),
  ManualTopic(
    icon: Icons.dashboard_outlined,
    title: l10n.manualBoardsTitle,
    summary: l10n.manualBoardsSummary,
    steps: [
      l10n.manualBoardsStep1,
      l10n.manualBoardsStep2,
      l10n.manualBoardsStep3,
    ],
  ),
  ManualTopic(
    icon: Icons.dashboard_customize_outlined,
    title: l10n.manualLooksTitle,
    summary: l10n.manualLooksSummary,
    steps: [
      l10n.manualLooksStep1,
      l10n.manualLooksStep2,
      l10n.manualLooksStep3,
      l10n.manualLooksStep4,
    ],
  ),
  ManualTopic(
    icon: Icons.photo_library_outlined,
    title: l10n.manualPhotosTitle,
    summary: l10n.manualPhotosSummary,
    steps: [
      l10n.manualPhotosStep1,
      l10n.manualPhotosStep2,
      l10n.manualPhotosStep3,
      l10n.manualPhotosStep4,
    ],
  ),
  ManualTopic(
    icon: Icons.search,
    title: l10n.manualFindTitle,
    summary: l10n.manualFindSummary,
    steps: [l10n.manualFindStep1, l10n.manualFindStep2, l10n.manualFindStep3],
  ),
  ManualTopic(
    icon: Icons.ios_share,
    title: l10n.manualShareTitle,
    summary: l10n.manualShareSummary,
    steps: [
      l10n.manualShareStep1,
      l10n.manualShareStep2,
      l10n.manualShareStep3,
    ],
  ),
  ManualTopic(
    icon: Icons.shield_outlined,
    title: l10n.manualSafeTitle,
    summary: l10n.manualSafeSummary,
    steps: [
      l10n.manualSafeStep1,
      l10n.manualSafeStep2,
      if (_syncBuild) l10n.manualSafeSync,
      l10n.manualSafeStep3,
    ],
  ),
  ManualTopic(
    icon: Icons.palette_outlined,
    title: l10n.manualYoursTitle,
    summary: l10n.manualYoursSummary,
    steps: [
      l10n.manualYoursStep1,
      l10n.manualYoursStep2,
      l10n.manualYoursStep3,
      l10n.manualYoursStep4,
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
                    onTap: () => ManualTopicPage.open(context, start: i),
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

/// A topic is a scrollable sheet: one numbered instruction and one still
/// spotlight illustration per card. Reading never changes the user's wall.
class ManualTopicPage extends StatefulWidget {
  const ManualTopicPage({
    super.key,
    required this.start,
    this.scrollController,
  });

  final int start;
  final ScrollController? scrollController;

  static Future<void> open(BuildContext context, {required int start}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: false,
        backgroundColor: guideGround(context),
        constraints: const BoxConstraints(maxWidth: 720),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: .92,
          minChildSize: .55,
          maxChildSize: .96,
          expand: false,
          builder: (_, controller) =>
              ManualTopicPage(start: start, scrollController: controller),
        ),
      );

  @override
  State<ManualTopicPage> createState() => _ManualTopicPageState();
}

class _ManualTopicPageState extends State<ManualTopicPage> {
  late int _at = widget.start;
  late final _scroll = widget.scrollController ?? ScrollController();

  @override
  void dispose() {
    if (widget.scrollController == null) _scroll.dispose();
    super.dispose();
  }

  void _goTo(int topic) {
    _scroll.jumpTo(0);
    setState(() => _at = topic);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topics = manualTopics(l10n);
    final topic = topics[_at];
    const words = TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 15,
      height: 1.5,
      color: AppColors.ink,
    );
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inkSoft.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.howToUseTopicOf(_at + 1, topics.length),
                            style: words.copyWith(
                              fontSize: 12,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            header: true,
                            child: Text(
                              topic.title,
                              style: words.copyWith(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('manual-close'),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  topic.summary,
                  style: words.copyWith(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                for (final (i, instruction) in topic.steps.indexed)
                  Container(
                    key: Key('manual-step-$i'),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.inkSoft.withValues(alpha: .25),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${i + 1}',
                                style: words.copyWith(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                instruction,
                                style: words.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ManualIllustration(
                                key: ValueKey('still-$_at-$i'),
                                assetName: manualAssetName(_at, i),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (_at > 0)
                      Expanded(
                        child: TextButton.icon(
                          key: const Key('manual-previous'),
                          onPressed: () => _goTo(_at - 1),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: Text(l10n.howToUsePrevious),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 8),
                    if (_at < topics.length - 1)
                      Expanded(
                        child: TextButton.icon(
                          key: const Key('manual-next'),
                          onPressed: () => _goTo(_at + 1),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(l10n.guideNext),
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
                FilledButton(
                  key: const Key('manual-done'),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.guideDone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

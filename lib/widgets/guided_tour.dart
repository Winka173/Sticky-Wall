import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// The steps of the interactive guide, practised on the real wall.
enum TourStep { tap, drag, thread, done }

/// A small card above the tool pill that walks through the wall's three
/// gestures while the user does them for real: tap a note to write on it,
/// drag one, pull a thread from a pin. Each step moves on when the gesture
/// is done, or with Next (for anyone who can't or would rather not do the
/// gesture; the thread step also names the menu way). Skip ends it any time.
/// Nothing is created, changed or deleted by the guide itself.
class GuidedTourCard extends StatelessWidget {
  const GuidedTourCard({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
    required this.onFirstNote,
  });

  final TourStep step;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  /// The last step's main action: write a note of one's own.
  final VoidCallback onFirstNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, title, body) = switch (step) {
      TourStep.tap => (
        Icons.touch_app_outlined,
        l10n.tourTapTitle,
        l10n.tourTapBody,
      ),
      TourStep.drag => (Icons.open_with, l10n.tourDragTitle, l10n.tourDragBody),
      TourStep.thread => (
        Icons.timeline,
        l10n.tourThreadTitle,
        l10n.tourThreadBody,
      ),
      TourStep.done => (
        Icons.check_circle_outline,
        l10n.tourDoneTitle,
        l10n.tourDoneBody,
      ),
    };
    final index = step.index;
    final last = step == TourStep.done;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: AppColors.paper,
        elevation: 6,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(AppRadii.control * 1.5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.ink, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  // Step dots: where you are, and that it is short.
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        for (var i = 0; i < TourStep.values.length; i++)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i <= index
                                  ? AppColors.ink
                                  : AppColors.inkHint,
                            ),
                          ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: AppColors.ink,
                  ),
                ),
              ),
              // Wraps under itself on a narrow screen or with large text.
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 4,
                children: [
                  if (!last)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        minimumSize: const Size(48, 44),
                      ),
                      onPressed: onSkip,
                      child: Text(l10n.tourSkip),
                    ),
                  if (last)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        minimumSize: const Size(48, 44),
                      ),
                      onPressed: onSkip,
                      child: Text(l10n.tourClose),
                    ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 44),
                    ),
                    onPressed: last ? onFirstNote : onNext,
                    child: Text(last ? l10n.tourFirstNote : l10n.tourNext),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

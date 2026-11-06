import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../theme.dart';

/// One add entrance in every view. The result is a note type, or 'memory'.
/// This sheet owns presentation only; the caller keeps all creation logic.
Future<Object?> showAddToWallSheet(BuildContext context) =>
    showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddToWallSheet(),
    );

class AddToWallSheet extends StatelessWidget {
  const AddToWallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final choices = [
      (NoteType.normal, AppIcons.note, l.typeNormal, l.addTextHint),
      (
        NoteType.checklist,
        AppIcons.checklist,
        l.typeChecklist,
        l.addChecklistHint,
      ),
      (NoteType.photo, AppIcons.photo, l.typePhoto, l.addPhotoHint),
      (NoteType.link, AppIcons.link, l.typeLink, l.addLinkHint),
      (NoteType.audio, AppIcons.voice, l.typeAudio, l.addVoiceHint),
      (NoteType.drawing, AppIcons.drawing, l.typeDrawing, l.addDrawingHint),
    ];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.addToWall, style: AppType.heading(context)),
              const SizedBox(height: AppSpace.small),
              Text(l.addToWallHint, style: AppType.caption(context)),
              const SizedBox(height: AppSpace.large),
              LayoutBuilder(
                builder: (context, box) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(16) > 23;
                  final columns = box.maxWidth < 300 || largeText ? 1 : 2;
                  final width =
                      (box.maxWidth - AppSpace.small * (columns - 1)) / columns;
                  return Wrap(
                    spacing: AppSpace.small,
                    runSpacing: AppSpace.small,
                    children: [
                      for (final (type, icon, title, hint) in choices)
                        SizedBox(
                          width: width,
                          child: Material(
                            color: type == NoteType.normal
                                ? AppColors.accent.withValues(alpha: .22)
                                : AppColors.ink.withValues(alpha: .045),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.control,
                              ),
                              side: BorderSide(
                                color: AppColors.ink.withValues(alpha: .12),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('add-${type.name}'),
                              onTap: () => Navigator.pop(context, type),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpace.medium),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(icon, size: AppMetrics.icon),
                                    const SizedBox(height: AppSpace.small),
                                    Text(
                                      title,
                                      style: AppType.control(context),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(hint, style: AppType.caption(context)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpace.medium),
              Wrap(
                spacing: AppSpace.small,
                runSpacing: AppSpace.small,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(AppIcons.label),
                    label: Text(l.typeLabel),
                    onPressed: () => Navigator.pop(context, NoteType.label),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(AppIcons.sticker),
                    label: Text(l.typeSticker),
                    onPressed: () => Navigator.pop(context, NoteType.sticker),
                  ),
                ],
              ),
              const Divider(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(AppIcons.memory),
                title: Text(l.memoryWall),
                subtitle: Text(l.memoryWallHint),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, 'memory'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

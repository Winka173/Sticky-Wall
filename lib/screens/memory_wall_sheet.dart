import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/memory_wall.dart';
import '../services/pro_controller.dart';
import '../services/theme_packs.dart';
import '../theme.dart';
import '../widgets/photo_frames.dart';
import '../widgets/pro_sheet.dart';
import 'gallery_screen.dart';

/// The looks offered for a memory wall: papers and frames that suit
/// photos. Any other pack can be put on the board later.
const memoryWallLooks = [
  'polaroid_studio',
  'cork_classic',
  'warm_wood',
  'scrapbook_craft',
  'travel_journal',
  'pastel_kawaii',
  'minimal_cream',
  'dark_chalk',
];

/// What the memory-wall sheet settled on.
typedef MemoryWallChoice = ({
  MemoryLayout layout,
  ThemePack look,
  PhotoFrame frame,
  CaptionPreset caption,
});

/// Asks how [count] picked photos should be laid out, framed and captioned,
/// and in which look. Returns null when cancelled.
Future<MemoryWallChoice?> showMemoryWallSheet(
  BuildContext context, {
  required int count,
}) {
  return showModalBottomSheet<MemoryWallChoice>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _MemoryWallSheet(count: count),
  );
}

class _MemoryWallSheet extends StatefulWidget {
  const _MemoryWallSheet({required this.count});

  final int count;

  @override
  State<_MemoryWallSheet> createState() => _MemoryWallSheetState();
}

class _MemoryWallSheetState extends State<_MemoryWallSheet> {
  MemoryLayout _layout = MemoryLayout.collage;
  ThemePack _look = themePackById(memoryWallLooks.first)!;
  PhotoFrame _frame = PhotoFrame.polaroid;
  CaptionPreset _caption = CaptionPreset.none;

  @override
  void initState() {
    super.initState();
    // Without Pro the first look offered is a free one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ProScope.unlockedOf(context) || !_look.pro) return;
      setState(() => _look = themePackById('cork_classic')!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final pro = ProScope.unlockedOf(context);
    final layouts = [
      (
        MemoryLayout.collage,
        Icons.auto_awesome_mosaic_outlined,
        l10n.layoutCollage,
      ),
      (MemoryLayout.prints, Icons.grid_view_outlined, l10n.layoutPrints),
      (MemoryLayout.film, Icons.movie_outlined, l10n.layoutFilm),
      (MemoryLayout.timeline, Icons.timeline, l10n.layoutTimeline),
      (MemoryLayout.hero, Icons.center_focus_strong_outlined, l10n.layoutHero),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.memoryWall,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.memoryPhotoCount(widget.count),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            if (widget.count > memoryWallMax)
              Text(
                l10n.memoryTooMany(memoryWallMax),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.warnText),
              ),
            const SizedBox(height: 16),
            Text(l10n.memoryLayout, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final (layout, icon, label) in layouts)
                  ChoiceChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    selected: _layout == layout,
                    onSelected: (_) => setState(() => _layout = layout),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.photoFrame, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final f in PhotoFrame.values)
                  ChoiceChip(
                    avatar: f.pro && !pro
                        ? const Icon(Icons.lock_outline, size: 16)
                        : null,
                    label: Text(photoFrameName(l10n, f)),
                    selected: _frame == f,
                    onSelected: (_) => f.pro && !pro
                        ? showProSheet(context)
                        : setState(() => _frame = f),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.memoryCaption, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final (c, label) in [
                  (CaptionPreset.none, l10n.captionNone),
                  (CaptionPreset.numbers, l10n.captionNumbers),
                  (CaptionPreset.date, l10n.captionDate),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _caption == c,
                    onSelected: (_) => setState(() => _caption = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.memoryLook, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            SizedBox(
              height: 190,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final id in memoryWallLooks)
                    if (themePackById(id) case final pack?)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _LookChoice(
                          pack: pack,
                          name: pack.name(lang),
                          selected: _look.id == pack.id,
                          locked: pack.pro && !pro,
                          onTap: pack.pro && !pro
                              ? () => showProSheet(context)
                              : () => setState(() => _look = pack),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.memoryCreate),
              onPressed: () => Navigator.pop(context, (
                layout: _layout,
                look: _look,
                frame: _frame,
                caption: _caption,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookChoice extends StatelessWidget {
  const _LookChoice({
    required this.pack,
    required this.name,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final ThemePack pack;
  final String name;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? AppLocalizations.of(context)!.proLocked(name) : name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: SizedBox(
          width: 96,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.control),
                        border: Border.all(
                          color: selected ? AppColors.ink : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ThemePreview(pack: pack),
                      ),
                    ),
                    if (locked)
                      const Positioned(top: 6, right: 6, child: ProMark()),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

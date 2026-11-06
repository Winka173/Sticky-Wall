import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/image_service.dart';
import '../services/memory_wall.dart';
import '../services/pro_controller.dart';
import '../services/theme_packs.dart';
import '../theme.dart';
import '../widgets/paper_choice_chip.dart';
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
  List<String> photos,
});

/// Asks how [count] picked photos should be laid out, framed and captioned,
/// and in which look. Returns null when cancelled.
Future<MemoryWallChoice?> showMemoryWallSheet(
  BuildContext context, {
  required int count,
  List<String> photos = const [],
  Future<List<String>> Function(int remaining)? onAddPhotos,
}) {
  return showModalBottomSheet<MemoryWallChoice>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _MemoryWallSheet(
      count: count,
      photos: photos,
      onAddPhotos: onAddPhotos,
    ),
  );
}

class _MemoryWallSheet extends StatefulWidget {
  const _MemoryWallSheet({
    required this.count,
    this.photos = const [],
    this.onAddPhotos,
  });

  final int count;

  /// The picked photos (stored names), shown in the live preview.
  final List<String> photos;
  final Future<List<String>> Function(int remaining)? onAddPhotos;

  @override
  State<_MemoryWallSheet> createState() => _MemoryWallSheetState();
}

class _MemoryWallSheetState extends State<_MemoryWallSheet> {
  MemoryLayout _layout = MemoryLayout.collage;
  ThemePack _look = themePackById(memoryWallLooks.first)!;
  PhotoFrame _frame = PhotoFrame.polaroid;
  CaptionPreset _caption = CaptionPreset.none;
  late final List<String> _photos;
  bool _picking = false;
  bool _pickFailed = false;

  /// Photos picked again that were already on the list (the system picker
  /// cannot show what was chosen before), left out and counted.
  int _duplicates = 0;

  /// Content hashes of the photos on the list, by stored name.
  final _hashes = <String, String>{};

  /// What [name] holds, as a short fingerprint (its size and a hash of its
  /// first 64 KB): the same picture picked twice is copied in under two
  /// names. Read synchronously, a few KB per photo. Null when unreadable.
  Future<String?> _hashOf(String name) async {
    final known = _hashes[name];
    if (known != null) return known;
    try {
      final file = File(ImageService.resolve(name));
      if (!file.existsSync()) return null;
      final raf = file.openSync();
      try {
        final head = raf.readSync(64 * 1024);
        return _hashes[name] = '${raf.lengthSync()}:${sha1.convert(head)}';
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _addPhotos() async {
    setState(() {
      _picking = true;
      _pickFailed = false;
    });
    try {
      final added = await widget.onAddPhotos!(memoryWallMax - _photos.length);
      if (!mounted) {
        for (final photo in added) {
          await ImageService.deleteFile(photo);
        }
        return;
      }
      // Leave out what is already on the list (or twice in this batch).
      final seen = <String>{
        for (final p in _photos) (await _hashOf(p)) ?? 'name:$p',
      };
      final fresh = <String>[];
      var repeats = 0;
      for (final photo in added) {
        final key = (await _hashOf(photo)) ?? 'name:$photo';
        if (seen.add(key)) {
          fresh.add(photo);
        } else {
          repeats++;
        }
      }
      if (!mounted) return;
      setState(() {
        _duplicates = repeats;
        _photos.addAll(fresh.take(memoryWallMax - _photos.length));
      });
    } catch (_) {
      if (mounted) setState(() => _pickFailed = true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _photos = widget.photos.take(memoryWallMax).toList();
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.memoryWall,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // How many photos, with a small "add more" beside it.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.memoryPhotoCount(
                            _photos.isEmpty ? widget.count : _photos.length,
                          ),
                          style: const TextStyle(color: AppColors.inkSoft),
                        ),
                        if (widget.onAddPhotos != null)
                          IconButton(
                            tooltip: l10n.memoryAddPhotosHint(memoryWallMax),
                            icon: _picking
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                            color: AppColors.ink,
                            onPressed:
                                _picking || _photos.length >= memoryWallMax
                                ? null
                                : _addPhotos,
                          ),
                      ],
                    ),
                    if (widget.count > memoryWallMax)
                      Text(
                        l10n.memoryTooMany(memoryWallMax),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.warnText,
                        ),
                      ),
                    if (_photos.length > 1 || widget.onAddPhotos != null)
                      _ChosenStrip(
                        photos: _photos,
                        onRemove: _photos.length <= 1
                            ? null
                            : (photo) => setState(() {
                                _photos.remove(photo);
                                _duplicates = 0;
                              }),
                      ),
                    if (_duplicates > 0)
                      Text(
                        l10n.memoryDuplicates(_duplicates),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    if (_pickFailed)
                      Text(
                        l10n.photoPickFailed,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.warnText),
                      ),
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      // What the board will look like, with these very photos:
                      // layout, frame and look change it live, before anything is
                      // created.
                      Semantics(
                        key: const ValueKey('memory-live-preview'),
                        label: l10n.memoryPreview,
                        child: _MemoryPreview(
                          photos: _photos.toList(),
                          layout: _layout,
                          frame: _frame,
                          look: _look,
                          caption: _caption,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.memoryLayout,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final (layout, icon, label) in layouts)
                          PaperChoiceChip(
                            icon: icon,
                            label: label,
                            selected: _layout == layout,
                            onSelected: () => setState(() => _layout = layout),
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
                          PaperChoiceChip(
                            icon: switch (f) {
                              PhotoFrame.print => Icons.crop_original_rounded,
                              PhotoFrame.polaroid => Icons.photo_outlined,
                              PhotoFrame.film => Icons.local_movies_outlined,
                              PhotoFrame.vintage =>
                                Icons.filter_vintage_outlined,
                              PhotoFrame.torn => Icons.receipt_long_outlined,
                              PhotoFrame.rounded =>
                                Icons.rounded_corner_rounded,
                              PhotoFrame.scrapbook =>
                                Icons.auto_stories_outlined,
                            },
                            label:
                                '${photoFrameName(l10n, f)}${f.pro && !pro ? ' · Pro' : ''}',
                            selected: _frame == f,
                            onSelected: () => setState(() => _frame = f),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.memoryCaption,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final (c, label, icon) in [
                          (
                            CaptionPreset.none,
                            l10n.captionNone,
                            Icons.notes_rounded,
                          ),
                          (
                            CaptionPreset.numbers,
                            l10n.captionNumbers,
                            Icons.format_list_numbered_rounded,
                          ),
                          (
                            CaptionPreset.date,
                            l10n.captionDate,
                            Icons.calendar_today_outlined,
                          ),
                        ])
                          PaperChoiceChip(
                            icon: icon,
                            label: label,
                            selected: _caption == c,
                            onSelected: () => setState(() => _caption = c),
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
                                  onTap: () => setState(() => _look = pack),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Always in reach: the button never scrolls away.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!pro && (_look.pro || _frame.pro))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.memoryPreviewPro,
                        style: AppType.caption(context),
                      ),
                    ),
                  FilledButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      !pro && (_look.pro || _frame.pro)
                          ? l10n.proUnlock
                          : l10n.memoryCreate,
                    ),
                    onPressed: _picking
                        ? null
                        : () async {
                            if ((_look.pro || _frame.pro) &&
                                !ProScope.unlockedOf(context)) {
                              await showProSheet(context);
                              if (!context.mounted ||
                                  !ProScope.unlockedOf(context)) {
                                return;
                              }
                            }
                            if (!context.mounted) return;
                            Navigator.pop(context, (
                              layout: _layout,
                              look: _look,
                              frame: _frame,
                              caption: _caption,
                              photos: List<String>.unmodifiable(_photos),
                            ));
                          },
                  ),
                ],
              ),
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
                        color: null,
                        borderRadius: BorderRadius.circular(AppRadii.control),
                        border: Border.all(
                          color: selected
                              ? AppColors.ink.withValues(alpha: .7)
                              : Colors.transparent,
                          width: 2,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                decoration: BoxDecoration(
                  color: null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check_circle_rounded, size: 14),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
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

/// A small, live picture of the memory wall about to be made: the look's
/// wall with the picked photos placed by the chosen layout and frame.
class _MemoryPreview extends StatelessWidget {
  const _MemoryPreview({
    required this.photos,
    required this.layout,
    required this.frame,
    required this.look,
    required this.caption,
  });

  final List<String> photos;
  final MemoryLayout layout;
  final PhotoFrame frame;
  final ThemePack look;
  final CaptionPreset caption;

  @override
  Widget build(BuildContext context) {
    final made = memoryWallNotes(
      photos,
      'memory-preview',
      layout,
      pack: look,
      frame: frame,
      caption: caption,
      date: MaterialLocalizations.of(context).formatMediumDate(DateTime.now()),
      now: DateTime(2026),
    );
    // The actual renderer preserves image aspect ratios, frame geometry,
    // captions and timeline threads, rather than forcing photos into squares.
    return SizedBox(
      height: 260,
      child: Center(
        child: AspectRatio(
          aspectRatio: previewSize.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.control),
            child: BoardPreview(
              fitContent: true,
              wall: look.wallStyle,
              notes: made.notes,
              links: made.links,
              pack: look,
            ),
          ),
        ),
      ),
    );
  }
}

/// The chosen photos as small thumbnails, in order, each with a button to
/// take it off the list (at least one stays).
class _ChosenStrip extends StatelessWidget {
  const _ChosenStrip({required this.photos, required this.onRemove});

  final List<String> photos;
  final void Function(String photo)? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final photo = photos[i];
          // The remove badge sits on the thumbnail's corner, inside the
          // strip so it is never clipped.
          return SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.paper * 2),
                    child: Image.file(
                      File(ImageService.resolve(photo)),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      cacheWidth: 120,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 56,
                        height: 56,
                        child: ColoredBox(color: AppColors.inkHint),
                      ),
                    ),
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Semantics(
                      button: true,
                      label: l10n.memoryRemovePhoto(i + 1),
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onRemove!(photo),
                        // A small badge with a bigger target around it.
                        child: const SizedBox.square(
                          dimension: 28,
                          child: Center(
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.ink,
                              child: Icon(
                                Icons.close,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

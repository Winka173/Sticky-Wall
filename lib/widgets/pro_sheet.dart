import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/pro_controller.dart';
import '../theme.dart';

/// Opens the Sticky Wall Pro sheet: what Pro adds, the price, Unlock and
/// Restore. Every Pro thing in the app (a paper, wall, font or pin with the
/// small Pro mark) opens it when tapped without Pro.
Future<void> showProSheet(BuildContext context) {
  // Read here, above the sheet's own route, so the sheet works wherever
  // it is opened from.
  final pro = ProScope.maybeOf(context);
  _loadPrice(pro);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: pro == null
          ? const _ProBody(pro: null)
          : ListenableBuilder(
              listenable: pro,
              builder: (context, _) => _ProBody(pro: pro),
            ),
    ),
  );
}

/// A price that failed to load is asked for again when the sheet opens.
void _loadPrice(ProController? pro) {
  if (pro != null && pro.price == null) pro.loadProduct().ignore();
}

class _ProBody extends StatefulWidget {
  const _ProBody({required this.pro});

  final ProController? pro;

  @override
  State<_ProBody> createState() => _ProBodyState();
}

class _ProBodyState extends State<_ProBody> {
  bool _restoring = false;

  /// The answer to the last Restore, shown under the buttons.
  String? _restoreNote;

  Future<void> _restore(AppLocalizations l10n) async {
    final pro = widget.pro;
    if (pro == null) return;
    setState(() {
      _restoring = true;
      _restoreNote = null;
    });
    final found = await pro.restore();
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _restoreNote = found ? l10n.proRestored : l10n.proRestoreNone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pro = widget.pro;
    final unlocked = pro?.unlocked ?? false;
    final status = pro?.status ?? ProStatus.unavailable;
    final price = pro?.price;

    final String? note = unlocked
        ? null
        : switch (status) {
            ProStatus.pending => l10n.proPending,
            ProStatus.failed => l10n.proFailed,
            ProStatus.unavailable => l10n.proUnavailable,
            ProStatus.idle || ProStatus.loading => null,
          };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.proTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.proPitch,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          _Perk(lead: const _PaperFan(), text: l10n.proPerkPapers),
          _Perk(lead: const _WallChip(), text: l10n.proPerkWalls),
          _Perk(lead: const _FontChip(), text: l10n.proPerkFonts),
          _Perk(
            lead: const Icon(Icons.push_pin_outlined, color: AppColors.ink),
            text: l10n.proPerkPins,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.proKeepsLook,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          if (unlocked)
            Semantics(
              liveRegion: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.ink),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.proUnlocked,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: pro != null && pro.canBuy ? pro.buy : null,
              child: status == ProStatus.loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.chalk,
                      ),
                    )
                  : Text(
                      price == null ? l10n.proBuyNoPrice : l10n.proBuy(price),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: pro == null || _restoring
                  ? null
                  : () => _restore(l10n),
              child: _restoring
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.proRestore),
            ),
          ],
          for (final line in [?note, ?_restoreNote])
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One line of what Pro adds, with a small picture of it.
class _Perk extends StatelessWidget {
  const _Perk({required this.lead, required this.text});

  final Widget lead;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox.square(dimension: 44, child: Center(child: lead)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three of the Pro papers fanned out.
class _PaperFan extends StatelessWidget {
  const _PaperFan();

  @override
  Widget build(BuildContext context) {
    Widget sheet(int index, double angle, Offset at) => Positioned(
      left: at.dx,
      top: at.dy,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: paperColorOf(context, index, ''),
            borderRadius: BorderRadius.circular(AppRadii.paper),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
    return SizedBox.square(
      dimension: 40,
      child: Stack(
        children: [
          sheet(8, -0.2, const Offset(2, 10)),
          sheet(6, 0.05, const Offset(10, 6)),
          sheet(7, 0.22, const Offset(17, 12)),
        ],
      ),
    );
  }
}

/// The first Pro wall, as a tiny tile.
class _WallChip extends StatelessWidget {
  const _WallChip();

  @override
  Widget build(BuildContext context) {
    final wall = walls.firstWhere((w) => w.pro);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: 34,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(wall.asset, fit: BoxFit.cover),
            ColoredBox(color: wall.overlay),
          ],
        ),
      ),
    );
  }
}

/// "Aa" in the first Pro font.
class _FontChip extends StatelessWidget {
  const _FontChip();

  @override
  Widget build(BuildContext context) {
    final font = fontChoices.firstWhere((f) => f.pro);
    return Text(
      'Aa',
      style: TextStyle(
        fontFamily: font.family,
        fontSize: 24 * font.scale,
        color: AppColors.ink,
      ),
    );
  }
}

/// The small "Pro" mark on a paper, wall, font or pin that needs Pro.
class ProMark extends StatelessWidget {
  const ProMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ink, width: 0.8),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 9,
          height: 1.3,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

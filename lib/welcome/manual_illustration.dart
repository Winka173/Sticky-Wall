import 'package:flutter/material.dart';

import 'manual_image_ratios.dart';

/// Bundled, static crops of the real app UI, with its actual target highlighted.
/// Regenerate with test/manual_assets_test.dart after changing those screens.
class ManualIllustration extends StatelessWidget {
  const ManualIllustration({super.key, required this.assetName});

  final String assetName;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode == 'vi'
        ? 'vi'
        : 'en';
    final id = '$language/$assetName';
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: manualImageRatios[id] ?? 1.6,
        child: Image.asset(
          'assets/manual/$id.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

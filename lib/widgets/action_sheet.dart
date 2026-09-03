import 'package:flutter/material.dart';

/// A bottom sheet holding a short menu of [ListTile]s (optionally under a
/// [title]). It sizes to its content — the default modal sheet caps itself
/// at 9/16 of the screen, which clipped a long menu ("bottom overflowed")
/// on small phones — and scrolls once it would pass [maxFraction] of the
/// screen. Resolves with whatever the tiles `Navigator.pop`.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  String? title,
  TextStyle? titleStyle,
  required List<Widget> children,
  double maxFraction = 0.85,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxFraction,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    title,
                    style:
                        titleStyle ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Opens a control's menu from the keyboard (Shift+F10 or the menu key) —
/// what a long-press does under a finger.
class _MenuIntent extends Intent {
  const _MenuIntent();
}

/// Makes a hand-built tappable (a note card, a board tab, a swatch) usable
/// from a keyboard, as on a tablet with a keyboard or a Chromebook: Tab
/// reaches it and draws a ring round it, Enter or Space does what a tap
/// does, Shift+F10 or the menu key does what a long-press does.
///
/// It wraps the control's own gesture detector rather than replacing it, so
/// fingers behave exactly as before.
class KeyboardTappable extends StatefulWidget {
  const KeyboardTappable({
    super.key,
    required this.child,
    this.onActivate,
    this.onMenu,
    this.borderRadius = BorderRadius.zero,
    this.circle = false,
  });

  final Widget child;
  final VoidCallback? onActivate;
  final VoidCallback? onMenu;

  /// The ring's shape: the control's own corners, or a circle.
  final BorderRadius borderRadius;
  final bool circle;

  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.f10, shift: true): _MenuIntent(),
    SingleActivator(LogicalKeyboardKey.contextMenu): _MenuIntent(),
  };

  @override
  State<KeyboardTappable> createState() => _KeyboardTappableState();
}

class _KeyboardTappableState extends State<KeyboardTappable> {
  bool _ring = false;

  @override
  Widget build(BuildContext context) {
    final activate = widget.onActivate;
    final menu = widget.onMenu;
    return FocusableActionDetector(
      enabled: activate != null || menu != null,
      shortcuts: menu == null ? const {} : KeyboardTappable._shortcuts,
      actions: {
        if (activate != null)
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        if (menu != null)
          _MenuIntent: CallbackAction<_MenuIntent>(
            onInvoke: (_) {
              menu();
              return null;
            },
          ),
      },
      // Only for keyboard focus: a tap must not leave a ring behind.
      onShowFocusHighlight: (on) => setState(() => _ring = on),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: _ring
            ? BoxDecoration(
                shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.circle ? null : widget.borderRadius,
                border: Border.all(color: AppColors.accent, width: 3),
              )
            : const BoxDecoration(),
        child: widget.child,
      ),
    );
  }
}

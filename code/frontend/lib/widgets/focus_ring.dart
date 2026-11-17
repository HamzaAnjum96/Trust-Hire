import 'package:flutter/material.dart';

import '../core/roles.dart';

/// A visible ring around a custom control while it has keyboard focus.
///
/// **Material's own controls show focus; the ones this app draws itself did
/// not.** An `InkWell` marks focus with a wash at a few percent of the text
/// colour, which on a row, a bar slot or the profile header is close to
/// nothing, so a person tabbing through the app lost their place at the first
/// custom control. This draws a 2px ring in the action colour (turmeric on the
/// ink shell), which clears 3:1 against what it sits on.
///
/// Only in keyboard mode: a finger already knows where it is, and a ring left
/// behind after a tap reads as a selection.
///
/// It takes no focus itself. It wraps whatever is focusable inside it and
/// listens, so focus order, semantics and the control's own behaviour are
/// untouched.
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.child,
    this.radius = BorderRadius.zero,
    this.onShell = false,
  });

  final Widget child;

  /// The corners of the control, so the ring follows its shape.
  final BorderRadius radius;

  /// On the ink navigation shell, where ink would be invisible.
  final bool onShell;

  @override
  State<FocusRing> createState() => FocusRingState();
}

class FocusRingState extends State<FocusRing> {
  bool _focused = false;

  /// Whether the ring is drawn now. For tests.
  bool get isShowing =>
      _focused &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onModeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onModeChanged);
    super.dispose();
  }

  void _onModeChanged(FocusHighlightMode _) {
    if (_focused && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colour = widget.onShell
        ? context.colours.highlight
        : context.colours.action;

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: isShowing
            ? BoxDecoration(
                border: Border.all(color: colour, width: 2),
                borderRadius: widget.radius,
              )
            : const BoxDecoration(),
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// Only when the last thing somebody did was press a key, as the web's
/// `:focus-visible` does. A finger or a mouse already knows where it is, and a
/// ring left behind after a click reads as a selection. Flutter's own
/// highlight mode is not enough for this: it calls a mouse "traditional", so
/// clicking the map (which takes focus for its arrow keys) ringed the whole
/// map.
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
  bool get isShowing => _focused && _LastInput.instance.wasKey;

  @override
  void initState() {
    super.initState();
    _LastInput.instance
      ..listen()
      ..addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _LastInput.instance.removeListener(_onInputChanged);
    super.dispose();
  }

  void _onInputChanged() {
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

/// Whether the most recent input was a key press or a pointer.
///
/// One listener for the whole app, installed the first time a ring is built:
/// every key event says "keyboard", every pointer press says "not".
class _LastInput extends ChangeNotifier {
  _LastInput._() {
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  static final instance = _LastInput._();

  /// (Re)attaches the key handler. Idempotent: the handler is removed before
  /// it is added. Something can clear the keyboard's handlers (the test
  /// binding does, between tests), and a ring that stops hearing keys fails
  /// silently.
  void listen() {
    HardwareKeyboard.instance
      ..removeHandler(_onKey)
      ..addHandler(_onKey);
  }

  bool wasKey = false;

  bool _onKey(KeyEvent event) {
    if (!wasKey) {
      wasKey = true;
      notifyListeners();
    }
    // Only listening; the key goes on to whoever handles it.
    return false;
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent && wasKey) {
      wasKey = false;
      notifyListeners();
    }
  }
}

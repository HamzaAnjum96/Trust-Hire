import 'package:flutter/material.dart';

import 'tokens.dart';

/// Motion helpers that respect the platform's reduced-motion setting.
///
/// Section 28 requires support for reduced motion, and section 29 lists it
/// among the accessibility requirements. Rather than leaving each screen to
/// remember, animations go through here: when the user has asked for less
/// motion, durations collapse to zero so state changes are instant instead of
/// animated. Nothing is removed — only the movement.
class Motion {
  const Motion._();

  /// True when the platform asks for reduced motion.
  static bool isReduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration fast(BuildContext context) =>
      isReduced(context) ? Duration.zero : BrandMotion.fast;

  static Duration standard(BuildContext context) =>
      isReduced(context) ? Duration.zero : BrandMotion.standard;

  static Duration large(BuildContext context) =>
      isReduced(context) ? Duration.zero : BrandMotion.large;
}

/// Fades and lifts its child in on first build.
///
/// Used to settle content into place rather than having it appear abruptly —
/// the "saved job appears smoothly" case from section 28. It moves 8 logical
/// pixels, not a parallax sweep.
class SettleIn extends StatefulWidget {
  const SettleIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<SettleIn> createState() => _SettleInState();
}

class _SettleInState extends State<SettleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: BrandMotion.standard,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.isReduced(context)) return widget.child;

    final curve = CurvedAnimation(
      parent: _controller,
      curve: BrandMotion.curve,
    );

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// A shimmering placeholder for content that is loading.
///
/// Section 28 rules out decorative loading animations, so this is a slow,
/// low-contrast sweep that communicates "content is coming, and this is its
/// shape" rather than entertaining anyone. It stops entirely under reduced
/// motion, leaving a plain block.
class LoadingBlock extends StatefulWidget {
  const LoadingBlock({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = BrandRadius.mediumAll,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<LoadingBlock> createState() => _LoadingBlockState();
}

class _LoadingBlockState extends State<LoadingBlock>
    with SingleTickerProviderStateMixin {
  // Created in initState rather than as a `late final` field: under reduced
  // motion `build` never reads it, so a lazy field would be constructed for
  // the first time inside dispose — where looking up TickerMode on a
  // deactivated element throws.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final base = isLight ? BrandColours.warmSand : BrandColours.darkElevated;
    final highlight = isLight ? BrandColours.mist : BrandColours.darkSurface;

    if (Motion.isReduced(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: widget.borderRadius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1 + _controller.value * 3, 0),
              end: Alignment(1 + _controller.value * 3, 0),
            ),
          ),
        );
      },
    );
  }
}

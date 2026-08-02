import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// A horizontally scrolling row that fades out at the edge it runs off.
///
/// **A chip cut in half by the edge of the screen looks broken; a chip fading
/// out looks like more.** The job filters have five or six chips and a phone
/// fits three, so on every launch the row was clipped mid-word with nothing to
/// say it scrolled — and the directory's category row, which has the same
/// problem, was still doing exactly that a sprint after the filters were
/// fixed. One row, so the next one gets it for free.
///
/// Follows the reading direction: in Urdu the row fades on the left, which is
/// where it runs off.
class FadingRow extends StatelessWidget {
  const FadingRow({
    super.key,
    required this.children,
    this.height = BrandSizing.touchTargetMinimum,
    this.spacing = BrandSizing.spaceSm,
    this.padding = const EdgeInsets.symmetric(horizontal: BrandSizing.spaceMd),
  });

  final List<Widget> children;

  /// Fixed, because a horizontal `ListView` has no intrinsic height and would
  /// otherwise be unbounded in the direction it does not scroll.
  final double height;

  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final rightToLeft = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      height: height,
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: rightToLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: rightToLeft ? Alignment.centerLeft : Alignment.centerRight,
          stops: const [0.0, 0.9, 1.0],
          colors: const [Colors.black, Colors.black, Colors.transparent],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: children.length,
          separatorBuilder: (_, _) => SizedBox(width: spacing),
          itemBuilder: (_, index) => Center(child: children[index]),
        ),
      ),
    );
  }
}

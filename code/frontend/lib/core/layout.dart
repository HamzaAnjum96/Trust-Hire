import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// How much room there is to work with.
///
/// The same build runs on a handset, a tablet and a desktop browser, and the
/// POC only ever designed for the first. These are Material's window size
/// classes, named for what the app does at each rather than for the device
/// that usually has them — a phone held sideways gets the medium treatment
/// because it has the room, not because it stopped being a phone.
enum LayoutSize {
  /// A handset held upright. Bottom navigation, one column, sheets.
  compact,

  /// A large phone in landscape, or a tablet. Still one column, but the
  /// content stops stretching and navigation moves to the side.
  medium,

  /// A tablet in landscape or a desktop browser. Room for two panes.
  expanded;

  static const mediumFrom = 600.0;
  static const expandedFrom = 1024.0;

  static LayoutSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static LayoutSize fromWidth(double width) {
    if (width >= expandedFrom) return LayoutSize.expanded;
    if (width >= mediumFrom) return LayoutSize.medium;
    return LayoutSize.compact;
  }

  /// True once navigation should move off the bottom edge.
  ///
  /// A bottom bar on a desktop browser puts the app's main controls as far
  /// from the pointer as the window allows, and reads as a phone screenshot.
  bool get usesRail => this != LayoutSize.compact;

  /// True once there is room to show a list beside the map.
  bool get isSplit => this == LayoutSize.expanded;
}

/// Centres its child and stops it stretching past [BrandSizing.readableWidth].
///
/// Used on the single-column screens — the job list, the profile — where the
/// alternative is a 1400px row holding one short sentence.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? BrandSizing.readableWidth,
        ),
        child: child,
      ),
    );
  }
}

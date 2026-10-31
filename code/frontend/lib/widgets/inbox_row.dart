import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// One row of a list drawn as a single surface — an inbox.
///
/// The borders and corners depend on where the row sits, so a list built
/// lazily, a row at a time, still reads as one card with hairlines between
/// its rows rather than as a stack of identical cards. Updates and messages
/// both use it: twenty separate cards made twenty items read as twenty things
/// of equal weight.
///
/// [highlighted] marks something new the way the app always has — by an
/// edge, now a burgundy bar down the leading side over a faint tint. Not a dot
/// and not a bold weight: an inbox is read at a glance, and a coloured edge
/// survives being glanced at.
class InboxRow extends StatelessWidget {
  const InboxRow({
    super.key,
    required this.index,
    required this.count,
    required this.child,
    this.highlighted = false,
  });

  /// Where this row sits, and how many there are.
  final int index;
  final int count;

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = index == 0;
    final last = index == count - 1;
    const corner = Radius.circular(BrandRadius.large);
    final side = BorderSide(color: scheme.outlineVariant);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          left: side,
          right: side,
          top: first ? side : BorderSide.none,
          bottom: side,
        ),
        borderRadius: BorderRadius.vertical(
          top: first ? corner : Radius.zero,
          bottom: last ? corner : Radius.zero,
        ),
      ),
      // So a row's ink is drawn over the white above it, not under it.
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: highlighted ? scheme.primary.withValues(alpha: 0.06) : null,
            border: BorderDirectional(
              start: BorderSide(
                color: highlighted ? scheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

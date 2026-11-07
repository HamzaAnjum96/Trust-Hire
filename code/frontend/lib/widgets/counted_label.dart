import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// A name with its count beside it, quieter, in figures that line up — so
/// "Offers 12" and "Saved 3" read as a name and a number rather than as one
/// phrase. Used in segmented controls, where the old "Offers · 12" put a
/// middle dot between two things that are not a list.
class CountedLabel extends StatelessWidget {
  const CountedLabel({super.key, required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: BrandSizing.spaceXs + 2),
        Text(
          '$count',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

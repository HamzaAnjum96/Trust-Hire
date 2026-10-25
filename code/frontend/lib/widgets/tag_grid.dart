import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../models/job_tag.dart';
import 'tag_tile.dart';

/// Every kind of work at once, in even rows.
///
/// **The posting form showed three and a half of nineteen.** Its tiles sat in
/// a sideways scroller, and nothing on screen said there were fifteen more
/// past the edge — on the one field the form requires, and the one that
/// decides who ever sees the job. The trades screen had the opposite problem:
/// a wrap of fixed 92px tiles that left a ragged gap at the end of each row.
/// Both now use this, which divides the width it is given into as many
/// columns as fit and sizes the tiles to fill them.
class TagGrid extends StatelessWidget {
  const TagGrid({
    super.key,
    required this.tags,
    required this.isSelected,
    required this.onTap,
    this.isEnabled,
  });

  final List<JobTag> tags;
  final bool Function(JobTag tag) isSelected;
  final ValueChanged<JobTag> onTap;

  /// Null means every tile can be chosen.
  final bool Function(JobTag tag)? isEnabled;

  /// Narrower than this and "Construction" has to shrink past legibility.
  static const minTileWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = BrandSizing.spaceSm;
        final columns = ((constraints.maxWidth + gap) / (minTileWidth + gap))
            .floor()
            .clamp(3, 12);
        // Floored, so rounding never pushes the last tile onto a row of its
        // own.
        final width =
            ((constraints.maxWidth - gap * (columns - 1)) / columns)
                .floorToDouble();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tag in tags)
              TagTile(
                tag: tag,
                width: width,
                selected: isSelected(tag),
                enabled: isEnabled?.call(tag) ?? true,
                onTap: () => onTap(tag),
              ),
          ],
        );
      },
    );
  }
}

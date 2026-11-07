import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/tokens.dart';

/// A placeholder in the shape of the job list.
///
/// Better than a spinner: it says what is coming and stops the layout jumping
/// when real content lands. Section 28 asks that motion communicate a state
/// change rather than decorate, which a shape-of-the-content placeholder does
/// and a spinning circle does not.
class JobListSkeleton extends StatelessWidget {
  const JobListSkeleton({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      // The shape of the rows it stands in for: flat, with a hairline
      // between them.
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: BrandSizing.spaceSm),
        itemCount: rows,
        separatorBuilder: (_, _) => const Divider(indent: BrandSizing.spaceMd),
        itemBuilder: (_, _) => const _JobRowSkeleton(),
      ),
    );
  }
}

class _JobRowSkeleton extends StatelessWidget {
  const _JobRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(BrandSizing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingBlock(width: 180, height: 20),
          SizedBox(height: BrandSizing.spaceSm),
          LoadingBlock(width: 240, height: 14),
          SizedBox(height: BrandSizing.spaceMd),
          Row(
            children: [
              LoadingBlock(width: 96, height: 12),
              SizedBox(width: BrandSizing.spaceMd),
              LoadingBlock(width: 72, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

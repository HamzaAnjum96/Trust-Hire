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
      child: ListView.separated(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        itemCount: rows,
        separatorBuilder: (_, _) =>
            const SizedBox(height: BrandSizing.spaceSm + 4),
        itemBuilder: (_, _) => const _JobRowSkeleton(),
      ),
    );
  }
}

class _JobRowSkeleton extends StatelessWidget {
  const _JobRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(BrandSizing.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BrandRadius.largeAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const Column(
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

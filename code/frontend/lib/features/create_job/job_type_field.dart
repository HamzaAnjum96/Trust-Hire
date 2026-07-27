import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/tokens.dart';
import '../../models/job_type.dart';
import 'job_draft_controller.dart';

/// Choosing the kind of work.
///
/// Optional throughout: there is no "please select" prompt, tapping the
/// selected tile again clears it, and the label says so. What it buys is a
/// map where a plumbing pin and a driving pin read differently at a glance.
///
/// Tiles rather than a dropdown — a dropdown means two taps and a scroll on a
/// small screen, and hides every option until opened.
class JobTypeField extends StatelessWidget {
  const JobTypeField({super.key, required this.draft});

  final JobDraftController draft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: JobType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: BrandSizing.spaceSm),
        itemBuilder: (context, index) {
          final type = JobType.values[index];
          return _TypeTile(
            type: type,
            selected: draft.type == type,
            // Tapping the chosen type again unsets it, so a mis-tap is not a
            // trap.
            onTap: () => draft.setType(draft.type == type ? null : type),
          );
        },
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final JobType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final background = selected
        ? theme.colorScheme.primary
        : (isLight ? BrandColours.warmSand : BrandColours.darkElevated);
    final foreground = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: type.label,
      child: Material(
        color: background,
        borderRadius: BrandRadius.mediumAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: BrandRadius.mediumAll,
          child: AnimatedContainer(
            duration: Motion.fast(context),
            width: 92,
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSizing.spaceSm,
              vertical: BrandSizing.spaceSm,
            ),
            decoration: BoxDecoration(
              borderRadius: BrandRadius.mediumAll,
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, size: 28, color: foreground),
                const SizedBox(height: BrandSizing.spaceXs + 2),
                Text(
                  type.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

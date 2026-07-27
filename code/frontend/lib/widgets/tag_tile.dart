import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/job_tag.dart';

/// A selectable kind of work: icon above, plain word below.
///
/// Shared by the two places tags are chosen — a hirer tagging a job and a
/// worker picking their trades — because they are the same decision seen from
/// two sides, and the audience should not have to learn two controls for it.
///
/// Icon-led on purpose. Section 8 asks a worker only to recognise their own
/// work, and the brand guidelines want that possible without reading.
class TagTile extends StatelessWidget {
  const TagTile({
    super.key,
    required this.tag,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.width = 92,
  });

  final JobTag tag;
  final bool selected;

  /// False when the tile can be seen but not chosen — a fourth tag on a job
  /// that already has three. It stays visible rather than disappearing, so the
  /// list does not reshuffle under a finger.
  final bool enabled;

  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final background = selected
        ? theme.colorScheme.primary
        : (isLight ? BrandColours.warmSand : BrandColours.darkElevated);
    final foreground = selected
        ? theme.colorScheme.onPrimary
        : (enabled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant);

    return Semantics(
      button: true,
      selected: selected,
      label: tag.label(strings),
      child: Material(
        color: background,
        borderRadius: BrandRadius.mediumAll,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BrandRadius.mediumAll,
          child: AnimatedContainer(
            duration: Motion.fast(context),
            width: width,
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
                Icon(tag.icon, size: 28, color: foreground),
                const SizedBox(height: BrandSizing.spaceXs + 2),
                Text(
                  tag.label(strings),
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

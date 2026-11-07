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
            // Room for a two-line label on every tile, so a row whose labels
            // wrap and a row whose labels do not are the same height.
            constraints: const BoxConstraints(minHeight: 84),
            // Narrow at the sides: the label needs the width more than the
            // tile needs the margin. At 8px a side "Appliance repair" and
            // "Legal advice" were shrunk to about 10px to fit one line.
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
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
                // Two-word labels wrap at the space; a single word too long
                // for the tile is shrunk rather than broken mid-word, which
                // read as a rendering fault ("Constructio / n"). Since 0.23
                // the shrink is the exception — at large text sizes — not
                // what happens to every long label: these labels exist so
                // somebody who reads slowly can check the icon against a
                // word, and 10px defeats that.
                _TileLabel(
                  text: tag.label(strings),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tile's label: wrapped at its spaces, and shrunk only if one word alone
/// is wider than the tile.
///
/// A bare `FittedBox` around the text — what this used to be — lays the text
/// out with no width limit, so it never wraps: every two-word label was
/// shrunk onto one line instead. Here the text is laid out at the tile's own
/// width, or at the widest single word if that is wider, and only then scaled.
class _TileLabel extends StatelessWidget {
  const _TileLabel({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        var widest = 0.0;
        for (final word in text.split(RegExp(r'\s+'))) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: style),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          if (painter.width > widest) widest = painter.width;
          painter.dispose();
        }

        final width = constraints.maxWidth.isFinite
            ? (widest.ceilToDouble() > constraints.maxWidth
                  ? widest.ceilToDouble()
                  : constraints.maxWidth)
            : widest.ceilToDouble();

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: width,
            child: Text(
              text,
              style: style,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

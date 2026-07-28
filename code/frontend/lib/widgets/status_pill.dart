import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// A small, filled, labelled state marker.
///
/// One widget for the three places that had grown their own: a job's status, a
/// bid's outcome, and an account's standing in the admin panel. They were
/// identical apart from two pixels of padding, which is the shape a brand
/// change goes wrong in — somebody updates the radius on the one they are
/// looking at and the other two quietly diverge.
///
/// **Always labelled.** Section 29 of the brand guidelines forbids colour as
/// the only carrier of meaning, so the word is the message and the tint only
/// reinforces it. That is why this takes a label rather than being able to
/// render an unlabelled dot.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceSm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BrandRadius.smallAll,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// The quiet treatment — for a state that is neither good news nor bad.
  factory StatusPill.muted(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return StatusPill(
      label: label,
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurfaceVariant,
    );
  }

  /// The brand treatment — for the state that is currently in force.
  factory StatusPill.emphasised(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return StatusPill(
      label: label,
      background: scheme.primary,
      foreground: scheme.onPrimary,
    );
  }

  /// Finished, and finished well.
  factory StatusPill.good(String label) => StatusPill(
    label: label,
    background: BrandColours.successTeal,
    foreground: BrandColours.white,
  );

  /// Stopped by somebody, rather than simply over.
  factory StatusPill.bad(String label) => StatusPill(
    label: label,
    background: BrandColours.errorRed,
    foreground: BrandColours.white,
  );
}

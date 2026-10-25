import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../l10n/app_localizations.dart';

/// "Your posting", on a job the person looking posted.
///
/// **There were three copies of this** — the job row, the map's preview card
/// and the job sheet — and all three set 12px white type on solid copper,
/// which is 3.8:1: below what small text needs. One widget now, with the
/// copper as a tint and a border instead, so it still reads as the colour the
/// map marks the same jobs in, and the words are ink on near-white.
class MineBadge extends StatelessWidget {
  const MineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.16),
        borderRadius: BrandRadius.smallAll,
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.7)),
      ),
      child: Text(
        strings.onThisDevice,
        style: BrandType.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

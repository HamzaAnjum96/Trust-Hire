import 'package:flutter/material.dart';
import '../core/roles.dart';

import '../core/tokens.dart';
import '../l10n/app_localizations.dart';

/// "Your posting", on a job the person looking posted.
///
/// **There were three copies of this** — the job row, the map's preview card
/// and the job sheet — and all three set 12px white type on solid copper,
/// which is 3.8:1: below what small text needs. One widget now. Since 0.24 it
/// is drawn the way the map draws your own pins, inverted: the surface inside
/// and an ink edge. It was briefly peacock, which is for voice notes only.
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
        color: context.colours.surface,
        borderRadius: BrandRadius.smallAll,
        border: Border.all(color: context.colours.text),
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

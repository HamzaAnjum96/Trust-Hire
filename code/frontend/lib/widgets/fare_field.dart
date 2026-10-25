import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../l10n/app_localizations.dart';

/// The decoration every typed fare uses: the currency always in view, and an
/// example amount as the hint.
///
/// **`prefixText` was the obvious way to show "Rs." and the wrong one.** It is
/// drawn only once the field has focus or text, but its space is kept either
/// way — so an empty fare field showed its hint indented by an invisible
/// "Rs.", which read as a layout fault on the posting form and the offer
/// sheet alike.
InputDecoration fareDecoration(
  BuildContext context, {
  TextStyle? style,
  String? errorText,
}) {
  final strings = AppStrings.of(context);
  final theme = Theme.of(context);

  return InputDecoration(
    hintText: strings.fareHintAmount,
    errorText: errorText,
    prefixIcon: Padding(
      padding: const EdgeInsetsDirectional.only(
        start: BrandSizing.spaceMd,
        end: BrandSizing.spaceSm,
      ),
      child: Text(
        strings.rupees('').trim(),
        style: (style ?? theme.textTheme.bodyLarge)?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    prefixIconConstraints: const BoxConstraints(),
  );
}

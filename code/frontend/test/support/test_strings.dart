import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trust_hire/l10n/app_localizations.dart';

/// Loads the string catalogue outside a widget tree.
///
/// Model and filter tests need the same [AppStrings] the app uses — search
/// reaches a job's shown words, and those come from the catalogue — but they
/// have no `BuildContext` to look one up from.
Future<AppStrings> loadStrings([String locale = 'en']) async {
  // Formatting a date in a locale whose symbols were never loaded throws,
  // which is exactly the bug this helper existing at all uncovered.
  await initializeDateFormatting(locale);
  return AppStrings.delegate.load(Locale(locale));
}

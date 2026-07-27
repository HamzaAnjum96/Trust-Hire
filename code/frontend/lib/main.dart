import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Date and number symbols for every language on offer. Without this,
  // formatting a date in a non-default locale throws — and it throws inside
  // a build, so the failure surfaces as a blank screen rather than an error.
  for (final locale in AppStrings.supportedLocales) {
    await initializeDateFormatting(locale.languageCode);
  }

  // Storage opened *and seeded* before the first frame. See [bootstrap] for
  // why the second half of that matters.
  final store = await bootstrap();

  runApp(TrustHireApp(store: store));
}

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'l10n/app_localizations.dart';
import 'services/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Date and number symbols for every language on offer. Without this,
  // formatting a date in a non-default locale throws — and it throws inside
  // a build, so the failure surfaces as a blank screen rather than an error.
  for (final locale in AppStrings.supportedLocales) {
    await initializeDateFormatting(locale.languageCode);
  }

  // Local storage is opened before the first frame so the app never renders
  // against an uninitialised store.
  final store = await LocalStore.open();

  runApp(TrustHireApp(store: store));
}

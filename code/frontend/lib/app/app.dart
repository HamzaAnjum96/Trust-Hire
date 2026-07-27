import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../features/jobs/job_filter_controller.dart';
import '../features/jobs/saved_jobs_controller.dart';
import '../features/map/location_controller.dart';
import '../services/job_repository.dart';
import '../services/local_store.dart';
import '../services/media_store.dart';
import 'app_shell.dart';
import 'job_controller.dart';
import 'settings_controller.dart';

/// Application root — wires up the controllers and the themes.
class TrustHireApp extends StatelessWidget {
  const TrustHireApp({super.key, required this.store});

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MediaStore>(create: (_) => MediaStore(store)),
        ChangeNotifierProvider(
          create: (_) => SettingsController(store)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              JobController(JobRepository(store, MediaStore(store)))..load(),
        ),
        ChangeNotifierProvider(create: (_) => JobFilterController()),
        ChangeNotifierProvider(
          create: (_) => SavedJobsController(store)..load(),
        ),
        ChangeNotifierProvider(
          // Location is requested on first launch so the map can open on the
          // user rather than the fallback. A refusal is handled, not retried.
          create: (_) => LocationController()..request(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            onGenerateTitle: (context) => AppStrings.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            locale: settings.locale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: BrandTheme.light,
            darkTheme: BrandTheme.dark,
            themeMode: settings.themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

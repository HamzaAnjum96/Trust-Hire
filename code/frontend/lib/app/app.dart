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
import '../features/onboarding/onboarding_screen.dart';
import 'app_shell.dart';
import 'job_controller.dart';
import 'profile_controller.dart';
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
        ChangeNotifierProvider(create: (_) => ProfileController(store)..load()),
        ChangeNotifierProvider(
          // Deliberately not requested here. Asking for a permission before
          // explaining what it is for is what section 19 warns against, so
          // the intro asks — and afterwards, only "Near Me" does.
          create: (_) => LocationController(),
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
            home: const _Entry(),
          );
        },
      ),
    );
  }
}

/// Chooses between the intro and the app itself.
class _Entry extends StatelessWidget {
  const _Entry();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    if (settings.introSeen) return const AppShell();

    return OnboardingScreen(
      location: context.read<LocationController>(),
      onFinished: settings.markIntroSeen,
    );
  }
}

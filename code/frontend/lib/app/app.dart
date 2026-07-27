import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../features/jobs/job_filter_controller.dart';
import '../features/jobs/saved_jobs_controller.dart';
import '../features/map/location_controller.dart';
import '../services/bid_repository.dart';
import '../services/job_repository.dart';
import '../services/local_store.dart';
import '../services/media_store.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'account_controller.dart';
import 'app_shell.dart';
import 'bid_controller.dart';
import 'job_controller.dart';
import 'rating_controller.dart';
import 'wallet_controller.dart';
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

        // Before everything that depends on identity, so the proxies below
        // read a settled account rather than switching one frame in.
        ChangeNotifierProvider(create: (_) => AccountController(store)..load()),

        // Each of these belongs to a person rather than to the device, so
        // each follows the active account. A proxy rather than a listener in
        // a widget: the dependency is real and permanent, and hiding it in a
        // `initState` somewhere would let a screen forget to re-read.
        ChangeNotifierProxyProvider<AccountController, SavedJobsController>(
          create: (_) => SavedJobsController(store)..load(),
          update: (_, account, saved) =>
              saved!..setAccount(account.activeId),
        ),
        ChangeNotifierProxyProvider<AccountController, ProfileController>(
          create: (_) => ProfileController(store)..load(),
          update: (_, account, profile) =>
              profile!..setAccount(account.activeId),
        ),
        ChangeNotifierProxyProvider<AccountController, BidController>(
          create: (_) => BidController(BidRepository(store))..load(),
          update: (_, account, bids) => bids!..setAccount(account.activeId),
        ),
        ChangeNotifierProxyProvider<AccountController, WalletController>(
          create: (_) => WalletController(store)..load(),
          update: (_, account, wallet) =>
              wallet!..setAccount(account.activeId),
        ),
        ChangeNotifierProvider(create: (_) => RatingController(store)..load()),
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

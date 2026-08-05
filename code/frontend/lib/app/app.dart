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
import '../services/seed_loader.dart';
import '../services/local_store.dart';
import '../services/backend/mock_backend.dart';
import '../services/media_store.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'account_controller.dart';
import 'notification_controller.dart';
import 'admin_controller.dart';
import 'sync_controller.dart';
import 'verification_controller.dart';
import 'app_shell.dart';
import 'bid_controller.dart';
import 'job_controller.dart';
import 'premium_controller.dart';
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

        // The backend seam, and the queue that feeds it. **Before the
        // repositories**, because they write through it: a change lands
        // locally and is handed on afterwards, never the other way round.
        Provider<MockBackend>(create: (_) => MockBackend()),
        ChangeNotifierProvider(
          create: (context) =>
              SyncController(store, context.read<MockBackend>())..load(),
        ),

        ChangeNotifierProvider(
          create: (_) => SettingsController(store)..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => JobController(
            JobRepository(
              store,
              MediaStore(store),
              const SeedLoader(),
              context.read<SyncController>().enqueue,
            ),
          )..load(),
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
          create: (context) => BidController(
            BidRepository(store, context.read<SyncController>().enqueue),
          )..load(),
          update: (_, account, bids) => bids!..setAccount(account.activeId),
        ),
        ChangeNotifierProxyProvider<AccountController, WalletController>(
          create: (_) => WalletController(store)..load(),
          update: (_, account, wallet) =>
              wallet!..setAccount(account.activeId),
        ),
        ChangeNotifierProvider(create: (_) => RatingController(store)..load()),
        ChangeNotifierProxyProvider<AccountController, PremiumController>(
          create: (_) => PremiumController(store)..load(),
          update: (_, account, premium) =>
              premium!..setAccount(account.activeId),
        ),
        // Follows the account so the audit log records which member of staff
        // did a thing rather than an anonymous "admin".
        ChangeNotifierProxyProvider<AccountController, AdminController>(
          create: (_) => AdminController(store)..load(),
          update: (_, account, admin) => admin!..setAccount(account.activeId),
        ),
        // Takes the account's *name* as well as its id: the SIM-name check
        // compares the name on the card against it, and a controller that
        // knew only an id would have nothing to compare.
        ChangeNotifierProxyProvider<AccountController, VerificationController>(
          create: (_) => VerificationController(store)..load(),
          update: (_, account, verification) => verification!
            ..setAccount(account.activeId, name: account.active.name ?? ''),
        ),
        // Only the "seen up to here" mark lives here; the feed itself is
        // derived from the controllers above whenever a screen asks for it.
        ChangeNotifierProxyProvider<AccountController, NotificationController>(
          create: (_) => NotificationController(store)..load(),
          update: (_, account, notifications) =>
              notifications!..setAccount(account.activeId),
        ),
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

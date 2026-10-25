import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trust_hire/app/account_controller.dart';
import 'package:trust_hire/app/bid_controller.dart';
import 'package:trust_hire/app/job_controller.dart';
import 'package:trust_hire/app/message_controller.dart';
import 'package:trust_hire/app/notification_controller.dart';
import 'package:trust_hire/app/premium_controller.dart';
import 'package:trust_hire/app/profile_controller.dart';
import 'package:trust_hire/app/rating_controller.dart';
import 'package:trust_hire/app/verification_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/jobs/saved_jobs_controller.dart';
import 'package:trust_hire/features/map/location_controller.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/services/bid_repository.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';
import 'package:trust_hire/services/message_repository.dart';

/// Every provider the app has, around whatever screen a test is looking at.
///
/// **This exists because four test files kept a hand-written copy of the
/// provider tree, and every one of them broke whenever a screen gained a
/// dependency.** Three separate rounds ended with the same fix applied in
/// three places — and the copies had already drifted: one registered the
/// wallet twice, another was missing the rating controller entirely, and none
/// of them agreed on the order.
///
/// The rule this follows is the one the rest of the codebase follows: a thing
/// that must stay identical in several places belongs in one place. A test
/// that wants to reach inside a controller passes it in; everything else is
/// built from [store] and never thought about again.
Widget appHarness({
  required LocalStore store,
  required Widget child,
  MediaStore? media,
  JobController? jobs,
  BidController? bids,
  SavedJobsController? saved,
  ProfileController? profile,
  WalletController? wallet,
  AccountController? accounts,
  RatingController? ratings,
  PremiumController? premium,
  MessageController? messages,
  NotificationController? notifications,
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  final mediaStore = media ?? MediaStore(store);

  /// Uses the controller a test handed in, or builds one. `.value` matters:
  /// a test that inspects a controller must be given the same instance the
  /// widget is using, not a second one over the same storage.
  ChangeNotifierProvider<T> provide<T extends ChangeNotifier>(
    T? supplied,
    T Function() build,
  ) => supplied == null
      ? ChangeNotifierProvider<T>(create: (_) => build())
      : ChangeNotifierProvider<T>.value(value: supplied);

  return MultiProvider(
    providers: [
      provide<JobController>(
        jobs,
        () => JobController(JobRepository(store, mediaStore))..load(),
      ),
      provide<BidController>(
        bids,
        () => BidController(BidRepository(store))..load(),
      ),
      provide<AccountController>(accounts, () => AccountController(store)..load()),
      provide<SavedJobsController>(saved, () => SavedJobsController(store)..load()),
      provide<ProfileController>(profile, () => ProfileController(store)..load()),
      provide<WalletController>(wallet, () => WalletController(store)..load()),
      provide<RatingController>(ratings, () => RatingController(store)..load()),
      provide<PremiumController>(premium, () => PremiumController(store)..load()),
      provide<MessageController>(
        messages,
        () => MessageController(MessageRepository(store))..load(),
      ),
      provide<NotificationController>(
        notifications,
        () => NotificationController(store)..load(),
      ),
      ChangeNotifierProvider(create: (_) => VerificationController(store)..load()),
      ChangeNotifierProvider(create: (_) => LocationController()),
      Provider<MediaStore>.value(value: mediaStore),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      theme: theme ?? BrandTheme.light,
      home: child,
    ),
  );
}

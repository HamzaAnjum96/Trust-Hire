import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/job_controller.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/jobs/job_details_sheet.dart';
import 'package:trust_hire/features/jobs/my_jobs_screen.dart';
import 'package:trust_hire/features/jobs/saved_jobs_controller.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/app/bid_controller.dart';
import 'package:trust_hire/app/profile_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/app/rating_controller.dart';
import 'package:trust_hire/app/premium_controller.dart';
import 'package:trust_hire/app/verification_controller.dart';
import 'package:trust_hire/app/notification_controller.dart';
import 'package:trust_hire/services/bid_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

import 'support/test_strings.dart';
import 'package:trust_hire/app/account_controller.dart';

/// Until now there was nowhere to come back to: a worker who found a job had
/// to find it again, and a poster had no home for what they had offered.
void main() {
  late AppStrings strings;

  setUpAll(() async => strings = await loadStrings());

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Job job(String id, {bool isLocal = false}) => Job(
    id: id,
    location: const JobLocation(latitude: 33.68, longitude: 73.04),
    createdAt: DateTime(2026, 7, 27),
    title: 'Job $id',
    isLocal: isLocal,
  );

  group('saving', () {
    test('starts with nothing saved', () async {
      final store = await LocalStore.open();
      final saved = SavedJobsController(store)..load();

      expect(saved.count, 0);
      expect(saved.isSaved('a'), isFalse);
    });

    test('toggles on and off, reporting which it did', () async {
      final store = await LocalStore.open();
      final saved = SavedJobsController(store)..load();

      expect(await saved.toggle('a'), isTrue);
      expect(saved.isSaved('a'), isTrue);

      expect(await saved.toggle('a'), isFalse);
      expect(saved.isSaved('a'), isFalse);
    });

    test('survives a restart', () async {
      final store = await LocalStore.open();
      await (SavedJobsController(store)..load()).toggle('a');

      final reloaded = SavedJobsController(store)..load();
      expect(reloaded.isSaved('a'), isTrue);
      expect(reloaded.count, 1);
    });

    test('keeps the newest save first', () async {
      final store = await LocalStore.open();
      final saved = SavedJobsController(store)..load();

      await saved.toggle('a');
      await saved.toggle('b');
      await saved.toggle('c');

      final resolved = saved.resolve([job('a'), job('b'), job('c')]);
      expect(resolved.map((j) => j.id), ['c', 'b', 'a']);
    });
  });

  group('resolving against the real jobs', () {
    test('reflects an edit rather than showing a stale copy', () async {
      // Ids are stored, not copies — so a job edited after saving shows the
      // edit.
      final store = await LocalStore.open();
      final saved = SavedJobsController(store)..load();
      await saved.toggle('a');

      final edited = Job(
        id: 'a',
        location: const JobLocation(latitude: 33.68, longitude: 73.04),
        createdAt: DateTime(2026, 7, 27),
        title: 'Changed title',
      );

      expect(saved.resolve([edited]).single.title, 'Changed title');
    });

    test('skips a job that has since been deleted', () async {
      final store = await LocalStore.open();
      final saved = SavedJobsController(store)..load();
      await saved.toggle('a');
      await saved.toggle('b');

      // 'a' is gone.
      final resolved = saved.resolve([job('b')]);

      expect(resolved.map((j) => j.id), ['b']);
      expect(saved.hasMissing([job('b')]), isTrue);
    });

    test('pruning drops ids whose jobs are gone', () async {
      final store = await LocalStore.open();
      final saved = SavedJobsController(store)..load();
      await saved.toggle('a');
      await saved.toggle('b');

      await saved.prune([job('b')]);

      expect(saved.count, 1);
      expect(saved.isSaved('a'), isFalse);
      expect(saved.hasMissing([job('b')]), isFalse);
    });

    test('pruning does nothing when everything still exists', () async {
      final store = await LocalStore.open();
      final saved = SavedJobsController(store)..load();
      await saved.toggle('a');

      await saved.prune([job('a')]);

      expect(saved.count, 1);
    });
  });

  group('the screen', () {
    Future<(JobController, MediaStore, SavedJobsController)> build() async {
      final store = await LocalStore.open();
      final media = MediaStore(store);
      final jobs = JobController(JobRepository(store, media));
      await jobs.load();
      return (jobs, media, SavedJobsController(store)..load());
    }

    Future<void> pump(
      WidgetTester tester,
      JobController jobs,
      MediaStore media,
      SavedJobsController saved,
      Widget child,
    ) async {
      final store = await LocalStore.open();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: jobs),
            ChangeNotifierProvider.value(value: saved),
            ChangeNotifierProvider(
              create: (_) => AccountController(store)..load(),
            ),
            // The details sheet grew a bidding block in P1-2, and it reads
            // both of these.
            ChangeNotifierProvider(
              create: (_) => BidController(BidRepository(store))..load(),
            ),
            ChangeNotifierProvider(
              create: (_) => ProfileController(store)..load(),
            ),
            ChangeNotifierProvider(
              create: (_) => WalletController(store)..load(),
            ),
            // The Activity screen leads with the Updates tab from 0.17.0, and
            // the feed is derived from these four.
            ChangeNotifierProvider(
              create: (_) => RatingController(store)..load(),
            ),
            ChangeNotifierProvider(
              create: (_) => PremiumController(store)..load(),
            ),
            ChangeNotifierProvider(
              create: (_) => VerificationController(store)..load(),
            ),
            ChangeNotifierProvider(
              create: (_) => NotificationController(store)..load(),
            ),
            Provider<MediaStore>.value(value: media),
          ],
          child: MaterialApp(
            localizationsDelegates: AppStrings.localizationsDelegates,
            supportedLocales: AppStrings.supportedLocales,
            theme: BrandTheme.light,
            home: child,
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Moves to the tab named by [label].
    ///
    /// Every test below was written when Saved was the first tab and the
    /// screen opened on it. 0.17.0 put Updates in front — the destination now
    /// carries a badge, and tapping a badge must land on the thing it counted
    /// — so a test about saved jobs has to say so.
    Future<void> openTab(WidgetTester tester, String label) async {
      await tester.tap(find.textContaining(label));
      await tester.pumpAndSettle();
    }

    testWidgets('says what to do when nothing is saved', (tester) async {
      final (jobs, media, saved) = await build();
      await pump(tester, jobs, media, saved, const MyJobsScreen());
      await openTab(tester, strings.savedTab);

      expect(find.text(strings.noSavedJobs), findsOneWidget);
      expect(find.text(strings.noSavedJobsMessage), findsOneWidget);
    });

    testWidgets('lists a saved job', (tester) async {
      final (jobs, media, saved) = await build();
      // By whatever the repository actually holds: the seed is generated, so
      // naming an id here would be testing the generator.
      final job = jobs.jobs.first;
      await saved.toggle(job.id);

      await pump(tester, jobs, media, saved, const MyJobsScreen());
      await openTab(tester, strings.savedTab);

      expect(find.text(job.displayTitle(strings)), findsOneWidget);
    });

    testWidgets('separates postings from saved jobs', (tester) async {
      final (jobs, media, saved) = await build();
      await jobs.saveJob(job('mine', isLocal: true));

      await pump(tester, jobs, media, saved, const MyJobsScreen());
      await openTab(tester, strings.savedTab);

      // Nothing saved, so the saved tab is empty …
      expect(find.text(strings.noSavedJobs), findsOneWidget);

      // … while the posted tab has the job.
      await openTab(tester, strings.postedTab);
      await tester.pumpAndSettle();
      expect(find.text('Job mine'), findsOneWidget);
    });

    testWidgets('mentions once when a saved job has disappeared', (
      tester,
    ) async {
      final (jobs, media, saved) = await build();
      await saved.toggle('seed-001');
      await saved.toggle('gone-for-good');

      await pump(tester, jobs, media, saved, const MyJobsScreen());
      await openTab(tester, strings.savedTab);

      expect(find.text(strings.savedJobGone), findsOneWidget);
    });

    testWidgets('the details sheet saves and unsaves', (tester) async {
      final (jobs, media, saved) = await build();
      final jobId = jobs.jobs.first.id;

      await pump(
        tester,
        jobs,
        media,
        saved,
        Scaffold(
          body: JobDetailsSheet(jobId: jobId, mediaStore: media),
        ),
      );

      expect(saved.isSaved(jobId), isFalse);

      await tester.tap(find.byTooltip(strings.saveThisJob));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(saved.isSaved(jobId), isTrue);

      await tester.tap(find.byTooltip(strings.removeFromSaved));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(saved.isSaved(jobId), isFalse);
    });
  });
}
